"""Test checked execution, evidence identity and refusal before command launch."""

from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import venv

import agent_check as check


class AgentCheckTest(unittest.TestCase):
    """Exercise the helper against disposable real Git repositories."""

    PROCESS_TIMEOUT_S = 10

    def setUp(self) -> None:
        """Create a clean committed source and explicitly isolated Git config."""
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.repo = self.base / "source"
        self.repo.mkdir()
        self.environment = {
            **os.environ,
            "HOME": str(self.base),
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
        }
        environment = mock.patch.dict(os.environ, self.environment)
        environment.start()
        self.addCleanup(environment.stop)
        self.git("init", "-q")
        (self.repo / "source.txt").write_text("source\n")
        self.git("add", "source.txt")
        self.git(
            "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-qm", "fixture",
        )
        self.commit = self.git("rev-parse", "HEAD")
        self.receipt = self.base / "receipt.json"
        self.command = [sys.executable, "-c", "pass"]
        self.spec = {
            "version": 1,
            "kind": "check",
            "source": {
                "root": str(self.repo),
                "commit": self.commit,
                "required_ancestors": [self.commit],
            },
            "context": {
                "selection": "fixture", "platform": sys.platform,
                "toolchain": sys.version.split()[0], "features": "none",
            },
        }

    def git(self, *args: str) -> str:
        """Use Git with only per-subprocess test configuration."""
        return subprocess.check_output(
            ["git", "-C", str(self.repo), *args],
            env=self.environment,
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()

    def run_check(self, spec: dict | None = None, command: list[str] | None = None) -> int:
        """Run against the isolated source with an external atomic receipt."""
        return check.run(spec or self.spec, self.base, command or self.command, self.receipt)

    def status(self) -> str:
        """Return the persisted outcome."""
        return json.loads(self.receipt.read_text())["status"]

    def build(self) -> tuple[dict, list[str], Path]:
        """Produce a new artifact with a witnessed clean-source execution."""
        output = self.base / "artifact"
        spec = {**self.spec, "kind": "build", "outputs": [str(output)]}
        command = [
            sys.executable, "-c",
            "from pathlib import Path; Path(" + repr(str(output)) + ").write_text('binary')",
        ]
        self.assertEqual(self.run_check(spec, command), 0)
        return spec, command, output

    def consumer(self, artifact: Path) -> dict:
        """Pin the reviewed producer receipt and its exact artifact."""
        return {
            **self.spec,
            "artifacts": {str(artifact): check.digest_file(artifact)},
            "provenance": [{
                "receipt": str(self.receipt), "sha256": check.digest_file(self.receipt),
            }],
        }

    def test_success_and_exact_evidence_reuse(self) -> None:
        """Success can be verified without automatically rerunning or skipping work."""
        self.assertEqual(self.run_check(), 0)
        self.assertEqual(check.verify(self.spec, self.base, self.command, self.receipt), 0)

    def test_wrong_commit_and_missing_fix_refuse_launch(self) -> None:
        """Source identity and required-fix ancestry are launch preconditions."""
        spec = copy.deepcopy(self.spec)
        spec["source"]["commit"] = "0" * 40
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check(spec), 0)
            execute.assert_not_called()
        spec["source"]["commit"] = self.commit
        spec["source"]["required_ancestors"] = ["0" * 40]
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check(spec), 0)
            execute.assert_not_called()
        self.assertEqual(self.status(), "refused")

    def test_existing_unrelated_commit_is_not_a_required_ancestor(self) -> None:
        """A valid object ID alone does not establish fix ancestry."""
        result = subprocess.run(
            [
                "git", "-C", str(self.repo), "-c", "user.name=Fixture",
                "-c", "user.email=fixture@example.invalid",
                "commit-tree", self.git("rev-parse", "HEAD^{tree}"),
            ],
            input="unrelated\n", text=True, capture_output=True,
            env=self.environment, check=True,
        )
        spec = copy.deepcopy(self.spec)
        spec["source"]["required_ancestors"] = [result.stdout.strip()]
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check(spec), 0)
            execute.assert_not_called()

    def test_dirty_source_is_not_qualified(self) -> None:
        """A commit label cannot hide modified source bytes."""
        (self.repo / "source.txt").write_text("modified\n")
        self.assertNotEqual(self.run_check(), 0)
        self.assertEqual(self.status(), "refused")

    def test_hidden_tracked_edits_refuse_launch(self) -> None:
        """A clean status cannot qualify assume-unchanged or skip-worktree edits."""
        for flag, reset in (
            ("--assume-unchanged", "--no-assume-unchanged"),
            ("--skip-worktree", "--no-skip-worktree"),
        ):
            with self.subTest(flag=flag):
                self.git("update-index", flag, "source.txt")
                (self.repo / "source.txt").write_text("hidden edit\n")
                self.assertEqual(self.git("status", "--porcelain"), "")
                with mock.patch.object(check, "execute") as execute:
                    self.assertNotEqual(self.run_check(), 0)
                    execute.assert_not_called()
                self.assertEqual(self.status(), "refused")
                (self.repo / "source.txt").write_text("source\n")
                self.git("update-index", reset, "source.txt")

    def test_sparse_source_configuration_refuses_launch(self) -> None:
        """Sparse checkout cannot masquerade as an exact complete source tree."""
        self.git("config", "core.sparseCheckout", "true")
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check(), 0)
            execute.assert_not_called()

    def test_ignored_output_under_source_refuses_launch(self) -> None:
        """Ignored paths still violate the explicit outside-source output contract."""
        (self.repo / ".gitignore").write_text("generated/\n")
        self.git("add", ".gitignore")
        self.git(
            "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-qm", "ignore generated",
        )
        spec = copy.deepcopy(self.spec)
        spec["source"]["commit"] = self.git("rev-parse", "HEAD")
        spec.update(kind="build", outputs=[str(self.repo / "generated" / "binary")])
        self.assertEqual(self.git("status", "--porcelain"), "")
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check(spec), 0)
            execute.assert_not_called()

    def test_wrong_input_refuses_launch(self) -> None:
        """Explicit input mismatches refuse before argv starts."""
        asset = self.base / "asset"
        asset.write_text("one")
        spec = {**self.spec, "inputs": {str(asset): "0" * 64}}
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check(spec), 0)
            execute.assert_not_called()

    def test_changed_input_or_source_invalidates_completion(self) -> None:
        """Changed persistent identities cannot produce a successful receipt."""
        for path in (self.base / "asset", self.repo / "source.txt"):
            with self.subTest(path=path):
                path.write_text("one")
                spec = {**self.spec, "inputs": {str(path): check.digest_file(path)}}
                if path.parent == self.repo:
                    path.write_text("source\n")
                    spec["inputs"][str(path)] = check.digest_file(path)
                command = [
                    sys.executable, "-c",
                    "from pathlib import Path; Path(" + repr(str(path)) + ").write_text('two')",
                ]
                self.assertNotEqual(self.run_check(spec, command), 0)
                self.assertEqual(self.status(), "invalidated")

    def test_failed_command_replaces_previous_success(self) -> None:
        """A failed new run cannot leave an old success-shaped receipt."""
        self.assertEqual(self.run_check(), 0)
        self.assertEqual(self.run_check(command=[sys.executable, "-c", "raise SystemExit(7)"]), 7)
        self.assertEqual(self.status(), "failed")
        with self.assertRaises(check.CheckError):
            check.verify(self.spec, self.base, self.command, self.receipt)

    def test_command_and_context_mismatch_refuse_evidence_reuse(self) -> None:
        """Selection, platform, features, toolchain and argv are evidence identity."""
        self.assertEqual(self.run_check(), 0)
        for field in ("selection", "platform", "features", "toolchain"):
            spec = copy.deepcopy(self.spec)
            spec["context"][field] = "different"
            with self.subTest(field=field), self.assertRaises(check.CheckError):
                check.verify(spec, self.base, self.command, self.receipt)
        with self.assertRaises(check.CheckError):
            check.verify(self.spec, self.base, [*self.command, "different"], self.receipt)

    def test_missing_receipt_cannot_be_reused(self) -> None:
        """Evidence absence is a refusal, never assumed success."""
        with self.assertRaises(FileNotFoundError):
            check.verify(self.spec, self.base, self.command, self.receipt)

    def test_malformed_receipt_is_an_explicit_refusal(self) -> None:
        """Malformed evidence never becomes a success-shaped fallback."""
        self.receipt.write_text("[]")
        with self.assertRaisesRegex(check.CheckError, "invalid receipt structure"):
            check.verify(self.spec, self.base, self.command, self.receipt)

    def test_receipt_cannot_replace_source_or_required_inputs(self) -> None:
        """Failure evidence never overwrites the source or a declared asset."""
        source = self.repo / "source.txt"
        with self.assertRaises(check.CheckError):
            check.run(self.spec, self.base, self.command, source)
        self.assertEqual(source.read_text(), "source\n")
        asset = self.base / "asset"
        asset.write_text("asset")
        spec = {**self.spec, "inputs": {str(asset): check.digest_file(asset)}}
        with self.assertRaises(check.CheckError):
            check.run(spec, self.base, self.command, asset)
        self.assertEqual(asset.read_text(), "asset")

    def test_changed_producer_input_refuses_launch(self) -> None:
        """Pinned output bytes cannot hide a changed producer input."""
        asset = self.base / "asset"
        asset.write_text("one")
        output = self.base / "artifact"
        producer = {
            **self.spec, "kind": "build", "outputs": [str(output)],
            "inputs": {str(asset): check.digest_file(asset)},
        }
        command = [
            sys.executable, "-c",
            "from pathlib import Path; Path(" + repr(str(output)) + ").write_text('binary')",
        ]
        self.assertEqual(self.run_check(producer, command), 0)
        consumer = self.consumer(output)
        asset.write_text("two")
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(
                check.run(consumer, self.base, self.command, self.base / "consumer.json"), 0,
            )
            execute.assert_not_called()

    def test_unknown_specification_field_refuses_launch(self) -> None:
        """A mistyped requirement cannot silently disappear from qualification."""
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check({**self.spec, "input": {}}), 0)
            execute.assert_not_called()

    @unittest.skipUnless(os.name == "posix", "process groups require POSIX")
    def test_failed_command_cleans_surviving_descendants(self) -> None:
        """A failed parent cannot leave its child running in the owned group."""
        pid_file = self.base / "descendant.pid"
        child_code = "import signal; signal.pause()"
        parent_code = (
            "import pathlib, subprocess, sys; "
            f"p = subprocess.Popen([sys.executable, '-c', {child_code!r}], "
            "stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); "
            f"pathlib.Path({str(pid_file)!r}).write_text(str(p.pid)); "
            "raise SystemExit(7)"
        )
        self.assertEqual(check.execute([sys.executable, "-c", parent_code], str(self.repo)), 7)
        child = int(pid_file.read_text())
        result = subprocess.run(
            ["ps", "-p", str(child), "-o", "stat="],
            capture_output=True, text=True, check=False,
        )
        self.assertTrue(
            not result.stdout.strip() or result.stdout.strip().startswith("Z"),
            "owned descendant remains running",
        )

    @unittest.skipUnless(os.name == "posix", "process groups require POSIX")
    def test_successful_command_cleans_surviving_descendants(self) -> None:
        """A successful parent also cannot leave an owned descendant running."""
        pid_file = self.base / "descendant.pid"
        child_code = "import signal; signal.pause()"
        parent_code = (
            "import pathlib, subprocess, sys; "
            f"p = subprocess.Popen([sys.executable, '-c', {child_code!r}], "
            "stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); "
            f"pathlib.Path({str(pid_file)!r}).write_text(str(p.pid))"
        )
        self.assertEqual(check.execute([sys.executable, "-c", parent_code], str(self.repo)), 0)
        child = int(pid_file.read_text())
        result = subprocess.run(
            ["ps", "-p", str(child), "-o", "stat="],
            capture_output=True, text=True, check=False,
        )
        self.assertTrue(
            not result.stdout.strip() or result.stdout.strip().startswith("Z"),
            "owned descendant remains running after successful parent",
        )

    def test_denied_live_group_cleanup_is_not_silently_accepted(self) -> None:
        """Only verified absent or zombie-only macOS groups tolerate EPERM."""
        for rows, should_raise in (
            ("123 Z\n", False), ("", False), ("123 S\n", True),
        ):
            result = subprocess.CompletedProcess([], 0, stdout=rows, stderr="")
            with (
                self.subTest(rows=rows),
                mock.patch.object(check.platform, "system", return_value="Darwin"),
                mock.patch.object(check.os, "killpg", side_effect=PermissionError),
                mock.patch.object(check.subprocess, "run", return_value=result),
            ):
                if should_raise:
                    with self.assertRaises(PermissionError):
                        check.signal_owned_group(123, signal.SIGKILL)
                else:
                    check.signal_owned_group(123, signal.SIGKILL)

    def test_unverified_or_nonmacos_permission_failure_remains_an_error(self) -> None:
        """A missing proof or a different OS cannot turn denial into success."""
        with (
            mock.patch.object(check.os, "killpg", side_effect=PermissionError),
            mock.patch.object(check.platform, "system", return_value="Linux"),
            self.assertRaises(PermissionError),
        ):
            check.signal_owned_group(123, signal.SIGKILL)
        with (
            mock.patch.object(check.os, "killpg", side_effect=PermissionError),
            mock.patch.object(check.platform, "system", return_value="Darwin"),
            mock.patch.object(
                check.subprocess, "run",
                return_value=subprocess.CompletedProcess([], 1, stdout="", stderr=""),
            ),
            self.assertRaises(check.CheckError),
        ):
            check.signal_owned_group(123, signal.SIGKILL)

    @unittest.skipUnless(os.name == "posix", "signals require POSIX")
    def test_interruption_during_spawn_is_deferred_until_child_is_owned(self) -> None:
        """A pending launch signal cannot escape cleanup before Popen returns."""
        original_popen = subprocess.Popen
        spawned = []
        fallback_called = False

        def fallback(signum: int, frame: object) -> None:
            nonlocal fallback_called
            fallback_called = True

        def interrupted_spawn(
            command: list[str], cwd: str, start_new_session: bool,
        ) -> subprocess.Popen[bytes]:
            process = original_popen(command, cwd=cwd, start_new_session=start_new_session)
            spawned.append(process)
            os.kill(os.getpid(), signal.SIGTERM)
            if fallback_called:
                process.kill()
                process.wait(timeout=self.PROCESS_TIMEOUT_S)
                self.fail("spawn signal reached the caller before process ownership")
            self.assertIsNone(process.poll())
            return process

        previous = signal.getsignal(signal.SIGTERM)
        signal.signal(signal.SIGTERM, fallback)
        try:
            with mock.patch.object(check.subprocess, "Popen", side_effect=interrupted_spawn):
                with self.assertRaises(InterruptedError):
                    check.execute(
                        [sys.executable, "-c", "import signal; signal.pause()"],
                        str(self.repo),
                    )
            self.assertEqual(signal.getsignal(signal.SIGTERM), fallback)
        finally:
            signal.signal(signal.SIGTERM, previous)
            for process in spawned:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=self.PROCESS_TIMEOUT_S)
        self.assertEqual(len(spawned), 1)
        with self.assertRaises(ProcessLookupError):
            os.kill(spawned[0].pid, 0)

    def start_helper(self, command: list[str], receipt: Path) -> subprocess.Popen[str]:
        """Start the real CLI with a deterministic stdout-ready protocol."""
        spec = self.base / "spec.json"
        spec.write_text(json.dumps(self.spec))
        return subprocess.Popen(
            [
                sys.executable, check.__file__, "run", "--spec", str(spec),
                "--receipt", str(receipt), "--", *command,
            ],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )

    def ready_child(self, process: subprocess.Popen[str]) -> int:
        """Wait for the child's explicit PID, not a timing-based startup guess."""
        ready, _, _ = select.select([process.stdout], [], [], self.PROCESS_TIMEOUT_S)
        self.assertTrue(ready, "child did not reach its deterministic ready point")
        return int(process.stdout.readline())

    def stop_helper(self, process: subprocess.Popen[str]) -> None:
        """Stop the owned test helper on assertion failure and reap its streams."""
        if process.poll() is None:
            process.terminate()
        process.communicate(timeout=self.PROCESS_TIMEOUT_S)

    @unittest.skipUnless(os.name == "posix", "signals require POSIX")
    def test_command_receives_normal_termination_signal(self) -> None:
        """The startup protocol must not leave the command's signals blocked."""
        command = [
            sys.executable, "-c",
            "import os, signal, sys; "
            "signal.signal(signal.SIGTERM, lambda *_: sys.exit(23)); "
            "print(os.getpid(), flush=True); signal.pause()",
        ]
        process = self.start_helper(command, self.receipt)
        try:
            child = self.ready_child(process)
            os.kill(child, signal.SIGTERM)
            process.communicate(timeout=self.PROCESS_TIMEOUT_S)
            self.assertEqual(process.returncode, 23)
            self.assertEqual(self.status(), "failed")
            self.assertEqual(json.loads(self.receipt.read_text())["exit_code"], 23)
        finally:
            self.stop_helper(process)

    @unittest.skipUnless(os.name == "posix", "receipt locks require POSIX")
    def test_concurrent_receipt_run_refuses_without_replacing_owner_evidence(self) -> None:
        """A rejected newer run cannot race an older owner's final receipt."""
        owner_command = [
            sys.executable, "-c",
            "import os, signal, sys; "
            "signal.signal(signal.SIGUSR1, lambda *_: sys.exit(0)); "
            "print(os.getpid(), flush=True); signal.pause()",
        ]
        owner = self.start_helper(owner_command, self.receipt)
        try:
            child = self.ready_child(owner)
            original_receipt = self.receipt.read_bytes()
            marker = self.base / "unwanted-launch"
            contender = self.start_helper([
                sys.executable, "-c",
                f"from pathlib import Path; Path({str(marker)!r}).touch(); raise SystemExit(7)",
            ], self.receipt)
            try:
                _, error = contender.communicate(timeout=self.PROCESS_TIMEOUT_S)
                self.assertEqual(contender.returncode, 1)
                self.assertIn("already owned", error)
                self.assertFalse(marker.exists())
                self.assertEqual(self.receipt.read_bytes(), original_receipt)
            finally:
                self.stop_helper(contender)
            os.kill(child, signal.SIGUSR1)
            owner.communicate(timeout=self.PROCESS_TIMEOUT_S)
            self.assertEqual(owner.returncode, 0)
            self.assertEqual(self.status(), "success")
            self.assertEqual(
                json.loads(self.receipt.read_text())["identity"]["command_sha256"],
                check.digest_json(owner_command),
            )
        finally:
            self.stop_helper(owner)

    def test_producer_output_and_verified_provenance(self) -> None:
        """A consumer requires a pinned successful producer for its artifact."""
        _, _, output = self.build()
        consumer = self.consumer(output)
        receipt = self.base / "consumer.json"
        self.assertEqual(check.run(consumer, self.base, self.command, receipt), 0)
        self.assertEqual(check.verify(consumer, self.base, self.command, receipt), 0)

    def test_consumer_can_require_additional_ancestor_checks_for_same_source(self) -> None:
        """Fix requirements are checked against the commit, not list equality."""
        _, _, output = self.build()
        consumer = copy.deepcopy(self.consumer(output))
        consumer["source"]["required_ancestors"] = []
        self.assertEqual(
            check.run(consumer, self.base, self.command, self.base / "consumer.json"), 0,
        )

    def test_pinned_wrong_source_receipt_refuses_launch(self) -> None:
        """Even an explicitly pinned receipt must name the intended source."""
        _, _, output = self.build()
        receipt = json.loads(self.receipt.read_text())
        receipt["identity"]["source"]["commit"] = "0" * 40
        self.receipt.write_text(json.dumps(receipt))
        consumer = self.consumer(output)
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(
                check.run(consumer, self.base, self.command, self.base / "consumer.json"), 0,
            )
            execute.assert_not_called()

    def test_changed_executable_refuses_evidence_reuse(self) -> None:
        """An unchanged argv string cannot hide new executable bytes."""
        program = self.base / "program"
        program.write_text("#!/bin/sh\nexit 0\n")
        program.chmod(0o755)
        command = [str(program)]
        self.assertEqual(self.run_check(command=command), 0)
        program.write_text("#!/bin/sh\nexit 1\n")
        with self.assertRaises(check.CheckError):
            check.verify(self.spec, self.base, command, self.receipt)

    def test_interpreter_symlink_preserves_selected_environment(self) -> None:
        """Canonical executable hashing must not bypass a Python environment."""
        environment = (self.base / "venv").resolve()
        venv.EnvBuilder(with_pip=False).create(environment)
        program = environment / "bin" / "python"
        command = [
            str(program), "-c",
            f"import sys; assert sys.prefix == {str(environment)!r}, sys.prefix",
        ]
        self.assertEqual(self.run_check(command=command), 0)
        receipt = json.loads(self.receipt.read_text())
        self.assertEqual(receipt["identity"]["executable"]["invocation"], str(program))

    @unittest.skipUnless(os.name == "posix", "FIFO fixtures require POSIX")
    def test_nonregular_input_refuses_without_reading_or_launching(self) -> None:
        """A declared pipe cannot hang the digest precondition."""
        fifo = self.base / "fifo"
        os.mkfifo(fifo)
        spec = {**self.spec, "inputs": {str(fifo): "0" * 64}}
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(self.run_check(spec), 0)
            execute.assert_not_called()

    def test_binary_digest_alone_is_not_source_provenance(self) -> None:
        """An artifact digest without a source-to-output receipt refuses launch."""
        _, _, output = self.build()
        spec = {**self.spec, "artifacts": {str(output): check.digest_file(output)}}
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(
                check.run(spec, self.base, self.command, self.base / "consumer.json"), 0,
            )
            execute.assert_not_called()

    def test_changed_artifact_and_receipt_refuse_launch(self) -> None:
        """Changed binaries and unpinned producer evidence cannot be reused."""
        _, _, output = self.build()
        consumer = self.consumer(output)
        output.write_text("different")
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(
                check.run(consumer, self.base, self.command, self.base / "consumer.json"), 0,
            )
            execute.assert_not_called()
        output.write_text("binary")
        self.receipt.write_text(self.receipt.read_text() + "\n")
        with mock.patch.object(check, "execute") as execute:
            self.assertNotEqual(
                check.run(consumer, self.base, self.command, self.base / "consumer.json"), 0,
            )
            execute.assert_not_called()

    def test_preexisting_output_cannot_get_new_provenance(self) -> None:
        """A no-op command cannot relabel a preexisting binary as newly built."""
        spec, command, _ = self.build()
        self.assertNotEqual(self.run_check(spec, command), 0)
        self.assertEqual(self.status(), "refused")

    def test_missing_output_invalidates_build(self) -> None:
        """A successful process without its required artifact is not a build."""
        spec = {**self.spec, "kind": "build", "outputs": [str(self.base / "missing")]}
        self.assertNotEqual(self.run_check(spec), 0)
        self.assertEqual(self.status(), "invalidated")

    def test_receipt_does_not_store_arguments_environment_or_output(self) -> None:
        """Receipts store identity digests, not sensitive argv or payloads."""
        secret = "fixture-secret-not-a-real-credential"
        command = [sys.executable, "-c", "pass", secret]
        self.assertEqual(self.run_check(command=command), 0)
        self.assertNotIn(secret, self.receipt.read_text())
        self.assertNotIn("HOME", self.receipt.read_text())
        self.assertNotIn('"command":', self.receipt.read_text())

    def test_cli_options_are_parsed_before_argv(self) -> None:
        """The documented interface accepts options after the run subcommand."""
        spec = self.base / "spec.json"
        spec.write_text(json.dumps(self.spec))
        with mock.patch.object(check, "run", return_value=0) as run:
            with mock.patch.object(sys, "argv", [
                "agent_check.py", "run", "--spec", str(spec),
                "--receipt", str(self.receipt), "--", *self.command,
            ]):
                self.assertEqual(check.main(), 0)
        self.assertEqual(run.call_args.args[2], self.command)

    @unittest.skipUnless(os.name == "posix", "process groups require POSIX")
    def test_interruption_records_failure_and_cleans_child(self) -> None:
        """A real signal produces an interrupted receipt after process cleanup."""
        spec = self.base / "spec.json"
        spec.write_text(json.dumps(self.spec))
        helper = Path(check.__file__)
        command = [
            sys.executable, "-c",
            "import os, signal; print(os.getpid(), flush=True); signal.pause()",
        ]
        process = subprocess.Popen(
            [
                sys.executable, str(helper), "run", "--spec", str(spec),
                "--receipt", str(self.receipt), "--", *command,
            ],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        self.addCleanup(lambda: process.poll() is None and process.kill())
        ready, _, _ = select.select([process.stdout], [], [], 10)
        self.assertTrue(ready, "child did not reach its deterministic ready point")
        child = int(process.stdout.readline())
        process.send_signal(signal.SIGTERM)
        process.communicate(timeout=10)
        self.assertEqual(process.returncode, 130)
        self.assertEqual(self.status(), "interrupted")
        with self.assertRaises(ProcessLookupError):
            os.kill(child, 0)


if __name__ == "__main__":
    unittest.main()
