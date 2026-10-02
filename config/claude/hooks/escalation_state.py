"""Shared state for reader escalations: parsing, storage and range matching.

A reader subagent ends every answer with an ESCALATE block naming the ranges it
could not judge at its level. Those ranges are stored per session so the main
agent is told about them even when the reader ran in the background, and so an
edit to an escalated file can be held until the main agent has read the range
itself
"""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

from plan_state import ROOT, write_atomically

ESCALATIONS = ROOT / ".escalations"
READER_TYPES = frozenset({"bulk-reader", "careful-reader", "deep-reader"})
STATE_MAX_AGE_S = 30 * 86400
EDIT_MAX_DENIALS = 2

_HEADER = re.compile(r"^\W*ESCALATE\W*:?\s*(?P<rest>.*)$", re.IGNORECASE)
_ENTRY = re.compile(
    r"^\s*[-*\d.)]*\s*`?(?P<path>[^\s`:]+):(?P<start>\d+)(?:-(?P<end>\d+))?`?"
    r"\s*[-:]*\s*(?P<reason>.*)$",
)
_NONE = re.compile(r"^\W*none\b", re.IGNORECASE)


def parse_block(message: str) -> list[dict] | None:
    """Escalations from a reader's final message.

    Returns:
        The entries (possibly empty for "ESCALATE: none"), or None when the
        message has no ESCALATE block at all
    """
    lines = message.splitlines()
    for index in range(len(lines) - 1, -1, -1):
        header = _HEADER.match(lines[index])
        if header:
            return _entries(header.group("rest"), lines[index + 1 :])
    return None


def _entries(rest: str, following: list[str]) -> list[dict]:
    """Parse the entries of one ESCALATE block."""
    if _NONE.match(rest):
        return []
    entries = []
    for line in [rest, *following]:
        match = _ENTRY.match(line)
        if not match:
            continue
        start = int(match.group("start"))
        entries.append(
            {
                "path": match.group("path"),
                "start": start,
                "end": int(match.group("end") or start),
                "reason": match.group("reason").strip(),
            },
        )
    return entries


def resolve(path: str, cwd: str) -> str:
    """Absolute form of a path as the tools would see it."""
    candidate = Path(path).expanduser()
    if not candidate.is_absolute():
        candidate = Path(cwd or ".") / candidate
    return str(candidate.resolve())


def state_path(session_id: str) -> Path:
    """Where this session's escalations live."""
    return ESCALATIONS / f"{session_id}.json"


def load(session_id: str) -> list[dict]:
    """This session's stored escalations, or an empty list."""
    try:
        return json.loads(state_path(session_id).read_text())
    except (OSError, json.JSONDecodeError):
        return []


def save(session_id: str, entries: list[dict]) -> None:
    """Persist this session's escalations, dropping the file when empty."""
    if not entries:
        state_path(session_id).unlink(missing_ok=True)
        return
    write_atomically(state_path(session_id), json.dumps(entries).encode())


def prune_old() -> None:
    """Drop state left behind by sessions that ended long ago."""
    if not ESCALATIONS.is_dir():
        return
    cutoff = time.time() - STATE_MAX_AGE_S
    for entry in ESCALATIONS.glob("*.json"):
        if entry.stat().st_mtime < cutoff:
            entry.unlink(missing_ok=True)


def overlaps(entry: dict, offset: int | None, limit: int | None) -> bool:
    """Whether a Read with this offset/limit covers the escalated range."""
    if offset is None and limit is None:
        return True
    first = offset or 1
    if limit is None:
        return first <= entry["end"]
    return first <= entry["end"] and entry["start"] < first + limit


def describe(entry: dict) -> str:
    """One line naming an escalated range and why."""
    return f"{entry['path']}:{entry['start']}-{entry['end']} ({entry['agent_type']}): {entry['reason']}"
