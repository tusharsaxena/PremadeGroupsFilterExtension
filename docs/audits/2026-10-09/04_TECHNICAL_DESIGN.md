# 04 — Technical design: closing the 2026-10-09 deviations

Keyed to `02_DEVIATIONS.md`. Standard: v2.77.0. Nothing here changes behavior a player sees except
PGE-01 (a filter that may currently not filter), PGE-13/14 (the logo path and size) and PGE-19 if the
owner adds the visibility row. Every code change rides the green gate (`lua tests/run.lua`,
`luacheck .`) and is test-first where a test can fail (testing-§4, testing-§12).

## D1 — Route the spec readers through Compat (PGE-01)

**Change.** `modules/EnvInject.lua` `RefreshPlayer`:

```lua
local Compat = NS.Compat               -- call time is fine too; Compat loads in # Core
local idx = Compat.GetSpecialization()
local specID, role, _
if idx then specID, _, _, _, role = Compat.GetSpecializationInfo(idx) end
```

`NS.Compat` already carries both members with library-absent nil answers (`core/Compat.lua:14-18`),
and the library prefers `C_SpecializationInfo` over the deprecated globals.

**Test first.** In `tests/test_envinject.lua`, a case whose mock removes the two globals
(`m.GetSpecialization = nil`, `m.GetSpecializationInfo = nil`) and supplies
`m.C_SpecializationInfo = { GetSpecialization = …, GetSpecializationInfo = … }`; assert
`pgfe_samespec` reads the member count for the player's keyword. It goes red on today's code (the bare
global is nil, the keyword caches nil, the variable reads 0) — record that mutation in a
`-- red under:` comment.

