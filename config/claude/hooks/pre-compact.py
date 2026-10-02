#!/usr/bin/env python3
"""Checkpoint a bounded tail of the active transcript before compaction."""

import json
import os
import sys
import tempfile
from pathlib import Path

ROOT = Path.home() / ".local" / "share" / "ai-sessions"
CHECKPOINT_FILENAME = "pre-compact-tail.jsonl"
TAIL_MAX_BYTES = 32 * 1024


def topic_dir_for(session_id: str) -> Path | None:
    """Resolve a session binding to a safe topic directory."""
    binding = ROOT / ".by-session" / session_id
    if not binding.is_file():
        return None
    topic = binding.read_text().strip()
    if not topic:
        return None
    root = ROOT.resolve()
    topic_dir = (ROOT / topic).resolve()
    if not topic_dir.is_relative_to(root) or topic_dir == root:
        raise ValueError(f"unsafe topic binding for session {session_id}")
    return topic_dir


def read_complete_tail(transcript: Path) -> bytes:
    """Read complete JSONL records from the bounded transcript tail."""
    with transcript.open("rb") as stream:
        size = stream.seek(0, os.SEEK_END)
        offset = max(0, size - TAIL_MAX_BYTES)
        stream.seek(offset)
        data = stream.read()
    if offset:
        _, separator, data = data.partition(b"\n")
        if not separator:
            return b""
    return data[-TAIL_MAX_BYTES:]


def write_atomically(destination: Path, data: bytes) -> None:
    """Replace the checkpoint only after its complete contents reach disk."""
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


def main() -> None:
    """Checkpoint the transcript when an active plan binding exists."""
    event = json.load(sys.stdin)
    session_id = event.get("session_id", "")
    transcript_value = event.get("transcript_path")
    if not session_id or not transcript_value:
        return
    topic_dir = topic_dir_for(session_id)
    transcript = Path(transcript_value)
    if topic_dir is None or not transcript.is_file():
        return
    write_atomically(topic_dir / CHECKPOINT_FILENAME, read_complete_tail(transcript))


if __name__ == "__main__":
    main()
