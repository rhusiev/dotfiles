#!/usr/bin/env python3
"""Adapt the existing Claude plan and reader hooks to Copilot's native events."""

from __future__ import annotations

import contextlib
import hashlib
import importlib.util
import io
import json
import re
import sys
from pathlib import Path
from types import ModuleType

SOURCE = Path.home() / ".config" / "claude"
CONFIG = Path(__file__).resolve().parent.parent
SESSION_PREFIX = "copilot-"
TOOL_NAMES = {
    "view": "Read",
    "edit": "Edit",
    "str_replace_editor": "Edit",
    "apply_patch": "Edit",
    "create": "Write",
    "bash": "Bash",
    "powershell": "Bash",
    "task": "Agent",
    "rg": "Grep",
    "glob": "Glob",
    "web_fetch": "WebFetch",
    "web_search": "WebSearch",
}


def load_hook(filename: str) -> ModuleType:
    """Load a shared hook without executing its command-line exception handler."""
    path = SOURCE / "hooks" / filename
    spec = importlib.util.spec_from_file_location(
        "copilot_" + path.stem.replace("-", "_"), path,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load shared hook: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def call_hook(module: ModuleType, event: dict) -> str:
    """Run a shared hook with isolated JSON input and captured output."""
    previous = sys.stdin
    output = io.StringIO()
    try:
        sys.stdin = io.StringIO(json.dumps(event))
        with contextlib.redirect_stdout(output):
            module.main()
    finally:
        sys.stdin = previous
    return output.getvalue().strip()


def result(output: str) -> dict:
    """Translate Claude hook output to Copilot's flat output object."""
    if not output:
        return {}
    parsed = json.loads(output)
    return parsed.get("hookSpecificOutput", parsed)


def normalize(event: dict) -> dict:
    """Translate native tool arguments and isolate Copilot's shared state."""
    session_id = event.get("sessionId") or event.get("session_id")
    if not isinstance(session_id, str) or not re.fullmatch(r"[\w-]+", session_id):
        raise ValueError("Missing or unsafe Copilot session ID")
    name = event.get("toolName", event.get("tool_name", ""))
    if name.startswith("functions."):
        name = name.removeprefix("functions.")
    args = event.get("toolArgs", event.get("tool_input", event.get("arguments"))) or {}
    if isinstance(args, str):
        args = {"input": args} if name == "apply_patch" else json.loads(args)
    if not isinstance(args, dict):
        raise ValueError("Tool arguments must be an object")
    args = args.copy()
    if "path" in args:
        args.setdefault("file_path", args["path"])
    span = args.get("view_range")
    if span is not None:
        first, last = span
        args["offset"] = first
        if last != -1:
            args["limit"] = last - first + 1
    response = event.get("toolResult", event.get("tool_response"))
    if response is None and event.get("success") is True:
        native_result = event.get("result")
        if isinstance(native_result, dict) and isinstance(native_result.get("content"), str):
            response = {
                "resultType": "success",
                "textResultForLlm": native_result["content"],
                "truncated": native_result.get("truncated", False),
            }
    return {
        **event,
        "session_id": SESSION_PREFIX + session_id.removeprefix(SESSION_PREFIX),
        "tool_name": TOOL_NAMES.get(name, name),
        "tool_input": args,
        "_copilot_native_view": name == "view",
        "cwd": event.get("cwd", event.get("workingDirectory", "")),
        "agent_id": event.get("agentId", event.get("agent_id")),
        "agent_type": event.get("agentName") or event.get("agentType")
        or event.get("agent_type", ""),
        "last_assistant_message": event.get(
            "response", event.get("last_assistant_message", ""),
        ),
        "tool_response": response,
    }


def instruction_status(session_id: str) -> str:
    """Report changes to the entry point and all three shared instruction files."""
    from instruction_state import fingerprint
    from plan_state import remember_instructions

    paths = [
        CONFIG / "copilot-instructions.md",
        SOURCE / "CLAUDE.md",
        SOURCE / "work.md",
        SOURCE / "ste.md",
    ]
    current = hashlib.blake2b(
        json.dumps({str(path): fingerprint(path) for path in paths}).encode(),
    ).hexdigest()[:12]
    previous = remember_instructions(session_id, current)
    verdict = (
        "CHANGED - re-read all four files"
        if previous and previous != current
        else "observed digest unchanged - see the separate freshness status"
    )
    return (
        f"GLOBAL INSTRUCTIONS: {', '.join(str(path) for path in paths)} "
        f"(blake2b {current}), {verdict}"
    )


def startup(event: dict, *, injected: bool = False) -> str:
    """Generate the shared recovery header without pruning other sessions' data."""
    from instruction_state import startup_status

    if event["agent_id"]:
        return ""
    module = load_hook("session-start.py")
    module.prune_bindings = lambda: 0
    module.prune_topics = lambda: []
    module.instructions_line = instruction_status
    module.print_imported_instructions = lambda: None
    header = call_hook(module, event)
    if "GLOBAL INSTRUCTIONS:" not in header:
        header += "\n" + instruction_status(event["session_id"])
    return header + "\n" + startup_status(
        {**event, "instructions_injected": injected}, "copilot",
    )


def recovery_path(event: dict) -> Path:
    """Locate a pending post-compaction recovery header."""
    from plan_state import ROOT

    return ROOT / ".copilot-recovery" / f"{event['session_id']}.json"


def pre_compact(event: dict) -> dict:
    """Save a bounded transcript tail and arm recovery before context is lost."""
    from plan_state import write_atomically

    if event["agent_id"]:
        return {}
    transcript = event.get("transcriptPath") or event.get("transcript_path")
    if not transcript:
        session_id = event["session_id"].removeprefix(SESSION_PREFIX)
        transcript = CONFIG / "session-state" / session_id / "events.jsonl"
    call_hook(
        load_hook("pre-compact.py"),
        {**event, "transcript_path": str(transcript)},
    )
    header = startup({**event, "source": "compact"})
    write_atomically(
        recovery_path(event), json.dumps({"header": header}).encode(),
    )
    return {}


def edit_paths(event: dict) -> list[str]:
    """Return all targets, including both sides of a patch move."""
    args = event["tool_input"]
    paths = [args[key] for key in ("file_path", "notebook_path") if args.get(key)]
    patch = args.get("input") or args.get("patch") or args.get("patch_text")
    if isinstance(patch, str):
        paths.extend(re.findall(
            r"^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$",
            patch, re.MULTILINE,
        ))
    return list(dict.fromkeys(paths))


def pre_tool(event: dict) -> dict:
    """Enforce the plan gate, large-read routing, and escalated-file edit gate."""
    if event["agent_id"]:
        return {}
    from instruction_state import before_tool

    try:
        freshness = before_tool(event, "copilot") or {}
    except (OSError, ValueError, KeyError, TypeError) as error:
        from instruction_state import READ_ONLY_TOOLS, read_path

        message = f"INSTRUCTION FRESHNESS FAILED: {type(error).__name__}: {error}"
        print(message, file=sys.stderr)
        freshness = (
            {} if event["tool_name"] in READ_ONLY_TOOLS or read_path(event)
            else {"permissionDecision": "deny", "permissionDecisionReason": message}
        )
    if freshness.get("permissionDecision") == "deny":
        return freshness
    output = result(call_hook(load_hook("pre-tool-use.py"), event))
    if output.get("permissionDecision") == "deny":
        pending = recovery_path(event)
        if pending.is_file():
            header = json.loads(pending.read_text())["header"]
            output["permissionDecisionReason"] += "\n\n" + header
        return output
    if event["tool_name"] == "Read":
        module = load_hook("large-read-gate.py")
        module.EXEMPT_ROOTS += (CONFIG,)
        output = result(call_hook(module, event))
        if output.get("permissionDecision") == "deny":
            output["permissionDecisionReason"] = (
                output["permissionDecisionReason"]
                .replace("Agent with subagent_type", "the custom-agent tool with")
                .replace(
                    "Read again with offset/limit",
                    "use view again with view_range",
                )
            )
        return output
    if event["tool_name"] in {"Edit", "Write", "MultiEdit", "NotebookEdit"}:
        module = load_hook("escalation-edit-gate.py")
        reasons = []
        for path in edit_paths(event):
            candidate = {**event, "tool_input": {**event["tool_input"], "file_path": path}}
            output = result(call_hook(module, candidate))
            if output.get("permissionDecision") == "deny":
                reasons.append(output["permissionDecisionReason"])
        if reasons:
            return {
                "permissionDecision": "deny",
                "permissionDecisionReason": "\n".join(reasons),
            }
    return freshness


def post_tool(event: dict) -> dict:
    """Announce reader escalations and deliver the saved recovery header."""
    if event["agent_id"]:
        return {}
    from instruction_state import after_tool

    after_tool(event, "copilot")
    output = result(call_hook(load_hook("escalation-notify.py"), event))
    pending = recovery_path(event)
    if pending.is_file():
        header = json.loads(pending.read_text())["header"]
        output["additionalContext"] = "\n\n".join(
            text for text in [header, output.get("additionalContext", "")] if text
        )
        pending.unlink()
    return output


def reader_stop(event: dict) -> dict:
    """Require an explicit escalation block, with at most one retry per reader."""
    from escalation_state import READER_TYPES, parse_block
    from plan_state import ROOT, write_atomically

    if event["agent_type"] not in READER_TYPES:
        return {}
    agent_id = event["agent_id"] or event["agent_type"]
    token = hashlib.blake2b(str(agent_id).encode()).hexdigest()[:16]
    retry = ROOT / ".copilot-reader-retries" / f"{event['session_id']}-{token}"
    has_block = parse_block(event["last_assistant_message"]) is not None
    event["stop_hook_active"] = retry.exists()
    output = result(call_hook(load_hook("reader-stop.py"), event))
    if output.get("decision") == "block":
        write_atomically(retry, b"retried\n")
    elif has_block:
        retry.unlink(missing_ok=True)
    return output


def main() -> None:
    """Dispatch one native hook and report adapter errors without deadlocking."""
    action = sys.argv[1]
    try:
        sys.path.insert(0, str(SOURCE / "hooks"))
        event = normalize(json.load(sys.stdin))
        if action == "sessionStart":
            output = {"additionalContext": startup(event, injected=True)}
        elif action == "preCompact":
            output = pre_compact(event)
        elif action == "preToolUse":
            output = pre_tool(event)
        elif action == "postToolUse":
            output = post_tool(event)
        elif action == "subagentStop":
            output = reader_stop(event)
        else:
            raise ValueError(f"Unsupported hook event: {action}")
    except Exception as error:
        message = f"COPILOT PLAN HOOK FAILED ({action}): {type(error).__name__}: {error}"
        print(message, file=sys.stderr)
        if action in {"sessionStart", "postToolUse"}:
            output = {"additionalContext": message}
        else:
            output = {}
    print(json.dumps(output))


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    main()
