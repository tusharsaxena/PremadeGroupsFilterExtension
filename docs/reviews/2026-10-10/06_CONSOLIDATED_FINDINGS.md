# 06 — Consolidated findings (audit + review, 2026-10-10)

This file merges the 2026-10-10 standards audit (`docs/audits/2026-10-10/`, ids `PGE-nn`), the
2026-10-10 review (`docs/reviews/2026-10-10/01_FINDINGS.md`, ids `F-nnn`) and the open audit-carried
GitHub issues #4-#19 into one list of 39 findings, `C-01`..`C-39`. Each finding was checked against
the code at `0dabcde` on `fix/2026-10-10-audit-review`. All 39 are real and still present.

The `C-nn` ids belong to this file only. They are **not** the review bundle's own
`02_PROPOSED_CHANGES.md` change ids, which reuse the same letters for a different list.

- Spec: [`docs/superpowers/specs/2026-10-10-audit-review-fixes-design.md`](../../superpowers/specs/2026-10-10-audit-review-fixes-design.md)
- Plan: [`docs/superpowers/plans/2026-10-10-audit-review-fixes.md`](../../superpowers/plans/2026-10-10-audit-review-fixes.md)

## Owner decisions (2026-10-10)

- Every finding is fixed by **conforming** to the standard, with four exceptions (C-17, C-18, C-26,
  C-34). C-09 takes the standard's own performance-§12 exit, which is also recorded as a register row.
- **C-17**, **C-18**, and **C-26 + C-34** (one combined row) are ratified as rows in
  `docs/ARCHITECTURE.md` -> `## Documented deviations`.
- **C-15** conforms: the two extra rows move to a new General `Filters` tab.
- **C-09** (owner checkpoint D1, answered 2026-10-10): the **performance-§12 no-combat-path
  exemption**, not buckets. The perf wiring is removed, the combat-path sweep is committed, the
  offline `tests/perf.lua` is shipped anyway, and the exemption is recorded as a `performance-§12`
  row in `## Documented deviations`.
- **Upstream** items (C-12, C-14, C-36, C-37) are filed as GitHub issues on `tusharsaxena/LibKa0s` and
  `tusharsaxena/WowAddonStandards`. Other repositories are not edited. C-14 is cleared locally by
  C-02's hoist.
- **C-27**: label colors are set with `gh label edit`, and the audit-carried issues get new
  severities under the vocabulary.
- Fixed issues among #4-#19 are closed after the merge to `main`.

## Disposition key

| Disposition | Meaning |
|---|---|
| `fix-in-code` | Lua, TOC, asset or test change in this repo, red test first where possible |
| `register-row` | A ratified row in `docs/ARCHITECTURE.md` -> `## Documented deviations` |
| `upstream-issue` | A GitHub issue on LibKa0s or WowAddonStandards; nothing changes in this repo beyond what is noted |
| `github-admin` | A GitHub write on this repo (labels, issue edits); no repo file changes |
| `docs` | Documentation only in this repo |

## Summary table

Severity is the consolidated severity after verification. Verifier adjustments are noted in the
sections below.

