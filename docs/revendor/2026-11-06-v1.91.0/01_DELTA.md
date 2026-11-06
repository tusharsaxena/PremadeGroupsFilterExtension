Delta: LibKa0s v1.90.0 -> v1.91.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-FOLLOWUPS_V1_91/` (item FU-RV-PGFE). The tag is local and not pushed: `git -C ../LibKa0s ls-remote --tags origin v1.91.0` prints nothing, which is expected for this run and is not a refresh (the provenance named v1.90.0). Its commit is `55bfbb4` (`git -C ../LibKa0s rev-parse v1.91.0^{commit}`). Payload taken with `git -C ../LibKa0s archive v1.91.0 LibKa0s testkit tools`, never the working tree.

Step 0 (the collection-wide pre-flight) was skipped: the installed skill's roster regex expects markdown links where ADDONS.md writes `` `../../<Folder>/` ``, so it matches nothing. That defect is fixed upstream in this run (FU-DC1). The per-addon base check below covers this addon.

## Base (3a, 3b)

- `grep -n '[Bb]undles' CLAUDE.md` -> `52: Bundles [LibKa0s](...) v1.90.0 (MIT).`
- `git log -1 --format=%h -- libs/LibKa0s tests/_kit` -> `c47d112` (SF2-RV-PGFE, the v1.90.0 refresh), whose `CLAUDE.md` line names v1.90.0. No `CLAUDE.md` commit since. The two agree.
- `diff -rq` of both payloads against `git -C ../LibKa0s archive v1.90.0 LibKa0s testkit` shows only the undeclared icons (`Only in <extract>/LibKa0s/media/icons`), so the bytes are v1.90.0's and the minors match the line.
- Newest single-tag bundle `2026-11-06-v1.90.0` states base v1.89.0, and the provenance before its re-vendor was v1.89.0 (that bundle's own 3a). No correction owed.

Range: `git -C ../LibKa0s log --oneline v1.90.0..v1.91.0` (9 commits; the release is `FU-L1`, `FU-L2`, `FU-L3`).

## Per-file minors (3c), moved and new files only

`for f in <v1.91.0 LibKa0s.xml files>: grep 'local (MAJOR, )?[A-Z_]*MINOR = ...' old against tag`

| File | old | new |
|---|---|---|
| Core.lua | 16 | 17 |
| CorePixel.lua | (new) | 1 |
| SkinPaintExtras.lua | 18 | 19 |
| SkinPaintHud.lua | (new) | 1 |
| SkinAceConfirm.lua | (new) | 1 |
| Widgets.lua | 25 | 26 |
| WidgetsDropdown.lua | (new) | 1 |
| WidgetsLineChart.lua | 6 | 7 |

Every other file is at its v1.90.0 minor. No file behind: no cross-major skew. No `NEEDS_*` floor rises (CHANGELOG v1.91.0, "Versions in this release").

## Diffs (3d)

Before the copy, content differs only in the files above and the undeclared icons. After `cp -r` of both payloads and before the prune: `diff -r` (bytes) is empty for `LibKa0s` and for `testkit`, so content is empty too. Nothing only in the addon: no file was removed upstream. After the prune, `diff -r --strip-trailing-cr` shows only `Only in <extract>/LibKa0s/media/icons` lines, and `testkit` is clean.

## Kit (3f)

`grep -n 'Kit.VERSION' framework.lua`: revision 51 on both sides. The two payloads are still copied whole in one commit (the pairing rule); `tests/_kit/` has no byte change.

## Consumption (3e)

As at v1.90.0: Compat, Core, DebugLog, Env, Launcher, Lifecycle, Media, Options, Schema, Skin (2 sites), Slash, Widgets. The moved majors Core, Skin and Widgets are consumed. This addon draws no line chart (`grep -rn 'LineChart'` outside the payloads prints nothing).

## Contract delta (3g)

Read: CHANGELOG v1.91.0 and the new documents `docs/api/Core/version-17.1-docs.md`, `docs/api/Widgets/version-26.1.6.13.7.8.5-docs.md`, `docs/api/Skin/version-17.1.27.8.19.19.1.1.17.4.9-docs.md`. The peels are pure moves ("No member, option or behavior changes"); WidgetsLineChart 7 changes only how a chart's lines are sized. `docs/releasing.md` step 8 at the tag: v1.91.0 adds no Skin facade, major or instance member, and a consumer whose tests load library files by name adds the four new files. `grep -rn '__Attach' --include='*.lua'` outside the payloads finds nothing. No addon stub mirrors a moved member (`grep -rn '__Pixel\|__WatchPixels\|__OnPixelScale\|__aceConfirm\|__dropdownKit'` outside the payloads prints nothing).

### Blockers

- **`tests/loader.lua`'s explicit LibKa0s list** (`LIBKA0S`, lines 14-86 after the fix) loads library files by name, and `tests/test_harness.lua:74` pins it to `LibKa0s.xml` in XML order. The four new files are added in that order: `CorePixel.lua` after `Core.lua`, `SkinPaintHud.lua` and `SkinAceConfirm.lua` after `SkinPaintExtras.lua`, `WidgetsDropdown.lua` after `Widgets.lua`. Fixed in the re-vendor commit.
- No test pins an exact library minor (`grep -rnE '_MINOR|minors\[' tests/*.lua` finds none), so no pin moves.

## Icons (3i, 3j)

`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 53, directly under the provenance line: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` Kept as decided by the run plan. The tag's `docs/releasing.md` library-drawn table adds no name in this range. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'` prints nothing: no whole-catalog test. `grep -rn '__releaseChrome'` outside the payloads prints nothing: no dead stub mirror.

## Span check (3h)

Run with `tag_at` rewritten on a named variable (the installed skill's text shows `"Ka0s"`/`"repos:"` where `"$1"`/`"$2:"` were meant; fixed upstream in FU-DC1). The walk over `libs/LibKa0s`, `tests/_kit` and the `CLAUDE.md` rolls since the store's horizon (2026-10-22) lists v1.75.0 v1.75.1 v1.75.2 v1.76.0 v1.77.0 v1.80.0 v1.81.0 v1.82.0 v1.83.0 v1.84.0 v1.85.0 v1.89.0 v1.90.0, every one recorded. No span bundle is owed.
