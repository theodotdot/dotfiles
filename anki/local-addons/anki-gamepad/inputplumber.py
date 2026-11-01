"""InputPlumber profile switching for the AYN Thor gamepad.

Talks to inputplumber over the system bus with ``busctl`` so the add-on needs no
extra Python modules.  Profile loading is allowed for members of the ``wheel`` or
``inputplumber`` groups via inputplumber's polkit rule, so no root is required.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path
from typing import List, Optional

SERVICE = "org.shadowblip.InputPlumber"
IFACE = "org.shadowblip.Input.CompositeDevice"

CONFIG_DIR = Path.home() / ".config" / "inputplumber" / "profiles"
ANKI_PROFILE = CONFIG_DIR / "anki.yaml"

# Installed by the pocknix overlay; restores whatever the session should use
# (Plasma Mobile navigation, or the stock gamepad profile in game mode).
POCKNIX_HELPER = Path("/usr/lib/pocknix/pocknix-gamepad-profile.sh")
FALLBACK_PROFILE = Path("/etc/inputplumber/profiles/plasma-mobile.yaml")

_COMPOSITE_RE = re.compile(r"/org/shadowblip/InputPlumber/CompositeDevice\d+")


def _run(args: List[str], timeout: float = 5) -> Optional[str]:
    try:
        proc = subprocess.run(
            args, capture_output=True, text=True, timeout=timeout, check=False
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if proc.returncode != 0:
        return None
    return proc.stdout


def composite_devices() -> List[str]:
    out = _run(["busctl", "--system", "tree", SERVICE], timeout=3)
    if not out:
        return []
    return sorted(set(_COMPOSITE_RE.findall(out)))


def load_profile(path: Path) -> bool:
    """Load ``path`` on every composite device. True if at least one accepted it."""
    if not path.is_file():
        return False
    devices = composite_devices()
    loaded = False
    for dev in devices:
        if _run(
            [
                "busctl",
                "--system",
                "call",
                SERVICE,
                dev,
                IFACE,
                "LoadProfilePath",
                "s",
                str(path),
            ]
        ) is not None:
            loaded = True
    return loaded


def activate() -> bool:
    """Switch the gamepad to the Anki review profile."""
    return load_profile(ANKI_PROFILE)


def restore() -> bool:
    """Give the gamepad back to the session (desktop navigation / game mode)."""
    if POCKNIX_HELPER.is_file():
        return _run([str(POCKNIX_HELPER), "apply-session"], timeout=10) is not None
    return load_profile(FALLBACK_PROFILE)


def _selftest() -> int:
    print("composite devices:", composite_devices())
    print("profile present:", ANKI_PROFILE.is_file())
    print("activate:", activate())
    print("restore:", restore())
    return 0


if __name__ == "__main__":
    raise SystemExit(_selftest())
