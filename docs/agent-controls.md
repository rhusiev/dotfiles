# Universal agent controls

The shared policy defines required outcomes, approvals and resource ownership
The hooks detect changed global instructions at supported tool boundaries
The optional [evidence helper](agent-evidence.md) checks declared execution identities
Neither mechanism grants approval or replaces project-specific launchers

## Action boundaries

The shared `action_boundary_rules` define trigger-based checks before actions and claims
They require agent judgment, not mechanically certified permissions
No new hook certifies the meaning of user approval
The existing freshness hook only enforces loading changed instructions
These additions grant no permission

Before performing or delegating a protected action, identify its operation, target, effect and actual user authorization
Preserve the originating instruction, conditions and limits when delegating
Agent-supplied approval text cannot override the recipient's user or host rules
Without required authority, keep that action pending and continue safe independent preparation
Do not repeat approval for unchanged scope while it remains valid under standing rules

| Trigger | Check | Stop or continue |
| --- | --- | --- |
| Approval to implement a CI job | Does the user also authorize opening an MR/PR in this repository? | Implement locally. Keep publication pending without that authority |
| Permission to review or merge video changes | Does it cover an MR/PR in an unrelated repository? | Do not transfer that permission. Ask only for the uncovered action |
| An explicitly approved scoped post remains unchanged | Are the operation, target, limits and approval still valid? | Proceed without redundant reapproval, subject to compaction, security and host rules |
| Publication or a decision about its scope | Inspect the actual target and full diff. Separate prerequisites, stacked commits and unrelated history. Check selected tests and simulated versus real hardware | Disclose the scope and coverage first. Resolve an ambiguous target or surprising range before publication |
| A conditional budget allowance becomes policy | Preserve the condition, exceptions and target. A relaxed cap does not cancel optimization or raise other caps | Ask before broadcasting broader scope. Retract a corrected rule with every affected recipient |
| A shared signature changes | Identify callers and modes from repository/CI configuration, including study and test-only callers | Run the cheapest affected non-default checks. Name any unexercised mode before handoff |
| An installed wrapper is called a deployed guard | Trace active callers and exercise the prevented failure. Check bypasses and existing locks | Do not claim adoption or fairness from installation or fixtures alone. A passing-alone flaky test does not exclude a product race |
| A delay or speedup receives a safety claim | Separate the configured bound, observed sample, queue time and execution. Compare equivalent conditions | An 18 ms sample does not dismiss a permitted six-second delay. Commit percentages do not measure scheduler speedup |

These checks use the existing plan or task state
They add no approval database, permission tokens, shell parser or automatic test skipping
Ordinary local coding, review and status messages do not need a protected-action approval relay

## Install or update

Python 3.10 or later and Git are required
The freshness state locks use POSIX `flock` on Linux and macOS
Windows needs a supported state-lock adapter before these hooks can enforce freshness
The execution helper supports Linux and macOS process groups, not Windows
Use the same checkout for the shared policy, hooks and runtime adapters
Do not install over another session's live configuration without checking its current bytes
Use a session whose configured workspace includes the target checkout
A permission prompt does not expand that workspace boundary
Allow old hook callbacks to finish before updating their shared state protocol

1. Compare `config/claude/CLAUDE.md` with `config/codex/AGENTS.md` using `cmp`
2. Install `config/claude` at `~/.config/claude`, preserving the existing untracked `work.md`
3. Keep `~/.claude` linked to `~/.config/claude` when Claude uses its default directory
4. Install the Codex mirror and adapters at the active `CODEX_HOME`, normally `~/.codex`
5. Merge the hook registrations from `config/claude/settings.json` and `config/codex/hooks.json` with existing registrations
6. Copy the files in `config/copilot` to the corresponding paths under `~/.copilot`
7. Preserve `~/.copilot/instructions/claude.instructions.md` as a symlink to `~/.config/claude/CLAUDE.md`
8. Link `work.instructions.md` and `ste.instructions.md` in that directory to the corresponding shared modules
9. Keep machine-specific content in the untracked `work.md`, not in a portable module
10. Start disposable sessions in each runtime and check the coverage described below before relying on enforcement

