# 01 — Findings

**Verdict: blocking issues.** Two High findings land on the shipped 0.1.0 flow. F-001: disabling the
addon after an Apply makes Premade Groups Filter hide every dungeon listing. F-002: the spec read goes
around the Compat seam.

**Resolved scope:** branch `feat/2026-10-09-m-plus-v0.1` against `main` (merge-base `50c1740`, HEAD
`58156ca`). `main` holds only `.gitattributes`, `.gitignore` and `README.md`, so the branch diff
(328 files, +56257/-1) is effectively the whole addon. I reviewed every authored file
(`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'` gives 51 files), plus the TOC, `.luacheckrc`,
`.pkgmeta`, `tools/realm_map_diff.py` and the docs the code cites. `libs/` and `tests/_kit/` are
vendored. They are covered only by the vendor-sync and cross-addon checks below. Repo profile: `wow`,
kind `addon`.

**Standards cross-check:** ran against Ka0s WoW Addon Standard **v2.77.0 (2026-10-07)**, fetched with
`curl` from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`. I followed the index's
Sections list to all 27 section files.

## Measurement run

Every command was run today (2026-10-09) from the repo root through `~/.claude/dev-copilot/bin/ka0s-bounded`.
Output went to the session scratchpad. Nothing was written into the repo.

| Suite | Result | Command |
|---|---|---|
| luacheck | **pass**: 0 warnings / 0 errors in 51 files | `ka0s-bounded luacheck .` |
| Headless tests | **pass**: 186 passed, 0 failed, 1 skipped, 187 total. The skip is the kit's `diagnostics contract: an addon that opts out…`, which is declared and does not apply. | `ka0s-bounded lua5.1 tests/run.lua` |
| Fresh `--list` inventory | **pass**: byte-identical to the committed `docs/test-cases.md` after CR-normalization (`diff <(tr -d '\r' < docs/test-cases.md) <(tr -d '\r' < $scratch/list.md)` printed nothing) | `ka0s-bounded lua5.1 tests/run.lua --list > $scratch/list.md` |
| Offline perf runner | **skipped**: the repo has no `tests/perf.lua`. That gap is the subject of F-006. | n/a |
| Complexity (sighted) | **pass**: 0 warnings, 4144 NLOC / 653 functions, avg CCN 2.0, max CCN 13, blindFiles 0. Kit revision 38, so the run is sighted. | `ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` |
| `make test` | **n/a**: there is no root `Makefile` | n/a |
| Vendor sync | **pass**: `diff -rq libs/LibKa0s ../LibKa0s/LibKa0s` and `diff -rq tests/_kit ../LibKa0s/testkit` both printed nothing. The sibling LibKa0s is at `v1.71.0` on clean `master`, which matches the CLAUDE.md provenance line. | `diff -rq` (both) |
| Cross-addon, class 1 (slash tokens) | **pass**: 24 roots across the 11 roster addons plus this one, no collisions. This addon registers `pgfe` and `premadegroupsfilterextension`. There are no raw `SLASH_*` writes in loaded source (scope: each addon's TOC-derived load list). | the two loops under *Slash-token distinctness*, with `$@` = the 11 roster names + `PremadeGroupsFilterExtension` |
| Cross-addon, class 2 (LibKa0s minors) | **pass**: all 12 report one line, `Bus:2 Compat:1 Core:10 DebugLog:19 Env:2 Item:2 Launcher:5 Lifecycle:3 Media:4 Options:28 Perf:14 Pool:3 Schema:2 Slash:20 Widgets:12` | the class-2 loop |
| Cross-addon, class 3 (payload bytes) | **pass**: `diff -rq PremadeGroupsFilterExtension/libs/LibKa0s <each>/libs/LibKa0s` printed nothing for all 12. The reference copy is this addon's. | the class-3 loop |
| Cross-addon, class 4 (`## Interface:`) | **pass**: `120100`, uniform across all 12 | the class-4 loop |

