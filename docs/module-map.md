# Module map — Ka0s Premade Groups Filter Extension

Every non-vendored file, in TOC load order, with its one responsibility. Vendored: `libs/` (Ace3,
LibStub, CallbackHandler, LibSharedMedia, LibDataBroker, LibDBIcon, LibKa0s v1.71.0) and
`tests/_kit/` (the LibKa0s test kit) — never edited here.

## Load order and why

Libraries load first (the `# Libraries` block, LibKa0s last after Ace3). Then `locales/enUS.lua`
(publishes `NS.L`), the `core/` setup files, `core/PGFBridge.lua`, `core/EUIBridge.lua`, `defaults/`, `modules/`, and
`settings/` last. Every addon file's TOC line is annotated: `# LOAD-BEARING:` names what the file
needs at load, `# Conventional` says it reads its neighbors at call time only, and `# LAST` marks the
Profiles page. The constraints that fix the order:

- `core/CoreSetup.lua` first in core: every later file captures `NS.Print` / `NS.Util.print`.
- `core/MediaSetup.lua` before `core/PGFE.lua`: `NS.FONT_MONO` is resolved from `NS.MediaFont` at load.
- `core/PGFE.lua` before every other addon file below it: it promotes `NS` to the AceAddon object
  and publishes `NS.PREFIX`, `NS.State`, `NS.FEATURE_EVENTS`, `NS.STAND_DOWN` and `NS.STAND_UP`.
  `modules/EnvInject.lua`, `modules/Panel.lua`, `modules/EUISkin.lua` and every `settings/` file
  read `NS.addon` at load.
- `core/PGFE.lua` and `core/PGFBridge.lua` before `modules/EnvInject.lua` and `modules/Panel.lua`:
  both append to `NS.FEATURE_EVENTS` / `NS.STAND_UP` (Panel also to `NS.STAND_DOWN`) and install
  their hook through the bridge (`NS.Bridge.InstallEnvHook`, `NS.Bridge.HookDialog`) at file load.
- `core/DebugLogSetup.lua` after `core/PGFE.lua` (font, flag) and before any `NS.Debug` call.
- `core/LifecycleSetup.lua` before `core/PerfSetup.lua`: the Perf descriptor takes the latch.
- `defaults/Profile.lua` before `settings/Schema.lua` (`NS.C` is a file-scope upvalue there).
- `settings/SchemaSetup.lua` → `settings/Schema.lua` → `settings/OptionsSetup.lua` →
  `settings/Panel.lua`: each consumes what the previous publishes at file scope.
- `settings/Schema.lua` before `settings/Slash.lua`: Slash captures `NS.SchemaRuntime.Get` / `Set`
  / `FindRow` / `ApplyDefault` into its descriptor at load.
- `core/EUIBridge.lua` before `modules/EUISkin.lua`, which registers with EllesmereUI at file load
  under `NS.EUIBridge.SKIN_NAME`; `## OptionalDeps: EllesmereUI` loads EllesmereUI first when present.
- `settings/Profiles.lua` last, so the Profiles page is the last subcategory.

## Files