On systems that already link `~/.config/codex` and `~/.codex`, update the shared target once
On systems with a separate active copy, synchronize `~/.codex/AGENTS.md` explicitly
Do not replace an existing Codex or Copilot directory merely to install these files
The general move scripts do not install Copilot or migrate separate runtime copies

Before replacing a live file, compare its hash with the reviewed expected original
Stop on any mismatch
Apply only the task delta when the checkout contains earlier staged or unstaged work
Preserve the index, unrelated files, symlinks and executable modes
Git patches preserve executable bits, not every POSIX permission
Restore the reviewed original modes after applying a task overlay
Repeat `cmp` against the active Codex copy after installation

## Instruction freshness

Each runtime has separate state under `~/.local/share/ai-sessions/.instructions`
The state records acknowledged SHA256 digests and pending read identities
It does not contain instruction bodies
Each callback holds a stable per-runtime/session lock for its complete state transaction
Atomic replacement alone does not protect concurrent updates
The lock is not held while the tool reads the source
Parallel chunks and different files retain their own pending records and verified coverage
Only cooperating callbacks participate in the advisory lock protocol
Do not delete a shared lock inode
The original plan gate remains separate, including its intentional bounded fail-open policy

1. A real session-start event establishes the initial injected baseline
2. Before each supported main-agent tool call, the hook compares the global sources with that baseline
3. If a source changes, the hook permits read-only recovery but refuses state-changing tools
4. A supported read records the requested byte range and the complete source digest
5. A matching successful result verifies that range against the same source version
6. Only complete gap-free byte coverage acknowledges the changed source

Claude observes `~/.config/claude/CLAUDE.md`, `work.md` and `ste.md`
Codex observes its active `AGENTS.md` plus the two shared modules
The freshness module honors `CODEX_HOME` when the caller sets it
Copilot also observes `~/.copilot/copilot-instructions.md`
Optional modules can be absent initially
Removing a previously loaded module or a required entry point marks that source unread
Mutation initially blocks, subject to the bounded recovery described below
Nested agent events with `agent_id` do not read, acknowledge or arm the parent's gates
This isolation requires the host to identify nested events

Codex does not import the shared modules automatically
Its first supported startup therefore requires explicit reads of existing `work.md` and `ste.md`
Without a startup event, all present sources remain unread
Printing another header never acknowledges a changed source
Manufactured Copilot compaction recovery is not a real injection event
If its freshness state is absent, recovery marks every present source unread
Existing valid loaded state remains intact

### Copied-source recovery

A constrained workspace can forbid direct reads of the installed global sources
A coordinator with access can place an exact current copy inside that workspace
The agent can read that copy through the same supported bounded ranges

The hook requires the copy's whole SHA256 to equal a currently changed source's whole SHA256
Before the read, it records the actual source path and digest plus the snapshot path and digest
After the read, both whole digests must remain unchanged
The returned bytes must match the requested source range
Only complete verified coverage acknowledges the actual source

A stale or tampered copy, matching prefix, or path mention does not acknowledge it
This is copied-source recovery, not an injected baseline or permission to read outside the workspace
It uses no alias allowlist or agent-selected acknowledgement
Existing host permissions and source/command boundaries remain unchanged

The supported requests are bounded `Read` ranges and exact single-file `cat` commands
Use consecutive bounded ranges for instruction files larger than a transport's result limit
The tests cover a 52,600-byte source through results smaller than 20,000 bytes
Copilot's `view_range: [first, last]` maps to the shared offset and limit
Use `-1` for the final native Copilot range so its EOF delimiter is preserved
An explicit final line number can omit that delimiter and will not acknowledge EOF coverage

Native Copilot `view` omits one terminal LF when a bounded slice ends before EOF
The adapter identifies native view requests separately from generic reads
For an exact paired `view_range`, the hook accepts that one omitted delimiter only
Every content byte, CR byte and blank line must still match
EOF slices, full-file reads and generic reads retain strict final-byte matching

