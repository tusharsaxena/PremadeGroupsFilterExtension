local addonName, NS = ...
-- core/PGFE.lua — AceAddon registration and lifecycle; the one place NS is promoted to an addon.
--
-- Hooks into Premade Groups Filter are installed at FILE LOAD by the modules that own them, with
-- hooksecurefunc and never AceHook (events-frames-taint). Every game event the addon reacts to is
-- declared in NS.FEATURE_EVENTS, so OnEnable and the stand-up register exactly the same list and the
-- stand-down unregisters exactly that list (slash-commands-§7).

local PGFE = LibStub("AceAddon-3.0"):NewAddon(NS, addonName,
    "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
NS.addon = PGFE

NS.version   = "0.1.0"
PGFE.VERSION = NS.version

-- Session-only runtime state, never persisted (debug-logging-§5).
NS.State = NS.State or {}
NS.State.debug = false

-- The mandatory cyan chat tag (slash-commands-§4).
NS.PREFIX = "|cff00ffff[PGFE]|r"

-- Reclaim NS.Print from AceConsole's embed: core/CoreSetup.lua published the library printer on
-- NS.Util.print, and the two names must be the same function object (architecture-§2).
NS.Print = NS.Util.print

-- The debug console's monospace face, from the shared payload; a real client font when absent.
NS.FONT_MONO_NAME = "JetBrains Mono"
NS.FONT_MONO = NS.MediaFont and NS.MediaFont(NS.FONT_MONO_NAME) or _G.STANDARD_TEXT_FONT
    or "Fonts\\FRIZQT__.TTF"

-- Every game event this addon owns, as { event, handlerMethodName } pairs. Feature modules append
-- their rows at file load; nothing registers an event anywhere else.
NS.FEATURE_EVENTS = NS.FEATURE_EVENTS or {}

-- Teardown and rebuild steps feature modules contribute (frames hidden, timers canceled, caches
-- dropped). Run by NS.StandDown / NS.StandUp, the lifecycle latch's two callbacks.
NS.STAND_DOWN = NS.STAND_DOWN or {}
NS.STAND_UP   = NS.STAND_UP or {}

local function registerFeatureEvents(self)
    for _, row in ipairs(NS.FEATURE_EVENTS) do
        NS.SafeRegisterEvent(self, row[1], row[2], NS.rejectedEvents)
    end
end

local function runAll(list)
    for _, fn in ipairs(list) do fn() end
end

-- The three profile events share one reaction: migrations, panel refresh, and the latch re-read,
-- because an incoming profile carries its own answer to `enabled`.
local function reloadProfile(self)
    self:RunMigrations()
    local S = self.Settings
    local H = S and S.Helpers
    if H and H.RefreshAll then H.RefreshAll() end
    if S and S.RefreshProfilesPage then S.RefreshProfilesPage() end
    -- The attached panel's collapsed state is in the profile. A stand-down below hides it anyway.
    if NS.Panel and NS.Panel.frame then NS.Panel.Refresh() end
    if NS.Lifecycle then
        NS.Lifecycle:Set(NS.HOLD_DISABLED, not (self.db and self.db.profile and self.db.profile.enabled))
        NS.Lifecycle:Reevaluate()
    end
end

-- Logged here, once (debug-logging-§10): a profile switch rewrites no row through the write seam.
function PGFE:OnProfileChanged(_, _, key)
    NS.Debug("Profile", "switched to '%s'", tostring(key or self.db:GetCurrentProfile()))
    reloadProfile(self)
end

function PGFE:OnProfileCopied(_, _, source)
    NS.Debug("Set", "copied profile '%s' \226\134\146 '%s'", source, self.db:GetCurrentProfile())
    reloadProfile(self)
end

function PGFE:OnProfileReset()
    local S = self.Settings
    local n = S and S.ConsumeResetCount and S.ConsumeResetCount()
    if n then
        NS.Debug("Set", "reset profile '%s' to defaults (%d rows)", self.db:GetCurrentProfile(), n)
    else
        NS.Debug("Set", "reset profile '%s' to defaults", self.db:GetCurrentProfile())
    end
    reloadProfile(self)
end

function PGFE:OnInitialize()
    -- settings/Schema.lua has loaded by ADDON_LOADED, so BuildDefaults exists.
    local S = self.Settings
    local defaults = S and S.BuildDefaults and S.BuildDefaults() or { profile = {} }
    self.db = LibStub("AceDB-3.0"):New("PremadeGroupsFilterExtensionDB", defaults, true)
    NS.db = self.db

    -- Before anything reads the profile (savedvariables-§1).
    self:RunMigrations()

    if self.db.RegisterCallback then
        self.db.RegisterCallback(self, "OnProfileChanged", function(...) self:OnProfileChanged(...) end)
        self.db.RegisterCallback(self, "OnProfileCopied",  function(...) self:OnProfileCopied(...) end)
        self.db.RegisterCallback(self, "OnProfileReset",   function(...) self:OnProfileReset(...) end)
    end

    self:RegisterChatCommand("pgfe", "OnSlashCommand")
    self:RegisterChatCommand("premadegroupsfilterextension", "OnSlashCommand")
end

-- DISABLED MEANS THE ADDON IS NOT RUNNING (slash-commands-§7). The latch's standDown: every
-- feature event actually unregistered and every module's teardown run. The chat command, the
-- dispatcher, the settings category, the launcher and AceDB's callbacks are setup and stay up.
-- The latch logs the edge itself (LibKa0s-Lifecycle-1.0); no edge line is written here.
function NS.StandDown()
    for _, row in ipairs(NS.FEATURE_EVENTS) do PGFE:UnregisterEvent(row[1]) end
    runAll(NS.STAND_DOWN)
end

-- Rebuilds from CURRENT state: settings may change while the addon is off.
function NS.StandUp()
    registerFeatureEvents(PGFE)
    runAll(NS.STAND_UP)
end

function PGFE:OnEnable()
    registerFeatureEvents(self)

    -- The player's spec keywords for the PGF env hook (modules/EnvInject.lua). The stand-up re-reads
    -- them too, but a first enable that is not stood down never crosses that edge.
    if NS.EnvInject and NS.EnvInject.RefreshPlayer then NS.EnvInject.RefreshPlayer() end

    -- Eager category registration (options-ui-§1); bodies stay lazy.
    if self.Settings and self.Settings.Register then self.Settings.Register() end

    -- The launcher needs db.global.minimap, which exists from OnInitialize.
    if NS.Launcher then NS.Launcher:Register() end

    -- THE LATCH, taken from the stored path. Last, so everything above is up before it can be taken
    -- back down.
    if NS.Lifecycle then
        NS.Lifecycle:Set(NS.HOLD_DISABLED, not (self.db and self.db.profile and self.db.profile.enabled))
    end
end

-- The [Init] session summary (debug-logging-§5): name, version, schema, profile, then state.
function PGFE:InitSummary()
    local db = self.db
    local schema  = db and db.global and db.global.schemaVersion
    local profile = (db and db.GetCurrentProfile and db:GetCurrentProfile()) or "?"
    local enabled = db and db.profile and db.profile.enabled
    local line = ("%s v%s, schema v%s, profile '%s' (enabled=%s, PremadeRegions=%s)"):format(
        addonName, tostring(NS.version), tostring(schema), tostring(profile), tostring(enabled),
        tostring(_G.PremadeRegions ~= nil))
    if #NS.rejectedEvents > 0 then
        line = line .. ", rejected events: " .. table.concat(NS.rejectedEvents, ", ")
    end
    return line
end
