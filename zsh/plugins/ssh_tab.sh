# Use native argument completion; only the host source is customized.
autoload -Uz _ssh
compdef _ssh ssh

_ssh_hosts() {
    local config=${(Q)${opt_args[-F]:-$HOME/.ssh/config}}
    local -Ua hosts
    hosts=( ${(f)"$(awk '
        function emit( i, host) {
            if (user == "git") return
            for (i = 1; i <= count; i++) {
                host = aliases[i]
                if (host == "" || host ~ /[!*?]/) continue
                gsub(/:/, "\\:", host)
                print host ":" note
            }
        }
        tolower($1) == "host" {
            emit()
            note = $0
            if (!sub(/^[^#]*#[[:space:]]*/, "", note)) note = ""
            sub(/[[:space:]]+$/, "", note)
            sub(/[[:space:]]*#.*/, "")
            count = NF - 1
            for (i = 1; i <= count; i++) aliases[i] = $(i + 1)
            user = ""
        }
        tolower($1) == "user" && user == "" {
            user = $2
            gsub(/^"|"$/, "", user)
        }
        tolower($1) == "match" { emit(); count = 0 }
        END { emit() }
    ' "$config" 2>/dev/null)"} )
    _describe -t hosts 'SSH host' hosts "$@"
}

zstyle ':completion:*:ssh:argument-1:*' tag-order hosts -
