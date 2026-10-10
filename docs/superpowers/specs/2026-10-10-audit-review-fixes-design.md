# Ka0s Premade Groups Filter Extension — 2026-10-10 audit + review fixes: design

**Inputs:** `docs/audits/2026-10-10/` (PGE-nn), `docs/reviews/2026-10-10/` (F-nnn), open issues #4-#19,
consolidated into [`docs/reviews/2026-10-10/06_CONSOLIDATED_FINDINGS.md`](../../reviews/2026-10-10/06_CONSOLIDATED_FINDINGS.md)
(C-01..C-39, verified at `0dabcde`).
**Plan:** [`docs/superpowers/plans/2026-10-10-audit-review-fixes.md`](../plans/2026-10-10-audit-review-fixes.md).
**Branch:** `fix/2026-10-10-audit-review`. **Standard:** the Ka0s WoW Addon Standard (v2.78.0 at verification).

## 1. Goal

Close all 39 consolidated findings in one branch. When the branch lands:

- The release gate can pass: complexity is sighted (`blindFiles` 0, max CCN ≤ 15), and perf is
  measured by the offline `tests/perf.lua` (six scenarios). No bucket is declared: the addon holds
  the performance-§12 no-combat-path exemption the owner chose at checkpoint D1 (C-09).
- Every code finding is fixed by conforming to the standard, with a red test first wherever a test
  is possible.
- The four ratified deviations (the three in section 3 item 2, plus the performance-§12 row) sit in
  `docs/ARCHITECTURE.md` -> `## Documented deviations` with accurate *Why* cells.
- The upstream items are filed as well-formed issues in their own repos.
- The GitHub label palette and the severities of the audit-carried issues are correct.
- A fresh automated-test bundle records the merged commit, and `CLAUDE.md` points at the 2026-10-10
  bundles.

## 2. Scope

All 39 findings, C-01..C-39. The disposition of each is in the table in `06_CONSOLIDATED_FINDINGS.md`
(26 fix-in-code, 3 register rows covering 4 findings, 4 upstream issues, 1 GitHub admin, 4 docs).
C-09 stays counted as fix-in-code (the wiring is removed) and also carries a register row, the
performance-§12 row, so this run appends **four** rows in all (section 5).

## 3. Owner decisions (2026-10-10)

1. **Default: conform.** Every finding is fixed to the standard's text unless listed below.
2. **Ratified deviations** (rows in `## Documented deviations`, `Decided` = `2026-10-10 (owner)`):
   - **C-17**: architecture-§5, for `char.filters` and `profile.panelCollapsed`, which panel controls
     set. Both move out of *Named non-setting state*.
   - **C-18**: architecture-§4 / anti-patterns #19, direct module calls with no bus. `## Message Bus`
     is rewritten to cite the threshold and the row. The *Why* rests on ordering, because
     `reloadProfile` fans out to several receivers.
   - **C-26 + C-34**: one combined row (standalone-windows; library-stack-§8; options-ui-§15). It
     covers the host chrome, names the quest-tracker atlases explicitly, and records that there is
     no General visibility row.
   - **C-09**: the performance-§12 no-combat-path exemption (item 8 below), recorded as the
     standard requires, once, in the register.
3. **C-15 conforms:** `filtersActive` and `showRegionTags` move to a new General `Filters` tab, giving
   **Master controls | Filters | EllesmereUI skin**. The §16 mis-citations are corrected.
4. **Upstream (C-12, C-14, C-36, C-37):** no edits to other repositories. These are filed as issues
   with `gh issue create` on `tusharsaxena/LibKa0s` and `tusharsaxena/WowAddonStandards`. C-14's local
   half is cleared by C-02's hoist.
5. **C-27:** `gh label edit` the eight labels, and re-severity the audit-carried issues (#4-#19) per
   the vocabulary.
6. **Issue closure:** every #4-#19 that a task fixes is closed after the merge to `main`, with
   `gh issue close` and a comment naming the commit. The state label is swapped to `state:done`.
7. **Process:** incremental commits, one or more per task. Push at milestones. Never merge without the
   owner's go-ahead. After the merge, delete the branch, worktrees and stashes the run created. Never
   bump the version. Never edit `libs/` (removing the unused `libs/AceTimer-3.0/` folder whole is not
   editing it) or `tests/_kit/`.
8. **C-09, owner checkpoint D1 (answered 2026-10-10): the performance-§12 no-combat-path exemption,
   not buckets.** The perf wiring is removed (`core/PerfSetup.lua`, `PremadeGroupsFilterExtensionPerfDB`,
   the `perf` verb registration, `NS.HOLD_PERF`), the committed combat-path sweep goes in
   `docs/performance.md`, `docs/perf-analysis/README.md` is deleted, the offline `tests/perf.lua` is
   shipped anyway, and the exemption is recorded as a performance-§12 register row (section 5).
   Section 4 C-09 is written for this route.

### Open design choices settled here by the default-conform rule

These are flagged for owner review at M3. Each has a conformant default. C-09 was the exception:
both of its routes are inside the standard, so the default-conform rule did not settle it, and the
route changes the TOC, the SVs, the `perf` verb and the hold. It was asked before implementation,
at owner checkpoint D1 (plan Task 0 Step 5), and the owner chose the performance-§12 exemption on
2026-10-10 (section 3 item 8). Its row below records that answer; it is no longer open.

| Finding | Choice | Default taken | Alternative |
|---|---|---|---|
| C-09 | Buckets vs the performance-§12 exemption | **Decided by the owner at D1 on 2026-10-10: the performance-§12 exemption.** Remove `core/PerfSetup.lua`, the PerfDB SV, the `perf` verb registration and `NS.HOLD_PERF`; commit the combat-path sweep; add the §12 register row; ship `tests/perf.lua` anyway (WhatGroup precedent). Section 4 C-09 is written for this route. | Buckets (`envInject`, `regionTags`) with Shape A brackets. **Not taken:** the capture windows open on combat state and this addon runs nothing in combat, so the buckets would read 0.000 in every capture (performance-§3). |
| C-29 | Drop the `OnLeave` gates, or undo in stand-down | **(a)** Keep every gate. Hide the tooltip and reset the glyph alpha in the STAND_DOWN/STAND_UP rows. | (b) Drop both `OnLeave` gates. This conflicts with "every hook body gates". |
| C-16 (PGE-12) | Slash refusal wording during a perf hold | **Moot after D1:** production no longer takes a perf hold, so the case cannot arise. The library's `DisabledLine` is kept (the wording belongs to the library), and the C-16 commit says so. | Override `DisabledLine`. That would deviate from the LibKa0s contract. |
| C-13 | `tests/test_panel.lua` band row | **Disposition "on notice"**: a test-only file, to be split by area before 1500 lines or at the next panel feature. Every other file the final run puts in the 1000-1500 band gets its own Disposition (a test file: the same wording; a production file such as `modules/Panel.lua`: asked at M3). | Split now into four suites, which keeps 325 pass / 1 skip. |
| C-38 | Spec amend vs runtime warning | **Spec amend.** Any is an owner requirement (`tests/test_filters.lua:41`). | Print a notice. Rejected, because it fights the Any UI. |
| C-30 | Do it, or will-not-do | **Do it.** One-line guard, smoke test only. | Close as will-not-do. |

## 4. Per-finding design

Line numbers are at `0dabcde`. Every "red under" names the mutation that must turn the new test red.
The gate after every commit is `lua tests/run.lua` and `luacheck .`, both at 0/0. Tests use the
factories `T.newAddon`, `T.bootAddon` and `T.enableAddon` (`local T = _G.PGFE_TEST`).

### C-01 — PGF-skin link EditBox hook (settings/Panel.lua `addPGFSkinLink`, 163-179)
- **Change:** set `local eb = box.editbox`. Then
  `if eb and eb.HookScript and not eb.__pgfeLinkHook then eb.__pgfeLinkHook = true; eb:HookScript("OnEditFocusGained", function(self) if self.__pgfeLinkActive then self:HighlightText() end end) end`.
  Then `if eb then eb.__pgfeLinkActive = true end`. Then
  `box:SetCallback("OnRelease", function(w) if w.editbox then w.editbox.__pgfeLinkActive = nil end; if Settings.PGFSkinLinkBox == w then Settings.PGFSkinLinkBox = nil end end)`.
  Update the comment above the function.
- **Tests (red first), `tests/test_euisettings.lua`, near the "a missing PGF skin gets a box" case
  (~196), using `setup{ pgfSkin = "missing" }`, `openTab`, and a counting `rawset(eb, "HighlightText", …)` spy:**
  The kit's AceGUI fake gives an EditBox widget no `editbox` field (`tests/_kit/mock_base.lua`
  `makeWidget`, ~1259), so `box.editbox` is nil under the harness and today's hook never runs in
  tests. **All three cases** wrap `Create` on the AceGUI lib table (`Helpers.AceGUI`, the LibStub
  object) so each EditBox gets `w.editbox = eb`, one shared `m.__stubFrame()` (it chains
  `HookScript` and has `__fire`). Confirm that a second `H.SelectTab` re-renders the tab (count the
  wrapper's EditBox creates); otherwise drive the second render through the page's own path.
  (a) focus selects (n == 1). With the wrapper this passes today: a pinning case. Red under: drop
  the hook.
  (b) after `box:Release()`, focus gives n == 0 and `Settings.PGFSkinLinkBox == nil`. Red under: delete the OnRelease.
  (c) no stacking: two renders on one `editbox`, then one focus gives n == 1. Red under: drop the
  `__pgfeLinkHook` guard.
- **Risk:** none at runtime. The kit's fake fires OnRelease before wiping events, as AceGUI does
  (`mock_base.lua:1389`).

### C-02 — lizard-safe RegionTags install (modules/RegionTags.lua 62-69)
- **Change:** `local PAINTER_HOOKS = { LFGListSearchEntry_Update = function(...) RegionTags.OnSearchEntryUpdate(...) end, LFGListApplicationViewer_UpdateApplicantMember = function(...) RegionTags.OnApplicantMemberUpdate(...) end }`,
  then `for name, fn in pairs(PAINTER_HOOKS) do if type(_G[name]) == "function" then hooksecurefunc(name, fn) end end`.
  Keep the "Installed at FILE LOAD" comment, and add one line explaining that the table is hoisted
  because lizard 1.24 crashes on function literals in a for-in header. In the same task, add the
  C-10 store: `RegionTags.hooked = {}` before the loop, and `RegionTags.hooked[name] = true` inside
  the `if`.
- **Tests:** `tests/test_regiontags.lua` runs unchanged as the characterization; it must stay green.
  The red-first case is new: "a painter the client lacks is skipped and the other still tags".
  Remove one painter from the mock before load, then assert no error,
  `RegionTags.hooked.LFGListSearchEntry_Update == true`, and the missing one reads `nil`. Red under:
  drop the store.
- **Verification:** `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`
  must give complexity pass, `blindFiles` 0 and max CCN ≤ 15.
- **Risk:** behavior does not change. If another file shows up blind, that is a new finding and is
  out of scope for this task.

### C-03 + C-33 — Expression Strip (modules/Expression.lua)
- **Change (C-03), `Expression.Strip` (68-87) only:**
  - In the `P_BEGIN` branch, after `j` is found, set
    `wrapped = wrapped or (j > i + 1 and lines[j-1]:match("and %(%s*$") ~= nil)`.
  - In the `P_CLOSE` branch, after the `)` check passes, set `closed = true`.
  - Before the final return, add `if wrapped and not closed then return text, false end`.
  - Update the comment at 65-67 to list the third damage shape.
- **Change (C-33):** line 86 becomes `return table.concat(out, "\n"), true`. Delete the
  `trimBlankEdges` local (25-32). The header line 5 becomes "kept line for line (CRLF is normalized
  to LF)".
