function fish_user_key_bindings
    # Have emacs keybindings where possible, unless overridden by vi
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    # Custom keys
    bind --mode insert \e\[3\;5~ kill-word
end
