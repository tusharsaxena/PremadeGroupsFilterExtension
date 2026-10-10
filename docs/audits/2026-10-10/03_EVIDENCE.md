# 03 — Evidence: Ka0s Premade Groups Filter Extension

Commit `5decd65`, standard v2.78.0. Every `file:line` below was re-read at that commit before it was
written, and the quoted text is what sits on that line. Every count names its command and its scope.
**Default census scope** (layout-§1): `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`,
which is 58 files and includes `tests/`. Runtime claims (registrations, hooks, writes) use the
**TOC load list**, which is the same 58 files minus the 25 under `tests/`.

## E0 — Standard fetch and kind

```
$ curl -fsSL $RAW/AUDIT.md / standards/STANDARDS.md / standards/ADDONS.md / standards/standards/<27 files>
fail=0                                  # every Sections link fetched
$ diff -q <fetched> ../WowAddonStandards/<same path>   # clone at e6ab2b8 = origin/master
(no output for AUDIT.md, STANDARDS.md or any of the 27 section files)
STANDARDS.md:1  # Ka0s WoW Addon Standard (v2.78.0, 2026-10-09)
$ dev-copilot-profile
profile=wow  kind=addon  reason=toc:## Interface
$ grep -c '^| ' standards/ADDONS.md      # 17 table lines; grep -i 'premade' → no hit
```

## E1 — Deviation register (PGE-R01, PGE-R02)

- `docs/ARCHITECTURE.md:388`: `| library-stack-§6, anti-patterns #29 | `core/EUIBridge.lua` reads EllesmereUI's SavedVariables … | 2026-10-09 | EllesmereUI ships a public query for its third-party switches, or the standard gains a carve-out … |`
- `docs/ARCHITECTURE.md:389`: `| library-stack-§6, toc-file-§1 | Hard `## Dependencies: PremadeGroupsFilter` … | 2026-10-09 | PGF ships a public API, or the standard gains an extension-addon rule |`
- The rules are unchanged at v2.78.0. `library-stack.md` §6 still says "**MUST NOT** read a suite's
  media files, textures, fonts, or SavedVariables" and "**MUST NOT** hard-depend on any addon
  suite or standalone addon". `anti-patterns.md:35` (#29) is unchanged.
- The reads are confined to one file: `core/EUIBridge.lua:44` `local d = EllesmereUIDB` (inside
  `db()`, `:43-46`), read by `IsMasterOn` (`:56-59`) and `IsEntryOn` (`:62-66`). No write.
- Issue store: `gh issue list --state all --limit 200 --json number,title,state,labels` returns 19
  issues, all OPEN and all `state:untriaged`. No `state:will-not-do`, so there is no missing-row case.

## E2 — Closed: PGE-01, PGE-14, PGE-22

- `modules/EnvInject.lua:43`: `local idx = NS.Compat.GetSpecialization()`. `:45`: `if idx then specID, _, _, _, role = NS.Compat.GetSpecializationInfo(idx) end`
- `settings/Panel.lua:28`: `Helpers.BuildLandingPage(ctx, {`. `:29`: `logo     = MAIN_LOGO_TEXTURE,` (no `logoSize` key in `:28-38`).
- `CLAUDE.md:24`: `The newest compliance snapshot is `docs/audits/2026-10-09/` (standard v2.77.0; …`

