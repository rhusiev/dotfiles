#!/usr/bin/env python3
"""Keep whole large files out of the main context by routing them to readers.

A full Read of a big file puts every line into the most expensive context in
the session, usually to answer a question about a few of them. This refuses
such reads in the main agent and points at the reader subagents, whose context
is cheap and thrown away. Targeted reads (offset or limit) pass, so editing
still works. Subagents are never gated - they are where the reading belongs

Like the plan gate, it fails open: any error allows the call
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ALLOW = 0
DEFAULT_MIN_LINES = 350
MIN_LINES_ENV = "LARGE_READ_MIN_LINES"
BINARY_SNIFF_BYTES = 8192
EXEMPT_ROOTS = (
    Path.home() / ".local" / "share" / "ai-sessions",
    Path.home() / ".local" / "share" / "ai-guides",
    Path.home() / ".config" / "claude",
    Path.home() / ".config" / "codex",
)


def min_lines() -> int:
    """The threshold, overridable through the environment."""
    value = os.environ.get(MIN_LINES_ENV, "")
    return int(value) if value.isdigit() else DEFAULT_MIN_LINES


def is_exempt(path: Path) -> bool:
    """Plans, guides and agent config must always be readable whole."""
    resolved = path.resolve()
    return any(resolved.is_relative_to(root.resolve()) for root in EXEMPT_ROOTS)


def count_text_lines(path: Path) -> int | None:
    """Line count of a text file, or None for binaries (images, PDFs)."""
    with path.open("rb") as stream:
        head = stream.read(BINARY_SNIFF_BYTES)
        if b"\0" in head:
            return None
        return head.count(b"\n") + sum(chunk.count(b"\n") for chunk in stream)


def deny(lines: int, threshold: int) -> None:
    """Refuse the read and say what to do instead."""
    reason = (
        f"BLOCKED: whole-file Read of a {lines}-line file (threshold {threshold}). "
        "Delegate it: Agent with subagent_type careful-reader (needs understanding; "
        "the default) or bulk-reader (mechanical: exports, definitions, shapes). "
        "Give it the paths and one precise question. If you need exact lines to "
        "edit, Read again with offset/limit for just that section"
    )
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


def main() -> None:
    """Allow or deny one Read call."""
    event = json.load(sys.stdin)
    if event.get("agent_id"):
        return
    tool_input = event.get("tool_input") or {}
    if tool_input.get("offset") is not None or tool_input.get("limit") is not None:
        return
    raw_path = tool_input.get("file_path")
    if not raw_path:
        return
    path = Path(raw_path).expanduser()
    if not path.is_file() or is_exempt(path):
        return
    threshold = min_lines()
    lines = count_text_lines(path)
    if lines is not None and lines > threshold:
        deny(lines, threshold)


if __name__ == "__main__":
    try:
        main()
    except BaseException:  # noqa: BLE001 - a broken gate must never block work
        sys.exit(ALLOW)
