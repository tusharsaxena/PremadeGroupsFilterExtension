-- tests/test_panel.lua — NS.Panel (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 8).
--
-- The panel's frames come from tests/wow_mock.lua's PANEL FRAMES: every frame built under PGF's
-- dialog records its anchors, text, checked state and children, so a case reads back what the
-- player would see.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local function seasonFromScreenshot(m)
    m.mapTable = { 586, 587, 250, 585, 588, 399, 584, 249 }
    local best = { [586]=14, [587]=14, [250]=14, [585]=14, [588]=13, [399]=13, [584]=13, [249]=13 }
    for id, lvl in pairs(best) do
        m.mapUIInfo[id] = { name = "D" .. id, mapID = id }
        m.seasonBest[id] = { intime = { level = lvl } }
    end
end

test("panel: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Panel), "table")
end)

test("panel: anchored under PGF dialog, both edges", function()
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create()
    local p1, rel1, rp1, x1, y1 = f:GetPoint(1)
    assertEqual(p1, "TOPLEFT"); assertEqual(rel1, m.PremadeGroupsFilterDialog); assertEqual(rp1, "BOTTOMLEFT")
    local p2, rel2, rp2, x2, y2 = f:GetPoint(2)
    assertEqual(p2, "TOPRIGHT"); assertEqual(rel2, m.PremadeGroupsFilterDialog); assertEqual(rp2, "BOTTOMRIGHT")
    -- Owner request: a 1px gap between the two borders (0 left ~4 units, 5 closed it; 2 was 1px too wide).
    -- red under: anchor at y = 0 or 5
    assertEqual(x1, 0); assertEqual(x2, 0); assertEqual(y1, 3); assertEqual(y2, 3)
    assertEqual(f.__name, "PremadeGroupsFilterExtensionPanel")
    assertEqual(f.__template, "PortraitFrameTemplateMinimizable")
end)

test("panel: Create is idempotent", function()
    local NS = T.enableAddon{}
    assertTrue(NS.Panel.Create() == NS.Panel.Create())
end)

test("panel: visible only for shown dialog on the dungeon category", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create()
    m.pgf.dialog.shown = true; NS.Panel.UpdateVisibility(); assertTrue(NS.Panel.frame:IsShown())
    m.pgf.dialog.activeId = "c3f0"; NS.Panel.UpdateVisibility(); assertFalse(NS.Panel.frame:IsShown())
    m.pgf.dialog.activeId = "c2f4"; m.pgf.dialog.shown = false; NS.Panel.UpdateVisibility()
    assertFalse(NS.Panel.frame:IsShown())
end)

-- Spec §5 / spec-adversary #2: PGF minimized swaps in its mini panel (UI/Dialog.lua:178-182) while
-- activeId stays on Dungeons; the attached panel follows the ACTIVE panel, not the category.
test("panel: hidden while PGF's dialog is minimized", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create()
    NS.Panel.UpdateVisibility(); assertTrue(NS.Panel.frame:IsShown())
    m.pgf.dialog.activePanel = { name = "mini" }
    -- red under: test only IsDungeonCategory in Panel.UpdateVisibility
    NS.Panel.UpdateVisibility(); assertFalse(NS.Panel.frame:IsShown())
    m.pgf.dialog.activePanel = m.pgf.panel
    NS.Panel.UpdateVisibility(); assertTrue(NS.Panel.frame:IsShown())
end)

test("panel: created lazily, on the first UpdateVisibility that wants it", function()
    local NS, _, m = T.enableAddon{}
    m.pgf.dialog.shown = false; NS.Panel.UpdateVisibility()
    assertEqual(NS.Panel.frame, nil)
    m.pgf.dialog.shown = true; NS.Panel.UpdateVisibility()
    assertTrue(NS.Panel.frame ~= nil and NS.Panel.frame:IsShown())
end)

test("panel: the dialog's SwitchToPanel is hooked at load", function()
    local NS, _, m = T.enableAddon{}
    m.pgf.dialog:SwitchToPanel()
    assertTrue(NS.Panel.frame ~= nil and NS.Panel.frame:IsShown())
    m.pgf.dialog.activeId = "c3f0"; m.pgf.dialog:SwitchToPanel()
    assertFalse(NS.Panel.frame:IsShown())
end)

test("panel: hidden when stood down, and the dialog hook is a no-op", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.UpdateVisibility(); assertTrue(NS.Panel.frame:IsShown())
    NS.addon:OnSlashCommand("disable")
    assertFalse(NS.Panel.frame:IsShown())
    m.pgf.dialog:SwitchToPanel(); NS.Panel.UpdateVisibility()
    assertFalse(NS.Panel.frame:IsShown())
    NS.addon:OnSlashCommand("enable")
    assertTrue(NS.Panel.frame:IsShown())
end)

