local _, NS = ...
-- core/PGFBridge.lua — the only file that touches Premade Groups Filter internals.
--
-- Every seam below was read against PGF v7.6.2 (PremadeGroupsFilter.toc:3); citations are
-- <PGF file>:<line> in that version. Each accessor nil-guards, so a PGF rename degrades the feature
-- (Check() names the first missing seam) instead of raising. Every PGF global is read at CALL
-- time, never captured at load. Nothing here writes LFGListFrame.SearchPanel.SearchBox.

local Bridge = NS.Bridge or {}
NS.Bridge = Bridge

-- PGF's private namespace, published as PremadeGroupsFilter.Debug (Init.lua:27).
local function pgf() return PremadeGroupsFilter and PremadeGroupsFilter.Debug end

-- CreateFrame("Frame", "PremadeGroupsFilterDialog", ...) (UI/Dialog.lua:33); fields `panels`,
-- `activeId`, `activeState`, `activePanel` initialized in OnLoad (UI/Dialog.lua:39-42).
function Bridge.GetDialog() return PremadeGroupsFilterDialog end

-- CreateFrame("Frame", "PremadeGroupsFilterDungeonPanel", ...) (UI/DungeonPanel.lua:105),
-- registered for category id "c2f4" (UI/DungeonPanel.lua:451), panel.name = "dungeon"
-- (UI/DungeonPanel.lua:109).
local function panel() return PremadeGroupsFilterDungeonPanel end

-- The dungeon panel's checkbox rows: NUM_DUNGEON_CHECKBOXES = 8 (UI/DungeonPanel.lua:59).
local NUM_DUNGEON_ROWS = 8

--- PGF's spec table, [specID] = { class = "HUNTER", spec = "BEASTMASTERY", ... }
--- (C.SPECIALIZATIONS, Modules/Specializations.lua:25). Read by modules/EnvInject.lua.
--- @return table|nil
function Bridge.Specializations()
    local ns = pgf()
    return ns and ns.C and ns.C.SPECIALIZATIONS
end

--- PGF's keyword row for a challenge-mode map, { "<expansion>", "<dungeon>", "<season>" }
--- (C.MAP_ID_TO_KEYWORDS, Modules/ActivityKeywords.lua:59). Not a checked seam: its only reader
--- falls back to the dungeon name's initials.
--- @return table|nil
function Bridge.MapKeywords(mapID)
    local ns = pgf()
    local t = ns and ns.C and ns.C.MAP_ID_TO_KEYWORDS
    return t and mapID and t[mapID]
end

-- panel.Advanced.Expression.EditBox (UI/Common.lua:144-156).
local function editBox()
    local p = panel()
    return p and p.Advanced and p.Advanced.Expression and p.Advanced.Expression.EditBox
end

-- Structural rows: dialog.panels (UI/Dialog.lua:39), panel.Dungeons (UI/DungeonPanel.xml:81) and the
-- edit box. activeId / activeState are not rows: both are nil until the dialog is first shown.
local SEAMS = {
    { "PremadeGroupsFilter.Debug", function() return pgf() end },
    { "PutPremadeRegionInfo", function() return pgf() and pgf().PutPremadeRegionInfo end },
    { "C.SPECIALIZATIONS", function() return Bridge.Specializations() end },
    { "PremadeGroupsFilterDialog", function() return Bridge.GetDialog() end },
    { "Dialog.panels", function() return Bridge.GetDialog() and Bridge.GetDialog().panels end },
    { "Dialog.RefreshButton", function() return Bridge.GetDialog() and Bridge.GetDialog().RefreshButton end },
    { "PremadeGroupsFilterDungeonPanel", function() return panel() end },
    { "DungeonPanel.Dungeons", function() return panel() and panel().Dungeons end },
    { "DungeonPanel.Advanced.Expression.EditBox", function() return editBox() end },
    { "DungeonPanel.TriggerFilterExpressionChange",
        function() return panel() and panel().TriggerFilterExpressionChange end },
}

--- Every seam this addon needs, present?
--- @return boolean ok
--- @return string|nil missing  the first absent seam's name
function Bridge.Check()
    for _, seam in ipairs(SEAMS) do
        if not seam[2]() then return false, seam[1] end
    end
    return true
end

function Bridge.IsDialogShown()
    local d = Bridge.GetDialog()
    return d ~= nil and d:IsShown() == true
end

-- The active category's panel is `dialog.panels[dialog.activeId]` when maximized
-- (UI/Dialog.lua:191-194; activeId = "c<category>f<filters>", UI/Dialog.lua:181-182). Minimized or
-- not, this answers which category the dialog is ON.
function Bridge.IsDungeonCategory()
    local d, p = Bridge.GetDialog(), panel()
    return d ~= nil and p ~= nil and d.panels ~= nil and d.activeId ~= nil and d.panels[d.activeId] == p
