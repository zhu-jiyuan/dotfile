#!/bin/sh
# Runs inside tabfind.lua's floating pane: find a tab with fzf and go to it, or
# rename, close and pin tabs, or make a tab or a session. fzf calls this script
# back for its keys.
#
# Usage: tabfind.sh [CLIENT] [ORIGIN_BLOCK]
# Internal: tabfind.sh preview SESSION BLOCK | screen SESSION BLOCK |
#           key NAME [ARG...]
#
# The rows come from tabfind-list.lua, whose header lists their fields.
#
# fzf calls are separate processes, so what they share lives in $TABFIND_STATE:
#   mode     search, rename, close, tab or session
#   rows     the last list that loaded; count, how many tabs it has
#   cols     the columns the list has for a row
#   targets  the rows a rename or close acts on
#   query    what the search line held before leaving search
#   input    what the input line held at the last redraw
#   error    the message on show, if any
#   help     exists while the full key bar is on
#   footer   the key bar as drawn
#   lastpos  where the cursor last rested, to step over headings the same way
#   choice   the session and tab to go to once fzf exits
set -u

self=$0
dir=$(dirname "$self")
pins="${XDG_STATE_HOME:-$HOME/.local/state}/rex/tabfind-pins"
TAB=$(printf '\t')
ESC=$(printf '\033')

# The keys that only mean something while searching. The other modes use the
# input line for their own text, so these are off meanwhile.
SEARCH_KEYS='tab,shift-tab,ctrl-r,ctrl-x,ctrl-t,ctrl-s,ctrl-v,ctrl-j,ctrl-k,ctrl-n,ctrl-p,ctrl-f,ctrl-b,up,down,?,alt-p,alt-enter'
PREVIEW_PERCENT=40

# The list's ground follows the system appearance, like Rex's own sidebar. The
# preview keeps the terminal's own colours, which are the tab's.
if [ -z "${TABFIND_DARK+set}" ]; then
	TABFIND_DARK=
	[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = Dark ] && TABFIND_DARK=1
fi
if [ -n "$TABFIND_DARK" ]; then
	STRONG='242;243;245' DIM='163;166;172' KEY_BG='69;72;77' ON_PILL='31;33;36'
	BLUE='124;192;238' RED='255;160;110' GREEN='190;210;90' AMBER='230;195;90'
else
	STRONG='7;54;66' DIM='79;99;105' KEY_BG='226;219;197' ON_PILL='253;246;227'
	BLUE='11;95;152' RED='168;60;12' GREEN='86;99;0' AMBER='111;84;0'
fi

# Rex spaces out captured screens with cursor moves, which fzf's preview drops,
# so turn them back into spaces to keep columns lined up.
show_preview() {
	case $2 in
	-) return ;; # A heading, which the cursor is only passing over.
	none)
		echo 'This tab has no terminal to show.'
		return
		;;
	esac
	rex capture -s "$1" -b "$2" --format=vt 2>&1 |
		tail -n 200 |
		perl -pe 's/\e\[(\d*)C/q( ) x ($1 || 1)/ge'
}

# The raw capture replayed at full size, so it matches the tab exactly. Stays
# until any key is pressed.
show_screen() {
	case $2 in - | none) return ;; esac
	rows=$(stty size </dev/tty | cut -d' ' -f1)
	printf '\033[?25l\033[2J\033[H'
	rex capture -s "$1" -b "$2" --format=vt 2>&1 |
		tail -n "$rows" |
		perl -0pe 's/\r?\n\z//'
	saved=$(stty -g </dev/tty)
	stty -icanon -echo min 1 time 0 </dev/tty
	# One read takes the whole key: an arrow is several bytes, and any left
	# behind would land in fzf's query.
	dd bs=64 count=1 </dev/tty >/dev/null 2>&1
	stty "$saved" </dev/tty
	printf '\033[?25h'
}

window_id_from_json() {
	sed -n 's/.*"window_id": *"\([^"]*\)".*/\1/p' | head -n 1
}

# The directory of the pane the panel was opened from: field 9 as shown, 11 in
# full. New tabs and sessions start there.
origin_dir() { # FIELD
	awk -F'\t' -v block="${TABFIND_ORIGIN_BLOCK:-}" -v field="$1" \
		'block != "" && $6 == block { print $field; exit }' "$TABFIND_STATE/rows"
}

