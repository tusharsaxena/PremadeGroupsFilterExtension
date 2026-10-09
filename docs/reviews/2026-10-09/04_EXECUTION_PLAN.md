# 04 — Execution plan

Findings F-001 to F-011 map to changes C-001 to C-010, as listed in `02_PROPOSED_CHANGES.md`. There are
no upstream findings, so this plan has no cross-repo milestone.

## M1: blocking fixes (F-001, F-002)

| Task | Role | Implements | Files |
|---|---|---|---|
| T1 | lua-fixer | C-001 / F-001 | `modules/Expression.lua`, `modules/EnvInject.lua`, `tests/test_expression.lua`, `tests/test_envinject.lua`, `tests/test_apply.lua`, `docs/ARCHITECTURE.md`, `docs/data-flow.md`, `docs/test-cases.md`, `README.md` |
| T2 | wow-api-migrator | C-002 / F-002 | `modules/EnvInject.lua`, `.luacheckrc`, `tests/wow_mock.lua`, `tests/test_envinject.lua`, `docs/test-cases.md`, `README.md` |

Done when `lua tests/run.lua` is green, `luacheck .` reports 0/0, and the inventory and badge are regenerated in each commit.

**Checkpoint:** a human runs the C-001 and C-002 smoke tests in-client before M2.

## M2: panel and Apply truthfulness (F-003, F-004, F-008, F-009, F-010)

| Task | Role | Implements | Files |
|---|---|---|---|
| T3 | ux-cleanup | C-003 / F-003 | `modules/Panel.lua`, `tests/test_panel.lua` |
| T4 | lua-fixer | C-004 / F-004 | `core/PGFBridge.lua`, `modules/Apply.lua`, `locales/enUS.lua`, `tests/test_apply.lua`, `docs/data-flow.md` |
| T5 | ux-cleanup | C-005 / F-008, F-009 | `modules/Panel.lua`, `modules/Apply.lua`, `locales/enUS.lua`, `tests/test_panel.lua`, `tests/test_apply.lua` |
| T6 | lua-fixer | C-009 / F-010 | `core/PGFE.lua`, `tests/test_panel.lua` |

Done when the M2 smoke tests pass and the suite is green.

## M3: tests, perf evidence, robustness (F-005, F-006, F-007, F-011)

| Task | Role | Implements | Files |
|---|---|---|---|
| T7 | test-author | C-006 / F-005 | `tests/test_disabled.lua`, `docs/test-cases.md`, `README.md` |
| T8 | perf-author | C-007 / F-006 | `tests/perf.lua` (new), `docs/performance.md`, `docs/ARCHITECTURE.md` |
| T9 | lua-fixer | C-008 / F-007 | `modules/Presets.lua`, `tests/test_presets.lua` |
| T10 | lua-fixer | C-010 / F-011 | `modules/Regions.lua`, `tests/test_regions.lua` |

Done when the suite is green and `lua tests/perf.lua` runs bounded. The bucket-or-§12 decision is recorded in `docs/ARCHITECTURE.md`.

## Concurrency map

- **T1 → T2 serialize:** both touch `modules/EnvInject.lua`, `tests/test_envinject.lua`, `docs/test-cases.md` and `README.md`.
- **T3 → T5 → T6 serialize:** all three touch `modules/Panel.lua` or `tests/test_panel.lua`.
- **T4 → T5 serialize:** both touch `modules/Apply.lua`, `locales/enUS.lua` and `tests/test_apply.lua`.
- **T1 and T4 share `tests/test_apply.lua` and `docs/data-flow.md`:** run M1 before M2, as ordered.
- **T7 and T1/T2 share the inventory and badge:** run T7 after M1.
- **Parallelizable:** T8, T9 and T10 have disjoint file sets with each other and with T7, apart from T7's inventory regeneration. Run T7 last in M3, or regenerate once at the end of M3 inside T7's commit.
- `docs/ARCHITECTURE.md` is touched by T1 and T8. T8 comes after T1 by milestone order.

## Commit strategy

One commit per task. Each commit regenerates `docs/test-cases.md` (`lua tests/run.lua --list > docs/test-cases.md`) and updates the README badge whenever its case count moves. No version bump, and no automated-test bundle; those belong to release.

Suggested messages:
- T1 `Make the managed expression block neutral when the env hook did not run`
- T2 `Route the player's spec read through NS.Compat`
- T3 `Commit key level and max age only on Enter or focus loss`
- T4 `Refuse Apply and Clear while PGF's dialog is minimized`
- T5 `Range field follows the key level; Apply reports rows ticked`
- T6 `Refresh the attached panel on profile change`
- T7 `Rewrite test_disabled to the slash-commands-§7 conformance shape`
- T8 `Add the offline env-hook perf scenario`
- T9 `Load presets over the current filter defaults`
- T10 `Guard the region lookup against a non-string leader name`
