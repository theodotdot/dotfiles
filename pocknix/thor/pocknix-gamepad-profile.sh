#!/bin/bash
# pocknix-gamepad-profile.sh — keep the InputPlumber gamepad profile/targets matched to the
# current pocknix session.
#   apply         : Plasma Mobile navigation (mouse + keyboard).
#   reset         : stock profile + Deck pad, for game mode.
#   apply-session : pick apply/reset from the current session state (used by the systemd unit
#                   so an InputPlumber restart can't leave desktop mode on the default profile).
set -u

SERVICE=org.shadowblip.InputPlumber
IFACE=org.shadowblip.Input.CompositeDevice
PROFILE=/etc/inputplumber/profiles/plasma-mobile.yaml
DEFAULT_PROFILE=/usr/share/inputplumber/profiles/default.yaml
SESSION_STATE=/home/deck/.local/state/pocknix-session

composites() {
  busctl --system tree "${SERVICE}" 2>/dev/null \
    | grep -o '/org/shadowblip/InputPlumber/CompositeDevice[0-9]\+' | sort -u
}

wait_composites() {
  local i=0
  while [ -z "$(composites)" ]; do
    i=$((i + 1))
    [ "${i}" -ge 100 ] && return 1
    sleep 0.1
  done
  return 0
}

load() {  # <profile-path>
  local path="$1" p
  wait_composites || {
    echo "pocknix-gamepad-profile: no InputPlumber composite device" >&2
    return 1
  }
  for p in $(composites); do
    busctl --system call "${SERVICE}" "${p}" "${IFACE}" LoadProfilePath s "${path}" >/dev/null 2>&1 \
      || echo "pocknix-gamepad-profile: failed to load ${path} on ${p}" >&2
  done
}

attach_deck() {
  # The plasma profile drops the pad target, and pocknix-gamepad-target only swaps one pad for
  # another, so re-attach the Deck pad explicitly for game mode.
  wait_composites || return 1
  local p
  for p in $(composites); do
    busctl --system call "${SERVICE}" "${p}" "${IFACE}" SetTargetDevices as 2 deck-uhid keyboard \
      >/dev/null 2>&1 \
      || echo "pocknix-gamepad-profile: failed to restore deck-uhid on ${p}" >&2
  done
}

reset() {
  load "${DEFAULT_PROFILE}"
  attach_deck
}

case "${1:-}" in
  apply)
    load "${PROFILE}"
    ;;
  reset)
    reset
    ;;
  apply-session)
    case "$(cat "${SESSION_STATE}" 2>/dev/null)" in
      plasma|desktop) load "${PROFILE}" ;;
      *) reset ;;
    esac
    ;;
  *)
    echo "usage: $0 apply|reset|apply-session" >&2
    exit 2
    ;;
esac
