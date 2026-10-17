local _, NS = ...
-- modules/Presets.lua — named, account-wide snapshots of the filter options (global.presets).
--
-- Save stores a deep copy of char.filters; Load deep-copies back into the live table in place, so
-- every holder of Filters.Get() sees the loaded values and the stored preset is never aliased. Load
-- lays the preset over a copy of the current filter defaults, so a preset saved before a filter key
-- existed still loads a complete option set.
--
-- The selected preset (the panel dropdown's choice) is per character, in char.selectedPreset, so it
-- survives a reload or login. Save and Load select; Delete clears it. A name another character
-- deleted from the shared registry reads back as no selection.

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

local function char() return NS.addon.db.char end

--- @return string|nil name  the selected preset, nil when none is selected or it no longer exists
function Presets.GetSelected()
    local name = char().selectedPreset
    if name ~= nil and store()[name] == nil then
        char().selectedPreset = nil
        return nil
    end
    return name
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
    if name == "" then
        NS.Debug("Preset", "save refused: badName")
        return false, "badName"
    end
    store()[name] = copy(NS.Filters.Get())
    char().selectedPreset = name
    NS.Debug("Preset", "saved '%s'", name)
    return true
end

-- ok, err: "missing" when no preset has this name.
function Presets.Load(name)
    name = cleanName(name)
    local src = store()[name]
    if not src then
        NS.Debug("Preset", "load '%s' refused: missing", name)
        return false, "missing"
    end
    local fresh = copy(NS.C.CHAR_DEFAULTS.filters)
    for k, v in pairs(copy(src)) do fresh[k] = v end
    local live = NS.Filters.Get()
    for k in pairs(live) do live[k] = nil end
    for k, v in pairs(fresh) do live[k] = v end
    char().selectedPreset = name
    NS.Debug("Preset", "loaded '%s'", name)
    return true
end

function Presets.Delete(name)
    name = cleanName(name)
    local presets = store()
    if presets[name] == nil then
        NS.Debug("Preset", "delete '%s': absent", name)
    else
        presets[name] = nil
        if char().selectedPreset == name then char().selectedPreset = nil end
        NS.Debug("Preset", "deleted '%s'", name)
    end
    return true
end
