# 02 — Proposed changes

Standards resolved: **Ka0s WoW Addon Standard v2.77.0 (2026-10-07)**, fetched verbatim. Every change
below stays inside it. No change targets `libs/` or `tests/_kit/`.

## HLD

### Theme A: the managed block must be safe when this addon is not running (F-001)

The block lives in PGF's state, which outlives this addon's runtime. That covers a stand-down, an
AddOns-list disable and an uninstall. The block therefore has to evaluate to "no restriction" whenever
the hook did not run.

- **Chosen:** the hook writes a sentinel `env.pgfe_on = true` and Merge wraps the clauses as
  `( not pgfe_on or ( <clauses> ) )`. When the hook does not run, `pgfe_on` is `nil`, `not nil` is
  `true`, and the block passes everything.
- **Rejected: strip the block at stand-down.** That writes into PGF's state from the stand-down path,
  and it does nothing for an AddOns-list disable or an uninstall. It also adds a second effect to the
  latch, which slash-commands-§7 wants to stay pure teardown.
- **Rejected: keep injecting neutral values while stood down.** slash-commands-§7 lets a
  `hooksecurefunc` body only gate and return.
- **Trade-off:** adds about 20 characters to the block (well under `MAX_LENGTH` 2000). Blocks written by
  0.1.0 have the old shape. Strip already removes them by marker, so the next Apply or Clear rewrites
  them, and nothing needs to change in the migration runner.

### Theme B: every version-variant call goes through Compat (F-002)

Route the spec read through `NS.Compat`, the seam that already exists (compat:
"MUST route every deprecated-API call through `Compat`"). Remove the lint allowance that hid the
bypass.

### Theme C: panel input and Apply truthfulness (F-003, F-004, F-008, F-009)

- Number boxes commit only a complete, valid value and re-sync on focus loss.
- Apply refuses while PGF's dialog is minimized, with a message naming the fix (maximize the dialog).
  It does not write and search into an inactive panel.
- **Rejected:** having Apply maximize the dialog itself. That would call PGF's dialog methods from our
  code, which widens the PGF surface `docs/ARCHITECTURE.md`'s documented deviation allows.
- The range field follows the level. The Apply message reports the rows actually ticked and drops the
  count when targeting is off.

### Theme D: a disabled-state suite that can fail (F-005)

Rewrite `tests/test_disabled.lua` to the slash-commands-§7 ten-step shape against the addon's real
`NS.FEATURE_EVENTS`, with no injected probe.

### Theme E: measure the hot path before the tag (F-006)

Add an offline `tests/perf.lua` (performance-§9) with an env-hook scenario. Whether to declare an
`envInject` bucket, or to record performance-§12's no-combat-path exemption, is a decision for the
owner. The PGF search hook rarely runs in combat, so §12 may qualify. Either way, the decision is
recorded, not inferred.

### Theme F: robustness (F-007, F-010, F-011)

`Presets.Load` merges over the current defaults. The profile callbacks refresh the attached panel. The
hook body tolerates a non-string leader name.

## Upstream change-set

None.

## LLD

### C-001: neutral-when-absent managed block (F-001)

- `modules/EnvInject.lua`, `EnvInject.Apply`: after the stood-down return, set `env.pgfe_on = true`
  before the other writes.
- `modules/Expression.lua`, `Expression.Merge`, both branches:
  ```lua
  -- before
  local body = "( " .. table.concat(clauses, " and ") .. " )"
  -- after
  local body = "( not pgfe_on or ( " .. table.concat(clauses, " and ") .. " ) )"
  ```
  The user-text branch keeps `body .. " and ("`, so its result is `( not pgfe_on or ( … ) ) and ( U )`.
- `docs/ARCHITECTURE.md:232-233`, `docs/data-flow.md`, the spec line: replace "Clear before disabling"
  with the neutral-when-absent behavior.
- Tests:
  - New `test_expression` cases evaluate a Merge result with `loadstring` + `setfenv` against an env
    with and without `pgfe_on`.
  - The `test_envinject` stood-down case gains `assertNil(env.pgfe_on)` with
    `-- red under: drop the IsStoodDown return in EnvInject.Apply`.
  - New `test_apply` case: Apply, `/pgfe disable`, evaluate as PGF does, and get `true`.
  - `test_apply`'s Normalize assertion (`"( pgfe_samespec == 0 ) and ( voice or myrealm )"`) changes
    text. Editing that expected string is a deliberate behavior change, not a weakened test.
- **Risk:** low. The pure function's output changes shape. Strip's marker logic is untouched.
- **Count movement:** adds about 3 cases. `docs/test-cases.md` and the README `Tests` badge move in the
  **same** commit (testing-§5).

### C-002: Compat-routed spec read (F-002)

- `modules/EnvInject.lua:39-47`: `local idx = NS.Compat.GetSpecialization()` and
  `specID, _, _, _, role = NS.Compat.GetSpecializationInfo(idx)`.
- `.luacheckrc:27`: remove `"GetSpecialization", "GetSpecializationInfo",`. Keep `C_SpecializationInfo`
  only if a file still reads it. After the change none does, so remove it too. Lint must stay 0/0 (lint).
- `tests/wow_mock.lua`: add `C_SpecializationInfo.GetSpecialization/GetSpecializationInfo` returning
  the seeded spec. Add a `test_envinject` case with the globals set to `nil` that still computes
  `beastmastery_hunters`.
