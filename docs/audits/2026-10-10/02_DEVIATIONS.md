# 02 — Deviations: Ka0s Premade Groups Filter Extension

Audited against **Ka0s WoW Addon Standard v2.78.0 (2026-10-09)** at commit `5decd65`. The prefix is
**`PGE`**, reused from `docs/audits/2026-10-09/`. Recurring deviations keep their IDs, and new ones
start at PGE-23. Evidence ids (`E<n>`) point into `03_EVIDENCE.md`.

## Tally, with its basis

Grades are **impact**, not rule strength (AUDIT.md step 5). Dependents (`derived from <ID>`) are left
out of the headline and the root MUST count. The two recorded deviations (PGE-R01, PGE-R02) are
accepted and appear in neither count. The three closed deviations (PGE-01, PGE-14, PGE-22) are listed
at the end and are not counted.

| | High | Medium | Low | Info | Total |
|---|---|---|---|---|---|
| **Headline — roots only** | 0 | 1 | 16 | 4 | **21** |
| Total including dependents | 0 | 1 | 21 | 4 | **26** |

| MUST failures | High | Medium | Low | Total |
|---|---|---|---|---|
| **Headline — roots only** | 0 | 1 | 14 | **15** |
| Including dependents | 0 | 1 | 18 | **19** |

- **Root MUST failures (15):** PGE-02, -03, -04, -05, -06, -09, -10, -11, -13, -15, -17, -18, -23,
  -24 and -27.
- **Root SHOULDs:** PGE-16 and PGE-25.
- **Info:** PGE-19, -20, -21 and -29.
- **Dependents (5):** PGE-07, -08 and -28 under PGE-06, and PGE-26 under PGE-17, each a MUST.
  PGE-12 under PGE-11 is a SHOULD.

**Verdict: minor deviations.** No user can hit an error or lose data today. There is one Medium: an
AceGUI EditBox hook that rides the frame pool into other edit boxes. The rest is structure, tests,
docs and the release record. The disabled-state stand-down is still **compliant**.

**Since 2026-10-09:**