# Load the tabs, sized to the list. A failure keeps the last list on screen and
# reports the error.
fetch_rows() {
	cols=${FZF_COLUMNS:-$(stty size </dev/tty | cut -d' ' -f2)}
	# The preview takes its share. Of the rest, the list's border, padding and
	# cursor columns take 6, and one more keeps fzf from cutting a full row.
	list_cols=$((cols - cols * PREVIEW_PERCENT / 100 - 7))
	printf '%s' "$list_cols" >"$TABFIND_STATE/cols"
	if TABFIND_LIST_COLS=$list_cols rex do "$dir/tabfind-list.lua" \
		>"$TABFIND_STATE/rows.new" 2>"$TABFIND_STATE/rows.err"; then
		mv "$TABFIND_STATE/rows.new" "$TABFIND_STATE/rows"
		grep -c '^t' "$TABFIND_STATE/rows" >"$TABFIND_STATE/count"
	else
		tr '\n' ' ' <"$TABFIND_STATE/rows.err" >"$TABFIND_STATE/error"
		return 1
	fi
}

pill() { # COLOR TEXT
	printf '%s[1;38;2;%s;48;2;%sm %s %s[0m ' "$ESC" "$ON_PILL" "$1" "$2" "$ESC"
}

key_item() { # KEY LABEL
	printf '%s[1;38;2;%s;48;2;%sm %s %s[0;38;2;%sm %s%s[0m' \
		"$ESC" "$STRONG" "$KEY_BG" "$1" "$ESC" "$DIM" "$2" "$ESC"
}

# The key bar for the mode, wrapped to the list's width. Each item comes with
# the columns it takes, which sh can't count for these characters.
write_footer() {
	case $(cat "$TABFIND_STATE/mode") in
	search)
		items='6|⏎|go
8|⇥|mark
11|^R|rename
10|^X|close
12|^T|new tab
16|^S|new session'
		if [ -e "$TABFIND_STATE/help" ]; then
			items="$items
11|⇧⇥|unmark
8|⌥P|pin
17|⌥⏎|whole screen
12|^V|preview
12|^J ^K|move
12|^F ^B|page
8|?|less"
		else
			items="$items
8|?|more"
		fi
		;;
	rename) items='8|⏎|save
12|esc|cancel' ;;
	close) items='9|y|close
8|n|keep' ;;
	tab | session)
		place=$(origin_dir 9)
		place=${place:-'~'}
		items="$((14 + ${#place}))|⏎|create in $place
12|esc|cancel"
		;;
	esac

	width=$(cat "$TABFIND_STATE/cols")
	out= line= used=0
	while IFS='|' read -r w key label; do
		if [ "$used" -gt 0 ] && [ $((used + 3 + w)) -gt "$width" ]; then
			out="$out$line
"
			line= used=0
		fi
		if [ "$used" -gt 0 ]; then
			line="$line   "
			used=$((used + 3))
		fi
		line="$line$(key_item "$key" "$label")"
		used=$((used + w))
	done <<EOF
$items
EOF
	printf '%s%s' "$out" "$line" >"$TABFIND_STATE/footer"
}

# Each function from here on prints fzf actions for it to run.

draw_footer() {
	write_footer
	printf 'transform-footer(cat "$TABFIND_STATE/footer")'
}

# The line above the list holds an error, if there is one. fzf only reports
# typing while change is bound, so an error binds it for the keystroke that
# dismisses it.
draw_header() {
	if [ -s "$TABFIND_STATE/error" ]; then
		printf 'rebind(change)+transform-header(cat "$TABFIND_STATE/error")'
	else
		printf 'change-header()'
	fi
}

# Always last: fzf drops what comes after a reload that has to keep the cursor
# on its row.
reload_rows() { # ROWS_FILE
	printf '+reload-sync(cat "$TABFIND_STATE/%s")' "$1"
}

# Every mode change comes through here and sets all that a mode controls, so
# nothing carries over from the last one.
draw_mode() { # MODE PROMPT GHOST ROWS_FILE
	printf '%s' "$1" >"$TABFIND_STATE/mode"
	case $1 in
	search) keys=rebind search=enable-search change=unbind ;;
	# Search stays on because fzf reports no typing while it is off.
	close) keys=unbind search=enable-search change=rebind ;;
	*) keys=unbind search=disable-search change=unbind ;;
	esac
	printf '%s(%s)+%s(change)+%s+change-ghost(%s)+change-prompt(%s)+transform-query(cat "$TABFIND_STATE/input")+' \
		"$keys" "$SEARCH_KEYS" "$change" "$search" "$3" "$2"
	draw_footer
	printf '+'
	draw_header
	reload_rows "$4"
}

