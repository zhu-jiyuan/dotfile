function sshfzf() {
    selected_host=$(grep "^Host " ~/.ssh/config | awk '{print $2}' | fzf --height 20%)

    if [ -n "$selected_host" ]; then
        echo "$selected_host"
    fi
}

# 定义 zsh 补全函数
function _ssh_fzf_complete() {
    compadd $(sshfzf)
}

# 将 _ssh_fzf_complete 函数绑定到 ssh 命令
compdef _ssh_fzf_complete ssh

