# 04 — Technical design: closing the 2026-10-10 deviations

Keyed to `02_DEVIATIONS.md`. The design is ordered by risk. The one Medium comes first, then the
release blocker, then the structural MUSTs, then the docs and config. Every change goes through the
green gate (`lua tests/run.lua` and `luacheck .` at 0/0, both via `ka0s-bounded`), and `libs/` and
`tests/_kit/` are never edited (re-vendor instead). The table maps carried items to their existing
issue: close or narrow the issue in the same change that fixes it.

| ID | Issue | Area |
|---|---|---|
| PGE-27 | new | `settings/Panel.lua` |
| PGE-24 | new | `modules/RegionTags.lua`, release record |
| PGE-05 | #4 | `tests/test_disabled.lua` |
| PGE-09 | #5 | `core/PerfSetup.lua`, `modules/EnvInject.lua`, `modules/RegionTags.lua`, `tests/perf.lua` |
| PGE-02, PGE-03 | #10 | `docs/ARCHITECTURE.md` (+ optional code) |
| PGE-04, PGE-25 | #11 | `modules/*.lua` debug lines |
| PGE-06/07/08/28 | #12 | `PremadeGroupsFilterExtension.toc` |
| PGE-10 | #13 | `tests/test_reset.lua` (new) |
| PGE-11/12 | #14 | `core/LauncherSetup.lua`, `settings/Slash.lua` |
| PGE-13 | #15 (narrow: PGE-14 closed) | `media/logos/`, three references |
| PGE-15 | #16 | `DEPENDENCIES.md` |
| PGE-16 | #17 | `locales/enUS.lua` + call sites |
| PGE-17/26, PGE-19 | #18 | `docs/ARCHITECTURE.md` register, `modules/EUISkin.lua` |
| PGE-18 | #19 | GitHub labels |
| PGE-23 | new | `settings/Panel.lua`, `docs/settings-panel.md` |
| PGE-20, PGE-21, PGE-29 | none | Info |

## PGE-27 — the link EditBox hook (options-ui-§19), Medium

**Shape.** Only the widget's own frames may carry the behavior, and the release must undo it. AceGUI
keeps one callback per name, and `"OnRelease"` fires before callbacks are cleared, so:

```lua
local function addPGFSkinLink(scroll)
    ...
    local box = AceGUI:Create("EditBox")
    ...
    local eb = box.editbox
    if eb and eb.HookScript and not eb.__pgfeLinkHook then
        eb.__pgfeLinkHook = true                      -- hook once per pooled frame, never stacked
        eb:HookScript("OnEditFocusGained", function(self)
            if self.__pgfeLinkActive then self:HighlightText() end
        end)
    end
    if eb then eb.__pgfeLinkActive = true end
    box:SetCallback("OnRelease", function(w)          -- the box's single OnRelease
        if w.editbox then w.editbox.__pgfeLinkActive = nil end
    end)
    scroll:AddChild(box)
    Settings.PGFSkinLinkBox = box
end
```

`box` comes from `AceGUI:Create`, not from a library maker, so setting `"OnRelease"` on it is
allowed (options-ui-§19). Also drop `Settings.PGFSkinLinkBox` inside the same `OnRelease`
(`Settings.PGFSkinLinkBox = nil` when `w == Settings.PGFSkinLinkBox`), so a released widget is never
read back.

**Test.** Add a mock pool to `tests/wow_mock.lua` if the AceGUI fake has none, or assert at the hook
level: render the tab, release the box, acquire a new `EditBox`, fire `OnEditFocusGained`, and
assert `HighlightText` was **not** called. Mutation: delete the `OnRelease` and the case goes red.

**Risk.** Low. The rendered behavior of the link box itself does not change.

## PGE-24 — make HEAD measurable again (automated-tests-§3)

**Shape.** `modules/RegionTags.lua:64-69` becomes the shape lizard 1.24.0 parses, with identical
behavior:

```lua
local PAINTERS = {
    LFGListSearchEntry_Update = function(...) RegionTags.OnSearchEntryUpdate(...) end,
    LFGListApplicationViewer_UpdateApplicantMember = function(...) RegionTags.OnApplicantMemberUpdate(...) end,
}
for name, fn in pairs(PAINTERS) do
    if type(_G[name]) == "function" then hooksecurefunc(name, fn) end
end
```

