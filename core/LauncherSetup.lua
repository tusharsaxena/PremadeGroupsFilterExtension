local addonName, NS = ...
-- core/LauncherSetup.lua — the launcher: one LibDataBroker object, registered twice (launcher).
--
-- LibKa0s-Launcher-1.0 builds the `launcher` object, registers the same object with LibDBIcon, owns
-- its single OnClick (left-click opens settings, right-click the options menu) and draws the status
-- tooltip. This file supplies the seams: the logo, the brand label, where LibDBIcon's `hide` lives
-- (db.global.minimap, shared with the Minimap button row) and the enable pair: it reads the stored
-- `enabled` setting, the same accessor the Master-controls row reads (launcher-§1), not the latch,
-- and it writes through the same handler `/pgfe enable|disable` calls.

local lib = LibStub and LibStub("LibKa0s-Launcher-1.0", true)

-- The 128x128 uncompressed 32-bit logo; the same path as the TOC's ## IconTexture.
local ICON = ("Interface\\AddOns\\%s\\media\\logos\\premadegroupsfilterextension.logo.128.tga"):format(addonName)

local function minimapStore()
    local db = NS.addon and NS.addon.db
    return db and db.global and db.global.minimap
end

if not lib then
    local missing = NS.L["%s, so there is no minimap button and no broker plugin."]:format(NS.LIBKA0S_MISSING)
    local said = false
    NS.Launcher = {
        Register = function()
            if not said then
                said = true
                if NS.Print then NS.Print(missing) end
            end
            return false
        end,
        IsRegistered = function() return false end,
        Object       = function() return nil end,
        IsShown      = function()
            local t = minimapStore()
            return not (t and t.hide)
        end,
        SetShown     = function(_, shown)
            local t = minimapStore()
            if t then t.hide = not shown end
            return false
        end,
    }
    return
end

NS.Launcher = lib:New({
    name  = addonName,
    icon  = ICON,
    label = "Ka0s Premade Groups Filter Extension",

    minimap = minimapStore,

    openSettings = function() NS.addon:OpenSettings() end,

    isEnabled  = function() return NS.SchemaRuntime and NS.SchemaRuntime.Get("enabled") ~= false end,
    setEnabled = function(on) NS.addon:SlashEnabled(on) end,

    print         = function(line) NS.Print(line) end,
    debug         = function(tag, message) NS.Debug(tag, message) end,
    debugAtEnable = function(tag, message) NS.DebugAtEnable(tag, "%s", message) end,

    version = function()
        local v = NS.Version()
        return v ~= "?" and v or nil
    end,
})
