#!/usr/bin/env bash
# The host each pane's ssh is logged in to, for the status bar and window
# names. tmux knows the command in front of a pane is ssh but not its
# arguments, so this reads them off the leader of the terminal's foreground
# process group, as tm does, and keeps the destination in the pane option
# @ssh_host, with the leader's pid in @ssh_pid so each ssh is read once.
# Panes no longer running ssh lose both. Prints nothing.
#
# The window-renamed hook runs it as ssh starts (automatic rename names the
# window "ssh" first), and status-right every status-interval for the rest:
# a window renamed by hand, ssh in a pane that is not the active one.
# Usage: tmux-ssh-host.sh

set -u
set -f

# The destination among ssh's arguments, without the user or a URI's port.
destination() {
    local word flags lead host=""
    while [ $# -gt 0 ]; do
        word=$1
        shift
        case $word in
            --)
                host=${1-}
                break
                ;;
            -?*)
                # Flags cluster (-tt, -vp22). The first that takes a value
                # takes the rest of the word, or the next word when it ends it.
                flags=${word#-}
                lead=${flags%%[BbcDEeFIiJLlmOoPpQRSWw]*}
                if [ $((${#lead} + 1)) -eq ${#flags} ] && [ $# -gt 0 ]; then
                    shift
                fi
                ;;
            *)
                host=$word
                break
                ;;
        esac
    done
    case $host in
        ssh://*)
            host=${host#ssh://}
            host=${host##*@}
            # ssh://host:2222, ssh://[::1]:22
            case ${host##*:} in
                "$host" | "" | *[!0-9]*) ;;
                *) host=${host%:*} ;;
            esac
            ;;
        *) host=${host##*@} ;;
    esac
    printf '%s' "$host"
}

commands=()
tab=$(printf '\t')
while IFS=$tab read -r pane command tty seen; do
    if [ "$command" != ssh ]; then
        [ -n "$seen" ] && commands+=(set -pu -t "$pane" @ssh_host \; set -pu -t "$pane" @ssh_pid \;)
        continue
    fi
    # pid == tpgid: the foreground group's leader, the process tmux names.
    line=$(ps -t "${tty#/dev/}" -o pid=,tpgid=,command= | awk '$1 == $2 { $2 = ""; print; exit }')
    leader=${line%% *}
    if [ -z "$leader" ] || [ "$leader" = "$seen" ]; then
        continue
    fi
    # Linux keeps the arguments apart. ps joins them with spaces, so on macOS
    # an option value with spaces in it (-o "ProxyCommand nc %h %p") reads as
    # several words; tm asks the system for them one by one instead.
    args=()
    if [ -r "/proc/$leader/cmdline" ]; then
        while IFS= read -r -d '' word; do args+=("$word"); done <"/proc/$leader/cmdline"
    else
        args=(${line#* })
    fi
    host=$(destination "${args[@]:1}")
    if [ -n "$host" ]; then
        commands+=(set -p -t "$pane" @ssh_host "$host" \;)
    else
        commands+=(set -pu -t "$pane" @ssh_host \;)
    fi
    commands+=(set -p -t "$pane" @ssh_pid "$leader" \;)
done < <(tmux list-panes -a -F "#{pane_id}$tab#{pane_current_command}$tab#{pane_tty}$tab#{@ssh_pid}")

[ ${#commands[@]} -eq 0 ] && exit 0
# A pane option alone does not make tmux rename a window until the pane
# prints something; setting automatic-rename, even to what it was, does.
commands+=(set -g automatic-rename "$(tmux show -gv automatic-rename)")
# A pane closed since the listing fails its commands; the hook would show
# that in a pane, and the next run catches up anyway.
tmux "${commands[@]}" >/dev/null 2>&1
exit 0
