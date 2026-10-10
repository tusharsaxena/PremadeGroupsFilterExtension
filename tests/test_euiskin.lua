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
    assertEqual(rel, m.PremadeGroupsFilterDialog); assertEqual(y, 3, "the metal border's raise stays")
end)

test("euiskin: every condition on, the login dispatch paints the built panel", function()
    local NS, m, f = painted()
    assertTrue(NS.EUISkin.IsApplied())
    assertEqual(#m.eui.callsFor("Shell", f), 1)
    assertEqual(#m.eui.callsFor("FadeNineSlice", f.NineSlice), 1)
    assertEqual(m.eui.count("Checkbox"), 8, "the Toggle row and the seven filter boxes")
    assertEqual(m.eui.count("EditBox"), 3, "level, age and the copy box")
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

-- red under: reloadProfile calling TryApply instead of the switch handler OnSwitch
test("euiskin: a profile switch to one with the switch off, after a paint, asks for a reload", function()
    local NS, m = painted()
    NS.addon.db.profile.euiSkin = false
    NS.addon:OnProfileChanged(nil, nil, "Other")
    assertEqual(#m.popupsShown, 1)
    assertEqual(m.popupsShown[1][1], NS.EUISkin.POPUP_RELOAD)
    assertTrue(NS.EUISkin.IsApplied(), "a skin cannot come off live")
end)

-- red under: reloadProfile painting before the Lifecycle re-read of `enabled`
test("euiskin: a profile switch to a disabled profile with the switch on paints nothing", function()
    local NS, _, m = setup()
    NS.addon.db.profile.euiSkin = false
    NS.Panel.Create()
    m.eui.dispatch(NAME)
    NS.addon.db.profile.euiSkin = true
    NS.addon.db.profile.enabled = false
    NS.addon:OnProfileChanged(nil, nil, "Other")
    assertTrue(NS.IsStoodDown())
    assertFalse(NS.EUISkin.IsApplied())
    assertEqual(m.eui.count("Shell"), 0)
end)

-- ── a facade that changed shape, or raises ──────────────────────────────────────────────────────

-- An EllesmereUI whose facade lost a member must never half-paint the panel: the paint checks the
-- whole shape first and refuses, and the panel stays stock and usable.
-- red under: drop the REQUIRED shape check in blocked()
test("euiskin: a facade missing a primitive is refused before any paint", function()
    local NS, m, f = painted{ omit = { "StateButtonLabel" } }
    assertTrue(NS.EUISkin.HasFacade(), "S is kept")
    assertFalse(NS.EUISkin.IsApplied())
    assertFalse(NS.EUISkin.TryApply())
    assertEqual(m.eui.count("Shell"), 0, "nothing painted")
    NS.Panel.UpdateVisibility()
    assertTrue(f:IsShown(), "the panel still shows")
end)

-- A primitive that raises mid-paint fails closed: no raise out of TryApply, no retry (a retry would
-- skin the same widgets twice), and the switch turned off offers the reload that drops the partial
-- paint.
-- red under: drop the pcall, or the paintFailed latch
test("euiskin: a primitive that raises fails closed, once", function()
    local NS, _, m = setup{ raise = "Dropdown" }
    NS.Panel.Create()
    m.eui.dispatch(NAME)
    assertFalse(NS.EUISkin.IsApplied())
    local boxes = m.eui.count("Checkbox")
    assertTrue(boxes > 0, "the paint got as far as the boxes")
    assertFalse(NS.EUISkin.TryApply())
    NS.Panel.UpdateVisibility()
    assertEqual(m.eui.count("Checkbox"), boxes, "no second paint")
    NS.addon.db.profile.euiSkin = false
    NS.EUISkin.OnSwitch(false)
    assertEqual(#m.popupsShown, 1)
    assertEqual(m.popupsShown[1][1], NS.EUISkin.POPUP_RELOAD)
end)

-- ── skip logging ────────────────────────────────────────────────────────────────────────────────

-- How many console lines carry `needle`.
local function linesWith(NS, needle)
    local n = 0
    for _, line in ipairs(NS.DebugLog.buffer) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

-- A panel re-show repeats a skip; the console writes it once, and again after a Clear.
-- red under: the lastSkip memo (a file-local the console's Clear never re-arms)
test("euiskin: a skip is logged again after a console Clear", function()
    local NS, _, m = setup()
    NS.DebugLog:SetEnabled(true)
    m.eui.dispatch(NAME)                    -- no panel built: the callback's TryApply skips
    NS.EUISkin.TryApply(); NS.EUISkin.TryApply()
    assertEqual(linesWith(NS, "skipped: panel not built yet"), 1)
    NS.DebugLog:Clear()
    NS.EUISkin.TryApply()
    assertEqual(linesWith(NS, "skipped: panel not built yet"), 1, "re-armed by the Clear")
end)

-- red under: the lastSkip memo (set while logging was off, so the line is never written)
test("euiskin: a skip with logging off is logged once logging turns on", function()
    local NS, _, m = setup()
    m.eui.dispatch(NAME)
    NS.EUISkin.TryApply()
    NS.DebugLog:SetEnabled(true)
    NS.EUISkin.TryApply()
    assertEqual(linesWith(NS, "skipped: panel not built yet"), 1)
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

test("euiskin: skinned, the panel sits flush under PGF's dialog, both edges", function()
    local _, m, f = painted()
    local p1, rel1, rp1, x1, y1 = f:GetPoint(1)
    local p2, rel2, rp2, _, y2 = f:GetPoint(2)
    assertEqual(p1, "TOPLEFT"); assertEqual(rel1, m.PremadeGroupsFilterDialog); assertEqual(rp1, "BOTTOMLEFT")
    assertEqual(p2, "TOPRIGHT"); assertEqual(rel2, m.PremadeGroupsFilterDialog); assertEqual(rp2, "BOTTOMRIGHT")
    assertEqual(x1, 0)
    -- Owner request: flush, as the metal look is. red under: SHELL_GAP 1 (the old 1px gap)
    assertEqual(y1, 0); assertEqual(y2, 0)
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

-- A stand-down while the pointer is on a min/max button: the OnLeave hook is gated off, so the
-- stand-down puts the glyph back to its resting alpha itself. 0.75 is GLYPH_ALPHA, a file-local
-- (modules/EUISkin.lua:35) the module does not export.
-- red under: drop the glyph reset row
test("euiskin: a stand-down restores the min/max glyph alpha", function()
    local NS, _, f = painted()
    local b = f.MaximizeMinimizeFrame.MinimizeButton
    b:__fire("OnEnter")
    assertEqual(b.pgfeGlyph.__vertexColor[4], 1, "hover brightens")
    NS.addon:OnSlashCommand("disable")
    b:__fire("OnLeave")                     -- gated: stood down
    NS.addon:OnSlashCommand("enable")
    assertEqual(b.pgfeGlyph.__vertexColor[4], 0.75)
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
    -- Owner report (screenshot): Smart's box-to-text gap must match the rows'. A row's text stays
    -- put while its box's right edge moves in by 8, so Smart's text moves out by 8 with its hit rect.
    -- red under: Smart's label left where the shrink found it
    local _, sr = smart:GetHitRectInsets()
    assertEqual(sr, smartR - 8, "Smart's hit rect follows its label")
    local _, _, _, rowLabelX = f.checks.keyTargeting:GetPoint(1)
    local rowGap = 35 - (rowLabelX + row.__width)
    local _, _, _, smartGap = f.smartLabel:GetPoint(1)
    assertEqual(smartGap, rowGap, "Smart's text sits as far from its box as a row's")
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

-- The accent ring of a painted box: the frame skinCheckBox created last on it.
local function ringOf(cb) return cb.__children[#cb.__children] end

-- red under: repaintLooks a no-op (the block and ring keep the old accent)
test("euiskin: a live looks change recolors the accent block and ring", function()
    local _, m, f = painted()
    local cb = f.checks.experiencedLeader
    m.eui.accent = { 1, 0, 0 }
    m.eui.looks[1]()
    assertEqual(table.concat(cb:GetCheckedTexture().__color, ","), "1,0,0,1")
    assertEqual(table.concat(ringOf(cb).edges[1].__color, ","), "1,0,0,1")
end)

-- At a 0.7 pixel factor the 16px box is 23px and the 10px block rounds to 14, then to 13 for
-- the box's parity: 13 * 0.7 units.
-- red under: OnEUISkinScale skipping layoutAccentMark
test("euiskin: a scale change re-lays out the accent block in whole pixels", function()
    local _, m, f = painted()
    local mark = f.checks.experiencedLeader:GetCheckedTexture()
    assertEqual(mark.__width, 10)
    m.PixelUtil.GetPixelToUIUnitFactor = function() return 0.7 end
    m.fireEvent("UI_SCALE_CHANGED")
    assertTrue(math.abs(mark.__width - 9.1) < 1e-9, tostring(mark.__width))
    m.fireEvent("DISPLAY_SIZE_CHANGED")
end)

-- Before any paint there is nothing to re-lay out. No red-first test is possible: the early return
-- (`not applied`) and the empty checkBoxes loop it guards behave the same, and the kit cannot spy
-- on the file-local layoutAccentMark. A smoke test only.
test("euiskin: scale events before a paint are inert", function()
    local NS, _, m = setup()
    m.fireEvent("UI_SCALE_CHANGED")
    m.fireEvent("DISPLAY_SIZE_CHANGED")
    assertFalse(NS.EUISkin.HasFacade())
    assertFalse(NS.EUISkin.IsApplied())
end)

-- red under: the STAND_UP entry only calling TryApply (which refuses once applied)
test("euiskin: theme and scale changes while stood down catch up at the stand-up", function()
    local NS, m, f = painted()
    local mark = f.checks.experiencedLeader:GetCheckedTexture()
    NS.addon:OnSlashCommand("disable")
    m.eui.accent = { 1, 0, 0 }
    m.eui.looks[1]()
    m.PixelUtil.GetPixelToUIUnitFactor = function() return 0.7 end
    NS.addon.OnEUISkinScale()
    assertEqual(table.concat(mark.__color, ","), "0.05,0.8,0.6,1", "nothing while stood down")
    assertEqual(mark.__width, 10)
    NS.addon:OnSlashCommand("enable")
    assertEqual(table.concat(mark.__color, ","), "1,0,0,1")
    assertTrue(math.abs(mark.__width - 9.1) < 1e-9, tostring(mark.__width))
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
