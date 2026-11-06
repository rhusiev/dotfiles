# dotfiles

## Usage
1. Clone this git repository to ~/dotfiles
2. Run `scripts/move.sh` on Linux or `scripts/move_macos.sh` on macOS
3. If you want to add some files to dotfiles but don't want them to be added to git, add their location to .gitignore
4. Settings that differ per machine and can't branch on the OS live in untracked files:
   `config/alacritty/platform.toml` (symlink made by the move scripts), `config/claude/work.md`, `config/nvim/lua/work/`

## AI agents
Claude, Codex and Copilot share `config/claude/CLAUDE.md` (= `config/codex/AGENTS.md`) and the hooks in `config/claude/hooks`.
Copilot's portable mappings and adapters live in `config/copilot`
Codex's default active configuration is `~/.codex`, not `~/.config/codex`
On Linux, `CLAUDE_CONFIG_DIR` and `CODEX_HOME` can select other directories
On macOS, `scripts/move_macos.sh` links the default Claude and Codex directories to `~/.config`
Per-session plans live in `~/.local/share/ai-sessions`, long-lived per-subject guides in `~/.local/share/ai-guides`

See [agent controls](docs/agent-controls.md) for all three runtimes' installation, freshness enforcement, failure recovery and coverage limits
See [execution evidence](docs/agent-evidence.md) for checked execution, provenance, measurements, shared stashes and accurate citations
Transferable operating knowledge belongs in these docs, not machine-local guides