- **Tests (red first), `tests/test_expression.lua`, after the "damaged block (begin without end)"
  case (~59):**
  - "close marker without ')' → damaged". Covers the existing branch at line 79.
  - "wrapped block, close marker deleted → damaged (both Merge and Clear refuse)". Red under: drop
    the `wrapped and not closed` check.
  - "deleting both close and ')' is refused (conservative)".
  - "unwrapped comment-only block strips ok without a close pair".
  - "strip keeps blank edge lines" over `{ "\nvoice\n\n", "  \nvoice", "voice\n", "-- note\n\n", "\n\n" }`.
    Red under: restore `trimBlankEdges`.
  - Clear path: `Merge(Merge("\nvoice\n", c), {}) == "\nvoice\n"`.
  - Round trip with blank edges: `Strip(Merge("\nvoice\n", c)) == "\nvoice\n"`, ok. (Merge-twice
    idempotence is not a red case: it passes today, because Strip trims to `voice` on both passes.)
  - Apply level (the fixNotes' optional case, in plan Task 13, which owns `tests/test_apply.lua`
    then): `Apply.Clear` on the wrapped-without-close input returns `false, "MSG_DAMAGED"`. Red under:
    drop the `wrapped and not closed` check.
- **Docs:** `docs/ARCHITECTURE.md` `## Expression block format`: add the third damage shape and the
  both-deleted refusal.
- **Risk:** a user who deletes both the marker and its `)` now gets `MSG_DAMAGED` where today the
  text is silently recovered. This is accepted and documented. `Apply.lua` needs no change, because
  `damaged` already maps to `MSG_DAMAGED` (`modules/Apply.lua:19`); the Apply-level case above
  proves it.

### C-04 + C-32 + C-31 + C-10 (bridge half) — PGF seams (core/PGFBridge.lua, modules/EnvInject.lua, modules/Regions.lua)
- **Change, `core/PGFBridge.lua`:**
  - Add `function Bridge.Specializations() local ns = pgf(); return ns and ns.C and ns.C.SPECIALIZATIONS end`.
  - Add `function Bridge.MapKeywords(mapID) local ns = pgf(); local t = ns and ns.C and ns.C.MAP_ID_TO_KEYWORDS; return t and mapID and t[mapID] end`.
  - Cite the PGF 7.6.2 source lines: `Modules/Specializations.lua:25` for SPECIALIZATIONS. Look up
    the MAP_ID_TO_KEYWORDS line in PGF source; do not invent it.
  - SEAMS gains, after `PutPremadeRegionInfo` and before the dialog rows:
    `{ "C.SPECIALIZATIONS", function() return Bridge.Specializations() end }`.
  - For C-10 / #7, SEAMS also gains the structural rows `d.panels`, `p.Dungeons` and
    `Advanced.Expression.EditBox`. Not `activeId`/`activeState`, which are nil before the first show.
    The existing first-missing expectation (`tests/test_apply.lua:60`, "Dialog.RefreshButton") holds
    whatever the order: that case nils only `RefreshButton`, and the fake supplies every new seam
    (`tests/pgf_fake.lua:6`, `:25`, `:35`). No edit to `tests/test_apply.lua` is needed or made.
- **Change, `modules/EnvInject.lua`:**
  - 47-49 become `NS.Bridge.Specializations()`. Keep the `PlayerKeywords(specID, role, classFile, specTable)`
    signature and update the `@param` comment at :29.
  - Line 89 becomes `EnvInject.hooked = NS.Bridge.InstallEnvHook(...)`. On false, write
    `NS.Debug("Env", "env hook not installed: %s", select(2, NS.Bridge.Check()))`.
- **Change, `modules/Regions.lua` `GetRegion` (C-32):**
  `if type(leaderName) ~= "string" or not NS.IsConcatSafe(leaderName) or leaderName == "" then return nil end`.
  Look up `NS.IsConcatSafe` at call time. Place the check after the `GetPortal()` nil-return (with
  `== ""` moved after it) so unsupported portals skip the pcall. Replace the "a type check, not a
  pcall" comment with the cost note.
- **Change, `.luacheckrc:28-29`:** the comment covers the PGF globals and `PremadeRegions`, and must
  be true for both. PGF globals: `core/PGFBridge.lua` and `modules/Diagnostics.lua` (presence-only),
  plus `modules/Season.lua` until the Season half lands (plan Task 7 then drops it).
  `PremadeRegions`: `modules/EnvInject.lua:65`, `modules/RegionTags.lua:25` and
  `modules/Diagnostics.lua:44`.
- **Season half of C-04** (`modules/Season.lua:20-23` -> `NS.Bridge.MapKeywords(mapID)`) is done in
  the Season task (plan Task 7), because that task owns `Season.lua`.
- **Tests (red first):**
  - `tests/test_bridge.lua`: "missing C.SPECIALIZATIONS is named" (`m.pgf.PGF.C.SPECIALIZATIONS = nil`
    makes `Check()` return `false, "C.SPECIALIZATIONS"`; red under: drop the SEAMS row). Accessors
    return the fake's tables, and nil without error when `C` or `PremadeGroupsFilter` is nil. One
    case per new structural seam.
  - `tests/test_bridge.lua` (C-31): rename the case to "commit with minimized dialog leaves PGF's live
    panel alone". Add `-- red under: drop the activePanel check in Bridge.Commit` and the positive
    `m.pgf.state.c2f4.dungeon.dungeon5` / `expression == "voice"` asserts (cmID 588 is row 5,
    `tests/pgf_fake.lua:28`).
  - `tests/test_regions.lua`: `NS.IsConcatSafe = function() return false end` makes
    `GetRegion("Bob-Frostmourne")` nil. Red under: drop the clause.
  - `tests/test_envinject.lua`: `EnvInject.hooked == true` under the mock (red under: drop the store
    at :89). With PremadeRegions nil and IsConcatSafe false, `env.region` is nil.
  - Optional structural guard in `tests/test_surface_parity.lua`: neither `modules/Season.lua` nor
    `modules/EnvInject.lua` contains `PremadeGroupsFilter`. It is enabled once the Season half lands
    (plan Task 7).
- **Docs:** ARCHITECTURE `## PGF seams`: "six seams" becomes the new count. Add the `C.SPECIALIZATIONS`
  row (checked yes), the `C.MAP_ID_TO_KEYWORDS` row (checked no, initials fallback) and the
  structural rows, and trim the Debug row. `## Taint Notes`: the RegionTags bullet lists the
  concat-safe guard; add that the env hook's `Regions.GetRegion` now probes the same way (C-32).
  After the Season half, sweep `docs/module-map.md` and `docs/data-flow.md` for any line saying
  Season or EnvInject reads PGF directly (none at `0dabcde`; plan Task 15).
