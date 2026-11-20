"""Regression tests for recording commands started by agent-lock."""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import importlib.machinery
import importlib.util
import io
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from types import ModuleType
from typing import Any
from unittest import mock


class AgentLockTest(unittest.TestCase):
    """Check that record failures leave no command running."""

    CHILD_SLEEP_S = 20
    CHILD_START_WAIT_S = 2
    CHILD_START_POLL_S = 0.01

    def _load_lock(self: AgentLockTest) -> ModuleType:
        return load_lock_module()

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


def load_lock_module() -> ModuleType:
    """Load the script as a module so its helpers can be tested directly."""
    name = "agent_lock_under_test"
    path = Path(__file__).with_name("agent-lock")
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    loader.exec_module(module)
    return module


class AgentLockConfigTest(unittest.TestCase):
    """Check limit parsing and slot paths without touching the live state."""

    def test_missing_limit_defaults_to_one(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(lock.read_limit(Path(directory), "res"), 1)

    def test_valid_limit_is_read(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / "res.limit").write_text(" 3 \n")
            self.assertEqual(lock.read_limit(Path(directory), "res"), 3)

    def test_invalid_limits_are_rejected(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        for text in ("0", "two", "-1", "١", str(lock.MAX_SLOTS + 1)):
            with self.subTest(text=text), tempfile.TemporaryDirectory() as directory:
                (Path(directory) / "res.limit").write_text(text)
                with self.assertRaises(lock.ConfigError):
                    lock.read_limit(Path(directory), "res")

    def test_status_shows_a_live_stray_slot(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            path = state / "res.0.lock"
            fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o644)
            try:
                fcntl.flock(fd, fcntl.LOCK_EX)
                holder = lock.Holder(
                    pid=os.getpid(),
                    started=lock.start_time_live(os.getpid()) or "",
                    mode=lock.LEASE,
                    owner_key="key",
                    owner_pid=os.getpid(),
                    owner_label="test owner",
                    purpose="test",
                    since=time.time(),
                )
                lock.write_json(state / "res.0.json", lock.asdict(holder))
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    lock.cmd_status(state, "res")
                self.assertIn("res[0]: held by test owner", output.getvalue())
            finally:
                os.close(fd)

    def test_group_is_ours_when_start_was_not_recorded(
        self: AgentLockConfigTest,
    ) -> None:
        lock = load_lock_module()
        pid = os.getpid()
        run = lock.RunRecord(
            runner_pid=pid,
            runner_started="",
            owner_key="key",
            owner_label="test",
            command="cmd",
            cmd_pid=pid,
            cmd_started="",
            deadline=None,
        )
        with mock.patch.object(
            lock, "ps_rows", return_value=[(pid, pid, "started", "cmd")]
        ):
            self.assertTrue(lock.is_our_group(run))

    def test_slots_have_independent_paths(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            group = lock.ResourceGroup("res", Path(directory), 2)
            first, second = group.slots
            self.assertEqual(first.lock.name, "res.0.lock")
            self.assertEqual(second.record.name, "res.1.json")
            self.assertNotEqual(first.runs_lock, second.runs_lock)
            self.assertEqual(group.slots[0].path("json"), group.slots[0].record)

    def test_mutex_keeps_legacy_paths(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            group = lock.ResourceGroup("res", Path(directory), 1)
            slot = group.slots[0]
            self.assertEqual(slot.lock.name, "res.lock")
            self.assertEqual(slot.runs.name, "res.runs")
            self.assertEqual(group.label(slot), "res")

    def test_stray_slot_files_are_detected(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.0.lock").write_text("")
            (state / "res.2.lock").write_text("")
            (state / "res.runs.lock").write_text("")
            mutex = lock.ResourceGroup("res", state, 1)
            self.assertEqual(lock.stray_slots(mutex), [0, 2])
            sema = lock.ResourceGroup("res", state, 2)
            self.assertEqual(lock.stray_slots(sema), [2])

    def test_non_head_cannot_take_a_free_slot(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            group = lock.ResourceGroup("res", Path(directory), 1)
            group.queue.mkdir()
            started = lock.start_time(os.getpid()) or ""
            head = lock.Waiter(1, 0, os.getpid(), started, "head")
            other = lock.Waiter(2, 0, os.getpid(), started, "other")
            for waiter in (head, other):
                lock.write_json(lock.waiter_path(group, waiter), lock.asdict(waiter))
            self.assertIsNone(lock.take_head_slot(group, other))
            self.assertFalse(lock.is_locked(group.slots[0]))
            taken = lock.take_head_slot(group, head)
            self.assertIsNotNone(taken)
            if taken is not None:
                os.close(taken[1])

    def test_waiters_sort_by_priority_then_arrival(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            group = lock.ResourceGroup("res", Path(directory), 1)
            group.queue.mkdir()
            started = lock.start_time(os.getpid()) or ""
            waiters = [
                lock.Waiter(1, 0, os.getpid(), started, "low"),
                lock.Waiter(2, 10, os.getpid(), started, "high"),
                lock.Waiter(3, 0, os.getpid(), started, "late"),
            ]
            for waiter in waiters:
                lock.write_json(lock.waiter_path(group, waiter), lock.asdict(waiter))
            ordered = lock.live_waiters(group)
            self.assertEqual([w.owner_label for w in ordered], ["high", "low", "late"])

    def test_dead_waiters_are_pruned(self: AgentLockConfigTest) -> None:
        lock = load_lock_module()
        child = subprocess.Popen([sys.executable, "-c", "pass"])
        child.wait()
        with tempfile.TemporaryDirectory() as directory:
            group = lock.ResourceGroup("res", Path(directory), 1)
            group.queue.mkdir()
            path = group.queue / "stale.json"
            lock.write_json(
                path,
                lock.asdict(lock.Waiter(1, 0, child.pid, "long gone", "dead")),
            )
            self.assertEqual(lock.live_waiters(group), [])
            self.assertFalse(path.exists())


class AgentLockRecoveryTest(unittest.TestCase):
    """Check cleanup and error paths that keep the resource safe."""

    def _run_record(
        self: AgentLockRecoveryTest, lock: ModuleType, res: Any, started: str
    ) -> Path:
        owner = lock.Owner(os.getpid(), "started", "test")
        run = lock.RunRecord(
            runner_pid=os.getpid(),
            runner_started=started,
            owner_key=owner.key,
            owner_label="test",
            command="cmd",
            cmd_pid=os.getpid(),
            cmd_started=started,
            deadline=time.time() + 60,
        )
        path = res.runs / f"{os.getpid()}.json"
        lock.write_json(path, lock.asdict(run))
        return path

    def test_reap_keeps_record_while_command_is_still_alive(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            res = lock.Resource("res", Path(directory))
            res.runs.mkdir()
            path = self._run_record(lock, res, "")
            with mock.patch.object(lock, "is_our_group", return_value=True):
                with mock.patch.object(lock, "terminate_group", return_value=False):
                    lock.reap_orphans(res)
            self.assertTrue(path.exists(), "an alive command needs a kept record")
            with mock.patch.object(lock, "is_our_group", return_value=True):
                with mock.patch.object(lock, "terminate_group", return_value=True):
                    lock.reap_orphans(res)
            self.assertFalse(path.exists())

    def test_reap_dead_runners_leaves_live_runs_alone(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            res = lock.Resource("res", Path(directory))
            res.runs.mkdir()
            started = lock.start_time(os.getpid()) or ""
            live = self._run_record(lock, res, started)
            with mock.patch.object(lock, "is_our_group", return_value=True):
                with mock.patch.object(lock, "terminate_group") as terminate:
                    lock.reap_dead_runners(res)
            terminate.assert_not_called()
            self.assertTrue(live.exists())
            live.unlink()
            dead = self._run_record(lock, res, "")
            with mock.patch.object(lock, "is_our_group", return_value=True):
                with mock.patch.object(lock, "terminate_group") as terminate:
                    lock.reap_dead_runners(res)
            terminate.assert_called_once()
            self.assertFalse(dead.exists())

    def test_acquire_slot_notices_a_lease_created_while_waiting(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            group = lock.ResourceGroup("res", state, 1)
            owner = lock.Owner(os.getpid(), "started", "test")
            waiter = lock.Waiter(1, 0, os.getpid(), "started", "test")
            with mock.patch.object(
                lock, "register_waiter", return_value=(waiter, state / "waiter.json")
            ):
                with mock.patch.object(
                    lock, "find_lease", side_effect=[None, group.slots[0]]
                ):
                    with mock.patch.object(lock, "take_head_slot", return_value=None):
                        result = lock.acquire_slot(group, owner, 5, 0)
            self.assertIsNone(result)

    def test_zombie_waiter_is_pruned(self: AgentLockRecoveryTest) -> None:
        lock = load_lock_module()
        child = subprocess.Popen(
            [sys.executable, "-c", "pass"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:

            def is_zombie() -> bool:
                result = subprocess.run(
                    ["ps", "-o", "stat=", "-p", str(child.pid)],
                    capture_output=True,
                    text=True,
                )
                return result.stdout.strip().startswith("Z")

            deadline = time.monotonic() + 5
            while not is_zombie() and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue(is_zombie(), "the child should become a zombie")
            lock._process_info_bucket.cache_clear()
            with tempfile.TemporaryDirectory() as directory:
                group = lock.ResourceGroup("res", Path(directory), 1)
                group.queue.mkdir()
                waiter = lock.Waiter(
                    1, 0, child.pid, lock.start_time_live(child.pid) or "", "zombie"
                )
                lock.write_json(lock.waiter_path(group, waiter), lock.asdict(waiter))
                self.assertFalse(lock.process_alive(child.pid))
                self.assertEqual(lock.live_waiters(group), [])
        finally:
            child.wait()

    def test_parse_start_from_c_locale_string(self: AgentLockRecoveryTest) -> None:
        lock = load_lock_module()
        self.assertGreater(lock.parse_start("Fri Nov 20 21:50:18 2026"), 0)

    def test_state_dir_is_absolute(self: AgentLockRecoveryTest) -> None:
        lock = load_lock_module()
        with mock.patch.dict(os.environ, {lock.STATE_DIR_ENV: "relative/path"}):
            self.assertTrue(lock.state_dir().is_absolute())

    def test_acquire_publishes_no_lease_during_claim(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            group = lock.ResourceGroup("res", Path(directory), 1)
            owner = lock.Owner(os.getpid(), "started", "test")
            res = group.slots[0]
            fd = os.open(res.lock, os.O_RDWR | os.O_CREAT, 0o644)
            args = argparse.Namespace(purpose="test", idle=0, wait=1, priority=0)

            def during_claim(_res: Any) -> None:
                self.assertFalse(res.record.exists())

            with mock.patch.object(lock, "acquire_slot", return_value=(res, fd)):
                with mock.patch.object(lock, "claim", side_effect=during_claim):
                    with mock.patch.object(lock, "start_holder", return_value=True):
                        self.assertEqual(
                            lock.acquire_under_owner_lock(group, owner, args), 0
                        )

    def test_owner_lock_is_keyed_by_owner_and_resource(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        first = lock.Owner(11, "started", "first")
        second = lock.Owner(22, "started", "second")
        self.assertNotEqual(
            lock.owner_lock(Path("/tmp"), "res", first),
            lock.owner_lock(Path("/tmp"), "res", second),
        )
        self.assertNotEqual(
            lock.owner_lock(Path("/tmp"), "res", first),
            lock.owner_lock(Path("/tmp"), "other", first),
        )

    def test_session_variable_matches_the_detected_agent(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        values = {
            "CLAUDE_CODE_SESSION_ID": "claude-session",
            "OPENCODE_SESSION_ID": "opencode-session",
        }
        with mock.patch.dict(os.environ, values):
            self.assertEqual(lock.env_session("claude"), "claude-session")
            self.assertEqual(lock.env_session("opencode"), "opencode-session")

    def test_unmapped_agent_has_no_session(self: AgentLockRecoveryTest) -> None:
        lock = load_lock_module()
        values = {
            "CLAUDE_CODE_SESSION_ID": "claude-session",
            "OPENCODE_SESSION_ID": "opencode-session",
        }
        with mock.patch.dict(os.environ, values):
            self.assertEqual(lock.env_session("codex"), "")

    def test_oversized_limit_is_a_config_error(self: AgentLockRecoveryTest) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / "res.limit").write_text("9" * 5000)
            with self.assertRaises(lock.ConfigError):
                lock.read_limit(Path(directory), "res")

    def test_oversized_duration_is_an_argument_error(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with self.assertRaises(argparse.ArgumentTypeError):
            lock.duration("9" * 400)

    def test_claim_times_out_and_reports_the_blocker(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            res = lock.Resource("res", Path(directory))
            fd = os.open(res.runs_lock, os.O_RDWR | os.O_CREAT, 0o644)
            try:
                fcntl.flock(fd, fcntl.LOCK_EX)
                stderr = io.StringIO()
                with mock.patch.object(lock, "CLAIM_TIMEOUT_S", 0.2):
                    with mock.patch.object(lock, "CLAIM_NOTICE_S", 0.05):
                        with mock.patch.object(lock, "WAIT_POLL_S", 0.01):
                            with contextlib.redirect_stderr(stderr):
                                with self.assertRaises(lock.BusyError):
                                    lock.claim(res)
                self.assertIn("still waiting to claim res", stderr.getvalue())
            finally:
                os.close(fd)

    def test_extend_accumulates_under_a_slot_lock(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            res = lock.Resource("res", Path(directory))
            res.runs.mkdir()
            started = lock.start_time(os.getpid()) or ""
            path = self._run_record(lock, res, started)
            original = lock.read_json(path)["deadline"]
            owner = lock.Owner(os.getpid(), "started", "test")
            self.assertEqual(lock.extend_slot(res, owner, 5), 1)
            self.assertEqual(lock.extend_slot(res, owner, 5), 1)
            self.assertAlmostEqual(
                lock.read_json(path)["deadline"], original + 10, delta=1
            )
            self.assertTrue(res.extend_lock.exists())

    def test_start_holder_failure_returns_false(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        owner = lock.Owner(os.getpid(), "started", "test")
        with mock.patch.object(lock.os, "pipe", return_value=(11, 12)):
            with mock.patch.object(lock.os, "fork", return_value=1):
                with mock.patch.object(
                    lock.select, "select", return_value=([], [], [])
                ):
                    with mock.patch.object(lock.os, "close"):
                        with mock.patch.object(lock.os, "kill"):
                            self.assertFalse(
                                lock.start_holder(
                                    lock.Resource("res", Path("/tmp")), 9, owner, "", 0
                                )
                            )

    def test_dead_holder_is_not_reported_as_unrecorded(
        self: AgentLockRecoveryTest,
    ) -> None:
        lock = load_lock_module()
        with tempfile.TemporaryDirectory() as directory:
            res = lock.Resource("res", Path(directory))
            fd = os.open(res.lock, os.O_RDWR | os.O_CREAT, 0o644)
            try:
                fcntl.flock(fd, fcntl.LOCK_EX)
                holder = lock.Holder(
                    pid=os.getpid(),
                    started="long gone",
                    mode=lock.LEASE,
                    owner_key="key",
                    owner_pid=os.getpid(),
                    owner_label="old owner",
                    purpose="",
                    since=time.time(),
                )
                lock.write_json(res.record, lock.asdict(holder))
                self.assertIn("dead holder", lock.describe_lock(res))
            finally:
                os.close(fd)


class AgentLockSemaphoreTest(unittest.TestCase):
    """Exercise the lock through its command line with a private state dir."""

    LOCK_PATH = Path(__file__).with_name("agent-lock")
    POLL_S = 0.05
    START_TIMEOUT_S = 6
    QUIET_S = 1
    CHILD_SLEEP_S = 8

    def _wait_for(self: AgentLockSemaphoreTest, predicate, timeout_s: float) -> bool:
        deadline = time.monotonic() + timeout_s
        while time.monotonic() < deadline:
            if predicate():
                return True
            time.sleep(self.POLL_S)
        return predicate()

    def _child_code(self: AgentLockSemaphoreTest, marker: Path, sleep_s: float) -> str:
        return (
            "import pathlib, time; "
            f"pathlib.Path({str(marker)!r}).write_text('x'); "
            f"time.sleep({sleep_s})"
        )

    def _start_code(
        self: AgentLockSemaphoreTest,
        state: Path,
        name: str,
        code: str,
        priority: int | None = None,
    ) -> subprocess.Popen[bytes]:
        command = [
            sys.executable,
            str(self.LOCK_PATH),
            "run",
            name,
            "--wait",
            "10s",
            "--timeout",
            "30s",
        ]
        if priority is not None:
            command += ["--priority", str(priority)]
        command += ["--", sys.executable, "-c", code]
        env = {**os.environ, "AGENT_LOCK_DIR": str(state)}
        return subprocess.Popen(
            command, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )

    def _start(
        self: AgentLockSemaphoreTest,
        state: Path,
        name: str,
        marker: Path,
        priority: int | None = None,
        sleep_s: float | None = None,
    ) -> subprocess.Popen[bytes]:
        hold_s = self.CHILD_SLEEP_S if sleep_s is None else sleep_s
        return self._start_code(
            state, name, self._child_code(marker, hold_s), priority
        )

    def _cli(
        self: AgentLockSemaphoreTest, state: Path, *arguments: str
    ) -> subprocess.CompletedProcess[bytes]:
        env = {**os.environ, "AGENT_LOCK_DIR": str(state)}
        return subprocess.run(
            [sys.executable, str(self.LOCK_PATH), *arguments],
            env=env,
            capture_output=True,
            timeout=15,
        )

    def _stop(
        self: AgentLockSemaphoreTest, procs: list[subprocess.Popen[bytes]]
    ) -> None:
        for proc in procs:
            if proc.poll() is None:
                proc.terminate()
        for proc in procs:
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()

    def test_limit_allows_two_holders_and_blocks_the_third(
        self: AgentLockSemaphoreTest,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "sema.limit").write_text("2\n")
            markers = [state / "first", state / "second", state / "third"]
            procs = [self._start(state, "sema", marker) for marker in markers]
            try:
                self.assertTrue(
                    self._wait_for(
                        lambda: sum(m.exists() for m in markers) == 2,
                        self.START_TIMEOUT_S,
                    ),
                    "exactly two holders should run at once",
                )
                time.sleep(self.QUIET_S)
                self.assertEqual(
                    sum(m.exists() for m in markers), 2, "no third holder may run"
                )
                winners = [
                    proc
                    for proc, marker in zip(procs, markers)
                    if marker.exists()
                ]
                waiter = next(
                    proc for proc, marker in zip(procs, markers) if not marker.exists()
                )
                self._stop(winners)
                self.assertTrue(
                    self._wait_for(
                        lambda: all(m.exists() for m in markers), self.START_TIMEOUT_S
                    ),
                    "the waiting holder should take a freed slot",
                )
            finally:
                self._stop(procs)

    def test_priority_waits_before_a_lower_priority_waiter(
        self: AgentLockSemaphoreTest,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            low_marker = state / "low"
            medium_marker = state / "medium"
            high_marker = state / "high"
            low = self._start(state, "prio", low_marker)
            medium = None
            high = None
            try:
                self.assertTrue(
                    self._wait_for(lambda: low_marker.exists(), self.START_TIMEOUT_S),
                    "the first holder should run before the waiters start",
                )
                medium = self._start(
                    state, "prio", medium_marker, priority=0, sleep_s=1
                )
                high = self._start(
                    state, "prio", high_marker, priority=10, sleep_s=1
                )
                time.sleep(self.QUIET_S)
                queue = state / "prio.queue"
                self.assertTrue(
                    self._wait_for(
                        lambda: len(list(queue.glob("*.json"))) == 2,
                        self.START_TIMEOUT_S,
                    ),
                    "both waiters should be registered",
                )
                self._stop([low])
                self.assertTrue(
                    self._wait_for(
                        lambda: high_marker.exists(), self.START_TIMEOUT_S
                    ),
                    "the higher priority waiter should go first",
                )
                self.assertFalse(
                    medium_marker.exists(),
                    "the lower priority waiter must wait for the slot",
                )
                self.assertTrue(
                    self._wait_for(
                        lambda: medium_marker.exists(), self.START_TIMEOUT_S
                    ),
                    "the lower priority waiter should run afterwards",
                )
            finally:
                self._stop([p for p in [low, medium, high] if p is not None])


    def test_exit_codes_for_bad_config_and_busy(self: AgentLockSemaphoreTest) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.limit").write_text("nope")
            invalid = self._cli(
                state, "run", "res", "--wait", "0s", "--", sys.executable, "-c", "pass"
            )
            self.assertEqual(invalid.returncode, 2)
            self.assertEqual(self._cli(state, "status").returncode, 2)
            (state / "res.limit").write_text("1")
            marker = state / "held"
            holder = self._start(state, "res", marker, sleep_s=8)
            try:
                self.assertTrue(
                    self._wait_for(lambda: marker.exists(), self.START_TIMEOUT_S)
                )
                busy = self._cli(
                    state,
                    "run",
                    "res",
                    "--wait",
                    "0s",
                    "--",
                    sys.executable,
                    "-c",
                    "pass",
                )
                self.assertEqual(busy.returncode, 75)
            finally:
                self._stop([holder])

    def test_killed_waiter_does_not_block_a_later_waiter(
        self: AgentLockSemaphoreTest,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.limit").write_text("1")
            holder_marker = state / "holder"
            second_marker = state / "second"
            holder = self._start(state, "res", holder_marker, sleep_s=8)
            killed = None
            try:
                self.assertTrue(
                    self._wait_for(
                        lambda: holder_marker.exists(), self.START_TIMEOUT_S
                    ),
                    "the holder should run before the waiter starts",
                )
                killed = self._start(state, "res", state / "killed", sleep_s=1)
                queue = state / "res.queue"
                self.assertTrue(
                    self._wait_for(
                        lambda: len(list(queue.glob("*.json"))) == 1,
                        self.START_TIMEOUT_S,
                    )
                )
                killed.kill()
                killed.wait()
                second = self._start(state, "res", second_marker, sleep_s=1)
                try:
                    self._stop([holder])
                    self.assertTrue(
                        self._wait_for(
                            lambda: second_marker.exists(), self.START_TIMEOUT_S
                        ),
                        "a stale waiter must not block the queue",
                    )
                finally:
                    self._stop([second])
            finally:
                self._stop([p for p in [holder, killed] if p is not None])

    def test_lease_runs_on_a_limited_resource(self: AgentLockSemaphoreTest) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.limit").write_text("2")
            self.assertEqual(
                self._cli(state, "acquire", "res", "--purpose", "test").returncode, 0
            )
            try:
                status = self._cli(state, "status").stdout.decode()
                self.assertIn("2 slots", status)
                self.assertIn("res[", status)
                self.assertIn("held by", status)
                run = self._cli(
                    state,
                    "run",
                    "res",
                    "--wait",
                    "0s",
                    "--",
                    sys.executable,
                    "-c",
                    "pass",
                )
                self.assertEqual(run.returncode, 0)
            finally:
                self.assertEqual(self._cli(state, "release", "res").returncode, 0)


    def test_lease_run_reaps_a_command_with_a_dead_runner(
        self: AgentLockSemaphoreTest,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            self.assertEqual(self._cli(state, "acquire", "res").returncode, 0)
            pid_path = state / "child.pid"
            first_marker = state / "first"
            second_marker = state / "second"
            code = (
                "import os, pathlib, time; "
                f"pathlib.Path({str(pid_path)!r}).write_text(str(os.getpid())); "
                f"pathlib.Path({str(first_marker)!r}).write_text('x'); "
                "time.sleep(8)"
            )
            first = self._start_code(state, "res", code)
            second = None
            try:
                self.assertTrue(
                    self._wait_for(
                        lambda: first_marker.exists(), self.START_TIMEOUT_S
                    )
                )
                child_pid = int(pid_path.read_text())
                first.kill()
                first.wait()
                try:
                    os.kill(child_pid, 0)
                except ProcessLookupError:
                    self.fail("the child should outlive a SIGKILLed runner")
                second = self._start(state, "res", second_marker, sleep_s=1)
                self.assertTrue(
                    self._wait_for(
                        lambda: second_marker.exists(), self.START_TIMEOUT_S
                    ),
                    "a new run should start under the lease",
                )

                def child_gone() -> bool:
                    try:
                        os.kill(child_pid, 0)
                    except ProcessLookupError:
                        return True
                    return False

                self.assertTrue(
                    self._wait_for(child_gone, self.START_TIMEOUT_S),
                    "the orphaned command should be reaped",
                )
            finally:
                self._stop([p for p in [first, second] if p is not None])
                self._cli(state, "release", "res")


    def test_break_does_not_kill_processes_that_only_hold_the_fd(
        self: AgentLockSemaphoreTest,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.limit").write_text("2\n")
            lock_path = state / "res.1.lock"
            marker = state / "held"
            holder_code = (
                "import fcntl, os, pathlib, time; "
                f"fd = os.open({str(lock_path)!r}, os.O_RDWR | os.O_CREAT, 0o644); "
                "fcntl.flock(fd, fcntl.LOCK_EX); "
                f"pathlib.Path({str(marker)!r}).write_text('x'); "
                "time.sleep(30)"
            )
            bystander_code = (
                "import os, pathlib, time; "
                f"fd = os.open({str(lock_path)!r}, os.O_RDWR | os.O_CREAT, 0o644); "
                f"pathlib.Path({str(state / 'bystander')!r}).write_text('x'); "
                "time.sleep(30)"
            )
            processes = [
                subprocess.Popen(
                    [sys.executable, "-c", code],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                for code in (holder_code, bystander_code)
            ]
            try:
                self.assertTrue(
                    self._wait_for(
                        lambda: marker.exists() and (state / "bystander").exists(),
                        self.START_TIMEOUT_S,
                    )
                )
                (state / "res.limit").write_text("1\n")
                blocked = self._cli(
                    state,
                    "run",
                    "res",
                    "--wait",
                    "0s",
                    "--",
                    sys.executable,
                    "-c",
                    "pass",
                )
                self.assertEqual(blocked.returncode, 2)
                self.assertEqual(
                    self._cli(state, "break", "res", "--slot", "5").returncode, 2
                )
                broken = self._cli(state, "break", "res", "--slot", "1")
                self.assertEqual(broken.returncode, 1)
                self.assertIn(b"no holder record", broken.stderr)
                for process in processes:
                    self.assertIsNone(process.poll(), "a bystander must survive break")
            finally:
                for process in processes:
                    if process.poll() is None:
                        process.kill()
                        process.wait()

    def test_priority_holds_with_two_slots(self: AgentLockSemaphoreTest) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.limit").write_text("2\n")
            first = state / "first"
            second = state / "second"
            high = state / "high"
            low = state / "low"
            holders = [self._start(state, "res", m, sleep_s=8) for m in (first, second)]
            waiters = []
            try:
                self.assertTrue(
                    self._wait_for(
                        lambda: first.exists() and second.exists(),
                        self.START_TIMEOUT_S,
                    )
                )
                waiters.append(self._start(state, "res", low, priority=0, sleep_s=1))
                waiters.append(self._start(state, "res", high, priority=10, sleep_s=1))
                time.sleep(self.QUIET_S)
                queue = state / "res.queue"
                self.assertTrue(
                    self._wait_for(
                        lambda: len(list(queue.glob("*.json"))) == 2,
                        self.START_TIMEOUT_S,
                    )
                )
                self._stop([holders[0]])
                self.assertTrue(
                    self._wait_for(lambda: high.exists(), self.START_TIMEOUT_S)
                )
                self.assertFalse(low.exists())
            finally:
                self._stop(holders + waiters)


    def test_concurrent_acquire_by_one_owner_creates_one_lease(
        self: AgentLockSemaphoreTest,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.limit").write_text("4\n")
            processes = []
            for index in range(6):
                env = {**os.environ, "AGENT_LOCK_DIR": str(state)}
                processes.append(
                    subprocess.Popen(
                        [
                            sys.executable,
                            str(self.LOCK_PATH),
                            "acquire",
                            "res",
                            "--purpose",
                            f"p{index}",
                        ],
                        env=env,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                    )
                )
            try:
                deadline = time.monotonic() + self.START_TIMEOUT_S
                while time.monotonic() < deadline:
                    if all(proc.poll() is not None for proc in processes):
                        break
                    time.sleep(self.POLL_S)
                self.assertTrue(
                    all(proc.poll() is not None for proc in processes),
                    "all acquires should finish",
                )
                records = list(state.glob("res.[0-9].json"))
                self.assertEqual(
                    len(records), 1, "one owner must not hold several leases"
                )
            finally:
                self._stop(processes)
                self._cli(state, "release", "res")


    def test_run_waits_while_a_lease_is_being_established(
        self: AgentLockSemaphoreTest,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "res.limit").write_text("1\n")
            stale_marker = state / "stale"
            code = (
                "import pathlib, signal, time; "
                "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                f"pathlib.Path({str(stale_marker)!r}).write_text('x'); "
                "time.sleep(30)"
            )
            stale = subprocess.Popen(
                [sys.executable, "-c", code],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            acquire = None
            runner = None
            try:
                self.assertTrue(
                    self._wait_for(lambda: stale_marker.exists(), self.START_TIMEOUT_S)
                )
                started = subprocess.run(
                    ["ps", "-o", "lstart=", "-p", str(stale.pid)],
                    capture_output=True,
                    text=True,
                ).stdout.strip()
                (state / "res.runs").mkdir()
                record = {
                    "runner_pid": os.getpid(),
                    "runner_started": "",
                    "owner_key": "other",
                    "owner_label": "other",
                    "command": "stale",
                    "cmd_pid": stale.pid,
                    "cmd_started": started,
                    "deadline": None,
                }
                (state / "res.runs" / f"{os.getpid()}.json").write_text(
                    json.dumps(record)
                )
                env = {**os.environ, "AGENT_LOCK_DIR": str(state)}
                acquire = subprocess.Popen(
                    [sys.executable, str(self.LOCK_PATH), "acquire", "res"],
                    env=env,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                time.sleep(self.QUIET_S)
                marker = state / "runner"
                runner = self._start(state, "res", marker, sleep_s=1)
                self.assertFalse(
                    marker.exists(), "a run must not start under a lease being claimed"
                )
                self.assertTrue(
                    self._wait_for(lambda: marker.exists(), self.START_TIMEOUT_S),
                    "the run should start once the lease is ready",
                )
            finally:
                self._stop([p for p in [acquire, runner] if p is not None])
                if stale.poll() is None:
                    stale.kill()
                    stale.wait()
                self._cli(state, "release", "res")


    def test_break_slot_is_rejected_for_a_mutex(self: AgentLockSemaphoreTest) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            result = self._cli(state, "break", "res", "--slot", "0")
            self.assertEqual(result.returncode, 2)
            self.assertFalse((state / "res.0.lock").exists())


if __name__ == "__main__":
    unittest.main()
