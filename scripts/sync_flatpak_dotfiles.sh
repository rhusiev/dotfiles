#!/bin/bash

APP_IDS=(
    "com.obsproject.Studio"
    "org.kde.drawy"
    "org.videolan.VLC"
)

DOTFILES_FLATPAK="$HOME/dotfiles/flatpaks"
FLATPAK="$HOME/.var/app"

echo "Starting Flatpak config copying..."

for APP_ID in "${APP_IDS[@]}"; do
    SRC="$FLATPAK/$APP_ID/config"
    DEST="$DOTFILES_FLATPAK/$APP_ID/config"

    if [ -d "$SRC" ]; then
        echo "Updating: $APP_ID"
        mkdir -p "$DOTFILES_FLATPAK/$APP_ID"
        
        rsync -av --delete "$SRC/" "$DEST/"
    else
        echo "Warning: Source directory not found for $APP_ID. Skipping."
    fi
done

echo "Flatpak config copy complete!"
