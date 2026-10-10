# 01 — Current state: Ka0s Premade Groups Filter Extension

Audit run **2026-10-10**, read-only, at commit `5decd65` (branch `fix/2026-10-10-audit-review`,
working tree clean at start). This is the second audit; prefix **`PGE`** (assigned 2026-10-09) and
every recurring ID are reused. The prior bundle `docs/audits/2026-10-09/` measured `58156ca`; HEAD
is 37 commits past it (`git log --oneline 58156ca..HEAD | wc -l` = 37), and those commits add the
EllesmereUI skin (`core/EUIBridge.lua`, `modules/EUISkin.lua`, a second General tab), the Group
Finder region tags (`modules/RegionTags.lua`), a panel rework, and fixes for PGE-01, PGE-14 and
PGE-22.

## Standard resolved

- **Audited against: Ka0s WoW Addon Standard v2.78.0 (2026-10-09)**, fetched with `curl -fsSL` from
  `https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` on 2026-10-10:
  `AUDIT.md`, `standards/STANDARDS.md`, `standards/ADDONS.md` and all **27** section files the
  Sections list links. No fetch failed. Each fetched file is byte-identical to the sibling clone
  `../WowAddonStandards` at `e6ab2b8` (`origin/master`), checked with `diff -q`.
- What changed since the last run's v2.77.0: options-ui-§5 now requires `BuildLandingPage` (and a
  300×300 logo), options-ui-§8 moves the landing constants into the library, the new options-ui-§19
  covers AceGUI's frame pool, the new anti-pattern #93 names its symptom, and AUDIT.md's panel checks
  gain item (j).
- **Repository kind: Addon.** `dev-copilot-profile` reported `profile=wow`, `kind=addon`
  (`reason=toc:## Interface`), and the repo has a `.toc`, which is AUDIT.md step 1's discriminator.
  The addon rule set (every section) is used.
- **Disagreement noted (carried):** the repo is still **not a row in `standards/ADDONS.md`** (the
  three tables hold 17 `| ` lines and none names this addon). The `.toc` makes the kind unambiguous,
  so this is recorded as the roster gap PGE-21 (Info, upstream), not as a kind disagreement.

## Layout (layout-§1..§4)

- Source lives under `core/` (12 files), `defaults/` (2), `modules/` (12), `settings/` (6) and
  `locales/` (1). `tests/` holds 25 authored files plus the vendored `tests/_kit/`. `tools/` holds
  `tools/realm_map_diff.py`, a diff tool that writes no tracked file, so it is not a generator.
- Authored Lua: **58 files, 8,921 lines** (`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`).
  Nothing is over the 1500 cap. **One file has entered the 1000–1500 band since the last record:
  `tests/test_panel.lua`, 1061 lines.** The largest shipped file is `modules/Panel.lua` at 895. The
  census heading `### Files over the 1500-line cap` sits under `## Documented deviations` and reads
  "Nothing is over the cap today." (`docs/ARCHITECTURE.md:391`, `:396`), which is correct. The kit
  gate `test_layout_cap` is wired (`tests/run.lua:110`).
- `media/logos/` holds `pgfe.logo.128.tga` (type 2, 128×128, 32 bpp), `pgfe.logo.tga` (type 2,
  256×256, 32 bpp) and `pgfe.logo.png`. The filenames are still not the folder name (PGE-13). There
  is no private copy of any `libs/LibKa0s/media/` asset.

## TOC (toc-file)

- `## Interface: 120100`, `## Title: Ka0s Premade Groups Filter Extension`, `## IconTexture` →
  `…\media\logos\pgfe.logo.128.tga` (the right format; the name is PGE-13), two SavedVariables,
  `## Dependencies: PremadeGroupsFilter` (ratified, PGE-R01),
  `## OptionalDeps: PremadeRegions, EllesmereUI, …`, `## X-License: MIT`, `## X-Standard`, and
  `# X-Curse-Project-ID: not published on CurseForge yet` in the field's position (compliant).
