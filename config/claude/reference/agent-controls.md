# Agent controls reference

Claude, Codex and Copilot use the hooks described here. OpenCode uses its own local port.
The shared policy defines required outcomes, approvals and resource ownership.
The hooks detect changed global instructions at supported tool boundaries.
The optional evidence helper checks declared execution identities.
Neither mechanism grants approval or replaces project-specific launchers.

## Action boundaries

The normative checks are `action_boundary_rules` in CLAUDE.md. They require judgment, not mechanically certified permissions. No hook certifies the meaning of user approval. The freshness hook only enforces loading changed instructions.

Examples:
- Approval to implement a CI job does not authorize opening an MR/PR. Implement locally and keep publication pending
- Permission to review or merge video changes does not cover an unrelated repository
- An unchanged, approved scoped post needs no reapproval while its operation, target, limits and approval remain valid
- For publication, inspect the target and full diff. Separate prerequisites, stacked commits and unrelated history. Check selected tests and simulated versus real hardware. Disclose the scope and coverage first
- A conditional budget allowance does not cancel optimization or raise other caps. Ask before broadcasting broader scope. Retract a corrected rule with every affected recipient
- A shared signature change needs the callers and build modes from repository and CI configuration. Run the cheapest affected non-default checks. Name unexercised modes
- An installed wrapper is not a deployed guard. Trace active callers and exercise the prevented failure. Check bypasses and existing locks
- A delay or speedup claim needs the configured bound, observed sample, queue time and execution under comparable conditions. An 18 ms sample does not dismiss a permitted six-second delay. Commit percentages do not measure scheduler speedup

These checks use the existing plan or task state. They add no approval database, permission tokens, shell parser or automatic test skipping. Ordinary local coding, review and status messages need no protected-action relay.

## Instruction freshness

Each runtime has separate state under `~/.local/share/ai-sessions/.instructions`.
The state records acknowledged SHA256 digests and pending read identities. It does not contain instruction bodies.
Each callback holds a per-runtime/session lock for its complete state transaction. Atomic replacement alone does not protect concurrent updates.
The lock is not held while the tool reads the source.
Parallel chunks and different files keep their own pending records and verified coverage.
Only cooperating callbacks use the advisory lock. Do not delete a shared lock inode.
The legacy plan gate remains separate, including its bounded fail-open policy.

1. A real session-start event establishes the injected baseline.
2. Before each supported main-agent tool call, the hook compares the global sources with that baseline.
3. If a source changes, the hook permits read-only recovery and refuses state-changing tools.
4. A supported read records the requested byte range and the complete source digest.
5. A matching successful result verifies that range against the same source version.
6. Only complete gap-free byte coverage acknowledges the changed source.

Claude observes `~/.config/claude/CLAUDE.md`, `work.md` and `ste.md`.
Codex observes its active `AGENTS.md` plus the two shared modules.
The freshness module honors `CODEX_HOME`. The fallback order is `CODEX_HOME`, then an existing `~/.codex`, then `~/.config/codex`.
Copilot also observes `~/.copilot/copilot-instructions.md`.
Optional modules can be absent initially. Removing a loaded module or a required entry point marks that source unread.
Mutation initially blocks, subject to the bounded recovery below.
Nested agent events with `agent_id` do not read, acknowledge or arm the parent's gates. This needs host support.

Codex does not import the shared modules. Its first supported startup needs explicit reads of existing `work.md` and `ste.md`.
Without a startup event, all present sources stay unread. Printing another header never acknowledges a changed source.
Manufactured Copilot compaction recovery is not a real injection event. If its state is absent, recovery marks every present source unread. Existing valid loaded state stays intact.

### Copied-source recovery

A constrained workspace can forbid direct reads of installed global sources.
A coordinator with access can place an exact current copy inside that workspace.
The agent can read that copy through the same supported bounded ranges.

The hook requires the copy's whole SHA256 to equal a currently changed source's whole SHA256.
Before the read, it records the actual source path and digest plus the snapshot path and digest.
After the read, both whole digests must stay unchanged. The returned bytes must match the requested source range.
Only complete verified coverage acknowledges the actual source.
A stale or tampered copy, matching prefix or path mention does not acknowledge it.
This is copied-source recovery, not an injected baseline or permission to read outside the workspace.
It uses no alias allowlist or agent-selected acknowledgement. Host permissions and source/command boundaries stay unchanged.

The supported requests are bounded `Read` ranges and exact single-file `cat` commands.
Use consecutive bounded ranges for files larger than a transport's result limit.
The tests cover a 52,600-byte source through results smaller than 20,000 bytes.
Copilot's `view_range: [first, last]` maps to the shared offset and limit. Use `-1` for the final native range so its EOF delimiter is preserved. An explicit final line number can omit that delimiter and will not acknowledge EOF coverage.

