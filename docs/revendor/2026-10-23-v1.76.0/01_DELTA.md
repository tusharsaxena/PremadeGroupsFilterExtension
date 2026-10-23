Delta: LibKa0s v1.75.2 -> v1.76.0

# LibKa0s v1.75.2 -> v1.76.0: the delta (Ka0s Premade Groups Filter Extension)

Item PG-RV of the 2026-10-23 "sim auto-run, QC preview selector, mode strips, MM/KCD simulators" run
(Ka0sAddonsCommonTasks `docs/2026-10-23-SIM_PREVIEW_MODE_STRIPS/`). A mechanical re-vendor through
the installed `/dev-copilot:wow-revendor-libka0s` at 2.4.0: no adoption interview and no GitHub issue,
because the run's item spec pre-decides that (PGFE adopts nothing from this release). Copied from the
annotated tag `v1.76.0` (tag object `546e284`, LibKa0s commit `9949368`) with
`git -C ../LibKa0s archive v1.76.0 LibKa0s testkit tools | tar -x` into a scratch directory, then
`libs/LibKa0s/` and `tests/_kit/` replaced whole. The tag is **local only**
(`git -C ../LibKa0s ls-remote --tags origin v1.76.0` prints nothing), and the tag was never checked
out. `tools/` was extracted only for `prune-icons.lua` and is not copied.

This file was written before the copy. The *After the copy* section at the end was added once the
copy and the prune had run.

## Step 0. Pre-flight (this addon)

```sh
head -1 docs/revendor/2026-10-22-v1.75.0/01_DELTA.md
# Delta: LibKa0s v1.71.0 -> v1.75.0
# the re-vendor commit that rolled the line to v1.75.0, and the line at its parent:
# f71ef3c (PG-RV: Re-vendor LibKa0s v1.75.0 (kit 41), icons clear, close, copy), parent at v1.71.0
```

The newest single-tag bundle states base v1.71.0, and the history agrees. No correction is owed.

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 50:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.75.2 (MIT).
c=$(git log -1 --format=%H -- libs/LibKa0s tests/_kit)            # 3e12554 Re-vendor LibKa0s v1.75.2 (SimPanel minor 4)
git show "$c:CLAUDE.md" | grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9]+\.[0-9]+\.[0-9]+'
# Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.75.2
git -C ../LibKa0s archive v1.75.2 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq <scratch>/claimed/LibKa0s libs/LibKa0s   # only "Only in <scratch>/claimed/LibKa0s/media/icons" lines (223: the 221 undeclared Open Iconic icons and the `phosphor/` and `game-icons/` folders)
diff -rq <scratch>/claimed/testkit tests/_kit     # empty
```

The line and the last payload commit agree, and the payload is the v1.75.2 payload apart from the
icons the declaration prunes. **Base: v1.75.2.**

```sh
git -C ../LibKa0s log --oneline v1.75.2..v1.76.0
# 9949368 LK-90: address review — name tests/test_sim_panel.lua in the CLAUDE.md 1000-1500 band
# 82d76f6 LK-90: close v1.76.0 with its release record (20261023-150627)
# f9ce82a LK-90 (1/2): release v1.76.0: version block, pointers, consumers
# 37e6b69 LK-25: add the preview and simulation re-look to the release checklist
# d5fa6e9 LK-10: give W.TestStrip a simulation flavor (Widgets minor 14)
# d728cc4 LK-01: play a simulation on its own and drop Run all (Sim 2.3.5)
# 05cb400 LK-00: open v1.76.0 with an unreleased CHANGELOG block
# 99fb662 Merge branch 'fix/2026-10-23-sim-picker-step-delay' (LibKa0s v1.75.2: SimPanel minor 4)
git -C ../LibKa0s diff --stat v1.75.2 v1.76.0 -- LibKa0s testkit
#  LibKa0s/SimPanel.lua    |  36 ++++++++------
#  LibKa0s/SimTimeline.lua | 122 +++++++++++++++++++++++++++++++++++++-----------
#  LibKa0s/Widgets.lua     |  43 ++++++++++++-----
#  3 files changed, 148 insertions(+), 53 deletions(-)
```

## 3b. Actual version

```sh
grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua
```

Every vendored minor equals the v1.75.2 tag's (3c's `old:` column). Claim and bytes agree.

## 3c. Per-file minor delta

The loop over the tag's `LibKa0s/LibKa0s.xml` (the spec's 3c command). Three files moved; the other
37 are unchanged, and no file is new or went backwards.

| File | v1.75.2 | v1.76.0 |
|---|---|---|
| `Widgets.lua` | `MINOR` 13 | `MINOR` 14 |
| `SimTimeline.lua` | `TIMELINE_MINOR` 2 | `TIMELINE_MINOR` 3 |
| `SimPanel.lua` | `SIM_PANEL_MINOR` 4 | `SIM_PANEL_MINOR` 5 |

No cross-major skew.

## 3d. Both diffs (before the copy)

```sh
diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -v 'Only in .*media/icons'
diff -rq                     <scratch>/LibKa0s libs/LibKa0s | grep -v 'media/icons'
# both: SimPanel.lua, SimTimeline.lua, Widgets.lua differ
diff -rq <scratch>/testkit tests/_kit                  # empty (bytes)
diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit   # empty (content)
```

Content and bytes give the same three files, so there is no line-ending disagreement; the copy is
the fix. 223 `Only in <scratch>/LibKa0s/media/icons` lines (221 Open Iconic icons plus the `phosphor/` and
`game-icons/` folders) are the icons PGFE does not declare (the
declaration working, not drift). No `Only in libs/LibKa0s` line: nothing was removed upstream.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

PGFE looks up Lifecycle (`core/LifecycleSetup.lua:13`), Media (`core/MediaSetup.lua:9`), Launcher
(`core/LauncherSetup.lua:11`), Env (`core/EnvSetup.lua:7`), DebugLog (`core/DebugLogSetup.lua:9`),
Core (`core/CoreSetup.lua:19`), Compat (`core/Compat.lua:11`), Options
(`settings/OptionsSetup.lua:11`), Schema (`settings/SchemaSetup.lua:187`) and Slash
(`settings/Slash.lua:57`), unchanged since v1.75.0. It looks up neither of the two majors that
moved: **Widgets** is reached only inside the library (DebugLog's console and copy window), and
**Sim** not at all (no host descriptor, so the vendored Sim files load inert).

## 3f. Kit revision

```sh
grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua
# both: Kit.VERSION = 41
```

Kit 41 on both sides; the kit is byte-identical. The pairing rule (LibKa0s v1.9.0+ needs kit 11 or
newer in the same commit) holds by construction, since both payloads are copied whole together.

## 3g. Contract delta

The majors that moved a minor (Widgets, Sim) intersected with the majors PGFE looks up is empty, so
no host-supplied member can be reached by a moved call site:

```sh
grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit
# (no output)
```

Read anyway, for the library-internal path: `W.TestStrip` without a `kind` is unchanged
(`docs/api/Widgets/version-14.1.4.3.2-docs.md:27-37`), and the Sim auto-run binds only the verb
layer of a Sim host (`docs/api/Sim/version-2.3.5-docs.md:347`). The v1.76.0 *What a consumer owes*
list (`CHANGELOG.md:84-102` at the tag) asks a host to re-true Sim suites, reword Run all prose and
check for a `RUN_ALL` override; PGFE has no Sim suite and no Run all prose, and
`grep -rn 'RUN_ALL' locales modules` prints nothing.

**Blockers: none.**

## 3h. Tags vendored and never recorded

The spec's 3h listing (horizon `2026-10-22`, the store's first bundle):

```text
vendored:   v1.75.0 v1.75.1 v1.75.2
recorded:   v1.75.0
unrecorded: v1.75.1 v1.75.2
```

v1.75.1 (`0740b82 Re-vendor LibKa0s v1.75.1 (SimPanel minor 3)`) and v1.75.2
(`3e12554 Re-vendor LibKa0s v1.75.2 (SimPanel minor 4)`) were carried by the post-run fix branches
without a bundle. They are recorded in the consolidated span bundle
`docs/revendor/2026-10-23-v1.75.1-v1.75.2/`, written in this commit.

## 3i. The icon declaration

```sh
grep -n 'LibKa0s icons:' CLAUDE.md
# 51:LibKa0s icons: clear, close, copy.
```

Kept as it stands, directly under the provenance line (line 50); no split is needed. The set is the
debug console's title-bar `clear` and `copy` and the library-drawn `close`, unchanged since v1.75.0.
v1.76.0 adds no library-drawn name for a surface PGFE wires (the strip's `info` mark is a host call,
and PGFE builds no strip). Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`,
WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop, because a
pruned icon still resolves to a path and draws blank.

