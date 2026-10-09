# Smoke tests — Ka0s Premade Groups Filter Extension

The in-client checks the headless suite cannot make: real frames, PGF's real dialog, the real
Group Finder and the real client's locale. Run them from a clean `/reload` with Premade Groups Filter
enabled, debug logging off unless a check says to turn it on, and record each result on the check's
`Result:` line (date, client build, pass or what happened). IDs are `<THEME>-<n>`, stable: a new check
takes the next free number in its theme and a retired number is never reused.

## Index

| ID range | Theme | What it covers |
|---|---|---|
| INSTALL-1..3 | Install | Load with and without PGF, reload, first run |
| SLASH-1..3 | Slash | `/pgfe` verbs, help, the long alias |
| PANEL-1..3 | Settings panel | Landing page, General page, Defaults |
| PROFILE-1..2 | Profiles | The Profiles page and `/pgfe profile` |
| STATE-1..2 | Enable / disable | Stand-down and stand-up |
| COMBAT-1..2 | Combat | Apply refusal, settings panel in combat |
| DIAG-1..2 | Diagnostics | Debug console, the diagnostics report |
| DEGRADED-1 | Degraded install | LibKa0s absent |
| APPLY-1..24 | Attached panel and Apply | The panel under PGF, targeting, regions, playstyle, composition, leader, leader score, age, presets, Clear, PGF minimized, collapse, layout, tooltips, Smart key level, filters toggle, row spacing, region tags |
| LOC-1..2 | Non-English client | Realm-name and dungeon-name seams on a deDE/frFR client |
| SKIN-1..10 | EllesmereUI skin | The gate's four conditions, the PGF skin's install states and link, the settings tab, the painted panel, live on, reload off |

## Before you start

Retail client at the TOC's interface, Premade Groups Filter 7.6.2 or later enabled, PremadeRegions
**disabled** unless a check says otherwise, a max-level character with some timed Mythic+ runs this
season. Know your best timed level per dungeon (the Mythic+ tab) before the APPLY checks.

## Install

- **INSTALL-1. Loads with PGF.** Enable both addons, `/reload` → no Lua error; the minimap button
  shows; `/pgfe version` prints `v0.1.0`. Result:
- **INSTALL-2. Does not load without PGF.** Disable Premade Groups Filter at the character screen →
  this addon is listed as missing a dependency and does not load; `/pgfe` is an unknown command.
  Result:
- **INSTALL-3. First run defaults.** Delete `PremadeGroupsFilterExtensionDB` from the account's
  SavedVariables, log in → `/pgfe list` shows `enabled = true`; no error. Result:

## Slash

- **SLASH-1. Help.** `/pgfe help` → the command list, every row `/pgfe <verb> — <description>`;
  `/premadegroupsfilterextension help` prints the same. Result:
- **SLASH-2. Bare command.** `/pgfe` → opens Settings at this addon's page. Result:
- **SLASH-3. Unknown verb.** `/pgfe nonsense` → one line naming the unknown command and the help;
  no Lua error. Result:

## Settings panel

- **PANEL-1. Landing page.** Settings → AddOns → Ka0s Premade Groups Filter Extension → the logo,
  the notes line and one row per slash command; no tab strip. Result:
- **PANEL-2. General page.** General → one tab, `Master controls`: Enable, Debug console, Minimap
  button, *Toggle PGF Extension Filters*, *Show server regions in the Group Finder*, and a *Reset all
  settings* button. No scale, alpha, lock, visibility or test-mode rows.
  Result:
- **PANEL-3. Defaults button.** Header **Defaults** → a confirmation popup; Yes → `/pgfe list` back
  at defaults; the minimap button keeps its shown/hidden state. Result:

## Profiles

- **PROFILE-1. Profiles page.** Create a profile, switch to it → no error; `/pgfe profile` lists
  both. Result:
- **PROFILE-2. Disabled profile.** In the new profile `/pgfe disable`, switch back to Default → the
  addon is enabled again (`/pgfe get enabled` is true); switch again → disabled. Result:

## Enable / disable

- **STATE-1. Disable stands down.** `/pgfe disable` → `enabled = false`; `/pgfe debug on` then
  `/pgfe diagnostics` → `stoodDown=true`, `holds` lists `disabled`; `/pgfe apply` and `/pgfe clear`
  answer with the disabled line; the attached panel is hidden even with PGF open on Dungeons.
  `/pgfe enable` → the panel comes back without a `/reload`. Result:
- **STATE-2. Launcher menu.** Right-click the minimap button → *Enabled* toggles the addon; the other
  entries gray while disabled; left-click opens Settings. Result:

## Combat

- **COMBAT-1. Apply refused in combat.** Attack a training dummy, press Apply (and type
  `/pgfe apply`) → the line `Cannot apply in combat.`; nothing in PGF changes and no search runs.
  Result:
- **COMBAT-2. Settings in combat.** In combat, `/pgfe config` → a gray refusal; no taint error after
  combat. Result:

## Diagnostics

- **DIAG-1. Console.** `/pgfe debug` toggles the window; `/pgfe debug on` shows the `[Init]` line
  with the version, schema, profile and `PremadeRegions=false`. Result:
- **DIAG-2. Report.** `/pgfe diagnostics` with logging off → the report appends between two
  `Ka0s Premade Groups Filter Extension` markers and logging is now on; the `dependencies` line says
  PGF's namespace, dialog and dungeon panel are present. Result:

## Degraded install

- **DEGRADED-1. LibKa0s absent.** Rename `libs/LibKa0s` and `/reload` → one line saying LibKa0s is
  missing; `/pgfe version` answers; `/pgfe config` says the panel is unavailable; no Lua error.
  Restore the folder afterwards. Result:

## Attached panel and Apply

Each is in *Pending sign-off* until it records a pass. The targeting checks use the owner's
character as the reference: at the time of writing its best timed level is 13 in AOF, RLP, BV and KR
and 14 or more in the other four dungeons. On another character, read the panel's readout first and
substitute its numbers.

- **APPLY-1. Attached, same width.** Open PGF's dialog on the Dungeons category → the panel sits
  directly under it, edge to edge. Switch PGF to Raids → the panel hides; back to Dungeons → it
  returns at the same width; close PGF → it hides. Resize the Group Finder (or change UI scale) →
  the panel still matches PGF's width. Result:
- **APPLY-2. Targeting at N=14.** Type `14` in the level box and press Enter (the value is kept
  only on Enter or when the box loses focus; `45` snaps back to the stored level), key targeting on,
  Apply → exactly AOF, RLP, BV and KR
  are ticked in PGF's dungeon list **and** in the game's own Filter → Dungeons menu; the readout shows
  those four in gold and the rest gray; the search runs; chat says 4 dungeons, range `14-14`.
  Result:
- **APPLY-3. Everything timed.** Key level 2, Apply → `Every dungeon is already timed at +2; nothing
  to target.`; PGF's checkboxes and expression are unchanged. Result:
- **APPLY-4. Regions.** US portal, server regions on with OCE only, Apply → the expression block holds
  `( oce )`; every listed leader is on an Oceanic realm (hover a few). With PremadeRegions enabled
  the result is the same. Regions on with no region ticked, Apply → no region clause in the block, no
  refusal, listings from every region. Result:
- **APPLY-5. Composition.** As a Beast Mastery hunter, *Composition* on with *No one with my spec* ticked in its dropdown, Apply → no listed
  group already has a Beast Mastery hunter. Then only *No one with my class + role* ticked instead (the button never reads Any with both ticked; Any unticks both) → no listed
  group has a damage-dealing hunter of any spec. Switch spec without re-applying and refresh the
  search → the exclusion follows the new spec. Result:
- **APPLY-6. User expression kept.** Type `voice` in PGF's advanced filter, Apply → the marked block
  wraps your text; Clear → exactly `voice` remains and the dungeon ticks are unchanged. Repeat with
  `mprating > 2000 or partyfit` → results honor both the block and the `or`. Result:
- **APPLY-7. Presets across characters.** Save a preset with Save as…, log in on another character,
  pick it from the Presets menu → the options match; the first character's own options are
  unchanged; Delete asks for confirmation and removes it from both characters' menus. Result:
- **APPLY-8. Copy into search box.** The field sits at the right end of the Apply row, labeled
  *Copy into search box*; hovering the label or the field explains why the addon cannot fill the
  search box itself. The `N-N` field selects all on click and cannot be typed over;
  Ctrl+C, click the Group Finder search box, Ctrl+V → it pastes `14-14`. Keyboard chain: Apply →
  the copy field has focus with `14-14` selected; Ctrl+C, Enter → the cursor is in the Group
  Finder search box (if it stays in the copy field, the client refused the focus change: record
  it); Ctrl+V, Enter → the search runs with `14-14`, no Lua error and no "action blocked"
  (`/console taintLog 1`, then check `Logs/taint.log` for this addon). Untick *Untimed dungeons at
  key level* → the copy box and its label dim and the box cannot be focused; Apply does not focus
  it; tick it again → both return. Result:
- **APPLY-9. Targeting at N=15.** Key level 15, Apply → all eight dungeons ticked in PGF and in the
  game's Filter → Dungeons menu. Result:
- **APPLY-10. Experienced leader.** *Experienced leader* on at N=14, Apply → the block holds
  `( mpmapintime and mpmapmaxkey >= 14 )`; open a few listed groups' leader tooltips → each has timed
  that dungeon at 14 or higher. Result:
- **APPLY-11. Max group age.** *Max group age* on, 5 minutes, Apply → no listing older than five
  minutes appears (PGF's age column or the listing tooltip). Result:
- **APPLY-12. PGF minimized.** Minimize PGF's dialog while on Dungeons → the attached panel hides;
  `/pgfe apply` → `Maximize the Premade Groups Filter dialog first; nothing was applied.`, no search
  runs, no Lua error; maximize PGF → the panel returns. Result:
- **APPLY-13. Not on Dungeons.** With PGF on Raids, `/pgfe apply` → `Open Premade Groups Filter on
  the Dungeons category first; nothing was applied.` Result:
- **APPLY-14. Collapse.** Expanded, the corner button shows the up-right arrow. Press it → the
  panel folds to its header strip only (title, arrow and the closing metal bar, about 50px tall,
  no empty body under it), and the button shows the down-left arrow. Check the strip's metal art:
  the left and right rails meet the bottom bar with no step or gap, no corner art shows past the
  strip, and the strip sits flush under PGF's dialog (if rail stubs show above the bar, or the bar
  is cut off, record it: `HEADER_H` / `HEADER_SEAM` in `modules/Panel.lua` need a pixel or two).
  `/reload` → it stays folded with the same arrow; press the arrow → the rows return, the border
  looks exactly as before folding, and the arrow flips back. Result:
- **APPLY-15. Layout.** Expanded, no label is covered by its input box (key level, min score, max
  age) or by the Smart checkbox; the readout (`AOF 13  RLP 13 …`) is one line, not cut off, and the
  gap from it to the Server regions row matches the gap between the other rows. The Server regions,
  Playstyle and Composition dropdowns are equally wide (about half the panel) and share one
  right-hand column.
  The Presets dropdown, Save, Save as and Delete share one row: the three buttons right-aligned at
  one width, their text not clipped, and the dropdown filling the rest of the row. Apply and Clear are equally wide, with a little more space above
  them than between the rows above; the *Copy into search box* label does not touch Clear, and the
  Apply row sits inside the frame. Result:
- **APPLY-16. Min leader score.** *Min leader M+ score* on at 2500, Apply → the block holds
  `mprating >= 2500`; hover a few listed leaders → each rating is 2500 or more. Result:
- **APPLY-17. Multi-select dropdowns.** Open the Server regions dropdown → *Any* (ticked) heads
  the list above a divider, then this portal's regions as checkboxes; tick two → the menu stays
  open, *Any* unticks, the button reads e.g. `OCE, CHI`; click *Any* → the menu stays open and every
  region unticks, the button reads `Any`. Tick every region one by one → on the last one the
  regions untick, *Any* is ticked and the button reads `Any` (never `5 selected`). Same for
  Playstyle; three long names read `3 selected`. Result:
- **APPLY-18. Playstyle.** Playstyle on with Relaxed ticked, Apply → the block holds `( relaxed )`;
  hover a few listings → each is listed as Relaxed. Result:
- **APPLY-19. Tooltips.** Hover each checkbox row, on the box and on its label → a tooltip names
  the option and says what it does (Untimed dungeons, Smart, Server regions, Playstyle,
  Composition, Experienced leader, Min leader M+ score, Max group age); clicking the label
  toggles the box. Hover the three number boxes, the three dropdown buttons, every entry in the
  Server regions and Playstyle menus (e.g. OCE → Oceanic realms, Sydney data center), Save, Save
  as…, Delete, Apply, Clear and the copy field → each has a tooltip. The dropdowns' hover art still
  works and no tooltip sticks after the pointer leaves. Result:
- **APPLY-20. Smart key level.** On a character that never used the addon, *Smart* is ticked and
  the panel matches the owner's defaults: Toggle, Untimed dungeons, Smart, Server regions, Playstyle and
  Composition ticked (all three dropdowns read Any); Experienced leader, Min leader M+ score (2000)
  and Max group age (15) unticked. Note your best timed levels on the Mythic+ tab. Tick *Smart* →
  the level box grays out and cannot be focused or typed in (hovering it still shows its tooltip), and shows the lowest best timed level
  + 1 (best timed 12, 13, 13, 14 → 13; all four at 13 → 14); the readout and the copy field follow.
  Apply → that level is targeted. Time a key that raises your lowest best → after the key completes
  the level moves up by itself. `/pgfe apply` with Smart on uses the same level. Untick *Smart* →
  the box is editable again and keeps the last level. Save a preset with Smart on, load another
  without it, load the first → Smart is ticked again. Result:
- **APPLY-21. Toggle PGF Extension Filters.** It is the first row, ticked on a new profile, with a
  wider gap under it. Apply, then untick it → chat says the block was removed; PGF's advanced filter
  holds only your own text, the dungeon ticks are unchanged, Apply is grayed out and `/pgfe apply`
  refuses. Settings → General shows *Toggle PGF Extension Filters* unticked as well (and *Enable*
  still ticked). Load a preset → it stays unticked. Tick it on the settings page → the panel's box
  ticks and the block is written back (no search runs). Result:
- **APPLY-23. Row spacing.** Every row, from Untimed dungeons to Presets (the dungeon readout
  included), is the same distance from the next as the Server regions and Playstyle rows are; only
  the gaps under the toggle row, around the Presets row and above Apply are wider. Result:
- **APPLY-22. Title centered, 1px gap.** A 1px gap separates PGF's dialog from the panel: the two
  metal borders neither touch nor overlap (tune `ATTACH_RAISE` in `modules/Panel.lua`), and PGF's
  border never draws over the panel's title strip, expanded or
  collapsed. The panel's title is centered on the whole header strip, expanded
  and collapsed, and does not touch the arrow button. Result:
- **APPLY-24. Region tags.** With PremadeRegions disabled, search Mythic+ → every listing's dungeon
  name starts with the leader's colored region (OCE, LA, CHI, MEX, BZL on US; ENG, GER, ... on EU),
  matching what PremadeRegions showed; list your own group → each applicant's name starts with
  their region. Settings → General → untick *Show server regions in the Group Finder*, refresh →
  no tags. Enable PremadeRegions again → exactly one tag per row (its own). No Lua error and no
  "action blocked" with `/console taintLog 1`. Result:

## EllesmereUI skin

Needs EllesmereUI (with EllesmereUI Blizzard Skin) and Premade Groups Filter - EllesmereUI Skin
installed, unless a check says otherwise. EllesmereUI's switches are under *Blizz UI Enhanced >
Blizzard Window Skins > Third-Party Addons*; check the wording there matches the hints on our
settings tab and record any difference.

- **SKIN-1. EllesmereUI absent.** Disable EllesmereUI, `/reload` → no Lua error; the panel looks
  exactly as without this feature (metal border, 1px gap under PGF's dialog). Settings → General →
  *EllesmereUI skin*: four red lines (each with its hint), "a condition above is not met", the box
  checked but disabled; hovering it lists what is missing. `/pgfe set euiSkin false` works;
  `/pgfe set euiSkin true` is then refused with the reasons. Result:
- **SKIN-2. Everything on.** All four conditions on, *Use the EllesmereUI skin* ticked, `/reload`,
  open PGF on Dungeons → the panel wears the same flat shell as PGF's dialog, with a 1px gap between
  them and neither drawn over the other; title white and centered in the 25px top bar; 16px
  checkboxes with the accent block and ring when ticked; flat number boxes (Smart's grayed level and
  the dimmed copy box keep their gray); flat dropdowns with EllesmereUI's arrow, opening
  EllesmereUI-styled menus; flat buttons (gray when disabled); the readout's gold/gray colors kept.
  The settings tab shows four green lines and "The skin is applied." Result:
- **SKIN-3. Collapse.** Fold the skinned panel → only the 25px bar is left, the border closes
  cleanly around it (no squashed atlas corners, no metal header pieces), and the glyph is a plus;
  unfold → a minus, the body back. The glyph brightens on hover. Result:
- **SKIN-4. Master off.** In EllesmereUI turn off *Skin Third-Party Addons*, `/reload` → the panel is
  stock; our tab shows the master line red and the box disabled. Turn it back on in EllesmereUI
  (no reload) → PGF's dialog and our panel are painted at once (or on the panel's next show). Result:
- **SKIN-5. Our entry off.** Untick *PremadeGroupsFilterExtension* in EllesmereUI's Third-Party
  Addons list, `/reload` → stock panel, that line red, box disabled. Result:
- **SKIN-6. PGF's skin off.** Untick *PremadeGroupsFilter* there (or disable Premade Groups Filter -
  EllesmereUI Skin), `/reload` → both windows stock; our pgf line red, box disabled. Re-tick it
  without a reload, then reopen PGF on Dungeons → our panel is painted on that show. Result:
- **SKIN-10. PGF's skin missing or disabled.** Remove the Premade Groups Filter - EllesmereUI Skin
  folder, restart → the pgf line reads *not installed* and a box below the lines holds
  `https://www.curseforge.com/wow/addons/premade-groups-filter-ellesmereui`; click it → the link is
  selected, Ctrl+C copies it, typing puts it back. Reinstall it but disable it in the AddOns list →
  the line reads *installed but disabled*, no link box. Enable it and untick *PremadeGroupsFilter*
  in EllesmereUI → *turned off in EllesmereUI*. Result:
- **SKIN-7. Our switch.** Everything on, untick *Use the EllesmereUI skin*, `/reload` → stock panel,
  "The skin is off." Tick it → the panel is painted at once, no reload. Untick it again → a popup
  asks to reload; *Later* leaves the panel painted, *Reload* reloads into the stock panel. Result:
- **SKIN-8. Live re-read.** With the settings tab open in one window, change an EllesmereUI switch,
  come back and reopen the page → the lines and the box's disabled state follow without a reload.
  Result:
- **SKIN-9. Stand-down and theme.** `/pgfe disable` then `/pgfe enable` on a skinned panel → no
  error, still painted. Change EllesmereUI's accent color → the checkbox accent follows; change the UI
  scale → the accent block stays centered. `/pgfe diagnostics` → the dependencies section names the
  four conditions and `applied=true`. Result:

## Non-English client

The headless mock is enUS, so a path keyed off a localized string passes there whether it is right
or wrong. These are the addon's locale seams.

- **LOC-1. Realm names on a deDE/frFR client.** Leader names carry the realm as the client
  shows it, and the region lookup normalizes that string (lowercase, spaces and punctuation removed)
  against the realm map. On a deDE client, EU portal, regions on with GER only, Apply → the listed
  leaders are on German realms. **Failure looks like:** an empty result list, or leaders from
  English realms only, because a localized realm spelling (an umlaut or accent, `Aman'Thul` vs a
  translated name) did not normalize to the map's key. Headless stand-ins: the `regions:` cases for
  apostrophes, accents and the no-suffix leader. Signed off on English only if the leader names on
  that client are byte-identical to the enUS ones (check one German realm with `/pgfe debug on`).
  Result:
- **LOC-2. Dungeon names on a deDE/frFR client.** The panel's readout uses PGF's
  locale-independent keyword for each dungeon (by map id) and falls back to the localized name's
  initials only for an unknown map. On a deDE client the readout shows the same short names as on
  enUS (AOF, DON, …). **Failure looks like:** initials of German dungeon names in the readout, or a
  stray `%s`/`%d` in any panel line. Headless stand-in: the `season:` short-name cases. Sufficient on
  English for the format check; the keyword path needs the client. Result:

## Pending sign-off

| ID | Origin | Why it is owed |
|---|---|---|
| INSTALL-1..3, SLASH-1..3, PANEL-1..3, PROFILE-1..2, STATE-1..2, COMBAT-2, DIAG-1..2, DEGRADED-1 | Scaffold, 2026-10-09 | No client pass recorded yet |
| COMBAT-1, APPLY-1..24, LOC-1..2 | M+ v0.1 (0.1.0) | Built and covered headlessly; no client pass recorded yet |
| SKIN-1..10 | EllesmereUI skin (2026-10-09) | Built and covered headlessly against an EllesmereUI fake; the look needs the client |
