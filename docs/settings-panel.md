# Settings panel — Ka0s Premade Groups Filter Extension

Registered eagerly as **Settings → AddOns → Ka0s Premade Groups Filter Extension**; page bodies
build on first show (`LibKa0s-Options-1.0`, options-ui-§1/§5). The filter options are **not** here:
they live on the panel attached under PGF's dialog (plan Task 8), which is a feature surface, not a
settings page.

| Page | Covers |
|---|---|
| Ka0s Premade Groups Filter Extension (landing) | Logo, the TOC notes, and the slash command list from `NS.COMMANDS` |
| General | Master controls: enable, debug console, minimap button, reset all settings |
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
  - *Reset all settings* (button) → confirmation popup → profile reset.

The header **Defaults** button runs the same confirmation.

### Profiles

Untabbed by rule: AceConfigDialog draws AceDBOptions' table (`settings/Profiles.lua`).