- Listing: `# Libraries` (Ace3, LSM, LDB, LDBIcon, then the single `libs\LibKa0s\LibKa0s.xml`) →
  `# Locales` → `# Core` (now including `core\EUIBridge.lua`) → `# Defaults` → `# Modules` (now
  `RegionTags`, `EUISkin`) → `# Settings`. `modules\EUISkin.lua` carries a correct LOAD-BEARING line.
  The `# Modules` group comment still says "conventional", which is false for `EnvInject`/`Panel`
  (PGE-06/07). `settings\Slash.lua` is still annotated conventional (PGE-08), and `settings\Panel.lua`
  carries no annotation on its own line (PGE-28, new dependent).

## Libraries (library-stack)

- Vendored under `libs/`: LibStub, CallbackHandler-1.0, AceAddon/Event/Console/Timer/DB/GUI/Config/
  DBOptions, LibSharedMedia-3.0, LibDataBroker-1.1, LibDBIcon-1.0 and LibKa0s. No `.pkgmeta`
  `externals:`.
- **Provenance:** `CLAUDE.md:45`, `Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.71.0 (MIT).`
  It is not in `README.md`. Both payloads diff **empty** against `../LibKa0s` at tag `v1.71.0`
  (E3). The TOC lists the aggregate `.xml` once.
- AceTimer-3.0 is still embedded and still unused (PGE-20, Info).
- **Optional integrations:** PremadeRegions (presence checks only) and EllesmereUI (new). EllesmereUI
  is presence-guarded, listed in `## OptionalDeps`, and the addon falls back to its own look without
  it, which is library-stack-§6's MAY. Its reads of `EllesmereUIDB` are ratified (PGE-R02).

## Shared subsystems — descriptors and stubs (library-stack-§7)

All are consumed from `LibKa0s` and none is hand-rolled. Each setup file resolves its major with
`LibStub(major, true)` and carries a library-absent branch. The shapes are unchanged since the last
run: Core, Media, Compat (reader arm), Env, DebugLog (member-answering, with gates and the
`RunDiagnostics` absent line), Launcher, Lifecycle (two-hold stub), Perf, Schema (runtime-completing),
Options (load-completing, the documented exception) and Slash (minimal dispatch, verbatim
`DISABLED_LINE_FORMAT`). `tests/test_surface_parity.lua` is green.

## Patterns (architecture, savedvariables)

- `NewAddon(NS, addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")` (`core/PGFE.lua:9-10`).
  `NS.Print` is reclaimed (`:25`) and the cyan `[PGFE]` tag set (`:21`).
- Feature modules are plain `NS.<Name>` tables that call each other directly. There is **no message
  bus**, and the new EllesmereUI skin adds more direct reactions: Panel → EUISkin, the profile reload
  → EUISkin and Panel, filtersActive → Apply → Panel (PGE-03).
- AceDB: `profile` {`enabled`, `filtersActive`, `showRegionTags`, `panelCollapsed`, `euiSkin`},
  `char.filters`, `global` {`schemaVersion = 0`, `presets`, `minimap = { hide = false }`}
  (`defaults/Profile.lua:15-38`). `NS.SCHEMA_VERSION = 1`, with one no-op step (`core/Database.lua`).
- Schema rows: the composed Master controls, plus `filtersActive` and `showRegionTags` as composer
  extras (PGE-23) and `euiSkin` on its own tab. The filter options and `panelCollapsed` are still
  written outside the seam and still documented as "named non-setting state" (PGE-02).

## Settings panel (options-ui)

- **Landing page:** `settings/Panel.lua:27-39` calls `Helpers.BuildLandingPage` with no `logoSize`,
  which is v2.78.0's mandated shape. PGE-14 is closed, and checklist (j)'s first half is compliant.
