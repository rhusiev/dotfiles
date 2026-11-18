"""Track global instruction changes separately from the legacy plan read gate."""

from __future__ import annotations

from collections.abc import Callable
import difflib
import fcntl
from functools import wraps
import hashlib
import json
import re
import shlex
import time
from pathlib import Path
from typing import TypeVar

import task_topics
from plan_state import (
    CONVENTIONS,
    GATE_MAX_AGE_S,
    GATE_MAX_DENIALS,
    ROOT,
    codex_home,
    team_instructions_root,
    write_atomically,
)

READ_ONLY_TOOLS = frozenset({"Read", "Glob", "Grep", "LS", "WebFetch", "WebSearch"})
RUNTIMES = frozenset({"claude", "codex", "copilot"})
ReturnT = TypeVar("ReturnT")
DIFF_CONTEXT_LINES = 3
PRIVATE_FILE_MODE = 0o600
COPILOT_SHELL_FOOTER = re.compile(
    r"<shellId: [0-9]+ completed with exit code (-?[0-9]+)>\Z",
)


def sources(runtime: str, cwd: str | None = None) -> list[Path]:
    """Return the instruction sources one runtime needs in the repository at cwd.

    CONVENTIONS is needed only where the repository tracks no AGENTS.md or
    CLAUDE.md of its own. No runtime imports it, so it is never in a startup
    baseline and always takes an explicit read.
    """
    shared = Path.home() / ".config" / "claude"
    primary = {
        "claude": [shared / "CLAUDE.md"],
        "codex": [
            codex_home() / "AGENTS.md",
        ],
        "copilot": [
            Path.home() / ".copilot" / "copilot-instructions.md",
            shared / "CLAUDE.md",
        ],
    }
    conventions = [] if team_instructions_root(cwd) else [CONVENTIONS]
    return [*primary[runtime], shared / "work.md", shared / "ste.md", *conventions]


def fingerprint(path: Path) -> str | None:
    """Hash original bytes, retaining absence as a distinct state."""
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except FileNotFoundError:
        return None


def state_path(event: dict, runtime: str) -> Path:
    """Keep runtime/session state isolated and reject unsafe identifiers."""
    session = event.get("session_id")
    if runtime not in RUNTIMES or not isinstance(session, str):
        raise ValueError("Missing runtime or session identifier")
    if not re.fullmatch(r"[\w-]+", session):
        raise ValueError("Unsafe session identifier")
    return ROOT / ".instructions" / f"{runtime}-{session}.json"


def serialized(
    operation: Callable[[dict, str], ReturnT],
) -> Callable[[dict, str], ReturnT]:
    """Serialize a complete state transaction, not the tool read between hooks."""
    @wraps(operation)
    def invoke(event: dict, runtime: str) -> ReturnT:
        if event.get("agent_id"):
            return operation(event, runtime)
        path = state_path(event, runtime).with_suffix(".lock")
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a+b") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                return operation(event, runtime)
            finally:
                fcntl.flock(lock, fcntl.LOCK_UN)

    return invoke


def save(event: dict, runtime: str, state: dict) -> None:
    """Atomically save observed acknowledgments and pending read identities."""
    write_atomically(state_path(event, runtime), json.dumps(state).encode())


def artifact_path(event: dict, runtime: str, source: Path, suffix: str) -> Path:
    """Locate a private source artifact beside the session state."""
    key = hashlib.sha256(str(source).encode()).hexdigest()
    return state_path(event, runtime).with_suffix(f".{key}.{suffix}")


def save_snapshot(event: dict, runtime: str, source: Path, data: bytes) -> None:
    """Retain acknowledged source bytes with owner-only permissions."""
    path = artifact_path(event, runtime, source, "snapshot")
    write_atomically(path, data)
    path.chmod(PRIVATE_FILE_MODE)


