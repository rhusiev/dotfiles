#!/usr/bin/env bash
# Run one backup script and record a status file for the tray indicator.
set -u

name="$1"
shift
status_dir=/hdd/backup-staging/status
mkdir -p "$status_dir"
start="$(date -Is)"

if "$@" > "$status_dir/$name.log" 2>&1; then
    result=ok
    message="OK"
else
    result=error
    message="failed, see $name.log"
fi

printf '{"name":"%s","last_run":"%s","status":"%s","message":"%s"}\n' \
    "$name" "$start" "$result" "$message" > "$status_dir/$name.json"

if [[ "$result" == error ]]; then
    notify-send -u critical "Backup $name failed" "$message" 2>/dev/null || true
fi
