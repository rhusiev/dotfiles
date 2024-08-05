alias update-grub="sudo grub2-mkconfig -o /etc/grub2.cfg; sudo grub2-mkconfig -o /etc/grub2-efi.cfg"
alias update="tmux new-session -d && \
    tmux split-window -h && \
    tmux send -t 0:0.0 'flatpak --user update -y && tldr --update' C-m && \
    tmux send -t 0:0.1 'sudo dnf update -y' C-m && \
    tmux -2 attach-session -d"

alias bat="bat --theme ansi"
alias ls="lsd -1 -L"
alias ll="ls -l"
alias la="ls -lA"
alias _rm="command rm"
alias rm='echo "Not trash?"; echo; echo "Run _rm to remove permanently"; false'
alias glog="git log --graph --oneline"
alias ff="fastfetch -s title:separator:terminal:shell:memory:swap:uptime:colors -l fedora_small"
alias fastfetch="fastfetch -s title:separator:os:host:kernel:terminal:shell:display:cpu:gpu:memory:swap:theme:localip:uptime:colors"

alias phi="ollama run phi3"
alias gemma="ollama run codegemma:2b-code"
# alias oloff="docker stop docker_ollama_1"
# alias olon="docker start docker_ollama_1"
# alias chatoff="docker stop docker_web_1 docker_db_1 docker_redis_1 docker_weaviate_1 docker_sandbox_1 docker_api_1 docker_worker_1 docker_nginx_1"
# alias chaton="docker start docker_web_1 docker_db_1 docker_redis_1 docker_weaviate_1 docker_sandbox_1 docker_api_1 docker_worker_1 docker_nginx_1"
# alias llmoff="bash -c 'cd /games/dify/docker && docker compose down'"
# alias llmon="bash -c 'cd /games/dify/docker && docker compose up -d'"
# alias oloff="docker stop librechat_ollama_1"
# alias olon="docker start librechat_ollama_1"
# alias chatoff="docker stop chat-meilisearch chat-mongodb vectordb rag_api LibreChat"
# alias chaton="docker start chat-meilisearch chat-mongodb vectordb rag_api LibreChat"
# alias llmoff="bash -c 'cd /games/LibreChat && docker compose down'"
# alias llmon="bash -c 'cd /games/LibreChat && docker compose up -d'"
alias olon="podman start ollama"
alias oloff="podman stop ollama"
alias chaton="podman start open-webui"
alias chatoff="podman stop open-webui"
alias llmoff="bash -c 'cd /games/open-webui && docker compose down'"
alias llmon="bash -c 'cd /games/open-webui && docker compose -f docker-compose.yaml -f docker-compose.api.yaml -f docker-compose.gpu.yaml up -d'"
alias chatre="chatoff && chaton"
alias olre="oloff && olon"
alias llmre="llmoff && llmon"
alias nvpod="sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml --device-name-strategy=uuid"

alias da='deactivate'

alias clang++="clang++ -Wall -pedantic -Werror=vla"
alias cppbuild="docker build -f project.Dockerfile . -t"
alias cppcompile="docker run --rm -ti -v .:/app/project:z"
alias cppproj="cp $HOME/Templates/cpp_template/* . -r"
function cpprun
    set container $argv[1]
    set -e argv[1]
    set args $argv
    docker run --rm -ti -v (pwd):/app/project:z $container --r="$args"
end

function cpplsp
    sed -i "s/\/app\/project/$(echo {$PWD} | sed 's/\//\\\\\//g')/g" cmake-build-debug/compile_commands.json
    and cp cmake-build-debug/compile_commands.json .
end

alias pls='sudo "/bin/bash" -c "$(fc -ln -1)"'
function d
    nohup bash -c "$argv" &>/dev/null & disown
end
function D
    nohup bash -c $argv[1] &>/dev/null & disown
end
function o
    nohup bash -c "dolphin $argv" &>/dev/null & disown
end

alias novideo="__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia"
alias battery="sudo cpupower frequency-set --max 1.2GHz -- min 800MHz"
alias plug="sudo cpupower frequency-set --max 4.2GHz -- min 800MHz"
alias nvidia="sudo python ~/.dotfiles/envycontrol/envycontrol.py -s hybrid"
alias intel="sudo python ~/.dotfiles/envycontrol/envycontrol.py -s integrated"

alias kssh="kitty +kitten ssh"
function servre
    if test -z "$argv"
        echo "Usage: connect_ssh <ip_address>"
        return 1
    end

    set ip_address $argv[1]

    ssh -i ~/.ssh/Servers/id_rsa rad1an-server@$ip_address -t 'wg-quick down wirehole && wg-quick up wirehole'
end
alias wgre="ssh -i ~/.ssh/Servers/aws/wirehole_aws.pem ubuntu@51.20.116.39 -t 'cd /home/ubuntu/wirehole && sudo docker-compose down && sudo docker-compose up -d'"

alias gu="~/.dotfiles/scripts/backup_conspectus.sh; ~/.dotfiles/scripts/backup_dotfiles.sh"
alias cs="~/.dotfiles/scripts/backup_conspectus.sh"
alias ґіт="git"

alias v="nvim -u ~/.config/nvim/init_code.lua"
alias vb="nvim -u ~/.config/nvim/init_bigfile.lua"
alias lvim="nvim -u ~/.config/nvim/lua/init_latex.lua"
alias dvim="konsole -e nvim -u ~/.config/nvim/init_code.lua"
alias convim="nvim -u ~/.config/nvim/init_code.lua ~/.config/nvim/init_code.lua +'cd $HOME/.config/nvim'"

alias light="tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Sparse --icons='Few icons' --transient=No"
alias dark="tide configure --auto --style=Classic --prompt_colors='16 colors' --show_time='24-hour format' --classic_prompt_separators=Slanted --powerline_prompt_heads=Slanted --powerline_prompt_tails=Slanted --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_spacing=Sparse --icons='Few icons' --transient=No"
