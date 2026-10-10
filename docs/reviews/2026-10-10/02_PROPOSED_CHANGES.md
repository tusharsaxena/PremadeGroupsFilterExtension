# 02 — Proposed changes (review, 2026-10-10)

The standard these changes were checked against is the **Ka0s WoW Addon Standard v2.78.0** (2026-10-09). Its index was fetched from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master/standards/STANDARDS.md`, and the sections were read from `../WowAddonStandards` at `e6ab2b8`. No change below edits `libs/` or `tests/_kit/`.

## HLD — themes

| Theme | Findings | Rationale |
|---|---|---|
| **T1. Make the complexity suite sighted again** | F-001 | Release gate (`automated-tests-§3`). The fix goes in the source, as the section prescribes: hoist the literal table. Rejected: a local lizard workaround or guard (anti-pattern #92; `testing-§9` drift) |
| **T2. Stop the season-data request loop** | F-002 | Ask the server once per "loading" episode, not once per event |
| **T3. Harden the managed-block parser** | F-003 | Treat the orphaned-wrap shape as damage, the way the two existing shapes are, so Apply and Clear refuse rather than ship unbalanced text |
| **T4. Put every PGF read behind the bridge** | F-004 | Restore the documented invariant (`docs/ARCHITECTURE.md` *PGF seams*). A constant that has to be present is checked, and a constant used only for display is read through a bridge accessor |
| **T5. Make the skin paint fail closed** | F-005 | Check the facade's shape before claiming `applied`, and pcall the paint so a failure is logged instead of half-painting |
| **T6. Locale hygiene** | F-006, F-010 | `localization-§1/§3`: route strings through `NS.L`, define every key in `enUS.lua`, delete the dead key |
| **T7. UX / observability tidy-ups** | F-009, F-011, F-012, F-013, F-015 | Small consistency fixes in already-owned code |
| **T8. Tests that can fail** | F-008, F-014, plus new cases for T2/T3/T4/T5 | `testing-§12`: negative assertions need a falsifiable partner |
| **T9. Upstream** | F-007, F-017, F-018 | Cross-repo; re-vendor commit here |
| **T10. Record the consistent guard** | F-016 | Add an `NS.IsConcatSafe` check on the env path so both region callers share one rule |

Alternatives considered and rejected:
- **T2.** Removing `RequestMapInfo` altogether was rejected: a fresh login does need one request before season bests arrive. A timer-based retry was rejected because it adds a timer to stand down (`slash-commands-§7`).
- **T4.** Adding both constants to `SEAMS` (so "PGF version not supported" fires) was rejected for `MAP_ID_TO_KEYWORDS`, which is used only for display and should not disable the addon. It is accepted for `C.SPECIALIZATIONS`, because without it the composition filter is silently inert.
- **T5.** Wrapping the paint in `pcall` alone was rejected: a failure would still leave `applied = true` on a half-painted panel. Checking the shape first and setting `applied` only after a successful paint is the change.
- **T9.** Patching `tests/_kit/run-automated-tests.sh` locally is forbidden (`library-stack-§5`, `testing-§1`, CLAUDE.md "Never edit libs/ or tests/_kit/").

## Upstream change-set

| ID | Repo / file | Fix | Bump | This repo then |
|---|---|---|---|---|
| U-1 (F-007) | LibKa0s `testkit/run-automated-tests.sh` | Capture `lizard`'s exit status. On non-zero, or a footer that is not eight numeric fields, record complexity `fail` with note "lizard crashed on `<file>`" (a per-file retry finds the file), and write numeric zeros, never the traceback, into `manifest.json` | kit revision 38 → 39 (LibKa0s minor/patch per its own release rules) | A re-vendor commit of `tests/_kit/` (and `libs/LibKa0s/` if the release moves it), byte-identical to the tag, with the `CLAUDE.md` provenance line moved in the same commit (`testing-§11` vendor-sync gate) |
| U-2 (F-017) | LibKa0s `testkit/lizard_sighted.lua`; WowAddonStandards `standards/standards/automated-tests.md` hazard table | Sanitizer: recognize a function literal inside a `for ... in` header and either defuse it or have parity name it. Standard: correct the row's "what lizard does" cell to say it can raise and abort the run | kit revision (folded into U-1's release); standard patch version | The same re-vendor commit as U-1 |
| U-3 (F-018) | WowAddonStandards `standards/ADDONS.md` | Add the *Ka0s Premade Groups Filter Extension* row (`../../PremadeGroupsFilterExtension/`, launcher entries `Enabled`) | standard patch version | Nothing |

## LLD — change-set

### C-01 (F-001) — hoist the hook table in `modules/RegionTags.lua`
```lua
-- before (:64-67)
for name, fn in pairs({
    LFGListSearchEntry_Update = function(...) RegionTags.OnSearchEntryUpdate(...) end,
    LFGListApplicationViewer_UpdateApplicantMember = function(...) RegionTags.OnApplicantMemberUpdate(...) end,
}) do
-- after
local PAINTER_HOOKS = {
    LFGListSearchEntry_Update = function(...) RegionTags.OnSearchEntryUpdate(...) end,
    LFGListApplicationViewer_UpdateApplicantMember = function(...) RegionTags.OnApplicantMemberUpdate(...) end,
}
for name, fn in pairs(PAINTER_HOOKS) do
```
- **Risk:** none. The code is behavior-identical. `tests/test_regiontags.lua` already pins both hooks (its `-- red under: drop the ... hook` cases), so it serves as the characterization test `testing-§13` requires before a behavior-preserving refactor.
- **Measurement:** the scratch run with exactly this hoist gives 1064 functions, 0 warnings, max CCN 14 and 0 blind files. The next release regeneration should confirm it: `RESULTS.md`'s watch list goes from *Not sighted* to an empty warned list.
- **Conformance:** `automated-tests-§3` ("hoisting a function literal out of a `for ... in` header into a local is the usual one").

### C-02 (F-002) — request map info once per loading episode
`modules/Panel.lua`: add a file-local `requested` flag. `updateReadout` calls `RequestMapInfo()` only when it is false, and sets it. `OnPanelSeasonData` (an event that already brought data) clears the flag only after `GetDungeons()` answers non-nil.
```lua
local mapInfoRequested = false
local function updateReadout(f)
    local dungeons = NS.Season.GetDungeons()
    if not dungeons then
        f.readout:SetText(L.READOUT_LOADING)
        if not mapInfoRequested and C_MythicPlus.RequestMapInfo then
            mapInfoRequested = true
            C_MythicPlus.RequestMapInfo()
        end
        return
    end
    mapInfoRequested = false
    ...
