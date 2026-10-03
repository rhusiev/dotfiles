# dotfiles

## Usage
1. Clone this git repository to ~/dotfiles
2. Run `scripts/move.sh` on Linux or `scripts/move_macos.sh` on macOS
3. If you want to add some files to dotfiles but don't want them to be added to git, add their location to .gitignore
4. Settings that differ per machine and can't branch on the OS live in untracked files:
   `config/alacritty/platform.toml` (symlink made by the move scripts), `config/claude/work.md`, `config/nvim/lua/work/`

## AI agents
Claude and Codex share `config/claude/CLAUDE.md` (= `config/codex/AGENTS.md`) and the hooks in `config/claude/hooks`.
Tracked files refer to them as `~/.config/claude` and `~/.config/codex`. On Linux the tools find them there through `CLAUDE_CONFIG_DIR` and `CODEX_HOME` (set by `scripts/install_fedora.sh`). On macOS the tools use their default `~/.claude` and `~/.codex`, which `scripts/move_macos.sh` links to `~/.config`.
Per-session plans live in `~/.local/share/ai-sessions`, long-lived per-subject guides in `~/.local/share/ai-guides`
