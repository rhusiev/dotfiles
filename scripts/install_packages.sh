FIRST_RUN=false
if $FIRST_RUN; then
    sudo tee -a /etc/yum.repos.d/vscodium.repo << 'EOF'
[gitlab.com_paulcarroty_vscodium_repo]
name=gitlab.com_paulcarroty_vscodium_repo
baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
metadata_expire=1h
EOF
fi
# RPMFusion + Nvidia
sudo dnf update -y
if $FIRST_RUN; then
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
fi
sudo dnf install -y akmod-nvidia
sudo dnf install -y xorg-x11-drv-nvidia-cuda
# Disable nvidia-powerd
sudo systemctl disable --now nvidia-powerd.service

# dnf
sudo dnf install -y htop tealdeer zoxide youtube-dl trash-cli bat lsd flatpak fastfetch powertop neovim python3-neovim git ranger podman-docker podman-compose parallel kitty
sudo dnf install -y fish qalculate python3-devel wl-clipboard ripgrep fzf xclip tidy pip nodejs cmake tlp
sudo dnf install -y kate plasma-systemmonitor plasma-discover-flatpak plasma-discover chromium nextcloud-client
sudo dnf install -y steam gimp krita
# vscodium
sudo dnf install codium -y
# pypy3
sudo dnf install -y pypy3 pypy3-devel
pypy3 -m ensurepip
pypy3 -m pip install --upgrade pip

# calyxos
# sudo dnf install android-tools

# remove unnecessary
sudo dnf remove -y kwrite konversation kmahjongg kmines akregator digikam dragonplayer

# java
# sudo dnf install -y java-17-openjdk-jmods java-17-openjdk-devel java-17-openjdk maven
# cpp
sudo dnf install -y clang clang-tools-extra cppcheck valgrind
# acs
# sudo dnf install -y openmpi openmpi-devel boost-openmpi boost-openmpi-devel
# sudo dnf install -y boost-devel libarchive-devel tbb-devel
# de 10 nano
# added /etc/udev/rules.d/45-altera.rules
# sudo dnf install screen
# opengl
sudo dnf install -y wayland-devel libxkbcommon-devel mesa-libGL-devel glm-devel mangohud
# rust
if ! command -v rustup &> /dev/null; then
    export RUSTUP_HOME="$HOME/.local/share/rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "/home/rad1an/.local/share/cargo/env"
    rustup update
    rustup default stable
    rustup component add rust-analyzer
fi
if $FIRST_RUN; then
    rustup completions fish > ~/.config/fish/completions/rustup.fish
fi

# mariadb
# sudo systemctl enable mariadb
# sudo systemctl start mariadb

# LaTeX
sudo dnf install 'tex(wallpaper.sty)' 'tex(fontawesome5.sty)' 'tex(hyphenat.sty)' rubber

# needed for Jupyter for neovim
cargo install geckodriver
pipx install notebook nbclassic jupyter-console

# Keyboard remap
sudo dnf install input-remapper -y
sudo systemctl enable --now input-remapper

# Flatpaks
if $FIRST_RUN; then
    # Add flathub
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi
# Install apps
flatpak --user install -y com.discordapp.Discord
flatpak --user install -y com.github.tchx84.Flatseal com.bitwarden.desktop com.github.d4nj1.tlpui
flatpak --user install -y com.obsproject.Studio org.videolan.VLC org.kde.kalgebra
flatpak --user install -y org.prismlauncher.PrismLauncher
# Additional
flatpak --user install -y com.github.micahflee.torbrowser-launcher org.signal.Signal org.telegram.desktop org.inkscape.Inkscape org.kde.kdenlive

# Python programs
pip install --user --upgrade pipx
pipx install ruff shell-ai poetry
if $FIRST_RUN; then
    poetry completions fish > ~/.config/fish/completions/poetry.fish
