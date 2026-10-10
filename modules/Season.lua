local _, NS = ...
-- modules/Season.lua — current-season Mythic+ dungeons and the player's best timed level.
--
-- GetDungeons() returns nil while C_ChallengeMode.GetMapTable() is not yet populated (early after
-- login); callers treat that as "loading". A dungeon never run, or never timed, has bestTimed 0.
-- GetDungeons() also owns the season-data request (RequestOnce), so every caller (the panel, Apply,
-- Smart) asks the server and none asks twice in one episode.

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

-- The season-data request (C_MythicPlus.RequestMapInfo): once per episode, not once per
-- CHALLENGE_MODE_MAPS_UPDATE round trip. `requested` is the guard; `lastFull` remembers that the map
-- table was populated, so the full -> empty rollover re-arms the request exactly once.
local requested = false
local lastFull = false

--- Ask the server for season data, unless this episode already asked.
function Season.RequestOnce()
    if requested then return end
    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        requested = true
        C_MythicPlus.RequestMapInfo()
    end
end

--- Re-arm the request: the next RequestOnce sends again. Called on a rollover and on every
--- PLAYER_ENTERING_WORLD (modules/Panel.lua), so a lost request recovers on the next loading screen.
function Season.ResetRequest() requested = false end

-- Array of { cmID, name, short, bestTimed } in GetMapTable() order, or nil while loading.
-- Every call reads the map table first, then decides, then requests (spec 2026-10-10 C-06): the
-- first empty read after a full one is a rollover that resets AND sends in the same call; a second
-- empty read finds the "was full" memory cleared, so it neither resets nor sends.
function Season.GetDungeons()
    local ids = C_ChallengeMode.GetMapTable()
    local full = ids and #ids > 0
    if full then
        lastFull = true
    elseif lastFull then
        lastFull = false
        Season.ResetRequest()
    end
    Season.RequestOnce()
    if not full then return nil end
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
