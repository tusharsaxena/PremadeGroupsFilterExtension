# Analysis — 20261031-212020

- **Addon:** PremadeGroupsFilterExtension 1.0.0
- **Verdict:** green
- **Commit:** 2c97779 (feat/2026-10-31-findings-remediation)
- **Previous run:** 20261031-202055

## Headline

All four suites pass and the tree was clean (`manifest.json`). The previous run's `perf` failure is
gone: `combatEvents` allocates 28113.1 bytes/iter, down from 30641.4, and `perf.txt` records no failed
assertion. Complexity is clean with no function above CCN 15, the largest at 14, and
`tests/test_panel.lua` has left the 1000–1500 band. Nothing is left to act on from this run.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-202055 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 69 files | [`lint.txt`](lint.txt) | Files 67 → 69, still 0/0 |
| tests | pass | 456 passed, 1 skipped, 0 failed, 457 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 453 → 457, same one skip |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | fail → pass; `combatEvents` 30641.4 → 28113.1 bytes/iter |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 9540 → 9598, functions 1408 → 1416, band files 2 → 1 |

| Metric | Value |
|---|---|
| Total NLOC | 9598 |
| Functions | 1416 |
| Avg NLOC / function | 5.8 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**tests.** Pass, with one skip that is pre-existing: the kit's diagnostics opt-out case. This addon
keeps the default, so the case does not apply (`tests.txt`). The skip is counted in the total and not
in `passed`.

**complexity.** Sighted and measured: `blindFiles` and `crashedFiles` are both 0, and nothing warns
(`manifest.json`).

## What moved

- **lint:** 67 → 69 files, 0/0 unchanged.
- **tests:** 453 → 457 cases; failures unchanged at 0, skips unchanged at 1.
- **perf:** the suite moved fail → pass. `combatEvents` fell 30641.4 → 28113.1 bytes/iter, and the
  failed assertion the previous `perf.txt` carried is absent from this one. The scenario count (6)
  and every api/iter figure are unchanged. The other five scenarios held their bytes/iter. The
  ms/iter figures moved in both directions, and `perf.txt` says timings are for orientation only, so
  they are not read as a change.
- **complexity:** Total NLOC 9540 → 9598 and functions 1408 → 1416, which is growth: avg NLOC (5.8),
  avg CCN (2.0), max CCN (14) and avg tokens (51.8) are unchanged. Band files 2 → 1:
  `tests/test_panel.lua` left the band, and `modules/Panel.lua` went 1026 → 1032 LOC, still on notice.

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

None. Both actions of the previous run are closed by this one: `combatEvents` passes, and
`tests/test_panel.lua` is out of the band.