def source_lines(data: bytes) -> list[bytes]:
    """Split only on LF, preserving the original record delimiters."""
    records = data.split(b"\n")
    return [line + b"\n" for line in records[:-1]] + (
        [records[-1]] if records[-1] else []
    )


def prepare_diffs(event: dict, runtime: str, state: dict, changed: list[Path]) -> dict:
    """Build changes only from snapshots matching the acknowledged digest."""
    diffs = {}
    for source in changed:
        snapshot = artifact_path(event, runtime, source, "snapshot")
        previous = state["loaded"].get(str(source))
        if previous is None or fingerprint(snapshot) != previous or not source.exists():
            continue
        data = source.read_bytes()
        current = hashlib.sha256(data).hexdigest()
        header = (
            f"Instruction source: {source}\n"
            f"Acknowledged SHA256: {previous}\nCurrent SHA256: {current}\n"
            f"Current lines: {len(source_lines(data))}\n"
        )
        changes = difflib.unified_diff(
            [line.decode() for line in source_lines(snapshot.read_bytes())],
            [line.decode() for line in source_lines(data)],
            fromfile=str(source), tofile=str(source), n=DIFF_CONTEXT_LINES,
        )
        # Separate unterminated source lines so additions and removals stay distinct.
        body = "".join(
            line if line.endswith("\n") else line + "\n\\ No newline at end of file\n"
            for line in changes
        )
        path = artifact_path(event, runtime, source, "diff")
        content = (header + body).encode()
        if not path.exists() or path.read_bytes() != content:
            write_atomically(path, content)
            path.chmod(PRIVATE_FILE_MODE)
        diffs[str(source)] = {"path": str(path), "digest": current}
    return diffs


def full_read_requirement(source: Path, state: dict, runtime: str) -> str:
    """Describe exact outstanding LF-record ranges for a complete source read."""
    if not source.exists():
        return f"{source}: deleted source - restore it"
    data = source.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    coverage = state.get("coverage", {}).get(str(source), {})
    spans = coverage.get("intervals", []) if coverage.get("digest") == digest else []
    missing = []
    offset = 0
    for number, line in enumerate(source_lines(data), start=1):
        end = offset + len(line)
        if not any(start <= offset and stop >= end for start, stop in spans):
            if missing and missing[-1][1] == number - 1:
                missing[-1][1] = number
            else:
                missing.append([number, number])
        offset = end
    total = len(source_lines(data))
    ranges = ", ".join(str(a) if a == b else f"{a}-{b}" for a, b in missing)
    message = f"{source}: {total} lines, {len(data)} bytes; unread lines: {ranges or 'none'}"
    if runtime == "copilot":
        message += f"; use view_range chunks of at most ~15 KB; the last chunk ends at line {total}"
    return message


def read_requirements(changed: list[Path], diffs: dict, state: dict, runtime: str) -> str:
    """Name the exact diff or outstanding source ranges to read."""
    return "\n".join(
        f"- {source}: read complete diff {diffs[str(source)]['path']}"
        if str(source) in diffs else "- " + full_read_requirement(source, state, runtime)
        for source in changed
    )


def load(event: dict, runtime: str, startup: bool = False) -> dict:
    """Initialize an injected baseline only on a real startup event."""
    path = state_path(event, runtime)
    if path.exists():
        state = json.loads(path.read_text())
        if (
            not isinstance(state, dict)
            or state.get("version") != 1
            or any(
                not isinstance(state.get(key, {}), dict)
                for key in ("loaded", "pending", "coverage", "guard")
            )
        ):
            raise ValueError("Invalid instruction freshness state")
        return state
    paths = sources(runtime, event.get("cwd"))
    current = {str(path): fingerprint(path) for path in paths}
    loaded = current.copy() if startup else {}
    loaded.pop(str(CONVENTIONS), None)
    if startup and runtime == "codex":
        for path in paths[1:]:
            if current[str(path)] is not None:
                loaded.pop(str(path), None)
    state = {"version": 1, "loaded": loaded, "pending": {}, "coverage": {}}
    for source in paths:
        if loaded.get(str(source)) is not None:
            data = source.read_bytes()
            if hashlib.sha256(data).hexdigest() == loaded[str(source)]:
                save_snapshot(event, runtime, source, data)
    save(event, runtime, state)
    return state


