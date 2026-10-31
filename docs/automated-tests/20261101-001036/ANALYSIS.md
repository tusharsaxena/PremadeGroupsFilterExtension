# Analysis — 20261101-001036

- **Addon:** PremadeGroupsFilterExtension 1.0.0
- **Verdict:** green
- **Commit:** 91b79e3 (feat/2026-10-31-findings-remediation)
- **Previous run:** 20261031-212020

## Headline

All four suites pass on a clean tree under the label `v1.84.0-adoption` (`manifest.json`). Against the
previous run, tests grew 457 → 459, the same one skip stands, and every perf allocation and API figure
held. Complexity is clean with no function above CCN 15, the largest at 14. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-212020 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 69 files | [`lint.txt`](lint.txt) | Not moved |
| tests | pass | 458 passed, 1 skipped, 0 failed, 459 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 457 → 459, same one skip |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | api/iter and bytes/iter unchanged in all six |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 9598 → 9642, functions 1416 → 1419, avg tokens 51.8 → 51.9 |

| Metric | Value |
|---|---|
| Total NLOC | 9642 |
| Functions | 1419 |
| Avg NLOC / function | 5.8 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.9 |
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

- **lint:** did not move: 69 files, 0/0.
- **tests:** 457 → 459 cases; failures unchanged at 0, skips unchanged at 1. Both new cases are in
  `test_settings_layout.lua` (11 → 13) and cover the Filters pointer (`test-cases.md`).
- **perf:** the scenario count (6) and every api/iter and bytes/iter figure are unchanged,
  `combatEvents` included at 143.00 api/iter and 28113.1 bytes/iter (`perf.txt`). All six ms/iter
  figures rose, for example `combatEvents` 0.17577 → 0.31532. Every suite's own duration also rose in
  this run (`manifest.json`, total 17132 → 28419 ms), and `perf.txt` says timings are for orientation
  only, so they are not read as a change.
- **complexity:** Total NLOC 9598 → 9642 and functions 1416 → 1419, which is growth. Avg NLOC (5.8),
  avg CCN (2.0) and max CCN (14) did not move. Avg tokens rose 51.8 → 51.9, which is the rounding-size
  edge of the figure and not a density signal on its own. Band files stay at 1 and over-cap files at 0.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `modules/Panel.lua` | 1032 | on notice: cohesive, the row builders, layout and paint of the one attached panel frame; split the row builders out before it reaches 1500 lines |

No entry is new this run, so no Disposition cell is blank.

## Actions

None.