| ID | Sev | Title | Sources | Issue | Files | Disposition |
|---|---|---|---|---|---|---|
| C-01 | medium | Pool-leaking HookScript on the PGF-skin link EditBox | PGE-27 | — | `settings/Panel.lua` `addPGFSkinLink` (163-179, call 239) | fix-in-code |
| C-02 | medium | lizard crashes on RegionTags' for-in header table; complexity unmeasured | PGE-24, F-001 | — | `modules/RegionTags.lua:64-69` | fix-in-code |
| C-03 | medium | `Expression.Strip` accepts a wrapped block whose close marker was deleted | F-003 | — | `modules/Expression.lua` `Strip` (68-87) | fix-in-code |
| C-04 | medium | Season and EnvInject read PGF's private namespace outside the bridge; `C.SPECIALIZATIONS` unchecked | F-004 | — | `core/PGFBridge.lua:27-35`, `modules/Season.lua:20-23`, `modules/EnvInject.lua:47-49`, `.luacheckrc:28-29` | fix-in-code |
| C-05 | medium | EllesmereUI paint does not check the facade shape and marks itself applied before painting | F-005 | — | `modules/EUISkin.lua` `blocked`/`TryApply`/`OnSwitch` (305-343), `onFacade` (385-390) | fix-in-code |
| C-06 | medium | Readout can re-request season map info on every `CHALLENGE_MODE_MAPS_UPDATE` | F-002 | — | `modules/Panel.lua:165-170`, `:866-884`; `tests/wow_mock.lua:80` | fix-in-code |
| C-07 | medium | Season-best data may never be requested when the map table is populated | issue | #6 | `modules/Season.lua:29-43`, `modules/Panel.lua:169`, `:882-884` | fix-in-code |
| C-08 | medium | `test_disabled.lua` is not the slash-commands-§7 ten-step suite | PGE-05, F-008 | #4 | `tests/test_disabled.lua` | fix-in-code |
| C-09 | medium | No perf buckets and no `tests/perf.lua` | PGE-09 | #5 | `core/PerfSetup.lua:37`, `modules/EnvInject.lua:60-68`, `modules/RegionTags.lua:48-60` | fix-in-code (performance-§12 exemption: wiring removed, `tests/perf.lua` shipped) + register-row (`performance-§12`) |
| C-10 | medium | Diagnostics reports declared state, not running state | F-013 | #7 | `modules/Diagnostics.lua:40-62`, `modules/EnvInject.lua:89`, `modules/Panel.lua:892`, `modules/RegionTags.lua:64-69`, `core/PGFBridge.lua` SEAMS | fix-in-code |
| C-11 | medium | 12 locale keys used but missing from `enUS.lua`; one key read by nothing | F-006 | — | `core/EUIBridge.lua:107-113`, `settings/Panel.lua:168`, `:211-216`, `locales/enUS.lua:166-167` | fix-in-code |
| C-12 | medium | [upstream LibKa0s] complexity runner ignores lizard's exit status | F-007, PGE-24 note | — | `tests/_kit/run-automated-tests.sh:508`, `:522` (vendored) | upstream-issue |
| C-13 | low | Automated-test record 38 commits stale; `test_panel.lua` in the 1000-1500 band; CLAUDE.md pointers dated | PGE-24 (record), review note | — | `docs/automated-tests/`, `CLAUDE.md:24-25` | docs |
| C-14 | low | [upstream LibKa0s + standard] sanitizer misses the for-in function-literal shape; the standard calls it a silent drop | F-017, PGE-24 upstream | — | `tests/_kit/lizard_sighted.lua` (vendored); WowAddonStandards `automated-tests.md:155` | upstream-issue (local half cleared by C-02) |
| C-15 | low | Master controls tab carries two non-canonical extra rows, justified by a mis-cited §16 | PGE-23 | — | `settings/Panel.lua:46-81`, `docs/settings-panel.md:11`, `:24-37` | fix-in-code |
| C-16 | low | Launcher Enabled entry reads the stand-down latch but writes the stored setting | PGE-11, PGE-12, F-015 | #14 | `core/LauncherSetup.lua:55-56`, `settings/Slash.lua:129` | fix-in-code |
| C-17 | low | `char.filters` and `panelCollapsed` written outside the seam and mis-filed as non-setting state | PGE-02 | #10 | `docs/ARCHITECTURE.md:108-116` | register-row |
| C-18 | low | Modules call each other directly with no bus and no architecture-§4 row | PGE-03 | #10 | `docs/ARCHITECTURE.md:120-122` | register-row |
| C-19 | low | Feature flows write no debug lines | PGE-04 | #11 | `modules/Apply.lua`, `Panel.lua`, `Presets.lua`, `EnvInject.lua`, `core/PGFE.lua` `OnEnable` | fix-in-code |
| C-20 | low | EUISkin hand-rolls a log-on-change memo instead of `DebugChanged` | PGE-25 | #11 | `modules/EUISkin.lua:45`, `:323-324` | fix-in-code |
| C-21 | low | TOC load-order annotations mislabel load-bearing files as conventional | PGE-06, -07, -08, -28 | #12 | `PremadeGroupsFilterExtension.toc:49-50`, `:73`, `:84-85`, `:93`, `:98-99`; `docs/module-map.md` | fix-in-code |
| C-22 | low | No test covers what *Reset all settings* reaches | PGE-10 | #13 | `tests/test_reset.lua` (new), `tests/run.lua` | fix-in-code |
| C-23 | low | Logo files named `pgfe.logo.*` instead of after the folder | PGE-13 | #15 | `media/logos/`, `.toc:6`, `core/LauncherSetup.lua:13`, `settings/Panel.lua:18`, `tests/test_setup.lua:127`, `DEPENDENCIES.md:76-84` | fix-in-code |
| C-24 | low | `DEPENDENCIES.md` omits Python 3 for `tools/realm_map_diff.py` | PGE-15 | #16 | `DEPENDENCIES.md:76`, `docs/realm-map-maintenance.md:41` | docs |
| C-25 | low | Player-facing English literals bypass `NS.L` | PGE-16, F-010 | #17 | `settings/Slash.lua`, `settings/Panel.lua:249-252`, `core/DebugLogSetup.lua`, `core/CoreSetup.lua`, `core/LauncherSetup.lua`, `core/PerfSetup.lua`, `settings/OptionsSetup.lua` | fix-in-code |
| C-26 | low | Attached panel uses PGF/EllesmereUI chrome and quest-tracker atlases with no register row | PGE-17, PGE-26 | #18 | `modules/Panel.lua:29`, `:767-771`; `modules/EUISkin.lua:33-34`, `:227` | register-row (combined with C-34) |
| C-27 | low | `state:`/`severity:` label colors miss the palette; audit-carried issues under-severitied | PGE-18 | #19 | GitHub labels | github-admin |
| C-28 | low | Apply's targeting-off message names a key range; `Apply.LastRange` has no production reader | F-009 | — | `modules/Apply.lua:15`, `:61-63`; `locales/enUS.lua:61` | fix-in-code |
| C-29 | low | Tooltip and glyph `OnLeave` handlers return early while stood down | F-011 | — | `modules/Panel.lua:96-99`, `:886-888`; `modules/EUISkin.lua:236-239`, `:369-373` | fix-in-code |
| C-30 | low (verifier: info) | Skin scale events run the relayout handler for every player | F-012 | — | `modules/EUISkin.lua:360-366` | fix-in-code |
| C-31 | low | `test_bridge` "commit with minimized dialog writes state only" asserts only negatives | F-014 | — | `tests/test_bridge.lua:60-64` | fix-in-code |
| C-32 | low | Env-hook region lookup trusts the leader name's type alone | F-016 | — | `modules/Regions.lua:46-51` | fix-in-code |
| C-33 | low | Strip/Clear is not byte-for-byte: blank edge lines dropped | issue | #9 | `modules/Expression.lua:5`, `:25-32`, `:86` | fix-in-code |
| C-34 | info | General visibility row omitted with no recorded decision | PGE-19 | #18 | `settings/Panel.lua:8-10`, `:51` | register-row (combined with C-26) |
| C-35 | info | AceTimer-3.0 embedded but unused | PGE-20 | — | `core/PGFE.lua:9-10`, `.toc:22`, `libs/AceTimer-3.0/` | fix-in-code |
| C-36 | info | [upstream standard] this addon is not a row in `standards/ADDONS.md` | PGE-21, F-018 | — | WowAddonStandards `standards/ADDONS.md` | upstream-issue |
| C-37 | info | [upstream standard] slash-commands-§7 survivor list does not name a one-shot third-party registration | PGE-29 | — | `modules/EUISkin.lua:382-395` | upstream-issue (+ local note in docs) |
| C-38 | info | Empty region selection means Any, but spec §6.3 says "ignored with a warning" | issue | #8 | `docs/superpowers/specs/2026-10-09-m-plus-v0.1-design.md:93` | docs |
| C-39 | info | Register rows' Why cells cite a plan decision, not a resolvable source | PGE-R02 observation | — | `docs/ARCHITECTURE.md:388-389` | docs |

