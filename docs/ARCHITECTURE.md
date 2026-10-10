# Architecture — Ka0s Premade Groups Filter Extension

The engineer brief and the hub of the doc set (documentation-§3). Each section summarizes and links
to its topic doc; the full register is [Documentation map](#documentation-map).

## Overview

A companion addon to **Premade Groups Filter** (PGF) that adds Mythic+ conveniences PGF does not
have: target every dungeon the player has not timed at a chosen key level (or let Smart pick the
level), filter by the leader's server region and the listing's playstyle, exclude groups that already
hold the player's spec or class-and-role, ask for an experienced leader,
cap the listing age, and keep named presets; a Toggle PGF Extension Filters switch takes it all out
of PGF again. It also replaces PremadeRegions: the leader's server region is tagged on every Group
Finder row and applicant. It does **not** filter on its own: it writes PGF's dungeon checkboxes and
PGF's Advanced Filter Expression, and injects its `pgfe_*` variables (and, without PremadeRegions,
the region variables) into PGF's per-result filter environment through one `hooksecurefunc`. Apply
then clicks PGF's search button inside the hardware event.

Optionally (`## OptionalDeps: EllesmereUI`), the attached panel is painted in the user's
EllesmereUI theme, the way `PremadeGroupsFilter_EllesmereUI` paints PGF's own dialog, through
EllesmereUI's public skinning API. Only when EllesmereUI (with its Blizzard Skin child), its
third-party skinning, this addon's Third-Party Addons entry and PGF's own EllesmereUI skin are all
on, and the *Use the EllesmereUI skin* switch (default on) is too: see
[EllesmereUI seams](#ellesmereui-seams). Plan:
[`superpowers/plans/2026-10-09-eui-skin.md`](superpowers/plans/2026-10-09-eui-skin.md).

Built to the Ka0s WoW Addon Standard: Ace3, vendored `LibKa0s` v1.71.0 (one setup file per adopted
major), schema-driven master settings, the launcher, one stand-down latch, headless tests and
luacheck. Retail only (`## Interface: 120100`). The design is
[`superpowers/specs/2026-10-09-m-plus-v0.1-design.md`](superpowers/specs/2026-10-09-m-plus-v0.1-design.md)
and the build plan
[`superpowers/plans/2026-10-09-m-plus-v0.1.md`](superpowers/plans/2026-10-09-m-plus-v0.1.md).

**State at v0.1.0.** Every module the plan names is built and covered by the headless suite: the
realm map and region lookup, season data and targeting, the expression compiler, the per-character
filter options and presets, the PGF bridge and env hook, Apply/Clear with the `apply` and `clear`
verbs, the attached panel, and the region tags on Group Finder rows (`modules/RegionTags.lua`). What
the suite cannot see (real frames, PGF's real dialog, the
Group Finder) is the in-game list in [`smoke-tests.md`](smoke-tests.md).

## Contracts later tasks build on

Recorded here because the plan names them provisionally.

| What | Exact name | Notes |
|---|---|---|
| Stand-down accessor | **`NS.IsStoodDown()`** | Published by `core/LifecycleSetup.lua`; true while a hold is taken; production takes one, `disabled` (no perf harness is wired, so nothing takes the library's `perf` hold). The plan's provisional `NS.Lifecycle:IsStoodDown()` does not exist: use `NS.IsStoodDown()` (or `NS.Lifecycle:IsDown()`). Every hook body returns at once when it answers true. |
| Disabling in a test | `NS.addon:OnSlashCommand("disable")`, or `NS.addon.Settings.Helpers.Set("enabled", false)` | Both go through the write seam to the latch. **`NS.addon:Disable()` is not the stand-down** (that is AceAddon's, and the kit fake does not model it). |
| Test factories | **`T.newAddon(opts)`**, **`T.bootAddon(opts)`**, **`T.enableAddon(opts)`** on `local T = _G.PGFE_TEST` | Each returns `(NS, env, mock)`, env and mock the same table. `newAddon`: files loaded. `bootAddon`: + `OnInitialize` (db, migrations). `enableAddon`: + `OnEnable` (events, settings category, launcher, latch). |
| Factory `opts` | `currentRegion`, `realmName`, `mapTable`, `specID`, `role`, `classFile`, `inCombat` seed the mock; `skip` (file list), `mock` (fn), `addonName`, `afterFile` (fn, run after each addon file) | See `tests/loader.lua`. |
| Mock fields | `currentRegion`, `realmName`, `mapTable`, `mapUIInfo`, `seasonBest`, `specID`, `role`, `classFile`, `inCombat`, `fireEvent(name, ...)`, `pgf`, `hooks`, `prints`, `popupsShown`, `reloads`, `installEUI(spec)` / `eui` | `tests/wow_mock.lua`; `hooksecurefunc` is a real post-hook. Assigning a mock key sets that global (`m.PremadeRegions = {...}`). |
| PGF fake | `tests/pgf_fake.lua` (the plan's Task 6 fake, verbatim) | Installed by the mock builder before any addon file loads; handle at `mock.pgf`. |
| EllesmereUI fake | `m.installEUI{ child, pgfSkin, masterOff, entries }` from a factory's `mock` option | Opt-in (absent by default). Installs `EllesmereUI.RegisterSkin`, `EllesmereUIDB`, `C_AddOns`; `m.eui.dispatch(name)` is the login dispatch, `m.eui.dispatchAll()` the live one; the facade records every primitive call (`m.eui.calls`, `callsFor`, `count`). |
| Slash registry | `NS.COMMANDS` (positional triples) and `NS.SlashCommands` (the dispatcher) | `apply` and `clear` sit in `settings/Slash.lua`'s table and delegate to `NS.Apply`. |
| Feature events | append `{ "EVENT", "MethodName" }` to `NS.FEATURE_EVENTS` at file load | `core/PGFE.lua` registers the list on enable and stand-up and unregisters it on stand-down. Teardown/rebuild steps go in `NS.STAND_DOWN` / `NS.STAND_UP`. |
| Spec readers | `NS.Compat.GetSpecialization()`, `NS.Compat.GetSpecializationInfo(i)` | `core/Compat.lua`, through `LibKa0s-Compat-1.0`; use these rather than the bare globals. |
| Defaults | `NS.C.PROFILE`, `NS.C.CHAR_DEFAULTS`, `NS.C.GLOBAL_DEFAULTS` | `defaults/Profile.lua`; db at `NS.addon.db` (== `NS.db`). |
| Perf | No Perf instance | performance-§12 exemption; the re-arm trigger is in `## Documented deviations`. |

## Module Map

Single modular layout (`core/ defaults/ locales/ modules/ settings/`). Load order is the TOC's:
libraries → `locales/enUS.lua` → the `core/` setup files → `core/PGFBridge.lua` → `core/EUIBridge.lua` → `defaults/` →
`modules/` → `settings/`, with every addon file's TOC line annotated. Full per-file
table and the load-order reasoning: [`module-map.md`](module-map.md).

`LibKa0s` majors wired, one setup file each: Core (`core/CoreSetup.lua`), Media
(`core/MediaSetup.lua`), Compat (`core/Compat.lua`), Env (`core/EnvSetup.lua`), DebugLog
(`core/DebugLogSetup.lua`), Launcher (`core/LauncherSetup.lua`), Lifecycle
(`core/LifecycleSetup.lua`), Schema (`settings/SchemaSetup.lua`), Options
(`settings/OptionsSetup.lua`), Slash (`settings/Slash.lua`). Vendored and not wired: Bus, Pool, Item,
Widgets, Perf (the performance-§12 exemption). Ace3, LibSharedMedia, LibDataBroker and LibDBIcon are vendored under `libs/` too
(`DEPENDENCIES.md`).

The feature modules, one purpose each:

| Unit | File | Purpose |
|---|---|---|
| PGF bridge | `core/PGFBridge.lua` | The only file that touches PGF internals (see [PGF seams](#pgf-seams)) |
| EllesmereUI bridge | `core/EUIBridge.lua` | The only file that reads EllesmereUI state: the skin's four gate conditions, with a label and a hint each (see [EllesmereUI seams](#ellesmereui-seams)) |
| Realm data | `defaults/Realms.lua` | `NS.RealmLists`: realm display names per portal and region bucket ([`realm-map-maintenance.md`](realm-map-maintenance.md)) |
| Regions | `modules/Regions.lua` | Portal detection, realm normalization, leader name → region key |
| Season | `modules/Season.lua` | Current-season dungeons: cmID, name, short keyword, best timed level |
| Targeting | `modules/Targeting.lua` | Pure: dungeons whose best timed level is below N; the Smart level (lowest best timed + 1); the `N-N` range text |
| Expression | `modules/Expression.lua` | Pure: options → clauses → the marked block; merge and strip |
| Filters | `modules/Filters.lua` | The live `char.filters` table, the multi-select toggles (all ticked = Any), validation, the clause options, the Smart level write |
| Presets | `modules/Presets.lua` | Named snapshots in `global.presets` |
| Env injector | `modules/EnvInject.lua` | The env post-hook body: `pgfe_*` and, without PremadeRegions, the region variables |
| Apply | `modules/Apply.lua` | Apply and Clear: refusals first, then the bridge writes, then the search |
| Region tags | `modules/RegionTags.lua` | The leader's / applicant's colored server region on Group Finder rows (replaces PremadeRegions' display) |
| Panel | `modules/Panel.lua` | The frame attached under PGF's dialog |
| EllesmereUI skin | `modules/EUISkin.lua` | Registers with EllesmereUI at load, keeps the facade `S`, and paints the panel once every condition and the switch hold |

## Settings Schema

Three AceDB scopes on `PremadeGroupsFilterExtensionDB`; full shape and defaults in
[`schema.md`](schema.md).

- **Schema rows (the write seam).** The Master controls block (`enabled`, `state.debugConsole`,
  `global.minimap.shown`, composed by `LibKa0s-Options-1.0`) and the General Filters tab's two rows
  (`filtersActive` and `showRegionTags`, `FILTER_ROWS`), both in `settings/Panel.lua` and written only
  through `NS.SchemaRuntime.Set` (panel, CLI, resets and launcher alike).
- **`euiSkin`** (profile, default `true`, in `defaults/Profile.lua`): the *Use the EllesmereUI skin*
  row on the General page's *EllesmereUI skin* tab (`settings/Panel.lua`). `disabledIf` while any
  gate condition fails; its `validate` refuses `true` while one fails (off always passes, a bulk
  reset never refused); `onChange` is `NS.EUISkin.OnSwitch` (on paints live, off after a paint asks
  for a reload). A profile switch, copy or reset runs the same `OnSwitch` with the incoming value,
  after the `enabled` latch re-read, so a disabled incoming profile is never painted.
- **Registries outside the seam** (architecture-§5), each written by one owner:
  - `global.presets` — a **structural registry** of named filter snapshots shared by every
    character. One registry writer, `modules/Presets.lua` (`Presets.Save`, `Presets.Delete`); no
    load pass.
  - `global.minimap` — LibDBIcon's own table (`hide`, position), handed to the launcher.
- **The attached panel's own state** (`char.filters`, the per-character filter options, and
  `profile.panelCollapsed`) is written by the panel's controls outside the seam: a ratified
  architecture-§5 deviation, with every writer named, in
  [Documented deviations](#documented-deviations).

## Message Bus

None, by a ratified deviation from architecture-§4
([Documented deviations](#documented-deviations)). The two-feature-module threshold is crossed:
`modules/Apply.lua`, `Panel.lua`, `EUISkin.lua`, `Filters.lua`, `Presets.lua`, `RegionTags.lua`,
`Targeting.lua` and `EnvInject.lua`. The addon still defines no AceEvent messages, and modules call
each other directly through `NS`, because each cross-module reaction has one sender and a required
order that CallbackHandler's fan-out does not promise. There are three reaction sites:

- **`reloadProfile`** (`core/PGFE.lua`, on the three AceDB profile callbacks) runs, in order,
  `Settings.Helpers.RefreshAll` / `RefreshProfilesPage`, `Panel.Refresh`, the `enabled` latch
  re-read (`Lifecycle:Set` + `Reevaluate`) and `EUISkin.OnSwitch`. The latch is re-read before the
  one-way EllesmereUI paint, so a disabled incoming profile is never painted. That order is pinned
  by `tests/test_euiskin.lua` ("a profile switch to a disabled profile with the switch on paints
  nothing").
- **`Apply.OnFiltersToggled`** (`modules/Apply.lua`, the `filtersActive` onChange) runs
  `Apply.Run` / `Apply.Clear` and then `Panel.Refresh`, so the PGF block is written or cleared
  before the panel readout refreshes.
- **`Panel.Create` / `Panel.UpdateVisibility`** (`modules/Panel.lua`) call `EUISkin.TryApply`.

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
| `apply` | `NS.Apply.Run{ search = true }` (a typed command is a hardware event, so it may search) |
| `clear` | `NS.Apply.Clear()` |

`apply` and `clear` are refused with the library's disabled line while the addon is stood down.
`perf` is reserved and unregistered (performance-§12 exemption): the library answers it with the
unknown-command line and the index.

## Event Subscriptions

Registered in `OnEnable` and on stand-up from `NS.FEATURE_EVENTS`, through `NS.SafeRegisterEvent`
(events-frames-taint-§1), and actually unregistered on stand-down. AceDB's three profile callbacks
are setup and stay up while disabled.

| Event | Handler | Declared in | Does |
|---|---|---|---|
| `ACTIVE_PLAYER_SPECIALIZATION_CHANGED` | `OnActiveSpecChanged` | `modules/EnvInject.lua` | Re-reads the player's spec and class-role keywords |
| `PLAYER_SPECIALIZATION_CHANGED` | `OnPlayerSpecChanged` | `modules/EnvInject.lua` | Same, for `unit == "player"` |
| `CHALLENGE_MODE_MAPS_UPDATE` | `OnPanelSeasonData` | `modules/Panel.lua` | Recomputes the Smart key level (when on) and rebuilds the best-timed readout once season data arrives |
| `CHALLENGE_MODE_COMPLETED` | `OnPanelSeasonData` | `modules/Panel.lua` | Same, after a key finishes |
| `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE` | `OnPanelSeasonData` | `modules/Panel.lua` | Same, when the season's affix data arrives (it can land after the map table) |
| `PLAYER_ENTERING_WORLD` | `OnPanelEnteringWorld` | `modules/Panel.lua` | Re-arms the season-data request (`Season.ResetRequest()`), then `Panel.UpdateVisibility()` |
| `UI_SCALE_CHANGED` | `OnEUISkinScale` | `modules/EUISkin.lua` | Re-lays the skinned checkboxes' accent ring and block in whole pixels (nothing to do unless skinned) |
| `DISPLAY_SIZE_CHANGED` | `OnEUISkinScale` | `modules/EUISkin.lua` | Same |

EllesmereUI's skin callback is not an event: `modules/EUISkin.lua` registers it at file load with
`EllesmereUI.RegisterSkin`, and EllesmereUI calls it once per session (PLAYER_LOGIN, or live from
its options). The skin's own hooks are on this addon's frames (see [Taint Notes](#taint-notes)).

Besides events, four `hooksecurefunc` hooks run (see [Taint Notes](#taint-notes)): the env post-hook;
the dialog hook (`SwitchToPanel`, plus `OnShow`/`OnHide` script hooks), which calls
`Panel.UpdateVisibility()`; and the two Group Finder row hooks of `modules/RegionTags.lua`
(`LFGListSearchEntry_Update`, `LFGListApplicationViewer_UpdateApplicantMember`). Stand-up re-runs `EnvInject.RefreshPlayer` and
`Panel.UpdateVisibility`; stand-down hides the panel, and `GameTooltip` first when the panel or a
frame inside it owns it (the tooltip handlers' own `OnLeave` gates on the stand-down). Whether the
dialog hook went in is kept on `Panel.dialogHooked`.

## Taint Notes

- Hooks into PGF are `hooksecurefunc` post-hooks installed **at file load**, never AceHook, and each
  hook body returns at once when `NS.IsStoodDown()` (a post-hook has no un-hook; slash-commands-§7's
  sanctioned exception).
- `modules/RegionTags.lua` post-hooks Blizzard's `LFGListSearchEntry_Update` and
  `LFGListApplicationViewer_UpdateApplicantMember` the same way, and writes the region tag onto the
  row's own font string (`ActivityName`, `Name`) with `SetText(tag .. " " .. text)`, as PremadeRegions
  did. Display only: no Blizzard table field is written. `..` and SetText pass a protected ("secret")
  string through; a leader or applicant name that is not concat-safe gets no tag
  (events-frames-taint-§8). Skipped while stood down, with `showRegionTags` off, or while
  PremadeRegions is loaded. The env hook's region lookup (`Regions.GetRegion`) probes the leader
  name the same way before matching it, so a protected name leaves `region` nil and every region
  key false.
- `LFGListFrame.SearchPanel.SearchBox` has `securityDisableSetText`: no code path writes it. The key
  range is shown in a read-only field (*Copy into search box*, whose tooltip says why) for the player to copy. Clicking that field
  selects its text (Apply leaves keyboard focus alone); Enter in it moves keyboard focus to the search box (`SetFocus`, pcall-guarded,
  only while the box is visible and the addon is not stood down), so the player's own Ctrl+V and
  Enter fill it and search. Only focus is moved; no text is written.
- `C_LFGList.Search` is hardware-event protected: the search runs only through
  `PremadeGroupsFilterDialog.RefreshButton:Click()` inside the Apply button's `OnClick` or a typed
  `/pgfe apply`.
- Apply refuses under `InCombatLockdown()`. The settings panel's combat lock is the library's.
- The EllesmereUI skin (`modules/EUISkin.lua`) touches only frames `modules/Panel.lua` created,
  through EllesmereUI's facade primitives: art removal is alpha-only and overlays are added, never
  `Hide` or `SetParent`. Its hooks (`OnClick` / `OnEnter` / `OnLeave` `HookScript`s and a
  `hooksecurefunc` on each skinned checkbox's own `SetChecked`) return at once while stood down, and
  the paint itself refuses while stood down (the stand-up retries). The `EllesmereUI.RegisterSkin`
  callback cannot be unregistered, so it survives a stand-down and gates itself: `onFacade` only
  keeps the facade and calls `TryApply`, which refuses while stood down, and the `NS.STAND_UP` row
  retries (`modules/EUISkin.lua:394-422`; upstream WowAddonStandards #10). It never touches PGF's dialog;
  that is `PremadeGroupsFilter_EllesmereUI`'s job.

## PGF seams

Every touch of PGF internals is in `core/PGFBridge.lua`, nil-guarded, and read at call time.
Citations are `<file>:<line>` in PGF **7.6.2**. `Bridge.Check()` tests the ten seams marked *checked*
in order and names the first missing one; the panel and Apply then show "PGF version not supported".

| Seam | PGF source | Used for | Checked |
|---|---|---|---|
| `PremadeGroupsFilter.Debug` (PGF's private namespace) | `Init.lua:27` | Every seam on the namespace | yes |
| `PGF.PutPremadeRegionInfo(env, leaderName)` | `Plugins/PremadeRegions.lua:24`, called per result at `Main.lua:363-364` | The env post-hook | yes |
| `C.SPECIALIZATIONS` (`Bridge.Specializations()`) | `Modules/Specializations.lua:25` | The player's spec keyword for `pgfe_samespec` (`modules/EnvInject.lua`) | yes |
| `C.MAP_ID_TO_KEYWORDS` (`Bridge.MapKeywords(mapID)`) | `Modules/ActivityKeywords.lua:59` | The dungeon short names | no (falls back to the name's initials) |
| `PremadeGroupsFilterDialog` | `UI/Dialog.lua:33`; `panels`, `activeId`, `activeState`, `activePanel` at `UI/Dialog.lua:39-42` | Visibility, category test, state table | yes |
| `Dialog.panels` | `UI/Dialog.lua:39` | Category test (`panels[activeId]`) | yes |
| `PremadeGroupsFilterDungeonPanel` | `UI/DungeonPanel.lua:105`; category `c2f4` at `:451`; `name = "dungeon"` at `:109` | Category test, rows, edit box | yes |
| `Dialog.RefreshButton` | `UI/Dialog.lua:77-78` → `LFGListSearchPanel_DoSearch` (`:147-154`) | The search, inside a hardware event | yes |
| `DungeonPanel:TriggerFilterExpressionChange()` | `UI/DungeonPanel.lua:314` (it runs `UpdateAdvancedFilters`, `:320`, `:408`) | Re-filter and sync the game's advanced filter | yes |
| `DungeonPanel.Dungeons` | `UI/DungeonPanel.xml:81` (`parentKey="Dungeons"`) | The dungeon row table | yes |
| Dungeon rows `panel.Dungeons["Dungeon"..i].cmId`, state key `"dungeon"..i` | `UI/DungeonPanel.lua:59` (8 rows), `:168`, `:210-211`, `:252` | cmID → positional checkbox | no (rows without a `cmId` are skipped) |
| `activeState.dungeon` (`PremadeGroupsFilterState[activeId]`) | `UI/Dialog.lua:183`, `:196`, `:216-224` | Where checkboxes and `expression` are written | no |
| `panel:Init(state)` | `UI/DungeonPanel.lua:217-255` | Push written state into the live panel | no (called only when the dungeon panel is the active one) |
| `panel.Advanced.Expression.EditBox` | `UI/Common.lua:144-156` (commit on `OnEditFocusLost`, `:153-156`) | Clear focus before reading, so typed text is committed | yes |
| `Dialog:SwitchToPanel` | `UI/Dialog.lua:116-128`, `:178-199` | Hooked: category switch, minimize, maximize | no (hook skipped if absent) |

When the dialog is minimized the dungeon panel is not the active panel (`SwitchToPanel` makes
`panels.mini` active, `UI/Dialog.lua:178-182`) and PGF filters with the mini panel's expression
(`UI/Dialog.lua:244-247`). `Bridge.IsDungeonPanelActive()` answers this; Apply and Clear refuse with
`MSG_MINIMIZED` and the attached panel is hidden. `Bridge.Commit` still skips `Init` /
`TriggerFilterExpressionChange` when the panel is not active, as a second guard.

## EllesmereUI seams

Every read of EllesmereUI state is in `core/EUIBridge.lua`, read at call time and nil-guarded; the
only EllesmereUI call is `EllesmereUI.RegisterSkin` in `modules/EUISkin.lua`, presence-guarded.
Read against EllesmereUI **9.4** (`EllesmereUI_SharedHelpers.lua`,
`EllesmereUIBlizzardSkin/EllesmereUIBlizzardSkin_SkinAPI.lua`, `SKINNING_API.md`) and
`PremadeGroupsFilter_EllesmereUI` 1.1.0 (`Skin.lua`). Nothing is ever written.

| Condition (status line) | Read | Notes |
|---|---|---|
| EllesmereUI and its Blizzard Skin module are loaded | `EllesmereUI.RegisterSkin` is a function and `C_AddOns.IsAddOnLoaded("EllesmereUIBlizzardSkin")` | The child holds the dispatcher; without it `RegisterSkin` only queues. Every condition below also needs this one |
| EllesmereUI third-party skinning is on | `EllesmereUIDB.thirdPartySkinsOff` not truthy | Mirrors the dispatcher's `MasterOn` (SkinAPI.lua:32-35) exactly: nil = on, any truthy value (a `1` from an import too) = off |
| This addon's Third-Party Addons entry is on | `EllesmereUIDB.thirdPartySkinAddons["PremadeGroupsFilterExtension"]` not false | Mirrors `AddonOn` (SkinAPI.lua:37-41); the entry is listed because we register under the folder name |
| PGF's own EllesmereUI skin is on | `C_AddOns.IsAddOnLoaded("PremadeGroupsFilter_EllesmereUI")` and `thirdPartySkinAddons["PremadeGroupsFilter"]` not false | `Skin.lua` registers as `PremadeGroupsFilter`; keeps PGF's window and this panel matched |

The facade `S` (apiVersion 3) is kept from the callback; the paint uses `Shell`, `FadeNineSlice`,
`FadeRegions`, `Checkbox`, `EditBox`, `Dropdown`, `Button`, `StateButtonLabel`, `Font`, `White`,
`GetAccentColor`, `GetFont` and `OnLooksChanged`. The paint checks the facade's shape first: a
facade missing any of those primitives or getters except `OnLooksChanged` (optional: without it
the paint just does not follow live theme changes) is refused before anything is painted, and the
panel stays stock. The paint itself is pcall'd and fails closed: a primitive that raises logs
`paint failed`, latches, and is never retried (a retry would skin the same widgets twice); turning
the switch off then offers the reload that drops the partial paint. EllesmereUI skins the Blizzard
menus the dropdowns open and the preset StaticPopups globally, under its own *popups and menus*
switch.

**Standards note (ratified deviation).** Reading `EllesmereUIDB` departs from library-stack-§6 /
anti-pattern #29 ("MUST NOT read a suite's ... SavedVariables"). EllesmereUI has no public query
that works before it dispatches (`S.IsEnabled()` exists only after the callback, and covers only the
master switch and our own entry, never PGF's), and the owner's gate (plan, owner decision 1) needs
all three switch reads. The reads are read-only, call-time, nil-guarded and confined to
`core/EUIBridge.lua`. Ratified by the owner on 2026-10-09: see
[Documented deviations](#documented-deviations).

## Injected variables

The env post-hook (`modules/EnvInject.lua`, installed at file load through
`Bridge.InstallEnvHook`) runs after PGF has counted the members into `env` (`Main.lua:316`;
`Modules/MemberInfo.lua:45-77`).

| Variable | Value | When |
|---|---|---|
| `pgfe_on` | `true` — the managed block's guard (`not pgfe_on or ( … )`); `false` while *Toggle PGF Extension Filters* (`filtersActive`) is off | Always (while not stood down) |
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
only when its option is on, in this order: regions `( oce or chi )`, playstyles
`( relaxed or carry )`, `pgfe_samespec == 0`, `pgfe_sameclassrole == 0`,
`( mpmapintime and mpmapmaxkey >= N )`, `age <= M`.

With user text `U` that has real (non-comment) content:

```
-- [pgfe] begin: managed by Ka0s PGF Extension (Apply rewrites, Clear removes)
( not pgfe_on or ( <clauses joined by " and "> ) ) and (
-- [pgfe] end
U
-- [pgfe] close
)
```

With `U` empty or comment-only (wrapping it would hand PGF `( … ) and ( )`, a parse error), the
block is just the begin marker, `( not pgfe_on or ( <clauses> ) )` and the end marker, followed by `U` unchanged.
PGF's normalization drops `--` lines and joins the rest, so the result is `( clauses ) and ( U )`
and an `or` in `U` cannot change precedence. The `not pgfe_on or` guard makes the block neutral
whenever the env hook did not run: the block lives in PGF's state, which outlives this addon's
runtime (a stand-down, an AddOns-list disable, an uninstall), and without the guard `pgfe_samespec
== 0` would compare nil and hide every group. Strip removes `begin..end`, and a `close` marker with
the `)` line after it. Three shapes are **damage**: a begin without an end, a close not followed by
`)`, and a wrapped block (its body ends `and (`) with no close + `)` pair after it. Apply and Clear
refuse and leave the text alone. Deleting both the close marker and its `)` is refused the same way,
on purpose: the text may well be recoverable, but Strip never guesses. Everything outside the block
is kept line for line, blank edge lines included. No clauses means no block. Over 2000 characters
(PGF's edit-box limit) refuses.

## Known Limitations

- The Group Finder's search box cannot be written by an addon, so key-level title searches stay a
  copy and paste (click the copy field, Ctrl+C, Enter, Ctrl+V, Enter). Nothing else can stand in for it: a
  listing's title and comment reach PGF as protected strings, the search-result API has no key-level
  field, and PGF's `findnumber()` scans only the activity name (`Dungeon (Mythic Keystone)`).
- The leader's item level is not filterable: the search-result API exposes only the listing's
  required item level (PGF `ilvl`). The leader's M+ rating is (`mprating`), through PGF's own *M+ Rating*
  row; this addon's former *Min leader M+ score* row duplicated it and was removed.
- Server regions exist for the US and EU portals only; KR, TW and CN have none.
- Apply (button or `/pgfe apply`) needs PGF's dialog to be on the Dungeons category (the category
  it last showed) and maximized; on any other category, or minimized, it refuses rather than write
  state PGF would not filter with.
- The realm map is static data; a realm Blizzard adds, moves or renames resolves to no region until
  the map is updated ([`realm-map-maintenance.md`](realm-map-maintenance.md)).
- While the addon is disabled (or not loaded) the managed block is neutral (`not pgfe_on or …`),
  so its filters stop applying until it is re-enabled; a user's own expression that references
  `pgfe_*` directly compares nil and should be cleared first.
- PGF internals are not a public API: every touch is in `core/PGFBridge.lua`, nil-guarded, and a
  missing seam is reported as "PGF version not supported" rather than raising.
- The EllesmereUI skin is one-way per session: EllesmereUI dispatches each skin once, and painted
  art cannot be taken off live. Turning *Use the EllesmereUI skin* off after a paint asks for a
  `/reload`, and so does a profile switch, copy or reset onto a profile with it off; a condition turned off in EllesmereUI's options (including PGF's own skin) leaves the
  panel painted until a reload, while the status lines already show it off.
- A condition turned on in EllesmereUI's options while the panel is built paints on the panel's next
  show (EllesmereUI does not tell this addon when PGF's entry changes).
- The skinned header-only collapse (EllesmereUI's 25px shell bar with its stretched atlas border),
  the shell border's layering over the body, and the dropdowns' look are checked in game only
  ([`smoke-tests.md`](smoke-tests.md), SKIN-*).
- Best timed levels read 0 until the server answers the season-data request
  (`C_MythicPlus.RequestMapInfo`, sent once per episode by `Season.GetDungeons`). The client cannot
  tell a dungeon never timed from one whose best has not loaded yet: both answer no in-time level.

## Documentation map

Every `.md` under `docs/` appears in exactly one table below. Out of scope and named once each as
directories, never row by row: `docs/audits/`, `docs/reviews/`, `docs/automated-tests/<run>/`,
`docs/revendor/<date>-v<tag>/`, `docs/superpowers/` (the design spec and the implementation plan)
and `docs/investigations/`.

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
| `perf-analysis/README.md` | Not applicable | The performance-§12 exemption is held; no harness is wired |
| `slash-dispatch.md` | Present | 15 commands in `NS.COMMANDS` |
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
| library-stack-§6, anti-patterns #29 | `core/EUIBridge.lua` reads EllesmereUI's SavedVariables: `EllesmereUIDB.thirdPartySkinsOff` and `EllesmereUIDB.thirdPartySkinAddons[...]` (our entry and PGF's skin's). Read-only, at call time, nil-guarded, in that one file; never written | The optional EllesmereUI skin's gate and its settings status lines must show the master Third-Party switch, our own entry and PGF's skin's entry separately (owner decision 1 in [`superpowers/plans/2026-10-09-eui-skin.md`](superpowers/plans/2026-10-09-eui-skin.md#owner-decisions-2026-10-09) -> `## Owner decisions (2026-10-09)`, ratified at that plan's step 6a; and the "turned off in EllesmereUI" state). EllesmereUI exposes no API for them before it dispatches: `S.IsEnabled()` arrives only with the skin callback, merges the master switch with our entry, and cannot see PGF's entry | 2026-10-09 | EllesmereUI ships a public query for its third-party switches, or the standard gains a carve-out for an optional integration reading the suite's own on/off switches |
| library-stack-§6, toc-file-§1 | Hard `## Dependencies: PremadeGroupsFilter`; the addon reads/writes PGF state and hooks PGF's env builder | It is an extension of PGF and has no function without it (owner requirement, [`superpowers/specs/2026-10-09-m-plus-v0.1-design.md`](superpowers/specs/2026-10-09-m-plus-v0.1-design.md) §1 item 5 (the requirement) and §2 (recorded as a user-requirement deviation)) | 2026-10-09 | PGF ships a public API, or the standard gains an extension-addon rule |
| architecture-§5 | The attached panel's per-character filter options (`char.filters`) and `profile.panelCollapsed` are set by the panel's own controls, outside the schema write seam, and no settings-page row or CLI path addresses them. Writers of `char.filters`: `Filters.Set`, `Filters.ToggleRegion` / `ClearRegions`, `Filters.TogglePlaystyle` / `ClearPlaystyles`, `Filters.ToggleComposition` / `ClearComposition` and `Filters.ApplySmartLevel` (`modules/Filters.lua`), reached from the panel controls and from `/pgfe apply` (`modules/Apply.lua` -> `ApplySmartLevel`), plus `Presets.Load` (`modules/Presets.lua`), which refills the table in place. Writer of `profile.panelCollapsed`: `setCollapsed` (`modules/Panel.lua`), from the min/max arrow and the header-strip click | Per-character scope is an owner requirement that the schema seam (profile and global roots only) cannot hold; presets snapshot and refill `char.filters` whole, keeping its identity; the panel is a feature surface attached to PGF's dialog, not a settings page (issue #10; audit `docs/audits/2026-10-10/` PGE-02) | 2026-10-10 (owner) | A filter option or `panelCollapsed` gains a settings-page row or a get/set CLI path, or LibKa0s-Schema gains a char root |
| architecture-§4, anti-patterns #19 | No AceEvent message bus, although the two-feature-module threshold is crossed (Apply, Panel, EUISkin, Filters, Presets, RegionTags, Targeting, EnvInject). Modules call each other through `NS`. The cross-module reactions: the shell's `reloadProfile` (`core/PGFE.lua`, on the three AceDB profile callbacks) fans out, in order, to `Settings.Helpers.RefreshAll` / `RefreshProfilesPage`, `Panel.Refresh`, the `enabled` latch re-read (`Lifecycle:Set` + `Reevaluate`) and `EUISkin.OnSwitch`; `Apply.OnFiltersToggled` (the `filtersActive` onChange) runs `Apply.Run` / `Apply.Clear` and then calls `Panel.Refresh`; `Panel.Create` / `Panel.UpdateVisibility` call `EUISkin.TryApply` | Every reaction has one sender and a required order that CallbackHandler's fan-out does not promise: `reloadProfile` must re-read the latch before the one-way EllesmereUI paint so a disabled incoming profile is never painted, and `Apply.OnFiltersToggled` must write or clear the PGF block before the panel readout refreshes. `reloadProfile` has several receivers, but none its sender should not know about, and with no messages defined the CallbackHandler clobber §4 guards against cannot occur (issue #10; audit `docs/audits/2026-10-10/` PGE-03) | 2026-10-10 (owner) | A reaction gains an order-independent receiver the sender should not name, a module outside the shell and Apply needs to hear profile-changed or filters-toggled, or the standard adds an ordered-dispatch carve-out |
| standalone-windows; library-stack-§8; options-ui-§15 | The attached panel (`modules/Panel.lua` `buildFrame`) takes PGF's dialog chrome when unskinned (`PortraitFrameTemplateMinimizable` with the `ButtonFrameTemplateNoPortraitMinimizable` border layout) and EllesmereUI's shell when skinned (`modules/EUISkin.lua`), not the Ka0s window edge. The skinned min/max control draws the Blizzard atlases `UI-QuestTrackerButton-Secondary-Collapse` and `UI-QuestTrackerButton-Secondary-Expand` (`EUISkin.lua` `COLLAPSE_ATLAS` / `EXPAND_ATLAS`) to match EllesmereUI's own minus and plus, not the LibKa0s catalog's minimize / expand glyphs (`libs/LibKa0s/Media.lua:94`). The panel is parented and anchored to PGF's dialog, is not movable and persists no geometry. The General page has no General visibility row (`settings/Panel.lua` `omit = { visibility = true }`): the panel shows only with PGF's dialog on the dungeon category, and the addon holds no visibility state | An extension surface must read as part of the host window it attaches to; its visibility is the host's, so a visibility setting would only duplicate Enable and `filtersActive` (issue #18; audit `docs/audits/2026-10-10/` PGE-17, PGE-19, PGE-26) | 2026-10-10 (owner) | The panel becomes independently shown or movable, or the standard gains an attached-panel or extension-surface rule |
| `performance-§12` | No performance harness is wired: no `core/PerfSetup.lua`, no `PremadeGroupsFilterExtensionPerfDB` (the TOC declares one SavedVariables global), no `perf` verb registration (`perf` stays reserved; `/pgfe perf` answers with the library's unknown-command line and the index), no suspend/resume contract (production takes only the `disabled` hold), and no `docs/perf-analysis/`. `libs/LibKa0s/` stays vendored whole, `Perf.lua` included, and `docs/performance.md` stays as the one-screen page. The offline `tests/perf.lua` is shipped anyway (it suspends nothing, ships nothing to the client and adds no SavedVariable), so the runner's `perf` suite reads `pass` rather than this exemption's skip | **Criterion (a) plus (b).** (a): the committed whole-repo sweep of `RegisterEvent` / `SetScript("OnUpdate"` / `C_Timer`, with every `hooksecurefunc` / `HookScript` site, in [`performance.md`](./performance.md), sweep at ``2c86d49``: no `OnUpdate` handler, no timer of any kind (AceTimer removed, C-35), one registration site over eight `NS.FEATURE_EVENTS` rows that each do one small refresh, hooks that run on the player's own Group Finder actions, and `Apply` refusing in combat; `tests/perf.lua`'s `combatEvents` scenario measures the per-event cost. (b): the capture windows open on the player's combat state (performance-§7), so every declared bucket would read `0.000` by construction. Owner checkpoint D1 (C-09, issue #5; audit `docs/audits/2026-10-10/` PGE-09) | 2026-10-10 (owner) | The first `OnUpdate` handler, repeating ticker, or in-combat event handler doing real work re-arms the full wiring MUST (performance-§12): wire `core/PerfSetup.lua`, `PremadeGroupsFilterExtensionPerfDB`, the `perf` verb and the suspend contract, and retire this row |

### Files over the 1500-line cap

The layout-§1 census of authored `.lua` files over the 1500-line cap. Vendored code (`libs/`,
`tests/_kit/`) is out of scope, and the repository has no generated data.

Nothing is over the cap today.