def changed_sources(state: dict, runtime: str, cwd: str | None = None) -> list[Path]:
    """Find changed, newly created, removed, or not-yet-loaded sources."""
    changed = []
    paths = sources(runtime, cwd)
    required = paths[:2] if runtime == "copilot" else paths[:1]
    for path in paths:
        current = fingerprint(path)
        if current is None and path in required:
            changed.append(path)
        elif str(path) not in state["loaded"]:
            if current is not None:
                changed.append(path)
        elif state["loaded"][str(path)] != current:
            changed.append(path)
    return changed


def read_path(event: dict) -> Path | None:
    """Recognize bounded Read requests and exact, single-file cat commands."""
    args = event.get("tool_input") or {}
    name = event.get("tool_name")
    raw = None
    if name == "Read":
        start, limit = args.get("offset", 1), args.get("limit")
        if not isinstance(start, int) or isinstance(start, bool) or start < 1:
            return None
        if limit is not None and (
            not isinstance(limit, int) or isinstance(limit, bool) or limit < 1
        ):
            return None
        raw = args.get("file_path")
    elif name in {"Bash", "exec_command"}:
        command = args.get("command", args.get("cmd", ""))
        if not isinstance(command, str) or any(
            character in command for character in "$;|&<>`\n\r"
        ):
            return None
        try:
            words = shlex.split(command)
        except ValueError:
            return None
        if len(words) == 3 and words[:2] == ["cat", "--"]:
            words.pop(1)
        if len(words) == 2 and words[0] == "cat":
            raw = words[1]
    if not isinstance(raw, str):
        return None
    path = Path(raw).expanduser()
    cwd = args.get("workdir") or event.get("cwd") or "."
    return (path if path.is_absolute() else Path(cwd) / path).absolute()


def requested_span(event: dict, data: bytes) -> tuple[int, int, int]:
    """Map a one-based LF line request onto exact original byte boundaries."""
    lines = data.split(b"\n")
    if data.endswith(b"\n"):
        lines.pop()
    starts = [0]
    for line in lines:
        starts.append(min(len(data), starts[-1] + len(line) + 1))
    args = event.get("tool_input") or {}
    first = args.get("offset", 1) if event.get("tool_name") == "Read" else 1
    limit = args.get("limit") if event.get("tool_name") == "Read" else None
    last = len(lines) if limit is None else min(len(lines), first - 1 + limit)
    if first > len(lines) or first > last:
        raise ValueError("Instruction read range is outside the file")
    return starts[first - 1], starts[last], first


def matching_text(text: str, expected: bytes, first: int) -> bool:
    """Require exact raw bytes or one explicitly supported numbered framing."""
    if text.encode() == expected:
        return True
    if not expected:
        return False
    lines = expected.decode().split("\n")
    has_final_lf = lines[-1] == ""
    if has_final_lf:
        lines.pop()
    numbered = "\n".join(f"L{first + index}:{line}" for index, line in enumerate(lines))
    if has_final_lf:
        numbered += "\n"
    return text == numbered


def host_line_count(data: bytes) -> int:
    """Count lines as Claude Read metadata does: LF-separated, so a final LF adds one."""
    return data.count(b"\n") + 1


def add_coverage(state: dict, pending: dict, size: int) -> bool:
    """Merge verified byte intervals and report complete, gap-free coverage."""
    coverage = state.setdefault("coverage", {}).get(pending["path"], {})
    if coverage.get("digest") != pending["digest"]:
        coverage = {"digest": pending["digest"], "intervals": []}
    spans = sorted([*coverage["intervals"], [pending["start"], pending["end"]]])
    merged = []
    for start, end in spans:
        if merged and start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    coverage["intervals"] = merged
    state["coverage"][pending["path"]] = coverage
    return merged == [[0, size]]


