# 02 Candidates, LibKa0s v1.107.0 -> v1.108.0

Sources: `git -C ../LibKa0s log --oneline v1.107.0..v1.108.0`; the LibKa0s CHANGELOG.md v1.108.0 block and its *What a consumer owes*; Ka0sAddonsCommonTasks `docs/2026-11-20-LIBKA0S_94_97_99_100/00_PLAN.md` and `SD_RULE.md`.

Delivered on the copy (class A, no host change):

- **The shared menu's submenu arrow is tinted from the menu palette (WidgetsDropdown minor 3, SD-LK-97.4)** and the menu measures no secret label (U-21). Reaches every `W.Dropdown` this addon opens through core/WidgetsSetup.lua:35.
- **Kit revision 58's skin guards (SD-LK-GUARD).** The family-by-family comparison and the colorless-face check run over `tests/skin_surfaces.lua` with no host change; the addon's surface declarations are SD-SK-PGFE's.

Not applicable (this addon builds none of the surface): the footer relayout (LibKa0s#94), the drag-strip tooltip fallback (LibKa0s#99), the call-out's strip marks (LibKa0s#100), the composers' new companions (OptionsCompose minor 20), W.Bar's border and gloss, Charts' `barFill`, `S.ApplyBarFill`'s texture, the call-out and waypoint-arrow text, and `Core.ApplySkin`'s `skinBands`.

New surface noted, not adopted: `W.OwnerWarnings(owner, sink)` (Widgets minor 30, SD-LK-97.1), a debug-gated report of a library widget built with no owner inside an owned window. Every library widget this addon builds already passes `owner = addonName` (core/WidgetsSetup.lua:35), so it would report nothing today. Left for the lead to decide; no issue filed in this run.
