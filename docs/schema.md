# Schema — Ka0s Premade Groups Filter Extension

SavedVariables: `PremadeGroupsFilterExtensionDB` (AceDB) and `PremadeGroupsFilterExtensionPerfDB`
(the perf capture ring, owned by `LibKa0s-Perf-1.0`). Defaults live in `defaults/Profile.lua` and are
assembled by `Settings.BuildDefaults` in `settings/Schema.lua`.

## `profile` (per AceDB profile)

| Key | Default | Written by |
|---|---|---|
| `enabled` | `true` | The write seam: the *Enable* row, `/pgfe enable|disable`, the launcher menu |
| `panelCollapsed` | `false` | `modules/Panel.lua` (the collapse button), plan Task 8 |

## `char` (per character)

| Key | Default | Notes |
|---|---|---|
| `filters.keyTargeting` | `true` | Tick untimed dungeons on Apply |
| `filters.keyLevel` | `10` | Integer 2–40 |
| `filters.regionsEnabled` | `false` | |
| `filters.regions` | `{}` | Set: `{ oce = true, chi = true }` |
| `filters.noSameSpec` | `false` | |
| `filters.noSameClassRole` | `false` | |
| `filters.experiencedLeader` | `false` | |
| `filters.maxAgeEnabled` | `false` | |
| `filters.maxAge` | `15` | Minutes, integer 1–240 |

Owner: `modules/Filters.lua`; `Presets.Load` copies a preset in place.

## `global`

| Key | Default | Notes |
|---|---|---|
| `schemaVersion` | `0` | Never the current version (savedvariables-§1); the runner stamps it |
| `presets` | `{}` | `[name] = <copy of char.filters>`; owner `modules/Presets.lua` |
| `minimap` | `{ hide = false }` | LibDBIcon's own table; the *Minimap button* row inverts `hide` |

Session-only, never stored: `NS.State.debug` (the console's logging flag).

## Migrations

`NS.SCHEMA_VERSION = 1`. Steps in `core/Database.lua`'s `NS.MIGRATIONS`, run by `NS:RunMigrations()`
right after `AceDB:New` and on every profile event.

| Step | What it does |
|---|---|
| 0 → 1 | The stamp itself; nothing to reshape |
