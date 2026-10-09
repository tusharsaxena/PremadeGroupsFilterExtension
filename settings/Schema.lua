local _, NS = ...
-- settings/Schema.lua — the schema rows and the one write seam every settings path goes through.
--
-- One row per setting drives the panel widget, `/pgfe list|get|set|reset` and the defaults reset
-- (architecture-§5). Today every row is a Master controls row composed by LibKa0s-Options-1.0 in
-- settings/Panel.lua and spliced in at load. The filter options are NOT schema rows: they are the
-- attached panel's per-character state, written by modules/Filters.lua (docs/ARCHITECTURE.md ->
-- Settings Schema names every store and its one owner).

local PGFE = NS.addon
local L    = NS.L
local C    = NS.C

PGFE.Settings = PGFE.Settings or {}
local Settings   = PGFE.Settings
Settings.Schema  = {}
Settings.Helpers = Settings.Helpers or {}
local Schema  = Settings.Schema
local Helpers = Settings.Helpers

local function pout(...) return NS.Print(...) end

local function deepcopy(v)
    if type(v) ~= "table" then return v end
    local c = {}
    for k, val in pairs(v) do c[k] = deepcopy(val) end
    return c
end

-- Session-only rows: storage is the console's own flag, never SavedVariables.
local SESSION = {
    ["state.debugConsole"] = function()
        local DL = NS.DebugLog
        return DL and DL.ConsoleCheckbox and DL:ConsoleCheckbox() or nil
    end,
}

-- The Minimap button row reads and writes LibDBIcon's own `hide` in the GLOBAL store, inverted
-- (launcher-§3). There is no `shown` key anywhere.
local MINIMAP_PATH = "global.minimap.shown"
local function minimapStore()
    local db = PGFE.db
    return db and db.global and db.global.minimap
end
local GLOBAL = {
    [MINIMAP_PATH] = {
        get = function()
            local t = minimapStore()
            return not (t and t.hide)
        end,
        set = function(v)
            local t = minimapStore()
            if t then t.hide = not v end
            if NS.Launcher then NS.Launcher:SetShown(v and true or false) end
        end,
    },
}

--- Bind get/set closures onto the composed rows whose storage is not a profile path.
function Settings.StampClosureRows(rows)
    for _, row in ipairs(rows or {}) do
        local path = type(row) == "table" and row.path or nil
        local session, g = SESSION[path], GLOBAL[path]
        if session then
            row.get = function()
                local spec = session()
                return spec and spec.get() or false
            end
            row.set = function(v)
                local spec = session()
                if spec then spec.set(v and true or false) end
            end
        elseif g then
            row.get = g.get
            row.set = function(v) g.set(v and true or false) end
        end
    end
end

-- THE WRITE SEAM. The panel checkbox, the CLI and the resets all land in S.Set.
local S = Settings.SchemaLib:New{
    rows         = Schema,
    resolveRoot  = function() return PGFE.db and PGFE.db.profile, 1 end,
    announce     = function() Helpers.RefreshAll() end,
    debug        = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,
    debugEnabled = function() return NS.State.debug == true end,
    print        = pout,
    -- The minimap button is a per-installation display preference: neither reset may touch it.
    resetExempt  = { [MINIMAP_PATH] = true },
}
NS.SchemaRuntime = S

Helpers.Get, Helpers.Set, Helpers.FindSchema, Helpers.ApplyDefault =
    S.Get, S.Set, S.FindRow, S.ApplyDefault
Settings.ConsumeResetCount = S.ConsumeResetCount

local VALID_TYPES = { bool = true, number = true, string = true }

--- Validate every row; returns the error count.
function Helpers.ValidateSchema()
    local errors = S.Validate{ types = VALID_TYPES }
    for i, def in ipairs(Schema) do
        if type(def) == "table" then
            local where = "row #" .. i .. " (" .. tostring(def.path or "<no path>") .. ")"
            if type(def.section) ~= "string" then
                pout("|cffff0000schema error|r: " .. where .. ": missing or non-string `section`")
                errors = errors + 1
            end
            if type(def.label) ~= "string" then
                pout("|cffff0000schema error|r: " .. where .. ": missing or non-string `label`")
                errors = errors + 1
            end
        end
    end
    return errors
end

--- The AceDB defaults tree: defaults/Profile.lua's three scopes, then every stored schema row.
function Settings.BuildDefaults()
    local out = {
        profile = deepcopy(C.PROFILE),
        char    = deepcopy(C.CHAR_DEFAULTS),
        global  = deepcopy(C.GLOBAL_DEFAULTS),
    }
    for _, def in ipairs(Schema) do
        if def.path and not def.sessionOnly and not GLOBAL[def.path] then
            local segs = {}
            for part in string.gmatch(def.path, "[^.]+") do segs[#segs + 1] = part end
            local parent = out.profile
            for i = 1, #segs - 1 do
                parent[segs[i]] = parent[segs[i]] or {}
                parent = parent[segs[i]]
            end
            parent[segs[#segs]] = deepcopy(def.default)
        end
    end
    return out
end

local function notGlobal(row) return not GLOBAL[row.path] end

--- The global reset IS a profile reset (options-ui-§12); the walk keeps only session rows.
function Settings.VetoedFromResetAll(row)
    return row.page == "profiles" or not row.sessionOnly
end

function Helpers.RestoreAllDefaults()
    local db = PGFE.db
    if db and db.ResetProfile then
        local ok, err = pcall(S.ResetCounted, function() db:ResetProfile() end, notGlobal)
        if not ok then
            NS.Debug("Set", "reset profile '%s' to defaults (stopped by an error)", db:GetCurrentProfile())
            error(err, 0)
        end
    end
    S.BulkRun("reset", "profile", function(info)
        info.profileReset = true
        for _, def in ipairs(Schema) do
            if not Settings.VetoedFromResetAll(def) then S.ApplyDefault(def) end
        end
    end)
end

function Helpers.RefreshAll()
    local H = Settings.Helpers
    if H and H.RefreshScalars then H.RefreshScalars() end
end

function Settings.EnsureResetPopup()
    if Settings._resetPopupRegistered then return end
    Settings._resetPopupRegistered = true
    StaticPopupDialogs["PREMADEGROUPSFILTEREXTENSION_RESET_ALL"] = {
        text         = L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."],
        button1      = YES or "Yes",
        button2      = NO  or "No",
        timeout      = 0,
        whileDead    = true,
        hideOnEscape = true,
        OnAccept     = function()
            Helpers.RestoreAllDefaults()
            pout(L["all settings reset to defaults"])
        end,
    }
end
