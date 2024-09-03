# If want to measure startup time, uncomment this
# zmodload zsh/zprof
# And then run `zprof`

# powerlevel10k(nice prompt)
source ~/.local/share/zsh/powerlevel10k/powerlevel10k.zsh-theme
# Enable Powerlevel10k instant prompt. Should stay close to the top of zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# General
HISTFILE=~/.local/share/zsh/zsh_history
export EDITOR='nvim'
HISTSIZE=5000
SAVEHIST=5000
bindkey -v
export PATH=$PATH:~/.local/bin
export PATH=$PATH:~/.config/git/commands
fpath+=~/.local/share/zsh/zfunc
path+=~/.local/share/venvs/linters_venv/bin

# Aliases
alias pbcopy="xclip -selection clipboard"
# alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias update-grub="sudo grub2-mkconfig -o /etc/grub2.cfg; sudo grub2-mkconfig -o /etc/grub2-efi.cfg"
alias update="tmux new-session -d && \
    tmux split-window -h && \
    tmux send -t 0:0.0 'flatpak --user update -y && tldr --update' C-m && \
    tmux send -t 0:0.1 'sudo dnf update -y' C-m && \
    tmux -2 attach-session -d"

alias bat="bat --theme ansi"
alias ls="lsd -1 -L"
alias ll="ls -l"
alias la="ls -lA"
alias rm='echo "Not trash?"; echo; echo "Add backslash to remove permanently"; false'
alias kssh="kitty +kitten ssh"
alias glog="git log --graph --oneline"
alias nf="neofetch --ascii ~/.config/neofetch/fedora.txt --disable model kernel de wm icons theme cpu gpu cpu_usage packages"
alias ff="fastfetch -s title:separator:terminal:shell:memory:swap:uptime:colors -l fedora_small"
alias fastfetch="fastfetch -s title:separator:os:host:kernel:terminal:shell:display:cpu:gpu:memory:swap:theme:localip:uptime:colors"

alias phi="ollama run dolphin-phi:2.7b-v2.6-q8_0"
alias star="ollama run starling-lm:7b-alpha"

alias pyproj="cp ~/Templates/python_template/.* . && cp ~/Templates/python_template/* ."
# alias penv='eval $(pdm venv activate)'
alias da='deactivate'

alias clang++="clang++ -Wall -pedantic -Werror=vla"
alias cppbuild="docker build -f project.Dockerfile . -t"
alias cppcompile="docker run --rm -ti -v .:/app/project:z"
alias cppproj="cp $HOME/Templates/cpp_template/* . -r"
cpprun() {
    container=$1
    args=${@:2}
    docker run --rm -ti -v .:/app/project:z $container --r="$args"
}
cpplsp() {
    echo "s/\//\\\//g"
    echo "s/\\/app\\/project/$(echo ${PWD} | sed 's/\//\\\//g')/g" 
    sed -i "s/\\/app\\/project/$(echo ${PWD} | sed 's/\//\\\//g')/g" cmake-build-debug/compile_commands.json && cp cmake-build-debug/compile_commands.json .
}

alias pls='sudo "/bin/bash" -c "$(fc -ln -1)"'

alias novideo="__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia"
alias battery="sudo cpupower frequency-set --max 1.2GHz -- min 800MHz"
alias plug="sudo cpupower frequency-set --max 4.2GHz -- min 800MHz"
alias nvidia="sudo python ~/dotfiles/envycontrol/envycontrol.py -s hybrid"
alias intel="sudo python ~/dotfiles/envycontrol/envycontrol.py -s integrated"

alias gu="~/dotfiles/scripts/backup_conspectus.sh; ~/dotfiles/scripts/backup_dotfiles.sh"
alias cs="~/dotfiles/scripts/backup_conspectus.sh"
alias ґіт="git"

alias v="nvim -u ~/.config/nvim/init_code.lua"
alias lvim="nvim -u ~/.config/nvim/lua/init_latex.lua"
alias dvim="kitty --detach nvim -u ~/.config/nvim/init_code.lua"
alias convim="nvim -u ~/.config/nvim/init_code.lua ~/.config/nvim/init_code.lua +'cd $HOME/.config/nvim'"
alias zshrc="nvim -u ~/.config/nvim/init_code.lua ~/.config/zsh/.zshrc"

alias dol="nohup dolphin . &>/dev/null & disown"
alias firehome="firefox --profile /home/rad1an/.mozilla/firefox/4nrx48w9.Firehome"


