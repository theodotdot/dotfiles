// Ctrl+Tab like Firefox: tap = jump to the last used tab; hold Ctrl and keep
// tapping Tab / Shift+Tab to walk the most-recently-used list; release Ctrl to go.
//
// One copy sits in the layout as a 0px block and records tab history. Keys
// (keys.json): "ctrl-tab": "tab-mru.next", "ctrl-shift-tab": "tab-mru.prev".
// The first press opens this same mod as an overlay, which owns the Ctrl release.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, focused, run, props, theme, shared, setShared, openOverlay, closeOverlay, nextCommand, exec, appHome } from "herdr";

const SESSION = "tab-mru.session";
const SHOW_AFTER_MS = 180;
const IDLE_COMMIT_MS = 5000;
const ROW = 32;
const MAX_ROWS = 10;

function allTabs() {
  const out = [];
  const many = spaces().length > 1;
  for (const s of spaces())
    for (const t of s.tabs) out.push({ space: s.id, tab: t.id, name: t.name, spaceName: many ? s.name : "", status: t.status });
  return out;
}

function step(dir) {
  const s = shared(SESSION);
  if (!s) return;
  const now = Date.now();
  if (s.dir === dir && now - s.t < 15) return; // same key seen by the app and the overlay
  setShared(SESSION, { ...s, index: (s.index + dir + s.items.length) % s.items.length, t: now, dir, shown: true });
}

function finish(select) {
  const s = shared(SESSION);
  if (!s) return;
  setShared(SESSION, null);
  closeOverlay(s.overlay);
  const item = s.items[s.index];
  if (!select || !item) return;
  const f = focused();
  if (f?.space !== item.space) run("space.select", { id: item.space });
  run("tab.select", { id: item.tab });
}

export default class TabMru extends View {
  init(_props, cx) {
    if (props()?.overlay) return this.initOverlay(cx);
    this.history = JSON.parse(localStorage.getItem("mru") ?? "[]");
    cx.spawn(async (cx) => {
      for (;;) {
        const cmd = await nextCommand();
        if (cmd === "next" || cmd === "prev") this.press(cmd === "next" ? 1 : -1, cx);
      }
    });
  }

  record() {
    const tab = focused()?.tab;
    if (!tab || this.history[0] === tab) return;
    this.history = [tab, ...this.history.filter((id) => id !== tab)].slice(0, 200);
    localStorage.setItem("mru", JSON.stringify(this.history));
  }

  press(dir, cx) {
    const live = shared(SESSION);
    if (live && Date.now() - live.t < IDLE_COMMIT_MS + 500) return step(dir);
    if (live) finish(false);
    const tabs = allTabs();
    if (tabs.length < 2) return;
    const byId = new Map(tabs.map((t) => [t.tab, t]));
    const items = [];
    for (const id of this.history) if (byId.has(id)) items.push(byId.get(id));
    for (const t of tabs) if (!items.includes(t)) items.push(t);
    const current = focused()?.tab;
    const at = items.findIndex((t) => t.tab === current);
    if (at > 0) items.unshift(...items.splice(at, 1));
    const rows = Math.min(items.length, MAX_ROWS);
    const overlay = openOverlay({
      mod: "tab-mru",
      kind: "window",
      frame: "none",
      key: "tab-mru",
      width: 460,
      height: rows * ROW + 20,
    });
    const now = Date.now();
    setShared(SESSION, { items, index: dir > 0 ? 1 : items.length - 1, overlay, opened: now, t: now, dir: 0, shown: false });
    cx.spawn(async () => {
      // Key events can miss a quick Ctrl release (the overlay isn't focused yet), so ask the kernel.
      const r = await exec("python3", [`${appHome()}/mods/tab-mru/ctrl_wait.py`], { timeout: 130000 }).catch(() => null);
      if (r?.code === 0 && shared(SESSION)?.overlay === overlay) finish(true);
    });
  }

  initOverlay(cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.visible = false;
    cx.timer.every(16, (cx) => {
      const s = shared(SESSION);
      if (!s) return;
      if (!this.handle.is_focused()) this.handle.focus();
      const now = Date.now();
      if (now - s.t > IDLE_COMMIT_MS) return finish(true);
      if (!this.visible && (s.shown || now - s.opened >= SHOW_AFTER_MS)) {
        this.visible = true;
        cx.notify();
      }
    });
  }

  renderOverlay() {
    const s = shared(SESSION);
    if (!s) return div();
    const t = theme();
    const start = Math.max(0, Math.min(s.index - Math.floor(MAX_ROWS / 2), s.items.length - MAX_ROWS));
    const rows = s.items.slice(start, start + MAX_ROWS).map((item, i) => {
      const selected = start + i === s.index;
      return h_flex()
        .id(`mru-${item.tab}`)
        .h(ROW).px(12).gap(8).items_center().rounded(6)
        .when(selected, (el) => el.bg(t.selected))
        .on_click(() => {
          setShared(SESSION, { ...s, index: start + i });
          finish(true);
        })
        .child(div().text_color(t.dim).child(item.spaceName ? `${item.spaceName} /` : ""))
        .child(div().flex_1().truncate().text_color(selected ? t.foreground : t.muted).child(item.name));
    });
    return v_flex()
      .id("tab-mru")
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape") finish(false);
        else if (e.key === "tab") step(e.modifiers.shift ? -1 : 1);
        else if (e.key === "enter" || !e.modifiers.control) finish(true);
        else return;
        cx.stop_propagation();
      })
      .on_key_up((e) => {
        if (!e.modifiers.control) finish(true);
      })
      .on_modifiers_changed((e) => {
        if (!e.modifiers.control) finish(true);
      })
      .size_full()
      .p(10)
      .text_size(13)
      .when(this.visible, (el) => el.rounded(10).bg(t.popover).border_1().border_color(t.border).children(rows));
  }

  render(cx) {
    if (props()?.overlay) return this.renderOverlay();
    this.record();
    return div().w(0).h(0);
  }
}
