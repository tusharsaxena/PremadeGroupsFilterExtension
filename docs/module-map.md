# Module map — Ka0s Premade Groups Filter Extension

Every non-vendored file, in TOC load order, with its one responsibility. Vendored: `libs/` (Ace3,
LibStub, CallbackHandler, LibSharedMedia, LibDataBroker, LibDBIcon, LibKa0s v1.71.0) and
`tests/_kit/` (the LibKa0s test kit) — never edited here.

## Load order and why

Libraries load first (the `# Libraries` block, LibKa0s last after Ace3). Then `locales/enUS.lua`
(publishes `NS.L`), the `core/` setup files, `core/PGFBridge.lua`, `defaults/`, `modules/`, and
`settings/` last. Inside each block the TOC annotates every load-bearing position; the others are
conventional. The constraints that fix the order:

- `core/CoreSetup.lua` first in core: every later file captures `NS.Print` / `NS.Util.print`.
- `core/MediaSetup.lua` before `core/PGFE.lua`: `NS.FONT_MONO` is resolved from `NS.MediaFont` at load.
- `core/PGFE.lua` before every other addon file below it: it promotes `NS` to the AceAddon object
  and publishes `NS.PREFIX`, `NS.State`, `NS.FEATURE_EVENTS`.
- `core/DebugLogSetup.lua` after `core/PGFE.lua` (font, flag) and before any `NS.Debug` call.
- `core/LifecycleSetup.lua` before `core/PerfSetup.lua`: the Perf descriptor takes the latch.
- `defaults/Profile.lua` before `settings/Schema.lua` (`NS.C` is a file-scope upvalue there).
- `settings/SchemaSetup.lua` → `settings/Schema.lua` → `settings/OptionsSetup.lua` →
  `settings/Panel.lua`: each consumes what the previous publishes at file scope.
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
| `core/PGFBridge.lua` | The only file that touches PGF internals (stub until plan Task 6) |
| `defaults/Profile.lua` | `NS.C`: profile, char and global default values |
| `defaults/Realms.lua` | Realm → region data per portal (stub until Task 2) |
| `modules/Regions.lua` | Leader realm → region lookup (stub until Task 2) |
| `modules/Season.lua` | Season dungeons and best timed levels (stub until Task 3) |
| `modules/Targeting.lua` | Pure: untimed dungeons at a level (stub until Task 3) |
| `modules/Expression.lua` | Pure: options → PGF expression block, merge and strip (stub until Task 4) |
| `modules/Filters.lua` | The per-character filter options (stub until Task 5) |
| `modules/Presets.lua` | Named presets, account-wide (stub until Task 5) |
| `modules/EnvInject.lua` | The PGF env post-hook body (stub until Task 6) |
| `modules/Apply.lua` | Apply / Clear orchestration: prechecks, validation, targeting, expression merge, bridge writes, search |
| `modules/Panel.lua` | The panel attached under PGF's dialog (stub until Task 8) |
| `modules/Diagnostics.lua` | The sections of `/pgfe diagnostics` |
| `settings/SchemaSetup.lua` | `LibKa0s-Schema-1.0` or its host stub |
| `settings/Schema.lua` | Schema rows, the write seam, defaults assembly, the reset |
| `settings/OptionsSetup.lua` | `LibKa0s-Options-1.0`: the settings panel descriptor |
| `settings/Panel.lua` | Landing page body and the General page (Master controls) |
| `settings/Slash.lua` | `NS.COMMANDS` and `LibKa0s-Slash-1.0` |
| `settings/Profiles.lua` | The Profiles page |
| `tests/run.lua` | Suite list, factories, surface source, diagnostics facts |
| `tests/loader.lua` | Per-case isolated instance factory |
| `tests/wow_mock.lua` | Mock extender (client APIs this addon reads, AceDB `char`, LDB fakes) |
| `tests/pgf_fake.lua` | Premade Groups Filter stand-in |
| `tests/test_*.lua` | One suite per module plus the standard's named suites |
