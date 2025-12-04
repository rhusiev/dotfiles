FIRST_RUN=false
PACKAGES=false

echo === Requiring manual intervention:
# Require intervention
if $PACKAGES; then
    # Choose the default shell
    sudo dnf install -y zsh
    chsh -s /bin/zsh
    sudo dnf install -y input-remapper
    sudo systemctl enable --now input-remapper

    sudo dnf copr enable erovia/dfu-programmer
    sudo dnf copr enable erovia/dfu-prog
    sudo dnf install \
      https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

    echo === Nvidia
    sudo dnf install -y akmod-nvidia
    sudo dnf install -y xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs
    sudo dnf install -y nvidia-vaapi-driver libva-utils vdpauinfo # video acceleration
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
      sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.0-1
    sudo dnf install -y \
      nvidia-container-toolkit-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-toolkit-base-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container1-${NVIDIA_CONTAINER_TOOLKIT_VERSION}

    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    sudo tee /etc/systemd/system/nvidia-cdi-generate.service << 'EOF'
[Unit]
Description=Generate NVIDIA CDI specification
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable nvidia-cdi-generate.service

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

    sudo dnf install -y uv
    # qmk
    sudo dnf install -y arm-none-eabi-gcc-cs-c++ arm-none-eabi-newlib avr-binutils avr-gcc avr-gcc-c++ avr-libc avrdude dfu-programmer dfu-util kernel-devel libusb-compat-0.1-devel libusb1-devel
    uv tool install qmk
    qmk setup -H ~/Drive/Projects/Personal/keyboard/qmk_config
    sudo cp /hdd/drive/Projects/Personal/keyboard/qmk_config/util/udev/50-qmk.rules /etc/udev/rules.d/
fi

