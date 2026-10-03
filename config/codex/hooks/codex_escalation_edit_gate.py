#!/usr/bin/env python3
"""Block Codex patches to files with uncleared reader escalations."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config" / "claude" / "hooks"))

from escalation_state import EDIT_MAX_DENIALS, describe, load, resolve, save  # noqa: E402

ALLOW = 0
PATCH_PATH = re.compile(r"^\*\*\* (?:Add|Update|Delete) File: (.+)$", re.MULTILINE)


def main() -> None:
    """Deny an apply_patch call that touches an escalated file."""
    event = json.load(sys.stdin)
    if event.get("agent_id"):
        return
    patch = (event.get("tool_input") or {}).get("command", "")
    paths = {resolve(raw_path, event.get("cwd", "")) for raw_path in PATCH_PATH.findall(patch)}
    if not paths:
        return
    session_id = event.get("session_id", "")
    entries = load(session_id)
    blocking = [entry for entry in entries if entry["path"] in paths]
    if not blocking:
        return
    for entry in blocking:
        entry["denials"] += 1
    remaining = [entry for entry in entries if entry["denials"] <= EDIT_MAX_DENIALS]
    save(session_id, remaining)
    still_blocking = [entry for entry in blocking if entry in remaining]
    if not still_blocking:
        return
    reason = "BLOCKED: read each escalated range yourself before editing: " + " ".join(f"[{describe(entry)}]" for entry in still_blocking)
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}))


if __name__ == "__main__":
    try:
        main()
    except BaseException:
        sys.exit(ALLOW)
