# Schema — Ka0s Premade Groups Filter Extension

SavedVariables: `PremadeGroupsFilterExtensionDB` (AceDB), the one global the TOC declares. There is
no perf capture ring: the addon holds the performance-§12 exemption. Defaults live in `defaults/Profile.lua` and are
assembled by `Settings.BuildDefaults` in `settings/Schema.lua`.

## `profile` (per AceDB profile)

| Key | Default | Written by |
|---|---|---|
| `enabled` | `true` | The write seam: the *Enable* row, `/pgfe enable|disable`, the launcher menu |
| `panelCollapsed` | `false` | `modules/Panel.lua` `setCollapsed` (the panel's minimize/maximize button and header strip), outside the write seam: the architecture-§5 row in `docs/ARCHITECTURE.md` -> `## Documented deviations` |
| `filtersActive` | `true` | The write seam: *Use the extension's filters* on the General page's *Filters* tab, the panel's first box, `/pgfe set filtersActive`. Its onChange (`Apply.OnFiltersToggled`) removes or rewrites the managed block. Off: Apply refuses (`MSG_INACTIVE`) and `pgfe_on` is false. Separate from `enabled`; not in presets |
| `showRegionTags` | `true` | The write seam: *Show region tags in the Group Finder*, leading the General page's *Region tags* tab, `/pgfe set showRegionTags`. Read by `modules/RegionTags.lua` on every row paint |
| `regionColors.<key>` | per key, `defaults/Profile.lua` `REGION_HEX` | The write seam: one color picker per region (`oce`, `la`, `chi`, `mex`, `bzl`, `eng`, `ger`, `fra`, `ita`, `spa`, `por`, `rus`) on the General page's *Region tags* tab, its *Reset region tag colors* button (`Settings.ResetRegionColors`, one bulk act), `/pgfe set regionColors.<key> r g b` (0–1 or 0–255). Stored `{ r, g, b, a }` (0–1; alpha unused). Read by `modules/RegionTags.lua` `Hex`, cached per stored table. Additive key: no migration |

## `char` (per character)

| Key | Default | Notes |
|---|---|---|
| `filters.keyTargeting` | `true` | Tick untimed dungeons on Apply |
| `filters.keyLevel` | `10` | Integer 2–40. With `smartKeyLevel` on, written by `Filters.ApplySmartLevel` |
| `filters.smartKeyLevel` | `true` | On: the addon sets `keyLevel` to the lowest best timed level across the season dungeons + 1 (never timed = 0), clamped 2–40, and the panel's level box is locked. Recomputed on panel refresh, on season-data events and at the start of Apply; with no season data the stored level stands |
| `filters.regionsEnabled` | `true` | On with Any selected for the portal (none, or all of them): no region clause (every region passes) |
| `filters.regions` | `{}` | Set: `{ oce = true, chi = true }`. Ticking the portal's last unticked region stores Any (clears that portal's keys) |
| `filters.playstyleEnabled` | `true` | On with Any (none or all ticked): no playstyle clause (every playstyle passes) |
| `filters.playstyles` | `{}` | Set over `learning`, `relaxed`, `competitive`, `carry`. Ticking the last unticked one stores Any (empty set) |
| `filters.compositionEnabled` | `true` | The Composition row's box; the two below apply only while it is on |
| `filters.noSameSpec` | `false` | Composition dropdown entry |
| `filters.noSameClassRole` | `false` | Composition dropdown entry |
| `filters.experiencedLeader` | `false` | |
| `filters.maxAgeEnabled` | `false` | |
| `filters.maxAge` | `15` | Minutes, integer 1–240 |

Owner: `modules/Filters.lua`; `Presets.Load` copies a preset in place. Written by the attached panel's
controls outside the write seam: the architecture-§5 row in `docs/ARCHITECTURE.md` -> `## Documented
deviations` names every writer.

`char.selectedPreset` (no default): the name the panel's preset dropdown shows as selected, kept
across reloads and logins. It is the `global.presets` registry's current-member pointer
(architecture-§5, standard v2.82.0), owned by the registry writer `modules/Presets.lua`:
`Presets.Save` and `Presets.Load` set it, `Presets.Delete` clears it, and `Presets.GetSelected` reads
a name gone from `global.presets` as none.

## `global`

| Key | Default | Notes |
|---|---|---|
| `schemaVersion` | `0` | Never the current version (savedvariables-§1); the runner stamps it |
| `presets` | `{}` | `[name] = <copy of char.filters>`; owner `modules/Presets.lua` |
| `minimap` | `{ hide = false }` | LibDBIcon's own table; the *Minimap button* row inverts `hide` |

Session-only, never stored: `NS.State.debug` (the console's logging flag).

## Migrations

`NS.SCHEMA_VERSION = 2`. Steps in `core/Database.lua`'s `NS.MIGRATIONS`, run by `NS:RunMigrations()`
right after `AceDB:New` and on every profile event.

| Step | What it does |
|---|---|
| 0 → 1 | The stamp itself; nothing to reshape |
| 1 → 2 | The skinning rollout's PG-06: every profile's `euiSkin` (the retired EllesmereUI bridge's switch, default `true`) is carried to `skin.source = "eui"` when it was not an explicit `false` and EllesmereUI is present (the library provider's `eui` condition at `OnInitialize`), then deleted. Walks `db.sv.profiles` raw, so an absent key reads as the old default |
