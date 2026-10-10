# Ka0s Premade Groups Filter Extension — 2026-10-10 audit + review fixes: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to carry out this plan one task at a time. Steps use
> checkbox (`- [ ]`) syntax for tracking. Every code step is red-first
> (superpowers:test-driven-development). Write the test, run it, see it FAIL for the stated reason,
> then implement.

**Goal:** close all 39 consolidated findings (C-01..C-39) from the 2026-10-10 standards audit and
review on one branch. Make the release gate passable (complexity sighted, perf measured by the
offline `tests/perf.lua`), take the performance-§12 no-combat-path exemption the owner chose at
checkpoint D1 (C-09), ratify the four owner-approved deviations (the three spec section 5 rows plus
the performance-§12 row), file the upstream issues, and record a fresh automated-test bundle.

**Architecture:** no new modules. The fixes stay inside the files that own each concern: the bridge
(`core/PGFBridge.lua`), the hot path (`modules/EnvInject.lua`, `modules/RegionTags.lua`,
`modules/Regions.lua`), season data (`modules/Season.lua`), the panel (`modules/Panel.lua`), the skin
(`modules/EUISkin.lua`), the settings page (`settings/Panel.lua`), locale (`locales/enUS.lua`), the
TOC and assets, the tests, and docs.

**Tech stack:** Lua 5.1 (WoW Retail 12.x), Ace3, vendored LibKa0s v1.71.0, the LibKa0s test kit
(`lua tests/run.lua`), luacheck, lizard 1.24.0, Python 3 + Pillow (logo render only), `gh`.

**Read first:**

- Findings: [`docs/reviews/2026-10-10/06_CONSOLIDATED_FINDINGS.md`](../../reviews/2026-10-10/06_CONSOLIDATED_FINDINGS.md).
- Spec, with per-finding design, exact register rows and non-goals:
  [`docs/superpowers/specs/2026-10-10-audit-review-fixes-design.md`](../specs/2026-10-10-audit-review-fixes-design.md).
- Where this plan and the spec differ on a detail, the spec's section 4 wins. Where the spec and
  the findings' *proposedFix* differ, the verifier's fixNotes (folded into the spec) win.

---

## Checkpoint ledger (resume here)

A resumed run starts at the first row that is not `done`. Branch: `fix/2026-10-10-audit-review`
(base `0dabcde`). Never merge without the owner's go-ahead.

**Who edits this table, and when (it is not a shared file):**

- **Worktree tasks never edit this plan file.** A task branch (`…--T<n>`) leaves the ledger alone,
  so parallel tasks in one wave cannot conflict on adjacent rows.
- **The integrator ticks it on `fix/2026-10-10-audit-review`, in the main tree, once per wave**,
  after every task of the wave is fast-forwarded in: one docs-only commit
  `Tick wave <N> in the plan ledger`, with each task's last sha in its Commit cell. That commit also
  carries Task 6's outcome (it makes no commit of its own): the label evidence and the six issue
  URLs go in row 6's Commit cell. The commit passes the gate like any other (CRLF; `test_eol`).
- **A task run sequentially in the main tree** may tick its own row in its last commit instead.
- **Milestones.** The M1 row's pushed sha rides the first Task 15 commit (the push happens before
  Task 15 starts, so nothing is circular). M2 and M3 are recorded **in the PR body only**, never in a
  commit: a commit after Task 16 would move the tip past the commit the automated-test record names
  (C-13). Task 16 ticks its own row inside its bundle commit, which is the last commit before the
  merge. Rows M2, M3 and 17 are ticked on `main` after the merge only if the owner wants them there
  (Task 17).

| # | Task | Findings | Wave | Status | Commit |
|---|---|---|---|---|---|
| 0 | Preflight: baseline counts, tools, branch; owner checkpoint D1 (C-09 route) | — | 0 | done | this commit (D1 = §12) |
| 1 | RegionTags hoist + install store | C-02, C-14 (local), C-10 (store) | 1 | done | `10350bc` |
| 2 | Expression Strip: wrapped-without-close damage, byte-for-byte edges | C-03, C-33 | 1 | done | `c768fd0` |
| 3 | Settings page: PGF-link hook, Filters tab | C-01, C-15 | 1 | done | `195bc63` |
| 4 | EllesmereUI skin hardening | C-05, C-20, C-30, C-29 (EUISkin half) | 1 | done | `40237ba` |
| 5 | PGF bridge seams, region probe, bridge test | C-04 (bridge + EnvInject), C-32, C-31, C-10 (SEAMS + env store) | 1 | done | `fd73897` |
| 6 | GitHub admin, upstream issues, local re-vendor issue | C-27, C-12, C-14, C-36, C-37 (+ #15 narrowing) | 1 | done | labels recolored (C-27); #15 narrowed; LibKa0s #46 (C-12), #47 (C-14); WowAddonStandards #8 (C-14), #9 (C-36), #10 (C-37); local re-vendor tracker #25. Re-severity of #4-#19 deferred to `/dev-copilot:issue-triage` (bulk relabel not run) |
| 7 | Season request guard, affix event, panel tooltip, dialog store | C-06, C-07, C-04 (Season half), C-29 (Panel half), C-10 (Panel store) | 2 | done | `2be37ba` |
| 8 | performance-§12 exemption: remove the perf wiring, ship `tests/perf.lua` | C-09 | 2b (after wave 2) | done | `2c86d49` |
| 9 | TOC annotations, AceTimer removal, logo rename + 512 render | C-21, C-35, C-23 | 2 | done | `620a297` |
| 10 | Reset tests | C-22 | 2 | done | `34db256` |
| 11 | Diagnostics reports running state | C-10 | 3 | done | `9c399be` |
| 12 | Locale: missing keys, literals through `NS.L` | C-11, C-25 | 3 | done | `9113702` |
| 13 | Debug lines on feature flows; targeting-off message | C-19, C-28 (+ C-03 Apply-level case) | 4 (first) | done | `1d06f55` |
| 14 | Launcher enable pair; ten-step disabled suite | C-16, C-08 | 4 (after T13) | pending | |
| — | **Milestone M1: push** (all code fixes) | | | pending | |
| 15 | Docs + register rows + spec/DEPENDENCIES fixes | C-17, C-18, C-26, C-34, C-09 (register row), C-39, C-38, C-24, C-37 (note) | 5 | pending | |
| 16 | Full automated-test bundle + CLAUDE.md pointers | C-13 | 6 | pending | |
| — | **Milestone M2: push** (docs, register, bundle) | | | pending | |
| — | **Milestone M3: `gh pr create`, ask the owner for the merge go-ahead** | | | pending | |
| 17 | After go-ahead: merge `--no-ff`, push `main`, close issues, delete branch, clean worktrees/stashes | — | 7 | pending | |

## Parallelism

Tasks in the same wave touch **disjoint files** and may run at the same time. Run each one in its
own worktree (superpowers:using-git-worktrees), at `../pgfe-wt-T<n>` on branch
`fix/2026-10-10-audit-review--T<n>`, cut from the tip of `fix/2026-10-10-audit-review`. Or run the
wave sequentially in the main tree. A wave starts only when every task of the previous wave is `done`
and integrated. Integrate each task in two places:

1. **In the task worktree:** `git rebase fix/2026-10-10-audit-review`, then the gate.
2. **In the main tree** (git refuses to check out `fix/2026-10-10-audit-review` inside a task
   worktree while the main tree has it checked out):
   `git -C <main-tree> merge --ff-only fix/2026-10-10-audit-review--T<n>`, where `<main-tree>` is
   this repo's own checkout (the one `git worktree list` prints first).

**Wave 2b is Task 8 alone, after wave 2 is integrated.** Under the performance-§12 route (owner
checkpoint D1) Task 8 removes the perf wiring, and that reaches files Tasks 7, 9 and 10 own in wave 2
(`.luacheckrc`, `tests/test_surface_parity.lua`, the TOC, `tests/test_setup.lua`, `docs/module-map.md`,
`tests/run.lua`), so it cannot share their wave. Cut it from the tip that holds all of wave 2.

**Wave 4 is sequential, not parallel:** Task 13 first, then Task 14, cut from the tip that already
holds Task 13. Task 14's disabled suite pins the hook list and debug lines Task 13 adds (spec C-16 +
C-08 "Order"), and its red-under mutation targets `core/PGFE.lua`, which Task 13 edits.

**Shared-file rules.** Only these may be touched by two tasks in the same wave:

- `docs/ARCHITECTURE.md`. Each task edits only the section it names. Disjoint hunks rebase cleanly.
  On a conflict, keep both edits.
- `docs/test-cases.md` and the README `[tests]` badge (`README.md:6`). These are generated. Every
  task regenerates them in each of its own commits that change the inventory (testing-§5). On a
  rebase conflict, never hand-merge: run
  `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua --list > docs/test-cases.md`, convert it
  to CRLF, set the badge to the new Total, and `git add` + `git rebase --continue`. The same fix-up
  applies to every later commit the rebase replays.

The plan file itself is **not** a shared file: see the ledger rules above.
`tests/test_apply.lua` is owned by Task 3 alone in wave 1 (Task 5 makes no edit to it; see Task 5
Step 6).

| Wave | Tasks | Waits for | Files owned in the wave |
|---|---|---|---|
| 0 | 0 (D1 answered: performance-§12) | — | none |
| 1 | 1, 2, 3, 4, 5, 6 | 0 | T1 `modules/RegionTags.lua`, `tests/test_regiontags.lua` · T2 `modules/Expression.lua`, `tests/test_expression.lua` · T3 `settings/Panel.lua`, `settings/Schema.lua` (header comment :5), `locales/enUS.lua`, `defaults/Profile.lua`, `tests/test_euisettings.lua`, `tests/test_setup.lua`, `tests/test_apply.lua` (comment), `docs/settings-panel.md`, `docs/schema.md`, `docs/smoke-tests.md` · T4 `modules/EUISkin.lua`, `tests/wow_mock.lua`, `tests/test_euiskin.lua` · T5 `core/PGFBridge.lua`, `modules/EnvInject.lua`, `modules/Regions.lua`, `.luacheckrc`, `tests/test_bridge.lua`, `tests/test_regions.lua`, `tests/test_envinject.lua`, `tests/pgf_fake.lua` · T6 GitHub only |
| 2 | 7, 9, 10 | wave 1 (T7 needs T4 + T5; T9 and T10 need T3) | T7 `modules/Season.lua`, `modules/Panel.lua`, `.luacheckrc` (drop Season from the reader list), `tests/wow_mock.lua`, `tests/test_panel.lua`, `tests/test_season.lua`, `tests/test_surface_parity.lua`, `docs/data-flow.md`, `docs/smoke-tests.md` · T9 `PremadeGroupsFilterExtension.toc`, `core/PGFE.lua`, `libs/AceTimer-3.0/` (removed), `media/logos/*`, `core/LauncherSetup.lua`, `settings/Panel.lua`, `tests/test_harness.lua`, `tests/test_setup.lua`, `DEPENDENCIES.md`, `docs/module-map.md` · T10 `tests/test_reset.lua` (new), `tests/run.lua` |
| 2b | 8 (alone) | wave 2 integrated (T8 needs T1, T5, T7, T9 and T10: it edits `.luacheckrc` and `tests/test_surface_parity.lua` (T7), the TOC, `tests/test_setup.lua` and `docs/module-map.md` (T9) and `tests/run.lua` (T10)) | T8 `core/PerfSetup.lua` (deleted), `core/LifecycleSetup.lua`, `PremadeGroupsFilterExtension.toc`, `settings/Slash.lua`, `locales/enUS.lua`, `.luacheckrc`, `tests/perf.lua` (new), `tests/run.lua`, `tests/test_setup.lua`, `tests/test_slash.lua`, `tests/test_surface_parity.lua`, `tests/test_disabled.lua`, `docs/performance.md`, `docs/perf-analysis/README.md` (deleted), `docs/schema.md`, `docs/module-map.md`, `docs/slash-dispatch.md`, `docs/testing.md`, `docs/ARCHITECTURE.md` (sections named below) |
| 3 | 11, 12 | wave 2b (T11 needs T1, T5, T7, T10; T12 needs T3, T8, T9) | T11 `modules/Diagnostics.lua`, `tests/test_diagnostics.lua` (new), `tests/run.lua`, `docs/debug.md` · T12 `locales/enUS.lua`, `settings/Slash.lua`, `settings/Panel.lua`, `core/DebugLogSetup.lua`, `core/CoreSetup.lua`, `core/LauncherSetup.lua`, `settings/OptionsSetup.lua`, `tests/loader.lua` (an `opts.afterFile` hook), `tests/test_slash.lua`, `tests/test_surface_parity.lua` |
| 4 | 13, **then** 14 (sequential) | wave 3 (T13 needs T7, T8, T9, T11, T12; T14 needs T4, T7, T8, T12 **and T13**) | T13 `modules/Apply.lua`, `modules/Presets.lua`, `modules/EnvInject.lua`, `modules/Panel.lua`, `core/PGFE.lua`, `locales/enUS.lua`, `tests/test_apply.lua`, `tests/test_panel.lua`, `tests/test_presets.lua`, `tests/test_envinject.lua`, `tests/test_setup.lua`, `docs/debug.md`, `docs/data-flow.md` · then T14 `core/LauncherSetup.lua`, `tests/test_disabled.lua`, `docs/testing.md` |
| 5 | 15 | M1 | `docs/ARCHITECTURE.md`, `DEPENDENCIES.md`, `docs/realm-map-maintenance.md`, `docs/superpowers/specs/2026-10-09-m-plus-v0.1-design.md`, `tests/test_filters.lua`, header comments of `settings/Panel.lua` and `modules/Panel.lua`, `docs/schema.md`, `docs/data-flow.md`, `docs/module-map.md` (the "non-setting" sweep and the C-04 PGF-reader sweep) |
| 6 | 16 | 15 | `docs/automated-tests/<stamp>/`, `docs/automated-tests/RESULTS.md`, `CLAUDE.md`, `docs/testing.md` / `docs/ARCHITECTURE.md` (stale "newest record" wording only) |
| 7 | 17 | owner go-ahead | git + GitHub only |

`ARCHITECTURE.md` sections, one owner per wave: T2 `## Expression block format` · T3 `## Settings
Schema` line ~100 · T4 `## EllesmereUI seams` (facade paragraph ~241) · T5 `## PGF seams`,
`## Taint Notes` (the RegionTags concat-safe bullet ~177-183, C-32) · T7 `## Event Subscriptions`,
`## Known Limitations` · T8 (wave 2b) `## Contracts later tasks build on` (stand-down accessor row :47,
Perf bucket row :58), `## Module Map` (Perf in the setup list :70), the SavedVariables list (:118), the `perf` row of
`## Slash Commands` (:140) and the `perf-analysis/README.md` row of `## Documentation map` (:356); **not**
`## Documented deviations`, which is Task 15's · T9
`## Module Map` (load-order summary 62-65) · T11 `## Slash Commands` (diagnostics rows 138-139,
check only) · T14 any launcher/latch line (check only; wave 4 runs after T13) · T15 `## Settings
Schema` (108-116), `## Message Bus`, `## Taint Notes` (stand-down sentence), `## Documented
deviations`.

