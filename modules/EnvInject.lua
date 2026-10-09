local _, NS = ...
-- modules/EnvInject.lua — the PGF env post-hook body: region and pgfe_* variables.
--
-- PGF builds one env table per search result and calls PutPremadeRegionInfo(env, leaderName) on it
-- last (PGF v7.6.2 Main.lua:363-364), after the member keywords (`<spec>_<class>s`,
-- `<roleprefix>_<class>s`) are counted into it (Main.lua:316; Modules/MemberInfo.lua:45-77). This
-- module post-hooks that call and adds:
--   pgfe_samespec       members sharing the player's spec (env[<player spec keyword>])
--   pgfe_sameclassrole  members sharing the player's class in the player's role
--   region + the twelve region keys, only when PremadeRegions is not loaded (PGF's own plugin
--   fills them from PremadeRegions when it is: Plugins/PremadeRegions.lua:25-46).

local EnvInject = NS.EnvInject or {}
NS.EnvInject = EnvInject

-- PGF's C.ROLE_PREFIX (Init.lua:134-138), used for its roleClassKeyword "tank_warriors"
-- (Modules/Specializations.lua:97).
local ROLE_PREFIX = { DAMAGER = "dps", HEALER = "heal", TANK = "tank" }

-- The player's two keywords, cached at enable and on spec change, so the per-result hook does no
-- API call.
local player = {}

--- PGF's own keyword formulas (Modules/Specializations.lua:94, 97):
---   specKeyword      = spec:lower() .. "_" .. class:lower() .. "s"   ("beastmastery_hunters")
---   roleClassKeyword = ROLE_PREFIX[role] .. "_" .. class:lower() .. "s"  ("dps_hunters")
--- @param specTable table|nil  PGF's C.SPECIALIZATIONS (Modules/Specializations.lua:25)
--- @return string|nil specKeyword
--- @return string|nil classRoleKeyword
function EnvInject.PlayerKeywords(specID, role, classFile, specTable)
    local info = specID and specTable and specTable[specID]
    local spec = info and info.spec and info.class
        and (info.spec:lower() .. "_" .. info.class:lower() .. "s") or nil
    local prefix = role and ROLE_PREFIX[role]
    local classRole = (prefix and classFile) and (prefix .. "_" .. classFile:lower() .. "s") or nil
    return spec, classRole
end

function EnvInject.RefreshPlayer()
    local idx = GetSpecialization and GetSpecialization()
    local specID, role, _
    if idx then specID, _, _, _, role = GetSpecializationInfo(idx) end
    local _, classFile = UnitClass("player")
    local pgf = PremadeGroupsFilter and PremadeGroupsFilter.Debug
    player.spec, player.classRole = EnvInject.PlayerKeywords(specID, role, classFile,
        pgf and pgf.C and pgf.C.SPECIALIZATIONS)
end

local function injectRegions(env, leaderName)
    for _, k in ipairs(NS.Regions.ALL_KEYS) do env[k] = false end
    local r = NS.Regions.GetRegion(leaderName)
    env.region = r
    if r then env[r] = true end
end

--- The hook body. Returns at once while stood down (hooksecurefunc has no un-hook).
function EnvInject.Apply(env, leaderName)
    if NS.IsStoodDown() then return end
    if not PremadeRegions then injectRegions(env, leaderName) end
    env.pgfe_samespec = player.spec and tonumber(env[player.spec]) or 0
    env.pgfe_sameclassrole = player.classRole and tonumber(env[player.classRole]) or 0
end

-- Spec changes: ACTIVE_PLAYER_SPECIALIZATION_CHANGED (no payload) and PLAYER_SPECIALIZATION_CHANGED
-- (unit). Declared through NS.FEATURE_EVENTS so the stand-down unregisters them; the stand-up
-- re-reads the player because the spec may have changed while the addon was off.
local addon = NS.addon

function addon.OnActiveSpecChanged()
    EnvInject.RefreshPlayer()
end

function addon.OnPlayerSpecChanged(_, _, unit) -- AceEvent: (self, event, unit)
    if unit == nil or unit == "player" then EnvInject.RefreshPlayer() end
end

NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "OnActiveSpecChanged" }
NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "PLAYER_SPECIALIZATION_CHANGED", "OnPlayerSpecChanged" }
NS.STAND_UP[#NS.STAND_UP + 1] = EnvInject.RefreshPlayer

-- Installed at FILE LOAD (hooks at load; never AceHook). PGF is a hard dependency
-- (## Dependencies), so its namespace exists by now.
NS.Bridge.InstallEnvHook(function(env, leaderName) EnvInject.Apply(env, leaderName) end)
