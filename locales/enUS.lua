local _, NS = ...
-- locales/enUS.lua — NS.L and its metatable fallback; the key IS the English source string.
--
-- Canonical locale (localization-§1). An unknown key answers itself, so a string added to the code
-- before it is added here still renders in English rather than as nil. Input side (localization-§4):
-- game data is matched on stable ids and tokens (cmID, specID, classFile, role tokens), never on a
-- localized display string.

local L = setmetatable({}, {
    __index = function(_, k) return k end,
})
NS.L = L

-- Settings panel and landing page
L["Slash Commands"] = "Slash Commands"
L["Profiles"]       = "Profiles"
L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."] =
    "Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded \226\128\148 your other profiles are not affected."
L["all settings reset to defaults"] = "all settings reset to defaults"

-- Slash command descriptions (NS.COMMANDS)
L["List available commands"] = "List available commands"
L["Open the Ka0s Premade Groups Filter Extension settings panel"] =
    "Open the Ka0s Premade Groups Filter Extension settings panel"
L["Enable the addon"]  = "Enable the addon"
L["Disable the addon"] = "Disable the addon"
L["Print the addon version"] = "Print the addon version"
L["List every setting and its current value"] = "List every setting and its current value"
L["Print a setting's current value — `/pgfe get <path>`"] =
    "Print a setting's current value — `/pgfe get <path>`"
L["Set a setting — `/pgfe set <path> <value>` (try /pgfe list)"] =
    "Set a setting — `/pgfe set <path> <value>` (try /pgfe list)"
L["Reset one setting to its default — `/pgfe reset <path>`"] =
    "Reset one setting to its default — `/pgfe reset <path>`"
L["Reset every setting to defaults"] = "Reset every setting to defaults"
L["List profiles, or switch to one: profile <name>"] =
    "List profiles, or switch to one: profile <name>"
L["Open/close the debug window — `/pgfe debug on|off` toggles logging"] =
    "Open/close the debug window — `/pgfe debug on|off` toggles logging"
L["Write the diagnostics report to the debug console"] =
    "Write the diagnostics report to the debug console"
L["Measure performance — try `/pgfe perf` for the workflow"] =
    "Measure performance — try `/pgfe perf` for the workflow"
L["Apply the filter options to Premade Groups Filter and search"] =
    "Apply the filter options to Premade Groups Filter and search"
L["Remove this addon's block from the Advanced Filter Expression"] =
    "Remove this addon's block from the Advanced Filter Expression"

-- Apply / Clear messages (modules/Apply.lua; the key is a message id, the value its format)
L.MSG_COMBAT       = "Cannot apply in combat."
L.MSG_NO_PGF       = "Premade Groups Filter is missing or changed (%s not found); nothing was applied."
L.MSG_NOT_DUNGEONS = "Open Premade Groups Filter on the Dungeons category first; nothing was applied."
L.MSG_MINIMIZED    = "Maximize the Premade Groups Filter dialog first; nothing was applied."
L.MSG_LOADING      = "Mythic+ season data is still loading; try again in a moment."
L.MSG_ALL_TIMED    = "Every dungeon is already timed at +%d; nothing to target."
L.MSG_BAD_LEVEL    = "Key level must be a whole number from 2 to 40."
L.MSG_BAD_AGE      = "Max age must be a whole number of minutes from 1 to 240."
L.MSG_NO_REGIONS   = "Server regions are on but none is selected for your region."
L.MSG_DAMAGED      = "The [pgfe] block in the Advanced Filter Expression is damaged; fix or delete it by hand."
L.MSG_TOOLONG      = "The Advanced Filter Expression would exceed 2000 characters; nothing was applied."
L.MSG_APPLIED      = "Applied: %d dungeon(s) targeted, key range %s."
L.MSG_CLEARED      = "Removed this addon's block from the Advanced Filter Expression."

-- The attached panel (modules/Panel.lua; the key is a widget id, the value its text)
L.PANEL_TITLE           = "Ka0s PGF Extension"
L.PGF_UNSUPPORTED       = "This Premade Groups Filter version is not supported (%s not found)."
L.KEY_TARGETING         = "Untimed dungeons at key level"
L.READOUT_LOADING       = "Mythic+ season data loading\226\128\166"
L.REGIONS               = "Server regions"
L.REGIONS_UNSUPPORTED   = "Server regions are not available on this region's realms."
L.NO_SAME_SPEC          = "No one with my spec"
L.NO_SAME_CLASSROLE     = "No one with my class + role"
L.EXPERIENCED_LEADER    = "Experienced leader"
L.LEADER_TOOLTIP        = "Only groups whose leader has timed this dungeon at the key level or higher."
L.MAX_AGE               = "Max group age"
L.MINUTES               = "min"
L.PRESET_NONE           = "Presets"
L.PRESET_EMPTY          = "No presets saved"
L.SAVE                  = "Save"
L.SAVE_AS               = "Save as\226\128\166"
L.DELETE                = "Delete"
L.CANCEL                = "Cancel"
L.APPLY                 = "Apply"
L.CLEAR                 = "Clear"
L.RANGE                 = "Range"
L.RANGE_TOOLTIP         = "Ctrl+C, then click the search box and Ctrl+V"
L.PRESET_SAVE_AS_PROMPT = "Save the current filter options as a preset named:"
L.PRESET_DELETE_CONFIRM = "Delete the preset \"%s\"?"
L.PRESET_SAVED          = "Saved preset \"%s\"."
L.PRESET_DELETED        = "Deleted preset \"%s\"."
L.PRESET_BAD_NAME       = "A preset needs a name."

-- Library-absent and diagnostics lines
L["%s is unavailable: the LibKa0s library did not load."] =
    "%s is unavailable: the LibKa0s library did not load."
L["Diagnostic report written to the debug console: %d lines. Use Copy to share it."] =
    "Diagnostic report written to the debug console: %d lines. Use Copy to share it."
