#!/bin/sh
# Runs inside tabfind.lua's floating pane: find tabs with fzf, go to one, or
# rename, close, create and pin them. fzf calls this script back for its keys.
#
# Usage: tabfind.sh [CLIENT] [TAB_ROWS]
# Internal: tabfind.sh list | preview SESSION BLOCK | screen SESSION BLOCK |
#           key NAME [ARG...]
set -u

self=$0
dir=$(dirname "$self")
pins="${XDG_STATE_HOME:-$HOME/.local/state}/rex/tabfind-pins"

# The keys that only mean something while searching. Rename, new and close use
# the input line for their own text, so these are switched off meanwhile.
SEARCH_KEYS='tab,shift-tab,ctrl-r,ctrl-x,ctrl-o,ctrl-s,ctrl-t,ctrl-v,ctrl-j,ctrl-k,ctrl-n,ctrl-p,ctrl-f,ctrl-b,up,down,ctrl-/'
# At least this many rows stay for the search line and list.
MIN_LIST_ROWS=5
SHORT_HINTS=' enter go · tab mark · ctrl+r rename · ctrl+x close · ctrl+o new · ctrl+/ all keys · esc back '
MORE_KEYS='shift+tab unmark · ctrl+s pin · ctrl+j/k move · ctrl+f/b page · ctrl+v toggle screen · ctrl+t whole screen'

# Rex spaces out captured screens with cursor moves, which fzf's preview drops,
# so turn them back into spaces to keep columns lined up.
show_preview() {
	rex capture -s "$1" -b "$2" --format=vt 2>&1 |
		tail -n 200 |
		perl -pe 's/\e\[(\d*)C/q( ) x ($1 || 1)/ge'
}

# The raw capture replayed at full size, so it matches the tab exactly. Stays
# until any key is pressed.
show_screen() {
	rows=$(stty size </dev/tty | cut -d' ' -f1)
	printf '\033[?25l\033[2J\033[H'
	rex capture -s "$1" -b "$2" --format=vt 2>&1 |
		tail -n "$rows" |
		perl -0pe 's/\r?\n\z//'
	saved=$(stty -g </dev/tty)
	stty -icanon -echo min 1 time 0 </dev/tty
	dd bs=1 count=1 </dev/tty >/dev/null 2>&1
	stty "$saved" </dev/tty
	printf '\033[?25h'
}

# Each of these prints fzf actions for it to run.

enter_mode() { # MODE PROMPT
	printf '%s' "$1" >"$TABFIND_STATE/mode"
	printf '%s' "${FZF_QUERY:-}" >"$TABFIND_STATE/query"
	printf 'unbind(%s)+change-ghost()+change-prompt(%s)+transform-query(cat "$TABFIND_STATE/draft")+reload-sync(cat "$TABFIND_STATE/targets")' \
		"$SEARCH_KEYS" "$2"
}

leave_mode() {
	printf 'search' >"$TABFIND_STATE/mode"
	printf 'unbind(change)+rebind(%s)+enable-search+change-ghost(type to search tabs)+change-prompt(find )+transform-query(cat "$TABFIND_STATE/query")+reload-sync(sh "$TABFIND_SELF" list)' \
		"$SEARCH_KEYS"
}

# Show an error above the list and stay put, keeping what was typed.
show_error() {
	printf '%s' "$1" | tr '\n' ' ' >"$TABFIND_STATE/error"
	printf 'transform-header(cat "$TABFIND_STATE/error")'
}

create_tab() { # NAME
	case $1 in
	'' | -*)
		show_error 'A tab name cannot be empty or start with a dash.'
		return
		;;
	esac
	out=$(rex window new -s "$REX_SESSION" "$1" --focus=false --json 2>&1) || {
		show_error "$out"
		return
	}
	window=$(printf '%s' "$out" | sed -n 's/.*"window_id": *"\([^"]*\)".*/\1/p' | head -n 1)
	printf '%s\t%s\n' "$REX_SESSION" "$window" >"$TABFIND_STATE/choice"
	printf 'abort'
}

close_targets() {
	failed=
	closes_own=
	while IFS="$(printf '\t')" read -r session window _; do
		if [ "$window" = "$TABFIND_OWN_WINDOW" ]; then
			closes_own=$session
		else
			err=$(rex window close -s "$session" "$window" 2>&1) || failed=$err
		fi
	done <"$TABFIND_STATE/targets"

	# Last, because closing this tab also ends this script.
	if [ -z "$failed" ] && [ -n "$closes_own" ]; then
		err=$(rex window close -s "$closes_own" "$TABFIND_OWN_WINDOW" 2>&1) || failed=$err
	fi

	leave_mode
	[ -z "$failed" ] || printf '+%s' "$(show_error "$failed")"
}

