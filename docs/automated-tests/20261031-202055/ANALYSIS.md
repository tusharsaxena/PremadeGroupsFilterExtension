# Analysis — 20261031-202055

- **Addon:** PremadeGroupsFilterExtension 1.0.0
- **Verdict:** amber
- **Commit:** e6bbce4 (feat/2026-10-31-font-pickers-skin-faces)
- **Previous run:** 20261010-195814

## Headline

Lint and tests pass, so the run and the commit are not blocked. `perf` failed one assertion:
`combatEvents` allocated 30641.4 bytes/iter over its 28186-byte ceiling (`perf.txt`), a real
regression that **gates the tag**. Complexity is clean with no function above CCN 15, the largest
at 14 (`manifest.json`), and `modules/Panel.lua` newly entered the 1000–1500 band.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261010-195814 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 67 files | [`lint.txt`](lint.txt) | Files 60 → 67, still 0/0 |
| tests | pass | 452 passed, 1 skipped, 0 failed, 453 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 415 → 453, same one skip |
| perf | **fail** | 6 scenarios, 1 assertion failed | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | pass → fail; `combatEvents` 28161.1 → 30641.4 bytes/iter |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 8679 → 9540, functions 1281 → 1408, band files 1 → 2 |

| Metric | Value |
|---|---|
| Total NLOC | 9540 |
| Functions | 1408 |
| Avg NLOC / function | 5.8 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 2 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**perf.** A regression, not a flake: this suite's ceilings assert deterministic allocation, and
`tests/perf.lua` sets each one 24 bytes above the measured figure so the smallest added allocation
trips it. API calls did not move (`combatEvents` stays at 143 api/iter), so the growth is
allocation only. Running `tests/perf.lua` over exported snapshots of the commits since the previous
run (a diagnostic, not part of this bundle) puts the first crossing at `5dc2e86` and the largest
step at `1ecf7a7`, the chevron commit. That commit made `Panel.Refresh`'s `applyLayout` call
`placeMinMax` and its `tintChevrons`, whose `ipairs({ ... })` builds a throwaway table per refresh,
beside new skin token reads. The fix, or a re-measured ceiling, is for the owner to rule on; this
run changes no code.

**tests.** The one skip is the kit's diagnostics opt-out case: this addon keeps the default, so the
case does not apply (`tests.txt`).

**complexity.** Sighted and measured: `blindFiles` and `crashedFiles` are both 0, and nothing warns.

## What moved

- **lint:** 60 → 67 files, 0/0 unchanged.
- **tests:** 415 → 453 cases; failures unchanged at 0, skips unchanged at 1.
- **perf:** the failure above. The scenario count (6) and every api/iter figure are unchanged.
  `searchRowPaint` moved 160.4 → 160.6 bytes/iter, under its ceiling. The other four scenarios held
  their bytes/iter. The combat event list dropped `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`
  (`perf.txt`), and the allocation rose even so.
- **complexity:** Total NLOC 8679 → 9540 and functions 1281 → 1408, which is growth: avg NLOC (5.8),
  avg CCN (2.0) and max CCN (14) are unchanged. Avg tokens 51.1 → 51.8.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `modules/Panel.lua` | 1026 | **new this run.** on notice: cohesive, the row builders, layout and paint of the one attached panel frame; split the row builders out before it reaches 1500 lines |
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1169 | on notice: test-only file; split by area (rows / presets / collapse / copy box) before it reaches 1500 lines or at the next panel feature |

## Actions

1. Bring `combatEvents` back under its ceiling in `modules/Panel.lua` (drop the per-refresh table in
   `tintChevrons`, then re-measure) or re-measure the ceiling in `tests/perf.lua` with the reason
   recorded. The tag stays gated until `perf` passes. New here, no tracked owner yet.
2. Split `tests/test_panel.lua` by area, per its disposition. Carried from the previous run.