# dnf
if $PACKAGES; then
    echo === Codecs
    sudo dnf install -y libavcodec-freeworld svt-vp9-libs x265 x265-libs
    echo === Installing most through dnf
    sudo dnf install -y flatpak xdg-desktop-portal-gtk git alacritty
    sudo dnf install -y powertop htop fastfetch
    sudo dnf install -y tealdeer trash-cli bat lsd
    sudo dnf install -y yt-dlp neovim ranger tmux #zoxide
    sudo dnf install -y wl-clipboard libqalculate qalculate
    sudo dnf install -y ripgrep fd fzf tidy
    sudo dnf install -y cmake pypy3 nodejs python-devel # deno
    sudo dnf install -y steam vlc
    # podman; fix podman permissions
    sudo dnf install -y podman podman-compose
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo semanage fcontext -a -e /var/lib/containers /home/rad1an/dotfiles/local/share/containers
    sudo restorecon -R -v /home/rad1an/dotfiles/local/share/containers

    sudo dnf install -y kate plasma-systemmonitor partitionmanager filelight kcolorchooser # discover
    sudo dnf install -y gimp krita kdenlive
    sudo dnf install -y nextcloud-client

    sudo dnf install -y @virtualization
    sudo systemctl enable libvirtd --now

    # pypy3 specific
    pypy3 -m ensurepip
    pypy3 -m pip install --upgrade pip

    # diploma
    sudo dnf install -y gpsd gpsd-clients

    # cpp
    echo === Installing for cpp
    sudo dnf install -y clang cppcheck valgrind perf gdb
    sudo dnf install -y boost-devel

    # gimmick
    sudo dnf install -y zlib-devel

    # solomon
    sudo dnf install -y libcap-devel
    sudo dnf install -y mono # for MissionPlanner.exe
    sudo dnf install -y FlightGear xdotool
    # adrupilot
    sudo dnf install -y ccache astyle libtool libxml2-devel libxslt-devel SFML-devel gtk3-devel wxGTK-devel python3-wxpython4 freetype-devel libpng-devel libjpeg-turbo-devel portmidi-devel sdl12-compat-devel SDL_image-devel SDL_mixer-devel SDL2_ttf-devel
    sudo dnf remove -y ModemManager

    # de 10 nano
    # added /etc/udev/rules.d/45-altera.rules
    sudo dnf install -y screen

    # control theory
    sudo dnf install -y putty
    flatpak instll -y cc.arduino.IDE2

    # Flatpaks
    echo === Installing flatpaks
    flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y com.discordapp.Discord im.riot.Riot org.signal.Signal org.telegram.desktop
    flatpak install --user -y md.obsidian.Obsidian
    flatpak install --user -y com.github.tchx84.Flatseal com.bitwarden.desktop org.kde.kalgebra me.iepure.devtoolbox
    flatpak install --user -y com.obsproject.Studio
    flatpak install --user -y io.github.martchus.syncthingtray
    flatpak install --user -y org.prismlauncher.PrismLauncher
    flatpak install --user -y net.mullvad.MullvadBrowser org.torproject.torbrowser-launcher com.protonvpn.www app.zen_browser.zen
    flatpak install --user -y com.github.tenderowl.frog org.inkscape.Inkscape io.gitlab.adhami3310.Converter
    flatpak install --user -y dev.heppen.webapps

    # Cargo programs
    uv tool install peco # needed for ask-sh
    cargo install ask-sh
    # Python programs
    echo === Installing python programs
    # sudo dnf install -y pipx
    # pipx install ruff poetry magic-wormhole
    uv tool install ruff
    uv tool install snakeviz # prof visualization
    uv tool install magic-wormhole
    # Useful plugins for projects without venvs
    sudo dnf install -y python3-matplotlib python3-pyperclip
    # Flake8
    if $FIRST_RUN; then
        echo === Creating venvs
        mkdir -p ~/.local/share/venvs
        uv venv ~/.local/share/venvs/linters_venv
        uv venv ~/.local/share/venvs/jupyter_venv
        uv venv ~/.local/share/venvs/rgrader_venv
        uv venv ~/.local/share/venvs/obs_venv
    fi
    echo === Installing linters to venv
    source ~/.local/share/venvs/linters_venv/bin/activate
    uv pip install --upgrade pip
    uv pip install --upgrade flake8
    uv pip install --upgrade darglint dlint
    uv pip install --upgrade flake8-annotations flake8-annotations-complexity
    uv pip install --upgrade flake8-comments flake8-expression-complexity
    uv pip install --upgrade flake8-use-fstring pep8-naming flake8-docstrings flake8-return
    uv pip install --upgrade flake8-secure-coding-standard flake8-mutable flake8-picky-parentheses
    # Leave No One Behind
    # sudo dnf install -y python3-idle
    source ~/.local/share/venvs/rgrader_venv/bin/activate
    uv pip install --upgrade rgrader pylint numpy
    deactivate
    # Missing stubs, mypy
    # uv pip install --upgrade types-PyYAML
    # uv pip install --upgrade mypy # for some reason does not work for nvim-lint inside venv
    sudo dnf install -y mypy

    # needed for Jupyter for neovim
    cargo install geckodriver
    source ~/.local/share/venvs/jupyter_venv/bin/activate
    uv pip install --upgrade notebook nbclassic jupyter-console
    deactivate

    source ~/.local/share/venvs/obs_venv/bin/activate
    uv pip install obsws_python
    deactivate

    # tex stuff
    sudo dnf install -y 'tex(wallpaper.sty)' 'tex(fontawesome5.sty)' 'tex(hyphenat.sty)' rubber
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
echo "export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export LESSHISTFILE="$XDG_STATE_HOME"/less/history
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export ERRFILE="$XDG_CACHE_HOME/X11/xsession-errors"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME"/npm/config/npm-init.js
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME"/npm
export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR"/npm
export PYTHON_HISTORY="$XDG_DATA_HOME"/python_history
export WINEPREFIX="$XDG_DATA_HOME"/wine" | sudo tee -a /etc/profile.d/mycustomvars.sh > /dev/null
sudo sh -c "cp /dev/null /etc/zshenv"
echo "export ZDOTDIR=\"\$HOME\"/.config/zsh" | sudo tee -a /etc/zshenv > /dev/null
