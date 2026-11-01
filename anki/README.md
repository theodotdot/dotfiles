# Anki add-ons

`addons.txt` lists the AnkiWeb add-on IDs from the desktop profile; `config/` holds
snapshots of each add-on's `config.json` (the settings that actually live outside the
collection).

`../run_anki-addons.sh.tmpl` runs on every `chezmoi apply` and:

1. downloads only the add-ons missing from `~/.local/share/Anki2/addons21/`,
   writing `meta.json` the way Anki's installer does;
2. writes `config/<id>/config.json` only when the add-on has no `config.json` yet;
3. copies add-ons that have no AnkiWeb ID from `local-addons/`.

It exits silently until Anki is installed and `~/.local/share/Anki2` exists, so the
order (install Anki, then `chezmoi apply`) does not matter.

Because step 3 only copies add-ons that are *missing*, edits to `local-addons/` are not
picked up on their own. After changing the controller add-on:

```sh
cp -a ~/.local/share/chezmoi/anki/local-addons/anki-gamepad/*.py \
      ~/.local/share/Anki2/addons21/anki-gamepad/
rm -rf ~/.local/share/Anki2/addons21/anki-gamepad/__pycache__
```

then restart Anki (add-on code is only loaded at startup).

## Thor controller

Anki is driven by the gamepad through `local-addons/anki-gamepad/`, which reads evdev
devices directly. Two earlier approaches failed: Chromium/Contanki never saw the d-pad
(the Thor capability map exposes it as `KEY_UP/DOWN/LEFT/RIGHT`, not as gamepad
buttons), and coarse keyboard emulation was eaten by KDE's global shortcuts and Anki's
own bindings.

The add-on loads `~/.config/inputplumber/profiles/anki.yaml` while an Anki window has
focus and reads two evdev devices directly (udev grants the seat user rw access, so no
root): the Xbox 360 pad for face buttons/bumpers, and the ``InputPlumber Keyboard``
target for the d-pad, because the Thor capability map turns the packed d-pad buttons
into `KEY_UP/DOWN/LEFT/RIGHT` (pass-through drops them on the pad target). Reviewer
scrolling of the d-pad is Anki's native arrow-key scrolling; the add-on adds deck
navigation for the same arrows.

The right stick scrolls the main Anki screen (card, deck list, overview): the
add-on turns `ABS_RY` deflection into `window.scrollBy` calls on `mw.web` every 16 ms,
so the speed follows how far the stick is pushed (260 px/s at the deadzone edge,
2.2k px/s at full deflection).

| Pad | Answer screen | Question screen | Deck browser |
|---|---|---|---|
| A | Good (3) | show answer | open deck → overview |
| B | Easy (4) | back | back |
| X | Hard (2) | edit note | — |
| Y | Again (1) | undo | — |
| LB / RB | undo / edit note | undo / edit note | — |
| Start / Select | back to deck list | back | — |
| D-pad | scroll the card (native) | scroll the card (native) | previous/next deck |
| Right stick ↑↓ | scroll the card | scroll the card | scroll the deck list |
| Left stick / LT / RT | unused | | |

The add-on also appends the controller hint to Anki's grading labels via the
`reviewer_will_init_answer_buttons` hook ("Again (Y)", "Hard (X)", "Good (A)",
"Easy (B)"); grading is layout-aware, so 2/3-button learning cards use the same
face buttons (A=Good, B=Easy, X=Hard, Y=Again, skipping buttons the card lacks).

When focus moves to another application the session profile is restored via
`pocknix-gamepad-profile.sh apply-session`, so Plasma Mobile navigation keeps working.
Anki has to be restarted once for the add-on to load.

Not managed here on purpose: the collection, media, backups and `prefs21.db`
(the latter holds the AnkiWeb `syncKey`, plus window geometry and UI scale).
Collection, deck presets, note types and FSRS parameters come from AnkiWeb sync.
