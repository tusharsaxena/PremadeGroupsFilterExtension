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

**State at v0.1.0.** Every module the plan names is built and covered by the headless suite: the
realm map and region lookup, season data and targeting, the expression compiler, the per-character
filter options and presets, the PGF bridge and env hook, Apply/Clear with the `apply` and `clear`
verbs, and the attached panel. What the suite cannot see (real frames, PGF's real dialog, the
Group Finder) is the in-game list in [`smoke-tests.md`](smoke-tests.md).

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
| Slash registry | `NS.COMMANDS` (positional triples) and `NS.SlashCommands` (the dispatcher) | `apply` and `clear` sit in `settings/Slash.lua`'s table and delegate to `NS.Apply`. |
| Feature events | append `{ "EVENT", "MethodName" }` to `NS.FEATURE_EVENTS` at file load | `core/PGFE.lua` registers the list on enable and stand-up and unregisters it on stand-down. Teardown/rebuild steps go in `NS.STAND_DOWN` / `NS.STAND_UP`. |
| Spec readers | `NS.Compat.GetSpecialization()`, `NS.Compat.GetSpecializationInfo(i)` | `core/Compat.lua`, through `LibKa0s-Compat-1.0`; use these rather than the bare globals. |
| Defaults | `NS.C.PROFILE`, `NS.C.CHAR_DEFAULTS`, `NS.C.GLOBAL_DEFAULTS` | `defaults/Profile.lua`; db at `NS.addon.db` (== `NS.db`). |
| Perf bucket | declare `{ key = "envInject" }` in `core/PerfSetup.lua` in the change that brackets the env hook | Not declared at v0.1.0: the env hook is not bracketed yet, and a bucket no bracket reaches reads 0.000 (performance-§3). |

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

The feature modules, one purpose each:

| Unit | File | Purpose |
|---|---|---|
| PGF bridge | `core/PGFBridge.lua` | The only file that touches PGF internals (see [PGF seams](#pgf-seams)) |
| Realm data | `defaults/Realms.lua` | `NS.RealmLists`: realm display names per portal and region bucket ([`realm-map-maintenance.md`](realm-map-maintenance.md)) |
| Regions | `modules/Regions.lua` | Portal detection, realm normalization, leader name → region key |
| Season | `modules/Season.lua` | Current-season dungeons: cmID, name, short keyword, best timed level |
| Targeting | `modules/Targeting.lua` | Pure: dungeons whose best timed level is below N; the `N-N` range text |
| Expression | `modules/Expression.lua` | Pure: options → clauses → the marked block; merge and strip |
| Filters | `modules/Filters.lua` | The live `char.filters` table, validation, the clause options |
| Presets | `modules/Presets.lua` | Named snapshots in `global.presets` |
| Env injector | `modules/EnvInject.lua` | The env post-hook body: `pgfe_*` and, without PremadeRegions, the region variables |
| Apply | `modules/Apply.lua` | Apply and Clear: refusals first, then the bridge writes, then the search |
| Panel | `modules/Panel.lua` | The frame attached under PGF's dialog |

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

`/pgfe` and `/premadegroupsfilterextension`, dispatched by `LibKa0s-Slash-1.0` from `NS.COMMANDS`
(`settings/Slash.lua`), in table order. Bare `/pgfe` opens the settings panel. Details:
[`slash-dispatch.md`](slash-dispatch.md).

| Verb | Does |
|---|---|
| `help` | Prints the command list |
| `config` | Opens the settings panel |
| `enable` / `disable` | Writes `enabled` through the write seam; the latch follows |
| `version` | Prints the version |
| `list` / `get` / `set` / `reset` / `resetall` | The schema CLI |
| `profile` | Lists profiles, or switches to one |
| `debug` | The console window; `debug on\|off` the logging flag; `debug diagnostics` the report |
| `diagnostics` | Writes the diagnostics report to the console |
| `perf` | The `LibKa0s-Perf-1.0` capture workflow |
| `apply` | `NS.Apply.Run{ search = true }` (a typed command is a hardware event, so it may search) |
| `clear` | `NS.Apply.Clear()` |

`apply` and `clear` are refused with the library's disabled line while the addon is stood down.

## Event Subscriptions

Registered in `OnEnable` and on stand-up from `NS.FEATURE_EVENTS`, through `NS.SafeRegisterEvent`
(events-frames-taint-§1), and actually unregistered on stand-down. AceDB's three profile callbacks
are setup and stay up while disabled.

| Event | Handler | Declared in | Does |
|---|---|---|---|
| `ACTIVE_PLAYER_SPECIALIZATION_CHANGED` | `OnActiveSpecChanged` | `modules/EnvInject.lua` | Re-reads the player's spec and class-role keywords |
| `PLAYER_SPECIALIZATION_CHANGED` | `OnPlayerSpecChanged` | `modules/EnvInject.lua` | Same, for `unit == "player"` |
| `CHALLENGE_MODE_MAPS_UPDATE` | `OnPanelSeasonData` | `modules/Panel.lua` | Rebuilds the best-timed readout once season data arrives |
| `CHALLENGE_MODE_COMPLETED` | `OnPanelSeasonData` | `modules/Panel.lua` | Same, after a key finishes |
| `PLAYER_ENTERING_WORLD` | `OnPanelEnteringWorld` | `modules/Panel.lua` | `Panel.UpdateVisibility()` |

Besides events, two `hooksecurefunc` hooks run (see [Taint Notes](#taint-notes)): the env post-hook
and the dialog hook (`SwitchToPanel`, plus `OnShow`/`OnHide` script hooks), which calls
`Panel.UpdateVisibility()`. Stand-up re-runs `EnvInject.RefreshPlayer` and
`Panel.UpdateVisibility`; stand-down hides the panel.

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

## PGF seams

Every touch of PGF internals is in `core/PGFBridge.lua`, nil-guarded, and read at call time.
Citations are `<file>:<line>` in PGF **7.6.2**. `Bridge.Check()` tests the six seams marked *checked*
in order and names the first missing one; the panel and Apply then show "PGF version not supported".

| Seam | PGF source | Used for | Checked |
|---|---|---|---|
| `PremadeGroupsFilter.Debug` (PGF's private namespace) | `Init.lua:27` | Every other seam; `C.SPECIALIZATIONS`, `C.MAP_ID_TO_KEYWORDS` | yes |
| `PGF.PutPremadeRegionInfo(env, leaderName)` | `Plugins/PremadeRegions.lua:24`, called per result at `Main.lua:363-364` | The env post-hook | yes |
| `PremadeGroupsFilterDialog` | `UI/Dialog.lua:33`; `panels`, `activeId`, `activeState`, `activePanel` at `UI/Dialog.lua:39-42` | Visibility, category test, state table | yes |
| `PremadeGroupsFilterDungeonPanel` | `UI/DungeonPanel.lua:105`; category `c2f4` at `:451`; `name = "dungeon"` at `:109` | Category test, rows, edit box | yes |
| `Dialog.RefreshButton` | `UI/Dialog.lua:77-78` → `LFGListSearchPanel_DoSearch` (`:147-154`) | The search, inside a hardware event | yes |
| `DungeonPanel:TriggerFilterExpressionChange()` | `UI/DungeonPanel.lua:314` (it runs `UpdateAdvancedFilters`, `:320`, `:408`) | Re-filter and sync the game's advanced filter | yes |
| Dungeon rows `panel.Dungeons["Dungeon"..i].cmId`, state key `"dungeon"..i` | `UI/DungeonPanel.lua:59` (8 rows), `:168`, `:210-211`, `:252` | cmID → positional checkbox | no (rows without a `cmId` are skipped) |
| `activeState.dungeon` (`PremadeGroupsFilterState[activeId]`) | `UI/Dialog.lua:183`, `:196`, `:216-224` | Where checkboxes and `expression` are written | no |
| `panel:Init(state)` | `UI/DungeonPanel.lua:217-255` | Push written state into the live panel | no (called only when the dungeon panel is the active one) |
| `panel.Advanced.Expression.EditBox` | `UI/Common.lua:144-156` (commit on `OnEditFocusLost`, `:153-156`) | Clear focus before reading, so typed text is committed | no |
| `Dialog:SwitchToPanel` | `UI/Dialog.lua:116-128`, `:178-199` | Hooked: category switch, minimize, maximize | no (hook skipped if absent) |

When the dialog is minimized the dungeon panel is not the active panel: Apply writes the stored
state and skips `Init` / `TriggerFilterExpressionChange`; PGF re-reads that state on the next
`SwitchToPanel` (`UI/Dialog.lua:190-199`).

## Injected variables

The env post-hook (`modules/EnvInject.lua`, installed at file load through
`Bridge.InstallEnvHook`) runs after PGF has counted the members into `env` (`Main.lua:316`;
`Modules/MemberInfo.lua:45-77`).

| Variable | Value | When |
|---|---|---|
| `pgfe_samespec` | `env[<player spec keyword>]` or 0 — members with the player's spec | Always (while not stood down) |
| `pgfe_sameclassrole` | `env[<role prefix>_<class>s]` or 0 — members of the player's class in the player's role | Always (while not stood down) |
| `region` | The leader's region key, or nil | Only when `PremadeRegions` is not loaded |
| `oce la chi mex bzl eng ger fra ita spa por rus` | `false`, then `true` for the leader's region | Only when `PremadeRegions` is not loaded |

The keywords follow PGF's own formulas (`Modules/Specializations.lua:94`, `:97`):
`spec:lower().."_"..class:lower().."s"` (`beastmastery_hunters`) and
`ROLE_PREFIX[role].."_"..classFile:lower().."s"` (`dps_hunters`, prefixes from `Init.lua:134-138`).
Both are cached on enable, on the two spec events and on stand-up, so the per-result hook makes no
API call. With PremadeRegions loaded, PGF's own plugin fills the region variables
(`Plugins/PremadeRegions.lua:24-46`) and the hook leaves them alone.

## Expression block format

`modules/Expression.lua` owns one marked block in the dungeon state's `expression`. Clauses, each
only when its option is on, in this order: regions `( oce or chi )`, `pgfe_samespec == 0`,
`pgfe_sameclassrole == 0`, `( mpmapintime and mpmapmaxkey >= N )`, `age <= M`.

With user text `U` that has real (non-comment) content:

```
-- [pgfe] begin: managed by Ka0s PGF Extension (Apply rewrites, Clear removes)
( <clauses joined by " and "> ) and (
-- [pgfe] end
U
-- [pgfe] close
)
```

With `U` empty or comment-only (wrapping it would hand PGF `( … ) and ( )`, a parse error), the
block is just the begin marker, `( <clauses> )` and the end marker, followed by `U` unchanged.
PGF's normalization drops `--` lines and joins the rest, so the result is `( clauses ) and ( U )`
and an `or` in `U` cannot change precedence. Strip removes `begin..end`, and a `close` marker with
the `)` line after it. A begin without an end, or a close not followed by `)`, is **damage**: Apply
and Clear refuse and leave the text alone. No clauses means no block. Over 2000 characters (PGF's
edit-box limit) refuses.

## Known Limitations

- The Group Finder's search box cannot be written by an addon, so key-level title searches stay a
  copy and paste.
- Server regions exist for the US and EU portals only; KR, TW and CN have none.
- Apply (button or `/pgfe apply`) needs PGF's dialog to be on the Dungeons category (the category
  it last showed); on any other it refuses rather than write another category's state.
- The realm map is static data; a realm Blizzard adds, moves or renames resolves to no region until
  the map is updated ([`realm-map-maintenance.md`](realm-map-maintenance.md)).
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
| `slash-dispatch.md` | Present | 16 commands in `NS.COMMANDS` |
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
| `realm-map-maintenance.md` | What the realm → region map holds, when and how to check it against PremadeRegions and warcraft.wiki.gg, and the source reconciliation log |

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
