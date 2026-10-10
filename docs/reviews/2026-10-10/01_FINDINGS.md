# 01 — Findings (review, 2026-10-10)

**Verdict: minor issues.** Nothing Critical or High. Seven Medium findings: one stops the complexity suite (and so the release gate) from passing, one may loop network requests in an off-season, one lets a hand-edited expression end up with unbalanced parentheses, and the rest are design, error-handling and locale drift. Eleven Low.

**Resolved scope:** `all`, the whole addon at `5decd65` on `fix/2026-10-10-audit-review` (clean tree). Every authored file under `core/ defaults/ locales/ modules/ settings/ tests/ tools/` plus the TOC, `.luacheckrc`, `.pkgmeta`, `.gitattributes` and `docs/`. `libs/` and `tests/_kit/` were read only as vendored code, and their defects are routed `[upstream]`. Step 0b's measurement ran over the whole addon.

**Standards cross-check:** Ka0s WoW Addon Standard **v2.78.0** (2026-10-09). I fetched the index with `curl -fsSL https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master/standards/STANDARDS.md`. The section files were read from the sibling checkout `../WowAddonStandards` at `e6ab2b8`, whose index reports the same version.

## Measurement run

Every command ran from the repo root through `~/.claude/dev-copilot/bin/ka0s-bounded` (shown as `kb`), with output to the session scratchpad. Nothing was written into the repo except this bundle.

| Suite | Result | Command | Counts |
|---|---|---|---|
| luacheck | **pass** | `kb luacheck .` | 0 warnings / 0 errors in 58 files |
| Headless tests | **pass** | `kb lua tests/run.lua` (Lua 5.1.5) | 325 passed, 0 failed, 1 skipped, 326 total. The skip is the declared `diagnostics contract: an addon that opts out ...` case |
| Fresh `--list` inventory | **pass (no drift)** | `kb lua tests/run.lua --list > $scratch/list.md`, then `diff <(tr -d '\r' < docs/test-cases.md) <(tr -d '\r' < $scratch/list.md)` | Empty diff. The committed Total of 325 and the README badge `325/325` both match |
| Offline perf runner | **skipped (no `tests/perf.lua`)** | n/a | The addon ships no offline scenarios. Bracket zero-overhead is **unverified** (no bracket exists yet either) |
| Complexity (sighted, kit rev 38) | **fail (amber)** | `kb bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` | `lizard 1.24.0` **raised `TypeError: sequence item 0: expected str instance, NoneType found`** on the sighted shadow of `modules/RegionTags.lua`. The runner then reported "lizard blind in 54 file(s)" (every authored file, 0 functions listed) and a garbled summary (`str warnings (fun rate instance,), TypeError: NLOC ...`). See F-001 and F-007 |
| Complexity, scratch reproduction | informational | the runner's two steps by hand in scratch (`lizard_sighted.lua shadow`, then the fixed `lizard -l lua -L 1500 -x ./libs/* -x ./tests/_kit/* .`) | Per-file run: only `modules/RegionTags.lua` crashes. With the `for ... in pairs({ function ... })` literal hoisted into a local **in the scratch shadow only**: 1064 functions, **0 warnings, max CCN 14** (`reloadProfile@53-72@./core/PGFE.lua`), parity clean (0 blind files) |
| `make test` | not applicable | n/a | No root `Makefile` |
| Vendor sync | **pass** | `diff -rq libs/LibKa0s ../LibKa0s/LibKa0s` and `diff -rq tests/_kit ../LibKa0s/testkit` | Both empty. `../LibKa0s` is at `aad51fa`, newest tag `v1.71.0`, which matches the `CLAUDE.md` provenance line |
| Cross-addon (4 classes) | **pass (clean)** | run from `..` over the 11 `ADDONS.md` rows **plus this addon** (12), scoped to each TOC-derived load list | Class 1: 24 slash roots, 0 duplicates, 0 raw `SLASH_*` (this addon has `pgfe`, `premadegroupsfilterextension`). Class 2: one line across 12 (`Bus:2 Compat:1 Core:10 DebugLog:19 Env:2 Item:2 Launcher:5 Lifecycle:3 Media:4 Options:28 Perf:14 Pool:3 Schema:2 Slash:20 Widgets:12`). Class 3: zero `diff -rq` output against AbsorbTracker's copy. Class 4: `## Interface: 120100`, uniform. The brief's baseline (v1.56.0) is behind the measured tag v1.71.0, so the baseline is stale, not drifted. This addon is not on the roster (F-018) |

