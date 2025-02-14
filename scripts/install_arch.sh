FIRST_RUN=false

echo === Requiring manual intervention:
# Require intervention
yay -S envycontrol
yay -S webapp-manager vscodium-bin
sudo pacman -S steam podman podman-compose
yay -S input-remapper-git
sudo systemctl enable --now input-remapper


# Choose the default shell
sudo pacman -S --noconfirm zsh
chsh -s /bin/zsh

# pacman
echo === Installing most through pacman
sudo pacman -S --noconfirm flatpak xdg-desktop-portal-gtk flatpak-kcm git alacritty
sudo pacman -S --noconfirm powertop htop fastfetch
sudo pacman -S --noconfirm tealdeer trash-cli bat lsd
sudo pacman -S --noconfirm parallel zoxide yt-dlp neovim ranger tmux qmk
sudo pacman -S --noconfirm wl-clipboard libqalculate flatpak-kcm
sudo pacman -S --noconfirm ripgrep fd fzf tidy
sudo pacman -S --noconfirm python-pip cmake pypy3 deno nodejs 

sudo pacman -S --noconfirm kate plasma-systemmonitor discover partitionmanager
sudo pacman -S --noconfirm gimp krita kdenlive
sudo pacman -S --noconfirm nextcloud-client

# pypy3 specific
pypy3 -m ensurepip
pypy3 -m pip install --upgrade pip

# cpp
echo === Installing for cpp
sudo pacman -S --noconfirm clang cppcheck valgrind perf gdb
sudo pacman -S --noconfirm boost

# bp*a
flatpak install --system -y cc.arduino.IDE2
sudo usermod -a -G uucp $USER

# de 10 nano
# added /etc/udev/rules.d/45-altera.rules
sudo pacman -S --noconfirm screen

# rust
if ! command -v rustup &> /dev/null; then
    echo === Installing rustup
    export RUSTUP_HOME="$HOME/.local/share/rustup"
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
flatpak install --system -y net.mullvad.MullvadBrowser com.github.micahflee.torbrowser-launcher com.protonvpn.www org.qbittorrent.qBittorrent
flatpak install --system -y com.github.tenderowl.frog org.inkscape.Inkscape
flatpak install --system -y net.codelogistics.webapps io.github.ungoogled_software.ungoogled_chromium
# Need to be installed --system
#flatpak --system install -y com.dec05eba.gpu_screen_recorder
# Icons, cursor
flatpak --user override --filesystem=/usr/share/icons/:ro
flatpak --user override --filesystem=/home/$USER/.icons/:ro
flatpak --user override --filesystem=/home/$USER/.local/share/icons/:ro

# Python programs
echo === Installing python programs
sudo pacman -S --noconfirm python-pipx
pipx install ruff shell-ai poetry magic-wormhole
# Useful plugins for projects without venvs
sudo pacman -S --noconfirm python-matplotlib python-pyperclip
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
sudo pacman -S --noconfirm mypy

# needed for Jupyter for neovim
cargo install geckodriver
source ~/.local/share/venvs/jupyter_venv/bin/activate
pip install --upgrade notebook nbclassic jupyter-console
deactivate

# virt
#sudo pacman -S --noconfirm qemu-full qemu-img libvirt virt-install virt-manager virt-viewer \
#edk2-ovmf dnsmasq swtpm guestfs-tools libosinfo tuned
#for drv in qemu interface network nodedev nwfilter secret storage; do
#    sudo systemctl enable virt${drv}d.service;
#    sudo systemctl enable virt${drv}d{,-ro,-admin}.socket;
#done
## add intel_iommu=on to /etc/kernel/cmdline and then sudo reinstall-kernels
#sudo systemctl enable --now tuned.service
#sudo tuned-adm profile virtual-host

# old, mb will need
# calyxos
# sudo dnf install android-tools
# acs
# sudo dnf install -y openmpi openmpi-devel boost-openmpi boost-openmpi-devel
# sudo dnf install -y libarchive-devel tbb-devel
# sudo dnf install -y readline-devel
# opengl
# sudo dnf install -y wayland-devel libxkbcommon-devel mesa-libGL-devel glm-devel mangohud
# OS
# sudo dnf install -y libuuid libuuid-devel nasm acpica-tools strace
# LaTeX
# echo === Installing latex things
# sudo dnf install -y 'tex(wallpaper.sty)' 'tex(fontawesome5.sty)' 'tex(hyphenat.sty)' rubber


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
