FIRST_RUN=true
PACKAGES=true

echo === Requiring manual intervention:
# Require intervention
if $PACKAGES; then
    sudo dnf install -y envycontrol
    sudo dnf install -y vscodium
    sudo dnf install -y steam podman podman-compose
    sudo dnf install -y input-remapper
    sudo systemctl enable --now input-remapper

    # Choose the default shell
    sudo dnf install -y zsh
    chsh -s /bin/zsh
fi

# dnf
if $PACKAGES; then
    echo === Installing most through dnf
    sudo dnf install -y flatpak xdg-desktop-portal-gtk git alacritty
    sudo dnf install -y powertop htop fastfetch
    sudo dnf install -y tealdeer trash-cli bat lsd
    sudo dnf install -y parallel zoxide yt-dlp neovim ranger tmux #qmk
    sudo dnf install -y wl-clipboard libqalculate
    sudo dnf install -y ripgrep fd fzf tidy
    sudo dnf install -y python3-pip cmake pypy3 nodejs # deno
    sudo dnf install -y tailscale

    sudo dnf install -y kate plasma-systemmonitor partitionmanager filelight # discover
    sudo dnf install -y gimp krita kdenlive
    sudo dnf install -y nextcloud-client

    sudo dnf install -y @virtualization
    sudo systemctl enable libvirtd --now

    # pypy3 specific
    pypy3 -m ensurepip
    pypy3 -m pip install --upgrade pip

    # cpp
    echo === Installing for cpp
    sudo dnf install -y clang cppcheck valgrind perf gdb
    sudo dnf install -y boost-devel

    # gimmick
    sudo dnf install -y zlib-devel

    # UV
    flatpak install --system -y cc.arduino.IDE2

    # de 10 nano
    # added /etc/udev/rules.d/45-altera.rules
    sudo dnf install -y screen

    # rust
    if ! command -v rustup &> /dev/null; then
        echo === Installing rustup
        export RUSTUP_HOME="$HOME/.local/share/rustup"
	export CARGO_HOME="$HOME/.local/share/cargo"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        source "/home/rad1an/.local/share/cargo/env"
        rustup update
        rustup default stable
        rustup component add rust-analyzer
    fi

    # Flatpaks
    echo === Installing flatpaks
    flatpak install --system -y com.discordapp.Discord im.riot.Riot org.signal.Signal org.telegram.desktop
    flatpak install --system -y org.onlyoffice.desktopeditors
    flatpak install --system -y com.github.tchx84.Flatseal com.bitwarden.desktop org.kde.kalgebra
    flatpak install --system -y com.obsproject.Studio org.videolan.VLC
    flatpak install --system -y io.github.martchus.syncthingtray
    flatpak install --system -y org.prismlauncher.PrismLauncher com.modrinth.ModrinthApp com.heroicgameslauncher.hgl
    flatpak install --system -y net.mullvad.MullvadBrowser com.github.micahflee.torbrowser-launcher com.protonvpn.www org.qbittorrent.qBittorrent app.zen_browser.zen
    flatpak install --system -y com.github.tenderowl.frog org.inkscape.Inkscape
    flatpak install --system -y dev.heppen.webapps io.github.ungoogled_software.ungoogled_chromium

    # Cybersecurity
    flatpak install --system -y org.ghidra_sre.Ghidra

    # Python programs
    echo === Installing python programs
    sudo dnf install -y pipx
    pipx install ruff shell-ai poetry magic-wormhole
    # Useful plugins for projects without venvs
    sudo dnf install -y python3-matplotlib python3-pyperclip
    # Flake8
    if $FIRST_RUN; then
        echo === Creating venvs
        mkdir -p ~/.local/share/venvs
        python -m venv ~/.local/share/venvs/linters_venv
        python -m venv ~/.local/share/venvs/jupyter_venv
        python -m venv ~/.local/share/venvs/rgrader_venv
    fi
    echo === Installing linters to venv
    source ~/.local/share/venvs/linters_venv/bin/activate
    pip install --upgrade pip
    pip install --upgrade flake8
    pip install --upgrade darglint dlint
    pip install --upgrade flake8-annotations flake8-annotations-complexity
    pip install --upgrade flake8-comments flake8-expression-complexity
    pip install --upgrade flake8-use-fstring pep8-naming flake8-docstrings flake8-return
    pip install --upgrade flake8-secure-coding-standard flake8-mutable flake8-picky-parentheses
    # Leave No One Behind
    # sudo dnf install -y python3-idle
    source ~/.local/share/venvs/rgrader_venv/bin/activate
    pip install --upgrade rgrader pylint numpy
    deactivate
    # Missing stubs, mypy
    # pip install --upgrade types-PyYAML
    # pip install --upgrade mypy # for some reason does not work for nvim-lint inside venv
    sudo dnf install -y mypy

    # needed for Jupyter for neovim
    cargo install geckodriver
    source ~/.local/share/venvs/jupyter_venv/bin/activate
    pip install --upgrade notebook nbclassic jupyter-console
    deactivate
fi

