# Summary: LibKa0s v1.75.2 -> v1.76.0 (Ka0s Premade Groups Filter Extension)

- **Tag:** v1.75.2 -> v1.76.0 (local annotated tag `546e284`, LibKa0s commit `9949368`, never
  checked out). Base from the `CLAUDE.md` provenance line, confirmed against the payload. Minors
  moved: Widgets 13 -> 14, SimTimeline 2 -> 3, SimPanel 4 -> 5; every other file unchanged, kit 41
  unchanged and byte-identical (`01_DELTA.md` 3c, 3f).
- **Branch:** `feat/2026-10-23-sim-preview-mode-strips`, cut from a clean `main`.
- **Span bundle:** `docs/revendor/2026-10-23-v1.75.1-v1.75.2/`, two tags (v1.75.1, v1.75.2) the
  post-run fix branches vendored without a bundle. No base correction: the v1.75.0 bundle's base
  (v1.71.0) matches the history.
- **Delivered free (class A):** `TestStrip` without a `kind` is unchanged; the release re-look is
  library docs only. Nothing PGFE draws changes on screen.
- **Contract blockers:** none. Neither moved major (Widgets, Sim) is looked up by PGFE, and PGFE
  passes no `__Attach*` members.
- **Icon line:** kept, `LibKa0s icons: clear, close, copy.`, directly under the provenance line.
  Prune: kept 4 files (3 icons plus `LICENSE-open-iconic.txt`), removed 5,836 the copy had brought
  back, so the committed icon folder is unchanged.
- **README credits:** unchanged (the shipped set is still the three Open Iconic icons). No dead stub
  mirror, no 3j test, no harness list change.
- **Adopted:** nothing. **Declined:** `TestStrip`'s sim flavor, Sim, a direct Widgets lookup
  (`03_DECISIONS.md`); no GitHub issue filed, per the item. **Unreached:** none.
- **Refresh file:** none.
- **Docs rippled:** the `CLAUDE.md` provenance line; the LibKa0s version in `docs/ARCHITECTURE.md`
  and `docs/module-map.md`, which still said v1.75.0 after the v1.75.1 and v1.75.2 re-vendors.
- **`/dev-copilot:wow-revendor-standards` against v2.87.0 (2026-10-23, read from the local
  `../WowAddonStandards` run branch):** a no-op. TOC `## X-Standard:` is the standard's URL, the
  README badge is the bare canonical image, and `CLAUDE.md`'s `## Standards compliance (read first)`
  keeps the stop-and-flag directive and the two-way classification. The command forbids a version
  stamp on the reference, so none is written. The `§N.M` sweep
  (`grep -rEn '§[0-9]+\.[0-9]' . --exclude-dir=.git --exclude-dir=libs --exclude-dir=_kit
  --exclude-dir=audits --exclude-dir=reviews --exclude-dir=automated-tests`) finds 0. Every
  `filename-§N` outside the frozen bundles resolves in range; the only unresolved forms,
  `bucket-or-§12` and `bucket-vs-§12`, are prose inside the frozen `docs/reviews/2026-10-09/`. The
  standard has no quirks catalog. `.gitattributes` is the canonical CRLF body with both carve-outs
  and the binaries; worktree stragglers: 1 (`docs/smoke-tests.md`, bare LF), repaired by re-checkout
  for the gate (no content change). No `docs/automated-tests/RESULTS.md` gate claim was swept.
- **Gates:** `luacheck .` 0 warnings / 0 errors in 60 files; `lua tests/run.lua` 422 passed,
  0 failed, 1 skipped, 423 total (`tests/test_vendor_sync.lua` green at v1.76.0); largest authored
  `.lua` file 1,215 lines (`tests/test_panel.lua`), under the 1,500 cap.
- **Owner smoke owed:** none new; PGFE's UI is unchanged by this release.

## Addendum: the tag moved (PG-RV2, 2026-10-23)

LibKa0s item LK-91 moved the local annotated tag `v1.76.0` from tag object `546e284` (commit
`9949368`) to tag object `2949c78` (commit `7e81ff7`), to bound the step-panel row labels before
the command column (the owner's BankLedger `/bl sim` overlap report). PG-RV2 re-vendored
`libs/LibKa0s/` and `tests/_kit/` whole from the moved tag (git archive into a scratch dir, tag
never checked out) and re-ran `tools/prune-icons.lua` against the unchanged declaration
`LibKa0s icons: clear, close, copy.` (kept 4 files, removed 5,836 the copy had brought back).

- **Files that changed:** `libs/LibKa0s/PerfPanel.lua` (minor 7 -> 8, Perf key 15.1.1.7 ->
  15.1.1.8) and `libs/LibKa0s/SimPanel.lua` (minor stays 5, already bumped in the unpublished
  v1.76.0). Every other payload file and the whole kit (still 41) are byte-identical.
- **Contract:** no blocker. PGFE loads both files only through `tests/loader.lua` and calls neither
  Sim nor the Perf panel; the change is row-label anchoring with no signature change. Adopted
  nothing new.
- **Verify:** before the prune both `diff -r` runs were empty; after it the only differences are
  the same 223 `Only in` lines under `media/icons/`.
- **Gates:** `luacheck .` 0 warnings / 0 errors in 60 files; `lua tests/run.lua` 422 passed,
  0 failed, 1 skipped (`tests/test_vendor_sync.lua` green against the moved tag); largest authored
  `.lua` file 1,215 lines.
- **Provenance line:** already `v1.76.0`; kept. No standard change.
