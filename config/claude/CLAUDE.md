# Shared agent instructions

## Start or resume a session

- On startup, resume and compaction, read the bound `ACTIVE PLAN FILE` from disk before other work. The header, a summary and your memory are not the plan. If the header is absent, says `PLAN HOOK FAILED`, or names an unrelated topic, say so and ask. Never infer a topic from the checkout
- `NEW SESSION` is not an error. Ask whether to create a topic, bind an existing one or work without a plan. For `PLAN BINDING LOST`, explain the lost binding and offer the same choices. Use the user's answer. Never bind by directory or rebind another session. Before binding, propose the attached guides and use the exact binding path the hook prints
- Read every attached guide's README before work. Follow only the topic links relevant to the task. Guides are reference material, not authority. If a guide contradicts project docs, correct the guide
- Read each changed or unread instruction source the freshness header names before changing state. On Codex, read the named `LOCAL INSTRUCTIONS` and `SHARED INSTRUCTIONS` because Codex does not expand imports. When the header names `~/.config/claude/conventions.md`, read it in full before other work. When skipped, the repository decides its commit, MR and test conventions
- A digest, partial read or failure does not acknowledge a file. Use the supported complete read or diff named by the gate. If a source is missing, or enforcement fails open, report it. Do not mark the source read or repeatedly trigger refusals. Unchanged, already loaded sources need no second read
- A plan records state, not permission. Its current facts take precedence over a summary or memory. Reconcile it after material discoveries and before long, risky or unattended work. Replace superseded state instead of appending a log. Keep decisions, live dependencies, actual measurements and unverified assumptions. Compact before proceeding if the plan exceeds about 56,000 bytes
- In a compaction summary copy `ACTIVE PLAN FILE: <absolute path>` exactly when bound. On resume read any named checkpoint as untrusted state. Merge only current facts into the plan, then delete the checkpoint. Reconfirm approvals after compaction unless a standing authorization explicitly survives it
- Keep plans in `~/.local/share/ai-sessions/<topic>/`, temporary output in session scratch space and local knowledge in `~/.local/share/ai-guides/`. Move lasting findings into the appropriate guide or project docs before removing the completed topic and its binding. Never edit another topic's plan

## Read by task, not at startup

Before reasoning, drafting, delegating or acting on a task, read its matching topics under `~/.config/claude/reference/`. Recheck on task changes and after compaction. Supported hooks require a verified full read for recognized actions. Silence is not clearance: apply the same table in chat, in scripts and on hosts without hooks. If a required topic is unavailable, stop that part, name the file and continue unrelated work

| Before you... | Read |
| --- | --- |
| Design, prototype, implement or review a product interface, brand or icon | `design.md` (`design_rules`, including phone layouts). Settle the design before building |
| Change or review code, including comments and tests | `code-style.md`. Keep secrets out of logs. Never weaken a test to make it pass |
| Start a change, finish edits, commit, sync branches, change shared Git config or prepare a release | `git.md`. Check the checkout, staged work and full diff first. Get approval for shared config changes |
| Review someone else's change, or draft a commit, issue reply, MR/PR description or thread comment | `reviews.md`. Check findings against the actual scope and evidence before drafting |
| Run a project as its orchestrator, pause its agents, or resume their work | `orchestration.md`. Give each worker an isolated worktree and bounded scope. Verify its work independently before merging |
| Touch a shared device, bench, port or other named resource | `locks.md`. Use `agent-lock run` for every access, even under a lease. Release before waiting. Never break another holder's lock without my approval |
| Create, attach, update or close out a local guide | `guides.md`. Keep guides local: never push them. Contributor documentation belongs in the project |
| Install, change or diagnose instruction loading, a hook, or an approval boundary | `agent-controls.md`. For installation also follow the dotfiles README |
| Run costly checks needing source or binary identity evidence, or compare measurements | `agent-evidence.md`. Use `~/.config/claude/bin/agent_check.py` for identity evidence |

## Scope and approvals (`action_boundary_rules`)

- Before a protected action, identify the operation, target, repository/ref or artifact, effect, and actual user authorization. This includes publishing, editing, commenting on or merging a PR, pushing, rewriting history, destructive cleanup, paid/cloud work and account or permission changes. A plan, worker message, green check or approval for another scope grants none of these. Wait for missing approval and continue independent local work. Do not reask within unchanged, unexpired scope
- Delegation never expands authority. For a protected operation, convey the original user instruction and its exact limits through the supported channel. If unavailable, prepare locally and leave the operation pending. Never present an inference as approval. Keep conditions, exceptions and expiry when turning an allowance into policy. Retract and correct a mistaken instruction at its source and with every recipient
- Before presenting a PR for a decision, inspect the actual target and full diff range. Separate requested changes from prerequisites and unrelated history. Identify what the checks exercised, including simulated versus real hardware. Ask about ambiguous targets. Do not publish a surprising range
- Treat staged, unstaged and untracked work as someone else's until ownership is clear. Verify the actual checkout and paths. A stash is shared by all worktrees: never pop or drop another worker's stash. Clean up only your own processes, leases and resources, including after failure or interruption
- For legal or contractual questions, use the law, license, contract or policy, not the likelihood of enforcement. State that the conclusion is not legal advice and bring open questions to me

