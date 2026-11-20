Delta: LibKa0s v1.107.0 -> v1.108.0

Recorded before the commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.108.0 LibKa0s testkit tools` (tag commit 56c20b76, local tag, not on origin yet: `git -C ../LibKa0s ls-remote --tags origin v1.108.0` prints nothing, as the run expects). Run under the cross-repo run `feat/2026-11-20-libka0s-94-97-99-100` (Ka0sAddonsCommonTasks `docs/2026-11-20-LIBKA0S_94_97_99_100/`), item SD-RV-PGFE. The adoption interview and the issue filing are skipped: the run's bundle pre-decides this addon's items (SD-RV-PGFE, SD-SK-PGFE).

## Step 0 pre-flight (this addon)
Newest single-tag bundle `2026-11-19-v1.107.0` states base v1.106.0; the provenance line before its re-vendor (25049da) named v1.106.0. ok. No correction owed.

## 3a Base
- `grep -n 'Bundles' CLAUDE.md` named v1.107.0 (CLAUDE.md:52) before the roll.
- Last payload commit, `git log -1 --format=%h -- libs/LibKa0s tests/_kit` = ccae1e7 (the v1.107.0 re-cut); its CLAUDE.md names v1.107.0. They agree.
- Payload before the copy equalled the library at v1.107.0: `diff -rq --strip-trailing-cr` of both payloads against a v1.107.0 extract printed only the undeclared icons and the unshipped `media/sounds/callout` (no `LibKa0s sounds:` line). payload-matches.
- Library range: `git -C ../LibKa0s log --oneline v1.107.0..v1.108.0`, 15 commits (SD-LK-94, SD-LK-99, SD-LK-100, SD-LK-97 Batches A to D, SD-LK-GUARD, SD-LK-REL).

## 3b/3c Per-file minors that moved
```
Core.lua                   old: 18  new: 19
Callout.lua                old: 4   new: 5
CalloutSettings.lua        old: 5   new: 6
WaypointArrow.lua          old: 2   new: 3
WaypointArrowSettings.lua  old: 2   new: 3
Charts.lua                 old: 2   new: 3
ChartsRender.lua           old: 1   new: 2
SkinPaint.lua              old: 19  new: 20
SkinPaintHud.lua           old: 1   new: 2
SkinPaintControls.lua      old: 18  new: 19
Widgets.lua                old: 29  new: 30
WidgetsDropdown.lua        old: 2   new: 3
WidgetsDragHandle.lua      old: 15  new: 16
WidgetsDragHandleTip.lua   old: 2   new: 3
WidgetsLineChart.lua       old: 7   new: 8
WidgetsBar.lua             old: 1   new: 2
OptionsCompose.lua         old: 19  new: 20
```
Every other file at its v1.107.0 minor; no file added or removed (`diff -rq` of the two extracts reports only `differ` lines). No cross-major skew.

## 3d Diffs
After the copy and before the prune, `diff -r --strip-trailing-cr` and `diff -rq` of both payloads against the extract printed nothing (content and bytes clean). After the prune the only differences are `Only in <extract>/LibKa0s/media/icons` (undeclared icons) and `media/sounds`.

## 3e Consumption
The addon looks up Compat, Core, DebugLog, Env, Launcher, Lifecycle, Media, Skin, Widgets (core/*Setup.lua), Options, Schema, Slash (settings/) and Tooltip (modules/Panel.lua). Of the moved majors it consumes Core (`NS.ApplySkin`, core/CoreSetup.lua:86, never with `skinBands`), Skin (S.Shell and the paint facade), Widgets (W.Dropdown through core/WidgetsSetup.lua:35, W.HeaderButtons) and Options (the settings page; `H.FontGroup`, `H.BorderGroup`, `H.BarGroup`, `H.ColorPair` appear only as degraded stubs, settings/OptionsSetup.lua:54-57, and no host calls a composer). It builds no Callout, WaypointArrow, Charts, LineChart, Bar, DragHandle or StatusBar.

## 3f Kit
`Kit.VERSION` 57 -> 58 (`tests/_kit/framework.lua:20`). The two payloads move together.

## 3g Contract delta (blockers)
None. OptionsCompose minor 20 flips the composers' defaults to follow the skin, but this addon composes no group. W.BarStyle, S.ApplyBarFill, Charts, the Callout and the WaypointArrow change defaults on surfaces it never builds. `Core.ApplySkin` moves only for a host table with `skinBands = true`, which it never passes. Kit revision 58's stricter skin-switch checks pass on the 19 declared surfaces as they stand (the suite is green right after the copy).

## 3h Unrecorded tags
None: every tag vendored since the store's first bundle has a bundle (v1.107.0's is `../2026-11-19-v1.107.0/`).

## 3i Icon declaration
`CLAUDE.md:53`, the next non-blank line under the provenance line, kept as written: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` The prune (`lua <extract>/tools/prune-icons.lua .`) removed the 362 undeclared files and reported `sounds none`; the working tree's icon set is unchanged.

## 3j Tests that assume the whole icon folder
`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'` finds nothing.
