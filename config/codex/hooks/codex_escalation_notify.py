#!/usr/bin/env python3
"""Announce reader escalations and clear them after targeted Codex shell reads."""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path.home() / ".config" / "claude" / "hooks"))

from escalation_state import covers, describe, load, save  # noqa: E402
from codex_read_command import parse_reads  # noqa: E402

ALLOW = 0


def main() -> None:
    """Process one main-agent shell call."""
    event = json.load(sys.stdin)
    if event.get("agent_id"):
        return
    session_id = event.get("session_id", "")
    entries = load(session_id)
    if not entries:
        return
    tool_input = event.get("tool_input") or {}
    reads = parse_reads(
        tool_input.get("cmd", tool_input.get("command", "")),
        tool_input.get("workdir") or event.get("cwd", ""),
    )
    for path, start, limit in reads:
        entries = [
            entry
            for entry in entries
            if entry["path"] != str(path) or not covers(entry, start, limit)
        ]
    fresh = [entry for entry in entries if not entry["is_announced"]]
    for entry in fresh:
        entry["is_announced"] = True
    if fresh:
        message = "READER ESCALATIONS - read these ranges yourself or send them to a stronger reader before acting or editing:\n" + "\n".join(f"- {describe(entry)}" for entry in fresh)
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": message}}))
    save(session_id, entries)


if __name__ == "__main__":
    try:
        main()
    except BaseException:
        sys.exit(ALLOW)
