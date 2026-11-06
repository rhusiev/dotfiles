#!/usr/bin/env python3
"""Run explicitly qualified argv and atomically record identity-bound evidence."""

from __future__ import annotations

import argparse
from collections.abc import Iterator
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time

SCHEMA_VERSION = 1
TERMINATE_GRACE_S = 2
GIT_TIMEOUT_S = 30
PROCESS_QUERY_TIMEOUT_S = 5
HASH_BLOCK_BYTES = 1024 * 1024
REQUIRED_CONTEXT = frozenset({"selection", "platform", "toolchain", "features"})
SPEC_KEYS = frozenset({
    "version", "kind", "source", "context", "inputs", "artifacts", "outputs", "provenance",
})


class CheckError(ValueError):
    """A declared execution or evidence precondition does not hold."""


class ReceiptBusyError(CheckError):
    """Another run owns the requested receipt."""


def digest_file(path: Path) -> str:
    """Hash a required regular file without recording its contents."""
    if not path.is_file():
        raise CheckError("required evidence path is not a regular file")
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(HASH_BLOCK_BYTES), b""):
            digest.update(block)
    return digest.hexdigest()


def digest_json(value: object) -> str:
    """Hash a canonical declaration without exposing command arguments."""
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode(),
    ).hexdigest()


