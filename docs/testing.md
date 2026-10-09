# Testing — Ka0s Premade Groups Filter Extension

## The green commit gate

Both MUST pass before every commit (testing-§4):

```sh
lua tests/run.lua      # the headless suite, Lua 5.1
luacheck .             # 0 warnings / 0 errors
```

Toolchain: [`DEPENDENCIES.md`](../DEPENDENCIES.md). The suite needs a sibling `../LibKa0s` checkout
for the vendor gate's two payload cases (they SKIP without it).

## The harness

`tests/run.lua` on the vendored LibKa0s kit (`tests/_kit/`, never edited). `tests/loader.lua` builds
a fresh, isolated addon per case from the TOC's own file list; `tests/wow_mock.lua` extends the kit's
base mock with what this addon reads (region, realm, season data, spec, combat, the AceDB `char`
scope, a real `hooksecurefunc`) and installs the PGF fake (`tests/pgf_fake.lua`) before any addon
file loads.

Suites reach the harness as `local T = _G.PGFE_TEST` and build instances with the three factories,
each taking an `opts` table and returning `(NS, env, mock)`:

- `T.newAddon(opts)` — every file loaded.
- `T.bootAddon(opts)` — plus `OnInitialize`.
- `T.enableAddon(opts)` — plus `OnEnable`.

Named suites the standard requires: `test_surface_parity` (testing-§8), `test_vendor_sync`
(testing-§11, delegating to the kit), `test_disabled` (slash-commands-§7). Kit suites, declared by
directory: `test_eol`, `test_prose`, `test_layout_cap`, `test_diagnostics_contract`,
`test_lizard_sighted`.

`lua tests/run.lua --list` prints the case inventory; it is committed as
[`test-cases.md`](test-cases.md), and its pass count is the README's `[tests]` badge. Regenerate both
in the change that moves the count (testing-§5).

## The four suites, and which checkpoint each gates

| Suite | Command | Commit / run | Release (the tag) |
|---|---|---|---|
| `lint` | `luacheck .` | **gates** | gates |
| `tests` | `lua tests/run.lua` | **gates** | gates |
| `perf` | `lua tests/perf.lua` | recorded, never fails a run or blocks a commit | gates |
| `complexity` | `bash tests/_kit/run-automated-tests.sh --suite complexity` (the sighted shadow) | recorded, never fails a run or blocks a commit | gates, with zero functions above CCN 15 and `blindFiles` 0 |

The release gate is evaluated by `/dev-copilot:bump-version` from the run's `manifest.json`
(automated-tests-§3). The record itself: [`automated-tests/README.md`](automated-tests/README.md).

## In game

[`smoke-tests.md`](smoke-tests.md) — the checks the headless suite cannot make.
