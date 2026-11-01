#!/bin/sh
# Enables the right-stick scroll helper once its unit is installed. chezmoi writes
# unit files but never enables them, so a fresh machine would otherwise miss it.
set -u

unit="$HOME/.config/systemd/user/pocknix-stick-scroll.service"
[ -f "$unit" ] || exit 0

# Only when a user manager is reachable (chezmoi can also run over plain ssh/root).
systemctl --user show-environment >/dev/null 2>&1 || exit 0

systemctl --user enable pocknix-stick-scroll.service >/dev/null 2>&1 || exit 0
systemctl --user start pocknix-stick-scroll.service >/dev/null 2>&1 || true
