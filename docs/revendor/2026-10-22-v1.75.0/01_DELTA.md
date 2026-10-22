Delta: LibKa0s v1.71.0 -> v1.75.0

# LibKa0s v1.71.0 -> v1.75.0: the delta (Ka0s Premade Groups Filter Extension)

Item PG-RV of the 2026-10-22 "LibKa0s issues #45-#58" run: a mechanical re-vendor through the
installed `/dev-copilot:wow-revendor-libka0s` at 2.4.0, with no adoption interview and no GitHub
issue filed (the run's owner scope; M2 is non-interactive and PGFE has no M3 adoption). Copied from
the annotated tag `v1.75.0` (tag object `eae0ee5`, LibKa0s commit `265a89e`) by
`git -C ../LibKa0s archive v1.75.0 LibKa0s testkit tools | tar -x` into a scratch directory, then
`libs/LibKa0s/` and `tests/_kit/` replaced whole. The tag is **local only**
(`git -C ../LibKa0s ls-remote --tags origin v1.75.0` prints nothing); the payload comes from the
tag, never the working tree. `tools/` was extracted only for `prune-icons.lua` and is not copied.

This file was written before the copy. *After the copy*, at the end, was added once the copy and
the prune had run.

## Precondition: the default branch and the unpushed owner commit

PGFE's default branch is **`main`**, not `master` (`git symbolic-ref --short
refs/remotes/origin/HEAD` prints `origin/main`). At the start of this item `main` was one commit
ahead of `origin/main` (`git status -sb`: `## main...origin/main [ahead 1]`), carrying the owner's
unpushed `8e9b5ee Keep the selected preset across reloads and logins`. That commit is owner work and
was not rebased, dropped or pushed. The run branch `feat/2026-10-22-libka0s-issues-45-58` was cut
from local `main`, so it carries `8e9b5ee` and that commit rides the run branch to its merge.

## Step 0. Pre-flight (this addon)

```sh
ls docs/revendor
# ls: cannot access 'docs/revendor': No such file or directory
```

No store yet, so there is no newest bundle to check and no correction paragraph is owed.

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 49:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.71.0 (MIT).
git log -1 --format='%h %s' -- libs/LibKa0s tests/_kit
# 5939cc7 Scaffold addon to the Ka0s standard with stub modules
git -C ../LibKa0s archive v1.71.0 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq <scratch>/claimed/LibKa0s libs/LibKa0s && diff -rq <scratch>/claimed/testkit tests/_kit \
  && echo payload-matches
# payload-matches
```

The scaffold commit vendored v1.71.0 and the line has named it since; the payload today is the
library's payload at v1.71.0 (`3bf1b97`), kit revision 38. The base is **v1.71.0**. PGFE never
vendored v1.72.0, v1.73.0 or v1.74.0; the range below covers them.

```sh
git -C ../LibKa0s log --oneline v1.71.0..v1.75.0 | wc -l
# 56
git -C ../LibKa0s diff --stat v1.71.0 v1.75.0 | tail -1
# 5863 files changed, 81438 insertions(+), 410 deletions(-)
```

Most of the file count is the icon catalog that arrived at v1.74.0 (Media minor 5, MediaIcons
minor 1), which the prune below removes again apart from three icons.

## 3b. Actual version

The minors in `libs/LibKa0s/*.lua` (the `old:` column below) are every file's v1.71.0 minor, so the
claim and the bytes agree.

## 3c. Per-file minor delta

```sh
for f in $(git -C ../LibKa0s show v1.75.0:LibKa0s/LibKa0s.xml | grep -oE 'file="[^"]+\.lua"' | cut -d'"' -f2); do
  printf '%s  old: %s  new: %s\n' "$f" "$(grep -hoE '...MINOR...' libs/LibKa0s/"$f")" \
    "$(git -C ../LibKa0s show v1.75.0:LibKa0s/"$f" | grep -hoE '...MINOR...')"
done
```

| File | v1.71.0 | v1.75.0 | Range |
|---|---|---|---|
| `Core.lua` | 10 | **11** | v1.75.0 (comment-only, #57) |
| `Env.lua` | 2 | 2 | |
| `Compat.lua` | 1 | 1 | |
| `Lifecycle.lua` | 3 | 3 | |
| `Bus.lua` | 2 | 2 | |
| `Schema.lua` | 2 | 2 | |
| `Pool.lua` | 3 | 3 | |
| `Item.lua` | 2 | **3** | v1.75.0 (`Item.BonusIDsFromLink`) |
| `Glow.lua` | (new) | **1** | v1.75.0 (new major `LibKa0s-Glow-1.0`) |
| `Media.lua` | 4 | **5** | v1.74.0 (`ICON_SETS`, `IconAuthor`) |
| `MediaIcons.lua` | (new) | **1** | v1.74.0 (the 5,836-name catalog) |
| `Widgets.lua` | 12 | **13** | v1.75.0 (`W.SearchBox`, `W.TestStrip`) |
| `WidgetsReorder.lua` | 1 | 1 | |
| `WidgetsDragHandle.lua` | 4 | 4 | |
| `WidgetsLineChart.lua` | 3 | 3 | |
| `WidgetsAutocomplete.lua` | 2 | 2 | |
| `DebugLog.lua` | 19 | **20** | v1.75.0 (comment-only, #57) |
| `DebugLogDiagnostics.lua` | 2 | **3** | v1.75.0 (header names Glow and Sim) |
| `DebugLogGates.lua` | 1 | 1 | |
| `Slash.lua` | 20 | 20 | |
| `SlashParse.lua` | 2 | 2 | |
| `Launcher.lua` | 5 | 5 | |
| `Options.lua` | 28 | **29** | v1.73.0 (structural refresh keeps the scroll offset) |
| `OptionsRegistry.lua` | 2 | 2 | |
| `OptionsWidgets.lua` | 34 | 34 | |
| `OptionsIds.lua` | 2 | 2 | |
| `OptionsIdList.lua` | 4 | **5** | v1.75.0 (comment-only, #57) |
| `OptionsTabs.lua` | 8 | **9** | v1.75.0 (`O.__releaseChrome` no longer exported, #45) |
| `OptionsCombat.lua` | 1 | 1 | |
| `OptionsCompose.lua` | 7 | 7 | |
| `OptionsScroll.lua` | 4 | 4 | |
| `OptionsNav.lua` | 2 | 2 | |
| `OptionsDrawer.lua` | (new) | **1** | v1.73.0 (`O.Drawer`) |
| `Perf.lua` | 14 | **15** | v1.72.0 (`Perf.Note` at top level) |
| `PerfSampler.lua` | 1 | 1 | |
| `PerfCommands.lua` | 1 | 1 | |
| `PerfPanel.lua` | 6 | **7** | v1.75.0 (comment-only) |
| `Sim.lua` | (new) | **1** | v1.75.0 (new major `LibKa0s-Sim-1.0`) |
| `SimTimeline.lua` | (new) | **1** | v1.75.0 |
| `SimPanel.lua` | (new) | **1** | v1.75.0 (the step panel, Sim-private) |

No file goes backwards, so there is no cross-major skew. `WidgetsStepPanel.lua` is **not** in the
tag's `LibKa0s.xml`: LK-11 came out at outcome B, so `W.StepPanel` is not public and the step-panel
renderer is Sim-private inside `SimPanel.lua`.

## 3d. Both diffs

Recorded under *After the copy*.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

| Major | Lookup site |
|---|---|
| Core | `core/CoreSetup.lua:19` |
| Media | `core/MediaSetup.lua:8` |
| Compat | `core/Compat.lua:11` |
| Env | `core/EnvSetup.lua:7` |
| DebugLog | `core/DebugLogSetup.lua:9` |
| Launcher | `core/LauncherSetup.lua:11` |
| Lifecycle | `core/LifecycleSetup.lua:13` |
| Schema | `settings/SchemaSetup.lua:187` |
| Options | `settings/OptionsSetup.lua:11` |
| Slash | `settings/Slash.lua:57` |

Vendored and not wired: Bus, Pool, Item, Widgets, Perf (the performance-§12 exemption,
`docs/ARCHITECTURE.md` `## Documented deviations`), and from this range Glow and Sim.

## 3f. Kit revision, and the pairing rule

```sh
grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua
# <scratch>/testkit/framework.lua:20:Kit.VERSION = 41
# tests/_kit/framework.lua:20:Kit.VERSION = 38
```

Kit 38 -> 41. Both payloads move together in one commit; the pairing rule (v1.9.0+ needs kit 11 or
newer) is satisfied by construction.

## 3g. Contract delta: adoption blockers

```sh
grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit
# (no output)
```

PGFE hands the library no `__Attach*` members, so no host-supplied member's call site can have
moved. The blockers below come from the consumed majors whose minors moved (Core, Media, DebugLog,
Options) and from the kit.

### Blockers

- **(a) Options stub parity, `Drawer`** (Options minor 29 / OptionsDrawer 1, v1.73.0). The tag's
  `docs/api/Options/version-29.2.34.2.5.9.1.7.4.2.1-docs.md:72` (*A drawer (D1 and O29)*) adds
  `O.Drawer`; LibKa0s `CHANGELOG.md:602-608` (v1.73.0 *What a consumer owes*): "An Options
  degradation stub pinned with `Kit.assertSurfaceParity` by name goes red until it gains `Drawer`
  as a no-op". `tests/test_surface_parity.lua:33` pins `LibKa0s-Options-1.0` against the stub in
  `settings/OptionsSetup.lua`. Fix in the copy commit: `H.Drawer = function() end` in the
  library-absent branch, after `H.ChoiceGrid` (the QuickComms `settings/OptionsSetup.lua:77` shape).
- **(b) The dead `__releaseChrome` mirror** (OptionsTabs minor 9, #45). The same API document,
  `:43` and `:60`: `O.__releaseChrome` is no longer exported. `settings/OptionsSetup.lua:49`
  (`H.__releaseChrome = function() end`) mirrors it. `Kit.assertSurfaceParity` walks the live
  surface, so the stale member turns nothing red; it is dead weight, removed in the copy commit
  (the KickCD M4-09 precedent).
- **(c) Kit 39 `__fireUnconditional` reaches method-name handlers** (LibKa0s `CHANGELOG.md:693-
  700`, v1.72.0). The only caller is `tests/test_disabled.lua:157,160`, which already calls each
  `NS.FEATURE_EVENTS` handler directly (`:158`) and asserts no SV write, nothing said and nothing
  shown. Expected green; if red, the addon's stand-down guard is the fix, never the test.
- **(d) Options 29 keeps a page's scroll offset across a structural refresh** (v1.73.0). No host
  change: PGFE never scrolls a page back to the top by hand. The owner's smoke SM-PG-2 checks it.
- **(e) Kit 40/41 `Kit.__deviationRows` / `Kit.__declineFor` withdrawn.**
  `grep -rn '__deviationRows\|__declineFor' tests --include='*.lua' | grep -v _kit` prints nothing;
  nothing to delete.

The comment-only minors (Core 11, DebugLog 20, OptionsIdList 5, PerfPanel 7) change no contract.
They do correct one claim this addon relied on: a library-drawn icon a host did not declare draws
**blank**, not the text fallback. That is why the declaration below names every library-drawn icon
PGFE wires.

## 3h. Tags vendored and never recorded

No `docs/revendor/` store exists, so there is no horizon and no span bundle. The store is measured
from this bundle on.

## 3i. The icon declaration (decided by the run's item spec)

```sh
grep -n 'LibKa0s icons:' CLAUDE.md
# (no output)
```

CLAUDE.md:49 is a standalone provenance sentence (the next non-blank line is end of file), so no
split is needed. The line is pre-decided by the run's item PG-RV and is recorded here as decided:

```
LibKa0s icons: clear, close, copy.
```

Evidence for every name, every draw site checked:

| Name | Drawn by | Evidence |
|---|---|---|
| `close` | `Core.MakeCloseButton` given the addon name | `core/CoreSetup.lua:87-88` wraps `lib.MakeCloseButton(parent, onClick, addonName)`; `libs/LibKa0s/Core.lua:241-242` resolves `media.Icon(addonName, "close")`. The DebugLog console and its copy window close through it (`core/DebugLogSetup.lua:85` passes `addonName`). |
| `clear` | the DebugLog console's title bar | `libs/LibKa0s/DebugLog.lua:292` `makeIconButton(titleBar, spec.addonName, "clear", ...)` |
| `copy` | the DebugLog console's title bar | `libs/LibKa0s/DebugLog.lua:293` `makeIconButton(titleBar, spec.addonName, "copy", ...)` |

Not declared, each checked:

- `info` (the Options id list's help mark): PGFE never calls `H.IdList` live;
  `settings/OptionsSetup.lua:60` is the library-absent stub only. It hosts no `W.TestStrip`.
- `PerfPanel`'s close: no perf harness is wired (`docs/ARCHITECTURE.md:446`, the performance-§12
  exemption; `settings/Slash.lua:8`).
- The Widgets copy window's close: Widgets is not wired (`docs/ARCHITECTURE.md:67-72`).
- The Sim step panel's close: Sim is not wired.
- The host seam `NS.Icon` (`core/MediaSetup.lua:13-16`) has no caller in `core/`, `settings/`,
  `modules/` or `defaults/` (`grep -rn 'NS.Icon' core settings modules defaults` hits only its own
  definition), and no icon data table or constant feeds it. The addon's own art is
  `media/logos/*` (`core/LauncherSetup.lua:14`, `settings/Panel.lua:21`), outside the library.

Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup
`tests/test_mediasetup.lua:19`). The gate cannot see a name the host forgot to declare, because a
pruned icon still resolves to a path and draws blank; the owner's in-client smoke DIAG-3 (SM-PG-1)
is the backstop.

## 3j. Tests that assume the whole icon folder

```sh
grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'
# (no output)
```

None; nothing to rewrite.

## After the copy

### 3d. Both diffs, before the prune

```sh
cp -r <scratch>/LibKa0s/. libs/LibKa0s/ && cp -r <scratch>/testkit/. tests/_kit/
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s   # (no output)
diff -rq                    <scratch>/LibKa0s libs/LibKa0s   # (no output)
diff -r --strip-trailing-cr <scratch>/testkit tests/_kit     # (no output)
diff -rq                    <scratch>/testkit tests/_kit     # (no output)
```

All four empty: the whole tag landed, content and bytes, with no `Only in libs/LibKa0s` line, so no
file needed deleting. `tests/_kit/framework.lua:20` is now `Kit.VERSION = 41`.

### The prune

```sh
lua <scratch>/tools/prune-icons.lua .
# prune-icons: .: 3 icon(s) declared; kept 4 file(s), removed 5836
```

`libs/LibKa0s/media/icons/` keeps exactly `clear.tga`, `close.tga`, `copy.tga` and
`LICENSE-open-iconic.txt`. Removed by set: Open Iconic 221 icons; Phosphor 1,434 icons plus
`LICENSE-phosphor.txt` (the `phosphor/` folder is gone); Game-icons 4,178 icons plus
`LICENSE-game-icons.txt` and `AUTHORS.txt` (the `game-icons/` folder is gone).

### One more blocker found by the gate: the harness's explicit LibKa0s list

The first gate after the copy failed one case: `harness: the explicit LibKa0s list matches
LibKa0s.xml, in XML order (anti-pattern #48)` (`tests/test_harness.lua:74`), `LibKa0s file count
(expected 40, got 34)`. `tests/loader.lua`'s `LIBKA0S` list restates the XML so the headless loader
pulls every library file in order. It gains the six files the range added, at their XML positions:
`Glow.lua` after `Item.lua`, `MediaIcons.lua` after `Media.lua`, `OptionsDrawer.lua` after
`OptionsNav.lua`, and `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua` after `PerfPanel.lua`. Fixed in
the copy commit, as 3g requires. The item spec expected no source change beyond the two stub lines;
this one is the anti-pattern #48 ripple every new payload file brings.

### Gate

```sh
~/.claude/dev-copilot/bin/ka0s-bounded luacheck .
# Total: 0 warnings / 0 errors in 60 files
~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua
# 422 passed, 0 failed, 1 skipped, 423 total
~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle
# complexity  pass  — 0 warnings (fun rate 0.00), 8895 NLOC / 1305 funcs, ... avg CCN 2.0 (max 14)
```

`luacheck`'s `exclude_files` (`.luacheckrc:11`) leaves out `libs/` and `tests/_kit/`; both seams this
commit touches (`settings/OptionsSetup.lua`, `tests/loader.lua`) are inside the checked set.
`tests/test_vendor_sync.lua` resolves tag v1.75.0 from the provenance line and holds the copy to the
declaration (`libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles` and
`tests/_kit is the test kit that shipped with that release`, both PASS). Complexity under kit 41:
pass, no crash note, so no file is crashed or blind, and no function is above CCN 15 (#25's last
bullet). The largest authored `.lua` file is `tests/test_panel.lua` at 1,215 lines, under the
1,500-line cap.
