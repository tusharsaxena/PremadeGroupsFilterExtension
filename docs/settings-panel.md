# Settings panel — Ka0s Premade Groups Filter Extension

Registered eagerly as **Settings → AddOns → Ka0s Premade Groups Filter Extension**; page bodies
build on first show (`LibKa0s-Options-1.0`, options-ui-§1/§5). The filter options are **not** here:
they live on the panel attached under PGF's dialog (`modules/Panel.lua`, described in
[`data-flow.md`](data-flow.md#the-attached-panel)), which is a feature surface, not a settings page.

| Page | Covers |
|---|---|
| Ka0s Premade Groups Filter Extension (landing) | Logo, the TOC notes, and the slash command list from `NS.COMMANDS` |
| General | Master controls: enable, debug console, minimap button, Toggle PGF Extension Filters, Show server regions in the Group Finder, reset all settings |
| Profiles | AceDB profiles: switch, copy, delete, reset |

## Page → tab → row

### Landing page

Untabbed by rule (options-ui-§13): the host's `buildMain` in `settings/Panel.lua`.

### General

- **Master controls** (the only tab), composed by `Helpers.MasterControls` with `frameless = true`
  and no visibility row (the attached panel's visibility is PGF's dialog and category):
  - *Enable Ka0s Premade Groups Filter Extension* → `enabled` (profile). Drives the `disabled` hold.
  - *Debug console* → `state.debugConsole` (session-only; the console window).
  - *Minimap button* → `global.minimap.shown`, inverted onto LibDBIcon's `global.minimap.hide`.
    Vetoed out of both resets (launcher-§3).
  - *Toggle PGF Extension Filters* → `filtersActive` (profile), the first of two legitimate extra
    rows (options-ui-§16) after the mandated ones. The attached panel's first box writes the same
    path. Off removes the managed block from PGF's expression; on writes it back. Separate from
    *Enable*: the addon stays up and the panel stays shown.
  - *Show server regions in the Group Finder* → `showRegionTags` (profile), the second extra row:
    the colored region tag on Group Finder rows and applicants (`modules/RegionTags.lua`).
  - *Reset all settings* (button) → confirmation popup → profile reset.

The header **Defaults** button runs the same confirmation.

### Profiles

Untabbed by rule: AceConfigDialog draws AceDBOptions' table (`settings/Profiles.lua`).
