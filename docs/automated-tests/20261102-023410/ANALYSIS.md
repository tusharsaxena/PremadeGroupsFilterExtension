# Analysis — 20261102-023410

- **Addon:** PremadeGroupsFilterExtension 1.0.0
- **Verdict:** green
- **Commit:** 99d7869 (feat/2026-11-01-full-skinning)
- **Previous run:** 20261101-201349

## Headline

All four suites pass on a clean tree. Nothing moved in the code figures since the previous run: the
changes since then are the LibKa0s v1.85.0 re-cut refresh and the SF-PG-1 smoke-check record
(`manifest.json`). Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-201349 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 71 files | [`lint.txt`](lint.txt) | Unchanged |
| tests | pass | 516 passed, 1 skipped, 0 failed, 517 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Unchanged, same one skip |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | api/iter and bytes/iter unchanged in all six; timings differ (orientation only) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Unchanged |

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
| Files in the 1000-1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**tests.** The one skip is the kit's diagnostics opt-out case, which does not apply here (`tests.txt`).

**complexity (recorded, non-gating).** Sighted and measured; nothing warns (`manifest.json`).

## What moved

Nothing in lint, tests or complexity. Perf allocation figures are identical to the previous run;
`combatEvents` stays at 28129.1 bytes/iter (`perf.txt`).

## Complexity watch list

Carried forward unchanged: no warned functions; `modules/Panel.lua` stays the one file on notice in
the 1000-1500 band, disposition as in `RESULTS.md`.

## Actions

None.
