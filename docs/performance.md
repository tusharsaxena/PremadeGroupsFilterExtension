# Performance — Ka0s Premade Groups Filter Extension

## Where the addon spends time

- **Idle:** nothing. No `OnUpdate`, no ticker, no timer. The registered events (spec changes, season
  data, entering the world) each do one small refresh.
- **Per search result:** PGF calls `PutPremadeRegionInfo(env, leaderName)` once per result while it
  filters; the addon's post-hook sets two numbers from cached keywords and, only without
  PremadeRegions, does one realm lookup (normalize the realm string, one table read in a lookup
  built once per portal). This is the one hot path, and the one the `envInject` bucket is for.
- **On Apply:** one pass over the season's dungeons (8), one pass over PGF's 8 dungeon rows, one
  string build and PGF's own re-filter. A hardware event, never repeated.
- **Panel:** `Panel.Refresh` runs on show, on a widget change and on season-data events; it rebuilds
  one readout string. The frame is built once, lazily.
- **Combat:** no combat path. Apply refuses in combat and nothing else of this addon runs then.

## The harness

`LibKa0s-Perf-1.0` is wired (`core/PerfSetup.lua`), with `PremadeGroupsFilterExtensionPerfDB`, the
`perf` verb, and suspension through the lifecycle latch. **No bucket is declared at v0.1.0**: the env
hook is not bracketed yet, and a declared bucket no bracket reaches reads 0.000 in every report
(performance-§3). The bracket and the `envInject` bucket go in together. In-game captures:
[`perf-analysis/README.md`](perf-analysis/README.md).

## Offline scenarios

`tests/perf.lua` is not written yet, so the automated-test runner records `perf` as a skip ("no
tests/perf.lua") and the record says nothing about runtime cost. The release gate needs all four
suites at pass, so the scenarios (the env hook with and without PremadeRegions, and the
stood-down zero-overhead case) are owed before `v0.1.0` is tagged.
