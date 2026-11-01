# Analysis — 20261101-143040

- **Addon:** PremadeGroupsFilterExtension 1.0.0
- **Verdict:** green
- **Commit:** e5ba7dd (feat/2026-11-01-full-skinning)
- **Previous run:** 20261101-025325

## Headline

All four suites pass on a clean tree under the label `FS-PG full skinning, LibKa0s v1.85.0`
(`manifest.json`). Against the previous run, tests grew 463 → 469, the same one skip stands, and one
perf figure moved: `combatEvents` allocates 16 bytes more per iteration, inside its ceiling. No
function is above CCN 15, the largest at 14. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-025325 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 70 files | [`lint.txt`](lint.txt) | Files 69 → 70 |
| tests | pass | 468 passed, 1 skipped, 0 failed, 469 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 463 → 469, same one skip |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | `combatEvents` 28113.1 → 28129.1 bytes/iter; api/iter unchanged in all six |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 9716 → 9941, functions 1430 → 1465, avg tokens 52.0 → 52.2 |

| Metric | Value |
|---|---|
| Total NLOC | 9941 |
| Functions | 1465 |
| Avg NLOC / function | 5.8 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 52.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**tests.** Pass, with one skip that is pre-existing: the kit's diagnostics opt-out case. This addon
keeps the default, so the case does not apply (`tests.txt`). The skip is counted in the total and not
in `passed`, and at the release gate it is not evaluated.

**complexity.** Sighted and measured: `blindFiles` and `crashedFiles` are both 0, and nothing warns
(`manifest.json`).

## What moved

- **lint:** 69 → 70 files, the new `core/WidgetsSetup.lua`; 0/0.
- **tests:** 463 → 469 cases; failures unchanged at 0, skips unchanged at 1. The new cases cover the
  Ka0s menu on the panel's dropdowns, the library-absent arm, the shared menu closing with the panel,
  the tooltip and input roles in every skin and the title's alignment (`test-cases.md`).
- **perf:** the scenario count (6) and every api/iter figure are unchanged, `combatEvents` included at
  143.00. `combatEvents` allocates 28113.1 → 28129.1 bytes/iter, under the 28138 ceiling in
  `tests/perf.lua`: `Panel.Refresh` now refills the Presets dropdown's rows. Timings are for
  orientation only and are not read as a change.
- **complexity:** Total NLOC 9716 → 9941 and functions 1430 → 1465, which is growth from the vendored
  and panel changes. Avg NLOC (5.8), avg CCN (2.0) and max CCN (14) did not move. Avg tokens rose
  52.0 → 52.2, not a density signal on its own. Band files stay at 1 and over-cap files at 0.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `modules/Panel.lua` | 1158 | on notice: cohesive, the row builders, layout and paint of the one attached panel frame; split the row builders out before it reaches 1500 lines |

No entry is new this run, so no Disposition cell is blank. `modules/Panel.lua` rose 1063 → 1158 lines
inside the band it already sat in, and the runner carried its disposition forward.

## Actions

None.
