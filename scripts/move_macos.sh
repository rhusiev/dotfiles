#!/bin/sh
for dir in nvim tmux lsd zsh yabai skhd ruff mypy linearmouse alacritty; do
    ln -sfn "$HOME/dotfiles/config/$dir" "$HOME/.config/$dir"
done
ln -sfn macos.toml "$HOME/dotfiles/config/alacritty/platform.toml"
