"""Drive Anki with the AYN Thor gamepad.

InputPlumber turns the Thor pad into a mouse + keyboard for Plasma Mobile. While
Anki is focused this add-on loads the ``Anki`` profile, which exposes the pad as
a plain Xbox 360 gamepad, and reads that gamepad straight from evdev. Going
through the kernel device avoids both of the earlier failure modes: Chromium/
Contanki saw no d-pad, and keyboard emulation was eaten by global (KDE) and
Anki shortcuts.

When focus moves to another application the session profile is restored, so
Plasma Mobile navigation keeps working.
"""

from __future__ import annotations

import traceback

from aqt import gui_hooks, mw
from aqt.qt import QApplication, QEvent, QObject, Qt, QTimer

from . import gamepad, inputplumber, scroll
from .gamepad import log

_SOUTH, _EAST, _NORTH, _WEST = 0x130, 0x131, 0x133, 0x134
_LB, _RB, _SELECT, _START = 0x136, 0x137, 0x13A, 0x13B



class _FocusWatcher(QObject):
    """Switch the gamepad profile with the application activation state.

    ``QEvent.ApplicationActivate``/``ApplicationDeactivate`` are emitted when a
    window of this process gains/loses focus, so Anki's own dialogs (editor,
    preferences, ...) keep the pad while another application takes it back.
    """

    def __init__(self) -> None:
        super().__init__()
        self.switched = False

    def eventFilter(self, obj, event) -> bool:  # noqa: N802 (Qt API)
        try:
            if obj is QApplication.instance():
                etype = event.type()
                if etype == QEvent.Type.ApplicationActivate:
                    self.enter()
                elif etype == QEvent.Type.ApplicationDeactivate:
                    self.leave()
        except Exception:  # never let an add-on bug abort Anki
            log("eventFilter failed: " + traceback.format_exc())
        return False

    def enter(self) -> None:
        if not self.switched:
            self.switched = inputplumber.activate()
        if not self.switched:
            return
        if not _pad.is_open():
            _pad.start()
        if not _keys.is_open():
            _keys.start()

    def leave(self) -> None:
        if not self.switched:
            return
        _pad.stop()
        _keys.stop()
        _scroller.reset()
        inputplumber.restore()
        self.switched = False

    def sync(self) -> None:
        """Match the profile to the current activation state (startup/profile open)."""
        try:
            app = QApplication.instance()
            if app is not None and app.applicationState() == Qt.ApplicationState.ApplicationActive:
                self.enter()
            else:
                self.leave()
        except Exception:
            log("sync failed: " + traceback.format_exc())


def _reviewer():
    return getattr(mw, "reviewer", None)


def _in_review() -> bool:
    return mw.state == "review" and _reviewer() is not None


def _on_answer() -> bool:
    reviewer = _reviewer()
    return (
        _in_review()
        and reviewer is not None
        and getattr(reviewer, "state", "") == "answer"
    )


# Map the controller's face buttons to grading *roles*, then to the ease that
# the current card actually offers: 4-button cards are Again/Hard/Good/Easy,
# 3-button cards Again/Good/Easy and 2-button cards Again/Good.
_ROLE_HINTS = {"again": "Y", "hard": "X", "good": "A", "easy": "B"}
_EASE_FOR_ROLE = {
    4: {"again": 1, "hard": 2, "good": 3, "easy": 4},
    3: {"again": 1, "good": 2, "easy": 3},
    2: {"again": 1, "good": 2},
}
_ROLE_FOR_EASE = {
    count: {ease: role for role, ease in roles.items()}
    for count, roles in _EASE_FOR_ROLE.items()
}


def _answer_count() -> int:
    try:
        return mw.col.sched.answerButtons(mw.reviewer.card)
    except Exception:
        return 4


def _grade(role: str) -> None:
    """Grade with the ease that corresponds to ``role`` for this card."""
    reviewer = _reviewer()
    if not _on_answer() or reviewer is None:
        return
    count = _answer_count()
    ease = _EASE_FOR_ROLE.get(count, _EASE_FOR_ROLE[4]).get(role)
    if ease is not None:
        reviewer._answerCard(ease)  # noqa: SLF001 (Anki API)


def _relabel_answer_buttons(buttons, reviewer, card):
    """Show the controller button next to each grading label."""
    count = len(buttons)
    roles = _ROLE_FOR_EASE.get(count, _ROLE_FOR_EASE[4])
    return tuple(
        (ease, f"{label} ({_ROLE_HINTS[role]})" if (role := roles.get(ease)) else label)
        for ease, label in buttons
    )


