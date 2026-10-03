"""Resolve which ai-guides apply to a session.

A guide is a directory under GUIDES_ROOT whose README.md is always read and
whose other Markdown files are read on demand. A session gets a guide in two
ways: its plan topic lists the guide by name in a TOPIC_GUIDES_FILENAME file, or
the guide's README front matter lists a directory that contains the cwd
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

GUIDES_ROOT = Path.home() / ".local" / "share" / "ai-guides"
GUIDE_README_FILENAME = "README.md"
TOPIC_GUIDES_FILENAME = "guides"
FRONT_MATTER_FENCE = "---"


@dataclass(frozen=True)
class Guide:
    """One guide directory and what its README front matter says about it."""

    name: str
    readme: Path
    description: str
    paths: tuple[Path, ...]


def parse_front_matter(text: str) -> dict[str, str | list[str]]:
    """Read the flat `key: value` / `key:` + `- item` block between leading fences.

    Only the subset the guide READMEs use is supported, so no YAML dependency
    is needed

    Returns:
        Keys mapped to a string, or to a list for keys followed by `- item` lines
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != FRONT_MATTER_FENCE:
        return {}
    fields: dict[str, str | list[str]] = {}
    key = None
    for line in lines[1:]:
        stripped = line.split(" #", 1)[0].strip()
        if stripped == FRONT_MATTER_FENCE:
            return fields
        if stripped.startswith("- ") and key is not None:
            items = fields.setdefault(key, [])
            if isinstance(items, list):
                items.append(stripped[2:].strip())
        elif ":" in stripped:
            key, value = (part.strip() for part in stripped.split(":", 1))
            if value:
                fields[key] = value
    return {}


def load_guide(directory: Path) -> Guide | None:
    """A guide for a directory with a README, or None when it has none."""
    readme = directory / GUIDE_README_FILENAME
    try:
        fields = parse_front_matter(readme.read_text())
    except OSError:
        return None
    description = fields.get("description")
    paths = fields.get("paths")
    return Guide(
        name=directory.name,
        readme=readme,
        description=description if isinstance(description, str) else "",
        paths=tuple(Path(path).expanduser() for path in paths)
        if isinstance(paths, list)
        else (),
    )


def all_guides() -> list[Guide]:
    """Every guide under the root, sorted by name."""
    if not GUIDES_ROOT.is_dir():
        return []
    guides = (
        load_guide(entry)
        for entry in sorted(GUIDES_ROOT.iterdir())
        if entry.is_dir() and not entry.name.startswith(".")
    )
    return [guide for guide in guides if guide is not None]


def attached_names(topic_dir: Path) -> list[str]:
    """Guide names a plan topic lists, one per line, ignoring blanks and comments."""
    try:
        lines = (topic_dir / TOPIC_GUIDES_FILENAME).read_text().splitlines()
    except OSError:
        return []
    names = (line.strip() for line in lines)
    return [name for name in names if name and not name.startswith("#")]


def covers(guide: Guide, cwd: Path) -> bool:
    """Whether the cwd lies inside one of the directories the guide lists."""
    try:
        resolved = cwd.resolve()
        return any(resolved.is_relative_to(path.resolve()) for path in guide.paths)
    except OSError:
        return False
