Refresh: LibKa0s v1.84.0 payload after the local tag moved

# 06 - Refresh 1 (Ka0s Premade Groups Filter Extension)

Run: 2026-11-01, item M3-RV of the findings remediation (Ka0sAddonsCommonTasks
`docs/2026-10-31-FINDINGS_REMEDIATION/`), on branch `feat/2026-10-31-findings-remediation`. Files
01..05 of this bundle are frozen and describe the copy of the tag at `e917ccd`. This file records the
later refresh and does not edit them.

## Why

The owner ruled on 2026-11-01 that `Ka0sMedia_*` is the only media picker in the collection, because
it is the one a skin can paint. The local, unpushed tag `v1.84.0` in `../LibKa0s` was re-cut for that
(`git ls-remote --tags origin v1.84.0` prints nothing), so this is a refresh and takes no new bundle.

| `git -C ../LibKa0s rev-parse v1.84.0^{commit}` | Commit |
|---|---|
| Old | `e917ccd` (checked: the six changed files at HEAD match it, ignoring line endings) |
| New | `7a8bc0f133ed118d2c79c7c5288b97964e24fae5` |

## What was done

The same procedure as the first copy: `git -C ../LibKa0s archive v1.84.0 LibKa0s testkit tools` into
scratch, both payloads copied whole, both diffs clean in content and bytes before the prune, then the
tag's `tools/prune-icons.lua` against the unchanged line `LibKa0s icons: chevron-down, chevron-up,
clear, close, copy, settings.` (`6 icon(s) declared; kept 7 file(s), removed 5833`). After the prune
the only difference from the tag is the undeclared icons. The provenance line still reads v1.84.0.
No file needed deleting against the diff.

## Files that changed

| File | Change |
|---|---|
| `libs/LibKa0s/Options.lua` | `LibKa0s-Options-1.0` minor **35 -> 36**: `lib.__PatchLSM30Border` is a no-op answering false |
| `libs/LibKa0s/OptionsWidgets.lua` | `WIDGETS_MINOR` **40 -> 41**: a row naming `LSM30_*` draws the picker whether or not that type is registered |
| `libs/LibKa0s/OptionsCompose.lua` | `COMPOSE_MINOR` **15 -> 16**: the composers write `Ka0sMedia_*` |
| `libs/LibKa0s/OptionsMedia.lua` | `MEDIA_MINOR` **1 -> 2**: `lib.__MediaWidgetType` answers for an `LSM30_*` name |
| `libs/LibKa0s/OptionsScroll.lua` | `SCROLL_MINOR` **9 -> 10**: comments only |
| `libs/LibKa0s/SkinAce.lua` | `ACE_MINOR` **5 -> 6**: comments only |

`tests/_kit/` is unchanged: kit revision 47. The docs keys move to Options
36.4.41.2.6.1.7.13.2.3.16.10.4.3.6.5.5.1.1.2 and Skin 11.1.19.1.13.7.11.2.6.

## Contract read

The library's *A consumer owes* list for this re-cut names a test pinning `LSM30_*` on a composed row,
one expecting `__PatchLSM30Border` to wrap, and a page calling `AceGUI:Create("LSM30_*")`. This addon
has none of the three: outside `libs/`, `tests/_kit/` and the frozen bundles nothing names `LSM30`,
`AceGUIWidgetLSMlists` or SharedMediaWidgets, and `git grep dialogControl` finds no row of its own.
It never vendored AceGUI-3.0-SharedMediaWidgets, so `libs/`, the `.toc`, `.pkgmeta` (no externals) and
`DEPENDENCIES.md` need no removal. LibSharedMedia-3.0 stays: the pickers read it. No blocker.

The addon's only media rows are the Skin tab's Font and Texture, which the library draws through
`lib.__MediaWidgetType`. No addon pin names the moved minors or docs keys.

## Gates

| Gate | Result |
|---|---|
| `ka0s-bounded luacheck .` | 0 warnings / 0 errors in 69 files |
| `lua tests/run.lua` | 462 passed, 0 failed, 1 skipped, 463 total; `test_vendor_sync` green against `7a8bc0f` |
| 1500-line cap | no authored file touched by this refresh; `docs/smoke-tests.md` is the only other edit |
