##
## This section contains the keybindings for fish-ai. If you want to change the
## default keybindings, edit the key binding escape sequences below according to
## your needs. You can get the key binding escape sequence for a keyboard shortcut
## using the command `fish_key_reader`.
##
bind --mode insert \cP _fish_ai_codify_or_explain
bind --mode insert -k nul _fish_ai_autocomplete_or_fix

##
## This section contains functionality for setting and clearing the status shown
## in the right prompt.
##
bind --mode insert \r 'clear_status; commandline -f execute'
bind --mode insert \cc 'clear_status; commandline -f repaint; commandline -f cancel-commandline'

function clear_status
    set -e status_emoji
end

##
## This section contains the plugin lifecycle hooks invoked by the fisher package
## manager.
##
function _fish_ai_install --on-event fish_ai_install
    echo "🥡 Setting up a virtual environment..."
    python3 -m venv ~/.local/share/fish-ai
    echo "🍬 Installing dependencies. This may take a few seconds..."
    ~/.local/share/fish-ai/bin/pip install -qq "$(get_installation_url)"
    if ! test -f ~/.config/fish-ai.ini
        echo "👨‍🏫 You must create a configuration file before the plugin can be used!"
    end
end

function _fish_ai_update --on-event fish_ai_update
    echo "🍬 Upgrading dependencies. This may take a few seconds..."
    ~/.local/share/fish-ai/bin/pip install -qq --upgrade "$(get_installation_url)"
end

function _fish_ai_uninstall --on-event fish_ai_uninstall
    if test -d ~/.local/share/fish-ai
        echo "💣 Nuking the virtual environment..."
        rm -r ~/.local/share/fish-ai
    end
end

function get_installation_url
    set plugin (fisher list "fish-ai")
    if test (string sub --start 1 --length 1 "$plugin") = /
        # Install from a local folder
        echo -n "$plugin"
    else
        # Install from GitHub
        echo -n "fish-ai@git+https://github.com/$plugin"
    end
end
