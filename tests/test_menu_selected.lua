-- tests/test_menu_selected.lua — the panel's dropdown menus mark their selection in a color of its
-- own (FB2-PGFE-01 of Ka0sAddonsCommonTasks docs/2026-11-24-FEEDBACK_BATCH/, decision D3; LibKa0s
-- v1.113.0, WidgetsDropdown minor 4).
--
-- The owner, 2026-11-24: "make the current selected always be a different color than the other
-- texts - e.g. gold in ka0s default, etc - Check this for all addons that have a similar pattern".
-- Every menu this addon drops is the library's (core/WidgetsSetup.lua, NS.MakeDropdown): the
-- presets single-select (its selected preset) and the three multi-selects (regions, playstyle,
-- composition: their ticked entries through `isActive`). None paints its own row colors and no
-- option carries a value color, so the library's rule is the whole rule here: a selected row wears
-- W.SelectedColor(owner), which differs from a plain row's `menu.text` under every shipped skin.
-- The owner's ruling on round 2 (2026-11-24, FB2-LK-04; "leave it as gold"): that color is Ka0s
-- Default's gold in EVERY skin, WoW Forever's default skin included; a skin's own `menu.textSel`
-- stands in only where the gold sits under 20 CIEDE2000 off its `menu.text`, which no shipped skin
-- does today.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local OWNER = "PremadeGroupsFilterExtension"
local GOLD = "1.000,0.820,0.000"

local function rgb(c) return ("%.3f,%.3f,%.3f"):format(c[1], c[2], c[3]) end

--- Open `dd`'s menu by its click; answers the shared menu (the first frame its build made).
local function open(m, dd, state)
    local saved = m.CreateFrame
    m.CreateFrame = function(...)
        local f = saved(...)
        state.menu = state.menu or f
        return f
    end
    dd:__fire("OnClick")
    m.CreateFrame = saved
    return state.menu
end

--- The painted label color of the menu row showing `label` (a ticked row's text leads with its mark).
local function rowColor(menu, label)
    for _, b in ipairs(menu.buttons) do
        local t = b:IsShown() and b.fs:GetText() or ""
        if t == label or t:sub(-(#label + 1)) == " " .. label then return b.fs.__textColor end
    end
    error("no shown menu row reads " .. tostring(label))
end

-- The kit's paint recorder (tests/_kit/mock_paint.lua), installed before the first open builds the
-- shared menu, so its rows are real font strings that keep their text and color.
local function setup()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 1
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local restore = dofile("tests/_kit/mock_paint.lua")(m)
    return NS, m, f, restore
end

local function skinKeys(m)
    local out = {}
    for _, def in ipairs(m.LibStub("LibKa0s-Skin-1.0"):Skins()) do out[#out + 1] = def.key end
    return out
end

test("menu selected: the selected preset stands off a plain preset under every shipped skin", function()
    -- red under: WidgetsDropdown minor 3 (Azeroth's selection painted its menu.textSel, 16.3 ΔE00
    -- off its menu.text), round 2's minor 4 (a skin's accent kept while 20 ΔE00 off, so WoW
    -- Forever's tan), or a host repaint of the row in menu.text.
    local NS, m, f, restore = setup()
    local W = m.LibStub("LibKa0s-Widgets-1.0")
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    assertTrue(NS.Presets.Save("alpha")); assertTrue(NS.Presets.Save("beta"))
    NS.Panel.SelectPreset("alpha"); NS.Panel.Refresh()
    local keys = skinKeys(m)
    assertTrue(#keys >= 9, "every shipped skin walked, got " .. #keys)
    local state = {}
    for _, key in ipairs(keys) do
        NS.ApplySkinChoice("ka0s", key)
        local menu = open(m, f.presetDropdown, state)
        local sel, plain = rowColor(menu, "alpha"), rowColor(menu, "beta")
        assertEqual(rgb(plain), rgb(Skin:ResolveSkin(key)["menu.text"]), key .. ": a plain preset is menu.text")
        assertEqual(rgb(sel), rgb({ W.SelectedColor(OWNER) }), key .. ": the selected preset is the library's selected color")
        assertEqual(rgb(sel), GOLD, key .. ": the selected preset is Ka0s Default's gold")
        assertTrue(rgb(sel) ~= rgb(plain), key .. ": the selected preset differs from a plain one")
        W.CloseMenu()
    end
    local forever = false
    for _, key in ipairs(keys) do forever = forever or key == "forever" end
    assertTrue(forever, "the WoW Forever skin is among the skins walked")
    NS.ApplySkinChoice("ka0s", "ka0s")
    restore()
end)

test("menu selected: a ticked multi-select entry stands off an unticked one, and wears no value color", function()
    -- red under: a multi-select row given its own opt.color (a value color the selection would have
    -- to replace), or an isActive row painted as a plain one.
    local NS, m, f, restore = setup()
    local W = m.LibStub("LibKa0s-Widgets-1.0")
    local state = {}
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect, f.compositionSelect }) do
        for _, opt in ipairs(dd._options) do
            assertTrue(opt.color == nil, "no menu entry carries a value color: " .. tostring(opt.label))
        end
    end
    for _, dd in ipairs({ f.presetDropdown }) do
        for _, opt in ipairs(dd._options) do
            assertTrue(opt.color == nil, "no preset row carries a value color: " .. tostring(opt.label))
        end
    end
    local first, second = f.playstyleSelect._options[3], f.playstyleSelect._options[4]
    NS.Filters.TogglePlaystyle(first.value); NS.Panel.Refresh()
    for _, key in ipairs({ "ka0s", "azeroth", "obsidian", "forever" }) do
        NS.ApplySkinChoice("ka0s", key)
        local menu = open(m, f.playstyleSelect, state)
        local on, off = rowColor(menu, first.label), rowColor(menu, second.label)
        assertEqual(rgb(on), rgb({ W.SelectedColor(OWNER) }), key .. ": a ticked entry is the selected color")
        assertEqual(rgb(on), GOLD, key .. ": a ticked entry is Ka0s Default's gold")
        assertTrue(rgb(on) ~= rgb(off), key .. ": a ticked entry differs from an unticked one")
        W.CloseMenu()
    end
    NS.ApplySkinChoice("ka0s", "ka0s")
    restore()
end)
