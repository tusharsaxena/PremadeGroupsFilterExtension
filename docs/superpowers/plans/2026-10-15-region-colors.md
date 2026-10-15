# Region colors setting — plan (2026-10-15)

Spec: `docs/superpowers/specs/2026-10-15-region-colors-design.md`. Branch
`feat/2026-10-15-region-colors`. Gate per step: `lua tests/run.lua`, `luacheck .` (0/0).

1. Defaults: `REGION_HEX` and `PROFILE.regionColors` in `defaults/Profile.lua`.
2. `modules/RegionTags.lua`: `Hex(key)` (cached per stored table) and `Colored(key)` replace
   `COLORS`.
3. `settings/Panel.lua`: `REGION_ROWS`, `renderRegionTab`, `Settings.ResetRegionColors`,
   `Settings.RegionPreviewText`; tab order Master controls, Filters, Region colors, EllesmereUI
   skin. `settings/OptionsSetup.lua`: `scheduleTimer`. Locale strings.
4. Tests: rows and defaults per key, a changed color paints the next tag, the cache follows a new
   value, reset, `/pgfe set` in 0-255, the tab's pickers, preview and refresh; tab order updated.
5. Docs: schema, ARCHITECTURE, settings-panel, module-map, profiles, README FAQ, smoke APPLY-26
   (owner to run) and PANEL-2 re-check.
