# 05 — Execution plan

Ordered remediation for `02_DEVIATIONS.md`, designed in `04_TECHNICAL_DESIGN.md`. Each step names its
deviation id(s). Every code step ends on the green gate (`lua tests/run.lua` and `luacheck .`, 0/0)
through `~/.claude/dev-copilot/bin/ka0s-bounded`; never commit red, never push, tag or bump without the
owner's go-ahead (versioning-git). Owner decisions are marked **[decide]** — the audit does not make
them.

Counts carried from `02_DEVIATIONS.md`: **19 roots (0 High, 1 Medium, 14 Low, 4 Info), 22 with
dependents; 14 root MUST failures, 16 with dependents.**

## Sprint 1 — the one behavior defect (PGE-01)

- [ ] 1.1 Add the failing case to `tests/test_envinject.lua`: globals absent, `C_SpecializationInfo`
      present, `pgfe_samespec` must read the member count; confirm it is red today. *(PGE-01)*
- [ ] 1.2 Route `EnvInject.RefreshPlayer` through `NS.Compat.GetSpecialization` /
      `GetSpecializationInfo`; case goes green; add the `-- red under:` comment. *(PGE-01)*
- [ ] 1.3 Drop `GetSpecialization` / `GetSpecializationInfo` from `.luacheckrc` `read_globals` if
      `luacheck .` stays 0/0 without them. *(PGE-01)*
- [ ] 1.4 Add a smoke test to `docs/smoke-tests.md`: *No one with my spec* removes a group holding the
      player's spec on the live client. Regenerate `docs/test-cases.md` and the README `[tests]` badge.
      Commit. *(PGE-01)*

## Sprint 2 — tests the standard mandates (PGE-05, PGE-10, PGE-11)

- [ ] 2.1 Rewrite `tests/test_disabled.lua` to the ten steps of slash-commands-§7 (04 D5), on the real
      FEATURE_EVENTS and the recording mock; falsification comments on steps 3, 6, 10. *(PGE-05)*
- [ ] 2.2 Add `tests/test_reset.lua` proving the global reset's blast radius and that the minimap row
      survives both resets (04 D8); list it in `tests/run.lua`. *(PGE-10)*
- [ ] 2.3 Launcher `isEnabled` → the Enable row's accessor, with a case: perf hold taken → tooltip
      *Enabled: Yes*. **[decide]** whether the Slash gate stays on the latch (04 D9). *(PGE-11, PGE-12)*
- [ ] 2.4 Regenerate `docs/test-cases.md` and the badge; commit.

## Sprint 3 — trace the flows (PGE-04)

- [ ] 3.1 Add the gated lines in 04 D4's table (`Apply`, `PGF`, `Spec`, `Panel`, `Preset`, `Init`
      tags), using `DebugChanged` / `DebugAtEnable` where the table says so. *(PGE-04)*
- [ ] 3.2 Cases: each Apply refusal lands one `[Apply] refused: <guard>` line with logging on and none
      with it off. Update `docs/debug.md` with the new tags. Commit. *(PGE-04)*

## Sprint 4 — record the decisions (PGE-02, PGE-03, PGE-09, PGE-16, PGE-17, PGE-19)

- [ ] 4.1 **[decide]** PGE-02: register row (04 D2 a) or schema rows (D2 b). If the row: add it and
      rewrite ARCHITECTURE → Settings Schema so `char.filters` / `panelCollapsed` are preferences
      covered by the row, not *named non-setting state*. *(PGE-02)*
- [ ] 4.2 PGE-03: register row citing `architecture-§4` and rewrite `## Message Bus` to cite the
      threshold (04 D3). *(PGE-03)*
- [ ] 4.3 **[decide]** PGE-09: the `performance-§12` exemption (04 D7 a — sweep, row, remove the
      instance/verb/PerfDB/lint entries/perf-analysis README, update the Documentation map and
      `docs/performance.md`) or a real `envInject` bucket plus `tests/perf.lua` (D7 b). If (a), the `perf`
      verb leaves `NS.COMMANDS`: regenerate `docs/test-cases.md`, the badge, `docs/slash-dispatch.md`,
      the ARCHITECTURE slash table and step 2.1's step-7 list. *(PGE-09)*
