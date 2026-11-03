-- tests/test_skin.lua — the attached panel through the skin (modules/Panel.lua, skinning-§1, §2;
-- PG-02 of the skinning rollout, PG-01 of the library follow-ups).
--
-- The panel is ONE frame, painted once through NS.Skin at build and recorded, so the library replays
-- every later switch onto it, Ka0s Default included: LibKa0s v1.81.0 retired the stock look under
-- Ka0s Default (owner ruling R-2, decision D-05), and with it the never-painted metal instance this
-- suite used to pin. A player who wants the client's look picks WoW Default. What this suite pins is
-- the host half: that every widget and label is recorded, that a switch repaints the same frame live,
-- that the panel keeps its geometry and its shown state across one, that it is a window and keeps the
-- skin under Ignore settings panel (D-01), and that the colors the panel writes itself are the skin's
-- tokens, Ka0s Default's exact pixels.
--
-- "Recorded" is LibKa0s-Skin-1.0's own ledger, `lib.painted[target]` ({ owner, calls = { [prim] =
-- args } }): a frame some primitive painted for an owner. Every case builds its own instance.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local OWNER = "PremadeGroupsFilterExtension"
local FRAME_NAME = "PremadeGroupsFilterExtensionPanel"

--- An enabled instance, its Skin major, and the panel built and shown under PGF's dialog.
local function setup(opts)
    local NS, _, m = T.enableAddon(opts)
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    return NS, m, Skin
end

