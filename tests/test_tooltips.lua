-- tests/test_tooltips.lua — where the attached panel's tooltips open (LibKa0s#92, AD-92-PGFE of
-- Ka0sAddonsCommonTasks docs/2026-11-17-LIBKA0S_V1_105_ADOPTION/; WowAddonStandards
-- standalone-windows, *Tooltip placement*).
--
-- The panel is the one window this addon draws. Every option on it (a checkbox and its label, a
-- number box, a dropdown button, a preset button, Apply, Clear, the copy box and its label) is a
-- BODY element: the panel's content is its controls (the standard's Terms: every element the
-- chrome row does not name is a body element). Its tooltip opens beside the panel, the window
-- group (the panel alone: PGF's dialog it docks under is PGF's), right of it when it fits and
-- otherwise left, its top level with the hovered control, through LibKa0s-Tooltip-1.0's
-- PlaceBeside, owned at ANCHOR_NONE. It was owned at ANCHOR_RIGHT, the corner offset the rule
-- retires. The title-bar marks are chrome (tests/test_titlebar.lua). An entry of the library's
-- menu is placed by the library beside its menu once the host's renderer showed it, owned by the
-- row and anchored nowhere.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local H = dofile("tests/panel_helpers.lua")
local menuEntries = H.menuEntries

