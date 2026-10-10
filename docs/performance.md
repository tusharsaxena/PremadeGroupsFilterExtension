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

## The combat-path sweep (criterion (a))

Swept with `grep -rn -E 'RegisterEvent|RegisterUnitEvent|OnUpdate|C_Timer|NewTicker|ScheduleTimer|ScheduleRepeatingTimer|hooksecurefunc|HookScript|SetScript'`
over every file outside `libs/`, `tests/` and `docs/`. The search found no `OnUpdate`, `C_Timer`
call, ticker or AceTimer (removed, C-35). `C_Timer` appears only as a `.luacheckrc` read-global.
There is one registration site, and every hook runs on a player UI action.

| Site | Hit | Work per event or call | Runs in combat? |
|---|---|---|---|
| `core/PGFE.lua:42` | `registerFeatureEvents`, through `NS.SafeRegisterEvent` (`core/CoreSetup.lua:55-79`) | The only registration site. It registers the 8 `NS.FEATURE_EVENTS` rows below on enable and stand-up, and unregisters them on stand-down | — |
| `modules/EnvInject.lua:82-83` | `ACTIVE_PLAYER_SPECIALIZATION_CHANGED`, `PLAYER_SPECIALIZATION_CHANGED` | `RefreshPlayer`: 3 calls (spec index, spec info, `UnitClass`) | Rare (a spec change) |
| `modules/Panel.lua:883-885` | `CHALLENGE_MODE_MAPS_UPDATE`, `CHALLENGE_MODE_COMPLETED`, `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE` | `OnPanelSeasonData`: Smart level, then the readout rebuilt over 8 dungeons. 34 calls, about 7 KB | Rare (a season-data reply, a completed key, an affix change) |
| `modules/Panel.lua:886` | `PLAYER_ENTERING_WORLD` | Re-arms the season request, then `Panel.UpdateVisibility` (the readout as above). 35 calls | At a loading screen |
| `modules/EUISkin.lua:382-383` | `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED` | Re-lays out the skin's checkbox marks; returns before a paint. 0 calls | Rare (a scale change) |
| `core/PGFE.lua:105-108` | AceDB `OnProfileChanged` / `Copied` / `Reset` | Migrations, panel refresh, the latch re-read | Player action |
| `core/PGFBridge.lua:173` | `hooksecurefunc(PGF, "PutPremadeRegionInfo")` | `EnvInject.Apply`, above: 1.2 calls and 80 bytes per result, 0 while stood down | Only while PGF filters a search the player started |
| `core/PGFBridge.lua:184-186` | `SwitchToPanel`, dialog `OnShow` / `OnHide` | `Panel.UpdateVisibility` | Player action |
| `modules/RegionTags.lua:74` | `LFGListSearchEntry_Update`, `LFGListApplicationViewer_UpdateApplicantMember` | One row tag: 5.2 calls, 160 bytes | Only while the Group Finder repaints |
| `modules/EUISkin.lua:176-177`, `:236-240` | Skin checkbox `OnClick` / `SetChecked`; min/max glyph `OnEnter` / `OnLeave` | One accent repaint; one vertex color | Player action |
| `modules/Panel.lua:90-96` | Tooltip `OnEnter` / `OnLeave` | Fill and show `GameTooltip`; hide it | Player action |
| `modules/Panel.lua`, `settings/Panel.lua` | `SetScript` / `HookScript` on the addon's own widgets (click, edit box, focus, settings `OnShow`) | One handler per player action | Player action |
| `modules/Apply.lua:22` | `InCombatLockdown()` in `precheck` | Apply refuses in combat | Refused |

`PLAYER_REGEN_DISABLED` and every other combat event are unregistered. `combatEvents` fires them
with `InCombatLockdown` true and finds no handler and no call.