**Counts:** 12 medium, 21 low, 6 info. By disposition: 26 fix-in-code, 3 register rows (four
findings, because C-26 and C-34 share one row), 4 upstream issues, 1 GitHub admin, 4 docs. C-09 is
counted as fix-in-code and also carries a fourth register row, the `performance-§12` exemption, so
the run appends four rows in all.

**Issue map:** #4 C-08 · #5 C-09 · #6 C-07 · #7 C-10 · #8 C-38 · #9 C-33 · #10 C-17 + C-18 ·
#11 C-19 + C-20 · #12 C-21 · #13 C-22 · #14 C-16 · #15 C-23 · #16 C-24 · #17 C-25 ·
#18 C-26 + C-34 · #19 C-27. Issues #1-#3 are feature requests and are out of scope.

---

## Findings

### C-01 — Pool-leaking HookScript on the PGF-skin link EditBox (medium)
`addPGFSkinLink` hooks `OnEditFocusGained` on a pooled AceGUI EditBox's frame. It never unhooks it
and sets no `OnRelease`. After a re-render, the next EditBox from the pool (the Profiles *New* box, or
another addon's) selects all its text on focus, and every render adds one more hook. This breaks
options-ui-§19 and anti-pattern #93. **Fix:** hook once per frame under `__pgfeLinkHook`, gate the
body on `__pgfeLinkActive`, and clear the flag and `Settings.PGFSkinLinkBox` in the box's `OnRelease`.
Tests go in `tests/test_euisettings.lua`. Leave `tests/_kit` and `tests/wow_mock.lua` alone. The
kit's AceGUI EditBox fake has no `editbox` frame (`tests/_kit/mock_base.lua` `makeWidget`), so
`box.editbox` is nil under the harness and today's hook never runs there. Each test wraps the AceGUI
lib's `Create("EditBox")` so the widget carries a `m.__stubFrame()`, which does chain `HookScript`.

### C-02 — lizard crashes on RegionTags' for-in header table (medium)
A table of function literals inside a file-scope `for … in pairs({ … })` header makes lizard 1.24.0
raise `TypeError`. As a result, all 54 files read as blind and the complexity suite fails. That blocks
the release tag (automated-tests-§3). **Fix:** hoist the table to `local PAINTER_HOOKS = { … }`, with a
comment saying why. `tests/test_regiontags.lua` is the characterization and runs unchanged. Then
confirm complexity passes with `blindFiles` 0. This also clears C-14's local half.

### C-03 — Strip accepts a wrapped block with its close marker deleted (medium)
In the wrapped form (`… and (`), deleting `-- [pgfe] close` but keeping its `)` lets Strip report
`ok`. Merge and Clear then hand PGF an unparseable expression, and Apply and Clear still report
success. **Fix (Strip only, not Normalize):** set a `wrapped` flag when the begin block's last body
line ends in `and (`. Set `closed` when a close + `)` pair is consumed. Refuse with `text, false` when
the block is wrapped and never closed. Deleting both the marker and its `)` is now also refused. That
is the conservative choice, and the docs record it.

### C-04 — PGF private namespace read outside the bridge (medium)
`modules/Season.lua` reads `PremadeGroupsFilter.Debug.C.MAP_ID_TO_KEYWORDS`, and
`modules/EnvInject.lua` reads `C.SPECIALIZATIONS`. Neither is in `Bridge.SEAMS`. If PGF renames
`SPECIALIZATIONS`, the same-spec exclusion silently passes every group. **Fix:** add
`Bridge.Specializations()` and `Bridge.MapKeywords(mapID)`, plus a `C.SPECIALIZATIONS` SEAMS row
(MAP_ID_TO_KEYWORDS stays unchecked because it is cosmetic). Switch both modules to the accessors and
correct `.luacheckrc` and the ARCHITECTURE PGF-seams table (six seams become seven, plus the
unchecked row).

### C-05 — EllesmereUI paint unchecked and marked applied first (medium)
`TryApply` sets `applied = true` and then paints without a pcall. Nothing checks the 12 facade
primitives. A missing primitive leaves a half-painted panel that is never retried, and it loses the
first show. **Fix:** add a `REQUIRED` primitive list checked in `blocked()`, pcall the paint, set
`applied` only on success, and add a `paintFailed` session latch so nothing double-paints. `OnSwitch(false)`
asks for a reload on `applied or paintFailed`. The mock gains `spec.omit`.

### C-06 — Season map info re-requested every round trip (medium)
`updateReadout` calls `RequestMapInfo()` whenever `GetDungeons()` is nil, and the event that answers
the request re-enters `updateReadout`. **Fix:** one guard, shared with C-07 and moved into Season.
It is re-armed on `PLAYER_ENTERING_WORLD` and on the full -> empty rollover. "Re-arm when data
arrives" merges into that rollover re-arm: with C-07's request at the top of every `GetDungeons()`
call, re-arming on each full read would request on every call. The "was full" memory is cleared on
the reset and the request goes out in the same call, so one rollover event sends exactly one
request (spec C-06 state machine; the "MAPS_UPDATE ×2 adds exactly 1" test guards it). The mock
counts requests. This has not been verified in the client (smoke test).

### C-07 — Season bests never requested when the map table is populated (medium, #6)
The only request sits on the nil branch, so a populated table with bests not yet loaded reads as
all-zero. Apply then ticks every dungeon. `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE` (spec §11) is not
registered. **Fix:** `Season.RequestOnce()` is called at the top of `Season.GetDungeons()`, so all
three callers trigger it. The event is registered through `NS.FEATURE_EVENTS`. Whatever gap is left
goes under Known Limitations.

### C-08 — `test_disabled.lua` is not the ten-step suite (medium, #4)
The probe event shadows `OnPanelEnteringWorld`. The real events are never asserted by name, and only
`version`/`list` are dispatched. There are no `-- red under:` notes. **Fix:** rewrite the suite to
slash-commands-§7's ten steps, on the kit recorders (`__registrations`, `__timers`, `__shownFrames`,
`__svWrites`, `__printed`, `__fireUnconditional`), with the final event names pinned. It runs last
among the code tasks.

