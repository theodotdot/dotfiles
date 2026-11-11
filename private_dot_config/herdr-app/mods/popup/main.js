// Floating shell per space, shown as a peek (the only overlay whose terminal
// takes the keyboard). Bound to `mod.open:popup`: opens the space's shell, or
// closes it when it was opened by this key. Closing with the ✕ leaves that flag
// stale, so the next press closes nothing and the one after opens it. Opening the mod itself is only
// the trigger; it closes its own overlay at once.

import { View, div } from "gpui-kit";
import { terminals, spaces, focused, hc, run, props, closeOverlay, shared, setShared } from "herdr";

async function terminalFor(space) {
  const name = `pp-${space.id.replace(/\W/g, "").slice(-24)}`;
  const known = terminals().find((t) => t.name === name && t.state !== "finished");
  if (known) return known.address;
  const args = ["run", "--bg", "--json", "--no-parent", "--outlive-parent", "--name", name];
  if (space.folder) args.push("--cwd", space.folder);
  const r = await hc(args);
  if (r.code !== 0) throw new Error(r.stderr || r.stdout);
  return JSON.parse(r.stdout).address;
}

export default class Popup extends View {
  init(_props, cx) {
    if (!props()) return;
    const overlay = props().overlay;
    const f = focused();
    const space = spaces().find((s) => s.id === f?.space);
    if (!space) return closeOverlay(overlay);
    cx.spawn(async (cx) => {
      try {
        const terminal = await terminalFor(space);
        closeOverlay(overlay);
        const shown = { ...(shared("popup.shown") ?? {}) };
        if (shown[space.id]) {
          delete shown[space.id];
          run("overlay.close");
        } else {
          shown[space.id] = true;
          run("terminal.peek", { terminal });
        }
        setShared("popup.shown", shown);
      } catch (e) {
        closeOverlay(overlay);
      }
    });
  }

  render() {
    return div();
  }
}
