# Thor brightness — handoff for the kernel-patch session

State as of 2026-11-01, `thor` branch. Everything below was measured on this machine unless
marked as coming from an upstream issue.

## The problem in one paragraph

The AYN Thor's two panels are backlit to the **same raw percentage** by every brightness
owner, but the panels do not produce the same light at the same percentage: at low levels the
620×540 bottom panel is clearly brighter than the 1920×1080 top one. Plasma (PowerDevil →
kwin) writes both nodes; Steam writes one. There is no calibration hook anywhere in the chain,
so the only place a curve can live — once — is the panel driver, or the code that fans a
single request out to two nodes. Trying to fix it from a user process after the fact produces
a visible flash, because one write to the bottom node costs ~33 ms.

## Hardware and driver map

| | Top panel | Bottom panel |
|---|---|---|
| DRM connector | DSI-2 (`mdss_dsi1`) | DSI-1 (`mdss_dsi0`) |
| Backlight node | `/sys/class/backlight/ae96000.dsi.0` | `/sys/class/backlight/ae94000.dsi.0` |
| `max_brightness` | 3413 | 255 |
| Panel driver | `panel-chipone-icna35xx` | `panel-ddic-ch13726a` (AMOLED) |
| Driver build | builtin (`modules.builtin`) | builtin (`modules.builtin`) |
| Kernel package | `linux-pocknix-sm8550 7.2.10-13`, `uname -r` 7.2.10 | same |

* Both nodes report `type=raw`, `scale=unknown`. No `brightness-levels` anywhere in
  `/proc/device-tree`. So neither the backlight class nor the device tree offers a curve.
* `modinfo panel-ddic-ch13726a` → `filename: (builtin)`; the `.ko` under
  `/lib/modules/7.2.10/kernel/drivers/gpu/drm/panel/` is a stub. This is a **kernel rebuild**,
  not a module swap.
* Armada's device config for the same hardware (`system_files/usr/lib/armada/devices/ayn-thor.conf`)
  agrees on the mapping: `ARMADA_PRIMARY_BACKLIGHT=ae96000.dsi.0`,
  `ARMADA_SECONDARY_BACKLIGHT=ae94000.dsi.0`, primary connector DSI-2.

## How a brightness change flows today

