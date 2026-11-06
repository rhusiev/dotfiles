"""Regression tests for recording commands started by agent-lock."""

from __future__ import annotations

import contextlib
import importlib.machinery
import importlib.util
import os
import signal
import sys
import tempfile
import time
import unittest
from pathlib import Path
from types import ModuleType
from unittest import mock


class AgentLockTest(unittest.TestCase):
    """Check that record failures leave no command running."""

    CHILD_SLEEP_S = 20
    CHILD_START_WAIT_S = 2
    CHILD_START_POLL_S = 0.01

    def _load_lock(self: AgentLockTest) -> ModuleType:
        name = "agent_lock_under_test"
        path = Path(__file__).with_name("agent-lock")
        loader = importlib.machinery.SourceFileLoader(name, str(path))
        spec = importlib.util.spec_from_loader(name, loader)
        assert spec is not None
        module = importlib.util.module_from_spec(spec)
        sys.modules[name] = module
        loader.exec_module(module)
        return module

    def test_directory_failure_does_not_start_command(self: AgentLockTest) -> None:
        """A bad record directory stops the command before launch."""
        lock = self._load_lock()
        with tempfile.TemporaryDirectory() as directory:
            resource = lock.Resource("test", Path(directory))
            resource.runs.write_text("not a directory")
            owner = lock.Owner(os.getpid(), "test", "test")
            with mock.patch.object(lock.subprocess, "Popen") as popen:
                with self.assertRaises(FileExistsError):
                    lock.start_run(resource, owner, ["/usr/bin/true"], 0)
            popen.assert_not_called()

    def test_record_failure_stops_started_command(self: AgentLockTest) -> None:
        """A command that starts but cannot be recorded is stopped."""
        lock = self._load_lock()
        with tempfile.TemporaryDirectory() as directory:
            resource = lock.Resource("test", Path(directory))
            owner = lock.Owner(os.getpid(), "test", "test")
            pid_path = Path(directory) / "child.pid"
            child_code = (
                "import os, pathlib, time; "
                f"pathlib.Path({str(pid_path)!r}).write_text(str(os.getpid())); "
                f"time.sleep({self.CHILD_SLEEP_S})"
            )

            def fail_write(_path: Path, _data: dict[str, object]) -> None:
                deadline = time.monotonic() + self.CHILD_START_WAIT_S
                while not pid_path.exists() and time.monotonic() < deadline:
                    time.sleep(self.CHILD_START_POLL_S)
                self.assertTrue(pid_path.exists(), "child did not start")
                raise OSError("forced record failure")

            try:
                with mock.patch.object(lock, "write_json", side_effect=fail_write):
                    with self.assertRaisesRegex(OSError, "forced record failure"):
                        lock.start_run(
                            resource, owner, [sys.executable, "-c", child_code], 0
                        )
                child_pid = int(pid_path.read_text())
                with self.assertRaises(ProcessLookupError):
                    os.kill(child_pid, 0)
            finally:
                if pid_path.exists():
                    child_pid = int(pid_path.read_text())
                    with contextlib.suppress(ProcessLookupError):
                        os.killpg(child_pid, signal.SIGKILL)


if __name__ == "__main__":
    unittest.main()