def read_key(event: dict) -> str:
    """Pair acknowledgments with a previously allowed read request."""
    payload = {
        "id": event.get("tool_use_id") or event.get("toolCallId"),
        "name": event.get("tool_name"),
        "input": event.get("tool_input"),
    }
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()


def response_text(event: dict, runtime: str) -> str | None:
    """Recognize supported result shapes before exact content verification."""
    response = event.get("tool_response")
    if event.get("is_error") or event.get("truncated") or event.get("success") is False:
        return None
    if runtime == "copilot":
        if not isinstance(response, dict) or response.get("resultType") != "success":
            return None
        if response.get("truncated"):
            return None
        return response.get("textResultForLlm")
    if (
        runtime == "codex"
        and isinstance(response, str)
        and event.get("hook_event_name") == "PostToolUse"
        and event.get("tool_name") == "Bash"
        and read_path(event) is not None
    ):
        return response
    if isinstance(response, str) and event.get("tool_name") == "Read":
        return response
    if not isinstance(response, dict):
        return None
    if response.get("is_error") or response.get("truncated"):
        return None
    file = read_file_metadata(event)
    if file is not None:
        return file.get("content")
    if event.get("tool_name") in {"Bash", "exec_command"}:
        if response.get("exit_code") == 0 or claude_shell_result(event, runtime):
            return response.get("stdout", response.get("output"))
    return None


def read_file_metadata(event: dict) -> dict | None:
    """Return the `file` object of a structured Read result."""
    response = event.get("tool_response")
    file = response.get("file") if isinstance(response, dict) else None
    if event.get("tool_name") != "Read" or not isinstance(file, dict):
        return None
    return file


def claude_shell_result(event: dict, runtime: str) -> bool:
    """Recognize Claude's Bash result, which has no exit code and trims stdout."""
    response = event.get("tool_response")
    return (
        runtime == "claude"
        and event.get("tool_name") == "Bash"
        and isinstance(response, dict)
        and "exit_code" not in response
        and response.get("interrupted") is False
        and response.get("stderr") == ""
    )


def metadata_matches(event: dict, text: str, data: bytes, first: int) -> bool:
    """Require Read range metadata, when present, to agree with text and source."""
    file = read_file_metadata(event)
    if file is None:
        return True
    returned = host_line_count(text.encode())
    return (
        file.get("startLine", first) == first
        and file.get("numLines", returned) == returned
        and file.get("totalLines", host_line_count(data)) == host_line_count(data)
    )


def omits_range_delimiter(event: dict, runtime: str, pending: dict) -> bool:
    """Recognize the single LF omitted by a paired native read."""
    if runtime == "copilot":
        return bool(pending.get("copilot_view_slice")) and native_view_request(event)
    file = read_file_metadata(event) if runtime == "claude" else None
    if file is None:
        return False
    span = [file.get(key) for key in ("startLine", "numLines", "totalLines")]
    if not all(type(value) is int for value in span):
        return False
    start, count, total = span
    return start + count - 1 < total


def returned_range_matches(
    event: dict, runtime: str, pending: dict, text: str, data: bytes,
) -> bool:
    """Match the requested bytes exactly, or with one known host newline trim."""
    expected = data[pending["start"]:pending["end"]]
    first = pending["first"]
    if (
        runtime == "copilot"
        and pending.get("copilot_native_bash")
        and event.get("_copilot_native_bash") is True
    ):
        footer = COPILOT_SHELL_FOOTER.search(text)
        if footer is not None:
            body = text[:footer.start()].encode()
            return footer.group(1) == "0" and body in (expected, expected + b"\n")
    if matching_text(text, expected, first):
        return True
    if expected.endswith(b"\n") and omits_range_delimiter(
        event, runtime, pending,
    ):
        return matching_text(text, expected[:-1], first)
    if claude_shell_result(event, runtime):
        return matching_text(text, expected.rstrip(b"\n"), first)
    return False


