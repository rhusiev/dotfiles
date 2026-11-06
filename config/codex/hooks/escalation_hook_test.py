"""Regression tests for clearing reader escalations after shell reads."""

from __future__ import annotations

import io
import json
import runpy
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "claude" / "hooks"))

# Load the worktree state before the notifier adds the live hook path.
from escalation_state import covers, parse_block  # noqa: E402
from codex_read_command import parse_reads  # noqa: E402
import codex_escalation_notify  # noqa: E402


class EscalationHookTest(unittest.TestCase):
    """Check compound reads and the full-range clearance rule."""

    def test_compound_sed_clears_every_read_range(self: EscalationHookTest) -> None:
        """One sed command can satisfy several escalations in the same file."""
        path = Path(__file__).resolve()
        spans = [(187, 232), (387, 403), (487, 500), (589, 599), (632, 647)]
        entries = [
            {
                "path": str(path),
                "start": first,
                "end": last,
                "is_announced": True,
            }
            for first, last in spans
        ]
        expressions = ";".join(f"{first},{last}p" for first, last in spans)
        event = {
            "session_id": "test-session",
            "cwd": str(path.parent),
            "tool_input": {"command": f"sed -n '{expressions}' {path}"},
        }
        with (
            mock.patch.object(codex_escalation_notify, "load", return_value=entries),
            mock.patch.object(codex_escalation_notify, "save") as save,
            mock.patch.object(sys, "stdin", io.StringIO(json.dumps(event))),
        ):
            codex_escalation_notify.main()
        self.assertEqual(save.call_args.args[1], [])

    def test_exec_command_uses_cmd_and_workdir(self: EscalationHookTest) -> None:
        """Native shell arguments clear only the displayed escalation."""
        path = Path(__file__).resolve()
        entries = [
            {"path": str(path), "start": 131, "end": 143, "is_announced": True},
            {"path": str(path), "start": 224, "end": 230, "is_announced": True},
        ]
        event = {
            "session_id": "test-session",
            "cwd": "/",
            "tool_input": {
                "cmd": f"sed -n '131,143p' {path.name}",
                "workdir": str(path.parent),
            },
        }
        with (
            mock.patch.object(codex_escalation_notify, "load", return_value=entries),
            mock.patch.object(codex_escalation_notify, "save") as save,
            mock.patch.object(sys, "stdin", io.StringIO(json.dumps(event))),
        ):
            codex_escalation_notify.main()
        self.assertEqual(save.call_args.args[1], [entries[1]])

    def test_partial_range_does_not_clear(self: EscalationHookTest) -> None:
        """The gate retains an escalation until the whole range is read."""
        entry = {"start": 187, "end": 232}
        self.assertFalse(covers(entry, 187, 14))
        self.assertFalse(covers(entry, 200, 33))
        self.assertTrue(covers(entry, 187, 46))
        self.assertTrue(covers(entry, None, None))

    def test_claude_read_requires_full_range(self: EscalationHookTest) -> None:
        """Claude's Read notification follows the same full-range rule."""
        path = Path(__file__).resolve()
        hook = path.parents[2] / "claude" / "hooks" / "escalation-notify.py"
        clear_read = runpy.run_path(str(hook))["clear_read"]
        entry = {"path": str(path), "start": 187, "end": 232}
        event = {
            "tool_name": "Read",
            "cwd": str(path.parent),
            "tool_input": {"file_path": str(path), "offset": 187, "limit": 14},
        }
        self.assertEqual(clear_read([entry], event), [entry])
        event["tool_input"]["limit"] = 46
        self.assertEqual(clear_read([entry], event), [])

    def test_reader_line_can_name_multiple_ranges(self: EscalationHookTest) -> None:
        """A comma-separated reader escalation stores every span."""
        entries = parse_block(
            "ESCALATE:\n- `/tmp/example:487-500,589-599,632-647` - reason"
        )
        self.assertIsNotNone(entries)
        self.assertEqual(
            [(entry["start"], entry["end"]) for entry in entries],
            [(487, 500), (589, 599), (632, 647)],
        )

    def test_unsupported_sed_expression_is_not_a_read(self: EscalationHookTest) -> None:
        """Unrecognized sed programs cannot clear an escalation."""
        self.assertEqual(parse_reads("sed -n '187,232p;d' /tmp/example", "/"), [])

    def test_whole_file_read_still_clears(self: EscalationHookTest) -> None:
        """A simple cat remains a recognized read of the entire file."""
        path = Path(__file__).resolve()
        self.assertEqual(
            parse_reads(f"cat {path}", str(path.parent)),
            [(path, None, None)],
        )


if __name__ == "__main__":
    unittest.main()