# Grub
if [ -f /etc/default/grub ]; then
    if ! grep -q "GRUB_THEME" /etc/default/grub && ! grep -q "# GRUB_TERMINAL_OUTPUT=\"console\"" /etc/default/grub; then
        echo === Changing grub theme
        git clone https://github.com/vinceliuice/grub2-themes.git
        cd grub2-themes
        sudo ./install.sh -t vimix -b
        cd ..
        sudo rm -rf grub2-themes
        # If there is "GRUB_TERMINAL_OUTPUT="console", comment it out
        sudo sed -i 's/GRUB_TERMINAL_OUTPUT="console"/# GRUB_TERMINAL_OUTPUT="console"/g' /etc/default/grub
        sudo sed -i "s/GRUB_TERMINAL_OUTPUT='console'/# GRUB_TERMINAL_OUTPUT='console'/g" /etc/default/grub
        # Remove blank lines
        sudo sed -i '/^$/d' /etc/default/grub
        # Add an empty line
        sudo sed -i -e '$a\' /etc/default/grub
        # Change "GRUB_DISABLE_SUBMENU=true" to "GRUB_DISABLE_SUBMENU=false"
        sudo sed -i 's/GRUB_DISABLE_SUBMENU=true/GRUB_DISABLE_SUBMENU=false/g' /etc/default/grub
        sudo sed -i "s/GRUB_DISABLE_SUBMENU='true'/GRUB_DISABLE_SUBMENU='false'/g" /etc/default/grub
        # Update grub
        sudo grub2-mkconfig -o /etc/grub2.cfg
        sudo grub2-mkconfig -o /etc/grub2-efi.cfg
    fi
fi

if $FIRST_RUN; then
    # Zsh plugins
    cd ~/.local/share/zsh
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git 
    git clone https://github.com/zsh-users/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-history-substring-search
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git
    git clone https://github.com/romkatv/zsh-defer.git
fi

# Change numerosign to numbersign in /usr/share/X11/xkb/symbols/ua
echo === Changing numerosign to numbersign
sudo sed -i 's/numerosign/numbersign/g' /usr/share/X11/xkb/symbols/ua

# If LC_TIME="en_GB.UTF-8" not in /etc/locale.conf:
if ! grep -q "LC_TIME=\"en_GB.UTF-8\"" /etc/locale.conf; then
    echo === Changing locale to GB
    # Remove blank lines
    sudo sed -i '/^$/d' /etc/locale.conf
    # Add an empty line
    sudo sed -i -e '$a\' /etc/locale.conf
    # Append "LC_TIME="en_GB.UTF-8"" line to /etc/locale.conf
    sudo sed -i '$a LC_TIME="en_GB.UTF-8"' /etc/locale.conf
fi

# Disable mouse acceleration even in SDDM
if [ ! -f /etc/X11/xorg.conf.d/50-mouse-acceleration.conf ]; then
    echo === Disabling mouse acceleration in SDDM
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/50-mouse-acceleration.conf << EOF > /dev/null
Section "InputClass"
    Identifier "My Mouse"
    MatchIsPointer "yes"
    Option "AccelerationProfile" "-1"
    Option "AccelerationScheme" "none"
    Option "AccelSpeed" "-1"
EndSection
EOF
fi

# Move to xdg
sudo sh -c "cp /dev/null /etc/profile.d/mycustomvars.sh"
echo "export XDG_DATA_HOME=\"\$HOME/.local/share\"
export XDG_CONFIG_HOME=\"\$HOME/.config\"
export XDG_CACHE_HOME=\"\$HOME/.cache\"
export XDG_STATE_HOME=\"\$HOME/.local/state\"
export PYTHONSTARTUP=\"/etc/python/pythonrc\"
export LESSHISTFILE=\"\$XDG_STATE_HOME\"/less/history
export GTK2_RC_FILES=\"\$XDG_CONFIG_HOME\"/gtk-2.0/gtkrc
export GNUPGHOME=\"\$XDG_DATA_HOME\"/gnupg
export CARGO_HOME=\"\$XDG_DATA_HOME\"/cargo
export RUSTUP_HOME=\"\$XDG_DATA_HOME\"/rustup
export ERRFILE=\"\$XDG_CACHE_HOME/X11/xsession-errors\"
export BUN_INSTALL=\"\$XDG_DATA_HOME\"/bun" | sudo tee -a /etc/profile.d/mycustomvars.sh > /dev/null
sudo sh -c "cp /dev/null /etc/zshenv"
echo "export ZDOTDIR=\"\$HOME\"/.config/zsh" | sudo tee -a /etc/zshenv > /dev/null
sudo mkdir -p /etc/python
sudo sh -c "cp /dev/null /etc/python/pythonrc"
echo "import os
import atexit
import readline
from pathlib import Path

if readline.get_current_history_length() == 0:

    state_home = os.environ.get(\"XDG_STATE_HOME\")
    if state_home is None:
        state_home = Path.home() / \".local\" / \"state\"
    else:
        state_home = Path(state_home)

    history_path = state_home / \"python_history\"
    if history_path.is_dir():
        raise OSError(f\"'{history_path}' cannot be a directory\")

    history = str(history_path)

    try:
        readline.read_history_file(history)
    except OSError: # Non existent
        pass

    def write_history():
        try:
            readline.write_history_file(history)
        except OSError:
            pass

    atexit.register(write_history)
" | sudo tee -a /etc/python/pythonrc > /dev/null
