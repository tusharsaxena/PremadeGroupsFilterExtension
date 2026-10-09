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
L.MSG_BAD_SCORE    = "Min leader score must be a whole number from 1 to 5000."
L.MSG_DAMAGED      = "The [pgfe] block in the Advanced Filter Expression is damaged; fix or delete it by hand."
L.MSG_TOOLONG      = "The Advanced Filter Expression would exceed 2000 characters; nothing was applied."
L.MSG_APPLIED      = "Applied: %d dungeon(s) targeted, key range %s."
L.MSG_APPLIED_NO_TARGETING = "Applied (dungeon checkboxes left as they were), key range %s."
L.MSG_CLEARED      = "Removed this addon's block from the Advanced Filter Expression."
L.MSG_INACTIVE     = "PGF Extension filters are toggled off; tick Toggle PGF Extension Filters first."

-- The attached panel (modules/Panel.lua; the key is a widget id, the value its text)
L.PANEL_TITLE           = "Ka0s PGF Extension"
L.PGF_UNSUPPORTED       = "This Premade Groups Filter version is not supported (%s not found)."
L.FILTERS_ACTIVE        = "Toggle PGF Extension Filters"
L.FILTERS_ACTIVE_TOOLTIP = "Off: removes this addon's block from Premade Groups Filter's advanced filter, and Apply does nothing until you tick it again. Your own filter text and the dungeon ticks are left as they are. On: writes the block back from the options below. Also on the settings page; separate from Enable, which turns the whole addon off."
L.COMPOSITION           = "Composition"
L.SHOW_REGION_TAGS      = "Show server regions in the Group Finder"
L.SHOW_REGION_TAGS_TOOLTIP = "Put the group leader's server region (OCE, LA, CHI, ENG, GER, ...) in front of each Group Finder listing, and each applicant's region in front of their name. Does nothing while PremadeRegions is loaded, which shows the same tag."
L.COMPOSITION_TOOLTIP   = "Hide groups that already have someone like you. Pick which from the dropdown; with Any, no group is hidden for its composition."
L.COMPOSITION_SELECT_TOOLTIP = "Tick one or both. Each one hides more groups. Any: no composition filter."
L.KEY_TARGETING         = "Untimed dungeons at key level"
L.KEY_TARGETING_TOOLTIP = "On Apply, tick every season dungeon you haven't timed at the key level and untick the rest. Off: Premade Groups Filter's dungeon checkboxes are left as they are."
L.LEVEL_TOOLTIP         = "The key level to push, a whole number from 2 to 40, kept on Enter. The line below shows your best timed level in each dungeon: gold ones are still untimed at this level."
L.SMART                 = "Smart"
L.SMART_TOOLTIP         = "Let the addon pick the key level: the lowest level at which at least one season dungeon is still untimed (your lowest best timed level + 1). While ticked, the level box is locked and follows your season bests."
L.READOUT_LOADING       = "Mythic+ season data loading\226\128\166"
L.REGIONS               = "Server regions"
L.REGIONS_UNSUPPORTED   = "Not available here"
L.NO_SAME_SPEC          = "No one with my spec"
L.NO_SAME_SPEC_TOOLTIP  = "Hide groups that already have a player with your specialization."
L.NO_SAME_CLASSROLE     = "No one with my class + role"
L.NO_SAME_CLASSROLE_TOOLTIP = "Hide groups that already have a player of your class in your role, whatever their spec."
L.EXPERIENCED_LEADER    = "Experienced leader"
L.LEADER_TOOLTIP        = "Only groups whose leader has timed this dungeon at the key level or higher."
L.MIN_SCORE             = "Min leader M+ score"
L.SCORE_TOOLTIP         = "Only groups whose leader's overall Mythic+ rating is at least this."
L.SCORE_BOX_TOOLTIP     = "The lowest overall Mythic+ rating the group's leader may have, a whole number from 1 to 5000, kept on Enter."
L.REGIONS_TOOLTIP       = "Only groups whose leader plays on a realm in a selected region. Any (none or all selected) lets every region through."
L.REGIONS_SELECT_TOOLTIP = "Pick the server regions to keep. Any means every region."
L.PLAYSTYLE             = "Playstyle"
L.PLAYSTYLE_TOOLTIP     = "Only groups listed with a selected playstyle. Any (none or all selected) lets every playstyle through."
L.PLAYSTYLE_SELECT_TOOLTIP = "Pick the playstyles to keep. Any means every playstyle."
-- One line per server region (modules/Panel.lua, the region menu's entries; keyed by region key)
L.REGION_TIP_OCE        = "Oceanic realms, in the Sydney data center."
L.REGION_TIP_LA         = "US realms in the Los Angeles data center."
L.REGION_TIP_CHI        = "US realms in the Chicago data center."
L.REGION_TIP_MEX        = "The Latin American (Spanish) realms."
L.REGION_TIP_BZL        = "The Brazilian (Portuguese) realms."
L.REGION_TIP_ENG        = "English-language realms."
L.REGION_TIP_GER        = "German-language realms."
L.REGION_TIP_FRA        = "French-language realms."
L.REGION_TIP_ITA        = "Italian-language realms."
L.REGION_TIP_SPA        = "Spanish-language realms."
L.REGION_TIP_POR        = "Portuguese-language realms."
L.REGION_TIP_RUS        = "Russian-language realms."
-- One line per playstyle (the playstyle menu's entries; keyed by PGF's playstyle keyword)
L.PLAYSTYLE_TIP_LEARNING    = "Groups learning the dungeon or the level: expect a slower run with explanations."
L.PLAYSTYLE_TIP_RELAXED     = "Groups that care more about finishing the key than beating the timer."
L.PLAYSTYLE_TIP_COMPETITIVE = "Groups aiming to time the key, who expect you to know the route."
L.PLAYSTYLE_TIP_CARRY       = "Groups offering to carry players through the key."
-- Fallbacks for the game's GROUP_FINDER_GENERAL_PLAYSTYLE1..4 (modules/Panel.lua playstyleLabels)
L.PLAYSTYLE_LEARNING    = "Learning"
L.PLAYSTYLE_RELAXED     = "Relaxed"
L.PLAYSTYLE_COMPETITIVE = "Competitive"
L.PLAYSTYLE_CARRY       = "Carry Offered"
L.SELECT_ANY            = "Any"
L.SELECT_ANY_TOOLTIP    = "No filter: every option passes. Ticking every option means the same."
L.SELECT_COUNT          = "%d selected"
L.MAX_AGE               = "Max group age"
L.MAX_AGE_TOOLTIP       = "Hide listings older than this many minutes."
L.AGE_BOX_TOOLTIP       = "Minutes, a whole number from 1 to 240, kept on Enter."
L.MINUTES               = "min"
L.PRESETS               = "Presets"
L.PRESETS_TOOLTIP       = "Load a saved set of filter options. Presets are shared by all your characters; the options themselves are per character."
L.PRESET_NONE           = "Presets"
L.PRESET_EMPTY          = "No presets saved"
L.SAVE                  = "Save"
L.SAVE_TOOLTIP          = "Overwrite the selected preset with the current filter options."
L.SAVE_AS               = "Save as"
L.SAVE_AS_TOOLTIP       = "Save the current filter options as a preset under a new name (an existing name is overwritten)."
L.DELETE                = "Delete"
L.DELETE_TOOLTIP        = "Delete the selected preset, after confirming."
L.CANCEL                = "Cancel"
L.APPLY                 = "Apply"
L.APPLY_TOOLTIP         = "Set these filters in Premade Groups Filter (its dungeon checkboxes and advanced filter), then search."
L.CLEAR                 = "Clear"
L.CLEAR_TOOLTIP         = "Remove this addon's block from Premade Groups Filter's advanced filter. Your own text and the dungeon checkboxes stay as they are."
L.COPY_SEARCH           = "Copy into search box"
L.COPY_SEARCH_TOOLTIP   = "The game blocks addons from typing into the Group Finder search box, and a listing's title is hidden from addons, so the key level can't be filtered any other way. Copy it yourself: after Apply this text is already selected. Press Ctrl+C, then Enter to jump to the search box, then Ctrl+V and Enter."
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

-- EllesmereUI skin: the gate's four conditions (core/EUIBridge.lua), each a status line and a hint
L["EllesmereUI and its Blizzard Skin module are loaded"] =
    "EllesmereUI and its Blizzard Skin module are loaded"
L["Install and enable EllesmereUI, including EllesmereUI Blizzard Skin."] =
    "Install and enable EllesmereUI, including EllesmereUI Blizzard Skin."
L["EllesmereUI third-party skinning is on"] = "EllesmereUI third-party skinning is on"
L["In EllesmereUI, turn on Blizz UI Enhanced > Blizzard Window Skins > Third-Party Addons > Skin Third-Party Addons."] =
    "In EllesmereUI, turn on Blizz UI Enhanced > Blizzard Window Skins > Third-Party Addons > Skin Third-Party Addons."
L["PremadeGroupsFilterExtension is on in EllesmereUI's Third-Party Addons list"] =
    "PremadeGroupsFilterExtension is on in EllesmereUI's Third-Party Addons list"
L["In EllesmereUI's Third-Party Addons list, turn on PremadeGroupsFilterExtension."] =
    "In EllesmereUI's Third-Party Addons list, turn on PremadeGroupsFilterExtension."
L["Premade Groups Filter's own EllesmereUI skin is on"] = "Premade Groups Filter's own EllesmereUI skin is on"
L["Install and enable Premade Groups Filter - EllesmereUI Skin, and turn on PremadeGroupsFilter in EllesmereUI's Third-Party Addons list."] =
    "Install and enable Premade Groups Filter - EllesmereUI Skin, and turn on PremadeGroupsFilter in EllesmereUI's Third-Party Addons list."
