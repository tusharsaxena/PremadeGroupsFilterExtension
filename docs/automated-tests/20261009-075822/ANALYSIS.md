# Analysis — 20261009-075822

The first automated-test run of Ka0s Premade Groups Filter Extension, recorded on the scaffold
commit `5939cc7` (plan Task 1), clean tree, version 0.1.0. Not a release run: nothing is tagged.

## Headline

**Green.** Lint 0/0 over 50 files, 102 of 103 cases passed with 1 declared skip, complexity sighted
with no function above CCN 15. Perf did not run: there is no `tests/perf.lua` yet.

## Suites

| Suite | Result | Reading |
|---|---|---|
| lint | pass, 0/0, 50 files | `libs/` and `tests/_kit/` are excluded (vendored), as are the frozen doc stores |
| tests | pass, 102/1/103 | The skip is the kit's diagnostics opt-out case, which does not apply: this addon keeps the default and a report turns logging on |
| perf | skip | No `tests/perf.lua` (reason 1, *nothing to run*). The only hot path is PGF's per-result env hook, which arrives in plan Task 6; the offline scenarios and the `envInject` bucket come with it |
| complexity | pass, 404 functions, avg CCN 1.9, max 13 | Measured through the kit's sighted shadow; `blindFiles` 0 |

## What moved

Nothing: this is the first run, so there is no earlier row to diff against. Every later run's value
is the difference from this one.

## Complexity watch list

Empty. No function was warned on and no authored file is in the 1000–1500 line band. The largest
function by CCN (13) is in `settings/SchemaSetup.lua`'s host stub, inherited from the collection's
shared shape and exercised only on a library-absent load.

## Actions

- Write `tests/perf.lua` with the env-hook scenarios (and a zero-overhead scenario) when plan Task 6
  lands, and declare the `envInject` bucket in `core/PerfSetup.lua` in the same change.
- Before tagging `v0.1.0`, re-run with `--release 0.1.0`; the tag needs all four suites at `pass`,
  so `perf` must have run by then.
