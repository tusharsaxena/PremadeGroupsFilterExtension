-- tests/test_titlebar.lua — the filter panel's title-bar controls (modules/Panel.lua): the strip
-- they are built on, a tooltip on each, and the skin's title-bar colors (SR-PGFE of
-- Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, smoke round 1, rulings 3 and 4; the
-- strip is LibKa0s#86, AD-86-PGFE of docs/2026-11-17-LIBKA0S_V1_105_ADOPTION).
--
-- The panel is the one window this addon draws itself. Its title band carries W.HeaderButtons'
-- strip, left to right extras · settings · close (standalone-windows, *Title-bar controls*): the
-- collapse toggle (the panel's one extra: chevron up and *Collapse* while expanded, chevron down and
-- *Expand* while collapsed), the settings mark, and no close, which would hide the panel under a
-- dialog that stays open. Each shows a one-line tooltip above it on hover, in the owner's
-- `gtip.title`; its art rests in the skin's `icon.tint` and takes `text.link` under the pointer. The
-- click band over the rest of the title is the title itself, not a control, and carries no tooltip.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local OWNER = "PremadeGroupsFilterExtension"

local function setup()
    local NS, _, m = T.enableAddon{}
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    return NS, m, Skin
end

local function close(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 1e-6 end

local function sameColor(c, r, g, b)
    return type(c) == "table" and close(c[1], r) and close(c[2], g) and close(c[3], b)
end

--- The title-bar controls of the panel, each with the words its tooltip must carry.
local function controls(NS)
    local f = NS.Panel.frame
    return {
        { btn = f.collapseMark, words = NS.L.PANEL_COLLAPSE_TIP, name = "collapse" },
        { btn = f.settingsMark, words = NS.L.PANEL_SETTINGS_TIP, name = "settings" },
    }
end

--- Hover `btn`: what GameTooltip was given (its text and color), who owns it, and at which anchor.
local function hover(m, btn)
    local seen = {}
    local tip = m.GameTooltip
    local points = {}
    rawset(tip, "SetText", function(_, text, r, g, b) seen.text, seen.color = text, { r, g, b } end)
    rawset(tip, "ClearAllPoints", function() points = {} end)
    rawset(tip, "SetPoint", function(_, ...) points[#points + 1] = { ... } end)
    btn:__fire("OnEnter")
    seen.owner, seen.anchor = tip.__owner, tip.__anchor
    seen.point = points[#points] or {}
    return seen
end

test("title bar: every control on the filter panel's title band shows its tooltip, in every skin", function()
    -- red under: the min/max buttons built with no tooltip (the panel before SR-PGFE), or a title band
    -- with no settings mark (the panel before LibKa0s#86).
    local NS, m, Skin = setup()
    local n = 0
    for _, def in ipairs(Skin:Skins()) do
        NS.ApplySkinChoice("ka0s", def.key)
        n = n + 1
        local r, g, b = Skin:Color(OWNER, "gtip.title")
        for _, c in ipairs(controls(NS)) do
            local seen = hover(m, c.btn)
            local where = def.key .. ", " .. c.name
            assertTrue(type(c.words) == "string" and c.words ~= "", where .. ": the words exist")
            assertEqual(seen.text, c.words, where .. ": a non-empty tooltip")
            assertTrue(seen.owner == c.btn, where .. ": owned by its control")
            assertEqual(seen.anchor, "ANCHOR_NONE", where .. ": placed, never at the cursor")
            assertTrue(seen.point[1] ~= nil, where .. ": placed against the control")
            assertTrue(sameColor(seen.color, r, g, b), where .. ": in the owner's gtip.title")
            c.btn:__fire("OnLeave")
            assertEqual(m.GameTooltip.__owner, nil, where .. ": hidden on leave")
        end
    end
    assertEqual(n, 9, "every registered skin")
end)

test("title bar: the tooltip opens above its control (PlaceAttached), not below", function()
    -- red under: a relative point hung below the control, or the old ANCHOR_RIGHT hover tooltip.
    local NS, m = setup()
    for _, c in ipairs(controls(NS)) do
        local seen = hover(m, c.btn)
        local p = seen.point
        if p[2] == c.btn then
            assertEqual(p[1], "BOTTOM", c.name .. ": the tooltip's bottom")
            assertEqual(p[3], "TOP", c.name .. ": on the control's top")
        else
            -- PlaceAttached's absolute pin on UIParent's BOTTOMLEFT, when the screen reads.
            assertEqual(p[1], "BOTTOM", c.name .. ": the tooltip's bottom")
            assertEqual(p[3], "BOTTOMLEFT", c.name .. ": an absolute pin")
        end
        c.btn:__fire("OnLeave")
    end
end)

test("title bar: a control's art rests in icon.tint and takes text.link on hover, in every skin", function()
    -- red under: the chevrons in icon.arrow at rest, or no color change under the pointer.
    local NS, _, Skin = setup()
    local n = 0
    for _, def in ipairs(Skin:Skins()) do
        NS.ApplySkinChoice("ka0s", def.key)
        n = n + 1
        local tr, tg, tb = Skin:Color(OWNER, "icon.tint")
        local lr, lg, lb = Skin:Color(OWNER, "text.link")
        for _, c in ipairs(controls(NS)) do
            local where = def.key .. ", " .. c.name
            local chev = c.btn.icon
            assertTrue(sameColor(chev.__vertexColor, tr, tg, tb), where .. ": icon.tint at rest")
            c.btn:__fire("OnEnter")
            assertTrue(sameColor(chev.__vertexColor, lr, lg, lb), where .. ": text.link under the pointer")
            c.btn:__fire("OnLeave")
            assertTrue(sameColor(chev.__vertexColor, tr, tg, tb), where .. ": icon.tint again on leave")
        end
    end
    assertEqual(n, 9, "every registered skin")
end)

test("title bar: Ka0s Default and Obsidian tell the rest and hover colors apart", function()
    -- red under: a hover that paints the rest color again, which the owner could not see (ruling 4).
    local NS, _, Skin = setup()
    for _, key in ipairs({ "ka0s", "obsidian" }) do
        NS.ApplySkinChoice("ka0s", key)
        local tr, tg, tb = Skin:Color(OWNER, "icon.tint")
        local lr, lg, lb = Skin:Color(OWNER, "text.link")
        assertTrue(tr ~= nil and lr ~= nil, key .. ": both tokens resolve")
        assertTrue(not (close(tr, lr) and close(tg, lg) and close(tb, lb)), key .. ": rest and hover differ")
    end
end)

test("title bar: the collapse toggle shows no tooltip while the addon is stood down", function()
    -- red under: a hover that ignores the stand-down every other panel tooltip honors. The settings
    -- mark keeps its words: settings are where the addon is turned back on.
    local NS, m = setup()
    local was = NS.IsStoodDown
    NS.IsStoodDown = function() return true end
    local b = NS.Panel.frame.collapseMark
    local seen = hover(m, b)
    assertEqual(seen.text, nil, "nothing written")
    b:__fire("OnLeave")
    NS.IsStoodDown = was
    seen = hover(m, b)
    assertEqual(seen.text, NS.L.PANEL_COLLAPSE_TIP, "the words again once standing up")
    b:__fire("OnLeave")
end)

test("title bar: collapsed, the toggle says Expand; expanded again, Collapse", function()
    -- red under: one tooltip for both states (the template's two buttons each carried its own).
    local NS, m = setup()
    local b = NS.Panel.frame.collapseMark
    b:__fire("OnClick", "LeftButton")
    assertEqual(hover(m, b).text, NS.L.PANEL_EXPAND_TIP, "collapsed")
    b:__fire("OnLeave")
    b:__fire("OnClick", "LeftButton")
    assertEqual(hover(m, b).text, NS.L.PANEL_COLLAPSE_TIP, "expanded")
    b:__fire("OnLeave")
end)

-- ── the strip (LibKa0s#86, AD-86-PGFE) ──────────────────────────────────────────────────────────

test("title bar: the marks are W.HeaderButtons', left to right collapse · settings, and no close", function()
    -- red under: the hand-built MaximizeMinimize toggle, or a title band with no settings mark.
    local NS = setup()
    local f = NS.Panel.frame
    local hb = f.headerButtons
    assertTrue(type(hb) == "table", "the strip's answer on the panel")
    assertEqual(table.concat(hb.order, ","), "collapse,settings", "extras · settings, left to right")
    assertEqual(hb.close, nil, "no close: it would hide the panel under a dialog that stays open")
    assertEqual(hb.optOut, nil, "the settings mark is not opted out")
    assertTrue(hb.settings == f.settingsMark and hb.extras.collapse == f.collapseMark)
    assertEqual(f.settingsMark.icon.__texture, NS.Icon("settings"), "the shipped settings icon")
    assertEqual(hb.offsets.settings, -6, "settings PAD in from the corner")
    assertEqual(hb.offsets.collapse, -(6 + 18 + 6), "the toggle GAP past it")
    assertTrue(f.CloseButton == nil or not f.CloseButton:IsShown(), "the template's close stays hidden")
end)

test("title bar: the settings mark hides PGF's dialog, then opens this addon's settings", function()
    -- red under: no settings mark, a click that opens nothing, or the FULLSCREEN dialog (and the
    -- docked panel, its child) left over the HIGH settings window.
    local NS, m = setup()
    local opened, order = 0, {}
    local real = NS.addon.OpenSettings
    NS.addon.OpenSettings = function() opened = opened + 1; order[#order + 1] = "open" end
    local dialog = m.pgf.dialog
    local hide = dialog.Hide
    dialog.Hide = function(self, ...)
        order[#order + 1] = "hide"
        self.shown = false
        if hide then return hide(self, ...) end
    end
    NS.Panel.frame.settingsMark:__fire("OnClick", "LeftButton")
    NS.addon.OpenSettings, dialog.Hide = real, hide
    assertEqual(opened, 1, "the launcher-registered opener ran once")
    assertEqual(table.concat(order, ","), "hide,open", "the dialog hidden first")
end)

test("title bar: without the library the collapse toggle still shows its tooltip above it", function()
    -- red under: a tooltip that exists only through LibKa0s-Tooltip-1.0.
    local NS, _, m = T.enableAddon{ skip = T.loadAddon.libFiles }
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    local b = NS.Panel.frame.collapseMark
    local seen = hover(m, b)
    assertEqual(seen.text, NS.L.PANEL_COLLAPSE_TIP, "the words")
    assertEqual(seen.anchor, "ANCHOR_NONE", "placed, never at the cursor")
    assertEqual(seen.point[1], "BOTTOM", "the tooltip's bottom")
    assertTrue(seen.point[2] == b, "on its control")
    assertEqual(seen.point[3], "TOP", "at the control's top")
    b:__fire("OnLeave")
    b:__fire("OnClick", "LeftButton")
    assertEqual(b.label:GetText(), "+", "collapsed, the expand glyph")
    assertEqual(hover(m, b).text, NS.L.PANEL_EXPAND_TIP, "and its words")
    b:__fire("OnLeave")
end)