- **General:** tab strip `Master controls` → `EllesmereUI skin`. Master controls is composed
  `frameless`, omits visibility (PGE-19), and carries the two extras `filtersActive` and
  `showRegionTags` (PGE-23). The EllesmereUI tab is a host tab: the switch row, four status lines
  (`InteractiveLabel`s that use AceGUI callbacks only, which is compliant), a state line, and, when
  PGF's skin is missing, a link `EditBox` whose child `editbox` gets a `HookScript` that nothing
  undoes (PGE-27, options-ui-§19).
- **Profiles:** AceDBOptions through AceConfigDialog.
- The global reset is `db:ResetProfile()` behind the verbatim popup. The minimap row is
  `resetExempt` (`settings/Schema.lua:89`). Only one test touches the reset (PGE-10).
- No `SettingsPanel`/`HideUIPanel`/`OpenToCategory` call in host code. No host combat lock.

## Slash (slash-commands)

`/pgfe` and `/premadegroupsfilterextension` use `LibKa0s-Slash-1.0` with 16 `NS.COMMANDS` rows:
every reserved verb plus `profile`, `apply` and `clear`. `liveVerbs` is `lib.LIVE_VERBS` plus
`profile`, so `diagnostics` stays live. `apply`/`clear` are refused while stood down (the feature-verb
SHOULD, implemented). `enable`/`disable` write `enabled` through the seam (`settings/Slash.lua:157-167`).

## Disabled state (slash-commands-§7)

- **Latch:** `LibKa0s-Lifecycle-1.0`, one latch with two holds (`core/LifecycleSetup.lua`), and the
  perf harness takes its hold on the same latch. There is no second teardown path.
- **Registration census** (E7): seven feature events, all through `NS.FEATURE_EVENTS` →
  `NS.SafeRegisterEvent` (`core/PGFE.lua:43`), all unregistered on stand-down (`:121`). The two new
  ones are `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (`modules/EUISkin.lua:365-366`). There are
  no timers, tickers or `OnUpdate`. The survivors are `hooksecurefunc`/`HookScript` bodies that gate
  on `NS.IsStoodDown()`: PGF env, PGF dialog, the two RegionTags painters, and EUISkin's own-frame
  hooks. EllesmereUI's `RegisterSkin` callback has no unregister; its body keeps the facade but never
  paints while stood down (PGE-29, Info). No SavedVariables write is reachable from a game event while
  stood down.
- **Verdict on the stand-down: compliant.** The conformance suite is still the pre-rewrite shape
  (PGE-05), and it does not dispatch either diagnostics form.
- Launcher and Slash `isEnabled` still read the latch (PGE-11/12).

## Debug (debug-logging)

The console comes from a descriptor with `addonName`, a session-only flag, the `[Init]` summary and
diagnostics in both forms (sections in `modules/Diagnostics.lua`, now covering EllesmereUI). Every
`LibKa0s` descriptor that takes `debug` is given the sink. The new skin writes three lines, one of
them behind a hand-rolled change memo (PGE-25). **Apply/Clear, the panel, presets and the env hook
still write no debug line** (PGE-04).

## Tests and lint

- `luacheck .`: **0 warnings / 0 errors in 58 files**. `exclude_files` narrows to `libs/`, the frozen
  doc stores, `_dev/` and `tests/_kit/`. The harness global is in `files["tests/"]`.
- `lua tests/run.lua`: **325 passed, 0 failed, 1 skipped, 326 total** (exit 0), kit revision 38.
  `docs/test-cases.md` equals a fresh `--list` byte for byte, and the README badge `325/325` matches.

## Performance (performance) and complexity

- The harness is wired, but there is **no bucket and no `tests/perf.lua`** (PGE-09). The new
  RegionTags row hooks are a second per-row path, also unbracketed.
- **Complexity (vendored runner, sighted): FAIL, unmeasured.** `lizard` 1.24.0 raises a `TypeError`
  on `modules/RegionTags.lua`'s install loop (`pairs({ … = function … })`), so the run produces no
  table. The kit's parity check then reports **54 blind files** and the verdict reads amber. The
  newest bundle `20261009-082905` measured `2c78ddb`, **38 commits behind HEAD**. A diagnostic run
  with that one file removed from the shadow (not comparable, recorded in E17) shows 0 warnings, max
  CCN 14 (`reloadProfile`, dense guarding) and 1057 functions (PGE-24).

## Packaging and line endings

- `.pkgmeta`: all three packaging checks are clean. Only `.git` is unaccounted, and it needs no row.
- **`.gitattributes`, recorded in substance:** the 84-line canonical **client-bound** body with pin
  `* text=auto eol=crlf` (`:26`), `*.sh text eol=lf` (`:36`), `*.py text eol=lf` (`:37`) and 20
  `binary` lines. The diff of the first 84 lines against line-endings-§5's client-bound body is
  **empty**, and there is no appendix. Check (e) finds **0** tracked files disagreeing with the pin.
  The kit's `test_eol` gate is wired.

## Root doc set (documentation-§1/§2/§7)

- `README.md` keeps the canonical section order. All five cheap checks pass: the badge is bare
  (`:5`), there is no logo image, no bundled-library inventory and no numbered list outside fences,
  and the provenance line is in `CLAUDE.md`. `## Reporting a bug` is verbatim for `/pgfe`.