Committed artifacts compared with today's run:
- `docs/test-cases.md`: agrees with today's run (see above). The README badge `Tests-186/186_passing` matches 186 passed, and the skip sits outside Total as the file's own header requires.
- `docs/automated-tests/RESULTS.md`: the newest bundle `20261009-082905` measured `2c78ddb`, one commit behind HEAD. HEAD `58156ca` only records that bundle. Its complexity figures (4144 / 653 / max 13 / 0 warnings) equal today's run, so the record is behind HEAD only on paper.
- `docs/performance.md`: no offline scenarios exist, so there is nothing to compare.
- Cross-addon baseline: the overlay's recorded table (2026-09-23, LibKa0s v1.56.0) is a **stale brief**, not drift. The tag has moved to v1.71.0, and today's figures are recorded above. This addon is **not** a row in `WowAddonStandards/standards/ADDONS.md` (11 rows). I ran the pass over 12 addons so that its tokens were included. Adding it to the roster is a standards-repo matter, not a finding here.

Census scope note: every count in this file uses the default scope
(`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`, which gives 51 files) unless it says otherwise. No
authored file is in layout-§1's 1000–1500 band (`… | xargs -0 wc -l | awk '$2!="total" && $1>1000'`
printed nothing). The largest is `defaults/Realms.lua`, at 559 lines.

## High

### F-001: Disabling the addon after an Apply makes PGF hide every dungeon listing, and the addon refuses the only in-addon remedy `[correctness]`

- **Where:** `modules/EnvInject.lua:58` `if NS.IsStoodDown() then return end`;
  `modules/Expression.lua:49` `c[#c + 1] = "( " .. table.concat(opts.regions, " or ") .. " )"`,
  `:51` `if opts.noSameSpec then c[#c + 1] = "pgfe_samespec == 0" end`,
  `:52` `if opts.noSameClassRole then c[#c + 1] = "pgfe_sameclassrole == 0" end`.
  Documented as a limitation at `docs/ARCHITECTURE.md:232-233` ("Expressions that reference `pgfe_*` evaluate to nil while the addon is disabled … Clear before disabling"). The design spec promises more at `docs/superpowers/specs/2026-10-09-m-plus-v0.1-design.md:147-148`: "the user is told to Clear or re-enable". No code path tells the user anything.
- **Problem:** the managed block is persisted inside PGF's own state (`PremadeGroupsFilterState`). Once the addon stands down, the env hook stops writing `pgfe_samespec` / `pgfe_sameclassrole`, and stops writing the region keys when PremadeRegions is absent. PGF's per-result evaluator (`Modules/Expression.lua` `DoesPassThroughFilter`: `setfenv(func, env)`, no `__index` fallback) then sees `nil == 0`, which is `false`, and `( oce )`, which is `false` because PGF's own `PutPremadeRegionInfo` resets every region key to `false`. Every listing is filtered out. Meanwhile `apply`/`clear` are not live verbs (`libs/LibKa0s/Slash.lua:123-126` `LIVE_VERBS` omits them), so `/pgfe clear` returns the disabled line, and the attached panel with its Clear button is hidden.
- **Impact:** the player switches the addon off and PGF's Dungeons search returns **zero results** from then on, with no message. The only way back is to re-enable, Clear, then disable, or to hand-edit PGF's expression. Unloading the addon from the AddOns list has the same effect.
- **Reachability:** any player who has applied with *Server regions* (without PremadeRegions installed), *No one with my spec* or *No one with my class + role* ticked, and then disables through the General checkbox, `/pgfe disable`, the launcher's *Enabled* entry, or a switch to a profile with `enabled = false`. This is a normal session on the default install.
- **Evidence (measured today):** a headless probe on the real harness (`$scratch/probe.lua`, built from `tests/loader.lua` and `tests/wow_mock.lua`) applied `noSameSpec + regions{oce}` and got the expression `( ( oce ) and pgfe_samespec == 0 )`. It then evaluated that expression PGF's way against the env produced by PGF's `PutPremadeRegionInfo`. Enabled: `true`. After `/pgfe disable`: `false`. `/pgfe clear` printed `Ka0s Premade Groups Filter Extension is disabled — enable it with /pgfe enable` and the block was still present.
- **Coverage note:** `tests/test_envinject.lua:73-80` ("stood down → hook is a no-op") asserts `assertNil(env.pgfe_samespec)`. It pins the very behavior that causes the defect. No case evaluates the merged expression against the env.
- **Fix direction (compliant):** make the managed block neutral when this addon is not running, rather than writing anything at stand-down. The hook already sets a sentinel such as `pgfe_on = true` when it is not stood down. Merge would emit `( not pgfe_on or ( <clauses> ) )`, which yields `true` whenever the hook did not run, whether the addon is stood down or not loaded at all. The `hooksecurefunc` body still gates and returns while stood down (slash-commands-§7, *the one sanctioned exception*). Correct the two doc lines in the same change.

