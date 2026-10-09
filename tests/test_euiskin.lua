-- tests/test_euiskin.lua — NS.EUISkin, the optional EllesmereUI skin of the attached panel
-- (docs/superpowers/plans/2026-10-09-eui-skin.md, Task 3). Driven against the EllesmereUI fake in
-- tests/wow_mock.lua (installEUI): `m.eui.dispatch(name)` is EllesmereUI's PLAYER_LOGIN dispatch,
-- `m.eui.dispatchAll()` its live dispatch when a switch turns on in its options, and the facade
-- records every primitive call in `m.eui.calls`.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local NAME = "PremadeGroupsFilterExtension"

-- An enabled instance with EllesmereUI installed per `spec`; `nineSlice` builds the header copies.
local function setup(spec, nineSlice)
    return T.enableAddon{ mock = function(m)
        m.installEUI(spec)
        if nineSlice then
            m.NineSliceUtil = { GetLayout = function() return {} end, ApplyLayout = function() end }
        end
    end }
end

-- The usual order in the client: the panel is built, then EllesmereUI's login dispatch.
local function painted(spec, nineSlice)
    local NS, _, m = setup(spec, nineSlice)
    local f = NS.Panel.Create()
    m.eui.dispatch(NAME)
    return NS, m, f
end

test("euiskin: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.EUISkin), "table")
end)

test("euiskin: registers once, at file load, under the folder name", function()
    local NS, _, m = T.newAddon{ mock = function(m) m.installEUI() end }
    assertEqual(table.concat(m.eui.order, ","), NAME)
    assertTrue(NS.EUISkin.registered)
end)

-- red under: dropping the presence guard around EllesmereUI.RegisterSkin
test("euiskin: EllesmereUI absent registers nothing and leaves the panel stock", function()
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create()
    assertNil(NS.EUISkin.registered)
    assertFalse(NS.EUISkin.HasFacade()); assertFalse(NS.EUISkin.IsApplied())
    assertFalse(NS.EUISkin.TryApply())
    assertNil(f.headerHeight)
    local _, rel, _, _, y = f:GetPoint(1)
    assertEqual(rel, m.PremadeGroupsFilterDialog); assertEqual(y, 2, "the metal border's raise stays")
end)

