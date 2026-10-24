Delta: LibKa0s v1.76.0 -> v1.77.0

# LibKa0s v1.76.0 -> v1.77.0: the delta (Ka0s Premade Groups Filter Extension)

Item PG-RV of the 2026-10-24 "keybindings (015), settings layout (020), frame strata (030)" run
(Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`). A mechanical re-vendor through
the installed `/dev-copilot:wow-revendor-libka0s` at 2.4.0: no adoption interview and no GitHub issue,
because the run's item spec pre-decides that (the only PGFE adoption this run is PG-ZS, held for the
owner). Copied from the annotated tag `v1.77.0` (tag object `7380d36`, LibKa0s commit `78240f7`)
with `git -C ../LibKa0s archive v1.77.0 LibKa0s testkit tools | tar -x` into a scratch directory,
then `libs/LibKa0s/` and `tests/_kit/` replaced whole. The tag is **local only**
(`git -C ../LibKa0s ls-remote --tags origin v1.77.0` prints nothing), and it was never checked out.
`tools/` was extracted only for `prune-icons.lua` and is not copied.

This file was written before the copy. The *After the copy* section at the end was added once the
copy and the prune had run.

## Step 0. Pre-flight (this addon)

```sh
head -1 docs/revendor/2026-10-23-v1.76.0/01_DELTA.md
# Delta: LibKa0s v1.75.2 -> v1.76.0
# the commit that rolled the line to v1.76.0, and the line at its parent:
# bfa0674 (PG-RV: Re-vendor LibKa0s v1.76.0 and refresh the standard reference), parent at v1.75.2
```

The newest single-tag bundle states base v1.75.2, and the history agrees. No correction is owed.

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 50:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.76.0 (MIT).
c=$(git log -1 --format=%H -- libs/LibKa0s tests/_kit)   # eccfe7b PG-RV2: Re-vendor LibKa0s from the moved v1.76.0 tag (LK-91 labels)
git show "$c:CLAUDE.md" | grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9]+\.[0-9]+\.[0-9]+'
# Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.76.0
git -C ../LibKa0s archive v1.76.0 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq <scratch>/claimed/LibKa0s libs/LibKa0s | grep -v 'Only in .*media/icons'   # empty
diff -rq <scratch>/claimed/testkit tests/_kit                                      # empty
```

The line and the last payload commit agree, and the payload is the (moved) v1.76.0 payload apart
from the icons the declaration prunes. **Base: v1.76.0.**

```sh
git -C ../LibKa0s log --oneline v1.76.0..v1.77.0
# 78240f7 LK-90: close v1.77.0 with its release record (20261024-074358)
# 3c2bb20 LK-90: split three functions over CCN 15 that the release run found
# ea2cb09 LK-90: close v1.77.0: version block, pointers, consumers, band
# 0a5807d LK-13: Sync the Keybindings tab with Options -> Keybindings
# 9ab9d37 LK-12: Add the Keybindings tab, OptionsKeybinds minor 2
# 0b10ad3 LK-11: address review — refuse BUTTON1/BUTTON2 on the client chord route
# 88dfa8a LK-11: Add OptionsKeybinds.lua minor 1, the key binding model
# 66b7bd4 LK-20: Add O.StrataTooltip, the one shared strata-row tooltip
# 7de587b LK-04: Close the IdList suggestion list at the start of combat
# f452d69 LK-03: Clamp the dropdown menu and the autocomplete list to the screen
# dda3ff9 LK-02: Add DragHandle level offset, ApplyLevel and ignoreParentAlpha
# 665bf63 LK-01: Make the tool windows toplevel and re-raise shown StaticPopups
# 8173cdb LK-10: Kit revision 42: binding mock, layer recorder, Bindings.xml check
# 0a1683a LK-00: Open v1.77.0 with an unreleased CHANGELOG section
# 9df6df8 Merge branch 'feat/2026-10-23-sim-preview-mode-strips'
git -C ../LibKa0s diff --stat v1.76.0 v1.77.0 -- LibKa0s testkit
#  13 LibKa0s/ files (OptionsKeybinds.lua new, 819 lines; LibKa0s.xml +1) and 5 testkit/ files
#  (bindings_xml.lua, mock_bindings.lua, mock_layers.lua new); 18 files, 1672 insertions, 34 deletions
```

## 3b. Actual version

```sh
grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua
```

Every vendored minor equals the v1.76.0 tag's (3c's `old:` column). Claim and bytes agree.

## 3c. Per-file minor delta

The loop over the tag's `LibKa0s/LibKa0s.xml` (the spec's 3c command), 41 files. Twelve moved and
one is new; the other 28 are unchanged, and none went backwards.

