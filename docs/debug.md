# Debug — Ka0s Premade Groups Filter Extension

## The console

`LibKa0s-DebugLog-1.0` (`core/DebugLogSetup.lua`). `/pgfe debug` toggles the window;
`/pgfe debug on|off` toggles logging. The logging flag is session-only (`NS.State.debug`, off after
every `/reload`) and independent of the window, so a bug can be reproduced with the window closed.
Lines are written with `NS.Debug(tag, fmt, ...)`; the library writes its own `[Cmd]`, `[Cfg]`,
`[Launcher]` and `[Lifecycle]` lines. The EllesmereUI skin writes `[Skin]` lines: the callback,
one `applied: N widgets` summary, and a `skipped: <reason>` line each time the reason changes. The `[Init]` summary (name, version, schema, profile, enabled,
PremadeRegions) lands when logging is turned on.

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
| `dependencies` | Whether PGF's namespace, dialog and dungeon panel exist; whether PremadeRegions is loaded; the EllesmereUI skin's four gate conditions and its state (registered, facade held, wanted, applied) |
| `registration` | The feature events this build registers, and any the client rejected |
| `launcher` | Whether the launcher is registered and the minimap button shown |

What it does not do: it reads state only. It takes no hold, registers no event, starts no timer,
writes no SavedVariable and calls no PGF function.
