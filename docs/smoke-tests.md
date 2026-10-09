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
| APPLY-1..8 | Apply (plan Tasks 7–8) | The attached panel, targeting, regions, composition, presets, Clear |
| LOC-1..2 | Non-English client | Realm-name and dungeon-name seams on a deDE/frFR client |

## Before you start

Retail client at the TOC's interface, Premade Groups Filter 7.6.2 or later enabled, PremadeRegions
**disabled** unless a check says otherwise, a level-80 character with some timed Mythic+ runs this
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
  `/pgfe diagnostics` → `stoodDown=true`, `holds` lists `disabled`; feature verbs (once Task 7 lands,
  `/pgfe apply`) answer with the disabled line. Result:
- **STATE-2. Launcher menu.** Right-click the minimap button → *Enabled* toggles the addon; the other
  entries gray while disabled; left-click opens Settings. Result:

## Combat

- **COMBAT-1. Apply refused in combat** (Task 7). Attack a training dummy, press Apply → a chat line
  says it cannot run in combat; nothing in PGF changes. Result:
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

## Apply

Filled in as plan Tasks 7–8 land; each is in *Pending sign-off* until it records a pass.

- **APPLY-1. Attached panel.** Open PGF's dialog on the dungeon category → the panel sits under it,
  same width; switch PGF to raids → it hides; close PGF → it hides. Result:
- **APPLY-2. Targeting at your timed level + 1.** Set the key level one above your lowest timed
  dungeon, press Apply → exactly the dungeons timed below it are ticked in PGF **and** in the game's
  own Filter → Dungeons menu; the search runs. Result:
- **APPLY-3. Everything timed.** Set the key level to 2 → the "timed every dungeon" line; nothing
  changes. Result:
- **APPLY-4. Regions.** US portal, regions on with OCE only → every listed leader is on an OCE realm.
  Result:
- **APPLY-5. Composition.** No one with my spec on → no listed group already has your spec. Result:
- **APPLY-6. User expression kept.** Type `voice` in PGF's advanced filter, Apply → the marked block
  wraps your text; Clear → exactly `voice` remains. Result:
- **APPLY-7. Presets across characters.** Save a preset, log in on another character, load it → the
  options match; the first character's live options are unchanged. Result:
- **APPLY-8. Range field.** The `N-N` field selects all on click; Ctrl+C then Ctrl+V into the search
  box pastes it. Result:

## Non-English client

The headless mock is enUS, so a path keyed off a localized string passes there whether it is right
or wrong. These are the addon's locale seams.

- **LOC-1. Realm names on a deDE/frFR client** (Task 2). Leader names carry the realm as the client
  shows it, and the region lookup normalizes that string (lowercase, spaces and punctuation removed)
  against the realm map. On a deDE client, EU portal, regions on with GER only, Apply → the listed
  leaders are on German realms. **Failure looks like:** an empty result list, or leaders from
  English realms only, because a localized realm spelling (an umlaut or accent, `Aman'Thul` vs a
  translated name) did not normalize to the map's key. Headless stand-ins: the `regions:` cases for
  apostrophes, accents and the no-suffix leader. Signed off on English only if the leader names on
  that client are byte-identical to the enUS ones (check one German realm with `/pgfe debug on`).
  Result:
- **LOC-2. Dungeon names on a deDE/frFR client** (Task 3). The panel's readout uses PGF's
  locale-independent keyword for each dungeon (by map id) and falls back to the localized name's
  initials only for an unknown map. On a deDE client the readout shows the same short names as on
  enUS (AOF, DON, …). **Failure looks like:** initials of German dungeon names in the readout, or a
  stray `%s`/`%d` in any panel line. Headless stand-in: the `season:` short-name cases. Sufficient on
  English for the format check; the keyword path needs the client. Result:

## Pending sign-off

| ID | Origin | Why it is owed |
|---|---|---|
| INSTALL-1..3, SLASH-1..3, PANEL-1..3, PROFILE-1..2, STATE-1..2, COMBAT-2, DIAG-1..2, DEGRADED-1 | Scaffold, 2026-10-09 | No client pass recorded yet |
| COMBAT-1, APPLY-1..8, LOC-1..2 | M+ v0.1 plan | The features land in plan Tasks 2–8 |