- `CLAUDE.md`: the stub shape with `## Standards compliance (read first)` (`:6`). It now points at
  `docs/audits/2026-10-09/`, so PGE-22 is closed.
- `DEPENDENCIES.md` still says the Release group has "One entry" and still omits Python for
  `tools/realm_map_diff.py` (PGE-15). It calls `lizard` "any recent" (`:40`, `:72`), which E17's
  crash qualifies.

## `docs/` (documentation-§3)

- The trio is present. All six Tier 1 docs are present. Tier 2: `slash-dispatch.md` (16 commands),
  `profiles.md`, `debug.md` and `perf-analysis/README.md` are present. `midnight-quirks.md`,
  `compat-layer.md` (the standard's grep counts **0** `function X.` shims in `core/Compat.lua`; the
  row says "2 shims, both supplied by LibKa0s", which is below three either way) and
  `message-bus.md` are *Not applicable* rows. There is one Tier 3 doc.
- `## Documentation map`: four tables in order. Every live `.md` under `docs/` is in exactly one
  table, there are no dangling rows, and the frozen stores are named as directories. The hub has no
  self-row (a MAY, not filed).
- There are no non-canonical names, no retired docs, no `docs/pending/` and no `docs/perf-runs/`. The
  hub is **396 lines**, just under the ~400 SHOULD. No mandated section is over 60 lines.

## Deviation register and issue store (audit-review-history)

- `## Documented deviations` holds **two rows** (`docs/ARCHITECTURE.md:388`, `:389`):
  - `library-stack-§6, anti-patterns #29`: `core/EUIBridge.lua` reads `EllesmereUIDB` switches.
    Decided 2026-10-09. The trigger is "EllesmereUI ships a public query … or the standard gains a
    carve-out". It has not fired, and the cited rules still say what the row claims. **PGE-R02,
    accepted (new).**
  - `library-stack-§6, toc-file-§1`: the hard `## Dependencies: PremadeGroupsFilter`. Decided
    2026-10-09, trigger not fired. **PGE-R01, accepted (carried).**
  - Neither row cites an issue or bundle id, so nothing fails to resolve. Observation only: the Why
    cells cite an owner decision rather than an issue (documentation-§3 SHOULD).
- Issue store (`gh issue list --state all`): 19 open issues, #1–#19, each `state:untriaged` plus one
  `severity:` label. There are no `[status]` prefixes and no `state:will-not-do` issue, so there is
  no missing-row case. Label colors still miss the palette (PGE-18). #4–#19 carry the 2026-10-09
  audit and review findings; none is closed although PGE-01 and PGE-14 are fixed in the tree.
- No `docs/revendor/` store exists, and the only commit touching `libs/LibKa0s`/`tests/_kit` is the
  scaffold `5939cc7`, so the re-vendor check has no horizon.