--- Every option on the panel that carries a hover tooltip, by name.
local function options(f)
    local list = {
        { "activeCheck", f.activeCheck }, { "levelBox", f.levelBox }, { "ageBox", f.ageBox },
        { "regionSelect", f.regionSelect }, { "playstyleSelect", f.playstyleSelect },
        { "compositionSelect", f.compositionSelect }, { "presetDropdown", f.presetDropdown },
        { "saveButton", f.saveButton }, { "saveAsButton", f.saveAsButton },
        { "deleteButton", f.deleteButton }, { "applyButton", f.applyButton },
        { "clearButton", f.clearButton }, { "rangeBox", f.rangeBox },
        { "copyLabelHover", f.copyLabelHover },
    }
    local keys = {}
    for key in pairs(f.checks) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do list[#list + 1] = { "checks." .. key, f.checks[key] } end
    return list
end

--- Spy on the library's two placers; answers the calls and a restore.
local function spyPlacers(m)
    local Tip = m.LibStub("LibKa0s-Tooltip-1.0")
    local calls = {}
    local beside, attached = Tip.PlaceBeside, Tip.PlaceAttached
    Tip.PlaceBeside = function(tip, el, group, opts)
        calls[#calls + 1] = { kind = "beside", tip = tip, el = el, group = group }
        return beside(tip, el, group, opts)
    end
    Tip.PlaceAttached = function(tip, el, opts)
        calls[#calls + 1] = { kind = "attached", tip = tip, el = el }
        return attached(tip, el, opts)
    end
    return calls, function() Tip.PlaceBeside, Tip.PlaceAttached = beside, attached end
end

test("tooltips: every option on the panel opens beside the panel (PlaceBeside), never at ANCHOR_RIGHT", function()
    -- red under: GameTooltip:SetOwner(self, "ANCHOR_RIGHT") in Panel's tooltip(), the corner offset.
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local calls, restore = spyPlacers(m)
    for _, o in ipairs(options(f)) do
        local name, w = o[1], o[2]
        assertTrue(w ~= nil, name .. ": built")
        for i = #calls, 1, -1 do calls[i] = nil end
        w:__fire("OnEnter")
        assertEqual(m.GameTooltip.__anchor, "ANCHOR_NONE", name .. ": owned at ANCHOR_NONE")
        assertTrue(m.GameTooltip:GetOwner() == w, name .. ": the hovered control owns it")
        local c = calls[1]
        assertTrue(c ~= nil and c.kind == "beside", name .. ": placed by PlaceBeside")
        assertTrue(c.tip == m.GameTooltip and c.el == w, name .. ": the tooltip, on the hovered control")
        assertTrue(c.group == f, name .. ": the panel is the window group")
        w:__fire("OnLeave")
    end
    restore()
end)

--- Put `frame` at `l, b` (own units, scale 1), `w` x `h`, for the fake screen.
local function at(frame, l, b, w, h)
    rawset(frame, "GetLeft", function() return l end)
    rawset(frame, "GetBottom", function() return b end)
    rawset(frame, "GetRight", function() return l + w end)
    rawset(frame, "GetTop", function() return b + h end)
    rawset(frame, "GetWidth", function() return w end)
    rawset(frame, "GetHeight", function() return h end)
    rawset(frame, "GetEffectiveScale", function() return 1 end)
end

--- Hover `widget` on the panel `f` laid out at `panelLeft`, on a 1920x1080 fake screen, with a
--- 250x60 tooltip: answers the side, the tooltip's screen rect and its log of ops.
local function hoverOnScreen(m, f, widget, panelLeft)
    local scr = dofile("tests/_kit/mock_screen.lua")(m, { width = 1920, height = 1080 })
    local tip = scr.tooltip{ width = 250, height = 60 }
    local saved = m.GameTooltip
    m.GameTooltip = tip
    at(f, panelLeft, 300, 420, 400)
    at(widget, panelLeft + 40, 600, 60, 20)
    widget:__fire("OnEnter")
    local l, b, r, t = scr.rectOf(tip)
    local ops = scr.ops(tip)
    m.GameTooltip = saved
    scr.restore()
    return { l = l, b = b, r = r, t = t, ops = ops, anchorType = tip.__anchorType, owner = tip.__owner }
end

test("tooltips: a panel option's tooltip opens right of the panel, top level with the option, 2px out", function()
    -- red under: the ANCHOR_RIGHT owner (no point written: rectOf answers nil).
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local got = hoverOnScreen(m, f, f.levelBox, 600)
    assertEqual(got.l, 600 + 420 + 2, "the tooltip's left is the panel's right edge + TIP_GAP")
    assertEqual(got.t, 620, "its top is the option's top")
    assertEqual(got.anchorType, "ANCHOR_RIGHT", "comparisons extend outward on the same side")
    assertTrue(got.owner == f.levelBox, "the option owns it")
    assertTrue(not got.ops:find("SetOwner.*SetOwner"), "owned once")
end)

test("tooltips: with no room right of the panel the tooltip opens left of it, never over it", function()
    -- red under: a tooltip hung off the option's corner (over the panel's neighbors) or at the cursor.
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local got = hoverOnScreen(m, f, f.applyButton, 1920 - 420 - 10)
    assertEqual(got.r, 1920 - 420 - 10 - 2, "the tooltip's right is the panel's left edge - TIP_GAP")
    assertEqual(got.t, 620, "its top is the option's top")
    assertEqual(got.anchorType, "ANCHOR_LEFT")
end)

test("tooltips: a menu entry's tooltip is owned by its row at ANCHOR_NONE, for the library to place", function()
    -- red under: the renderer's GameTooltip:SetOwner(row, "ANCHOR_RIGHT").
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 1
    local f = NS.Panel.Create()
    local row = m.CreateFrame("Button")
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect, f.compositionSelect }) do
        local entries = menuEntries(dd)
        local all = { entries.any }
        for _, e in ipairs(entries) do all[#all + 1] = e end
        for _, e in ipairs(all) do
            if e and e.row and e.row.tooltip then
                m.GameTooltip.__anchor = nil
                e.row.tooltip(row, e.row)
                assertTrue(m.GameTooltip:GetOwner() == row, "the row owns it")
                assertEqual(m.GameTooltip.__anchor, "ANCHOR_NONE", "anchored nowhere until placed")
            end
        end
    end
end)

--- Hover a library menu entry of `dd` end to end on a 1920x1080 fake screen: its menu at `menuLeft`
--- (200 wide), the row inside it, the row's OnEnter path (Widgets' __rowTip) run with the host's
--- renderer. Answers the tooltip's screen rect, its owner and anchor type.
local function hoverMenuEntry(m, dd, menuLeft)
    local scr = dofile("tests/_kit/mock_screen.lua")(m, { width = 1920, height = 1080 })
    local tip = scr.tooltip{ width = 250, height = 60, shown = false }
    rawset(tip, "IsOwned", function(self, frame) return self:GetOwner() == frame end)  -- the client's
    local menu = scr.frame{ left = menuLeft, bottom = 500, width = 200, height = 300 }
    local row = scr.frame{ left = menuLeft, bottom = 700, width = 200, height = 18, parent = menu }
    row.__menu = menu
    local opt
    for _, o in ipairs(dd._options) do if type(o.tooltip) == "function" then opt = o; break end end
    assertTrue(opt ~= nil, "an entry with a renderer")
    local saved = m.GameTooltip
    m.GameTooltip = tip
    m.LibStub("LibKa0s-Widgets-1.0").__rowTip(row, opt, { text = { 1, 1, 1 } })
    local l, b, r, t = scr.rectOf(tip)
    local got = { l = l, b = b, r = r, t = t, owner = tip.__owner, anchorType = tip.__anchorType,
                  row = row, shown = tip:IsShown() }
    m.GameTooltip = saved
    scr.restore()
    return got