## E3 — Vendored LibKa0s and test kit

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md
45:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.71.0 (MIT).
$ grep -n 'Bundles \[LibKa0s\]' README.md            → (none)
$ git -C ../LibKa0s archive v1.71.0 LibKa0s testkit | tar -x -C <scratch>
$ diff -r <scratch>/LibKa0s libs/LibKa0s && echo SHIP-EMPTY     → SHIP-EMPTY
$ diff -r <scratch>/testkit tests/_kit   && echo KIT-EMPTY      → KIT-EMPTY
$ git log --format='%h %ad %s' --date=short -- libs/LibKa0s tests/_kit
5939cc7 2026-10-09 Scaffold addon to the Ka0s standard with stub modules
$ ls docs/revendor → No such file or directory          # no store, no horizon
```

`PremadeGroupsFilterExtension.toc:34`: `libs\LibKa0s\LibKa0s.xml` (once).

## E4 — Write paths (PGE-02)

```
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'db\.(profile|global|char)\.[A-Za-z.]+ *=[^=]|table\.(insert|remove)|wipe\('
modules/Panel.lua:712:    if not stoodDown() then NS.addon.db.profile.panelCollapsed = on and true or false end
settings/SchemaSetup.lua:71:        for i, row in ipairs(list) do table.insert(rows, at + i - 1, row) end   # schema row list, not stored
```

Scope: the TOC load list (tests excluded). The filters are written through a local alias that the
grep does not see:

- `modules/Filters.lua:10`: `function Filters.Get() return NS.addon.db.char.filters end`
- `:12`: `function Filters.Set(key, value) Filters.Get()[key] = value end`

Controls that set them:

- `modules/Panel.lua:208`: `NS.Filters.Set(key, self:GetChecked() and true or false)` (checkbox)
- `:242` (number boxes through `accept`)
- `:743`: `setCollapsed(NS.addon.db.profile.panelCollapsed ~= true)` (the new header click)
- `docs/ARCHITECTURE.md:108`: `- **Named non-setting state** (architecture-§5), each written outside the seam by one owner:`
- `:116`: `- `profile.panelCollapsed` — the attached panel folded to its title strip. Owner `modules/Panel.lua`.`

## E5 — Message bus (PGE-03)

- `docs/ARCHITECTURE.md:122`: `None. The addon defines no AceEvent messages; modules call each other directly through `NS`.`
- Direct reactions to another module's change:
  - `modules/Panel.lua:807`: `if NS.EUISkin then NS.EUISkin.TryApply() end`
  - `:845`: `if want and NS.EUISkin then NS.EUISkin.TryApply() end`
  - `core/PGFE.lua:60`: `if NS.Panel and NS.Panel.frame then NS.Panel.Refresh() end`
  - `:70`: `NS.EUISkin.OnSwitch(p ~= nil and p.euiSkin == true)`
  - `modules/Apply.lua:90`: `if NS.Panel and NS.Panel.Refresh then NS.Panel.Refresh() end`
- `git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE '(Send|Register)Message\(|"Ka0s_'` → no hit.

## E6 — Debug lines (PGE-04, PGE-25)

```
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'NS\.Debug(AtEnable|Once|Changed)?\('
core/LauncherSetup.lua:59 / :60, core/LifecycleSetup.lua:58, settings/OptionsSetup.lua:87,
settings/Schema.lua:85, settings/Slash.lua:134            # descriptor forwarders
core/PGFE.lua:76, :81, :89, :91                           # the profile callbacks
settings/Schema.lua:152                                   # reset error
modules/EUISkin.lua:323, :331, :388                       # the skin
```

No hit in `modules/Apply.lua`, `modules/Panel.lua`, `modules/Presets.lua`, `modules/EnvInject.lua`
or `modules/RegionTags.lua` (scope: TOC load list).

- PGE-25: `modules/EUISkin.lua:45`: `local lastSkip      -- the last skip reason logged: a panel re-show repeats it, the log does not`
- `:323`: `if why ~= lastSkip then NS.Debug(TAG, "skipped: %s", why) end`
- `:324`: `lastSkip = why`
- `core/DebugLogSetup.lua:83-116`: `lib:New({ … })` carries no `onClear` key.

## E7 — Disabled-state census (PGE-05, PGE-20, PGE-29)

```
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'Register(Unit)?Event|RegisterMessage|RegisterBucketEvent|FEATURE_EVENTS'
core/PGFE.lua:43:        NS.SafeRegisterEvent(self, row[1], row[2], NS.rejectedEvents)
modules/EUISkin.lua:365/366   UI_SCALE_CHANGED, DISPLAY_SIZE_CHANGED
modules/EnvInject.lua:83/84   ACTIVE_PLAYER_SPECIALIZATION_CHANGED, PLAYER_SPECIALIZATION_CHANGED
modules/Panel.lua:882/883/884 CHALLENGE_MODE_MAPS_UPDATE, CHALLENGE_MODE_COMPLETED, PLAYER_ENTERING_WORLD
(+ core/CoreSetup.lua stub bodies, modules/Diagnostics.lua:59 reader)
$ … | xargs grep -nE 'Unregister(All)?Events?|UnregisterMessage|UnregisterBucket|CancelTimer|CancelAllTimers|:Cancel\(|OnUpdate|C_Timer|ScheduleTimer|NewTicker'
core/PGFE.lua:121:    for _, row in ipairs(NS.FEATURE_EVENTS) do PGFE:UnregisterEvent(row[1]) end
```

Seven feature events, every one undone at `:121`. There is no timer, ticker or `OnUpdate` anywhere,
so PGE-20's AceTimer embed (`core/PGFE.lua:10`, `"AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")`)
is unused.

Hooks (scope: TOC load list), each gated:

- `core/PGFBridge.lua:149` and `:160-162`
- `modules/RegionTags.lua:68` (body `active()` at `:25`: `if NS.IsStoodDown() or PremadeRegions then return false end`)
- `modules/EUISkin.lua:172-173`, `:232-239` (`if stoodDown() then return end`)
- `modules/Panel.lua:90-99`

PGE-29: `modules/EUISkin.lua:385-390` (`onFacade`: `S = facade`, `S.OnLooksChanged(repaintLooks)`,
`NS.Debug`, `EUISkin.TryApply()`) and `:392-395` (`EllesmereUI.RegisterSkin(NS.EUIBridge.SKIN_NAME, onFacade)`).

PGE-05, `tests/test_disabled.lua`:

- `git log --oneline 58156ca..HEAD -- tests/test_disabled.lua` returns nothing (unchanged).
- `:16`: `NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "PLAYER_ENTERING_WORLD", "OnProbeEvent" }`, the
  same event `modules/Panel.lua:884` registers to `OnPanelEnteringWorld`. AceEvent keeps one method
  per event per object, so the probe displaces it.
- `:67`: `NS.addon:OnSlashCommand("version")`
- `:70`: `NS.addon:OnSlashCommand("list")`
- `grep -n 'diagnostics' tests/test_disabled.lua` → no hit.

## E8 — TOC annotations (PGE-06, -07, -08, -28)

- `PremadeGroupsFilterExtension.toc:73`: `# Modules (conventional: each publishes its own NS table and reads others at call time)`
- `:98`: `settings\Panel.lua` (no comment on or above it except `:95-96`, which annotates `settings\OptionsSetup.lua`)
- `:99`: `# Conventional: NS.COMMANDS and the slash descriptor; handlers resolve everything at call time.`

