# 05 — Final summary (review, 2026-10-10)

*Written ahead of the work. It assumes every change in `04_EXECUTION_PLAN.md` landed and every check in `03_SMOKE_TESTS.md` passed. Fill in the commit range and sign-off when that is true.*

## Headline

This cycle makes the addon measurable again and closes several quiet failure modes. The complexity suite had been crashing on one file, which also blocked the release gate; it now reads every file. The Mythic+ readout no longer re-asks the server for season data on every reply. A hand-damaged filter block is refused instead of becoming an unparseable expression. Every read of Premade Groups Filter internals goes back through the bridge, so a PGF rename now says "not supported" instead of silently disabling the spec exclusion. The EllesmereUI paint checks the theme API before it starts. Twelve missing locale keys are defined, and the stray English strings are routed through the locale table. The disabled-state and bridge tests can now fail. Three tooling and doc fixes go upstream.

## Counts

Critical fixed: 0, High fixed: 0, Medium fixed: 7 (F-001..F-007, F-007 upstream), Low fixed: 11 (F-008..F-018; F-017 and F-018 upstream). Nothing deferred, provided M5's upstream releases ship. If they do not, F-007, F-017 and F-018 stay open in their own repos and nothing in this addon changes.

## Changes by theme

### T1 — Complexity suite sighted
- **What changed:** the region-tag hook table is a named local instead of a literal inside the loop header.
- **Why it mattered:** `lizard` crashed on it, so no file was measured and the release gate could not pass.
- **Findings / changes:** F-001 / C-01.
- **Files:** `modules/RegionTags.lua`.

### T2 — One season-data request per loading episode
- **What changed:** the readout asks for map info once until data arrives.
- **Why it mattered:** an empty map table (between seasons) turned each server reply into another request.
- **Findings / changes:** F-002 / C-02.
- **Files:** `modules/Panel.lua`, `tests/wow_mock.lua`, `tests/test_panel.lua`.

### T3 — Managed-block damage
- **What changed:** a wrapped block whose close marker was deleted is refused as damage.
- **Why it mattered:** before, it produced an unbalanced expression PGF could not parse, while reporting success.
- **Findings / changes:** F-003 / C-03.
- **Files:** `modules/Expression.lua`, `tests/test_expression.lua`, `docs/ARCHITECTURE.md`.

### T4 — Every PGF read behind the bridge
- **What changed:** `C.SPECIALIZATIONS` (a checked seam) and `C.MAP_ID_TO_KEYWORDS` are read through `core/PGFBridge.lua` accessors.
- **Why it mattered:** a PGF rename silently made *No one with my spec* pass every group.
- **Findings / changes:** F-004 / C-04.
- **Files:** `core/PGFBridge.lua`, `modules/EnvInject.lua`, `modules/Season.lua`, `.luacheckrc`, `docs/ARCHITECTURE.md`, `tests/test_bridge.lua`.

### T5 — Skin paint fails closed
- **What changed:** the facade's twelve primitives are checked before painting, the paint is pcall-guarded, and `applied` is set only on success.
- **Why it mattered:** a different EllesmereUI build could half-paint the panel and lose its first show.
- **Findings / changes:** F-005 / C-05.
- **Files:** `modules/EUISkin.lua`, `tests/test_euiskin.lua`.

### T6 — Locale hygiene
- **What changed:** 12 keys added to `enUS.lua`, one dead key removed, four hard-coded strings routed through `NS.L`.
- **Findings / changes:** F-006, F-010 / C-06.
- **Files:** `locales/enUS.lua`, `settings/Slash.lua`, `settings/Panel.lua`.

### T7 — UX and observability
- **What changed:** the Apply message drops the key range while targeting is off. Tooltips always hide. The skin's scale handler skips work when unpainted. Diagnostics report installed hooks and the filter options. The launcher's *Enabled* entry reads the stored setting.
- **Findings / changes:** F-009, F-011, F-012, F-013, F-015 / C-07..C-11.
- **Files:** `modules/Apply.lua`, `modules/Panel.lua`, `modules/EUISkin.lua`, `modules/Diagnostics.lua`, `modules/EnvInject.lua`, `modules/RegionTags.lua`, `core/LauncherSetup.lua`, `locales/enUS.lua`, `docs/data-flow.md`, `docs/debug.md`.