1. Plasma: PowerDevil's Linux backlight helper **merges every raw backlight node into one
   device** — it lists them by name in reverse (`ae96000` sorts first), reads
   brightness/max/syspath from the first, and writes every node scaled by
   `node_max / first_max`. That merged device is handed to kwin as an internal display with
   no EDID; kwin's `Workspace::assignBrightnessDevices()` gives it to the first internal
   output and every other output gets none (pocknix #152 has the code references).
2. kwin then **animates**: a 10 %→100 % jump is 7 sysfs writes over 421 ms; a 30 %→50 % jump
   is 3 writes over 258 ms. It emits
   `org.kde.ScreenBrightness.BrightnessChanged(display, brightness, "", "")` per display, and
   the signal precedes its own write of the bottom node.
3. Game Mode: Steam writes the **first** backlight node directly (`ae94000.dsi.0`, the bottom
   one — dark in Game Mode) and only falls back to
   `/usr/bin/steamos-polkit-helpers/steamos-priv-write <path> <value>` if that write fails
   (pocknix #80). The write does fail with `errno 22` on this hardware — see the EINVAL note
   below — so both paths can run.

## Measurements that matter for a driver-side fix

Same percentage, different light — this is the defect:

```
PowerDevil 3100/10000  →  top 1059/3413 (31 %)   bottom 79/255 (31 %)
```

Cost of a write, which is the entire reason a user-space correction flashes:

```
write /sys/class/backlight/ae94000.dsi.0/brightness : 32.91 ms   (20 writes, DSI round trip)
read  …/brightness                                  :  0.03 ms
```

The bottom driver **returns `EINVAL` from the sysfs write while still applying the value**
(matches #80's `errno = 22`). Any code that trusts the write's return status — Steam's
sysfs fast path included — will think it failed.

Perceptual curve, dialled in by eye on this unit (top panel = reference):

```
bottom = round(bottom_max · (top / top_max) ** 2.7)
   20 % → 3/255      31 % → 11/255      40 % → 22/255      100 % → 255/255
```

Gamma 1.6 and 2.0 were still too bright; 2.2 close; **2.7 is the number the user settled on**.
Treat it as a per-panel/per-unit value, not a constant of the universe — cf. pocknix #131
(per-unit panel calibration) and Armada #202, where AYN shipped its own adjustment after
release ("sets both screens to a similar brightness level instead of just matching the
percentage").

## What userspace tried, and why it cannot win

`~/.config/scripts/pocknix-brightness-sync` (this repo, chezmoi-managed, **currently
disabled**: `systemctl --user disable --now pocknix-brightness-sync`) subscribes to kwin's
`BrightnessChanged`, reads the top node, and rewrites the bottom node with the gamma above.

It gets the final value right — verified at every level — but every variant flashes:

| Variant | Result |
|---|---|
| 200 ms polling | bottom visibly strobes during a drag |
| settle after the burst | bottom stays bright for the whole animation, then drops |
| chase (re-apply every 5 ms during the burst) | fleet of short blips, 17–34 ms each |

The cause is not the scheduling: kwin writes the bottom linearly, and the correcting write
costs 33 ms on the same DSI link, so it can never land in the same frame. Two writers cannot
coexist on one 33 ms sysfs attribute without a visible transient. Any fix has to collapse it
to **one** write.

## Candidate fixes, in order of preference

### 1. Per-panel gamma inside the bottom panel driver (recommended)

`panel-ddic-ch13726a`'s brightness path (`set_brightness` / `backlight_ops.update_status`)
would map the incoming level through the curve before writing the panel register:

```
raw = round(max · (level / max) ** gamma)
```

Consequences:

* every writer becomes correct at once — PowerDevil/kwin, Steam, plain `echo` — with a single
  write, so **no flash anywhere**, and no user-space daemon;
* the sysfs range stays 0..255, so nothing in userspace has to change (kwin keeps writing
  percentages, reads back what it asked for);
* must be applied on every path that writes the register, including resume/restore, or the
  panel jumps brightness after suspend;
* make it a **per-device property**, not a compile-time constant, because it is per panel and
  probably per unit: either a device-tree property handled by the driver (e.g.
  `panel,brightness-gamma = <2700>;` on the ch13726a node) or a board-data table next to the
  existing panel quirks. pocknix #131 is the precedent for board-data-driven panel
  calibration.
* the top panel needs nothing: it is the reference.

### 2. Apply the ratio in PowerDevil's helper instead (image patch, no kernel)

PowerDevil already fans one request out to both nodes with `node_max / first_max`
(pocknix #152). Replacing that per-node scale with the measured curve would fix Plasma with a
single write as well — no flash, no daemon — but:

* it does nothing for Game Mode, where Steam writes sysfs directly;
* it bakes the two-panel coupling deeper in, when the real goal is independent panels.

Worth it only as a stopgap if a kernel rebuild is too slow.

### 3. Device-tree `brightness-levels`

Rejected: that is a `pwm-backlight` binding, and these panels are DCS/AMOLED panels driven
through the DRM panel driver, not PWM backlights. There is no `brightness-levels` consumer in
these drivers.

## What already exists in this repo, and what to delete afterwards

| Path | Role | Fate once the driver carries the curve |
|---|---|---|
| `pocknix/thor/steamos-priv-write` → `/usr/bin/steamos-polkit-helpers/steamos-priv-write` | Answers Steam's pkexec fallback: rescales the value from the node Steam named onto `ae96000.dsi.0` (logind `SetBrightness`, no password), so Game Mode's slider moves the top panel | Keep only if the driver fix does not also make Game Mode target the right panel; with the gamma in the driver this helper only needs the *panel redirection*, not the curve |
| `~/.config/scripts/pocknix-brightness-sync` + `pocknix-brightness-sync.service` + `run_after_enable-brightness-sync.sh` | The user-space gamma described above | **Delete** — delete the three files, `systemctl --user disable --now pocknix-brightness-sync`, `chezmoi apply` |
| `~/.local/share/plasma/quicksettings/org.kde.plasma.quicksetting.brightness/` | Quick-setting tile (cycles 100/75/50/25/10 %) | Unrelated to this defect; keep |

Both the helper and the tile are documented in `README.md` under `🔆 Thor brightness`.

## Verification commands for the kernel session

```sh
# what the panels are doing right now
for f in /sys/class/backlight/*/brightness; do echo "$f = $(cat $f)"; done

# drive both panels the way Plasma does
busctl --user call org.kde.Solid.PowerManagement \
  /org/kde/Solid/PowerManagement/Actions/BrightnessControl \
  org.kde.Solid.PowerManagement.Actions.BrightnessControl setBrightness i 3100

# write one panel by hand (returns EINVAL on the bottom one, still applies)
printf '%s' 11 > /sys/class/backlight/ae94000.dsi.0/brightness || true
cat /sys/class/backlight/ae94000.dsi.0/brightness

# write latency, the reason user space cannot fix the flash
python3 - <<'PY'
import time
p = "/sys/class/backlight/ae94000.dsi.0/brightness"
t = time.perf_counter()
for _ in range(20):
    open(p, "w").write("20")
print(f"{(time.perf_counter()-t)/20*1000:.2f} ms per write")
PY

# kwin's animation cadence (7 steps / ~421 ms for a 10 %→100 % jump)
python3 /dev/stdin <<'PY'
import time
top = "/sys/class/backlight/ae96000.dsi.0/brightness"
last, t0 = None, time.time()
while time.time() - t0 < 2:
    v = open(top).read().strip()
    if v != last:
        print(f"{time.time()-t0:.3f} {v}"); last = v
    time.sleep(0.002)
PY
```

Note `powerdevil 6.8.1-2` and `kwin 6.8.2-1` are what run here today; pocknix #152 and #108
were written against the 6.7.4 base, so re-check the merge helper before relying on its
details verbatim.

## Open questions

1. Is the 2.7 exponent the panel's, the driver's, or this unit's? Two Thor units agreeing
   would settle it. Armada #202 suggests AYN adjusted the mapping device-wide.
2. Where does the curve belong for the *top* panel — reference (no change) or should the pair
   be normalised against a nominal panel? Reference is simpler and matches what the user sees.
3. Does a driver-side curve interact with the darkness floor in pocknix #108
   (`knownSafeMinBrightness()` = 0, panels go black at the bottom of the slider)? With gamma
   2.7 a requested 1 % lands on 0/255 — the floor issue gets *worse* at the low end unless the
   curve has a minimum, so pick a floor (Armada uses `ARMADA_BACKLIGHT_MIN=0.01`) as part of
   the same patch.
4. Game Mode still targets the bottom node (#80). Even with the curve, Steam's slider moves
   the wrong panel; that is a separate fix (either the driver/board declaring the top node
   first, or keeping `steamos-priv-write`'s redirection).

## References

Upstream, same hardware, useful context:

* pocknix #152 — *thor: Plasma brightness drives both panels*: PowerDevil node merge,
  kwin `assignBrightnessDevices()`, Display-Settings slider path. ·
  https://github.com/shuuri-labs/pocknix-os/issues/152
* pocknix #80 — *thor: Steam brightness slider drives the bottom panel's backlight*: Steam's
  sysfs-first / pkexec-fallback order, `errno = 22`. ·
  https://github.com/shuuri-labs/pocknix-os/issues/80
* pocknix #108 — *desktop: Plasma's lowest brightness turns built-in panels off*:
  `knownSafeMinBrightness()` returns 0, floor proposal `maxBrightness()/20`. ·
  https://github.com/shuuri-labs/pocknix-os/issues/108
* pocknix #131 — *display: per-unit panel refresh calibration*: precedent for board-data
  driven panel parameters. · https://github.com/shuuri-labs/pocknix-os/issues/131
* pocknix #68 — *devices: AYN Thor support (dual screen)*. ·
  https://github.com/shuuri-labs/pocknix-os/issues/68
* armada #202 — *brightness differentiation between screens on the combined slider*: "sets the
  same brightness to both", AYN shipped a corrected mapping after release. ·
  https://github.com/armada-os/armada/issues/202
* armada #563 — *Can't adjust bottom screen brightness in desktop mode*: Armada Control's
  slider fights kwin's. · https://github.com/armada-os/armada/issues/563
* armada #78 / #375 — Thor second screen support, userspace and Plasma Mobile. ·
  https://github.com/armada-os/armada/issues/78 · https://github.com/armada-os/armada/issues/375

Code worth reading before patching:

* Armada's Steam-facing helper, which already carries a gamma knob (default 1) and maps a
  request onto the primary panel only:
  `system_files/usr/bin/steamos-polkit-helpers/steamos-priv-write` and
  `system_files/usr/libexec/armada/steam-backlight-value`
  (`ARMADA_BACKLIGHT_GAMMA`, `ARMADA_BACKLIGHT_INPUT_MIN`, `ARMADA_BACKLIGHT_MIN=0.01`).
* Armada's device mapping: `system_files/usr/lib/armada/devices/ayn-thor.conf`.