## Global constraints

- **Green gate before every commit (both at 0/0):**
  ```sh
  ~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua
  ~/.claude/dev-copilot/bin/ka0s-bounded luacheck .
  ```
  Baseline at `0dabcde`: **325 passed, 1 skipped, 326 total**. Luacheck is 0/0.
- **Inventory, per commit:** every commit that changes the case count or a case name also runs
  `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua --list > docs/test-cases.md` (then CRLF)
  and sets the README `[tests]` badge (`README.md:6`) to the new Total, **in that same commit**
  (testing-§5). A task with several commits regenerates before each commit that adds or renames a
  case, not once at the end. Each task's "regenerate" step below names the commits it applies to.
  Never hand-edit `docs/test-cases.md`.
- **Never edit `libs/` or `tests/_kit/`.** Removing the unused `libs/AceTimer-3.0/` folder whole (T9)
  is not editing vendored code. The commit message says so.
- **Never bump the version, tag, or pass `--label` with a release name.**
- **Never auto-merge.** Push only at M1/M2. Open the PR at M3 and wait for the owner.
- Don't edit the frozen bundles (`docs/audits/*`, `docs/reviews/*`, old `docs/automated-tests/<stamp>/`)
  or the 2026-10-09 plans.
- A new suite file must be added to the `Kit.run{ suites = … }` list in `tests/run.lua` (~88-107).
  The kit's inventory check fails in both directions.
- **Line endings:** the repo is pinned CRLF in the working tree (`.gitattributes`, line-endings-§2),
  and `test_eol` checks it on disk. A file written through WSL tools (Write, sed, a shell redirect)
  lands LF. Before every commit, convert new or rewritten files to CRLF, or restore them with
  `rm <f> && git checkout -- <f>` after staging. Then check that the CR count equals the LF count.
- **Prose gate:** `test_prose` (kit, localization-§5) scans every tracked `.lua`, the TOC, `README.md`
  and `docs/**` for British spellings (`tests/_kit/prose_lists.lua`). Write US English everywhere,
  including commit-bound docs and comments. Never quote the LibKa0s catalog key for the minimize
  glyph; say "minimize glyph" and cite `libs/LibKa0s/Media.lua:94`. Add a `tests/prose_waivers.lua`
  entry only for game data, with the reason beside it.
- Red-under notes: every new test carries `-- red under: <mutation>`, naming the change that turns
  it red (testing-§12).
- **Commit trailer:** the attribution lines from the executing session's system reminder.
- **Deviation stop rule (CLAUDE.md):** if an implementation step would deviate from the standard in
  a way the spec does not already ratify, STOP and flag it to the owner. The open design choices in
  spec section 3 are pre-settled to their conformant defaults. Re-raise them only if a step proves
  the default unworkable.
- **Issues are closed only in Task 17, after the merge.** Commit messages say `Refs #N`, never
  `Fixes #N`, so nothing auto-closes before the owner's merge.

## Finding -> task coverage matrix

