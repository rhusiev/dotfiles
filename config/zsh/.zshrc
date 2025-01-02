# If want to measure startup time, uncomment this
# zmodload zsh/zprof
# And then run `zprof`

if [ -z "$TMUX" ] && [ "$TERM" = "xterm-kitty" ]; then
  exec tmux new-session;
fi

# powerlevel10k(nice prompt)
source $XDG_DATA_HOME/zsh/powerlevel10k/powerlevel10k.zsh-theme
# Enable Powerlevel10k instant prompt. Should stay close to the top of zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
if zmodload zsh/terminfo && (( terminfo[colors] >= 256 )); then
  # Source nicer p10k
  [[ ! -f $XDG_DATA_HOME/zsh/p10k.zsh ]] || source $XDG_DATA_HOME/zsh/p10k.zsh
  if test -n "$KITTY_INSTALLATION_DIR"; then
    export KITTY_SHELL_INTEGRATION="enabled"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
  fi
else
  # might be TTY or some other not very capable terminal
  [[ ! -f $XDG_DATA_HOME/zsh/tty_p10k.zsh ]] || source $XDG_DATA_HOME/zsh/tty_p10k.zsh
fi

source $XDG_DATA_HOME/zsh/zsh-defer/zsh-defer.plugin.zsh

# General
zsh-defer source $XDG_CONFIG_HOME/zsh/aliases.zsh
zsh-defer source $XDG_CONFIG_HOME/zsh/secrets.zsh
HISTFILE=$XDG_DATA_HOME/zsh/zsh_history
export EDITOR='nvim'
HISTSIZE=5000
SAVEHIST=5000
LS_COLORS+=':ow=37;41'
setopt CORRECT # Ask whether to correct misspelled command
setopt share_history # Share history between zsh sessions

# Plugins
# Autosuggestions
# ZSH_AUTOSUGGEST_MANUAL_REBIND=true
# ZSH_AUTOSUGGEST_STRATEGY=history
zsh-defer source $XDG_DATA_HOME/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
# Highlighting
zsh-defer source $XDG_DATA_HOME/zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
# History substring search
zsh-defer source $XDG_DATA_HOME/zsh/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh

zsh-defer source $XDG_CONFIG_HOME/zsh/custom_installs.zsh

zsh-defer source $XDG_CONFIG_HOME/zsh/keybinds.zsh


# Completion
zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' menu select=1
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle :compinstall filename "$XDG_CONFIG_HOME/zsh/.zshrc"

zsh-defer autoload -Uz compinit
zsh-defer compinit -C


# Change cursor shape
zle-line-init() {
    echo -ne "\e[6 q"
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup.
