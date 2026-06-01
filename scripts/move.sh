#!/bin/sh

echo "Symlinking..."

(mv $HOME/.local $HOME/.local.old || echo "No .local") && ln -s $HOME/dotfiles/local $HOME/.local
(mv $HOME/.config $HOME/.config.old || echo "No .config") && ln -s $HOME/dotfiles/config $HOME/.config
(mv $HOME/Templates $HOME/Templates.old || echo "No Templates") && ln -s $HOME/dotfiles/Templates $HOME/Templates

DOTFILES_FLATPAK="$HOME/dotfiles/flatpaks"

echo "Restoring Flatpak configs from repository..."

for app_dir in "$DOTFILES_FLATPAK"/*; do
    [ -d "$app_dir" ] || continue
    
    APP_ID=$(basename "$app_dir")
    SRC="$DOTFILES_FLATPAK/$APP_ID/config"
    DEST="$HOME/.var/app/$APP_ID/config"

    echo "Restoring: $APP_ID"
    
    mkdir -p "$HOME/.var/app/$APP_ID"
    
    rsync -av --delete "$SRC/" "$DEST/"
done

echo "Restore complete!"
