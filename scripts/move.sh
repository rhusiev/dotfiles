#!/bin/sh

(mv ../.local ../.local.old || echo "No .local") && ln -s $HOME/dotfiles/local $HOME/.local
(mv ../.config ../.config.old || echo "No .config") && ln -s $HOME/dotfiles/config $HOME/.config
(mv ../Templates ../Templates.old || echo "No Templates") && ln -s $HOME/dotfiles/Templates $HOME/Templates
