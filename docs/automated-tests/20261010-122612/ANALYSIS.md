# Analysis — 20261010-122612

- **Addon:** Ka0s Premade Groups Filter Extension 0.1.0 (non-release run, no `--label`)
- **Verdict:** green
- **Commit:** ee090c7 (fix/2026-10-10-audit-review)
- **Previous run:** 20261009-082905

## Headline

Green on all four suites at a clean tree (`manifest.json`). Lint is 0/0 over 60 files, 414 of 415
cases passed with the same one declared skip, and `perf` passes with 6 scenarios. The previous run
skipped `perf` because the addon shipped no `tests/perf.lua`. Complexity is sighted (`blindFiles` 0),
nothing is above CCN 15 (max 14), and `tests/test_panel.lua` is the first file to enter the
1000-1500 band. This run records the tip of the 2026-10-10 audit and review fix branch (C-13). It is
not a release record.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261009-082905 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 60 files | [`lint.txt`](lint.txt) | Files 51 → 60; still 0/0 |
| tests | pass | 414 passed, 1 skipped, 0 failed, 415 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Passed 186 → 414, total 187 → 415; the same one skip |
| perf | pass | 6 scenarios | [`perf.txt`](perf.txt) · [`perf.json`](perf.json) | skip → pass (`tests/perf.lua` now exists) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | See below |

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

**tests.** The one skip is the kit's diagnostics opt-out case ("an addon that opts out lands the
report and leaves logging off"). It does not apply here: this addon keeps the default, so its report
turns logging on, and the case above it pins that (`tests.txt`). This skip was also in the previous
run, and it is correct.

**perf.** `perf` passes on the 6 scenarios in `tests/perf.lua` (`perf.txt`, `perf.json`):
`envNoPR`, `envWithPR`, `envStoodDown`, `searchRowPaint`, `applicantRowPaint` and `combatEvents`.
The addon holds the `performance-§12` no-combat-path exemption (`docs/ARCHITECTURE.md`,
`## Documented deviations`), so no in-game perf harness is wired. The offline scenarios ship anyway,
which is why this suite reads `pass` and not the exemption's skip. `envStoodDown` reads 0.00 api and
0.0 bytes per iteration, which is the stood-down zero-overhead case. `combatEvents` drives every
feature event with `InCombatLockdown` true. The per-event table in `perf.txt` puts the cost in the
season refreshes (`CHALLENGE_MODE_MAPS_UPDATE`, `CHALLENGE_MODE_COMPLETED`,
`MYTHIC_PLUS_CURRENT_AFFIX_UPDATE` at 34 api each, `PLAYER_ENTERING_WORLD` at 35) and shows no
handler on `PLAYER_REGEN_DISABLED`. The timings are for orientation within this run only, as
`perf.txt` says.

**complexity.** Sighted: `blindFiles` 0 in `manifest.json`. The highest CCN is 14, shared by
`Expression.Strip` (`modules/Expression.lua`), `reloadProfile` (`core/PGFE.lua`),
`Panel.UpdateVisibility` (`modules/Panel.lua`), and two `tests/test_surface_parity.lua` helpers (an
anonymous function at 174-198 and `literalKeys`), all from `complexity.txt`. Next come `Apply.Run`,
`S.SetMany` and `logInstalls` at 13. None of them warns.

## What moved

- **lint:** files 51 → 60; warnings and errors stayed at 0/0.
- **tests:** total 187 → 415 (+228). Six suites are new since the previous run: `test_euiskin`
  32, `test_euisettings` 19, `test_euibridge` 17, `test_regiontags` 9, `test_diagnostics` 6 and
  `test_reset` 5. The largest growth in existing suites is `test_panel` 25 → 83, `test_apply`
  10 → 33, `test_disabled` 5 → 14, `test_expression` 9 → 18 and `test_filters` 4 → 12
  (`test-cases.md` against the previous bundle's). The one skip did not change.
- **perf:** skip → pass. The previous record said nothing about runtime cost. This one has a
  baseline for the 6 scenarios above, with nothing earlier to compare it to.
- **complexity:** NLOC 4144 → 8665 and functions 653 → 1281, because the addon grew. Avg CCN stayed
  at 2.0 and max CCN went 13 → 14, with warnings still 0. Avg NLOC per function went 4.8 → 5.8 and
  avg tokens 40.0 → 51.0, so functions got somewhat longer on average without getting more
  branchy. Band files went 0 → 1 (`tests/test_panel.lua`, 1197 lines).

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1197 | on notice: test-only file; split by area (rows / presets / collapse / copy box) before it reaches 1500 lines or at the next panel feature |

`tests/test_panel.lua` is the only file in the band. It is new to the band since the previous run.
No production file is in the band: `modules/Panel.lua` is at 915 lines.

## Actions

1. Split `tests/test_panel.lua` by area (rows / presets / collapse / copy box) before it reaches
   1500 lines or at the next panel feature, whichever comes first. This is the disposition above,
   and nothing else tracks it yet.
2. Run the in-game smoke checks the fix branch still owes before merging (`docs/smoke-tests.md`).
   This bundle does not cover real frames, PGF's real dialog or the EllesmereUI paint.
