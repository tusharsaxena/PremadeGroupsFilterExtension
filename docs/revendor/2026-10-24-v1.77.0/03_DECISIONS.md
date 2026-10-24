# Decisions: LibKa0s v1.76.0 -> v1.77.0 (Ka0s Premade Groups Filter Extension)

No interview ran. The cross-repo run's item PG-RV pre-decides the adoptions
(`Ka0sAddonsCommonTasks/docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`, `plan-data/items.json` and
`inputs/OWNER_SCOPE.md`): PGFE's adoptions this run are the PG-ZS item's, and everything else is
deferred. The item files no GitHub issue, so the decisions below are recorded here only.

| Candidate | Decision | Source | Issue |
|---|---|---|---|
| `O.StrataTooltip` | left to PG-ZS (held for the owner) | run bundle, item PG-ZS | none filed |
| Kit `mock_layers.lua` | left to PG-ZS (held for the owner) | run bundle, item PG-ZS | none filed |
| `O.KeybindingsTab`, `O.KeybindRows`, `O.KEYBINDS_UNCHANGED` | deferred (run 2026-10-24) | run bundle, item PG-RV | none filed |
| Kit `mock_bindings.lua`, `Kit.assertBindingsXml`, `Kit.keybindThroughTab` | deferred (run 2026-10-24) | run bundle, item PG-RV | none filed |
| DragHandle `level`, `ApplyLevel`, `ignoreParentAlpha` | deferred (run 2026-10-24) | run bundle, item PG-RV | none filed |
| `LibKa0s-Sim-1.0` | not adopted (settled at v1.75.0; premise unchanged) | `docs/revendor/2026-10-22-v1.75.0/03_DECISIONS.md` | none filed |
| `LibKa0s-Perf-1.0` | not adopted (settled at v1.75.0, `performance-§12` exemption) | `docs/revendor/2026-10-22-v1.75.0/03_DECISIONS.md` | none filed |
| `LibKa0s-Widgets-1.0` direct lookup | deferred (run 2026-10-24) | run bundle, item PG-RV | none filed |

No `04_EXECUTION_PLAN.md`: nothing was adopted in this item, so there is nothing to plan.
