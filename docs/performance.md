# Performance — Ka0s Premade Groups Filter Extension

## Where the addon spends time

- **Idle:** nothing. No `OnUpdate`, no ticker, no timer. The scaffold registers no game event.
- **Per search result (plan Task 6):** PGF calls its `PutPremadeRegionInfo(env, leaderName)` once per
  result; the addon's post-hook adds two numbers and, without PremadeRegions, one realm lookup (a
  table read after normalizing the realm name). This is the hot path and gets the `envInject` bucket.
- **On Apply (plan Task 7):** one pass over the season's dungeons and one string build; a hardware
  event, never repeated.
- **Combat:** no combat path. Apply refuses in combat and nothing else runs then.

## The harness

`LibKa0s-Perf-1.0` is wired (`core/PerfSetup.lua`), with `PremadeGroupsFilterExtensionPerfDB`, the
`perf` verb, and suspension through the lifecycle latch. No bucket is declared until a bracket
reaches it (performance-§3). In-game captures: [`perf-analysis/README.md`](perf-analysis/README.md).

## Offline scenarios

`tests/perf.lua` is not written yet; the automated-test runner records `perf` as a skip ("no
tests/perf.lua") until the env hook exists to measure.
