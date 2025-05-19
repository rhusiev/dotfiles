#!/bin/sh

(mv $HOME/.local $HOME/.local.old || echo "No .local") && ln -s $HOME/dotfiles/local $HOME/.local
(mv $HOME/.config $HOME/.config.old || echo "No .config") && ln -s $HOME/dotfiles/config $HOME/.config
(mv $HOME/Templates $HOME/Templates.old || echo "No Templates") && ln -s $HOME/dotfiles/Templates $HOME/Templates
