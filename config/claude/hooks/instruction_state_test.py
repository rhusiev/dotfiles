"""Regression tests for instruction freshness and supported runtime boundaries."""

from __future__ import annotations

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
import fcntl
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock
from types import ModuleType, SimpleNamespace

import instruction_state as state


class InstructionStateTest(unittest.TestCase):
    """Keep freshness acknowledgements separate from path mentions and plan gates."""

    CALLBACK_TIMEOUT_S = 10

    def setUp(self) -> None:
        """Create isolated instruction sources and session state."""
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.files = [self.root / name for name in ("main.md", "local.md", "style.md")]
        for path in self.files:
            path.write_bytes(b"first line\nsecond line\n")
        self.event = {
            "session_id": "fixture",
            "cwd": str(self.root),
            "tool_name": "Edit",
            "tool_input": {"file_path": str(self.root / "output")},
            "instructions_injected": True,
        }
        for patch in (
            mock.patch.object(state, "ROOT", self.root / "sessions"),
            mock.patch.object(state, "sources", return_value=self.files),
        ):
            patch.start()
            self.addCleanup(patch.stop)
        state.startup_status(self.event, "claude")

    def read(self, path: Path, text: str | None = None, **extra: object) -> dict:
        """Build one paired complete Claude read fixture."""
        return {
            **self.event,
            "tool_name": "Read",
            "tool_use_id": "read-fixture",
            "tool_input": {"file_path": str(path)},
            "tool_response": path.read_bytes().decode() if text is None else text,
            **extra,
        }

    def change(self) -> Path:
        """Change a loaded instruction source."""
        self.files[0].write_bytes(b"changed line\nsecond line\n")
        return self.files[0]

    def concurrent_callbacks(
        self, callback: Callable[[dict, str], object], events: list[dict],
    ) -> None:
        """Release callbacks together and verify each load holds the real mutex."""
        barrier = threading.Barrier(len(events))
        original_load = state.load

        def guarded_load(event: dict, runtime: str, startup: bool = False) -> dict:
            path = state.state_path(event, runtime).with_suffix(".lock")
            with path.open("a+b") as probe:
                with self.assertRaises(BlockingIOError):
                    fcntl.flock(probe, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return original_load(event, runtime, startup=startup)

        def invoke(event: dict) -> None:
            barrier.wait(timeout=self.CALLBACK_TIMEOUT_S)
            callback(event, "claude")

        with mock.patch.object(state, "load", side_effect=guarded_load):
            with ThreadPoolExecutor(max_workers=len(events)) as executor:
                futures = [executor.submit(invoke, event) for event in events]
                for future in futures:
                    future.result(timeout=self.CALLBACK_TIMEOUT_S)

    def test_parallel_disjoint_chunks_preserve_pending_and_coverage(self) -> None:
        """Concurrent callbacks retain both chunks without a serial-read rule."""
        path = self.change()
        events = []
        for offset, text in enumerate(("changed line\n", "second line\n"), start=1):
            event = self.read(path, text, tool_use_id=f"parallel-{offset}")
            event["tool_input"].update({"offset": offset, "limit": 1})
            events.append(event)
        self.concurrent_callbacks(state.before_tool, events)
        self.assertEqual(len(state.load(self.event, "claude")["pending"]), 2)
        self.concurrent_callbacks(state.after_tool, events)
        self.assertEqual(state.load(self.event, "claude")["pending"], {})
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_parallel_changed_files_preserve_both_acknowledgements(self) -> None:
        """Concurrent results cannot discard another changed file's loaded digest."""
        events = []
        for index, path in enumerate(self.files[:2]):
            path.write_text(f"changed source {index}\n")
            events.append(self.read(path, tool_use_id=f"file-{index}"))
        self.concurrent_callbacks(state.before_tool, events)
        self.assertEqual(len(state.load(self.event, "claude")["pending"]), 2)
        self.concurrent_callbacks(state.after_tool, events)
        self.assertEqual(state.load(self.event, "claude")["pending"], {})
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_compaction_recovery_without_state_does_not_bless_disk(self) -> None:
        """Manufactured recovery cannot substitute for a real injection event."""
        adapter = self.copilot_adapter()
        event = adapter.normalize({"sessionId": "compact-fixture"})
        with (
            mock.patch.object(adapter, "load_hook", return_value=SimpleNamespace()),
            mock.patch.object(adapter, "call_hook", return_value="GLOBAL INSTRUCTIONS: fixture"),
            mock.patch.object(adapter, "recovery_path", return_value=self.root / "recovery.json"),
        ):
            adapter.pre_compact(event)
        observed = state.load(event, "copilot")
        self.assertEqual(observed["loaded"], {})
        self.assertEqual(state.changed_sources(observed, "copilot"), self.files)

    def test_compaction_recovery_preserves_valid_loaded_state(self) -> None:
        """Existing verified state survives recovery without unnecessary rereads."""
        adapter = self.copilot_adapter()
        event = adapter.normalize({"sessionId": "compact-fixture"})
        state.startup_status({**event, "instructions_injected": True}, "copilot")
        loaded = state.load(event, "copilot")["loaded"]
        with (
            mock.patch.object(adapter, "load_hook", return_value=SimpleNamespace()),
            mock.patch.object(adapter, "call_hook", return_value="GLOBAL INSTRUCTIONS: fixture"),
            mock.patch.object(adapter, "recovery_path", return_value=self.root / "recovery.json"),
        ):
            adapter.pre_compact(event)
        self.assertEqual(state.load(event, "copilot")["loaded"], loaded)
        self.assertEqual(state.changed_sources(state.load(event, "copilot"), "copilot"), [])

    def copilot_adapter(self) -> ModuleType:
        """Load only the worktree adapter, never installed runtime modules."""
        path = Path(__file__).resolve().parents[2] / "copilot/hooks/claude-parity.py"
        spec = importlib.util.spec_from_file_location("parity_recovery_fixture", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def native_read(
        self, path: Path, text: str, span: list[int] | None = None,
        **extra: object,
    ) -> dict:
        """Normalize an actual-shaped Copilot view request and successful result."""
        arguments: dict[str, object] = {"path": str(path)}
        if span is not None:
            arguments["view_range"] = span
        return self.copilot_adapter().normalize({
            "sessionId": "fixture",
            "toolName": "view",
            "toolCallId": "native-read",
            "arguments": arguments,
            "toolResult": {"resultType": "success", "textResultForLlm": text},
            **extra,
        })

    def test_current_snapshot_native_chunks_acknowledge_actual_source(self) -> None:
        """Read a current 52,600-byte copy without trusting its path as an alias."""
        path = self.files[0]
        data = (b"x" * 49 + b"\n") * 1052
        path.write_bytes(data)
        snapshot = self.root / "current-copy.md"
        snapshot.write_bytes(data)
        lines = data.decode().splitlines(keepends=True)
        for offset in range(0, len(lines), 200):
            last = min(offset + 200, len(lines))
            text = "".join(lines[offset:last])
            if last < len(lines):
                text = text[:-1]
            self.assertLess(len(text.encode()), 20000)
            event = self.native_read(snapshot, text, [offset + 1, last])
            state.before_tool(event, "copilot")
            pending = next(iter(state.load(event, "copilot")["pending"].values()))
            self.assertEqual(pending["path"], str(path))
            self.assertEqual(pending["digest"], state.fingerprint(path))
            self.assertEqual(pending["snapshot_path"], str(snapshot))
            self.assertEqual(pending["snapshot_digest"], state.fingerprint(snapshot))
            state.after_tool(event, "copilot")
            if last < len(lines):
                self.assertIn(path, state.changed_sources(state.load(event, "copilot"), "copilot"))
        self.assertEqual(state.load(event, "copilot")["loaded"][str(path)], state.fingerprint(path))

    def test_snapshot_chunks_support_claude_without_injected_baseline(self) -> None:
        """A copied-source read clears only verified ranges of a changed source."""
        path = self.change()
        snapshot = self.root / "copy.md"
        snapshot.write_bytes(path.read_bytes())
        events = []
        for offset, text in enumerate(path.read_text().splitlines(keepends=True), 1):
            event = self.read(snapshot, text, tool_use_id=f"copy-{offset}")
            event["tool_input"].update({"offset": offset, "limit": 1})
            events.append(event)
        self.concurrent_callbacks(state.before_tool, events)
        self.assertIn(path, state.changed_sources(state.load(self.event, "claude"), "claude"))
        self.concurrent_callbacks(state.after_tool, events)
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_stale_snapshot_matching_only_requested_chunk_is_refused(self) -> None:
        """A matching prefix cannot substitute for a matching whole-source digest."""
        path = self.files[0]
        snapshot = self.root / "stale.md"
        snapshot.write_bytes(path.read_bytes())
        path.write_text("first line\nchanged second line\n")
        event = self.read(snapshot, "first line\n")
        event["tool_input"].update({"offset": 1, "limit": 1})
        state.before_tool(event, "claude")
        self.assertEqual(state.load(event, "claude")["pending"], {})
        state.after_tool(event, "claude")
        self.assertNotIn(str(path), state.load(event, "claude")["coverage"])

    def test_changed_or_removed_snapshot_during_read_is_refused(self) -> None:
        """Post acknowledgement requires the same whole copy as the pre callback."""
        path = self.change()
        snapshot = self.root / "copy.md"
        for remove in (False, True):
            with self.subTest(remove=remove):
                snapshot.write_bytes(path.read_bytes())
                event = self.read(snapshot)
                state.before_tool(event, "claude")
                if remove:
                    snapshot.unlink()
                else:
                    snapshot.write_text("tampered copy\n")
                state.after_tool(event, "claude")
                self.assertIn(path, state.changed_sources(state.load(event, "claude"), "claude"))

    def test_source_change_during_snapshot_read_is_refused(self) -> None:
        """An unchanged copy does not acknowledge a source that advanced meanwhile."""
        path = self.change()
        snapshot = self.root / "copy.md"
        snapshot.write_bytes(path.read_bytes())
        event = self.read(snapshot)
        state.before_tool(event, "claude")
        path.write_text("a newer source\n")
        state.after_tool(event, "claude")
        self.assertIn(path, state.changed_sources(state.load(event, "claude"), "claude"))

    def test_source_and_copy_change_between_chunks_require_new_full_coverage(self) -> None:
        """A replacement snapshot cannot inherit coverage for the old source digest."""
        path = self.change()
        snapshot = self.root / "copy.md"
        snapshot.write_bytes(path.read_bytes())
        first = self.read(snapshot, "changed line\n")
        first["tool_input"]["limit"] = 1
        state.before_tool(first, "claude")
        state.after_tool(first, "claude")
        path.write_text("new first line\nnew second line\n")
        snapshot.write_bytes(path.read_bytes())
        second = self.read(snapshot, "new second line\n")
        second["tool_input"]["offset"] = 2
        state.before_tool(second, "claude")
        state.after_tool(second, "claude")
        self.assertIn(path, state.changed_sources(state.load(second, "claude"), "claude"))

    def test_snapshot_mentions_unpaired_failed_and_truncated_reads_do_not_acknowledge(self) -> None:
        """Copy equality alone is neither a read nor successful returned content."""
        path = self.change()
        snapshot = self.root / "copy.md"
        snapshot.write_bytes(path.read_bytes())
        state.after_tool(self.read(snapshot), "claude")
        self.assertIsNotNone(state.before_tool({
            **self.event, "tool_input": {"file_path": str(snapshot)},
        }, "claude"))
        for flags in ({"is_error": True}, {"truncated": True}):
            event = self.read(snapshot, **flags)
            state.before_tool(event, "claude")
            state.after_tool(event, "claude")
            self.assertIn(path, state.changed_sources(state.load(event, "claude"), "claude"))

    def test_native_view_accepts_only_non_eof_terminal_lf_omission(self) -> None:
        """Native bounded views retain all line content and strict EOF bytes."""
        path = self.change()
        first = self.native_read(path, "changed line", [1, 1])
        state.before_tool(first, "copilot")
        state.after_tool(first, "copilot")
        self.assertEqual(
            state.load(first, "copilot")["coverage"][str(path)]["intervals"],
            [[0, len(b"changed line\n")]],
        )
        last = self.native_read(path, "second line\n", [2, 2])
        state.before_tool(last, "copilot")
        state.after_tool(last, "copilot")
        self.assertEqual(state.load(last, "copilot")["loaded"][str(path)], state.fingerprint(path))

    def test_native_view_full_and_eof_reads_keep_strict_final_byte(self) -> None:
        """An EOF slice or full-file request must include the final LF."""
        path = self.change()
        for span in (None, [1, -1], [1, 2], [2, 2]):
            with self.subTest(span=span):
                text = "second line" if span == [2, 2] else path.read_text()[:-1]
                event = self.native_read(path, text, span)
                state.before_tool(event, "copilot")
                state.after_tool(event, "copilot")
                self.assertNotIn(str(path), state.load(event, "copilot")["coverage"])

    def test_native_view_rejects_lost_content_wrong_numbers_and_explicit_truncation(self) -> None:
        """The delimiter exception cannot conceal missing content or an error flag."""
        path = self.change()
        for text, flags in (
            ("changed lin", {}),
            ("changed line\n\n", {}),
            ("L2:changed line", {}),
            ("changed line", {"truncated": True}),
            ("changed line", {"success": False}),
            ("changed line", {"toolResult": {
                "resultType": "success", "textResultForLlm": "changed line",
                "truncated": True,
            }}),
        ):
            with self.subTest(text=text, flags=flags):
                event = self.native_read(path, text, [1, 1], **flags)
                state.before_tool(event, "copilot")
                state.after_tool(event, "copilot")
                self.assertNotIn(str(path), state.load(event, "copilot")["coverage"])

    def test_generic_read_cannot_claim_native_delimiter_exception(self) -> None:
        """Even view-shaped arguments cannot turn another tool into native view."""
        path = self.change()
        for runtime in ("claude", "codex", "copilot"):
            event = self.native_read(
                path, "changed line", [1, 1],
                toolName="Read", _copilot_native_view=True,
            )
            if runtime != "copilot":
                event["tool_response"] = "changed line"
            state.before_tool(event, runtime)
            state.after_tool(event, runtime)
            self.assertNotIn(str(path), state.load(event, runtime)["coverage"])

    def test_native_view_range_must_match_pre_and_normalized_span(self) -> None:
        """An altered post range or inconsistent offset cannot claim a read span."""
        path = self.change()
        path.write_text("changed line\nsecond line\nthird line\n")
        event = self.native_read(path, "changed line", [1, 1])
        state.before_tool(event, "copilot")
        event["tool_input"]["view_range"] = [2, 2]
        state.after_tool(event, "copilot")
        self.assertNotIn(str(path), state.load(event, "copilot")["coverage"])
        event = self.native_read(path, "second line", [1, 1])
        event["tool_input"]["offset"] = 2
        state.before_tool(event, "copilot")
        state.after_tool(event, "copilot")
        self.assertNotIn(str(path), state.load(event, "copilot")["coverage"])

    def test_native_slice_post_cannot_change_tool_kind(self) -> None:
        """A generic post result cannot borrow a native pre delimiter exception."""
        path = self.change()
        state.before_tool(self.native_read(path, "changed line", [1, 1]), "copilot")
        event = self.native_read(path, "changed line", [1, 1], toolName="Read")
        state.after_tool(event, "copilot")
        self.assertNotIn(str(path), state.load(event, "copilot")["coverage"])

    def test_native_view_does_not_normalize_crlf_or_drop_blank_lines(self) -> None:
        """Only one LF delimiter may differ, never CR bytes or blank-line content."""
        path = self.change()
        path.write_bytes(b"changed\r\n\r\nlast\r\n")
        for text in ("changed\n\n", "changed\r\n"):
            event = self.native_read(path, text, [1, 2])
            state.before_tool(event, "copilot")
            state.after_tool(event, "copilot")
            self.assertNotIn(str(path), state.load(event, "copilot")["coverage"])
        event = self.native_read(path, "changed\r\n\r", [1, 2])
        state.before_tool(event, "copilot")
        state.after_tool(event, "copilot")
        self.assertEqual(
            state.load(event, "copilot")["coverage"][str(path)]["intervals"],
            [[0, len(b"changed\r\n\r\n")]],
        )

    def test_change_blocks_mutations_not_recovery_reads(self) -> None:
        """A changed source blocks edits while unrelated reads remain usable."""
        path = self.change()
        self.assertIn(
            str(path),
            state.before_tool(self.event, "claude")["permissionDecisionReason"],
        )
        self.assertIsNone(state.before_tool(self.read(path), "claude"))
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_successful_complete_read_clears_exact_source(self) -> None:
        """Only matched complete returned bytes acknowledge the changed version."""
        event = self.read(self.change())
        state.before_tool(event, "claude")
        state.after_tool(event, "claude")
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_spoofed_post_without_pre_cannot_acknowledge(self) -> None:
        """A matching result alone is not a paired successful read."""
        state.after_tool(self.read(self.change()), "claude")
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_path_mention_does_not_acknowledge(self) -> None:
        """An edit mentioning the source cannot clear the freshness state."""
        path = self.change()
        event = {**self.event, "tool_input": {"file_path": str(path)}}
        self.assertIsNotNone(state.before_tool(event, "claude"))

    def test_failed_truncated_partial_and_changed_reads_do_not_acknowledge(self) -> None:
        """Failure and byte truncation cannot silently clear the gate."""
        path = self.change()
        for extra in ({"is_error": True}, {"truncated": True}):
            with self.subTest(extra=extra):
                event = self.read(path, **extra)
                state.before_tool(event, "claude")
                state.after_tool(event, "claude")
                self.assertIsNotNone(state.before_tool(self.event, "claude"))
        for text in ("changed line\n", path.read_text().rstrip("\n"), "spoof"):
            with self.subTest(text=text):
                event = self.read(path, text)
                state.before_tool(event, "claude")
                state.after_tool(event, "claude")
                self.assertIsNotNone(state.before_tool(self.event, "claude"))
        event = self.read(path)
        state.before_tool(event, "claude")
        path.write_text("changed again\n")
        state.after_tool(event, "claude")
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_partial_request_cannot_acknowledge_even_with_full_result(self) -> None:
        """A fabricated complete response cannot bless an unsupported request."""
        event = self.read(self.change())
        event["tool_input"]["limit"] = 1
        state.before_tool(event, "claude")
        state.after_tool(event, "claude")
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_printed_startup_status_does_not_acknowledge(self) -> None:
        """Repeated startup headers keep changed instructions pending."""
        self.change()
        for _ in range(2):
            self.assertIn("CHANGED", state.startup_status(self.event, "claude"))
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_unchanged_sources_do_not_require_repeated_reads(self) -> None:
        """A loaded unchanged baseline permits mutations without extra reads."""
        self.assertIsNone(state.before_tool(self.event, "claude"))
        self.assertIn("unchanged", state.startup_status(self.event, "claude"))

    def test_deleted_required_source_stays_blocked(self) -> None:
        """A missing mandatory source cannot become an acknowledged absence."""
        self.files[0].unlink()
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_new_and_deleted_optional_sources_are_detected(self) -> None:
        """Optional imported files receive freshness checks after installation."""
        self.files[1].unlink()
        self.assertIsNotNone(state.before_tool(self.event, "claude"))
        self.files[1].write_bytes(b"first line\nsecond line\n")
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_nested_agents_do_not_use_parent_state(self) -> None:
        """Nested events neither block nor acknowledge the parent's instructions."""
        nested = {**self.event, "agent_id": "worker"}
        self.change()
        self.assertIsNone(state.before_tool(nested, "claude"))
        self.assertEqual(state.startup_status(nested, "claude"), "")
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_shell_redirection_and_substitution_are_not_reads(self) -> None:
        """Recovery does not authorize mutation hidden inside a cat command."""
        for command in (
            f"cat {self.files[0]}>output",
            f"cat {self.files[0]};touch output",
            f"cat $(echo {self.files[0]})",
            f"cat {self.files[0]}\ntouch output",
        ):
            with self.subTest(command=command):
                event = {**self.event, "tool_name": "Bash", "tool_input": {"command": command}}
                self.assertIsNone(state.read_path(event))

    def test_exact_cat_supported_success_result(self) -> None:
        """A plain single-file shell read has a narrow successful result path."""
        path = self.change()
        event = {
            **self.event,
            "tool_name": "exec_command",
            "tool_input": {"cmd": f"cat -- {path}", "workdir": str(self.root)},
            "tool_response": {"exit_code": 0, "stdout": path.read_text()},
        }
        state.before_tool(event, "claude")
        state.after_tool(event, "claude")
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_copilot_result_shape_is_explicit(self) -> None:
        """Unsupported or failed native results never acknowledge instructions."""
        state.startup_status(self.event, "copilot")
        path = self.change()
        for result in ({}, {"resultType": "failure", "textResultForLlm": path.read_text()}):
            event = self.read(path, tool_response=result)
            state.before_tool(event, "copilot")
            state.after_tool(event, "copilot")
            self.assertIsNotNone(state.before_tool(self.event, "copilot"))
        event = self.read(path, tool_response={
            "resultType": "success", "textResultForLlm": path.read_text(),
        })
        state.before_tool(event, "copilot")
        state.after_tool(event, "copilot")
        self.assertIsNone(state.before_tool(self.event, "copilot"))

    def test_codex_imports_need_explicit_reads(self) -> None:
        """Codex startup does not pretend the runtime imports local modules."""
        state.startup_status(self.event, "codex")
        self.assertIsNotNone(state.before_tool(self.event, "codex"))
        for path in self.files[1:]:
            event = self.read(path)
            state.before_tool(event, "codex")
            state.after_tool(event, "codex")
        self.assertIsNone(state.before_tool(self.event, "codex"))

    def test_no_startup_event_does_not_claim_loaded_instructions(self) -> None:
        """Missing lifecycle events yield an unread gate, not fake parity."""
        event = {**self.event, "session_id": "no-start-event"}
        self.assertIsNotNone(state.before_tool(event, "claude"))

    def test_original_crlf_bytes_are_required(self) -> None:
        """Universal newline conversion cannot acknowledge a byte-mismatched read."""
        path = self.files[0]
        path.write_bytes(b"changed\r\nline\r\n")
        event = self.read(path, path.read_text())
        state.before_tool(event, "claude")
        state.after_tool(event, "claude")
        self.assertIsNotNone(state.before_tool(self.event, "claude"))

    def test_empty_source_cannot_acknowledge_an_added_newline(self) -> None:
        """Empty-file coverage still requires the exact original zero bytes."""
        path = self.files[0]
        path.write_bytes(b"")
        for text, loaded in (("\n", False), ("", True)):
            event = self.read(path, text)
            state.before_tool(event, "claude")
            state.after_tool(event, "claude")
            observed = state.load(event, "claude")
            self.assertEqual(path not in state.changed_sources(observed, "claude"), loaded)

    def test_large_source_uses_verified_bounded_numbered_chunks(self) -> None:
        """A real instruction-sized source needs no single result above 20KB."""
        path = self.files[0]
        data = (b"x" * 49 + b"\n") * 1052
        self.assertEqual(len(data), 52600)
        path.write_bytes(data)
        lines = data.decode().splitlines(keepends=True)
        for offset in range(0, len(lines), 200):
            chunk = lines[offset:offset + 200]
            numbered = "".join(
                f"L{offset + index + 1}:{line}" for index, line in enumerate(chunk)
            )
            self.assertLess(len(numbered.encode()), 20000)
            event = self.read(path, numbered)
            event["tool_use_id"] = f"chunk-{offset}"
            event["tool_input"].update({"offset": offset + 1, "limit": 200})
            state.before_tool(event, "claude")
            state.after_tool(event, "claude")
            if offset + 200 < len(lines):
                self.assertIn(path, state.changed_sources(state.load(event, "claude"), "claude"))
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_large_truncated_result_never_acknowledges_full_file(self) -> None:
        """Missing truncation metadata cannot conceal missing source bytes."""
        path = self.files[0]
        path.write_bytes((b"x" * 49 + b"\n") * 1052)
        event = self.read(path, path.read_text()[:20000])
        state.before_tool(event, "claude")
        state.after_tool(event, "claude")
        self.assertIn(path, state.changed_sources(state.load(event, "claude"), "claude"))

    def test_numbered_chunks_require_correct_numbers_and_metadata(self) -> None:
        """Decorations cannot claim coverage for a different source range."""
        path = self.change()
        for response in (
            "L2:changed line\n",
            {"file": {"content": "changed line\n", "startLine": 2, "numLines": 1}},
        ):
            event = self.read(path, tool_response=response)
            event["tool_input"]["limit"] = 1
            state.before_tool(event, "claude")
            state.after_tool(event, "claude")
            self.assertNotIn(str(path), state.load(event, "claude").get("coverage", {}))

    def test_source_change_between_chunks_invalidates_old_coverage(self) -> None:
        """A new source version cannot inherit verified ranges from the old one."""
        path = self.change()
        first = self.read(path, "changed line\n")
        first["tool_input"]["limit"] = 1
        state.before_tool(first, "claude")
        state.after_tool(first, "claude")
        path.write_text("changed line\nnew second line\n")
        second = self.read(path, "new second line\n")
        second["tool_input"]["offset"] = 2
        state.before_tool(second, "claude")
        state.after_tool(second, "claude")
        self.assertIn(path, state.changed_sources(state.load(second, "claude"), "claude"))

    def test_unsupported_transport_has_bounded_explicit_unguarded_recovery(self) -> None:
        """Denial exhaustion reports unread state instead of deadlock or fake ack."""
        path = self.change()
        for _ in range(state.GATE_MAX_DENIALS):
            self.assertEqual(state.before_tool(self.event, "claude")["permissionDecision"], "deny")
        output = state.before_tool(self.event, "claude")
        self.assertNotIn("permissionDecision", output)
        self.assertIn("UNGUARDED", output["additionalContext"])
        self.assertIn(path, state.changed_sources(state.load(self.event, "claude"), "claude"))
        event = self.read(path)
        state.before_tool(event, "claude")
        state.after_tool(event, "claude")
        self.assertIsNone(state.before_tool(self.event, "claude"))

    def test_expired_freshness_gate_reports_unread_without_permanent_denial(self) -> None:
        """Age expiry is explicit recovery and never a read acknowledgement."""
        path = self.change()
        state.before_tool(self.event, "claude")
        observed = state.load(self.event, "claude")
        observed["guard"]["started"] = time.time() - state.GATE_MAX_AGE_S - 1
        state.save(self.event, "claude", observed)
        output = state.before_tool(self.event, "claude")
        self.assertIn("UNGUARDED", output["additionalContext"])
        self.assertIn(path, state.changed_sources(state.load(self.event, "claude"), "claude"))

    def test_unsafe_session_and_runtime_are_refused(self) -> None:
        """State paths cannot escape their runtime/session namespace."""
        with self.assertRaises(ValueError):
            state.state_path({**self.event, "session_id": "../other"}, "claude")
        with self.assertRaises(ValueError):
            state.state_path(self.event, "unsupported")

    def test_corrupt_state_is_an_explicit_failure(self) -> None:
        """A malformed state container cannot imply loaded instructions."""
        state.state_path(self.event, "claude").write_text("[]")
        with self.assertRaisesRegex(ValueError, "Invalid instruction freshness state"):
            state.before_tool(self.event, "claude")


class RuntimeBoundaryTest(unittest.TestCase):
    """Test adapter normalization and the unchanged legacy gate behavior."""

    def test_copilot_native_normalization(self) -> None:
        """Normalize native arguments and preserve supported native results."""
        path = Path(__file__).resolve().parents[2] / "copilot/hooks/claude-parity.py"
        spec = importlib.util.spec_from_file_location("parity_fixture", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        event = module.normalize({
            "sessionId": "copilot-test",
            "toolName": "functions.view",
            "toolArgs": json.dumps({"path": "/tmp/instructions", "view_range": [1, -1]}),
            "toolResult": {"resultType": "success", "textResultForLlm": "text"},
        })
        self.assertEqual(event["session_id"], "copilot-test")
        self.assertEqual(event["tool_name"], "Read")
        self.assertEqual(event["tool_input"]["offset"], 1)
        self.assertNotIn("limit", event["tool_input"])
        self.assertEqual(event["tool_response"]["resultType"], "success")
        captured_shape = module.normalize({
            "sessionId": "fixture",
            "toolName": "view",
            "arguments": {"path": "/tmp/instructions", "view_range": [3, 5]},
            "success": True,
            "result": {"content": "line three\nline four\nline five\n"},
        })
        self.assertEqual(captured_shape["tool_input"]["limit"], 3)
        self.assertEqual(captured_shape["tool_response"]["textResultForLlm"], "line three\nline four\nline five\n")
        failed_shape = module.normalize({
            "sessionId": "fixture", "toolName": "view",
            "arguments": {"path": "/tmp/instructions"},
            "success": False, "result": {"content": "text"},
        })
        self.assertIsNone(failed_shape["tool_response"])

    def test_unsupported_hook_event_reports_failure(self) -> None:
        """Unknown events do not produce a success-shaped acknowledgement."""
        hook = Path(__file__).with_name("instruction-hook.py")
        result = subprocess.run(
            [sys.executable, str(hook), "claude", "unsupported"],
            input=json.dumps({"session_id": "test"}),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertIn("Unsupported instruction hook event", result.stderr)
        self.assertIn("FAILED", result.stdout)

    def test_nested_events_neither_arm_nor_clear_legacy_plan_gate(self) -> None:
        """The inherited parent plan state remains untouched by nested events."""
        for filename, state_function in (
            ("pre-tool-use.py", "load_gate"),
            ("session-start.py", "plan_for"),
            ("pre-compact.py", "topic_dir_for"),
        ):
            path = Path(__file__).with_name(filename)
            spec = importlib.util.spec_from_file_location(filename, path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            with (
                mock.patch.object(sys, "stdin", io.StringIO(
                    json.dumps({"agent_id": "nested", "session_id": "parent"}),
                )),
                mock.patch.object(module, state_function) as state_function_mock,
            ):
                module.main()
            state_function_mock.assert_not_called()

    def test_legacy_plan_denial_limit_still_fails_open(self) -> None:
        """Freshness hardening does not change the original plan-gate escape."""
        path = Path(__file__).with_name("pre-tool-use.py")
        spec = importlib.util.spec_from_file_location("legacy_plan_fixture", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        gate = {
            "plan": "/fixture/plan.md",
            "denials": module.GATE_MAX_DENIALS,
            "armed_at": time.time(),
        }
        with (
            mock.patch.object(sys, "stdin", io.StringIO(
                json.dumps({"session_id": "parent", "tool_input": {}}),
            )),
            mock.patch.object(module, "load_gate", return_value=gate),
            mock.patch.object(module, "disarm_gate") as disarm,
            mock.patch.object(module, "deny") as deny,
        ):
            module.main()
        disarm.assert_called_once_with("parent")
        deny.assert_not_called()


if __name__ == "__main__":
    unittest.main()
