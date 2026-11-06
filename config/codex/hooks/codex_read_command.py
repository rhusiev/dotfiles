"""Recognize straightforward Codex shell commands that display file contents."""

from __future__ import annotations

import re
import shlex
from pathlib import Path

SHELL_OPERATORS = frozenset({";", "&&", "||", "|", ">", ">>", "<"})
WHOLE_FILE_COMMANDS = frozenset({"cat", "bat"})
SED_RANGE = re.compile(r"^(\d+),(\d+|\$)p$")


def parse_reads(command: str, cwd: str) -> list[tuple[Path, int | None, int | None]]:
    """Return the ranges displayed by a simple file read command."""
    try:
        tokens = shlex.split(command)
    except ValueError:
        return []
    if not tokens or any(token in SHELL_OPERATORS for token in tokens):
        return []
    executable = Path(tokens[0]).name
    if executable in WHOLE_FILE_COMMANDS and len(tokens) == 2:
        return [(_resolve(tokens[1], cwd), None, None)]
    if executable != "sed" or len(tokens) != 4:
        return []
    if tokens[1] != "-n":
        return []
    ranges = []
    path = _resolve(tokens[3], cwd)
    for expression in tokens[2].split(";"):
        match = SED_RANGE.fullmatch(expression)
        if not match:
            return []
        start = int(match.group(1))
        end_text = match.group(2)
        limit = None if end_text == "$" else int(end_text) - start + 1
        if limit is not None and limit < 1:
            return []
        ranges.append((path, start, limit))
    return ranges


def _resolve(raw_path: str, cwd: str) -> Path:
    """Resolve a command path against the hook working directory."""
    path = Path(raw_path).expanduser()
    if not path.is_absolute():
        path = Path(cwd) / path
    return path.resolve()
