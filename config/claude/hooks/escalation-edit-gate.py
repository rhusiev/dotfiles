#!/usr/bin/env python3
"""Hold edits to a file a reader escalated until the main agent has read it.

An escalation says a reader's summary is not good enough for part of a file.
Editing that file on the strength of the summary is exactly the failure the
escalation exists to prevent, so the edit is refused until a main-agent Read
covers the flagged range (escalation-notify.py clears it then)

Fails open: gives up on an entry after EDIT_MAX_DENIALS refusals, and any
error allows the call
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from escalation_state import (  # noqa: E402
    EDIT_MAX_DENIALS,
    describe,
    load,
    resolve,
    save,
)

ALLOW = 0


def target_path(event: dict) -> str | None:
    """The file an editing tool is about to change."""
    tool_input = event.get("tool_input") or {}
    raw_path = tool_input.get("file_path") or tool_input.get("notebook_path")
    return resolve(raw_path, event.get("cwd", "")) if raw_path else None


def deny(blocking: list[dict]) -> None:
    """Refuse the edit and list the ranges still to read."""
    reason = " ".join(
        [
            (
                "BLOCKED: a reader escalated ranges in this file and you have not "
                "read them yourself. Read each with offset/limit, then retry the edit:"
            ),
            *(f"[{describe(entry)}]" for entry in blocking),
        ],
    )
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        },
    }
    print(json.dumps(output))


def main() -> None:
    """Allow or deny one main-agent edit."""
    event = json.load(sys.stdin)
    if event.get("agent_id"):
        return
    path = target_path(event)
    session_id = event.get("session_id", "")
    entries = load(session_id)
    blocking = [entry for entry in entries if entry["path"] == path]
    if not path or not blocking:
        return
    for entry in blocking:
        entry["denials"] += 1
    remaining = [entry for entry in entries if entry["denials"] <= EDIT_MAX_DENIALS]
    save(session_id, remaining)
    still_blocking = [entry for entry in blocking if entry in remaining]
    if still_blocking:
        deny(still_blocking)


if __name__ == "__main__":
    try:
        main()
    except BaseException:  # noqa: BLE001 - a broken gate must never block work
        sys.exit(ALLOW)
