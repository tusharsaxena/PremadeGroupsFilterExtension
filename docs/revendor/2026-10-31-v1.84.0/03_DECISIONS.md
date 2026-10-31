# Decisions: LibKa0s v1.83.0 -> v1.84.0 (Ka0s Premade Groups Filter Extension)

No interview ran. The run's brief (Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/`,
M2 adoption) names the adoption and records the rest as declined here, with no GitHub issue.

| Candidate | Decision | Source | Issue |
|---|---|---|---|
| Schema `note` row | adopted, `ac1f593` | run brief, LibKa0s#59 | none filed |
| `opts.beforeGroup`, `opts.afterSubgroup` | declined (run 2026-10-31): nothing to hook | run brief | none filed |
| `O.PositionBlock` | declined (run 2026-10-31): no positionable frame; the stub member stays | run brief | none filed |
| `O.PageBanner{ acts }` | declined (run 2026-10-31): the page uses no banner | run brief | none filed |
| `LibKa0s-Charts-1.0` | declined (run 2026-10-31): the addon draws no charts | run brief | none filed |
| `LibKa0s-Sim-1.0` | not adopted (settled at v1.75.0; premise unchanged) | `docs/revendor/2026-10-22-v1.75.0/03_DECISIONS.md` | none filed |
| `LibKa0s-Perf-1.0` | not adopted (settled at v1.75.0; premise unchanged) | `docs/revendor/2026-10-22-v1.75.0/03_DECISIONS.md` | none filed |

## LibKa0s#67 and #68 in this addon

- **#67: none.** No row in `settings/` uses `disabledIf` or `shownWhen`. The schema's three Dropdowns
  (skin source, skin, font outline) are `skipRender` rows the library's Skin tab draws, and no host
  row group hangs off a selector. Region colors follow one switch and stay drawn, which options-ui
  §22 *Hidden is not disabled* leaves alone in any case, and they carry no dimming.
- **#68: not in the host table.** The addon makes no `DragHandle` call and has no mover: the attached
  panel is parented and anchored to PGF's dialog.