def native_view_request(event: dict) -> bool:
    """Validate native whole-file and inclusive-range requests, including EOF."""
    args = event.get("tool_input") or {}
    span = args.get("view_range")
    if event.get("_copilot_native_view") is not True:
        return False
    if span is None:
        return args.get("offset") is None and args.get("limit") is None
    return (
        isinstance(span, list)
        and len(span) == 2
        and all(type(value) is int for value in span)
        and span[0] >= 1
        and (span[1] == -1 or span[1] >= span[0])
        and args.get("offset") == span[0]
        and args.get("limit") == (
            None if span[1] == -1 else span[1] - span[0] + 1
        )
    )


@serialized
def before_tool(event: dict, runtime: str) -> dict | None:
    """Refuse mutations until changed instructions receive a successful full read."""
    if event.get("agent_id"):
        return None
    state = load(event, runtime)
    changed = changed_sources(state, runtime, event.get("cwd"))
    diffs = prepare_diffs(event, runtime, state, changed)
    path = read_path(event)
    if path is not None:
        candidates = [*sources(runtime, event.get("cwd"))]
        # A topic may be read proactively. Never add it to the startup baseline.
        if path.name in task_topics.TOPICS:
            topic = task_topics.REFERENCE / path.name
            candidates.append(topic)
            current = fingerprint(topic)
            if current is not None and state["loaded"].get(str(topic)) != current:
                changed.append(topic)
        diff_source = next(
            (source for source, diff in diffs.items()
             if Path(diff["path"]).resolve() == path.resolve()),
            None,
        )
        match = next(
            (
                source for source in candidates
                if source.resolve() == path.resolve()
            ),
            None,
        )
        if diff_source is not None:
            match = Path(diff_source)
        snapshot_digest = None
        if match is None and changed:
            snapshot_digest = fingerprint(path)
            match = next(
                (source for source in changed if snapshot_digest is not None
                 and fingerprint(source) == snapshot_digest),
                None,
            )
        if match in changed and fingerprint(match) is not None:
            data = path.read_bytes() if diff_source is not None else match.read_bytes()
            digest = hashlib.sha256(data).hexdigest()
            if snapshot_digest is not None and snapshot_digest != digest:
                return None
            start, end, first = requested_span(event, data)
            state["pending"] = {
                key: value for key, value in state["pending"].items()
                if value["path"] != str(match)
                or (value.get("start"), value.get("end")) != (start, end)
            }
            state["pending"][read_key(event)] = {
                "path": str(match),
                "digest": digest,
                "start": start,
                "end": end,
                "first": first,
                **(
                    {"diff_path": str(path), "source_digest": diffs[diff_source]["digest"]}
                    if diff_source is not None else {}
                ),
                "copilot_view_slice": runtime == "copilot"
                and native_view_request(event),
                "copilot_native_bash": runtime == "copilot"
                and event.get("_copilot_native_bash") is True,
                **(
                    {"snapshot_path": str(path), "snapshot_digest": snapshot_digest}
                    if snapshot_digest is not None else {}
                ),
            }
            save(event, runtime, state)
        return None
    unread = []
    for name in sorted(task_topics.required_topics(event)):
        topic = task_topics.REFERENCE / name
        current = fingerprint(topic)
        if current is None or state["loaded"].get(str(topic)) != current:
            unread.append(str(topic))
    if unread:
        return {
            "permissionDecision": "deny",
            "permissionDecisionReason": "TASK INSTRUCTIONS UNREAD: read in full before "
            "this action: " + ", ".join(unread) + ". Use a verified Read or exact cat. "
            "If a file is missing, restore the installed reference. Unrelated work can continue.",
        }
    if not changed or event.get("tool_name") in READ_ONLY_TOOLS:
        return None
    reason = (
        "INSTRUCTIONS CHANGED OR UNREAD: before state-changing work, read:\n"
        + read_requirements(changed, diffs, state, runtime)
        + "\nA path mention or incomplete/truncated/failed result does not acknowledge "
        "them. Use bounded Read chunks with complete returned text, or an exact "
        "`cat <path>` command. Restore "
        "a deleted source. See ~/.config/claude/reference/agent-controls.md for supported result schemas."
    )
    signature = {str(path): fingerprint(path) for path in changed}
    guard = state.get("guard", {})
    if guard.get("signature") != signature:
        guard = {"signature": signature, "denials": 0, "started": time.time()}
    if (
        guard["denials"] >= GATE_MAX_DENIALS
        or time.time() - guard["started"] > GATE_MAX_AGE_S
    ):
        return {
            "additionalContext": "INSTRUCTION FRESHNESS UNGUARDED: bounded gate "
            "exhausted without verified coverage. Instructions remain unread. "
            "Do not claim enforcement or acknowledgment. " + reason,
        }
    guard["denials"] += 1
    state["guard"] = guard
    save(event, runtime, state)
    return {"permissionDecision": "deny", "permissionDecisionReason": reason}


