-- tests/test_panel.lua — NS.Panel (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 8): its
-- lifecycle, dropdowns, boxes, readout, season requests, Apply, collapse and presets.
-- tests/test_panel_layout.lua holds the owner feedback round (layout, tooltips, Smart).
--
-- The panel's frames come from tests/wow_mock.lua's PANEL FRAMES: every frame built under PGF's
-- dialog records its anchors, text, checked state and children, so a case reads back what the
-- player would see.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local H = dofile("tests/panel_helpers.lua")
local seasonFromScreenshot, menuEntries, typeInto = H.seasonFromScreenshot, H.menuEntries, H.typeInto

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
    -- Flush: the skin's flat window sits on its rect (the retired metal border's 3px raise is gone).
    -- red under: the metal panel's ATTACH_RAISE
    assertEqual(x1, 0); assertEqual(x2, 0); assertEqual(y1, 0); assertEqual(y2, 0)
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

-- C-29 (Panel half): every tooltip handler gates on the stand-down, so OnLeave cannot hide a
-- tooltip the panel showed once the addon stands down. The STAND_DOWN row hides it instead, and
-- only when the panel (or a frame inside it) owns it.
test("panel: a stand-down hides a tooltip the panel showed", function()
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    f.levelBox:__fire("OnEnter")
    assertTrue(m.GameTooltip:GetOwner() == f.levelBox, "the panel's widget owns the tooltip")
    local hides, hide = 0, m.GameTooltip.Hide
    m.GameTooltip.Hide = function(self) hides = hides + 1; return hide(self) end
    NS.addon:OnSlashCommand("disable")
    -- red under: drop the tooltip hide in the STAND_DOWN row
    assertTrue(hides >= 1, "GameTooltip:Hide() ran on stand-down")
    T.assertNil(m.GameTooltip:GetOwner())
end)

test("panel: a stand-down leaves a tooltip owned outside the panel shown", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create(); NS.Panel.Refresh()
    local outside = m.CreateFrame("Frame", "SomeOtherAddonFrame", m.UIParent)
    m.GameTooltip:SetOwner(outside, "ANCHOR_RIGHT"); m.GameTooltip:Show()
    local hides, hide = 0, m.GameTooltip.Hide
    m.GameTooltip.Hide = function(self) hides = hides + 1; return hide(self) end
    NS.addon:OnSlashCommand("disable")
    -- red under: hide GameTooltip unconditionally in the STAND_DOWN row
    assertEqual(hides, 0)
    assertTrue(m.GameTooltip:GetOwner() == outside)
end)

-- C-10 (Panel store): Diagnostics reads whether the dialog hook went in.
test("panel: the dialog hook install is recorded", function()
    local NS = T.enableAddon{}
    -- red under: drop the Panel.dialogHooked store
    assertTrue(NS.Panel.dialogHooked == true)
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
    assertEqual(f.__height, 30, "Ka0s Default's title band")
    f.MaximizeMinimizeFrame.__onMaximized()
    assertFalse(NS.addon.db.profile.panelCollapsed)
    assertTrue(f.body:IsShown())
    assertTrue(f.__height > 30)
end)

-- Review F-010: a profile switch carries its own panelCollapsed; the attached panel follows it.
test("panel: a profile switch refreshes the attached panel's layout", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    assertTrue(f.body:IsShown())
    NS.addon.db.profile.panelCollapsed = true
    NS.addon:OnProfileChanged(nil, nil, "Other")
    -- red under: drop the Panel.Refresh call in PGFE's reloadProfile
    assertFalse(f.body:IsShown()); assertEqual(f.__height, 30)
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

-- red under: keep the dropdown's selection in a Panel local (it was session only)
test("panel: the selected preset is still selected after a reload", function()
    local NS = T.enableAddon{}
    NS.Presets.Save("Keep")
    NS.Panel.Create(); NS.Panel.SelectPreset("Keep")
    local saved = _G.PremadeGroupsFilterExtensionDB
    local NS2 = T.enableAddon{ afterFile = function() _G.PremadeGroupsFilterExtensionDB = saved end }
    NS2.Panel.Create(); NS2.Panel.Refresh()
    assertEqual(NS2.Presets.GetSelected(), "Keep")
    assertTrue(NS2.Panel.frame.saveButton:IsEnabled())
    assertTrue(NS2.Panel.frame.deleteButton:IsEnabled())
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

test("panel: collapsed shows only the skin's title band; no metal header copies are built", function()
    -- red under: the retired metal instance's clipped border copies (headerArt) and its 32px strip.
    local NS = T.enableAddon{}
    local f = NS.Panel.Create()
    assertEqual(f.headerArt, nil)
    f.MaximizeMinimizeFrame.__onMinimized()
    assertEqual(f.__height, 30)
    assertFalse(f.body:IsShown())
    NS.addon.db.profile.panelCollapsed = false
    NS.Panel.Refresh()
    assertEqual(f.__height, f.expandedHeight)
    assertTrue(f.body:IsShown())
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

-- ── debug lines (C-19 / review PGE-04) ──────────────────────────────────────────────────────────

-- How many console lines carry `needle` (plain find).
local function logged(NS, needle)
    local n = 0
    for _, line in ipairs(NS.DebugLog.buffer) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

test("panel: visibility logs on change only, and again after a stand-down", function()
    local NS, _, m = T.enableAddon{}
    NS.State.debug = true
    NS.DebugLog:Clear()
    NS.Panel.UpdateVisibility(); NS.Panel.UpdateVisibility()
    assertEqual(logged(NS, "[Panel] shown"), 1, "a repeat show is not logged")
    m.pgf.dialog.activeId = "c3f0"; NS.Panel.UpdateVisibility()
    assertEqual(logged(NS, "[Panel] hidden"), 1)
    m.pgf.dialog.activeId = "c2f4"; NS.Panel.UpdateVisibility()
    assertEqual(logged(NS, "[Panel] shown"), 2)
    NS.addon:OnSlashCommand("disable")
    NS.addon:OnSlashCommand("enable")
    -- red under: drop the DebugForget on the STAND_DOWN hide
    assertEqual(logged(NS, "[Panel] shown"), 3)
end)
