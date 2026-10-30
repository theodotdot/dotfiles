#!/bin/bash
# Installs the Pocknix Plasma Mobile gamepad mapping.
# Run as root:  sudo bash /home/deck/pocknix-install/install.sh
set -e
S="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -D -m755 "$S/pocknix-gamepad-profile.sh" /usr/lib/pocknix/pocknix-gamepad-profile.sh
install -D -m755 "$S/10-plasma-mobile-gamepad.sh" /usr/lib/pocknix/desktop.d/10-plasma-mobile-gamepad.sh
install -D -m644 "$S/plasma-mobile.yaml" /etc/inputplumber/profiles/plasma-mobile.yaml
install -D -m644 "$S/pocknix-gamepad-reset.service" /etc/systemd/user/pocknix-gamepad-reset.service
install -D -m644 "$S/thor-gamepad.yaml" /usr/share/inputplumber/capability_maps/thor-gamepad.yaml
install -D -m644 "$S/pocknix-gamepad-profile.service" /etc/systemd/system/pocknix-gamepad-profile.service
mkdir -p /etc/systemd/user/pocknix-game-session.target.wants
ln -sf ../pocknix-gamepad-reset.service /etc/systemd/user/pocknix-game-session.target.wants/pocknix-gamepad-reset.service
mkdir -p /etc/systemd/system/inputplumber.service.wants
ln -sf ../pocknix-gamepad-profile.service /etc/systemd/system/inputplumber.service.wants/pocknix-gamepad-profile.service

echo "installed."
