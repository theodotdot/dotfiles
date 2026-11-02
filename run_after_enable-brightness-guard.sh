#!/bin/sh
# Enables the brightness guard, which restarts the shell once when it started before
# PowerDevil and therefore lost its quick-settings brightness slider.
set -u

unit="$HOME/.config/systemd/user/pocknix-brightness-guard.service"
script="$HOME/.config/scripts/pocknix-brightness-guard"
[ -f "$unit" ] && [ -x "$script" ] || exit 0

# Only when a user manager is reachable (chezmoi can also run over plain ssh/root).
systemctl --user show-environment >/dev/null 2>&1 || exit 0

systemctl --user daemon-reload >/dev/null 2>&1 || true
# enable only: the unit is oneshot at session start, starting it now would restart the shell
# in the middle of a chezmoi apply.
systemctl --user enable pocknix-brightness-guard.service >/dev/null 2>&1 || true