### C-09 — No perf buckets, no `tests/perf.lua` (medium, #5)
`buckets = {}`, nothing is bracketed, and the perf suite records `skip`, which leaves the release gate
open. Both fixes were inside the standard, so the owner was asked at checkpoint D1 (plan Task 0)
before Task 8. **Disposition (owner, D1, 2026-10-10): the performance-§12 no-combat-path exemption,
not buckets.** The addon runs no code in combat, and the capture windows open on combat state, so
any bucket would read `0.000` in every capture (performance-§3, §12 criterion (b)). **Fix:** remove
`core/PerfSetup.lua`, `PremadeGroupsFilterExtensionPerfDB`, the `perf` verb registration and
`NS.HOLD_PERF` (`perf` stays a reserved, unregistered verb, and `libs/LibKa0s/` stays vendored whole);
commit the whole-repo combat-path sweep in `docs/performance.md` (criterion (a)); delete
`docs/perf-analysis/README.md`; ship the offline `tests/perf.lua` anyway (allocation and call-count
assertions only, outside the commit gate), so perf reads `pass` at the release gate; and record the
exemption as a `performance-§12` row in `## Documented deviations` citing the sweep commit, with
the standard's re-arm trigger. The spec's C-09 section and section 5 have the detail and the row
text.

### C-10 — Diagnostics reports declared, not running, state (medium, #7)
The report has no `Bridge.Check()` line and no hook-install results, the filter options are missing,
and the feature-event list prints the same while stood down. **Fix:** store `EnvInject.hooked`,
`Panel.dialogHooked` and `RegionTags.hooked[name]`. Diagnostics then gains a seams line, a hooks line,
a `filters` section and the declared/registered wording. Add the structural SEAMS rows `d.panels`,
`p.Dungeons` and `Advanced.Expression.EditBox` (not `activeId`/`activeState`), so #7 closes in full.

