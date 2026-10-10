# 03 — In-client smoke tests (review, 2026-10-10)

What only the client can verify, after the changes in `02_PROPOSED_CHANGES.md` land. The headless suites already ran in Step 0b. After the changes, re-run them once as pre-flight: `lua tests/run.lua` (expect 0 failed, pass count = the new `docs/test-cases.md` Total) and `luacheck .` (0/0). The complexity suite should then report `pass` with 0 blind files: `bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`.

## Pre-flight

- Retail client at `## Interface: 120100` (Midnight 12.1.0), on a US or EU character with M+ history. A KR/TW/CN character is needed only for the "unsupported portal" line in C-12.
- Addons: Premade Groups Filter 7.6.2 (hard dependency), this addon, and PremadeRegions **disabled** unless a step says otherwise. For C-05: EllesmereUI 9.4 with EllesmereUIBlizzardSkin and PremadeGroupsFilter_EllesmereUI.
- `/console scriptErrors 1`, then `/reload`. Keep the debug console open (`/pgfe debug`, `/pgfe debug on`).

## Per-change tests

### C-01 — hoisted hook table (F-001)
- **Setup:** PremadeRegions disabled, showRegionTags on.
- **Steps:** 1. Open the Group Finder → Dungeons → Mythic+ and search. 2. List a group and wait for an applicant.
- **Expected:** every listing's activity name starts with a colored region tag (`OCE`, `CHI`, ...), and the applicant's name carries one. No Lua error.
- **Pass:** tags appear exactly as before the change, and there is no error.

