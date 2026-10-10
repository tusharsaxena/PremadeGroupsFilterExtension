# 05 — Execution plan: 2026-10-10 remediation

The hand-off to the remediation engagement. Each step names its deviation ID(s) and issue, and each
sprint ends with the green gate:

```
~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua
~/.claude/dev-copilot/bin/ka0s-bounded luacheck .
```

The figures quoted here match `02_DEVIATIONS.md`: 21 roots, 26 with dependents, 15 root MUST
failures, 19 with dependents, 1 Medium. Commit per step, and never edit `libs/` or `tests/_kit/`.

## Sprint 1 — user-reachable and release-blocking

- [ ] **1.1 PGE-27.** In `settings/Panel.lua` `addPGFSkinLink`, hook `box.editbox` once under
  `__pgfeLinkHook`, gate the body on `__pgfeLinkActive`, and clear that flag (and
  `Settings.PGFSkinLinkBox`) in the box's single `"OnRelease"`. Add a pool-reuse case: release, then
  acquire another EditBox, then focus, and assert no highlight. Name the falsifying mutation.
- [ ] **1.2 PGE-24 (code).** Hoist `modules/RegionTags.lua:64-67`'s table to `local PAINTERS = {…}`
  and loop over it. Run `tests/test_regiontags.lua` unchanged.
- [ ] **1.3 PGE-24 (measure).** Run
  `ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` verbatim and
  confirm `blindFiles` 0 and 0 warnings. If any function is above CCN 15, it is a release blocker.
- [ ] **1.4 PGE-24 (upstream).** Open a LibKa0s issue: the runner reports a lizard crash as N blind
  files.
- [ ] Gate green.

## Sprint 2 — structure (MUSTs)

- [ ] **2.1 PGE-23.** Move `filtersActive` and `showRegionTags` from the Master controls `extra` to a
  `Filters` group (second General tab). Correct `settings/Panel.lua:56` and
  `docs/settings-panel.md:32-36`. Re-check the tab-index assumptions in the tests.
- [ ] **2.2 PGE-11 (#14).** `core/LauncherSetup.lua:55` reads `NS.SchemaRuntime.Get("enabled") ~= false`.
  Add a perf-hold launcher case. **PGE-12:** keep the Slash latch read and state the accepted
  wording in the commit.
- [ ] **2.3 PGE-06/07/08/28 (#12).** Per-line TOC annotations for `modules\EnvInject.lua`,
  `modules\Panel.lua`, `settings\Panel.lua` and `settings\Slash.lua`, and replace `.toc:73`'s group
  comment. Sync `docs/module-map.md`.
- [ ] **2.4 PGE-04, PGE-25 (#11).** Add debug lines to Apply/Clear (each refusal, the write pass, the
  search), Panel edges, Presets, the `EnvInject.RefreshPlayer` change gate and an enable-time PGF
  seam line. Replace EUISkin's `lastSkip` with `NS.DebugChanged`. Add console assertions to
  `tests/test_apply.lua`.
- [ ] **2.5 PGE-09 (#5).** Add the `envInject` and `regionTags` buckets and their brackets in the
  frozen idiom, plus `tests/perf.lua` with the zero-overhead scenario. Update `docs/performance.md`
  and the hub's *Perf bucket* row.
- [ ] Gate green.

## Sprint 3 — tests

- [ ] **3.1 PGE-10 (#13).** Write `tests/test_reset.lua`: two profiles, session-row sweep, minimap
  survival on both resets, and the latch re-read. Register it in `tests/run.lua`.
- [ ] **3.2 PGE-05 (#4).** Rewrite `tests/test_disabled.lua` to the ten steps:
  - Snapshot `R_on` and assert empty by name.
  - Fire every event and hook path while down and assert zero writes, prints and shows.
  - Walk every `NS.COMMANDS` verb, including both diagnostics forms.
  - Cover the launcher and the setting changed while disabled.
  - Cover both hold orders.
  - Drop the probe event.
  - Add three `-- red under:` comments.
- [ ] **3.3** Regenerate `docs/test-cases.md` (`lua tests/run.lua --list > docs/test-cases.md`) and
  update the README badge to the new Total.
- [ ] Gate green.

## Sprint 4 — docs, config, register

- [ ] **4.1 PGE-02, PGE-03 (#10).** Decide with the owner whether to write register rows (the
  recommendation) or adopt the bus.
  - **Rows:** add the `architecture-§5` and `architecture-§4` rows, shrink
    `docs/ARCHITECTURE.md:108-116`, and rewrite `## Message Bus` to cite the threshold.
- [ ] **4.2 PGE-17, PGE-19, PGE-26 (#18).** Add one register row covering the attached panel's chrome,
  the EllesmereUI min/max glyphs and the omitted General visibility, with a trigger.
- [ ] **4.3 PGE-13 (#15).** Rename the three logo files to `premadegroupsfilterextension.logo.*`,
  regenerate the landing TGA at 512 and update the three references and `DEPENDENCIES.md`. Narrow #15
  to PGE-13 (PGE-14 is closed).
- [ ] **4.4 PGE-15 (#16).** Add the Python 3 stdlib entry for `tools/realm_map_diff.py`, reword "One
  entry", and add the lizard note.
- [ ] **4.5 PGE-16 (#17).** Move the E14 literals into `locales/enUS.lua`. Fix the claim at
  `docs/scope.md:52` if any literal is kept.
- [ ] **4.6 PGE-18 (#19).** `gh label edit` the eight colors, and re-severity the audit-carried issues
  at triage.
- [ ] **4.7 PGE-20.** Drop or document AceTimer-3.0.
- [ ] **4.8 Issue hygiene.** Close or narrow on GitHub every issue the sprints fixed. #15's PGE-14
  half and the PGE-01 part of the review findings are already fixed in the tree.
- [ ] Gate green.

## Sprint 5 — release record

- [ ] **5.1 PGE-24 (record).** At the commit to be tagged, run
  `ka0s-bounded bash tests/_kit/run-automated-tests.sh` (a full run with a bundle) and confirm
  complexity `pass` with `blindFiles` 0. Write the Disposition for the band row of
  `tests/test_panel.lua` (1061 lines, or fewer if split).
- [ ] **5.2** Update `CLAUDE.md`'s "newest compliance snapshot / automated-test record" pointer to
  `docs/audits/2026-10-10/` and the new run.

## Upstream (not this repo)

- PGE-21: add the ADDONS.md row (WowAddonStandards).
- PGE-29: name one-shot third-party registrations in slash-commands-§7's survivor list
  (WowAddonStandards).
- PGE-24: report a lizard crash as a crash in the runner (LibKa0s testkit).