**Committed artifacts that disagree with today's run**

- `docs/automated-tests/RESULTS.md` and the bundle `20261009-082905` (`manifest.json`: sha `2c78ddb`, **38 commits behind HEAD**) record tests 186/187 and complexity **pass** (653 functions, max CCN 13, 0 blind). Today it is 325/326 with complexity **fail**. `modules/RegionTags.lua` did not exist at `2c78ddb`. This is stale, not non-compliant: the record regenerates at release.
- `docs/test-cases.md`: agrees.
- `docs/performance.md`: nothing fresh to compare it against, because the perf runner is absent.

---

## Medium

### F-001 — A function literal in a `for ... in` header crashes `lizard`, so the complexity suite cannot pass `[complexity]` `[tests]`
- **Where:** `modules/RegionTags.lua:64-67`, quoted: `for name, fn in pairs({` / `LFGListSearchEntry_Update = function(...) RegionTags.OnSearchEntryUpdate(...) end,` / `LFGListApplicationViewer_UpdateApplicantMember = function(...) RegionTags.OnApplicantMemberUpdate(...) end,` / `}) do`
- **Problem:** `lizard 1.24.0` raises a Python `TypeError` on the sighted shadow of this file (measured today, per file). The crash aborts the whole run, so no file is measured.
- **Impact:** The complexity suite records `fail` with 54 blind files. `automated-tests-§3` says that blocks the tag the same way a skip does, so 0.1.0 cannot pass its release gate. Today the cost is CCN ceilings nobody can see. The scratch hoist shows max CCN 14 and 0 warnings.
- **Reachability:** Only the maintainer running the complexity suite or `/dev-copilot:bump-version`, every run from the commit that added `RegionTags.lua` (`e6615db`). No runtime effect.
- **Measurement:** complexity runner (above). The per-file crash is reproduced in scratch, and the fix direction is proven in scratch (1064 functions, parity clean).
- **Fix direction:** hoist the literal table into a file-local before the loop, which is the remedy `automated-tests-§3` names.

### F-002 — The readout can re-request season map info on every map-info event, forever `[perf]` `[correctness]` (**unverified in client**)
- **Where:** `modules/Panel.lua:165-170` (`if not dungeons then` ... `if C_MythicPlus.RequestMapInfo then C_MythicPlus.RequestMapInfo() end`) and `modules/Panel.lua:866-876` (`function addon.OnPanelSeasonData()` ... `updateReadout(f)`). The handler is registered on `CHALLENGE_MODE_MAPS_UPDATE` at `modules/Panel.lua:882`.
- **Problem:** `updateReadout` calls `RequestMapInfo()` whenever `Season.GetDungeons()` answers nil. The `CHALLENGE_MODE_MAPS_UPDATE` that request produces runs `updateReadout` again. `GetDungeons` answers nil whenever `C_ChallengeMode.GetMapTable()` is empty (`modules/Season.lua:31`), so if the map table stays empty the panel keeps asking the server.
- **Impact:** A server request every round trip for the whole session, from a panel that only wanted to say "loading".
- **Reachability:** Any player who opens PGF on the Dungeons category once in a session where the client's M+ map table is empty. That is expected between seasons and **not verified in client**. In season the table fills after the first response and the loop ends after one round.
- **Coverage:** `tests/test_panel.lua:288-291` pins loading → event → loaded. No case pins "an event received while still empty does not request again". The mock's `RequestMapInfo` (`tests/wow_mock.lua:80`) is a no-op that records nothing.

