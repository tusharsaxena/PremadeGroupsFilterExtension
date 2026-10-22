# Summary: LibKa0s v1.71.0 -> v1.75.0 (Ka0s Premade Groups Filter Extension)

- **Tag:** v1.71.0 -> v1.75.0 (local annotated tag, LibKa0s commit `265a89e`), base taken from the
  `CLAUDE.md` provenance line and confirmed against the payload (`payload-matches`). Kit revision
  38 -> 41. The per-file minor table is in `01_DELTA.md` 3c; no file went backwards.
- **Branch:** `feat/2026-10-22-libka0s-issues-45-58`, cut from local `main`, which carries the
  owner's unpushed `8e9b5ee Keep the selected preset across reloads and logins`. That commit rides
  the run branch; it was not rebased, dropped or pushed.
- **Span bundle:** none. This is the store's first bundle, so there is no horizon and no base
  correction.
- **Delivered free (class A):** Options 29's kept scroll offset, the #57 comment corrections, the
  diagnostics header's Glow and Sim entries, kit 39's `__fireUnconditional` reach, kit 40's icon
  gate and kit 41's crashed-lizard bucket (LibKa0s#46, #47, which PGFE#25 waited for).
- **Contract blockers, all fixed in the copy commit:** `H.Drawer` added to the Options
  library-absent stub (surface parity, Options 29 / OptionsDrawer 1); the dead
  `H.__releaseChrome` mirror removed (OptionsTabs 9, LibKa0s#45); `tests/loader.lua`'s explicit
  LibKa0s list gained the six new payload files (anti-pattern #48, caught by
  `tests/test_harness.lua:74`). Kit 39's `__fireUnconditional` change and Options 29's scroll offset
  needed no code. No `__deviationRows` / `__declineFor` references existed.
- **Icon line:** written, `LibKa0s icons: clear, close, copy.`, directly under the provenance line
  (no split needed). Prune: kept 3 icons plus `LICENSE-open-iconic.txt`; removed 5,836 files
  (Open Iconic 221; Phosphor 1,434 plus its license; Game-icons 4,178 plus its license and authors
  list).
- **README credits:** the Open Iconic sentence now names the three buttons, the author (Waybury),
  the MIT license and the link. No Phosphor or Game-icons credit is owed (neither set ships), and no
  library credit (anti-pattern #58). JetBrains Mono and PGF/PremadeRegions credits are unchanged.
- **Dead stub mirrors removed:** `H.__releaseChrome` in `settings/OptionsSetup.lua`.
- **Adopted:** nothing (no OWNER_SCOPE adoption for PGFE). **Declined:** every new surface, recorded
  in `03_DECISIONS.md`; no GitHub issue filed (M2 is non-interactive). **Unreached:** none.
- **Refresh file:** none.
- **Docs rippled:** `CLAUDE.md` compliance paragraph (#25 landed), `docs/ARCHITECTURE.md` (version,
  Glow and Sim in the not-wired list, the performance-§12 row's "vendored whole apart from
  `media/icons`"), `docs/module-map.md`, `docs/testing.md` complexity row, `DEPENDENCIES.md` lizard
  row, the `core/MediaSetup.lua` header comment, and `docs/smoke-tests.md` (DIAG-3 *Console icons*,
  Result empty; Index DIAG-1..3). `docs/test-cases.md` regenerated with no change and the README
  Tests badge stays 422/422, because the case count did not move.
- **`/dev-copilot:wow-revendor-standards`:** a no-op here. The TOC's `X-Standard` is the bare URL,
  and neither the README badge nor `CLAUDE.md` carries a standard version.
- **Gates:** `luacheck .` 0 warnings / 0 errors in 60 files; `lua tests/run.lua` 422 passed,
  0 failed, 1 skipped, 423 total (`tests/test_vendor_sync.lua` green at v1.75.0 with the
  declaration enforced); complexity suite pass, no crash note, max CCN 14, so nothing above CCN 15;
  largest authored `.lua` file 1,215 lines, under the cap.
- **Owner smoke owed:** DIAG-3 (console icons), the Region-colors scroll-offset check (SM-PG-2) and a
  re-run of DEGRADED-1 (SM-PG-3). None is marked passed here.
