#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
package_file="$repo_dir/packages/debian.list"
manual_file="$repo_dir/packages/manual.list"

dry_run=0
update_cache=1
assume_yes=1
strict_manual=0

usage() {
    cat <<'EOF'
Usage: ./install_dependencies.sh [OPTIONS]

Install dotfile dependencies without reinstalling packages that are already
satisfied.

Options:
  --dry-run       Print what would be installed, but do not install anything.
  --no-update     Skip apt-get update.
  --ask           Let apt ask before installing instead of passing -y.
  --strict        Exit non-zero if commands in packages/manual.list are missing.
  -h, --help      Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            dry_run=1
            ;;
        --no-update)
            update_cache=0
            ;;
        --ask)
            assume_yes=0
            ;;
        --strict)
            strict_manual=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

log() {
    printf '[deps] %s\n' "$*"
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

require_cmd() {
    if ! have_cmd "$1"; then
        printf 'Required command not found: %s\n' "$1" >&2
        exit 1
    fi
}

require_cmd apt-get
require_cmd apt-cache
require_cmd dpkg-query
require_cmd sudo

if [[ ! -f "$package_file" ]]; then
    printf 'Package list not found: %s\n' "$package_file" >&2
    exit 1
fi

deb_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'
}

apt_available() {
    apt-cache show "$1" >/dev/null 2>&1
}

any_command_available() {
    local cmd
    for cmd in "$@"; do
        [[ -n "$cmd" ]] || continue
        if have_cmd "$cmd"; then
            return 0
        fi
    done
    return 1
}

declare -A seen_packages=()
declare -a to_install=()
declare -a satisfied=()
declare -a unavailable=()

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line="${raw_line%%#*}"
    # Trim leading/trailing whitespace.
    line="${line#"${line%%[!$' \t\r\n']*}"}"
    line="${line%"${line##*[!$' \t\r\n']}"}"
    [[ -n "$line" ]] || continue

    read -r -a fields <<<"$line"
    pkg="${fields[0]}"
    [[ -n "$pkg" ]] || continue

    if [[ -n "${seen_packages[$pkg]:-}" ]]; then
        continue
    fi
    seen_packages["$pkg"]=1

    commands=("${fields[@]:1}")
    if deb_installed "$pkg"; then
        satisfied+=("$pkg")
    elif [[ "${#commands[@]}" -gt 0 ]] && any_command_available "${commands[@]}"; then
        satisfied+=("$pkg (command already available)")
    elif apt_available "$pkg"; then
        to_install+=("$pkg")
    else
        unavailable+=("$pkg")
    fi
done <"$package_file"

log "package list: $package_file"
log "already satisfied: ${#satisfied[@]}"
log "missing apt packages: ${#to_install[@]}"

if [[ "${#unavailable[@]}" -gt 0 ]]; then
    log "not available in apt:"
    printf '  %s\n' "${unavailable[@]}"
fi

if [[ "${#to_install[@]}" -gt 0 ]]; then
    printf '%s\n' "${to_install[@]}" | sort -u
fi

if [[ "$dry_run" -eq 1 ]]; then
    log "dry-run mode, not installing."
else
    if [[ "${#to_install[@]}" -gt 0 ]]; then
        if [[ "$update_cache" -eq 1 ]]; then
            sudo apt-get update
        fi

        install_args=(apt-get install)
        if [[ "$assume_yes" -eq 1 ]]; then
            install_args+=(-y)
        fi
        sudo "${install_args[@]}" "${to_install[@]}"
    else
        log "no apt packages need installation."
    fi
fi

manual_missing=()
if [[ -f "$manual_file" ]]; then
    while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
        line="${raw_line%%#*}"
        line="${line#"${line%%[!$' \t\r\n']*}"}"
        line="${line%"${line##*[!$' \t\r\n']}"}"
        [[ -n "$line" ]] || continue

        read -r command_name _ <<<"$line"
        [[ -n "$command_name" ]] || continue

        if ! have_cmd "$command_name"; then
            manual_missing+=("$line")
        fi
    done <"$manual_file"
fi

if [[ "${#manual_missing[@]}" -gt 0 ]]; then
    log "manual dependencies still missing:"
    printf '  %s\n' "${manual_missing[@]}"
    if [[ "$strict_manual" -eq 1 ]]; then
        exit 3
    fi
fi

log "done."
