"""Verify topic selection and read enforcement without touching installed hooks."""

from pathlib import Path
import tempfile
import unittest
from unittest import mock

import instruction_state as state
import task_topics as topics


class TopicGateTest(unittest.TestCase):
    """Exercise matched and unrelated actions against an isolated session."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.reference = self.root / "reference"
        self.reference.mkdir()
        self.topic = self.reference / "code-style.md"
        self.topic.write_text("first\nsecond\n")
        for patch in (
            mock.patch.object(topics, "REFERENCE", self.reference),
            mock.patch.object(state, "ROOT", self.root / "state"),
            mock.patch.object(state, "sources", return_value=[]),
        ):
            patch.start()
            self.addCleanup(patch.stop)
        self.session = {"session_id": "test", "cwd": str(self.root)}
        self.edit = {**self.session, "tool_name": "Edit", "tool_input": {"file_path": "app.py"}}
        self.read = {**self.session, "tool_name": "Read", "tool_input": {"file_path": str(self.topic)}}

    def assert_blocked(self, event: dict, runtime: str = "claude") -> None:
        result = state.before_tool(event, runtime)
        self.assertEqual(result["permissionDecision"], "deny")
        self.assertIn(str(self.topic), result["permissionDecisionReason"])

    def test_require_complete_current_topic_only_for_related_actions(self) -> None:
        for _ in range(state.GATE_MAX_DENIALS + 1):
            self.assert_blocked(self.edit)
        lookup = {**self.session, "tool_name": "Bash", "tool_input": {"command": "git status"}}
        self.assertIsNone(state.before_tool(lookup, "claude"))
        first = {**self.read, "tool_input": {**self.read["tool_input"], "limit": 1}}
        self.assertIsNone(state.before_tool(first, "claude"))
        state.after_tool({**first, "tool_response": "first\n"}, "claude")
        self.assert_blocked(self.edit)
        self.assertIsNone(state.before_tool(self.read, "claude"))
        state.after_tool({**self.read, "tool_response": self.topic.read_text()}, "claude")
        self.assertIsNone(state.before_tool(self.edit, "claude"))
        self.topic.write_text("changed\n")
        self.assert_blocked(self.edit)
        self.topic.unlink()
        self.assert_blocked(self.edit)

    def test_proactive_read_survives_only_in_its_own_context(self) -> None:
        self.assertIsNone(state.before_tool(self.read, "claude"))
        post = {**self.read, "tool_response": self.topic.read_text()}
        state.after_tool(post, "claude")
        self.assertIsNone(state.before_tool(self.edit, "claude"))
        self.assert_blocked({**self.edit, "session_id": "other"})
        self.assert_blocked(self.edit, "codex")
        # A new read started in the old context must not count in the new one.
        self.topic.write_text("new version\n")
        state.before_tool(self.read, "claude")
        state.startup_status({**self.session, "source": "compact"}, "claude")
        state.after_tool({**self.read, "tool_response": self.topic.read_text()}, "claude")
        self.assert_blocked(self.edit)

    def test_copied_topic_needs_matching_bytes_and_successful_result(self) -> None:
        copy = self.root / self.topic.name
        read = {**self.session, "tool_name": "exec_command", "tool_input": {"cmd": f"cat {copy}"}}
        for text, code in (("different\n", 0), (self.topic.read_text(), 1)):
            copy.write_text(text)
            state.before_tool(read, "codex")
            state.after_tool({**read, "tool_response": {"exit_code": code, "stdout": text}}, "codex")
            self.assert_blocked(self.edit, "codex")
        state.before_tool(read, "codex")
        state.after_tool({**read, "tool_response": {"exit_code": 0, "stdout": copy.read_text()}}, "codex")
        self.assertIsNone(state.before_tool(self.edit, "codex"))

    def test_routes_additive_topics_and_keeps_unrelated_tasks_free(self) -> None:
        cases = [
            ("apply_patch", {"command": "*** Update File: README.md\n*** Move to: ui.tsx\n"},
             {"code-style.md", "design.md"}),
            ("Write", {"file_path": str(topics.GUIDES_ROOT / "subject/README.md")}, {"guides.md"}),
            ("Write", {"file_path": "docs/guides/README.md"}, set()),
            ("Bash", {"command": "git status && git -C 'another repo' commit -m 'fix: demo'"},
             {"git.md", "reviews.md"}),
            ("Bash", {"command": "echo 'git merge branch' && git branch --show-current"}, set()),
            ("Bash", {"command": "~/.copilot/bin/agent-lock acquire bench"}, {"locks.md"}),
            ("Bash", {"command": "agent-lock release bench"}, set()),
            ("functions.add_pr_review_comment", {}, {"reviews.md"}),
            ("create_session", {}, {"orchestration.md"}),
        ]
        for name, args, expected in cases:
            with self.subTest(tool=name, args=args):
                event = {**self.session, "tool_name": name, "tool_input": args}
                self.assertEqual(topics.required_topics(event), expected)
