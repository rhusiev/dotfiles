#!/bin/sh

(mv ../.local ../.local.old || echo "No .local") && ln -s $HOME/dotfiles/local $HOME/.local
(mv ../.config ../.config.old || echo "No .config") && ln -s $HOME/dotfiles/config $HOME/.config
(mv ../.mozilla ../.mozilla.old || echo "No .mozilla") && ln -s $HOME/dotfiles/mozilla $HOME/.mozilla
(mv ../.mullvad-browser ../.mullvad-browser.old || echo "No .mullvad-browser") && ln -s $HOME/dotfiles/mullvad-browser $HOME/.mullvad-browser
(mv ../Templates ../Templates.old || echo "No Templates") && ln -s $HOME/dotfiles/Templates $HOME/Templates
