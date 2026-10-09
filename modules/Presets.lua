local _, NS = ...
-- modules/Presets.lua — named, account-wide snapshots of the filter options (global.presets).
--
-- Save stores a deep copy of char.filters; Load deep-copies back into the live table in place, so
-- every holder of Filters.Get() sees the loaded values and the stored preset is never aliased. Load
-- lays the preset over a copy of the current filter defaults, so a preset saved before a filter key
-- existed still loads a complete option set.

local Presets = NS.Presets or {}
NS.Presets = Presets

local function copy(src)
    local out = {}
    for k, v in pairs(src) do out[k] = type(v) == "table" and copy(v) or v end
    return out
end

local function store() return NS.addon.db.global.presets end

local function cleanName(name)
    return type(name) == "string" and name:match("^%s*(.-)%s*$") or ""
end

function Presets.List()
    local names = {}
    for name in pairs(store()) do names[#names + 1] = name end
    table.sort(names)
    return names
end

-- ok, err: "badName" for an empty or whitespace-only name. An existing preset is overwritten.
function Presets.Save(name)
    name = cleanName(name)
    if name == "" then return false, "badName" end
    store()[name] = copy(NS.Filters.Get())
    return true
end

-- ok, err: "missing" when no preset has this name.
function Presets.Load(name)
    local src = store()[cleanName(name)]
    if not src then return false, "missing" end
    local fresh = copy(NS.C.CHAR_DEFAULTS.filters)
    for k, v in pairs(copy(src)) do fresh[k] = v end
    local live = NS.Filters.Get()
    for k in pairs(live) do live[k] = nil end
    for k, v in pairs(fresh) do live[k] = v end
    return true
end

function Presets.Delete(name)
    store()[cleanName(name)] = nil
    return true
end
