"""Right-stick scrolling for Anki's main webview.

The Anki profile exposes the pad as an Xbox 360 target, so the right stick
arrives as ``ABS_RY`` (0 = centred, 32767 = pushed down).  evdev only reports the
axis when it moves, so a fixed-rate timer repeats the scroll while the stick
stays deflected, scaling the step from the deflection so light pushes creep and
full deflection flies.

The scroll itself is applied inside the page: Anki shares one webview between
the deck browser, the overview and the reviewer, and its DOM is the only thing
that knows which element actually overflows.
"""

from __future__ import annotations

import traceback
from typing import Optional

from aqt import mw
from aqt.qt import QObject, QTimer

from .gamepad import log

MAX_RAW = 32767.0  # ABS_RY full deflection
DEADZONE = 0.22  # fraction of full deflection ignored, matches the pad's own slack
SLOW_PPS = 260.0  # pixels/second just past the deadzone
FAST_PPS = 2200.0  # pixels/second at full deflection
TICK_MS = 16

_SCROLL_JS = (
    "(function (dy) {"
    " var e = document.scrollingElement || document.documentElement;"
    " if (e.scrollHeight > e.clientHeight) { e.scrollTop += dy; return; }"
    " var qa = document.getElementById('qa');"
    " if (qa) { qa.scrollTop += dy; }"
    "})(%d)"
)


def pixels_per_tick(axis: float) -> int:
    """Pixels to scroll in one tick for a normalised (-1..1) stick deflection."""
    magnitude = (abs(axis) - DEADZONE) / (1.0 - DEADZONE)
    if magnitude <= 0.0:
        return 0
    speed = SLOW_PPS + (FAST_PPS - SLOW_PPS) * min(magnitude, 1.0) ** 1.5
    direction = 1 if axis > 0 else -1
    return int(round(direction * speed * TICK_MS / 1000.0))


def scroll_js(pixels: int) -> str:
    """JS that scrolls the overflowing element of the current Anki screen."""
    return _SCROLL_JS % pixels


class StickScroller(QObject):
    """Repeat scroll steps while the right stick is held away from centre."""

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self._axis = 0.0
        self._timer = QTimer(self)
        self._timer.setInterval(TICK_MS)
        self._timer.timeout.connect(self._tick_failed_safe)

    def set_axis(self, raw: int) -> None:
        self._axis = max(-1.0, min(1.0, raw / MAX_RAW))
        active = pixels_per_tick(self._axis) != 0
        if active:
            if not self._timer.isActive():
                self._timer.start()
            self._tick()  # react to the first event instead of waiting a frame
        elif self._timer.isActive():
            self._timer.stop()

    def reset(self) -> None:
        self._axis = 0.0
        self._timer.stop()

    def _tick_failed_safe(self) -> None:
        try:
            self._tick()
        except Exception:  # never let an add-on bug abort Anki
            log("scroll tick failed: " + traceback.format_exc())
            self.reset()

    def _tick(self) -> None:
        pixels = pixels_per_tick(self._axis)
        if pixels == 0:
            self._timer.stop()
            return
        web: Optional[object] = getattr(mw, "web", None)
        if web is None:
            return
        web.eval(scroll_js(pixels))