- **Risk:** low. LibKa0s-Compat already prefers the namespaced rung.
- **Count:** +1 case. Inventory and badge move in the same change.

### C-003: number boxes commit whole values (F-003)

- `modules/Panel.lua`, `numberBox`: keep `OnTextChanged` for the live readout only. Commit through
  `accept(n)` in `OnEnterPressed` and `OnEditFocusLost`. When the value is rejected, restore the box
  from `NS.Filters.Get()` so the box never shows a value that is not stored.
- Tests: rewrite the `test_panel` level case to type `4` then `45` keystroke by keystroke, then lose
  focus. It must assert `keyLevel` unchanged and the box re-synced. Do the same for the age box.

### C-004: refuse Apply/Clear while PGF is minimized (F-004)

- `core/PGFBridge.lua`: add `Bridge.IsDungeonPanelActive()`, which returns `d.activePanel == panel()`.
- `modules/Apply.lua`, `precheck`: after `IsDungeonCategory`, return `"MSG_MINIMIZED"` when not active.
- `locales/enUS.lua`: `L.MSG_MINIMIZED = "Maximize the Premade Groups Filter dialog first; nothing was applied."`.
  It follows the existing `MSG_*` key style and localization-§2.
- Tests: `test_apply` case with `activePanel = { name = "mini" }`: refusal, `refresh == 0`, state untouched.
- Update the `modules/Apply.lua` header comment and `docs/data-flow.md`, which currently say "minimized
  counts".

### C-005: range and message truthfulness (F-008, F-009)

- `modules/Panel.lua:38-40`: `rangeText()` returns `RangeText(Filters.Get().keyLevel)`. Drop the
  `LastRange` preference. Keep `Apply.LastRange` for the message.
- `modules/Apply.lua:52,57`: capture `local ticked = NS.Bridge.SetDungeons(...)` and report `ticked`.
  When `targets == nil`, return `"MSG_APPLIED_NO_TARGETING"` (new key: `"Applied; key range %s."`).

### C-006: `test_disabled.lua` to slash-commands-§7 shape (F-005)

Replace the probe with assertions over the mock's recorded registration set for this addon's AceEvent
target:
1. `R_on` contains exactly the 5 `NS.FEATURE_EVENTS` names.
2. After `Helpers.Set("enabled", false)`, the set is empty by count and by name.
3. Fire every name in `R_on` and get zero SV writes, zero prints, zero shows.
4. Every `NS.COMMANDS` verb answers.
5. Change `char.filters` while disabled, re-enable, and confirm the panel and readout reflect the change.
6. Run both `perf`/`disabled` hold orders.

Add `-- red under:` comments on the three negative assertions (testing-§12). This changes the case count
in `test_disabled.lua` (5 → about 8), and the inventory and badge move in the same commit.

### C-007: offline perf scenario for the env hook (F-006)

- New `tests/perf.lua`: load the list from `Loader.tocFiles` (testing-§9), and run 1000 synthetic results
  through `PGF.PutPremadeRegionInfo` with the hook installed. Record allocations (`collectgarbage("count")`
  delta) and `GetCurrentRegion`/`GetRealmName` call counts. Deterministic counts only. No wall-clock
  assertion (performance-§9).
- Once the scenario shows the cost, consider a per-portal memo (`lookups` keyed by raw realm string) in
  `Regions.GetRegion`. That optimization is **not** proposed until the scenario shows a number.
- Record the bucket-vs-§12 decision in `docs/ARCHITECTURE.md`.
- Not counted as test cases (testing-§7). No badge movement.

### C-008: `Presets.Load` merges over defaults (F-007)

- `modules/Presets.lua`, `Load`: build `fresh = copy(NS.C.CHAR_DEFAULTS.filters)`, overlay
  `copy(src)`, then refill `live` from `fresh`. Table identity is preserved.
- Test: a preset missing `regions` loads without error and `regions` is `{}`.

### C-009: profile callbacks refresh the attached panel (F-010)

- `core/PGFE.lua`, `reloadProfile`: `if NS.Panel and NS.Panel.frame then NS.Panel.Refresh() end`,
  before the latch re-read. If the latch stands the addon down, the stand-down hides the panel anyway.

### C-010: tolerate a non-string leader name (F-011)

- `modules/Regions.lua:47`: `if type(leaderName) ~= "string" or leaderName == "" then return nil end`.
  No `pcall` in the per-result path. A type check is cheaper and sufficient.

## Standards conformance

| Change | Conformance |
|---|---|
| C-001 | slash-commands-§7: the hook still gates and returns while stood down. No write is added at stand-down. |
| C-002 | Brings the addon into line with compat (spec APIs through `core/Compat.lua`). Lint keeps 0/0 (lint). |
| C-003, C-005 | New strings go through `NS.L` (localization-§1/§2). |
| C-004 | Reads PGF state only, through `core/PGFBridge.lua`, which stays within the documented PGF deviation. Rejected: calling PGF's maximize, which would widen that deviation. |
| C-006 | Implements slash-commands-§7 *conformance test* and testing-§12. The inventory moves in the same change (testing-§5). |
| C-007 | performance-§9 runner. Load list from the TOC (testing-§9). Scenarios are not cases (testing-§7). |
| C-008–C-010 | No standard rule engaged beyond savedvariables-§2 (defaults stay in `defaults/Profile.lua`). |

Expected watch-list movement for the next release's regeneration: none. Max CCN is 13 today, and none
of these changes should push a function past 15. `Expression.Merge` and `Apply.Run` gain one decision
each.
