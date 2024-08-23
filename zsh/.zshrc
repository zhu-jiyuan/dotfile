# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

export DWM="$HOME/.dwm"
autoload -U compinit; compinit
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

export HISTFILE=~/.zsh_history
setopt INC_APPEND_HISTORY
# add timestamp to History
# export HISTTIMEFORMAT="[%F %T] "
# setopt EXTENDED_HISTORY

export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
export SAVEHIST=655350
export GLFW_IM_MODULE=ibus

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

# set tab color
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)(?)*==02=01}:${(s.:.)LS_COLORS}")'

############## load theme ################
source $ZSH/themes/powerlevel10k/powerlevel10k.zsh-theme
# config man theme
# Depend on bat
export MANPAGER='sh -c "col -bx | bat -pl man --theme=Monokai\ Extended"'
export MANROFFOPT='-c'

[[ ! -f $ZSH/.p10k.zsh ]] || source $ZSH/.p10k.zsh

############## plugins #################
source $ZSH/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fpath=($ZSH/plugins/zsh-completions/src $fpath)
# eval "$(zoxide init zsh)"
eval "$(lua $ZSH/plugins/zlua/z.lua --init zsh enhanced once echo fzf)"
source $ZSH/plugins/sudo/sudo.zsh