### F-003 — `Expression.Strip` accepts a wrapped block whose close marker was deleted, so the result has unbalanced parentheses `[correctness]`
- **Where:** `modules/Expression.lua:78-80` (`elseif line:find(P_CLOSE) then` / `if not (lines[i + 1] and lines[i + 1]:match("^%s*%)%s*$")) then return text, false end`) and the wrapped form at `:104-105` (`body .. " and (", ... user, Expression.MARK_CLOSE, ")"`).
- **Problem:** Damage detection covers a begin without an end, and a close not followed by `)`. It does not cover a wrapped block (`... and (`) whose `-- [pgfe] close` line is gone while its `)` remains. Strip keeps the orphan `)` as user text and reports `ok`. Probed in scratch: re-Merge gives `( not pgfe_on or ( age <= 5 ) ) and ( mprating > 1000 ) )` after normalization, and Clear leaves `mprating > 1000\n)`.
- **Impact:** PGF gets an expression with an unbalanced `)` and cannot parse it. Apply and Clear both report success, so the player is never told.
- **Reachability:** Only a player who hand-edits PGF's Advanced Filter Expression box and deletes the `-- [pgfe] close` comment line (a visible line in the box) but not the `)` below it.
- **Coverage:** `tests/test_expression.lua` has one damage case, `:59` (begin without end). Neither the close-without-`)` case nor this orphan case is tested.

### F-004 — Two modules read PGF's private namespace outside the bridge, and `Bridge.Check` does not check those seams `[design]`
- **Where:** `modules/Season.lua:22-23` (`local pgf = PremadeGroupsFilter and PremadeGroupsFilter.Debug` / `... pgf.C.MAP_ID_TO_KEYWORDS[mapID]`) and `modules/EnvInject.lua:47-49` (`local pgf = PremadeGroupsFilter and PremadeGroupsFilter.Debug` / `... pgf and pgf.C and pgf.C.SPECIALIZATIONS)`).
- **Problem:** This contradicts `docs/ARCHITECTURE.md:202` ("Every touch of PGF internals is in `core/PGFBridge.lua`, nil-guarded, and read at call time."), the module-map row at `:79`, and the `.luacheckrc:29-30` comment (which names `core/PGFBridge.lua, modules/EnvInject.lua and modules/Diagnostics.lua` and not `Season.lua`). `C.SPECIALIZATIONS` and `C.MAP_ID_TO_KEYWORDS` are not in `SEAMS` (`core/PGFBridge.lua:27-35`).
- **Impact:** If PGF renames `C.SPECIALIZATIONS`, `player.spec` becomes nil. `pgfe_samespec` is then always 0, and the *no same spec* exclusion silently passes every group. The panel never shows "PGF version not supported". A renamed `MAP_ID_TO_KEYWORDS` only degrades the readout to initials.
- **Reachability:** Any player once a PGF release renames either constant. Not reachable on PGF 7.6.2, the version the seams were read against.

### F-005 — The EllesmereUI paint has no guard against a facade without a primitive, and a failure leaves a half-painted panel that is never retried `[error-handling]`
- **Where:** `modules/EUISkin.lua:327-330` (`applied = true` / `local f = NS.Panel.frame` / `local n = paintShell(f) + paintBody(f)` / `NS.Panel.Refresh()`) and `modules/EUISkin.lua:385-390` (`local function onFacade(facade)` / `S = facade` ... `EUISkin.TryApply()`).
- **Problem:** `onFacade` checks neither `S.apiVersion` nor whether the twelve primitives the paint calls exist (`Shell`, `FadeNineSlice`, `FadeRegions`, `Checkbox`, `EditBox`, `Dropdown`, `Button`, `StateButtonLabel`, `Font`, `White`, `GetAccentColor`, `GetFont`). `applied` is set before the paint, and the paint is not pcall-guarded.
- **Impact:** On a facade missing one primitive, the paint raises partway through. The panel stays half-painted for the session, because `applied` already reads true. On the `Panel.Create` path (`modules/Panel.lua:807`) the error also escapes `Panel.UpdateVisibility` before `f:SetShown`, so that first show of the panel is lost.
- **Reachability:** A player with every gate condition met whose EllesmereUI build ships a facade without one of the twelve primitives (an older or newer EllesmereUI than 9.4).

