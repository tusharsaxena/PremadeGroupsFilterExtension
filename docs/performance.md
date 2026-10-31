# Performance — Ka0s Premade Groups Filter Extension

**The addon brackets nothing.** It holds the performance-§12 no-combat-path exemption (owner
checkpoint D1, 2026-10-10; the register row is in `docs/ARCHITECTURE.md` -> `## Documented
deviations`). No `core/PerfSetup.lua`, no `PremadeGroupsFilterExtensionPerfDB`, no `perf` verb (it
stays reserved and unregistered) and no suspend contract. `libs/LibKa0s/` stays vendored whole,
`Perf.lua` included.

- **Criterion (a)** holds, and the sweep below is its proof: no `OnUpdate` handler, no timer of
  any kind, and no event handler doing more than occasional work in combat.
- **Criterion (b)** applies too. The capture windows open on the player's combat state
  (performance-§7), and this addon's hot paths run while the player browses the Group Finder, so
  every declared bucket would read `0.000` by construction.
- **Re-arm trigger**, in the standard's words: "the first `OnUpdate` handler, repeating ticker, or
  in-combat event handler doing real work re-arms the full wiring MUST".
- **The measurement** is the offline scenarios in `tests/perf.lua`, outside the green gate,
  recorded in each `docs/automated-tests/` run. `combatEvents` measures the per-event cost in the
  sweep, and `envStoodDown` pins the stood-down hook at 0 bytes and 0 calls.

## Where the addon spends time

- **Per search result** (the hottest path): PGF calls `PutPremadeRegionInfo(env, leaderName)` once
  per result while it filters. The post-hook sets `pgfe_on` and two numbers from cached keywords.
  Only without PremadeRegions does it do one realm lookup, behind the C-32 concat probe.
- **Per Group Finder row paint:** the two `modules/RegionTags.lua` post-hooks make one `C_LFGList`
  read, the same lookup and one `SetText`. They do nothing while stood down, with `showRegionTags`
  off, or with PremadeRegions loaded.
- **On Apply:** one pass over the season's 8 dungeons and PGF's 8 rows, one string build, then
  PGF's own re-filter. It is a player action, and it refuses in combat.
- **Panel:** `Panel.Refresh` runs on show and on a widget change. The frame is built once, lazily.
  A refresh allocates about 7.6 KB in `tests/perf.lua`, most of it the readout's strings. It
  re-anchors the collapse button only when the skin's title band moved, and only an owner on the
  `eui` source, or waiting on a reload, pays for `GetEUIStatus`'s tables (about 1.2 KB).

## The combat-path sweep (criterion (a))

Swept with `grep -rn -E 'RegisterEvent|RegisterUnitEvent|OnUpdate|C_Timer|NewTicker|ScheduleTimer|ScheduleRepeatingTimer|hooksecurefunc|HookScript|SetScript'`
over every file outside `libs/`, `tests/` and `docs/`. The search found no `OnUpdate`, ticker,
repeating timer or AceTimer (removed, C-35). The one `C_Timer` read is `C_Timer.After` in
`settings/OptionsSetup.lua:114`, the settings color picker's 50 ms drag throttle: one call per
drag step, on a player action. There are two registration sites, and every hook runs on a player
UI action.

| Site | Hit | Work per event or call | Runs in combat? |
|---|---|---|---|
| `core/PGFE.lua:41` | `registerFeatureEvents`, through `NS.SafeRegisterEvent` (`core/CoreSetup.lua:56-80`) | The feature registration site. It registers the 6 `NS.FEATURE_EVENTS` rows below on enable and stand-up, and unregisters them on stand-down | — |
| `modules/EnvInject.lua:85-86` | `ACTIVE_PLAYER_SPECIALIZATION_CHANGED`, `PLAYER_SPECIALIZATION_CHANGED` | `RefreshPlayer`: 3 calls (spec index, spec info, `UnitClass`) | Rare (a spec change) |
| `modules/Panel.lua:1003-1005` | `CHALLENGE_MODE_MAPS_UPDATE`, `CHALLENGE_MODE_COMPLETED`, `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE` | `OnPanelSeasonData`: Smart level, then the readout rebuilt over 8 dungeons. 34 calls, about 8 KB | Rare (a season-data reply, a completed key, an affix change) |
| `modules/Panel.lua:1006` | `PLAYER_ENTERING_WORLD` | Re-arms the season request, then `Panel.UpdateVisibility` (the readout as above). 35 calls | At a loading screen |
| `core/PGFE.lua:116-118` | AceDB `OnProfileChanged` / `Copied` / `Reset` | Migrations, panel refresh, the latch re-read | Player action |
| `core/PGFBridge.lua:173` | `hooksecurefunc(PGF, "PutPremadeRegionInfo")` | `EnvInject.Apply`, above: 1.2 calls and 80 bytes per result, 0 while stood down | Only while PGF filters a search the player started |
| `core/PGFBridge.lua:184-186` | `SwitchToPanel`, dialog `OnShow` / `OnHide` | `Panel.UpdateVisibility` | Player action |
| `modules/RegionTags.lua:102` | `LFGListSearchEntry_Update`, `LFGListApplicationViewer_UpdateApplicantMember` | One row tag: 5.2 calls, 160 bytes | Only while the Group Finder repaints |
| `modules/Panel.lua:111-120` | Tooltip `OnEnter` / `OnLeave` | Fill and show `GameTooltip`; hide it | Player action |
| `modules/Panel.lua`, `settings/Panel.lua` | `SetScript` / `HookScript` on the addon's own widgets (click, edit box, focus, settings `OnShow`) | One handler per player action | Player action |
| `core/SkinSetup.lua:311` | `PLAYER_REGEN_ENABLED` on a private one-shot frame (D11) | Registered only while the first-run skin picker is held in combat; it unregisters and drops its frame when it fires, then shows the picker once. The stand-down drops it the same way | Once, as combat ends |
| `modules/Apply.lua:37` | `InCombatLockdown()` in `precheck` | Apply refuses in combat | Refused |

`PLAYER_REGEN_DISABLED` and every other combat event are unregistered (the picker's one-shot
`PLAYER_REGEN_ENABLED` exists only while a held start waits). `combatEvents` fires them
with `InCombatLockdown` true and finds no handler and no call.
