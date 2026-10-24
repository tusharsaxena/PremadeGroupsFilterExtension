# Summary: LibKa0s v1.76.0 -> v1.77.0 (Ka0s Premade Groups Filter Extension)

- **Tag:** v1.76.0 -> v1.77.0 (local annotated tag `7380d36`, LibKa0s commit `78240f7`, never
  checked out). Base from the `CLAUDE.md` provenance line, confirmed against the payload. Minors
  moved: Core 11 -> 12, Widgets 14 -> 15, WidgetsDragHandle 4 -> 5, WidgetsAutocomplete 2 -> 3,
  DebugLog 20 -> 21, Options 29 -> 30, OptionsIds 2 -> 3, OptionsCombat 1 -> 2, OptionsCompose
  7 -> 8, PerfPanel 8 -> 9, SimPanel 5 -> 6; new `OptionsKeybinds.lua` at minor 3. Kit 41 -> 42
  (`01_DELTA.md` 3c, 3f).
- **Branch:** `feat/2026-10-24-keybinds-layout-strata`, cut from a clean `master`.
- **Span bundle:** none; every vendored tag since the horizon is recorded. No base correction.
- **Delivered free (class A):** the toplevel debug console that re-raises a shown confirmation, and
  dropdown menus clamped to screen. Owner smoke for PGFE comes with PG-ZS, not here.
- **Contract blocker (fixed in the re-vendor commit):** every Options degradation stub owes
  `KeybindingsTab`, `KeybindRows`, `KEYBINDS_UNCHANGED` and `StrataTooltip` (tag `CHANGELOG.md`
  *What a consumer owes*; Options doc lines 1539-1541, 1581, 1994-1996). `settings/OptionsSetup.lua`
  gains the four, inert. Also `tests/loader.lua` gains `OptionsKeybinds.lua` in XML order.
- **Icon line:** kept, `LibKa0s icons: clear, close, copy.`, directly under the provenance line.
  Prune: kept 4 files (3 icons plus `LICENSE-open-iconic.txt`), removed 5,836 the copy had brought
  back, so the committed icon folder is unchanged.
- **README credits:** unchanged (the shipped set is still the three Open Iconic icons). No dead stub
  mirror, no 3j test.
- **Adopted:** nothing. `O.StrataTooltip` and the kit's `mock_layers.lua` are left to PG-ZS;
  everything else is deferred (run 2026-10-24) (`03_DECISIONS.md`); no GitHub issue filed, per the
  item. **Unreached:** none.
- **Refresh file:** none.
- **Docs rippled:** the `CLAUDE.md` provenance line; the LibKa0s version in `docs/ARCHITECTURE.md`
  and `docs/module-map.md`.
- **`/dev-copilot:wow-revendor-standards` against v2.88.0 (2026-10-24, read from the local
  `../WowAddonStandards` run branch, which is not pushed, so the raw GitHub base would serve
  v2.87.0):** a no-op. `documentation.md` and `toc-file.md` did not change in v2.88.0. TOC
  `## X-Standard:` is the standard's URL, the README badge is the bare canonical image, and
  `CLAUDE.md`'s `## Standards compliance (read first)` keeps the stop-and-flag directive and the
  two-way classification. The command forbids a version stamp on the reference ("Do not write the
  standard version into any repo file"), so none is written, and the item's
  `grep 2.88.0 *.toc README.md CLAUDE.md` check finds nothing by design. The `§N.M` sweep
  (`grep -rEn '§[0-9]+\.[0-9]' . --exclude-dir=.git --exclude-dir=libs --exclude-dir=_kit
  --exclude-dir=audits --exclude-dir=reviews --exclude-dir=automated-tests`) finds 0. Every
  `filename-§N` outside the frozen bundles resolves in range against v2.88.0's 28 section files
  (the new `frame-layering` among them). The only unresolved forms are prose: `filename-§N`,
  `bucket-or-§12` and `bucket-vs-§12` quoted in the frozen `docs/revendor/2026-10-23-v1.76.0/05_SUMMARY.md`,
  and the placeholder `performance-§N` in the executed plan
  `docs/superpowers/plans/2026-10-10-audit-review-fixes.md:789`. All are left alone. The standard
  has no quirks catalog. `.gitattributes` is unchanged; worktree stragglers 0 (the 3g command).
  No 3f gate sentence changed; the `docs/automated-tests/RESULTS.md` lead-in is runner-generated
  and out of this sweep's reach.
- **Gates:** `luacheck .` 0 warnings / 0 errors in 60 files; `lua tests/run.lua` 422 passed,
  0 failed, 1 skipped, 423 total (`tests/test_vendor_sync.lua` green at v1.77.0); largest authored
  `.lua` file 1,215 lines (`tests/test_panel.lua`), under the 1,500 cap.
- **Owner smoke owed:** none new from this item.

## Re-vendor after the tag moved (M3)

- **Why:** LK-95 moved the local annotated tag `v1.77.0` in `../LibKa0s` to carry the M3
  settings-layout surface. Item PG-RV2 re-vendors it exactly as PG-RV did; no new bundle, no
  adoption (PG-LY adopts).
- **Old tag:** tag object `7380d3662be0568acf9a0d224a6aef8ac6df93ce`, commit
  `78240f7b2d69df27b74fc9280cbfbf7b95dd4f1f`.
- **New tag:** tag object `b2b8ee25c5f9fa26db146254bf786b366dec986b`, commit
  `afae2f75cb7ff61c57156d9a3d8a6b2b9f4c5e10` (`git -C ../LibKa0s rev-parse v1.77.0^{}`), never
  checked out; extracted with `git archive v1.77.0 LibKa0s testkit` into a scratch dir.
- **Minors moved:** OptionsCompose 8 -> 11 (minor 9: `MasterControls` takes `notes`,
  `resetPositionTooltip` and `lockIsPreview`, the alpha row reads Master opacity, the frameless
  packing; minor 10: the group composers take `tooltips`; minor 11: `O.ResetAllTooltip(tail)`).
  Every other `libs/LibKa0s/` file and the whole `tests/_kit/` are byte-identical to the previous
  vendoring (kit revision unchanged at 42). `LibKa0s.xml` is unchanged, so `tests/loader.lua` is too.
- **Provenance line:** unchanged, `Bundles LibKa0s v1.77.0 (MIT).`; it records no sha or kit
  revision, so nothing rolls. Icon line kept, `LibKa0s icons: clear, close, copy.`; the tag's
  `tools/prune-icons.lua` kept 4 files and removed the 5,836 the copy brought back, so the
  committed icon folder is unchanged.
- **Contract blocker (fixed here):** the Options degradation stub owed the new public
  `ResetAllTooltip` (parity red: "ResetAllTooltip is missing (live: function)"), so
  `settings/OptionsSetup.lua` gains it, inert (returns `""`).
- **Standards half:** nothing. Since PG-RV, the standard's `documentation.md` and `toc-file.md`
  did not change (WS-30..WS-38, WS-95 touch options-ui, library-stack and the ripple sites), so the
  three-place reference still matches; the `§N.M` sweep finds 0.
- **Gates:** `luacheck .` 0 warnings / 0 errors in 63 files; `lua tests/run.lua` 430 passed,
  0 failed, 1 skipped, 431 total; largest authored `.lua` file 1,215 lines
  (`tests/test_panel.lua`), under the 1,500 cap.
- **Owner smoke owed:** none new from this item.