### F-006 — Twelve locale keys are missing from `enUS.lua`, and one `enUS` key is read by nothing `[locale]`
- **Where:** Keys used but not defined in `locales/enUS.lua`: six `L["..."]` keys at `core/EUIBridge.lua:109-114` (the three *Premade Groups Filter - EllesmereUI Skin is ...* labels and their three hints) and six at `settings/Panel.lua:168, 211, 212, 213, 214, 216` (the link label, the four `CONDITION_TIPS` and `STATE_TIP`). The dead key is at `locales/enUS.lua:166`: `L["Install and enable Premade Groups Filter - EllesmereUI Skin, and turn on PremadeGroupsFilter in EllesmereUI's Third-Party Addons list."] =`.
- **Problem:** `localization-§3`: "`enUS.lua` **MUST NOT** accumulate keys nothing reads". The missing keys render in English only through the metatable fallback, so `enUS.lua` no longer lists the addon's strings.
- **Impact:** A translator working from `enUS.lua` misses 12 strings, and the dead key overstates what is covered (documentation-§5).
- **Reachability:** No runtime effect on enUS clients, since the fallback renders the same text. It affects every future locale file and anyone using `enUS.lua` as the string inventory.
- **Census:** I took the TOC-derived load list minus `libs/` and `locales/enUS.lua` (`tr -d '\r' < *.toc | grep -iE '\.lua$' | grep -v '^#' | grep -v '^libs' | sed 's|\\|/|g' | grep -v enUS`) and compared `grep -ohE 'L\["[^"]+"\]'` over it with `grep -ohE '^L\["[^"]+"\]' locales/enUS.lua` using `comm`. Result: 12 used-but-undefined and 1 defined-but-unused. Dynamic `L[key]` / `L[prefix .. KEY]` lookups (`MSG_*`, `REGION_TIP_*`, `PLAYSTYLE_*`) were checked by hand and all resolve.

### F-007 — `[upstream]` LibKa0s test kit: the complexity runner ignores `lizard`'s exit status and parses a traceback as its summary
- **Owning library:** LibKa0s, `testkit/run-automated-tests.sh` (vendored here as `tests/_kit/run-automated-tests.sh`, kit revision 38).
- **Where:** `tests/_kit/run-automated-tests.sh:508` (`raw="$(cd "$CX_TMP/src" && bounded lizard -l lua -L 1500 -x "./libs/*" -x "./tests/_kit/*" . 2>&1)"`) and `:522` (`footer="$(printf '%s\n' "$raw" | tail -1)"`).
- **Problem:** When `lizard` crashes, the last line of its traceback (`TypeError: ...`) is read as the eight-field footer. The console then prints `str warnings (fun rate instance,), TypeError: NLOC / expected funcs ...`, and parity reports every file blind (54/54) instead of naming the one file that crashed.
- **Impact:** The run is correctly `fail`, but the diagnosis is wrong. A maintainer is sent to look at 54 files for a hoist, when one file has the problem. Any `manifest.json` written from such a run carries non-numeric fields.
- **Reachability:** Any maintainer whose tree crashes `lizard`. That is this repo, today.
- **Remediation (not a local edit):** fix in the LibKa0s repo: detect a non-zero `lizard` exit or a missing footer, and report "lizard crashed" with the file that crashed (a per-file retry finds it). Bump the kit revision, then re-vendor `tests/_kit/` into this addon as its own commit. Do **not** edit `tests/_kit/` here.

## Low

