# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

autoload -U compinit; compinit
## ENV ##

addToPathFront() {
  if [[ ! "$PATH" == *"$1"* ]]; then
    export PATH="$1:$PATH"
  fi
}

export ZSH="$HOME/.config/zsh"

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


