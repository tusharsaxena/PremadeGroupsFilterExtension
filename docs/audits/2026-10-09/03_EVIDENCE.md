# 03 — Evidence: Ka0s Premade Groups Filter Extension

Every citation below was re-read at commit `58156ca` before it was written, and the quoted text is what
the line holds (CR stripped for display). Every count names its command and its scope. Runs were made
from the repo root; the working tree was clean at the start of the run (`git status --short` printed
nothing). The only files this run wrote are the five under `docs/audits/2026-10-09/`.

## E0 — The standard, the kind, the census scope

```
curl -fsSL $RAW/AUDIT.md, $RAW/standards/STANDARDS.md, $RAW/standards/ADDONS.md
grep -oE '\(standards/[A-Za-z0-9_-]+\.md' STANDARDS.md | sort -u   → 27 section files, all fetched
STANDARDS.md line 1: "# Ka0s WoW Addon Standard (v2.77.0, 2026-10-07)"
dev-copilot-profile → profile=wow kind=addon reason=toc:## Interface
grep -c 'PremadeGroupsFilterExtension' ADDONS.md → 0
```

**Default census scope (layout-§1's denominator):**

```
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | wc -l
51
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | xargs wc -l | sort -n | tail -3
   432 modules/Panel.lua
   559 defaults/Realms.lua
  5193 total
```

Covers every tracked authored `.lua`, `tests/` included; excludes `libs/` (159 tracked files under
`libs/LibKa0s` alone) and `tests/_kit/` (23 files). No generated data is declared. Whole tracked set:
330 files (`git ls-files | wc -l`), used only by the line-ending check (E17).

## E1 — The deviation register and the issue store (PGE-R01, PGE-18)

- `docs/ARCHITECTURE.md:291`:
  `| library-stack-§6, toc-file-§1 | Hard ## Dependencies: PremadeGroupsFilter; the addon reads/writes PGF state and hooks PGF's env builder | It is an extension of PGF and has no function without it (owner requirement, 2026-10-09) | 2026-10-09 | PGF ships a public API, or the standard gains an extension-addon rule |`
- Rule check against the fetched sections: library-stack-§6 still reads "**MUST NOT** hard-depend on any
  addon suite or standalone addon: no `## Dependencies:` …"; toc-file-§1 still reads "**SHOULD NOT**
  declare hard `Dependencies`". Trigger check: no section of v2.77.0 carries an extension-addon rule;
  PGF 7.6.2 is cited as the read version (`core/PGFBridge.lua:4`) and nothing in the tree consumes a PGF
  public API. Not fired. Evidence ids in Why: none.
- `PremadeGroupsFilterExtension.toc:8`: `## Dependencies: PremadeGroupsFilter`.
- `gh issue list --state all --limit 200 --json number,title,state,labels,url` → 3 issues, all OPEN:
  #1 "Raid support: brainstorm and design" (`state:untriaged`, `severity:medium`), #2 "PvP support:
  brainstorm and design" (`state:untriaged`, `severity:medium`), #3 "Leader blocklist"
  (`state:untriaged`, `severity:low`). No `[status]` prefix. No `state:will-not-do`.
- `docs/pending/`: absent (`ls: cannot access 'docs/pending'`).

## E2 — Spec readers bypass Compat (PGE-01)

- `modules/EnvInject.lua:40`: `    local idx = GetSpecialization and GetSpecialization()`
- `modules/EnvInject.lua:42`: `    if idx then specID, _, _, _, role = GetSpecializationInfo(idx) end`
- `core/Compat.lua:6`: `-- prefers C_SpecializationInfo and falls back to the global. modules/EnvInject.lua is the caller.`
- `core/Compat.lua:14`: `Compat.GetSpecialization = CompatLib and CompatLib.GetSpecialization or function() return nil end`
- `docs/ARCHITECTURE.md:43`: `| Spec readers | NS.Compat.GetSpecialization(), NS.Compat.GetSpecializationInfo(i) | core/Compat.lua, through LibKa0s-Compat-1.0; use these rather than the bare globals. |`
- `libs/LibKa0s/Compat.lua:266-267` (library, cited only for its contract): "`C_SpecializationInfo.GetSpecialization` is authoritative where it exists; the deprecated global where it does not."
- `tests/wow_mock.lua:50`: `    M.GetSpecialization     = function() return 1 end` and `:51` `M.GetSpecializationInfo = function(index)` — the mock defines the globals only, so no case runs the path with them absent.
- `.luacheckrc:27`: `  "GetSpecialization", "GetSpecializationInfo",` (permission that lets the bypass lint clean).
- compat states the rule in its own words: "Direct calls to deprecated spec/spell APIs scattered through feature modules are a violation".
- Impact chain: `modules/EnvInject.lua:60-61` set `pgfe_samespec` / `pgfe_sameclassrole` to `0` when the cached keyword is nil, and `modules/Expression.lua:51-52` emit `pgfe_samespec == 0` / `pgfe_sameclassrole == 0`, which are then true for every group. Whether 12.1.0 still ships the deprecated globals was **not verifiable headlessly**; the grade (Medium) reflects that.

## E3 — Vendored payloads and provenance (compliant)

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md
45:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.71.0 (MIT).
$ grep -n 'Bundles \[LibKa0s\]' README.md                      → (none)
$ grep -nE '^## (Libraries|Bundled libraries|Libraries and credits|Credits and libraries|Credits and bundled libraries)' README.md → (none)
$ grep -n 'WoW_Addon_Standard' README.md
5:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
$ grep -nE '^[[:space:]]*[0-9]+[.)][[:space:]]' README.md      → (none)
$ grep -nE '!\[.*\]\(media/logos|<img' README.md                → (none)
```

Diffed against the **tag** the provenance line names, not the sibling's HEAD (`../LibKa0s` HEAD is
`e08dd1d`, tag `v1.71.0` is `cb274a4`):

```
$ git -C ../LibKa0s archive v1.71.0 LibKa0s testkit | tar -x -C <scratch>
$ diff -r <scratch>/LibKa0s libs/LibKa0s      → (empty)   (also empty with --strip-trailing-cr)
$ diff -r <scratch>/testkit tests/_kit        → (empty)
$ diff -r ../LibKa0s/LibKa0s libs/LibKa0s     → exit 0 (HEAD's ship folder is also identical)
$ diff -r ../LibKa0s/testkit tests/_kit       → exit 0
```

`PremadeGroupsFilterExtension.toc:34`: `libs\LibKa0s\LibKa0s.xml` (listed once). Kit revision:
`tests/_kit/framework.lua:20` `Kit.VERSION = 38`. Vendoring commits:
`git log -- libs/LibKa0s tests/_kit` → only `5939cc7 Scaffold addon to the Ka0s standard with stub modules`.

## E4 — Writes outside the seam (PGE-02)

- `docs/ARCHITECTURE.md:86`: `- **Named non-setting state** (architecture-§5), each written outside the seam by one owner:`
- `docs/ARCHITECTURE.md:87`: `  - char.filters — the filter options, **per character**. Owner modules/Filters.lua`
- `docs/ARCHITECTURE.md:93`: `  - profile.panelCollapsed — the attached panel folded to its title bar. Owner modules/Panel.lua.`
- `settings/Schema.lua:6`: `-- settings/Panel.lua and spliced in at load. The filter options are NOT schema rows: they are the`
- Writers, each reached from a control:
  - `modules/Filters.lua:12`: `function Filters.Set(key, value) Filters.Get()[key] = value end`
  - `modules/Filters.lua:16`: `    r[key] = (not r[key]) or nil`
  - `modules/Presets.lua:42-43`: `for k in pairs(live) do live[k] = nil end` / `for k, v in pairs(copy(src)) do live[k] = v end`
  - `modules/Panel.lua:97` (checkboxes): `        NS.Filters.Set(key, self:GetChecked() and true or false)`
  - `modules/Panel.lua:128` (key-level box): `        NS.Filters.Set("keyLevel", n)`
  - `modules/Panel.lua:163` (region chips): `            NS.Filters.ToggleRegion(key)`
  - `modules/Panel.lua:187` (age box): `        if n >= 1 and n <= 240 then NS.Filters.Set("maxAge", n) end`
  - `modules/Panel.lua:312` (minimize button): `    NS.addon.db.profile.panelCollapsed = on and true or false`
- Register: one row only (E1); none cites `architecture-§5`.
- architecture-§5, guard 1 (fetched text): "**A control makes it a preference.** If any control sets the value — a slider, an X/Y field, a dropdown, a checkbox … — it is a preference, not named state, and with no row it is a missing row that needs a row or a register row."
- Compliant beside it: `global.presets` is a registry with one named writer (`modules/Presets.lua` Save/Delete) and no load pass; `global.minimap` is LibDBIcon's table with the Minimap row's closures going through the seam (`settings/Schema.lua:45-57`).

## E5 — No bus above the threshold (PGE-03)

- `docs/ARCHITECTURE.md:99`: `None. The addon defines no AceEvent messages; modules call each other directly through NS.`
- Direct cross-module calls, examples: `modules/Apply.lua:52` `    if targets then NS.Bridge.SetDungeons(NS.Targeting.ToSet(targets)) end`; `modules/Apply.lua:53` `    NS.Bridge.SetExpression(text)`; `modules/Panel.lua:273` `        NS.Apply.Report(NS.Apply.Run{ search = true })`.
- Feature modules (ARCHITECTURE Module Map table, `docs/ARCHITECTURE.md:64-76`): PGF bridge, Regions, Season, Targeting, Expression, Filters, Presets, Env injector, Apply, Panel.
- `Ka0s_` message sweep (authored Lua, `libs/` and `tests/_kit/` excluded): `git ls-files '*.lua' ':!libs' ':!tests/_kit' | xargs grep -nE '(Send|Register)Message\("Ka0s_|"Ka0s_[A-Za-z]+_'` → no hits.

## E6 — Debug coverage (PGE-04)

```
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'NS\.Debug(Once|Changed|AtEnable)?\(|DebugLog:Add'
core/LauncherSetup.lua:59:    debug         = function(tag, message) NS.Debug(tag, message) end,
core/LauncherSetup.lua:60:    debugAtEnable = function(tag, message) NS.DebugAtEnable(tag, "%s", message) end,
core/LifecycleSetup.lua:58:    debug     = function(tag, message) NS.Debug(tag, message) end,
core/PGFE.lua:67:    NS.Debug("Profile", "switched to '%s'", tostring(key or self.db:GetCurrentProfile()))
core/PGFE.lua:72:    NS.Debug("Set", "copied profile '%s' \226\134\146 '%s'", source, self.db:GetCurrentProfile())
core/PGFE.lua:80:        NS.Debug("Set", "reset profile '%s' to defaults (%d rows)", self.db:GetCurrentProfile(), n)
core/PGFE.lua:82:        NS.Debug("Set", "reset profile '%s' to defaults", self.db:GetCurrentProfile())
core/PerfSetup.lua:41:        if NS.DebugLog and NS.DebugLog.Add then NS.DebugLog:Add("Perf", line) else NS.Print(line) end
settings/OptionsSetup.lua:86:    debug = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,
settings/Schema.lua:85:    debug        = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,
settings/Schema.lua:152:            NS.Debug("Set", "reset profile '%s' to defaults (stopped by an error)", db:GetCurrentProfile())
settings/Slash.lua:134:        debug        = function(tag, message) NS.Debug(tag, message) end,
```

Scope: authored shipping Lua (`libs/` and `tests/` excluded). Zero hits in `modules/` and in
`core/PGFBridge.lua`. The refusals that go unlogged are at `modules/Apply.lua:20-23` (`precheck`),
`:30` / `:32` (loading, all timed), `:45` (validation) and `:51` (damaged / too long). Compliant
half: every descriptor that takes `debug` is given the gated sink (the descriptor lines above).

## E7 — The disabled state (compliant stand-down; PGE-05 suite gap; PGE-20)

Three census greps, scope = authored Lua including `tests/` (vendored payloads excluded):

```
$ git ls-files '*.lua' ':!libs' ':!tests/_kit' | xargs grep -nE 'Register(Unit)?Event|RegisterMessage|RegisterBucketEvent'
core/CoreSetup.lua:55-79   (the library-absent SafeRegister* stub bodies and the three library aliases)
core/PGFE.lua:43:        NS.SafeRegisterEvent(self, row[1], row[2], NS.rejectedEvents)
tests/test_harness.lua:69:    NS.addon:RegisterEvent("PLAYER_ENTERING_WORLD", "OnTestEvent")
$ git ls-files '*.lua' ':!libs' ':!tests/_kit' | xargs grep -nE 'Unregister(All)?Events?|UnregisterMessage|UnregisterBucket|CancelTimer|CancelAllTimers|:Cancel\(|SetScript\("OnUpdate", *nil\)'
core/PGFE.lua:112:    for _, row in ipairs(NS.FEATURE_EVENTS) do PGFE:UnregisterEvent(row[1]) end
$ git ls-files '*.lua' ':!libs' ':!tests/_kit' | xargs grep -nE 'ScheduleTimer|CancelTimer|C_Timer|OnUpdate|NewTicker'
(no hits)
```

- The five feature events are declared in `NS.FEATURE_EVENTS` (`modules/EnvInject.lua:77-78`,
  `modules/Panel.lua:422-424`), registered only at `core/PGFE.lua:43` and unregistered at `:112`.
- One latch: `core/LifecycleSetup.lua:55` `    standDown = function() NS.StandDown() end,`; the perf
  hold on the same latch: `core/PerfSetup.lua:36` `    lifecycle = NS.Lifecycle,`; the stored path
  drives the `disabled` hold: `core/PGFE.lua:138`, and the Enable row's hook `settings/Panel.lua:98`
  `        if NS.Lifecycle then NS.Lifecycle:Set(NS.HOLD_DISABLED, not v) end`.
- Unremovable hooks gate: `modules/EnvInject.lua:58` `    if NS.IsStoodDown() then return end`;
  `modules/Panel.lua:393` `    local want = not stoodDown() and NS.Bridge.IsDialogShown() and NS.Bridge.IsDungeonCategory()`.
  Stand-down hides the panel (`modules/Panel.lua:425-427`).
- Slash surface: `settings/Slash.lua:122-123` build `liveVerbs` from `lib.LIVE_VERBS` plus `profile`;
  `diagnostics` is one row at `:46-47`.
- **Suite:** `tests/test_disabled.lua:16`
  `    NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "PLAYER_ENTERING_WORLD", "OnProbeEvent" }` (a probe
  the test adds); `:29` `    assertEqual(m.fireEvent("PLAYER_ENTERING_WORLD"), 0, "no handler runs while disabled")`;
  step 7 is `:63-72`, dispatching only `version` (`:67`) and `list` (`:70`); the latch case `:43-53`
  holds and releases `perf` without writing `enabled`. Falsification comments:
  `grep -rn 'red under' tests/*.lua` → no hit in `tests/test_disabled.lua`.
- AceTimer: `core/PGFE.lua:10` `    "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")`;
  `PremadeGroupsFilterExtension.toc:22` `libs\AceTimer-3.0\AceTimer-3.0.lua`; the timer grep above is empty.

## E8 — TOC position annotations (PGE-06, -07, -08)

- `PremadeGroupsFilterExtension.toc:71`: `# Modules (conventional: each publishes its own NS table and reads others at call time)`
- `:78` `modules\EnvInject.lua` — file scope: `modules/EnvInject.lua:67` `local addon = NS.addon`;
  `:77` `NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "OnActiveSpecChanged" }`;
  `:83` `NS.Bridge.InstallEnvHook(function(env, leaderName) EnvInject.Apply(env, leaderName) end)`.
- `:80` `modules\Panel.lua` — file scope: `modules/Panel.lua:18` `local L = NS.L`; `:412` `local addon = NS.addon`;
  `:422` `NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "CHALLENGE_MODE_MAPS_UPDATE", "OnPanelSeasonData" }`;
  `:432` `NS.Bridge.HookDialog(function() Panel.UpdateVisibility() end)`.
- `:93` `# Conventional: NS.COMMANDS and the slash descriptor; handlers resolve everything at call time.` /
  `:94` `settings\Slash.lua` — file scope: `settings/Slash.lua:10` `local PGFE = NS.addon`; `:11`
  `local L    = NS.L`; `:136` `        get          = NS.SchemaRuntime.Get,`; `:137`
  `        set          = NS.SchemaRuntime.Set,           -- the single write seam`; `:140`
  `        applyDefault = NS.SchemaRuntime.ApplyDefault,`.
- Compliant beside them: every `# Core` load-bearing line and `settings\SchemaSetup.lua`,
  `settings\Schema.lua`, `settings\OptionsSetup.lua`, `settings\Profiles.lua` carry a comment naming
  what resolves (`.toc:41-61`, `:85-95`). `settings\Panel.lua` carries none but is pinned by the
  `OptionsSetup` line's comment naming `Helpers.MasterControls` (the toc-file-§5 worked-example shape).

## E9 — Performance wiring (PGE-09)

- `core/PerfSetup.lua:7`: `-- BUCKETS. None are declared yet, deliberately: a declared bucket no bracket reaches reads 0.000 in`
- `core/PerfSetup.lua:37`: `    buckets   = {},`
- `docs/performance.md:15`: `- **Combat:** no combat path. Apply refuses in combat and nothing else of this addon runs then.`
- `docs/performance.md:27`: `` `tests/perf.lua` is not written yet, so the automated-test runner records `perf` as a skip ("no ``
- `ls tests/perf.lua` → absent. `docs/automated-tests/20261009-082905/manifest.json`:
  `"perf": { "status": "skip", … "skipReason": "no tests/perf.lua — this addon ships no offline scenarios" … }`,
  `"release": "0.1.0"`.
- `.luacheckrc:29`: `  "debugprofilestop",                     -- the perf bracket's clock (performance-§2)` — a
  permission nothing uses.

## E10 — Reset coverage (PGE-10)

```
$ grep -n 'RestoreAllDefaults\|ResetProfile\|resetall\|minimap' tests/test_*.lua
tests/test_slash.lua:25:        "help,config,enable,disable,version,list,get,set,reset,resetall,profile,debug,diagnostics,perf,apply,clear")
tests/test_setup.lua:34:    assertEqual(g.minimap.hide, false)
tests/test_setup.lua:54:    assertTrue(H.FindSchema("global.minimap.shown") ~= nil)
tests/test_setup.lua:63:    assertTrue(H.Get("global.minimap.shown"))
tests/test_setup.lua:64:    H.Set("global.minimap.shown", false)
tests/test_setup.lua:65:    assertTrue(NS.addon.db.global.minimap.hide)
tests/test_setup.lua:66:    assertEqual(NS.addon.db.global.minimap.shown, nil)
```

No case calls `RestoreAllDefaults` or `db:ResetProfile()`. The implementation is compliant:
`settings/Schema.lua:89` `    resetExempt  = { [MINIMAP_PATH] = true },`; `:144`
`    return row.page == "profiles" or not row.sessionOnly`.

## E11 — Launcher and slash enabled accessors (PGE-11, PGE-12)

- `core/LauncherSetup.lua:55`: `    isEnabled  = function() return not NS.IsStoodDown() end,`
- `settings/Slash.lua:129`: `        isEnabled    = function() return not NS.IsStoodDown() end,`
- The Enable row's stored path is `enabled` (`settings/Slash.lua:16` `local ENABLED_PATH = "enabled"`), and
  the latch is down whenever **any** hold is taken (`core/LifecycleSetup.lua:16-18`).
- launcher-§1 (fetched): "Each state is **read on every show, never cached**, through the same accessor
  the Master-controls row reads, so the tooltip cannot disagree with the panel."
- Compliant beside it: label `core/LauncherSetup.lua:49` `    label = "Ka0s Premade Groups Filter Extension",`
  (= README H1); no `NewDataObject`, `OnTooltipShow`, `MenuUtil` or `EasyMenu` in authored Lua (grep empty).

## E12 — Logo files (PGE-13, PGE-14)

```
media/logos/pgfe.logo.128.tga type 2 w 128 h 128 bpp 32     (TGA header bytes 2, 12-15, 16)
media/logos/pgfe.logo.tga     type 2 w 256 h 256 bpp 32
media/logos/pgfe.logo.png     512 x 512                     (PNG IHDR)
```

- `PremadeGroupsFilterExtension.toc:6`: `## IconTexture: Interface\AddOns\PremadeGroupsFilterExtension\media\logos\pgfe.logo.128.tga`
- `core/LauncherSetup.lua:13`: `local ICON = ("Interface\\AddOns\\%s\\media\\logos\\pgfe.logo.128.tga"):format(addonName)`
- `settings/Panel.lua:17`: `local MAIN_LOGO_TEXTURE   = ("Interface\\AddOns\\%s\\media\\logos\\pgfe.logo.tga"):format(addonName)`
- `settings/Panel.lua:18`: `local MAIN_LOGO_SIZE      = 256`
- layout-§4 (fetched): "**`<addon>` is the addon's folder name, lowercased** in both names". options-ui-§5
  (fetched): "display at **300×300**".

## E13 — DEPENDENCIES and the tool (PGE-15)

- `DEPENDENCIES.md:68`: `**One entry: Python 3 with Pillow**, and only for **regenerating** the launcher logo from its`
- `tools/realm_map_diff.py:1`: `#!/usr/bin/env python3`
- `docs/realm-map-maintenance.md:41`: `python3 tools/realm_map_diff.py "<WoW>/_retail_/Interface/AddOns/PremadeRegions/Regions.lua"`
- `grep -n 'realm_map_diff' DEPENDENCIES.md` → no hit.
- Generator-placement check (`git ls-files '*.py' '*.sh'`, vendored excluded) → `tools/realm_map_diff.py`
  only; it writes no tracked file (it prints a diff), so it is not a generator, sits under `tools/` and is
  `.pkgmeta`-ignored (`.pkgmeta:15`).

## E14 — Strings that bypass NS.L (PGE-16)

```
$ git ls-files '*.lua' ':!libs' ':!tests' ':!locales' | xargs grep -nE '(NS\.Print|pout|print)\(\s*"|Tooltip\s*=\s*"|label\s*=\s*"|title\s*=\s*"'
```

User-facing literals among the hits (brand-name `label`/`title` descriptor fields excluded, as they are
the brand string, not prose):

- `settings/Slash.lua:84`: `            NS.Print("unknown command '" .. name .. "'")` (library-absent stub)
- `settings/Slash.lua:150`: `    if not (H and H.OpenOptionsPanel) then return NS.Print("Settings panel is not available.") end`
- `settings/Slash.lua:171`: `        NS.Print("|cffFFFF00/pgfe reset|r takes a setting path: |cffFFFF00/pgfe reset <path>|r "`
- `settings/Slash.lua:188`: `    if not DL then return NS.Print("Debug console not ready yet") end`
- `settings/Schema.lua:106`: `                pout("|cffff0000schema error|r: " .. where .. ": missing or non-string `section`")`
- `settings/Schema.lua:110`: `                pout("|cffff0000schema error|r: " .. where .. ": missing or non-string `label`")`
- `settings/Panel.lua:116`: `        defaultsTooltip = "Reset every Ka0s Premade Groups Filter Extension setting to its default. "`
- `core/DebugLogSetup.lua:61`: `                label   = "Debug console",` (library-absent stub)
- `core/LauncherSetup.lua:21`, `core/PerfSetup.lua:24`, `core/DebugLogSetup.lua:16`, `settings/OptionsSetup.lua:13`,
  `settings/Slash.lua:59`: library-absent lines built from the literal `NS.LIBKA0S_MISSING` (`core/CoreSetup.lua:9-10`).
- `docs/scope.md:33`: `- **Translations.** English only for now; strings go through NS.L so a locale can be added.`
- Dead-key check (every dotted `L.<KEY>` in `locales/enUS.lua` against authored shipping Lua): no unused key.

## E15 — The attached panel's chrome and the visibility row (PGE-17, PGE-19)

- `modules/Panel.lua:338`: `    local f = CreateFrame("Frame", FRAME_NAME, dialog, "PortraitFrameTemplateMinimizable")`
- `modules/Panel.lua:339`: `    f:SetBorder("ButtonFrameTemplateNoPortraitMinimizable")`
- `modules/Panel.lua:342`: `    f:SetFrameStrata("FULLSCREEN")`
- `modules/Panel.lua:320`: `    if f.CloseButton then f.CloseButton:Hide() end` — no close control is built, so the
  close-button grep (`grep -rn 'MakeCloseButton(' … | grep -v '/libs/' | grep -v '/tests/'`) returns only
  the wrapper `core/CoreSetup.lua:87` `    return lib.MakeCloseButton(parent, onClick, addonName)`.
- `SetMovable` sweep (authored Lua): no hits; `UISpecialFrames`: no hits.
- `settings/Panel.lua:87`: `    frameless        = true,`; `:88` `    omit             = { visibility = true },`.

## E16 — Process and stale-line items (PGE-18, PGE-21, PGE-22)

- `gh label list --limit 100` (excerpt): `state:untriaged … #ededed`, `state:done … #5319e7`,
  `state:triaged … #0e8a16`, `state:will-not-do … #000000`, `severity:critical … #b60205`,
  `severity:high … #d93f0b`, `severity:low … #c2e0c6`, `severity:medium … #fbca04`. Mandated:
  `ff0000`, `00ff00`, `ffff00`, `0000ff`, `110000`, `110800`, `001100`, `111100`.
- `grep -c 'PremadeGroupsFilterExtension' standards/ADDONS.md` (fetched) → `0`.
- `CLAUDE.md:24`: `No frozen compliance snapshot yet: the first audit lands in docs/audits/ with plan Task 11. The`

## E17 — Mechanical checks (run, not reasoned)

**Lint** (`.luacheckrc:11` `exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "docs/revendor/", "_dev/", "tests/_kit/" }`; no top-level `ignore`; harness global in `files["tests/"]`, `:38-44`):

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded luacheck .
Total: 0 warnings / 0 errors in 51 files
```

**Headless suite:**

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua
186 passed, 0 failed, 1 skipped, 187 total        (exit 0)
SKIP  diagnostics contract: an addon that opts out lands the report and leaves logging off — this addon keeps the default …
$ ~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua --list   → byte-identical to docs/test-cases.md (CR stripped); Total 186
```

**Complexity** (verbatim invocation, vendored sighted runner, kit 38):

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle
complexity  pass  — 0 warnings (fun rate 0.00), 4144 NLOC / 653 funcs, avg NLOC 4.8, avg CCN 2.0 (max 13), avg tokens 40.0 (recorded, non-gating)
verdict: green
record:  newest bundle 20261009-082905 measured 2c78ddb, 1 commit(s) behind HEAD
```

Drift against `docs/automated-tests/20261009-082905/` and `RESULTS.md:35`
(`2c78ddb | clean | 0.1.0 → 0.1.0 | 0/0 | 51 | 186/1/187 | skip | 4144 | 653 | 4.8 | 2.0 | 13 | 0 | green`):
**none** — identical NLOC, function count, averages and max. `git rev-list --count 2c78ddb..HEAD` → `1`
(the commit that records the bundle). Watch list: empty ("None."), no Accepted entries, so
anti-pattern #53 has no instance. `test_lizard_sighted` wired (`tests/run.lua:108`); manifest
`blindFiles: 0`. No `docs/complexity.md`.

**Line endings** (whole tracked set, no exclusions):

```
$ test -f .gitattributes                                      → present
$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes    → 26:* text=auto eol=crlf
$ grep -nE '^\*\.(sh|py) text eol=lf$' .gitattributes         → 36:*.sh text eol=lf / 37:*.py text eol=lf
$ grep -c ' binary$' .gitattributes                           → 20
$ diff <canonical client-bound body, 84 lines from line-endings-§5> <(head -n 84 .gitattributes | tr -d '\r') → (empty); tail past line 84 → nothing
$ git ls-files -z | xargs -0 -n1 sh -c '…check (e) as AUDIT.md prints it…' _ | wc -l
0
```

The kit's EOL gate is wired (`tests/run.lua:104`) and green.

**Packaging** (AUDIT.md's three loops): (a) nothing printed; (b) `UNACCOUNTED — .git` only (needs no row);
(c) nothing printed.

**Documentation shape:** `ls docs` matches the Documentation map one-for-one (Tier 1 ×6, Tier 2 present
×4 / not applicable ×3 with triggers, Verification and record ×6, Tier 3 ×1); `wc -l docs/ARCHITECTURE.md`
→ 298. compat-layer trigger count, documentation-§3's grep over `core/Compat.lua` → `0`. Commands:
`grep -c '^    {"' settings/Slash.lua` → `16` (matches the map's "16 commands").

**Citation sweep** (live docs and authored files, frozen stores, `libs/`, `tests/_kit/` excluded):
retired `§N.M` notation → `0` hits; 49 distinct `filename-§N` citations range-checked against each
fetched section's `grep -c '^### [0-9]'` → no out-of-range or unknown-file citation.