### T8 — One secret-safety rule
- **What changed:** `Regions.GetRegion` refuses a name that is not concat-safe.
- **Findings / changes:** F-016 / C-12.
- **Files:** `modules/Regions.lua`, `tests/test_regions.lua`.

### T9 — Tests that can fail
- **What changed:** `test_disabled` walks every declared feature event and checks `config`/bare `/pgfe`. `test_bridge`'s minimized-commit case gains a falsifiable assertion.
- **Findings / changes:** F-008, F-014 / C-13.
- **Files:** `tests/test_disabled.lua`, `tests/test_bridge.lua`.

### T10 — Upstream
- **What changed:** LibKa0s's complexity runner reports a `lizard` crash by file, and its sanitizer handles the for-in literal shape. The standard's hazard table is corrected and its roster lists this addon. This addon re-vendors the kit.
- **Findings / changes:** F-007, F-017, F-018 / U-1..U-3.
- **Files here:** `tests/_kit/` (re-vendor only), `CLAUDE.md` provenance line.

## API / behavior changes

- `MSG_APPLIED_NO_TARGETING` text changes and takes no argument. `Apply.Run` with targeting off returns no range, and `Apply.LastRange` is nil while targeting is off.
- `Bridge.Check()` names a new seam, `C.SPECIALIZATIONS`. New accessors: `Bridge.Specializations()`, `Bridge.MapKeywords(mapID)`.
- `/pgfe diagnostics` gains `hooks:` and filter-option lines.
- The launcher menu's *Enabled* entry reflects `profile.enabled` rather than the latch.
- New locale keys only; no key renamed. No slash verb, schema row, default or SavedVariables shape changes.

## Saved-variable / migration notes

None. `NS.SCHEMA_VERSION` stays 1.

## Deprecated-API migrations

None. No deprecated call was found in the addon's own code.

## Performance impact

No perf-tagged change has a measured before/after. The addon has no perf bracket and no `tests/perf.lua`. C-02's evidence is the `/etrace` event count in `03_SMOKE_TESTS.md`. C-12 adds one pcall per search result, which is **unmeasured** and owed to the perf follow-up below.

## Test and complexity movement

- Pass count **325 → 333** (334 with C-06's optional locale guard). `docs/test-cases.md` and the README `[tests]` badge move in each commit that adds a case.
- Complexity: from **fail, 54 blind files** (today) to an expected **pass, 0 warnings, max CCN 14, 1064+ functions**, measured in scratch with C-01's hoist. The next release's regeneration of `docs/automated-tests/RESULTS.md` should confirm it.

## Known follow-ups

- **Perf evidence:** declare the `envInject` bucket with its bracket and write `tests/perf.lua` (env hook with and without PremadeRegions, stood-down zero-overhead), as `docs/performance.md` already owes. Out of this review's change-set, and an audit item.
- **F-002 verification:** the off-season baseline in C-02's smoke step decides whether the loop was real.

## Verification evidence

- `03_SMOKE_TESTS.md` with its sign-off table filled: *pending*.
- Commit range / PR: *pending*.

## Suggested PR description

```
Fix the 2026-10-10 review findings (F-001..F-018)

- Hoist RegionTags' painter hooks so lizard can read the tree again (F-001)
- Request season map info once per loading episode (F-002)
- Refuse a wrapped [pgfe] block with no close marker as damage (F-003)
- Read PGF's spec/keyword constants through the bridge; check C.SPECIALIZATIONS (F-004)
- Check EllesmereUI's facade before painting; pcall the paint (F-005)
- Define every locale key in enUS; route stray English (F-006, F-010)
- Apply message, tooltip hide, scale guard, diagnostics hooks, launcher pair (F-009, F-011..F-013, F-015)
- Secret-safe region lookup (F-016)
- test_disabled walks every feature event; test_bridge minimized commit can fail (F-008, F-014)
- Re-vendor the LibKa0s test kit for the lizard-crash reporting fix (F-007, F-017 upstream)

Tests: 325 -> 333. Complexity: fail (54 blind) -> pass (0 blind).
```