| File | Responsibility |
|---|---|
| `PremadeGroupsFilterExtension.toc` | Metadata and the load order |
| `locales/enUS.lua` | `NS.L` with the key-is-English metatable fallback |
| `core/CoreSetup.lua` | `LibKa0s-Core-1.0`: the `[PGFE]` printer, `SafeRegister*`, skin, close-button wrapper |
| `core/MediaSetup.lua` | `LibKa0s-Media-1.0`: `NS.Icon`, `NS.MediaFont`, the LSM registration |
| `core/Compat.lua` | `LibKa0s-Compat-1.0`: the spec readers |
| `core/EnvSetup.lua` | `LibKa0s-Env-1.0`: `NS.Meta`, `NS.Version` |
| `core/PGFE.lua` | The AceAddon object, lifecycle (`OnInitialize`, `OnEnable`), `NS.StandDown` / `NS.StandUp`, the `[Init]` summary |
| `core/Database.lua` | The schemaVersion migration runner |
| `core/DebugLogSetup.lua` | `LibKa0s-DebugLog-1.0`: the console, `NS.Debug` and its gates, the diagnostics hook-up |
| `core/LauncherSetup.lua` | `LibKa0s-Launcher-1.0`: the LDB launcher and minimap button |
| `core/LifecycleSetup.lua` | `LibKa0s-Lifecycle-1.0`: the stand-down latch, `NS.IsStoodDown()` |
| `core/PerfSetup.lua` | `LibKa0s-Perf-1.0`: the perf harness |
| `core/PGFBridge.lua` | The only file that touches PGF internals: seam check, dungeon state and expression read/write, commit, search, the env and dialog hooks |
| `core/EUIBridge.lua` | The only file that reads EllesmereUI state: the skin's four gate conditions (`Conditions`, `GateOpen`, `WhyClosed`) |
| `defaults/Profile.lua` | `NS.C`: profile, char and global default values |
| `defaults/Realms.lua` | `NS.RealmLists`: realm display names per portal and region bucket |
| `modules/Regions.lua` | Portal detection, realm normalization, leader name → region key |
| `modules/Season.lua` | Season dungeons, their short keywords and the player's best timed levels |
| `modules/Targeting.lua` | Pure: untimed dungeons at a level, the Smart level, level validation, the `N-N` range text |
| `modules/Expression.lua` | Pure: options → PGF expression block, merge and strip |
| `modules/Filters.lua` | The per-character filter options: get/set, region and playstyle toggles (all ticked = Any), validation, clause options, the Smart level write |
| `modules/Presets.lua` | Named presets, account-wide: list, save, load in place, delete |
| `modules/EnvInject.lua` | The PGF env post-hook body and the player's cached spec keywords; installs the hook at load |
| `modules/Apply.lua` | Apply / Clear orchestration: prechecks, validation, targeting, expression merge, bridge writes, search |
| `modules/RegionTags.lua` | The region tag on Group Finder rows and applicants; installs its two Blizzard hooks at load |
| `modules/Panel.lua` | The panel attached under PGF's dialog; installs the dialog hook at load |
| `modules/EUISkin.lua` | The optional EllesmereUI skin of that panel: registers at load, keeps the facade, paints when every condition and the switch hold, the reload prompt |
| `modules/Diagnostics.lua` | The sections of `/pgfe diagnostics` |
| `settings/SchemaSetup.lua` | `LibKa0s-Schema-1.0` or its host stub |
| `settings/Schema.lua` | Schema rows, the write seam, defaults assembly, the reset |
| `settings/OptionsSetup.lua` | `LibKa0s-Options-1.0`: the settings panel descriptor |
| `settings/Panel.lua` | Landing page body and the General page (Master controls; the EllesmereUI skin tab and its `euiSkin` row) |
| `settings/Slash.lua` | `NS.COMMANDS` and `LibKa0s-Slash-1.0` |
| `settings/Profiles.lua` | The Profiles page |
| `tests/run.lua` | Suite list, factories, surface source, diagnostics facts |
| `tests/loader.lua` | Per-case isolated instance factory |
| `tests/wow_mock.lua` | Mock extender (client APIs this addon reads, AceDB `char`, LDB fakes, the opt-in EllesmereUI fake) |
| `tests/pgf_fake.lua` | Premade Groups Filter stand-in |
| `tests/prose_waivers.lua` | Per-file, per-word waivers for the kit's prose gate (realm names) |
| `tests/test_*.lua` | One suite per module plus the standard's named suites |
| `tools/realm_map_diff.py` | Diffs `defaults/Realms.lua` against an installed PremadeRegions ([`realm-map-maintenance.md`](realm-map-maintenance.md)) |
