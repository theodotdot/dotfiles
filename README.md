<h1 align="center">
   <img src="./Downloads/misc/icon.jpg  " width="100px" /> 
   <br>
      theodotdot's dots 
   <br>
      <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px" /> <br>
 
</h1>

##### Disclaimer: My dotfiles are managed using [chezmoi](https://github.com/twpayne/chezmoi). 
-------------------------------------
### 🖼️ Theme
I use [catppuccin](https://catppuccin.com/) macchiato everywhere I can 🐈‍⬛

### 🛠️ Tools I use

#### Fish

[Fisher](https://github.com/jorgebucaran/fisher) is the plugin manager. Plugins are listed in [fish_plugins](./private_dot_config/fish/fish_plugins).

|     Plugins                                                     |     Others                                          |
| --------------------------------------------------------------- | --------------------------------------------------- |
| **[catppuccin/fish](https://github.com/catppuccin/fish)**       | **[starship prompt](https://starship.rs/)**         |
| **[patrickf1/fzf.fish](https://github.com/patrickf1/fzf.fish)** | **[direnv](https://direnv.net/)**                   |
| **[joseluisq/gitnow](https://github.com/joseluisq/gitnow)**     | **[zoxide](https://github.com/ajeetdsouza/zoxide)** |
| **[laughedelic/pisces](https://github.com/laughedelic/pisces)** | **[fzf](https://github.com/junegunn/fzf)**          |

#### Everything else

|     Tool                                                                          |     Use                               |
| --------------------------------------------------------------------------------- | ------------------------------------- |
| **[kitty](https://sw.kovidgoyal.net/kitty/)**                                     | terminal                              |
| **[helix](https://helix-editor.com/)**                                            | editor                                |
| **[yazi](https://yazi-rs.github.io/)**                                            | file manager                          |
| **[zellij](https://zellij.dev/)**                                                 | multiplexer                           |
| **[niri](https://github.com/YaLTeR/niri)**                                        | Wayland compositor                    |
| **[noctalia](https://github.com/noctalia-dev/noctalia)**                          | bar, notifications, wallpaper (niri)  |
| **[bat](https://github.com/sharkdp/bat)**                                         | cat with wings                        |
| **[btop](https://github.com/aristocratos/btop)**                                  | system monitor                        |
| **[gitui](https://github.com/extrawurst/gitui)**                                  | git TUI                               |
| **[zathura](https://pwmt.org/projects/zathura/)**                                 | PDF viewer                            |

### 🕹️ Thor gamepad

InputPlumber cannot map an analog axis to wheel steps (`Mouse::Wheel` from an axis source
is `NotImplemented` in 0.8x), so right-stick scrolling is done in user space in two places:

| Where | What |
|---|---|
| Plasma Mobile | `~/.config/scripts/pocknix-stick-scroll` (user unit `pocknix-stick-scroll.service`): adds the pad target to the composite device over D-Bus while the `Plasma Mobile` profile is loaded, reads `ABS_RX/ABS_RY` and emits `REL_WHEEL`/`REL_HWHEEL` on its own uinput device, rate scaled by deflection. Idle for every other profile. |
| Anki | `anki/local-addons/anki-gamepad` loads the `Anki` profile on focus, handles the face buttons/d-pad and scrolls the card with the right stick — see [anki/README.md](./anki/README.md). |

`anki/` and `pocknix/` are payloads, not home config: chezmoi ignores them.
`run_anki-addons.sh.tmpl` copies the add-ons out of `anki/`, and `pocknix/thor/` is
installed by `sudo bash pocknix/thor/install.sh` (mirrored to `~/pocknix-install` on the
Thor) which writes `/etc/inputplumber/profiles/`, `/usr/share/inputplumber/capability_maps/`
and `/usr/lib/pocknix/`.

Desktop pad mapping (`pocknix/thor/plasma-mobile.yaml`): left stick = pointer, d-pad =
arrows, bottom key = left click, right key = right click, X (top) = Meta+W (KWin Overview:
switch apps, close the selected one), Y (left) = Meta (home), LB/RB = Alt+Left/Alt+Right,
LT/RT = held LeftCtrl/LeftShift, Start = play/pause, Select = Esc. The MCU reports the face
keys positionally — `BTN_SOUTH` bottom, `BTN_EAST` right, `BTN_NORTH` top, `BTN_WEST`
left — while the shell is printed with Nintendo letters (B bottom, A right, Y left,
X top). `thor-gamepad.yaml` therefore swaps only X/Y (top key = pad X, left key = pad Y)
and leaves A/B as they are, so the bottom key presents as A and the right one as B. The
wheel mappings are gone — the right stick scrolls.
`~/.config/inputplumber/profiles/plasma-mobile.yaml` is tracked as the same file so it can
be `LoadProfilePath`-ed without root; keep it identical to the bundle copy (that one is
what `install.sh` writes to `/etc`).

Game-mode pad mapping (`pocknix/thor/thor-gamepad.yaml`): d-pad emits gamepad `DPad*`;
the stock map sent keyboard arrows, which games read as steering instead of menu
navigation. Only X/Y are swapped relative to the raw `BTN_NORTH`/`BTN_WEST` codes, so the
top key is pad X and the left key pad Y; A/B stay identity, so the bottom key is pad A and
the right key pad B. The AYN key emits `Guide` (Steam button and chord modifier), the hardware
Steam/Guide key emits `LeftPaddle1` so Steam Input can bind it as L4, Back/View stays
`QuickAccess`, and volume-up is re-emitted on the keyboard target. Desktop d-pad arrows
still come from `plasma-mobile.yaml`; the capability map only supplies the gamepad events.
The same mapping ships in the `pocknix-bsp-sm8550` package
(`devices/sm8550/packages/pocknix-bsp-sm8550/root/usr/share/inputplumber/`), so a package
update no longer reverts it; `install.sh` writes the bundle copy over
`/usr/share/inputplumber/capability_maps/thor-gamepad.yaml`, which is where InputPlumber
reads it from.

### 🔆 Thor brightness

Four separate problems with four different owners. The curve now lives in the kernel; the rest is
userspace. Sections 1–3 cover the Plasma/Steam path; section 4 is the niri + Noctalia desktop,
where the same kernel curve applies but the slider wiring is different.

#### 1. The slider vanishing for a whole session

`ScreenBrightnessUtil` builds its `isValid()` state once, at construction, from PowerDevil's D-Bus
object, and its only notification path watches `org.kde.Solid.PowerManagement.Actions.BrightnessControl`
— a name nothing owns (the real service is `org.kde.Solid.PowerManagement`). PowerDevil needs
several seconds to own its name here (DDC probing plus the internal panels) while the shell starts
~4 s into the session, so the shell won by ~3 s and the slider stayed hidden until the next login
(`Getting brightness failed: … "The name is not activatable"`).

Fixed in the shell itself: the installed `plasma-mobile` is a local build carrying the
`ScreenBrightnessUtil` patches (pocknix PR #175), so the util re-queries when
`org.kde.Solid.PowerManagement` appears instead of reading the object once at construction.
Verifiable without the sources — the plugin holds a service watcher:

```
$ strings -a /usr/lib/qt6/qml/org/kde/plasma/private/mobileshell/screenbrightnessplugin/libscreenbrightnessplugin.so \
    | grep QDBusServiceWatcher
_ZN19QDBusServiceWatcher17serviceRegisteredERK7QString
```

Ordering the shell `After=plasma-powerdevil.service` was the earlier approach. It is **not** what
ships: no installed package owns a `plasma-plasmashell.service.d/` drop-in (checked 2026-11-10
across every package), and the local copies are gone — see below.

| Where | What |
|---|---|
| `~/.local/share/plasma/quicksettings/org.kde.plasma.quicksetting.brightness/` | Quick setting tile: `toggle()` cycles 100 → 75 → 50 → 25 → 10 % and wraps, `status` is the live percentage, it drives the same util as the slider. `available` is bound to `maxBrightness` (which notifies) rather than `brightnessAvailable` (which does not), and a 1.5 s retry re-fetches while PowerDevil is absent, so the tile heals itself after a late start. |

`run_onchange_enable-brightness-quicksetting.sh` keeps the tile first in
`[QuickSettings] enabledQuickSettings` of `~/.config/plasmamobilerc`. That file is shell state and
stays unmanaged; the script only inserts the id when it is missing or not first.

Removed on 2026-11-10, once the shell patch was proven (`fails → no shell restart → PowerDevil
restarted by hand → no new failure`): `pocknix-brightness-guard` + its unit + its wants symlink, the
shadow `~/.config/systemd/user/plasma-powerdevil.service`, both hand-made drop-ins
(`plasma-plasmashell.service.d/10-after-powerdevil.conf`, `plasma-powerdevil.service.d/10-after-compositor.conf`),
and the `POCKNIX_*` backup copies taken during the 0.5.0 update. `install.sh` no longer writes any of
them — it installs the gamepad bundle only.

Two approaches that look right and are not:

* `Wants=plasma-powerdevil.service` pulls PowerDevil in at `graphical-session-pre`, i.e. before
  `kwin_wayland` exists, where it aborts on the missing display and lands in `start-limit-hit`.
  `After=` alone only orders, and the session starts PowerDevil anyway — on its own it never made
  the name land before the shell queried it.
* `ExecStartPre` polling for the interface blanks the desktop for the whole time PowerDevil needs
  (~7 s measured) and still loses whenever PowerDevil is slower than the budget.

#### 2. The two panels' light differing at the same percentage

Both backlights are `type=raw`, `scale=unknown`, so nothing in the class or the device tree offers a
curve, and every writer puts the two panels on the *same percentage* while the panels do not share a
response. Measured before the fix: 3100/10000 on the PowerDevil scale drove the top to 1059/3413
(31 %) and the bottom to 79/255 (31 %) — and the bottom looked far brighter.

Fixed in the kernel: patch `1097` on `thor/brightness-gamma`, plus two properties on the bottom
panel node (`&mdss_dsi0` → `panel@0` in `qcs8550-ayn-thor.dts`):

```dts
pocknix,brightness-gamma-milli = <2700>;   /* x^2.7; absent or 1000 = linear */
pocknix,brightness-min = <1>;              /* raw floor for a non-zero request */
```

The mapping happens inside `ch13726a_bl_update_status()`, the driver's only brightness write, so
kwin, PowerDevil and Steam are all correct by construction: one write, no overshoot, Game Mode
included. Integer only (`x^whole` × the square roots of the exponent's binary fractions), within one
level of an exact `pow()`, monotonic. `0` still writes `0`; the floor keeps a 1 % request dim rather
than black. The sysfs readback still reports the *request*, which is what keeps kwin's and the Steam
helper's readback checks honest.

Measured after: at 31 % the bottom is sent `11/255` instead of `79/255`; panels match by eye at
10 %, 31 % and 60 %; no flash on a drag or a 10→100 % jump; `level 79 -> 11` confirmed in the
driver's debug log.

Why it could never be done from userspace: writing
`/sys/class/backlight/ae94000.dsi.0/brightness` costs **~33 ms** (a DSI round trip to the AMOLED
controller; reads are 0.02 ms), so a second, correcting write can never land in the same frame as
the one it corrects. The old `pocknix-brightness-sync` helper followed kwin's signal and applied
the same curve; every variant (polling, settle-after-burst, chasing the burst) flashed, so it is
deleted — an enabler script would have turned it back on at the next `chezmoi apply`.

Note the bottom panel's real mode is **1080×1240@60** (video mode); the 620×540 figure that appears
in older notes is a layout size, not the panel.

#### 3. Steam's Game Mode slider (shipped by the image now)

Steam's slider does not go through PowerDevil. It writes the first entry in `/sys/class/backlight`
**directly** — `ae94000.dsi.0`, the bottom panel, while Game Mode runs on the top one (DSI-2) — and
falls back to `/usr/bin/steamos-polkit-helpers/steamos-priv-write <path> <value>` when that write
fails (pocknix #80). Since `pocknix-bsp-common 0.1.0-37` the direct write always fails: the udev
rule delegates to `pocknix-backlight-grant`, which on a board that names `POCKNIX_PANEL_BACKLIGHT`
leaves `brightness` root-only and grants `video` only `bl_power`. So the fallback is the live path,
not a rescue.

| Where | What |
|---|---|
| `/usr/bin/steamos-polkit-helpers/steamos-priv-write` (shipped by `pocknix-steamos-shim 0.1.0-10`) | Re-execs itself through `pkexec` — `/usr/share/polkit-1/rules.d/50-pocknix-steamos.rules` allows it promptless for `wheel` — then rescales the value from the node Steam named onto `POCKNIX_PANEL_BACKLIGHT` (`ae96000.dsi.0`, the top panel) and writes it as root. One node only; the slider position Steam shows comes from its own readback. Nothing of this lives in the dotfiles. |

Observed 2026-11-10, both paths live:

```
pkexec: deck: Executing command [USER=root] … steamos-priv-write /sys/class/backlight/ae94000.dsi.0/brightness 185
steamos-priv-write: /sys/class/backlight/ae94000.dsi.0/brightness 191 -> /sys/class/backlight/ae96000.dsi.0/brightness 2556
```

`191/255` is 74.9 %; `2556/3413` is the same fraction on the top panel.

The old name for the target, `POCKNIX_PRIMARY_BACKLIGHT`, no longer exists — `thor.conf` renames it
to `POCKNIX_PANEL_BACKLIGHT` in `pocknix-bsp-sm8550 0.2.0-22`, which is why the guest-side helper
(dual write through logind `SetBrightness`, readback retry) would now steer nothing and was dropped.

The kernel curve does not make this redundant: 1097 changes what light a percentage produces, not
which panel Steam addresses. It also leaves the `EINVAL` return alone on purpose, because that
return is what triggers the fallback.

#### 4. Noctalia sees neither backlight

Noctalia 5.4.1 maps each `/sys/class/backlight` node to an output by comparing its `device` parent
with `/sys/class/drm/card*-<connector>`. Both Thor nodes hang off their DSI controllers
(`…/ae94000.dsi/ae94000.dsi.0`, `…/ae96000.dsi/ae96000.dsi.0`), not the display controller's
connector, so both are skipped and every brightness request fails:

```
[brightness] skipping backlight 'ae94000.dsi.0' because it could not be matched to an active output
[brightness] skipping backlight 'ae96000.dsi.0' because it could not be matched to an active output
error: brightness control unavailable
```

`enable_ddcutil` does not help: DDC/CI does not reach these panels and `ddcutil detect` parses 0
candidate displays.

Pinned in `noctalia/config.toml.tmpl`:

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

`sync_all_monitors` sends every `brightness-set` to all mapped displays, so either Monitor-tab
slider moves both panels to the same percentage; the kernel gamma keeps them visually matched.
Noctalia still renders one card per panel — two sliders, locked together; a single card would need
an upstream change. Verified over IPC at 30/40/50/65/80 %: both sysfs nodes track, and reopening
the Monitor tab does not reset the value.
