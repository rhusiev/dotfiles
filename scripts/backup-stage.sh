#!/usr/bin/env bash
# Stage a third backup: git bundles plus an optional encrypted archive.
# Run manually or from the weekly backup-stage.timer. Nothing is copied to a
# flash drive here; that stays a deliberate step by the user.
set -euo pipefail

STAGE=/hdd/backup-staging
BUNDLES="$STAGE/GitBundles"
ARCHIVE="$STAGE/Archive"
REPOS_FILE="$STAGE/repos.txt"
PATHS_FILE="$STAGE/encrypted-paths.txt"
RECIPIENT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/backup/recipient"

mkdir -p "$BUNDLES" "$ARCHIVE"

if [[ -f "$REPOS_FILE" ]]; then
    while IFS= read -r repo; do
        [[ -z "$repo" || "$repo" == \#* ]] && continue
        if [[ ! -d "$repo/.git" ]]; then
            echo "SKIP no .git: $repo"
            continue
        fi
        name="$(basename "$repo")"
        if ! git -C "$repo" bundle create "$BUNDLES/$name.bundle" --all 2>/dev/null; then
            echo "SKIP bundle failed: $repo"
            continue
        fi
        git -C "$repo" remote -v > "$BUNDLES/$name.origin.txt"
        echo "BUNDLE $name"
    done < "$REPOS_FILE"
fi

if [[ -f "$RECIPIENT_FILE" && -f "$PATHS_FILE" ]]; then
    recipient="$(<"$RECIPIENT_FILE")"
    if [[ -n "$recipient" ]] && tar -C / -T "$PATHS_FILE" -cf - 2>/dev/null \
        | gpg --batch --yes --trust-model always --encrypt \
            --recipient "$recipient" -o "$ARCHIVE/sensitive.tar.gpg" 2>/dev/null; then
        echo "ENCRYPTED $ARCHIVE/sensitive.tar.gpg"
    else
        echo "SKIP encrypted archive: recipient or paths invalid"
    fi
else
    echo "SKIP encrypted archive: need $RECIPIENT_FILE and $PATHS_FILE"
fi

( cd "$STAGE" && find GitBundles Archive -type f -print0 \
    | sort -z | xargs -0 -r sha256sum ) > "$STAGE/SHA256SUMS"
date -Is > "$STAGE/LAST-RUN"
echo "STAGED $STAGE"
