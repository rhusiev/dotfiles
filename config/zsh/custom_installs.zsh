# General
# export PATH=$PATH:~/.config/git/commands
fpath+=~/.local/share/zsh/zfunc
export PATH=$PATH:~/.local/bin

# venvs
path+=~/.local/share/venvs/linters_venv/bin
path+=~/.local/share/venvs/rgrader_venv/bin
path+=~/.local/share/venvs/jupyter_venv/bin

# scripts
path+=~/dotfiles/scripts/

# Bun
export BUN_INSTALL="$HOME/.local/share/bun" 
export PATH="$BUN_INSTALL/bin:$PATH"
fpath+="$BUN_INSTALL"
[ -s "/home/rad1an/dotfiles/local/share/bun/_bun" ] && source /home/rad1an/dotfiles/local/share/bun/_bun

# Zoxide
source ~/.local/share/zsh/zoxide_init.sh

# Fzf
source /usr/share/fzf/shell/key-bindings.zsh

# Rustup
source "/home/rad1an/.local/share/cargo/env"
