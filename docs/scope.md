# Scope — Ka0s Premade Groups Filter Extension

## What it does

Mythic+ conveniences on top of Premade Groups Filter (PGF), applied through PGF's own state:

- **Key targeting** — tick every current-season dungeon the player has not timed at or above a
  chosen key level N (best timed level from `C_MythicPlus`, untimed counts as 0).
- **Server regions** — keep only groups whose leader's realm is in the selected regions (US portal:
  OCE, LA, CHI, MEX, BZL; EU portal: ENG, GER, FRA, ITA, SPA, POR, RUS).
- **Composition** — exclude groups that already have the player's spec, and/or the player's class in
  the player's role.
- **Experienced leader** — the leader has timed this dungeon at N or above.
- **Max group age** — drop listings older than M minutes.
- **Presets** — named snapshots of the options, shared by every character; the live options are
  per character.
- **Apply** writes PGF's dungeon checkboxes and a marked block in PGF's Advanced Filter Expression,
  then runs PGF's search. **Clear** removes only the marked block.

## What it deliberately does not do

- **Filter on its own.** PGF evaluates every result; this addon only sets PGF's inputs and adds two
  variables to PGF's per-result environment. Replacing PGF's filtering is out of scope.
- **Type into the Group Finder search box.** It is a secure edit box; addons cannot write it. The key
  range is shown for the player to copy.
- **Write the game's own advanced filter.** PGF rewrites it from its dungeon checkboxes; writing it
  here would be overwritten.
- **Work without PGF.** PGF is a hard dependency (`docs/ARCHITECTURE.md` -> Documented deviations).
- **Raids, PvP, leader blocklists.** Tracked as GitHub issues, not in v0.1.
- **KR, TW and CN regions.** No realm data; the regions row shows a one-line note there instead of region buttons.
- **Raider.IO data.** Targeting uses the client's own season-best data only.
- **Classic flavors.** Retail only.
- **Translations.** English only for now; strings go through `NS.L` so a locale can be added.