handle_key() {
	mode=$(cat "$TABFIND_STATE/mode")
	name=$1
	shift
	case "$mode:$name" in
	*:layout)
		lines=${FZF_LINES:-24}
		room=$((lines - MIN_LIST_ROWS))
		rows=$((lines * 83 / 100))
		# The tab's whole screen plus the hint line, when it fits.
		[ -n "$TABFIND_ROWS" ] && rows=$((TABFIND_ROWS + 1))
		[ "$rows" -gt "$room" ] && rows=$room
		# Refresh because fzf keeps its scroll position when the panel grows, which
		# would leave the top of the screen cut off and blank rows below.
		printf 'change-preview-window(down,%s,follow,border-bottom,noinfo)+refresh-preview' "$rows"
		;;
	search:enter)
		if [ "${FZF_MATCH_COUNT:-0}" -gt 0 ]; then
			printf 'execute-silent(cut -f1,2 {f} >"$TABFIND_STATE/choice")+abort'
		elif [ -n "${FZF_QUERY:-}" ]; then
			create_tab "$FZF_QUERY"
		fi
		;;
	search:esc)
		printf 'abort'
		;;
	search:ctrl-r)
		cp "$1" "$TABFIND_STATE/targets"
		cut -f7 "$1" | tr -d '\n' >"$TABFIND_STATE/draft"
		enter_mode rename 'rename to '
		printf '+disable-search'
		;;
	search:ctrl-x)
		cp "$1" "$TABFIND_STATE/targets"
		count=$(wc -l <"$1" | tr -d ' ')
		# A finished agent is still alive in its tab, so "done" counts too.
		active=$(cut -f6 "$1" | grep -c -E 'waiting|working|done|failed')
		word=tabs
		[ "$count" -eq 1 ] && word=tab
		note=
		[ "$active" -gt 0 ] && note=", $active with a program running"
		: >"$TABFIND_STATE/draft"
		# Search stays on because fzf reports no typing while it is off.
		printf 'rebind(change)+'
		enter_mode close "$(printf '\033[1;97;41m close %s %s%s? y / n \033[0m ' "$count" "$word" "$note")"
		;;
	search:ctrl-o)
		: >"$TABFIND_STATE/targets"
		printf '%s' "${FZF_QUERY:-}" >"$TABFIND_STATE/draft"
		enter_mode new 'new tab '
		printf '+disable-search'
		;;
	search:ctrl-s)
		mkdir -p "$(dirname "$pins")"
		touch "$pins"
		if grep -Fxq "$1" "$pins"; then
			grep -Fxv "$1" "$pins" >"$pins.new"
			mv "$pins.new" "$pins"
		else
			printf '%s\n' "$1" >>"$pins"
		fi
		printf 'reload-sync(sh "$TABFIND_SELF" list)'
		;;
	search:ctrl-/)
		if [ -e "$TABFIND_STATE/more" ]; then
			rm -f "$TABFIND_STATE/more"
			printf 'change-header()'
		else
			printf '%s' "$MORE_KEYS" >"$TABFIND_STATE/more"
			printf 'transform-header(cat "$TABFIND_STATE/more")'
		fi
		;;
	rename:enter)
		session=$(cut -f1 "$TABFIND_STATE/targets")
		window=$(cut -f2 "$TABFIND_STATE/targets")
		if [ -n "${FZF_QUERY:-}" ]; then
			err=$(rex window rename -s "$session" -- "$window" "$FZF_QUERY" 2>&1) || {
				show_error "$err"
				return
			}
		fi
		printf 'change-header()+'
		leave_mode
		;;
	new:enter)
		create_tab "${FZF_QUERY:-}"
		;;
	close:change)
		case ${FZF_QUERY:-} in
		y | Y) close_targets ;;
		n | N) leave_mode ;;
		*) printf 'clear-query' ;;
		esac
		;;
	rename:esc | new:esc | close:esc)
		printf 'change-header()+'
		leave_mode
		;;
	esac
}

case ${1:-} in
list)
	exec rex do "$dir/tabfind-list.lua"
	;;
preview)
	show_preview "$2" "$3"
	exit 0
	;;
screen)
	show_screen "$2" "$3"
	exit 0
	;;
key)
	shift
	handle_key "$@"
	exit 0
	;;
esac

client=${1:-}
TABFIND_ROWS=${2:-}

# Keep the error on screen: the pane closes as soon as this script exits.
fail() {
	printf '\n%s\nPress Enter to close.' "$1"
	read -r _
	exit 1
}

