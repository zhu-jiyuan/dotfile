# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

autoload -U compinit; compinit
## ENV ##

export ZSH="$HOME/.config/zsh"
export HISTFILE="$ZSH/.zsh_history"
export HISTSIZE=65535
export SAVEHIST=65535
export PATH=$PATH:/usr/local/go/bin

############# options#############
unsetopt flowcontrol

# close zsh parse *
setopt no_nomatch

# History won't save duplicates.
setopt HIST_IGNORE_ALL_DUPS

# History won't show duplicates on search.
setopt HIST_FIND_NO_DUPS

DISABLE_UNTRACKED_FILES_DIRTY="true"

# set tab color
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)(?)*==02=01}:${(s.:.)LS_COLORS}")'

############## load theme ################
source $ZSH/themes/powerlevel10k/powerlevel10k.zsh-theme
# config man theme
# Depend on bat
export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

############## plugins #################
source $ZSH/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fpath=($ZSH/plugins/zsh-completions/src $fpath)
eval "$(lua $ZSH/plugins/z.lua/z.lua --init zsh)"
source $ZSH/plugins/sudo/sudo.zsh

############### alias #################
alias ll='ls -lh --color'
alias ls='ls --color'
alias vim='nvim'
alias cls='clear'

# git
alias glog='git log --oneline --decorate --graph'
alias gco='git checkout'
alias g='git'
alias ga='git add'
alias gst='git status'
alias gcm='git checkout master'
alias gp='git push'
alias gcmsg='git commit -m'
alias gl='git pull'

# batcat
alias bat='batcat'
############### export ###############
# export LANG=en_US.UTF-8

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f $ZSH/.p10k.zsh ]] || source $ZSH/.p10k.zsh

proxy_host_ip=127.0.0.1
proxy_port=6666
on_proxy () {
  export http_proxy="http://username:passwd@$proxy_host_ip:$proxy_port"
  export https_proxy="https://username:passwd@$proxy_host_ip:$proxy_port"
  echo "HTTP Proxy on"
}

# where noproxy
off_proxy () {
  unset http_proxy
  unset https_proxy
  echo "HTTP Proxy off"
}

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