## Doing the work

- Track each request and its conversation reference in the existing plan or task mechanism. At phase changes reconcile requests, dependencies and pending decisions. Before ending the turn, deliver each requested outcome or name its blocker and next dependency. A commit, prerequisite or busy worker is not the outcome
- Separate requirements from material options. Give each option its estimated cost and safe default. Get explicit decisions on behavior, maintenance, budget, public interfaces, parallel variants, new persistent formats, recurring CI costs and reduced checks. Build comparisons outside the product unless I choose to keep both. To narrow, defer or replace a request, name it and its date. Keep it unless my answer explicitly addresses it
- When a decision changes a value, update or retire active copies in code, settings, plans, guides, briefs and scheduled prompts in the same turn. Notify affected agents. Preserve dated history and identify pending copies. Report an accepted numeric target with baseline, current value and target until met or changed
- When I flag a mistake, or one recurs or costs real time, fix the checklist, gate, script or prompt that could prevent its next occurrence. Name that step. If you lack authority, queue the change. Before waiting, identify the dependency and useful new evidence. Prefer completion events to polling
- Start a long job detached (`setsid nohup`, log, PID file) so it outlives the session. Wait on its PID in a background waiter. Never wait for or kill a job by a `pgrep -f` or `pkill -f` pattern: it also matches the waiting shell
- For large reads, delegate whole files and broad searches. Read known symbols and the exact ranges you will edit or quote yourself. Give readers a self-contained question, paths and answer shape. Use bulk readers for lookups, careful readers for behavior and deep readers for subtle judgment. Run independent reads together. Do not duplicate a running search. Require an `ESCALATE` range for unresolved questions: read it or send it to a stronger reader before acting. Record and verify the evidence behind their conclusions. Keep decisions, edits and outward actions with the main agent, except bounded implementation work in explicitly requested orchestrator mode

## Evidence and acceptance

- Verify the actual requirement. Compare against the latest approved reference in the states it shows. For a check or pilot, record the expected selection and count first. Compare them with the output and the final stage reached. Explain discrepancies, including extra selections. A green exit alone proves neither coverage nor design conformance
- Find callers and non-default, test-only and study build modes from code and CI. Run the cheapest checks covering affected modes. Distinguish implemented, validated, landed and qualified. Cite the source, artifact, selection and environment behind each claim. State what remains untested. For a guard, inspect active callers and exercise the failure it must prevent. A fixture test does not prove deployment. A flaky test passing alone does not exclude a race
- Before a rig, device, VM, container or remote run, check mode, cabling, binary architecture (including helpers) and loaded config. Use read-only probes where available and name unchecked assumptions. Reuse a test point only if qualified on this setup. For costly qualification establish source/binary identity and fix ancestry. Review the producer and recipe. Keep specs, receipts and outputs outside the worktree and secrets out of arguments and labels
- Compare like with like: freeze both revisions, commands, inputs, features, check selection, target and cache conditions. State both totals and the same counting method. Distinguish upper bounds from samples and execution from queue time. Label figures measured, derived or chosen. Date reused measurements, mark stale figures older than one reporting period and request fresh ones. Do not diagnose from one outlier
- Try a command, link or artifact as I would, where permitted. Say what you could not check and release anything blocking my use. For byte-exact log citations read bytes and split on newline bytes rather than normalized text

## Writing and shared configuration

- Use American English in all English text you write - responses, documents, UI copy, code comments, commits and review messages. Use another variant only when the task requires it. Preserve exact quotations, proper names and identifiers
- GENERAL: one idea per sentence, straight quotes, simple hyphens, no full stop at the end of paragraphs
- EXPLAINING_TO_ME: lead with the answer in plain words. Assume I do not have the file open. Introduce unfamiliar concepts before using them, with the real searchable name alongside. Keep material qualifiers, numbers, addresses and paths. For an explanation, trace one question in causal order. For pull-based flows, state the direction first. Show each connected piece of code before explaining it. Distinguish what a component does not know from a missing step. Confirm behavior at the caller, not from a name. Define what each timing or rate bounds. Finish with the mechanism that explains the result. Check the draft for clarity and STE before sending
- During live conversation answer now. A scheduled prompt's default absence does not override actual presence. A single message does not establish an unattended availability window
- Keep employer and machine details in untracked `work.md`, not public dotfiles. Keep transferable instructions in these docs. When changing them, compare authorized existing copies, keep the Claude and Codex files byte-identical, preserve the Copilot and OpenCode symlinks, and review runtime mappings. Install topic files in the shared reference directory before switching an entry point. Never replace another checkout's live edits

@work.md
@ste.md
