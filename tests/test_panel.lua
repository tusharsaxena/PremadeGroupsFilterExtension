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
    local p1, rel1, rp1 = f:GetPoint(1)
    assertEqual(p1, "TOPLEFT"); assertEqual(rel1, m.PremadeGroupsFilterDialog); assertEqual(rp1, "BOTTOMLEFT")
    local p2, rel2, rp2 = f:GetPoint(2)
    assertEqual(p2, "TOPRIGHT"); assertEqual(rel2, m.PremadeGroupsFilterDialog); assertEqual(rp2, "BOTTOMRIGHT")
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

test("panel: region chips follow portal", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 3
    NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(NS.Panel.frame.regionChips.eng:GetText(), "ENG")
    assertEqual(NS.Panel.frame.regionChips.oce, nil)
    assertFalse(NS.Panel.frame.regionsUnsupported:IsShown())
end)

test("panel: a chip click toggles the region and its highlight", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 1
    NS.Panel.Create(); NS.Panel.Refresh()
    local chip = NS.Panel.frame.regionChips.oce
    chip:__fire("OnClick")
    assertTrue(NS.Filters.Get().regions.oce)
    assertTrue(chip.__highlightLocked)
    chip:__fire("OnClick")
    assertEqual(NS.Filters.Get().regions.oce, nil)
    assertFalse(chip.__highlightLocked)
end)

test("panel: unsupported portal shows the note and no chips", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 2
    NS.Panel.Create(); NS.Panel.Refresh()
    assertEqual(next(NS.Panel.frame.regionChips), nil)
    assertTrue(NS.Panel.frame.regionsUnsupported:IsShown())
    assertEqual(NS.Panel.frame.regionsUnsupported:GetText(), NS.L.REGIONS_UNSUPPORTED)
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

test("panel: typing a level writes keyLevel and updates the range; junk is ignored", function()
    local NS = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    local box = NS.Panel.frame.levelBox
    box.__text = "15"; box:__fire("OnTextChanged", true)
    assertEqual(NS.Filters.Get().keyLevel, 15)
    assertEqual(NS.Panel.frame.rangeBox:GetText(), "15-15")
    box.__text = ""; box:__fire("OnTextChanged", true)
    assertEqual(NS.Filters.Get().keyLevel, 15)
    box.__text = "99"; box:__fire("OnTextChanged", true)
    assertEqual(NS.Filters.Get().keyLevel, 15)
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

test("panel: checkboxes write their filter option", function()
    local NS = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    local cb = NS.Panel.frame.checks.noSameSpec
    assertFalse(cb:GetChecked())
    cb:SetChecked(true); cb:__fire("OnClick")
    assertTrue(NS.Filters.Get().noSameSpec)
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
    assertEqual(f.__height, 24)
    f.MaximizeMinimizeFrame.__onMaximized()
    assertFalse(NS.addon.db.profile.panelCollapsed)
    assertTrue(f.body:IsShown())
    assertTrue(f.__height > 24)
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