| File | v1.76.0 | v1.77.0 |
|---|---|---|
| `Core.lua` | `MINOR` 11 | `MINOR` 12 |
| `Widgets.lua` | `MINOR` 14 | `MINOR` 15 |
| `WidgetsDragHandle.lua` | `DRAG_MINOR` 4 | `DRAG_MINOR` 5 |
| `WidgetsAutocomplete.lua` | `AUTOCOMPLETE_MINOR` 2 | `AUTOCOMPLETE_MINOR` 3 |
| `DebugLog.lua` | `MINOR` 20 | `MINOR` 21 |
| `Options.lua` | `MINOR` 29 | `MINOR` 30 |
| `OptionsIds.lua` | `IDS_MINOR` 2 | `IDS_MINOR` 3 |
| `OptionsCombat.lua` | `COMBAT_MINOR` 1 | `COMBAT_MINOR` 2 |
| `OptionsCompose.lua` | `COMPOSE_MINOR` 7 | `COMPOSE_MINOR` 8 |
| `OptionsKeybinds.lua` | (new) | `KEYBINDS_MINOR` 3 |
| `PerfPanel.lua` | `PANEL_MINOR` 8 | `PANEL_MINOR` 9 |
| `SimPanel.lua` | `SIM_PANEL_MINOR` 5 | `SIM_PANEL_MINOR` 6 |

No cross-major skew.

## 3d. Both diffs (before the copy)

```sh
diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -v 'Only in .*media/icons'
diff -rq                     <scratch>/LibKa0s libs/LibKa0s | grep -v 'media/icons'
# both: the twelve moved files above plus LibKa0s.xml differ; Only in <scratch>/LibKa0s: OptionsKeybinds.lua
diff -rq <scratch>/testkit tests/_kit
# README.md and framework.lua differ; Only in <scratch>/testkit: bindings_xml.lua, mock_bindings.lua, mock_layers.lua
```

Content and bytes give the same files, so there is no line-ending disagreement; the copy is the fix.
223 `Only in <scratch>/LibKa0s/media/icons` lines (221 Open Iconic icons plus the `phosphor/` and
`game-icons/` folders) are the icons PGFE does not declare (the declaration working, not drift).
No `Only in libs/LibKa0s` or `Only in tests/_kit` line: nothing was removed upstream.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

PGFE looks up Lifecycle (`core/LifecycleSetup.lua:13`), Media (`core/MediaSetup.lua:9`), Launcher
(`core/LauncherSetup.lua:11`), Env (`core/EnvSetup.lua:7`), Core (`core/CoreSetup.lua:19`),
DebugLog (`core/DebugLogSetup.lua:9`), Compat (`core/Compat.lua:11`), Options
(`settings/OptionsSetup.lua:11`), Schema (`settings/SchemaSetup.lua:187`) and Slash
(`settings/Slash.lua:57`), unchanged since v1.75.0. Of the majors that moved it consumes **Core**,
**DebugLog** and **Options**. **Widgets** is reached only inside the library (DebugLog's console and
copy window, the Options dropdowns), and **Perf** and **Sim** not at all (no host descriptor).

## 3f. Kit revision

```sh
grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua
# <scratch>/testkit/framework.lua:20:Kit.VERSION = 42
# tests/_kit/framework.lua:20:Kit.VERSION = 41
```

Kit 41 -> 42 (the binding mock, the frame-layer recorder, `Kit.assertBindingsXml` and
`Kit.keybindThroughTab`, all opt-in). The pairing rule (LibKa0s v1.9.0+ needs kit 11 or newer in the
same commit) holds by construction, since both payloads are copied whole together.

## 3g. Contract delta

The majors that moved and that PGFE looks up are Core (11 -> 12), DebugLog (key 21.3.1) and Options
(key 29.2.34.2.5.9.1.7.4.2.1 -> 30.2.34.3.5.9.2.8.4.2.1.3).

```sh
grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit
# (no output)
```

PGFE passes no `__Attach*` member, so no host-supplied member can be reached by a moved call site.
Core minor 12 adds `Core.RaiseStaticPopups()` and DebugLog 21 makes the console toplevel; neither
changes a surface PGFE supplies to (`CHANGELOG.md` at the tag, *Core minor 12, DebugLog minor 21,
PerfPanel minor 9 and SimPanel minor 6*: "What a consumer owes: nothing").

