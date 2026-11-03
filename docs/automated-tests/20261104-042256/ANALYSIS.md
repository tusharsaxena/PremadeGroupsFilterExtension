# Analysis — 20261104-042256

- **Addon:** PremadeGroupsFilterExtension 1.0.0
- **Verdict:** green
- **Commit:** ba5a536 (feat/2026-11-01-full-skinning), clean
- **Previous run:** 20261102-023410 (99d7869)

## Headline

Green: lint 0/0 over 72 files and 520 of 521 cases passing, with the one standing skip. Since the
previous run, 4 cases were added and one function newly crossed CCN 15. That function is `extent`
in `tests/test_skin.lua` (CCN 18), a test helper added by R5-PG2. It does not gate the commit, but
the tag needs zero functions above CCN 15, so it should be peeled before the next release.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261102-023410 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 72 files | [`lint.txt`](lint.txt) | files 71 → 72; still 0/0 |
| tests | pass | 520 passed, 1 skipped, 0 failed, 521 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | total 517 → 521, passed 516 → 520; skip unchanged |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | same 6 scenarios; api/iter and bytes/iter unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | warnings 0 → 1, max CCN 14 → 18 |

Every figure in the complexity table comes from `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 10314 |
| Functions | 1511 |
| Avg NLOC / function | 5.9 |
| Avg CCN | 2.1 |
| Max CCN | 18 |
| Avg tokens / function | 53.0 |
| Warnings (CCN > 15) | 1 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The complexity measurement is sighted: `blindFiles` is 0 and `crashedFiles` is 0. The single
warning is `extent@212-232@./tests/test_skin.lua` (21 NLOC, CCN 18, 195 tokens, per
[`complexity.txt`](complexity.txt)). This is a regression of this branch, not a newly measured
function: the previous run, at 99d7869, predates commit 2d3ca07 (R5-PG2), which added it. The
function resolves a mock region's top and bottom from its anchor points. It does this with genuine
branching: an anchor-less fallback to the parent, a per-point TOP/BOTTOM/middle split and three
height-completion cases. That branching is real control flow, not `or` defaulting.

The `tests` skip is the standing diagnostics-contract case. The addon keeps the default
(`Kit.diagnostics.enablesLogging` is not false), so the opt-out case does not apply. See
[`tests.txt`](tests.txt).

## What moved

- **lint:** 1 more file in scope (71 → 72). Still 0 warnings / 0 errors.
- **tests:** +4 cases (517 → 521), per the [`test-cases.md`](test-cases.md) diff against the
  previous bundle:
  - the panel's title and arrow sharing Ka0s Default's band middle without the library
  - the launcher descriptor passing `openSkinPicker`
  - the title and min/max button centered on the band in every skin
  - the Ka0s Friz Quadrata TT to Ka0s Ubuntu migration

  One case was renamed: the collapsed-panel case now reads "is exactly the band and its edges,
  nothing below it, in every skin". The skip count did not move (1).
- **perf:** the same six scenarios. `api/iter` and `bytes/iter` are identical for every scenario
  (for example, `combatEvents` is 143.00 api and 28129.1 bytes per iteration). `ms/iter` moved
  within noise, and timings are not compared across runs.
- **complexity:**
  - NLOC 10097 → 10314 (+217) and functions 1495 → 1511 (+16): growth.
  - Avg NLOC 5.8 → 5.9, avg CCN 2.0 → 2.1, avg tokens 52.2 → 53.0: a slight densening.
  - Max CCN 14 → 18 and warnings 0 → 1: the new `extent` test helper.
  - Band files unchanged at 1. `modules/Panel.lua` grew 1181 → 1192 LOC and remains on notice.
  - Over-cap files 0, blind files 0, crashed files 0.

## Complexity watch list

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|
| `extent` | 18 | `tests/test_skin.lua` | **Peel next.** This is new in R5-PG2 (2d3ca07). It is a test helper with genuine anchor-resolution branching. Hoist the per-point TOP/BOTTOM/middle classification and the height completion into local helpers before the next tag. |

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `modules/Panel.lua` | 1192 | on notice: cohesive, the row builders, layout and paint of the one attached panel frame; split the row builders out before it reaches 1500 lines |

## Actions

1. `tests/test_skin.lua`: peel `extent` (CCN 18) below 15 before the next release run. This is new
   here; no deviation ID or review finding tracks it yet.
2. `modules/Panel.lua` (1192 LOC): no action this run. It stays on notice under its existing
   disposition.
