# dotfiles

## Usage
1. Clone this git repository to ~/dotfiles
2. Run `scripts/move.sh` on Linux or `scripts/move_macos.sh` on macOS
3. If you want to add some files to dotfiles but don't want them to be added to git, add their location to .gitignore
4. Settings that differ per machine and can't branch on the OS live in untracked files:
   `config/alacritty/platform.toml` (symlink made by the move scripts), `config/claude/work.md`, `config/nvim/lua/work/`

## AI agents
Claude and Codex share `config/claude/CLAUDE.md` (= `config/codex/AGENTS.md`) and the hooks in `config/claude/hooks`.
Per-session plans live in `~/.local/share/ai-sessions`, long-lived per-subject guides in `~/.local/share/ai-guides`
