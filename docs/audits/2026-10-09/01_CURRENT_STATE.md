# 01 — Current state: Ka0s Premade Groups Filter Extension

Audit run **2026-10-09**, read-only, at commit `58156ca` (branch `feat/2026-10-09-m-plus-v0.1`,
working tree clean). First audit of this repository: the deviation prefix **`PGE`** is assigned here.

## Standard resolved

- **Audited against: Ka0s WoW Addon Standard v2.77.0 (2026-10-07)**, fetched with `curl -fsSL` from
  `https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` on 2026-10-09:
  `AUDIT.md`, `standards/STANDARDS.md`, `standards/ADDONS.md` and all **27** section files the
  `STANDARDS.md` Sections list links (anti-patterns through versioning-git). No fetch failed.
- **Repository kind: Addon.** `dev-copilot-profile` reported `profile=wow`, `kind=addon`
  (`reason=toc:## Interface`), and the repo has a `.toc`, which is `AUDIT.md` step 1's discriminator.
  The addon rule set (every section) is used.
- **Disagreement noted:** the repo is **not a row in `standards/ADDONS.md`** (eleven rows, none of them
  this addon). The discriminator is unambiguous (it has a `.toc`), so the table and the detector agree
  on the kind; the missing roster row is recorded as PGE-21 (Info, upstream action).

## Layout (layout-§1..§4)

- Source lives under `core/` (11 files), `defaults/` (2), `modules/` (10), `settings/` (6),
  `locales/` (1); `tests/` holds 21 authored files plus the vendored `tests/_kit/`; `tools/` holds one
  Python script, `tools/realm_map_diff.py` (a diff tool, not a generator).
- Authored Lua: **51 files, 5,193 lines** (`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`).
  Largest: `defaults/Realms.lua` 559, `modules/Panel.lua` 432. Nothing in the 1000–1500 band, nothing
  over the cap. The census heading `### Files over the 1500-line cap` sits under
  `## Documented deviations` and reads "Nothing is over the cap today." (`docs/ARCHITECTURE.md:293`,
  `:298`). The kit gate `test_layout_cap` is wired (`tests/run.lua:106`).
- `media/logos/` holds `pgfe.logo.128.tga` (type 2, 128×128, 32 bpp), `pgfe.logo.tga` (type 2,
  256×256, 32 bpp) and the source `pgfe.logo.png` (512×512). No other `media/` folder.

## TOC (toc-file)

- `PremadeGroupsFilterExtension.toc`: single `## Interface: 120100`; `## Title: Ka0s Premade Groups
  Filter Extension`; `## IconTexture` points at the addon's own 128 logo; two SavedVariables
  (`PremadeGroupsFilterExtensionDB`, `PremadeGroupsFilterExtensionPerfDB`); **`## Dependencies:
  PremadeGroupsFilter`** (ratified, see the register below); `## X-License: MIT`; `## X-Standard`;
  `# X-Curse-Project-ID: not published on CurseForge yet` in the field's position (compliant).
- Listing: `# Libraries` (Ace3, LSM, LDB, LDBIcon, then the single `libs\LibKa0s\LibKa0s.xml`) →
  `# Locales` → `# Core` → `# Defaults` → `# Modules` → `# Settings`. Load-bearing lines in `# Core`
  and most of `# Settings` are annotated; the `# Modules` group carries one "conventional" comment that
  is not true of two of its files (PGE-06/07), and `settings\Slash.lua` is annotated conventional though
  it captures `NS.SchemaRuntime` members at load (PGE-08).

## Libraries (library-stack)

- Vendored under `libs/`: LibStub, CallbackHandler-1.0, AceAddon/Event/Console/Timer/DB/GUI/Config/
  DBOptions, LibSharedMedia-3.0, LibDataBroker-1.1, LibDBIcon-1.0, LibKa0s (159 tracked files).
- **Provenance:** `CLAUDE.md:45` — `Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.71.0 (MIT).`
  Not in `README.md`. Both payloads diff **empty** against the sibling `../LibKa0s` at tag `v1.71.0`
  (03_EVIDENCE E3). The TOC lists the aggregate `.xml` once.
- AceTimer-3.0 is embedded through the `NewAddon` mixin string but no file calls a timer (PGE-20, Info).
- No `.pkgmeta` `externals:`.

## Shared subsystems — descriptors and stubs (library-stack-§7)

All consumed from `LibKa0s`, none hand-rolled. Each setup file resolves its major with
`LibStub(major, true)` and carries a library-absent branch:

| Major | Setup file | Stub shape |
|---|---|---|
| Core | `core/CoreSetup.lua` | printer, SafeToString, `SafeRegister*` one-rung bodies, `MakeCloseButton` wrapper (`:86-88`) |
| Media | `core/MediaSetup.lua` | `NS.Icon` / `NS.MediaFont` answer nil |
| Compat | `core/Compat.lua` | reader arm (nil answers) |
| Env | `core/EnvSetup.lua` | `C_AddOns` fallback |
| DebugLog | `core/DebugLogSetup.lua` | member-answering, incl. gates and `RunDiagnostics` library-absent line |
| Launcher | `core/LauncherSetup.lua` | member-answering |
| Lifecycle | `core/LifecycleSetup.lua` | two-hold latch stub |
| Perf | `core/PerfSetup.lua` | `on`, `suspended`, `Note`, `OnCommand` |
| Schema | `settings/SchemaSetup.lua` | runtime-completing host stub |
| Options | `settings/OptionsSetup.lua` | load-completing (the documented exception) |
| Slash | `settings/Slash.lua` | minimal dispatch, verbatim `DISABLED_LINE_FORMAT` pinned |

`tests/test_surface_parity.lua` loads the addon with the whole payload skipped and asserts stub parity
for nine majors (green).

## Patterns (architecture, savedvariables)

- `NewAddon(NS, addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")` (`core/PGFE.lua:9-10`);
  `NS.Print` reclaimed (`:25`); cyan `[PGFE]` tag (`:21`).
- Feature modules are plain `NS.<Name>` tables calling each other directly; **no message bus**
  (`docs/ARCHITECTURE.md:99`) — PGE-03.
- AceDB: `profile` {`enabled`, `panelCollapsed`}, `char.filters` (nine filter options),
  `global` {`schemaVersion = 0`, `presets`, `minimap = { hide = false }`} (`defaults/Profile.lua`).
  `NS.SCHEMA_VERSION = 1`, one no-op step, runner owns the stamp (`core/Database.lua`).
- Schema rows: only the composed Master-controls rows. The nine filter options and `panelCollapsed`
  are written outside the seam and documented as "named non-setting state" (PGE-02).
- `global.presets` is a structural registry with one named writer (`modules/Presets.lua`) — compliant.

## Settings panel (options-ui)

Landing page (logo at 256×256 — PGE-14, notes, command list) → **General** (one tab, `Master controls`,
composed `frameless`, visibility omitted — PGE-19 Info) → **Profiles** (AceDBOptions). The global reset
is `db:ResetProfile()` behind the verbatim popup; the minimap row is vetoed from both resets
(`settings/Schema.lua:89`, `:144`). No suite proves the reset's blast radius (PGE-10). The filter
options live on a panel attached under PGF's dialog (`modules/Panel.lua`), not on a settings page.

## Slash (slash-commands)

`/pgfe` and `/premadegroupsfilterextension`, `LibKa0s-Slash-1.0`, 16 `NS.COMMANDS` rows: every reserved
verb plus `profile`, `apply`, `clear`. `liveVerbs` is `lib.LIVE_VERBS` + `profile`; `apply`/`clear` are
refused while stood down (the feature-verb SHOULD, implemented).

## Disabled state (slash-commands-§7)

- **Latch:** `LibKa0s-Lifecycle-1.0`, one latch, two holds (`core/LifecycleSetup.lua`); the perf
  harness takes its hold on the same latch (`core/PerfSetup.lua:36`). No second teardown path.
- **Registration census** (03_EVIDENCE E7): every game event goes through `NS.FEATURE_EVENTS` →
  `NS.SafeRegisterEvent` (`core/PGFE.lua:43`) and is unregistered on stand-down (`:112`). No timers,
  tickers or `OnUpdate` anywhere. The only survivors are `hooksecurefunc`/`HookScript` hooks on PGF,
  whose bodies gate on `NS.IsStoodDown()` (`modules/EnvInject.lua:58`, `modules/Panel.lua:393`) — the
  sanctioned exception. No SavedVariables write is reachable from a game event while stood down.
- **Verdict on the stand-down itself: compliant.** The conformance suite exists and is in the gate but
  covers only part of the mandated ten steps (PGE-05).
- Launcher: `isEnabled` reads the latch rather than the Enable row (PGE-11/12).

## Debug (debug-logging)

Console from a descriptor with `addonName`, session-only flag, `[Init]` summary, diagnostics in both
forms (no alias, live while disabled, sections in `modules/Diagnostics.lua`). Every `LibKa0s` descriptor
that takes `debug` is given the gated sink. **The addon's own flows write no debug lines at all** outside
the three profile callbacks (PGE-04).

## Tests and lint

- `luacheck .` — **0 warnings / 0 errors in 51 files**; `exclude_files` narrows to `libs/`, the frozen
  doc stores, `_dev/` and `tests/_kit/`; harness global in `files["tests/"]`.
