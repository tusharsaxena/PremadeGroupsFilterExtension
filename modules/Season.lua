local _, NS = ...
-- modules/Season.lua — current-season Mythic+ dungeons and the player's best timed level.
--
-- GetDungeons() returns nil while C_ChallengeMode.GetMapTable() is not yet populated (early after
-- login); callers treat that as "loading". A dungeon never run, or never timed, has bestTimed 0.

local Season = NS.Season or {}
NS.Season = Season

-- "New Shiny Place" -> "NSP": first letter of each word longer than two letters (and always the
-- first word), so "Halls of Atonement" -> "HA".
local function initials(name)
    local out = {}
    for word in name:gmatch("%a+") do
        if #word > 2 or #out == 0 then out[#out + 1] = word:sub(1, 1):upper() end
    end
    return table.concat(out)
end

-- PGF's MAP_ID_TO_KEYWORDS rows look like { "<expansion>", "<dungeon>", "<season>" }.
local function shortName(mapID, name)
    local pgf = PremadeGroupsFilter and PremadeGroupsFilter.Debug
    local row = pgf and pgf.C and pgf.C.MAP_ID_TO_KEYWORDS and mapID and pgf.C.MAP_ID_TO_KEYWORDS[mapID]
    if row and row[2] then return row[2]:upper() end
    return initials(name or "?")
end

-- Array of { cmID, name, short, bestTimed } in GetMapTable() order, or nil while loading.
function Season.GetDungeons()
    local ids = C_ChallengeMode.GetMapTable()
    if not ids or #ids == 0 then return nil end
    local list = {}
    for _, cmID in ipairs(ids) do
        local name, _, _, _, _, mapID = C_ChallengeMode.GetMapUIInfo(cmID)
        local intime = C_MythicPlus.GetSeasonBestForMap(cmID)
        list[#list + 1] = {
            cmID = cmID, name = name or tostring(cmID),
            short = shortName(mapID, name),
            bestTimed = intime and intime.level or 0,
        }
    end
    return list
end
