# Analysis — 20261010-130739

- **Addon:** Ka0s Premade Groups Filter Extension 0.1.0 (non-release run, no `--label`)
- **Verdict:** green
- **Commit:** 33c358f (fix/2026-10-10-audit-review)
- **Previous run:** 20261010-122612

## Headline

Green on all four suites at a clean tree (`manifest.json`), with every measured figure the same as
the previous run. Two commits landed after `20261010-122612` measured `ee090c7`: `431a604` (that
bundle, its RESULTS row, CLAUDE.md and the ledger) and `33c358f` (the TGA recipe in
`DEPENDENCIES.md` and the ledger). Both are docs and ledger only. The C-13 rule wants the record to
measure the commit that will be merged, so this run supersedes `20261010-122612` as the fix branch's
record. It is not a release record.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261010-122612 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 60 files | [`lint.txt`](lint.txt) | No; `lint.txt` is byte-identical |
| tests | pass | 414 passed, 1 skipped, 0 failed, 415 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No; `tests.txt` and `test-cases.md` are byte-identical |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | Count, api/iter and bytes/iter unchanged; only ms/iter differs |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No; `complexity.txt` is byte-identical |

| Metric | Value |
|---|---|
| Total NLOC | 8665 |
| Functions | 1281 |
| Avg NLOC / function | 5.8 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**tests.** The one skip is the same kit diagnostics opt-out case as before ("an addon that opts out
lands the report and leaves logging off"). This addon keeps the default, so the case does not apply,
and the case above it pins the default (`tests.txt`).

**perf.** `perf` passes on the same 6 scenarios in `tests/perf.lua` (`perf.txt`, `perf.json`). The
addon holds the `performance-§12` no-combat-path exemption (`docs/ARCHITECTURE.md`,
`## Documented deviations`), and it ships the offline scenarios anyway, which is why this suite reads
`pass` and not the exemption's skip. `envStoodDown` reads 0.00 api and 0.0 bytes per iteration
(the stood-down zero-overhead case). The per-event `combatEvents` table matches the previous run
line for line, with no handler on `PLAYER_REGEN_DISABLED`.

**complexity.** Sighted: `blindFiles` 0 in `manifest.json`. Max CCN is 14 and nothing warns.
`complexity.txt` is byte-identical to the previous bundle's, so the leaders are unchanged from that
write-up.

## What moved

- **lint:** nothing; 0/0 over 60 files, as before.
- **tests:** nothing; 415 cases, 414 passed and the same one skip. `test-cases.md` is identical to
  the previous bundle's.
- **perf:** the scenario count (6), api/iter and bytes/iter are unchanged for every scenario. Only
  the ms/iter timings differ (for example `combatEvents` 0.13517 → 0.15104), and `perf.txt` says
  those are for orientation within one run only, so the difference means nothing.
- **complexity:** nothing; every footer figure and the band count are the same.

This is what a docs-and-ledger-only delta should produce. The previous bundle stays as frozen
evidence of `ee090c7`. It is superseded only because two doc commits landed on top of it.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1197 | on notice: test-only file; split by area (rows / presets / collapse / copy box) before it reaches 1500 lines or at the next panel feature |

The entry is unchanged, so the runner carried the Disposition forward. No production file is in the
band.

## Actions

1. Split `tests/test_panel.lua` by area (rows / presets / collapse / copy box) before it reaches
   1500 lines or at the next panel feature, whichever comes first. This is carried from the previous
   run and is still the disposition above.
2. Run the in-game smoke checks the fix branch still owes before merging (`docs/smoke-tests.md`).
   This bundle does not cover real frames, PGF's real dialog or the EllesmereUI paint.
