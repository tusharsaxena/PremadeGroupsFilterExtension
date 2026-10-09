# Analysis — 20261009-082905

- **Addon:** Ka0s Premade Groups Filter Extension 0.1.0 (release run, `--release 0.1.0`)
- **Verdict:** green
- **Commit:** 2c78ddb (feat/2026-10-09-m-plus-v0.1)
- **Previous run:** 20261009-075822

## Headline

The runner's verdict is green: lint 0/0, 186 of 187 cases passed with 1 declared skip, complexity
sighted with nothing above CCN 15 (`manifest.json`). **The release gate is not met**: `perf` is a
skip (no `tests/perf.lua`), and at the tag a skip is NOT EVALUATED, not a pass. `v0.1.0` cannot be
tagged on this record. Between the two runs the addon went from scaffold to the full M+ v0.1 feature
set: cases 103 → 187, functions 404 → 653, with averages nearly flat.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261009-075822 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 51 files | [`lint.txt`](lint.txt) | Files 50 → 51; still 0/0 |
| tests | pass | 186 passed, 1 skipped, 0 failed, 187 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Passed 102 → 186, total 103 → 187; the same one skip |
| perf | skip | not measured: no `tests/perf.lua` | — | Unchanged (skip both runs) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | See below |

| Metric | Value |
|---|---|
| Total NLOC | 4144 |
| Functions | 653 |
| Avg NLOC / function | 4.8 |
| Avg CCN | 2.0 |
| Max CCN | 13 |
| Avg tokens / function | 40.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**tests.** The one skip is the kit's diagnostics opt-out case ("an addon that opts out lands the
report and leaves logging off"), which does not apply: this addon keeps the default and its report
turns logging on, a behavior the case above it pins (`tests.txt`). Pre-existing, unchanged since
the previous run, and correct.

**perf.** Skipped for the first of `automated-tests-§3`'s two sanctioned reasons: the addon ships
**no** `tests/perf.lua`. It holds no `performance-§12` exemption, and it should not: it has a real
per-result hot path, PGF's `PutPremadeRegionInfo` post-hook in `modules/EnvInject.lua`, which runs
once per search result. This record therefore says nothing about runtime cost, and the release gate
cannot be evaluated until the scenarios exist.

**complexity.** Sighted: `blindFiles` 0 in `manifest.json`. The highest CCN is
13, `S.SetMany` in `settings/SchemaSetup.lua` (the library-absent host stub, as at the previous
run). The highest in the new feature code are `identity` in `modules/Diagnostics.lua` and
`EnvInject.PlayerKeywords` (11 each), then `Apply.Run` and `Expression.Strip` (10 each), all from
`complexity.txt`. `PlayerKeywords` and `identity` score on `and`/`or` guards, not branching.

## What moved

- **lint:** files 50 → 51; warnings and errors stayed at 0/0.
- **tests:** total 103 → 187 (+84). The new cases are the feature suites filled by plan Tasks 2–8:
  regions 10, targeting 7, season 6, expression 9, filters 4, presets 3, envinject 8, bridge 12,
  apply 10 and panel 25 (`test-cases.md`). Skips stayed at 1.
- **perf:** skip in both runs; nothing moved because nothing was measured.
- **complexity:** NLOC 2010 → 4144 and functions 404 → 653, because the addon grew. Avg NLOC per
  function 4.0 → 4.8, avg CCN 1.9 → 2.0, max CCN 13 → 13, warnings 0 → 0. The averages barely moved,
  so the growth did not make the code denser. Avg tokens is new to this write-up (40.0); the previous
  analysis did not record it.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

## Actions

1. Write `tests/perf.lua` with the env-hook scenarios (PremadeRegions absent and present, plus the
   stood-down zero-overhead case), and in the same change bracket `EnvInject.Apply` and declare the
   `envInject` bucket in `core/PerfSetup.lua` (performance-§3). New here: no issue tracks it yet.
   Then re-run `--release 0.1.0`; the tag needs `perf` at pass.
2. Run the in-game smoke tests (`docs/smoke-tests.md`, every row in *Pending sign-off*) before the
   tag; nothing in this bundle covers real frames or PGF's real dialog.