Native Copilot `view` omits one terminal LF when a bounded slice ends before EOF.
The adapter identifies native view requests separately from generic reads.
For an exact paired `view_range`, the hook accepts that one omitted delimiter only.
Every content byte, CR byte and blank line must still match. EOF slices, full-file reads and generic reads keep strict final-byte matching.

The shell path accepts `cat path` and `cat -- path` only. It rejects operators, substitutions and compound commands. This is not a general shell parser.
Other known read tools remain usable for recovery. An unknown tool or shell command is conservatively state-changing.

Supported post-tool results:

| Runtime | Successful result accepted for acknowledgement |
| --- | --- |
| Claude | `tool_response` with the requested Read text, or `file.content` with matching range metadata |
| Claude/Codex shell | `tool_response` with `exit_code: 0` and complete `stdout` or `output` |
| Copilot | Native `toolResult` with `resultType: "success"` and matching `textResultForLlm` |
| Copilot captured envelope | Explicit `success: true` with matching `result.content` and paired request arguments |

Requests and results must pair through the same normalized tool input and available call ID.
The source's SHA256 must stay unchanged across verified chunks. Each result must match the requested original byte range.
Exact raw text and explicit `L<number>:` line prefixes are supported. Line numbers and metadata must agree with the requested range. Missing metadata is not inferred as success.
An explicit successful envelope plus exact requested bytes provides the evidence when no line metadata exists.
A filename in an edit, a fabricated post event, incomplete coverage, normalized CRLF or a failed read cannot acknowledge.
Missing bytes cannot acknowledge, except for the one native non-EOF LF delimiter.
Explicit error or truncation flags also prevent acknowledgement.
The hook cannot detect later host truncation after the post-tool event.
Live native Copilot observation exposed the non-EOF delimiter difference.
Supported result framing does not establish enforcement for every host or recovery path. Qualify the installed runtime through its real callbacks.

## Coverage and failures

Claude registrations use `SessionStart`, `PreToolUse` and `PostToolUse`.
Copilot uses its native lower-camel-case events through `claude-parity.py`.
The adapter normalizes native tool names, JSON arguments, inclusive view ranges and native results.
Copilot's `preCompact` adapter provides recovery because its host does not emit a new `sessionStart` after compaction.

Codex hook support depends on the installed host. The checked-in configuration is a registration, not proof that the host emits these events.
If its host lacks a lifecycle or post-tool event, printing success cannot emulate it.
Use the shared policy and explicit source comparisons where hooks are unavailable.
If pre-tool hooks exist but complete successful chunk content is unavailable, the gate cannot acknowledge that read path.
Do not disable the gate silently or claim parity. Fix the adapter against a captured, non-sensitive event schema.

The freshness gate stops denying after four mutation refusals or one hour for the same changed-source set.
The hour starts at the first refused mutation for that set.
It then emits `INSTRUCTION FRESHNESS UNGUARDED` on mutation attempts.
This is bounded recovery for an unsupported transport, not acknowledgement or successful enforcement.
The sources stay unread, and the shared policy still requires reading them.
Read-only recovery stays available.
The legacy plan gate keeps its own limits and state.
Host permissions, security controls and resource locks remain separate.

Fixture tests exercise the supported schemas, not every released host or live permission flow.
No hook can observe a tool that bypasses it.
A source can change between the pre-tool check and the tool action.
These hooks are forcing functions, not a security sandbox.

`INSTRUCTIONS CHANGED OR UNREAD` names the pending sources.
Read each named file through a supported complete result path.
Restore a deleted source instead of acknowledging its absence.
`INSTRUCTION FRESHNESS FAILED` names an adapter or state error.
Read-only recovery stays available while a freshness-state error blocks mutation.
Inspect the exact session state file and preserve it before repairing corruption.
Do not delete another session's state or bypass a host permission denial.

## Validation

Run the standard-library tests from the checkout:

```sh
python3 -m unittest discover -s config/claude/hooks -p '*_test.py'
python3 -m unittest discover -s config/claude/bin -p '*_test.py'
python3 -m unittest discover -s config/codex/hooks -p '*_test.py'
```

In a disposable session, edit one instruction source from outside that session.
Check that the next mutation refuses, recovery reads remain available, and a complete successful read permits the mutation.
Restore the fixture source after the exercise.
Repeat after compaction and with a nested agent.
Do not interpret fixture success as live-host qualification.
