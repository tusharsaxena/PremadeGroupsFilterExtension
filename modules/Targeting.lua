local _, NS = ...
-- modules/Targeting.lua — pure: which dungeons are untimed at a key level.
--
-- A dungeon is a target at level N when the player's best TIMED run there is below N (never timed
-- counts as 0). No WoW API is touched here; the dungeon rows come from NS.Season.GetDungeons().

local Targeting = NS.Targeting or {}
NS.Targeting = Targeting

local MIN_LEVEL, MAX_LEVEL = 2, 40

-- True for an integer key level in 2..40.
function Targeting.IsValidLevel(n)
    return type(n) == "number" and n >= MIN_LEVEL and n <= MAX_LEVEL and n == math.floor(n)
end

-- The rows of `dungeons` whose best timed level is below `level`, same tables, input order.
function Targeting.Compute(dungeons, level)
    local targets = {}
    for _, d in ipairs(dungeons) do
        if (d.bestTimed or 0) < level then targets[#targets + 1] = d end
    end
    return targets
end

-- { [cmID] = true } for the given targets.
function Targeting.ToSet(targets)
    local set = {}
    for _, d in ipairs(targets) do set[d.cmID] = true end
    return set
end

-- PGF's difficulty range text for a single key level ("14-14").
function Targeting.RangeText(level)
    return ("%d-%d"):format(level, level)
end

-- Smart key level: the lowest level at which at least one of `dungeons` is still untimed, that is
-- the lowest best timed level + 1 (never timed counts as 0), clamped to 2..40. nil without rows.
-- KR 12, MR 13, TOS 13, DON 14 -> 13; all four at 13 -> 14.
function Targeting.SmartLevel(dungeons)
    if type(dungeons) ~= "table" or #dungeons == 0 then return nil end
    local low = math.huge
    for _, d in ipairs(dungeons) do low = math.min(low, d.bestTimed or 0) end
    return math.max(MIN_LEVEL, math.min(MAX_LEVEL, low + 1))
end