## 3j. Tests that assume the whole icon folder

```sh
grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'
# (no output)
```

None. **Dead stub mirrors:** `grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs
--exclude-dir=_kit` prints nothing (removed at v1.75.0). **Harness list:** `tests/loader.lua` names
the payload files explicitly; v1.76.0 adds no file, so it needs no change.

## After the copy

```sh
cp -r <scratch>/LibKa0s/. libs/LibKa0s/ && cp -r <scratch>/testkit/. tests/_kit/
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s   # empty (whole tag, before the prune)
diff -r                     <scratch>/LibKa0s libs/LibKa0s   # empty
diff -r                     <scratch>/testkit tests/_kit     # empty
lua <scratch>/tools/prune-icons.lua .
# prune-icons: .: 3 icon(s) declared; kept 4 file(s), removed 5836
diff -rq <scratch>/LibKa0s libs/LibKa0s | grep -v '^Only in <scratch>.*media/icons'   # empty
diff -rq <scratch>/LibKa0s libs/LibKa0s | grep -c '^Only in <scratch>.*media/icons'  # 223
```

The whole tag landed (both diffs empty before the prune). The prune kept `clear`, `close`, `copy`
and `LICENSE-open-iconic.txt`, and removed the same 5,836 files the v1.75.0 prune removed (the copy
brought them back first). After the prune the only differences are the same 223 `Only in` lines
(221 undeclared Open Iconic icons, the `phosphor/` and `game-icons/` folders); `git status`
shows the payload change as exactly `SimPanel.lua`, `SimTimeline.lua` and `Widgets.lua`, so the
icon folder in the commit is unchanged. The provenance line rolled to v1.76.0 and the declaration
under it is unchanged.

Gate: `luacheck .` 0 warnings / 0 errors in 60 files. `lua tests/run.lua` first ran 421 passed,
1 failed: the kit's eol case named `docs/smoke-tests.md` ("declared crlf, but 314 of 314 terminators
are bare LF"), a working-tree straggler this re-vendor did not touch (`git diff` empty for that
file). Repaired as the case says, `rm docs/smoke-tests.md && git checkout -- docs/smoke-tests.md`
(314 CR, 314 LF afterwards), with no content change and nothing to commit. Re-run: 422 passed,
0 failed, 1 skipped, 423 total, `tests/test_vendor_sync.lua` green at v1.76.0.