def atomic_receipt(path: Path, receipt: dict) -> None:
    """Publish a complete receipt, never an old success or partial new file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
            stream.flush()
            os.fsync(stream.fileno())
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def git(root: Path, *args: str) -> str:
    """Run a bounded read-only Git query without exposing stderr payloads."""
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        capture_output=True,
        text=True,
        check=False,
        timeout=GIT_TIMEOUT_S,
    )
    if result.returncode:
        raise CheckError("source Git query failed")
    return result.stdout.strip()


def source_identity(spec: dict, base: Path) -> dict:
    """Require the declared clean source commit and every required fix ancestor."""
    source = spec["source"]
    root = (base / source["root"]).resolve()
    commit = source["commit"]
    if not isinstance(commit, str) or not re.fullmatch(r"[a-f0-9]{40}|[a-f0-9]{64}", commit):
        raise CheckError("source commit must be a full lowercase object ID")
    if Path(git(root, "rev-parse", "--show-toplevel")).resolve() != root:
        raise CheckError("source root is not the Git worktree root")
    if git(root, "rev-parse", "HEAD") != commit:
        raise CheckError("source commit mismatch")
    if git(root, "status", "--porcelain", "--untracked-files=normal"):
        raise CheckError("source worktree is not clean")
    if git(root, "config", "--bool", "--default=false", "--get", "core.sparseCheckout") == "true":
        raise CheckError("sparse source worktrees are not qualified")
    entries = git(root, "ls-files", "-v", "-z").split("\0")
    if any(entry and (entry[0].islower() or entry[0] == "S") for entry in entries):
        raise CheckError("source index hides tracked files with assume-unchanged or skip-worktree")
    for ancestor in source.get("required_ancestors", []):
        if not isinstance(ancestor, str) or not re.fullmatch(
            r"[a-f0-9]{40}|[a-f0-9]{64}", ancestor,
        ):
            raise CheckError("required ancestor must be a full object ID")
        try:
            git(root, "merge-base", "--is-ancestor", ancestor, commit)
        except CheckError as error:
            raise CheckError("required fix is unavailable or not a source ancestor") from error
    return {
        "root": str(root),
        "commit": commit,
        "tree": git(root, "rev-parse", "HEAD^{tree}"),
        "required_ancestors": source.get("required_ancestors", []),
    }


def declared_files(values: dict, base: Path) -> dict:
    """Require exact declared file digests, including artifacts and input assets."""
    if not isinstance(values, dict):
        raise CheckError("file declarations must be path-to-sha256 objects")
    actual = {}
    for name, expected in values.items():
        if not isinstance(expected, str) or not re.fullmatch(r"[a-f0-9]{64}", expected):
            raise CheckError("file declarations require full SHA256 digests")
        path = (base / name).resolve()
        observed = digest_file(path)
        if observed != expected:
            raise CheckError("declared file digest mismatch")
        actual[str(path)] = observed
    return actual


def identity(spec: dict, base: Path, command: list[str]) -> dict:
    """Bind source, declared inputs, selection, environment labels and argv hash."""
    if not command or any(not isinstance(value, str) for value in command):
        raise CheckError("argv must be a nonempty string list")
    if not isinstance(spec, dict) or set(spec) - SPEC_KEYS:
        raise CheckError("unknown specification fields")
    if spec.get("version") != SCHEMA_VERSION or spec.get("kind") not in {"build", "check"}:
        raise CheckError("unsupported specification version or kind")
    if os.name != "posix":
        raise CheckError("checked process-group execution requires POSIX")
    if set(spec["source"]) - {"root", "commit", "required_ancestors"}:
        raise CheckError("unknown source fields")
    context = spec["context"]
    if not isinstance(context, dict) or not REQUIRED_CONTEXT.issubset(context):
        raise CheckError("context requires selection, platform, toolchain and features")
    if any(not isinstance(value, str) or not value for value in context.values()):
        raise CheckError("context values must be nonempty, non-secret labels")
    source = source_identity(spec, base)
    root = Path(source["root"])
    search_path = os.pathsep.join(
        str(path if path.is_absolute() else root / path)
        for path in map(Path, os.get_exec_path())
    )
    name = command[0]
    if "/" in name:
        executable = shutil.which(str(root / name))
    else:
        executable = shutil.which(name, path=search_path)
    if executable is None:
        raise CheckError("argv executable is unavailable")
    program = Path(executable).resolve()
    return {
        "kind": spec["kind"],
        "source": source,
        "inputs": declared_files(spec.get("inputs", {}), base),
        "artifacts": declared_files(spec.get("artifacts", {}), base),
        "context": context,
        "host": {"system": platform.system(), "machine": platform.machine()},
        "executable": {
            "path": str(program),
            "invocation": str(Path(executable).absolute()),
            "sha256": digest_file(program),
        },
        "command_sha256": digest_json(command),
        "spec_sha256": digest_json(spec),
    }


def verify_provenance(spec: dict, base: Path, current: dict) -> None:
    """Require pinned successful producer receipts for every declared artifact."""
    artifacts = current["artifacts"]
    produced = {}
    for declaration in spec.get("provenance", []):
        path = (base / declaration["receipt"]).resolve()
        if digest_file(path) != declaration["sha256"]:
            raise CheckError("producer receipt digest mismatch")
        receipt = json.loads(path.read_text())
        if not isinstance(receipt, dict) or not isinstance(receipt.get("identity"), dict):
            raise CheckError("invalid producer receipt structure")
        producer = receipt.get("identity", {})
        producer_source = producer.get("source")
        same_source = all(
            isinstance(producer_source, dict)
            and producer_source.get(key) == current["source"][key]
            for key in ("root", "commit", "tree")
        )
        if (
            receipt.get("version") != SCHEMA_VERSION
            or receipt.get("status") != "success"
            or producer.get("kind") != "build"
            or not same_source
        ):
            raise CheckError("producer receipt does not qualify this source")
        declared_files(producer.get("inputs", {}), base)
        produced.update(receipt.get("outputs", {}))
    if any(produced.get(path) != digest for path, digest in artifacts.items()):
        raise CheckError("artifact lacks a matching source-to-output receipt")


def output_paths(spec: dict, base: Path) -> list[Path]:
    """Resolve declared producer outputs, refusing duplicates and source files."""
    values = spec.get("outputs", [])
    if not isinstance(values, list) or any(not isinstance(value, str) for value in values):
        raise CheckError("outputs must be a list of paths")
    if any((base / value).is_symlink() for value in values):
        raise CheckError("producer output cannot be a preexisting symlink")
    paths = [(base / value).resolve() for value in values]
    root = (base / spec["source"]["root"]).resolve()
    if any(path.is_relative_to(root) for path in paths):
        raise CheckError("producer outputs must be outside the source root")
    if len(set(paths)) != len(paths):
        raise CheckError("duplicate output path")
    if spec["kind"] == "build" and not paths:
        raise CheckError("build requires newly produced outputs")
    if spec["kind"] == "check" and paths:
        raise CheckError("checks cannot publish producer outputs")
    return paths


def execute(command: list[str], cwd: str) -> int:
    """Wait for argv and clean its process group on completion or interruption."""
    process = None
    previous = {}
    may_interrupt = False
    pending_signal = None

    def interrupt(signum: int, frame: object) -> None:
        nonlocal pending_signal
        pending_signal = signum
        if may_interrupt:
            raise InterruptedError(f"signal {signum}")

    try:
        for signum in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
            previous[signum] = signal.signal(signum, interrupt)
        if pending_signal is not None:
            raise InterruptedError(f"signal {pending_signal}")
        process = subprocess.Popen(command, cwd=cwd, start_new_session=True)
        may_interrupt = True
        if pending_signal is not None:
            raise InterruptedError(f"signal {pending_signal}")
        return process.wait()
    finally:
        may_interrupt = False
        try:
            if process is not None:
                cleanup_process(process)
        finally:
            for signum, handler in previous.items():
                signal.signal(signum, handler)
        if pending_signal is not None:
            raise InterruptedError(f"signal {pending_signal}")


def cleanup_process(process: subprocess.Popen[bytes]) -> None:
    """Stop the owned group, including descendants left after a parent exit."""
    signal_owned_group(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=TERMINATE_GRACE_S)
    except subprocess.TimeoutExpired:
        signal_owned_group(process.pid, signal.SIGKILL)
        process.wait()
    signal_owned_group(process.pid, signal.SIGKILL)


def signal_owned_group(pgid: int, signum: int) -> None:
    """Keep live permission failures visible while tolerating a departed group."""
    try:
        os.killpg(pgid, signum)
    except ProcessLookupError:
        return
    except PermissionError:
        if platform.system() != "Darwin" or live_group_members(pgid):
            raise


def live_group_members(pgid: int) -> bool:
    """Verify macOS EPERM denotes an absent or zombie-only process group."""
    result = subprocess.run(
        ["ps", "-axo", "pgid=,stat="],
        capture_output=True, text=True, check=False,
        timeout=PROCESS_QUERY_TIMEOUT_S,
    )
    if result.returncode:
        raise CheckError("cannot verify denied process-group cleanup")
    for row in result.stdout.splitlines():
        fields = row.split()
        if len(fields) != 2 or not fields[0].isdigit():
            raise CheckError("invalid process-group query response")
        if int(fields[0]) == pgid and not fields[1].startswith("Z"):
            return True
    return False


@contextmanager
def receipt_ownership(path: Path) -> Iterator[None]:
    """Reject concurrent receipt writers without replacing their lock inode."""
    path.parent.mkdir(parents=True, exist_ok=True)
    lock_path = path.with_name(path.name + ".lock")
    with lock_path.open("a+b") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise ReceiptBusyError("receipt is already owned by another run") from error
        try:
            yield
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def run(spec: dict, base: Path, command: list[str], receipt_path: Path) -> int:
    """Refuse unmet preconditions and replace stale evidence on every outcome."""
    protect_receipt(spec, base, receipt_path)
    try:
        with receipt_ownership(receipt_path):
            return _run_owned(spec, base, command, receipt_path)
    except ReceiptBusyError as error:
        print(f"agent-check: refused: {error}", file=sys.stderr)
        return 1


def _run_owned(spec: dict, base: Path, command: list[str], receipt_path: Path) -> int:
    """Replace evidence only while this invocation owns the receipt transaction."""
    receipt = {"version": SCHEMA_VERSION, "status": "running", "started_ns": time.time_ns()}
    atomic_receipt(receipt_path, receipt)
    code = 1
    try:
        before = identity(spec, base, command)
        paths = output_paths(spec, base)
        if any(path.exists() for path in paths):
            raise CheckError("producer output already exists")
        if receipt_path.resolve() in paths:
            raise CheckError("receipt cannot also be a producer output")
        verify_provenance(spec, base, before)
        receipt["identity"] = before
        code = execute(
            [before["executable"]["invocation"], *command[1:]],
            before["source"]["root"],
        )
        receipt["exit_code"] = code
        if identity(spec, base, command) != before:
            raise CheckError("declared identity changed during execution")
        verify_provenance(spec, base, before)
        if code:
            receipt["status"] = "failed"
        else:
            receipt["outputs"] = {str(path): digest_file(path) for path in paths}
            receipt["status"] = "success"
    except InterruptedError:
        receipt["status"] = "interrupted"
        code = 130
    except (CheckError, OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        receipt["status"] = "refused" if "identity" not in receipt else "invalidated"
        receipt["error_type"] = type(error).__name__
        print(f"agent-check: {receipt['status']}: {error}", file=sys.stderr)
        code = 1
    finally:
        receipt["finished_ns"] = time.time_ns()
        atomic_receipt(receipt_path, receipt)
    return code


def protect_receipt(spec: dict, base: Path, path: Path) -> None:
    """Prevent receipt writes from replacing source, inputs or existing evidence."""
    root = (base / spec["source"]["root"]).resolve()
    target = path.resolve()
    protected = [
        *spec.get("inputs", {}), *spec.get("artifacts", {}),
        *(entry["receipt"] for entry in spec.get("provenance", [])),
        *spec.get("outputs", []),
    ]
    if (
        target.is_relative_to(root)
        or path.is_symlink()
        or target in {(base / value).resolve() for value in protected}
    ):
        raise CheckError("receipt path overlaps protected source, input or evidence")


def verify(spec: dict, base: Path, command: list[str], receipt_path: Path) -> int:
    """Refuse stale, failed, missing or differently selected evidence."""
    receipt = json.loads(receipt_path.read_text())
    if not isinstance(receipt, dict):
        raise CheckError("invalid receipt structure")
    current = identity(spec, base, command)
    if (
        receipt.get("version") != SCHEMA_VERSION
        or receipt.get("status") != "success"
        or receipt.get("identity") != current
    ):
        raise CheckError("receipt does not qualify the declared execution")
    verify_provenance(spec, base, current)
    declared_files(receipt.get("outputs", {}), base)
    return 0


def main() -> int:
    """Parse the small optional execution interface without evaluating a shell."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["run", "verify"])
    parser.add_argument("--spec", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    arguments = sys.argv[1:]
    try:
        separator = arguments.index("--")
    except ValueError:
        parser.error("argv is required after --")
    args = parser.parse_args(arguments[:separator])
    command = arguments[separator + 1:]
    if not command:
        parser.error("argv is required after --")
    try:
        if args.spec.resolve() == args.receipt.resolve():
            raise CheckError("receipt cannot replace its specification")
        spec = json.loads(args.spec.read_text())
        base = args.spec.resolve().parent
        if args.action == "run":
            return run(spec, base, command, args.receipt)
        return verify(spec, base, command, args.receipt)
    except (CheckError, OSError, ValueError, KeyError, TypeError) as error:
        print(f"agent-check: refused: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
