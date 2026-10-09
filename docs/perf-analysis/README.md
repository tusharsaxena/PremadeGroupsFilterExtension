# Perf analysis — Ka0s Premade Groups Filter Extension

The standing store of **in-game** performance captures (performance-§8). Offline scenarios are not
here; they are part of the automated-test record.

## A capture

Taken in game with the addon's own verb, `/pgfe perf` (the `LibKa0s-Perf-1.0` workflow: start,
measure, finish, report). The harness suspends the addon for its comparison arm through the
lifecycle latch's `perf` hold, the same teardown `/pgfe disable` uses. Records land in
`PremadeGroupsFilterExtensionPerfDB`.

Each capture is recorded by `/dev-copilot:wow-perf-analysis` as one frozen bundle,
`docs/perf-analysis/<YYYYMMDD-HHMMSS>/`, holding `report.md` (the in-game report), `dump.json` (the
record, schema per `LibKa0s-Perf-1.0`'s API document) and `ANALYSIS.md` (the write-up).

## Buckets

None declared at v0.1.0. The first, `envInject` (PGF's per-result env hook), is declared together
with its bracket in `modules/EnvInject.lua`; that change has not been made yet.

## Capture index

No capture has been taken yet: nobody has played this addon, and a capture cannot be assembled from
the offline scenarios or the source.
