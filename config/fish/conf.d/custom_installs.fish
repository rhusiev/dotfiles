# if "linters_venv" in PATH
if string match -q "linters_venv" $PATH
    return
end

# Editor
set -gx EDITOR 'nvim'

# Bun
set -gx BUN_INSTALL "$HOME/.local/share/bun"
set fish_user_paths $fish_user_paths $BUN_INSTALL

# PATH
set -gx PATH $PATH ~/.local/bin ~/.config/git/commands ~/.local/share/venvs/linters_venv/bin ~/.local/share/venvs/jupyter_venv/bin ~/.local/share/venvs/rgrader_venv/bin $BUN_INSTALL/bin ~/dotfiles/scripts/
