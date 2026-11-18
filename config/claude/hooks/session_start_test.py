"""Regression tests for the no-plan session-start headers.

A first start must offer the topic choice. A continuation that lost its binding
must say so. The two must not collapse into one "no active plan" message.
"""

from __future__ import annotations

import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

import importlib.util

_SPEC = importlib.util.spec_from_file_location(
    "session_start", Path(__file__).with_name("session-start.py")
)
hook = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(hook)


class ClassifySessionTest(unittest.TestCase):
    """Keep a first start apart from a continuation that lost its binding."""

    def test_first_start_is_new(self) -> None:
        self.assertEqual(hook.classify_session(False, "startup"), "new")

    def test_resume_compact_and_fork_are_lost(self) -> None:
        for source in ("resume", "compact", "fork"):
            with self.subTest(source=source):
                self.assertEqual(hook.classify_session(False, source), "lost")

    def test_seen_startup_is_lost(self) -> None:
        self.assertEqual(hook.classify_session(True, "startup"), "lost")


class NoPlanHeaderTest(unittest.TestCase):
    """Drive main() with no bound plan and check which header it prints."""

    def setUp(self) -> None:
        """Patch the filesystem and plan lookup, leaving only the header logic."""
        patches = {
            "plan_for": mock.MagicMock(return_value=None),
            "prune_bindings": mock.MagicMock(return_value=0),
            "prune_topics": mock.MagicMock(return_value=[]),
            "print_topics": mock.MagicMock(),
            "print_guides": mock.MagicMock(),
            "print_imported_instructions": mock.MagicMock(),
            "disarm_gate": mock.MagicMock(),
            "arm_gate": mock.MagicMock(),
            "mark_seen": mock.MagicMock(),
            "BY_SESSION": Path("/tmp/opencode/fake-sessions"),
        }
        for name, value in patches.items():
            patch = mock.patch.object(hook, name, value)
            patch.start()
            self.addCleanup(patch.stop)

    def run_hook(self, session_id: str, source: str, already_seen: bool) -> str:
        """Run main() once and return what it printed."""
        event = json.dumps(
            {"session_id": session_id, "cwd": "/tmp/opencode", "source": source}
        )
        output = io.StringIO()
        with (
            mock.patch.object(sys, "stdin", io.StringIO(event)),
            mock.patch.object(hook, "seen_before", return_value=already_seen),
            redirect_stdout(output),
        ):
            hook.main()
        return output.getvalue()

    def test_first_start_offers_the_topic_choice(self) -> None:
        output = self.run_hook("new-session", "startup", already_seen=False)
        self.assertIn("NEW SESSION", output)
        self.assertIn("create a new topic", output)
        self.assertIn("bind this session to an existing topic", output)
        self.assertIn("work without a plan", output)
        self.assertNotIn("PLAN BINDING LOST", output)
        self.assertNotIn("NO ACTIVE PLAN", output)

    def test_second_start_says_the_binding_was_lost(self) -> None:
        output = self.run_hook("same-session", "startup", already_seen=True)
        self.assertIn("PLAN BINDING LOST", output)
        self.assertNotIn("NEW SESSION", output)

    def test_fork_says_the_binding_was_lost(self) -> None:
        output = self.run_hook("forked-session", "fork", already_seen=False)
        self.assertIn("PLAN BINDING LOST", output)
        self.assertIn("source=fork", output)
        self.assertNotIn("NEW SESSION", output)


if __name__ == "__main__":
    unittest.main()