end

test("tooltips: a menu entry's tooltip lands beside its menu through the library, right then left", function()
    -- red under: a renderer that forgets Show(), or owns the tooltip by anything but the row (the
    -- library then places nothing: rectOf answers nil). End to end through Widgets' __rowTip.
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 1
    local f = NS.Panel.Create()
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect, f.compositionSelect }) do
        local got = hoverMenuEntry(m, dd, 800)
        assertTrue(got.shown, "the renderer showed it")
        assertTrue(got.owner == got.row, "the row owns it")
        assertEqual(got.l, 800 + 200 + 2, "right of the menu, TIP_GAP out")
        assertEqual(got.t, 718, "its top level with the entry")
        assertEqual(got.anchorType, "ANCHOR_RIGHT")
        got = hoverMenuEntry(m, dd, 1920 - 200 - 10)
        assertEqual(got.r, 1920 - 200 - 10 - 2, "left of the menu when the right does not fit")
        assertEqual(got.t, 718)
        assertEqual(got.anchorType, "ANCHOR_LEFT")
    end
end)

test("tooltips: without the Tooltip library a panel option's tooltip attaches above it, not at a corner", function()
    -- red under: ANCHOR_RIGHT with the placer absent. The fallback is the chrome rule's shape by a
    -- relative point (the library's own fallback, Dropdown's placeRowTip), never the cursor.
    local NS, _, m = T.enableAddon{}
    local f = NS.Panel.Create(); NS.Panel.Refresh()
    local Tip = m.LibStub("LibKa0s-Tooltip-1.0")
    local beside = Tip.PlaceBeside
    Tip.PlaceBeside = function() return nil end   -- the geometry unreadable: nothing placed
    local tip = m.GameTooltip
    local points = {}
    local setPoint, clear = rawget(tip, "SetPoint"), rawget(tip, "ClearAllPoints")
    rawset(tip, "ClearAllPoints", function() points = {} end)
    rawset(tip, "SetPoint", function(_, ...) points[#points + 1] = { ... } end)
    f.saveButton:__fire("OnEnter")
    rawset(tip, "SetPoint", setPoint); rawset(tip, "ClearAllPoints", clear)
    Tip.PlaceBeside = beside
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    local p = points[#points]
    assertTrue(p ~= nil, "a point was written")
    assertEqual(p[1], "BOTTOM"); assertTrue(p[2] == f.saveButton); assertEqual(p[3], "TOP")
    assertEqual(p[4], 0); assertEqual(p[5], 2)
end)

test("tooltips: the panel's code carries no cursor anchor and no corner anchor", function()
    -- red under: any ANCHOR_CURSOR, ANCHOR_CURSOR_RIGHT or ANCHOR_<corner> owner in the addon's own
    -- Lua (the TOC's own files: libs/ and tests/ are not the addon's). ANCHOR_NONE is the placers'
    -- owner.
    local files = T.loadAddon.tocFiles
    assertTrue(#files > 10, "the TOC's files")
    for _, path in ipairs(files) do if path:match("%.lua$") then
        local fh = assert(io.open(path, "rb"))
        local src = fh:read("*a"); fh:close()
        for anchor in src:gmatch("ANCHOR_[%u_]+") do
            assertEqual(anchor, "ANCHOR_NONE", path .. ": " .. anchor)
        end
        assertTrue(not src:find("GetCursorPosition", 1, true), path .. ": no cursor-following tooltip")
    end end
end)