@serialized
def after_tool(event: dict, runtime: str) -> None:
    """Acknowledge only unchanged bytes returned by a paired successful read."""
    if event.get("agent_id"):
        return
    state = load(event, runtime)
    pending = state["pending"].pop(read_key(event), None)
    text = response_text(event, runtime)
    if pending and isinstance(text, str):
        path = Path(pending["path"])
        data = Path(pending.get("diff_path", str(path))).read_bytes()
        current = hashlib.sha256(data).hexdigest()
        if (
            current == pending["digest"]
            and (
                "source_digest" not in pending
                or fingerprint(path) == pending["source_digest"]
            )
            and (
                "snapshot_path" not in pending
                or fingerprint(Path(pending["snapshot_path"])) == pending["snapshot_digest"]
            )
            and metadata_matches(event, text, data, pending["first"])
            and returned_range_matches(event, runtime, pending, text, data)
            and add_coverage(state, pending, len(data))
        ):
            source_data = path.read_bytes()
            acknowledged = pending.get("source_digest", current)
            if hashlib.sha256(source_data).hexdigest() != acknowledged:
                save(event, runtime, state)
                return
            save_snapshot(event, runtime, path, source_data)
            state["loaded"][str(path)] = acknowledged
            if path.parent != task_topics.REFERENCE:
                state.pop("guard", None)
    save(event, runtime, state)


@serialized
def startup_status(event: dict, runtime: str) -> str:
    """Report changes without mistaking a printed digest for a successful read."""
    if event.get("agent_id"):
        return ""
    state = load(
        event, runtime, startup=event.get("instructions_injected") is True,
    )
    if event.get("instructions_injected") or event.get("source") == "compact":
        # Global baselines survive recovery. On-demand texts are not reinjected.
        paths = {str(task_topics.REFERENCE / name) for name in task_topics.TOPICS}
        for key in ("loaded", "coverage"):
            for path in paths:
                state.get(key, {}).pop(path, None)
        state["pending"] = {key: value for key, value in state["pending"].items()
                            if value["path"] not in paths}
        save(event, runtime, state)
    changed = changed_sources(state, runtime, event.get("cwd"))
    if changed:
        diffs = prepare_diffs(event, runtime, state, changed)
        return "GLOBAL INSTRUCTIONS CHANGED OR UNREAD - read:\n" + read_requirements(
            changed, diffs, state, runtime,
        )
    return "GLOBAL INSTRUCTIONS unchanged against this session's loaded baseline"
