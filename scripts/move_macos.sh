#!/bin/sh
for dir in nvim tmux lsd zsh yabai skhd ruff mypy linearmouse alacritty karabiner claude codex; do
    ln -sfn "$HOME/dotfiles/config/$dir" "$HOME/.config/$dir"
done
ln -sfn "$HOME/.config/claude" "$HOME/.claude"
ln -sfn "$HOME/.config/codex" "$HOME/.codex"
ln -sfn macos.toml "$HOME/dotfiles/config/alacritty/platform.toml"
