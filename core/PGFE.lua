local addonName, NS = ...
-- core/PGFE.lua — AceAddon registration and lifecycle; the one place NS is promoted to an addon.
--
-- Hooks into Premade Groups Filter are installed at FILE LOAD by the modules that own them, with
-- hooksecurefunc and never AceHook (events-frames-taint). Every game event the addon reacts to is
-- declared in NS.FEATURE_EVENTS, so OnEnable and the stand-up register exactly the same list and the
-- stand-down unregisters exactly that list (slash-commands-§7).

local PGFE = LibStub("AceAddon-3.0"):NewAddon(NS, addonName, "AceConsole-3.0", "AceEvent-3.0")
NS.addon = PGFE

NS.version   = "1.0.0"
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

-- The three profile events share one reaction: migrations, the skin, panel refresh, and the latch re-read,
-- because an incoming profile carries its own answer to `enabled`.
local function reloadProfile(self)
    -- FIRST, the first-run skin picker down, quietly (core/SkinSetup.lua): a showing belongs to the
    -- profile it opened on, and taking it down puts back a pending preview (the stored skin, through
    -- the library's revert), so it lands before NS.ApplySkinChoice below and the new profile's whole
    -- pair is the last skin written. A new or reset profile still shows it, fresh, below.
    if NS.HideSkinPicker then NS.HideSkinPicker() end
    self:RunMigrations()
    -- The incoming profile's skin (core/SkinSetup.lua), right after its migrations and before
    -- anything refreshes: Skin:SetChoice repaints every recorded frame and fires OnLooksChanged,
    -- whether or not the attached panel was ever built, so the skin cannot ride Panel.Refresh.
    if NS.ApplySkinChoice then NS.ApplySkinChoice() end
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
    -- The first-run skin picker (core/SkinSetup.lua): a new or reset profile starts from the
    -- defaults, `skin.pickerSeen` false, so it shows; one that has seen it stays down. After the
    -- latch, so a profile with the addon switched off shows nothing.
    if NS.MaybeShowSkinPicker then NS.MaybeShowSkinPicker() end
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

    -- The skin the active profile names (core/SkinSetup.lua), right after the store and its
    -- migrations exist: the owner registered at file load, before AceDB, and has worn Ka0s Default
    -- since. Before any page or the attached panel is built, so the first paint is the profile's.
    if NS.ApplySkinChoice then NS.ApplySkinChoice() end

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

-- The seams and hook installs, written now with logging on or held for the next enable edge.
-- The install results are the stores each module keeps at load (Diagnostics reads them too).
local function logInstalls()
    if not (NS.DebugAtEnable and NS.Bridge) then return end
    local seamsOk, missing = NS.Bridge.Check()
    local rows = NS.RegionTags and NS.RegionTags.hooked or {}
    NS.DebugAtEnable("Init",
        "PGF seams %s; PremadeRegions %s; hooks env=%s dialog=%s searchRow=%s applicantRow=%s",
        seamsOk and "ok" or ("missing " .. tostring(missing)),
        _G.PremadeRegions and "loaded" or "absent",
        tostring(NS.EnvInject and NS.EnvInject.hooked == true or false),
        tostring(NS.Panel and NS.Panel.dialogHooked == true or false),
        tostring(rows.LFGListSearchEntry_Update == true),
        tostring(rows.LFGListApplicationViewer_UpdateApplicantMember == true))
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

    logInstalls()

    -- THE LATCH, taken from the stored path. Last, so everything above is up before it can be taken
    -- back down.
    if NS.Lifecycle then
        NS.Lifecycle:Set(NS.HOLD_DISABLED, not (self.db and self.db.profile and self.db.profile.enabled))
    end

    -- The first-run skin picker (core/SkinSetup.lua), once at login on a profile that has not closed
    -- it. After the latch, so a disabled addon shows nothing; in combat it holds for
    -- PLAYER_REGEN_ENABLED. No timer: the addon schedules nothing at rest (tests/test_disabled.lua).
    if NS.MaybeShowSkinPicker then NS.MaybeShowSkinPicker() end
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