**Lint.** If nothing else reads them, drop `GetSpecialization` / `GetSpecializationInfo` from
`.luacheckrc` `read_globals` so a future bypass fails lint (`C_SpecializationInfo` stays only if a file
still reads it; Compat's library does, but it is under `libs/`).

**Risk.** None functional where the globals exist (same answers); a fix where they do not. A smoke
check (`docs/smoke-tests.md`) should confirm *No one with my spec* removes a group with the player's
spec on a 12.1.0 client.

## D2 — Decide the filter options' home (PGE-02)

Two compliant shapes; the owner picks one.

- **(a) Register row (smallest).** One `## Documented deviations` row:
  `| architecture-§5 | The attached panel's nine per-character filter options (char.filters) and panelCollapsed are written by modules/Filters.lua, modules/Presets.lua and modules/Panel.lua, not through the schema seam; they are not in /pgfe get|set and not in Reset all settings | They are working state of a feature surface attached to PGF's dialog, per character by the owner's requirement; presets snapshot them whole | 2026-10-09 | The first filter option exposed on a settings page or the CLI |`.
  Then rewrite `docs/ARCHITECTURE.md` → Settings Schema so `char.filters` and `panelCollapsed` are no
  longer called *named non-setting state* (they are preferences; the register row is what makes them
  compliant). `global.presets` (registry) and `global.minimap` (library table) keep their naming.
- **(b) Schema rows.** Declare nine rows under a `filters` section with a `resolveRoot` that answers
  `db.char` for `char.`-prefixed paths (the Schema major takes `resolveRoot(parts)`), route
  `Filters.Set` / `ToggleRegion` / `Presets.Load` (as one `SetMany`) through `NS.SchemaRuntime`, and the
  CLI, the debug `[Set]` line (debug-logging-§10) and validation come for free. Larger change; touches
  `Filters`, `Presets`, `Panel`, the schema, the defaults assembly and tests.

Recommendation: (a) now, (b) when a second surface needs the options (the trigger in the row).

## D3 — Record the no-bus decision (PGE-03)

Register row: `| architecture-§4 | No message bus; modules call each other directly through NS | No module reacts to a change another module makes: every cross-module call is a synchronous query or command on the caller's own path (Apply → Bridge/Filters/Expression; Panel → Apply/Filters/Presets), so the same-target clobber the bus prevents cannot arise | 2026-10-09 | The first module that must react to another module's state change |`.
Rewrite `## Message Bus` to cite the threshold and the row in two sentences. If the owner prefers
adoption instead, the one reactive edge today is *preset loaded / filter changed → panel refresh*,
which is currently a direct `Panel.Refresh()` call inside the panel itself — so adoption buys nothing
yet, which is the argument for the row. Optionally raise upstream (open-evolutions) whether pure helper
tables (`Targeting`, `Expression`, `Regions`) are "feature modules".

## D4 — Trace the flows (PGE-04)

Add gated lines, string-building behind the gate (debug-logging-§4), one per event:

| Where | Tag | Line |
|---|---|---|
| `Apply.Run` / `Apply.Clear` each refusal | `Apply` | `refused: <msgKey> (<arg>)` — names the guard |
| `Apply.Run` success | `Apply` | `applied: %d dungeons, range %s, %d clauses, search=%s` |
| `Apply.Clear` success | `Apply` | `cleared managed block` |
| `Bridge.Check` failure | `PGF` | `seam missing: %s` (via `DebugChanged` so it logs on change) |
| `Bridge.InstallEnvHook` / `HookDialog` | `PGF` | `env hook installed` / `dialog hook installed` (or `skipped: <why>`) — through `DebugAtEnable` since they run at load |
| `EnvInject.RefreshPlayer` | `Spec` | `keywords: spec=%s classRole=%s` via `DebugChanged` |
| `Panel.UpdateVisibility` edges | `Panel` | `shown` / `hidden (<reason>)` via `DebugChanged` |
| `Presets.Save/Load/Delete` | `Preset` | `saved '%s'` / `loaded '%s'` / `deleted '%s'` |
| `OnEnable` | `Init` | `PremadeRegions=%s, PGF seams=%s` via `DebugAtEnable` |

The per-result env hook stays silent (it runs once per search result). Add a test per new line only
where its absence would hide a refusal (the Apply refusals), asserting the line lands with logging on
and does not with it off.

## D5 — Bring `test_disabled.lua` to the ten steps (PGE-05)

Rewrite around a real `enableAddon()` and the kit's recording AceEvent mock (no probe):

1. Snapshot `R_on` (every registered event by target and name — the five FEATURE_EVENTS), `T_on`
   (empty; assert it), `F_on` (the panel shown via a PGF fake on the dungeon category). Assert `R_on`
   non-empty.
2. Disable through `Helpers.Set("enabled", false)`.
3. Assert the registry holds none of `R_on`, by count and by name. `-- red under: drop the UnregisterEvent loop in NS.StandDown`.
4. Assert no timer armed (and stays so).
5. Assert the panel is hidden.
6. Fire every event in `R_on` plus `PLAYER_REGEN_DISABLED`, and drive the PGF dialog hook and the env
   hook; assert zero SavedVariables writes (snapshot-compare `db.profile`/`db.char`/`db.global`), zero
   prints, zero shows. `-- red under: remove the IsStoodDown gate in EnvInject.Apply`.
7. Dispatch every `NS.COMMANDS` row and the bare `/pgfe`; assert normal output for the live list and
   exactly one refusal line for `apply` and `clear` with no PGF write.
8. Launcher: drive `OnClick("LeftButton")` → `OpenSettings` called, nothing written;
   `OnClick("RightButton")` through the kit's menu mock → *Enabled* clickable.
9. Re-enable; assert the set equals `R_on`; repeat with a filter option changed while disabled and
   assert the panel reflects it on stand-up.
10. Take `perf`, write `enabled=false`, release `perf` → still stood down; write `enabled=true` → up;
    repeat in the other order. `-- red under: StandUp called directly from the perf release`.

## D6 — Annotate the three positions (PGE-06, -07, -08)

```
# Modules -- each reads the # Core seams (NS.addon, NS.FEATURE_EVENTS, NS.STAND_DOWN/UP, NS.Bridge)
# at file load, so the whole group is LOAD-BEARING below # Core; within the group the order is free.
...
# LOAD-BEARING: reads NS.addon, appends NS.FEATURE_EVENTS / NS.STAND_UP and installs the env hook
# through NS.Bridge (core\PGFE.lua, core\PGFBridge.lua) at file load.
modules\EnvInject.lua
...
# LOAD-BEARING: takes NS.L and NS.addon as upvalues and installs the dialog hook through NS.Bridge
# at file load.
modules\Panel.lua
...
# LOAD-BEARING: captures NS.SchemaRuntime.Get/Set/FindRow/ApplyDefault into the Slash descriptor at
# load, so it sits below settings\Schema.lua.
settings\Slash.lua
```

No line moves. The TOC is the harness's load list (`test_harness` derives it), so the suite proves the
order is unchanged.

## D7 — Decide the perf harness (PGE-09)

- **(a) Exemption (matches `docs/performance.md:15`).** Commit the §12 sweep (the E7 census already is
  one: five low-frequency events, no timer, no `OnUpdate`; the env hook runs only during an LFG search,
  which the player starts), add the register row citing `performance-§12` with the trigger *the first
  OnUpdate handler, repeating ticker, or in-combat event handler doing real work*, then remove the
  instance and `core/PerfSetup.lua`, the `perf` COMMANDS row, `PremadeGroupsFilterExtensionPerfDB` from
  the TOC and `.luacheckrc`, `debugprofilestop`, `docs/perf-analysis/README.md` (its Documentation-map
  row becomes *Not applicable*), and shrink `docs/performance.md` to one screen. The Lifecycle latch
  keeps its `disabled` hold; the `perf` hold simply never gets taken. Release notes name the exemption
  (automated-tests-§3). `LibKa0s/Perf*.lua` stays vendored (whole-folder).
- **(b) Wire a real bucket.** Bracket `EnvInject.Apply` with Shape A and a load-time `local Perf =
  NS.Perf`, declare `{ key = "envInject" }`, and ship `tests/perf.lua` with the zero-overhead scenario
  (capture off allocates no more than with the bracket absent) plus the PremadeRegions/no-PremadeRegions
  pair. Deterministic assertions only (performance-§9).

Recommendation: (b) if the owner wants to measure the per-result hook (it is the one real hot path);
otherwise (a). Either clears the release gate's perf line.

## D8 — Prove the reset (PGE-10)

New `tests/test_reset.lua`: two profiles; set `global.minimap.shown = false`, turn the debug console
on, write a non-default `enabled`; run `Helpers.RestoreAllDefaults()`; assert the active profile is
back to defaults, the other profile untouched, the profile list and the current profile unchanged, the
console row swept, `minimap.hide` still `true`, and `OnProfileReset` re-evaluated the latch. Repeat via
the General page's Defaults path (`ctx.panel.defaultsOnClick` → popup `OnAccept`).

## D9 — One enabled accessor (PGE-11, PGE-12)

Launcher descriptor: `isEnabled = function() return NS.SchemaRuntime.Get("enabled") ~= false end`.
For the Slash descriptor the owner decides: the dispatcher's gate refuses feature verbs; while only the
perf hold is taken, refusing `apply` is still right (the addon is inert), but the line says "disabled".
Either keep the latch read and accept the wording (record nothing — it is a SHOULD-level dependent), or
move the gate to the stored row too and let `apply` write PGF state during a capture. Recommended: keep
the Slash gate on the latch, change only the launcher. Add a launcher case: perf hold taken → tooltip
*Enabled: Yes*.

## D10 — Logo names and size (PGE-13, PGE-14)

`git mv media/logos/pgfe.logo.128.tga media/logos/premadegroupsfilterextension.logo.128.tga` (and
`pgfe.logo.tga`, `pgfe.logo.png` likewise); update `## IconTexture`, `core/LauncherSetup.lua:13`,
`settings/Panel.lua:17`, the `DEPENDENCIES.md` recipe and any test pinning the path. Set
`MAIN_LOGO_SIZE = 300`. The `.pkgmeta` glob `media/logos/*.png` needs no change. Binary renames keep the
`binary` attribute (extension-keyed).

## D11 — Documents (PGE-15, PGE-16, PGE-17, PGE-19, PGE-22)

- `DEPENDENCIES.md` Release/assets: add *Python 3 (standard library only) — `tools/realm_map_diff.py`,
  the realm-map maintenance diff (`docs/realm-map-maintenance.md`)*, with `python3 --version`; reword
  "One entry".
- Localization: route the eight literals through `NS.L` (new `enUS` keys), or file the English-only
  register row citing `localization-§1` with the trigger *the first non-English locale file added to
  `locales/`*, and fix `docs/scope.md:33` to match whichever is chosen.
- Attached panel: register row citing `standalone-windows` — the panel is a child of PGF's dialog and
  wears PGF's chrome so the two read as one window; trigger *the panel becoming movable or shown
  without PGF's dialog*.
- General visibility: either add the composed dropdown (drop `omit = { visibility = true }`) and make
  `Panel.UpdateVisibility` honor it (*Never* hides the panel; *Only out of combat* hides it in combat), or
  write one sentence in `docs/settings-panel.md` recording why the row does not apply.
- `CLAUDE.md:24`: point at `docs/audits/2026-10-09/`.

## D12 — Labels (PGE-18) and roster (PGE-21)

`gh label edit "state:untriaged" --color ff0000`, `state:done` `00ff00`, `state:triaged` `ffff00`,
`state:will-not-do` `0000ff`, `severity:critical` `110000`, `severity:high` `110800`,
`severity:medium` `111100`, `severity:low` `001100`. Roster: a row in WowAddonStandards
`standards/ADDONS.md` (`Ka0s Premade Groups Filter Extension | ../../PremadeGroupsFilterExtension/ |
https://github.com/tusharsaxena/PremadeGroupsFilterExtension | Enabled`) — an upstream change, outside
this repo.

## D13 — AceTimer (PGE-20)

Optional: remove `"AceTimer-3.0"` from `NewAddon`, the TOC line and `libs/AceTimer-3.0/`; or keep it
deliberately. No behavior depends on it.

## Ordering constraints

- D6 (TOC comments) before any change that moves a TOC line (D10 does not move one).
- D7(a) removes `perf` from `NS.COMMANDS`: regenerate `docs/test-cases.md` and the README badge in the
  same change (testing-§5), and update D5's step 7 list.
- D2(b), if chosen, changes what D5 step 6 snapshots and what D8 resets; do D2 before D5 and D8.
- D10 renames binaries: one commit, with the path updates.
