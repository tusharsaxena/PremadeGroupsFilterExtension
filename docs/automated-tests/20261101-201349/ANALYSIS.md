# Analysis — 20261101-201349

- **Addon:** PremadeGroupsFilterExtension 1.0.0
- **Verdict:** green
- **Commit:** e638513 (feat/2026-11-01-full-skinning)
- **Previous run:** 20261101-143040

## Headline

All four suites pass on a clean tree at the branch's code head, which closes the gap the previous
record left: it measured `e5ba7dd`, and `80da57a` then changed code with no run behind it (`manifest.json`).
Tests grew 469 → 517 with the kit's two skin gates adopted, skips stayed at one, and no perf ceiling or
api count moved. No function is above CCN 15, the largest at 14. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-143040 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 71 files | [`lint.txt`](lint.txt) | Files 70 → 71 |
| tests | pass | 516 passed, 1 skipped, 0 failed, 517 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 469 → 517, same one skip |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | `searchRowPaint` 160.6 → 161.3 and `applicantRowPaint` 160.4 → 161.1 bytes/iter; api/iter unchanged in all six |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 9941 → 10097, functions 1465 → 1495 |

| Metric | Value |
|---|---|
| Total NLOC | 10097 |
| Functions | 1495 |
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

- **lint:** 70 → 71 files, the new `tests/skin_surfaces.lua`; 0/0.
- **tests:** 469 → 517 cases; failures unchanged at 0, skips unchanged at 1. The growth is mostly the
  kit's `test_skin_values` and `test_skin_switch`, the latter one case per declared surface in each of
  its two passes, plus the panel's per-entry tooltips, its divider and the unknown realm's tag
  (`test-cases.md`).
- **perf:** the scenario count (6) and every api/iter figure are unchanged. The two row-paint scenarios
  allocate about 0.7 bytes/iter more, and both stay under their ceilings (`perf.txt`). `combatEvents`
  is unchanged at 28129.1 bytes/iter. Timings are for orientation only and are not read as a change.
- **complexity:** Total NLOC 9941 → 10097 and functions 1465 → 1495, growth from the re-vendored kit
  and library. Avg NLOC (5.8), avg CCN (2.0), max CCN (14) and avg tokens (52.2) did not move. Band
  files stay at 1 and over-cap files at 0.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `modules/Panel.lua` | 1181 | on notice: cohesive, the row builders, layout and paint of the one attached panel frame; split the row builders out before it reaches 1500 lines |

No entry is new this run, so no Disposition cell is blank. `modules/Panel.lua` rose 1158 → 1181 lines
inside the band it already sat in, and the runner carried its disposition forward.

## Actions

None.