def _back() -> None:
    if mw.state in ("review", "overview"):
        mw.moveToState("deckBrowser")


def _on_a() -> None:
    """A: open deck / start review / show answer / Good."""
    if mw.state == "deckBrowser":
        mw.moveToState("overview")
    elif mw.state == "overview":
        mw.moveToState("review")
    elif _in_review():
        reviewer = _reviewer()
        if _on_answer():
            _grade("good")
        else:
            reviewer.onEnterKey()  # show answer / submit typed answer


def _on_b() -> None:
    """B: Easy on the answer screen, back everywhere else."""
    if _on_answer():
        _grade("easy")
    else:
        _back()


def _on_x() -> None:
    """X: Hard on the answer screen, edit the note elsewhere."""
    if _on_answer():
        _grade("hard")
    elif _in_review():
        mw.onEditCurrent()


def _on_y() -> None:
    """Y: Again on the answer screen, undo elsewhere."""
    if _on_answer():
        _grade("again")
    elif _in_review():
        mw.undo()


def _on_lb() -> None:
    if _in_review():
        mw.undo()


def _on_rb() -> None:
    if _in_review():
        mw.onEditCurrent()


def _select_relative(step: int) -> None:
    if mw.col is None:
        return
    ids = [deck.id for deck in mw.col.decks.all_names_and_ids()]
    if not ids:
        return
    current = mw.col.decks.get_current_id()
    index = ids.index(current) if current in ids else 0
    mw.col.decks.select(ids[(index + step) % len(ids)])
    mw.deckBrowser.refresh()


def _on_hat(axis: int, value: int) -> None:
    """D-pad: deck navigation in the deck browser (arrows scroll natively)."""
    if value == 0:
        return
    if mw.state == "deckBrowser":
        _select_relative(value)
    # In the reviewer the arrow keys scroll the card natively, so the add-on
    # does not scroll again.


_BUTTON_HANDLERS = {
    _SOUTH: _on_a,
    _EAST: _on_b,
    _WEST: _on_x,
    _NORTH: _on_y,
    _LB: _on_lb,
    _RB: _on_rb,
    _SELECT: _back,
    _START: _back,
}


# The Thor capability map turns the d-pad into arrow keys on the keyboard
# target: KEY_UP/DOWN/LEFT/RIGHT.
_ARROW_KEYS = {
    103: (gamepad.ABS_HAT0Y, -1),  # KEY_UP
    108: (gamepad.ABS_HAT0Y, 1),   # KEY_DOWN
    105: (gamepad.ABS_HAT0X, -1),  # KEY_LEFT
    106: (gamepad.ABS_HAT0X, 1),   # KEY_RIGHT
}


def _handle_keyboard_event(etype: int, code: int, value: int) -> None:
    try:
        if etype == gamepad.EV_KEY and value:
            direction = _ARROW_KEYS.get(code)
            if direction is not None:
                log(f"dpad key {code}")
                _on_hat(*direction)
    except Exception:
        log("keyboard handling failed: " + traceback.format_exc())


def _handle_event(etype: int, code: int, value: int) -> None:
    try:
        if etype == gamepad.EV_KEY:
            if not value:
                return
            if code in _BUTTON_HANDLERS:
                _BUTTON_HANDLERS[code]()
            else:
                log(f"unhandled key code {code:#x}")
        elif etype == gamepad.EV_ABS:
            if code in (gamepad.ABS_HAT0X, gamepad.ABS_HAT0Y):
                _on_hat(code, value)
            elif code == gamepad.ABS_RY:
                _scroller.set_axis(value)
            elif value and code >= 0x10:
                log(f"unhandled abs code {code:#x} value {value}")
    except Exception:  # never let an add-on bug abort Anki
        log("event handling failed: " + traceback.format_exc())


_pad = gamepad.GamepadReader(_handle_event)
_keys = gamepad.GamepadReader(_handle_keyboard_event, gamepad.KEYBOARD_NAME)
_scroller = scroll.StickScroller()
_watcher = _FocusWatcher()

gui_hooks.profile_will_close.append(_watcher.leave)
gui_hooks.reviewer_will_init_answer_buttons.append(_relabel_answer_buttons)

_app = QApplication.instance()
if _app is not None:
    _app.installEventFilter(_watcher)
    QTimer.singleShot(0, _watcher.sync)
    gui_hooks.profile_did_open.append(lambda: QTimer.singleShot(300, _watcher.sync))