### F-002: The player's spec is read from the global spec APIs, bypassing `NS.Compat`, so *No one with my spec* depends on deprecated globals `[deprecated-api]`

- **Where:** `modules/EnvInject.lua:40` `local idx = GetSpecialization and GetSpecialization()` and `:42` `if idx then specID, _, _, _, role = GetSpecializationInfo(idx) end`. The seam that should own the calls has zero authored callers: `core/Compat.lua:14` `Compat.GetSpecialization = CompatLib and CompatLib.GetSpecialization or function() return nil end`, and `:17`. Its own header says "modules/EnvInject.lua is the caller", which is false. Lint config: `.luacheckrc:27` `"GetSpecialization", "GetSpecializationInfo",` whitelists the globals, so lint cannot flag the bypass.
- **Problem:** compat says outright that every deprecated-API call MUST route through `Compat`, and that "direct calls to deprecated spec/spell APIs scattered through feature modules are a violation". `libs/LibKa0s/Compat.lua:266-275` prefers `C_SpecializationInfo.GetSpecialization` and treats the global as the deprecated fallback. The test mock defines only the globals (`tests/wow_mock.lua:50-51`), so the suite cannot tell the two routes apart.
- **Impact:** when the client stops providing the deprecated globals, there are two outcomes. If `GetSpecialization` is gone, `player.spec` is `nil`, `pgfe_samespec` is always `0`, and both composition filters silently pass every group. If only `GetSpecializationInfo` is gone, `OnEnable` raises at `:42` before the settings category, the launcher and the lifecycle latch come up (`core/PGFE.lua:127-139`).
- **Reachability:** every player, at every login (`OnEnable`) and on every spec change. **Unverified:** I could not confirm against a 12.1 client whether the globals still exist today. The defect in kind (a compat-routing violation with a silent failure mode) is certain. The removal date is not.
- **Fix direction (compliant):** call `NS.Compat.GetSpecialization()` / `NS.Compat.GetSpecializationInfo()` from `EnvInject.RefreshPlayer`. Drop `GetSpecialization`/`GetSpecializationInfo` from `.luacheckrc` `read_globals`. Seed the mock's `C_SpecializationInfo` so a test proves the namespaced rung is the one taken.

## Medium

### F-003: The key-level and max-age boxes store the in-range prefix of an out-of-range entry `[ux]`

