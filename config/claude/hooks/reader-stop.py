#!/usr/bin/env python3
"""Hold a reader subagent until it states its escalations, then store them.

A reader that says nothing about what it could not judge looks exactly like one
that judged everything. Requiring an explicit ESCALATE block - "none" included -
makes the omission visible: a missing block sends the reader back once to add
it. The stored entries are announced to the main agent by escalation-notify.py

Fails open: any error lets the subagent stop
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from escalation_state import (  # noqa: E402
    READER_TYPES,
    load,
    parse_block,
    prune_old,
    resolve,
    save,
)

ALLOW = 0
MISSING_BLOCK_REASON = (
    "Your answer has no ESCALATE block. End it with 'ESCALATE: none', or with "
    "'ESCALATE:' followed by one line per range: '- path:start-end - reason'. "
    "Do not repeat the rest of your answer"
)


def main() -> None:
    """Check one reader's final message."""
    event = json.load(sys.stdin)
    agent_type = event.get("agent_type")
    if agent_type not in READER_TYPES:
        return
    entries = parse_block(event.get("last_assistant_message") or "")
    if entries is None:
        if not event.get("stop_hook_active"):
            print(json.dumps({"decision": "block", "reason": MISSING_BLOCK_REASON}))
        return
    if not entries:
        return
    session_id = event["session_id"]
    cwd = event.get("cwd", "")
    stored = load(session_id)
    for entry in entries:
        entry.update(
            path=resolve(entry["path"], cwd),
            agent_type=agent_type,
            is_announced=False,
            denials=0,
        )
        stored.append(entry)
    save(session_id, stored)
    prune_old()


if __name__ == "__main__":
    try:
        main()
    except BaseException:  # noqa: BLE001 - a broken check must never block work
        sys.exit(ALLOW)
