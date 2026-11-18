# Copilot runtime mapping

Apply the three symlinked modules in `~/.copilot/instructions/`: Claude's shared entry point, `work.md` and `ste.md`. Copilot does not expand their imports. Use the entry point's task table for selective reads from `~/.config/claude/reference/`. Do not link the topics or `conventions.md` as global modules. Read conventions only when the header names them. Keep machine-specific policy out of tracked files
For a role defined in `work.md`, read its named local guides when the user invokes it. Role guides are not global instruction modules.

## Hooks and recovery

- `~/.copilot/hooks/claude-parity.json` registers `claude-parity.py`, which calls the shared hooks. Use the printed `copilot-<sessionId>` binding. The adapter does not prune shared plans, topics or other bindings
- Only native `sessionStart` establishes the initial injection baseline. Copilot does not emit it after compaction. The pre-compaction hook saves the tail and arms the plan gate. Read the bound plan on the next main-agent tool call. A recovery header neither marks absent sources read nor invalidates valid state
- The freshness gate observes the entry point, three global modules and applicable conventions. Use `view` with `path` and inclusive `view_range`; `-1` means through EOF. Exact, successful, gap-free coverage of one version counts. Unsupported or truncated output does not. After four mutation denials or one hour it can report UNGUARDED, not read. See `~/.config/claude/reference/agent-controls.md` for accepted event shapes and recovery. Fixtures do not prove live enforcement
- `TASK INSTRUCTIONS UNREAD` is separate. Read the named topic with `view` before retrying that action. Its read state resets on compaction and does not expire into permission

## Tools and coordinating sessions

- On every `task` call, set `model` and `reasoning_effort` explicitly unless I or project instructions specify otherwise. Match Codex's readers: `bulk-reader` uses `gpt-6-luna` / `medium`, `careful-reader` uses `gpt-6-luna` / `xhigh`, and `deep-reader` uses `gpt-6.1-sol` / `medium`. All other agent types use `gpt-6.1-sol` / `low`. These defaults override the general orchestration tiers on Copilot
- Readers have read and search tools only. Read their exact escalated ranges with `view` before editing, including move destinations in an `apply_patch`
- Use `~/.copilot/bin/agent-lock` in place of Claude's lock command. It adds Copilot process ownership and uses the same locks. Use the shared `agent_check.py` for costly runs needing identity evidence, not as a substitute for the project launcher or approvals
- In autopilot, `ask_user` is declined. When present, ask the user through the available conversation channel. When absent, queue the question, context and default in the plan and continue independent work
- Session automations stop with the runtime. On resume compare the last recorded wake with the time now, record the gap and reconcile owned work. Prefer long context for long-running coordination if the model supports it and the budget allows