File-scope reads:

- `modules/EnvInject.lua:73`: `local addon = NS.addon`
- `modules/EnvInject.lua:89`: `NS.Bridge.InstallEnvHook(function(env, leaderName) EnvInject.Apply(env, leaderName) end)`
- `modules/Panel.lua:26`: `local L = NS.L`
- `modules/Panel.lua:861`: `local addon = NS.addon`
- `modules/Panel.lua:892`: `NS.Bridge.HookDialog(function()`
- `settings/Slash.lua:136`: `get          = NS.SchemaRuntime.Get,` and `:137` `set          = NS.SchemaRuntime.Set,`
- `settings/Panel.lua:12`: `local PGFE     = NS.addon`
- `settings/Panel.lua:46`: `local MASTER_ROWS, MASTER_TAIL = Helpers.MasterControls{`
- `settings/Panel.lua:81`: `NS.SchemaRuntime.AddRows(MASTER_ROWS, 1)`
- `settings/Panel.lua:113`: `NS.SchemaRuntime.AddRows(EUI_ROWS)`
- `settings/Panel.lua:266`: `Helpers.RegisterOptionsPage("general", "General", buildGeneralPage)`

Compliant, for contrast: `.toc:84-85` annotates `modules\EUISkin.lua` as LOAD-BEARING.
`modules/RegionTags.lua` reads no earlier `NS` member at file scope (its loop at `:64-69` hooks client
globals only), so its position is conventional.

