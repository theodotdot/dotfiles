#!/bin/bash
# Apply the Plasma Mobile gamepad profile when Plasma Mobile starts (not the regular
# Plasma desktop). DESKTOP_SESSION is exported by pocknix-desktop before these hooks run.
case ":${DESKTOP_SESSION:-}:" in
  *:plasma-mobile:*) ;;
  *) exit 0 ;;
esac

exec /usr/lib/pocknix/pocknix-gamepad-profile.sh apply