# The search area is a quiet shade of the tab's own ground, like Rex's sidebar. The
# preview keeps the terminal's own colours, which are the tab's.
if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = Dark ]; then
	TABFIND_DARK=1
	colors='bg:#34363a,fg:#d4d6da,bg+:#4a4d52,fg+:#f2f3f5:regular,hl:#7cc0ee:underline,hl+:#9ad2f5:underline,prompt:#7cc0ee:bold,query:#f2f3f5:bold,ghost:#a3a6ac,info:#a3a6ac,pointer:#7cc0ee,marker:#7cc0ee,header:#a3a6ac,preview-border:#5a5d63,preview-label:#a3a6ac,gutter:#34363a'
else
	TABFIND_DARK=
	colors='bg:#eee8d5,fg:#46595f,bg+:#fffdf7,fg+:#073642:regular,hl:#0b5f98:underline,hl+:#0b5f98:underline,prompt:#0b5f98:bold,query:#073642:bold,ghost:#4f6369,info:#4f6369,pointer:#0b5f98,marker:#0b5f98,header:#4f6369,preview-border:#d3cbb7,preview-label:#4f6369,gutter:#eee8d5'
fi

TABFIND_STATE=$(mktemp -d) || fail 'Could not create a temporary directory.'
trap 'rm -rf "$TABFIND_STATE"' EXIT
trap 'exit 1' HUP INT TERM
printf 'search' >"$TABFIND_STATE/mode"

TABFIND_OWN_WINDOW=$(rex block inspect "$REX_BLOCK" --json 2>/dev/null |
	sed -n 's/.*"window_id": *"\([^"]*\)".*/\1/p' | head -n 1)
TABFIND_SELF=$self
export TABFIND_STATE TABFIND_OWN_WINDOW TABFIND_SELF TABFIND_ROWS TABFIND_DARK

tabs=$(sh "$self" list 2>&1) || fail "$tabs"

printf '%s\n' "$tabs" | fzf \
	--ansi --multi --delimiter='\t' --with-nth='{4}  {5}  {6}' \
	--layout=reverse --no-scrollbar --no-separator --info=inline-right --highlight-line \
	--info-command='printf "%s/%s" "$FZF_MATCH_COUNT" "$FZF_TOTAL_COUNT"; [ "$FZF_SELECT_COUNT" -eq 0 ] || printf " · %s marked" "$FZF_SELECT_COUNT"' \
	--prompt='find ' --ghost='type to search tabs' --marker='✓' \
	--track --id-nth=2 \
	--color="$colors,preview-bg:-1,preview-fg:-1" \
	--preview='sh "$TABFIND_SELF" preview {1} {3}' \
	--preview-window='down,83%,follow,border-bottom,noinfo' \
	--preview-label="$SHORT_HINTS" --preview-label-pos='2:bottom' \
	--bind='start:unbind(change)+transform(sh "$TABFIND_SELF" key layout)' \
	--bind='resize:transform(sh "$TABFIND_SELF" key layout)' \
	--bind='change:transform(sh "$TABFIND_SELF" key change)' \
	--bind='enter:transform(sh "$TABFIND_SELF" key enter)' \
	--bind='esc:transform(sh "$TABFIND_SELF" key esc)' \
	--bind='ctrl-r:transform(sh "$TABFIND_SELF" key ctrl-r {f})' \
	--bind='ctrl-x:transform(sh "$TABFIND_SELF" key ctrl-x {+f})' \
	--bind='ctrl-o:transform(sh "$TABFIND_SELF" key ctrl-o)' \
	--bind='ctrl-s:transform(sh "$TABFIND_SELF" key ctrl-s {2})' \
	--bind='ctrl-/:transform(sh "$TABFIND_SELF" key ctrl-/)' \
	--bind='ctrl-t:execute(sh "$TABFIND_SELF" screen {1} {3})' \
	--bind='ctrl-v:toggle-preview' \
	--bind='tab:toggle+down,shift-tab:deselect+up' \
	--bind='ctrl-j:down,ctrl-k:up,ctrl-n:down,ctrl-p:up,ctrl-f:page-down,ctrl-b:page-up'

[ -s "$TABFIND_STATE/choice" ] || exit 0
session=$(cut -f1 "$TABFIND_STATE/choice")
window=$(cut -f2 "$TABFIND_STATE/choice")

# Another session's tab also needs the app to show that session, and the app only
# takes that from the CLI with Remote Control on (Settings > Rex Server).
if [ "$session" = "$REX_SESSION" ]; then
	err=$(rex window focus -s "$session" "$window" 2>&1) || fail "$err"
else
	err=$(rex ${client:+-C "$client"} do session.select session_id="$session" window_id="$window" 2>&1) || fail "$err"
fi
