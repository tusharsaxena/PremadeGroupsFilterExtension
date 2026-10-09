local _, NS = ...
-- modules/Filters.lua — the per-character filter options (char.filters).
--
-- Get() hands out the live AceDB table itself, so the panel, presets and Apply all read and write
-- the same storage; Presets.Load refills it in place to keep that identity stable.

local Filters = NS.Filters or {}
NS.Filters = Filters

function Filters.Get() return NS.addon.db.char.filters end

function Filters.Set(key, value) Filters.Get()[key] = value end

-- "Toggle PGF Extension Filters": the `filtersActive` profile setting (a schema row,
-- settings/Panel.lua), not a filter option, so presets never carry it.
function Filters.IsActive()
    local p = NS.addon.db and NS.addon.db.profile
    return not (p and p.filtersActive == false)
end

-- Through the schema seam, so the settings page, `/pgfe set filtersActive` and the panel all run the
-- row's onChange (Apply.OnFiltersToggled).
function Filters.SetActive(on)
    NS.addon.Settings.Helpers.Set("filtersActive", on and true or false)
end

-- The composition exclusions, in menu order. Booleans in `filters` (noSameSpec, noSameClassRole),
-- applied only while `compositionEnabled` is on.
Filters.COMPOSITION = { "noSameSpec", "noSameClassRole" }

function Filters.ToggleComposition(key)
    local f = Filters.Get()
    f[key] = not f[key]
end

function Filters.ClearComposition()
    local f = Filters.Get()
    for _, k in ipairs(Filters.COMPOSITION) do f[k] = false end
end

function Filters.SelectedComposition()
    local out, f = {}, Filters.Get()
    for _, k in ipairs(Filters.COMPOSITION) do
        if f[k] then out[#out + 1] = k end
    end
    return out
end

-- PGF's playstyle keywords (Main.lua: env.learning / relaxed / competitive / carry, one per
-- Enum.LFGEntryGeneralPlaystyle value 1..4), in the game's own order.
Filters.PLAYSTYLES = { "learning", "relaxed", "competitive", "carry" }

-- A multi-select with every option ticked means the same as none ticked: Any (no clause).
function Filters.IsAny(selected, total) return #selected == 0 or #selected >= total end

-- The keys of `set` that are among `keys`, in `keys` order.
local function selectedIn(set, keys)
    local out = {}
    for _, k in ipairs(keys) do
        if set[k] then out[#out + 1] = k end
    end
    return out
end

local function clearIn(set, keys)
    for _, k in ipairs(keys) do set[k] = nil end
end

local function isFull(set, keys) return #keys > 0 and #selectedIn(set, keys) >= #keys end

-- Toggle `key` in `set` over the options `keys`. A stored all-ticked set is Any, so it is cleared
-- first and the tick selects that one option; ticking the last unticked option clears the set to
-- Any. With no option list (an unsupported portal) it is a plain toggle.
local function toggleIn(set, keys, key)
    if isFull(set, keys) then clearIn(set, keys) end
    set[key] = (not set[key]) or nil
    if isFull(set, keys) then clearIn(set, keys) end
end

local function portalKeys(portal) return (portal and NS.Regions.KEYS[portal]) or {} end

function Filters.ToggleRegion(key, portal) toggleIn(Filters.Get().regions, portalKeys(portal), key) end

function Filters.TogglePlaystyle(key) toggleIn(Filters.Get().playstyles, Filters.PLAYSTYLES, key) end

-- Any: this portal's regions untick (another portal's stay as stored); nil portal clears nothing.
function Filters.ClearRegions(portal) clearIn(Filters.Get().regions, portalKeys(portal)) end

function Filters.ClearPlaystyles() clearIn(Filters.Get().playstyles, Filters.PLAYSTYLES) end

-- The selected playstyle keys in PLAYSTYLES order.
function Filters.SelectedPlaystyles()
    return selectedIn(Filters.Get().playstyles or {}, Filters.PLAYSTYLES)
end

-- The selected region keys that belong to this portal, in Regions.KEYS[portal] order. A nil portal
-- (unsupported region) selects nothing.
function Filters.SelectedRegions(portal)
    return selectedIn(Filters.Get().regions, portalKeys(portal))
end

Filters.MAX_AGE   = 240

-- The selected regions as a clause list, or nil for no region clause: regions off, an unsupported
-- portal, or Any (none selected, or every one of this portal's regions).
local function regionClause(f, portal)
    if not (f.regionsEnabled and portal) then return nil end
    local selected = Filters.SelectedRegions(portal)
    if Filters.IsAny(selected, #portalKeys(portal)) then return nil end
    return selected
end

-- The selected playstyles, or nil for no playstyle clause: off, or Any (none or all selected).
local function playstyleClause(f)
    if not f.playstyleEnabled then return nil end
    local selected = Filters.SelectedPlaystyles()
    if Filters.IsAny(selected, #Filters.PLAYSTYLES) then return nil end
    return selected
end

-- The opts table Expression.BuildClauses takes. Regions per regionClause, playstyles per
-- playstyleClause; maxAge only when enabled; keyLevel always.
function Filters.ToClauseOpts(portal)
    local f = Filters.Get()
    return {
        regions = regionClause(f, portal),
        playstyles = playstyleClause(f),
        noSameSpec = f.compositionEnabled and f.noSameSpec or nil,
        noSameClassRole = f.compositionEnabled and f.noSameClassRole or nil,
        experiencedLeader = f.experiencedLeader, keyLevel = f.keyLevel,
        maxAge = f.maxAgeEnabled and f.maxAge or nil,
    }
end

-- An integer in 1..max.
function Filters.IsWholeInRange(n, max)
    return type(n) == "number" and n >= 1 and n <= max and n == math.floor(n)
end

-- ok, errKey: "badLevel", "badAge" (integer 1..MAX_AGE).
function Filters.Validate()
    local f = Filters.Get()
    if not NS.Targeting.IsValidLevel(f.keyLevel) then return false, "badLevel" end
    if f.maxAgeEnabled and not Filters.IsWholeInRange(f.maxAge, Filters.MAX_AGE) then
        return false, "badAge"
    end
    return true
end

-- Smart key level: with smartKeyLevel on, keyLevel is set to Targeting.SmartLevel over the season's
-- dungeons; with no season data yet the stored level stands. Returns the key level.
function Filters.ApplySmartLevel()
    local f = Filters.Get()
    if not f.smartKeyLevel then return f.keyLevel end
    local level = NS.Targeting.SmartLevel(NS.Season.GetDungeons())
    if level then f.keyLevel = level end
    return f.keyLevel
end
