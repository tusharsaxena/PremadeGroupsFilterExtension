# Candidates: LibKa0s v1.71.0 -> v1.75.0 (Ka0s Premade Groups Filter Extension)

Sources: `git -C ../LibKa0s log --oneline v1.71.0..v1.75.0`, the v1.72.0 to v1.75.0 blocks of the
tag's `CHANGELOG.md`, and the tag's `docs/api/` documents for the majors whose minors moved. The run's
owner scope (`Ka0sAddonsCommonTasks/docs/2026-10-22-LIBKA0S_ISSUES_45_58/inputs/OWNER_SCOPE.md`)
pre-decides the adoptions, and PGFE is not an adopter of any of them, so nothing below is offered and
no interview runs.

The 3g blockers (the Options stub's `Drawer`, the dead `__releaseChrome` mirror and the harness's
LibKa0s list) are not candidates; they were fixed in the copy commit (`01_DELTA.md`).

## A. Reached the addon on the re-vendor alone (delivered)

| Change | Evidence | Why it is free |
|---|---|---|
| Options 29: a structural refresh of a page on screen keeps its scroll offset | LibKa0s `CHANGELOG.md:602-606` (v1.73.0) | Library-side; PGFE never scrolled back by hand. Owner smoke SM-PG-2 |
| Core 11, DebugLog 20, OptionsIdList 5, PerfPanel 7: comment corrections (#57) | `CHANGELOG.md`, v1.75.0 *Comment-only minors* | No member or behavior moves |
| DebugLogDiagnostics 3: the identity header names Glow and Sim | v1.75.0 *DebugLogDiagnostics minor 3* | A major absent from the client is skipped, so PGFE's report is unchanged |
| Kit 39: `__fireUnconditional` reaches method-name handlers | `CHANGELOG.md:693-700` | `tests/test_disabled.lua` step 6 stays green under it |
| Kit 41: a lizard crash is complexity `fail`, named in `crashedFiles` (LibKa0s#46, #47) | v1.75.0 *Test kit revision 41* | The runner does it; this is what PGFE#25 waited for |
| Kit 40: `vendor_sync.lua` holds `media/icons/` to the declaration | v1.75.0 *Test kit revision 40* | Wired through the existing `tests/test_vendor_sync.lua` |

## B. Host change required: none offered

| Surface | Evidence | Not adopted, because |
|---|---|---|
| `O.Drawer` (OptionsDrawer 1) | `docs/api/Options/version-29.2.34.2.5.9.1.7.4.2.1-docs.md:72` | Not an OWNER_SCOPE adopter: PGFE's settings pages have no collapsible detail to put in a drawer |
| `W.SearchBox` (Widgets 13) | v1.75.0 *Widgets minor 13: W.SearchBox* | Not an OWNER_SCOPE adopter: the attached panel deliberately keeps PGF's native `InputBoxTemplate` skin (`modules/Panel.lua:206,232,270,561`; `modules/EUISkin.lua:40,70`) |
| `W.TestStrip` (Widgets 13) | v1.75.0 *Widgets minor 13: W.TestStrip* | Not an OWNER_SCOPE adopter: PGFE has no Show window and no test mode |
| `Item.BonusIDsFromLink` (Item 3) | `docs/api/Item/version-3-docs.md` | Not an OWNER_SCOPE adopter: PGFE reads no item links |
| `Media.ICON_SETS`, `Media.IconAuthor` (Media 5) | v1.74.0 block | Not an OWNER_SCOPE adopter: PGFE has no icon browser and calls no catalog icon of its own |
| `Perf.Note(..., false)` (Perf 15) | v1.72.0 block | Perf is not wired: the performance-§12 exemption (`docs/ARCHITECTURE.md:446`) |
| `Kit.assertLatchHoldOrder` (kit 39) | `CHANGELOG.md:695-697` | Optional; the step-10 case in `tests/test_disabled.lua` already pins the latch order by hand |

## C. Whole-module adoption: none offered

| Major | Evidence | Not adopted, because |
|---|---|---|
| `LibKa0s-Glow-1.0` | `docs/api/Glow/version-1-docs.md` | Not an OWNER_SCOPE adopter (the adopters are DropWatcher, QuickComms, KickCD); PGFE draws no glows |
| `LibKa0s-Sim-1.0` | `docs/api/Sim/` at the tag | Not an OWNER_SCOPE adopter (DropWatcher, LootHistory, BankLedger); PGFE has no test mode and no simulator. The step panel is Sim-private (LK-11 outcome B) |
| Bus, Pool, Item, Widgets, Perf | `docs/ARCHITECTURE.md:67-72` | Settled earlier: vendored and not wired; Perf under the performance-§12 exemption. No premise moved in this range |
