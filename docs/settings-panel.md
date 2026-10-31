# Settings panel — Ka0s Premade Groups Filter Extension

Registered eagerly as **Settings → AddOns → Ka0s Premade Groups Filter Extension**; page bodies
build on first show (`LibKa0s-Options-1.0`, options-ui-§1/§5). The filter options are **not** here:
they live on the panel attached under PGF's dialog (`modules/Panel.lua`, described in
[`data-flow.md`](data-flow.md#the-attached-panel)), which is a feature surface, not a settings page.

| Page | Covers |
|---|---|
| Ka0s Premade Groups Filter Extension (landing) | Logo, the TOC notes, and the slash command list from `NS.COMMANDS` |
| General | Master controls: enable, debug console, minimap button, reset all settings. Filters: Use the extension's filters, and a line saying where the filter options are. Region tags: Show region tags in the Group Finder, then every region tag's color, with a picker each. Skin: the library's Skin tab (source, skin, font and texture, scope, copy to every Ka0s addon) |
| Profiles | AceDB profiles: switch, copy, delete, reset |

## Page → tab → row

### Landing page

Untabbed by rule (options-ui-§13): the host's `buildMain` (`Helpers.BuildMainContent` in
`settings/Panel.lua`) hands the logo, the TOC notes line and the `NS.COMMANDS` rows to the library's
`BuildLandingPage`, which owns the clear and the logo's lifecycle. Never draw on a pooled AceGUI
frame here: a private copy that did left a second logo under the Slash Commands heading after a
re-render.

### General

- **Master controls** (the first tab), composed by `Helpers.MasterControls` with `frameless = true`
  and no visibility row (the attached panel's visibility is PGF's dialog and category):
  - *Enable Ka0s Premade Groups Filter Extension* → `enabled` (profile). Drives the `disabled` hold.
  - *Debug console* → `state.debugConsole` (session-only; the console window).
  - *Minimap button* → `global.minimap.shown`, inverted onto LibDBIcon's `global.minimap.hide`.
    Vetoed out of both resets (launcher-§3).
  - *Reset all settings* (button) → confirmation popup → profile reset.

  Master controls holds only those mandated rows (options-ui-§15); the two feature switches lead
  their own tabs.

- **Filters** (the second tab; its own group, `FILTER_ROWS` in `settings/Panel.lua`, rendered by the
  library's default tab body):
  - *Use the extension's filters* → `filtersActive` (profile). The attached panel's first box
    writes the same path. Off removes the managed block from PGF's expression; on writes it back.
    Separate from *Enable*: the addon stays up and the panel stays shown.
  - A static line, drawn by the tab's after-group hook (`AFTER_GROUP[FILTER_GROUP]`), not a schema
    row, so `/pgfe list` does not list it: "The filter options are on the panel under Premade Groups
    Filter's window: open the Group Finder, choose Dungeons, and it appears below PGF's filters."

- **Region tags** (the third tab; one group, drawn by a host tab in `settings/Panel.lua`):
  - *Show region tags in the Group Finder* → `showRegionTags` (profile), first and unheaded, as the
    tab's leading switch (options-ui-§7): the colored region tag on Group Finder rows and applicants
    (`modules/RegionTags.lua`). Its own row list (`TAG_SWITCH_ROWS`), added before `REGION_ROWS` and
    never inside it, so *Reset region tag colors* does not reset it and `/pgfe list` keeps it
    between `filtersActive` and the colors.
  - Per portal, *Americas and Oceania (US realms)* then *Europe (EU realms)*: a heading, a preview
    line with every region tag of that portal in its current color (re-read on every write), then
    one color picker per region (`regionColors.<key>`, profile, no alpha, `REGION_ROWS`), three to
    a line, labeled with the tag and what it stands for (*OCE — Oceanic* ... *RUS — Russian*, the
    `REGION_PICKER_*` locale keys) and tooltipped with the region's description. The tag text the
    Group Finder and the attached panel draw (`NS.Regions.LABELS`) is unchanged.
  - *Reset region tag colors* (button): the twelve region colors back to their defaults, as one bulk
    act. The page's Defaults button and Reset all settings reset them too, as profile rows.
  - A change shows on the Group Finder's next search or list refresh.

- **Filters**, while EllesmereUI is loaded, ends with a pointer to Premade Groups Filter's own
  EllesmereUI skin (`settings/Panel.lua` `renderPGFSkinAdvice`, after a 12px gap): it is loaded, or
  installed but disabled (enable it and reload), or not installed (a read-only box holds its
  CurseForge link to copy). Advice only, read from `C_AddOns` at render time; the EllesmereUI
  skin's own conditions are the Skin tab's (the retired *EllesmereUI skin* tab's `euiSkin` switch
  was carried to the Skin tab's source by schema step 2, PG-06).

- **Skin** (the last tab): the library's `O.AppearanceTab`, drawn over the skip-render `skin.*` rows
  (`core/SkinSetup.lua` is the write seam): the source (Ka0s skins or EllesmereUI, with EllesmereUI's
  four conditions and their fixes), the nine skins, the font and texture overrides with their two
  reset buttons, the *Font outline* (`skin.outline`: All text, HUD text only, the default, Off; LibKa0s
  v1.82.0), the scope and *Copy to every Ka0s addon* under its own heading. *Ignore settings panel* is on in a new profile, so these pages stay
  the client's until the player unticks it; the attached panel and the debug console follow the
  skin either way. The first-run skin picker (`NS.MaybeShowSkinPicker`, once per profile while
  `skin.pickerSeen` is false) offers the same choice at login, and its gear opens this tab;
  `/pgfe skin` opens it on demand, seen or not.

The header **Defaults** button runs the same confirmation, and its tooltip is the library's
`Helpers.ResetAllTooltip()`, the same words *Reset all settings* carries (options-ui-§12); the addon
has no key bindings, so no tail.

### Profiles

Untabbed by rule: AceConfigDialog draws AceDBOptions' table (`settings/Profiles.lua`). The
renderer paints that tree for the skin owner after each `Open` (`NS.SkinPaintAceTree`), so it follows
the skin like the other pages, unless *Ignore settings panel* is on.
