# Settings panel — Ka0s Premade Groups Filter Extension

Registered eagerly as **Settings → AddOns → Ka0s Premade Groups Filter Extension**; page bodies
build on first show (`LibKa0s-Options-1.0`, options-ui-§1/§5). The filter options are **not** here:
they live on the panel attached under PGF's dialog (`modules/Panel.lua`, described in
[`data-flow.md`](data-flow.md#the-attached-panel)), which is a feature surface, not a settings page.

| Page | Covers |
|---|---|
| Ka0s Premade Groups Filter Extension (landing) | Logo, the TOC notes, and the slash command list from `NS.COMMANDS` |
| General | Master controls: enable, debug console, minimap button, Toggle PGF Extension Filters, Show server regions in the Group Finder, reset all settings. EllesmereUI skin: the skin's conditions and switch |
| Profiles | AceDB profiles: switch, copy, delete, reset |

## Page → tab → row

### Landing page

Untabbed by rule (options-ui-§13): the host's `buildMain` in `settings/Panel.lua`.

### General

- **Master controls** (the first tab), composed by `Helpers.MasterControls` with `frameless = true`
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

- **EllesmereUI skin** (the second tab; its own group, drawn by a host tab in `settings/Panel.lua`):
  - *Use the EllesmereUI skin* → `euiSkin` (profile, default on), first, with a 12px gap below.
    Disabled while any condition fails (never forced on); its tooltip adds what is missing, live.
    Off after a paint asks for a reload, whether from the switch or from a profile switch, copy or
    reset.
  - Four status lines, one per gate condition (`core/EUIBridge.lua`): a green ready mark or a red
    not-ready mark, the condition, and under a failing one what to do about it (indented by an empty
    icon slot the size of the marks). Hovering a line shows what the condition is, why it matters
    and how to turn it on:
    1. EllesmereUI and its Blizzard Skin module are loaded;
    2. EllesmereUI third-party skinning is on (*Blizz UI Enhanced > Blizzard Window Skins >
       Third-Party Addons > Skin Third-Party Addons*);
    3. PremadeGroupsFilterExtension is on in EllesmereUI's Third-Party Addons list;
    4. Premade Groups Filter's own EllesmereUI skin is on. When it is not, the line says which: not
       installed (and a read-only box holds its CurseForge link to copy), installed but disabled in
       the AddOns list, or turned off in EllesmereUI's Third-Party Addons list
       (`EUIBridge.PGFSkinState`).
  - After an 8px gap, a state line in the same empty icon slot (so its text lines up under the
    conditions'), with its own tooltip: applied; applied until a reload; not applied (stood down / a condition not met);
    off; applied after a reload; applied when the panel next shows.
  - Every line and the box are re-read each time the page is shown (an `OnShow` hook running the
    page's refreshers), since EllesmereUI's options change them outside this addon's write seam.

The header **Defaults** button runs the same confirmation.

### Profiles

Untabbed by rule: AceConfigDialog draws AceDBOptions' table (`settings/Profiles.lua`).
