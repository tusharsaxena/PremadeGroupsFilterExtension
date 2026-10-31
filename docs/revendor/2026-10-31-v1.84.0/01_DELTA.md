Delta: LibKa0s v1.83.0 -> v1.84.0

# LibKa0s v1.83.0 -> v1.84.0: the delta (Ka0s Premade Groups Filter Extension)

Step 7 of the 2026-10-31 findings remediation's M2 addendum (Ka0sAddonsCommonTasks
`docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`). A mechanical re-vendor through the
installed `/dev-copilot:wow-revendor-libka0s` at 2.6.1, with no interview and no GitHub issue: the
run names this addon's adoptions, and every other candidate is recorded as declined. Copied from
tag `v1.84.0` (LibKa0s commit `e917ccd`) with `git -C ../LibKa0s archive v1.84.0 LibKa0s testkit tools
| tar -x` into an empty scratch directory. The tag is local until the owner's go-ahead. The reads
below ran before the copy; this file was written straight after it, while the copy's gate ran.

## 3a. Base

`grep -n '[Bb]undles' CLAUDE.md` gives line 52, v1.83.0. The last payload commit
(`git log -1 -- libs/LibKa0s tests/_kit`, `e6bbce4`) carries the same line, so the base is v1.83.0.
Step 0 for this addon: the newest single-tag bundle, `2026-10-24-v1.77.0`, states base v1.76.0,
which agrees with the history. No base correction.

## 3b. Actual version

The vendored minors matched v1.83.0: `diff -rq` of the v1.83.0 extract against `libs/LibKa0s` printed
only the undeclared icons, and against `tests/_kit` printed nothing.

## 3c. Per-file minors

Loop over the tag's `LibKa0s/LibKa0s.xml`. Files not listed did not move. An empty old minor is new.

```
Schema.lua  old: 2  new: 3
Charts.lua  old:   new: 1
ChartsRender.lua  old:   new: 1
Skin.lua  old: 10  new: 11
SkinOwnerTokens.lua  old:   new: 1
SkinDefs.lua  old: 18  new: 19
SkinDefsOthers.lua  old:   new: 1
WidgetsDragHandle.lua  old: 8  new: 10
DebugLogDiagnostics.lua  old: 5  new: 6
Slash.lua  old: 20  new: 21
Options.lua  old: 34  new: 35
OptionsWidgets.lua  old: 38  new: 40
OptionsFlow.lua  old:   new: 2
OptionsIds.lua  old: 5  new: 6
OptionsIdSuggest.lua  old:   new: 1
OptionsTabs.lua  old: 11  new: 13
OptionsTabbed.lua  old:   new: 2
OptionsCompose.lua  old: 14  new: 15
OptionsSkinPicker.lua  old: 4  new: 5
OptionsSkinPickerRows.lua  old:   new: 1
SimPanel.lua  old: 8  new: 9
SimPanelRender.lua  old:   new: 1
```

Nothing sits behind: no cross-major skew. The payload is now 64 files in twenty majors.

## 3d. Diffs

Before the copy, content differed by the release alone. After the copy and before the prune, both
content and byte diffs were empty in both payloads. After the prune the only difference is the
undeclared `media/icons` files. Nothing upstream was removed, so no file was deleted by hand.

## 3e. Consumption map

Env, Lifecycle, Compat, Media, Core, Launcher, DebugLog and Skin in `core/`, Skin in
`modules/Diagnostics.lua`, Options, Slash and Schema in `settings/`. Charts (new), Perf, Sim and
Widgets have no direct lookup.

## 3f. Kit revision

46 -> 47 (`grep -n 'Kit.VERSION'`). Both payloads move in one commit, per the kit-revision pairing
rule.

## 3g. Contract delta

Diffed the Options, Schema, Slash, DebugLog, Widgets and Skin documents, old against new. No surface
already in use changed its contract. `grep -rn '__Attach' --include='*.lua'` outside the payloads
finds no site, so no host member's call site moved.

### Blockers

- **`O.PositionBlock` is a new public member the degradation stub owes**
  (`docs/api/Options/version-35.4.40.2.6.1.7.13.2.3.15.9.4.3.6.5.5.1.1.1-docs.md`, *What changed at
  this version*; `tests/test_surface_parity.lua`). Fixed in the re-vendor commit:
  `settings/OptionsSetup.lua` gains an inert `H.PositionBlock`.
- **`tests/loader.lua` types the payload's file list.** The nine new files join it in XML order in
  the re-vendor commit.

## 3h. Span

`grep -vxF -f recorded.txt vendored.txt` prints nothing. No span bundle.

## 3i. Icons

Kept: `LibKa0s icons: chevron-down, chevron-up, clear, close, copy, settings.`, directly under the
provenance line. A pruned icon draws blank and resolves to a path, so the owner's smoke stays the
backstop for a name the host forgot.

## 3j. Whole-folder tests

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'` prints nothing.
