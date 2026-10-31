# Candidates: LibKa0s v1.83.0 -> v1.84.0 (Ka0s Premade Groups Filter Extension)

Sources: `git -C ../LibKa0s log --oneline v1.83.0..v1.84.0`, the tag's v1.84.0 `CHANGELOG.md` block and
the tag's `docs/api/` documents for the majors whose minors moved. The run's brief names the
adoptions; everything else is recorded as declined. The 3g blockers are not candidates.

## A. Reached the addon on the re-vendor alone (delivered)

| Change | Evidence | Why it is free |
|---|---|---|
| The library peels (Skin, SkinDefs, SimPanel, OptionsSkinPicker, OptionsIds, OptionsWidgets, OptionsTabs) | `CHANGELOG.md` *The library peels* | Pure moves; no public member moves |
| WoW Default's Friz measured and guarded | *WoW Default's Friz* | No size moves |
| DragHandle minor 10 fit | *The drag handle's fit* | PGFE builds no drag handle, so it is inert here |
| `ApplyLevel` allocates nothing | *`ApplyLevel` allocates nothing* | Inert here for the same reason |
| The diagnostics identity header names Charts | *DebugLogDiagnostics minor 6* | The kit's header case passes unchanged |

## B. Host change required

| Surface | Evidence | Status |
|---|---|---|
| Schema `note` row | Options doc, *The `note` row* | Named by the brief; adopted |
| `opts.beforeGroup`, `opts.afterSubgroup` | Options doc, *`O.RenderRows`' `opts`* | Declined: no positioned block or subgroup to hook |
| `O.PositionBlock` | Options doc | Declined: the addon draws no positionable frame (only the stub's member) |
| `O.PageBanner{ acts }` | Options doc | Declined: the General page uses no banner |

## C. Whole-module adoption

| Major | Evidence | Status |
|---|---|---|
| `LibKa0s-Charts-1.0` | `docs/api/Charts/version-1.1-docs.md` | Declined: the addon draws no charts |
| `LibKa0s-Sim-1.0` | `CHANGELOG.md` | Settled at v1.75.0; the premise is unchanged |
| `LibKa0s-Perf-1.0` | `CHANGELOG.md` | Settled at v1.75.0 (`performance-§12` exemption); the premise is unchanged |
