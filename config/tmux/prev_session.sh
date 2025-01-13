#!/bin/bash
current_session=$(tmux display-message -p "#S")
current_num=${current_session//[!0-9]/}

prev_session=$(tmux list-sessions -F "#{session_name}" | grep -E "^[0-9]+$" | sort -rn | awk -v target=$current_num '$1 < target {print $1; exit}')

if [ ! -z "$prev_session" ]; then
    tmux switch-client -t "$prev_session"
    tmux kill-session -t "$current_session"
fi
