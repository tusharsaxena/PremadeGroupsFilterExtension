# Refresh 1 of v1.85.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-01-FULL_SKINNING/` (FS-PG-GATE). The tag is local-only and was re-cut before any push, so this is a refresh and not a new re-vendor.

- **Old:** `9776130`. `libs/LibKa0s/` and `tests/_kit/` matched it, content, before this copy.
- **New:** `2ad1a5080112cc1323fe79f7e134b00768a7ebca`, tag object `36506d6`.

| File | Constant | Old | New |
|---|---|---|---|
| `Media.lua` | `MINOR` | 11 | 12 |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 17 | 18 |
| `Skin.lua` | `MINOR` | 14 | 15 |
| `SkinDefs.lua` | `DEFS_MINOR` | 24 | 25 |
| `SkinDefsOthers.lua` | `OTHERS_MINOR` | 6 | 7 |
| `SkinEUI.lua` | `EUI_MINOR` | 3 | 4 |
| `SkinPaint.lua` | `PAINT_MINOR` | 16 | 17 |
| `SkinPaintControls.lua` | `CONTROLS_MINOR` | 14 | 15 |
| `SkinPaintExtras.lua` | `EXTRAS_MINOR` | 15 | 16 |
| `Widgets.lua` | `MINOR` | 20 | 21 |

Kit revision 49 -> 50: `test_skin_values`, `test_skin_switch` and their two modules are new (`git -C ../LibKa0s diff --stat 9776130 v1.85.0 -- LibKa0s testkit`).

**Copy:** `git archive v1.85.0` of the two payloads, each replacing its folder, then `tools/prune-icons.lua` from the tag. Both diffs were empty after the prune but for the undeclared icons, content and bytes. The icons line did not move.

**Blockers, fixed in the FS-PG-GATE commit:** the degraded facade's `BarBorder` (its stored three) and `HoverArt` (a no-op); the two kit suites declared by the pair. This addon has no Widgets stub, so `ContextMenu` owes nothing: with the library absent `core/WidgetsSetup.lua` answers nil and the panel builds the client's dropdown.

**Adopted:**

- The typed-value gate, with no allow rows. Its one hit, the unknown realm's `|cff9d9d9d?|r`, moved onto the owner token `pg.regionUnknown` (Ka0s Default's value, following `text.disabled`).
- The skin-switch test: `tests/skin_surfaces.lua` declares 20 surfaces.
- The `tooltip` and `divider` row options, on the multi-selects' dropdown options, which take W.ContextMenu's row options. The panel keeps `W.Dropdown`, whose multi-select state W.ContextMenu has no part in. The button's tooltip goes back to the dropdown's own line, and every entry and the divider under *Any* are back as on master.

**Owed nothing:** no HUD and no D2 to D7 row (Options, *A host with no HUD owes no step*), so no `Skin.FollowOnce`, no record and no repair; no numeric path; no `S.Mark` or `S.HoverArt` on a pooled AceGUI widget, the panel having no AceGUI widget of its own; no `Solid` border registration; no bar border.
