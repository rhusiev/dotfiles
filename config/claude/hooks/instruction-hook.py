#!/usr/bin/env python3
"""Dispatch supported instruction-freshness events without changing the plan gate."""

from __future__ import annotations

import json
import sys

from instruction_state import (
    READ_ONLY_TOOLS,
    after_tool,
    before_tool,
    read_path,
    startup_status,
)


def main() -> None:
    """Handle a supported runtime event and expose failures explicitly."""
    runtime, phase = sys.argv[1:]
    event = json.load(sys.stdin)
    output = {}
    try:
        if phase == "start":
            message = startup_status({**event, "instructions_injected": True}, runtime)
            output = {"additionalContext": message}
        elif phase == "pre":
            output = before_tool(event, runtime) or {}
        elif phase == "post":
            after_tool(event, runtime)
        else:
            raise ValueError("Unsupported instruction hook event")
    except (OSError, ValueError, KeyError, TypeError) as error:
        message = f"INSTRUCTION FRESHNESS FAILED: {type(error).__name__}: {error}"
        print(message, file=sys.stderr)
        if phase == "pre" and not event.get("agent_id"):
            if event.get("tool_name") not in READ_ONLY_TOOLS and read_path(event) is None:
                output = {
                    "permissionDecision": "deny",
                    "permissionDecisionReason": message,
                }
        else:
            output = {"additionalContext": message}
    if output:
        output = {
            "hookSpecificOutput": {
                "hookEventName": {
                    "pre": "PreToolUse", "post": "PostToolUse", "start": "SessionStart",
                }.get(phase, phase),
                **output,
            },
        }
        print(json.dumps(output))


if __name__ == "__main__":
    main()
