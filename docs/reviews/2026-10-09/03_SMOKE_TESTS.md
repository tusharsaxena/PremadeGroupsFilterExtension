# 03 — In-client smoke tests

Headless pre-flight, once the changes land: `lua tests/run.lua` and `luacheck .`. Both must be green,
and `docs/test-cases.md` plus the README badge must have moved in the same commits.

## Pre-flight

- Retail client on `## Interface: 120100`, with Premade Groups Filter (v7.6.2 or the current release)
  installed. Use a US or EU character who has a spec and at least one timed M+ dungeon this season.
- Run once without PremadeRegions installed, then repeat C-001 with it installed.
- `/console scriptErrors 1`. Open the debug console with `/pgfe debug on`.

## C-001: neutral-when-absent block (F-001)

- **Setup:** Group Finder → Dungeons, PGF dialog maximized. In the attached panel tick *Server regions*
  (pick your own region), *No one with my spec* and *No one with my class + role*.
- **Steps:** 1) Click Apply. Note the result count. 2) `/pgfe disable`. 3) Click PGF's Refresh.
  4) `/pgfe enable`, then Refresh.
- **Expected:** step 1 filters normally. In step 3 the list is **not** empty: it shows the unfiltered
  dungeon listings. In step 4 the filtered count returns. The Advanced Filter Expression shows the
  `-- [pgfe] begin` block containing `not pgfe_on or`.
- **Also:** untick the addon in the AddOns list, `/reload`, Refresh. The listings must still appear.
- **Pass:** no step shows zero results while groups are listed in the plain Blizzard view.

## C-002: spec via Compat (F-002)

- **Setup:** a character in a spec other than the most common one listed.
- **Steps:** tick *No one with my spec*, Apply, then hover several groups that list your spec.
- **Expected:** groups containing your spec are hidden. Change spec and confirm groups with the new spec
  are hidden without re-applying.
- **Pass:** the filter follows the current spec, and no Lua error appears at login or on spec change.

## C-003: number boxes (F-003)

- **Steps:** click the level box, type `45`, press Tab or click elsewhere. Then type `12` and press Enter.
- **Expected:** after `45` the box reverts to the stored level. After `12` the readout re-colors for +12.
- **Pass:** the box never shows a value the readout does not reflect after focus leaves it.

## C-004: minimized refusal (F-004)

- **Steps:** minimize PGF's dialog on Dungeons and click Apply. Then maximize and click Apply.
- **Expected:** first click: one chat line, `Maximize the Premade Groups Filter dialog first; nothing was applied.`, and no search. Second click: `Applied…` and the filtered search.
- **Pass:** both messages exactly as above.

## C-005: range and message (F-008, F-009)

- **Steps:** set level 10, Apply. Change the level to 12. Read the Range field. Untick key targeting and Apply.
- **Expected:** Range shows `12-12` after the edit. The second Apply prints `Applied; key range 12-12.` with no dungeon count.

## C-006: disabled suite

Headless only. No in-client step.

## C-007: perf

Headless runner. No in-client step. If the owner chooses an `envInject` bucket over the §12 exemption,
run `/pgfe perf` per the two-arm capture protocol with a PGF search inside the window, and record the
bundle via `/dev-copilot:wow-perf-analysis`. Read the bucket figure, not the frame-time delta.

## C-008: preset load (F-007)

- **Steps:** save preset `A`, load it, `/reload`, and load it again.
- **Expected:** no error, and the widgets match the preset.

## C-009: profile switch (F-010)

- **Steps:** with the dialog open, collapse the panel. `/pgfe profile <other>` (create it first in Profiles).
- **Expected:** the panel immediately shows the other profile's collapsed state.

## C-010: leader-name guard

Headless only.

## Regression suite

- `/reload` is clean. Login → `[Init]` line in the debug console with no rejected events.
- Open Group Finder → Dungeons: the panel appears under PGF. Switch to Raids: the panel hides.
- Enter and leave combat with the dialog open: no errors. Apply in combat prints `Cannot apply in combat.`
- Settings → AddOns → Ka0s Premade Groups Filter Extension: General and Profiles each appear once.
  Toggle Enable off and on.
- Cross-addon: type `/pgfe`, and each sibling's root if loaded. Each reaches its own addon.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-001 | | | |
| C-002 | | | |
| C-003 | | | |
| C-004 | | | |
| C-005 | | | |
| C-006 | | | headless |
| C-007 | | | headless (+ optional capture) |
| C-008 | | | |
| C-009 | | | |
| C-010 | | | headless |