- **Where:** `modules/Panel.lua:114-118` (`numberBox`'s `OnTextChanged`, `:117` `if n then accept(n) end`), `:127` `if not NS.Targeting.IsValidLevel(n) then return end`, `:187` `if n >= 1 and n <= 240 then NS.Filters.Set("maxAge", n) end`. There is no `OnEditFocusLost` re-sync.
- **Problem:** the handler fires on every keystroke. Typing `45` stores `4` after the first keystroke and then silently ignores `45`. The box keeps showing `45` while `keyLevel` is `4`. The same happens with `250` in the age box, which stores `25`.
- **Impact:** Apply targets dungeons and builds the experienced-leader clause at a level the player did not type. The readout re-colors for level 4, but nothing marks the box as invalid.
- **Reachability:** any player who types a key level above 40 or an age above 240 into the attached panel.
- **Evidence:** the probe typed `4`, then `45`, and got `keyLevel 4`, with the box showing `45`.
- **Coverage note:** `tests/test_panel.lua:132` `box.__text = "99"; box:__fire("OnTextChanged", true)` sets the whole string in one event, so it can never follow the keystroke path that stores the prefix.
- Severity: graded Medium, not High. The bad state needs an invalid entry and the readout partly shows it.

### F-004: Apply while PGF's dialog is minimized reports "Applied" and searches, but the filter is not active `[correctness]`

- **Where:** `core/PGFBridge.lua:57` (`IsDungeonCategory` is true for the category, minimized or not), `:118` `if d and p and d.activePanel == p then` (Commit skips Init/Trigger when minimized), `modules/Apply.lua:56` `if opts and opts.search then NS.Bridge.Search() end`, `:57` `return true, "MSG_APPLIED", …`.
- **Problem:** when the dialog is minimized, PGF's `SwitchToPanel` makes `panels.mini` the active panel (PGF `UI/Dialog.lua:190-194`), and `PGF.DoFilterSearchResults` filters with `activePanel:GetFilterExpression()` (`UI/Dialog.lua:245-248`). The search the Apply button fires therefore runs with the mini panel's expression. The dungeon state written by Apply only takes effect after the player maximizes the dialog.
- **Impact:** the core flow prints `Applied: N dungeon(s) targeted…` and shows a result list the new filters were never applied to.
- **Reachability:** any player who uses PGF's minimize button on the Dungeons category, which keeps the attached panel visible, and then presses Apply or types `/pgfe apply`.
- **Evidence:** a probe with `dialog.activePanel = { name = "mini" }` returned `true, MSG_APPLIED` with `refresh clicks: 1, trigger: 0`. `tests/test_bridge.lua:60-64` covers Commit alone, never the Apply-level message or the search.

### F-005: `tests/test_disabled.lua` does not meet slash-commands-§7's conformance shape, and its probe displaces a real handler `[tests]`

- **Where:** `tests/test_disabled.lua:16` `NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "PLAYER_ENTERING_WORLD", "OnProbeEvent" }`, `:29` `assertEqual(m.fireEvent("PLAYER_ENTERING_WORLD"), 0, "no handler runs while disabled")`.
- **Problem:** the central assertion is on one event the test itself injected. It never checks the addon's own registration set by count and by name, never asserts `R_on` is non-empty, and never fires every registered event while disabled (step 6). Step 9 (a setting changed while disabled) and step 10 (both hold orders) are missing, and no case carries the `-- red under:` falsification comment testing-§12 requires on steps 3, 6 and 10. AceEvent keeps one handler per event per object, so the probe row also **replaces** `modules/Panel.lua`'s own `PLAYER_ENTERING_WORLD → OnPanelEnteringWorld` registration inside the test instance. The suite therefore runs against wiring the shipped addon does not have.
- **Impact:** a regression that left any of the five real feature events registered while disabled would stay green.
- **Reachability:** only the test inventory. The shipped stand-down (`core/PGFE.lua:111-114`) is correct today.

### F-006: The per-search-result env hook, the addon's only hot path, is unmeasured `[perf]`

- **Where:** `core/PerfSetup.lua:37` `buckets   = {},`; there is no `tests/perf.lua`. Per-result work: `modules/EnvInject.lua:50` `for _, k in ipairs(NS.Regions.ALL_KEYS) do env[k] = false end`, `modules/Regions.lua:28` `return (realm:lower():gsub("[%s%p]", ""))` (two string allocations per result), and `GetCurrentRegion()` per result (`Regions.lua:32`).
- **Problem:** the hook runs once per search result on every PGF filter pass, and nothing counts its cost. The 0.1.0 bundle commit (`58156ca`) itself records that "the tag's release gate stays open until the env-hook perf scenarios exist".
- **Impact:** a per-result allocation that cannot be measured. Its cost is **unverified**: there is no runner and no capture.
- **Reachability:** every PGF search while the addon is enabled.

### F-007: `Presets.Load` replaces the live filter table wholesale, so a preset missing a key deletes that key from `char.filters` `[design]`

- **Where:** `modules/Presets.lua:42` `for k in pairs(live) do live[k] = nil end`, `:43` `for k, v in pairs(copy(src)) do live[k] = v end`. Readers index unguarded: `modules/Filters.lua:16` `r[key] = (not r[key]) or nil` and `modules/Panel.lua:381` `… paintChip(chip, filters.regions[key])`.
- **Problem:** presets are account-wide and survive version upgrades. A preset saved before a filter key existed loads with that key absent, and AceDB does not backfill until the next login. A preset without `regions` raises in `Panel.Refresh`.
- **Impact:** after the first schema change to `char.filters`, loading an older preset can raise on the panel refresh or leave an option `nil`. The `NS.MIGRATIONS` runner does not touch `global.presets`.
- **Reachability:** nobody today, since 0.1.0 is the first shape. It becomes live with the first release that adds a `char.filters` key.

## Low

### F-008: The range box stops following the key level after the first Apply `[ux]`

- **Where:** `modules/Panel.lua:39` `return NS.Apply.LastRange or NS.Targeting.RangeText(NS.Filters.Get().keyLevel)`; `modules/Apply.lua:55` `Apply.LastRange = NS.Targeting.RangeText(f.keyLevel)`.
- **Problem:** the level box's accept handler calls `updateRange(f)` (`Panel.lua:130`), but once a successful Apply has set `LastRange` for the session, the field keeps showing the old range.
- **Reachability:** any player who changes the level after an Apply and copies the range before applying again.

### F-009: The Apply message reports a dungeon count that may not match what was ticked `[ux]`

- **Where:** `modules/Apply.lua:57` `return true, "MSG_APPLIED", targets and #targets or 0, Apply.LastRange`; `locales/enUS.lua:60` `L.MSG_APPLIED      = "Applied: %d dungeon(s) targeted, key range %s."`; `core/PGFBridge.lua:88` `return n` (the rows actually ticked), discarded at `Apply.lua:52`.
- **Problem:** with key targeting off, the message reads "0 dungeon(s) targeted, key range 10-10" (seen in today's probe). With targeting on, it counts the computed targets, not the PGF rows that were ticked.
- **Reachability:** any player who applies with *Untimed dungeons at key level* unticked.

### F-010: A profile switch does not refresh the attached panel `[correctness]`

- **Where:** `core/PGFE.lua:53-63` (`reloadProfile` refreshes the settings panel and the latch; `:57` `if H and H.RefreshAll then H.RefreshAll() end`) but never calls `NS.Panel.Refresh()`. `profile.panelCollapsed` is per-profile (`defaults/Profile.lua:17`).
- **Reachability:** a player who switches profile while PGF's dialog is open. The panel corrects itself on the next dialog show.

### F-011: The env hook runs inside PGF's per-result loop with no guard `[error-handling]`

- **Where:** `modules/Regions.lua:50` `local realm = leaderName:match("%-(.+)") or GetRealmName()`; `modules/EnvInject.lua:57-62`.
- **Problem:** any error in the hook aborts PGF's whole filter pass, because `hooksecurefunc` post-hooks propagate errors to the caller. `leaderName` is assumed to be a string. Whether 12.x ever hands an LFG leader name over as a secret value is **unverified**. PGF itself passes the same value to PremadeRegions' string matching.
- **Reachability:** none known today.

## Upstream findings

None. Vendor sync and all four cross-addon classes are clean, and no defect was traced into `libs/` or `tests/_kit/`.
