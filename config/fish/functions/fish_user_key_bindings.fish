function fish_user_key_bindings
    # Have emacs keybindings where possible, unless overridden by vi
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    # Custom keys
    bind --mode insert \e\[3\;5~ kill-path-component
    bind --mode insert \e\[3\;3~ kill-bigword
    bind --mode insert \cW backward-kill-path-component
    bind --mode insert \e\x7F backward-kill-bigword
    bind --mode insert \e\[1\;3D backward-bigword
    bind --mode insert \e\[1\;3C forward-bigword
end
