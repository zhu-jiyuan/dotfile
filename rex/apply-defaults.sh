#!/bin/sh
# Apply the Rex.app settings that live in macOS preferences. init.lua only
# covers key bindings and actions, so these cannot go there.
#
# Rex reads these at launch: quit and reopen it after running this script.
# The setting names come from the app itself, not from documentation, so a
# Rex update could rename them.
set -eu

domain=com.superlogical.rex
theme_id=custom-iterm2-solarized-light
theme_file="$(cd "$(dirname "$0")" && pwd)/solarized-light-theme.json"

# An empty pipeline below would still succeed and wipe the custom themes.
if [ ! -s "$theme_file" ]; then
	echo "[ERROR]: $theme_file is missing or empty, nothing was changed."
	exit 1
fi

defaults write "$domain" Workspace.tabStyle -string vertical
defaults write "$domain" Workspace.sidebarPosition -string left

# tabfind.sh switches sessions through the app, which needs Remote Control on.
defaults write "$domain" rex.client.remoteControl -bool true

# Font, matching ghostty/config. Install it with the command in the README.
defaults write "$domain" Workspace.terminalFontName -string "JetBrainsMono Nerd Font Mono"
defaults write "$domain" Workspace.terminalFontPointSize -float 19
defaults write "$domain" Workspace.terminalFallbackFontNames -array "PingFang SC"

# Both Option keys send Alt, like macos-option-as-alt = true in Ghostty.
# Use leftActsAsAlt to keep typing special characters with the right one.
defaults write "$domain" Workspace.terminalOptionKeyBehavior -string actsAsAlt

# iTerm2 Solarized Light, used when macOS is in light mode.
# This replaces the whole custom theme list, including any imported in Rex.
defaults write "$domain" Workspace.customThemes -data "$(xxd -p "$theme_file" | tr -d '\n')"
defaults write "$domain" Workspace.lightThemeID -string "$theme_id"

echo "[SUCCESS]: Rex settings written. Quit and reopen Rex to apply them."
