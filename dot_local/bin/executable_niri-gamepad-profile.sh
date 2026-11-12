#!/bin/sh
# niri-gamepad-profile.sh — load the InputPlumber gamepad layout for the session.
#
# Pocknix's InputPlumber integration re-applies the *Plasma Mobile* profile on
# boot and after every InputPlumber restart (pocknix-gamepad-profile.service,
# apply-session), so a niri session has to claim the pad itself. Called from
# niri's spawn-at-startup; safe to run by hand after an InputPlumber restart:
#
#   niri-gamepad-profile.sh                                  # niri layout
#   niri-gamepad-profile.sh ~/.config/inputplumber/profiles/anki.yaml
#
# Members of `wheel` may load profiles (inputplumber's polkit rule): no root.

set -u
SERVICE=org.shadowblip.InputPlumber
IFACE=org.shadowblip.Input.CompositeDevice
PROFILE=${1:-$HOME/.config/inputplumber/profiles/niri.yaml}

# InputPlumber creates the composite device asynchronously at boot.
i=0
while :; do
    composites=$(busctl --system tree "$SERVICE" 2>/dev/null \
        | grep -o '/org/shadowblip/InputPlumber/CompositeDevice[0-9]\+' | sort -u)
    [ -n "$composites" ] && break
    i=$((i + 1))
    if [ "$i" -ge 50 ]; then
        echo "niri-gamepad-profile: no InputPlumber composite device" >&2
        exit 1
    fi
    sleep 0.2
done

rc=0
for p in $composites; do
    busctl --system call "$SERVICE" "$p" "$IFACE" LoadProfilePath s "$PROFILE" \
        >/dev/null 2>&1 \
        || { echo "niri-gamepad-profile: failed to load $PROFILE on $p" >&2; rc=1; }
done
exit "$rc"