## E9 — Performance (PGE-09)

- `core/PerfSetup.lua:37`: `buckets   = {},`
- `ls tests/perf.lua` → No such file or directory
- `docs/performance.md:25`: `… **No bucket is declared at v0.1.0**: the env …`
- `docs/performance.md:32`: `` `tests/perf.lua` is not written yet, so the automated-test runner records `perf` as a skip ``

The second per-row path is `modules/RegionTags.lua:48-52` / `:56-60` (`OnSearchEntryUpdate`,
`OnApplicantMemberUpdate`), unbracketed.

## E10 — Reset tests (PGE-10)

```
$ grep -lnE 'RestoreAllDefaults|ResetProfile|resetall' tests/*.lua
tests/test_euisettings.lua   tests/test_slash.lua
```

- `tests/test_euisettings.lua:148`: `H.RestoreAllDefaults()`. Its only assertion is `:149`, `assertTrue(S.Get("euiSkin"))`.
- `tests/test_slash.lua:25` is the verb list string, not a reset.

## E11 — Launcher and Slash enabled source (PGE-11, PGE-12)

- `core/LauncherSetup.lua:55`: `isEnabled  = function() return not NS.IsStoodDown() end,`
- `settings/Slash.lua:129`: `isEnabled    = function() return not NS.IsStoodDown() end,`

## E12 — Logo files (PGE-13)

```
$ python3 -c '<read 18-byte TGA header>' media/logos/*.tga
media/logos/pgfe.logo.128.tga type 2 w 128 h 128 bpp 32
media/logos/pgfe.logo.tga     type 2 w 256 h 256 bpp 32
```

- `.toc:6`: `## IconTexture: Interface\AddOns\PremadeGroupsFilterExtension\media\logos\pgfe.logo.128.tga`
- `core/LauncherSetup.lua:13`: `local ICON = ("Interface\\AddOns\\%s\\media\\logos\\pgfe.logo.128.tga"):format(addonName)`
- `settings/Panel.lua:18`: `local MAIN_LOGO_TEXTURE = ("Interface\\AddOns\\%s\\media\\logos\\pgfe.logo.tga"):format(addonName)`

## E13 — DEPENDENCIES.md (PGE-15)

- `DEPENDENCIES.md:76`: `**One entry: Python 3 with Pillow**, and only for **regenerating** the launcher logo from its`
- `docs/realm-map-maintenance.md:41`: `python3 tools/realm_map_diff.py "<WoW>/_retail_/Interface/AddOns/PremadeRegions/Regions.lua"`
- `grep -n 'realm_map_diff' DEPENDENCIES.md` → no hit.

## E14 — Literals outside `NS.L` (PGE-16)

```
$ git ls-files '*.lua' ':!libs' ':!tests' ':!locales' | xargs grep -nE '(Print|SetText|AddLine|label *=|tooltip *=|defaultsTooltip *=|text *=)\(? *"[A-Za-z]' | grep -v 'L\['
core/DebugLogSetup.lua:55:  NS.Print("debug logging " .. (on and "|cff40ff40ON|r" or "|cffff4040OFF|r"))
core/DebugLogSetup.lua:61:  label   = "Debug console",
core/LauncherSetup.lua:49:  label = "Ka0s Premade Groups Filter Extension",      # brand name: launcher-§1 literal, not a finding
settings/Panel.lua:251:     defaultsTooltip = "Reset every Ka0s Premade Groups Filter Extension setting to its default. "
settings/Slash.lua:84:      NS.Print("unknown command '" .. name .. "'")
settings/Slash.lua:88:      NS.Print("v" .. NS.Version() .. " slash commands")
settings/Slash.lua:111:     CliVersion      = function() NS.Print("v" .. NS.Version()) end,
settings/Slash.lua:150:     … return NS.Print("Settings panel is not available.") end
settings/Slash.lua:188:     if not DL then return NS.Print("Debug console not ready yet") end
```