### C-02 — one map-info request per loading episode (F-002)
- **Setup:** a fresh login. If possible, the off-season (a week with no active M+ season), where `/dump #C_ChallengeMode.GetMapTable()` prints `0`.
- **Steps:** 1. Before the change, record the baseline: `/etrace`, filter `CHALLENGE_MODE_MAPS_UPDATE`, open PGF on Dungeons, watch for 30 s. 2. Repeat after the change.
- **Expected:** after the change, at most one `CHALLENGE_MODE_MAPS_UPDATE` follows each panel show while the readout says loading. In season, the readout fills after the first event.
- **Pass:** event count after the change ≤ 1 per panel show, with the off-season baseline noted (and **whether the loop existed before**, which settles F-002's *unverified* tag).

### C-03 — orphaned wrap is refused (F-003)
- **Setup:** PGF on Dungeons, maximized. In PGF's Advanced Filter Expression, type `mprating > 1000`. In the panel, tick *Max group age* and press Apply.
- **Steps:** 1. In PGF's expression box, delete only the line `-- [pgfe] close` and leave the `)` below it. Click away to commit. 2. Press Apply. 3. Press Clear.
- **Expected:** both print `The [pgfe] block in the Advanced Filter Expression is damaged; fix or delete it by hand.`, and the expression text is unchanged.
- **Pass:** both refuse, and PGF shows no expression parse error introduced by the addon.

### C-04 — PGF constants through the bridge (F-004)
- **Steps:** 1. Open the panel and check the readout's short names (e.g. `AOF 12  RLP 13`). 2. Tick Composition → *No one with my spec*, Apply, search.
- **Expected:** short names are unchanged, and no listing holding your spec remains. `/pgfe diagnostics` shows `PremadeGroupsFilter namespace=true`.
- **Pass:** identical behavior to before, with no "PGF version not supported".

### C-05 — skin paint fails closed (F-005)
- **Setup:** EllesmereUI suite fully on (all four conditions green on General → *EllesmereUI skin*).
- **Steps:** 1. `/reload`, then open PGF on Dungeons. 2. Read the debug console's `Skin` lines.
- **Expected:** `applied: N widgets`, and the panel is fully painted (flat shell, skinned checkboxes, dropdowns, buttons).
- **Pass:** fully painted, no Lua error. (The missing-primitive path is covered headless; it cannot be produced in client without a modified EllesmereUI.)

### C-06 — locale (F-006, F-010)
- **Steps:** 1. `/pgfe reset` (no path). 2. Hover General → *Defaults*. 3. Open the *EllesmereUI skin* tab with PGF's skin addon uninstalled, then disabled. Hover each status line.
- **Expected:** the same English text as before, word for word.
- **Pass:** no string changed, and no `nil` or a key name shown.

### C-07 — Apply message with targeting off (F-009)
- **Steps:** untick *Untimed dungeons at key level*, press Apply.
- **Expected:** chat says `Applied (dungeon checkboxes left as they were).` with no key range, and the copy box is empty and dimmed.
- **Pass:** chat and panel agree.

### C-08 — tooltips always hide (F-011)
- **Steps:** hover *Apply* so its tooltip shows. Without moving the mouse, type `/pgfe perf` and start a capture whose suspend arm stands the addon down. (Or bind `/pgfe disable` to a key and press it while hovering.)
- **Expected:** the panel hides and the tooltip goes with it.
- **Pass:** no orphan tooltip remains on screen.

### C-09 — scale guard (F-012)
- **Steps:** without EllesmereUI, change UI scale in System → Graphics.
- **Expected:** no Lua error, and nothing in the console.
- **Pass:** silent.

### C-10 — diagnostics (F-013)
- **Steps:** `/pgfe diagnostics`, then copy the report.
- **Expected:** a `hooks: env=true dialog=true searchRow=true applicantRow=true` line, the filter options, and feature events labelled as declared.
- **Pass:** every line present, and the report is identical while disabled except `stoodDown=true`.

### C-11 — launcher enable pair (F-015)
- **Steps:** 1. Right-click the minimap button and check *Enabled*. 2. Start `/pgfe perf` (suspend arm) and right-click again.
- **Expected:** *Enabled* reflects the setting (ticked) in both cases. Unticking it writes `enabled = false` (the chat echo).
- **Pass:** the menu entry always toggles the setting it shows.

### C-12 — secret-safe region lookup (F-016)
- **Steps:** search M+ with PremadeRegions disabled. In PGF's expression box, filter with `oce` (or `eng` on EU).
- **Expected:** only that region's leaders remain, with no Lua error. On a KR character, the region row shows the unsupported note and nothing raises.
- **Pass:** filtering works as before.

### C-13 — tests only (F-008, F-014)
Headless. No in-client step.

### U-1 / U-2 — after the re-vendor
- **Steps:** `bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`, run once on the tree before C-01 and once after.
- **Expected:** before C-01, the console names `modules/RegionTags.lua` as the file lizard crashed on, with numeric summary fields. After, `pass` with 0 blind files.
- **Pass:** both.

## Regression suite

1. `/reload`: no error. The `[Init]` line in the console shows `schema v1`, the profile and `enabled=true`.
2. Login → open PGF → Dungeons: the panel attaches below the dialog. Minimize PGF and the panel hides. Maximize it and the panel returns. Switch to another category and it hides.
3. Each panel option toggled once, then Apply: chat reports the applied message, PGF's checkboxes and expression update, and the search runs.
4. Clear: the managed block is gone and your own expression text is untouched.
5. Presets: Save as `t1`, change options, select `t1` (options restored), Delete `t1`.
6. `/pgfe disable`: the panel hides, region tags stop on the next search, and `/pgfe config` and bare `/pgfe` still open settings. `/pgfe enable` brings the panel back.
7. Enter combat (target dummy) and press Apply: `Cannot apply in combat.`
8. Profile switch to a new profile and back: the panel collapse state follows its profile, with no error.
9. Settings → AddOns → Ka0s Premade Groups Filter Extension: the landing page, General (both tabs) and Profiles open. Toggle every Master control once.

## Cross-addon (in client)

With several Ka0s addons loaded: type each loaded addon's root (`/at`, `/am`, `/bl`, `/cm`, `/kcd`, `/lh`, `/mm`, `/pm`, `/pfe`, `/pc`, `/wg`, `/pgfe`) and confirm each reaches its own addon. Open Settings → AddOns and confirm each addon appears once, and each multi-page addon's pages appear once each.

## Performance spot-check (F-002, F-012)

No perf bracket exists (`core/PerfSetup.lua` declares no bucket), so `/pgfe perf` has no bucket figures to read for these changes. The evidence for C-02 is the `/etrace` event count above. If a capture is wanted anyway, follow the standard's two-arm protocol (clean arm, then the suspend arm, no `/reload` between). Read the bucket figures, never the frame-time delta, and store the bundle via `/dev-copilot:wow-perf-analysis`.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-01 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-02 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26); off-season baseline: not recorded, so F-002's *unverified* tag stands |
| C-03 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-04 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-05 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-06 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-07 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-08 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-09 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-10 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-11 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-12 | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| C-13 | Yes (headless) | Pass | `lua tests/run.lua` 414/1/415; release run `docs/automated-tests/20261010-195814/` |
| U-1/U-2 | No | — | Blocked: waits on the LibKa0s re-vendor (#25; upstream LibKa0s#46, #47 still open). The complexity suite passes today with 0 blind files |
| Regression | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
| Cross-addon | Yes | Pass | Owner, in client, 2026-10-10 (before the merge of PR #26) |