open_mode() { # MODE PROMPT GHOST ROWS_FILE INPUT
	printf '%s' "${FZF_QUERY:-}" >"$TABFIND_STATE/query"
	printf '%s' "$5" >"$TABFIND_STATE/input"
	draw_mode "$1" "$2" "$3" "$4"
}

back_to_search() {
	fetch_rows
	cp "$TABFIND_STATE/query" "$TABFIND_STATE/input"
	draw_mode search '❯ ' 'Search tabs' rows
}

# Show an error above the list and stay put, keeping what was typed.
show_error() {
	printf '%s' "$1" | tr '\n' ' ' >"$TABFIND_STATE/error"
	printf '%s' "${FZF_QUERY:-}" >"$TABFIND_STATE/input"
	draw_header
}

check_name() { # NAME WHAT
	case $1 in
	'' | -*)
		show_error "A $2 name cannot be empty or start with a dash."
		return 1
		;;
	esac
}

create_tab() { # NAME
	check_name "$1" tab || return
	cwd=$(origin_dir 11)
	out=$(rex window new -s "$REX_SESSION" "$1" --focus=false --json ${cwd:+--cwd "$cwd"} 2>&1) || {
		show_error "$out"
		return
	}
	window=$(printf '%s' "$out" | window_id_from_json)
	printf '%s\t%s\n' "$REX_SESSION" "$window" >"$TABFIND_STATE/choice"
	printf 'abort'
}

create_session() { # NAME
	check_name "$1" session || return
	cwd=$(origin_dir 11)
	out=$(rex new "$1" --json ${cwd:+--cwd "$cwd"} 2>&1) || {
		show_error "$out"
		return
	}
	session=$(printf '%s' "$out" | sed -n 's/.*"session_id": *"\([^"]*\)".*/\1/p' | head -n 1)
	window=$(printf '%s' "$out" | window_id_from_json)
	printf '%s\t%s\n' "$session" "$window" >"$TABFIND_STATE/choice"
	printf 'abort'
}

close_targets() {
	failed=
	closes_own=
	cut -f4,5 "$TABFIND_STATE/targets" >"$TABFIND_STATE/closing"
	while IFS="$TAB" read -r session window; do
		if [ "$window" = "$TABFIND_OWN_WINDOW" ]; then
			closes_own=$session
		else
			err=$(rex window close -s "$session" "$window" 2>&1) || failed="$failed$err "
		fi
	done <"$TABFIND_STATE/closing"

	# Last, because closing this tab also ends this script.
	if [ -z "$failed" ] && [ -n "$closes_own" ]; then
		err=$(rex window close -s "$closes_own" "$TABFIND_OWN_WINDOW" 2>&1) || failed=$err
	fi

	[ -z "$failed" ] || printf '%s' "$failed" | tr '\n' ' ' >"$TABFIND_STATE/error"
	back_to_search
}

toggle_pin() { # WINDOW
	mkdir -p "$(dirname "$pins")"
	touch "$pins"
	if grep -Fxq "$1" "$pins"; then
		grep -Fxv "$1" "$pins" >"$pins.new"
		mv "$pins.new" "$pins"
	else
		printf '%s\n' "$1" >>"$pins"
	fi
}

# Headings are rows too, so step over one in the direction the cursor moved.
step_over_heading() { # KIND
	pos=${FZF_POS:-1}
	if [ "$1" != h ]; then
		printf '%s' "$pos" >"$TABFIND_STATE/lastpos"
		return
	fi
	last=$(cat "$TABFIND_STATE/lastpos" 2>/dev/null)
	if [ "$pos" -le 1 ] || [ "$pos" -gt "${last:-0}" ]; then
		printf 'down'
	else
		printf 'up'
	fi
}

