"""Select on-demand instructions from observable actions, not prompt keywords."""

from __future__ import annotations

from pathlib import Path
import re
import shlex

from guide_state import GUIDES_ROOT

REFERENCE = Path.home() / ".config" / "claude" / "reference"
TOPICS = frozenset({
    "code-style.md", "design.md", "git.md", "guides.md", "locks.md",
    "orchestration.md", "reviews.md",
})
UI_SUFFIXES = {".css", ".scss", ".html", ".jsx", ".tsx", ".vue", ".svelte"}
CODE_SUFFIXES = UI_SUFFIXES | set(
    ".py .rs .c .cc .cpp .h .hpp .go .java .kt .swift .js .mjs .ts .rb "
    ".sh .bash .zsh .fish .lua .sql .ipynb".split()
)
PATCH_PATH = re.compile(r"^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$", re.M)
GIT_ACTIONS = set(
    "add am apply branch checkout cherry-pick clean clone commit config fetch init "
    "merge mv pull push rebase reset restore revert rm stash switch tag worktree".split()
)
REVIEW_TOOLS = {
    "add_pr_review_comment", "edit_pr_review_comment", "reply_to_review_thread",
    "reply_and_resolve_review_thread", "update_pull_request", "create_pull_request",
}


def edit_paths(args: dict, cwd: str) -> set[Path]:
    """Include both names of a patch move and every file of a multi-file edit."""
    names = [args.get(key) for key in ("file_path", "notebook_path", "path")]
    for key in ("input", "patch", "patch_text", "command"):
        if isinstance(args.get(key), str):
            names.extend(PATCH_PATH.findall(args[key]))
    return {Path(cwd) / Path(name).expanduser() for name in names if isinstance(name, str)}


def command_topics(words: list[str]) -> set[str]:
    """Recognize literal command invocations without expanding or executing them."""
    if not words:
        return set()
    command, args = Path(words[0]).name, words[1:]
    if command == "git":
        while args and args[0].startswith("-"):
            args = args[2:] if args[0] in {"-C", "-c", "--git-dir", "--work-tree"} else args[1:]
        if (args in (["branch"], ["branch", "--show-current"], ["worktree", "list"],
                     ["stash", "list"], ["tag"], ["remote", "-v"])
                or args[:2] in (["config", "--get"], ["config", "--get-all"])):
            return set()
        if args and args[0] in GIT_ACTIONS:
            return {"git.md", "reviews.md"} if args[0] == "commit" else {"git.md"}
    if command == "agent-lock" and args and args[0] in {"acquire", "run", "break"}:
        return {"locks.md"}
    if command in {"gh", "glab"} and len(args) >= 2 and args[0] in {"mr", "pr", "issue"}:
        if args[1] in {"create", "merge"}:
            return {"git.md", "reviews.md"}
        if args[1] in {"comment", "note", "review", "edit", "update", "approve"}:
            return {"reviews.md"}
    return set()


def shell_topics(command: str) -> set[str]:
    """Handle literal shell commands and common lists/pipelines, not scripts."""
    topics: set[str] = set()
    for line in command.splitlines():
        lexer = shlex.shlex(line, posix=True, punctuation_chars=";&|")
        lexer.whitespace_split = True
        words: list[str] = []
        try:
            for word in lexer:
                if word in {";", "&&", "||", "|", "&"}:
                    topics.update(command_topics(words))
                    words = []
                else:
                    words.append(word)
        except ValueError:
            # A multiline quotation is outside this recognizer.
            continue
        topics.update(command_topics(words))
    return topics


def required_topics(event: dict) -> set[str]:
    """Return only the topics required for this tool call."""
    name = event.get("tool_name", "").removeprefix("functions.")
    args = event.get("tool_input") or {}
    if isinstance(args, str) and name == "apply_patch":
        args = {"input": args}
    if name in {"Edit", "Write", "MultiEdit", "NotebookEdit", "apply_patch"}:
        paths = edit_paths(args, event.get("cwd") or ".")
        topics = set()
        if any(path.suffix.lower() in CODE_SUFFIXES for path in paths):
            topics.add("code-style.md")
        if any(path.suffix.lower() in UI_SUFFIXES for path in paths):
            topics.add("design.md")
        if any(path.resolve().is_relative_to(GUIDES_ROOT.resolve()) for path in paths):
            topics.add("guides.md")
        return topics
    if name in {"Bash", "exec_command"}:
        return shell_topics(args.get("command", args.get("cmd", "")))
    if name in REVIEW_TOOLS:
        return {"reviews.md", "git.md"} if name == "create_pull_request" else {"reviews.md"}
    if name == "rename_branch":
        return {"git.md"}
    if name in {"create_session", "run_dynamic_workflow", "respond_to_session_plan_v2"}:
        return {"orchestration.md"}
    if name in {"Agent", "Task", "task"} and args.get("agent_type", args.get("subagent_type")) == "code-review":
        return {"reviews.md", "code-style.md"}
    return set()
