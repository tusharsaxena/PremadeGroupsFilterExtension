Delta: LibKa0s v1.93.0 -> v1.105.0

Recorded before anything was committed. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.105.0 LibKa0s testkit tools` (tag commit 79b1d9c4, local tag, not on origin yet: `git -C ../LibKa0s ls-remote --tags origin v1.105.0` prints nothing, as the run expects). Run under the cross-repo run `feat/2026-11-16-libka0s-75-plus` (Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/`), item RV-PGFE: the copy and bundle half only.

## Step 0 pre-flight (this addon)
Newest single-tag bundle `2026-11-07-v1.93.0` states base v1.92.0; the provenance line before its re-vendor commit (738eec1) named v1.92.0. ok. No correction owed.

## 3a Base
- `grep -n 'Bundles' CLAUDE.md` named v1.93.0 (CLAUDE.md:52) before the roll.
- Last payload commit, `git log -1 --format=%h -- libs/LibKa0s tests/_kit` = a17105d; its CLAUDE.md names v1.93.0. They agree.
- Payload before the copy equalled the library at v1.93.0: `diff -rq --strip-trailing-cr` of both payloads against a v1.93.0 extract printed nothing apart from the undeclared icons (payload-matches).
- Library range: `git -C ../LibKa0s log --oneline v1.93.0..v1.105.0` is 117 commits, spanning v1.94.0 to v1.105.0.

## 3b/3c Per-file minors that moved (old = this addon at v1.93.0, new = v1.105.0)
```
Core.lua  old: 17  new: 18
Tooltip.lua  old: none  new: 1
Compat.lua  old: 3  new: 4
Role.lua  old: none  new: 1
Callout.lua  old: none  new: 4
CalloutSettings.lua  old: none  new: 5
WaypointArrow.lua  old: none  new: 2
WaypointArrowSettings.lua  old: none  new: 2
Charts.lua  old: 1  new: 2
Media.lua  old: 12  new: 13
Skin.lua  old: 17  new: 18
SkinDefs.lua  old: 27  new: 28
SkinDefsOthers.lua  old: 8  new: 10
Widgets.lua  old: 26  new: 27
WidgetsDropdown.lua  old: 1  new: 2
WidgetsReorder.lua  old: 6  new: 7
WidgetsDragHandle.lua  old: 13  new: 14
WidgetsDragHandleTip.lua  old: none  new: 1
WidgetsCopyWindow.lua  old: 5  new: 6
WidgetsHeader.lua  old: none  new: 1
WidgetsBar.lua  old: none  new: 1
DebugLog.lua  old: 22  new: 23
DebugLogDiagnostics.lua  old: 7  new: 11
DebugLogWindow.lua  old: 4  new: 5
Launcher.lua  old: 9  new: 11
OptionsWidgets.lua  old: 45  new: 46
OptionsNav.lua  old: 6  new: 7
OptionsSkinPicker.lua  old: 11  new: 12
OptionsSkinPickerQueue.lua  old: none  new: 1
IconBrowserWindow.lua  old: 1  new: 2
IconBrowser.lua  old: 1  new: 2
PerfPanel.lua  old: 13  new: 14
Sim.lua  old: 2  new: 3
SimPanel.lua  old: 10  new: 11
SimPanelRender.lua  old: 3  new: 4
```
Every file not listed matched before the copy, so there is no cross-major skew. Ten files are new in this range: Role, Callout, CalloutSettings, WaypointArrow, WaypointArrowSettings (v1.95.0 to v1.99.0), and Tooltip, WidgetsDragHandleTip, WidgetsHeader, WidgetsBar, OptionsSkinPickerQueue (v1.105.0).

## 3d Diffs
Before the prune, `diff -r --strip-trailing-cr` and `diff -r` of both payloads against the v1.105.0 extract were empty (content and bytes). After `tools/prune-icons.lua`, the only differences are `Only in <extract>/LibKa0s/media/icons` (undeclared icons) and `Only in <extract>/LibKa0s/media/sounds` (no `LibKa0s sounds:` line, so none ship; 362 files removed). No `Only in libs/LibKa0s` line, so nothing upstream removed survives here. `tests/test_vendor_sync.lua` is green.

