# jj rewrites the colocated Git index without file stat information. Refresh
# that information before p10k reads it, or clean files can appear modified.
# A precmd hook also covers aliases, `command jj`, scripts and `jj op restore`.
function _jj_p10k_refresh() {
  emulate -L zsh
  (( ${+commands[git]} )) || return 0

  local dir=${PWD:A}
  while true; do
    # Stop at the nearest repository boundary, including nested Git repos and
    # non-colocated jj workspaces. Only refresh a colocated repository.
    if [[ -e $dir/.git || -d $dir/.jj ]]; then
      if [[ -e $dir/.git && -d $dir/.jj ]]; then
        # Refresh cached stats only; do not stage changes or scan untracked files.
        command git -C "$dir" update-index -q --refresh &>/dev/null
      fi
      return 0
    fi
    [[ $dir == / ]] && return 0
    dir=${dir:h}
  done
}

# Run before p10k's precmd hook, including when this file is sourced again.
# Let p10k own its asynchronous gitstatus requests.
typeset -ga precmd_functions=(
  _jj_p10k_refresh ${precmd_functions:#_jj_p10k_refresh}
)