```
- **Risk:** low. A login that needs a second request does not get one, but the next panel show after data arrives clears the flag, and the next `Refresh` after that asks again.
- **Tests:** the mock's `RequestMapInfo` must count calls. That lives in this addon's `tests/wow_mock.lua` (not `tests/_kit/`). New case in `test_panel.lua`: with an empty map table, firing `CHALLENGE_MODE_MAPS_UPDATE` three times causes ≤ 1 request (red under: drop the flag). **+1 case → the pass count moves 325 → ≥326, and `docs/test-cases.md` plus the README badge move in the same change.**

### C-03 (F-003) — orphaned wrap is damage
`modules/Expression.lua` `Strip`: when the begin block's body line ends in `and (` (the wrapped form, `body .. " and ("`), require a `MARK_CLOSE` line followed by `)` later in the text. If none is found, return `text, false`.
- Implementation sketch: while scanning `begin..end`, note `wrapped = lines[j-1]:match("and %($") ~= nil` (the body line just before the end marker). After the loop, if `wrapped` and no close was consumed, return damage.
- **Risk:** low. A text the addon wrote itself always carries the close line, so only hand-damaged text changes behavior (Apply and Clear now refuse with `MSG_DAMAGED`, which already tells the player to fix it by hand).
- **Tests:** two new cases in `test_expression.lua`: close-without-`)` (an existing branch, until now untested) and wrapped-without-close (red under: drop the new check). **+2 cases.**

### C-04 (F-004) — bridge accessors for the two PGF constants
`core/PGFBridge.lua`: add `Bridge.Specializations()` and `Bridge.MapKeywords(mapID)`, nil-guarded and read at call time, each citing PGF 7.6.2 lines (`Modules/Specializations.lua:25` and `Init.lua`). Add `{ "C.SPECIALIZATIONS", function() return pgf() and pgf().C and pgf().C.SPECIALIZATIONS end }` to `SEAMS`. `MAP_ID_TO_KEYWORDS` is deliberately not added, because it only feeds a display.
`modules/EnvInject.lua:47-49` and `modules/Season.lua:22-23` call the accessors instead. Update the `.luacheckrc:29-30` comment and the `docs/ARCHITECTURE.md` *PGF seams* table (a `C.SPECIALIZATIONS` row, *Checked* = yes, and a `C.MAP_ID_TO_KEYWORDS` row, *Checked* = no).
- **Risk:** a PGF build without `C.SPECIALIZATIONS` now shows "PGF version not supported", which is intended: it replaces a silently inert filter.
- **Tests:** `test_bridge.lua` "missing seam is named" gains the new seam (red under: drop the SEAMS row). **+1 case.**
- **Conformance:** keeps the bridge invariant `docs/ARCHITECTURE.md` records. It is not a deviation and needs no register row.

### C-05 (F-005) — the skin paint fails closed
`modules/EUISkin.lua`: a file-local `REQUIRED = { "Shell", "FadeNineSlice", "FadeRegions", "Checkbox", "EditBox", "Dropdown", "Button", "StateButtonLabel", "Font", "White", "GetAccentColor", "GetFont" }` (a load-time constant, not built per call). In `blocked()`, return `"facade lacks <name>"` for the first non-function member. In `TryApply`, run `paintShell`/`paintBody` under `pcall` and set `applied = true` only on success. On failure, `NS.Debug(TAG, "paint failed: %s", err)` and leave `applied` false. Do not retry automatically: `lastSkip` keeps the log line to one.
- **Risk:** after a failed pcall the panel may still carry partial art from the primitives that ran. That is no worse than today, and it is now logged.
- **Tests:** `test_euiskin.lua`: a facade without `StateButtonLabel` → `TryApply` returns false, `IsApplied()` is false, and nothing raises (red under: drop the shape check). **+1 case.**
- **Conformance:** reads only the facade EllesmereUI hands over, so the ratified `EllesmereUIDB` deviation row is untouched and no new deviation is added.

### C-06 (F-006, F-010) — locale hygiene
- Add the 12 keys to `locales/enUS.lua` (key = value, English, `localization-§2`), and delete the dead key at `:166-167`.
- Route the four hard-coded strings in `settings/Slash.lua:150, :171-172, :188` and `settings/Panel.lua:251-252` through `NS.L`, and add their keys. `"%s"` formats keep word order (`localization`).
- **Tests:** none required. If the owner wants a guard, an addon-side case comparing `L["..."]` literals in the load list against `enUS.lua` is the addon's own integration test, not a kit duplicate. **+1 case if adopted.**
- **Conformance:** `localization-§3` ("Delete it or wire it"), US English spelling (`localization-§5`).

### C-07 (F-009) — the Apply message with targeting off
`locales/enUS.lua:61`: `L.MSG_APPLIED_NO_TARGETING = "Applied (dungeon checkboxes left as they were)."`, with no range argument. In `modules/Apply.lua:61-63`, set `Apply.LastRange` only when `targets` is non-nil, and return `true, "MSG_APPLIED_NO_TARGETING"` with no argument. Keep `LastRange`, because `docs/data-flow.md:46` documents it and tests use it as a seam, but say in its doc comment that it is nil while targeting is off.
- **Tests:** update `test_apply.lua`'s "says so when targeting is off" expectation. The assertion changes and the count does not move.

### C-08 (F-011) — tooltips always hide
`modules/Panel.lua:96-99`: drop the `stoodDown()` early return from the `OnLeave` hook. The `OnEnter` gate stays. Do the same at `modules/EUISkin.lua:236-239`, since restoring a glyph's alpha writes no state.
- **Risk:** none. `GameTooltip:Hide()` is idempotent.

### C-09 (F-012) — register the skin's scale events only once a paint exists
Rejected as stated: moving the rows out of `NS.FEATURE_EVENTS` would create a second registration path, which is the anti-pattern `slash-commands-§7` warns against. **Accepted alternative:** keep the rows and make `OnEUISkinScale` return before `relayout()` when `not applied`. That is one comparison, and it documents the intent. The finding is accepted as Low and closed by that guard plus a comment.

### C-10 (F-013) — diagnostics say what is running
`modules/Diagnostics.lua`: the `registration` section adds `hooks: env=%s dialog=%s searchRow=%s applicantRow=%s`. This needs `Bridge.InstallEnvHook`'s return (store it as `NS.EnvInject.hooked` at `modules/EnvInject.lua:89`), `Bridge.HookDialog`'s return (store `NS.Panel.dialogHooked`), and RegionTags recording which painters it hooked (`RegionTags.hooked[name] = true`). It also adds a `filters` section of `out:add` lines over `NS.Filters.Get()` with raw values (the library formats them). Feature events are labelled `declared`, beside `stoodDown`.
- **Tests:** `test_setup.lua` or a new diagnostics case asserting the `hooks:` line reads `true` for all four under the mock (red under: drop the store at `:89`). **+1 case.**

### C-11 (F-015) — the launcher pair agrees
`core/LauncherSetup.lua:55`: `isEnabled = function() local p = NS.addon.db and NS.addon.db.profile; return not (p and p.enabled == false) end`. The setter already writes the stored path, so getter and setter now describe the same thing. The tooltip's *Enabled* line then shows the setting, and a perf suspend no longer reads as "disabled". AbsorbTracker does the same (`NS.GetSetting("enabled") ~= false`).
- **Risk:** low. During a perf arm the menu shows *Enabled* ticked while the addon is suspended, which is accurate about the setting.

### C-12 (F-016) — one secret-safety rule for region lookups
`modules/Regions.lua:48`: add `or not NS.IsConcatSafe(leaderName)` to the guard, so `GetRegion` itself is safe and `RegionTags.Tag`'s own check becomes redundant (keep it, it is cheap). This adds one pcall per search result on the env path. Accepted: there is no bracket and no `tests/perf.lua` to measure it, so record that it is unmeasured. The perf follow-up below owns measuring it.
- **Tests:** `test_regions.lua` with `NS.IsConcatSafe` stubbed false → nil (red under: drop the clause). **+1 case.**

### C-13 (F-008, F-014) — tests that can fail
- `tests/test_disabled.lua`: after `disable`, loop `NS.FEATURE_EVENTS` and assert `m.fireEvent(row[1]) == 0` for every row, naming the event in the message. Assert `config` and the bare `/pgfe` still answer while disabled (prints, or the options-open counter in the mock). **+1 case** (or extend the existing ones; keep the count delta explicit).
- `tests/test_bridge.lua:60-64`: also assert the stored state is untouched or written as intended, and add `-- red under: drop the activePanel check in Bridge.Commit`. Rename to "commit with minimized dialog leaves PGF's live panel alone". The count does not move.

### Pass-count note
C-02 (+1), C-03 (+2), C-04 (+1), C-05 (+1), C-10 (+1), C-12 (+1), C-13 (+1), plus optionally C-06 (+1): **325 → 333** (334 with the optional C-06 guard). `docs/test-cases.md` (regenerated by `lua tests/run.lua --list`) and the README `[tests]` badge **move in the same commit as each case**, never as a follow-up.

## Standards conformance (per change)

| Change | Introduces a deviation? | Rule that shaped it |
|---|---|---|
| C-01 | no | `automated-tests-§3` (source remedy, not a scanner); `testing-§13` satisfied by the existing `test_regiontags.lua` cases, which pin both hooks |
| C-02 | no | `slash-commands-§7` (no new timer to stand down) |
| C-03 | no | — |
| C-04 | no | restores `docs/ARCHITECTURE.md` *PGF seams*; `library-stack-§6` row already ratified for the hard dependency |
| C-05 | no | ratified `EllesmereUIDB` row unchanged; no new suite read |
| C-06 | no | `localization-§1`, `§3`, `§5` |
| C-07 | no | — |
| C-08 | no | `slash-commands-§7` (gates guard writes, not a Hide) |
| C-09 | no; the second-registration-path option was rejected | `slash-commands-§7`, anti-patterns #85 |
| C-10 | no | `debug-logging-§14` (sections read, never act) |
| C-11 | no | `launcher-§2` (the enable pair) |
| C-12 | no | `events-frames-taint-§8` |
| C-13 | no | `testing-§12`; `docs/test-cases.md` + badge move with the count (`testing-§5`) |
| U-1..U-3 | upstream only; no edit under `libs/` or `tests/_kit/` here | `library-stack-§5`, `testing-§1`, `testing-§11` |
