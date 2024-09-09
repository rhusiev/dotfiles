echo === Configuring repos
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
    sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:paul4us/Fedora_40/home:paul4us.repo
fi
# RPMFusion + Nvidia
# sudo dnf update -y
# if $FIRST_RUN; then
#     sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
#     sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# fi
# sudo dnf install -y akmod-nvidia
# sudo dnf install -y xorg-x11-drv-nvidia-cuda
# Docker
if $FIRST_RUN; then
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
fi

# dnf
echo === Installing most through dnf
sudo dnf install -y htop tealdeer zoxide youtube-dl trash-cli bat lsd flatpak fastfetch powertop neovim python3-neovim git ranger parallel kitty
sudo dnf install -y fish qalculate python3-devel wl-clipboard ripgrep fd-find fzf xclip tidy pip nodejs cmake tmux
sudo dnf install -y kate plasma-systemmonitor chromium nextcloud-client
sudo dnf install -y plasma-discover-flatpak plasma-discover
sudo dnf install -y steam gimp krita
# vscodium
sudo dnf install codium -y
# klassy window decorations
sudo dnf install -y klassy
# docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
# pypy3
sudo dnf install -y pypy3 pypy3-devel
pypy3 -m ensurepip
pypy3 -m pip install --upgrade pip

# calyxos
# sudo dnf install android-tools

# remove unnecessary
echo === Removing unnecessary
sudo dnf remove -y kwrite konversation kmahjongg kmines akregator digikam dragonplayer

# java
# sudo dnf install -y java-17-openjdk-jmods java-17-openjdk-devel java-17-openjdk maven
# cpp
echo === Installing for cpp
sudo dnf install -y clang clang-tools-extra cppcheck valgrind
# acs
# sudo dnf install -y openmpi openmpi-devel boost-openmpi boost-openmpi-devel
sudo dnf install -y boost-devel libarchive-devel tbb-devel
# de 10 nano
# added /etc/udev/rules.d/45-altera.rules
# sudo dnf install screen
# opengl
# sudo dnf install -y wayland-devel libxkbcommon-devel mesa-libGL-devel glm-devel mangohud
# OS
sudo dnf install -y gdb
# sudo dnf install @virtualization # Installs the next:
# sudo dnf install -y libvirt-daemon-config-network libvirt-daemon-kvm qemu-kvm virt-install virt-manager virt-viewer SDL2_image capstone
# sudo dnf install -y cyrus-sasl cyrus-sasl-gssapi daxctl-libs device-mapper-multipath-libs edk2-ovmf glusterfs glusterfs-cli glusterfs-client-xlators glusterfs-fuse gnutls-utils gssproxy gtk-vnc2
# sudo dnf install -y gvnc iproute-tc libblkio libburn libcacard libev libfdt libgfapi0 libgfrpc0 libgfxdr0 libglusterfs0 libiscsi libisoburn libisofs libnbd libnfsidmap libphodav libpmem librados2 librbd1 librdmacm
# sudo dnf install -y libtpms libverto-libev
# sudo dnf install -y libvirt-client libvirt-daemon-common libvirt-daemon-driver-interface libvirt-daemon-driver-network libvirt-daemon-driver-nodedev libvirt-daemon-driver-nwfilter libvirt-daemon-driver-qemu libvirt-daemon-driver-secret libvirt-daemon-driver-storage libvirt-daemon-driver-storage-core libvirt-daemon-driver-storage-disk libvirt-daemon-driver-storage-gluster libvirt-daemon-driver-storage-iscsi libvirt-daemon-driver-storage-iscsi-direct libvirt-daemon-driver-storage-logical libvirt-daemon-driver-storage-mpath libvirt-daemon-driver-storage-rbd libvirt-daemon-driver-storage-scsi libvirt-daemon-driver-storage-zfs libvirt-daemon-lock libvirt-daemon-log libvirt-daemon-plugin-lockd libvirt-daemon-proxy libvirt-glib libvirt-libs
# sudo dnf install -y libwsman1 libxdp lttng-ust lzop mdevctl
# sudo dnf install -y nbdkit-basic-filters nbdkit-basic-plugins nbdkit-selinux nbdkit-server ndctl-libs nfs-utils numad passt-selinux python3-libvirt python3-libxml2
# sudo dnf install -y qemu-audio-alsa qemu-audio-dbus qemu-audio-jack qemu-audio-oss qemu-audio-pa qemu-audio-pipewire qemu-audio-sdl qemu-audio-spice qemu-block-blkio qemu-block-curl qemu-block-dmg
# sudo dnf install -y qemu-block-gluster qemu-block-iscsi qemu-block-nfs qemu-block-rbd qemu-block-ssh qemu-char-baum qemu-char-spice qemu-device-display-vhost-user-gpu qemu-device-display-virtio-gpu qemu-device-display-virtio-gpu-ccw qemu-device-display-virtio-gpu-gl qemu-device-display-virtio-gpu-pci qemu-device-display-virtio-gpu-pci-gl qemu-device-display-virtio-gpu-pci-rutabaga qemu-device-display-virtio-gpu-rutabaga qemu-device-display-virtio-vga qemu-device-display-virtio-vga-gl qemu-device-display-virtio-vga-rutabaga qemu-device-usb-host qemu-device-usb-redirect qemu-device-usb-smartcard qemu-img qemu-pr-helper qemu-system-x86 qemu-system-x86-core qemu-ui-curses
# sudo dnf install -y qemu-ui-egl-headless qemu-ui-gtk qemu-ui-sdl qemu-ui-spice-app rpcbind rutabaga-gfx-ffi scrub seabios-bin seavgabios-bin spice-glib spice-gtk3 sssd-nfs-idmap swtpm swtpm-libs swtpm-selinux swtpm-tools systemd-container thrift usbredir virglrenderer virt-manager-common virtiofsd xen-libs xen-licenses xorriso zfs-fuse zlib-ng libvirt-daemon nbdkit nbdkit-curl-plugin nbdkit-ssh-plugin passt
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
if $FIRST_RUN; then
    echo === Adding rustup completions
    rustup completions fish > ~/.config/fish/completions/rustup.fish