**Blockers: one.** The tag's *What a consumer owes* list (`CHANGELOG.md` v1.77.0 block, section
*What a consumer owes*) and the Options document
(`docs/api/Options/version-30.2.34.3.5.9.2.8.4.2.1.3-docs.md:1539-1541,1581,1994-1996` at the tag):
"Every Options degradation stub gains four instance members: `KeybindingsTab`, `KeybindRows`,
`KEYBINDS_UNCHANGED` and `StrataTooltip`. `Kit.assertSurfaceParity` is red at the re-vendor until the
stub answers them." PGFE's stub is `settings/OptionsSetup.lua:24-78`, asserted by
`tests/test_surface_parity.lua:31` ("parity: the Options helpers stub carries the whole live
surface"). Fixed in this commit: the stub gains the four members, inert (`KeybindingsTab` and
`KeybindRows` answer nil, as the live `KeybindRows` does when degraded; `StrataTooltip` answers an
empty string; `KEYBINDS_UNCHANGED` is the library's sentence). No decision is needed: the stub
exists only to absorb calls when the library is absent.

## 3h. Tags vendored and never recorded

The spec's 3h listing (horizon `2026-10-22`, the store's first bundle):

```text
vendored:   v1.75.0 v1.75.1 v1.75.2 v1.76.0
recorded:   v1.75.0 v1.75.1 v1.75.2 v1.76.0
unrecorded: (none)
```

Nothing to back-fill; no span bundle.

## 3i. The icon declaration

```sh
grep -n 'LibKa0s icons:' CLAUDE.md
# 51:LibKa0s icons: clear, close, copy.
```

Kept as it stands, directly under the provenance line (line 50); no split is needed. The set is the
debug console's title-bar `clear` and `copy` and the library-drawn `close`, unchanged since v1.75.0.
The tag's `docs/releasing.md` table under *Library-drawn icons are the host's to declare* is
unchanged in this range (`close`, `clear`, `copy`, `info`); PGFE wires no Options id list, so `info`
stays undeclared, and the new Keybindings tab draws no catalog icon. Hand lists have drifted before
(KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's
in-client smoke is the backstop, because a pruned icon still resolves to a path and draws blank.

## 3j. Tests that assume the whole icon folder

```sh
grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'
# (no output)
```

None. **Dead stub mirrors:** `grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs
--exclude-dir=_kit` prints nothing. **Harness list:** `tests/loader.lua` names the payload files
explicitly in XML order; v1.77.0 adds `OptionsKeybinds.lua` after `OptionsDrawer.lua`, so the list
gains that line in this commit (without it the harness's live Options instance would lack the
Keybindings members and the parity case would compare against an incomplete surface).

## After the copy

```sh
cp -r <scratch>/LibKa0s/. libs/LibKa0s/ && cp -r <scratch>/testkit/. tests/_kit/
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s   # empty (whole tag, before the prune)
diff -r                     <scratch>/LibKa0s libs/LibKa0s   # empty
diff -r                     <scratch>/testkit tests/_kit     # empty (bytes and content)
lua <scratch>/tools/prune-icons.lua .
# prune-icons: .: 3 icon(s) declared; kept 4 file(s), removed 5836
diff -rq <scratch>/LibKa0s libs/LibKa0s | grep -v '^Only in <scratch>.*media/icons'   # empty
diff -rq <scratch>/LibKa0s libs/LibKa0s | grep -c '^Only in <scratch>.*media/icons'  # 223
```

The whole tag landed (both diffs empty before the prune). The prune kept `clear`, `close`, `copy`
and `LICENSE-open-iconic.txt`, and removed the same 5,836 files the earlier prunes removed (the copy
brought them back first), so the committed icon folder is unchanged. The provenance line rolled to
v1.77.0 and the declaration under it is unchanged.

First gate, with the payload copied and nothing else changed: `lua tests/run.lua` 420 passed,
2 failed, 1 skipped, 423 total. The two reds are the two this file predicted:
`harness: the explicit LibKa0s list matches LibKa0s.xml, in XML order (anti-pattern #48)` (the
loader list lacked `OptionsKeybinds.lua`) and `parity: the Options helpers stub carries the whole
live surface` (the 3g blocker). Fixed in this commit, `tests/loader.lua` gaining
`libs/LibKa0s/OptionsKeybinds.lua` after `OptionsDrawer.lua` and `settings/OptionsSetup.lua`'s stub
gaining `KeybindingsTab`, `KeybindRows`, `KEYBINDS_UNCHANGED` and `StrataTooltip`. Re-run: 422
passed, 0 failed, 1 skipped, 423 total, `tests/test_vendor_sync.lua` green at v1.77.0. `luacheck .`
0 warnings / 0 errors in 60 files.