### C-11 — 12 missing enUS keys, one dead key (medium)
Six `PGF_TEXT` keys in `core/EUIBridge.lua` and six `settings/Panel.lua` keys render only through
the `__index` fallback, and `enUS.lua:166-167` is read by nothing (localization-§3 MUST NOT).
**Fix:** define the 12 keys byte for byte and delete the dead key. Add a static two-way key-parity
test, with a dynamic-prefix allowlist (`MSG_*`, the `REGION_TIP_*`/`PLAYSTYLE_*` families).

### C-12 — [upstream] complexity runner ignores lizard's exit status (medium)
On a crash, `run-automated-tests.sh` parses a traceback as the eight-field footer. The result is
garbled notes, all-files blame, and a `manifest.json` that may not be valid JSON. **Disposition:**
file a LibKa0s issue (capture the status, check the footer's shape, name the crashing file, force
numeric fields, bump the kit revision). Nothing changes in this repo until a release is re-vendored,
which is out of scope for this run. A local issue, "Re-vendor LibKa0s after the complexity-runner
fix", is filed after the upstream issues and cross-linked to them, so the deferred re-vendor is
tracked.

### C-13 — Automated-test record stale (low)
The newest record (`20261009-082905`, sha `2c78ddb`) is 38 commits behind and shows 186/187 tests.
`tests/test_panel.lua` (1061 lines) sits in the 1000-1500 band with no Disposition, and `CLAUDE.md`
names the 2026-10-09 bundles. **Fix:** as the last task, run the full battery through the vendored
runner (a non-release run), write a band Disposition for every file the run puts in the band
(`tests/test_panel.lua` "on notice"; this run may push others in, such as `tests/test_apply.lua` or
`modules/Panel.lua`), and point `CLAUDE.md` at the 2026-10-10 bundles and the new record, naming the
issues that closed the findings (#4-#19) and the upstream issue numbers.

### C-14 — [upstream] sanitizer misses the for-in function-literal shape (low)
The kit sanitizer leaves the shape alone, and the standard's hazard row (`automated-tests.md:155`)
calls it a silent drop when in fact it crashes the run. **Disposition:** a LibKa0s issue (handle it
in the runner, an optional detector, folded into C-12's release) and a WowAddonStandards issue (rewrite
the hazard row, patch bump). Locally, C-02's hoist removes the trigger.

### C-15 — Master controls carries two extra rows (low)
`filtersActive` and `showRegionTags` ride in `MasterControls{ extra = … }`, justified by a mis-cited
§16. **Fix (owner: conform):** declare `FILTER_ROWS` with `group = L["Filters"]`, added after
`MASTER_ROWS` and before `EUI_ROWS`, so the General tabs read **Master controls | Filters |
EllesmereUI skin**. Paths are unchanged, so no migration is needed. Correct the §16 citations in
code, `docs/settings-panel.md`, `docs/schema.md`, `docs/ARCHITECTURE.md:100`, `defaults/Profile.lua`
comments and `docs/smoke-tests.md`.

### C-16 — Launcher reads the latch, writes the setting (low, #14)
During a perf hold the launcher shows *Enabled: No* while the stored value is `true`, and clicking
writes `true` again. After C-09's D1 answer production takes no perf hold, so that symptom can no
longer occur; the fix stays because launcher-§1 requires the tooltip to read the same accessor as
the Master-controls row, and that row reads the stored setting.
**Fix:** `isEnabled = function() return NS.SchemaRuntime.Get("enabled") ~= false end`.
The Slash descriptor keeps the latch read. PGE-12's wording (now unreachable in production) is
accepted under the SHOULD, because the refusal line belongs to the library. The commit message
says so, and a `disabledReason` idea may be raised upstream later. Tests go in `tests/test_disabled.lua`.

### C-17 — `char.filters` / `panelCollapsed` mis-filed (low, #10) — register row
Panel controls set both outside the schema seam, and ARCHITECTURE files them as named non-setting
state. **Owner: ratify** an architecture-§5 row that names every writer, and move them out of
*Named non-setting state*. The exact row text is in the spec.

### C-18 — No message bus, no architecture-§4 row (low, #10) — register row
The two-feature-module threshold is crossed, and `## Message Bus` says only "None". **Owner: ratify**
an architecture-§4 row. The Why must be accurate: `reloadProfile` fans out to several receivers
(settings refresh, `Panel.Refresh`, the latch re-read, `EUISkin.OnSwitch`), so the reason is
*ordering*, not single-receiver. Rewrite `## Message Bus` to cite the threshold and the row.

### C-19 — Feature flows write no debug lines (low, #11)
Apply and Clear refusals, the write pass, the search, panel edges, presets, the spec refresh and the
enable summary are all silent (debug-logging-§8 MUST). **Fix:** route Apply and Clear returns through
one local `done(tag, ok, key, …)`. Add `DebugChanged` for panel visibility, with a forget on the
STAND_DOWN hide. Presets log in `Presets.Save/Load/Delete`. EnvInject logs a spec `DebugChanged`. An
`[Init]` `DebugAtEnable` line reports seams and hooks. The STAND_DOWN forget is `NS.DebugLog.DebugForget`: only `Debug`,
`DebugOnce`, `DebugChanged` and `DebugAtEnable` are published bare (`core/DebugLogSetup.lua:119-122`). The per-result env hook and the row painters
stay silent.

### C-20 — Hand-rolled log memo in EUISkin (low, #11)
`lastSkip` survives a console Clear and also memoizes while logging is off. **Fix:**
`NS.DebugChanged("euiskin.skip", TAG, "skipped: %s", why)`, with the key first, per
`DebugLogGates.lua:139`. Delete `lastSkip`.

### C-21 — TOC annotations mislabel load-bearing files (low, #12)
`modules\EnvInject.lua`, `modules\Panel.lua`, `settings\Panel.lua` and `settings\Slash.lua` do work
at load, and the TOC does not say so. **Fix:** give every line its own annotation naming the real
source files. Correct the `core\PGFE.lua`, `EUISkin` and settings-header comments, sync
`docs/module-map.md`, and add a TOC-annotation test to `tests/test_harness.lua`.

### C-22 — No test covers *Reset all settings* (low, #13)
**Fix:** a new `tests/test_reset.lua` with five cases. Two profiles: only the active profile resets.
The session row is swept. The minimap survives the reset and the page Defaults. A latch case,
corrected: resetting a disabled profile **releases** `HOLD_DISABLED`. Written after C-15.

### C-23 — Logo file names (low, #15)
**Fix:** a pure `git mv` to `premadegroupsfilterextension.logo.{128.tga,tga,png}`, updating every
reference including `tests/test_setup.lua:127`. Then a separate commit regenerates the landing TGA at
512×512 (uncompressed, type 2, 32 bpp). Add asset tests. Narrow #15 to PGE-13 first.

### C-24 — Python 3 missing from DEPENDENCIES (low, #16)
**Fix:** add a maintenance entry for `python3` (stdlib only) used by `tools/realm_map_diff.py`, drop
the "One entry" count, add the lizard source-shape note, and point to it from
`docs/realm-map-maintenance.md`.

### C-25 — English literals bypass `NS.L` (low, #17)
**Fix:** move every player-facing literal (Slash, Panel `defaultsTooltip`/`General`, DebugLog stub,
the `LIBKA0S_MISSING` "…, so X is unavailable." family) into whole-sentence `%s` keys. Keep
`DISABLED_LINE_FORMAT`, brand names, verb tokens and color escapes as they are. The `test_prose`
gate does **not** cover this, so add a sentinel-locale test.

### C-26 — Attached panel chrome and atlases (low, #18) — register row (with C-34)
The panel takes PGF's dialog chrome (unskinned) and EllesmereUI's shell (skinned), with
`UI-QuestTrackerButton-Secondary-Collapse`/`-Expand` atlases. **Owner: ratify** one combined row
(`standalone-windows; library-stack-§8; options-ui-§15`) that names the atlases explicitly.

### C-27 — Label palette and re-severity (low, #19)
**Fix:** `gh label edit` the eight labels to the mandated palette. Then re-severity #4-#19 under the
vocabulary (an audit or review-carried deviation is `severity:high`). Leave #1-#3 alone. The
upstream issues (C-12, C-14, C-36, C-37) are not this repo's deviations but defects and
enhancements in the kit and the standard, so they take impact severities; the spec section 6
records why.

### C-28 — Targeting-off message names a range (low)
**Fix:** `Apply.LastRange = targets and NS.Targeting.RangeText(f.keyLevel) or nil`. Return
`true, "MSG_APPLIED_NO_TARGETING"` with no argument. The locale string becomes "Applied (dungeon
checkboxes left as they were)." Update the doc comment and `docs/data-flow.md`.

