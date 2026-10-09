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
| APPLY-1..14 | Attached panel and Apply | The panel under PGF, targeting, regions, composition, leader, age, presets, Clear, PGF minimized |
| LOC-1..2 | Non-English client | Realm-name and dungeon-name seams on a deDE/frFR client |

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
  button, and a *Reset all settings* button. No scale, alpha, lock, visibility or test-mode rows.
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
  the result is the same. Result:
- **APPLY-5. Composition.** As a Beast Mastery hunter, *No one with my spec* on, Apply → no listed
  group already has a Beast Mastery hunter. Then *No one with my class + role* instead → no listed
  group has a damage-dealing hunter of any spec. Switch spec without re-applying and refresh the
  search → the exclusion follows the new spec. Result:
- **APPLY-6. User expression kept.** Type `voice` in PGF's advanced filter, Apply → the marked block
  wraps your text; Clear → exactly `voice` remains and the dungeon ticks are unchanged. Repeat with
  `mprating > 2000 or partyfit` → results honor both the block and the `or`. Result:
- **APPLY-7. Presets across characters.** Save a preset with Save as…, log in on another character,
  pick it from the Presets menu → the options match; the first character's own options are
  unchanged; Delete asks for confirmation and removes it from both characters' menus. Result:
- **APPLY-8. Range field.** The `N-N` field selects all on click and cannot be typed over;
  Ctrl+C, click the Group Finder search box, Ctrl+V → it pastes `14-14`. Result:
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
- **APPLY-14. Collapse.** Press the panel's minimize button → it folds to its title bar; `/reload` →
  it stays folded; maximize → the rows return. Result:

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
| COMBAT-1, APPLY-1..14, LOC-1..2 | M+ v0.1 (0.1.0) | Built and covered headlessly; no client pass recorded yet |
