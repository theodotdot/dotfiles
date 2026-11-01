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

#### Zsh

[Antidote](https://getantidote.github.io/) is the plugin manager. Zsh config layout inspired by [antidote's zdotdir project](https://github.com/getantidote/zdotdir).  

|     Plugins                                                                                                       |     Others                                                                     |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **[mattmc3/ez-compinit](https://github.com/mattmc3/ez-compinit)**                                                 | **[starship prompt](https://starship.rs/)**                                    |
| **[zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions)**                                     | **[direnv](https://direnv.net/)**                                              |
| **[aloxaf/fzf-tab](https://github.com/Aloxaf/fzf-tab)**                                                           | **[jump](https://github.com/gsamokovarov/jump)**                               |
| **[lincheney/fzf-tab-completion](https://github.com/lincheney/fzf-tab-completion)**                               | **[zoxide](https://github.com/ajeetdsouza/zoxide)**                            |
| **[belak/zsh-utils/editor](https://github.com/belak/zsh-utils/tree/main/editor)**                                 | **[modified dbt completion](https://github.com/dbt-labs/dbt-completion.bash)** |
| **[belak/zsh-utils/history](https://github.com/belak/zsh-utils/tree/main/history)**                               |
| **[belak/zsh-utils/utility](https://github.com/belak/zsh-utils/tree/main/utility)**                               |
| **[ohmyzsh/ohmyzsh/extract](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/extract)**                     |
| **[zdharma-continuum/fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)**   |
| **[zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**                             |
| **[zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)**           |

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
arrows, A = left click, B = right click, X = Meta, Y = Meta+C, LB/RB = Alt+Left/Alt+Right,
LT/RT = held LeftCtrl/LeftShift, Start = play/pause, Select = Esc. The wheel mappings are
gone — the right stick scrolls. `~/.config/inputplumber/profiles/plasma-mobile.yaml` is
tracked as the same file so it can be `LoadProfilePath`-ed without root; keep it identical
to the bundle copy (that one is what `install.sh` writes to `/etc`).

### 🔆 Thor brightness

Plasma Mobile's shade does have a brightness slider, but it is a thin bar under the tile
grid and it can vanish for a whole session. `ScreenBrightnessUtil` reads `isValid()` of
PowerDevil's D-Bus object once, at construction, and its only notification path watches
`org.kde.Solid.PowerManagement.Actions.BrightnessControl` — a name nothing owns; the real
service is `org.kde.Solid.PowerManagement`. A Steam Game Mode round trip respawns the
session, plasmashell wins the race against powerdevil by ~3 s
(`Getting brightness failed: … "The name is not activatable"`), and the slider stays hidden
until the shell is restarted.

| Where | What |
|---|---|
| `~/.local/share/plasma/quicksettings/org.kde.plasma.quicksetting.brightness/` | Quick setting tile, first in the shade: `toggle()` cycles 100 → 75 → 50 → 25 → 10 % and wraps, `status` is the live percentage. It drives the same `ScreenBrightnessUtil` as the slider, so both panels move together. `available` is bound to `maxBrightness` (which notifies) instead of `brightnessAvailable` (which does not), and a 1.5 s retry re-fetches while PowerDevil is absent, so the tile heals itself after a late start. |
| `~/.config/systemd/user/plasma-plasmashell.service.d/10-wait-for-powerdevil.conf` | `ExecStartPre` that polls PowerDevil's brightness method (0.1 s steps, 6 s cap, failure ignored) so the shell only starts once `org.kde.Solid.PowerManagement` answers, and the slider is valid from the first frame. Deliberately **not** `After=`/`Wants=plasma-powerdevil.service`: that unit is `After=plasma-core.target`, which pulls plasmashell in, so the edge forms an ordering cycle — systemd breaks it by deleting the plasmashell start job, leaving a black screen with no shell. |

`run_onchange_enable-brightness-quicksetting.sh` keeps the tile first in
`[QuickSettings] enabledQuickSettings` of `~/.config/plasmamobilerc`. That file is shell
state (tile list, wizard flags, status bar scale are rewritten at runtime) and stays
unmanaged; the script only inserts the id when it is missing or not first.

#### Game Mode (gamescope)

Steam's slider does not go through PowerDevil. `steamclient.so`/`steamui.so` run

```
/usr/bin/steamos-polkit-helpers/steamos-priv-write /sys/class/backlight/<dev>/brightness <value>
```

and fall back to `echo <value> | sudo -n tee <path>` when that helper is missing. pocknix
ships the other `steamos-polkit-helpers` but not this one, so every slider step logged
`sudo[…]: deck : a password is required ; … COMMAND=/usr/bin/tee /sys/class/backlight/ae94000.dsi.0/brightness`
and nothing changed — and even with sudo it would have moved the wrong screen, because
Steam takes the first entry in `/sys/class/backlight` (`ae94000.dsi.0`, the 620×540 bottom
panel) while Game Mode runs on the top panel (DSI-2).

| Where | What |
|---|---|
| `pocknix/thor/steamos-priv-write` → `/usr/bin/steamos-polkit-helpers/steamos-priv-write` | Implements the SteamOS interface for the brightness path only: rescales the value from the panel Steam named into `ae96000.dsi.0` (what Armada calls `ARMADA_PRIMARY_BACKLIGHT`) and writes through logind `SetBrightness` — active-session authorised, no password — or straight to sysfs when it is writable. The bottom panel is left to `pocknix-brightness-sync` (below). `POCKNIX_BRIGHTNESS_DEVICE` overrides the target panel. |

#### Bottom panel curve

Plasma and Steam both put the two backlights on the *same percentage*, but the panels do not
share a curve — `type=raw`, `scale=unknown` for both — so at low levels the 620×540 bottom
panel (`ae94000.dsi.0`, 0..255) reads noticeably brighter than the top one
(`ae96000.dsi.0`, 0..3413). Measured before the fix: 3100/10000 on the PowerDevil scale left
the top at 1059/3413 (31 %) and the bottom at 79/255 (31 %), and it looked wrong.

| Where | What |
|---|---|
| `~/.config/scripts/pocknix-brightness-sync` + `pocknix-brightness-sync.service` | Follows `org.kde.ScreenBrightness.BrightnessChanged` and drives the bottom through `bottom = max_bottom · (top / top_max) ** GAMMA`, so it sits lower at low levels while both still reach full at 100 %. Only the bottom panel is written — kwin, PowerDevil and Steam stay authoritative for the screen being looked at. Survives Game Mode round trips (`WantedBy=default.target`, not `PartOf=graphical-session.target`); idle cost ~0.2 % CPU and no polling. |

`GAMMA` is a constant in the script (`2.2`). It is a judgement call, so it can be tuned live
without a restart: `echo GAMMA=2.5 > ~/.config/pocknix/brightness-sync.conf` is picked up on
the next change, and deleting the file returns to the built-in value. `POCKNIX_BRIGHTNESS_GAMMA`
overrides both for a one-off test. At 2.2, 40 % on the top panel puts the bottom at 34/255
instead of 102/255, and 31 % at 19/255 instead of 79/255.

Two things the implementation had to work around:

* kwin writes **both** panels and animates a slider drag over up to ~0.5 s (7 sysfs steps for
  a 10 %→100 % jump), and its signals can arrive before that animation rather than after it.
  Correcting on each signal, or a fixed wait after the last one, therefore lands mid-animation
  and gets overwritten. So the helper waits for the *value* to stop moving — 150 ms after the
  last signal, then every 120 ms until two reads agree — and applies the curve then. During a
  drag the bottom follows kwin; it settles once afterwards.
* the bottom's driver answers `EINVAL` on the sysfs write while still applying the value, so
  success is judged by reading the backlight back, with logind `SetBrightness` as fallback.

Game Mode is skipped entirely: while a `gamescope` process exists the bottom panel is not
written at all, because gamescope drives only the top panel and SteamOS has no dual-screen
support yet. Revisit when a patch makes the second screen usable there.




