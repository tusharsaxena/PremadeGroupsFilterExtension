# 04 — Execution plan (review, 2026-10-10)

Implements `02_PROPOSED_CHANGES.md` (C-01..C-13, U-1..U-3) for findings F-001..F-018 of `01_FINDINGS.md`. Green gate before every commit: `lua tests/run.lua` and `luacheck .` (0/0) (`CLAUDE.md`). Each commit that adds a case regenerates `docs/test-cases.md` (`lua tests/run.lua --list > docs/test-cases.md`) and moves the README badge in the same commit. Never edit `libs/` or `tests/_kit/`. No version bump.

## Milestones

| # | Milestone | Done when |
|---|---|---|
| M1 | Complexity sighted | C-01 merged. `run-automated-tests.sh --suite complexity --no-bundle` reports `pass`, 0 blind files, max CCN ≤ 15 |
| M2 | Correctness | C-02, C-03, C-04, C-05 merged, each with its new red-under case. Suite green, pass count 325 → 330 |
| M3 | Locale + UX + observability | C-06..C-12 merged. Suite green, pass count → 332 (333 with the optional C-06 guard) |
| M4 | Tests that can fail | C-13 merged. Final count 333 (334 with C-06's optional guard). `docs/test-cases.md` and the badge equal it |
| M5 | Upstream (cross-repo) | U-1/U-2 released in LibKa0s (kit rev 39) and U-3 in WowAddonStandards. **Exit: a re-vendor commit in this addon** (`tests/_kit/`, plus `libs/LibKa0s/` if the tag moved it) byte-identical to the tag, with the `CLAUDE.md` provenance line moved and `test_vendor_sync` green |

## Tasks

| Task | Role | Implements | Files touched |
|---|---|---|---|
| T1 | lua-refactorer | C-01 / F-001 | `modules/RegionTags.lua` |
| T2 | lua-fixer | C-02 / F-002 | `modules/Panel.lua`, `tests/wow_mock.lua`, `tests/test_panel.lua`, `docs/test-cases.md`, `README.md` |
| T3 | lua-fixer | C-03 / F-003 | `modules/Expression.lua`, `tests/test_expression.lua`, `docs/test-cases.md`, `README.md`, `docs/ARCHITECTURE.md` (*Expression block format*: name the third damage shape) |
| T4 | lua-refactorer | C-04 / F-004 | `core/PGFBridge.lua`, `modules/EnvInject.lua`, `modules/Season.lua`, `.luacheckrc` (comment only), `docs/ARCHITECTURE.md` (*PGF seams*), `tests/test_bridge.lua`, `docs/test-cases.md`, `README.md` |
| T5 | lua-fixer | C-05 / F-005 | `modules/EUISkin.lua`, `tests/test_euiskin.lua`, `docs/test-cases.md`, `README.md` |
| T6 | ux-cleanup | C-06 / F-006, F-010 | `locales/enUS.lua`, `settings/Slash.lua`, `settings/Panel.lua` |
| T7 | ux-cleanup | C-07 / F-009 | `modules/Apply.lua`, `locales/enUS.lua`, `tests/test_apply.lua`, `docs/data-flow.md` |
| T8 | ux-cleanup | C-08 / F-011, C-09 / F-012 | `modules/Panel.lua`, `modules/EUISkin.lua` |
| T9 | observability | C-10 / F-013 | `modules/Diagnostics.lua`, `modules/EnvInject.lua`, `modules/RegionTags.lua`, `modules/Panel.lua`, `tests/test_setup.lua`, `docs/test-cases.md`, `README.md`, `docs/debug.md` |
| T10 | lua-fixer | C-11 / F-015 | `core/LauncherSetup.lua` |
| T11 | lua-fixer | C-12 / F-016 | `modules/Regions.lua`, `tests/test_regions.lua`, `docs/test-cases.md`, `README.md` |
| T12 | test-author | C-13 / F-008, F-014 | `tests/test_disabled.lua`, `tests/test_bridge.lua`, `docs/test-cases.md`, `README.md` |
| T13 | cross-repo coordinator | U-1, U-2 / F-007, F-017 | LibKa0s `testkit/run-automated-tests.sh`, `testkit/lizard_sighted.lua`; WowAddonStandards `standards/standards/automated-tests.md` |
| T14 | cross-repo coordinator | U-3 / F-018 | WowAddonStandards `standards/ADDONS.md` |
| T15 | revendor | M5 exit | `tests/_kit/` (whole folder), `libs/LibKa0s/` if moved, `CLAUDE.md` provenance line |

## Critical path and concurrency map

- Every task that adds a case touches **`docs/test-cases.md` and `README.md`** (T2, T3, T4, T5, T9, T11, T12). **Serialize them**, or regenerate the inventory once per merge in the order they land.
- `modules/Panel.lua`: T2, T8 and T9 → **serialize**.
- `modules/EUISkin.lua`: T5 and T8 → **serialize**.
- `modules/EnvInject.lua`: T4 and T9 → **serialize**.
- `modules/RegionTags.lua`: T1 and T9 → **serialize** (T1 first).
- `locales/enUS.lua`: T6 and T7 → **serialize**.
- `tests/test_bridge.lua`: T4 and T12 → **serialize**.
- `docs/ARCHITECTURE.md`: T3 and T4 → **serialize**.
- **Parallelizable:** T1 (first, alone), T10 (`core/LauncherSetup.lua` only), and T13/T14 (other repos), which run in parallel with everything here. T15 waits on T13.

Suggested order: T1 → T4 → T3 → T2 → T5 → T11 → T6 → T7 → T8 → T9 → T10 → T12, with T13/T14 in parallel and T15 last.

## Checkpoints

1. **After T1:** a human runs the complexity suite and confirms `pass`, 0 blind files. This is the release-gate blocker.
2. **After M2:** in-client C-02..C-05 from `03_SMOKE_TESTS.md`, especially the off-season C-02 baseline, which settles F-002's *unverified*.
3. **Before T15:** confirm the LibKa0s tag and that `diff -rq tests/_kit ../LibKa0s/testkit` is empty after the copy.

## Commit strategy

One commit per task, imperative subject, with the `Co-Authored-By` / `Claude-Session` trailers from the session.

- T1 `Hoist RegionTags' painter hooks out of the for-in header`
- T2 `Request season map info once per loading episode`
- T3 `Treat a wrapped block with no close marker as damage`
- T4 `Read PGF's spec and keyword constants through the bridge`
- T5 `Check EllesmereUI's facade before painting, and pcall the paint`
- T6 `Define every locale key in enUS and route the stray English strings`
- T7 `Drop the key range from the Apply message while targeting is off`
- T8 `Let tooltips hide while stood down; skip scale relayout when unpainted`
- T9 `Report installed hooks and filter options in diagnostics`
- T10 `Read the launcher's Enabled entry from the stored setting`
- T11 `Guard the region lookup against protected leader names`
- T12 `Assert every feature event goes quiet while disabled`
- T15 `Re-vendor LibKa0s test kit <tag>`
