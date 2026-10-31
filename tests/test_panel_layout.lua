-- tests/test_panel_layout.lua — NS.Panel, the owner feedback round: arrow art, Any, widths, row pitch,
-- tooltips, presets, copy box, Smart. Split from tests/test_panel.lua, whose header says how the
-- panel's frames read back.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local H = dofile("tests/panel_helpers.lua")
local seasonFromScreenshot, menuEntries, typeInto = H.seasonFromScreenshot, H.menuEntries, H.typeInto

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

-- Owner request (screenshots): expanded shows the up arrow, collapsed the down one. Since the skin
-- fonts and feedback run's PG-02 (ruling D-20, image-33/34) each is the skin's Button box with a
-- chevron from the shipped icon set on top, tinted `icon.arrow`: never S.PageButton, whose "up" and
-- "down" EllesmereUI's facade drew as the words.
test("panel: the min/max arrows are chevron icons on the skin's button, expanded up and collapsed down", function()
    local NS, _, m = T.enableAddon{}
    local mm = NS.Panel.Create().MaximizeMinimizeFrame
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    -- red under: the RedButton atlas swap left in Panel's buildMinMax, or the S.PageButton paint
    assertEqual(mm.MinimizeButton.__normalAtlas ~= "RedButton-Expand", true)
    for btn, icon in pairs({ [mm.MinimizeButton] = "chevron-up", [mm.MaximizeButton] = "chevron-down" }) do
        local calls = Skin.painted[btn].calls
        assertEqual(calls.PageButton, nil, icon .. ": no paging arrow")
        assertTrue(calls.Button ~= nil, icon .. ": the skin's button box")
        local chev = btn.chevron
        assertTrue(chev ~= nil, icon .. ": a chevron")
        assertEqual(chev.__texture, NS.Icon(icon), icon .. ": the shipped icon")
        assertEqual(chev.__width, 12); assertEqual(chev.__height, 12)
        local p, rel, rp = chev:GetPoint(1)
        assertEqual(p, "CENTER"); assertTrue(rel == btn, icon .. ": centered on its button"); assertEqual(rp, "CENTER")
        local r, g, b = Skin:Color("PremadeGroupsFilterExtension", "icon.arrow")
        assertEqual(chev.__vertexColor[1], r); assertEqual(chev.__vertexColor[2], g)
        assertEqual(chev.__vertexColor[3], b)
        local holder = btn.chevronHolder
        assertEqual(holder:GetFrameLevel(), btn:GetFrameLevel() + 2, icon .. ": over the button's edge")
    end
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
    -- The label starts LABEL_X - 24 = 11px past the box; the rect reaches the label's far end.
    assertEqual(f.checks.compositionEnabled.__hitRect[2], -(11 + #NS.L.COMPOSITION * 6))
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
    -- red under: the old BUTTON_GAP (4); then the owner asked for a 60px visible gap (56 + 4)
    assertEqual(x, 56)
    assertEqual(f.smartLabel:GetText(), NS.L.SMART)
    -- Owner report (screenshot): the box-to-text gap matches the rows' (LABEL_X 35 - 24 box).
    -- red under: the old LEFT-to-RIGHT, -2 anchor
    local lp, lrel, lrp, lx = f.smartLabel:GetPoint(1)
    assertEqual(lp, "LEFT"); assertTrue(lrel == cb); assertEqual(lrp, "RIGHT")
    assertEqual(lx, 35 - 24)
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
    local right = 35 + #NS.L.KEY_TARGETING * 6 + gap + f.levelBox.__width + smartGap + 24 + 11
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

-- Owner request: a "Use the extension's filters" box as the first option, on by default; unticked it
-- removes the managed block, ticked it writes it back.
test("panel: Use the extension's filters is the first row, on by default", function()
    local NS = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local _, _, _, _, y = f.activeCheck:GetPoint(1)
    assertEqual(y, 0, "the first row (its 24px box centered where the template's 32px sat at +4)")
    -- red under: filtersActive = false in defaults/Profile.lua
    assertTrue(f.activeCheck:GetChecked())
    assertTrue(NS.Filters.IsActive())
end)

test("panel: unticking Use the extension's filters removes the block; ticking writes it back", function()
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
