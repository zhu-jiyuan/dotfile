# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet


# dwm
export DWM="$HOME/.dwm"

#autoload -U compinit; compinit

## ENV ##
addToEnvFront() {
    local var_name="$1" local new_value="$2"
    # Get the current value of the variable
    # echo "$var_name"
    # local current_value="${!var_name}"
    eval "current_value=\$$var_name"

  # Check if the new value is already part of the variable
  if [[ ! "$current_value" == *"$new_value"* ]]; then
      export "$var_name"="$new_value:$current_value"
  fi
}

addToPathFront() {
  addToEnvFront "PATH" $1
}

export ZSH="$HOME/.config/zsh"
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export INPUT_METHOD=fcitx
export GLFW_IM_MODULE=ibus
GLFW_IM_MODULE=ibus

export HISTFILE=~/.zsh_history
setopt INC_APPEND_HISTORY
# add timestamp to History
# export HISTTIMEFORMAT="[%F %T] "
# setopt EXTENDED_HISTORY

export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
export SAVEHIST=655350

source $ZSH/.zsh_profile
[[ ! -f $HOME/.zsh_custom ]] || source $HOME/.zsh_custom

############# options#############
unsetopt flowcontrol

# close zsh parse *
setopt no_nomatch

# History won't save duplicates.
setopt HIST_IGNORE_ALL_DUPS

# History won't show duplicates on search.
setopt HIST_FIND_NO_DUPS

DISABLE_UNTRACKED_FILES_DIRTY="true"


############## load theme ################
# config man theme
# Depend on bat
export MANPAGER='sh -c "col -bx | bat -pl man --theme=OneHalfLight"'
export MANROFFOPT='-c'

############## zinit ################
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"
export ZINIT_ALIAS="zii"

############## plugins #################
#compinit before
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-completions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-history-substring-search

# docker
FPATH="$HOME/.docker/completions:$FPATH"
# zinit light mwilliammyers/zsh-docker-completion

# ===================== completions =====================
# 自定义 completions 目录
COMPDIR="$HOME/.zsh/completions"
mkdir -p "$COMPDIR"

# 如果 podman 补全不存在就生成
if command -v podman >/dev/null 2>&1; then
  if [[ ! -f "$COMPDIR/_podman" ]]; then
    podman completion zsh > "$COMPDIR/_podman"
  fi
fi

# 如果 docker 补全不存在就生成
if command -v docker >/dev/null 2>&1; then
  if [[ ! -f "$COMPDIR/_docker" ]]; then
    docker completion zsh > "$COMPDIR/_docker"
  fi
fi

if command -v uv >/dev/null 2>&1; then
  if [[ ! -f "$COMPDIR/_uv" ]]; then
	uv generate-shell-completion zsh > "$COMPDIR/_uv"
  fi
fi

# 加入到 fpath
fpath=("$COMPDIR" $fpath)

autoload -U compinit && compinit

zinit ice depth"1" # git clone depth
zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-autosuggestions

zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)(?)*==02=01}:${(s.:.)LS_COLORS}")'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:git-checkout:*' sort true
zstyle ':fzf-tab:*' use-fzf-default-opts yes

if command -v kubectl > /dev/null 2>&1; then
	source <(kubectl completion zsh)
fi

# zoxide - smarter cd
# https://github.com/ajeetdsouza/zoxide
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
alias zi='__zoxide_zi'
source $ZSH/plugins/sudo.zsh
source $ZSH/plugins/ssh_tab.sh
source $ZSH/fzf-theme.zsh

[[ ! -f $ZSH/.p10k.zsh ]] || source $ZSH/.p10k.zsh


# fnm
FNM_PATH="/home/ohayo/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/ohayo/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

