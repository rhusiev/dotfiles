# dotfiles

## Usage
1. Clone this git repository to ~/dotfiles
2. Run `scripts/move.sh` on Linux or `scripts/move_macos.sh` on macOS
3. If you want to add some files to dotfiles but don't want them to be added to git, add their location to .gitignore
4. Settings that differ per machine and can't branch on the OS live in untracked files:
   `config/alacritty/platform.toml` (symlink made by the move scripts), `config/claude/work.md`, `config/nvim/lua/work/`

## AI agents
Claude, Codex and Copilot share `config/claude/CLAUDE.md` (= `config/codex/AGENTS.md`) and the hooks in `config/claude/hooks`.
OpenCode loads the same file through `~/.config/opencode/AGENTS.md` and uses its own machine-local plan-gate plugin
Copilot's portable mappings and adapters live in `config/copilot`
Codex's default active configuration is `~/.codex`, not `~/.config/codex`
On Linux, `CLAUDE_CONFIG_DIR` and `CODEX_HOME` can select other directories
On macOS, `scripts/move_macos.sh` links the default Claude and Codex directories to `~/.config`
Per-session plans live in `~/.local/share/ai-sessions`, long-lived per-subject guides in `~/.local/share/ai-guides`

See [agent controls](config/claude/reference/agent-controls.md) for the three hook runtimes' installation, freshness enforcement, failure recovery and coverage limits
See [execution evidence](config/claude/reference/agent-evidence.md) for checked execution, provenance, measurements, shared stashes and accurate citations
Transferable operating knowledge belongs in these reference files, not machine-local guides

### Installing or updating the agent controls

Requirements: Python 3.10 or later and Git. The state locks use POSIX `flock` on Linux and macOS. Windows needs a state-lock adapter. The execution helper supports Linux and macOS process groups, not Windows.
Use one checkout for the shared policy, hooks and runtime adapters. Do not install over another session's live configuration without checking its current bytes. Use a session whose workspace includes the target checkout. A permission prompt does not expand that workspace. Allow old callbacks to finish before updating their shared state protocol.

1. Compare `config/claude/CLAUDE.md` with `config/codex/AGENTS.md` using `cmp`.
2. Install `config/claude` at `~/.config/claude`. Preserve the untracked `work.md`.
3. Link `~/.claude` to `~/.config/claude` when Claude uses its default directory.
4. Install the Codex mirror and adapters at the active `CODEX_HOME`, normally `~/.codex`.
5. Merge the hook registrations from `config/claude/settings.json` and `config/codex/hooks.json` with existing registrations.
6. Copy `config/copilot` to the corresponding paths under `~/.copilot`.
7. Keep `~/.copilot/instructions/claude.instructions.md` as a symlink to `~/.config/claude/CLAUDE.md`.
8. Link `work.instructions.md` and `ste.instructions.md` in that directory to the shared modules.
9. Keep machine-specific content in the untracked `work.md`.
10. Start disposable sessions in each runtime and check the coverage in the agent controls reference before relying on enforcement.

On systems that link `~/.config/codex` and `~/.codex`, update the shared target once. On systems with a separate active copy, synchronize `~/.codex/AGENTS.md`.
Do not replace an existing Codex or Copilot directory to install these files. The move scripts do not install Copilot or migrate separate runtime copies.
Before replacing a live file, compare its hash with the reviewed original. Stop on a mismatch. Apply only the task delta when the checkout has staged or unstaged work. Preserve the index, unrelated files, symlinks and executable modes. Patches preserve executable bits, not every POSIX permission. Restore the reviewed modes after a task overlay. Repeat `cmp` against the active Codex copy after installation.
