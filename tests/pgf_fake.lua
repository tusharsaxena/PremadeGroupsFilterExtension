-- Minimal stand-in for Premade Groups Filter v7.6.2 — only the seams core/PGFBridge.lua touches.
return function(env)
    local calls = { init = 0, trigger = 0, refresh = 0 }
    local C = {
        MAP_ID_TO_KEYWORDS = { [2993] = { "mn", "aof", "mns2" }, [2825] = { "mn", "don", "mns2" } },
        SPECIALIZATIONS = {
            [253] = { class = "HUNTER", spec = "BEASTMASTERY" },
            [262] = { class = "SHAMAN", spec = "ELEMENTAL" },
        },
    }
    local PGF = { C = C }
    -- Mirrors PGF's own Plugins/PremadeRegions.lua:25-46: every region key reset to false, then
    -- filled from PremadeRegions when that addon is loaded. This addon's hook runs AFTER it.
    local REGION_KEYS = { "oce", "la", "chi", "mex", "bzl", "eng", "ger", "fra", "ita", "spa", "por", "rus" }
    function PGF.PutPremadeRegionInfo(e, leaderName)
        e.region = nil
        for _, k in ipairs(REGION_KEYS) do e[k] = false end
        if leaderName and env.PremadeRegions then
            local region = env.PremadeRegions.GetRegion(leaderName)
            if region then e.region = region; e[region] = true end
        end
    end
    env.PremadeGroupsFilter = { Debug = PGF }

    local panel = { name = "dungeon", Dungeons = {}, state = nil, Advanced = { Expression = { EditBox = {
        focus = false, HasFocus = function(s) return s.focus end, ClearFocus = function(s) s.focus = false end,
    } } } }
    local cmIDs = { 586, 587, 250, 585, 588, 399, 584, 249 }
    for i, id in ipairs(cmIDs) do panel.Dungeons["Dungeon" .. i] = { cmId = id } end
    function panel:Init(state) self.state = state; calls.init = calls.init + 1 end
    function panel:TriggerFilterExpressionChange() calls.trigger = calls.trigger + 1 end
    env.PremadeGroupsFilterDungeonPanel = panel

    local state = { c2f4 = { enabled = true, dungeon = {} } }
    local dialog = { panels = { c2f4 = panel }, activeId = "c2f4", shown = true,
        RefreshButton = { Click = function() calls.refresh = calls.refresh + 1 end } }
    dialog.activeState = state.c2f4
    dialog.activePanel = panel
    panel.state = state.c2f4.dungeon
    function dialog:IsShown() return self.shown end
    function dialog:HookScript() end
    function dialog:SwitchToPanel() end
    env.PremadeGroupsFilterDialog = dialog
    env.PremadeGroupsFilterState = state
    return { calls = calls, dialog = dialog, panel = panel, state = state, PGF = PGF }
end
