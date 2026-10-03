#!/usr/bin/env python3
"""Checkpoint a bounded tail of the active transcript before compaction."""

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from plan_state import (  # noqa: E402
    CHECKPOINT_FILENAME,
    topic_dir_for,
    write_atomically,
)

TAIL_MAX_BYTES = 32 * 1024


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
