local _, NS = ...
-- settings/Slash.lua — the ordered NS.COMMANDS table and the LibKa0s-Slash-1.0 descriptor.
--
-- The dispatcher, help renderer, formatters and value parser are the library's (slash-commands-§1).
-- What stays here is the ordered verb table (positional triples {name, desc, fn}) and the host verbs
-- that reach into this addon's own state. The feature verbs `apply` and `clear` delegate to
-- modules/Apply.lua; a typed slash command is a hardware event, so `apply` may search (a macro
-- button works the same way). `perf` is reserved but never registered: the addon holds the
-- performance-§12 no-combat-path exemption, and the library answers it as an unknown command.

local PGFE = NS.addon
local L    = NS.L

local function helpers() return PGFE.Settings and PGFE.Settings.Helpers end
local function trim(s) return (s or ""):gsub("^%s+", ""):gsub("%s+$", "") end

local ENABLED_PATH = "enabled"

local Sl   -- forward-declared: the handlers below reach it at call time
local runConfig, runDebug, runReset, runResetAll, runEnabled, runApply, runClear

local COMMANDS = {
    {"help",     L["List available commands"],
        function() Sl:PrintHelp() end},
    {"config",   L["Open the Ka0s Premade Groups Filter Extension settings panel"],
        function() runConfig() end},
    {"enable",   L["Enable the addon"],
        function() runEnabled(true) end},
    {"disable",  L["Disable the addon"],
        function() runEnabled(false) end},
    {"version",  L["Print the addon version"],
        function() Sl:CliVersion() end},
    {"list",     L["List every setting and its current value"],
        function() Sl:CliList() end},
    {"get",      L["Print a setting's current value — `/pgfe get <path>`"],
        function(rest) Sl:CliGet(rest) end},
    {"set",      L["Set a setting — `/pgfe set <path> <value>` (try /pgfe list)"],
        function(rest) Sl:CliSet(rest) end},
    {"reset",    L["Reset one setting to its default — `/pgfe reset <path>`"],
        function(rest) runReset(rest) end},
    {"resetall", L["Reset every setting to defaults"],
        function() runResetAll() end},
    {"profile",  L["List profiles, or switch to one: profile <name>"],
        function(rest) Sl:CliProfile(rest) end},
    {"debug",    L["Open/close the debug window — `/pgfe debug on|off` toggles logging"],
        function(rest) runDebug(rest) end},
    {"diagnostics", L["Write the diagnostics report to the debug console"],
        function() NS.DebugLog:RunDiagnostics() end},
    {"apply",    L["Apply the filter options to Premade Groups Filter and search"],
        function() runApply() end},
    {"clear",    L["Remove this addon's block from the Advanced Filter Expression"],
        function() runClear() end},
}
NS.COMMANDS = COMMANDS
PGFE.COMMANDS = COMMANDS

local lib = LibStub and LibStub("LibKa0s-Slash-1.0", true)
local CLI_MISSING = L["%s, so the settings CLI is unavailable."]:format(NS.LIBKA0S_MISSING)

local function libraryAbsent(verb)
    NS.Print(L["%s is unavailable: the LibKa0s library did not load."]:format(verb))
end

if not lib then
    -- Degrade, never error: `/pgfe` is registered unconditionally, so something must answer. The
    -- host verbs keep working; the schema CLI names the missing library. The ONE library string the
    -- stub carries verbatim is DISABLED_LINE_FORMAT, pinned by Kit.assertLibraryConstant.
    local function unavailable() NS.Print(CLI_MISSING) end
    local function profileAbsent() libraryAbsent("/pgfe profile") end
    local DISABLED_LINE_FORMAT = "%s is disabled \226\128\148 enable it with |cFFFFFF00%s|r"

    local function helpRow(entry) return "/pgfe " .. entry[1] .. " — " .. entry[2] end

    Sl = {
        OnSlash = function(_, msg)
            local raw = trim(msg)
            if raw == "" then return runConfig() end
            local name, rest = raw:match("^(%S+)%s*(.*)$")
            name = (name or ""):lower()
            for _, entry in ipairs(COMMANDS) do
                if entry[1] == name then return entry[3](rest or "") end
            end
            NS.Print(L["unknown command '%s'"]:format(name))
            Sl:PrintHelp()
        end,
        PrintHelp = function()
            NS.Print(L["v%s slash commands"]:format(NS.Version()))
            for _, entry in ipairs(COMMANDS) do NS.Print("  " .. helpRow(entry)) end
        end,
        HelpRows = function()
            local out = {}
            for i, entry in ipairs(COMMANDS) do out[i] = "  " .. helpRow(entry) end
            return out
        end,
        LandingRows = function()
            local out = {}
            for i, entry in ipairs(COMMANDS) do out[i] = helpRow(entry) end
            return out
        end,
        HelpHeader   = function() return L["v%s slash commands"]:format(NS.Version()) end,
        DisabledLine = function()
            return DISABLED_LINE_FORMAT:format("Ka0s Premade Groups Filter Extension", "/pgfe enable")
        end,
        __disabledLineFormat = DISABLED_LINE_FORMAT,
        CliList         = unavailable,
        CliGet          = unavailable,
        CliSet          = unavailable,
        CliReset        = unavailable,
        CliResetAll     = unavailable,
        CliVersion      = function() NS.Print("v" .. NS.Version()) end,
        BuildListLines  = function() return { CLI_MISSING } end,
        SetRowAnnotator = function() end,
        Text            = function(_, key) return key end,
        CliProfile      = function() profileAbsent() end,
        ProfileSwitch   = function() profileAbsent(); return false end,
    }
    NS.SlashCommands = Sl