### C-29 — `OnLeave` gated while stood down (low)
**Fix (conformant route (a), every gate kept):** the Panel `STAND_DOWN` row hides `GameTooltip` when
its owner is a panel widget (the owner walk carries a self-parent guard, and `tests/wow_mock.lua`
gains `GameTooltip` owner recorders, because the kit's bare frame answers `GetOwner()` with
itself). EUISkin resets each min/max glyph to `GLYPH_ALPHA` in a stand-down or
stand-up row.

### C-30 — Scale handler runs without a paint (low; verifier: info)
**Fix:** `if stoodDown() or not applied then return end` in `OnEUISkinScale`, with a comment. The
rows stay in `NS.FEATURE_EVENTS`. A red test is not possible, because the change has no observable
effect. Add a smoke test only.

### C-31 — test_bridge minimized case asserts only negatives (low)
**Fix:** rename it "commit with minimized dialog leaves PGF's live panel alone", add the red-under
note, and assert the stored `state.c2f4.dungeon` writes persist. No production change.

### C-32 — Region lookup trusts the type alone (low)
**Fix:** `if type(leaderName) ~= "string" or not NS.IsConcatSafe(leaderName) or leaderName == "" then return nil end`,
looked up at call time. Optionally move it after the `GetPortal()` nil-return to save the
per-result pcall. Update the "a type check, not a pcall" comment.

