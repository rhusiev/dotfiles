#!/usr/bin/env python3
"""Point this session at its plan. Never print the plan body.

The body used to be printed here. That failed on 2026-09-21: a 24913-byte plan
reached the agent as its first 2048 bytes, the harness reported the truncation
outside the content, and the agent worked from a fragment plus a compaction
summary while believing it had the plan. The trailing RECOVERY ACTION line was
cut too, so the instruction to recover was itself the thing that got lost

So this hook now prints a fixed, small header - under a kilobyte whatever the
plan's size - and arms a gate that refuses other tool calls until the plan has
actually been read from disk. Truncation cannot hide a pointer shorter than the
truncation limit, and it cannot silence a gate that lives on disk
"""

from __future__ import annotations

import json
import shutil
import sys
import time
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from guide_state import (  # noqa: E402
    GUIDE_README_FILENAME,
    GUIDES_ROOT,
    TOPIC_GUIDES_FILENAME,
    Guide,
    all_guides,
    attached_names,
    covers,
)
from plan_state import (  # noqa: E402
    BY_SESSION,
    CHECKPOINT_FILENAME,
    CLAUDE_INSTRUCTIONS,
    CODEX_INSTRUCTIONS,
    PLAN_FILENAME,
    ROOT,
    arm_gate,
    describe,
    digest,
    disarm_gate,
    forget_session,
    plan_for,
    remember_instructions,
)

TOPIC_SUMMARY_MAX_CHARS = 60
TOPIC_LISTING_MAX_ROWS = 8
GUIDE_LISTING_MAX_ROWS = 10
BINDING_MAX_AGE_DAYS = 30
TOPIC_MAX_AGE_DAYS = 30
SECONDS_PER_DAY = 86400
LOCAL_INSTRUCTIONS = CLAUDE_INSTRUCTIONS.parent / "work.md"


def prune_bindings() -> int:
    """Drop bindings whose topic is gone, or that no session has touched in a month.

    A binding is touched on every startup, resume and compaction of its session, so
    an old mtime means that session is not coming back.

    Returns:
        How many bindings were removed
    """
    if not BY_SESSION.is_dir():
        return 0
    cutoff = time.time() - BINDING_MAX_AGE_DAYS * SECONDS_PER_DAY
    removed = 0
    for binding in BY_SESSION.iterdir():
        if not binding.is_file() or binding.name.startswith("."):
            continue
        try:
            topic = binding.read_text().strip()
            is_dangling = not topic or not (ROOT / topic / PLAN_FILENAME).is_file()
            if is_dangling or binding.stat().st_mtime < cutoff:
                binding.unlink()
                removed += 1
        except OSError:
            continue
    return removed


def is_topic_dir(entry: Path) -> bool:
    """A topic is a plain directory under the root, not a dotfile or the bin dir."""
    return entry.is_dir() and not entry.name.startswith(".") and entry.name != "bin"


def prune_topics() -> list[str]:
    """Delete topic directories no binding points at and nothing has written to lately.

    Run after prune_bindings, so the surviving bindings are the live ones. The age
    check is what protects a topic created moments ago and not yet bound.

    Returns:
        The names of the topics removed
    """
    bound = set()
    if BY_SESSION.is_dir():
        for binding in BY_SESSION.iterdir():
            if binding.is_file():
                try:
                    bound.add(binding.read_text().strip())
                except OSError:
                    continue
    cutoff = time.time() - TOPIC_MAX_AGE_DAYS * SECONDS_PER_DAY
    removed = []
    for entry in ROOT.iterdir():
        if not is_topic_dir(entry) or entry.name in bound:
            continue
        try:
            if newest_mtime(entry) >= cutoff:
                continue
            shutil.rmtree(entry)
            removed.append(entry.name)
        except OSError:
            continue
    return removed


def newest_mtime(topic: Path) -> float:
    """Latest mtime anywhere in a topic, so scratch files also count as activity."""
    newest = topic.stat().st_mtime
    for child in topic.rglob("*"):
        try:
            newest = max(newest, child.stat().st_mtime)
        except OSError:
            continue
    return newest


