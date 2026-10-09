local _, NS = ...
-- modules/Filters.lua — the per-character filter options (char.filters).
--
-- Get() hands out the live AceDB table itself, so the panel, presets and Apply all read and write
-- the same storage; Presets.Load refills it in place to keep that identity stable.

local Filters = NS.Filters or {}
NS.Filters = Filters

function Filters.Get() return NS.addon.db.char.filters end

function Filters.Set(key, value) Filters.Get()[key] = value end

function Filters.ToggleRegion(key)
    local r = Filters.Get().regions
    r[key] = (not r[key]) or nil
end

-- The selected region keys that belong to this portal, in Regions.KEYS[portal] order. A nil portal
-- (unsupported region) selects nothing.
function Filters.SelectedRegions(portal)
    local out, r = {}, Filters.Get().regions
    for _, k in ipairs((portal and NS.Regions.KEYS[portal]) or {}) do
        if r[k] then out[#out + 1] = k end
    end
    return out
end

-- The opts table Expression.BuildClauses takes. Regions only when enabled and the portal is
-- supported; maxAge only when enabled; keyLevel always.
function Filters.ToClauseOpts(portal)
    local f = Filters.Get()
    return {
        regions = (f.regionsEnabled and portal) and Filters.SelectedRegions(portal) or nil,
        noSameSpec = f.noSameSpec, noSameClassRole = f.noSameClassRole,
        experiencedLeader = f.experiencedLeader, keyLevel = f.keyLevel,
        maxAge = f.maxAgeEnabled and f.maxAge or nil,
    }
end

local function validAge(n)
    return type(n) == "number" and n >= 1 and n <= 240 and n == math.floor(n)
end

-- ok, errKey: "badLevel", "badAge" (integer 1..240), "noRegions" (enabled, none for this portal).
function Filters.Validate(portal)
    local f = Filters.Get()
    if not NS.Targeting.IsValidLevel(f.keyLevel) then return false, "badLevel" end
    if f.maxAgeEnabled and not validAge(f.maxAge) then return false, "badAge" end
    if f.regionsEnabled and portal and #Filters.SelectedRegions(portal) == 0 then
        return false, "noRegions"
    end
    return true
end