### C-33 — Strip drops blank edge lines (low, #9)
Merge adds no separator, so the whole fix is `return table.concat(out, "\n"), true`, deleting
`trimBlankEdges`. The header comment changes to "kept line for line (CRLF is normalized to LF)".
Lands with C-03.

### C-34 — General visibility omitted without a decision (info, #18) — register row (with C-26)
A visibility dropdown would only duplicate Enable and `filtersActive`. **Owner: ratify** inside
C-26's combined row (rule `options-ui-§15`).

### C-35 — AceTimer-3.0 unused (info)
**Fix:** drop the mixin, the TOC line and `libs/AceTimer-3.0/` (removing a whole vendored folder is
not editing it). Add harness asserts that `NS.addon.ScheduleTimer == nil` and that no line of the raw
TOC names AceTimer (`Loader.tocFiles` skips `libs\` lines, so it cannot see it).

### C-36 — [upstream] missing ADDONS.md row (info)
**Disposition:** a WowAddonStandards issue: add the `Ka0s Premade Groups Filter Extension` row
(launcher entries `Enabled`), sweep the "eleven addons" counts, patch bump. The issue also surfaces
that the `dev-copilot:wow-standards-audit` skill description carries the same count in the separate
dev-copilot repo (not filed in this run).

### C-37 — [upstream] §7 survivor list (info)
`EllesmereUI.RegisterSkin(…, onFacade)` cannot be undone, and its body gates itself. **Disposition:**
a WowAddonStandards issue (name one-shot third-party registrations among the §7 survivors). Locally,
add one sentence to the ARCHITECTURE stand-down notes. This is not a register row.

### C-38 — Spec §6.3 out of date on empty regions (info, #8)
**Fix:** amend the spec line (`2026-10-09-m-plus-v0.1-design.md:93`) to the shipped Any semantics,
where none selected or all selected means no clause and no warning. Add a full-selection
`ToClauseOpts` case to `tests/test_filters.lua` if it is missing. No warning is added, because Any
is an owner requirement.

### C-39 — Register Why cells cite unresolvable decisions (info)
**Fix:** point the EllesmereUIDB row's Why at `docs/superpowers/plans/2026-10-09-eui-skin.md` ->
`## Owner decisions (2026-10-09)` (step 6a). Point the PGF-dependency row at the M+ v0.1 spec section
that states the hard dependency, or at `docs/audits/2026-10-09/`. Checked: the M+ v0.1 spec states it
in `## 1. Intent` item 5 and records the deviation in `## 2`; cite both. Leave the other cells
unchanged.
