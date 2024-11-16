bindkey -e

#  Yank to the system clipboard
alias pbcopy="xclip -selection clipboard"


# Ctrl-up, ctrl-down for substring search, up, down to search current thing in history
bindkey '^[[1;5B' history-substring-search-down
bindkey '^[[1;5A' history-substring-search-up
bindkey '^[[B' history-beginning-search-forward
bindkey '^[[A' history-beginning-search-backward
# Ctrl-left, ctrl-right
WORDCHARS="_"
bindkey '^[[1;5C' vi-forward-word
bindkey '^[[1;5D' vi-backward-word
bindkey '^[[1;3C' vi-forward-blank-word
bindkey '^[[1;3D' vi-backward-blank-word
# Home, end
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
# Del, ctrl-del, ctrl-backspace
bindkey '^[[3~' delete-char
bindkey '^[[3;5~' kill-word
bindkey '^H' backward-kill-word
bindkey '^W' backward-kill-word
# Backward kill word for terminal opened inside nvim
bindkey '^[[127;5u' backward-kill-word

# Copy
zle -N widget::copy-selection
function widget::copy-selection {
    if ((REGION_ACTIVE)); then
        zle copy-region-as-kill
        printf "%s" $CUTBUFFER | pbcopy
        printf "%s" $CUTBUFFER | wl-copy
    fi
}
# Scrolls the screen up, in effect clearing it
zle -N widget::scroll-and-clear-screen
function widget::scroll-and-clear-screen() {
    printf "\n%.0s" {1..$LINES}
    zle clear-screen
}

bindkey '^L' widget::scroll-and-clear-screen
bindkey '^[c' widget::copy-selection

# open current command in editor
zsh-defer autoload -U edit-command-line
zle -N edit-command-line
bindkey '^e' edit-command-line

# For vi mode
# function vi-yank-clipboard {
#     zle vi-yank
#    echo "$CUTBUFFER" | wl-copy
#    echo "$CUTBUFFER" | pbcopy -i
# }
# # Cut to the system clipboard
# function vi-delete-clipboard {
#     zle vi-delete
#    echo "$CUTBUFFER" | wl-copy
#    echo "$CUTBUFFER" | pbcopy -i
# }
#
# zle -N vi-yank-clipboard
# zle -N vi-delete-clipboard
# bindkey -M vicmd 'y' vi-yank-clipboard
# bindkey -M vicmd 'd' vi-delete-clipboard
# Backspace to work
# bindkey -M viins '^?' backward-delete-char
# Instant ESC to vi mode
# KEYTIMEOUT=1
# bindkey -M vicmd '^[' undefined-key