- **Risk / trade-off:** gating `Check()` on SPECIALIZATIONS means a rename there disables Apply and
  the whole panel with "PGF version not supported". That is stricter than dropping only the
  same-spec clause, and it is chosen on purpose for consistency with the other seams.

### C-05 + C-20 + C-30 + C-29 (EUISkin half) — EllesmereUI skin (modules/EUISkin.lua)
- **C-05:**
  - Add a load-time `local REQUIRED = { "Shell","FadeNineSlice","FadeRegions","Checkbox","EditBox","Dropdown","Button","StateButtonLabel","Font","White","GetAccentColor","GetFont" }`.
  - In `blocked()` (~306-314), after `not S`, return `"facade lacks " .. name` for the first entry
    that is not a function. Optionally also refuse `apiVersion < 3`.
  - Add `local paintFailed`. `blocked()` returns `"paint failed earlier: " .. paintFailed` when it is set.
  - In `TryApply` (~319-333), use `local ok, res = pcall(function() return paintShell(f) + paintBody(f) end)`.
    Only on ok: set `applied = true`, call `NS.Panel.Refresh()`, log `applied: %d widgets`, return true.
    Otherwise set `paintFailed = tostring(res)`, write `NS.Debug(TAG, "paint failed: %s", …)`, and
    return false.
  - `OnSwitch(false)` (~337-343) asks for a reload on `applied or paintFailed`.
  - `onFacade` keeps `S`, so `HasFacade()` stays true.
- **C-20:** delete `local lastSkip` (:45). Replace :323-324 with
  `NS.DebugChanged("euiskin.skip", TAG, "skipped: %s", why)`, with the key first
  (`DebugLogGates.lua:139`). The paint-failed line uses plain `NS.Debug`.
- **C-30:** `OnEUISkinScale` (360-363) becomes `if stoodDown() or not applied then return end`, with
  the reason in a comment. The rows stay in `NS.FEATURE_EVENTS`.
- **C-29 (EUISkin half):** in a STAND_DOWN row (or the existing STAND_UP row at ~369), reset
  `b.pgfeGlyph:SetVertexColor(1,1,1,GLYPH_ALPHA)` for both `MaximizeMinimizeFrame` buttons. The
  `OnEnter` and `OnLeave` gates stay.
- **Mock:** `tests/wow_mock.lua` `installEUI` gains `spec.omit` (primitive names left out after the
  PRIMITIVES loop and the getters) and `spec.raise` (a primitive that errors). Document both in the
  spec comment (331-335). This is the addon's own mock, not `_kit`.
- **Tests (red first), `tests/test_euiskin.lua`:**
  - `painted{ omit = { "StateButtonLabel" } }`: no raise, `IsApplied()` false, `HasFacade()` true,
    a second TryApply false, `count("Shell") == 0`, and the panel still shows. Red under: drop the
    shape check.
  - `spec.raise = "Dropdown"`: TryApply returns false without raising, a second TryApply adds no
    `Checkbox` call, and `OnSwitch(false)` shows `POPUP_RELOAD`. Red under: drop the pcall, or drop
    `paintFailed`.
  - C-20: with logging on, two skips give one line. `NS.DebugLog:Clear()` and a third skip give the
    line again. With logging off then on, the same skip is logged. Red under: the `lastSkip` memo.
  - C-29: fire `MinimizeButton` OnEnter, stand down through the disable write seam
    (`/pgfe disable`, then `/pgfe enable`), and the glyph alpha is `0.75`. The test never names
    `NS.HOLD_PERF`, which C-09 removes. `GLYPH_ALPHA` is a file-local (`modules/EUISkin.lua:35`), so
    the test hard-codes the value and cites the line. The texture stub already records
    `SetVertexColor` as `__vertexColor` (`tests/wow_mock.lua:262`); no recorder is added. Red under:
    drop the reset.
  - C-30 smoke: no facade, then fire `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`. No error, and
    `IsApplied()` is false. A red test is not possible here, because the early return and the empty
    loop behave the same.
- **Docs:** the ARCHITECTURE facade paragraph (~241) says the paint checks the facade shape and fails
  closed.
- **Risk:** a partial paint before a raise stays on screen until `/reload`. That is accepted, and
  `OnSwitch(false)` now offers the reload.

### C-06 + C-07 + C-04 (Season half) + C-29 (Panel half) + C-10 (Panel store) — season data and panel (modules/Season.lua, modules/Panel.lua)
- **Change, `modules/Season.lua`:**
  - Add `local requested = false` and `local lastFull = false`.
  - Add `function Season.RequestOnce() if requested then return end; if C_MythicPlus and C_MythicPlus.RequestMapInfo then requested = true; C_MythicPlus.RequestMapInfo() end end`
    and `function Season.ResetRequest() requested = false end`.
  - **State machine, in `GetDungeons()`** (read the map table first, then decide, then request):
    1. `local ids = C_ChallengeMode.GetMapTable(); local full = ids and #ids > 0`.
    2. If `full`, set `lastFull = true`.
    3. If not `full` and `lastFull`, this is a rollover: set `lastFull = false` (the "was full"
       memory is **cleared on the reset**) and call `Season.ResetRequest()`.
    4. Call `Season.RequestOnce()`. Because it runs after step 3 in the same call, the first empty
       read after a full one sends the request at once; a single post-rollover event is enough.
    5. If not `full`, return nil; else build the list as today.
    A second empty read finds `lastFull == false`, so it neither resets nor sends: there is one
    request per episode, and the C-06 loop cannot come back. `addon.OnPanelEnteringWorld` calls
    `ResetRequest()` only (not `lastFull`), so each loading screen gets one fresh request.
  - **Why not "re-arm when data arrives"** (the C-06 proposedFix's non-nil branch setting the flag
    false): with `RequestOnce` at the top of every `GetDungeons()` call for C-07, re-arming on every
    full read would send a request on every call while the table is populated, which breaks C-07's
    "a populated table requests once" test. The full -> empty transition is that re-arm's merged
    form: data arriving sets `lastFull`, and the next empty read (the rollover) re-arms once.
  - `shortName` uses `NS.Bridge.MapKeywords(mapID)` (the C-04 Season half), with the "rows look like"
    comment moved to the accessor.
- **Change, `modules/Panel.lua`:**
  - `updateReadout` (165-170) drops the bare `RequestMapInfo` and keeps `READOUT_LOADING`.
  - `addon.OnPanelEnteringWorld` calls `NS.Season.ResetRequest()` before `UpdateVisibility()`, so a
    lost request recovers on the next loading screen.
  - Add `NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE", "OnPanelSeasonData" }`
    next to 882-883.
  - Line 892 becomes `Panel.dialogHooked = NS.Bridge.HookDialog(...)` (C-10 store).
  - The C-29 Panel half: the `NS.STAND_DOWN` row hides `GameTooltip` when its owner is
    `Panel.frame` or a descendant, before `Panel.frame:Hide()`. The walk carries a self-parent guard
    (`local p = o:GetParent(); if p == o then break end`), so a frame whose `GetParent` answers itself
    cannot loop.
- **Mock:** `tests/wow_mock.lua` gains `M.mapInfoRequests = 0` in the reset block (~38), documented
  in the header list. `RequestMapInfo = function() M.mapInfoRequests = M.mapInfoRequests + 1 end`
  (:80). Never fire the event from inside the mock.
  `M.GameTooltip` is the kit's bare `newFrame()` (`tests/_kit/mock_base.lua:1154`): `SetOwner` is a
  metatable no-op, and `GetOwner` / `GetParent` fall through to the uppercase fallback, which returns
  the frame itself. So `tests/wow_mock.lua` rawsets on it `SetOwner` (records `__owner`), `GetOwner`
  (returns it), `GetParent` (returns nil) and a `Hide` that clears `__owner`. Without them the
  tooltip test cannot go green and an unguarded owner walk never ends.
- **Tests (red first):**
  - `tests/test_panel.lua`, near "readout says loading" (~286):
    - "an empty map table asks the server once, not every round trip": three MAPS_UPDATE, one
      COMPLETED and one level-box Enter give `m.mapInfoRequests == 1`. Red under: drop the guard.
    - "a populated map table still requests once on the first readout" (`seasonFromScreenshot(m)`):
      a second Refresh, MAPS_UPDATE and AFFIX_UPDATE leave the count at 1. Red under: request only
      on nil.
    - "rollover re-arms": `m.mapTable = {}` then MAPS_UPDATE ×2 gives exactly one more request (and
      one MAPS_UPDATE alone already gives it). This is the guard for the state machine. Red under:
      leave `lastFull` set on the reset (the count then grows per event), or drop the `RequestOnce`
      after the reset (the single event then sends nothing).
    - "PLAYER_ENTERING_WORLD re-arms".
    - "AFFIX_UPDATE recomputes Smart and clears loading" (copy :833-838).
    - "a stood-down panel hides its tooltip" (spy `GameTooltip.Hide`, then take the hold). Red under:
      drop the hide in the STAND_DOWN row.
    - `Panel.dialogHooked == true`.
  - `tests/test_season.lua`: `Apply.Run` with no panel still requests (proving it lives in Season).
    With `C.MAP_ID_TO_KEYWORDS = nil`, short names fall back to initials. That second case passes
    today (`modules/Season.lua:22-25` already nil-guards): it pins the fallback through the accessor
    switch rather than going red first.
