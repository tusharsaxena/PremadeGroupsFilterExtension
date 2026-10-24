# Candidates: LibKa0s v1.76.0 -> v1.77.0 (Ka0s Premade Groups Filter Extension)

Sources: `git -C ../LibKa0s log --oneline v1.76.0..v1.77.0`, the v1.77.0 block of the tag's
`CHANGELOG.md`, and the tag's `docs/api/` documents for the majors whose minors moved (Core 12,
DebugLog 21.3.1, Options 30.2.34.3.5.9.2.8.4.2.1.3, Widgets 15.1.5.3.3, Perf 15.1.1.9, Sim 2.3.6,
testkit 42). The run's item spec (PG-RV, `Ka0sAddonsCommonTasks/docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/plan-data/items.json`)
says not to interview: the adoptions this run needs for PGFE are the PG-ZS item's (held for the
owner), and every other candidate is recorded as deferred. The 3g blocker (the four Options stub
members) is not a candidate; it was fixed in the re-vendor commit.

## A. Reached the addon on the re-vendor alone (delivered)

| Change | Evidence | Why it is free |
|---|---|---|
| The debug console is toplevel and re-raises a shown StaticPopup on show (Core 12 `Core.RaiseStaticPopups`, DebugLog 21) | `CHANGELOG.md` v1.77.0, *Core minor 12, DebugLog minor 21, PerfPanel minor 9 and SimPanel minor 6* | PGFE wires the console through `core/DebugLogSetup.lua`; "What a consumer owes: nothing" |
| Dropdown menus clamped to screen (Widgets 15) | *Widgets minor 15 and WidgetsAutocomplete minor 3* | Every `lib.Dropdown` PGFE's settings panel draws takes it with the copy |
| IdList suggestion list closed at combat start (OptionsIds 3, OptionsCombat 2) | *OptionsIds minor 3 and OptionsCombat minor 2* | Internal (`__`-prefixed); PGFE draws no id input, so it is inert here |
| Keybindings sync on `UPDATE_BINDINGS` (OptionsKeybinds 3) | *OptionsKeybinds minor 3* | Internal; reaches only a host that draws the tab |

## B. Host change required (listed, not offered)

| Surface | Evidence | Status |
|---|---|---|
| `O.StrataTooltip(values[, strings])` (OptionsCompose 8) | `docs/api/Options/version-30.2.34.3.5.9.2.8.4.2.1.3-docs.md:1581,2745` | Belongs to PG-ZS (step 3, only where PGFE has a player strata row); not adopted here |
| Kit `mock_layers.lua` (kit 42) | `docs/api/testkit/version-42-docs.md`; `CHANGELOG.md` *Test kit revision 42* | Belongs to PG-ZS (its frame-layer pins); not adopted here |
| `O.KeybindingsTab(spec)`, `O.KeybindRows(ctx, spec, parent)`, `O.KEYBINDS_UNCHANGED` (OptionsKeybinds 2) | Options doc lines 1539-1541, 1821-1996 | deferred (run 2026-10-24): PGFE declares no key binding and has no PG-KB item |
| Kit `mock_bindings.lua`, `Kit.assertBindingsXml`, `Kit.keybindThroughTab` (kit 42) | testkit doc; *Test kit revision 42* | deferred (run 2026-10-24): PGFE ships no `Bindings.xml` |
| WidgetsDragHandle `spec.level`, `handle:ApplyLevel()`, `spec.ignoreParentAlpha` (DragHandle 5) | `docs/api/Widgets/version-15.1.5.3.3-docs.md` | deferred (run 2026-10-24): PGFE builds no drag handle |

## C. Whole-module adoption (listed, not offered)

| Major | Evidence | Status |
|---|---|---|
| `LibKa0s-Sim-1.0` (2.3.6) | *SimPanel minor 6* | Settled at v1.75.0 (`docs/revendor/2026-10-22-v1.75.0/03_DECISIONS.md`): no test mode, no simulator. The premise is unchanged |
| `LibKa0s-Perf-1.0` (15.1.1.9) | *PerfPanel minor 9* | Settled at v1.75.0 (the recorded `performance-§12` exemption). The premise is unchanged |
| `LibKa0s-Widgets-1.0` as a direct lookup | as A | deferred (run 2026-10-24): no PGFE surface draws a library widget itself |