The shell path accepts `cat path` and `cat -- path` only
It rejects shell operators, substitutions and compound commands
This is not a general shell parser
Other known read tools remain usable for recovery
An unknown tool or shell command is conservatively state-changing

The supported post-tool results are:

| Runtime | Successful result accepted for acknowledgement |
| --- | --- |
| Claude | `tool_response` containing the requested Read text, or `file.content` with matching range metadata |
| Claude/Codex shell | `tool_response` with `exit_code: 0` and complete `stdout` or `output` |
| Copilot | Native `toolResult` with `resultType: "success"` and matching `textResultForLlm` |
| Copilot captured execution envelope | Explicit `success: true` with matching `result.content` and the paired request arguments |

Requests and results must pair through the same normalized tool input and available call ID
The source's SHA256 must remain unchanged across verified chunks
Each result must match the requested original byte range
Exact raw text and explicit `L<number>:` line prefixes are supported
Line numbers and any provided line metadata must agree with the requested source range
Missing metadata is not inferred as success
An explicit successful envelope plus exact requested bytes provides the evidence when no line metadata exists
A filename in an edit, fabricated post event, incomplete coverage, normalized CRLF or failed read cannot acknowledge
Missing bytes cannot acknowledge except for the one native non-EOF LF delimiter described above
Explicit error or truncation flags also prevent acknowledgement
The hook cannot detect later host truncation after the post-tool event
Live native Copilot observation exposed the non-EOF delimiter difference
Supported result framing alone does not establish enforcement for every host or recovery path
Qualify the installed runtime through its real callbacks before relying on it

## Coverage and failures

Claude registrations use `SessionStart`, `PreToolUse` and `PostToolUse`
Copilot uses its native lower-camel-case events through `claude-parity.py`
The adapter normalizes native tool names, JSON arguments, inclusive view ranges and native results
Copilot's `preCompact` adapter provides recovery because its host does not emit a new `sessionStart` after compaction

Codex hook support depends on the installed host
The checked-in configuration is only a registration, not proof that the host emits these events
If its host lacks a lifecycle or post-tool event, that event cannot be emulated by printing success
Use the shared policy and explicit source comparisons where hooks are unavailable
If pre-tool hooks exist but complete successful chunk content is unavailable, the gate cannot acknowledge that read path
Do not disable the gate silently or claim parity
Fix the adapter against a captured, non-sensitive event schema before depending on it

The separate freshness gate stops denying after four mutation refusals or one hour for the same changed-source set
The hour starts at the first refused mutation for that changed-source set
It then emits `INSTRUCTION FRESHNESS UNGUARDED` on mutation attempts
This is bounded recovery for an unsupported transport, not acknowledgement or successful enforcement
The sources remain unread, and the shared policy still requires reading them
Read-only recovery stays available throughout
The legacy plan gate retains its own original limits and state
Host permissions, security controls and resource locks remain separate

Fixture tests exercise the supported schemas, not every released host or live permission flow
No hook can observe a tool that bypasses it
A source can change between the pre-tool check and the tool action
These hooks are forcing functions, not a security sandbox

`INSTRUCTIONS CHANGED OR UNREAD` names the pending sources
Read each named file through a supported complete result path
Restore a deleted source instead of acknowledging its absence
`INSTRUCTION FRESHNESS FAILED` names an adapter or state error
Read-only recovery stays available while a freshness-state error blocks mutation
Inspect the exact session state file and preserve it before repairing corruption
Do not delete another session's state or bypass a host permission denial

## Validation

Run the existing standard-library tests from the checkout:

```sh
python3 -m unittest discover -s config/claude/hooks -p '*_test.py'
python3 -m unittest discover -s config/claude/bin -p '*_test.py'
python3 -m unittest discover -s config/codex/hooks -p '*_test.py'
```

In a disposable live session, edit one instruction source from outside that session
Confirm that the next mutation refuses, recovery reads remain available, and a complete successful read permits the mutation
Restore the fixture source after the exercise
Repeat after compaction and with a nested agent
Do not interpret fixture success as live-host qualification