else
    -- `profile` answers while disabled too: it is how a player reaches an enabled profile.
    local liveVerbs = {}
    for i, verb in ipairs(lib.LIVE_VERBS) do liveVerbs[i] = verb end
    liveVerbs[#liveVerbs + 1] = "profile"

    Sl = lib:New({
        slash        = "/pgfe",
        slashAliases = { "/premadegroupsfilterextension" },
        commands     = COMMANDS,                       -- passed IN, never owned by the library
        isEnabled    = function() return not NS.IsStoodDown() end,
        brandName    = "Ka0s Premade Groups Filter Extension",
        liveVerbs    = liveVerbs,
        profiles     = function() return PGFE.db end,
        print        = function(line) NS.Print(line) end,
        debug        = function(tag, message) NS.Debug(tag, message) end,
        version      = NS.Version,
        get          = NS.SchemaRuntime.Get,
        set          = NS.SchemaRuntime.Set,           -- the single write seam
        findRow      = NS.SchemaRuntime.FindRow,
        allRows      = function() return PGFE.Settings.Schema end,
        applyDefault = NS.SchemaRuntime.ApplyDefault,
        groupKey     = function(row) return row.section or "?" end,
    })
    NS.SlashCommands = Sl
end

--- Open the settings panel (registering the category first if OnEnable has not run yet).
function PGFE:OpenSettings()
    if self.Settings and self.Settings.Register then self.Settings.Register() end
    local H = helpers()
    if not (H and H.OpenOptionsPanel) then return NS.Print(L["Settings panel is not available."]) end
    H.OpenOptionsPanel()
end

function runConfig() PGFE:OpenSettings() end

-- `/pgfe enable|disable`: aliases writing the Enable row's stored path through the write seam.
function runEnabled(on)
    local H = helpers()
    if not (H and H.Set) then return NS.Print(CLI_MISSING) end
    local row = H.FindSchema(ENABLED_PATH)
    if not row then return libraryAbsent(on and "/pgfe enable" or "/pgfe disable") end
    local ok, err = H.Set(ENABLED_PATH, on)
    if ok == false then return NS.Print(tostring(err)) end
    local value = H.Get(ENABLED_PATH)
    if lib then return NS.Print(lib.FormatKV(row.path, lib.FormatValue(row, value))) end
    NS.Print(ENABLED_PATH .. " = " .. tostring(value))
end

function runReset(rest)
    if trim(rest) == "" then
        NS.Print(L["|cffFFFF00%s|r takes a setting path: |cffFFFF00%s|r (try |cffFFFF00%s|r). To reset everything: |cffFFFF00%s|r."]
            :format("/pgfe reset", "/pgfe reset <path>", "/pgfe list", "/pgfe resetall"))
        return
    end
    Sl:CliReset(rest)
end

function runResetAll()
    local H = helpers()
    if not (H and H.RestoreAllDefaults) then return NS.Print(CLI_MISSING) end
    PGFE.Settings.EnsureResetPopup()
    StaticPopup_Show("PREMADEGROUPSFILTEREXTENSION_RESET_ALL")
end

-- `diagnostics` is tested FIRST (inside DebugVerb), then on/off; anything else toggles the window.
function runDebug(rest)
    local DL = NS.DebugLog
    if not DL then return NS.Print(L["Debug console not ready yet"]) end
    if not DL:DebugVerb(rest) then DL:Toggle() end
end

-- `apply` / `clear`: modules/Apply.lua decides; this only prints its message.
function runApply() NS.Apply.Report(NS.Apply.Run{ search = true }) end
function runClear() NS.Apply.Report(NS.Apply.Clear()) end

function PGFE:SlashEnabled(on) runEnabled(on and true or false) end

function PGFE:OnSlashCommand(input)
    Sl:OnSlash(input)
end