- **Three deviations closed:** PGE-01 (the spec readers go through `NS.Compat`), PGE-14 (the landing
  page is the library's `BuildLandingPage` at 300) and PGE-22 (the `CLAUDE.md` pointer).
- **Seven new IDs:** four new roots (PGE-23, -24, -25, -27), one new Info (PGE-29) and two new
  dependents (PGE-26, -28). Each comes from code added after `58156ca` or from v2.78.0's
  options-ui-§19.
- **Not one of the 2026-10-09 findings tracked as issues #4–#19 has been closed on GitHub.** That
  includes #15, which still carries the fixed PGE-14.

## Recorded deviations (accepted, not counted)

| ID | Rule | What | Register row | Status |
|---|---|---|---|---|
| PGE-R01 | `library-stack-§6`, `toc-file-§1` | Hard `## Dependencies: PremadeGroupsFilter`; reads/writes PGF state and hooks PGF's env builder (anti-patterns #13, #29) | `docs/ARCHITECTURE.md:389`, Decided 2026-10-09, trigger "PGF ships a public API, or the standard gains an extension-addon rule" | **Accepted.** Both rules unchanged at v2.78.0; trigger not fired; no evidence id to resolve (E1). |
| PGE-R02 | `library-stack-§6`, anti-patterns #29 | `core/EUIBridge.lua` reads `EllesmereUIDB.thirdPartySkinsOff` / `thirdPartySkinAddons[...]`, read-only, call-time, nil-guarded | `docs/ARCHITECTURE.md:388`, Decided 2026-10-09, trigger "EllesmereUI ships a public query … or the standard gains a carve-out …" | **Accepted (new row).** The rule still forbids reading a suite's SavedVariables; the trigger has not fired; the reads are confined to `core/EUIBridge.lua:43-66` (E1). Observation: the Why cell cites "owner decision 1" (the plan), not an issue or bundle (documentation-§3 SHOULD). |

## Deviations

| ID | Section | Grade | MUST/SHOULD | Description | Fix direction |
|---|---|---|---|---|---|
| **PGE-02** | `architecture-§5` | Low | MUST | **Carried (issue #10).** Controls set the nine `char.filters` options and `profile.panelCollapsed`: checkboxes, number boxes, the multi-selects, the min/max button, **and now the header-strip click** (`modules/Panel.lua:712`, `:743`). The writes happen outside the seam, yet `docs/ARCHITECTURE.md:108-116` files them as *named non-setting state*. Class (f): there is no schema row and no register row (E4). | Either route them through the seam (rows with a `char`-rooted `resolveRoot`, or a profile row for `panelCollapsed`), or add one register row citing `architecture-§5` with a re-check trigger. Correct the Settings Schema text either way. |
| **PGE-03** | `architecture-§4` | Low | MUST | **Carried (related to #10).** The threshold (two or more feature modules) is crossed, and the new skin adds real reactions to another module's change: Panel → `EUISkin.TryApply` (`modules/Panel.lua:807`, `:845`), the profile reload → `EUISkin.OnSwitch` and `Panel.Refresh` (`core/PGFE.lua:60`, `:70`), and `filtersActive` → `Apply.OnFiltersToggled` → `Panel.Refresh` (`modules/Apply.lua:90`). `## Message Bus` says only "None …" and carries no register row (E5). Anti-pattern #19. | Adopt `LibKa0s-Bus-1.0` for the two reactions (profile changed, filters toggled), or add a register row citing `architecture-§4` with the trigger *the first fan-out to two receivers*. |
| **PGE-04** | `debug-logging-§8` | Low | MUST | **Carried (issue #11).** `modules/Apply.lua`, `modules/Panel.lua`, `modules/Presets.lua`, `modules/EnvInject.lua` and `modules/RegionTags.lua` write no `NS.Debug` line. The only host flow lines are the profile callbacks and the new skin's three (E6). A support read still cannot see why Apply refused. | One gated line per Apply/Clear refusal (naming the guard), per bridge write pass, per panel show/hide edge, per preset mutation; `DebugAtEnable` for the PGF seam check and PremadeRegions. |
| **PGE-05** | `slash-commands-§7` (*The conformance test every addon ships*), `testing-§12` | Low | MUST | **Carried (issue #4).** `tests/test_disabled.lua` is unchanged since `58156ca`. Its probe event is registered *on top of* the real `PLAYER_ENTERING_WORLD` row (`:16`), and AceEvent keeps one handler per event, so the probe replaces `OnPanelEnteringWorld`. The other six real events are never asserted by name. There is no timer, shown-frame, every-event-zero-writes, launcher or setting-changed-while-off step, and no `red under:` comments. Step 7 dispatches `version` and `list` only (`:63-72`), never `diagnostics` or `debug diagnostics`, which AUDIT.md's diagnostics check item 3 requires (E7). | Rewrite to the ten steps against the real `NS.FEATURE_EVENTS` snapshot, including the two skin events and the region-tag and skin hooks firing as no-ops while down. Dispatch both diagnostics forms and every `NS.COMMANDS` verb. Add the falsification comments. |
| **PGE-06** | `toc-file-§5` | Low | MUST | **Carried (issue #12).** `modules\EnvInject.lua` reads `NS.addon`, appends to `NS.FEATURE_EVENTS`/`NS.STAND_UP` and calls `NS.Bridge.InstallEnvHook` at file scope (`modules/EnvInject.lua:73`, `:83-85`, `:89`). The `# Modules` group comment (`PremadeGroupsFilterExtension.toc:73`) still says "reads others at call time" (E8). | Annotate the line with what resolves and correct the group comment. |
| PGE-07 | `toc-file-§5` | Low | MUST | **derived from PGE-06.** `modules\Panel.lua` takes `NS.L`/`NS.addon` at file scope, appends events and calls `NS.Bridge.HookDialog` at load (`modules/Panel.lua:26`, `:861`, `:882-888`, `:892`) (E8). | Same annotation fix. |
| PGE-08 | `toc-file-§5` | Low | MUST | **derived from PGE-06.** `settings\Slash.lua` is annotated "Conventional … resolve everything at call time" (`.toc:99`), but it captures `NS.SchemaRuntime.Get/Set/FindRow/ApplyDefault` into the descriptor at load (`settings/Slash.lua:136-140`) (E8). | Re-annotate as LOAD-BEARING on `settings\Schema.lua`. |
| PGE-28 | `toc-file-§5` | Low | MUST | **derived from PGE-06 (new).** `settings\Panel.lua` (`.toc:98`) carries no comment of its own. At file scope it reads `NS.addon`, `NS.C` and `Settings.Helpers`, calls `Helpers.MasterControls` and twice calls `NS.SchemaRuntime.AddRows` (`settings/Panel.lua:12-15`, `:46`, `:81`, `:113`, `:266`). The OptionsSetup line above names the dependency from the other side only (E8). | Add a LOAD-BEARING line naming `Settings.Helpers` (`settings\OptionsSetup.lua`) and `NS.SchemaRuntime` (`settings\Schema.lua`). |
| **PGE-09** | `performance-§9` (with `performance-§2`) | Low | MUST | **Carried (issue #5).** The harness is wired, but `buckets = {}` (`core/PerfSetup.lua:37`), nothing is bracketed and there is no `tests/perf.lua`. Every run records `perf: skip`. The per-row `RegionTags` hooks are now a second unmeasured per-search path beside the env hook (E9). | Bracket the env hook (and the two row hooks) with declared buckets and ship `tests/perf.lua` with the zero-overhead scenario. Or claim the `performance-§12` exemption in full. |
| **PGE-10** | `options-ui-§12` (Testing), `launcher-§3` | Low | MUST | **Carried (issue #13).** The only test that reaches `RestoreAllDefaults` checks that `euiSkin` comes back on (`tests/test_euisettings.lua:144-150`). Nothing asserts the blast radius: other profiles survive, session rows are swept, the minimap row survives both resets, and `OnProfileReset` re-reads the latch (E10). | Add the reset cases (two profiles, `minimap.hide = true`, console row on, `enabled = false` in the reset profile). |
| **PGE-11** | `launcher-§1`, `launcher-§2` | Low | MUST | **Carried (issue #14).** The launcher's `isEnabled` is `not NS.IsStoodDown()` (`core/LauncherSetup.lua:55`). During a perf hold the tooltip and menu say disabled while the Enable row reads `true` (E11). | Read the Enable row's accessor (`NS.SchemaRuntime.Get("enabled") ~= false`). |
| PGE-12 | `slash-commands-§7` (*The refusal line*) | Low | SHOULD | **derived from PGE-11.** The Slash `isEnabled` is the same latch read (`settings/Slash.lua:129`). During a perf hold `apply`/`clear` print "… enable it with /pgfe enable", and that verb changes nothing (E11). | Decide with PGE-11. |
| **PGE-13** | `layout-§4`, `toc-file-§1` | Low | MUST | **Carried (issue #15).** The logo files are still `pgfe.logo.*`. layout-§4 names them after the folder, lowercased. They are referenced at `.toc:6`, `core/LauncherSetup.lua:13` and `settings/Panel.lua:18`. The format is correct (E12). | `git mv` the three files and update the three references and `DEPENDENCIES.md`. Regenerate the landing logo at 512 while renaming (it is now 256 drawn at 300). |
| **PGE-15** | `documentation-§7` | Low | MUST | **Carried (issue #16).** `DEPENDENCIES.md:76` still reads "**One entry: Python 3 with Pillow**". `tools/realm_map_diff.py` (run as `python3 tools/realm_map_diff.py`, `docs/realm-map-maintenance.md:41`) is still unlisted. Anti-pattern #50 (E13). | Add a Python 3 (stdlib) row naming the tool and its verify command, and reword "One entry". |
| **PGE-16** | `localization-§1` (routing), `localization-§3` | Low | SHOULD | **Carried (issue #17), with new sites.** User-facing literals still bypass `NS.L`: `settings/Slash.lua:84`, `:88`, `:150`, `:171-172`, `:188`; `settings/Schema.lua:106`, `:110`; `settings/Panel.lua:251-252` (the Defaults tooltip; the old `:116` citation has moved); `core/DebugLogSetup.lua:55`, `:61`. Meanwhile `docs/scope.md:52` says "strings go through `NS.L`" (E14). | Route them through `NS.L`, or register the English-only decision with the trigger *the first non-English locale*. |
| **PGE-17** | `standalone-windows` (*The Ka0s window edge*) | Low | MUST | **Carried (issue #18).** The attached panel is still `PortraitFrameTemplateMinimizable` with `ButtonFrameTemplateNoPortraitMinimizable` (`modules/Panel.lua:29`, `:767`, `:771`). When skinned it becomes EllesmereUI's shell. Neither look is the Ka0s window edge, and no register row records why (E15). | One register row citing `standalone-windows`: the panel is an extension of PGF's dialog and takes its chrome, unskinned or EllesmereUI-skinned. Trigger: the panel becoming independently shown or movable. |
| PGE-26 | `library-stack-§8` (*The catalog is the vocabulary*) | Low | MUST | **derived from PGE-17 (new).** The skinned min/max control draws Blizzard atlases `UI-QuestTrackerButton-Secondary-Collapse`/`-Expand` (`modules/EUISkin.lua:33-34`, `:227`), although the catalog carries `minimise` and `expand` (`libs/LibKa0s/Media.lua:94`). A title-bar strip control is a catalog surface (E15). | Draw `NS.Icon("minimise")`/`NS.Icon("expand")`, or cover the glyph in PGE-17's register row as part of the EllesmereUI chrome. |
| **PGE-18** | `audit-review-history` | Low | MUST | **Carried (issue #19).** The `state:`/`severity:` colors still miss the palette, for example `state:untriaged` `ededed` against `ff0000` and `severity:low` `c2e0c6` against `001100`. Observation: the vocabulary's `severity:high` means "a standard deviation carried out of an audit or review bundle", yet #10–#19 are filed `severity:low` (E16). | `gh label edit` the eight colors. Re-severity the audit-carried issues at triage. |
| **PGE-19** | `options-ui-§15` | Info | — | **Carried (related to #18).** General visibility is omitted (`settings/Panel.lua:51`) on the reasoning at `:8-10`. The owner has not recorded whether an attached panel counts as frameless. | Record the decision or add the dropdown. |
| **PGE-20** | `library-stack-§3` | Info | — | **Carried.** AceTimer-3.0 is embedded (`core/PGFE.lua:10`, `.toc:22`), but there is still no timer anywhere (E7 timer grep). | Drop the mixin, folder and TOC line, or keep them knowingly. |
| **PGE-21** | `ADDONS.md` roster (process) | Info | — | **Carried.** This addon is still not a row in `standards/ADDONS.md` (E16). | Upstream: add the row in WowAddonStandards. |
| **PGE-23** | `options-ui-§15` | Low | MUST | **New.** The `Master controls` tab carries two non-canonical rows, `filtersActive` (*Toggle PGF Extension Filters*) and `showRegionTags`, through the composer's `extra` (`settings/Panel.lua:56-65`). §15's set is "canonical, not a menu", and the rows filed under the tab MUST be a subsequence of it. The code (`:56`) and `docs/settings-panel.md:32-36` justify the extras with options-ui-§16, but §16 governs font/border/bar control groups, not Master controls (E18). | Move both rows to their own General tab (for example `Filters`, after `Master controls`), or register the decision citing `options-ui-§15`. Correct the §16 citations either way. |
| **PGE-24** | `automated-tests-§3` (*The complexity gate is sighted*), anti-pattern #51 | Low | MUST | **New.** The vendored runner's complexity suite **cannot measure HEAD**. `lizard` 1.24.0 raises `TypeError: sequence item 0: expected str instance, NoneType found` on `modules/RegionTags.lua:64-69` (a `for … in pairs({ name = function … end })` loop at file scope; a two-file repro is in E17). The kit's parity check reads the empty table as **54 blind files**, and the suite reports `fail`. A release run cut today would fail the release gate (blindFiles > 0). The newest record (`20261009-082905`, `2c78ddb`) is 38 commits stale. `tests/test_panel.lua` (1061) has entered the 1000–1500 band unrecorded (E17). | Hoist the hook table to a named local in `RegionTags.lua` (verified: lizard parses that shape), re-run the suite, and cut a fresh record before 0.1.0 is tagged. Upstream (LibKa0s testkit): report a lizard crash as a crash, not as N blind files. |
| **PGE-25** | `debug-logging-§9` (change gates), `debug-logging-§4` item 4 | Low | SHOULD | **New.** `modules/EUISkin.lua:45` and `:323-324` hand-roll a log-on-change memo (`lastSkip`) in front of `NS.Debug`. That is the job of the console's `DebugChanged` gate, and the DebugLog descriptor passes no `onClear` (`core/DebugLogSetup.lua:83-116`), so after a console Clear the memo keeps a repeat skip silent over an empty log (E6). | `NS.DebugChanged(TAG, "skip", "skipped: %s", why)`, with the memo deleted. |
| **PGE-27** | `options-ui-§19`, anti-pattern #93 | **Medium** | MUST | **New (v2.78.0 rule).** `addPGFSkinLink` creates a pooled AceGUI `EditBox` and calls `box.editbox:HookScript("OnEditFocusGained", … HighlightText …)` (`settings/Panel.lua:167`, `:174-175`). Nothing undoes it: there is no `"OnRelease"`, and AceGUI's EditBox `OnAcquire`/`OnRelease` reset no script (`libs/AceGUI-3.0/widgets/AceGUIWidget-EditBox.lua:139-141`). Once the page re-renders, the hooked frame goes back to the pool, and the next AceGUI EditBox handed out (the Profiles page's *New* box, or any other addon sharing AceGUI) selects all its text on focus. Each re-render stacks another hook. The link renders for every player whose PGF EllesmereUI skin is **missing**, the common case (`settings/Panel.lua:239`; `core/EUIBridge.lua:94-99`) (E19). | Hook once under a namespaced key (`editbox.__pgfeLinkHook`), gate the body on a flag set at acquire and cleared in the box's single `"OnRelease"`. Or drop the hook and select the text from the widget's own callback path. Add a pool-reuse test. |
| **PGE-29** | `slash-commands-§7` (survivors) | Info | — | **New, observation.** `EllesmereUI.RegisterSkin(…, onFacade)` (`modules/EUISkin.lua:392-395`) has no unregister. While stood down its body still keeps `S`, subscribes `S.OnLooksChanged(repaintLooks)` and logs (`:385-390`). It never paints (TryApply refuses), and `repaintLooks` gates itself. The reason is written down (`:382-384`): the facade arrives once per session. §7's carve-out names only `hooksecurefunc` bodies, so a one-shot third-party callback is unnamed rather than non-compliant. | No addon change needed. Upstream: name the one-shot third-party registration in §7's survivor list (or say it is out of scope). |

## Closed since 2026-10-09 (not counted)

| ID | Rule | Evidence it is closed |
|---|---|---|
| PGE-01 | `compat` | `modules/EnvInject.lua:43-45` calls `NS.Compat.GetSpecialization()` / `NS.Compat.GetSpecializationInfo(idx)` (commit `e835996`). |
| PGE-14 | `options-ui-§5` | `settings/Panel.lua:27-39` hands the spec to `Helpers.BuildLandingPage` with no `logoSize` (commits `46f05d9`, `aeb0f75`). Issue #15 still lists it, so narrow #15 to PGE-13. |
| PGE-22 | `documentation-§5` | `CLAUDE.md:24-25` now names `docs/audits/2026-10-09/` and the review bundle. |

## Checked and compliant (not entries)

- **Disabled state:** the stand-down (one latch, real unregister of all seven events, gated hooks, no
  game-event writes, full slash surface live, `diagnostics` in `liveVerbs`).
- **Vendoring:** both `diff -r` checks are empty at v1.71.0, and the provenance line is in
  `CLAUDE.md` only.
- **Line endings and packaging:** the `.gitattributes` body, pin, carve-outs and binaries, with 0
  strays in the working tree. Packaging checks (a), (b) and (c) are clean.
- **Docs:** the README's five cheap checks and its section order; the four-table Documentation map
  with no orphan or dangling row; Tier 1 and Tier 2; the over-cap census and its kit gate.
- **Lint:** the scope is correct.
- **Diagnostics:** one row, no alias, live while disabled, library-built, no host `SetEnabled`.
- **LibKa0s descriptors:** every one that takes `debug` is given it, and the Launcher descriptor
  passes `debugAtEnable`.
- **Launcher:** label `Ka0s Premade Groups Filter Extension`, one object, no host tooltip or menu,
  the minimap row at `global.minimap.shown` and `resetExempt`.
- **Close-button grep:** the wrapper only.
- **Event registration:** through `SafeRegisterEvent`, with a player-reachable rejected list.
- **TOC:** the `IconTexture` format; the unpublished `X-Curse-Project-ID` comment.
- **Bus literals:** no `Ka0s_` message literal.
- **Settings window:** nothing closes it in combat, and there is no host page lock.
- **Landing page:** `BuildLandingPage`, logo 300.
- **Status rows:** the EllesmereUI status lines use `InteractiveLabel` callbacks (pool-safe).
- **Region tags:** no `string.format`/`table.concat` on a possibly-secret name, and a
  `NS.IsConcatSafe` guard (events-frames-taint-§8).