### F-008 — `test_disabled` checks one probe event and two verbs, not the addon's real registrations `[tests]`
- **Where:** `tests/test_disabled.lua:24-32` (`assertEqual(m.fireEvent("PLAYER_ENTERING_WORLD"), 0, "no handler runs while disabled")`) and `:63-72` (`version` and `list` only).
- **Problem:** The central assertion is the dispatch count of one event. The test does not walk the seven real `NS.FEATURE_EVENTS` rows by name. `config` and the bare `/pgfe` are not asserted to keep answering while disabled (`slash-commands-§2`).
- **Impact:** A future feature event registered outside `FEATURE_EVENTS` would stay live while disabled, and this suite would stay green.
- **Reachability:** Test inventory only. The shipped stand-down unregisters the whole list (`core/PGFE.lua:120-123`).

### F-009 — With key targeting off, Apply still reports a "key range" the panel no longer shows, and `Apply.LastRange` has no production reader `[ux]` `[dead-code]`
- **Where:** `modules/Apply.lua:61-63` (`Apply.LastRange = NS.Targeting.RangeText(f.keyLevel)` ... `return true, "MSG_APPLIED_NO_TARGETING", Apply.LastRange`) and `locales/enUS.lua:61` (`"Applied (dungeon checkboxes left as they were), key range %s."`).
- **Problem:** Since `603a254`, the copy box is empty while *Untimed dungeons at key level* is off ("there is no key level to search for"), yet the chat line names `10-10`. `Apply.LastRange` is read only by `tests/test_apply.lua:38`.
- **Impact:** The chat and the panel disagree about whether there is a range to search.
- **Reachability:** Any player who presses Apply (or types `/pgfe apply`) with key targeting off.

### F-010 — Hard-coded English in user-facing output `[locale]`
- **Where:** `settings/Slash.lua:150` (`NS.Print("Settings panel is not available.")`), `:171-172` (the `/pgfe reset` usage line), `:188` (`"Debug console not ready yet"`), and `settings/Panel.lua:251-252` (`defaultsTooltip = "Reset every Ka0s Premade Groups Filter Extension setting to its default. " .. "Asks for confirmation."`).
- **Impact:** These strings bypass `NS.L`, so a future locale cannot translate them.
- **Reachability:** Any player who types `/pgfe reset` with no path, or hovers the General page's Defaults button. The other two are degraded paths.

### F-011 — The panel's tooltip `OnLeave` returns early while stood down, so it never hides the tooltip it showed `[ux]`
- **Where:** `modules/Panel.lua:96-99` (`widget:HookScript("OnLeave", function()` / `if stoodDown() then return end` / `GameTooltip:Hide()`). The same pattern for the glyph alpha is at `modules/EUISkin.lua:236-239`.
- **Problem:** Hiding a tooltip writes nothing, so the stand-down gate does not need to cover it. If the latch drops while a control is hovered, the stand-down hides the panel, `OnLeave` fires with `stoodDown()` true, and the hover handler skips its own `Hide`.
- **Reachability:** A player hovering a panel control at the moment the addon stands down, for example when a perf capture's suspend arm starts. Whether GameTooltip clears itself when its owner hides is unverified in client.

### F-012 — The skin's scale events are registered for every player, with or without EllesmereUI `[perf]`
- **Where:** `modules/EUISkin.lua:365-366` (`{ "UI_SCALE_CHANGED", "OnEUISkinScale" }`, `{ "DISPLAY_SIZE_CHANGED", "OnEUISkinScale" }`).
- **Impact:** A registration and a no-op dispatch on every scale change, for players who can never be skinned. Negligible cost, but it widens the stood-up surface `test_disabled` has to cover.
- **Reachability:** Every player, on every UI-scale or display-size change.

