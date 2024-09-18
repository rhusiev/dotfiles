export PATH=$PATH:~/.local/bin
export HISTFILE="${XDG_STATE_HOME}"/bash/history
export ERRFILE="$XDG_CACHE_HOME/X11/xsession-errors"
export PYTHONSTARTUP="/etc/python/pythonrc"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export LESSHISTFILE="$XDG_STATE_HOME"/less/history
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH
. "/home/rad1an/.local/share/cargo/env"

export QSYS_ROOTDIR="/drive/fpga/install/23.1std/quartus/sopc_builder/bin"

# venvs
export PATH="$HOME/.local/share/venvs/jupyter_venv/bin:$PATH"
export PATH="$HOME/.local/share/venvs/linters_venv/bin:$PATH"
