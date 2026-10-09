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

-- Library-absent and diagnostics lines
L["%s is unavailable: the LibKa0s library did not load."] =
    "%s is unavailable: the LibKa0s library did not load."
L["Diagnostic report written to the debug console: %d lines. Use Copy to share it."] =
    "Diagnostic report written to the debug console: %d lines. Use Copy to share it."
