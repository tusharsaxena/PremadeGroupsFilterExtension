# Analysis — 20261010-195814

- **Addon:** Ka0s Premade Groups Filter Extension 1.0.0 (release run, `--release 1.0.0`; the runner
  read `0.1.0` from the TOC before the bump, which is why `manifest.json` carries `addonVersion`
  0.1.0 beside `release` 1.0.0)
- **Verdict:** green
- **Commit:** cd648c8 (main)
- **Previous run:** 20261010-130739

## Headline

The release gate for 1.0.0 passes: all four suites pass at a clean tree, no function is above CCN
15 and `blindFiles` is 0 (`manifest.json`). Since `20261010-130739` measured `33c358f`, ten commits
landed; the only code among them is the Smart checkbox spacing (`modules/Panel.lua`,
`modules/EUISkin.lua` and their tests), which adds 14 NLOC and moves two functions' CCN up by two,
both far under the threshold. Nothing to act on before tagging.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261010-130739 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 60 files | [`lint.txt`](lint.txt) | No; `lint.txt` is byte-identical |
| tests | pass | 414 passed, 1 skipped, 0 failed, 415 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No; `tests.txt` and `test-cases.md` are byte-identical (the spacing change edited existing cases, it added none) |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | Count, api/iter and bytes/iter unchanged; only ms/iter differs |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 8665 → 8679, avg tokens 51.0 → 51.1; two functions' CCN up |

| Metric | Value |
|---|---|
| Total NLOC | 8679 |
| Functions | 1281 |
| Avg NLOC / function | 5.8 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.1 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**tests.** The one skip is the kit's diagnostics opt-out case ("an addon that opts out lands the
report and leaves logging off"). This addon keeps the default, so the case does not apply (`tests.txt`).

**perf.** `perf` passes on the same 6 scenarios in `tests/perf.lua` (`perf.txt`, `perf.json`). The
addon holds the `performance-§12` no-combat-path exemption and ships the offline scenarios anyway, so
the suite ran and measured: this release's perf gate is a measurement, not the no-scenarios skip.

**complexity.** Sighted: `blindFiles` 0. Max CCN is 14 and nothing warns (`complexity.txt`).

## What moved

- **lint:** nothing; 0/0 over 60 files.
- **tests:** nothing; 415 cases, 414 passed and the same one skip.
- **perf:** the scenario count (6), api/iter and bytes/iter are unchanged for every scenario. Only
  ms/iter differs (`combatEvents` 0.15104 → 0.13516), which `perf.txt` says is for orientation
  within one run only.
- **complexity:** Total NLOC 8665 → 8679 and avg tokens 51.0 → 51.1; the function count (1281),
  averages, max CCN (14) and band count are unchanged. Per function (`complexity.txt`, matched by
  name): `shrinkCheckBox` (`modules/EUISkin.lua`) CCN 8 → 10, now moving the Smart label by what the
  box lost; `paintBody` (`modules/EUISkin.lua`) CCN 6 → 8, now passing the Smart label in;
  `buildSmart` (`modules/Panel.lua`) 96 → 98 tokens at the same CCN. Two test cases grew by a few
  lines. Line numbers further down `modules/Panel.lua` shifted by the new comment lines.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1202 | on notice: test-only file; split by area (rows / presets / collapse / copy box) before it reaches 1500 lines or at the next panel feature |

The file grew 1197 → 1202 lines with the Smart spacing assertions; the disposition is carried. No
production file is in the band.

## Actions

1. Split `tests/test_panel.lua` by area (rows / presets / collapse / copy box) before it reaches
   1500 lines or at the next panel feature, whichever comes first. Carried from the previous run.
2. Confirm the Smart spacing in the client under both skins before tagging (`docs/smoke-tests.md`
   APPLY-15 and SKIN-2). This bundle does not cover real frames or the EllesmereUI paint.