handle_key() {
	mode=$(cat "$TABFIND_STATE/mode")
	name=$1
	shift

	# Any key dismisses an old error. Whatever it does may report a new one.
	case $name in
	change | focus | resize) ;;
	*) rm -f "$TABFIND_STATE/error" ;;
	esac

	case "$mode:$name" in
	*:focus)
		step_over_heading "${1:-}"
		;;
	search:resize)
		fetch_rows
		draw_footer
		printf '+'
		draw_header
		reload_rows rows
		;;
	search:enter)
		if [ "${1:-}" = t ]; then
			printf 'execute-silent(cut -f4,5 {f} >"$TABFIND_STATE/choice")+abort'
		elif [ "${FZF_MATCH_COUNT:-0}" -eq 0 ] && [ -n "${FZF_QUERY:-}" ]; then
			create_tab "$FZF_QUERY"
		fi
		;;
	search:esc)
		printf 'abort'
		;;
	search:ctrl-r)
		# With no row under the cursor, fzf hands over a blank one.
		[ "${1:-}" = t ] || return
		cp "$2" "$TABFIND_STATE/targets"
		open_mode rename "$(pill "$BLUE" Rename)" '' targets "$(cut -f7 "$2" | tr -d '\n')"
		;;
	search:ctrl-x)
		grep '^t' "$1" >"$TABFIND_STATE/targets" || return
		count=$(wc -l <"$TABFIND_STATE/targets" | tr -d ' ')
		# A finished agent is still alive in its tab, so "done" counts too.
		active=$(cut -f10 "$TABFIND_STATE/targets" | grep -c .)
		word=tabs
		[ "$count" -eq 1 ] && word=tab
		note=
		[ "$active" -gt 0 ] && note=", $active with a program running"
		open_mode close "$(pill "$RED" "Close $count $word$note?")" 'y / n' targets ''
		;;
	search:ctrl-t)
		open_mode tab "$(pill "$GREEN" 'New tab')" 'Tab name' rows "${FZF_QUERY:-}"
		;;
	search:ctrl-s)
		open_mode session "$(pill "$AMBER" 'New session')" 'Session name' rows "${FZF_QUERY:-}"
		;;
	search:alt-p)
		[ "${1:-}" = t ] || return
		toggle_pin "$2"
		fetch_rows
		draw_header
		reload_rows rows
		;;
	search:help)
		if [ -e "$TABFIND_STATE/help" ]; then
			rm -f "$TABFIND_STATE/help"
		else
			: >"$TABFIND_STATE/help"
		fi
		draw_footer
		;;
	search:change | rename:change | tab:change | session:change)
		# Only bound while an error shows, or until the next redraw after one. A
		# redraw putting the query back also lands here, and that isn't typing.
		[ "${FZF_QUERY:-}" = "$(cat "$TABFIND_STATE/input")" ] && return
		rm -f "$TABFIND_STATE/error"
		printf 'unbind(change)+'
		draw_header
		;;
	rename:enter)
		session=$(cut -f4 "$TABFIND_STATE/targets")
		window=$(cut -f5 "$TABFIND_STATE/targets")
		if [ -n "${FZF_QUERY:-}" ]; then
			err=$(rex window rename -s "$session" -- "$window" "$FZF_QUERY" 2>&1) || {
				show_error "$err"
				return
			}
		fi
		back_to_search
		;;
	tab:enter)
		create_tab "${FZF_QUERY:-}"
		;;
	session:enter)
		create_session "${FZF_QUERY:-}"
		;;
	close:change)
		case ${FZF_QUERY:-} in
		y | Y) close_targets ;;
		n | N) back_to_search ;;
		*) printf 'clear-query' ;;
		esac
		;;
	rename:esc | close:esc | tab:esc | session:esc)
		back_to_search
		;;
	esac
}

case ${1:-} in
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
TABFIND_ORIGIN_BLOCK=${2:-}

# Keep the error on screen: the pane closes as soon as this script exits.
fail() {
	printf '\n%s\nPress Enter to close.' "$1"
	read -r _
	exit 1
}

command -v fzf >/dev/null 2>&1 || fail 'fzf is not on the PATH of this pane.'

if [ -n "$TABFIND_DARK" ]; then
	colors='bg:#34363a,fg:#d4d6da,bg+:#4a4d52,fg+:#f2f3f5:bold,hl:#7cc0ee:underline,hl+:#9ad2f5:underline:bold,prompt:#7cc0ee:bold,query:#f2f3f5:bold,ghost:#a3a6ac,info:#a3a6ac,pointer:#7cc0ee,marker:#7cc0ee,header:#ffa06e,border:#55585e,label:#a3a6ac,preview-border:#55585e,preview-label:#d4d6da,footer:#a3a6ac,gutter:#34363a'