- [ ] 4.4 **[decide]** PGE-16: route the eight literals through `NS.L` or file the English-only row;
      align `docs/scope.md:33`. *(PGE-16)*
- [ ] 4.5 PGE-17: register row citing `standalone-windows` for the attached panel's chrome. *(PGE-17)*
- [ ] 4.6 **[decide]** PGE-19: add the General visibility dropdown and honor it in
      `Panel.UpdateVisibility`, or record in `docs/settings-panel.md` why it does not apply. *(PGE-19)*
- [ ] 4.7 Run the register self-check: every new row has a `filename-§N` Rule, a Decided date and a
      trigger that has not fired. Commit.

## Sprint 5 — TOC, assets and documents (PGE-06/07/08, PGE-13, PGE-14, PGE-15, PGE-22)

- [ ] 5.1 Rewrite the `# Modules` group comment and annotate `modules\EnvInject.lua`,
      `modules\Panel.lua`, `settings\Slash.lua` as load-bearing, naming what resolves (04 D6). No line
      moves. *(PGE-06, PGE-07, PGE-08)*
- [ ] 5.2 Rename the three logo files to `premadegroupsfilterextension.logo{.128.tga,.tga,.png}` and
      update `## IconTexture`, `core/LauncherSetup.lua:13`, `settings/Panel.lua:17`, `DEPENDENCIES.md`.
      Set `MAIN_LOGO_SIZE = 300`. One commit. *(PGE-13, PGE-14)*
- [ ] 5.3 `DEPENDENCIES.md`: add Python 3 for `tools/realm_map_diff.py`, reword "One entry".
      *(PGE-15)*
- [ ] 5.4 `CLAUDE.md:24`: point at `docs/audits/2026-10-09/`. *(PGE-22)*
- [ ] 5.5 Optional: drop AceTimer-3.0 (mixin, TOC line, `libs/AceTimer-3.0/`). *(PGE-20)*
- [ ] 5.6 Green gate; commit.

## Sprint 6 — outside the code (PGE-18, PGE-21)

- [ ] 6.1 `gh label edit` the eight `state:` / `severity:` labels to audit-review-history's colors.
      *(PGE-18)*
- [ ] 6.2 Upstream, in WowAddonStandards: add this addon's row to `standards/ADDONS.md` with launcher
      entries `Enabled`. *(PGE-21)* Not a change to this repo.

## Before the v0.1.0 tag (not a deviation — the release gate)

- [ ] Run `bash tests/_kit/run-automated-tests.sh` (all four suites) on a clean tree after the sprints;
      the release gate needs lint, tests and complexity at pass, zero CCN > 15, `blindFiles` 0, and the
      perf line either `pass` (D7 b) or the sanctioned skip stated in the release notes — naming
      `performance-§12` if D7 (a) was chosen (automated-tests-§3).
- [ ] Write the release bundle's `ANALYSIS.md`, roll `## Version History` (date replaces
      "in development"), and only then ask the owner for the bump and tag.

## Traceability

| ID | Step(s) |
|---|---|
| PGE-01 | 1.1–1.4 |
| PGE-02 | 4.1 |
| PGE-03 | 4.2 |
| PGE-04 | 3.1–3.2 |
| PGE-05 | 2.1 |
| PGE-06, PGE-07, PGE-08 | 5.1 |
| PGE-09 | 4.3 |
| PGE-10 | 2.2 |
| PGE-11, PGE-12 | 2.3 |
| PGE-13, PGE-14 | 5.2 |
| PGE-15 | 5.3 |
| PGE-16 | 4.4 |
| PGE-17 | 4.5 |
| PGE-18 | 6.1 |
| PGE-19 | 4.6 |
| PGE-20 | 5.5 |
| PGE-21 | 6.2 |
| PGE-22 | 5.4 |
| PGE-R01 | none — ratified; re-evaluate its trigger at the next audit |