The grep's scope is the TOC load list minus `locales/`. Seen by reading, outside the grep's pattern:

- `settings/Slash.lua:171`: `NS.Print("|cffFFFF00/pgfe reset|r takes a setting path: …"`
- `settings/Schema.lua:106` / `:110`: `pout("|cffff0000schema error|r: " .. where .. …)`
- `docs/scope.md:52`: `- **Translations.** English only for now; strings go through `NS.L` so a locale can be added.`

## E15 — Panel chrome (PGE-17, PGE-19, PGE-26)

- `modules/Panel.lua:29`: `local BORDER_LAYOUT = "ButtonFrameTemplateNoPortraitMinimizable"`
- `modules/Panel.lua:767`: `local f = CreateFrame("Frame", FRAME_NAME, dialog, "PortraitFrameTemplateMinimizable")`
- `modules/Panel.lua:771`: `f:SetBorder(BORDER_LAYOUT)`
- `modules/EUISkin.lua:259`: `S.Shell(f)`. The register has no `standalone-windows` row (E1).
- `git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'SetMovable|UISpecialFrames'` → no hit.
- `settings/Panel.lua:51`: `omit             = { visibility = true },`
- `modules/EUISkin.lua:33`: `local COLLAPSE_ATLAS = "UI-QuestTrackerButton-Secondary-Collapse"   -- a minus`
- `modules/EUISkin.lua:34`: `local EXPAND_ATLAS   = "UI-QuestTrackerButton-Secondary-Expand"     -- a plus`
- `modules/EUISkin.lua:227`: `glyph:SetAtlas(atlas, false)`
- `libs/LibKa0s/Media.lua:94`: `"close", "minimise", "expand", "lock", "unlock", "settings", "segment", "reset", "export",`

## E16 — Labels, roster (PGE-18, PGE-21)

```
$ gh label list --json name,color --limit 100 --jq '.[] | "\(.name) \(.color)"' | grep -E 'state:|severity:'
state:untriaged ededed     (mandated ff0000)     state:done 5319e7      (00ff00)
state:triaged 0e8a16       (ffff00)              state:will-not-do 000000 (0000ff)
severity:high d93f0b       (110800)              severity:medium fbca04  (111100)
severity:low c2e0c6        (001100)              severity:critical b60205 (110000)
```

The mandated colors are from `audit-review-history.md:149-152` and `:169-171`, where `severity:high`
reads "A user-visible defect, or a standard deviation carried out of an audit or review bundle".
`standards/ADDONS.md` has no row for this addon (E0).

## E17 — Complexity (PGE-24)

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle
PremadeGroupsFilterExtension 0.1.0 — automated tests — 20261010-024533
  complexity  fail  — str warnings (fun rate instance,), TypeError: NLOC / expected funcs, avg NLOC sequence, avg CCN item (max 14), avg tokens 0: (recorded, non-gating)
              lizard blind in 54 file(s): `core/Compat.lua` (0 of 2 functions listed), … `tests/wow_mock.lua` (0 of 103 functions listed)
  verdict: amber
  record:  newest bundle 20261009-082905 measured 2c78ddb, 38 commit(s) behind HEAD — its figures describe a tree this one is no longer
