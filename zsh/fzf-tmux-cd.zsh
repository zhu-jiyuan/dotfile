# M-t: 在当前 pane 弹 fzf 列出所有 tmux pane 的 cwd（去重），选中后让当前 shell cd 过去。
# 用 ZLE widget 直接消费按键，不会在 prompt 上显示任何命令行。

_fzf_tmux_cd_widget() {
    if [[ -z "$TMUX" ]]; then
        zle redisplay
        return
    fi
    local sel
    sel=$(
        tmux list-panes -a -F '#{pane_current_path}' \
            | awk 'NF && !seen[$0]++' \
            | fzf --prompt='cd » ' --layout=reverse --border=rounded --no-multi
    )
    if [[ -n "$sel" ]]; then
        builtin cd -- "$sel"
        # p10k 等主题把路径段缓存放在 precmd 里，zle reset-prompt 不会重跑 precmd，
        # 必须手动触发一次，否则 prompt 上的 cwd 要等下次回车才刷新。
        local fn
        for fn in "${precmd_functions[@]}"; do
            "$fn"
        done
    fi
    zle reset-prompt
}

zle -N _fzf_tmux_cd_widget
bindkey '\et' _fzf_tmux_cd_widget
