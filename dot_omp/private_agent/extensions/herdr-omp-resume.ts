// Keep each herdr-core terminal labelled with the omp session it is running,
// so a pane that comes back as a shell after a reboot or core restart can
// resume the same conversation.
//
// The label (`omp.session=<absolute session file>`) is core's own durable
// per-terminal record: `terminal.label` saves before it replies and
// `recover_kept` does not clear labels, unlike argv/title/status. `herdr-omp-resume`
// reads the labels and types `omp --resume=<file>` into restored panes.
//
// A clean session shutdown removes the label, so a conversation the person
// quit does not reopen by itself. A crash or power loss leaves it behind on
// purpose: that is the case worth resuming.

import { spawnSync } from "node:child_process";

type Context = {
  hasUI?: unknown;
  sessionManager?: { getSessionFile?: () => unknown };
};

type Extension = {
  on: (event: string, handler: (event: unknown, ctx: Context) => void) => void;
};

const LABEL = "omp.session";

function absoluteSessionFile(ctx: Context | undefined): string | undefined {
  try {
    const file = ctx?.sessionManager?.getSessionFile?.();
    if (typeof file !== "string") return undefined;
    // POSIX or Windows absolute; `omp --resume` needs a real path.
    const absolute =
      file.startsWith("/") || /^[A-Za-z]:[\\/]/.test(file) || file.startsWith("\\\\");
    return absolute ? file : undefined;
  } catch {
    return undefined;
  }
}

function hc(args: string[]): string | undefined {
  for (const bin of ["hc", "/usr/bin/hc", "/usr/local/bin/hc"]) {
    const r = spawnSync(bin, args, { encoding: "utf8", timeout: 3000 });
    if (r.error) continue;
    return r.status === 0 ? r.stdout.trim() : undefined;
  }
  return undefined;
}

function labelOf(info: string): unknown {
  let parsed: unknown;
  try {
    parsed = JSON.parse(info);
  } catch {
    return undefined;
  }
  if (!parsed || typeof parsed !== "object" || !("labels" in parsed)) return undefined;
  const labels = parsed.labels;
  if (!labels || typeof labels !== "object" || !(LABEL in labels)) return undefined;
  return labels[LABEL];
}

export default function (pi: Extension) {
  let recorded: { terminal: string; file: string } | undefined;

  const record = (_event: unknown, ctx: Context) => {
    const terminal = process.env.HC_TERMINAL_ID;
    // hasUI: subagents and workers share the terminal but are not the pane's
    // conversation; only the interactive root session owns the label.
    const file = terminal && ctx?.hasUI === true ? absoluteSessionFile(ctx) : undefined;
    recorded = undefined;
    if (!terminal || !file) return;
    if (hc(["label", terminal, `${LABEL}=${file}`]) === undefined) return;
    recorded = { terminal, file };
  };

  pi.on("session_start", record);
  pi.on("session_switch", record);

  pi.on("session_shutdown", () => {
    if (!recorded) return;
    const info = hc(["get", recorded.terminal, "--json"]);
    if (info === undefined) return;
    // A newer session in the same pane may already own the label.
    if (labelOf(info) !== recorded.file) return;
    hc(["label", recorded.terminal, `${LABEL}=`]);
  });
}
