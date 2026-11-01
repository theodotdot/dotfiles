#!/bin/sh
# Enables the bottom-panel brightness sync once its unit and script are installed.
# chezmoi writes unit files but never enables them, so a fresh machine would otherwise
# miss it (same reasoning as run_after_enable-stick-scroll.sh).
set -u

unit="$HOME/.config/systemd/user/pocknix-brightness-sync.service"
script="$HOME/.config/scripts/pocknix-brightness-sync"
[ -f "$unit" ] && [ -x "$script" ] || exit 0

# Only when a user manager is reachable (chezmoi can also run over plain ssh/root).
systemctl --user show-environment >/dev/null 2>&1 || exit 0

systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user enable pocknix-brightness-sync.service >/dev/null 2>&1 || exit 0
# restart, not start: GAMMA is a constant in the script, so a tuned value only takes
# effect by reloading the helper.
systemctl --user restart pocknix-brightness-sync.service >/dev/null 2>&1 || true
