"""Track global instruction changes separately from the legacy plan read gate."""

from __future__ import annotations

from collections.abc import Callable
import fcntl
from functools import wraps
import hashlib
import json
import re
import shlex
import time
from pathlib import Path
from typing import TypeVar

from plan_state import (
    GATE_MAX_AGE_S,
    GATE_MAX_DENIALS,
    ROOT,
    codex_home,
    write_atomically,
)

READ_ONLY_TOOLS = frozenset({"Read", "Glob", "Grep", "LS", "WebFetch", "WebSearch"})
RUNTIMES = frozenset({"claude", "codex", "copilot"})
ReturnT = TypeVar("ReturnT")


def sources(runtime: str) -> list[Path]:
    """Return the instruction sources loaded by one installed runtime."""
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
    return [*primary[runtime], shared / "work.md", shared / "ste.md"]


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
    """Atomically save observed acknowledgements and pending read identities."""
    write_atomically(state_path(event, runtime), json.dumps(state).encode())


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
    current = {str(path): fingerprint(path) for path in sources(runtime)}
    loaded = current.copy() if startup else {}
    if startup and runtime == "codex":
        for path in sources(runtime)[1:]:
            if current[str(path)] is not None:
                loaded.pop(str(path), None)
    state = {"version": 1, "loaded": loaded, "pending": {}, "coverage": {}}
    save(event, runtime, state)
    return state


def changed_sources(state: dict, runtime: str) -> list[Path]:
    """Find changed, newly created, removed, or not-yet-loaded sources."""
    changed = []
    paths = sources(runtime)
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


def line_count(data: bytes) -> int:
    """Count LF records without treating carriage returns as extra lines."""
    return data.count(b"\n") + int(bool(data) and not data.endswith(b"\n"))


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
    """Pair acknowledgements with a previously allowed read request."""
    payload = {
        "id": event.get("tool_use_id") or event.get("toolCallId"),
        "name": event.get("tool_name"),
        "input": event.get("tool_input"),
    }
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()


def response_text(event: dict, runtime: str) -> str | None:
    """Accept only explicit supported successful result shapes."""
    response = event.get("tool_response")
    if event.get("is_error") or event.get("truncated") or event.get("success") is False:
        return None
    if runtime == "copilot":
        if not isinstance(response, dict) or response.get("resultType") != "success":
            return None
        if response.get("truncated"):
            return None
        return response.get("textResultForLlm")
    if isinstance(response, str) and event.get("tool_name") == "Read":
        return response
    if not isinstance(response, dict):
        return None
    if response.get("is_error") or response.get("truncated"):
        return None
    file = response.get("file")
    if event.get("tool_name") == "Read" and isinstance(file, dict):
        return file.get("content")
    if event.get("tool_name") in {"Bash", "exec_command"}:
        if response.get("exit_code") == 0:
            return response.get("stdout", response.get("output"))
    return None


def native_view_slice(event: dict, end: int, size: int) -> bool:
    """Recognize only a paired native Copilot range ending before source EOF."""
    args = event.get("tool_input") or {}
    span = args.get("view_range")
    return (
        event.get("_copilot_native_view") is True
        and isinstance(span, list)
        and len(span) == 2
        and all(type(value) is int for value in span)
        and 1 <= span[0] <= span[1]
        and args.get("offset") == span[0]
        and args.get("limit") == span[1] - span[0] + 1
        and end < size
    )


@serialized
def before_tool(event: dict, runtime: str) -> dict | None:
    """Refuse mutations until changed instructions receive a successful full read."""
    if event.get("agent_id"):
        return None
    state = load(event, runtime)
    changed = changed_sources(state, runtime)
    path = read_path(event)
    if path is not None:
        match = next(
            (source for source in sources(runtime) if source.resolve() == path.resolve()),
            None,
        )
        snapshot_digest = None
        if match is None and changed:
            snapshot_digest = fingerprint(path)
            match = next(
                (source for source in changed if snapshot_digest is not None
                 and fingerprint(source) == snapshot_digest),
                None,
            )
        if match in changed and fingerprint(match) is not None:
            data = match.read_bytes()
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
                "copilot_view_slice": runtime == "copilot"
                and native_view_slice(event, end, len(data)),
                **(
                    {"snapshot_path": str(path), "snapshot_digest": snapshot_digest}
                    if snapshot_digest is not None else {}
                ),
            }
            save(event, runtime, state)
        return None
    if not changed or event.get("tool_name") in READ_ONLY_TOOLS:
        return None
    reason = (
        "INSTRUCTIONS CHANGED OR UNREAD: read these complete files before "
        "state-changing work: "
        + ", ".join(str(path) for path in changed)
        + ". A path mention or incomplete/truncated/failed result does not acknowledge "
        "them. Use bounded Read chunks with complete returned text, or an exact "
        "`cat <path>` command. Restore "
        "a deleted source. See docs/agent-controls.md for supported result schemas."
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
            "Do not claim enforcement or acknowledgement. " + reason,
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
        data = path.read_bytes()
        current = hashlib.sha256(data).hexdigest()
        expected = data[pending["start"]:pending["end"]]
        response = event.get("tool_response")
        file = response.get("file") if isinstance(response, dict) else None
        metadata_matches = not isinstance(file, dict) or (
            file.get("startLine", pending["first"]) == pending["first"]
            and file.get("numLines", line_count(expected)) == line_count(expected)
            and file.get("totalLines", line_count(data)) == line_count(data)
        )
        if (
            current == pending["digest"]
            and (
                "snapshot_path" not in pending
                or fingerprint(Path(pending["snapshot_path"])) == pending["snapshot_digest"]
            )
            and metadata_matches
            and (
                matching_text(text, expected, pending["first"])
                or (
                    runtime == "copilot" and pending.get("copilot_view_slice")
                    and native_view_slice(event, pending["end"], len(data))
                    and expected.endswith(b"\n")
                    and matching_text(text, expected[:-1], pending["first"])
                )
            )
            and add_coverage(state, pending, len(data))
        ):
            state["loaded"][str(path)] = current
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
    changed = changed_sources(state, runtime)
    if changed:
        return "GLOBAL INSTRUCTIONS CHANGED OR UNREAD - read: " + ", ".join(
            str(path) for path in changed
        )
    return "GLOBAL INSTRUCTIONS unchanged against this session's loaded baseline"