## 3e Consumption map
`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua'`, minus libs/ and tests/:
```
core/Compat.lua:11:LibStub("LibKa0s-Compat-1.0", true)
core/CoreSetup.lua:19:LibStub("LibKa0s-Core-1.0", true)
core/DebugLogSetup.lua:9:LibStub("LibKa0s-DebugLog-1.0", true)
core/EnvSetup.lua:7:LibStub("LibKa0s-Env-1.0", true)
core/LauncherSetup.lua:12:LibStub("LibKa0s-Launcher-1.0", true)
core/LifecycleSetup.lua:13:LibStub("LibKa0s-Lifecycle-1.0", true)
core/MediaSetup.lua:9:LibStub("LibKa0s-Media-1.0", true)
core/SkinSetup.lua:90:LibStub("LibKa0s-Skin-1.0", true)
core/WidgetsSetup.lua:20:LibStub("LibKa0s-Widgets-1.0", true)
modules/Diagnostics.lua:91:LibStub("LibKa0s-Skin-1.0", true)
settings/OptionsSetup.lua:11:LibStub("LibKa0s-Options-1.0", true)
settings/SchemaSetup.lua:187:LibStub("LibKa0s-Schema-1.0", true)
settings/Slash.lua:64:LibStub("LibKa0s-Slash-1.0", true)
```
Majors in the payload with no lookup in this addon: LibKa0s-Bus-1.0 LibKa0s-Callout-1.0 LibKa0s-Charts-1.0 LibKa0s-Glow-1.0 LibKa0s-IconBrowser-1.0 LibKa0s-Item-1.0 LibKa0s-Perf-1.0 LibKa0s-Pool-1.0 LibKa0s-Role-1.0 LibKa0s-Sim-1.0 LibKa0s-Toast-1.0 LibKa0s-Tooltip-1.0 LibKa0s-WaypointArrow-1.0.

## 3f Kit revision
```
old: tests/_kit/framework.lua:20:Kit.VERSION = 53
new: testkit/framework.lua:20:Kit.VERSION = 57
```
Kit revision 57 pairs with v1.105.0 and both payloads are copied whole in one commit. Revision 57 holds a frame with a raw event registration until it unregisters (LibKa0s#75); no suite here relied on a collection dropping one, and the full run is green.

## 3g Contract delta and Blockers
Majors that moved a minor and that this addon looks up: Core (18), Compat (4), Media (13), Skin (SkinDefs 28, SkinDefsOthers 10, Skin 18), Widgets (27 and its secondaries), DebugLog (23.11.1.5), Launcher (11), Options (OptionsWidgets 46, OptionsNav 7, OptionsSkinPicker 12, new OptionsSkinPickerQueue 1).

Host-supplied members, `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`:
```
none
```
**Blockers: none.** No host-supplied member's call site moved. What the jump forced in this addon's own suites, all fixed in the re-vendor commit (the tag's CHANGELOG, *What a consumer owes*):
- `tests/loader.lua`'s hand list of library files (checked against `LibKa0s.xml` by `tests/test_harness.lua`) gains the ten new payload files in XML order. Without `OptionsSkinPickerQueue.lua` the run crashed at `OptionsSkinPicker.lua:287` (`lib.__pickerQueueKit` nil), which is the missing loader line, not a library fault.
- Surface parity (`tests/test_surface_parity.lua`): the DebugLog stub gains `Report` and `Serialize` (DebugLogDiagnostics minor 11), the Options helpers stub gains `SideTabs` (OptionsNav minor 7, v1.100.0), and `NS.Compat` wires the four identity readers `RegionalNames`, `UnitCharacterName`, `CharacterKey`, `RealmKey` (Compat minor 4, v1.94.0) with Retail fallbacks. No caller uses them yet, so behaviour does not change. `.luacheckrc` gains the `UnitName` read global the Compat fallback reads.
- No suite here pins a moved minor, a skin's `icon.hot`, or Ka0s Default's list values.

## 3h Unrecorded vendored tags
The audit walk (plus provenance rolls) over `docs/revendor/` since its first bundle:
```
(empty)
```
No span bundle is owed: every tag this addon vendored has its bundle. The library tags between v1.93.0 and v1.105.0 were never vendored here and are covered by this range.

## 3i Icon declaration
- `grep -n 'LibKa0s icons:' CLAUDE.md`: 53:LibKa0s icons: chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.
- Kept as written. It already carries `settings`, which kit 57's `LIBRARY_MARKS` now requires (the library windows' new settings mark). Prune: `12 icon(s) declared; kept 13 file(s), removed 0` (the 13th is the Open Iconic licence).
- Sounds: no `LibKa0s sounds:` line, so none ship (`kept 0 file(s), removed 362`). This addon does not consume Callout.
- README credits: only Open Iconic ships, as before. No credit change.

## 3j Tests that assume the whole icon folder
`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'`:
```
none
```

## Dead stub mirrors
`grep -rn '__releaseChrome'` outside libs and the kit: none.

## Size note
v1.99.0's `media/waypoint/` and v1.97.0's two fonts (Bebas Neue, Russo One, with their OFL texts) ship whole; they are not pruneable today.
