Delta: LibKa0s v1.85.0 -> v1.89.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (item V89-PGFE). The tag is pushed (`git -C ../LibKa0s ls-remote --tags origin v1.89.0` prints `0bd4839`, the tag object; its commit is `df00e5f`). Payload taken with `git -C ../LibKa0s archive v1.89.0 LibKa0s testkit tools`, never the working tree.

## Base (3a, 3b)

- `grep -n '[Bb]undles' CLAUDE.md` -> `52: Bundles [LibKa0s](...) v1.85.0 (MIT).`
- `git log -1 --format=%h -- libs/LibKa0s tests/_kit` -> `63f3ed5`, whose `CLAUDE.md` line names v1.85.0. The two agree.
- `diff -rq` of both payloads against `git archive v1.85.0 LibKa0s testkit` shows only the undeclared icons (`Only in .../media/icons`), so the bytes are v1.85.0's: the minors match the line.
- Step 0 pre-flight (`inputs/step0-preflight.txt` of the run): `2026-11-01-v1.85.0  base v1.84.0  vendored-before v1.84.0@29ac441  ok`. No correction owed.

Range: `git -C ../LibKa0s log --oneline v1.85.0..v1.89.0` (26 commits, releases v1.86.0, v1.87.0, v1.88.0, v1.89.0).

## Per-file minors (3c), moved files only

`for f in <v1.89.0 LibKa0s.xml files>: grep 'local (MAJOR, )?[A-Z_]*MINOR = ...' old against tag`

| File | old | new |
|---|---|---|
| Toast.lua | 3 | 4 |
| Widgets.lua | 22 | 23 |
| DebugLogDiagnostics.lua | 6 | 7 |
| IconBrowserSources.lua | (new) | 1 |
| IconBrowserWindow.lua | (new) | 1 |
| IconBrowser.lua | (new) | 1 |

Every other file is at its v1.85.0 minor. No file is behind: no cross-major skew. No `NEEDS_*` floor rises.

## Diffs before the copy (3d)

`diff -rq --strip-trailing-cr <extract>/LibKa0s libs/LibKa0s` (icons filtered): `DebugLogDiagnostics.lua`, `LibKa0s.xml`, `Toast.lua`, `Widgets.lua` differ; `IconBrowser.lua`, `IconBrowserSources.lua`, `IconBrowserWindow.lua` only in the tag. `<extract>/testkit` against `tests/_kit`: `README.md`, `framework.lua`, `mock_ace.lua` differ. Nothing only in the addon: no file was removed upstream.

## Kit (3f)

`grep -n 'Kit.VERSION' framework.lua`: revision 50 -> 51. The two payloads move together, copied whole in one commit (the pairing rule).

## Consumption (3e)

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)'` outside `libs/` and `tests/`: Charts, Compat, Core, DebugLog, Env, Item, Launcher, Lifecycle, Media, Options, Perf, Pool, Schema, Sim, Skin, Slash, Widgets. Unchanged. No Toast and no IconBrowser lookup (`tests/loader.lua:24` loads `Toast.lua` only because the payload loads in XML order).

Of the moved majors, this addon consumes Widgets (`core/WidgetsSetup.lua`, `W.Dropdown` and `W.CloseMenu` only) and DebugLog (`core/DebugLogSetup.lua`).

## Contract delta (3g)

- **Widgets 22 -> 23** (`docs/api/Widgets/version-22.5.12.6.7.5-docs.md` against `version-23.5.12.6.7.5-docs.md`): `submenu`, `radio`, `selected` and `opts.check` are new `W.ContextMenu` row options, and "a dropdown's rows ignore all three, and every flat menu draws what minor 22 drew" (v1.87.0 CHANGELOG block). `CloseMenu()` now also closes every cascading level; with no cascade open it does what minor 22 did. This addon opens only flat `W.Dropdown` menus, so no member it hands over moved.
- **DebugLogDiagnostics 6 -> 7**: the report names IconBrowser among the majors; one report line, no host member.
- **Toast 3 -> 4**: the stub members `SetStack`, `Visible`, `FrameFor` are owed only by a host with a Toast stub; this addon has none (no lookup).
- **Kit 51**: `mock_ace.lua`'s unregister guard; "a consumer owes only the re-vendor".
- `grep -rn '__Attach[A-Za-z]*'` outside `libs/` and `_kit/`: no site.

## Blockers

One, found at the first gate after the copy rather than by the reads before it: `tests/loader.lua` keeps an explicit list of every `LibKa0s.xml` file in XML order (anti-pattern #48), and the harness case *the explicit LibKa0s list matches LibKa0s.xml, in XML order* went red (`LibKa0s file count (expected 67, got 64)`). Fixed in the re-vendor commit: `IconBrowserSources.lua`, `IconBrowserWindow.lua` and `IconBrowser.lua` join the list after `OptionsMedia.lua`, where the tag's `LibKa0s.xml:58-60` loads them. Not a contract change: the list loads files, it hands the library nothing.

Otherwise none. No 3g contract change reaches this addon; 3j below finds nothing; `grep -rn '__releaseChrome'` outside the payloads finds no dead mirror, and no `__` member was removed in the range.

## Unrecorded tags (3h)

The span walk (payload commits plus `CLAUDE.md` rolls since the store's horizon 2026-10-22) lists v1.75.0, v1.75.1, v1.75.2, v1.76.0, v1.77.0, v1.80.0 to v1.85.0; the bundles record every one. `grep -vxF -f recorded.txt vendored.txt` prints nothing: no span bundle.

## Icon declaration (3i)

`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 53, the next non-blank line after the provenance line. Kept as is: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` The range adds library-drawn names only for the icon browser (`search`, `close`), which this addon does not wire, so no fact forces a change. Decided by the run plan, not re-asked. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop for a name the host forgot.

## Whole-folder icon tests (3j)

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'`: nothing.