-- Global Constraint (spec-adversary #8): every hook body returns at once when stood down.
test("panel: the dialog hook body returns at once while stood down", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create()
    local calls, real = 0, NS.Panel.UpdateVisibility
    NS.Panel.UpdateVisibility = function() calls = calls + 1; return real() end
    m.pgf.dialog:SwitchToPanel(); assertEqual(calls, 1)
    NS.addon:OnSlashCommand("disable")
    m.pgf.dialog:SwitchToPanel()
    -- red under: drop the stand-down return in the HookDialog callback
    assertEqual(calls, 1)
    NS.Panel.UpdateVisibility = real
end)

-- Run a dropdown's menu generator against a recording root. Every option entry, in order, as
-- { text, isOn, set, data, tooltip }; the Any entry (the first checkbox, no data) as `.any`; and the
-- kinds in build order as `.order` ("any", "divider", "entry").
local function menuEntries(dd)
    local entries = { order = {} }
    local root = {
        CreateCheckbox = function(_, text, isSelected, setSelected, data)
            local e = { text = text, isOn = isSelected, set = setSelected, data = data }
            e.SetTooltip = function(self, fn) self.tooltip = fn end
            if #entries.order == 0 and data == nil then
                entries.any = e; entries.order[1] = "any"
            else
                entries[#entries + 1] = e; entries.order[#entries.order + 1] = "entry"
            end
            return e
        end,
        CreateDivider = function() entries.order[#entries.order + 1] = "divider" end,
    }
    dd.__menuGen(dd, root)
    return entries
end

-- The lines a tooltip fill function writes (a dropdown's or a menu entry's SetTooltip).
local function tipLines(fn)
    local lines = {}
    local tip = { SetText = function(_, t) lines[#lines + 1] = t end, AddLine = function(_, t) lines[#lines + 1] = t end }
    fn(tip)
    return lines
end

-- The lines GameTooltip receives while `widget` is hovered.
local function hoverLines(m, widget)
    local lines = {}
    m.GameTooltip.SetText = function(_, t) lines[#lines + 1] = t end
    m.GameTooltip.AddLine = function(_, t) lines[#lines + 1] = t end
    widget:__fire("OnEnter")
    return lines
end

test("panel: the region dropdown lists this portal's regions", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 3
    NS.Panel.Create(); NS.Panel.Refresh()
    local entries = menuEntries(NS.Panel.frame.regionSelect)
    assertEqual(#entries, 7)
    assertEqual(entries[1].text, "ENG"); assertEqual(entries[1].data, "eng")
    assertTrue(NS.Panel.frame.regionSelect:IsShown())
    assertFalse(NS.Panel.frame.regionsUnsupported:IsShown())
end)

-- Owner request: a dropdown of checkboxes replaces the region chip buttons.
test("panel: ticking a region writes it and keeps the menu open; the button sums up", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 1
    m.MenuResponse = { Refresh = 2 }
    NS.Panel.Create(); NS.Panel.Refresh()
    local dd = NS.Panel.frame.regionSelect
    assertEqual(dd:GetText(), NS.L.SELECT_ANY)
    local oce, chi = menuEntries(dd)[1], menuEntries(dd)[3]
    assertFalse(oce.isOn(oce.data))
    assertEqual(oce.set(oce.data), 2, "the menu stays open for the next tick")
    assertTrue(NS.Filters.Get().regions.oce); assertTrue(oce.isOn(oce.data))
    chi.set(chi.data)
    assertEqual(dd:GetText(), "OCE, CHI")
    oce.set(oce.data)
    assertEqual(NS.Filters.Get().regions.oce, nil)
    assertEqual(dd:GetText(), "CHI")
end)

test("panel: a long selection is summed up as a count", function()
    local NS = T.enableAddon{}
    NS.Panel.Create()
    local f = NS.Filters.Get()
    f.playstyles = { relaxed = true, competitive = true, carry = true }
    NS.Panel.Refresh()
    assertEqual(NS.Panel.frame.playstyleSelect:GetText(), NS.L.SELECT_COUNT:format(3))
end)

test("panel: unsupported portal shows the note instead of the region dropdown", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 2
    NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(#menuEntries(NS.Panel.frame.regionSelect), 0)
    assertFalse(NS.Panel.frame.regionSelect:IsShown())
    assertTrue(NS.Panel.frame.regionsUnsupported:IsShown())
    assertEqual(NS.Panel.frame.regionsUnsupported:GetText(), NS.L.REGIONS_UNSUPPORTED)
end)

test("panel: the playstyle dropdown uses the game's names and writes the playstyles", function()
    local NS, _, m = T.enableAddon{}
    m.GROUP_FINDER_GENERAL_PLAYSTYLE4 = "Carry Offered (game)"
    NS.Panel.Create(); NS.Panel.Refresh()
    local entries = menuEntries(NS.Panel.frame.playstyleSelect)
    assertEqual(#entries, 4)
    assertEqual(entries[1].text, NS.L.PLAYSTYLE_LEARNING, "fallback when the global is absent")
    assertEqual(entries[4].text, "Carry Offered (game)")
    entries[2].set(entries[2].data)
    assertTrue(NS.Filters.Get().playstyles.relaxed)
    assertEqual(NS.Panel.frame.playstyleSelect:GetText(), NS.L.PLAYSTYLE_RELAXED)
    local cb = NS.Panel.frame.checks.playstyleEnabled
    cb:SetChecked(true); cb:__fire("OnClick")
    assertTrue(NS.Filters.Get().playstyleEnabled)
end)

test("panel: a tick while stood down writes nothing", function()
    local NS = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    NS.addon:OnSlashCommand("disable")
    local e = menuEntries(NS.Panel.frame.playstyleSelect)[1]
    e.set(e.data)
    assertEqual(NS.Filters.Get().playstyles.learning, nil)
end)

test("panel: range field shows N-N for the current level", function()
    local NS = T.enableAddon{}
    NS.Filters.Get().keyLevel = 14
    NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(NS.Panel.frame.rangeBox:GetText(), "14-14")
end)

test("panel: typing into the range field puts the range back", function()
    local NS = T.enableAddon{}
    NS.Filters.Get().keyLevel = 12
    NS.Panel.Create(); NS.Panel.Refresh()
    local box = NS.Panel.frame.rangeBox
    box.__text = "junk"; box:__fire("OnTextChanged", true)
    assertEqual(box:GetText(), "12-12")
end)

-- Keystroke by keystroke, as the client fires OnTextChanged(userInput = true) per character.
local function typeInto(box, text)
    for i = 1, #text do box.__text = text:sub(1, i); box:__fire("OnTextChanged", true) end
end

-- Review F-003: a box that saved on every keystroke stored `4` while the player typed `45`.
test("panel: a level commits on Enter / focus loss, never per keystroke", function()
    local NS = T.enableAddon{}
    NS.Filters.Get().smartKeyLevel = false -- a manually set level
    NS.Panel.Create(); NS.Panel.Refresh()
    local box = NS.Panel.frame.levelBox
    typeInto(box, "15")
    -- red under: commit from OnTextChanged in Panel's numberBox
    assertEqual(NS.Filters.Get().keyLevel, 10, "nothing stored mid-typing")
    box:__fire("OnEnterPressed")
    assertEqual(NS.Filters.Get().keyLevel, 15)
    assertEqual(NS.Panel.frame.rangeBox:GetText(), "15-15")
    typeInto(box, "45")
    box:__fire("OnEditFocusLost")
    assertEqual(NS.Filters.Get().keyLevel, 15, "45 is out of range")
    -- red under: drop the re-sync on a rejected value
    assertEqual(box:GetText(), "15", "the box never shows a value that is not stored")
    box.__text = ""; box:__fire("OnEditFocusLost")
    assertEqual(NS.Filters.Get().keyLevel, 15); assertEqual(box:GetText(), "15")
    typeInto(box, "9"); box:__fire("OnEscapePressed")
    assertEqual(NS.Filters.Get().keyLevel, 15); assertEqual(box:GetText(), "15")
end)

test("panel: the age box commits whole values and re-syncs a rejected one", function()
    local NS = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    local box = NS.Panel.frame.ageBox
    typeInto(box, "30")
    assertEqual(NS.Filters.Get().maxAge, 15, "nothing stored mid-typing")
    box:__fire("OnEditFocusLost")
    assertEqual(NS.Filters.Get().maxAge, 30)
    typeInto(box, "999"); box:__fire("OnEnterPressed")
    assertEqual(NS.Filters.Get().maxAge, 30); assertEqual(box:GetText(), "30")
end)

test("panel: readout highlights targeted dungeons, grays the rest", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().keyLevel = 14
    NS.Panel.Create(); NS.Panel.Refresh()
    local text = NS.Panel.frame.readout:GetText()
    assertTrue(text:find("|cffffd100D 13|r", 1, true) ~= nil, text)
    assertTrue(text:find("|cff808080D 14|r", 1, true) ~= nil, text)
end)

test("panel: readout says loading until the season data arrives", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(NS.Panel.frame.readout:GetText(), NS.L.READOUT_LOADING)
    seasonFromScreenshot(m)
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    assertTrue(NS.Panel.frame.readout:GetText() ~= NS.L.READOUT_LOADING)
end)

-- C-06 / C-07: the season-data request goes out once per episode, from Season.GetDungeons (spec
-- section 4, the state machine), never once per CHALLENGE_MODE_MAPS_UPDATE round trip.
test("panel: an empty map table asks the server once, not every round trip", function()
    local NS, _, m = T.enableAddon{ mapTable = {} }
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    m.fireEvent("CHALLENGE_MODE_COMPLETED")
    typeInto(f.levelBox, "12"); f.levelBox:__fire("OnEnterPressed")
    -- red under: drop the request guard
    assertEqual(m.mapInfoRequests, 1)
    assertEqual(f.readout:GetText(), NS.L.READOUT_LOADING)
end)

test("panel: a populated map table still requests once", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Panel.Create(); NS.Panel.Refresh(); NS.Panel.Refresh()
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    m.fireEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
    -- red under: request only when GetDungeons is nil
    assertEqual(m.mapInfoRequests, 1)
end)

test("panel: a rollover re-arms the request once, not once per event", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Panel.Create(); NS.Panel.Refresh()
    local before = m.mapInfoRequests
    m.mapTable = {}
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    -- red under: leave lastFull set on reset
    assertEqual(m.mapInfoRequests, before + 1)
end)

test("panel: one event after a rollover already sends the re-armed request", function()
    local NS, _, m = T.enableAddon{}
    -- Smart off, so the event makes exactly one season read (the readout's), not two.
    NS.Filters.Get().smartKeyLevel = false
    seasonFromScreenshot(m)
    NS.Panel.Create(); NS.Panel.Refresh()
    local before = m.mapInfoRequests
    m.mapTable = {}
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    -- red under: ResetRequest without the RequestOnce after it
    assertEqual(m.mapInfoRequests, before + 1)
end)

test("panel: PLAYER_ENTERING_WORLD re-arms the request", function()
    local NS, _, m = T.enableAddon{ mapTable = {} }
    NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(m.mapInfoRequests, 1)
    m.fireEvent("PLAYER_ENTERING_WORLD")
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    -- red under: drop the ResetRequest from OnPanelEnteringWorld
    assertEqual(m.mapInfoRequests, 2)
end)

test("panel: the affix event recomputes Smart and leaves loading", function()
    local NS, _, m = T.enableAddon{}
    NS.Filters.Get().smartKeyLevel = true
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(f.readout:GetText(), NS.L.READOUT_LOADING)
    seasonFromScreenshot(m)
    m.fireEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
    -- red under: drop the AFFIX FEATURE_EVENTS row
    assertEqual(NS.Filters.Get().keyLevel, 14)
    assertEqual(f.levelBox:GetText(), "14")
    assertTrue(f.readout:GetText() ~= NS.L.READOUT_LOADING)
end)

test("panel: checkboxes write their filter option", function()
    local NS = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    local cb = NS.Panel.frame.checks.experiencedLeader
    assertFalse(cb:GetChecked())
    cb:SetChecked(true); cb:__fire("OnClick")
    assertTrue(NS.Filters.Get().experiencedLeader)
end)

test("panel: Refresh re-reads the filters into the widgets", function()
    local NS = T.enableAddon{}
    NS.Panel.Create()
    local f = NS.Filters.Get(); f.experiencedLeader = true; f.maxAge = 30; f.keyLevel = 9
    NS.Panel.Refresh()
    assertTrue(NS.Panel.frame.checks.experiencedLeader:GetChecked())
    assertEqual(NS.Panel.frame.ageBox:GetText(), "30")
    assertEqual(NS.Panel.frame.levelBox:GetText(), "9")
end)

test("panel: Apply searches and prints; the range field follows", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().keyLevel = 14
    NS.Panel.Create(); NS.Panel.Refresh()
    NS.Panel.frame.applyButton:__fire("OnClick")
    assertEqual(m.pgf.calls.refresh, 1)
    assertEqual(NS.Panel.frame.rangeBox:GetText(), "14-14")
    assertTrue(#m.prints > 0)
end)

-- Review F-008: after an Apply the range field kept the applied range instead of the level box's.
test("panel: after an Apply the range field still follows the level", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().smartKeyLevel = false -- a manually set level
    NS.Filters.Get().keyLevel = 14
    NS.Panel.Create(); NS.Panel.Refresh()
    NS.Panel.frame.applyButton:__fire("OnClick")
    local box = NS.Panel.frame.levelBox
    box.__text = "15"; box:__fire("OnEnterPressed")
    -- red under: prefer Apply.LastRange in Panel's rangeText
    assertEqual(NS.Panel.frame.rangeBox:GetText(), "15-15")
end)

test("panel: Apply does nothing while stood down", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Panel.Create()
    NS.addon:OnSlashCommand("disable")
    NS.Panel.frame.applyButton:__fire("OnClick")
    assertEqual(m.pgf.calls.refresh, 0)
end)

test("panel: a missing PGF seam shows one line and disables Apply", function()
    local NS, _, m = T.enableAddon{}
    m.pgf.dialog.RefreshButton = nil
    NS.Panel.Create(); NS.Panel.Refresh()
    assertTrue(NS.Panel.frame.unsupported:IsShown())
    assertEqual(NS.Panel.frame.unsupported:GetText(), NS.L.PGF_UNSUPPORTED:format("Dialog.RefreshButton"))
    assertFalse(NS.Panel.frame.body:IsShown())
    assertFalse(NS.Panel.frame.applyButton:IsEnabled())
end)

test("panel: collapse folds to the title bar and is remembered in the profile", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    f.MaximizeMinimizeFrame.__onMinimized()
    assertTrue(NS.addon.db.profile.panelCollapsed)
    assertFalse(f.body:IsShown())
    assertEqual(f.__height, 32)
    f.MaximizeMinimizeFrame.__onMaximized()
    assertFalse(NS.addon.db.profile.panelCollapsed)
    assertTrue(f.body:IsShown())
    assertTrue(f.__height > 32)
end)

-- Review F-010: a profile switch carries its own panelCollapsed; the attached panel follows it.
test("panel: a profile switch refreshes the attached panel's layout", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    assertTrue(f.body:IsShown())
    NS.addon.db.profile.panelCollapsed = true
    NS.addon:OnProfileChanged(nil, nil, "Other")
    -- red under: drop the Panel.Refresh call in PGFE's reloadProfile
    assertFalse(f.body:IsShown()); assertEqual(f.__height, 32)
end)

test("panel: preset Save as stores a named preset; Load refills the widgets", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    NS.Filters.Get().keyLevel = 18
    local dlg = m.StaticPopupDialogs.PGFE_PRESET_SAVE_AS
    assertTrue(dlg ~= nil and dlg.hasEditBox)
    dlg.OnAccept({ EditBox = { GetText = function() return "Push" end } })
    assertEqual(NS.Presets.List()[1], "Push")
    NS.Filters.Get().keyLevel = 5
    NS.Panel.SelectPreset("Push")
    assertEqual(NS.Filters.Get().keyLevel, 18)
    assertEqual(NS.Panel.frame.levelBox:GetText(), "18")
end)

test("panel: preset Delete removes the selected preset after confirming", function()
    local NS, _, m = T.enableAddon{}
    NS.Presets.Save("Old")
    NS.Panel.Create(); NS.Panel.Refresh()
    NS.Panel.SelectPreset("Old")
    m.StaticPopupDialogs.PGFE_PRESET_DELETE.OnAccept({}, "Old")
    assertEqual(#NS.Presets.List(), 0)
end)

test("panel: Enter in the Save as box saves and closes the popup", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create()
    m.StaticPopupDialogs.PGFE_PRESET_SAVE_AS.EditBoxOnEnterPressed({ GetText = function() return " Farm " end })
    assertEqual(NS.Presets.List()[1], "Farm")
    assertEqual(m.popupsHidden[1], "PGFE_PRESET_SAVE_AS")
end)

test("panel: a blank preset name is refused", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create()
    m.StaticPopupDialogs.PGFE_PRESET_SAVE_AS.OnAccept({ EditBox = { GetText = function() return "  " end } })
    assertEqual(#NS.Presets.List(), 0)
end)

-- Owner report (screenshot): the level box sat at a fixed x and covered the end of its label.
test("panel: each number box is anchored to the right of its own label", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    for _, box in ipairs({ f.levelBox, f.ageBox }) do
        local point, rel, relPoint, x = box:GetPoint(1)
        -- red under: a fixed TOPLEFT x offset in Panel's numberBox
        assertEqual(point, "LEFT"); assertEqual(relPoint, "RIGHT"); assertTrue(x > 0)
        assertTrue(type(rel) == "table" and rel ~= f.body, "anchored to a label, not the body")
    end
end)

test("panel: the expanded height fits every row", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    -- One 26px pitch for every row: 26 + 8 toggle, 52 key + readout, 26 regions, 26 playstyle,
    -- 26 composition, 26 leader, 26 score, 26 age, 26 presets, 8 + 26 actions, plus the 28 title
    -- offset and the 12 bottom margin.
    assertEqual(f.__height, 318)
end)

-- Owner report (screenshots): the arrow showed maximize while expanded. PGF's convention
-- (UI/Dialog.lua MaximizeMinimize): expanded shows the minimize arrow, collapsed the maximize one.
test("panel: the min/max arrow follows the stored collapsed state", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    local mm = f.MaximizeMinimizeFrame
    local look
    mm.SetMinimizedLook = function() look = "minimize" end
    mm.SetMaximizedLook = function() look = "maximize" end
    NS.Panel.Refresh(); assertEqual(look, "minimize"); assertFalse(mm.isMinimized)
    mm.__onMinimized(); assertEqual(look, "maximize"); assertTrue(mm.isMinimized)
    mm.__onMaximized(); assertEqual(look, "minimize")
    NS.addon.db.profile.panelCollapsed = true
    NS.addon:OnProfileChanged(nil, nil, "Other")
    -- red under: drop syncMinMax from Panel's applyLayout
    assertEqual(look, "maximize")
    -- Stood down, a click must not change the state; the arrow is put back to match it.
    NS.addon:OnSlashCommand("disable")
    mm.__onMaximized(); assertEqual(look, "maximize")
    assertTrue(NS.addon.db.profile.panelCollapsed)
end)

-- Owner request: collapsed shows only the header strip. NineSliceUtil is the client's; the stub
-- below stands in for it so the clipped border copies are built.
local function stubNineSlice(m)
    local applied = 0
    m.NineSliceUtil = { GetLayout = function() return {} end, ApplyLayout = function() applied = applied + 1 end }
    return function() return applied end
end

test("panel: collapsed shows only the header strip, drawn by two clipped border copies", function()
    local NS, _, m = T.enableAddon{}
    local applied = stubNineSlice(m)
    local f = NS.Panel.Create()
    assertEqual(applied(), 2, "a top copy and a foot copy")
    assertEqual(#f.headerArt, 2)
    f.MaximizeMinimizeFrame.__onMinimized()
    -- red under: restore the corners-apart height (88) in Panel's applyLayout
    assertEqual(f.__height, 32)
    -- red under: drop setHeaderOnly from Panel's applyLayout
    assertTrue(f.headerArt[1]:IsShown()); assertTrue(f.headerArt[2]:IsShown())
    assertFalse(f.NineSlice:IsShown())
    assertFalse(f.body:IsShown())
end)

test("panel: expanded keeps the template's own border; the header copies hide", function()
    local NS, _, m = T.enableAddon{}
    stubNineSlice(m)
    local f = NS.Panel.Create()
    f.MaximizeMinimizeFrame.__onMinimized()
    f.MaximizeMinimizeFrame.__onMaximized()
    assertEqual(f.__height, f.expandedHeight)
    assertFalse(f.headerArt[1]:IsShown()); assertFalse(f.headerArt[2]:IsShown())
    assertTrue(f.NineSlice:IsShown())
    assertTrue(f.body:IsShown())
end)

test("panel: a saved collapsed state shows the header strip on the first Refresh", function()
    local NS, _, m = T.enableAddon{}
    stubNineSlice(m)
    NS.addon.db.profile.panelCollapsed = true
    local f = NS.Panel.Create()
    assertEqual(f.__height, 32)
    assertTrue(f.headerArt[1]:IsShown()); assertTrue(f.headerArt[2]:IsShown())
    assertFalse(f.NineSlice:IsShown())
end)

test("panel: without NineSliceUtil the collapse still folds, with no header copies", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    f.MaximizeMinimizeFrame.__onMinimized()
    assertEqual(f.headerArt, nil)
    assertEqual(f.__height, 32)
    assertTrue(f.NineSlice:IsShown(), "left alone when there is nothing to stand in for it")
end)

-- Review: the header copies sat one level above the panel, tied with the arrow and close button.
test("panel: the header copies sit at the panel's own level, under the arrow", function()
    local NS, _, m = T.enableAddon{}
    stubNineSlice(m)
    local create, levels = m.CreateFrame, {}
    m.CreateFrame = function(...)
        local fr = create(...)
        fr.GetFrameLevel = function() return 7 end
        fr.SetFrameLevel = function(self, l) levels[self] = l end
        return fr
    end
    local f = NS.Panel.Create()
    m.CreateFrame = create
    for i, clip in ipairs(f.headerArt) do
        -- red under: drop sinkToParentLevel from Panel's buildHeaderHalf
        assertEqual(levels[clip], 7, "clip " .. i)
        assertEqual(levels[clip.__children[1]], 7, "slice " .. i)
    end
end)

-- Owner request: Apply no longer takes keyboard focus into the copy box (it held movement and chat).
test("panel: Apply leaves focus alone; Enter in the copy box focuses the search box", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().smartKeyLevel = false -- a manually set level
    NS.Filters.Get().keyLevel = 14
    local searchFocused = 0
    m.LFGListFrame = { SearchPanel = { SearchBox = {
        IsVisible = function() return true end,
        SetFocus = function() searchFocused = searchFocused + 1 end,
    } } }
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local rangeFocused = 0
    f.rangeBox.SetFocus = function() rangeFocused = rangeFocused + 1 end
    f.applyButton:__fire("OnClick")
    assertEqual(m.pgf.calls.refresh, 1, "the Apply ran")
    -- red under: restore the rangeBox:SetFocus() in Panel's Apply OnClick
    assertEqual(rangeFocused, 0)
    f.rangeBox:__fire("OnEnterPressed")
    assertEqual(searchFocused, 1)
    -- Stood down, Enter does not reach for Blizzard's box.
    NS.addon:OnSlashCommand("disable")
    f.rangeBox:__fire("OnEnterPressed")
    assertEqual(searchFocused, 1)
end)

-- ── owner feedback round: arrow art, Any, widths, row pitch, tooltips, presets, copy box, Smart ────

-- Owner request (screenshots): expanded shows the up-right arrow, collapsed the down-left one. The
-- template pairs them the other way, so the art is swapped between its two buttons.
test("panel: the arrow art is swapped between the min/max buttons", function()
    local NS = T.enableAddon{}
    local mm = NS.Panel.Create().MaximizeMinimizeFrame
    -- red under: drop the setArrowArt calls from Panel's buildMinMax
    assertEqual(mm.MinimizeButton.__normalAtlas, "RedButton-Expand")
    assertEqual(mm.MinimizeButton.__pushedAtlas, "RedButton-Expand-Pressed")
    assertEqual(mm.MinimizeButton.__disabledAtlas, "RedButton-Expand-Disabled")
    assertEqual(mm.MaximizeButton.__normalAtlas, "RedButton-Condense")
    assertEqual(mm.MaximizeButton.__pushedAtlas, "RedButton-Condense-Pressed")
    assertEqual(mm.MaximizeButton.__disabledAtlas, "RedButton-Condense-disabled")
end)

test("panel: the regions and playstyle dropdowns are 225 wide, right-aligned in one column", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect }) do
        -- red under: the old 150
        assertEqual(dd.__width, 225)
        local point, _, _, x = dd:GetPoint(1)
        assertEqual(point, "TOPRIGHT"); assertEqual(x, 0)
    end
end)

test("panel: each menu opens with Any and a divider; Any is ticked with nothing ticked and clears", function()
    local NS, _, m = T.enableAddon{}
    m.MenuResponse = { Refresh = 2 }
    NS.Panel.Create(); NS.Panel.Refresh()
    for _, dd in ipairs({ NS.Panel.frame.regionSelect, NS.Panel.frame.playstyleSelect }) do
        local e = menuEntries(dd)
        assertEqual(e.order[1], "any"); assertEqual(e.order[2], "divider")
        assertEqual(e.any.text, NS.L.SELECT_ANY)
        assertTrue(e.any.isOn())
        e[1].set(e[1].data)
        assertFalse(e.any.isOn()); assertTrue(e[1].isOn(e[1].data))
        assertEqual(e.any.set(), 2, "the menu stays open")
        assertTrue(e.any.isOn()); assertFalse(e[1].isOn(e[1].data))
        assertEqual(dd:GetText(), NS.L.SELECT_ANY)
    end
    assertEqual(next(NS.Filters.Get().playstyles), nil)
    assertEqual(next(NS.Filters.Get().regions), nil)
end)

-- Owner request: every option ticked means Any.
test("panel: ticking every option stores Any and the button reads Any", function()
    local NS = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    local dd = NS.Panel.frame.playstyleSelect
    local e = menuEntries(dd)
    for i = 1, #e do e[i].set(e[i].data) end
    -- red under: drop the isFull clear after the toggle in Filters' toggleIn
    assertEqual(next(NS.Filters.Get().playstyles), nil, "the full set is stored as Any")
    assertEqual(dd:GetText(), NS.L.SELECT_ANY)
    assertTrue(e.any.isOn())
    local r = menuEntries(NS.Panel.frame.regionSelect)
    for i = 1, #r do r[i].set(r[i].data) end
    assertEqual(#NS.Filters.SelectedRegions("US"), 0)
    assertEqual(NS.Panel.frame.regionSelect:GetText(), NS.L.SELECT_ANY)
end)

test("panel: a stored all-ticked set reads Any; a tick then selects that option alone", function()
    local NS = T.enableAddon{}
    NS.Panel.Create()
    NS.Filters.Get().playstyles = { learning = true, relaxed = true, competitive = true, carry = true }
    NS.Panel.Refresh()
    local dd = NS.Panel.frame.playstyleSelect
    -- red under: summarize only an empty selection as Any in Panel's selectionSummary
    assertEqual(dd:GetText(), NS.L.SELECT_ANY)
    local e = menuEntries(dd)
    assertTrue(e.any.isOn()); assertFalse(e[2].isOn(e[2].data))
    e[2].set(e[2].data)
    assertEqual(table.concat(NS.Filters.SelectedPlaystyles(), ","), "relaxed")
    assertEqual(dd:GetText(), NS.L.PLAYSTYLE_RELAXED)
end)

-- Owner report (screenshot): the readout sat a full extra gap above the Server regions row.
test("panel: the readout is one row high, so the rows below keep the same pitch", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    -- red under: the old 23px rows under 26px dropdown rows
    assertEqual(f.readout.__height, 26)
    local _, _, _, _, y = f.regionSelect:GetPoint(1)
    assertEqual(y, -(26 + 8 + 26 + 26 - 6), "the toggle and its gap, the level row and the readout (pulled up 6)")
end)

-- Review: one line with no wrap, so a season of long names must close up rather than be cut off.
test("panel: a readout too wide for its row closes the gaps to one space", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Panel.Create()
    local readout = NS.Panel.frame.readout
    -- The mock measures 6px a byte, color codes included: 8 parts of 16 bytes ("|cff808080D 14|r"), 7 gaps.
    readout:__setGeom((8 * 16 + 7) * 6, 23)
    NS.Panel.Refresh()
    -- red under: drop the width check in Panel's updateReadout
    assertEqual(#readout:GetText(), 8 * 16 + 7)
    readout:__setGeom((8 * 16 + 14) * 6, 23)
    NS.Panel.Refresh()
    assertEqual(#readout:GetText(), 8 * 16 + 14, "two spaces while they fit")
end)

local function isLocaleString(s) return type(s) == "string" and s:match("^[%u_]+$") == nil end

-- Owner report: Untimed dungeons (and other rows) had no tooltip.
test("panel: every checkbox has a tooltip, and its label hovers and clicks as the box", function()
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create()
    local n = 0
    for key, cb in pairs(f.checks) do
        n = n + 1
        local lines = hoverLines(m, cb)
        assertEqual(#lines, 2, key .. ": a title and a description")
        assertTrue(isLocaleString(lines[2]), key .. ": a locale string, not a missing key")
        -- red under: drop stretchHitRect from Panel's checkRow
        assertTrue(cb.__hitRect ~= nil and cb.__hitRect[2] < 0, key .. ": stretched over the label")
    end
    assertEqual(n, 7)
    -- The label starts LABEL_X - 32 = 3px past the box; the rect reaches the label's far end.
    assertEqual(f.checks.compositionEnabled.__hitRect[2], -(3 + #NS.L.COMPOSITION * 6))
end)

test("panel: every number box, button and the copy box and its label have a tooltip", function()
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create()
    local widgets = { f.levelBox, f.ageBox, f.saveButton, f.saveAsButton, f.deleteButton,
        f.applyButton, f.clearButton, f.rangeBox, f.copyLabelHover }
    for i, w in ipairs(widgets) do
        local lines = hoverLines(m, w)
        assertEqual(#lines, 2, "widget " .. i)
        assertTrue(isLocaleString(lines[2]), "widget " .. i)
    end
    assertEqual(hoverLines(m, f.copyLabelHover)[2], NS.L.COPY_SEARCH_TOOLTIP)
    assertEqual(hoverLines(m, f.levelBox)[1], NS.L.KEY_TARGETING)
end)

test("panel: each dropdown and every menu entry has a tooltip", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 1
    local f = NS.Panel.Create()
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect, f.presetDropdown }) do
        assertEqual(#tipLines(dd.__tooltip), 2)
    end
    local regions = menuEntries(f.regionSelect)
    assertEqual(tipLines(regions.any.tooltip)[2], NS.L.SELECT_ANY_TOOLTIP)
    assertEqual(tipLines(regions[1].tooltip)[1], "OCE")
    assertEqual(tipLines(regions[1].tooltip)[2], "Oceanic realms, in the Sydney data center.")
    for _, e in ipairs(regions) do assertTrue(isLocaleString(tipLines(e.tooltip)[2]), e.data) end
    for _, e in ipairs(menuEntries(f.playstyleSelect)) do assertTrue(isLocaleString(tipLines(e.tooltip)[2]), e.data) end
    -- Every region of both portals has its line.
    for _, keys in pairs(NS.Regions.KEYS) do
        for _, key in ipairs(keys) do assertTrue(isLocaleString(NS.L["REGION_TIP_" .. key:upper()]), key) end
    end
end)

test("panel: tooltips stay quiet while stood down", function()
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create()
    NS.addon:OnSlashCommand("disable")
    -- red under: drop the stand-down return in Panel's tooltip
    assertEqual(#hoverLines(m, f.checks.keyTargeting), 0)
    assertEqual(#tipLines(f.regionSelect.__tooltip), 0)
end)

local function hasText(parent, text)
    for _, child in ipairs(parent.__children or {}) do
        if child.__text == text then return true end
    end
    return false
end

-- Owner request: Save / Save as / Delete at one width that fits their text, all on the dropdown's
-- row; the dropdown gives up width to make them fit.
test("panel: presets: one row, the dropdown up to three equal buttons right-aligned", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    assertFalse(hasText(f.body, NS.L.PRESETS), "no separate Presets label")
    local _, _, _, ddX, ddY = f.presetDropdown:GetPoint(1)
    assertEqual(ddX, 4)
    -- red under: the two-row layout (dropdown TOPRIGHT, its own width)
    local dp, drel, drp = f.presetDropdown:GetPoint(2)
    assertEqual(dp, "RIGHT"); assertTrue(drel == f.saveButton); assertEqual(drp, "LEFT")
    local row = { f.saveButton, f.saveAsButton, f.deleteButton }
    local widest = 0
    for _, b in ipairs(row) do widest = math.max(widest, b:GetTextWidth()) end
    for _, b in ipairs(row) do assertEqual(b.__width, math.max(64, widest + 20)) end
    local p, _, _, x, y = f.deleteButton:GetPoint(1)
    assertEqual(p, "TOPRIGHT"); assertEqual(x, 0); assertEqual(y, ddY)
    local p2, rel2, rp2 = f.saveAsButton:GetPoint(1)
    assertEqual(p2, "RIGHT"); assertTrue(rel2 == f.deleteButton); assertEqual(rp2, "LEFT")
    local p3, rel3 = f.saveButton:GetPoint(1)
    assertEqual(p3, "RIGHT"); assertTrue(rel3 == f.saveAsButton)
end)

test("panel: Apply and Clear share one width, with extra space above their row", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    assertEqual(f.applyButton.__width, f.clearButton.__width)
    assertTrue(f.applyButton.__width >= 88)
    local _, _, _, _, presetButtonsY = f.deleteButton:GetPoint(1)
    local _, _, _, _, applyY = f.applyButton:GetPoint(1)
    -- red under: drop ACTION_GAP from Panel's buildActionRow
    assertEqual(presetButtonsY - applyY, 26 + 8)
end)

-- Owner request: the range box moves to the right end of the action row, as "Copy into search box".
test("panel: the copy box is right-aligned on the action row, its label before it, clear of Clear", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    local p, _, _, x, y = f.rangeBox:GetPoint(1)
    local _, _, _, _, applyY = f.applyButton:GetPoint(1)
    assertEqual(p, "TOPRIGHT"); assertEqual(x, 0); assertEqual(y, applyY - 1)
    assertEqual(f.copyLabel:GetText(), "Copy into search box")
    local lp, rel, rp, lx = f.copyLabel:GetPoint(1)
    assertEqual(lp, "RIGHT"); assertTrue(rel == f.rangeBox); assertEqual(rp, "LEFT")
    -- In the 398px body: the label's left edge stays right of Clear's right edge.
    local clearRight = 4 + f.applyButton.__width + 4 + f.clearButton.__width
    assertTrue(398 - 56 + lx - f.copyLabel:GetStringWidth() > clearRight)
end)

-- Owner request: a Smart checkbox right of the level box; the addon picks the level.
test("panel: Smart sits right of the level box; ticked, it locks the box and sets the level", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m) -- lowest best timed 13, so Smart picks 14
    NS.Filters.Get().smartKeyLevel = false -- a manually set level
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local cb = f.checks.smartKeyLevel
    local p, rel, rp, x = cb:GetPoint(1)
    assertEqual(p, "LEFT"); assertTrue(rel == f.levelBox); assertEqual(rp, "RIGHT")
    -- Owner request: Smart a bit further right, so the row is less crowded.
    -- red under: the old BUTTON_GAP (4)
    assertEqual(x, 16)
    assertEqual(f.smartLabel:GetText(), NS.L.SMART)
    assertTrue(f.levelBox:IsEnabled())
    cb:SetChecked(true); cb:__fire("OnClick")
    assertTrue(NS.Filters.Get().smartKeyLevel)
    -- red under: drop applySmart from Panel.Refresh
    assertEqual(NS.Filters.Get().keyLevel, 14)
    assertEqual(f.levelBox:GetText(), "14"); assertEqual(f.rangeBox:GetText(), "14-14")
    -- red under: drop setLocked from Panel.Refresh
    assertFalse(f.levelBox:IsEnabled())
    typeInto(f.levelBox, "20"); f.levelBox:__fire("OnEnterPressed")
    -- red under: drop the locked() check in Panel's numberBox commit
    assertEqual(NS.Filters.Get().keyLevel, 14); assertEqual(f.levelBox:GetText(), "14")
    cb:SetChecked(false); cb:__fire("OnClick")
    assertTrue(f.levelBox:IsEnabled())
    assertEqual(NS.Filters.Get().keyLevel, 14, "unticking keeps the level it had")
end)

-- Review: a locked level box must still say why on hover; SetEnabled alone stops the typing.
test("panel: the level box locked by Smart still shows its tooltip", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    f.levelBox.EnableMouse = function(self, on) self.__mouse = on end
    local cb = f.checks.smartKeyLevel
    cb:SetChecked(true); cb:__fire("OnClick")
    assertFalse(f.levelBox:IsEnabled())
    -- red under: restore EnableMouse(not on) in Panel's setLocked
    assertTrue(f.levelBox.__mouse ~= false)
    assertEqual(hoverLines(m, f.levelBox)[1], NS.L.KEY_TARGETING)
end)

test("panel: Smart keeps the stored level until season data arrives, then follows it", function()
    local NS, _, m = T.enableAddon{}
    NS.Filters.Get().smartKeyLevel = true
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(NS.Filters.Get().keyLevel, 10, "no season data yet")
    seasonFromScreenshot(m)
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    -- red under: drop ApplySmartLevel from OnPanelSeasonData
    assertEqual(NS.Filters.Get().keyLevel, 14)
    assertEqual(f.levelBox:GetText(), "14"); assertEqual(f.rangeBox:GetText(), "14-14")
    for _, id in ipairs({ 588, 399, 584, 249 }) do m.seasonBest[id] = { intime = { level = 14 } } end
    m.fireEvent("CHALLENGE_MODE_COMPLETED")
    assertEqual(NS.Filters.Get().keyLevel, 15, "every dungeon timed at 14 now")
end)

test("panel: with Smart off, season data leaves the level box alone", function()
    local NS, _, m = T.enableAddon{}
    NS.Filters.Get().smartKeyLevel = false -- a manually set level
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    typeInto(f.levelBox, "1")
    seasonFromScreenshot(m)
    m.fireEvent("CHALLENGE_MODE_MAPS_UPDATE")
    assertEqual(f.levelBox:GetText(), "1", "a level being typed is not overwritten")
    assertEqual(NS.Filters.Get().keyLevel, 10)
end)

test("panel: Smart writes nothing while stood down", function()
    local NS, _, m = T.enableAddon{}
    NS.Filters.Get().smartKeyLevel = true
    NS.Panel.Create()
    NS.addon:OnSlashCommand("disable")
    seasonFromScreenshot(m)
    -- red under: drop the stand-down return in OnPanelSeasonData
    NS.addon.OnPanelSeasonData()
    NS.Panel.Refresh()
    assertEqual(NS.Filters.Get().keyLevel, 10)
end)

test("panel: the level row fits the body: label, box, Smart and its label", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    local _, _, _, gap = f.levelBox:GetPoint(1)
    local _, _, _, smartGap = f.checks.smartKeyLevel:GetPoint(1)
    local right = 35 + #NS.L.KEY_TARGETING * 6 + gap + f.levelBox.__width + smartGap + 32 - 2
        + f.smartLabel:GetStringWidth()
    assertTrue(right < 398, "ends at " .. right)
end)

-- Owner requirement: Smart is on and the min leader score blank on a fresh character.
-- Owner requirement (screenshot of the expected defaults): every box and value a fresh character sees.
test("panel: a fresh character sees the owner's default panel", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    assertTrue(f.activeCheck:GetChecked())
    local want = { keyTargeting = true, smartKeyLevel = true, regionsEnabled = true,
        playstyleEnabled = true, compositionEnabled = true, experiencedLeader = false,
        maxAgeEnabled = false }
    for key, on in pairs(want) do
        -- red under: change that key's default in defaults/Profile.lua
        assertEqual(f.checks[key]:GetChecked(), on, key)
    end
    assertFalse(f.levelBox:IsEnabled(), "Smart locks the level box")
    assertEqual(f.ageBox:GetText(), "15")
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect, f.compositionSelect }) do
        assertEqual(dd:GetText(), NS.L.SELECT_ANY)
    end
end)

-- Owner request: as much extra space above the presets row as above the Apply row.
-- Owner request: as much space above the presets row as below it; its buttons as tall as its dropdown.
test("panel: the presets row has the same extra space above as below, buttons as tall as the dropdown", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    local _, _, _, _, presetY = f.deleteButton:GetPoint(1)
    local _, _, _, _, compY = f.compositionSelect:GetPoint(1)
    local _, _, _, _, applyY = f.applyButton:GetPoint(1)
    -- composition, leader, score, age: four 26px rows, then the gap.
    -- red under: drop the ACTION_GAP step in Panel's buildPresetRow
    assertEqual(compY - 3 * 26 - presetY, 8)
    assertEqual(presetY - 26 - applyY, 8, "the same gap below")
    for _, b in ipairs({ f.saveButton, f.saveAsButton, f.deleteButton }) do
        -- red under: the old 22px buttons
        assertEqual(b.__height, 26)
    end
    assertEqual(f.saveAsButton:GetText(), "Save as")
end)

-- Owner request: the two composition boxes become one multi-select with Any.
test("panel: Composition is one dropdown; Any clears, both ticked stays both (not Any)", function()
    local NS, _, m = T.enableAddon{}
    m.MenuResponse = { Refresh = 2 }
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(f.checks.noSameSpec, nil); assertEqual(f.checks.noSameClassRole, nil)
    local dd = f.compositionSelect
    assertEqual(dd:GetText(), NS.L.SELECT_ANY)
    local entries = menuEntries(dd)
    local any = entries.any
    assertEqual(#entries, 2)
    assertEqual(entries[1].text, NS.L.NO_SAME_SPEC); assertEqual(entries[2].text, NS.L.NO_SAME_CLASSROLE)
    entries[1].set(entries[1].data); entries[2].set(entries[2].data)
    local filt = NS.Filters.Get()
    -- red under: allIsAny left true for composition (both ticked would read and clear as Any)
    assertTrue(filt.noSameSpec); assertTrue(filt.noSameClassRole)
    assertTrue(dd:GetText() ~= NS.L.SELECT_ANY)
    assertFalse(any.isOn())
    any.set()
    assertFalse(filt.noSameSpec); assertFalse(filt.noSameClassRole)
    assertEqual(dd:GetText(), NS.L.SELECT_ANY)
end)

-- Owner request: a "Toggle PGF Extension Filters" box as the first option, on by default; unticked it
-- removes the managed block, ticked it writes it back.
test("panel: Toggle PGF Extension Filters is the first row, on by default", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local _, _, _, _, y = f.activeCheck:GetPoint(1)
    assertEqual(y, 4, "the first row")
    -- red under: filtersActive = false in defaults/Profile.lua
    assertTrue(f.activeCheck:GetChecked())
    assertTrue(NS.Filters.IsActive())
end)

test("panel: unticking Toggle PGF Extension Filters removes the block; ticking writes it back", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local filters = NS.Filters.Get(); filters.maxAgeEnabled = true; filters.maxAge = 20
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    m.pgf.panel.state.expression = "voice"
    f.applyButton:__fire("OnClick")
    assertTrue(m.pgf.panel.state.expression:find("age <= 20", 1, true) ~= nil)
    f.activeCheck:SetChecked(false); f.activeCheck:__fire("OnClick")
    -- red under: drop the Apply.Clear call in Panel's buildActiveRow
    assertEqual(m.pgf.panel.state.expression, "voice")
    assertFalse(NS.Filters.IsActive())
    assertFalse(f.applyButton:IsEnabled())
    local refreshes = m.pgf.calls.refresh
    f.activeCheck:SetChecked(true); f.activeCheck:__fire("OnClick")
    assertTrue(m.pgf.panel.state.expression:find("age <= 20", 1, true) ~= nil)
    assertEqual(m.pgf.calls.refresh, refreshes, "re-enabling writes the block without searching")
    assertTrue(f.applyButton:IsEnabled())
end)

test("panel: presets never switch the extension on or off", function()
    local NS = T.enableAddon{}
    NS.Presets.Save("p")
    NS.Filters.SetActive(false)
    NS.Presets.Load("p")
    -- red under: carry filtersActive in char.filters (presets would copy it)
    assertFalse(NS.Filters.IsActive())
end)

-- Owner report (screenshot): the title sat right of the header's center (the template insets it
-- 58px from the left for a hidden portrait, 24px from the right).
test("panel: the title is centered on the whole header", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    local tc = f.TitleContainer
    -- red under: drop centerTitle from Panel's buildFrame
    local p1, rel1, rp1, x1, y1 = tc:GetPoint(1)
    local p2, rel2, rp2, x2, y2 = tc:GetPoint(2)
    assertEqual(p1, "TOPLEFT"); assertTrue(rel1 == f); assertEqual(rp1, "TOPLEFT")
    assertEqual(p2, "TOPRIGHT"); assertTrue(rel2 == f); assertEqual(rp2, "TOPRIGHT")
    assertEqual(x1, -x2, "the same inset on both sides"); assertEqual(y1, y2)
end)

-- Owner request: with "Untimed dungeons at key level" off, the copy box and its label are dimmed and
-- the box disabled; ticked again, both come back.
test("panel: the copy box and its label dim, disable and empty while key targeting is off", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    assertTrue(f.rangeBox:IsEnabled())
    local cb = f.checks.keyTargeting
    cb:SetChecked(false); cb:__fire("OnClick")
    -- red under: drop setCopyEnabled from Panel.Refresh
    assertFalse(f.rangeBox:IsEnabled())
    assertEqual(f.copyLabel.__textColor[1], 0.5)
    -- Owner request: with key targeting off there is no range to copy, so the box is empty.
    -- red under: rangeText ignoring keyTargeting
    assertEqual(f.rangeBox:GetText(), "")
    cb:SetChecked(true); cb:__fire("OnClick")
    assertTrue(f.rangeBox:IsEnabled())
    assertEqual(f.copyLabel.__textColor[1], 1)
    assertEqual(f.rangeBox:GetText(), NS.Targeting.RangeText(NS.Filters.Get().keyLevel), "the range comes back")
end)

-- Owner report (screenshot): with the panel raised into the dialog's bottom edge, PGF's border drew
-- over the panel's title strip. The panel sits a few levels above the dialog, set before any of its
-- own art is built.
test("panel: the panel's frame level is above PGF's dialog and its border", function()
    local NS, _, m = T.enableAddon{}
    m.pgf.dialog.GetFrameLevel = function() return 20 end
    local create, level = m.CreateFrame, nil
    m.CreateFrame = function(frameType, name, ...)
        local fr = create(frameType, name, ...)
        if name == "PremadeGroupsFilterExtensionPanel" then
            fr.SetFrameLevel = function(_, l) level = l end
        end
        return fr
    end
    NS.Panel.Create()
    m.CreateFrame = create
    -- red under: leave the panel at the child default (dialog + 1, PGF's NineSlice's level)
    assertEqual(level, 25)
end)

-- Owner requests: the full addon name as the title, and the N-N centered in the copy box.
test("panel: the title is the full addon name, and the copy box centers its range", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    -- red under: the old "Ka0s PGF Extension" title
    assertEqual(f.__title, "Ka0s Premade Groups Filter Extension")
    -- red under: drop SetJustifyH("CENTER") from Panel's buildCopyBox
    assertEqual(f.rangeBox.__justifyH, "CENTER")
end)

-- Owner request: clicking the header does what the collapse / expand arrow does.
test("panel: a click on the header strip collapses and expands, like the arrow", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local h = f.headerClick
    -- red under: drop buildHeaderClick from Panel's buildFrame
    assertTrue(h ~= nil, "the header click area")
    local _, _, _, _, y = h:GetPoint(1)
    local p2, _, _, x2 = h:GetPoint(2)
    assertEqual(y, 0); assertEqual(p2, "TOPRIGHT"); assertTrue(x2 < 0, "short of the arrow")
    h:__fire("OnClick")
    assertTrue(NS.addon.db.profile.panelCollapsed); assertFalse(f.body:IsShown())
    assertTrue(f.MaximizeMinimizeFrame.isMinimized, "the arrow follows")
    h:__fire("OnClick")
    assertFalse(NS.addon.db.profile.panelCollapsed); assertTrue(f.body:IsShown())
    NS.addon:OnSlashCommand("disable")
    h:__fire("OnClick")
    assertFalse(NS.addon.db.profile.panelCollapsed, "nothing while stood down")
end)