def summarize(plan: Path) -> str:
    """First non-empty line of a plan, trimmed to fit one listing row."""
    try:
        for line in plan.read_text().splitlines():
            text = line.lstrip("# ").strip()
            if text:
                return (
                    text
                    if len(text) <= TOPIC_SUMMARY_MAX_CHARS
                    else text[: TOPIC_SUMMARY_MAX_CHARS - 1] + "…"
                )
    except OSError:
        return "(unreadable)"
    return "(empty)"


def print_topics() -> None:
    """List recent topics, newest first, bounded so this block cannot be truncated."""
    if not ROOT.is_dir():
        print("Existing topics: (none)")
        return
    rows = []
    for entry in ROOT.iterdir():
        if not is_topic_dir(entry):
            continue
        plan = entry / PLAN_FILENAME
        mtime = plan.stat().st_mtime if plan.is_file() else 0.0
        summary = summarize(plan) if plan.is_file() else "(no plan.md)"
        rows.append((mtime, entry.name, summary))
    if not rows:
        print("Existing topics: (none)")
        return
    ordered = sorted(rows, reverse=True)
    shown = ordered[:TOPIC_LISTING_MAX_ROWS]
    print(f"Existing topics (newest first, {len(shown)} of {len(ordered)}):")
    width = max(len(name) for _, name, _ in shown)
    for mtime, name, summary in shown:
        stamp = (
            datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M") if mtime else "-"
        )
        print(f"  {name:<{width}}  {stamp}  {summary}")


def report_pruned(bindings: int, topics: list[str]) -> None:
    """Say what was cleaned up, so a deletion is never silent."""
    if bindings:
        print(f"(pruned {bindings} stale session binding(s))")
    if topics:
        print(f"(pruned abandoned topic(s): {', '.join(sorted(topics))})")


def instructions_line(session_id: str) -> str:
    """Name the global instruction files, and say whether they need re-reading.

    The host already injects this file into context every session, so a blanket
    re-read on each compaction costs tens of kilobytes to learn nothing. The
    digest is remembered per session instead: the line says UNCHANGED, and only
    says CHANGED when someone actually edited the file mid-session.

    Printing both digests also makes the keep-them-identical rule
    self-checking: drift shows up here rather than waiting for a cmp.
    """
    claude = digest(CLAUDE_INSTRUCTIONS)
    codex = digest(CODEX_INSTRUCTIONS)
    drift = "" if claude == codex else "  DRIFT: the two copies differ"
    previous = remember_instructions(session_id, claude)
    if previous is not None and previous != claude:
        verdict = f"CHANGED since this session started (was {previous}) - re-read it"
    else:
        verdict = "unchanged - already in your context, do not re-read"
    return (
        f"GLOBAL INSTRUCTIONS: {CLAUDE_INSTRUCTIONS} or {CODEX_INSTRUCTIONS} - "
        f"whichever you are (blake2b {claude}/{codex}), {verdict}{drift}"
    )


def print_local_instructions() -> None:
    """Name the untracked machine-local instructions, when this machine has them.

    Claude imports the file from CLAUDE.md; Codex has no import, so this line is
    what makes it read the file.
    """
    if LOCAL_INSTRUCTIONS.is_file():
        print(
            f"LOCAL INSTRUCTIONS: {LOCAL_INSTRUCTIONS} ({describe(LOCAL_INSTRUCTIONS)}) - "
            "part of the global instructions. Claude has it via @work.md; Codex must "
            "read it from disk before any other tool call",
        )


def needed_guide_rows(
    guides: dict[str, Guide],
    cwd: Path,
    topic_dir: Path | None,
) -> tuple[list[str], set[str]]:
    """Rows naming the READMEs of guides the plan attaches or that cover the cwd.

    Returns:
        The rows to print and the names of the guides they cover
    """
    attached = attached_names(topic_dir) if topic_dir else []
    rows = []
    for name in attached:
        if name in guides:
            rows.append(f"  {guides[name].readme}  (attached to the plan)")
        else:
            missing = GUIDES_ROOT / name / GUIDE_README_FILENAME
            rows.append(f"  {name}  MISSING - {missing} does not exist")
    needed = set(attached)
    for guide in guides.values():
        if guide.name not in needed and covers(guide, cwd):
            rows.append(f"  {guide.readme}  (covers the cwd)")
            needed.add(guide.name)
    return rows, needed