- `lua tests/run.lua` — **186 passed, 0 failed, 1 skipped, 187 total** (exit 0), kit revision 38. Kit
  suites wired by path: `test_eol`, `test_prose`, `test_layout_cap`, `test_diagnostics_contract`,
  `test_lizard_sighted`. `docs/test-cases.md` equals a fresh `--list` byte for byte; README badge
  `186/186` matches its Total.

## Performance (performance) and complexity

- `LibKa0s-Perf-1.0` wired (instance, `perf` verb, `PerfDB`, latch hold) but **no bucket declared and no
  `tests/perf.lua`** (`core/PerfSetup.lua:7`, `:37`; `docs/performance.md:27`) — PGE-09.
- Complexity (vendored runner, sighted): **0 warnings, max CCN 13, 653 functions, 4,144 NLOC,
  blindFiles 0**. Newest bundle `docs/automated-tests/20261009-082905/` measured `2c78ddb`, one commit
  behind HEAD (that commit only records the bundle). Watch list empty. No retired `docs/complexity.md`.

## Packaging and line endings

- `.pkgmeta`: no `externals:`; ignores `.luacheckrc`, `.pkgmeta`, `.gitignore`, `.gitattributes`, `docs`,
  `tests`, `tools`, `CLAUDE.md`, `DEPENDENCIES.md`, `media/logos/*.png`, `_dev`, `*.bak`; `.claude` and
  `.superpowers` commented out and absent. All three packaging checks clean (only `.git` unaccounted,
  which needs no row).
- **`.gitattributes`, recorded verbatim in substance:** the 84-line canonical **client-bound** body,
  pin `* text=auto eol=crlf` (`:26`), `*.sh text eol=lf` (`:36`), `*.py text eol=lf` (`:37`), 20
  `binary` lines; `diff` against line-endings-§5's body is **empty**, no appendix. Check (e): **0**
  tracked files disagree with the pin. The kit's `test_eol` gate is wired.

## Root doc set (documentation-§1/§2/§7)

- `README.md`: canonical order (H1, four badges — published-version omitted pre-publish, description,
  Screenshots placeholder, Usage, How the filtering works, FAQ, Troubleshooting, Reporting a bug,
  Issues, Version History, Credits). Five cheap checks: badge **bare** (`README.md:5`); **no logo
  image**; **no bundled-library inventory**; **no numbered list**; provenance line **in `CLAUDE.md`**,
  not README. All pass.
- `CLAUDE.md`: stub shape, `## Standards compliance (read first)`, green-gate line, provenance line.
  `:24` says no audit exists yet, which this bundle makes stale (PGE-22, Info).
- `DEPENDENCIES.md`: runtime / development / release groups with evidence; omits Python for
  `tools/realm_map_diff.py` (PGE-15).

## `docs/` (documentation-§3)

- Trio present. Tier 1 all six present under canonical names. Tier 2: `slash-dispatch.md` (16 commands),
  `profiles.md` (Profiles page ships), `debug.md` (always), `perf-analysis/README.md` (harness wired)
  present; `midnight-quirks.md`, `compat-layer.md` (Compat publishes 0 counted shims), `message-bus.md`
  recorded *Not applicable* with their triggers. One Tier 3 doc (`realm-map-maintenance.md`).
- `## Documentation map`: four tables in the right order; every live `.md` under `docs/` appears once;
  no dangling rows; frozen stores named as directories; hub has no self-row (a MAY, not filed).
- No non-canonical Tier 1/2 names, no `file-index.md`/`conventions.md`/`complexity.md`/`perf-runs/`, no
  `docs/pending/`, no `TODO.md`, no `agent-context.md`. Hub is 298 lines; no mandated section > 60 lines.

## Deviation register and issue store (audit-review-history)

- `## Documented deviations` holds **one row** (`docs/ARCHITECTURE.md:291`): `library-stack-§6,
  toc-file-§1` — the hard `## Dependencies: PremadeGroupsFilter`, Decided 2026-10-09, trigger "PGF ships
  a public API, or the standard gains an extension-addon rule". Both cited rules still say what the row
  claims; the trigger has not fired at v2.77.0; the row cites no issue or bundle id, so there is nothing
  to resolve. **Recorded as accepted (PGE-R01), not counted.**
- Issue store (`gh issue list --state all`): three open issues (#1 raid, #2 PvP, #3 leader blocklist),
  each `state:untriaged` + a `severity:` label; no `[status]` prefixes; no `state:will-not-do` issue, so
  no missing-row case. Label colors do not match audit-review-history's palette (PGE-18).
- No `docs/revendor/` store: the only vendoring commit is the scaffold (`5939cc7`), so the re-vendor
  check has no horizon yet and nothing to report.