end

--- Is the dungeon panel the dialog's ACTIVE panel? False while minimized: SwitchToPanel then makes
--- `panels.mini` active (UI/Dialog.lua:178-182, 194) and PGF filters with the mini panel's
--- expression (UI/Dialog.lua:244-247), so nothing written to the dungeon state would take effect.
function Bridge.IsDungeonPanelActive()
    local d, p = Bridge.GetDialog(), panel()
    return d ~= nil and p ~= nil and d.activePanel == p
end

-- The dungeon panel's state lives at activeState[panel.name] = activeState.dungeon
-- (UI/Dialog.lua:196); activeState is PremadeGroupsFilterState[activeId] (UI/Dialog.lua:183,
-- 216-224). Created here exactly as SwitchToPanel would, so a write before the panel was ever shown
-- lands in the table PGF will Init from.
function Bridge.GetDungeonState()
    if not Bridge.IsDungeonCategory() then return nil end
    local st = Bridge.GetDialog().activeState
    if type(st) ~= "table" then return nil end
    st.dungeon = st.dungeon or {}
    return st.dungeon
end

--- Tick exactly the rows whose challenge-mode id is in `set` and clear the rest. Rows are
--- positional: row i holds cmId (UI/DungeonPanel.lua:210-211) and its state key is "dungeon"..i
--- (UI/DungeonPanel.lua:168, 252).
--- @param set table  [cmID] = true
--- @return number count  rows set true
function Bridge.SetDungeons(set)
    local st, p, n = Bridge.GetDungeonState(), panel(), 0
    if not st then return 0 end
    for i = 1, NUM_DUNGEON_ROWS do
        local row = p.Dungeons and p.Dungeons["Dungeon" .. i]
        if row and row.cmId then
            local on = set[row.cmId] == true
            st["dungeon" .. i] = on
            if on then n = n + 1 end
        end
    end
    return n
end

--- The dungeon state's Advanced Filter Expression. Clears the edit box's focus first: PGF commits
--- typed text to panel.state.expression only in OnEditFocusLost (UI/Common.lua:153-156).
--- @return string
function Bridge.GetExpression()
    local box = editBox()
    if box and box.HasFocus and box:HasFocus() then box:ClearFocus() end
    local st = Bridge.GetDungeonState()
    return st and st.expression or ""
end

function Bridge.SetExpression(text)
    local st = Bridge.GetDungeonState()
    if st then st.expression = text end
end

--- Push written state into PGF's visible panel. Only when the dungeon panel is the ACTIVE panel
--- (maximized): Init(state) re-reads every checkbox and the edit box (UI/DungeonPanel.lua:217-255),
--- TriggerFilterExpressionChange rebuilds the filter (UI/DungeonPanel.lua:314). Otherwise nothing:
--- SwitchToPanel Inits from the stored state on the next switch (UI/Dialog.lua:190-199).
function Bridge.Commit()
    local d, p = Bridge.GetDialog(), panel()
    if d and p and d.activePanel == p then
        p:Init(p.state)
        p:TriggerFilterExpressionChange()
    end
end

--- Search through PGF's own Refresh button (UI/Dialog.lua:77-78 -> OnRefreshButtonClick ->
--- LFGListSearchPanel_DoSearch, UI/Dialog.lua:147-154). Call only from a hardware-event handler.
function Bridge.Search()
    local d = Bridge.GetDialog()
    if d and d.RefreshButton then d.RefreshButton:Click() end
end

local envHooked = false

--- Post-hook PGF's per-result PutPremadeRegionInfo(env, leaderName). PGF looks it up through its
--- namespace table on every result (Main.lua:363-364), after the member keywords are filled
--- (Main.lua:316), so a hooksecurefunc on the table field is heard. Installed once.
--- @return boolean installed
function Bridge.InstallEnvHook(fn)
    if envHooked then return true end
    local ns = pgf()
    if not (ns and type(ns.PutPremadeRegionInfo) == "function") then return false end
    hooksecurefunc(ns, "PutPremadeRegionInfo", fn)
    envHooked = true
    return true
end

--- Hear the dialog change category, minimize/maximize (both go through SwitchToPanel,
--- UI/Dialog.lua:116-128, 178-188), show or hide.
--- @return boolean hooked
function Bridge.HookDialog(onChange)
    local d = Bridge.GetDialog()
    if not (d and d.SwitchToPanel and d.HookScript) then return false end
    hooksecurefunc(d, "SwitchToPanel", onChange)
    d:HookScript("OnShow", onChange)
    d:HookScript("OnHide", onChange)
    return true
end
