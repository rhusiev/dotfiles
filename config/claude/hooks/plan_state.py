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
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path.home() / ".local" / "share" / "ai-sessions"
BY_SESSION = ROOT / ".by-session"
GATES = ROOT / ".gates"
STATE = ROOT / ".state"
CHECKPOINT_FILENAME = "pre-compact-tail.jsonl"
PLAN_FILENAME = "plan.md"

DIGEST_CHARS = 12
GATE_MAX_DENIALS = 4
GATE_MAX_AGE_S = 3600
# Intended window from the first refusal once the gate counts parallel batches.
GATE_BATCH_WINDOW_S = 2.0


def codex_home() -> Path:
    """Codex's config directory: CODEX_HOME, else the platform default."""
    configured = os.environ.get("CODEX_HOME")
    if configured:
        return Path(configured)
    default = Path.home() / ".codex"
    return default if default.is_dir() else Path.home() / ".config" / "codex"


CLAUDE_INSTRUCTIONS = Path.home() / ".config" / "claude" / "CLAUDE.md"
CODEX_INSTRUCTIONS = codex_home() / "AGENTS.md"
CONVENTIONS = CLAUDE_INSTRUCTIONS.parent / "conventions.md"
TEAM_INSTRUCTION_FILES = ("AGENTS.md", "CLAUDE.md")
GIT_TIMEOUT_S = 5


def git_output(cwd: str | Path, *args: str) -> str | None:
    """Stdout of a git command in cwd, or None when git fails or is missing."""
    try:
        result = subprocess.run(
            ["git", "-C", str(cwd), *args],
            capture_output=True,
            text=True,
            timeout=GIT_TIMEOUT_S,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return result.stdout.strip() if result.returncode == 0 else None


def team_instructions_root(cwd: str | Path | None) -> Path | None:
    """The repository above cwd when it tracks its own AGENTS.md or CLAUDE.md.

    Such a repository sets its own commit, MR and test conventions, so
    CONVENTIONS is not loaded there. Any git failure counts as no team file,
    which keeps the personal conventions in force.
    """
    if not cwd:
        return None
    root = git_output(cwd, "rev-parse", "--show-toplevel")
    if not root:
        return None
    tracked = git_output(root, "ls-files", "--", *TEAM_INSTRUCTION_FILES)
    return Path(root) if tracked else None


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


def topic_dir_for(session_id: str) -> Path | None:
    """Resolve this session's binding to its topic directory, or None.

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
    return topic_dir


def plan_for(session_id: str) -> Path | None:
    """Resolve this session's plan file through its binding, or None.

    Raises:
        ValueError: When the binding names a path outside the sessions root
    """
    topic_dir = topic_dir_for(session_id)
    if topic_dir is None:
        return None
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


def read_session_state(session_id: str) -> dict:
    """This session's remembered state, or an empty mapping when there is none."""
    try:
        state = json.loads((STATE / f"{session_id}.json").read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    return state if isinstance(state, dict) else {}


def seen_before(session_id: str) -> bool:
    """Whether this session id has started before, plan or no plan.

    A first start must be offered a topic choice. A session id that started
    before and now has no plan has lost its binding. The marker is written on
    every start, including a no-plan one, so the next start can tell them apart.

    Returns:
        True when this session id started at least once before
    """
    return bool(read_session_state(session_id).get("seen"))


def mark_seen(session_id: str) -> None:
    """Record that this session id has started, keeping any remembered digest."""
    state = read_session_state(session_id)
    state["seen"] = True
    state["seen_at"] = datetime.now().timestamp()
    try:
        write_atomically(STATE / f"{session_id}.json", json.dumps(state).encode())
    except OSError:
        pass


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
    state = read_session_state(session_id)
    previous = state.get("instructions_digest")
    state["instructions_digest"] = current
    try:
        write_atomically(STATE / f"{session_id}.json", json.dumps(state).encode())
    except OSError:
        pass
    return previous
