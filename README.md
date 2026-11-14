<h1 align="center">
   <img src="./Downloads/misc/icon.jpg  " width="100px" /> 
   <br>
      theodotdot's dots 
   <br>
      <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px" /> <br>
 
</h1>

Managed with [chezmoi](https://github.com/twpayne/chezmoi). `anki/` and `pocknix/` are
payloads that chezmoi ignores; the rest is `chezmoi apply` and done.

### 🖼️ Theme

[catppuccin](https://catppuccin.com/) macchiato.

### 🛠️ Tools

Fish with [Fisher](https://github.com/jorgebucaran/fisher); plugins are in
[fish_plugins](./private_dot_config/fish/fish_plugins). Prompt is
[starship](https://starship.rs/), plus `direnv`, `zoxide` and `fzf`.

|     Tool                                                                          |     Use                               |
| --------------------------------------------------------------------------------- | ------------------------------------- |
| **[kitty](https://sw.kovidgoyal.net/kitty/)**                                     | terminal                              |
| **[helix](https://helix-editor.com/)**                                            | editor                                |
| **[yazi](https://yazi-rs.github.io/)**                                            | file manager                          |
| **[zellij](https://zellij.dev/)**                                                 | multiplexer                           |
| **[niri](https://github.com/YaLTeR/niri)**                                        | Wayland compositor                    |
| **[noctalia](https://github.com/noctalia-dev/noctalia)**                          | bar, notifications, wallpaper         |
| **[bat](https://github.com/sharkdp/bat)**                                         | cat with wings                        |
| **[btop](https://github.com/aristocratos/btop)**                                  | system monitor                        |
| **[gitui](https://github.com/extrawurst/gitui)**                                  | git TUI                               |
| **[zathura](https://pwmt.org/projects/zathura/)**                                 | PDF viewer                            |

### 🕹️ niri on the Thor

The config lives in `~/.config/niri/config.kdl`, installed from
[config.kdl.tmpl](./private_dot_config/niri/config.kdl.tmpl). It includes `blur.kdl` and
[gestures.kdl](./private_dot_config/niri/gestures.kdl) from the same directory, the
latter being the touchscreen gesture set from the niri tablet patchset. `secrets.kdl` is
also included but stays local and unmanaged.

#### Screens

| Output | Panel | Mode | Logical |
|---|---|---|---|
| `DSI-2` | top | 1080×1920 @ 120, rotated 270° | 960×540 at scale 2, at 0,0 |
| `DSI-1` | bottom | 1080×1240 @ 60, rotated 270° | 620×540 at scale 2, at 170,540 |
| `DP-1` | USB-C dock | preferred | scale 1.5 |

The top screen sits at the origin and the bottom one is centred underneath it. Rotation
comes from the panel's DRM orientation property, so the config sets only scale and
position. `Mod+G` / `Mod+Shift+G` / `Mod+Alt+G` switch `DP-1` between 150 %, 100 % and
200 % for gaming.

#### Touch

Both panels are touchscreens with their own libinput name, and each is pinned to its own
output:

```kdl
touch "bottom_touchscreen" { map-to-output "DSI-1" }
touch "top_touchscreen"    { map-to-output "DSI-2" }
```

This needs a patched niri. Stock niri rejects a `touch` block that takes a device name,
rejects `gestures.kdl`, and has no `above-lock` layer rule, which the on-screen keyboard
needs. Per-device touch mapping is upstream PR #1856. No stylus is exposed on the device,
so there is no `tablet` block.

#### Bar

Noctalia runs the bar on the top screen only; `DSI-1` is switched off in
[config.toml.tmpl](./private_dot_config/noctalia/config.toml.tmpl) and `DP-1` gets a bar
of its own with wider end margins. The bar is sized for the 960 px logical width rather
than a desktop monitor.

#### Brightness

Noctalia matches each backlight to a display by comparing the backlight's parent device
with `/sys/class/drm/card*-<connector>`. Both Thor backlights hang off their DSI
controllers instead, so they are pinned by name:

```toml
[brightness]
sync_all_monitors = true

[brightness.monitor."DSI-2"]
backend = "backlight"
backlight_device = "ae96000.dsi.0"

[brightness.monitor."DSI-1"]
backend = "backlight"
backlight_device = "ae94000.dsi.0"
```

With `sync_all_monitors` any slider moves both panels to the same percentage. The kernel
applies the gamma curve to the bottom panel, so equal percentages give equal light.

#### Gamepad

[inputplumber/profiles/niri.yaml](./private_dot_config/inputplumber/profiles/niri.yaml)
turns the pad into a mouse and keyboard while niri runs. Pocknix re-applies its Plasma
Mobile profile on boot and after an InputPlumber restart, so
[niri-gamepad-profile.sh](./dot_local/bin/executable_niri-gamepad-profile.sh) is spawned
at session start to claim the pad back. Run it by hand after a restart mid-session.

| Input | Sends |
|---|---|
| Left stick | pointer |
| Bottom face key | Enter |
| Right face key | Escape |
| Left face key | Space |
| Top face key | `Super+F12`, toggles the on-screen keyboard |
| D-pad | arrow keys |
| LB | left click |
| LT / RT / RB | held Shift / Alt / Super |
| Start | overview (`Mod+N`) |
| Select | launcher (`Mod+Space`) |
| AYN key | control center (`Mod+A`) |
| View | close window (`Mod+Q`) |
| Home | Tab |

Held modifiers combine with the d-pad to give the Super binds, so `RB`+d-pad moves focus
in niri. The right stick scrolls through
[pocknix-stick-scroll](./private_dot_config/scripts/executable_pocknix-stick-scroll),
a user service: InputPlumber cannot map an axis to wheel steps, so it reads `ABS_RX` /
`ABS_RY` from the pad and emits `REL_WHEEL` / `REL_HWHEEL` on its own uinput device.

Game Mode is in Noctalia's session panel and runs `steamos-session-select gamescope`.

#### On-screen keyboard

[plasma-keyboard-custom](https://github.com/mops1k/plasma-keyboard-custom) is a fork of
Plasma Keyboard with a niri backend: a layer-shell surface, text sent through uinput, and
gamepad navigation. It comes from the `plasma-keyboard-custom-niri` package and runs as
a user unit for the whole session; the package does not enable it itself, so run
`systemctl --user enable plasma-keyboard-custom.service` once.

The top face key sends `Super+F12`, and niri binds `Mod+F12` to the keyboard's D-Bus
toggle:

```kdl
Mod+F12 repeat=false allow-when-locked=true { spawn-sh "gdbus call --session --dest org.kde.plasma.keyboard.custom --object-path /org/kde/plasma/keyboard --method org.kde.plasma.keyboard.custom.toggleKeyboard"; }
```

Two things make it work on the lock screen. `allow-when-locked` keeps the bind alive,
because niri drops binds while the session is locked, and a layer rule lets the keyboard
draw over the lock surface:

```kdl
layer-rule {
    match namespace="^plasma-keyboard$"
    above-lock true
}
```

Typing goes through uinput straight to the lock surface, so the two together give a
handheld with no hardware keyboard a way in. The chord avoids `F24` on purpose: the
capability map turns `KEY_F24` into `Guide`, so it never reaches the compositor.

While the keyboard is open it swaps InputPlumber to an unmapped profile and switches the
pad to gamepad-only interception, so the stick and buttons move around the keyboard
instead of the desktop. The previous profile goes back when it hides, and also after a
crash. If the pad ever comes out dead, run `niri-gamepad-profile.sh`.

The keyboard's settings live in `~/.config/plasmakeyboardrc`, which is local and
unmanaged: locale, floating position, swipe typing, dictation. Dictation uses `handy`,
started hidden from niri (`handy --start-hidden`) so it only sits in the tray.

### 📚 Anki

`anki/local-addons/anki-gamepad` drives Anki with the pad, and
`run_anki-addons.sh.tmpl` copies it out on `chezmoi apply`. See
[anki/README.md](./anki/README.md) for the button map and how to pick up local edits.

### 🧰 Pocknix payload

`sudo bash pocknix/thor/install.sh` installs `/etc/inputplumber/profiles/`,
`/usr/share/inputplumber/capability_maps/thor-gamepad.yaml`, `/usr/lib/pocknix/` and two
systemd units that follow the session profile. The capability map gives game mode a plain
gamepad: d-pad as `DPad*`, A/B unchanged, X/Y swapped to match the printed letters, the
AYN key as `Guide` and the Steam key as `LeftPaddle1`.