- **Docs:** ARCHITECTURE `## Event Subscriptions` gains the AFFIX row. `## Known Limitations` gains:
  bests read 0 until the reply arrives, and the client cannot tell "never timed" from "not loaded".
  `docs/data-flow.md:86-89`: the request goes out once per episode, is re-armed on
  `PLAYER_ENTERING_WORLD` and on the full -> empty rollover, and three events feed it.
- **Risk:** this has not been verified in the client (review smoke C-02 off-season and fresh login).
  It is recorded in `docs/smoke-tests.md`.

### C-09 — the performance-§12 no-combat-path exemption (owner checkpoint D1, 2026-10-10)
- **Decision.** At D1 (plan Task 0 Step 5) the owner chose the performance-§12 exemption over
  buckets, on 2026-10-10. The buckets design (`envInject` / `regionTags` declared, Shape A brackets
  in `EnvInject.Apply` and the two row painters) is not implemented, and nothing in this run
  brackets a path.
- **Why the addon qualifies (performance-§12's test).** Criterion **(a)**: no `OnUpdate` handler, no
  timer of any kind once C-35 removes AceTimer, one registration site (`core/PGFE.lua`
  `registerFeatureEvents`) over the eight `NS.FEATURE_EVENTS` rows (after C-07), each doing one small
  refresh, and hooks that run on the player's own Group Finder actions; `Apply` refuses in combat.
  This MUST be proven by a committed whole-repo sweep of `RegisterEvent` / `SetScript("OnUpdate"` /
  `C_Timer` naming the per-event work for each hit; the sweep also lists the `hooksecurefunc` /
  `HookScript` sites. Criterion **(b)** applies: the capture windows open on the player's combat
  state (performance-§7), so every declared bucket would read `0.000` by construction. (c) does not
  apply. If the sweep finds an `OnUpdate`, a repeating timer or real in-combat work, (a) fails and
  the decision goes back to the owner.
- **Removed (what the exemption suspends):** `core/PerfSetup.lua` and its TOC line and annotation;
  `PremadeGroupsFilterExtensionPerfDB` from `## SavedVariables` (one global remains, toc-file-§2 and
  savedvariables-§4; an exempt addon declaring the ring is non-compliant); the `perf` row and
  `runPerf` in `settings/Slash.lua` and its enUS help key; `NS.HOLD_PERF` in
  `core/LifecycleSetup.lua`; `docs/perf-analysis/README.md` and the `docs/perf-analysis/` store; the
  `.luacheckrc` PerfDB globals (and `debugprofilestop`, once nothing outside `libs/` reads it); the
  `LibKa0s-Perf-1.0` surface source in `tests/run.lua`, the PerfDB reset in `tests/loader.lua`, and
  the Perf stub parity case.
- **Kept (what it does not suspend):** `libs/LibKa0s/` vendored whole, `Perf.lua` included (the TOC
  keeps its single `LibKa0s.xml` line, `tests/loader.lua` keeps the `Perf*.lua` entries;
  anti-patterns #48); `perf` as a **reserved, unregistered** verb (slash-commands-§2): with LibKa0s
  Slash minor 14+ `/pgfe perf` answers with the unknown-command line and the index, the same enabled
  and disabled (`libs/LibKa0s/Slash.lua:863-873`); `docs/performance.md`, shrunk to one screen
  (brackets nothing, (b) applies, the sweep, the re-arm trigger); and the release notes' perf line.
- **`tests/perf.lua` (new, outside `tests/run.lua`), shipped anyway.** §12 suspends §9 as a MUST;
  the file is a choice (WhatGroup precedent: offline scenarios suspend nothing, ship nothing to the
  client and add no SavedVariable). It still follows §9's rules:
  - Modeled on `../WhatGroup/tests/perf.lua`. It dofiles the kit framework, `tests/wow_mock.lua`
    and the loader, takes `--out`/`--label`, and asserts allocation bytes per iteration (full
    `collectgarbage` on either side) and API call counts only. Wall-clock time is printed for
    orientation and never asserted.
  - Scenarios: (a) `envNoPR`, about 1000 synthetic results through `PutPremadeRegionInfo` without
    PremadeRegions (exercising `injectRegions` and `Regions.GetRegion`, including the C-32 probe);
    (b) `envWithPR`, with PremadeRegions, making no region lookup; (c) `envStoodDown`, giving 0 bytes
    and 0 API calls (it takes the place of §9's zero-overhead scenario, which has no subject because
    nothing is bracketed); (d) `searchRowPaint`, `OnSearchEntryUpdate` over about 1000 fake entries,
    counting `GetSearchResultInfo` and `SetText`; (e) `applicantRowPaint`, the same for
    `OnApplicantMemberUpdate`; (f) `combatEvents`, every `FEATURE_EVENTS` event and
    `PLAYER_REGEN_DISABLED` fired with `InCombatLockdown` true, pinning the per-event API calls the
    sweep names (0 for the unregistered combat event).
  - Output in the runner's shape: a `scenario iters ms/iter api/iter bytes/iter` header, one
    five-field row per scenario, a blank line, then failures; exit 1 on any failed assertion.
  - Lizard-safe: the complexity runner scans every `*.lua` outside `libs/` and `tests/_kit/`
    (`run-automated-tests.sh:505-508`), `tests/*.lua` included. No function literals in a `for … in`
    header (the C-02 crash shape); named locals for scenario tables; CCN ≤ 15 per function.
- **How the runner reads it.** `tests/_kit/run-automated-tests.sh` consults the register for a
  `performance-§12` Rule cell only when `tests/perf.lua` is absent (:272), which is automated-tests-§3's
  second sanctioned skip reason. With the file present it runs it and records `pass` on exit 0
  (:436-484), counting rows of exactly five fields under the `scenario  iters` header. So perf reads
  `pass`, the release gate's requirement, and the register row is the exemption's ratification for
  audits (performance-§12, *Recorded once*). Task 15 proves the row is machine-readable by running
  the perf suite once with `tests/perf.lua` moved aside and seeing the §12 skip note.
- **Tests (red first):**
  - `tests/test_setup.lua`: "no perf harness is wired (performance-§12)": `NS.Perf == nil`,
    `NS.HOLD_PERF == nil`, the raw TOC's `## SavedVariables:` is exactly
    `PremadeGroupsFilterExtensionDB`, no TOC line names `core\PerfSetup.lua`, and
    `libs/LibKa0s/Perf.lua` still exists. Red under: restore any one of them. It replaces the
    "perf harness is wired" case.
  - `tests/test_slash.lua`: "perf is reserved but not registered": no `NS.COMMANDS` row named
    `perf`, and `/pgfe perf` prints the unknown-command line and the index, the same enabled and
    disabled. Red under: restore the `perf` row. It replaces the "perf answers through the harness"
    case, and the pinned verb order loses `perf`.
  - `tests/test_disabled.lua`: the perf-hold case takes the library's reserved hold by its library
    constant, `(T.LibStub("LibKa0s-Lifecycle-1.0", true) or {}).HOLD_PERF or "perf"`, as a test-only
    second holder (BankLedger precedent), and drops the `NS.Perf.suspended` assert. C-08's rewrite
    keeps that local.
  - `tests/test_surface_parity.lua`: the Perf stub parity case is deleted with the stub.
- **Docs:** `docs/performance.md` (one screen plus the sweep table); `docs/perf-analysis/README.md`
  deleted; `docs/ARCHITECTURE.md` :47 (one production hold), :58 (no Perf instance), :70, :118, :140
  (`perf` reserved, unregistered), :338, :356 (`perf-analysis/README.md` → `Not applicable`, "The
  `performance-§12` exemption is held; no harness is wired"), :357 (16 commands become 15);
  `docs/schema.md:3-4`; `docs/module-map.md:19`, `:42`; `docs/slash-dispatch.md:19`;
  `docs/testing.md:45`. The register row is section 5's fourth row, appended by Task 15 with the
  sweep commit's sha.
- **Ripples:** C-11/C-25 lose the `core/PerfSetup.lua:24` site; the C-29 tests stand down through
  the disable seam; C-16 is re-checked (below); C-08's steps 7 and 10 handle `perf` as unregistered
  and take the `perf` hold through the test-local constant.
- **Order:** plan wave 2b, alone, after C-07 (the eighth event) and C-35 (no AceTimer), because it
  edits files wave 2's tasks own.
- **Risk:** criterion (a) is the half most likely to stop being true. PGF can filter a search, and
  the row painters can run, while the player has the Group Finder open in combat; the per-result
  work is small and the sweep names it, and the `combatEvents` and `env*` scenarios measure it. The
  re-arm trigger in the row is the guard. In-game smoke: `/reload` with no Lua error, `/pgfe perf`
  prints the unknown-command line and the index, and no `PremadeGroupsFilterExtensionPerfDB` table
  appears in the SavedVariables file after a logout.

### C-10 — Diagnostics (modules/Diagnostics.lua)
- **Change:**
  - In `dependencies()`, add `local ok, missing = NS.Bridge.Check(); out:add(TAG, "PGF seams ok=%s missing=%s", ok, missing or "none")`.
  - Also add `out:add(TAG, "hooks: env=%s dialog=%s searchRow=%s applicantRow=%s", …)`, with each
    value printed `== true` and the module tables guarded with `and`.
  - Add a new `filters` section after `settings`, read through `read(NS.Filters.Get)`. Scalars are
    sorted. The sets `regions` and `playstyles` go through `out:joined`, so empty reads "Any".
  - In `registration()`, relabel "feature events (declared)" and add
    `out:add(TAG, "feature events registered=%s", not stoodDown())`.
- **Tests (red first):** a new `tests/test_diagnostics.lua`, registered in `tests/run.lua`. It uses
  the capture-`out` pattern from `tests/test_euiskin.lua:327-341` plus `joined` and `list` stubs
  (`registration()` calls `out:list` at `modules/Diagnostics.lua:61`).
  - `PGF seams ok=true missing=none`.
  - `hooks: env=true dialog=true searchRow=true applicantRow=true`. Red under: drop the store at
    EnvInject:89.
  - With `PutPremadeRegionInfo` nil: `ok=false missing=PutPremadeRegionInfo`.
  - With `regions.oce = true`: "oce" appears and "table:" does not.
  - Stood down: `registered=false`.
- **Docs:** the `docs/debug.md` section table. Check that any `docs/ARCHITECTURE.md` line describing
  the diagnostics sections matches the new seams / hooks / `filters` output (today `## Slash
  Commands` names only the verb).
- **Risk:** none. `Check()` calls no PGF function.

### C-11 + C-25 — locale (locales/enUS.lua and the literal sites)
- **C-11:**
  - Add the six `PGF_TEXT` keys (`core/EUIBridge.lua:107-113`) to the enUS section at :153, replacing
    the dead :166-167.
  - Add the six `settings/Panel.lua` keys (:168, `CONDITION_TIPS` eui/master/own/pgf :211-214,
    `STATE_TIP` :216) to the section at :173.
  - Copy them byte for byte, including `\n\n`.
- **C-25:**
  - Whole-sentence `%s` keys for `settings/Slash.lua` (:84 unknown command, :88/:101 help header,
    :150 settings unavailable, :171-172 reset usage, :188 console not ready, :59 `CLI_MISSING`).
  - `settings/Panel.lua` `defaultsTooltip` (:251-252) and page name `General` (:249).
  - `core/DebugLogSetup.lua` (:16, :55, :61).
  - `core/CoreSetup.lua` (:9 `LIBKA0S_MISSING`, :36).
  - `core/LauncherSetup.lua:21`, `settings/OptionsSetup.lua:13`. (`core/PerfSetup.lua:24` is not a
    site: C-09 deletes the file before this task runs.)
  - Kept literal: `DISABLED_LINE_FORMAT` (pinned by `Kit.assertLibraryConstant`), brand names, `/pgfe`
    verb tokens (passed as `%s` arguments), and color escapes (inside the values).
  - `settings/Schema.lua:106/110` are developer-facing diagnostics and stay literal. That is noted
    in a comment.
- **Tests (red first):**
  - Key parity, both directions, in `tests/test_surface_parity.lua`. It reads `Loader.tocFiles`,
    collects `L["…"]`/`NS.L["…"]`/`L.IDENT` literals and the keys `enUS.lua` assigns, and allowlists
    the `MSG_*`, `REGION_TIP_*` and `PLAYSTYLE_*` dynamic families. Red under: delete one new enUS line.
  - Sentinel locale, in `tests/test_slash.lua`. `NS` is built inside `tests/loader.lua` (:94) and
    `NS.L` by `locales/enUS.lua` at load, so a swap "before loading" is not reachable, and a swap
    after load misses the strings built at load (`CLI_MISSING` `settings/Slash.lua:59`, DebugLogSetup
    `missing` :16, `core/LauncherSetup.lua:21`). `tests/loader.lua` (the
    addon's own) gains an optional `opts.afterFile(path, NS)` hook; the test wipes `NS.L` in place
    right after `locales/enUS.lua` and gives it an `__index` returning `"<<"..k..">>"`, so every later
    capture of the same table carries the sentinel.
    With LibKa0s absent (the stub paths), drive `/pgfe bogus`, the help header, bare `/pgfe reset`,
    `OpenSettings` with no Helpers, `runDebug` with no DebugLog, the stub DebugLog
    `SetEnabled`/`ConsoleCheckbox().label` and the `LIBKA0S_MISSING` family; each line contains `<<`.
    With LibKa0s present, `/pgfe bogus` and the help header are the library's lines, so only this
    addon's own sites are asserted there. Red under: revert any one site to a literal.
- **Risk:** existing exact-text asserts stay green only if the values are identical. Run the full
  suite, because `test_prose` scans the new English for spelling.

### C-15 + C-01 file sharing — settings page tabs (settings/Panel.lua 46-81)
- **Change:**
  - Remove `extra` from the `MasterControls` spec and `filtersActive` from `MASTER_HOOKS`.
  - Declare `FILTER_ROWS` (both rows: `page = "general"`, `section = "general"`, `group = L["Filters"]`,
    defaults, labels and tooltips unchanged). `filtersActive.onChange = function(v) NS.Apply.OnFiltersToggled(v and true or false) end`.
  - Call `Settings.StampClosureRows(FILTER_ROWS)` and then `NS.SchemaRuntime.AddRows(FILTER_ROWS)`,
    after the `MASTER_ROWS` insert at index 1 and **before** `AddRows(EUI_ROWS)`.
  - `GENERAL_OPTS.tabs` stays EUI-only, and `AFTER_GROUP` keeps the reset pair on Master controls.
  - The header comment (5-6) describes three tabs, and the §16 citation at :56 goes.
  - `locales/enUS.lua` gains `L["Filters"] = "Filters"`.
  - No migration and no `SCHEMA_VERSION` bump, because the paths are unchanged.
- **Tests (red first):**
  - `tests/test_euisettings.lua:54-65`: the expected order is `H.MASTER_GROUP .. " | Filters | " .. GROUP`.
    Rename the case and add the red-under note.
  - New `tests/test_setup.lua` case: every Master-controls-group row path is in
    `{ enabled, state.debugConsole, global.minimap.shown }`, and `filtersActive`/`showRegionTags` have
    `group == L["Filters"]`. Red under: putting either back in `extra`.
  - Update the `tests/test_apply.lua:213` comment.
- **Docs:**
  - `docs/settings-panel.md:11`, `:24-37`.
  - `docs/schema.md:13-14`.
  - `docs/ARCHITECTURE.md:100`.
  - The `defaults/Profile.lua:6`, `:18-19` comments.
  - `docs/smoke-tests.md:54`, `:201` (APPLY-21 now finds the box at Settings -> General -> Filters).
- **Risk:** the tab-index assumptions in the tests. C-22's reset tests are written after this.

### C-16 + C-08 — launcher and the disabled-state suite (core/LauncherSetup.lua, tests/test_disabled.lua)
- **C-16 re-checked after D1.** The finding is "the launcher's Enabled entry reads the latch, so a
  perf capture shows *Enabled: No* while `enabled` is stored `true`". C-09 removes the perf wiring,
  so production takes exactly one hold, `disabled`, set from the stored `enabled` path; the latch
  and the stored setting agree in every state production reaches, and the reported symptom cannot
  happen. What remains is launcher-§1's letter: each status line is read "through the same accessor
  the Master-controls row reads", and that row reads the stored setting. The fix stays, as a
  conformance fix that also keeps the tooltip right the day a second hold returns (the
  performance-§12 re-arm trigger). PGE-12's wording question is unreachable in production.
- **C-16 change:** `core/LauncherSetup.lua:55` becomes
  `isEnabled = function() return NS.SchemaRuntime and NS.SchemaRuntime.Get("enabled") ~= false end`.
  The header comment (7-8) changes to match. `settings/Slash.lua:129` keeps the latch.
- **The `perf` hold in tests.** `NS.HOLD_PERF` no longer exists (C-09). The suite takes the
  library's reserved hold by its library constant,
  `local HOLD_PERF = (T.LibStub("LibKa0s-Lifecycle-1.0", true) or {}).HOLD_PERF or "perf"`, as a
  test-only second holder that production never takes (BankLedger and PrettyChat precedent).
- **C-16 tests:**
  - "while another hold stands the addon down, the launcher reports the stored setting"
    (`NS.Lifecycle:Hold(HOLD_PERF)`, `NS.Launcher:Object().OnTooltipShow(fakeTT)`, Enabled says
    Yes). Red under: revert :55 to `not NS.IsStoodDown()`.
  - The mirror: after `/pgfe disable`, the tooltip says No.
  - The former third case (`apply` refused under a perf hold while `/pgfe get enabled` prints
    `true`) is dropped: it pins a state production no longer reaches, and C-08 step 10 pins the
    latch.
- **C-08 rewrite:** build every case from `T.enableAddon()` with the kit recorders. Drop the probe
  row and the `FEATURE_EVENTS`/`STAND_*` injection.
  1. Snapshot R_on/T_on/F_on. R_on equals the names in `NS.FEATURE_EVENTS` and pins the 8 literals:
     `ACTIVE_PLAYER_SPECIALIZATION_CHANGED`, `PLAYER_SPECIALIZATION_CHANGED`, `UI_SCALE_CHANGED`,
     `DISPLAY_SIZE_CHANGED`, `CHALLENGE_MODE_MAPS_UPDATE`, `CHALLENGE_MODE_COMPLETED`,
     `PLAYER_ENTERING_WORLD`, `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE`.
  2. Disable through `/pgfe disable` and through `NS.SchemaRuntime.Set("enabled", false)`.
  3. Registrations are empty by name. `-- red under: drop the UnregisterEvent loop in NS.StandDown (core/PGFE.lua, :121 at 0dabcde; re-read the line after C-19's OnEnable edit)`.
  4. No live timer.
  5. Showing PGF's dialog shows no panel frame.
  6. `__fireUnconditional` every R_on event plus `PLAYER_REGEN_DISABLED`. Drive the env hook,
     the dialog hook, both RegionTags painters, an EUISkin `SetChecked` hook, the `RegisterSkin`
     callback (C-37) and the Panel widget callbacks. Assert zero SV writes, prints and shows. Red
     under: remove `NS.IsStoodDown()` in `RegionTags.lua:25` / `EnvInject.lua:61`.
  7. Walk every `NS.COMMANDS` verb plus bare `""` and `debug diagnostics`. Also dispatch `perf`,
     which is reserved and not registered (C-09): it prints the unknown-command line and the index,
     the same as when enabled. `apply`/`clear` print
     exactly one `DISABLED_LINE_FORMAT` line and reach neither `Apply.Run` nor `Apply.Clear`.
     `config` and bare open the settings. `set`/`reset` write, then the writes are reset.
  8. Launcher left-click calls `OpenSettings` with zero writes and shows. The right-click menu keeps
     only Enabled clickable. Toggling it writes only `enabled`.
  9. Change a setting while disabled, enable, and assert that R_on is restored and the rebuild read
     the new value.
  10. Both latch orders (perf hold then disable, and disable then hold), the perf hold taken
      through the test-local `HOLD_PERF` above. Red under: replace the `Lifecycle` Set/Hold path
      with a direct `NS.StandUp()`.
  Keep the "profile stored disabled stands down at the next enable" case, asserting on empty
  registrations.
- **Order:** after C-07 (the 8th event), C-09 and C-19, so the pinned set and hook list are final.
  In the plan this makes wave 4 sequential: Task 13 (C-19) is integrated first, and Task 14 is cut
  from that tip. Step 6 asserts zero prints and shows across the paths C-19 changes (the Panel
  STAND_DOWN row's `DebugForget`, `UpdateVisibility`, `PGFE:OnEnable`).
- **Docs:** the `docs/testing.md:31` test_disabled line. Any `docs/ARCHITECTURE.md` line that says the
  launcher's enable pair reads the latch is corrected to the stored setting (none at `0dabcde`).
  Also correct issue #4's "5 events" text to 8 when it is closed.

### C-17, C-18, C-26 + C-34, C-39, C-37 note, C-38, C-24 — docs and register
- See section 5 for the rows: the first three are these findings'; the fourth, performance-§12,
  is C-09's and lands in the same task.
- `## Settings Schema` (108-116): drop the `char.filters` and `profile.panelCollapsed` bullets and
  leave a pointer to the architecture-§5 row. Keep `global.presets` (retitled as a registry) and
  `global.minimap`.
- `## Message Bus` (120-122) is rewritten: the §4 threshold is crossed (list the feature modules),
  there is no bus, the reason is ordered single-sender reactions, the three reaction sites are named,
  and the row is linked.
- **C-39:** the EllesmereUIDB row's Why says "owner decision 1 in
  [`superpowers/plans/2026-10-09-eui-skin.md`](superpowers/plans/2026-10-09-eui-skin.md#owner-decisions-2026-10-09)
  -> `## Owner decisions (2026-10-09)`, ratified at that plan's step 6a". The PGF-dependency row's Why
  says "owner requirement, [`superpowers/specs/2026-10-09-m-plus-v0.1-design.md`](superpowers/specs/2026-10-09-m-plus-v0.1-design.md)
  §1 item 5 (the requirement) and §2 (recorded as a user-requirement deviation)". Checked at plan
  time: §1 `## 1. Intent` item 5 (line 18) says "Hard dependency on PGF: the addon must not load
  without it.", and §2's constraints table (line 32) records the deviation. The implementer re-reads
  both, and the eui-skin plan's decision 1, before citing; if a source no longer says what the row
  claims, the Why falls back to `docs/audits/2026-10-09/`. The other cells are unchanged.
- **C-37:** one sentence in `## Taint Notes` (stand-down): the `EllesmereUI.RegisterSkin` callback
  survives a stand-down and gates itself (`modules/EUISkin.lua:382-395`).
- **C-38:** `docs/superpowers/specs/2026-10-09-m-plus-v0.1-design.md:93` reads: Regions:
  `( oce or chi )` (selected keys joined by `or`; *Any*, meaning none selected or every one of the
  portal's regions selected, adds no clause and prints no warning; issue #8). Add a
  `tests/test_filters.lua` full-selection case (`ToClauseOpts(portal).regions == nil`) if missing.
- **C-24:**
  - `DEPENDENCIES.md` gains a `## Release / assets / maintenance` group with two bullet entries
    (Pillow; `python3` stdlib only: `re`, `string`, `sys`; install
    `sudo apt-get install -y python3`; verify `python3 --version`). The count is dropped.
  - Qualify the lizard row (:40, :71-72) with the source-shape rule: keep function-literal tables
    as named locals.
  - `docs/realm-map-maintenance.md` "How to run it": "Needs Python 3 (stdlib only); see DEPENDENCIES.md."
- Comment pointers: the `settings/Panel.lua:8-10` and `modules/Panel.lua:8-9` headers gain
  "(ratified: docs/ARCHITECTURE.md -> Documented deviations)".
- **Tests:** none are possible for prose, because no authored test reads ARCHITECTURE.md. An optional
  guard is noted in the plan. The order the C-18 row's Why rests on (the latch re-read before
  `EUISkin.OnSwitch`) is already pinned by `tests/test_euiskin.lua:184-196` ("a profile switch to a
  disabled profile with the switch on paints nothing"); the `## Message Bus` rewrite cites it.

### C-19 + C-28 — debug lines and the targeting-off message (modules/Apply.lua, Presets.lua, EnvInject.lua, Panel.lua, core/PGFE.lua)
- **C-19:**
  - Apply: a local `done(tag, ok, key, ...)` writes `NS.Debug(tag, ok and "ok: %s" or "refused: %s", key)`
    and passes its arguments through. Every return in `Apply.Run` and `Apply.Clear` goes through it.
    `MSG_NO_PGF` appends the missing seam.
  - After Commit: `NS.Debug("Apply", "wrote %s dungeon rows, %d expr chars, range %s", tostring(ticked or "untouched"), #text, tostring(Apply.LastRange))`.
    Before `Bridge.Search()`: `NS.Debug("Apply", "search")`.
  - Matching lines under the `Clear` tag. One line in `Apply.OnFiltersToggled`.
  - Panel: `NS.DebugChanged("panel.vis", "Panel", want and "shown" or "hidden")` after `SetShown` in
    `UpdateVisibility`, past the `if not f` exit. The STAND_DOWN hide calls
    `NS.DebugLog.DebugForget("panel.vis")` so the next stand-up's "shown" is not deduplicated away.
    `DebugForget` is **not** published bare: `core/DebugLogSetup.lua:119-122` publishes only `Debug`,
    `DebugOnce`, `DebugChanged` and `DebugAtEnable`. Both branches carry it on the instance (the stub
    at `core/DebugLogSetup.lua:30`, the real one at `libs/LibKa0s/DebugLogGates.lua:150`), so
    `core/DebugLogSetup.lua` is not edited. Check the exact `DebugChanged(key, tag, fmt, ...)` name
    first.
  - Presets: `Presets.Save/Load/Delete` log `saved '%s'`, `loaded '%s'`, `deleted '%s'` /
    `delete '%s': absent`, and `refused: badName` / `missing`.
  - EnvInject: at the end of `RefreshPlayer`, `NS.DebugChanged("env.spec", "Env", "spec=%s classRole=%s", tostring(player.spec), tostring(player.classRole))`.
    `EnvInject.Apply` and the row painters stay silent.
  - `core/PGFE.lua` `OnEnable`, before the latch:
    `NS.DebugAtEnable("Init", "PGF seams %s; PremadeRegions %s; hooks env=%s dialog=%s searchRow=%s applicantRow=%s", …)`,
    built from `Bridge.Check()` and the C-10 stores.
- **C-28:**
  - `Apply.lua:61` becomes `Apply.LastRange = targets and NS.Targeting.RangeText(f.keyLevel) or nil`.
  - `:63` becomes `return true, "MSG_APPLIED_NO_TARGETING"`.
  - The doc comment at `:15` changes to match.
  - `locales/enUS.lua:61` becomes `L.MSG_APPLIED_NO_TARGETING = "Applied (dungeon checkboxes left as they were)."`.
- **Tests (red first):**
  - `tests/test_apply.lua`: `NS.State.debug = true`, read the `NS.DebugLog` buffer (confirm the
    field name on the real instance). One case per refusal key (`MSG_COMBAT`, `MSG_NO_PGF`,
    `MSG_NOT_DUNGEONS`, `MSG_MINIMIZED`, `MSG_INACTIVE`, `MSG_BAD_LEVEL`/`AGE`, `MSG_LOADING`,
    `MSG_ALL_TIMED`, `MSG_DAMAGED`, `MSG_TOOLONG`), plus the success `wrote`/`search` lines and Clear
    refusal and success. The Clear refusal uses C-03's wrapped-without-close input and asserts
    `false, "MSG_DAMAGED"`. Red under: drop `done`.
  - `tests/test_apply.lua` C-28: at 171-183 the off path returns `extra == nil` and
    `NS.Apply.LastRange == nil` after an on-path Apply. Red under: skip the write instead of
    resetting it. The printed text has no "14-14". Red under: keep `%s`.
  - `tests/test_panel.lua`: show twice gives one "shown"; hide gives "hidden"; stand-down then
    stand-up gives "shown" again.
  - `tests/test_presets.lua`: save, load, delete and badName lines.
  - `tests/test_envinject.lua`: one spec line, unchanged on a repeat refresh.
  - `tests/test_setup.lua`: the enable writes one `[Init]` seams/hooks line.
- **Docs:**
  - `docs/debug.md`: the tag vocabulary (`Apply`, `Clear`, `Panel`, `Preset`, `Env`, `Init`).
  - `docs/data-flow.md:46-48`: `LastRange` is nil while targeting is off, and the message carries no
    range.

### C-21 + C-35 + C-23 — TOC, assets, AceTimer
- **C-21:**
  - `.toc:73` becomes a plain `# Modules` heading, with per-line annotations.
    - `modules\EnvInject.lua`: `# LOAD-BEARING: reads NS.addon, appends NS.FEATURE_EVENTS/NS.STAND_UP (core\PGFE.lua), calls NS.Bridge.InstallEnvHook (core\PGFBridge.lua) at load`.
    - `modules\Panel.lua`: `# LOAD-BEARING: reads NS.L (locales\enUS.lua) and NS.addon, appends NS.FEATURE_EVENTS/NS.STAND_DOWN/NS.STAND_UP (core\PGFE.lua), calls NS.Bridge.HookDialog (core\PGFBridge.lua) at load`.
    - `modules\RegionTags.lua`: `# Conventional (vs. addon files): hooks Blizzard Group Finder globals at load; reads NS.* at call time`.
    - `modules\EUISkin.lua` (extend :84-85): it also reads NS.L and appends FEATURE_EVENTS/STAND_UP.
    - `settings\Panel.lua`: `# LOAD-BEARING: reads NS.addon, NS.C (defaults\Profile.lua), Settings.Helpers (settings\OptionsSetup.lua), NS.SchemaRuntime.AddRows and Settings.StampClosureRows (settings\Schema.lua) at file scope`.
    - `settings\Slash.lua`: `# LOAD-BEARING: captures NS.SchemaRuntime.Get/Set/FindRow/ApplyDefault (settings\Schema.lua) and NS.Version (core\EnvSetup.lua) at load`.
    - The rest are `# Conventional:`.
  - Reword `core\PGFE.lua` (:49-50) to name the real NS.addon consumers. The settings header (:93)
    names its files, after checking `Profiles.lua`.
  - Sync `docs/module-map.md` "Load order and why", including `NS.STAND_UP`, and keep the
    `docs/ARCHITECTURE.md` `## Module Map` load-order summary (62-65) consistent with it.
- **C-35:**
  - Drop `"AceTimer-3.0"` from `NewAddon` (`core/PGFE.lua:9-10`) and the `.toc:22` line.
  - `git rm -r libs/AceTimer-3.0/`, with the commit message saying that removing a whole vendored
    folder is not editing it.
- **C-23:**
  - Commit (a) is a pure `git mv` of the three files to `premadegroupsfilterextension.logo.{128.tga,tga,png}`,
    plus `.toc:6`, `core/LauncherSetup.lua:13`, `settings/Panel.lua:18`, `tests/test_setup.lua:127`
    and `DEPENDENCIES.md:77-83`.
  - Commit (b) regenerates the landing TGA at 512×512 from the PNG with Pillow (uncompressed), and
    adds the recipe line and `file media/logos/*.tga` check to `DEPENDENCIES.md`.
- **Tests (red first), `tests/test_harness.lua`:**
  - For every non-library, non-locale TOC file line, the **first** line of the contiguous comment
    block directly above it starts `# LOAD-BEARING:`, `# Conventional` or `# LAST`. Three
    annotations already run over two lines (`core\PGFE.lua` toc:49-50, `modules\EUISkin.lua` :84-85,
    `settings\OptionsSetup.lua` :95-96), so "the line directly above" would fail on them. Red under:
    delete one annotation.
  - `NS.addon.ScheduleTimer == nil` (red today: the kit's AceAddon fake embeds AceTimer's mixins,
    `mock_base.lua:540`), and no line of the raw TOC (`io.open`) names `AceTimer-3.0`.
    `Loader.tocFiles` drops every `libs\` line (`tests/_kit/loader.lua:115-129`), so it cannot see
    `.toc:22`. Red under: restore the mixin or the TOC line.
- **Tests (red first), `tests/test_setup.lua`:**
  - `## IconTexture` equals the launcher ICON and ends `premadegroupsfilterextension%.logo%.128%.tga$`.
  - The 18-byte TGA headers give type 2 and 32 bpp, 128×128 for the icon and 512×512 for the landing.
    Red under: skip commit (b).
  - No `pgfe.logo` file exists.
- **Risk:** an in-game `/reload` smoke test confirms there is no LibStub error after the AceTimer
  removal. `.pkgmeta:18` (`media/logos/*.png`) still covers the renamed PNG.

### C-22 — reset tests (tests/test_reset.lua, tests/run.lua)
- **New suite:** `tests/test_reset.lua`, registered in `tests/run.lua` after `test_euisettings`.
  Its header cites PGE-10 / options-ui-§12 / launcher-§3. Cases:
  1. Two profiles: only the active one resets. The current key and the profile list survive, and
     the other profile keeps its value.
  2. `state.debugConsole` is swept from on to off.
  3. `global.minimap.shown = false` survives `RestoreAllDefaults` (hide stays true and the minimap
     button stays hidden). Two layers protect it: `db:ResetProfile()` leaves `global` alone and the
     walk reaches only `sessionOnly` rows (`Settings.VetoedFromResetAll`, `settings/Schema.lua:144`),
     and `resetExempt` vetoes it inside the bracket (`libs/LibKa0s/Schema.lua:649`). So dropping
     `resetExempt` alone leaves case 3 green. Red under: drop `resetExempt` **and** make
     `VetoedFromResetAll` veto only the profiles page.
  4. It also survives `H.RestoreDefaults("general")`, while the other General rows do reset
     (`filtersActive` back to true). This proves the Defaults path ran. Red under: drop
     `resetExempt` (`settings/Schema.lua:89`), the only layer on this path.
  5. Latch, corrected: `/pgfe disable`, then `RestoreAllDefaults`, gives `profile.enabled == true`
     and `HOLD_DISABLED` not held. Red under: drop the `Lifecycle:Set` in `reloadProfile`.
- **Risk:** the tests can only go red against a mutation, because the code reads correct today. Each
  case names its mutation.

## 5. The four new register rows (exact text)

They are appended to `docs/ARCHITECTURE.md` -> `## Documented deviations`, after the two existing
rows, in this order. The first three are the section 3 item 2 rows. The fourth is the
performance-§12 exemption (C-09, owner checkpoint D1); Task 15 replaces `<sweep-sha>` with the sha of
the plan's Task 8 Commit B, the commit that put the sweep in `docs/performance.md`.

```markdown
| architecture-§5 | The attached panel's per-character filter options (`char.filters`) and `profile.panelCollapsed` are set by the panel's own controls, outside the schema write seam, and no settings-page row or CLI path addresses them. Writers of `char.filters`: `Filters.Set`, `Filters.ToggleRegion` / `ClearRegions`, `Filters.TogglePlaystyle` / `ClearPlaystyles`, `Filters.ToggleComposition` / `ClearComposition` and `Filters.ApplySmartLevel` (`modules/Filters.lua`), reached from the panel controls and from `/pgfe apply` (`modules/Apply.lua` -> `ApplySmartLevel`), plus `Presets.Load` (`modules/Presets.lua`), which refills the table in place. Writer of `profile.panelCollapsed`: `setCollapsed` (`modules/Panel.lua`), from the min/max arrow and the header-strip click | Per-character scope is an owner requirement that the schema seam (profile and global roots only) cannot hold; presets snapshot and refill `char.filters` whole, keeping its identity; the panel is a feature surface attached to PGF's dialog, not a settings page (issue #10; audit `docs/audits/2026-10-10/` PGE-02) | 2026-10-10 (owner) | A filter option or `panelCollapsed` gains a settings-page row or a get/set CLI path, or LibKa0s-Schema gains a char root |
| architecture-§4, anti-patterns #19 | No AceEvent message bus, although the two-feature-module threshold is crossed (Apply, Panel, EUISkin, Filters, Presets, RegionTags, Targeting, EnvInject). Modules call each other through `NS`. The cross-module reactions: the shell's `reloadProfile` (`core/PGFE.lua`, on the three AceDB profile callbacks) fans out, in order, to `Settings.Helpers.RefreshAll` / `RefreshProfilesPage`, `Panel.Refresh`, the `enabled` latch re-read (`Lifecycle:Set` + `Reevaluate`) and `EUISkin.OnSwitch`; `Apply.OnFiltersToggled` (the `filtersActive` onChange) runs `Apply.Run` / `Apply.Clear` and then calls `Panel.Refresh`; `Panel.Create` / `Panel.UpdateVisibility` call `EUISkin.TryApply` | Every reaction has one sender and a required order that CallbackHandler's fan-out does not promise: `reloadProfile` must re-read the latch before the one-way EllesmereUI paint so a disabled incoming profile is never painted, and `Apply.OnFiltersToggled` must write or clear the PGF block before the panel readout refreshes. `reloadProfile` has several receivers, but none its sender should not know about, and with no messages defined the CallbackHandler clobber §4 guards against cannot occur (issue #10; audit `docs/audits/2026-10-10/` PGE-03) | 2026-10-10 (owner) | A reaction gains an order-independent receiver the sender should not name, a module outside the shell and Apply needs to hear profile-changed or filters-toggled, or the standard adds an ordered-dispatch carve-out |
| standalone-windows; library-stack-§8; options-ui-§15 | The attached panel (`modules/Panel.lua` `buildFrame`) takes PGF's dialog chrome when unskinned (`PortraitFrameTemplateMinimizable` with the `ButtonFrameTemplateNoPortraitMinimizable` border layout) and EllesmereUI's shell when skinned (`modules/EUISkin.lua`), not the Ka0s window edge. The skinned min/max control draws the Blizzard atlases `UI-QuestTrackerButton-Secondary-Collapse` and `UI-QuestTrackerButton-Secondary-Expand` (`EUISkin.lua` `COLLAPSE_ATLAS` / `EXPAND_ATLAS`) to match EllesmereUI's own minus and plus, not the LibKa0s catalog's minimize / expand glyphs (`libs/LibKa0s/Media.lua:94`). The panel is parented and anchored to PGF's dialog, is not movable and persists no geometry. The General page has no General visibility row (`settings/Panel.lua` `omit = { visibility = true }`): the panel shows only with PGF's dialog on the dungeon category, and the addon holds no visibility state | An extension surface must read as part of the host window it attaches to; its visibility is the host's, so a visibility setting would only duplicate Enable and `filtersActive` (issue #18; audit `docs/audits/2026-10-10/` PGE-17, PGE-19, PGE-26) | 2026-10-10 (owner) | The panel becomes independently shown or movable, or the standard gains an attached-panel or extension-surface rule |
| `performance-§12` | No performance harness is wired: no `core/PerfSetup.lua`, no `PremadeGroupsFilterExtensionPerfDB` (the TOC declares one SavedVariables global), no `perf` verb registration (`perf` stays reserved; `/pgfe perf` answers with the library's unknown-command line and the index), no suspend/resume contract (production takes only the `disabled` hold), and no `docs/perf-analysis/`. `libs/LibKa0s/` stays vendored whole, `Perf.lua` included, and `docs/performance.md` stays as the one-screen page. The offline `tests/perf.lua` is shipped anyway (it suspends nothing, ships nothing to the client and adds no SavedVariable), so the runner's `perf` suite reads `pass` rather than this exemption's skip | **Criterion (a) plus (b).** (a): the committed whole-repo sweep of `RegisterEvent` / `SetScript("OnUpdate"` / `C_Timer`, with every `hooksecurefunc` / `HookScript` site, in [`performance.md`](./performance.md), sweep at `<sweep-sha>`: no `OnUpdate` handler, no timer of any kind (AceTimer removed, C-35), one registration site over eight `NS.FEATURE_EVENTS` rows that each do one small refresh, hooks that run on the player's own Group Finder actions, and `Apply` refusing in combat; `tests/perf.lua`'s `combatEvents` scenario measures the per-event cost. (b): the capture windows open on the player's combat state (performance-§7), so every declared bucket would read `0.000` by construction. Owner checkpoint D1 (C-09, issue #5; audit `docs/audits/2026-10-10/` PGE-09) | 2026-10-10 (owner) | The first `OnUpdate` handler, repeating ticker, or in-combat event handler doing real work re-arms the full wiring MUST (performance-§12): wire `core/PerfSetup.lua`, `PremadeGroupsFilterExtensionPerfDB`, the `perf` verb and the suspend contract, and retire this row |
```

The fourth row's Rule cell is exactly `` `performance-§12` ``. The vendored runner
(`tests/_kit/run-automated-tests.sh:220-262`) reads a row as the exemption only when that cell,
lower-cased and stripped of backticks, whitespace and the section sign, equals `performance-12`; a
qualifier in the cell (WhatGroup's "(the exemption is not claimed)") makes it a different row. Its
cells contain no `|`, so the row splits into exactly the five header cells. Its Re-check trigger
uses the standard's own words, as performance-§12 requires.

The third row names the catalog glyphs in plain US English and cites `libs/LibKa0s/Media.lua:94` instead of quoting the catalog key, because the kit's prose gate (`tests/_kit/test_prose.lua`, localization-§5) scans every tracked doc and the key is spelled the British way. The same rule applies to every doc this run writes.

Before committing, check the cited symbol names against the code: `setCollapsed`, `buildFrame`,
`COLLAPSE_ATLAS`, `EXPAND_ATLAS`, `omit = { visibility = true }`, and the `reloadProfile` order
(`core/PGFE.lua:53-73`). If C-15 has moved the `filtersActive` onChange, the row still reads
correctly, because the onChange is unchanged.

## 6. Upstream issues (C-12, C-14, C-36, C-37)

They are filed with `gh issue create`. Bodies are in the plan (Task 6). Nothing is edited in those
repos.

**Severities.** The vocabulary row that makes the audit-carried issues here `severity:high` ("a
standard deviation carried out of an audit or review bundle") describes a repo's own departure from
the standard. The upstream issues are not that: they are defects in the shared test kit (C-12,
C-14 LibKa0s), an inaccurate hazard row in the standard's text (C-14 WowAddonStandards) and
enhancements to the standard (C-36, C-37). They take impact severities (C-12 `medium`, the rest
`low`), and each body says so for that repo's triager.

- **LibKa0s #A (C-12):** the complexity runner ignores lizard's exit status and parses a traceback as
  its footer. Proposed: `raw=… && cx_rc=0 || cx_rc=$?`, a footer shape check (8 numeric fields after
  `Total nloc`), skip parity and zero the `CCN_*` fields on failure, a bounded per-file retry naming
  the crashing file, `fld` forced numeric, fixture tests (traceback/exit 1, a stderr warning after
  the footer, exit 124), and kit revision 38 -> 39.
- **LibKa0s #B (C-14):** the sanitizer and parity do not recognize the file-scope for-in
  function-literal shape. Handle it in the runner (`crashed` rows, separate from `blind`), add an
  optional `S.forInFunctionLiterals(src)` detector, and fold it into #A's release.
- **WowAddonStandards #C (C-14):** the `automated-tests.md:155` hazard row says "not listed / folds",
  when at file scope lizard 1.24.0 raises and aborts. The remedy is the same (hoist to a named
  local). Patch bump.
- **WowAddonStandards #D (C-36):** add the `Ka0s Premade Groups Filter Extension` row to
  `standards/ADDONS.md` (`../../PremadeGroupsFilterExtension/`, launcher entries `Enabled`), sweep the
  "eleven addons" counts, patch bump. The body also surfaces that the `dev-copilot:wow-standards-audit`
  skill description ("the eleven addons") lives in the separate dev-copilot repo and needs a
  rule-based or dated count; nothing is filed on dev-copilot in this run.
- **Local tracker (C-12 fixNotes):** a `tusharsaxena/PremadeGroupsFilterExtension` issue, "Re-vendor
  LibKa0s after the complexity-runner fix", filed after #A and #B and cross-linked both ways. It
  names the re-vendor's contents: both payloads whole, the CLAUDE.md provenance line in the same
  commit, kit revision 38 -> 39, a complexity re-run. It stays open after this run.
- **WowAddonStandards #E (C-37):** slash-commands-§7 survivors: name one-shot third-party
  registrations that cannot be undone, whose bodies gate themselves and whose stand-up retries, with
  a matching conformance-test line.

Optional, asked at M3 and not filed by default: a LibKa0s `disabledReason()` descriptor field (C-16;
less pressing after D1, since production takes no second hold),
and a WowAddonStandards §4 ordered-dispatch carve-out (C-18).

## 7. Non-goals

- No edits to LibKa0s, WowAddonStandards or any sibling addon. No re-vendor of `tests/_kit/` or
  `libs/LibKa0s/` in this run; C-12/C-14 land here only after an upstream release. The deferred
  re-vendor is tracked by the local issue in section 6.
- No version bump, no release label on the automated-test run, and no tag.
- No message bus (C-18 is ratified), no char-rooted schema rows (C-17 is ratified), no catalog glyph
  swap and no General visibility dropdown (C-26/C-34 are ratified).
- No custom slash refusal wording (C-16 / PGE-12).
- No perf buckets, brackets or in-game Perf wiring (C-09 takes the performance-§12 exemption at
  D1), and no `docs/perf-analysis/` store.
- No runtime warning for an empty region selection (C-38).
- No changes to the frozen bundles `docs/audits/*`, `docs/reviews/*` (except this run's new
  `06_CONSOLIDATED_FINDINGS.md`) or `docs/automated-tests/<old stamps>/`, or to the historical
  2026-10-09 plans.
- Issues #1-#3 (feature requests) are not touched, not even for re-severity.
- No split of `tests/test_panel.lua`. It gets a Disposition instead (C-13).
