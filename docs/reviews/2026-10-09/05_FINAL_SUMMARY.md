# 05 — Final summary (to be true once 03 is signed off)

## Headline

This cycle made Ka0s Premade Groups Filter Extension safe to turn off. A filter block it had written
into Premade Groups Filter no longer hides every dungeon listing once the addon is disabled or removed.
The player's spec is now read through the addon's Compat seam instead of through deprecated globals. The
attached panel tells the truth: a mistyped key level is no longer half-stored, Apply refuses rather than
pretending to work while PGF is minimized, and the range field and Apply message match what was applied.
The disabled-state test suite now meets the standard's conformance shape. The one hot path has an
offline measurement.

## Counts

Critical fixed: 0, High fixed: 2, Medium fixed: 5, Low fixed: 4. Nothing was deferred.

## Changes by theme

### A. Safe when not running
- **What changed:** the managed block reads `( not pgfe_on or ( … ) )`, and the env hook sets `pgfe_on`.
- **Why it mattered:** a disabled or uninstalled addon left PGF hiding every result.
- **Covers:** F-001, implemented by C-001.
- **Files:** `modules/Expression.lua`, `modules/EnvInject.lua`, tests, `docs/ARCHITECTURE.md`, `docs/data-flow.md`.

### B. Compat routing
- **What changed:** the spec read goes through `NS.Compat`, and the lint allowance is removed.
- **Why it mattered:** the read depended on deprecated globals and broke the compat MUST.
- **Covers:** F-002, implemented by C-002.
- **Files:** `modules/EnvInject.lua`, `.luacheckrc`, `tests/wow_mock.lua`, `tests/test_envinject.lua`.

### C. Panel and Apply truthfulness
- **What changed:** whole-value number input, a minimized-dialog refusal, a range that follows the level, accurate Apply messages, and a panel refresh on profile switch.
- **Covers:** F-003, F-004, F-008, F-009, F-010, implemented by C-003, C-004, C-005 and C-009.
- **Files:** `modules/Panel.lua`, `modules/Apply.lua`, `core/PGFBridge.lua`, `core/PGFE.lua`, `locales/enUS.lua`, tests.

### D. Disabled conformance suite
- **What changed:** `tests/test_disabled.lua` now asserts over the addon's real registration set and carries falsification comments.
- **Covers:** F-005, implemented by C-006.

### E. Hot-path evidence
- **What changed:** an offline `tests/perf.lua` env-hook scenario, and the bucket-or-exemption decision recorded.
- **Covers:** F-006, implemented by C-007.

### F. Robustness
- **What changed:** presets load over the current defaults, and the region lookup tolerates a non-string name.
- **Covers:** F-007, F-011, implemented by C-008 and C-010.

## API / behavior changes

- The managed expression block has a new shape. 0.1.0 blocks are replaced on the next Apply or Clear.
- New refusal: `Maximize the Premade Groups Filter dialog first; nothing was applied.`
- New message: `Applied; key range %s.` when key targeting is off.
- New locale keys: `MSG_MINIMIZED`, `MSG_APPLIED_NO_TARGETING`.
- No slash verbs, settings rows or defaults change.

## Saved-variable / migration notes

There is no schema bump. PGF's stored expression is migrated lazily by Strip's marker logic.

## Deprecated-API migrations

| Old API | New API | Files |
|---|---|---|
| `GetSpecialization()` (global) | `NS.Compat.GetSpecialization()` → `C_SpecializationInfo.GetSpecialization` | `modules/EnvInject.lua` |
| `GetSpecializationInfo()` (global) | `NS.Compat.GetSpecializationInfo()` | `modules/EnvInject.lua` |

## Performance impact

Fill this in only with numbers from the new `tests/perf.lua` env-hook scenario, run before and after
any optimization in the same session. No figure is claimed here.

## Test and complexity movement

The suite was at 186 passed / 1 skipped / 187 before this cycle. I expect it to rise by about 12 cases
across C-001 to C-010. `docs/test-cases.md` and the README `Tests` badge move in each commit that moves
the count. No watch-list movement is expected (max CCN 13 today).

## Known follow-ups

- Add PremadeGroupsFilterExtension to `WowAddonStandards/standards/ADDONS.md`. That is a standards-repo change.
- A per-portal realm memo in `Regions.GetRegion`, only if the C-007 scenario shows a cost.

## Verification evidence

- `docs/reviews/2026-10-09/03_SMOKE_TESTS.md`, with the sign-off table filled in.
- The commit range for T1 to T10 on `feat/2026-10-09-m-plus-v0.1`.

## Suggested PR description

```
Review fixes for M+ v0.1 (docs/reviews/2026-10-09)

- F-001 (High): the managed PGF expression block is neutral when the env hook
  did not run, so disabling or removing the addon no longer hides every listing.
- F-002 (High): read the player's spec through NS.Compat (compat MUST).
- F-003/F-004/F-008/F-009/F-010: panel input commits whole values; Apply refuses
  while PGF is minimized; range and Apply message are accurate; panel refreshes
  on profile switch.
- F-005: test_disabled rewritten to the slash-commands-§7 conformance shape.
- F-006: offline env-hook perf scenario (tests/perf.lua).
- F-007/F-011: presets load over defaults; leader-name type guard.

Tests: lua tests/run.lua green; luacheck . 0/0; docs/test-cases.md and README
badge regenerated in each commit.
```
