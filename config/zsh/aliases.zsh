alias update-grub="sudo grub2-mkconfig -o /etc/grub2.cfg && sudo grub2-mkconfig -o /etc/grub2-efi.cfg && sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
alias update="tmux new-session -d && \
    tmux split-window -h && \
    tmux send -t 0:0.0 'flatpak --user update -y && flatpak update -y && tldr --update' C-m && \
    tmux send -t 0:0.1 'sudo dnf update -y' C-m && \
    tmux -2 attach-session -d"

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

alias pyproj="cp ~/Templates/python_template/.* . && cp ~/Templates/python_template/* ."
alias da='deactivate'

alias clang++="clang++ -Wall -pedantic -Werror=vla"
alias cppbuild="podman build -f project.Dockerfile . -t"
alias cppcompile="podman run --rm -ti -v .:/app/project:z"
alias cppproj="cp $HOME/Templates/cpp_template/* . -r"
cpprun() {
    container=$1
    args=${@:2}
    podman run --rm -ti -v (pwd):/app/project:z $container --r="$args"
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
