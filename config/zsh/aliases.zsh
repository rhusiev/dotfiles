# alias update-grub="sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg && sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
update() {
    SESSION_NAME="system_update_$RANDOM"
    
    if [ -z "$TMUX" ]; then
        # Not in tmux, create new session
        tmux new-session -d -s $SESSION_NAME
        tmux split-window -h -t $SESSION_NAME
        tmux send -t $SESSION_NAME:1.1 "flatpak --user update -y && flatpak update -y && tldr --update" C-m
        # tmux send -t $SESSION_NAME:1.2 "sudo dnf update -y" C-m
        tmux send -t $SESSION_NAME:1.2 "yay --noconfirm" C-m
        tmux -2 attach-session -t $SESSION_NAME
    else
        # Already in tmux, split current window
        CURRENT_SESSION=$(tmux display-message -p '#S')
        last_window=$(tmux list-windows -t $CURRENT_SESSION | wc -l)
        tmux split-window -v -t $CURRENT_SESSION.$last_window
        last_window=$((last_window + 1))
        tmux send -t $CURRENT_SESSION.$last_window "flatpak --user update -y && flatpak update -y && tldr --update" C-m
        tmux split-window -h -t $CURRENT_SESSION.$last_window
        last_window=$((last_window + 1))
        # tmux send -t $CURRENT_SESSION.$last_window "sudo dnf update -y" C-m
        tmux send -t $CURRENT_SESSION.$last_window "yay --noconfirm" C-m
    fi
}

mkv2p4() {
    name=$1
    name=${name%.*}
    ffmpeg -i $name.mkv -c copy $name.mp4
}

alias bat="bat --theme ansi"
alias ls="lsd -1 -L"
alias ll="ls -l"
alias la="ls -lA"
alias rm='echo "Not trash?"; echo; echo "Add backslash to remove permanently"; false'
alias ff="fastfetch -s title:separator:terminal:shell:memory:swap:uptime:colors -l fedora_small"
alias fastfetch="fastfetch -s title:separator:os:host:kernel:terminal:shell:display:cpu:gpu:memory:swap:theme:localip:uptime:colors"

alias glog="git log --graph --oneline"
alias gu="~/dotfiles/scripts/backup_conspectus.sh; ~/dotfiles/scripts/backup_dotfiles.sh"
alias cs="~/dotfiles/scripts/backup_conspectus.sh"
alias ґіт="git"

alias kssh="kitty +kitten ssh"
servre() {
    if [ $# -eq 0 ]
    then
        echo "Usage: connect_ssh <ip_address>"
    else
        ssh -i ~/.ssh/Servers/id_rsa rad1an-server@$1 -t "wg-quick down wirehole && wg-quick up wirehole"
    fi
}

d() {
    all_args=${@:1}
    nohup bash -c "$all_args" &>/dev/null & disown
}
alias dk="kitty --detach"
o() {
    all_args=${@:1}
    nohup xdg-open "$all_args" &>/dev/null & disown
}

alias license="cp ~/Templates/LICENSE.md ."

alias aocproj="cargo init && mkdir src/bin && cp $HOME/Templates/aoc_rust/gitignore .gitignore && \\rm src/main.rs && cp $HOME/Templates/aoc_rust/first.rs src/bin/first.rs"
alias aocsec="cp src/bin/first.rs src/bin/second.rs"

alias pyproj="cp ~/Templates/python_template/.* . && cp ~/Templates/python_template/* ."
alias da='deactivate'

alias clang++="clang++ -Wall -pedantic -Werror=vla"
alias cppbuild="podman build -f project.Dockerfile . -t"
alias cppcompile="setarch `uname -m` -R podman run --rm -ti -v .:/app/project:z" # setarch... to disable aslr for sanitizers
alias cppproj="cp $HOME/Templates/cpp_template/* . -r && mv gitignore .gitignore && mkdir src; mkdir include"
alias cppargs="cp $HOME/Templates/cpp_args/args.cpp src/ && cp $HOME/Templates/cpp_args/args.hpp include/"
cpprun() {
    container=$1
    args=${@:2}
    podman run --rm -ti -v $(pwd):/app/project:z $container --r="$args"
}
cpplsp() {
    sed -i "s/\\/app\\/project/$(echo ${PWD} | sed 's/\//\\\//g')/g" cmake-build-debug/compile_commands.json && cp cmake-build-debug/compile_commands.json .
}

alias v="nvim -u ~/.config/nvim/init_code.lua"
alias vb="nvim -u ~/.config/nvim/init_bigfile.lua"
alias lvim="nvim -u ~/.config/nvim/init_latex.lua"
alias jvim="nvim -u ~/.config/nvim/init_jupyter.lua"
# alias dvim="konsole -e nvim -u ~/.config/nvim/init_code.lua"
alias dvim="kitty --detach sh -c 'nvim -u ~/.config/nvim/init_code.lua'"
alias convim="nvim -u ~/.config/nvim/init_code.lua ~/.config/nvim/init_code.lua +'cd $HOME/.config/nvim'"
alias zshrc="nvim -u ~/.config/nvim/init_code.lua ~/.config/zsh/.zshrc +'cd $HOME/.config/zsh'"

alias pls='sudo "/bin/bash" -c "$(fc -ln -1)"'
alias novideo="__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia"



# java
# alias jproj="mvn archetype:generate -DgroupId=nl.r1a -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=true -Dversion=0.1"
# alias cdj="cd src/main/java/nl/r1a/"
# alias cdjb="cd ../../../../../"
# alias jrun="java -cp target/classes/"
# alias jcc="mvn compile -f ../../../../.."
# export jp="src/main/java/nl/r1a/"
# function spring_project() {
#     echo "Creating spring project $1"
#     mkdir $1
#     cd $1
#     spring init --java-version=17 --packaging=jar --group-id=nl.r1a --build=maven --artifact-id=$1 -x -n $1
#     cd ..
# }
# alias sproj="spring_project"
# path+=~/dotfiles/scripts/spring/bin
# fpath+=~/dotfiles/scripts/spring/shell-completion/zsh
# # The next line updates PATH for the Google Cloud SDK.
# if [ -f '/home/rad1an/google-cloud-sdk/path.zsh.inc' ]; then . '/home/rad1an/google-cloud-sdk/path.zsh.inc'; fi
# # The next line enables shell command completion for gcloud.
# if [ -f '/home/rad1an/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/rad1an/google-cloud-sdk/completion.zsh.inc'; fi