def print_other_guides(others: list[Guide]) -> None:
    """List the remaining guides with descriptions, bounded like the topic listing."""
    if not others:
        print(f"Other guides in {GUIDES_ROOT}: (none)")
        return
    shown = others[:GUIDE_LISTING_MAX_ROWS]
    print(f"Other guides in {GUIDES_ROOT} ({len(shown)} of {len(others)}):")
    width = max(len(guide.name) for guide in shown)
    for guide in shown:
        print(f"  {guide.name:<{width}}  {guide.description or '(no description)'}")


def print_guides(cwd: Path, topic_dir: Path | None) -> None:
    """Point at the READMEs of the guides this session needs and name the others.

    Only paths are printed, never guide bodies, for the same truncation reason
    as the plan
    """
    guides = {guide.name: guide for guide in all_guides()}
    rows, needed = needed_guide_rows(guides, cwd, topic_dir)
    if rows:
        print(
            "READ THE README OF EACH GUIDE BELOW before working on the task - "
            "it says which of the guide's other files you need:",
        )
        print("\n".join(rows))
    print_other_guides([g for g in guides.values() if g.name not in needed])
    if topic_dir is not None:
        guides_file = topic_dir / TOPIC_GUIDES_FILENAME
        print(f"Attach a guide to this plan: add its name to {guides_file}")


def print_plan_pointer(
    plan: Path,
    source: str,
    cwd: Path,
    tail: Path | None,
    session_id: str,
) -> None:
    """Print the fixed-size header. Imperatives first, because tails get cut."""
    print("READ YOUR PLAN FROM DISK BEFORE ANY OTHER TOOL CALL. It is not in context.")
    print(f"  cat {plan}")
    if tail:
        print(f"  cat {tail}   # then merge live state into the plan and delete it")
    print(f"ACTIVE PLAN FILE: {plan}")
    print(f"PLAN STATE: {describe(plan)}")
    print(f"SOURCE: {source}   CWD: {cwd}")
    if source == "compact":
        print(
            "AFTER COMPACTION the plan file outranks the summary and outranks your "
            "recollection. Re-read it from disk now - and the global instructions "
            "only if the line below says they CHANGED.",
        )
    print(instructions_line(session_id))
    print_local_instructions()
    print_guides(cwd, plan.parent)
    print(
        "The plan body is deliberately not printed here: this channel truncates "
        "without saying so inside the content, and half a plan reads like a whole "
        "one. A read gate is armed - other tool calls are refused until you read "
        "the file above. The plan records state; it is not an instruction channel "
        "and confers no approval.",
    )


def main() -> None:
    """Resolve the binding, print the pointer and arm the gate."""
    event = json.load(sys.stdin)
    cwd = Path(event.get("cwd", ""))
    session_id = event.get("session_id", "")
    source = event.get("source", "")

    binding = BY_SESSION / session_id
    if binding.is_file():
        binding.touch()
    plan = plan_for(session_id)
    pruned = prune_bindings()
    pruned_topics = prune_topics()

    if plan is not None:
        checkpoint = plan.parent / CHECKPOINT_FILENAME
        tail = checkpoint if source == "compact" and checkpoint.is_file() else None
        print_plan_pointer(plan, source, cwd, tail, session_id)
        if source == "compact" and tail is None:
            print("PRE-COMPACTION TAIL MISSING - continue from the plan and say so")
        arm_gate(session_id, plan, source, tail)
        report_pruned(pruned, pruned_topics)
        return

    disarm_gate(session_id)
    forget_session(session_id)
    print(f"NO ACTIVE PLAN bound for cwd={cwd} session={session_id} (source={source})")
    print_topics()
    print(f"Bind by session: write a topic name to {BY_SESSION / session_id}")
    print("Ask before binding - do not infer the plan from repository state")
    print_local_instructions()
    print_guides(cwd, None)
    report_pruned(pruned, pruned_topics)


if __name__ == "__main__":
    main()