`tests/test_regiontags.lua` already pins the install. Re-run it unchanged, since this is a pure
refactor and the existing cases are its characterization (testing-§13).

**Then:**

- Run the complexity suite verbatim and confirm `blindFiles 0`.
- Before 0.1.0 is tagged, cut a fresh release record with
  `run-automated-tests.sh` (not `--no-bundle`). It will also generate the band row for
  `tests/test_panel.lua` (1061) in the watch list, which needs a Disposition. Splitting the suite by
  panel area (rows, presets, collapse, copy box) is the natural peel, but in the band it is only on
  notice and is not owed.

**Upstream (LibKa0s testkit, not this repo).** Make the runner treat a non-zero `lizard` exit or a
Python traceback as `complexity: error (lizard crashed on <file>)`, not as N blind files. Today the
parity check misattributes the crash to every file. File it as an issue on LibKa0s.

## PGE-05 — the conformance suite (slash-commands-§7), #4

Rewrite `tests/test_disabled.lua` to the section's ten steps:

1. Boot through `T.enableAddon()` and snapshot `R_on`, the mock's recorded registrations for the
   addon object (seven names).
2. Disable through `/pgfe disable`.
3. Assert the registration set is **empty by name**. `-- red under:` deleting `core/PGFE.lua:121`.
4. Assert no timer (the mock records none; there is no AceTimer use).
5. Assert `NS.Panel.frame:IsShown() == false` after a dialog show.
6. Fire every `R_on` event plus the hook paths (`m.pgf` env hook, the dialog hook, the two RegionTags
   painters, an EUISkin checkbox `SetChecked`), and assert zero SavedVariables writes, zero prints and
   zero shows. `-- red under:` removing the `stoodDown()` early return in `modules/RegionTags.lua:25`.
7. Walk every `NS.COMMANDS` verb, including `diagnostics` **and** `debug diagnostics`. Assert normal
   answers, and the one-line refusal for `apply`/`clear` that reaches no write seam.
8. The launcher: left-click opens settings while disabled; right-click *Enabled* writes only
   `enabled`.
9. Change a setting while disabled, enable, and assert the rebuild reads the current value.
10. The latch: the `disabled` hold under an active `perf` hold, and the reverse order.
    `-- red under:` replacing `Lifecycle:Set` with a direct `NS.StandUp()`.

Drop the probe event. It shadows `OnPanelEnteringWorld` (AceEvent keeps one method per event).

## PGE-09 — perf (performance-§9), #5

Declare `{ key = "envInject" }` and `{ key = "regionTags" }` in `core/PerfSetup.lua`'s `buckets`.
Bracket `EnvInject.Apply` and the two RegionTags bodies with the frozen idiom
(`local t0 = Perf.on and debugprofilestop()` …), taking `Perf` as a load-time upvalue (the TOC
already loads `core\PerfSetup.lua` before `# Modules`). Ship `tests/perf.lua` with the zero-overhead
scenario (capture off, so no `debugprofilestop` call is made) and a capture-on scenario. Update
`docs/performance.md`, and `docs/ARCHITECTURE.md`'s *Perf bucket* contract row. The alternative is
the performance-§12 exemption, which removes the instance, the verb, `PerfDB` and the hold, and is
the larger change. Prefer the brackets.

## PGE-02, PGE-03 — settings scope and bus (architecture-§5/§4), #10

**Recommended: two register rows, no code.**

- `architecture-§5`: "the attached panel's per-character filter options (`char.filters`) and
  `profile.panelCollapsed` are set by the panel's own controls outside the schema seam". Why: the
  panel is a feature surface bound to PGF's dialog, presets snapshot the table whole, and per-character
  scope is an owner requirement. Trigger: *a filter option gains a settings-page row or a CLI path*.
  Then delete the two from "Named non-setting state" (`docs/ARCHITECTURE.md:108-116`) and leave a
  pointer to the row.
- `architecture-§4`: "modules call each other directly". Why: every cross-module call is a
  synchronous single-receiver reaction (profile reload → panel/skin, filters toggled → panel). Trigger:
  *a second receiver for any of them*. Rewrite `## Message Bus` to cite the threshold.

