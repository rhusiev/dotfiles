#!/usr/bin/env python3
"""Refuse tool calls until this session has read its plan from disk.

An instruction can be overlooked; a wall cannot. SessionStart arms a gate
whenever a plan is bound, and this hook denies tool calls until one of them
names the plan file. That turns "re-read the plan after compaction" from a rule
the agent has to remember into the only move available

The gate fails open on purpose. A deadlocked session is worse than the bug it
prevents, so it arms only when a plan is actually bound, disarms itself after a
few denials and after an hour, and treats any internal error as permission to
proceed. The worst case is one wasted round trip
"""

from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from plan_state import (  # noqa: E402
    GATE_MAX_AGE_S,
    GATE_MAX_DENIALS,
    disarm_gate,
    load_gate,
    write_atomically,
)
from plan_state import gate_path as gate_file  # noqa: E402

ALLOW = 0


def mentions(payload: object, needle: str) -> bool:
    """Whether a tool input names this path anywhere inside it.

    The input is walked rather than string-matched as a whole, so a Read with
    ``file_path`` and a Bash with ``cat <path>`` both satisfy the gate. That is
    deliberate: the point is a forcing function, not an adversarial control.
    """
    if isinstance(payload, str):
        return needle in payload
    if isinstance(payload, dict):
        return any(mentions(value, needle) for value in payload.values())
    if isinstance(payload, list):
        return any(mentions(value, needle) for value in payload)
    return False


def deny(reason: str) -> None:
    """Refuse this tool call and tell the agent exactly how to clear the gate."""
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                },
            },
        ),
    )


def denial_reason(gate: dict) -> str:
    """The message the agent sees in place of its tool result."""
    plan = gate["plan"]
    tail = gate.get("tail")
    lines = [
        "BLOCKED: you have not read this session's plan from disk yet.",
        f"Read it now, and nothing else first: cat {plan}",
    ]
    if tail:
        lines.append(
            f"Then read {tail}, merge current task state into the plan, "
            "and delete that checkpoint.",
        )
    if gate.get("source") == "compact":
        lines.append(
            "This session was compacted. The plan file outranks the summary "
            "and outranks your recollection.",
        )
    lines.append(
        "The plan body is not in your context: the SessionStart channel "
        "truncates, so it was never sent. This gate clears as soon as a tool "
        "call names the plan path.",
    )
    return " ".join(lines)


def main() -> None:
    """Allow or deny one tool call, failing open on anything unexpected."""
    event = json.load(sys.stdin)
    session_id = event.get("session_id", "")
    gate = load_gate(session_id)
    if gate is None or "plan" not in gate:
        return

    age_s = datetime.now().timestamp() - gate.get("armed_at", 0)
    if age_s > GATE_MAX_AGE_S:
        disarm_gate(session_id)
        return

    if mentions(event.get("tool_input"), gate["plan"]):
        disarm_gate(session_id)
        return

    denials = int(gate.get("denials", 0)) + 1
    if denials > GATE_MAX_DENIALS:
        disarm_gate(session_id)
        print(
            "PLAN READ GATE gave up after "
            f"{GATE_MAX_DENIALS} refusals - proceeding unguarded. "
            f"You still have not read {gate['plan']}",
            file=sys.stderr,
        )
        return

    gate["denials"] = denials
    write_atomically(gate_file(session_id), json.dumps(gate).encode())
    deny(denial_reason(gate))


if __name__ == "__main__":
    try:
        main()
    except BaseException:  # noqa: BLE001 - a broken gate must never block work
        sys.exit(ALLOW)
