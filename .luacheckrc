-- .luacheckrc — lint config for Ka0s Premade Groups Filter Extension (lint).
-- `luacheck .` must report 0 warnings / 0 errors before every commit.

std = "lua51"
max_line_length = false
codes = true

-- libs/ is vendored (LibKa0s is linted in its own repo); tests/_kit/ is a byte copy of the
-- library's testkit/. Under docs/ only the frozen bundle stores are excluded. Everything else under
-- tests/ is ours and is linted.
exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "docs/revendor/", "_dev/", "tests/_kit/" }

-- No top-level `ignore`: a blanket suppression reaches every file (lint).

-- The SavedVariables write targets and the one Blizzard table the addon writes to.
globals = {
  "PremadeGroupsFilterExtensionDB",       -- AceDB
  "PremadeGroupsFilterExtensionPerfDB",   -- the perf capture ring (performance-§5)
  "StaticPopupDialogs",
}

read_globals = {
  "_G", "LibStub", "hooksecurefunc",
  "C_AddOns", "C_Timer", "C_ChallengeMode", "C_MythicPlus",
  "CreateFrame", "UIParent", "GameTooltip", "NineSliceUtil",
  "InCombatLockdown", "GetCurrentRegion", "GetRealmName", "UnitClass",
  "Settings", "LFGListFrame", "MenuResponse", "C_LFGList", "StaticPopup_Show", "StaticPopup_Hide", "YES", "NO",
  "debugprofilestop",                     -- the perf bracket's clock (performance-§2)
  -- Premade Groups Filter (## Dependencies) and PremadeRegions (## OptionalDeps). Read only by
  -- core/PGFBridge.lua, modules/EnvInject.lua and modules/Diagnostics.lua.
  "PremadeGroupsFilter", "PremadeGroupsFilterDialog", "PremadeGroupsFilterDungeonPanel",
  "PremadeGroupsFilterState", "PremadeRegions",
}

-- The harness global, declared for tests/ only so no shipped file can reach for it. The
-- SavedVariables names are cleared by tests/loader.lua before each boot.
files["tests/"] = {
  globals = {
    "_G.PGFE_TEST",
    "_G.PremadeGroupsFilterExtensionDB",
    "_G.PremadeGroupsFilterExtensionPerfDB",
  },
}

-- tests/pgf_fake.lua mirrors PGF's own method shapes (`panel:Init(state)`, `dialog:HookScript()`),
-- so a receiver the fake's body does not read is the calling convention, not dead code.
files["tests/pgf_fake.lua"] = {
  ignore = { "212/self" },
}

-- PGFE:SlashEnabled (the launcher's setEnabled seam) and PGFE:OnSlashCommand (AceConsole's handler)
-- are methods on the addon object by calling convention; neither body reads the receiver.
files["settings/Slash.lua"] = {
  ignore = { "212/self" },
}