fi
# Useful plugins for projects without venvs
pip install --upgrade matplotlib pyperclip pynput
# Flake8
if $FIRST_RUN; then
    mkdir -p ~/.local/share/venvs
    python -m venv ~/.local/share/venvs/flake8_venv
fi
source ~/.local/share/venvs/flake8_venv/bin/activate
pip install --upgrade pip
pip install --upgrade flake8
pip install --upgrade darglint dlint
pip install --upgrade flake8-annotations flake8-annotations-complexity
pip install --upgrade flake8-comments flake8-expression-complexity
pip install --upgrade flake8-use-fstring pep8-naming flake8-docstrings flake8-return
pip install --upgrade flake8-secure-coding-standard flake8-mutable flake8-picky-parentheses
deactivate
# Missing stubs, mypy
pip install --upgrade types-PyYAML
pip install --upgrade mypy

if $FIRST_RUN; then
    # Bun
    curl -fsSL https://bun.sh/install | bash
    bun install -g eslint prettier prettier-plugin-tailwindcss eslint-config-prettier healthier eslint-plugin-react
fi

if $FIRST_RUN; then
    # Zsh plugins
    # cd ~/.local/share/zsh
    # git clone --depth=1 https://github.com/romkatv/powerlevel10k.git 
    # git clone https://github.com/zsh-users/zsh-autosuggestions
    # git clone https://github.com/zsh-users/zsh-history-substring-search
    # git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

    # Choose the default shell
    chsh -s /bin/fish
fi

# Grub
if [ -f /etc/default/grub ]; then
    if ! grep -q "GRUB_THEME" /etc/default/grub && ! grep -q "# GRUB_TERMINAL_OUTPUT=\"console\"" /etc/default/grub; then
        git clone https://github.com/Se7endAY/grub2-theme-vimix.git
        sudo mkdir /boot/grub2/themes
        sudo cp -r grub2-theme-vimix/Vimix/ /boot/grub2/themes/Vimix
        # If there is "GRUB_TERMINAL_OUTPUT="console", comment it out
        sudo sed -i 's/GRUB_TERMINAL_OUTPUT="console"/# GRUB_TERMINAL_OUTPUT="console"/g' /etc/default/grub
        # Remove blank lines
        sudo sed -i '/^$/d' /etc/default/grub
        # Add an empty line
        sudo sed -i -e '$a\' /etc/default/grub
        # Append "GRUB_THEME="/boot/grub2/themes/Vimix/theme.txt"" line to /etc/default/grub
        sudo sed -i '$a GRUB_THEME="/boot/grub2/themes/Vimix/theme.txt"' /etc/default/grub
        # Change "GRUB_DISABLE_SUBMENU=true" to "GRUB_DISABLE_SUBMENU=false"
        sudo sed -i 's/GRUB_DISABLE_SUBMENU=true/GRUB_DISABLE_SUBMENU=false/g' /etc/default/grub
        rm -rf grub2-theme-vimix
        # Update grub
        sudo grub2-mkconfig -o /etc/grub2.cfg
        sudo grub2-mkconfig -o /etc/grub2-efi.cfg
    fi
fi

# Change numerosign to numbersign in /usr/share/X11/xkb/symbols/ua
sudo sed -i 's/numerosign/numbersign/g' /usr/share/X11/xkb/symbols/ua

# If LC_TIME="en_GB.UTF-8" not in /etc/locale.conf:
if ! grep -q "LC_TIME=\"en_GB.UTF-8\"" /etc/locale.conf; then
    # Remove blank lines
    sudo sed -i '/^$/d' /etc/locale.conf
    # Add an empty line
    sudo sed -i -e '$a\' /etc/locale.conf
    # Append "LC_TIME="en_GB.UTF-8"" line to /etc/locale.conf
    sudo sed -i '$a LC_TIME="en_GB.UTF-8"' /etc/locale.conf
fi

# Disable mouse acceleration even in SDDM
if [ ! -f /etc/X11/xorg.conf.d/50-mouse-acceleration.conf ]; then
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