**Alternative (code).** Adopt `LibKa0s-Bus-1.0` with two messages (`Ka0s_PGFE_ProfileChanged`,
`Ka0s_PGFE_FiltersToggled`, constants in one file). That is real work for one receiver each, so
decide with the owner.

## PGE-04, PGE-25 — debug lines (debug-logging-§8/§9), #11

- **Apply.** One `NS.Debug("Apply", "refused: %s", key)` at each precheck return, plus a write-pass
  line (`"wrote %d rows, %d chars"`) and a `"search"` line.
- **Clear.** The same shape under `"Clear"`.
- **Panel.** A `"shown"` / `"hidden"` edge line in `UpdateVisibility`, gated with
  `NS.DebugChanged("Panel", "vis", …)`.
- **Presets.** Save/Load/Delete under the `"Preset"` tag.
- **EnvInject.** `RefreshPlayer` writes `DebugChanged("Env", "spec", "spec=%s classRole=%s", …)`.
- **At enable.** `NS.DebugAtEnable("Init", "PGF seams %s; PremadeRegions %s", …)` from `OnEnable`.
- **EUISkin.** Replace the `lastSkip` memo with `NS.DebugChanged(TAG, "skip", "skipped: %s", why)`.
  The gate forgets on console Clear, which the memo cannot.

The per-result env hook and the row painters stay silent, because they are per-row paths. Add
console assertions to `test_apply.lua` (one per refusal key).

## PGE-06/07/08/28 — TOC annotations (toc-file-§5), #12

Replace `.toc:73`'s group comment with per-line annotations:

- `modules\EnvInject.lua`: `# LOAD-BEARING: reads NS.addon, appends NS.FEATURE_EVENTS/NS.STAND_UP and calls NS.Bridge.InstallEnvHook (core\PGFE.lua, core\PGFBridge.lua) at load.`
- `modules\Panel.lua`: `# LOAD-BEARING: reads NS.L, NS.addon, appends NS.FEATURE_EVENTS and calls NS.Bridge.HookDialog at load.`
- `settings\Panel.lua`: `# LOAD-BEARING: reads Settings.Helpers (settings\OptionsSetup.lua) and NS.SchemaRuntime (settings\Schema.lua) at file scope.`
- `settings\Slash.lua`: `# LOAD-BEARING: captures NS.SchemaRuntime.Get/Set/FindRow/ApplyDefault (settings\Schema.lua) into the Slash descriptor at load.`
- The remaining modules keep a `# Conventional:` line each. Update `docs/module-map.md`'s load-order
  table to match.

## PGE-10 — the reset suite (options-ui-§12), #13

Write `tests/test_reset.lua`, listed in `tests/run.lua`, with these cases:

- With two profiles, `RestoreAllDefaults()` resets only the active one, and the profile list and
  active key survive.
- `state.debugConsole` on → off after the reset.
- `global.minimap.hide = true` survives **both** the reset and the page Defaults path.
- An active profile with `enabled = false` takes the latch hold again after the reset
  (`OnProfileReset` → `reloadProfile`).

## PGE-11/12 — enabled source (launcher-§1/§2), #14

`core/LauncherSetup.lua:55` becomes
`isEnabled = function() return NS.SchemaRuntime.Get("enabled") ~= false end`. The Slash descriptor
keeps the latch (a perf hold must still refuse `apply`), so PGE-12 is resolved by **accepting** the
wording, which the SHOULD allows. Record that in the commit message. Add a case: under the perf hold,
the launcher reports Enabled = Yes.

## PGE-13 — logo names (layout-§4), #15

Run `git mv` to rename the files:

- `pgfe.logo.128.tga` → `premadegroupsfilterextension.logo.128.tga`
- `pgfe.logo.tga` → `premadegroupsfilterextension.logo.tga`
- `pgfe.logo.png` → `premadegroupsfilterextension.logo.png`

Update `.toc:6`, `core/LauncherSetup.lua:13`, `settings/Panel.lua:18`, `DEPENDENCIES.md:76-84` and
`docs/` mentions. Regenerate the landing TGA at 512×512 from the PNG, because it is drawn at 300
today and the 256 source upscales. Verify with the TGA header read (type 2, 32 bpp). The `.pkgmeta`
`*.png` glob is unaffected.

