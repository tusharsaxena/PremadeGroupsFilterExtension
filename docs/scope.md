# Scope — Ka0s Premade Groups Filter Extension

## What it does

Mythic+ conveniences on top of Premade Groups Filter (PGF), applied through PGF's own state:

- **Key targeting** — tick every current-season dungeon the player has not timed at or above a
  chosen key level N (best timed level from `C_MythicPlus`, untimed counts as 0). With **Smart**
  on, the addon picks N itself: the lowest level at which at least one dungeon is still untimed
  (lowest best timed level + 1).
- **Server regions** — keep only groups whose leader's realm is in the selected regions (US portal:
  OCE, LA, CHI, MEX, BZL; EU portal: ENG, GER, FRA, ITA, SPA, POR, RUS). Picked from a dropdown of
  checkboxes headed by **Any**; none selected or all selected both mean Any.
- **Playstyle** — keep only groups listed with a ticked playstyle (Learning, Relaxed, Competitive,
  Carry Offered; PGF's `learning` / `relaxed` / `competitive` / `carry`). Any (none or all ticked) passes every playstyle.
- **Composition** — exclude groups that already have the player's spec, and/or the player's class in
  the player's role, picked from one dropdown (Any = no exclusion; both ticked = both exclusions).
- **Experienced leader** — the leader has timed this dungeon at N or above.
- **Min leader M+ score** — the leader's overall Mythic+ rating is at least S.
- **Max group age** — drop listings older than M minutes.
- **Presets** — named snapshots of the options (Smart included), shared by every character; the
  live options are per character.
- **Tooltips** — every option, dropdown entry and button explains itself on hover.
- **Toggle PGF Extension Filters** — one switch (panel and settings page) that takes the addon's
  block out of PGF's expression without turning the addon off, and puts it back.
- **Region tags** — the leader's colored server region in front of every Group Finder listing, and
  each applicant's in front of their name: the display half of PremadeRegions, which this addon
  replaces.
- **Apply** writes PGF's dungeon checkboxes and a marked block in PGF's Advanced Filter Expression,
  then runs PGF's search. **Clear** removes only the marked block.

## What it deliberately does not do

- **Filter on its own.** PGF evaluates every result; this addon only sets PGF's inputs and adds its
  `pgfe_*` variables (and, without PremadeRegions, the region variables) to PGF's per-result
  environment. Replacing PGF's filtering is out of scope.
- **Type into the Group Finder search box.** It is a secure edit box; addons cannot write it. The key
  range is shown in the panel's *Copy into search box* field for the player to copy, and Enter in it
  moves focus to the search box.
- **Write the game's own advanced filter.** PGF rewrites it from its dungeon checkboxes; writing it
  here would be overwritten.
- **Work without PGF.** PGF is a hard dependency (`docs/ARCHITECTURE.md` -> Documented deviations).
- **Raids, PvP, leader blocklists.** Tracked as GitHub issues, not in v0.1.
- **KR, TW and CN regions.** No realm data; the regions row shows a one-line note there instead of the region dropdown.
- **Raider.IO data.** Targeting uses the client's own season-best data only.
- **Classic flavors.** Retail only.
- **Translations.** English only for now; strings go through `NS.L` so a locale can be added.
