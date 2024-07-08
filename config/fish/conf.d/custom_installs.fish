# if "flake8_venv" in PATH
if string match -q "flake8_venv" $PATH
    return
end

# Editor
set -gx EDITOR 'nvim'

# Bun
set -gx BUN_INSTALL "$HOME/.local/share/bun"
set fish_user_paths $fish_user_paths $BUN_INSTALL

# PATH
set -gx PATH $PATH ~/.local/bin ~/.config/git/commands ~/.local/share/venvs/flake8_venv/bin $BUN_INSTALL/bin ~/.dotfiles/scripts/
