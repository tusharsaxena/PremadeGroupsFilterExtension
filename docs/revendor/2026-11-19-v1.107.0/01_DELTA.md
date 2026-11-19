Delta: LibKa0s v1.106.0 -> v1.107.0

Recorded before the commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.107.0 LibKa0s testkit tools` (tag commit 5e963659, local tag, not on origin yet: `git -C ../LibKa0s ls-remote --tags origin v1.107.0` prints nothing, as the run expects). Run under the cross-repo run `feat/2026-11-19-adoption-feedback` (Ka0sAddonsCommonTasks `docs/2026-11-19-ADOPTION_FEEDBACK/`), item AF-RV-PGFE. The adoption interview is skipped: the run's bundle pre-decides this addon's items (AF-RV-PGFE, AF-WVR-PGFE).

## Step 0 pre-flight (this addon)
Newest single-tag bundle `2026-11-16-v1.105.0` states base v1.93.0; the provenance line before its re-vendor named v1.93.0. ok. No correction owed.

## 3a Base
- `grep -n 'Bundles' CLAUDE.md` named v1.106.0 (CLAUDE.md:52) before the roll.
- Last payload commit, `git log -1 --format=%h -- libs/LibKa0s tests/_kit` = 96c9988; its CLAUDE.md names v1.106.0. They agree.
- Payload before the copy equalled the library at v1.106.0: `diff -rq --strip-trailing-cr` of both payloads against a v1.106.0 extract printed only the undeclared icons and the unshipped `media/sounds/callout` (no `LibKa0s sounds:` line). payload-matches.
- Library range: `git -C ../LibKa0s log --oneline v1.106.0..v1.107.0`, six commits (AF-LK-01, AF-LK-02, AF-DR-LK, AF-LK-03 x3).

## 3b/3c Per-file minors that moved
```
WidgetsDragHandle.lua     old: local DRAG_MINOR = 14     new: local DRAG_MINOR = 15
WidgetsDragHandleTip.lua  old: local DRAGTIP_MINOR = 1   new: local DRAGTIP_MINOR = 2
```
Every other file at its v1.106.0 minor; no file added or removed (`diff -rq` of the v1.106.0 and v1.107.0 extracts names those two files only). No cross-major skew.

## 3d Diffs
After the copy and before the prune, `diff -r --strip-trailing-cr` of both payloads against the extract printed nothing. After the prune the only differences are `Only in <extract>/LibKa0s/media/icons` (undeclared icons) and `media/sounds`.

## 3e Consumption
The addon looks up Core, Skin, Media, Compat, Env, DebugLog, Launcher, Lifecycle, Schema, Options, Slash, Widgets and Tooltip. It builds no drag strip: `grep -rn 'DragHandle\|TestStrip\|tooltipPlace' --include='*.lua' core modules settings defaults` finds nothing. The two files that moved reach this addon only through `tests/loader.lua:50-51`, which loads them in XML order.

## 3f Kit
`Kit.VERSION = 57` before and after (`tests/_kit/framework.lua:20`). The two payloads still move together.

## 3g Contract delta (blockers)
None. The two moved files are `LibKa0s-Widgets-1.0` secondaries this addon never calls. The release's *What a consumer owes* (a strip host's `onClose`, its `tooltipPlace` hook, the `settings` icon) binds strip hosts only.

## 3h Unrecorded tags
The listing found `v1.106.0` (vendored by 96c9988 with no bundle). Its span bundle is `../2026-11-19-v1.106.0-v1.106.0/`.

## 3i Icon declaration
`CLAUDE.md:53`, the next non-blank line under the provenance line, kept as written: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` It already carries `settings`, the icon v1.107.0 asks a strip host to declare. The prune (`lua <extract>/tools/prune-icons.lua .`) removed the 362 undeclared files and reported `sounds none`; the working tree's icon set is unchanged.

## 3j Tests that assume the whole icon folder
`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'` finds nothing.
