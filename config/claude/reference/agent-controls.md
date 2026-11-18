# Agent controls reference

Claude, Codex and Copilot use the hooks described here. OpenCode uses its own local port.
The shared policy defines required outcomes, approvals and resource ownership.
The hooks detect changed global instructions at supported tool boundaries.
The optional evidence helper checks declared execution identities.
Neither mechanism grants approval or replaces project-specific launchers.

## Action boundaries

The normative checks are `action_boundary_rules` in CLAUDE.md. The hooks check instruction reads, not the meaning or scope of approval.

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
The JSON state records acknowledged SHA256 digests and pending read identities.
Owner-only snapshot files beside it retain acknowledged source bytes, including the injected startup baseline.
These local files contain instruction text. Do not copy them into logs or publish them.
Each callback holds a per-runtime/session lock for its complete state transaction. Atomic replacement alone does not protect concurrent updates.
The lock is not held while the tool reads the source.
Parallel chunks and different files keep their own pending records and verified coverage.
Only cooperating callbacks use the advisory lock. Do not delete a shared lock inode.
The legacy plan gate remains separate, including its bounded fail-open policy.

1. A real session-start event establishes the injected baseline.
2. Before each supported main-agent tool call, the hook compares the global sources with that baseline.
3. If a source changes, the hook permits read-only recovery and refuses state-changing tools.
4. With an acknowledged snapshot, the refusal names a unified diff with both digests and the current line count.
5. A complete verified diff read acknowledges that source only if its current digest still matches. This refreshes the snapshot.
6. Another edit before acknowledgment regenerates the diff from the same acknowledged snapshot.

Without a matching snapshot, the refusal names the source size and exact unread line ranges.
Only complete, gap-free coverage of that version acknowledges the source and creates its snapshot.
Copilot refusals recommend `view_range` chunks of at most ~15 KB and give the final line number.
A range end beyond EOF clamps to the last source line. Returned text must still match all requested bytes through EOF.
Truncated or failed reads never count, including diff reads.

Claude observes `~/.config/claude/CLAUDE.md`, `work.md` and `ste.md`.
Codex observes its active `AGENTS.md` plus the two shared modules.
The freshness module honors `CODEX_HOME`. The fallback order is `CODEX_HOME`, then an existing `~/.codex`, then `~/.config/codex`.
Copilot also observes `~/.copilot/copilot-instructions.md`.
Optional modules can be absent initially. Removing a loaded module or a required entry point marks that source unread.
Mutation initially blocks, subject to the bounded recovery below.
Nested agent events with `agent_id` do not read, acknowledge or arm the parent's gates. This needs host support.

Codex does not import the shared modules. Its first supported startup needs explicit reads of existing `work.md` and `ste.md`.
Every runtime also observes `~/.config/claude/conventions.md` when the event's working directory is outside a git repository, or in a repository whose top level tracks neither `AGENTS.md` nor `CLAUDE.md`. A git failure counts as no team file. No runtime imports the file, so it is never part of a startup baseline and always needs an explicit complete read. In a repository that tracks one of those files, the source is not observed, and the session-start header says it is skipped.
Without a startup event, all present sources stay unread. Printing another header never acknowledges a changed source.
Manufactured Copilot compaction recovery is not a real injection event. If its state is absent, recovery marks every present source unread. Existing valid loaded state stays intact.

### On-demand topic reads

The shared pre-tool hook checks the current digest only for the topics a recognized main-agent action needs. They are never part of the injected startup baseline. `TASK INSTRUCTIONS UNREAD` names the missing reads and denies that call. Repeating the call does not clear it. Unrelated work and recovery reads remain available. A current, complete read counts even if made before the first refusal. Use the same verified Read or exact `cat` result shapes as for global instructions. A workspace copy of a topic must have the same filename and bytes as the installed reference

| Observable action | Required topic |
| --- | --- |
| Structured edit or patch of a recognized source file (including a move destination) | Code style; also design for known UI suffixes |
| Structured edit under the local `ai-guides` root | Guide maintenance |
| Recognized Git subcommand, e.g. `add`, `merge` or `commit` | Git; `commit` also needs reviews |
| PR/thread authoring tools or literal `gh`/`glab` review commands | Reviews; PR creation and CLI merge also need Git |
| `agent-lock acquire`, `run` or `break` | Locks. The topic gate does not block `release` or `status` |
| Creating a child session, running a dynamic workflow or responding to a child plan | Orchestration |

An acknowledged file changing or disappearing blocks its next matching action. A startup/resume/compact callback discards topic acknowledgments, partial coverage and unfinished topic reads, without discarding the global baseline. The bounded global fail-open does not release an unread topic. If an installed file or usable post-tool result is missing, report that dependency. Do not retry with a different tool to avoid a refusal

This is not intent detection or a shell interpreter. It cannot identify a design discussion, a chat-only review, arbitrary scripts/aliases, every language, or direct device access. An operation inside a nested agent does not use the parent's read state. Some applications handle their own tools without sending callbacks. OpenCode's machine-local plugin is not part of this implementation. The shared entry point remains mandatory on those paths

