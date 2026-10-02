#!/usr/bin/env python3
"""Shared state between the plan hooks: bindings, digests and the read gate.

The gate exists because the SessionStart channel truncates. A plan printed into
context can arrive as its first two kilobytes with no marker the agent can see,
so the agent believes it has the plan and does not. Nothing here prints a plan
body; the hooks print a pointer and the gate makes reading it the only thing
the session can do first.
"""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path.home() / "ai-sessions"
BY_SESSION = ROOT / ".by-session"
GATES = ROOT / ".gates"
STATE = ROOT / ".state"
CHECKPOINT_FILENAME = "pre-compact-tail.jsonl"
PLAN_FILENAME = "plan.md"

DIGEST_CHARS = 12
GATE_MAX_DENIALS = 4
GATE_MAX_AGE_S = 3600

CLAUDE_INSTRUCTIONS = Path.home() / ".config" / "claude" / "CLAUDE.md"
CODEX_INSTRUCTIONS = Path.home() / ".config" / "codex" / "AGENTS.md"


def digest(path: Path) -> str:
    """Short blake2b of a file, so a stale copy in context is detectable.

    Returns:
        Hex digest truncated to DIGEST_CHARS, or "unreadable"
    """
    try:
        return hashlib.blake2b(path.read_bytes()).hexdigest()[:DIGEST_CHARS]
    except OSError:
        return "unreadable"


def describe(path: Path) -> str:
    """One line of size, line count, digest and mtime for a file."""
    try:
        data = path.read_bytes()
        stamp = datetime.fromtimestamp(path.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
    except OSError:
        return "(unreadable)"
    lines = data.count(b"\n") + (1 if data and not data.endswith(b"\n") else 0)
    return (
        f"{len(data)} bytes, {lines} lines, "
        f"blake2b {hashlib.blake2b(data).hexdigest()[:DIGEST_CHARS]}, "
        f"modified {stamp}"
    )


def plan_for(session_id: str) -> Path | None:
    """Resolve this session's plan file through its binding, or None.

    Raises:
        ValueError: When the binding names a path outside the sessions root
    """
    binding = BY_SESSION / session_id
    if not session_id or not binding.is_file():
        return None
    try:
        topic = binding.read_text().strip()
    except OSError:
        return None
    if not topic:
        return None
    root = ROOT.resolve()
    topic_dir = (ROOT / topic).resolve()
    if not topic_dir.is_relative_to(root) or topic_dir == root:
        raise ValueError(f"unsafe topic binding for session {session_id}")
    plan = topic_dir / PLAN_FILENAME
    return plan if plan.is_file() else None


def write_atomically(destination: Path, data: bytes) -> None:
    """Replace a file only after its complete contents reach disk."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
            temporary.replace(destination)
        except BaseException:
            temporary.unlink(missing_ok=True)
            raise


def gate_path(session_id: str) -> Path:
    """Where this session's read gate lives."""
    return GATES / f"{session_id}.json"


def arm_gate(session_id: str, plan: Path, source: str, tail: Path | None) -> None:
    """Require this session to read its plan from disk before doing anything else."""
    payload = {
        "plan": str(plan),
        "plan_digest": digest(plan),
        "tail": str(tail) if tail else None,
        "source": source,
        "armed_at": datetime.now().timestamp(),
        "denials": 0,
    }
    write_atomically(gate_path(session_id), json.dumps(payload).encode())


def disarm_gate(session_id: str) -> None:
    """Drop the gate, letting the session proceed normally."""
    gate_path(session_id).unlink(missing_ok=True)


def load_gate(session_id: str) -> dict | None:
    """Read this session's gate, or None when there is none or it is unusable."""
    try:
        return json.loads(gate_path(session_id).read_text())
    except (OSError, json.JSONDecodeError):
        return None


def remember_instructions(session_id: str, current: str) -> str | None:
    """Record the instruction-file digest this session was last told about.

    The global instruction file is already injected into context by the host on
    every session, so re-reading 34 kilobytes of it on each compaction buys
    almost nothing. What it does buy is catching an edit made mid-session - and
    that is a digest comparison, not a read. This remembers the digest so the
    header can say "unchanged" and spare the read.

    Args:
        session_id: Session to remember against
        current: Digest of the instruction file as it is on disk now

    Returns:
        The digest this session was last shown, or None the first time
    """
    path = STATE / f"{session_id}.json"
    previous = None
    try:
        previous = json.loads(path.read_text()).get("instructions_digest")
    except (OSError, json.JSONDecodeError):
        previous = None
    try:
        write_atomically(path, json.dumps({"instructions_digest": current}).encode())
    except OSError:
        pass
    return previous


def forget_session(session_id: str) -> None:
    """Drop remembered state for a session that no longer has a plan."""
    (STATE / f"{session_id}.json").unlink(missing_ok=True)
