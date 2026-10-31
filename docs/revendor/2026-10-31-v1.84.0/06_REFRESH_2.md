Refresh: LibKa0s v1.84.0 payload after the local tag moved again

# 06 - Refresh 2 (Ka0s Premade Groups Filter Extension)

Run: 2026-11-01, item M4-RV of the findings remediation (Ka0sAddonsCommonTasks
`docs/2026-10-31-FINDINGS_REMEDIATION/`), on branch `feat/2026-10-31-findings-remediation`. Files
01..05 and `06_REFRESH_1.md` of this bundle are frozen. This file records the later refresh and does
not edit them.

## Why

The owner ruled on 2026-11-01 that `lib.__PatchLSM30Border` goes, with no stub. The local, unpushed
tag `v1.84.0` in `../LibKa0s` was re-cut for that (`git ls-remote --tags origin v1.84.0` prints
nothing), so this is a refresh and takes no new bundle.

| `git -C ../LibKa0s rev-parse v1.84.0^{commit}` | Commit |
|---|---|
| Old | `7a8bc0f133ed118d2c79c7c5288b97964e24fae5` |
| New | `b5229b876e803768322fb4d8c66be69f01c8e4a1` |

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
| `libs/LibKa0s/Options.lua` | `LibKa0s-Options-1.0` minor **36 -> 37**: `lib.__PatchLSM30Border` deleted |
| `libs/LibKa0s/OptionsDrawer.lua` | `DRAWER_MINOR` **3 -> 4**: one comment |
| `libs/LibKa0s/OptionsMedia.lua` | `MEDIA_MINOR` **2 -> 3**: one comment |

`tests/_kit/` is unchanged: kit revision 47. The Options docs key moves to
37.4.41.2.6.1.7.13.2.3.16.10.4.4.6.5.5.1.1.3.

## Contract read

This addon never called the member. `git grep -nE 'PatchLSM|LSM30'` outside `libs/`, `tests/_kit/`
and `docs/revendor/` prints nothing, and so does a grep for the moved key, so no authored call, test,
stub surface or pin had to change. No blocker.

## Gates

| Gate | Result |
|---|---|
| `ka0s-bounded luacheck .` | 0 warnings / 0 errors in 69 files |
| `ka0s-bounded lua tests/run.lua` | 462 passed, 0 failed, 1 skipped, 463 total |
