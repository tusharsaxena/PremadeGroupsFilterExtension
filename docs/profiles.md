# Profiles — Ka0s Premade Groups Filter Extension

AceDB profiles hold only the **profile** scope: the master switch (`enabled`), *Toggle PGF Extension
Filters* (`filtersActive`), *Show server regions in the Group Finder* (`showRegionTags`) and the
attached panel's collapsed state. The filter options are per **character** (`char.filters`) and presets are
**global**, so switching profiles never changes a character's filters.

- **Where:** Settings → AddOns → Ka0s Premade Groups Filter Extension → Profiles (AceDBOptions), or
  `/pgfe profile [name]`.
- **What reacts:** `OnProfileChanged`, `OnProfileCopied` and `OnProfileReset` (`core/PGFE.lua`) run
  the migrations, refresh open panels and re-read `enabled` into the stand-down latch, so a profile
  stored as disabled stands the addon down at once. Each event logs one `[Profile]` / `[Set]` line.
- **Reset all settings** is a profile reset (options-ui-§12); the minimap button's state is global
  and survives it.
