"""Read the virtual Xbox 360 pad that InputPlumber exposes while Anki is focused.

Chromium-based add-ons and keyboard emulation both fought the rest of the system
(global shortcuts, Anki's own shortcuts), so the pad is read straight from evdev.
The pad is an InputPlumber *target*, not a grabbed device, and its udev uaccess
ACL lets the Anki user open it without root.
"""

from __future__ import annotations

import fcntl
import os
import struct
import time
import traceback
from pathlib import Path
from typing import Callable, Optional

from aqt.qt import QObject, QTimer

EV_KEY, EV_ABS = 1, 3

PAD_NAME = "Microsoft X-Box 360 pad"
_EVENT = struct.Struct("<qqHHi")  # struct input_event on 64-bit

ABS_HAT0X, ABS_HAT0Y = 0x10, 0x11
EVIOCGRAB = 0x40044590  # _IOW('E', 0x90, int)

KEYBOARD_NAME = "InputPlumber Keyboard"

LOG_PATH = Path.home() / ".cache" / "anki-gamepad.log"


def log(message: str) -> None:
    """Append to a log file; never write to stderr from a Qt slot."""
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(LOG_PATH, "a", encoding="utf8") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {message}\n")
    except Exception:
        pass


def find_event_device(name: str) -> Optional[str]:
    """Return /dev/input/eventN for the input device called ``name``."""
    try:
        with open("/proc/bus/input/devices", encoding="utf8", errors="replace") as f:
            blocks = f.read().split("\n\n")
    except OSError:
        return None
    for block in blocks:
        if f'Name="{name}"' not in block:
            continue
        for line in block.splitlines():
            if line.startswith("H: Handlers="):
                for token in line.split("=", 1)[1].split():
                    if token.startswith("event"):
                        return "/dev/input/" + token
    return None


class GamepadReader(QObject):
    """Poll the pad from a QTimer and forward raw events.

    A 15 ms poll over a non-blocking fd is cheap and avoids QSocketNotifier's
    fd semantics for character devices.
    """

    POLL_MS = 15

    def __init__(
        self,
        handler: Callable[[int, int, int], None],
        device_name: str = PAD_NAME,
        grab: bool = False,
        parent=None,
    ) -> None:
        super().__init__(parent)
        self.handler = handler
        self.device_name = device_name
        self.grab = grab
        self._fd = -1
        self._timer: Optional[QTimer] = None
        self._retries = 0

    def start(self) -> None:
        self._retries = 0
        self._start()

    def _start(self) -> None:
        try:
            self.stop()
            fd = self._open()
            if fd < 0:
                # The device is created by the profile we just loaded; udev may
                # still be applying permissions. Retry for a few seconds.
                if self._retries < 50:
                    self._retries += 1
                    QTimer.singleShot(100, self._start)
                else:
                    log("gamepad device not available")
                return
            self._retries = 0
            self._fd = fd
            self._timer = QTimer(self)
            self._timer.setInterval(self.POLL_MS)
            self._timer.timeout.connect(self._read)
            self._timer.start()
        except Exception:
            log("reader start failed: " + traceback.format_exc())
            self.stop()

    def is_open(self) -> bool:
        return self._fd >= 0

    def _open(self) -> int:
        path = find_event_device(self.device_name)
        if path is None:
            return -1
        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
        except OSError:
            return -1
        if self.grab:
            try:
                fcntl.ioctl(fd, EVIOCGRAB, 1)
            except OSError as err:
                log(f"grab failed on {path}: {err}")
        log(f"reading {path}{' (grabbed)' if self.grab else ''}")
        return fd

    def stop(self) -> None:
        if self._timer is not None:
            self._timer.stop()
            self._timer.deleteLater()
            self._timer = None
        if self._fd >= 0:
            if self.grab:
                try:
                    fcntl.ioctl(self._fd, EVIOCGRAB, 0)
                except OSError:
                    pass
            try:
                os.close(self._fd)
            finally:
                self._fd = -1

    def _read(self) -> None:
        if self._fd < 0:
            return
        try:
            data = os.read(self._fd, _EVENT.size * 64)
        except BlockingIOError:
            return
        except OSError:
            self.stop()
            return
        except Exception:
            log("read failed: " + traceback.format_exc())
            self.stop()
            return
        for offset in range(0, len(data) - _EVENT.size + 1, _EVENT.size):
            _, _, etype, code, value = _EVENT.unpack_from(data, offset)
            self.handler(etype, code, value)