# Bun
export BUN_INSTALL="$HOME/.local/share/bun" 
export PATH="$BUN_INSTALL/bin:$PATH"
fpath+="$BUN_INSTALL"
[ -s "/home/rad1an/dotfiles/local/share/bun/_bun" ] && source /home/rad1an/dotfiles/local/share/bun/_bun


# Plugins
# Autosuggestions
source ~/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
# Highlighting
source ~/.local/share/zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
# History substring search
source ~/.local/share/zsh/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh


# Binds
# For vi mode
#  Yank to the system clipboard
function vi-yank-clipboard {
    zle vi-yank
   echo "$CUTBUFFER" | wl-copy
   echo "$CUTBUFFER" | pbcopy -i
}
# Cut to the system clipboard
function vi-delete-clipboard {
    zle vi-delete
   echo "$CUTBUFFER" | wl-copy
   echo "$CUTBUFFER" | pbcopy -i
}

zle -N vi-yank-clipboard
zle -N vi-delete-clipboard
bindkey -M vicmd 'y' vi-yank-clipboard
bindkey -M vicmd 'd' vi-delete-clipboard
# Backspace to work
bindkey -M viins '^?' backward-delete-char


# Ctrl-up, ctrl-down to search current thing in history, alt-up, alt-down for substring search, up, down for just moving in history
bindkey '^[[1;5B' history-beginning-search-forward
bindkey '^[[1;5A' history-beginning-search-backward
bindkey '^[[1;3A' history-substring-search-up
bindkey '^[[1;3B' history-substring-search-down
bindkey '^[[B' history-search-forward
bindkey '^[[A' history-search-backward
# Ctrl-left, ctrl-right
WORDCHARS="_"
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
# Home, end
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
# Del, ctrl-del, ctrl-backspace
bindkey '^[[3~' delete-char
bindkey '^[[3;5~' kill-word
bindkey '^H' backward-kill-word
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

# Instant ESC to vi mode
KEYTIMEOUT=1
bindkey -M vicmd '^[' undefined-key

# Long Things

# Completion
zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' menu select=1
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle :compinstall filename '/home/rad1an/.config/zsh/.zshrc'

autoload -Uz compinit
compinit -C


# Zoxide
source ~/.local/share/zsh/zoxide_init.sh

# Fzf
source /usr/share/fzf/shell/key-bindings.zsh


# For capable terminals
if zmodload zsh/terminfo && (( terminfo[colors] >= 256 )); then
  # Source nicer p10k
  [[ ! -f ~/.local/share/zsh/p10k.zsh ]] || source ~/.local/share/zsh/p10k.zsh
  if test -n "$KITTY_INSTALLATION_DIR"; then
    export KITTY_SHELL_INTEGRATION="enabled"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
  fi
else
  # might be TTY or some other not very capable terminal
  [[ ! -f ~/.local/share/zsh/tty_p10k.zsh ]] || source ~/.local/share/zsh/tty_p10k.zsh
fi


# Change cursor shape for different vi modes. Needed for konsole.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[2 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[6 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[6 q"
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[6 q' ;} # Use beam shape cursor for each new prompt.


# java
# alias jproj="mvn archetype:generate -DgroupId=nl.r1a -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=true -Dversion=0.1"
# alias cdj="cd src/main/java/nl/r1a/"
# alias cdjb="cd ../../../../../"
# alias jrun="java -cp target/classes/"
# alias jcc="mvn compile -f ../../../../.."
# export jp="src/main/java/nl/r1a/"
# function spring_project() {
#     echo "Creating spring project $1"
#     mkdir $1
#     cd $1
#     spring init --java-version=17 --packaging=jar --group-id=nl.r1a --build=maven --artifact-id=$1 -x -n $1
#     cd ..
# }
# alias sproj="spring_project"
# path+=~/dotfiles/scripts/spring/bin
# fpath+=~/dotfiles/scripts/spring/shell-completion/zsh
# # The next line updates PATH for the Google Cloud SDK.
# if [ -f '/home/rad1an/google-cloud-sdk/path.zsh.inc' ]; then . '/home/rad1an/google-cloud-sdk/path.zsh.inc'; fi
# # The next line enables shell command completion for gcloud.
# if [ -f '/home/rad1an/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/rad1an/google-cloud-sdk/completion.zsh.inc'; fi

