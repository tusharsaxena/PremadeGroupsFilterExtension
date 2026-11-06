Delta: LibKa0s v1.89.0 -> v1.90.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (item SF1-RV-PGFE, from `SF1_SMOKE_FEEDBACK.md`). The tag is local and not pushed: `git -C ../LibKa0s ls-remote --tags origin v1.90.0` prints nothing, which is expected for this run and is not a refresh (the provenance named v1.89.0). Its commit is `4485b8f` (`git -C ../LibKa0s rev-parse v1.90.0^{commit}`). Payload taken with `git -C ../LibKa0s archive v1.90.0 LibKa0s testkit tools`, never the working tree.

## Base (3a, 3b)

- `grep -n '[Bb]undles' CLAUDE.md` -> `52: Bundles [LibKa0s](...) v1.89.0 (MIT).`
- `git log -1 --format=%h -- libs/LibKa0s tests/_kit` -> `c44ca60`, whose `CLAUDE.md` line names v1.89.0. The two agree.
- `diff -rq` of both payloads against `git archive v1.89.0 LibKa0s testkit` shows only the undeclared icons (`Only in <extract>/LibKa0s/media/icons`), so the bytes are v1.89.0's and the minors match the line.
- Step 0 for this addon: newest single-tag bundle `2026-11-06-v1.89.0`, base v1.85.0; the provenance before `c44ca60` was v1.85.0. `ok`, no correction owed.

Range: `git -C ../LibKa0s log --oneline v1.89.0..v1.90.0` (7 commits; the release is `SF1-L1`, `SF1-L2`, `SF1-L3`).

## Per-file minors (3c), moved files only

`for f in <v1.90.0 LibKa0s.xml files>: grep 'local (MAJOR, )?[A-Z_]*MINOR = ...' old against tag`

| File | old | new |
|---|---|---|
| Core.lua | 15 | 16 |
| Skin.lua | 16 | 17 |
| SkinPaint.lua | 18 | 19 |
| SkinPaintExtras.lua | 17 | 18 |
| Widgets.lua | 23 | 24 |
| WidgetsAutocomplete.lua | 7 | 8 |
| OptionsAppearance.lua | 6 | 7 |

Every other file is at its v1.89.0 minor. No new file, no file behind: no cross-major skew. No `NEEDS_*` floor rises (CHANGELOG v1.90.0, "Versions in this release").

## Diffs (3d)

Before the copy, content differs only in the seven files above and the undeclared icons. After `cp -r` of both payloads and before the prune: `diff -r --strip-trailing-cr` and `diff -r` are both empty for `LibKa0s` and for `testkit`. Nothing only in the addon: no file was removed upstream.

## Kit (3f)

`grep -n 'Kit.VERSION' framework.lua`: revision 51 on both sides. The two payloads are still copied whole in one commit (the pairing rule); `tests/_kit/` has no byte change.

## Consumption (3e)

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0"'` outside `libs/` and `tests/`: Compat, Core, DebugLog, Env, Launcher, Lifecycle, Media, Options, Schema, Skin (2 sites), Slash, Widgets. The moved majors Core, Skin, Widgets and Options are all consumed.

## Contract delta (3g)

Read: CHANGELOG v1.90.0 and the new documents `docs/api/Core/version-16-docs.md`, `docs/api/Widgets/version-24.5.12.6.8.5-docs.md`, `docs/api/Skin/version-17.1.27.8.19.18.17.4.9-docs.md`, `docs/api/Options/version-37.4.44.2.7.2.9.15.2.4.19.13.5.5.7.7.11.1.1.4-docs.md`, against their predecessors' *Superseded by* rows. Core 16's `__PixelSize`, `__WatchPixels`, `__OnPixelScale` and `__PixelBackdrop` are internal and no member manifest moves; Skin 17's `keepScope` is an optional `RegisterOwner` field; OptionsAppearance 7 changes `lib.__copySkinTo` only for a `keepScope` target. `docs/releasing.md` step 8 at the tag: "no member moves on the major, a facade or an instance". `grep -rn '__Attach' --include='*.lua'` outside the payloads finds nothing.

### Blockers

None. No host-supplied member changed call site or shape, and the gate after the copy is green with no stub or test change.

## Icons (3i, 3j)

`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 53, directly under the provenance line: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` Kept as decided by the run plan. The tag's `docs/releasing.md` library-drawn table adds no name in this range (`git -C ../LibKa0s diff v1.89.0 v1.90.0 -- docs/releasing.md`). Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'` prints nothing: no whole-catalog test. `grep -rn '__releaseChrome'` outside the payloads prints nothing: no dead stub mirror.

## Span check (3h)

The walk over `libs/LibKa0s`, `tests/_kit` and the `CLAUDE.md` rolls since the store's horizon (2026-10-22) lists v1.75.0 v1.75.1 v1.75.2 v1.76.0 v1.77.0 v1.80.0 v1.81.0 v1.82.0 v1.83.0 v1.84.0 v1.85.0 v1.89.0, every one recorded. No span bundle is owed.
