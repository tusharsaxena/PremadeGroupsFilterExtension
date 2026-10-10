# Debug — Ka0s Premade Groups Filter Extension

## The console

`LibKa0s-DebugLog-1.0` (`core/DebugLogSetup.lua`). `/pgfe debug` toggles the window;
`/pgfe debug on|off` toggles logging. The logging flag is session-only (`NS.State.debug`, off after
every `/reload`) and independent of the window, so a bug can be reproduced with the window closed.
Lines are written with `NS.Debug(tag, fmt, ...)`; the library writes its own `[Cmd]`, `[Cfg]`,
`[Launcher]` and `[Lifecycle]` lines. The EllesmereUI skin writes `[Skin]` lines: `EllesmereUI called back (apiVersion <n>)`,
one `applied: N widgets` summary, `paint failed: <error>` when a paint raises (latched, never retried), and a
`skipped: <reason>` line each time the reason changes. The `[Init]` summary (name, version, schema, profile, enabled,
PremadeRegions) lands when logging is turned on.

## Tag vocabulary

The addon's own feature lines, by tag. Each flow writes one line per outcome; the per-result PGF
env hook (`EnvInject.Apply`) and the Blizzard row painters write nothing.

| Tag | Written by | Lines |
|---|---|---|
| `Apply` | `modules/Apply.lua` `Run`, `OnFiltersToggled` | `refused: MSG_X` for every refusal (`MSG_NO_PGF` adds `(missing <seam>)`); on success `wrote <N\|untouched> dungeon rows, <n> expr chars, range <N-N\|nil>`, then `search` only with `opts.search`, then `ok: MSG_X`; `filters toggled on\|off` |
| `Clear` | `modules/Apply.lua` `Clear` | `refused: MSG_X`; on success `wrote <n> expr chars`, then `ok: MSG_CLEARED` |
| `Panel` | `modules/Panel.lua` `UpdateVisibility` | `shown` / `hidden`, on a change only (`DebugChanged` key `panel.vis`); the stand-down re-arms the key, so the stand-up's `shown` is written |
| `Preset` | `modules/Presets.lua` | `saved '<name>'`, `loaded '<name>'`, `deleted '<name>'`, `delete '<name>': absent`, `save refused: badName`, `load '<name>' refused: missing` |
| `Env` | `modules/EnvInject.lua` `RefreshPlayer` | `spec=<keyword> classRole=<keyword>`, on a change only (`DebugChanged` key `env.spec`); `env hook not installed: <reason>` at load |
| `Init` | `core/PGFE.lua` `OnEnable` | `PGF seams ok\|missing <seam>; PremadeRegions loaded\|absent; hooks env= dialog= searchRow= applicantRow=` (`DebugAtEnable`: held until logging is turned on), beside the library's session summary |
| `Profile` | `core/PGFE.lua` `OnProfileChanged` | `switched to '<name>'` |
| `Set` | `core/PGFE.lua` `OnProfileCopied` / `OnProfileReset`; `settings/Schema.lua` `RestoreAllDefaults` | `copied profile '<src>' → '<dst>'`; `reset profile '<name>' to defaults (<n> rows)` (without the count when none was taken); `reset profile '<name>' to defaults (stopped by an error)` |

## The diagnostics report (debug-logging-§14)

Two forms and no third: `/pgfe diagnostics` and `/pgfe debug diagnostics` (also the console's orange
**Diagnostics** link). Both run while the addon is disabled. A run **turns debug logging on for the
session** when it is off (the library does it; the descriptor does not opt out), **appends** after
whatever the console already holds and never clears, and is capped by the library.

The library writes the markers (`Ka0s Premade Groups Filter Extension`), the identity header's
library half and a `pcall` per section. The addon's sections (`modules/Diagnostics.lua`):

| Section | Reports |
|---|---|
| `identity` | Stored and code schema version, profile, `enabled`, stood down, the latch's holds |
| `settings` | Every schema row that differs from its default (`enabled` always) |
| `filters` | The character's filter options: the scalars as one sorted `key=value` list, then each set (`regions`, `playstyles`) as its sorted keys, an empty set reading `Any` |
| `dependencies` | Whether PGF's namespace, dialog and dungeon panel exist; the PGF seams `Bridge.Check` reads (`ok`, and the first one `missing`); which hooks went in (`env`, `dialog`, `searchRow`, `applicantRow`); whether PremadeRegions is loaded; the EllesmereUI skin's four gate conditions and its state (registered, facade held, wanted, applied) |
| `registration` | The feature events this build declares (`feature events (declared)`, printed even while stood down), whether they are registered right now (`registered=false` while stood down), and any the client rejected |
| `launcher` | Whether the launcher is registered and the minimap button shown |

What it does not do: it reads state only. It takes no hold, registers no event, starts no timer,
writes no SavedVariable and calls no PGF function.