To check an installation, start a disposable session and attempt to edit a disposable Python file before reading code style. The pre-tool event should refuse the edit and name `code-style.md`. Read that file in full through a supported tool, repeat the edit, then compact. The next matching edit should require the file again. A fixture replay is not evidence that the host emitted those events

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
It uses no alias allowlist or agent-selected acknowledgment. Host permissions and source/command boundaries stay unchanged.

The supported requests are bounded `Read` ranges and exact single-file `cat` commands.
Use consecutive bounded ranges for files larger than a transport's result limit.
The tests cover a 52,600-byte source through results smaller than 20,000 bytes.
Copilot's `view_range: [first, last]` maps to the shared offset and limit. Use `-1` to request through EOF, or give the final line number.

Live Copilot hook captures on 2026-11-16 show that native `view` omits one terminal LF, including at EOF.
The adapter identifies native view requests separately from generic reads.
For a paired native range or whole-file request, the hook accepts that one omitted delimiter only.
Every content byte, CR byte and blank line must still match. Generic reads keep strict final-byte matching.

The same live captures show that native `bash` appends `<shellId: N completed with exit code 0>`.
For a paired exact `cat`, the hook removes that footer and permits one added separator LF.
The source bytes must otherwise match exactly. A nonzero exit code, incomplete output or truncation flag cannot acknowledge.

Claude's structured Read result omits the same terminal LF when a range ends before the last line.
Claude counts lines by splitting on LF. A file that ends with LF has one more line in `numLines` and `totalLines` than it has LF-terminated lines.
The hook accepts the omitted LF only when `startLine + numLines - 1` is less than `totalLines`. A range that reaches the last line keeps strict final-byte matching.

The shell path accepts `cat path` and `cat -- path` only. It rejects operators, substitutions and compound commands. This is not a general shell parser.
Claude's Bash result has no exit code, and it removes trailing LF bytes from `stdout`.
For that shape, the hook requires `interrupted: false`, an empty `stderr` and `stdout` equal to the source without its trailing LF bytes.
Claude saves a large output to a file and returns a preview. That preview does not match the source, so it does not acknowledge.
Other known read tools remain usable for recovery. An unknown tool or shell command is conservatively state-changing.

Supported post-tool results:

| Runtime | Successful result accepted for acknowledgment |
| --- | --- |
| Claude | `tool_response` with the requested Read text, or `file.content` with `startLine`, `numLines` and `totalLines` in Claude's LF-split count |
| Claude Bash | `tool_response` without `exit_code`, with `interrupted: false`, empty `stderr` and `stdout` that matches except for trailing LF bytes |
| Claude/Codex structured shell | `tool_response` with `exit_code: 0` and complete `stdout` or `output` |
| Codex desktop Bash | `PostToolUse` with bare text for an exact single-file `cat`, paired to its request and matching every source byte |
| Copilot | Native `toolResult` with `resultType: "success"` and matching `textResultForLlm`, allowing the native framing described above |
| Copilot captured envelope | Explicit `success: true` with matching `result.content` and paired request arguments |

Requests and results must pair through the same normalized tool input and available call ID.
The source's SHA256 must stay unchanged across verified chunks. Each result must match the requested original byte range.
Exact raw text and explicit `L<number>:` line prefixes are supported. Line numbers and metadata must agree with the requested range. Missing metadata is not inferred as success.
An explicit successful envelope plus exact requested bytes provides the evidence when no line metadata exists.
A filename in an edit, a fabricated post event, incomplete coverage, normalized CRLF or a failed read cannot acknowledge.
Missing bytes cannot acknowledge, with limited delimiter exceptions. Native Copilot `view` can omit one terminal LF, including at EOF. Claude Read can omit the one non-EOF LF delimiter. Claude Bash can omit trailing LF bytes.
Explicit error or truncation flags also prevent acknowledgment.
The hook cannot detect later host truncation after the post-tool event.
Live native Copilot captures established the terminal LF omission and the shell completion footer.
Results recorded in a Claude Code transcript exposed the Claude Read line count, the Read delimiter omission and the Bash result shape.
Codex desktop also sends Bash output as a bare string in `tool_response`.
A live capture on 12 Nov 2026 showed this for successful, failed and truncated commands.
The callback contains no exit status. `PostToolUse` alone does not prove command success.
For this shape, acknowledgment requires the paired exact `cat` request and all unchanged source bytes.
Error messages, truncated previews and missing final newlines fail the byte comparison.
The hook proves complete content delivery for that read. It cannot prove the command's exit status.
The Claude and Copilot result rules do not accept this Codex-only shape.
See [OpenAI's hook documentation](https://learn.chatgpt.com/docs/hooks#posttooluse) for the callback contract.

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
This is bounded recovery for an unsupported transport, not acknowledgment or successful enforcement.
The sources stay unread, and the shared policy still requires reading them.
Read-only recovery stays available.
The legacy plan gate keeps its own limits and state.
Host permissions, security controls and resource locks remain separate.

Fixture tests exercise the supported schemas, not every released host or live permission flow.
No hook can observe a tool that bypasses it.
A source can change between the pre-tool check and the tool action.
These hooks are forcing functions, not a security sandbox.

`INSTRUCTIONS CHANGED OR UNREAD` names each pending diff or full source.
Read the named diff or outstanding source ranges through a supported complete result path.
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