## PGE-15 — DEPENDENCIES.md (documentation-§7), #16

Rewrite the Release/assets group as **two** entries: Python 3 with Pillow (the logo), and Python 3
stdlib only (`tools/realm_map_diff.py`, command `python3 tools/realm_map_diff.py <path>`, verify with
`python3 --version`). Add one line to the lizard row: "1.24.0 crashes on a table constructor of
anonymous functions passed straight into a call (PGE-24); the runner needs files lizard can parse".

## PGE-16 — locale routing (localization-§1/§3), #17

Move the literals from E14 into `locales/enUS.lua` and read them through `L[...]`. The brand label
`core/LauncherSetup.lua:49` stays literal (launcher-§1). The library-absent stub strings
(`core/DebugLogSetup.lua:55`, `:61`) go through `NS.L` too, because `NS.L` loads first. The prose
gate (`test_prose`) covers the new keys.

## PGE-17/26, PGE-19 — attached-panel chrome (standalone-windows, library-stack-§8, options-ui-§15), #18

Add one register row:

- **Rule:** `standalone-windows; library-stack-§8; options-ui-§15`
- **What differs:** the attached panel takes PGF's dialog chrome (`PortraitFrameTemplateMinimizable`)
  unskinned and EllesmereUI's shell skinned, including the skinned min/max glyphs (quest-tracker
  atlases matching EllesmereUI); it has no movable geometry and no General visibility row, because it
  shows only with PGF's dialog
- **Why:** an extension surface must match its host window
- **Decided:** the owner's date
- **Trigger:** *the panel becomes independently shown or movable, or Ka0s gains an attached-panel
  rule*

That closes PGE-17, PGE-19 and PGE-26 together. The alternative for PGE-26 alone is
`NS.Icon("minimise")`/`NS.Icon("expand")`, tinted, which would break the EllesmereUI match.

## PGE-18 — labels, #19

Recolor the eight labels with `gh label edit "<name>" --color <hex>`:

| Label | Color |
|---|---|
| `state:done` | `00ff00` |
| `state:will-not-do` | `0000ff` |
| `state:triaged` | `ffff00` |
| `state:untriaged` | `ff0000` |
| `severity:critical` | `110000` |
| `severity:high` | `110800` |
| `severity:medium` | `111100` |
| `severity:low` | `001100` |

At triage, revisit the severities of the audit-carried issues: the vocabulary puts "a standard
deviation carried out of an audit or review bundle" at `severity:high`.

## PGE-23 — Master controls extras (options-ui-§15)

Move `filtersActive` and `showRegionTags` out of `Helpers.MasterControls{ extra = … }` into a
`Filters` group, declared as ordinary schema rows with `group = L["Filters"]`. That makes them the
second tab, and *EllesmereUI skin* becomes the third. Their paths do not change, so no migration is
needed (a `group` is not a stored path). The attached panel's first box still writes `filtersActive`
through `Filters.SetActive`. Correct the §16 citations at `settings/Panel.lua:56` and
`docs/settings-panel.md:33`, and update the page → tab tree. `tests/test_euisettings.lua` and
`tests/test_setup.lua` may index tabs by position: re-check them.

## Info items

- **PGE-20.** Drop `"AceTimer-3.0"` from `NewAddon`, the TOC line and `libs/AceTimer-3.0/` (a
  vendoring change, not an edit), or record the keep in `DEPENDENCIES.md`.
- **PGE-21.** Upstream: add the ADDONS.md row.
- **PGE-29.** Upstream: name one-shot third-party registrations in slash-commands-§7's survivor list.

## Ordering constraints

1. **PGE-24 first.** Until the RegionTags loop is hoisted, no complexity number can be produced for
   any later refactor, so performance-§11 checks would be blind.
2. **PGE-23 before PGE-10.** The reset tests should index the final tab layout.
3. **PGE-05 after PGE-09.** The conformance suite's latch step uses the perf hold, and the new
   bucket brackets must stay inert while stood down.
4. **PGE-13 is a pure rename.** It goes in its own commit.
5. **The release record (PGE-24's second half) last.** It is cut at the commit that will be tagged.
