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

Not managed here on purpose: the collection, media, backups and `prefs21.db`
(the latter holds the AnkiWeb `syncKey`, plus window geometry and UI scale).
Collection, deck presets, note types and FSRS parameters come from AnkiWeb sync.