test("euiskin: every condition on, the login dispatch paints the built panel", function()
    local NS, m, f = painted()
    assertTrue(NS.EUISkin.IsApplied())
    assertEqual(#m.eui.callsFor("Shell", f), 1)
    assertEqual(#m.eui.callsFor("FadeNineSlice", f.NineSlice), 1)
    assertEqual(m.eui.count("Checkbox"), 9, "the Toggle row and the eight filter boxes")
    assertEqual(m.eui.count("EditBox"), 4, "level, score, age and the copy box")
    assertEqual(m.eui.count("Dropdown"), 4, "regions, playstyle, composition, presets")
    assertEqual(m.eui.count("Button"), 5, "Save, Save as, Delete, Apply, Clear")
    assertEqual(m.eui.count("StateButtonLabel"), 5)
    for _, c in ipairs(m.eui.calls) do assertEqual(c.skin, NAME) end
end)

test("euiskin: a dispatch before the panel exists keeps S, and Panel.Create paints", function()
    local NS, _, m = setup()
    assertTrue(m.eui.dispatch(NAME))
    assertTrue(NS.EUISkin.HasFacade()); assertFalse(NS.EUISkin.IsApplied())
    assertEqual(m.eui.count("Shell"), 0)
    -- red under: drop the TryApply call from Panel.Create
    NS.Panel.Create()
    assertTrue(NS.EUISkin.IsApplied())
    assertEqual(m.eui.count("Shell"), 1)
end)

test("euiskin: TryApply is idempotent", function()
    local NS, m = painted()
    assertFalse(NS.EUISkin.TryApply())
    assertEqual(m.eui.count("Shell"), 1)
end)

-- The gate matrix: each failing condition, alone, keeps the panel stock. Master off, our entry
-- off or the skin child missing mean EllesmereUI never calls back; PGF's skin off or absent means
-- it does, and the gate refuses.
-- red under: TryApply not asking NS.EUIBridge.GateOpen
test("euiskin: any one failing condition keeps the panel stock", function()
    local cases = {
        { { child = false }, false },
        { { masterOff = true }, false },
        { { entries = { [NAME] = false } }, false },
        { { entries = { PremadeGroupsFilter = false } }, true },
        { { pgfSkin = false }, true },
    }
    for i, case in ipairs(cases) do
        local NS, m = painted(case[1])
        assertEqual(NS.EUISkin.HasFacade(), case[2], "case " .. i .. " facade")
        assertFalse(NS.EUISkin.IsApplied(), "case " .. i .. " applied")
        assertEqual(m.eui.count("Shell"), 0, "case " .. i .. " painted nothing")
        assertFalse(NS.EUISkin.IsWanted(), "case " .. i .. " wanted")
    end
end)

test("euiskin: a condition turned off mid-session refuses a later paint", function()
    local NS, _, m = setup()
    m.eui.dispatch(NAME)
    m.loadedAddons.PremadeGroupsFilter_EllesmereUI = false
    NS.Panel.Create()
    assertFalse(NS.EUISkin.IsApplied())
end)

-- red under: TryApply not reading profile.euiSkin
test("euiskin: our switch off keeps S and paints nothing; turning it on paints live", function()
    local NS, _, m = setup()
    NS.addon.db.profile.euiSkin = false
    NS.Panel.Create()
    m.eui.dispatch(NAME)
    assertTrue(NS.EUISkin.HasFacade()); assertFalse(NS.EUISkin.IsApplied())
    NS.addon.db.profile.euiSkin = true
    NS.EUISkin.OnSwitch(true)
    assertTrue(NS.EUISkin.IsApplied())
end)

test("euiskin: turning the switch off after a paint asks for a reload and does not unpaint", function()
    local NS, m = painted()
    NS.addon.db.profile.euiSkin = false
    NS.EUISkin.OnSwitch(false)
    assertEqual(#m.popupsShown, 1)
    assertEqual(m.popupsShown[1][1], NS.EUISkin.POPUP_RELOAD)
    assertTrue(NS.EUISkin.IsApplied(), "a skin cannot come off live")
    m.StaticPopupDialogs[NS.EUISkin.POPUP_RELOAD].OnAccept()
    assertEqual(m.reloads, 1)
end)

-- red under: OnSwitch(false) showing the popup whether or not anything was painted
test("euiskin: turning the switch off before any paint asks for nothing", function()
    local NS, _, m = setup()
    NS.EUISkin.OnSwitch(false)
    assertEqual(#m.popupsShown, 0)
end)

test("euiskin: master off at login, turned on in EllesmereUI later, paints live", function()
    local NS, _, m = setup{ masterOff = true }
    NS.Panel.Create()
    assertFalse(m.eui.dispatch(NAME))
    m.EllesmereUIDB.thirdPartySkinsOff = nil
    assertTrue(m.eui.dispatchAll())
    assertTrue(NS.EUISkin.IsApplied())
end)

-- red under: dropping the stood-down guard from TryApply
test("euiskin: stood down, the callback paints nothing; the stand-up paints", function()
    local NS, _, m = setup()
    NS.Panel.Create()
    NS.addon:OnSlashCommand("disable")
    m.eui.dispatch(NAME)
    assertTrue(NS.EUISkin.HasFacade()); assertFalse(NS.EUISkin.IsApplied())
    assertEqual(m.eui.count("Shell"), 0)
    NS.addon:OnSlashCommand("enable")
    assertTrue(NS.EUISkin.IsApplied())
end)

test("euiskin: a profile switch to one with the switch on paints", function()
    local NS, _, m = setup()
    NS.addon.db.profile.euiSkin = false
    NS.Panel.Create()
    m.eui.dispatch(NAME)
    NS.addon.db.profile.euiSkin = true
    NS.addon:OnProfileChanged(nil, nil, "Other")
    assertTrue(NS.EUISkin.IsApplied())
end)

-- ── geometry ────────────────────────────────────────────────────────────────────────────────────

test("euiskin: skinned, the collapsed panel is the shell's 25px bar and the metal copies are hidden", function()
    local NS, _, f = painted(nil, true)
    assertEqual(#f.headerArt, 2)
    f.MaximizeMinimizeFrame.__onMinimized()
    -- red under: Panel's applyLayout ignoring f.headerHeight
    assertEqual(f.__height, NS.EUISkin.SHELL_HEADER_H)
    assertEqual(f.__height, 25)
    -- red under: dropping the headerArt alpha in paintShell
    assertEqual(f.headerArt[1].__alpha, 0); assertEqual(f.headerArt[2].__alpha, 0)
    f.MaximizeMinimizeFrame.__onMaximized()
    assertEqual(f.__height, f.expandedHeight)
end)

test("euiskin: skinned, the panel hangs 2px below PGF's dialog, both edges", function()
    local _, m, f = painted()
    local p1, rel1, rp1, x1, y1 = f:GetPoint(1)
    local p2, rel2, rp2, _, y2 = f:GetPoint(2)
    assertEqual(p1, "TOPLEFT"); assertEqual(rel1, m.PremadeGroupsFilterDialog); assertEqual(rp1, "BOTTOMLEFT")
    assertEqual(p2, "TOPRIGHT"); assertEqual(rel2, m.PremadeGroupsFilterDialog); assertEqual(rp2, "BOTTOMRIGHT")
    assertEqual(x1, 0)
    -- red under: SHELL_GAP sign flipped (the panel overlapping the dialog)
    assertEqual(y1, -2); assertEqual(y2, -2)
end)

test("euiskin: the min/max buttons get the minus (collapse) and the plus (expand)", function()
    local _, _, f = painted()
    local mm = f.MaximizeMinimizeFrame
    -- red under: swapping the two atlases in paintShell
    assertEqual(mm.MinimizeButton.pgfeGlyph.__atlas, "UI-QuestTrackerButton-Secondary-Collapse")
    assertEqual(mm.MaximizeButton.pgfeGlyph.__atlas, "UI-QuestTrackerButton-Secondary-Expand")
    assertEqual(mm.MinimizeButton:GetNormalTexture().__alpha, 0)
    assertEqual(mm.MaximizeButton:GetPushedTexture().__alpha, 0)
end)

test("euiskin: checkboxes shrink to 24, row boxes stay on their row, hit rects follow the label", function()
    local NS, _, m = setup()
    local f = NS.Panel.Create()
    local row, smart = f.checks.keyTargeting, f.checks.smartKeyLevel
    local _, _, _, rowX, rowY = row:GetPoint(1)
    local _, rowR = row:GetHitRectInsets()
    local sp, srel, srp, sx, sy = smart:GetPoint(1)
    local _, smartR = smart:GetHitRectInsets()
    m.eui.dispatch(NAME)
    assertEqual(row.__width, 24); assertEqual(row.__height, 24)
    local p, _, _, x, y = row:GetPoint(1)
    assertEqual(p, "TOPLEFT"); assertEqual(x, rowX)
    assertEqual(y, rowY - 4, "moved down by half of the 8 it lost")
    -- red under: shrinkCheckBox not stretching the row box's hit rect
    local _, r = row:GetHitRectInsets()
    assertEqual(r, rowR - 8)
    -- red under: treating the Smart box as a row box (labelOnBox ignored)
    local _, sr = smart:GetHitRectInsets()
    assertEqual(sr, smartR, "Smart's label rides the box")
    local p2, rel2, rp2, x2, y2 = smart:GetPoint(1)
    assertEqual(p2, sp); assertEqual(rel2, srel); assertEqual(rp2, srp); assertEqual(x2, sx); assertEqual(y2, sy)
    assertEqual(#m.eui.callsFor("Checkbox", row), 1)
    assertEqual(m.eui.callsFor("Checkbox", row)[1].opts.borderInset, 4)
end)

test("euiskin: the accent ring follows the check, and not while stood down", function()
    local NS, m, f = painted()
    local cb = f.checks.experiencedLeader
    local ring = cb.__children[#cb.__children]
    cb:SetChecked(true); assertTrue(ring:IsShown())
    cb:SetChecked(false); assertFalse(ring:IsShown())
    assertEqual(table.concat(cb:GetCheckedTexture().__color, ","), "0.05,0.8,0.6,1", "the accent block")
    -- red under: dropping the stood-down guard from the SetChecked hook's body
    NS.addon:OnSlashCommand("disable")
    cb:SetChecked(true); assertFalse(ring:IsShown())
    assertEqual(#m.eui.looks, 1, "follows live theme changes")
end)

-- The level box grays under Smart and the copy box dims without key targeting; the readout carries
-- its own color codes. Only the title may be whitened.
-- red under: S.White on every font string in fontRegions
test("euiskin: only the title is whitened; readout, copy label and number boxes keep their color", function()
    local _, m, f = painted()
    local whites = m.eui.callsFor("White")
    assertEqual(#whites, 1)
    assertEqual(whites[1].target, f.TitleContainer.TitleText)
    assertTrue(#m.eui.callsFor("Font", f.readout) == 1, "the theme font, kept color")
    assertTrue(#m.eui.callsFor("Font", f.copyLabel) == 1)
    assertEqual(#m.eui.callsFor("Font", f.levelBox), 1)
end)

test("euiskin: live looks and scale changes repaint without raising", function()
    local _, m, f = painted()
    m.eui.looks[1]()
    m.fireEvent("UI_SCALE_CHANGED")
    m.fireEvent("DISPLAY_SIZE_CHANGED")
    assertEqual(table.concat(f.checks.minScoreEnabled:GetCheckedTexture().__color, ","), "0.05,0.8,0.6,1")
end)

test("euiskin: the diagnostics dependencies section reports the gate and the skin", function()
    local NS = painted()
    local lines = {}
    local out = { add = function(_, _, fmt, ...)
        local args = { ... }
        for i = 1, select("#", ...) do args[i] = tostring(args[i]) end
        lines[#lines + 1] = fmt:gsub("%%s", function() return table.remove(args, 1) end)
    end }
    for _, sec in ipairs(NS.Diagnostics.Sections()) do
        if sec[1] == "dependencies" then sec[2](out) end
    end
    local text = table.concat(lines, "\n")
    assertTrue(text:find("EllesmereUI suite=true master=true ownEntry=true pgfSkin=true", 1, true) ~= nil, text)
    assertTrue(text:find("registered=true facade=true wanted=true applied=true", 1, true) ~= nil, text)
end)
