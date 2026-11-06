# Execution evidence and portable working practices

Evidence must identify what ran and what it establishes
A binary digest identifies bytes
A source-to-output receipt records a witnessed production step from declared source and inputs
A test selection identifies the checks that ran
The target environment identifies the platform, features and toolchain for that result
None of these facts implies the others

## Optional checked execution

`config/claude/bin/agent_check.py` checks explicit requirements before launching an argv list
It requires a clean Git worktree at the exact full commit ID and checks required-fix ancestry
It rejects sparse checkout, assume-unchanged and skip-worktree states that can hide tracked edits
It hashes declared input files, artifacts and the resolved argv executable
It preserves the selected executable's invocation path so a Python environment's interpreter symlink keeps its behavior
It binds the receipt to argv's hash, the specification, check selection, declared context and actual OS/architecture
It never infers semantic test coverage or automatically skips a check

Keep the specification, receipts and generated outputs outside the source worktree
Use absolute source and asset paths, or paths relative to the specification
For example:

```json
{
  "version": 1,
  "kind": "check",
  "source": {
    "root": "/path/to/clean/worktree",
    "commit": "<full-commit-id>",
    "required_ancestors": ["<full-required-fix-id>"]
  },
  "inputs": {
    "/path/to/test-input": "<sha256>"
  },
  "context": {
    "selection": "named integration checks",
    "platform": "intended target platform",
    "toolchain": "compiler identity",
    "features": "explicit feature set or none"
  }
}
```

Run or verify the exact same declaration and argv:

```sh
python3 ~/.config/claude/bin/agent_check.py run --spec check.json --receipt check.receipt.json -- program argument
python3 ~/.config/claude/bin/agent_check.py verify --spec check.json --receipt check.receipt.json -- program argument
```

The helper inherits the caller's environment and standard streams
Receipts contain hashes and explicit non-secret context labels
They do not contain command arguments, captured output, environment values or input payloads
Do not put secrets in context labels or argv
Supply secrets through the project's protected input mechanism

For a producer, set `"kind": "build"` and declare new output paths in `"outputs"`
Every output must be absent before launch and present after success
Outputs under the source root refuse launch even when Git ignores their directory
A consumer declares `"artifacts": {"path": "sha256"}` and pins producer receipts:

```json
{
  "provenance": [
    {"receipt": "/path/to/build.receipt.json", "sha256": "<receipt-sha256>"}
  ]
}
```

This fragment extends the complete check specification
Each artifact must match an output from a successful producer receipt for the same declared source
The producer's declared inputs must still match
An artifact digest without a pinned producer receipt refuses launch
A missing receipt, wrong ancestor, changed source, changed input or changed artifact also refuses launch

Receipts are local evidence, not signed attestations
Trust a source-to-output claim only when the producer, recipe and complete declared inputs are trustworthy
The helper does not prove that a command actually compiles the source or that a build is isolated from undeclared inputs
It cannot establish provenance for an old binary through a no-op command
For expensive qualification, review the producer declaration and recipe before trusting its receipt

The helper checks source, inputs and artifacts again after execution
Persistent changes invalidate the run
It cannot detect a change that occurs and reverses between those checks
Declared context labels are assertions, not automatic detection of nested compilers, remote targets or feature flags
Declare relevant compiler binaries, configuration and external assets as inputs
Ignored files, environment values, submodule configuration and undeclared assets are not a complete source snapshot

The receipt changes atomically from `running` to `success`, `failed`, `interrupted`, `refused` or `invalidated`
An accepted failed run replaces earlier success evidence
One run owns a receipt through a stable POSIX lock file
A competing run refuses before launch and does not replace the owner's evidence
Do not delete the shared lock inode
Preflight rejection of an unsafe receipt destination makes no writes
An invalid specification can also refuse before a safe receipt destination is established
A process killed with SIGKILL or a host crash can leave `running`, which never verifies as success
The helper cleans its owned process group on normal completion, failure and catchable interruption
It installs signal handlers before spawn and defers interruption until it owns the returned process
The protocol does not block signals inherited by the command
On macOS, a final group signal can report EPERM after that group terminates
The helper checks for absent or zombie-only members before accepting that cleanup
A live group or a failed process query remains an error
It cannot clean a daemon that deliberately escapes that process group
Resource locks and project-specific cleanup remain the caller's responsibility
It never removes failed outputs automatically
Inspect and remove only the declared outputs before retrying a producer

## Comparative measurements

Freeze the before and after source identities before measuring
Keep commands, selected checks, input data, features and target conditions comparable
Separate cold work from incremental work
Record cache state and external compiler or cache daemons when accounting for process CPU
Child-process CPU alone can omit work performed by a daemon
One anomalous run does not establish a general compiler-cache or artifact-reuse diagnosis

## Shared workspaces and isolated configuration

Linked Git worktrees share the common repository's stash
A stash is not private to the worktree that created it
Do not pop or drop another worker's stash
Check actual paths and current ownership before modifying a live workspace

For an isolated test, set `HOME` and the required XDG directories per subprocess
Pass required assets explicitly
Preserve unrelated environment variables unless the test demonstrates that they affect the result
Do not remove the whole environment as an unexplained isolation measure

## Accurate reading and citations

Follow the current question through the code
Treat unrelated types as opaque until their internals affect that question
Do not create extra note files merely to record every file read

For byte-accurate log citations, read original bytes and split records on `b"\n"`
Python text reads can normalize CR and CRLF
`splitlines()` also treats CR as a boundary
Those transformations can change both the cited bytes and apparent line numbers