fi

# mariadb
# sudo systemctl enable mariadb
# sudo systemctl start mariadb

# LaTeX
echo === Installing latex things
sudo dnf install 'tex(wallpaper.sty)' 'tex(fontawesome5.sty)' 'tex(hyphenat.sty)' rubber

# Keyboard remap
echo === Installing input-remapper
sudo dnf install input-remapper -y
sudo systemctl enable --now input-remapper

# Flatpaks
# if $FIRST_RUN; then
#     # Add flathub
#     flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
#     flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# fi
# Install apps
echo === Installing flatpaks
flatpak --user install -y com.discordapp.Discord
flatpak --user install -y com.github.tchx84.Flatseal com.bitwarden.desktop org.kde.kalgebra
flatpak --user install -y com.obsproject.Studio org.videolan.VLC
flatpak --user install -y org.prismlauncher.PrismLauncher com.modrinth.ModrinthApp
flatpak --user install -y net.mullvad.MullvadBrowser
# Additional
flatpak --user install -y com.github.micahflee.torbrowser-launcher org.signal.Signal org.telegram.desktop org.inkscape.Inkscape org.kde.kdenlive
# Need to be installed --system
flatpak --system install -y com.dec05eba.gpu_screen_recorder

# Python programs
echo === Installing python programs
pip install --user --upgrade pipx
pipx install ruff shell-ai poetry magic-wormhole
if $FIRST_RUN; then
    echo === Adding poetry completions
    poetry completions fish > ~/.config/fish/completions/poetry.fish
fi
# Useful plugins for projects without venvs
pip install --upgrade matplotlib pyperclip pynput
# Flake8
if $FIRST_RUN; then
    echo === Creating venvs
    mkdir -p ~/.local/share/venvs
    python -m venv ~/.local/share/venvs/linters_venv
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
pip install --upgrade rgrader pylint
deactivate
# Missing stubs, mypy
pip install --upgrade types-PyYAML
pip install --upgrade mypy

# needed for Jupyter for neovim
# cargo install geckodriver
# pipx install notebook nbclassic jupyter-console

if $FIRST_RUN; then
    # Bun
    echo === Installing bun
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
        echo === Changing grub theme
        https://github.com/vinceliuice/grub2-themes.git
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
