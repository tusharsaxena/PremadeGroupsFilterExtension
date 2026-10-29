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
  "StaticPopupDialogs",
}

read_globals = {
  "_G", "LibStub", "hooksecurefunc",
  "C_AddOns", "C_ChallengeMode", "C_MythicPlus",
  "CreateFrame", "UIParent", "GameTooltip", "NineSliceUtil",
  "InCombatLockdown", "GetCurrentRegion", "GetRealmName", "UnitClass",
  "Settings", "PlaySound", "SOUNDKIT", "LFGListFrame", "MenuResponse", "C_LFGList", "C_Timer", "StaticPopup_Show", "StaticPopup_Hide", "YES", "NO",
  -- Premade Groups Filter (## Dependencies): read by core/PGFBridge.lua and modules/Diagnostics.lua
  -- (presence only).
  -- PremadeRegions (## OptionalDeps): read by modules/EnvInject.lua, modules/RegionTags.lua and
  -- modules/Diagnostics.lua.
  "PremadeGroupsFilter", "PremadeGroupsFilterDialog", "PremadeGroupsFilterDungeonPanel",
  "PremadeGroupsFilterState", "PremadeRegions",
  -- EllesmereUI (## OptionalDeps) is not declared: no shipped file reads it since PG-06 retired the
  -- addon's own bridge; LibKa0s-Skin-1.0's provider (libs/, not linted here) is its one reader.
}

-- The harness global, declared for tests/ only so no shipped file can reach for it. The
-- SavedVariables names are cleared by tests/loader.lua before each boot.
files["tests/"] = {
  globals = {
    "_G.PGFE_TEST",
    "_G.PremadeGroupsFilterExtensionDB",
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
