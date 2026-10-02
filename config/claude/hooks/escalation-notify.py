#!/usr/bin/env python3
"""Tell the main agent about reader escalations, and clear them once it reads.

Runs after every main-agent tool call. New escalations are announced once, as
context separate from the reader's answer, so they cannot be buried in it or
missed when the reader ran in the background. A Read by the main agent that
covers an escalated range clears it

Fails open: any error is ignored
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from escalation_state import describe, load, overlaps, resolve, save  # noqa: E402

ALLOW = 0


def clear_read(entries: list[dict], event: dict) -> list[dict]:
    """Drop escalations the main agent has just read for itself."""
    tool_input = event.get("tool_input") or {}
    raw_path = tool_input.get("file_path")
    if event.get("tool_name") != "Read" or not raw_path:
        return entries
    path = resolve(raw_path, event.get("cwd", ""))
    offset, limit = tool_input.get("offset"), tool_input.get("limit")
    return [
        entry
        for entry in entries
        if entry["path"] != path or not overlaps(entry, offset, limit)
    ]


def announce(entries: list[dict]) -> None:
    """Emit the not-yet-announced escalations and mark them announced."""
    fresh = [entry for entry in entries if not entry["is_announced"]]
    if not fresh:
        return
    for entry in fresh:
        entry["is_announced"] = True
    lines = [
        (
            "READER ESCALATIONS - a reader flagged these ranges as needing judgement "
            "above its level. Do not act on its answer for them. Read each range "
            "yourself (Read with offset/limit), or send it to a stronger reader. "
            "Edits to these files are held until you have read the range:"
        ),
        *(f"- {describe(entry)}" for entry in fresh),
    ]
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": "\n".join(lines),
        },
    }
    print(json.dumps(output))


def main() -> None:
    """Process one main-agent tool call."""
    event = json.load(sys.stdin)
    if event.get("agent_id"):
        return
    session_id = event.get("session_id", "")
    entries = load(session_id)
    if not entries:
        return
    remaining = clear_read(entries, event)
    announce(remaining)
    save(session_id, remaining)


if __name__ == "__main__":
    try:
        main()
    except BaseException:  # noqa: BLE001 - a broken notifier must never block work
        sys.exit(ALLOW)