else
	colors='bg:#eee8d5,fg:#46595f,bg+:#fdf6e3,fg+:#073642:bold,hl:#0b5f98:underline,hl+:#0b5f98:underline:bold,prompt:#0b5f98:bold,query:#073642:bold,ghost:#4f6369,info:#4f6369,pointer:#0b5f98,marker:#0b5f98,header:#a83c0c,border:#cfc6ae,label:#4f6369,preview-border:#cfc6ae,preview-label:#46595f,footer:#4f6369,gutter:#eee8d5'
fi

TABFIND_STATE=$(mktemp -d) || fail 'Could not create a temporary directory.'
trap 'rm -rf "$TABFIND_STATE"' EXIT
trap 'exit 1' HUP INT TERM
printf 'search' >"$TABFIND_STATE/mode"
: >"$TABFIND_STATE/input"

TABFIND_OWN_WINDOW=$(rex block inspect "$REX_BLOCK" --json 2>/dev/null | window_id_from_json)
TABFIND_SELF=$self
export TABFIND_STATE TABFIND_OWN_WINDOW TABFIND_SELF TABFIND_DARK TABFIND_ORIGIN_BLOCK

fetch_rows || fail "$(cat "$TABFIND_STATE/error")"
write_footer

# Headings fill field 2 and tabs field 3, and only 3 is searched. The tab
# before field 3 indents tab rows under their heading.
fzf <"$TABFIND_STATE/rows" \
	--ansi --multi --delimiter='\t' --with-nth="{2}$TAB{3}" --nth=2 --tabstop=2 \
	--layout=reverse --no-scrollbar --no-hscroll --highlight-line \
	--gutter=' ' --pointer='▌' --marker='✓' \
	--input-border=rounded --input-label=' Find tab ' --input-label-pos=2 \
	--list-border=rounded --header-border=inline --footer-border=inline \
	--info=inline-right \
	--info-command='read -r m <"$TABFIND_STATE/mode"; [ "$m" = search ] || exit 0; read -r n <"$TABFIND_STATE/count"; if [ -n "$FZF_QUERY" ]; then printf "%s/%s" "$FZF_MATCH_COUNT" "$n"; else printf "%s tabs" "$n"; fi; [ "$FZF_SELECT_COUNT" -eq 0 ] || printf " · %s marked" "$FZF_SELECT_COUNT"' \
	--prompt='❯ ' --ghost='Search tabs' \
	--track --id-nth=5 \
	--color="$colors,preview-bg:-1,preview-fg:-1" \
	--preview='sh "$TABFIND_SELF" preview {4} {6}' \
	--preview-window="right,$PREVIEW_PERCENT%,follow,border-rounded,noinfo" --preview-label-pos=2 \
	--bind='start:unbind(change)+transform-footer(cat "$TABFIND_STATE/footer")' \
	--bind='focus:transform-preview-label(printf %s {12})+transform(sh "$TABFIND_SELF" key focus {1})' \
	--bind='resize:transform(sh "$TABFIND_SELF" key resize)' \
	--bind='change:transform(sh "$TABFIND_SELF" key change)' \
	--bind='enter:transform(sh "$TABFIND_SELF" key enter {1})' \
	--bind='esc:transform(sh "$TABFIND_SELF" key esc)' \
	--bind='ctrl-r:transform(sh "$TABFIND_SELF" key ctrl-r {1} {f})' \
	--bind='ctrl-x:transform(sh "$TABFIND_SELF" key ctrl-x {+f})' \
	--bind='ctrl-t:transform(sh "$TABFIND_SELF" key ctrl-t)' \
	--bind='ctrl-s:transform(sh "$TABFIND_SELF" key ctrl-s)' \
	--bind='?:transform(sh "$TABFIND_SELF" key help)' \
	--bind='alt-p:transform(sh "$TABFIND_SELF" key alt-p {1} {5})' \
	--bind='alt-enter:execute(sh "$TABFIND_SELF" screen {4} {6})' \
	--bind='ctrl-v:toggle-preview' \
	--bind='tab:toggle+down,shift-tab:deselect+up' \
	--bind='ctrl-j:down,ctrl-k:up,ctrl-n:down,ctrl-p:up,ctrl-f:page-down,ctrl-b:page-up'
status=$?

# Not a match (1) and abort (130) are normal. Anything else is fzf itself failing.
case $status in
0 | 1 | 130) ;;
*) fail "fzf failed with status $status." ;;
esac

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
