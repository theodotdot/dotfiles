#!/bin/sh
# Registers the Brightness quick setting at the front of Plasma Mobile's action drawer.
#
# ~/.config/plasmamobilerc is shell state (tile order, wizard flags, status bar scale are
# rewritten at runtime), so it is deliberately not managed as a file: this script only
# makes sure the one entry we care about is present and first.
set -u

cfg="${XDG_CONFIG_HOME:-$HOME/.config}/plasmamobilerc"
id="org.kde.plasma.quicksetting.brightness"

[ -f "$cfg" ] || exit 0
# Only meaningful where Plasma Mobile's quick settings actually exist.
[ -d /usr/share/plasma/quicksettings ] || exit 0
command -v kreadconfig6 >/dev/null 2>&1 || exit 0
command -v kwriteconfig6 >/dev/null 2>&1 || exit 0

current=$(kreadconfig6 --file "$cfg" --group QuickSettings --key enabledQuickSettings 2>/dev/null) || exit 0
[ -n "$current" ] || exit 0

# Already first: leave the user's ordering alone.
case "$current" in
    "$id" | "$id,"*) exit 0 ;;
esac

# Keep every other entry in order, drop any duplicate of ours, put ours in front.
rest=$(printf '%s' "$current" | tr ',' '\n' | grep -vx "$id" | paste -sd, -)
if [ -n "$rest" ]; then
    entries="$id,$rest"
else
    entries="$id"
fi

kwriteconfig6 --file "$cfg" --group QuickSettings --key enabledQuickSettings "$entries"