complexity exit 0
```

The cause was reproduced by running the runner's own steps by hand (the shadow via
`lua tests/_kit/lizard_sighted.lua shadow`, then the same `lizard` command in it):

```
$ cd <shadow> && ka0s-bounded lizard -l lua -L 1500 -x "./libs/*" -x "./tests/_kit/*" .   → exit 1
TypeError: sequence item 0: expected str instance, NoneType found     (lizard.py:413 with_namespace)
$ for f in <58 files>; do ka0s-bounded lizard -l lua "$f" || echo CRASH $f; done
CRASH modules/RegionTags.lua
```

Two-file repro (lizard 1.24.0):

- `for name, fn in pairs({ A = function(...) f(...) end, }) do g(name, fn) end` → **TypeError**
- `local t = { A = function(...) f(...) end, }` then `for name, fn in pairs(t) do g(name, fn) end` →
  parses: 1 function, 0 warnings.

The crashing site is `modules/RegionTags.lua:64`, `for name, fn in pairs({`, with the anonymous
functions at `:65-66`.

**Diagnostic only, not comparable with any record.** The same command over the shadow with
`modules/RegionTags.lua` removed reports `6928 NLOC, 1057 functions, 0 warnings`, max CCN 14 at
`reloadProfile@53-72@./core/PGFE.lua`. That is dense guarding: `S and S.Helpers`, `NS.Panel and
NS.Panel.frame`, `self.db and self.db.profile and …`, with no tangled flow. Next are
`S.SetMany@128-143` (13), `prepare@87-109` (12) and `Panel.UpdateVisibility@838-848` (12).

The previous record (`docs/automated-tests/20261009-082905/manifest.json:16`) reads
`"maxCcn": 13 … "functions": 653 … "blindFiles": 0`, on `"lizard": "1.24.0"` (`:11`), so the lizard
version is the same and the regression is the new file.

```
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | xargs wc -l | awk '$1>=1000 && $2!="total"'
  1061 tests/test_panel.lua
```

That is the band entry. The record says 0 band files (`docs/automated-tests/RESULTS.md:69`). The
watch list has no rows, so there are no **Accepted** entries and anti-pattern #53 has nothing to
count. `docs/complexity.md` is absent. `Kit.VERSION = 38` (`tests/_kit/framework.lua:20`), and
`test_lizard_sighted` is declared at `tests/run.lua:112`.

## E18 — Master controls extras (PGE-23)

- `settings/Panel.lua:56`: `-- A legitimate extra (options-ui-§16), after the mandated rows: the attached panel's first box.`
- `settings/Panel.lua:59`: `{ path = "filtersActive", type = "bool", default = C.PROFILE.filtersActive,`
- `settings/Panel.lua:63`: `{ path = "showRegionTags", type = "bool", default = C.PROFILE.showRegionTags,`
- `docs/settings-panel.md:33`: `rows (options-ui-§16) after the mandated ones. …`
- `options-ui.md` §15: "**The set is canonical, not a menu.** An addon includes every row that applies
  to it and **MUST NOT** reorder them, rename them, or split them across tabs". §16 is titled
  *Control groups — font, border, bar*.
- Page → tab list from the schema: **General** → `Master controls` (enabled, debug console, minimap
  button, filtersActive, showRegionTags, reset all) → `EllesmereUI skin` (euiSkin). The landing page
  and Profiles are exempt.

## E19 — AceGUI pool leak (PGE-27)

```
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'AceGUI|\.(frame|content)(:|\)|,)'
settings/Panel.lua:150  GameTooltip:SetOwner(cb.frame, "ANCHOR_RIGHT")      # anchor only, not a hit
settings/Panel.lua:167  local box = AceGUI:Create("EditBox")
settings/Panel.lua:197  GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPLEFT")  # anchor only
settings/Profiles.lua:29-36 container.frame:SetParent / SetPoint / Show      # reparent of a held widget, not a §19 hit
```

- `settings/Panel.lua:174`: `if box.editbox and box.editbox.HookScript then`
- `settings/Panel.lua:175`: `box.editbox:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)`
- `grep -n 'OnRelease' settings/Panel.lua` → no hit.
- `libs/AceGUI-3.0/widgets/AceGUIWidget-EditBox.lua:139-141`: `["OnRelease"] = function(self) self:ClearFocus() end,`.
  `OnAcquire` (`:129-137`) resets width, label, text, button and max letters, and no script.
- Reach: `settings/Panel.lua:239`: `if scroll and B.PGFSkinState() == "missing" then addPGFSkinLink(scroll) end`.
  `core/EUIBridge.lua:98`: `return installed(PGF_SKIN_ADDON) and "disabled" or "missing"`, which a
  player without `PremadeGroupsFilter_EllesmereUI` gets.

## E20 — Mechanical checks, compliant

```
$ ka0s-bounded luacheck .         → Total: 0 warnings / 0 errors in 58 files   (exit 0)
$ ka0s-bounded lua tests/run.lua  → 325 passed, 0 failed, 1 skipped, 326 total (exit 0)
  SKIP diagnostics contract: an addon that opts out … this addon keeps the default
$ ka0s-bounded lua tests/run.lua --list | diff docs/test-cases.md -   → (empty, CR-normalized)
README.md:6  ![Tests](https://img.shields.io/badge/Tests-325%2F325_passing-green)
```

- `.luacheckrc:11`: `exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "docs/revendor/", "_dev/", "tests/_kit/" }`. There is no top-level `ignore`.

Line endings (whole tracked set, 348 files):

```
test -f .gitattributes          → present
grep -n '^\* text=auto eol=…'   → 26:* text=auto eol=crlf
grep -nE '^\*\.(sh|py) …'       → 36:*.sh text eol=lf   37:*.py text eol=lf
grep -c ' binary$'              → 20
diff <(head -n 84 .gitattributes | tr -d '\r') <line-endings-§5 client-bound body>   → empty; wc -l = 84, no appendix
(e) git ls-files -z | xargs -0 -n1 sh -c '<AUDIT.md (e) body>' _ | wc -l   → 0
```

Packaging (bash): (a) nothing reported; (b) `UNACCOUNTED — .git` only; (c) nothing. The
`.pkgmeta:11-12` lines for `.claude`/`.superpowers` are commented out.

README checks:

- `README.md:5`: `![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)` (bare)
- These all return no hit: `grep -nE '^[[:space:]]*[0-9]+[.)][[:space:]]' README.md`, the
  library-heading grep, `![…](media/logos` and `<img`.

Documentation map:

- `git ls-files 'docs/*.md' 'docs/**/*.md'`, minus `docs/{audits,reviews,superpowers,investigations,revendor}/`
  and the dated `automated-tests/` and `perf-analysis/` runs, diffed against the hub's `| \`…\`` rows
  (`docs/ARCHITECTURE.md:341-379`). The only differences are `ARCHITECTURE.md` (the self-row MAY)
  and the three *Not applicable* rows.
- `grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua` → 0, below the trigger of 3.

Other checks:

- Close buttons: `grep -rn 'MakeCloseButton(' --include='*.lua' .` outside `libs/` returns only
  `core/CoreSetup.lua:87` (the wrapper).
- `SettingsPanel|HideUIPanel|ToggleGameMenu|OpenToCategory` and
  `LibStub("LibDataBroker|LibStub("LibDBIcon|OnTooltipShow|MenuUtil|EasyMenu` → no hit in host code.
- Diagnostics:
  - `grep -n '"diagnostics"' settings/*.lua core/*.lua` → `settings/Slash.lua:46` only.
  - `grep -rniE '"(diag|dump|dx)"' settings core modules` → `modules/Diagnostics.lua:11`
    `local TAG = "Diag"`, a console tag rather than an alias.
  - `settings/Slash.lua:122`: `for i, verb in ipairs(lib.LIVE_VERBS) do liveVerbs[i] = verb end`