| Finding | Task(s) | Finding | Task(s) | Finding | Task(s) |
|---|---|---|---|---|---|
| C-01 | 3 | C-14 | 1 (local), 6 (upstream) | C-27 | 6 |
| C-02 | 1 | C-15 | 3 | C-28 | 13 |
| C-03 | 2 (+ 13: Apply-level Clear case) | C-16 | 14 | C-29 | 4 (EUISkin), 7 (Panel) |
| C-04 | 5 (bridge, EnvInject), 7 (Season) | C-17 | 15 | C-30 | 4 |
| C-05 | 4 | C-18 | 15 | C-31 | 5 |
| C-06 | 7 | C-19 | 13 | C-32 | 5 |
| C-07 | 7 | C-20 | 4 | C-33 | 2 |
| C-08 | 14 | C-21 | 9 | C-34 | 15 |
| C-09 | 8 (§12: wiring removed, `tests/perf.lua`), 15 (register row) | C-22 | 10 | C-35 | 9 |
| C-10 | 1 (store), 5 (SEAMS + env store), 7 (dialog store), 11 (report) | C-23 | 9 (+ 6 narrows #15) | C-36 | 6 |
| C-11 | 12 | C-24 | 15 | C-37 | 6 (upstream), 14 (test step), 15 (doc note) |
| C-12 | 6 (upstream + local re-vendor issue) | C-25 | 12 | C-38 | 15 |
| C-13 | 16 | C-26 | 15 | C-39 | 15 |

All 39 are covered. Checked: C-01..C-39, none missing.

## Issue -> fix mapping (closed in Task 17)

| Issue | Finding | Fixed by task | Close comment names |
|---|---|---|---|
| #4 | C-08 | 14 | T14 commit (also correct "5 events" to 8) |
| #5 | C-09 | 8, 15 | T8 commit (+ the T15 register commit for the performance-§12 row) |
| #6 | C-07 | 7 | T7 commit |
| #7 | C-10 | 1, 5, 7, 11 | T11 commit (+ T5 for the SEAMS rows) |
| #8 | C-38 | 15 | T15 commit (spec amend) |
| #9 | C-33 | 2 | T2 commit |
| #10 | C-17, C-18 | 15 | T15 commit (two register rows) |
| #11 | C-19, C-20 | 4, 13 | T13 commit (+ T4 for DebugChanged) |
| #12 | C-21 | 9 | T9 annotation commit |
| #13 | C-22 | 10 | T10 commit |
| #14 | C-16 | 14 | T14 commit |
| #15 | C-23 | 9 | T9 commits (a) rename + (b) render |
| #16 | C-24 | 15 | T15 commit |
| #17 | C-25 | 12 | T12 commit |
| #18 | C-26, C-34 | 15 | T15 commit (combined row) |
| #19 | C-27 | 6 | the T6 checkpoint (labels set; no commit). Closed in T17 with the others |

The local "Re-vendor LibKa0s after the complexity-runner fix" issue that Task 6 Step 6 files stays
**open**: it tracks work this run defers (spec section 7). Task 17 does not close it.

---

### Task 0: Preflight

**Files:** none.

- [x] **Step 1:** Run `git status` and confirm it is clean on `fix/2026-10-10-audit-review`, with HEAD
  at or after `0dabcde`. Done 2026-10-10.
- [x] **Step 2 (eol repair):** at plan-writing time the gate showed `324 passed, 1 failed`. The
  kit's `test_eol` reports `docs/reviews/2026-10-10/02_PROPOSED_CHANGES.md` as LF on disk although
  `.gitattributes` declares CRLF. The index is correct, so the fix is
  `rm docs/reviews/2026-10-10/02_PROPOSED_CHANGES.md && git checkout -- docs/reviews/2026-10-10/02_PROPOSED_CHANGES.md`.
  This changes no content, which keeps the frozen bundle intact. Check that `tr -dc '\r' <f | wc -c`
  equals `tr -dc '\n' <f | wc -c`. Then run the gate and record the baseline (325/1/326, luacheck 0/0).
  **Done 2026-10-10:** eol repair applied; gate 325 passed, 1 skipped, 326 total; luacheck 0/0.
- [x] **Step 3:** Run `lizard --version` (expect 1.24.0), `python3 -c "import PIL; print(PIL.__version__)"`,
  `gh auth status`, and confirm `~/.claude/dev-copilot/bin/ka0s-bounded` exists.
  **Done 2026-10-10:** lizard 1.24.0, Pillow 10.2.0, `gh` authenticated, `ka0s-bounded` present.
- [x] **Step 4:** Reproduce the C-02 blocker:
  `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`
  shows complexity `fail`, with blind files. Done 2026-10-10 (preflight).
- [x] **Step 5 (owner checkpoint D1, C-09 route): answered.** Both routes were inside the standard,
  so the "default to conforming" decision did not settle it, and the owner was asked. **On
  2026-10-10 the owner chose the performance-§12 no-combat-path exemption, not buckets.** Task 8 is
  written for that route and is no longer blocked. What the answer means for the run:
  - Task 8 removes `core/PerfSetup.lua`, `PremadeGroupsFilterExtensionPerfDB` (the TOC declares one
    SavedVariables global), the `perf` verb registration, `NS.HOLD_PERF` and the perf-only
    references, commits the whole-repo combat-path sweep in `docs/performance.md`, deletes
    `docs/perf-analysis/README.md`, and ships the offline `tests/perf.lua` anyway (WhatGroup
    precedent: offline scenarios suspend nothing, ship nothing to the client and add no SavedVariable).
    `libs/LibKa0s/` stays vendored whole, `Perf.lua` included (performance-§1, anti-patterns #48).
  - Task 15 appends the performance-§12 register row (spec section 5), citing Task 8's sweep commit.
  - Task 12 drops `core/PerfSetup.lua:24` from its literal sites (the file is gone by then).
  - Tasks 4, 7 and 14 never name `NS.HOLD_PERF`. Task 4 and Task 7 stand the addon down through
    the disable write seam. Task 14's C-16 cases and step 10 of the disabled suite take the
    library's reserved `perf` hold by its library constant in the test (a test-only second holder,
    the BankLedger and PrettyChat precedent), because slash-commands-§7 step 10 still requires
    both hold orders.
  - The buckets route (declare `envInject` / `regionTags`, bracket the env hook and the row
    painters) is not taken. Nothing in this plan brackets a path.
- [x] **Step 6:** Tick ledger row 0 in a docs-only commit with the plan, spec and findings file:
  `Add the 2026-10-10 audit+review fix spec, plan and consolidated findings` (this commit, which
  also records D1).

---

### Task 1: RegionTags hoist + install store (C-02, C-14 local, C-10 store)

**Files:** modify `modules/RegionTags.lua` (62-69). Test `tests/test_regiontags.lua`.

- [ ] **Step 1 (red):** add a case to `tests/test_regiontags.lua`: "a painter the client lacks is
  skipped, the other still installs". Build the addon with
  `LFGListApplicationViewer_UpdateApplicantMember` absent from the mock (nil it in an `opts` hook or
  on `m` before load). Assert that loading raises nothing,
  `NS.RegionTags.hooked.LFGListSearchEntry_Update == true`,
  `NS.RegionTags.hooked.LFGListApplicationViewer_UpdateApplicantMember == nil`, and that the search
  row still tags. Add `-- red under: drop the RegionTags.hooked store`. Run `lua tests/run.lua`.
  Expect FAIL, because `hooked` is nil.
- [ ] **Step 2 (implement):** replace the for-in literal with `local PAINTER_HOOKS = { … }` and loop
  over it. Add the lizard comment line, `RegionTags.hooked = {}`, and `RegionTags.hooked[name] = true`
  inside the `if`. Follow spec section 4, C-02.
- [ ] **Step 3:** gate green. Every existing `test_regiontags` case passes unchanged (they are the
  characterization).
- [ ] **Step 4 (measure):**
  `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`
  must give complexity `pass`, blind files 0, and max CCN ≤ 15. If any other file is blind or above
  15, stop and report it as a new finding.
- [ ] **Step 5:** regenerate `docs/test-cases.md` and the badge (+1).
- [ ] **Step 6: commit** `Hoist RegionTags' painter table so lizard can measure the tree` (body: "C-02 /
  PGE-24 / F-001; records installed painters for diagnostics (C-10). Refs #7").

---

### Task 2: Expression Strip (C-03, C-33)

**Files:** modify `modules/Expression.lua` (`Strip` 68-87, `trimBlankEdges` 25-32, header :5).
Test `tests/test_expression.lua`. Docs: `docs/ARCHITECTURE.md` `## Expression block format`.

- [ ] **Step 1 (red):** add these cases after "damaged block (begin without end)" (~59), using
  `E()` / `assertNil` / `assertEqual`:
  - (a) "close marker without ')' -> damaged".
  - (b) "wrapped block, close marker deleted -> damaged". `Merge("voice or myrealm", {"age <= 15"})`,
    gsub out `"%-%- %[pgfe%] close\n"`, then assert that Strip returns the input with `ok == false`,
    and that `Merge(d, {"age <= 10"})` and `Merge(d, {})` both return `nil, "damaged"`. Add
    `-- red under: drop the wrapped-and-not-closed check`.
  - (c) "deleting both close and ')' is refused (conservative)".
  - (d) "unwrapped comment-only block strips ok without a close pair".
  - (e) "strip keeps blank edge lines" over `{ "\nvoice\n\n", "  \nvoice", "voice\n", "-- note\n\n", "\n\n" }`,
    with `-- red under: restore trimBlankEdges in Strip`.
  - (f) the Clear path: `Merge(Merge("\nvoice\n", c), {}) == "\nvoice\n"`.
  - (g) round trip with blank edges: `Strip(Merge("\nvoice\n", c)) == "\nvoice\n"` with `ok == true`.
    (`Merge(Merge(x, c), c) == Merge(x, c)` is not the red case: it passes today, because Strip trims
    to `voice` on both passes. Keep it as a pinning assert inside (g) if wanted.)
  Run the suite. Expect (b), (c), (e), (f) and (g) to FAIL. (a) and (d) may pass: they pin existing
  behavior.
  The Apply-level proof of the C-03 risk note (`Apply.Clear` returns `false, "MSG_DAMAGED"` on the
  wrapped-without-close input) lands in Task 13, which owns `tests/test_apply.lua` in wave 4.
- [ ] **Step 2 (implement):** in Strip, add the `wrapped`/`closed` flags and the final refusal, update
  the comment at 65-67, `return table.concat(out, "\n"), true`, delete `trimBlankEdges`, and change
  header line 5 to "kept line for line (CRLF is normalized to LF)". Leave `Normalize` alone.
- [ ] **Step 3:** gate green (luacheck must not flag an unused local).
- [ ] **Step 4 (docs):** in ARCHITECTURE `## Expression block format` (~299-302), add the third damage
  shape (a wrapped block, whose body ends `and (`, with no close + `)` pair) and the both-deleted
  refusal.
- [ ] **Step 5:** regenerate the inventory and badge.
- [ ] **Step 6: commit** `Refuse a wrapped block with no close pair; keep blank edge lines on Strip`
  (body: "C-03 / F-003, C-33. Refs #9").

---

### Task 3: Settings page: PGF-link hook and Filters tab (C-01, C-15)

**Files:**
- Modify: `settings/Panel.lua` (`addPGFSkinLink` 163-179; MasterControls 46-81; header 5-6).
- Modify: `locales/enUS.lua` (`L["Filters"]`).
- Modify: `defaults/Profile.lua` (comments :6, :18-19).
- Modify: `settings/Schema.lua:5-6` header comment only ("Today every row is a Master controls row"
  is already stale because of `euiSkin`, and C-15 makes it more wrong).
- Tests: `tests/test_euisettings.lua`, `tests/test_setup.lua`, `tests/test_apply.lua` (comment :213).
- Docs: `docs/settings-panel.md` (:11, :24-37), `docs/schema.md` (:13-14), `docs/smoke-tests.md`
  (:54, :201), `docs/ARCHITECTURE.md:100`.

- [ ] **Step 1 (red, C-01):** add three cases in `tests/test_euisettings.lua` next to "a missing PGF
  skin gets a box" (~196), using `setup{ pgfSkin = "missing" }` and `openTab`.
  - **All three cases need an EditBox wrapper first.** The kit's AceGUI fake
    (`tests/_kit/mock_base.lua` `makeWidget`, ~1259) gives an EditBox widget no `editbox` field, so
    `box.editbox` is nil under the harness and today's hook (`settings/Panel.lua:174`) never runs in
    tests. Before `openTab`, wrap the lib's `Create` on the table `Helpers.AceGUI` points at (the
    same object, so the wrap reaches `addPGFSkinLink`):
    `local eb = m.__stubFrame(); local orig = AG.Create; AG.Create = function(self, t, ...) local w = orig(self, t, ...); if t == "EditBox" then w.editbox = eb end; return w end`.
    The stub frame chains `HookScript` and has `__fire` (`mock_base.lua` `stubFrame`, ~124). Put a
    counting `rawset(eb, "HighlightText", …)` spy on it. Restore `AG.Create` at the end of each case.
    This touches neither `tests/_kit/` nor `tests/wow_mock.lua`.
  - (a) `eb:__fire("OnEditFocusGained")` gives n == 1. With the wrapper this passes today (the hook
    installs): a pinning case.
  - (b) after `box:Release()`, n == 0 and `PGFSkinLinkBox == nil`
    (`-- red under: delete the OnRelease callback`).
  - (c) a second render hands the same `eb` to a new widget (the wrapper does this), then one focus
    gives n == 1 (`-- red under: drop the __pgfeLinkHook guard`). **Verify first** that calling
    `H.SelectTab('general', GROUP)` a second time re-renders the tab: count `Create("EditBox")` calls
    in the wrapper. If it does not, drive the second render the way the page does (release the
    scroll's children and fire the page's OnShow, or re-open the page), and assert the wrapper saw
    two EditBox creates before the focus.
  Expect (b) and (c) to FAIL.
- [ ] **Step 2 (red, C-15):**
  - Change `tests/test_euisettings.lua:54-65` to expect `H.MASTER_GROUP .. " | Filters | " .. GROUP`
    and rename the case "the General page has three tabs: Master controls, Filters, EllesmereUI skin"
    (`-- red under: AddRows(FILTER_ROWS) after EUI_ROWS`).
  - Add to `tests/test_setup.lua` (near :52): "Master controls holds only the canonical rows". Every
    row with `group == H.MASTER_GROUP` has a path in `{ enabled, state.debugConsole, global.minimap.shown }`,
    and `filtersActive` / `showRegionTags` have `group == NS.L["Filters"]` and `page == "general"`
    (`-- red under: put either back in MasterControls extra`).
  Expect both to FAIL.
- [ ] **Step 3 (implement):** follow spec section 4 for C-01 and C-15. Build `FILTER_ROWS`, call
  `StampClosureRows` and then `AddRows` after `MASTER_ROWS` and before `EUI_ROWS`, drop `extra` and
  the `MASTER_HOOKS.filtersActive` entry, add the `L["Filters"]` key, rewrite the header comment, and
  remove the §16 citation.
- [ ] **Step 4:** gate green. `tests/test_apply.lua:208` (the onChange still fires through `H.Set`)
  and `tests/test_regiontags.lua:68` stay green. Update the comment at `tests/test_apply.lua:213` to
  point at `FILTER_ROWS`.
- [ ] **Step 5 (docs):** update `docs/settings-panel.md` (the tree, with a **Filters** second tab and
  EllesmereUI skin third, and the §16 citation gone), `docs/schema.md:13-14`, `docs/ARCHITECTURE.md:100`
  ("plus the two extra rows" becomes "and the General Filters tab's two rows"), `defaults/Profile.lua`
  comments, `settings/Schema.lua:5-6` (the rows are the General page's Master controls, Filters and
  EllesmereUI skin rows), and `docs/smoke-tests.md:54` and `:201` (APPLY-21: Settings -> General ->
  Filters).
- [ ] **Step 6:** regenerate the inventory and badge **before each of the two commits** (both
  change the inventory: the first adds the three C-01 cases, the second renames one case and adds
  one).
- [ ] **Step 7: commit** two commits, each with its own regenerated `docs/test-cases.md` and badge:
  - `Hook the PGF-skin link box once per pooled frame and clear it on release` (C-01 / PGE-27).
  - `Move filtersActive and showRegionTags to a General Filters tab` (C-15 / PGE-23; "paths unchanged,
    no migration").

---

### Task 4: EllesmereUI skin hardening (C-05, C-20, C-30, C-29 EUISkin half)

**Files:**
- Modify: `modules/EUISkin.lua` (`lastSkip` :45; `blocked` ~306-314; `TryApply` ~319-333;
  `OnSwitch` ~337-343; `OnEUISkinScale` 360-363; STAND_UP ~369-373).
- Modify: `tests/wow_mock.lua` (`installEUI`: `spec.omit`, `spec.raise`; doc comment 331-335).
- Test: `tests/test_euiskin.lua`.
- Docs: `docs/ARCHITECTURE.md` `## EllesmereUI seams` (~241).

- [ ] **Step 1 (mock):** add `spec.omit` (a list of primitive names removed after the PRIMITIVES loop
  and the getter assignments) and `spec.raise` (the named primitive calls `error()`), and document
  both. Existing tests must stay green with neither set.
- [ ] **Step 2 (red, C-05):**
  - "a facade missing a primitive is refused before any paint": `painted{ omit = { "StateButtonLabel" } }`.
    Assert no raise, `IsApplied()` false, `HasFacade()` true, a second `TryApply()` false,
    `count("Shell") == 0`, and the panel shows. `-- red under: drop the REQUIRED shape check in blocked()`.
  - "a primitive that raises fails closed, once": `painted{ raise = "Dropdown" }`. TryApply returns
    false without raising, a second TryApply / UpdateVisibility leaves `count("Checkbox")` unchanged,
    and `OnSwitch(false)` shows `POPUP_RELOAD`.
    `-- red under: drop the pcall, or the paintFailed latch`.
- [ ] **Step 3 (red, C-20):**
  - "a skip is logged again after a console Clear": logging on (`NS.State.debug = true`, or
    `NS.DebugLog:SetEnabled(true)`), no panel built, TryApply twice gives one `skipped:` line;
    `NS.DebugLog:Clear()` and TryApply give the line again. Confirm the buffer field on the real
    instance first. `-- red under: the lastSkip memo`.
  - "a skip with logging off is logged once logging turns on".
- [ ] **Step 4 (red, C-29 EUISkin half):** "a stand-down restores the min/max glyph alpha". On the
  existing min/max test (~228), fire `MinimizeButton` OnEnter, then stand the addon down through the
  disable write seam (`NS.addon:OnSlashCommand("disable")`) and back up (`"enable"`). Never name
  `NS.HOLD_PERF`: Task 8 removes it (D1 = performance-§12). Assert the recorded `pgfeGlyph` vertex
  alpha equals `0.75`. `GLYPH_ALPHA` is a
  file-local (`modules/EUISkin.lua:35`) and is not exported, so the test hard-codes `0.75` with a
  comment citing that line. No recorder is needed: `tests/wow_mock.lua` already records
  `SetVertexColor` as `__vertexColor` (wow_mock.lua:262), so read `glyph.__vertexColor[4]` (not
  `__color`, which is `SetColorTexture`'s field). `-- red under: drop the glyph reset row`.
- [ ] **Step 5 (C-30, no red test possible):** "scale events before a paint are inert": no facade,
  fire `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`, assert no error and `IsApplied()` false. A
  red-first test is not possible, because the early return and the empty `checkBoxes` loop behave
  the same and the kit cannot spy on the local `layoutAccentMark`. Say so in the case comment.
- [ ] **Step 6 (implement):** follow spec section 4 for C-05, C-20, C-30 and C-29 (`REQUIRED`,
  `paintFailed`, the pcall, `OnSwitch` on `applied or paintFailed`, `DebugChanged("euiskin.skip", TAG, …)`,
  the `not applied` guard, and the glyph alpha reset in a STAND_DOWN row).
- [ ] **Step 7:** gate green. "Stood down, the callback paints nothing; the stand-up paints" (:153)
  and "theme and scale changes while stood down catch up at the stand-up" (~311) stay green.
- [ ] **Step 8 (docs):** in the facade paragraph, say the paint checks the facade shape first and
  fails closed (it logs, does not retry, and a reload drops any partial paint).
- [ ] **Step 9:** regenerate the inventory and badge **before each of the two commits** (the C-05
  commit adds two cases; the C-20/C-29/C-30 commit adds four).
- [ ] **Step 10: commit** `Check the EllesmereUI facade before painting and fail closed` (C-05) and
  `Log skin skips through DebugChanged; reset glyph hover on stand-down; skip relayout before paint`
  (C-20, C-29, C-30; Refs #11). Each commit carries its own regenerated inventory and badge.

---

### Task 5: PGF bridge seams, region probe, bridge test (C-04 bridge, C-32, C-31, C-10 SEAMS/env store)

**Files:**
- Modify: `core/PGFBridge.lua` (accessors, SEAMS 27-35).
- Modify: `modules/EnvInject.lua` (47-49, :29 comment, :89).
- Modify: `modules/Regions.lua` (`GetRegion` 46-51).
- Modify: `.luacheckrc` (28-29). The comment covers two kinds of global and must stay true for
  both: the PGF globals are read by `core/PGFBridge.lua`, `modules/Diagnostics.lua`
  (presence-only) and, until Task 7 lands the Season accessor, `modules/Season.lua`;
  `PremadeRegions` is read by `modules/EnvInject.lua:65`, `modules/RegionTags.lua:25` and
  `modules/Diagnostics.lua:44`. Write it that way (one clause per kind). Task 7 then drops Season
  from the PGF clause.
- Tests: `tests/test_bridge.lua`, `tests/test_regions.lua`, `tests/test_envinject.lua`, and
  `tests/pgf_fake.lua` if a structural field is missing from the fake. **Not** `tests/test_apply.lua`
  (Task 3 owns it in wave 1; see Step 6).
- Docs: `docs/ARCHITECTURE.md` `## PGF seams`, and the RegionTags concat-safe bullet of
  `## Taint Notes` (C-32).

- [ ] **Step 1 (red), `tests/test_bridge.lua`:**
  - "missing C.SPECIALIZATIONS is named": `m.pgf.PGF.C.SPECIALIZATIONS = nil` makes `Check()` return
    `false, "C.SPECIALIZATIONS"`. `-- red under: drop the SEAMS row`.
  - "Specializations/MapKeywords read through the bridge": `MapKeywords(2993)` returns the fake row,
    and both accessors return nil with no error when `C` is nil and when `PremadeGroupsFilter` is nil.
  - One case per structural seam (`d.panels`, `p.Dungeons`, `Advanced.Expression.EditBox`): nil it
    and assert it is named.
- [ ] **Step 2 (red, C-31):** rewrite the case at `tests/test_bridge.lua:60-64` exactly as in the
  spec (it is renamed, gets `-- red under: drop the activePanel check in Bridge.Commit`, and asserts
  `m.pgf.state.c2f4.dungeon.dungeon5` and `expression == "voice"`). It should pass at once. Prove the
  note by deleting the guard locally, seeing it go red, and restoring the guard.
- [ ] **Step 3 (red, C-32):** in `tests/test_regions.lua`, "a protected leader name is not matched":
  `T.bootAddon{ currentRegion = 1 }` and `NS.IsConcatSafe = function() return false end` make
  `GetRegion("Bob-Frostmourne")` nil. `-- red under: drop the IsConcatSafe clause in Regions.GetRegion`.
- [ ] **Step 4 (red, C-10 env store), `tests/test_envinject.lua`:**
  - `NS.EnvInject.hooked == true` under the mock. `-- red under: drop the store at EnvInject:89`.
  - With PremadeRegions nil and IsConcatSafe false, `Apply` leaves `env.region` nil and every
    `ALL_KEYS` flag false.
- [ ] **Step 5:** run the suite. Expect the cases above to FAIL, except the C-31 rewrite.
- [ ] **Step 6 (implement):** follow spec section 4 for C-04, C-32, C-31 and C-10 (bridge half). Find
  the PGF 7.6.2 source line for `MAP_ID_TO_KEYWORDS` before citing it. The `test_apply.lua:60`
  first-missing expectation (`"Dialog.RefreshButton"`) stays true whatever order the new rows take:
  that case nils only `RefreshButton`, and the fake (`tests/pgf_fake.lua:6`, `:25`, `:35`) supplies
  `C.SPECIALIZATIONS`, `dialog.panels`, `panel.Dungeons` and `Advanced.Expression.EditBox`, so no
  new row is ever the first missing one there. **Make no edit to `tests/test_apply.lua`**; this keeps
  wave 1's files disjoint. If the case unexpectedly goes red, stop and report rather than edit it.
- [ ] **Step 7:** gate green.
- [ ] **Step 8 (docs):** update ARCHITECTURE `## PGF seams`: the new seam count, the
  `C.SPECIALIZATIONS` row (checked), the `C.MAP_ID_TO_KEYWORDS` row (unchecked, initials fallback),
  the structural rows, and a trimmed Debug row. In `## Taint Notes`, the RegionTags bullet already
  lists the concat-safe guard on the row painters; add that the env hook's region lookup
  (`Regions.GetRegion`) now probes the leader name the same way (C-32 refinement 6).
- [ ] **Step 9:** regenerate the inventory and badge **before each of the two commits** (the C-04 /
  C-10 commit adds the bridge and env-store cases; the C-32 / C-31 commit adds the region case and
  renames the minimized-commit case).
- [ ] **Step 10: commit** `Route PGF constants through the bridge and check the seams they need` (C-04
  bridge half, C-10 SEAMS; Refs #7), then `Probe leader names before matching; make the minimized-commit
  test assert what it keeps` (C-32, C-31). Each carries its own regenerated inventory and badge.

---

### Task 6: GitHub admin, upstream issues and the local re-vendor tracker (C-27, C-12, C-14, C-36, C-37, #15)

**Files:** none (no commit). The integrator records the outcome in row 6's Commit cell in the
wave-1 ledger commit (see the ledger rules), for example
`labels set; issues LibKa0s#…, WowAddonStandards#…, PGFE#…`. These are shared-repo writes that git
cannot revert, so run each block once and check it.

- [ ] **Step 1 (C-27 colors, first, so later label swaps land colored):**
  ```sh
  R=tusharsaxena/PremadeGroupsFilterExtension
  gh label edit 'state:untriaged'  -R $R --color ff0000
  gh label edit 'state:triaged'    -R $R --color ffff00
  gh label edit 'state:done'       -R $R --color 00ff00
  gh label edit 'state:will-not-do' -R $R --color 0000ff
  gh label edit 'severity:critical' -R $R --color 110000
  gh label edit 'severity:high'    -R $R --color 110800
  gh label edit 'severity:medium'  -R $R --color 111100
  gh label edit 'severity:low'     -R $R --color 001100
  gh label list -R $R --json name,color
  ```
  Verify all eight against the table. No in-repo test can cover this, so the `gh label list` output
  is the evidence.
- [ ] **Step 2 (C-27 re-severity, owner decision):** set each audit-carried issue #4-#19 to
  `severity:high` (vocabulary: "a standard deviation carried out of an audit or review bundle").
  Don't touch #1-#3.
  ```sh
  for n in 4 5 6 7; do gh issue edit $n -R $R --remove-label severity:medium --add-label severity:high; done
  for n in 8 9 10 11 12 13 14 15 16 17 18 19; do gh issue edit $n -R $R --remove-label severity:low --add-label severity:high; done
  ```
- [ ] **Step 3 (#15 narrowing, C-23):**
  `gh issue edit 15 -R $R --title "Logo files named pgfe.logo.* instead of after the addon folder (layout-§4)"`
  and edit the body (`--body-file`) to drop the PGE-14 sentence and the `MAIN_LOGO_SIZE` direction.
  Say that PGE-14 is already fixed by `BuildLandingPage`, and that the 512 render lands with the
  rename.
- [ ] **Step 4 (upstream labels):** `gh label list -R tusharsaxena/LibKa0s` and
  `-R tusharsaxena/WowAddonStandards` both carry `state:`/`severity:` labels. Create each issue with
  `--label state:untriaged --label severity:<x>`, plus `bug` or `enhancement` if the repo has them.
  **Why the upstream severities are not `severity:high`:** the vocabulary row Step 2 applies ("a
  standard deviation carried out of an audit or review bundle") describes a repo's own departure
  from the standard, found by an audit of that repo. None of the upstream issues is that: C-12 and
  C-14 (LibKa0s) are defects in the shared test kit, C-14 (WowAddonStandards) is an inaccurate
  hazard row in the standard's own text, and C-36 / C-37 are roster and wording enhancements to the
  standard. They take impact severities instead: C-12 `medium` (on a crash it misreports the release
  gate's complexity suite; latent here once C-02 lands), the rest `low` (documentation or tooling
  ergonomics, no wrong verdict). Each issue body carries one line saying so, so the triager can
  re-rate them under that repo's own reading of the vocabulary.
- [ ] **Step 5 (upstream issues):** `gh issue create -R <repo> --title … --body-file <scratch file>`.
  Each body has these headings: Summary, Where (file:line), Repro, Proposed change, Tests, Found by
  (`PremadeGroupsFilterExtension docs/reviews/2026-10-10/06_CONSOLIDATED_FINDINGS.md` C-nn plus the
  PGE/F ids). Write the bodies in the scratchpad, not the repo.
  - **LibKa0s, severity:medium, bug:** "Complexity runner ignores lizard's exit status and parses a
    traceback as the footer" (C-12). `testkit/run-automated-tests.sh:508` and `:522`. Repro: a
    for-in function-literal table at file scope gives a TypeError, then a garbled footer, then
    54/54 blind files, and `manifest.json` may be invalid JSON (:697). Proposal:
    `raw=… && cx_rc=0 || cx_rc=$?` with stderr in its own file; a shape check of 8 numeric fields
    after `Total nloc`; on failure set complexity fail with the note "lizard exited <rc> (crashed or
    bounded)", zero `CCN_*`, skip parity, and run a bounded per-file retry that names the crashing
    file; `fld` forced numeric; fixture tests (fake lizard: traceback + exit 1, a stderr warning
    after the footer with exit 0, exit 124); Kit.VERSION 38 -> 39.
  - **LibKa0s, severity:low, bug:** "Sanitizer/parity do not recognize the file-scope for-in
    function-literal shape" (C-14). `testkit/lizard_sighted.lua:126-145` leaves it byte-identical.
    Proposal: handle it in the runner (`crashed` rows separate from `blind`); an optional
    `S.forInFunctionLiterals(src)` detector so the note says "hoist the table to a local"; tests in
    `testkit/test_lizard_sighted.lua`; ship in the same release as the C-12 issue (cross-link it).
  - **WowAddonStandards, severity:low, documentation/bug:** "automated-tests hazard table: the
    for-in function-literal row says silent drop; at file scope lizard 1.24.0 crashes" (C-14).
    `standards/standards/automated-tests.md:155`. Proposal: split file scope (raises, aborts the
    run) from in-function (folds into the enclosing CCN, parity flags it); the same remedy (hoist to
    a named local); patch bump + CHANGELOG.
  - **WowAddonStandards, severity:low, enhancement:** "ADDONS.md roster omits Ka0s Premade Groups
    Filter Extension" (C-36). Row text:
    `| Ka0s Premade Groups Filter Extension | ../../PremadeGroupsFilterExtension/ | https://github.com/tusharsaxena/PremadeGroupsFilterExtension | Enabled |`,
    alphabetically between Party Frame Enhanced and Pretty Chat. Sweep `grep -rniE "eleven|11 addons"`
    (leave dated history alone); patch bump. The body also notes, under a "Related, outside this
    repo" heading, that the `dev-copilot:wow-standards-audit` skill description ("the eleven addons")
    lives in the separate dev-copilot repo and carries the same count; propose a rule-based wording
    ("every addon in `standards/ADDONS.md`") or a dated count there. It is surfaced only: this run
    files nothing on dev-copilot (the owner named LibKa0s and WowAddonStandards as the upstream
    repos).
  - **WowAddonStandards, severity:low, enhancement:** "slash-commands-§7: name one-shot third-party
    registrations among the stand-down survivors" (C-37). Evidence:
    `PremadeGroupsFilterExtension modules/EUISkin.lua:382-395` (`EllesmereUI.RegisterSkin`, no
    unregister). Proposed wording: "a one-shot registration with a third-party addon that cannot be
    undone (e.g. a skin or callback registry); its body must gate itself on the latch and do nothing
    visible or persistent while stood down, and the stand-up must retry anything it skipped". Add a
    matching conformance-test line.
- [ ] **Step 6 (local re-vendor tracker, C-12 fixNotes):** after the two LibKa0s issues exist, file
  one issue on this repo so the deferred re-vendor (spec section 7 non-goal) is tracked:
  `gh issue create -R $R --title "Re-vendor LibKa0s after the complexity-runner fix" --label state:untriaged --label severity:low --label enhancement --body-file <scratch>`
  (drop `enhancement` if the repo lacks it). The body links both LibKa0s issues (C-12 runner exit
  status, C-14 sanitizer shape) and names what the re-vendor must carry: both payloads whole
  (`libs/LibKa0s/`, `tests/_kit/`) through `dev-copilot:wow-revendor-libka0s`, the CLAUDE.md
  provenance line rolled in the same commit, kit revision 38 -> 39 (or whatever ships), and a
  complexity re-run. Severity `low`: once C-02 lands nothing here trips the runner bug. Then edit
  each LibKa0s issue body (or comment on it) to link back to the new local issue.
- [ ] **Step 7:** hand the six issue URLs (five upstream, one local) to the integrator for row 6 of
  the wave-1 ledger commit. In M3 (the PR body), ask the owner whether to also file the two optional
  ideas: a LibKa0s `disabledReason()` descriptor field (C-16 / PGE-12) and a WowAddonStandards §4
  ordered-dispatch carve-out (C-18).

---

### Task 7: Season request guard, affix event, panel tooltip, dialog store (C-06, C-07, C-04 Season half, C-29 Panel half, C-10 Panel store)

**Files:**
- Modify: `modules/Season.lua` (`shortName` 20-23, `GetDungeons` 29-43, new `RequestOnce` /
  `ResetRequest`).
- Modify: `modules/Panel.lua` (`updateReadout` 165-170, `OnPanelEnteringWorld`, FEATURE_EVENTS
  882-884, STAND_DOWN 885-887, `HookDialog` :892).
- Modify: `tests/wow_mock.lua` (`mapInfoRequests`; `GameTooltip` owner recorders and a real
  `GetParent`).
- Modify: `.luacheckrc:28-29` (drop `modules/Season.lua` from the PGF-reader clause Task 5 wrote).
- Tests: `tests/test_panel.lua`, `tests/test_season.lua`, `tests/test_surface_parity.lua`.
- Docs: `docs/data-flow.md` (86-89), `docs/smoke-tests.md`, `docs/ARCHITECTURE.md`
  `## Event Subscriptions` + `## Known Limitations`.

- [ ] **Step 1 (mock):** add `M.mapInfoRequests = 0` in the reset block (~38) and document it in the
  header list (~17-25). Change `RequestMapInfo` at :80 to count. Never fire the event from the mock.
- [ ] **Step 1b (mock, GameTooltip):** `M.GameTooltip` is the kit's bare `newFrame()`
  (`tests/_kit/mock_base.lua:1154`): its `SetOwner` is a metatable no-op and `GetOwner` /
  `GetParent` fall through to the uppercase fallback, which returns the frame itself. So
  `GameTooltip:GetOwner()` always answers `GameTooltip`, the stand-down test below can never go
  green, and a `while o do … o = o:GetParent() end` walk started from it never ends. In
  `tests/wow_mock.lua` (the addon's own mock, not `_kit`), after the kit builds `M.GameTooltip`,
  rawset `SetOwner = function(self, owner, anchor) self.__owner = owner; self.__anchor = anchor end`,
  `GetOwner = function(self) return self.__owner end`, `GetParent = function() return nil end`, and
  have `Hide` clear `__owner`. Document them in the header list. Existing tooltip tests must stay
  green.
- [ ] **Step 2 (red), `tests/test_panel.lua` near "readout says loading" (~286):**
  - "an empty map table asks the server once, not every round trip": `enableAddon{}`, `Create`,
    `Refresh`, then MAPS_UPDATE ×3, COMPLETED, and a level-box `typeInto(f.levelBox, "12")` +
    OnEnterPressed. `m.mapInfoRequests == 1`. `-- red under: drop the request guard`.
  - "a populated map table still requests once": `seasonFromScreenshot(m)`, then Refresh ×2,
    MAPS_UPDATE and `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE`. The count is 1.
    `-- red under: request only when GetDungeons is nil` (#6).
  - "a rollover re-arms the request": populated, then `m.mapTable = {}` and MAPS_UPDATE ×2 add
    exactly 1. This is the guard against the C-06 loop coming back: the first empty read after a
    full one resets **and sends** in the same `GetDungeons` call, and the second empty read neither
    resets nor sends, because the reset cleared the "was full" memory (spec C-06 state machine).
    `-- red under: leave lastFull set on reset` (the count then grows by one per MAPS_UPDATE). Add
    the single-event form too: one MAPS_UPDATE after the rollover already adds 1
    (`-- red under: ResetRequest without the RequestOnce after it`).
  - "PLAYER_ENTERING_WORLD re-arms the request".
  - "the affix event recomputes Smart and leaves loading" (copy :833-838).
    `-- red under: drop the AFFIX FEATURE_EVENTS row`.
  - "a stand-down hides a tooltip the panel showed": spy `m.GameTooltip.Hide`, fire OnEnter on a
    `tooltip()` widget (it calls `GameTooltip:SetOwner(widget, …)`, now recorded), stand down with
    `NS.addon:OnSlashCommand("disable")` (never `NS.HOLD_PERF`, which Task 8 removes), and assert
    Hide was called.
    `-- red under: drop the tooltip hide in the STAND_DOWN row`.
  - The mirror: a tooltip owned by a frame outside the panel is left shown by the stand-down.
  - "the dialog hook install is recorded": `NS.Panel.dialogHooked == true`.
- [ ] **Step 3 (red), `tests/test_season.lua`:**
  - "Apply with no panel still requests season data": `m.mapInfoRequests == 1` after `NS.Apply.Run{}`.
  - "short names fall back to initials without PGF's keyword table":
    `m.pgf.PGF.C.MAP_ID_TO_KEYWORDS = nil`. This one **passes today** (`modules/Season.lua:22-25`
    already nil-guards and falls back to `initials`): it is a pinning case that must stay green
    through the accessor switch. `-- red under: drop the nil guard in Bridge.MapKeywords`.
- [ ] **Step 4 (red), `tests/test_surface_parity.lua`:** "no module reads PGF outside the bridge".
  Read `modules/Season.lua` and `modules/EnvInject.lua` with the loader's file reader, and assert
  neither contains `PremadeGroupsFilter`.
  `-- red under: revert Season.lua to the direct C.MAP_ID_TO_KEYWORDS read`.
- [ ] **Step 5:** run the suite. Expect every new case to FAIL except the initials-fallback pinning
  case (Step 3) and the outside-owner tooltip mirror (Step 2), which pass today.
- [ ] **Step 6 (implement):** follow spec section 4 for C-06/C-07 (its state machine exactly:
  `lastFull` cleared on the reset, `RequestOnce` after `ResetRequest` in the same call) and the
  Season/Panel parts of C-04, C-29 and C-10. The tooltip owner walk carries a self-parent guard:
  `local o = GameTooltip:GetOwner(); while o and o ~= Panel.frame do local p = o:GetParent(); if p == o then o = nil else o = p end end`.
  Drop `modules/Season.lua` from the `.luacheckrc` PGF-reader clause.
- [ ] **Step 7:** gate green. Existing cases at `tests/test_panel.lua:286-292` and `:827-850` stay
  green.
- [ ] **Step 8 (docs):**
  - ARCHITECTURE: an event-table row for `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE`, and a Known Limitations
    entry ("bests read 0 until the reply; the client cannot tell never-timed from not-loaded").
  - `docs/data-flow.md:86-89`: one request per episode, re-armed on rollover and
    `PLAYER_ENTERING_WORLD`, three events.
  - `docs/smoke-tests.md`: an in-client check for off-season and fresh login (exactly one
    `RequestMapInfo` per loading screen; no loop).
- [ ] **Step 9:** regenerate the inventory and badge **before each of the two commits** (the C-06 /
  C-07 commit adds the request and affix cases; the C-29 / C-10 / C-04 commit adds the tooltip,
  dialog-store, initials and surface-parity cases).
- [ ] **Step 10: commit** `Request season data once per episode and on the affix event` (C-06 / F-002,
  C-07; Refs #6), then `Hide the panel's tooltip on stand-down; record the dialog hook; read map
  keywords through the bridge` (C-29, C-10, C-04; Refs #7). Each carries its own regenerated
  inventory and badge. Note `wc -l modules/Panel.lua` (895 at `0dabcde`) in the task report: Tasks 7
  and 13 both add to it, and Task 16 needs a Disposition if it crosses 1000.

---

### Task 8: performance-§12 exemption: remove the perf wiring, ship `tests/perf.lua` (C-09)

**Owner decision D1 (Task 0 Step 5, 2026-10-10): the performance-§12 no-combat-path exemption, not
buckets.** Wave 2b: Task 8 runs alone, cut from the tip that holds all of wave 2 (see Parallelism).
It needs Task 7 (the eighth `NS.FEATURE_EVENTS` row, which the sweep names) and Task 9 (AceTimer
removed, so the sweep can say no timer library is embedded).

**What the standard requires (performance-§12, read in `../WowAddonStandards/standards/standards/performance.md`
before starting; spec section 4 C-09 has the summary):**

- **Qualifying test.** Criterion **(a)**: no `OnUpdate` handler, no repeating ticker, and no event
  handler doing more than occasional work while the player is in combat, proven by a **committed
  whole-repo sweep** of `RegisterEvent` / `SetScript("OnUpdate"` / `C_Timer` that names the
  per-event work for each hit. Plus **(b)**, which applies here: the capture windows open on the
  player's combat state (performance-§7) and this addon's hot paths run while the player browses the
  Group Finder, so every declared bucket would read `0.000` by construction. (c) does not apply.
- **What the exemption suspends:** the instance and `core/PerfSetup.lua` (performance-§1), the `perf`
  verb registration (§4), `<Addon>PerfDB` (§5; the TOC then declares **one** SavedVariables global,
  toc-file-§2 and savedvariables-§4, and a PerfDB declared by an exempt addon is non-compliant), the
  suspend/resume contract (§6), the `tests/perf.lua` MUST (§9), and documentation-§3's
  `docs/perf-analysis/README.md` together with the `docs/perf-analysis/` store.
- **What it does NOT suspend:** whole-folder vendoring of `libs/LibKa0s/` (`Perf.lua` stays; the TOC
  keeps its one `libs\LibKa0s\LibKa0s.xml` line, and `tests/loader.lua` keeps the four
  `libs/LibKa0s/Perf*.lua` entries, anti-patterns #48); `perf` stays a **reserved, unregistered**
  verb (slash-commands-§2); `docs/performance.md` stays, shrunk to one screen; and the release
  notes still state the perf result.
- **Recorded once, in the register.** The row lands in Task 15 (spec section 5 has its exact text)
  and cites this task's sweep commit, so record that sha in the task report.

**How the vendored runner treats it (`tests/_kit/run-automated-tests.sh`, read before Step 5).** The
runner reads the register for a `performance-§12` Rule cell **only when `tests/perf.lua` is absent**
(:272, the `register_scan` at :208-297); that is the second sanctioned skip reason of
automated-tests-§3. When the file exists it runs `lua tests/perf.lua`, with `--out <bundle>/perf.json`
when it writes a bundle and `--label <text>` when one is passed (:446-448). It counts the scenario
table structurally: a header line starting `scenario  iters`, then rows of **exactly five**
whitespace-separated fields whose second field is an integer, ending at the first blank line
(:455-480). The suite is `pass` on exit 0 and `fail` otherwise (:482). So with `tests/perf.lua`
shipped, perf reads `pass` and the register row is never consulted by the runner. The row is still
the exemption's ratification for audits (performance-§12, *Recorded once*), and it would supply the
skip reason if `tests/perf.lua` were ever removed. The release gate (automated-tests-§3) then
needs perf at `pass`, which M1 and Task 16 check.

**`tests/perf.lua` under the exemption.** §12 suspends §9 as a MUST, so shipping the runner is a
choice (WhatGroup precedent, `../WhatGroup/tests/perf.lua`: offline scenarios suspend nothing, ship
nothing to the client and add no SavedVariable). It still follows §9's rules: outside the green
gate (never listed in `tests/run.lua`), no assertion on wall-clock time, assertions only on
deterministic quantities (API call counts and bytes allocated per iteration, with a full
`collectgarbage("collect")` on either side of each measured loop), and timings printed for
orientation with a note to compare within a run only. §9's zero-overhead scenario has no subject
here, because nothing is bracketed; the stood-down scenario (c) takes its place on the hottest path.

**Files:**
- Delete: `core/PerfSetup.lua`; `docs/perf-analysis/README.md` (and the `docs/perf-analysis/`
  directory, which holds only that file at `0dabcde`; check with `ls` first and stop if it holds a
  capture bundle).
- Modify: `PremadeGroupsFilterExtension.toc` (:7 `## SavedVariables:` becomes
  `PremadeGroupsFilterExtensionDB` alone; delete :60-61, the PerfSetup annotation and line; re-derive
  the `core\LifecycleSetup.lua` annotation at :58, which names PerfSetup today, from its real
  load-time readers, keeping a `# LOAD-BEARING:` or `# Conventional` first line so Task 9's
  annotation test stays green).
- Modify: `core/LifecycleSetup.lua` (header 4-7: one production hold, `disabled`; the library's other
  reserved hold, `perf`, is taken by nothing in this addon; delete `NS.HOLD_PERF` at :46 and :51).
- Modify: `settings/Slash.lua` (delete the `perf` row :48-49, `runPerf` :192-195 and its forward
  declaration at :19; check the LibKa0s-absent host stub's verb handling for a `perf` special case).
- Modify: `locales/enUS.lua` (delete the `/pgfe perf` help key at :42-43, or Task 12's two-way key
  parity flags it as unused).
- Modify: `.luacheckrc` (drop `PremadeGroupsFilterExtensionPerfDB` at :18 and :44; drop
  `debugprofilestop` at :28 once the Step 0 grep shows no reader outside `libs/` and `tests/_kit/`;
  if `tests/perf.lua` needs it, scope it to that file instead).
- Modify: `tests/run.lua` (drop the `LibKa0s-Perf-1.0` surface source at :54), `tests/loader.lua`
  (drop the PerfDB reset at :99; keep :45-48), `tests/test_surface_parity.lua` (delete the Perf stub
  parity case :64-75), `tests/test_setup.lua` (replace the harness case :87-92),
  `tests/test_slash.lua` (the verb list at :25 drops `perf`; replace the case at :46-51),
  `tests/test_disabled.lua` (the perf-hold case :43-52, see Step 2; Task 14 rewrites the suite later).
- Create: `tests/perf.lua` (not in `tests/run.lua`).
- Docs: `docs/performance.md` (one screen plus the sweep), `docs/schema.md` (:3-4),
  `docs/module-map.md` (:19, :42), `docs/slash-dispatch.md` (:19, and any command count),
  `docs/testing.md` (:45 perf row), `docs/ARCHITECTURE.md` (:47 stand-down accessor, :58 Perf bucket
  row, :70 setup list, :118 SavedVariables, :140 `perf` row, :338 store list naming
  `docs/perf-analysis/<run>/`, :356-357 Documentation map rows). **Not** `## Documented deviations`
  (Task 15).

- [ ] **Step 0 (find every reference):** run
  `grep -rn -i -E 'perf|HOLD_PERF|debugprofilestop' --exclude-dir=libs --exclude-dir=_kit --exclude-dir=audits --exclude-dir=reviews --exclude-dir=automated-tests --exclude-dir=superpowers --exclude-dir=.git .`
  and classify every hit. A `performance-§N` citation or the word "perfect" is not wiring. The
  wiring hits at `0dabcde` are exactly the ones in **Files**; re-check the line numbers after
  waves 1-2. A hit not listed there goes into this task, not a later one.
- [ ] **Step 1 (red):**
  - `tests/test_setup.lua`: "setup: no perf harness is wired (performance-§12)". Assert
    `NS.Perf == nil` and `NS.HOLD_PERF == nil`; that the raw TOC's (`io.open`) `## SavedVariables:`
    value is exactly `PremadeGroupsFilterExtensionDB`; that no TOC file line names
    `core\PerfSetup.lua`; and that `libs/LibKa0s/Perf.lua` still opens (whole-folder vendoring).
    `-- red under: restore the PerfDB SavedVariable, the PerfSetup TOC line or NS.HOLD_PERF`.
  - `tests/test_slash.lua`: "slash: perf is reserved but not registered". No `NS.COMMANDS` entry
    has the verb `perf`, and `/pgfe perf` prints the library's unknown-command line followed by the
    index, the **same** lines enabled and after `/pgfe disable` (LibKa0s Slash minor 14+,
    `libs/LibKa0s/Slash.lua:863-873`). `-- red under: restore the perf COMMANDS row`.
  Expect both to FAIL.
- [ ] **Step 2 (implement the removal):** apply every edit in **Files** except `tests/perf.lua` and
  the `docs/performance.md` sweep. In `tests/test_disabled.lua`, the perf-hold case takes the hold
  by the library's constant as a test-only second holder,
  `local HOLD_PERF = (T.LibStub("LibKa0s-Lifecycle-1.0", true) or {}).HOLD_PERF or "perf"`
  (BankLedger precedent, `../BankLedger/tests/test_disabled.lua:42`), and drops the
  `NS.Perf.suspended` assert. Re-derive the TOC annotation. Delete `core/PerfSetup.lua` with
  `git rm`. `libs/` is not touched.
- [ ] **Step 3:** gate green. Regenerate the inventory and badge (one case renamed in each of
  `test_setup` / `test_slash`, the parity case deleted). **Commit A** `Take the performance-§12
  exemption: remove the unused perf wiring` (body: "C-09 / PGE-09. The owner chose the
  performance-§12 no-combat-path exemption over buckets at checkpoint D1 on 2026-10-10.
  libs/LibKa0s/ stays vendored whole, Perf.lua included; perf stays a reserved, unregistered verb.
  The register row lands in Task 15. Refs #5").
- [ ] **Step 4 (the sweep, `docs/performance.md`):** run
  `grep -rn -E 'RegisterEvent|RegisterUnitEvent|OnUpdate|C_Timer|NewTicker|ScheduleTimer|ScheduleRepeatingTimer|hooksecurefunc|HookScript' --exclude-dir=libs --exclude-dir=tests --exclude-dir=docs --exclude-dir=.git .`
  and list every `NS.FEATURE_EVENTS` row (`grep -rn 'FEATURE_EVENTS\[' modules core`). Write the
  table: one row per hit, its file:line, the per-event (or per-call) work, and whether it can run
  in combat. Expected at the wave-2 tip: no `OnUpdate`, no `C_Timer`, no AceTimer; one
  registration site (`core/PGFE.lua` `registerFeatureEvents`, through `NS.SafeRegisterEvent`) over
  the eight `FEATURE_EVENTS` rows, each one small refresh; the hooks run on player UI actions (PGF's
  per-result env hook while PGF filters a search, the dialog hooks, the two Group Finder row
  painters, the skin and tooltip `HookScript`s); `Apply` refuses in combat. **If the sweep finds an
  `OnUpdate`, a repeating timer, or an in-combat handler doing real work, criterion (a) fails: stop
  and take it to the owner** (the exemption does not qualify, and the buckets route comes back).
  Then rewrite the rest of the page to one screen: the addon brackets nothing; (b) applies and why;
  where the sweep lives (this page); the re-arm trigger in the standard's words ("the first
  `OnUpdate` handler, repeating ticker, or in-combat event handler doing real work re-arms the full
  wiring MUST"); and that the offline scenarios in `tests/perf.lua` are the measurement, recorded in
  `docs/automated-tests/`. Keep the existing "Where the addon spends time" list, trimmed, and drop
  "Not bracketed by a perf bucket", "The harness" and the in-game capture link.
- [ ] **Step 5 (`tests/perf.lua`):** model it on `../WhatGroup/tests/perf.lua` (read it first): its
  argument loop (`--out`, `--label`, anything else exits 2 with a usage line), the
  `tests/loader.lua` instance driven through `OnInitialize` / `OnEnable`, payloads built outside
  each measured loop, a full collect either side, and the JSON writer for `--out`. Open with a
  header comment saying why the file exists under the performance-§12 exemption. Scenarios (names
  without spaces, about 1000 iterations each; read `tests/wow_mock.lua` and `tests/pgf_fake.lua` for
  how to count the calls):
  - (a) `envNoPR`: synthetic results through PGF's `PutPremadeRegionInfo` with the post-hook,
    PremadeRegions absent (`injectRegions`, `Regions.GetRegion`, the C-32 probe).
  - (b) `envWithPR`: the same with PremadeRegions loaded; asserts no region lookup is made.
  - (c) `envStoodDown`: after `/pgfe disable`; asserts **0** bytes/iter and **0** API calls/iter (the
    early return).
  - (d) `searchRowPaint`: `OnSearchEntryUpdate` over fake entries; counts `GetSearchResultInfo` and
    `SetText` per iteration.
  - (e) `applicantRowPaint`: `OnApplicantMemberUpdate` over fake applicants, the same counts.
  - (f) `combatEvents`: with `InCombatLockdown` answering true, fire each `FEATURE_EVENTS` event and
    `PLAYER_REGEN_DISABLED`; pins the API calls per event the sweep names, and 0 for the
    unregistered combat event. This is the measured backing of criterion (a).
  Pin each byte and call ceiling to the measured value with a stated margin, in a commented table
  at the top of the file. Print exactly the runner's shape: a header
  `scenario iters ms/iter api/iter bytes/iter` (five columns), one five-field row per scenario, a
  blank line, then the failed assertions; exit 1 on any failure. **Keep it lizard-safe:** the kit's
  complexity runner (`tests/_kit/run-automated-tests.sh:505-508`) scans every `*.lua` outside
  `libs/` and `tests/_kit/`, `tests/perf.lua` included. No function literals in a `for … in` header
  (at file scope that crashes lizard 1.24.0, the C-02 shape); hoist scenario tables to named locals;
  keep each function at CCN ≤ 15. Then:
  - `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/perf.lua` exits 0;
  - `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite perf --no-bundle`
    shows perf `pass` with 6 scenarios (not `skip`);
  - `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`
    still shows complexity `pass`, blind files 0, max CCN ≤ 15;
  - `luacheck .` stays 0/0 (it lints `tests/perf.lua` too).
- [ ] **Step 6 (docs):**
  - `docs/schema.md`: one SavedVariables global.
  - `docs/module-map.md`: drop the PerfSetup load-order line and table row.
  - `docs/slash-dispatch.md`: drop the `perf` row and note that `perf` is reserved and unregistered
    (performance-§12); fix any command count.
  - `docs/testing.md` :45: the perf row still runs `lua tests/perf.lua`; add that the addon holds
    the performance-§12 exemption and ships the offline scenarios anyway.
  - `docs/ARCHITECTURE.md`: :47 (one production hold, `disabled`), :58 (replace the Perf bucket
    row with "No Perf instance: performance-§12 exemption; the re-arm trigger is in `## Documented
    deviations`"), :70 (drop Perf from the setup list), :118 (drop the PerfDB bullet), :140 (drop
    the `perf` row, say it is reserved and unregistered), :338 (drop `docs/perf-analysis/<run>/`),
    :356 (`| perf-analysis/README.md | Not applicable | The performance-§12 exemption is held; no harness is wired |`,
    the documentation-§3 shape), :357 (the `slash-dispatch.md` trigger: 16 commands becomes 15).
- [ ] **Step 7:** gate green. Regenerate the inventory and badge if any case changed since
  Commit A.
- [ ] **Step 8: Commit B** `Commit the combat-path sweep and ship the offline perf scenarios` (C-09;
  body: "The whole-repo sweep performance-§12 criterion (a) requires, in docs/performance.md, and
  tests/perf.lua's six offline scenarios. Refs #5"). Put Commit B's sha in the task report: it is
  the sweep commit Task 15's register row cites.

---

### Task 9: TOC annotations, AceTimer removal, logo rename + 512 render (C-21, C-35, C-23)

**Files:**
- Modify: `PremadeGroupsFilterExtension.toc` (:6, :22, :49-50, :73, :84-85, :93, :98-99).
- Modify: `core/PGFE.lua` (:9-10).
- Remove: `libs/AceTimer-3.0/`.
- Rename: `media/logos/pgfe.logo.{128.tga,tga,png}` -> `premadegroupsfilterextension.logo.{128.tga,tga,png}`.
- Modify: `core/LauncherSetup.lua:13`, `settings/Panel.lua:18`, `DEPENDENCIES.md:76-84`,
  `docs/module-map.md`, `docs/ARCHITECTURE.md` `## Module Map` (load-order summary 62-65).
- Tests: `tests/test_harness.lua`, `tests/test_setup.lua` (:127 and new cases).

- [ ] **Step 1 (red, C-21), `tests/test_harness.lua`:** "every addon file in the TOC is annotated".
  Parse the raw TOC (`io.open`, CR stripped). For each non-`libs\`, non-`locales\` file line, take
  the contiguous block of `#` comment lines directly above it and assert that the block's **first**
  line starts `# LOAD-BEARING:`, `# Conventional` or `# LAST`. Checking only the line directly above
  would fail on the three annotations that already run over two lines: `core\PGFE.lua` (toc:49-50,
  continuation `# NS.FONT_MONO…`), `modules\EUISkin.lua` (:84-85, `# loaded first…`) and
  `settings\OptionsSetup.lua` (:95-96, `# Helpers.MasterControls…`). A block that is a section
  heading (`# Modules`, `# Settings …`) with no annotation under it does not count.
  `-- red under: delete one per-line annotation`. Expect FAIL (`settings\Panel.lua` and the modules
  carry no per-line comment).
- [ ] **Step 2 (implement C-21):** write the per-line annotations from spec section 4. Reword :49-50
  and :93 (check whether `settings/Profiles.lua` reads `SchemaRuntime` at load, and get the count
  right). Sync `docs/module-map.md` "Load order and why" (core/PGFE.lua and core/PGFBridge.lua come
  before EnvInject and Panel; settings/Slash.lua captures `NS.SchemaRuntime.*`; mention
  `NS.STAND_UP`). Keep the ARCHITECTURE `## Module Map` summary consistent with it (62-65: "with
  every load-bearing position annotated at its TOC line" becomes "with every addon file's TOC line
  annotated", and the order list still matches). Regenerate the inventory and badge (+1 case). Gate
  green. **Commit** `Annotate every TOC line with what it needs at load`
  (C-21 / PGE-06/07/08/28; Refs #12).
- [ ] **Step 3 (red, C-35), `tests/test_harness.lua`:** "AceTimer is not embedded".
  `NS.addon.ScheduleTimer == nil` (this half goes red today: the kit's AceAddon fake embeds AceTimer's
  mixins, `tests/_kit/mock_base.lua:540`), and no line of the **raw TOC read with `io.open`** matches
  `AceTimer%-3%.0` (pins `.toc:22`). Do not use `Loader.tocFiles` for the second half: it drops every
  `libs\` line (`tests/_kit/loader.lua:115-129`), so that assert would be vacuously true and could
  never go red. `-- red under: restore the AceTimer-3.0 mixin, or the TOC line`. Expect FAIL.
- [ ] **Step 4 (implement C-35):** drop the mixin and the TOC line, then `git rm -r libs/AceTimer-3.0/`.
  Gate green. Also run `grep -rn AceTimer --include='*.lua' --include='*.toc' --include='*.md' . | grep -v '^./libs/\|^./tests/_kit/\|^./docs/audits\|^./docs/reviews'`,
  which should find only historical docs. Regenerate the inventory and badge (+1 case).
  **Commit** `Drop the unused AceTimer-3.0 mixin and library`
  (body: "C-35 / PGE-20. Removes a whole vendored folder; no vendored file is edited").
- [ ] **Step 5 (C-23a, pure rename):** `git mv` the three files. Update `.toc:6`,
  `core/LauncherSetup.lua:13`, `settings/Panel.lua:18`, `tests/test_setup.lua:127`
  (`premadegroupsfilterextension.logo.tga`) and `DEPENDENCIES.md:77-83`. Gate green. Check that
  `git diff --cached -M --stat` shows the renames as renames. **Commit**
  `Rename the logo files after the addon folder` (C-23 / PGE-13; Refs #15).
- [ ] **Step 6 (red, C-23b), `tests/test_setup.lua`:**
  - "the TOC icon is the launcher icon and the folder-named 128 TGA": `## IconTexture` equals the
    launcher ICON and matches `premadegroupsfilterextension%.logo%.128%.tga$`.
  - "logo TGAs are uncompressed 32-bit at their sizes": the 18-byte header gives type 2, 32 bpp,
    128×128 for the icon and 512×512 for the landing. `-- red under: skip the 512 render`.
  - "no pgfe.logo file remains".
  Expect the 512 assert to FAIL (it is 256 today).
- [ ] **Step 7 (implement C-23b):**
  `python3 -c "from PIL import Image; Image.open('media/logos/premadegroupsfilterextension.logo.png').convert('RGBA').resize((512,512), Image.LANCZOS).save('media/logos/premadegroupsfilterextension.logo.tga', format='TGA')"`
  (no `compression=`), then `file media/logos/*.tga`, which must report RGBA 512 x 512 x 32. Add the
  recipe line, the check, and "the 512x512 landing-page render" prose to `DEPENDENCIES.md`. Gate green.
- [ ] **Step 8:** regenerate the inventory and badge for this commit (the three Step 6 cases). The
  Step 2 and Step 4 commits already carried their own regenerations; the Step 5 rename commit
  changes no case name, so it needs none.
- [ ] **Step 9: commit** `Render the landing logo at 512 and pin the logo assets` (C-23; Refs #15).
- [ ] **Step 10 (in-game, recorded for the owner):** add to the PR's checklist: `/reload` with no
  LibStub/AceTimer error, and the landing logo looks sharp.

---

### Task 10: Reset tests (C-22)

**Files:** create `tests/test_reset.lua`. Modify `tests/run.lua` (suite list: add `"test_reset"`
after `"test_euisettings"`).

- [ ] **Step 1:** write the five cases from spec section 4 for C-22. The header comment cites PGE-10 /
  options-ui-§12 / launcher-§3, and the file uses `local T = _G.PGFE_TEST` and `T.enableAddon`. Each
  case carries its red-under line:
  - 1: `-- red under: ResetProfile on every profile`.
  - 2: `-- red under: drop the sessionOnly sweep in RestoreAllDefaults`.
  - 3: `-- red under: drop resetExempt (settings/Schema.lua:89) AND make Settings.VetoedFromResetAll return only row.page == "profiles" (:144)`.
    Dropping `resetExempt` alone cannot turn case 3 red: `Helpers.RestoreAllDefaults` (:147) calls
    `db:ResetProfile()`, which leaves `global` alone, and its walk applies defaults only to rows
    `VetoedFromResetAll` lets through, which are the `sessionOnly` rows. The minimap row is never
    written on that path, and even with the veto widened, `S.ApplyDefault` still refuses it while
    the bracket is open because of `resetExempt` (`libs/LibKa0s/Schema.lua:649`). Case 3 pins that
    defense in depth, so its mutation removes both layers. Confirm locally that each layer alone
    keeps it green and both together turn it red, and say so in the case comment.
  - 4: `-- red under: drop resetExempt on the minimap row (settings/Schema.lua:89)`. The page
    Defaults path brackets its writes (`bulkBegin`), so `resetExempt` is the only thing between it
    and the minimap row.
  - 5: `-- red under: drop the Lifecycle:Set in reloadProfile`.
- [ ] **Step 2 (red-proof):** the code reads as correct today, so the cases pass. Prove each red-under
  locally by applying its mutation, seeing the case FAIL, and reverting. Record "red-proved 5/5" in
  the commit body.
- [ ] **Step 3:** gate green. The kit inventory sees `test_reset` in both directions.
- [ ] **Step 4:** regenerate the inventory and badge (+5).
- [ ] **Step 5: commit** `Test what Reset all settings reaches` (C-22 / PGE-10; Refs #13).

---

### Task 11: Diagnostics reports running state (C-10)

**Files:** modify `modules/Diagnostics.lua` (`dependencies` 40-55, `registration` 57-62,
`Sections` 70+). Create `tests/test_diagnostics.lua`. Modify `tests/run.lua` (add
`"test_diagnostics"` after `"test_euisettings"` or `"test_reset"`). Docs: `docs/debug.md`, and
`docs/ARCHITECTURE.md` `## Slash Commands` (check only).

- [ ] **Step 1 (red):** write `tests/test_diagnostics.lua` using the capture-`out` pattern from
  `tests/test_euiskin.lua:327-341`. That pattern stubs only `add`; this suite's stub needs `add`,
  `joined` **and `list`**, because `registration()` also calls `out:list(TAG, "rejected events", …)`
  (`modules/Diagnostics.lua:61`) and would raise on a missing method. Mirror the real `out`'s
  formatting for `joined` (empty prints `Any`/`none` as the library does; check
  `libs/LibKa0s/DebugLog*.lua` for the exact words). Cases:
  - `PGF seams ok=true missing=none`.
  - `hooks: env=true dialog=true searchRow=true applicantRow=true`.
    `-- red under: drop the store at EnvInject:89`. Check that `tests/wow_mock.lua` defines both
    painter globals before RegionTags loads.
  - `PutPremadeRegionInfo` nil in the fake gives `ok=false missing=PutPremadeRegionInfo`.
  - `filters` section: with `regions.oce = true`, the output contains `oce` and no `table:`, and an
    empty set prints `Any`.
  - Stood down: `feature events registered=false`, with the declared list still printed under
    `feature events (declared)`.
  Register the suite. Expect FAIL.
- [ ] **Step 2 (implement):** follow spec section 4, C-10.
- [ ] **Step 3:** gate green. `test_diagnostics_contract` (kit) stays green.
- [ ] **Step 4 (docs):** update the `docs/debug.md` sections table (the dependencies seams and hooks
  lines, the new `filters` row, and the registration declared/registered wording). Then check every
  `docs/ARCHITECTURE.md` line that describes the diagnostics sections against the new output
  (C-10 refinement 6): today `## Slash Commands` (138-139) and the Documentation map row (~359)
  name only the verb and the file, so expect no edit; if a line lists the sections, add seams,
  hooks and `filters` to it.
- [ ] **Step 5:** regenerate the inventory and badge (in the one commit below).
- [ ] **Step 6: commit** `Report seams, hook installs and filter options in diagnostics` (C-10 / F-013;
  Refs #7).

---

### Task 12: Locale: missing keys, literals through `NS.L` (C-11, C-25)

**Files:**
- Modify: `locales/enUS.lua` (sections :153 and :173; delete :166-167; new C-25 keys).
- Modify: `settings/Slash.lua` (:59, :84, :88, :101, :150, :171-172, :188).
- Modify: `settings/Panel.lua` (:249, :251-252).
- Modify: `core/DebugLogSetup.lua` (:16, :55, :61), `core/CoreSetup.lua` (:9, :36),
  `core/LauncherSetup.lua:21`, `settings/OptionsSetup.lua:13`. `core/PerfSetup.lua:24` is **not** a
  site: Task 8 deleted the file (D1 = performance-§12). Line numbers are at `0dabcde`; Task 8
  removed the `perf` row and `runPerf` from `settings/Slash.lua`, so re-read them first.
- Modify: `tests/loader.lua` (the addon's own loader, not `_kit`): an optional `opts.afterFile(path, NS)`
  hook, called after each addon file's chunk runs (~105). Default nil, so every existing caller is
  unchanged.
- Tests: `tests/test_surface_parity.lua`, `tests/test_slash.lua`.

- [ ] **Step 1 (red, C-11):** in `tests/test_surface_parity.lua`, "every locale key used is defined in
  enUS, and every enUS key is used". Statically scan `Loader.tocFiles` minus `libs\` and `locales\`.
  Unescape `\"` and `\n` the same way on both sides. Allowlist the dynamic families `MSG_*`,
  `REGION_TIP_*` and `PLAYSTYLE_*`. `-- red under: delete one of the new enUS lines`. Expect FAIL with
  the 12 missing keys and the 1 unused key listed.
- [ ] **Step 2 (implement C-11):** add the 12 keys byte for byte and delete :166-167. Gate green.
  Regenerate the inventory and badge (+1 parity case) in this commit.
  **Commit** `Define the 12 locale keys the skin status and settings tab use` (C-11 / F-006).
- [ ] **Step 3 (red, C-25):** in `tests/test_slash.lua`, "player-facing lines go through NS.L".
  - **How the sentinel gets in.** "Swap `NS.L` before loading" is not possible: `tests/loader.lua`
    builds `NS = {}` itself (:94), `locales/enUS.lua` creates `NS.L` at load, and `opts.mock` only
    reaches the mock. A metatable swap after load cannot change keys already rawset on `L`, nor the
    strings built at load time (`CLI_MISSING` `settings/Slash.lua:59`, DebugLogSetup `missing` :16,
    `core/LauncherSetup.lua:21`, and Slash's `local L` upvalue). So use the
    new loader hook: `opts.afterFile = function(path, NS) if path == "locales/enUS.lua" then for k in pairs(NS.L) do NS.L[k] = nil end; setmetatable(NS.L, { __index = function(_, k) return "<<" .. tostring(k) .. ">>" end }) end end`.
    Wiping the same table in place keeps every later `local L = NS.L` capture pointing at it, so the
    load-time strings built afterwards carry the sentinel too.
  - **LibKa0s absent (the stub paths):** drive `/pgfe bogus`, the help header, bare `/pgfe reset`,
    `OpenSettings` with no `Helpers.OpenOptionsPanel`, `runDebug` with `NS.DebugLog` nil, the stub
    DebugLog `SetEnabled(true)` and `ConsoleCheckbox().label`, and the `LIBKA0S_MISSING` family
    (`CLI_MISSING` and the other "…, so X is unavailable." lines). Each printed or returned string
    contains `<<`.
  - **LibKa0s present:** `/pgfe bogus` and the help header are printed by the library, not by
    `settings/Slash.lua:84/88/101`, so do not assert `<<` on them there. Assert only the sites this
    addon still prints on that path (bare `/pgfe reset` usage, `OpenSettings` without the helper,
    the console-not-ready line, the Panel `defaultsTooltip` and the `General` page name).
  - `-- red under: revert any site to a literal`. Expect FAIL.
- [ ] **Step 4 (implement C-25):** convert each site to a whole-sentence `%s` key, for example
  `L["%s, so the settings CLI is unavailable."]:format(L[LIBKA0S_MISSING])`. Keep these literal:
  `DISABLED_LINE_FORMAT`, brand names, verb tokens (as `%s` arguments) and color escapes (inside the
  values). Add a comment saying `settings/Schema.lua:106/110` are developer diagnostics and stay
  literal. Any existing exact-text assert must keep passing, so the enUS values must equal the old
  literals.
- [ ] **Step 5:** gate green. `test_prose` checks spelling of the new English.
- [ ] **Step 6:** regenerate the inventory and badge for this second commit (the sentinel cases).
- [ ] **Step 7: commit** `Route player-facing strings through NS.L` (C-25 / PGE-16 / F-010; Refs #17).

---

### Task 13: Debug lines on feature flows; targeting-off message (C-19, C-28)

**Files:**
- Modify: `modules/Apply.lua` (`Run` 43-65, `Clear` 70-78, `OnFiltersToggled` 85-91, comment :15).
- Modify: `modules/Presets.lua` (`Save` / `Load` / `Delete`).
- Modify: `modules/EnvInject.lua` (`RefreshPlayer` 41-50).
- Modify: `modules/Panel.lua` (`UpdateVisibility` ~838-852, the STAND_DOWN row).
- Modify: `core/PGFE.lua` (`OnEnable`).
- Modify: `locales/enUS.lua:61`.
- Tests: `tests/test_apply.lua`, `tests/test_panel.lua`, `tests/test_presets.lua`,
  `tests/test_envinject.lua`, `tests/test_setup.lua`.
- Docs: `docs/debug.md`, `docs/data-flow.md` (46-48).

- [ ] **Step 0:** read `libs/LibKa0s/DebugLogGates.lua:120-170` and `core/DebugLogSetup.lua` to
  confirm `NS.DebugChanged(key, tag, fmt, ...)`, `NS.DebugAtEnable(tag, fmt, ...)` and the console
  buffer field. **`DebugForget` is not published bare:** `core/DebugLogSetup.lua:119-122` publishes
  only `Debug`, `DebugOnce`, `DebugChanged` and `DebugAtEnable`. Both branches carry it on the
  instance (the stub at `core/DebugLogSetup.lua:30`, the real one at
  `libs/LibKa0s/DebugLogGates.lua:150`), so the STAND_DOWN row calls `NS.DebugLog.DebugForget("panel.vis")`.
  `core/DebugLogSetup.lua` stays out of this task's files.
- [ ] **Step 1 (red, C-28), `tests/test_apply.lua`:**
  - Rework 171-183: after an on-path Apply (`LastRange == "14-14"`), the off path gives
    `ok2, key2, extra = NS.Apply.Run{}` with `extra == nil` and `NS.Apply.LastRange == nil`.
    `-- red under: skip the LastRange write instead of resetting it`.
  - New case: `NS.Apply.Report(NS.Apply.Run{})` with targeting off prints
    `NS.L.MSG_APPLIED_NO_TARGETING`, and no printed line contains `14-14`.
    `-- red under: keep %s in the locale string`.
  Expect FAIL.
- [ ] **Step 2 (red, C-19), `tests/test_apply.lua`:** with `NS.State.debug = true`, add one case per
  refusal key using the existing precheck mocks (`MSG_COMBAT`, `MSG_NO_PGF` with the missing seam,
  `MSG_NOT_DUNGEONS`, `MSG_MINIMIZED`, `MSG_INACTIVE`, `MSG_BAD_LEVEL`, `MSG_BAD_AGE`, `MSG_LOADING`,
  `MSG_ALL_TIMED`, `MSG_DAMAGED`, `MSG_TOOLONG`). Each asserts a buffer line containing
  `[Apply] refused: MSG_X` (clear the buffer per case, or match by substring). `MSG_TOOLONG`
  (`modules/Apply.lua:19`) is reached by user text long enough that the merged expression passes
  2000 characters (`locales/enUS.lua:59`). Add a success case (`wrote`, plus `search` only with
  `opts.search`), a Clear refusal, a Clear success, and an `OnFiltersToggled` line.
  `-- red under: drop the done() logging`.
  - **The Clear refusal uses the C-03 input** (the C-03 fixNotes' optional Apply-level case): write
    the wrapped-without-close text from Task 2 case (b) into the fake's
    `Advanced.Expression.EditBox`, and assert `NS.Apply.Clear()` returns `false, "MSG_DAMAGED"`
    with a `[Clear] refused: MSG_DAMAGED` line. That proves end to end that `Apply.lua` needed no
    change for C-03. `-- red under: drop the wrapped-and-not-closed check in Expression.Strip`.
- [ ] **Step 3 (red, C-19 elsewhere):**
  - `tests/test_panel.lua`: show twice gives exactly one `shown`, hide gives `hidden`, and
    stand-down then stand-up gives `shown` again. `-- red under: drop the DebugForget on the
    STAND_DOWN hide`.
  - `tests/test_presets.lua`: the save, load, delete (present and absent) and badName lines.
  - `tests/test_envinject.lua`: one `spec=` line, unchanged on a repeat refresh.
  - `tests/test_setup.lua`: the enable writes one `[Init] PGF seams … hooks env=true …` line.
  Expect FAIL.
- [ ] **Step 4 (implement):** follow spec section 4 for C-19 and C-28. `EnvInject.Apply` and the row
  painters stay silent.
- [ ] **Step 5:** gate green.
- [ ] **Step 6 (docs):** `docs/debug.md` gets the tag vocabulary (`Apply`, `Clear`, `Panel`, `Preset`,
  `Env`, `Init`). `docs/data-flow.md:46-48`: `LastRange` is "N-N" only with targeting on, and the
  message carries no range.
- [ ] **Step 7:** regenerate the inventory and badge **before each of the two commits** (the C-28
  commit reworks one case and adds one; the C-19 commit adds the refusal, panel, preset, env and
  setup cases).
- [ ] **Step 8: commit** `Say nothing about a range when key targeting is off` (C-28 / F-009), then
  `Write debug lines for Apply, Clear, panel visibility, presets, spec and enable` (C-19 / PGE-04;
  Refs #11). Each carries its own regenerated inventory and badge. Report `wc -l` for
  `tests/test_apply.lua`, `tests/test_panel.lua` and `modules/Panel.lua` (Task 16's band check).

---

### Task 14: Launcher enable pair; ten-step disabled suite (C-16, C-08)

**Starts only after Task 13 is integrated** (wave 4 is sequential). Cut from the tip that holds
Task 13, so the pinned events, the hook list and the debug lines are final (spec C-16 + C-08
"Order"), and re-read `core/PGFE.lua` for the `NS.StandDown` UnregisterEvent loop's line before
writing the step 3 red-under note (Task 13's `OnEnable` change shifts it from :121).

**Files:** modify `core/LauncherSetup.lua` (:55, header 7-8). Rewrite `tests/test_disabled.lua`.
Docs: `docs/testing.md:31`; `docs/ARCHITECTURE.md` (check only: any line saying the launcher's
Enabled pair reads the latch, C-16 refinement 4).

**C-16 re-checked after D1 (performance-§12).** C-16 is "the launcher's Enabled entry reads the
latch, so a perf capture shows *Enabled: No* while `enabled` is stored `true`". Task 8 removed the
perf wiring, so production takes exactly one hold, `disabled`, and it is set from the stored
`enabled` path: `not NS.IsStoodDown()` and the stored setting now agree in every state production
reaches, and the reported symptom cannot happen. **What remains is launcher-§1's letter:** each
status line is read "through the same accessor the Master-controls row reads", and that row reads
the stored `enabled` setting, not the latch. The one-line fix therefore stays. It conforms the
tooltip to that rule and keeps it right the day a second hold returns (the performance-§12 re-arm
trigger). **PGE-12** (the slash refusal wording during a perf hold) is no longer reachable in
production: there is nothing to override, and the library's `DisabledLine` is kept.

**The `perf` hold in tests.** `NS.HOLD_PERF` no longer exists. slash-commands-§7 step 10 still
requires the `perf` hold in both orders, so this suite takes the library's reserved hold by its
library constant, as a test-only second holder that production never takes (the BankLedger and
PrettyChat precedent):
`local HOLD_PERF = (T.LibStub("LibKa0s-Lifecycle-1.0", true) or {}).HOLD_PERF or "perf"`. Task 8
already introduced this local in the current suite; keep it in the rewrite.

- [ ] **Step 1 (red, C-16), in the current `tests/test_disabled.lua`:**
  - "while another hold stands the addon down, the launcher reports the stored setting":
    `NS.Lifecycle:Hold(HOLD_PERF)` (the test-local constant above),
    `NS.Launcher:Object().OnTooltipShow(tt)` with a collecting `AddLine`, assert the Enabled line
    says Yes, then release. `-- red under: revert LauncherSetup:55 to not NS.IsStoodDown()`.
  - The mirror: after `OnSlashCommand("disable")`, it says No.
  The plan's former third case ("a perf hold still refuses apply while get enabled prints true")
  is dropped: it pins a state production can no longer reach, and step 10 of the rewrite pins the
  latch. Expect the first case to FAIL.
- [ ] **Step 2 (implement C-16):** change :55 as in the spec and update the header comment. Grep
  `docs/ARCHITECTURE.md` (and `docs/settings-panel.md`, `docs/debug.md`) for a line saying the
  launcher's enable pair reads the latch or `IsStoodDown`, and correct it to "reads the stored
  `enabled` setting" (none found at `0dabcde`; recheck). Regenerate the inventory and badge (+2
  cases). Gate green.
  **Commit** `Make the launcher's Enabled entry describe the stored setting` (body: "C-16 / PGE-11 /
  F-015. With the perf wiring removed (D1 = performance-§12) the latch and the stored setting no
  longer disagree in production; this conforms the tooltip to launcher-§1's same-accessor rule.
  PGE-12 is no longer reachable in production, and the library's DisabledLine is kept. Refs #14").
- [ ] **Step 3 (rewrite C-08):** replace the suite with the ten steps from spec section 4 (C-16 +
  C-08), built only from `T.enableAddon()` and the kit recorders (`M.__registrations`, `__timers` /
  `__liveTimers`, `__shownFrames`, `__svWrites` / `__resetSvWrites`, `__printed` / `__resetPrinted`,
  `__fireEvent`, `__fireUnconditional`). Read `tests/_kit/mock_base.lua` and `mock_record.lua` for
  the exact names first. Pin the 8 event names. Step 6 also fires the `RegisterSkin` callback captured
  from the wow_mock EllesmereUI fake while stood down (C-37 survivor: zero SV writes, nothing painted;
  `-- red under: remove the stoodDown() check from EUISkin blocked()`). Step 7 also dispatches
  `/pgfe perf`, which is not in `NS.COMMANDS` (performance-§12: reserved always, registered when
  wired), and asserts the library's unknown-command line and the index, the same lines as when
  enabled. Step 10 takes the `perf` hold through the test-local `HOLD_PERF`, never `NS.HOLD_PERF`.
  Keep the C-16 cases and the stored-disabled case, reworked to assert empty registrations. Drop the probe row and every
  `NS.FEATURE_EVENTS` / `NS.STAND_*` injection. There must be at least three `-- red under:` notes
  (steps 3, 6 and 10).
- [ ] **Step 4 (red-proof):** for each red-under note, apply its mutation locally, see the case FAIL,
  and revert. Record "red-proved" in the commit body.
- [ ] **Step 5:** gate green. Update the test_disabled line in `docs/testing.md:31`.
- [ ] **Step 6:** regenerate the inventory and badge for this second commit (the rewrite renames and
  replaces cases). The C-16 commit already carried its own.
- [ ] **Step 7: commit** `Rewrite test_disabled to the slash-commands-§7 ten steps` (C-08 / PGE-05 /
  F-008; Refs #4).

---

### Milestone M1: push

- [ ] Confirm ledger rows 0-14 are `done` (the wave-4 ledger commit is in) and every worktree task
  branch is fast-forwarded into `fix/2026-10-10-audit-review`.
- [ ] Gate green on the integrated tip. Run
  `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --no-bundle`, which
  must give a green verdict: complexity pass with blind 0 and max CCN ≤ 15, and perf pass.
- [ ] `git push -u origin fix/2026-10-10-audit-review`. Note the pushed sha; it is ticked into the M1
  row by the first Task 15 commit (see the ledger rules), not by a commit of its own.

---

### Task 15: Docs, register rows, spec and DEPENDENCIES fixes (C-17, C-18, C-26, C-34, C-09 row, C-39, C-38, C-24, C-37 note)

**Files:**
- `docs/ARCHITECTURE.md` (`## Settings Schema` 108-116, `## Message Bus` 120-122, `## Taint Notes`,
  `## Documented deviations` 381-389).
- `docs/schema.md`, `docs/data-flow.md`, `docs/module-map.md` (the "non-setting" sweep).
- `DEPENDENCIES.md`, `docs/realm-map-maintenance.md`.
- `docs/superpowers/specs/2026-10-09-m-plus-v0.1-design.md:93`.
- `tests/test_filters.lua`; `tests/test_surface_parity.lua` (only if the optional Step 10 guard
  lands); `tests/test_euiskin.lua` (only if the Step 1 order pin needs restoring).
- Header comments of `settings/Panel.lua` (8-10) and `modules/Panel.lua` (8-9).

- [ ] **Step 1 (verify symbols):** grep for `setCollapsed`, `buildFrame`, `COLLAPSE_ATLAS`,
  `EXPAND_ATLAS`, `omit = { visibility = true }`, `ToggleComposition`, `ClearComposition` and
  `ApplySmartLevel`, and read `core/PGFE.lua` `reloadProfile`. Every name and the call order in the
  spec section 5 rows must still match the code after Tasks 1-14. Adjust the row text if a task
  renamed anything. The architecture-§4 row's Why rests on `reloadProfile` re-reading the latch
  before `EUISkin.OnSwitch`; that order is already pinned by
  `tests/test_euiskin.lua:184-196` ("a profile switch to a disabled profile with the switch on paints
  nothing", `-- red under: reloadProfile painting before the Lifecycle re-read of enabled`). Confirm
  the case is still there and green, and cite it in the `## Message Bus` rewrite. If a task removed
  it, restore it in this task.
- [ ] **Step 2 (register):** append the **four** rows from spec section 5 verbatim to
  `## Documented deviations`: the three owner-ratified rows (C-17, C-18, C-26 + C-34) and the
  performance-§12 row (C-09, owner checkpoint D1). In the §12 row, replace `<sweep-sha>` with Task
  8's Commit B sha (from the Task 8 report or `git log --format=%h -1 -- docs/performance.md`), and
  check that the sweep in `docs/performance.md` still names eight `FEATURE_EVENTS` rows and no timer
  (re-run its grep; if anything since Task 8 added an `OnUpdate`, a repeating timer or real in-combat
  work, stop: the trigger has fired). The row's Rule cell **must be exactly** `` `performance-§12` ``:
  `tests/_kit/run-automated-tests.sh` matches it after lower-casing and stripping backticks,
  whitespace and the section sign, and only a whole-cell match counts (:220-222). Prove the runner
  reads it: move `tests/perf.lua` aside (`mv tests/perf.lua <scratch>/`), run
  `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite perf --no-bundle`,
  and confirm perf is `skip` with the note
  `performance-§12 no-combat-path exemption (ratified; docs/ARCHITECTURE.md -> Documented deviations)`,
  not "no tests/perf.lua", and that the run did not exit 2 (a malformed register). Move the file
  back and confirm `git status` shows it unchanged.
- [ ] **Step 3 (C-17):** in `## Settings Schema`, remove the `char.filters` and
  `profile.panelCollapsed` bullets from *Named non-setting state*. Add a one-line pointer to the
  architecture-§5 row. Retitle the remaining bullets so `global.presets` reads as a registry, and
  keep `global.minimap`. Sweep `grep -n "non-setting" docs/schema.md docs/data-flow.md docs/module-map.md`
  and align each hit.
- [ ] **Step 3b (C-04 refinement 5, doc sweep):** grep `docs/module-map.md` and `docs/data-flow.md`
  for any line saying `modules/Season.lua` or `modules/EnvInject.lua` reads PGF
  (`PremadeGroupsFilter`, `MAP_ID_TO_KEYWORDS`, `SPECIALIZATIONS`, "PGF's namespace") and repoint
  it at the bridge accessors. None was found at `0dabcde` (module-map.md:53 says only "the PGF env
  post-hook body"); recheck after Tasks 5 and 7.
- [ ] **Step 4 (C-18):** rewrite `## Message Bus`. The §4 threshold is crossed (list the feature
  modules). There is no bus, because the reactions are ordered and single-sender. Name the three
  reaction sites. Link `#documented-deviations`.
- [ ] **Step 5 (C-39):** repoint the two existing rows' Why sources, as in spec section 4. Leave the
  Rule, What differs, Decided and Re-check cells unchanged. Check that both link targets and the
  `#owner-decisions-2026-10-09` anchor resolve, **and that each cited section says what the row
  claims**. Verified at plan time: the M+ v0.1 spec states the hard dependency in `## 1. Intent`
  item 5 ("Hard dependency on PGF: the addon must not load without it.", line 18) and records it as
  a user-requirement deviation in `## 2. Constraints and findings` (line 32). Cite §1 item 5 for the
  requirement and §2 for the deviation, not §2 alone. Re-read the eui-skin plan's
  `## Owner decisions (2026-10-09)` and confirm decision 1 is the EllesmereUIDB read. If either
  source no longer says it, fall back to `docs/audits/2026-10-09/` as the C-39 fixNotes direct.
- [ ] **Step 6 (C-37 note):** add one sentence to `## Taint Notes`: the `EllesmereUI.RegisterSkin`
  callback cannot be unregistered, survives a stand-down and gates itself; the stand-up retries
  (`modules/EUISkin.lua:382-395`; upstream issue from Task 6).
- [ ] **Step 7 (C-26/C-34 pointers):** append "(ratified: docs/ARCHITECTURE.md -> Documented
  deviations)" to the `settings/Panel.lua:8-10` and `modules/Panel.lua:8-9` header comments. These
  are comment-only changes.
- [ ] **Step 8 (C-38):**
  - Amend spec line 93 as in spec section 4.
  - Check whether `tests/test_filters.lua` already asserts the full selection. If not, add
    "every region ticked adds no clause": `regionsEnabled = true`, every key in
    `NS.Regions.KEYS[portal]` ticked, `ToClauseOpts(portal).regions == nil`.
    `-- red under: drop the IsAny full-selection branch in regionClause`.
  - Prove it red, then green.
- [ ] **Step 9 (C-24):**
  - Restructure `DEPENDENCIES.md` into `## Release / assets / maintenance` with two entries (Pillow,
    and `python3` stdlib only: `re`, `string`, `sys`; `sudo apt-get install -y python3`;
    `python3 --version`), and drop the count.
  - Qualify the lizard row (:40, :71-72) with the source-shape rule.
  - Add "Needs Python 3 (stdlib only); see DEPENDENCIES.md." to `docs/realm-map-maintenance.md`
    "How to run it".
- [ ] **Step 10 (optional guard, cheap):** in `tests/test_surface_parity.lua`, assert that
  `docs/ARCHITECTURE.md`'s Documented deviations table has `architecture-§5`, `architecture-§4`,
  `standalone-windows` and `performance-§12` rows, and that every `modules/Filters.lua` writer name (`Set`, `Toggle*`,
  `Clear*`, `ApplySmartLevel`) appears in the §5 row.
  `-- red under: add a Filters.Toggle* without listing it`. Skip it if it makes the parity suite
  brittle. Prose otherwise has no test.
- [ ] **Step 11:** gate green. Regenerate the inventory and badge in the commit that adds the Step 8
  case (the C-38 commit) and, if Step 10 lands, in the commit that adds it (the register commit).
  The other two commits change no case.
- [ ] **Step 12: commit** (the first one also ticks the M1 row with the pushed sha from M1)
  - `Ratify the per-character state, direct-call, attached-panel and no-combat-path deviations`
    (C-17, C-18, C-26, C-34, C-09; Refs #10 #18 #5).
  - `Point register Why cells at resolvable sources; note the RegisterSkin survivor` (C-39, C-37).
  - `Amend spec 6.3 to the shipped Any semantics` (C-38; Refs #8).
  - `List Python 3 for the realm-map tool in DEPENDENCIES` (C-24; Refs #16).

---

### Task 16: Full automated-test bundle + CLAUDE.md pointers (C-13)

**Files:** `docs/automated-tests/<YYYYMMDD-HHMMSS>/` (generated), `docs/automated-tests/RESULTS.md`
(generated, plus the Disposition column), `CLAUDE.md` (:24-25), and the stale "newest record"
wording in `docs/testing.md` / `docs/ARCHITECTURE.md` if any. This task also ticks its own ledger
row inside the bundle commit; nothing is committed after it before the merge (M2 and M3 live in
the PR body). The record names the sha it ran at (the Step 1 tip); the bundle commit on top of it
adds only the bundle, the RESULTS row, CLAUDE.md and the tick.

- [ ] **Step 1:** check that the tree is clean at the tip that will be merged (after Task 15).
- [ ] **Step 2:** run the battery through the `dev-copilot:wow-automated-tests` skill, or directly with
  `~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh`. This is a full
  run with a bundle and **no** `--label` (a non-release run). The skill writes `ANALYSIS.md`. Do not
  hand-edit generated sections.
- [ ] **Step 3 (verify the manifest):** verdict green, lint pass, tests pass (the new Total, 1 skip),
  perf pass (6 scenarios: `tests/perf.lua` exists, so this is not the performance-§12 skip),
  complexity pass, `blindFiles` 0, `overCapFiles` 0 and `maxCcn` ≤ 15. **Do not require
  `bandFiles` to be exactly 1.** This run grows `tests/test_panel.lua` (Tasks 7, 13),
  `tests/test_apply.lua` (Task 13) and `modules/Panel.lua` (895 lines at `0dabcde`; Tasks 7, 13),
  and rewrites `tests/test_disabled.lua`, so more files may sit in the 1000-1500 band. Read the
  band list from the manifest and give **each** file in it a Disposition in Step 4. If
  `overCapFiles` is not 0 (a file past 1500), stop: that is a layout-§1 MUST, and it goes to the
  owner (split now, or a register row) before the bundle is committed.
- [ ] **Step 4 (Disposition, one per band file):** in `RESULTS.md` "Files by layout-§1 band", and the
  same text in the bundle's `ANALYSIS.md` band table:
  - `tests/test_panel.lua`: "on notice: test-only file; split by area (rows / presets / collapse /
    copy box) before it reaches 1500 lines or at the next panel feature".
  - Any other **test** file in the band: the same "on notice" wording, naming its own split areas
    (for `tests/test_apply.lua`: prechecks / write pass / debug lines / Clear).
  - A **production** file in the band (most likely `modules/Panel.lua`): do not write a Disposition
    on your own. Name the split seam you would use (for `modules/Panel.lua`: frame build / rows and
    readout / stand-down wiring) and ask the owner at M3 whether it is "on notice" or split now; the
    spec's "no split" non-goal covers `tests/test_panel.lua` only.
- [ ] **Step 5 (CLAUDE.md :24-25):** name the issues that close the findings, as the previous line
  did ("fixed or filed as issues #4-#19"): "The newest compliance snapshot is
  `docs/audits/2026-10-10/` (standard v2.78.0; its findings and the review bundle
  `docs/reviews/2026-10-10/` were consolidated in `docs/reviews/2026-10-10/06_CONSOLIDATED_FINDINGS.md`
  and fixed on `fix/2026-10-10-audit-review`, closing issues #4-#19, or filed upstream as
  LibKa0s#<a>, LibKa0s#<b>, WowAddonStandards#<c>, #<d>, #<e>; the re-vendor is tracked in #<n>).
  The newest automated-test record is `docs/automated-tests/<stamp>/`." Fill the numbers from row 6
  of the ledger (Task 6). Don't call it a release run. Fix any other "newest record"
  wording in `docs/testing.md` / `docs/ARCHITECTURE.md`.
- [ ] **Step 6:** gate green.
- [ ] **Step 7: commit** `Record the post-fix automated-test run and point CLAUDE.md at the 2026-10-10
  bundles` (C-13).

---

### Milestone M2: push

- [ ] Ledger rows 15-16 are `done`. Gate green. `git push`. Record M2 (the pushed sha) in the PR
  body, not in a commit (see the ledger rules).

### Milestone M3: open the PR, ask for the go-ahead

- [ ] `gh pr create --base main --head fix/2026-10-10-audit-review --title "Fix the 2026-10-10 audit and review findings (C-01..C-39)" --body-file <scratch>`.
  The body contains:
  - A summary by theme.
  - The finding -> task matrix.
  - The issue map (closed after the merge).
  - The four ratified rows (C-17, C-18, C-26 + C-34, and the performance-§12 row for C-09).
  - The settled design choices from spec section 3, for the owner to confirm (C-29 (a), C-13
    Disposition), the D1 answer for C-09 as already decided (performance-§12, 2026-10-10, which also
    makes PGE-12's wording question unreachable), and any production band file Task 16 Step 4
    raised.
  - The ledger's milestone record: M1 sha, M2 sha.
  - The two optional upstream ideas (Task 6 Step 6).
  - The upstream issue links.
  - The in-game checklist: `/reload` without AceTimer, the 512 landing logo, one season request per
    loading screen, the Filters tab, the EllesmereUI paint.
  - The new automated-test bundle path.
  - The PR trailer from the session's attribution reminder.
- [ ] Ask the owner for the merge go-ahead and **stop**. The PR number is M3's record; do not commit
  it to the branch.

---

### Task 17: After the owner's go-ahead: merge, push, close, clean up

**Files:** none apart from the ledger. The final ledger tick is committed on `main`, in or right
after the merge commit, only if the owner wants it there. Otherwise record it in the PR.

- [ ] **Step 1:** `git checkout main && git pull --ff-only && git merge --no-ff fix/2026-10-10-audit-review`.
  Gate green on `main`. `git push origin main`.
- [ ] **Step 2 (close the fixed issues):** for each row of the Issue -> fix mapping, run
  `gh issue close <n> -R tusharsaxena/PremadeGroupsFilterExtension --comment "Fixed in <sha> (<task>, <finding>) on main via PR #<pr>."`
  and then `gh issue edit <n> --remove-label state:untriaged --add-label state:done`. Before closing
  #4, edit its body's "5 events" to "8 events". #5 cites both T8 commits and the T15 register
  commit (the performance-§12 row). #19 cites the Task 6 label evidence. #15 cites both
  T9 commits. #7 cites T5 and T11. #10 and #18 cite the T15 register commit. #11 cites T4 and T13.
- [ ] **Step 3:** `gh issue list -R … --state open` shows only #1-#3 (plus anything new).
- [ ] **Step 4 (clean up what the run created, and nothing else):**
  - Run `git worktree list`, then `git worktree remove ../pgfe-wt-T<n>` for each and `git worktree prune`.
  - Delete the task branches with `git branch -d fix/2026-10-10-audit-review--T<n>`.
  - Delete the fix branch: `git branch -d fix/2026-10-10-audit-review` and
    `git push origin --delete fix/2026-10-10-audit-review`.
  - Run `git stash list` and drop only the stashes this run created (identify them by message or
    date).
- [ ] **Step 5:** `git status` is clean on `main`, up to date with `origin/main`. Tick ledger rows
  M2, M3 and 17 on `main` only if the owner wants the ledger there (see the Files note above);
  otherwise the PR is the record.
