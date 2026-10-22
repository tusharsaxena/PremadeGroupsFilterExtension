Refresh: LibKa0s v1.75.0 payload after the local tag moved

# 06 — Refresh (Ka0s Premade Groups Filter Extension)

Run: 2026-10-23, item PG-RV2 of the cross-repo run "LibKa0s issues #45-#58", on branch
`feat/2026-10-22-libka0s-issues-45-58`. Files 01..05 of this bundle are frozen and describe the PG-RV
copy of the tag at `265a89e`. This file records the later refresh and does not edit them.

## Why

The local, unpushed annotated tag `v1.75.0` in `../LibKa0s` moved twice after PG-RV (OWNER_SCOPE B):
from commit **`265a89e`** to `6bf5f3e` (LK-26, `Sim minor 2: Start reads scenarios live; prepare gets
host opts`), then to **`9e5c4e2`** (LK-27, `SimPanel minor 2: the picker reads its scenario at use`,
plus its review follow-up). `9e5c4e2` is the tag's final position. The vendored payload had to follow
the tag so that `tests/test_vendor_sync.lua` stays green against it.

## What was done

The same procedure as PG-RV: `git -C ../LibKa0s archive v1.75.0 LibKa0s testkit` into scratch, the
payload copied over `libs/LibKa0s/` and `tests/_kit/`, then the tag's `tools/prune-icons.lua` against
the unchanged `LibKa0s icons: clear, close, copy.` line in `CLAUDE.md` (`3 icon(s) declared; kept
4 file(s), removed 5836`, the same result as PG-RV). After the prune, `diff -rq` of the pruned tag
payload against `libs/LibKa0s/` and of `testkit/` against `tests/_kit/` is empty. No file needed
deleting against the diff. The provenance line still reads v1.75.0 and was not edited.

## Files that changed

| File | Change |
|---|---|
| `libs/LibKa0s/Sim.lua` | `LibKa0s-Sim-1.0` minor **1 -> 2**: `Start` reads `scenarios.names`/`defs` live; `prepare` receives a shallow copy of the caller's start options |
| `libs/LibKa0s/SimTimeline.lua` | `TIMELINE_MINOR` **1 -> 2**: `Restart` carries the host's extra start fields through |
| `libs/LibKa0s/SimPanel.lua` | `SIM_PANEL_MINOR` **1 -> 2**: the scenario picker reads its scenario at use |

`tests/_kit/` is byte-identical to the moved tag (the kit revision stays 41). The Sim docs key moves
1.1.1 -> **2.2.2** (`docs/api/Sim/version-2.2.2-docs.md` in LibKa0s). No public member was added or
removed from a surface this addon consumes.

## Addon pins

PGFE's own tests and docs pin no Sim, SimTimeline or SimPanel minor and no Sim docs key (searched
outside `libs/`, `tests/_kit/` and the frozen bundles). `tests/loader.lua` lists the three files by
path only, and `docs/ARCHITECTURE.md` names Sim as vendored but not wired, so nothing else needed
updating. PGFE does not consume Sim-1.0.

## Gates

| Gate | Result |
|---|---|
| `luacheck .` | 0 warnings / 0 errors in 60 files |
| `lua tests/run.lua` | 422 passed, 0 failed, 1 skipped, 423 total; `test_vendor_sync` green against `9e5c4e2` |
| 1500-line cap | largest authored file `tests/test_panel.lua`, 1215 lines |
