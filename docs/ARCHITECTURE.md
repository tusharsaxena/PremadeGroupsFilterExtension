# Architecture — Ka0s Premade Groups Filter Extension

The engineer brief and the hub of the doc set (documentation-§3). Each section summarizes and links
to its topic doc; the full register is [Documentation map](#documentation-map).

## Overview

A companion addon to **Premade Groups Filter** (PGF) that adds Mythic+ conveniences PGF does not
have: target every dungeon the player has not timed at a chosen key level, filter by the leader's
server region, exclude groups that already hold the player's spec or class-and-role, ask for an
experienced leader, cap the listing age, and keep named presets. It does **not** filter on its own:
it writes PGF's dungeon checkboxes and PGF's Advanced Filter Expression, and injects two variables
into PGF's per-result filter environment through one `hooksecurefunc`. Apply then clicks PGF's
search button inside the hardware event.

Built to the Ka0s WoW Addon Standard: Ace3, vendored `LibKa0s` v1.71.0 (one setup file per adopted
major), schema-driven master settings, the launcher, one stand-down latch, headless tests and
luacheck. Retail only (`## Interface: 120100`). The design is
[`superpowers/specs/2026-10-09-m-plus-v0.1-design.md`](superpowers/specs/2026-10-09-m-plus-v0.1-design.md)
and the build plan
[`superpowers/plans/2026-10-09-m-plus-v0.1.md`](superpowers/plans/2026-10-09-m-plus-v0.1.md).

**State at the scaffold (plan Task 1).** Every setup file, the master settings and the harness are
live; the feature modules are stubs that publish their namespace table, each filled by the plan task
named in its header.

## Contracts later tasks build on

Recorded here because the plan names them provisionally.

| What | Exact name | Notes |
|---|---|---|
| Stand-down accessor | **`NS.IsStoodDown()`** | Published by `core/LifecycleSetup.lua`; true while any hold (`disabled`, `perf`) is taken. The plan's provisional `NS.Lifecycle:IsStoodDown()` does not exist: use `NS.IsStoodDown()` (or `NS.Lifecycle:IsDown()`). Every hook body returns at once when it answers true. |
| Disabling in a test | `NS.addon:OnSlashCommand("disable")`, or `NS.addon.Settings.Helpers.Set("enabled", false)` | Both go through the write seam to the latch. **`NS.addon:Disable()` is not the stand-down** (that is AceAddon's, and the kit fake does not model it). |
| Test factories | **`T.newAddon(opts)`**, **`T.bootAddon(opts)`**, **`T.enableAddon(opts)`** on `local T = _G.PGFE_TEST` | Each returns `(NS, env, mock)`, env and mock the same table. `newAddon`: files loaded. `bootAddon`: + `OnInitialize` (db, migrations). `enableAddon`: + `OnEnable` (events, settings category, launcher, latch). |
| Factory `opts` | `currentRegion`, `realmName`, `mapTable`, `specID`, `role`, `classFile`, `inCombat` seed the mock; `skip` (file list), `mock` (fn), `addonName` | See `tests/loader.lua`. |
| Mock fields | `currentRegion`, `realmName`, `mapTable`, `mapUIInfo`, `seasonBest`, `specID`, `role`, `classFile`, `inCombat`, `fireEvent(name, ...)`, `pgf`, `hooks`, `prints` | `tests/wow_mock.lua`; `hooksecurefunc` is a real post-hook. Assigning a mock key sets that global (`m.PremadeRegions = {...}`). |
| PGF fake | `tests/pgf_fake.lua` (the plan's Task 6 fake, verbatim) | Installed by the mock builder before any addon file loads; handle at `mock.pgf`. |
| Slash registry | `NS.COMMANDS` (positional triples) and `NS.SlashCommands` (the dispatcher) | Task 7 appends `apply` and `clear` rows to `NS.COMMANDS` before the dispatcher is built, or inserts them in `settings/Slash.lua`'s table. |
| Feature events | append `{ "EVENT", "MethodName" }` to `NS.FEATURE_EVENTS` at file load | `core/PGFE.lua` registers the list on enable and stand-up and unregisters it on stand-down. Teardown/rebuild steps go in `NS.STAND_DOWN` / `NS.STAND_UP`. |
| Spec readers | `NS.Compat.GetSpecialization()`, `NS.Compat.GetSpecializationInfo(i)` | `core/Compat.lua`, through `LibKa0s-Compat-1.0`; use these rather than the bare globals. |
| Defaults | `NS.C.PROFILE`, `NS.C.CHAR_DEFAULTS`, `NS.C.GLOBAL_DEFAULTS` | `defaults/Profile.lua`; db at `NS.addon.db` (== `NS.db`). |
| Perf bucket | declare `{ key = "envInject" }` in `core/PerfSetup.lua` in the change that brackets the env hook | No bucket is declared until a bracket reaches it (performance-§3). |

## Module Map

Single modular layout (`core/ defaults/ locales/ modules/ settings/`). Load order is the TOC's:
libraries → `locales/enUS.lua` → the `core/` setup files → `core/PGFBridge.lua` → `defaults/` →
`modules/` → `settings/`, with every load-bearing position annotated at its TOC line. Full per-file
table and the load-order reasoning: [`module-map.md`](module-map.md).

`LibKa0s` majors wired, one setup file each: Core (`core/CoreSetup.lua`), Media
(`core/MediaSetup.lua`), Compat (`core/Compat.lua`), Env (`core/EnvSetup.lua`), DebugLog
(`core/DebugLogSetup.lua`), Launcher (`core/LauncherSetup.lua`), Lifecycle
(`core/LifecycleSetup.lua`), Perf (`core/PerfSetup.lua`), Schema (`settings/SchemaSetup.lua`), Options
(`settings/OptionsSetup.lua`), Slash (`settings/Slash.lua`). Vendored and not wired: Bus, Pool, Item,
Widgets. Ace3, LibSharedMedia, LibDataBroker and LibDBIcon are vendored under `libs/` too
(`DEPENDENCIES.md`).

## Settings Schema

Three AceDB scopes on `PremadeGroupsFilterExtensionDB`; full shape and defaults in
[`schema.md`](schema.md).

- **Schema rows (the write seam).** The Master controls block (`enabled`, `state.debugConsole`,
  `global.minimap.shown`), composed by `LibKa0s-Options-1.0` in `settings/Panel.lua` and written only
  through `NS.SchemaRuntime.Set` (panel, CLI, resets and launcher alike).
- **Named non-setting state** (architecture-§5), each written outside the seam by one owner:
  - `char.filters` — the filter options, **per character**. Owner `modules/Filters.lua`
    (`Filters.Set`, `Filters.ToggleRegion`); `modules/Presets.lua`'s `Presets.Load` also writes it,
    in place. Edited from the attached panel, which is not a settings page.
  - `global.presets` — a **structural registry** of named filter snapshots shared by every
    character. One registry writer, `modules/Presets.lua` (`Presets.Save`, `Presets.Delete`); no
    load pass.
  - `profile.panelCollapsed` — the attached panel folded to its title bar. Owner `modules/Panel.lua`.
  - `global.minimap` — LibDBIcon's own table (`hide`, position), handed to the launcher.
- **`PremadeGroupsFilterExtensionPerfDB`** — the perf capture ring, written by `LibKa0s-Perf-1.0`.

## Message Bus

None. The addon defines no AceEvent messages; modules call each other directly through `NS`.

## Slash Commands

`/pgfe` and `/premadegroupsfilterextension`, dispatched by `LibKa0s-Slash-1.0` from `NS.COMMANDS`:
`help`, `config`, `enable`, `disable`, `version`, `list`, `get`, `set`, `reset`, `resetall`,
`profile`, `debug`, `diagnostics`, `perf`. Bare `/pgfe` opens the settings panel. Plan Task 7 adds
`apply` (a typed slash command is a hardware event, so it may search) and `clear`. Details:
[`slash-dispatch.md`](slash-dispatch.md).

## Event Subscriptions

Registered in `OnEnable` and on stand-up from `NS.FEATURE_EVENTS`, through `NS.SafeRegisterEvent`
(events-frames-taint-§1), and actually unregistered on stand-down. **The scaffold registers none.**
Planned: `ACTIVE_PLAYER_SPECIALIZATION_CHANGED` / `PLAYER_SPECIALIZATION_CHANGED` (Task 6, refresh the
player's spec keywords), `CHALLENGE_MODE_MAPS_UPDATE` and `PLAYER_ENTERING_WORLD` (Task 8, season
readout and panel visibility). AceDB's three profile callbacks are setup and stay up while disabled.

## Taint Notes

- Hooks into PGF are `hooksecurefunc` post-hooks installed **at file load**, never AceHook, and each
  hook body returns at once when `NS.IsStoodDown()` (a post-hook has no un-hook; slash-commands-§7's
  sanctioned exception).
- `LFGListFrame.SearchPanel.SearchBox` has `securityDisableSetText`: no code path writes it. The key
  range is shown in a read-only field for the player to copy.
- `C_LFGList.Search` is hardware-event protected: the search runs only through
  `PremadeGroupsFilterDialog.RefreshButton:Click()` inside the Apply button's `OnClick` or a typed
  `/pgfe apply`.
- Apply refuses under `InCombatLockdown()`. The settings panel's combat lock is the library's.

## Known Limitations

- The Group Finder's search box cannot be written by an addon, so key-level title searches stay a
  copy and paste.
- Server regions exist for the US and EU portals only; KR, TW and CN have none.
- Expressions that reference `pgfe_*` evaluate to nil while the addon is disabled (the env hook is a
  no-op); Clear before disabling.
- PGF internals are not a public API: every touch is in `core/PGFBridge.lua`, nil-guarded, and a
  missing seam is reported as "PGF version not supported" rather than raising.

## Documentation map

Every `.md` under `docs/` appears in exactly one table below. Out of scope and named once each as
directories, never row by row: `docs/audits/`, `docs/reviews/`, `docs/automated-tests/<run>/`,
`docs/perf-analysis/<run>/`, `docs/revendor/<date>-v<tag>/`, `docs/superpowers/` (the design spec
and the implementation plan) and `docs/investigations/`.

### Required (documentation-§3, Tier 1)

| Doc | Covers |
|---|---|
| `scope.md` | What the addon is for, and what it deliberately leaves to PGF or does not do |
| `module-map.md` | Every non-vendored file, its responsibility, and the TOC load order |
| `schema.md` | The SavedVariables shape, every default, and the migration path |
| `settings-panel.md` | The `Page \| Covers` table and the page → tab → row tree |
| `data-flow.md` | Apply as a pipeline: options in, PGF state and expression out, search |
| `common-tasks.md` | Recipes for the changes made most often here |

### Conditional (documentation-§3, Tier 2)

| Doc | Status | Trigger |
|---|---|---|
| `perf-analysis/README.md` | Present | The performance harness is wired (`core/PerfSetup.lua`) |
| `slash-dispatch.md` | Present | 14 commands in `NS.COMMANDS` |
| `profiles.md` | Present | The Profiles page ships in the options UI |
| `debug.md` | Present | The diagnostics dump ships in every addon (debug-logging-§14) |
| `midnight-quirks.md` | Not applicable | The addon carries no client-version workaround of its own |
| `compat-layer.md` | Not applicable | `core/Compat.lua` publishes 2 shims, both supplied by `LibKa0s-Compat-1.0` (fewer than three addon-specific) |
| `message-bus.md` | Not applicable | No AceEvent messages are defined |

### Verification and record (documentation-§3)

| Doc | Covers |
|---|---|
| `testing.md` | How to run the harness and lint; the green commit gate and the release gate |
| `smoke-tests.md` | The in-game smoke-test suite |
| `test-cases.md` | The generated case inventory (authoritative pass count) |
| `performance.md` | The addon performance page |
| `automated-tests/README.md` | What the automated-test record is and how to produce it |
| `automated-tests/RESULTS.md` | One row per run; generated by the runner, never hand-edited apart from the watch list's `Disposition` column (automated-tests-§4) |

### Addon-specific (documentation-§3, Tier 3)

| Doc | Covers |
|---|---|
| — | None yet. `realm-map-maintenance.md` arrives with plan Task 2 |

## Documented deviations

The single home for a ratified deviation from the Ka0s WoW Addon Standard (documentation-§3). A
deviation not in this table is not ratified.

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| library-stack-§6, toc-file-§1 | Hard `## Dependencies: PremadeGroupsFilter`; the addon reads/writes PGF state and hooks PGF's env builder | It is an extension of PGF and has no function without it (owner requirement, 2026-10-09) | 2026-10-09 | PGF ships a public API, or the standard gains an extension-addon rule |

### Files over the 1500-line cap

The layout-§1 census of authored `.lua` files over the 1500-line cap. Vendored code (`libs/`,
`tests/_kit/`) is out of scope, and the repository has no generated data.

Nothing is over the cap today.
