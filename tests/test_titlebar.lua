-- tests/test_titlebar.lua — the filter panel's title-bar controls (modules/Panel.lua): a tooltip on
-- each, and the skin's title-bar colors (SR-PGFE of Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, smoke round 1, rulings 3 and 4).
--
-- The panel is the one window this addon draws itself. Its title band carries one control, the
-- min/max toggle: the collapse button (chevron up) while expanded and the expand button (chevron
-- down) while collapsed. Each shows a one-line tooltip above it on hover, through
-- LibKa0s-Tooltip-1.0's AttachTitleTip, in the owner's `gtip.title`; its chevron rests in the skin's
-- `icon.tint` and takes `text.link` under the pointer, the button's own highlight kept. The click
-- band over the rest of the title is the title itself, not a control, and carries no tooltip.

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
    local mm = NS.Panel.frame.MaximizeMinimizeFrame
    return {
        { btn = mm.MinimizeButton, words = NS.L.PANEL_COLLAPSE_TIP, name = "collapse" },
        { btn = mm.MaximizeButton, words = NS.L.PANEL_EXPAND_TIP, name = "expand" },
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
    -- red under: the min/max buttons built with no tooltip (the panel before SR-PGFE).
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

test("title bar: a control's chevron rests in icon.tint and takes text.link on hover, in every skin", function()
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
            local chev = c.btn.chevron
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

test("title bar: no tooltip while the addon is stood down", function()
    -- red under: a hover that ignores the stand-down every other panel tooltip honors.
    local NS, m = setup()
    local was = NS.IsStoodDown
    NS.IsStoodDown = function() return true end
    for _, c in ipairs(controls(NS)) do
        local seen = hover(m, c.btn)
        assertEqual(seen.text, nil, c.name .. ": nothing written")
        c.btn:__fire("OnLeave")
    end
    NS.IsStoodDown = was
end)

test("title bar: without the library each control still shows its tooltip above it", function()
    -- red under: a tooltip that exists only through LibKa0s-Tooltip-1.0.
    local NS, _, m = T.enableAddon{ skip = T.loadAddon.libFiles }
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    for _, c in ipairs(controls(NS)) do
        local seen = hover(m, c.btn)
        assertEqual(seen.text, c.words, c.name .. ": the words")
        assertEqual(seen.anchor, "ANCHOR_NONE", c.name .. ": placed, never at the cursor")
        assertEqual(seen.point[1], "BOTTOM", c.name .. ": the tooltip's bottom")
        assertTrue(seen.point[2] == c.btn, c.name .. ": on its control")
        assertEqual(seen.point[3], "TOP", c.name .. ": at the control's top")
        c.btn:__fire("OnLeave")
    end
end)