--- Every own widget of a panel instance the skin paints: the frame, the min/max arrows, the eight
--- check buttons, the three edit boxes, the four dropdowns and the five buttons.
local function widgets(f)
    local out = { f, f.MaximizeMinimizeFrame.MinimizeButton, f.MaximizeMinimizeFrame.MaximizeButton,
        f.activeCheck, f.levelBox, f.ageBox, f.rangeBox,
        f.regionSelect, f.playstyleSelect, f.compositionSelect, f.presetDropdown,
        f.saveButton, f.saveAsButton, f.deleteButton, f.applyButton, f.clearButton }
    for _, cb in pairs(f.checks) do out[#out + 1] = cb end
    return out
end

--- The font strings of a panel instance: the frame's and the body's regions.
local function texts(f)
    local out = {}
    for _, frame in ipairs({ f, f.body }) do
        for _, r in ipairs({ frame:GetRegions() }) do
            if r.__objType == "FontString" then out[#out + 1] = r end
        end
    end
    return out
end

--- The body's label that reads `text`.
local function labelFor(f, text)
    for _, fs in ipairs(texts(f)) do if fs:GetText() == text then return fs end end
end

local function recorded(Skin, target)
    local rec = Skin.painted[target]
    return rec ~= nil and rec.owner == OWNER
end

local function close(a, b) return math.abs((a or 1) - (b or 1)) < 1e-6 end

-- ── Ka0s Default: the Ka0s look ─────────────────────────────────────────────────────────────────

test("skin: under Ka0s Default the one panel is painted through the facade, every widget and label", function()
    -- red under: the retired metal instance (never handed to a primitive under Ka0s Default), or a
    -- widget or label the paint skipped.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    assertTrue(f ~= nil and f:IsShown(), "the panel did not show")
    assertEqual(f.__name, FRAME_NAME, "the one frame keeps the global name LAYER-1's /dump reads")
    assertEqual(rawget(NS.Panel, "stockFrame"), nil, "no metal instance")
    assertEqual(rawget(NS.Panel, "skinFrame"), nil, "no twin")
    for _, w in ipairs(widgets(f)) do assertTrue(recorded(Skin, w), "a widget was not painted") end
    for _, fs in ipairs(texts(f)) do assertTrue(recorded(Skin, fs), "a label was not painted") end
    assertTrue(#texts(f) >= 10, "the label walk found the panel's font strings")
    assertTrue(Skin.painted[f].calls.Shell ~= nil, "the window is the skin's Shell")
    assertTrue(Skin.painted[f.MaximizeMinimizeFrame.MinimizeButton].calls.Button ~= nil)
    assertTrue(Skin.painted[f.activeCheck].calls.Checkbox ~= nil)
    assertTrue(Skin.painted[f.levelBox].calls.EditBox ~= nil)
    assertTrue(Skin.painted[f.presetDropdown].calls.Dropdown ~= nil)
    assertTrue(Skin.painted[f.applyButton].calls.Button ~= nil)
end)

test("skin: the colors the panel writes under Ka0s Default are its exact pixels", function()
    -- red under: a token whose Ka0s Default value is not today's (0.9 gray boxes and labels, the
    -- input role, 0.5 gray dimmed, ffd100 / 808080 readout markup, white tooltip names over a gold body).
    local NS, m = setup()
    local f = NS.Panel.frame
    NS.Filters.Get().smartKeyLevel = true
    NS.Panel.Refresh()
    assertEqual(f.levelBox.__textColor[1], 0.5, "the locked level box is 0.5 gray")
    NS.Filters.Get().smartKeyLevel = false
    NS.Panel.Refresh()
    local c = f.levelBox.__textColor
    assertEqual(c[1], 0.9); assertEqual(c[2], 0.9); assertEqual(c[3], 0.9)
    assertEqual(c[4], nil, "an opaque color is passed as three components, as before")
    m.mapTable = { 586, 587 }
    m.mapUIInfo[586] = { name = "D586", mapID = 586 }; m.seasonBest[586] = { intime = { level = 13 } }
    m.mapUIInfo[587] = { name = "D587", mapID = 587 }; m.seasonBest[587] = { intime = { level = 14 } }
    NS.Filters.Get().keyLevel = 14
    NS.Panel.Refresh()
    local text = f.readout:GetText()
    assertTrue(text:find("|cffffd100D 13|r", 1, true) ~= nil, text)
    assertTrue(text:find("|cff808080D 14|r", 1, true) ~= nil, text)
end)

test("skin: the panel's tooltip lines are the skin's tooltip colors, Ka0s Default's white over gold", function()
    -- skinning-§7: the GameTooltip frame stays Blizzard's; the lines the addon writes take gtip.*.
    -- red under: typed 1, 1, 1 left in fillTooltip, or the two tokens swapped.
    local NS, m = setup()
    local f = NS.Panel.frame
    local tip = m.GameTooltip
    local setText, addLine = tip.SetText, tip.AddLine
    local title, body
    tip.SetText = function(self, t, r, g, b, ...) title = { t, r, g, b }; return setText(self, t, r, g, b, ...) end
    tip.AddLine = function(self, t, r, g, b, ...) body = { t, r, g, b }; return addLine(self, t, r, g, b, ...) end
    f.applyButton:__fire("OnEnter")
    tip.SetText, tip.AddLine = setText, addLine
    assertTrue(title ~= nil and body ~= nil, "the Apply button's tooltip was not written")
    assertEqual(title[2], 1); assertEqual(title[3], 1); assertEqual(title[4], 1)
    assertEqual(body[2], 1); assertTrue(close(body[3], 0.82)); assertEqual(body[4], 0)
end)

-- ── a switch: the same frame, repainted live ────────────────────────────────────────────────────

test("skin: a switch repaints the one panel live, and back to Ka0s Default the same frame again", function()
    -- red under: a second frame built for another skin (the retired twin), or a frame hidden by a pick.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    NS.ApplySkinChoice("ka0s", "obsidian")
    assertTrue(rawequal(NS.Panel.frame, f), "a pick built a second frame")
    assertTrue(f:IsShown(), "the panel still shows")
    local hr, hg, hb = Skin:Color(OWNER, "text.body")
    local label = labelFor(f, NS.L.KEY_TARGETING)
    assertTrue(label ~= nil and close(label.__textColor[1], hr) and close(label.__textColor[2], hg)
        and close(label.__textColor[3], hb), "the library replayed Obsidian's body text onto the labels")
    NS.ApplySkinChoice("ka0s", "ka0s")
    assertTrue(rawequal(NS.Panel.frame, f)); assertTrue(f:IsShown())
    for _, w in ipairs(widgets(f)) do assertTrue(recorded(Skin, w), "a widget left the ledger") end
end)

test("skin: a skin pick never shows a hidden panel, and the panel reads the stored filters", function()
    local NS, m = setup()
    local f = NS.Panel.frame
    NS.Filters.Set("keyTargeting", true)
    NS.Filters.Set("keyLevel", 12)
    NS.Panel.Refresh()
    m.pgf.dialog.shown = false
    NS.Panel.UpdateVisibility()
    assertFalse(f:IsShown())
    NS.ApplySkinChoice("ka0s", "azeroth")
    assertFalse(f:IsShown(), "a skin pick never shows a hidden panel")
    assertTrue(f.checks.keyTargeting:GetChecked())
    assertEqual(f.levelBox:GetText(), "12")
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    assertTrue(f:IsShown())
end)

test("skin: a pick before the panel exists builds the one panel, painted", function()
    local NS, _, m = T.enableAddon{}
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    NS.ApplySkinChoice("ka0s", "glass")
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    local f = NS.Panel.frame
    assertTrue(f ~= nil and f:IsShown())
    assertEqual(f.__name, FRAME_NAME)
    assertTrue(recorded(Skin, f))
end)

test("skin: the panel's geometry: 24px check buttons on the rows' centers, flush under the dialog", function()
    -- The skin's Checkbox draws its box 4 inside the frame, so 24 gives a 16px box (PGF's EllesmereUI
    -- skin's); a flat window sits on its rect, so the metal border's 3px raise is gone.
    -- red under: the template's 32px boxes, the metal panel's raise, or its header copies.
    local NS = setup()
    local f = NS.Panel.frame
    local cb = f.checks.keyTargeting
    assertEqual(cb:GetWidth(), 24); assertEqual(cb:GetHeight(), 24)
    local _, _, _, _, yRow = cb:GetPoint(1)
    local _, _, _, _, yLabel = labelFor(f, NS.L.KEY_TARGETING):GetPoint(1)
    assertEqual(yRow, yLabel, "the 24px box is centered on its 26px row as the template's 32px was")
    assertEqual(cb.__hitRect[2], -(35 - 24 + #NS.L.KEY_TARGETING * 6), "the hit rect still reaches the label")
    local _, _, _, _, y1 = f:GetPoint(1)
    assertEqual(y1, 0)
    assertEqual(f.headerArt, nil, "no metal header copies")
end)

test("skin: collapsed, the panel folds to the skin's title band, Ka0s Default's included", function()
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    NS.addon.db.profile.panelCollapsed = true
    NS.Panel.Refresh()
    assertEqual(f.__height, Skin:Token(OWNER, "title.height"))
    NS.ApplySkinChoice("ka0s", "obsidian")
    assertEqual(f.__height, Skin:Token(OWNER, "title.height"))
end)

-- PG-02 of the skin fonts and feedback run (ruling D-20, image-48..51): the min/max button had no
-- size of its own and sat on the hidden template close button's anchor, so it landed on a different
-- part of the band, or the window edge, in each skin. Now it is one size everywhere, centered on
-- the skin's title band (the band Shell draws: `win.borderSize` in from a flat edge, else 1, and
-- `title.height` tall), 4px in from the right; the header's click band covers the band up to it.
test("skin: the min/max button is one size and centered on the title band in every skin", function()
    -- red under: the CloseButton anchor (no size), or a click band that ignores the skin's edge and
    -- band height.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    local mm = f.MaximizeMinimizeFrame
    local n = 0
    for _, def in ipairs(Skin:Skins()) do
        NS.ApplySkinChoice("ka0s", def.key)
        n = n + 1
        local style = Skin:Token(OWNER, "win.borderStyle") or "flat"
        local inset = style == "flat" and Skin:Token(OWNER, "win.borderSize") or 1
        local h = Skin:Token(OWNER, "title.height") or 30
        assertEqual(mm.__width, 20, def.key .. ": width"); assertEqual(mm.__height, 20, def.key .. ": height")
        for _, btn in ipairs({ mm.MinimizeButton, mm.MaximizeButton }) do
            assertEqual(btn.__width, 20, def.key .. ": a button's width")
            assertEqual(btn.__height, 20, def.key .. ": a button's height")
            assertEqual(btn.chevron.__width, 12, def.key .. ": the chevron's size")
            local p, rel = btn:GetPoint(1)
            assertEqual(p, "CENTER"); assertTrue(rel == mm, def.key .. ": the button on its frame")
        end
        -- Where it sits on the band (RIGHT 4px in, y 0) is the R5-PG1 case below.
        local _, _, _, _, bodyTop = f.body:GetPoint(1)
        assertEqual(f.headerClick.__height, math.min(inset + h, -bodyTop),
            def.key .. ": the click band covers the title band")
        assertTrue(f.headerClick.__height <= -bodyTop, def.key .. ": the click band stops above the body")
        local _, _, _, cx = f.headerClick:GetPoint(2)
        assertEqual(cx, -(inset + 4 + 20), def.key .. ": the click band stops at the button")
    end
    assertEqual(n, 9, "every registered skin")
end)

-- R5-PG1 of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND5 (owner item 5, images 42 and 43): the
-- title sat about 4px above the arrow. The arrow was centered on the band, but the title kept
-- PortraitFrameTemplate's own anchor, TOP 5px down a 20px container at y -1, because centerTitle moved
-- only the container. Both now hang on S.Band(f), the band frame Shell lays (LibKa0s SkinPaintExtras
-- 17), through S.Header, at y 0: the title by `title.align`, the arrow RIGHT 4px in. A LEFT, CENTER or
-- RIGHT point at y 0 on the band IS its vertical middle; the glyphs' own baseline is the smoke check.
local ON_MIDDLE = { LEFT = true, CENTER = true, RIGHT = true }

local function assertOnBand(region, band, what)
    assertTrue(#region.__points >= 1, what .. ": anchored")
    for i = 1, #region.__points do
        local p, rel, rp, _, y = region:GetPoint(i)
        assertTrue(ON_MIDDLE[p] == true, what .. ": point " .. tostring(p) .. " is LEFT, CENTER or RIGHT, never TOP")
        assertTrue(rel == band, what .. ": anchored to the band")
        assertEqual(rp, p, what .. ": to the band's own " .. tostring(p))
        assertEqual(y, 0, what .. ": at y 0, the band's middle")
    end
end

test("skin: the title and the min/max button are centered on the band in every skin", function()
    -- red under: the template's TOP anchor left on TitleText (centerTitle moving only its container),
    -- or the arrow placed by the host's own copy of the band's arithmetic instead of on the band.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    local title, mm = f.TitleContainer.TitleText, f.MaximizeMinimizeFrame
    local n = 0
    for _, def in ipairs(Skin:Skins()) do
        NS.ApplySkinChoice("ka0s", def.key)
        n = n + 1
        local style = Skin:Token(OWNER, "win.borderStyle") or "flat"
        local inset = style == "flat" and Skin:Token(OWNER, "win.borderSize") or 1
        local h = Skin:Token(OWNER, "title.height") or 30
        local band = NS.Skin.Band(f)
        assertTrue(band ~= nil, def.key .. ": the band frame")
        local bp, brel, _, bx, by = band:GetPoint(1)
        assertEqual(bp, "TOPLEFT"); assertTrue(brel == f, def.key .. ": the band on the panel")
        assertEqual(bx, inset, def.key .. ": the band's inset"); assertEqual(by, -inset, def.key .. ": its top")
        assertEqual(band:GetHeight(), h, def.key .. ": the band's height")
        assertOnBand(title, band, def.key .. ": the title")
        assertEqual(#title.__points, 1, def.key .. ": the title's one anchor")
        local align = Skin:Token(OWNER, "title.align") or "CENTER"
        assertEqual((title:GetPoint(1)), align, def.key .. ": the title by title.align")
        assertEqual(title.__justifyH, align, def.key .. ": and justified to it")
        assertOnBand(mm, band, def.key .. ": the min/max button")
        assertEqual(#mm.__points, 1, def.key .. ": the button's one anchor")
        local mp, _, _, mx = mm:GetPoint(1)
        assertEqual(mp, "RIGHT"); assertEqual(mx, -4, def.key .. ": 4px in from the band's right end")
    end
    assertEqual(n, 9, "every registered skin")
end)

test("skin: a Refresh re-anchors the min/max button only when the band moved", function()
    -- red under: placeHeader's ClearAllPoints and SetPoint running on every layout, which is what
    -- tests/perf.lua's combatEvents ceiling caught.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    local mm = f.MaximizeMinimizeFrame
    local anchors = 0
    local realClear = mm.ClearAllPoints
    mm.ClearAllPoints = function(self) anchors = anchors + 1; return realClear(self) end
    NS.Panel.Refresh(); NS.Panel.Refresh()
    assertEqual(anchors, 0, "the same band: nothing moved")
    local moved = false
    for _, def in ipairs(Skin:Skins()) do
        NS.ApplySkinChoice("ka0s", def.key)
        moved = moved or anchors > 0
    end
    assertTrue(moved, "a skin with another band moves the button")
end)

test("skin: the panel writes the skin's colors: locked boxes, the dimmed label, the readout", function()
    -- red under: a color written once at build (a later switch would leave the last skin's), or a
    -- typed value.
    local NS, m, Skin = setup()
    NS.ApplySkinChoice("ka0s", "wow")
    local f = NS.Panel.frame
    NS.Filters.Get().smartKeyLevel = true
    NS.Filters.Get().keyTargeting = false
    NS.Panel.Refresh()
    local dr, dg, db = Skin:Color(OWNER, "text.disabled")
    assertTrue(close(f.levelBox.__textColor[1], dr) and close(f.levelBox.__textColor[2], dg)
        and close(f.levelBox.__textColor[3], db), "the locked box is the skin's text.disabled")
    assertTrue(close(f.copyLabel.__textColor[1], dr), "the dimmed copy label is the skin's text.disabled")
    NS.Filters.Get().keyTargeting = true
    NS.Panel.Refresh()
    local hr = Skin:Color(OWNER, "text.body")
    assertTrue(close(f.copyLabel.__textColor[1], hr), "the copy label is the skin's text.body")
    m.mapTable = { 586 }
    m.mapUIInfo[586] = { name = "D586", mapID = 586 }; m.seasonBest[586] = { intime = { level = 13 } }
    NS.Filters.Get().keyLevel = 14
    NS.Panel.Refresh()
    assertTrue(f.readout:GetText():find(NS.SkinEscape("text.accent") .. "D 13|r", 1, true) ~= nil,
        f.readout:GetText())
end)

test("skin: a pick after the panel is built rewrites the colors the panel reads from tokens", function()
    -- With the twin retired, the panel's onLooksChanged Refresh is the only thing that rewrites the
    -- host-written colors after a live pick: no manual Refresh between the pick and the asserts.
    -- red under: Panel.Refresh() removed from onLooksChanged (the locked box and the readout keep
    -- Ka0s Default's 0.5 gray and its escapes).
    local NS, m, Skin = setup()
    local f = NS.Panel.frame
    m.mapTable = { 586, 587 }
    m.mapUIInfo[586] = { name = "D586", mapID = 586 }; m.seasonBest[586] = { intime = { level = 13 } }
    m.mapUIInfo[587] = { name = "D587", mapID = 587 }; m.seasonBest[587] = { intime = { level = 14 } }
    NS.Filters.Get().smartKeyLevel = true
    NS.Filters.Get().keyTargeting = false
    NS.Panel.Refresh()
    local kr, kg, kb = Skin:Color(OWNER, "text.disabled")
    local kOff = NS.SkinEscape("text.disabled")
    NS.ApplySkinChoice("ka0s", "obsidian")
    local dr, dg, db = Skin:Color(OWNER, "text.disabled")
    local off = NS.SkinEscape("text.disabled")
    assertTrue(not (close(dr, kr) and close(dg, kg) and close(db, kb)) and off ~= kOff,
        "Obsidian's text.disabled differs from Ka0s Default's, so the case can tell them apart")
    local c = f.levelBox.__textColor
    assertTrue(close(c[1], dr) and close(c[2], dg) and close(c[3], db),
        "the locked level box took the new skin's text.disabled")
    assertTrue(close(f.copyLabel.__textColor[1], dr), "the dimmed copy label took the new skin's text.disabled")
    local text = f.readout:GetText()
    assertTrue(text:find(NS.SkinEscape("text.accent") .. "D 13|r", 1, true) ~= nil, text)
    assertTrue(text:find(off .. "D 14|r", 1, true) ~= nil, text)
end)

-- ── the Scope: the panel is a window, not the settings panel ────────────────────────────────────

test("skin: with Ignore settings panel on, the panel's labels and title still wear the skin", function()
    -- D-01: Ignore settings panel covers the settings panel only; the attached panel is a window.
    -- S.Text paints a window string unless it opts in with `panel = true` (LibKa0s v1.81.0, D-02).
    -- red under: the panel's labels passed `{ panel = true }`, or a host gate on GetIgnore's panel half.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    NS.ApplySkinChoice("ka0s", "obsidian")
    NS.ApplySkinIgnore(true, false)
    assertTrue((Skin:GetIgnore(OWNER)), "the owner ignores its settings panel (the profile default)")
    local br, bg, bb = Skin:Color(OWNER, "text.body")
    local n = 0
    for _, fs in ipairs(texts(f.body)) do
        if fs ~= f.copyLabel and fs ~= f.regionsUnsupported and fs.__textColor then
            n = n + 1
            assertTrue(close(fs.__textColor[1], br) and close(fs.__textColor[2], bg)
                and close(fs.__textColor[3], bb), "a label gave the skin back under Ignore settings panel")
        end
    end
    assertTrue(n >= 5, "the walk found the body's labels")
    local title = f.TitleContainer and f.TitleContainer.TitleText
    if title then assertTrue(recorded(Skin, title), "the title left the ledger") end
end)

-- ── the dropdowns: the skin picker's look (PG-D1) ───────────────────────────────────────────────

local ARROW_ART = "Interface\\ChatFrame\\ChatFrameExpandArrow"

local function dropdowns(f)
    return { f.regionSelect, f.playstyleSelect, f.compositionSelect, f.presetDropdown }
end

test("skin: every panel dropdown is the library's, owned by this addon, with its menu and marks", function()
    -- red under: the template's dropdown (the client's menu, cause A2), or a dropdown given no owner.
    local NS, _, Skin = setup()
    local r, g, b = Skin:Color(OWNER, "icon.arrow")
    for _, dd in ipairs(dropdowns(NS.Panel.frame)) do
        assertEqual(dd.__owner, OWNER)
        assertEqual(dd.__menuGen, nil, "no client menu")
        assertTrue(dd.arrow:IsShown())
        assertEqual(dd.__height, 26, "the row pitch")
        local c = dd.arrow.__vertexColor
        assertTrue(close(c[1], r) and close(c[2], g) and close(c[3], b), "the arrow wears icon.arrow")
        assertEqual(dd.arrow.__texture, ARROW_ART, "the arrow's shape is left alone (L10)")
        assertTrue(close(dd.arrow.__rotation, -math.pi / 2), "turned to point down")
        assertEqual(dd.arrow.__points[1][4], -8, "8px in from the right end")
        assertEqual(dd.text.__wordWrap, false, "a long name stays on one line")
        assertEqual(dd.text.__points[#dd.text.__points][4], -20, "and stops at the arrow")
        assertTrue(dd.__check:find("confirm", 1, true) ~= nil, "the Ka0s tick")
    end
end)

test("skin: a dropdown follows a live switch and stays under Ignore settings panel", function()
    -- red under: an arrow colored at build, or a dropdown given back by the Scope toggle (D-01).
    local NS, _, Skin = setup()
    local dd = NS.Panel.frame.presetDropdown
    NS.ApplySkinChoice("ka0s", "ember")
    local r, g, b = Skin:Color(OWNER, "icon.arrow")
    local c = dd.arrow.__vertexColor
    assertTrue(close(c[1], r) and close(c[2], g) and close(c[3], b), "Ember's arrow color replayed")
    NS.ApplySkinIgnore(true, false)
    assertTrue(dd.arrow:IsShown(), "the panel is a window: the Scope toggle leaves it skinned")
    assertEqual(dd.arrow.__texture, ARROW_ART)
end)

test("skin: without the library the dropdowns are the client's template and its art", function()
    -- red under: no dropdown at all, which leaves the filters with no way to pick a region.
    local NS, _, m = T.enableAddon{ skip = T.loadAddon.libFiles }
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    for _, dd in ipairs(dropdowns(NS.Panel.frame)) do
        assertEqual(dd.Arrow:GetAlpha(), 1, "the template's button stays")
        assertEqual(dd.Background:GetAlpha(), 1, "the template's text holder stays")
        assertEqual(dd.arrow, nil, "no second arrow")
    end
    assertTrue(NS.Panel.frame.regionSelect.__menuGen ~= nil, "the client's menu")
end)

test("skin: while EllesmereUI paints the panel its own arrow is the only one", function()
    -- red under: the library's arrow left showing beside the arrow WSkin.Dropdown draws.
    local NS, _, m = T.enableAddon({ mock = function(mm) mm.installEUI() end })
    NS.SchemaRuntime.Set("skin.source", "eui")
    m.eui.dispatch(OWNER)
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    assertTrue(NS.SkinEUIPainted(), "EllesmereUI painted the owner")
    for _, dd in ipairs(dropdowns(NS.Panel.frame)) do assertFalse(dd.arrow:IsShown(), "no second arrow") end
end)

-- ── roles (L8, L9) ──────────────────────────────────────────────────────────────────────────────

--- What the tooltip setters drew for `widget`'s hover: the name's and the first body line's rgb.
local function hoverColors(m, widget)
    local name, body
    local setText, addLine = m.GameTooltip.SetText, m.GameTooltip.AddLine
    m.GameTooltip.SetText = function(_, _, r, g, b) name = { r, g, b } end
    m.GameTooltip.AddLine = function(_, _, r, g, b) body = { r, g, b } end
    widget:__fire("OnEnter")
    m.GameTooltip.SetText, m.GameTooltip.AddLine = setText, addLine
    return name, body
end

local function sameColor(got, r, g, b, what)
    assertTrue(close(got[1], r) and close(got[2], g) and close(got[3], b), what)
end

test("skin: a tooltip's name and body keep Ka0s Default's pixels and take the roles in every other skin", function()
    -- red under: the crossed gtip.value and gtip.title (L8), or a body line that stayed gold under
    -- a skin whose tooltip body is not.
    local NS, m, Skin = setup()
    local b = NS.Panel.frame.applyButton
    local name, body = hoverColors(m, b)
    sameColor(name, 1, 1, 1, "Ka0s Default's name is white")
    sameColor(body, 1, 0.82, 0, "Ka0s Default's body is gold")
    for _, def in ipairs(Skin:Skins()) do
        if def.key ~= "ka0s" then
            NS.ApplySkinChoice("ka0s", def.key)
            local tr, tg, tb = Skin:Color(OWNER, "gtip.title")
            local lr, lg, lb = Skin:Color(OWNER, "gtip.line")
            name, body = hoverColors(m, b)
            sameColor(name, tr, tg, tb, def.key .. ": the name is gtip.title")
            sameColor(body, lr, lg, lb, def.key .. ": the body is gtip.line")
        end
    end
end)

test("skin: the level and copy boxes wear the input role, like the Age box, in every skin", function()
    -- red under: text.highlight written over S.EditBox's color (L8), or a skin with no input.text
    -- handing SetTextColor a nil.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    NS.Filters.Get().smartKeyLevel = false
    NS.Filters.Get().keyTargeting = true
    NS.Panel.Refresh()
    for _, def in ipairs(Skin:Skins()) do
        NS.ApplySkinChoice("ka0s", def.key)
        local r, g, b = Skin:Color(OWNER, "input.text")
        if r == nil then r, g, b = Skin:Color(OWNER, "text.body") end
        sameColor(f.levelBox.__textColor, r, g, b, def.key .. ": the level box")
        sameColor(f.rangeBox.__textColor, r, g, b, def.key .. ": the copy box")
        local lr, lg, lb = Skin:Color(OWNER, "text.body")
        sameColor(f.copyLabel.__textColor, lr, lg, lb, def.key .. ": the copy label")
    end
end)

test("skin: a skin with no input.text gives the boxes text.body", function()
    -- text.body is faked too, because Ka0s Default's two are the same gray.
    -- red under: dimText without its text.body arm.
    local NS = setup()
    local f = NS.Panel.frame
    NS.Filters.Get().smartKeyLevel = false
    NS.Filters.Get().keyTargeting = true
    local real = NS.SkinColor
    NS.SkinColor = function(name)
        if name == "input.text" then return nil end
        if name == "text.body" then return 0.1, 0.2, 0.3 end
        return real(name)
    end
    NS.Panel.Refresh()
    NS.SkinColor = real
    sameColor(f.levelBox.__textColor, 0.1, 0.2, 0.3, "the level box")
    sameColor(f.rangeBox.__textColor, 0.1, 0.2, 0.3, "the copy box")
end)

test("skin: the title follows title.align on a switch", function()
    -- Every shipped skin says CENTER, so a skin that aligns LEFT is registered here, as LibKa0s's own
    -- tests/test_header_band.lua does. Since R5-PG1 the anchor and the justify are S.Header's, which
    -- reads the library's resolved tokens, so faking the facade's Token no longer reaches them.
    -- red under: S.Text alone, which reads no title.align (L9), or a title left on the template's TOP.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    local title = f.TitleContainer.TitleText
    Skin:RegisterSkin({ key = "titleLeft", label = "Title left", tokens = { ["title.align"] = "LEFT" } })
    NS.ApplySkinChoice("ka0s", "titleLeft")
    local band = NS.Skin.Band(f)
    local p, rel, rp, x, y = title:GetPoint(1)
    assertEqual(p, "LEFT"); assertTrue(rel == band, "on the band"); assertEqual(rp, "LEFT")
    assertEqual(x, 24, "the title's inset, clear of the band's left end"); assertEqual(y, 0)
    assertEqual(title.__justifyH, "LEFT")
    NS.ApplySkinChoice("ka0s", "ka0s")
    p, rel, rp, x, y = title:GetPoint(1)
    assertEqual(p, "CENTER", "and back"); assertTrue(rel == band); assertEqual(rp, "CENTER")
    assertEqual(x, 0); assertEqual(y, 0)
    assertEqual(title.__justifyH, "CENTER")
end)

-- ── stand-down ──────────────────────────────────────────────────────────────────────────────────

test("skin: a pick while stood down builds nothing; the stand-up shows the same panel in the new skin", function()
    -- D10: the library repaints recorded frames whatever the latch; the host builds no frame while
    -- stood down.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    NS.addon.Settings.Helpers.Set("enabled", false)
    assertFalse(f:IsShown())
    NS.ApplySkinChoice("ka0s", "obsidian")
    NS.addon.Settings.Helpers.Set("enabled", true)
    assertTrue(rawequal(NS.Panel.frame, f) and f:IsShown(), "the stand-up shows the one panel")
    assertTrue(recorded(Skin, f))
end)

-- ── no typed look values ────────────────────────────────────────────────────────────────────────

test("skin: modules/Panel.lua types no color: no literal SetTextColor, tooltip color or markup", function()
    -- anti-pattern #107: an addon's own frames read colors from the skin, never literals.
    local fh = assert(io.open(T.root .. "/modules/Panel.lua", "rb"))
    local src = fh:read("*a")
    fh:close()
    for line in src:gmatch("[^\n]+") do
        local code = line:gsub("%-%-.*$", "")
        assertFalse(code:find("SetTextColor%(%s*[%d%.]") ~= nil, "a typed text color: " .. line)
        assertFalse(code:find("SetColorTexture%(%s*[%d%.]") ~= nil, "a typed texture color: " .. line)
        assertFalse(code:find("SetText%([^,]+,%s*[%d%.]") ~= nil, "a typed tooltip color: " .. line)
        assertFalse(code:find("|c%x%x%x%x%x%x%x%x") ~= nil, "a typed color escape: " .. line)
    end
end)