### F-013 — The diagnostics report states what is declared, not what is running `[observability]`
- **Where:** `modules/Diagnostics.lua:57-62` (`for i, row in ipairs(NS.FEATURE_EVENTS or {}) do names[i] = row[1] end` / `out:joined(TAG, "feature events", names)`). Related silent skips: `modules/EnvInject.lua:89` ignores `Bridge.InstallEnvHook`'s boolean, and `modules/RegionTags.lua:68` skips a missing Blizzard painter with no note.
- **Problem:** The report lists declared events even while stood down. It does not say whether the env hook, the dialog hook and the two row hooks were installed, and it omits the per-character filter options.
- **Impact:** For "tags/filters do nothing" bug reports, the report cannot tell a missing hook from a setting.
- **Reachability:** Any player who runs `/pgfe diagnostics` for a support report.

### F-014 — `test_bridge` "commit with minimized dialog writes state only" asserts only negatives `[tests]`
- **Where:** `tests/test_bridge.lua:60-64` (`NS.Bridge.Commit(); assertEqual(m.pgf.calls.trigger, 0); assertEqual(m.pgf.calls.init, 0)`).
- **Problem:** The test would also pass if `Commit` were a no-op on every path. The name claims a state write the test never checks, and there is no `-- red under:` note (`testing-§12`).
- **Reachability:** Test inventory only. The positive path is covered at `:50-58`.

### F-015 — The launcher's enable pair reads the latch but writes the stored path `[design]`
- **Where:** `core/LauncherSetup.lua:55-56` (`isEnabled  = function() return not NS.IsStoodDown() end,` / `setEnabled = function(on) NS.addon:SlashEnabled(on) end,`).
- **Problem:** Under the `perf` hold the menu shows *Enabled* unticked. Clicking it writes `enabled = true`, which is already stored, and nothing changes.
- **Reachability:** Only a player who opens the launcher menu during a `/pgfe perf` suspend arm.

### F-016 — The env hook's region lookup trusts the leader name's type alone, unlike the row tags `[taint]` (**unverified**)
- **Where:** `modules/Regions.lua:48-51` (`if type(leaderName) ~= "string" or leaderName == "" then return nil end` ... `local realm = leaderName:match("%-(.+)") or GetRealmName()`), reached from `modules/EnvInject.lua:65`. Compare `modules/RegionTags.lua:34` (`... or not NS.IsConcatSafe(name) or ...`).
- **Impact:** If a leader name ever arrives as a protected string, `:match` raises inside PGF's per-result filter loop.
- **Reachability:** Nobody today, as far as the code can show: `docs/ARCHITECTURE.md` records only title and comment as protected, and PGF's own `PutPremadeRegionInfo` reads the same name first. Recorded so the two call sites stay consistent.

### F-017 — `[upstream]` LibKa0s test kit and WowAddonStandards: the `for ... in` function-literal hazard is described as a silent drop, but it crashes `lizard`
- **Owning repos:** LibKa0s (`testkit/lizard_sighted.lua`, the shadow sanitizer) and WowAddonStandards (`standards/standards/automated-tests.md`, the hazard table's last row: "is not listed; inside a function its body folds into the enclosing function's CCN").
- **Problem:** At file scope with a table of function literals in the header (F-001's shape), `lizard 1.24.0` raises `TypeError` and aborts the run. The sanitizer does not defuse this shape, and the standard understates what it does.
- **Reachability:** Any consumer repo with this shape at file scope. Today, this one.
- **Remediation (not a local edit):** add the shape to the sanitizer or the parity diagnosis in LibKa0s, bump the kit revision and re-vendor `tests/_kit/` here as its own commit. Correct the hazard-table row in WowAddonStandards.

### F-018 — `[upstream]` WowAddonStandards: the roster omits this addon, so the cross-addon pass never includes it
- **Owning repo:** WowAddonStandards, `standards/ADDONS.md` (the *In-scope addons* table, 11 rows at `:19-29`).
- **Problem:** This addon declares itself a Ka0s addon (`CLAUDE.md`, `## X-Standard`). It is not a roster row, so the review spec's `set --` list (and any roster-driven sweep) skips it. Today's pass added it by hand, and it was clean.
- **Reachability:** Every future cross-addon pass run from the roster.
- **Remediation (not a local edit):** add the row upstream. Nothing changes in this repo.
