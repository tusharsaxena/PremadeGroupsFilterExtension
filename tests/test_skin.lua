-- tests/test_skin.lua — the attached panel through the skin (modules/Panel.lua, skinning-§1, §2;
-- PG-02 of the skinning rollout).
--
-- The panel is built twice from one builder: a metal instance that NO primitive ever touches, shown
-- while this owner draws Ka0s Default, so Ka0s Default stays today's PGF-matching chrome by
-- construction; and a skinned twin, built the first time another skin is drawn, painted once through
-- NS.Skin and recorded, so the library replays every later switch onto it. What this suite pins is
-- the host half: which instance shows, that the metal one is never recorded, that the twin's every
-- widget is, that a swap carries the filter state and the panel's shown state across, and that the
-- colors the panel writes itself are the skin's tokens, Ka0s Default's exact pixels on the metal one.
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

local function recorded(Skin, target)
    local rec = Skin.painted[target]
    return rec ~= nil and rec.owner == OWNER
end

local function close(a, b) return math.abs((a or 1) - (b or 1)) < 1e-6 end

-- ── Ka0s Default: the metal instance, untouched ─────────────────────────────────────────────────

test("skin: under Ka0s Default the panel is the metal instance, and no primitive ever touched it", function()
    -- red under: painting the one panel through NS.Skin (since SkinPaint minor 6 every primitive
    -- fades the template's art under Ka0s Default too), or showing the twin on Ka0s Default.
    local NS, _, Skin = setup()
    local f = NS.Panel.frame
    assertTrue(f ~= nil and f:IsShown(), "the panel did not show")
    assertTrue(rawequal(f, NS.Panel.stockFrame), "Ka0s Default shows the metal instance")
    assertEqual(f.__name, FRAME_NAME)
    assertEqual(NS.Panel.skinFrame, nil, "no twin is built while Ka0s Default is drawn")
    for _, w in ipairs(widgets(f)) do assertFalse(recorded(Skin, w), "a metal widget was painted") end
    for _, fs in ipairs(texts(f)) do assertFalse(recorded(Skin, fs), "a metal label was painted") end
    assertTrue(#texts(f) >= 10, "the label walk found the panel's font strings")
end)

test("skin: the colors the metal panel writes are Ka0s Default's exact pixels", function()
    -- red under: a token whose Ka0s Default value is not today's (white labels and boxes, 0.5 gray
    -- dimmed, ffd100 / 808080 readout markup, white tooltip names over a gold body).
    local NS, m = setup()
    local f = NS.Panel.frame
    NS.Filters.Get().smartKeyLevel = true
    NS.Panel.Refresh()
    assertEqual(f.levelBox.__textColor[1], 0.5, "the locked level box is 0.5 gray")
    NS.Filters.Get().smartKeyLevel = false
    NS.Panel.Refresh()
    local c = f.levelBox.__textColor
    assertEqual(c[1], 1); assertEqual(c[2], 1); assertEqual(c[3], 1)
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

-- ── another skin: the twin ──────────────────────────────────────────────────────────────────────

test("skin: another skin shows the twin, painted through the facade; the metal instance hides", function()
    -- red under: no twin (the metal panel left under Obsidian), a twin widget the paint skipped, or
    -- the metal instance painted on the way.
    local NS, _, Skin = setup()
    local stock = NS.Panel.frame
    NS.ApplySkinChoice("ka0s", "obsidian")
    local f = NS.Panel.frame
    assertTrue(f ~= nil and not rawequal(f, stock), "the panel did not swap to the twin")
    assertTrue(rawequal(f, NS.Panel.skinFrame))
    assertTrue(f:IsShown(), "the twin shows where the metal panel showed")
    assertFalse(stock:IsShown(), "the metal instance hides")
    assertTrue(f.__name == nil, "the twin takes no global name")
    for _, w in ipairs(widgets(f)) do assertTrue(recorded(Skin, w), "a twin widget was not painted") end
    for _, fs in ipairs(texts(f)) do assertTrue(recorded(Skin, fs), "a twin label was not painted") end
    for _, w in ipairs(widgets(stock)) do assertFalse(recorded(Skin, w), "a metal widget was painted") end
    assertTrue(Skin.painted[f].calls.Shell ~= nil, "the window is the skin's Shell")
    assertTrue(Skin.painted[f.MaximizeMinimizeFrame.MinimizeButton].calls.PageButton ~= nil)
    assertTrue(Skin.painted[f.activeCheck].calls.Checkbox ~= nil)
    assertTrue(Skin.painted[f.levelBox].calls.EditBox ~= nil)
    assertTrue(Skin.painted[f.presetDropdown].calls.Dropdown ~= nil)
    assertTrue(Skin.painted[f.applyButton].calls.Button ~= nil)
end)

test("skin: back to Ka0s Default shows the untouched metal instance again", function()
    -- red under: a single painted panel (a live switch back would replay Ka0s Default's flat tokens
    -- onto it), or a swap that leaves the twin on show.
    local NS, _, Skin = setup()
    local stock = NS.Panel.frame
    NS.ApplySkinChoice("ka0s", "obsidian")
    local twin = NS.Panel.frame
    NS.ApplySkinChoice("ka0s", "ka0s")
    assertTrue(rawequal(NS.Panel.frame, stock), "Ka0s Default did not bring the metal instance back")
    assertTrue(stock:IsShown()); assertFalse(twin:IsShown())
    for _, w in ipairs(widgets(stock)) do assertFalse(recorded(Skin, w), "a metal widget was painted") end
    NS.ApplySkinChoice("ka0s", "ember")
    assertTrue(rawequal(NS.Panel.frame, twin), "the twin is built once and reused")
end)

test("skin: a swap carries the filter state, and a hidden panel stays hidden", function()
    -- red under: a swap that shows the twin without a Refresh (its widgets read the build-time
    -- filters), or one that shows a panel PGF's dialog does not show.
    local NS, m = setup()
    local stock = NS.Panel.frame
    NS.Filters.Set("keyTargeting", true)
    NS.Filters.Set("keyLevel", 12)
    NS.Panel.Refresh()
    m.pgf.dialog.shown = false
    NS.Panel.UpdateVisibility()
    assertFalse(stock:IsShown())
    NS.ApplySkinChoice("ka0s", "azeroth")
    local f = NS.Panel.frame
    assertFalse(f:IsShown(), "a skin pick never shows a hidden panel")
    assertTrue(f.checks.keyTargeting:GetChecked(), "the twin reads the stored filters")
    assertEqual(f.levelBox:GetText(), "12")
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    assertTrue(f:IsShown()); assertFalse(stock:IsShown())
end)

test("skin: a pick before the panel exists builds only the instance the skin wants", function()
    local NS, m = T.enableAddon{}
    NS.ApplySkinChoice("ka0s", "glass")
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    assertTrue(NS.Panel.frame ~= nil and rawequal(NS.Panel.frame, NS.Panel.skinFrame))
    assertEqual(NS.Panel.stockFrame, nil, "the metal instance is built only when Ka0s Default is drawn")
end)

test("skin: the twin's geometry: 24px check buttons on the rows' centers, flush under the dialog", function()
    -- The skin's Checkbox draws its box 4 inside the frame, so 24 gives a 16px box (PGF's EllesmereUI
    -- skin's); a flat window sits on its rect, so the metal border's 3px raise goes.
    -- red under: the twin keeping the template's 32px boxes or the metal panel's raise.
    local NS = setup()
    NS.ApplySkinChoice("ka0s", "obsidian")
    local f = NS.Panel.frame
    local cb = f.checks.keyTargeting
    assertEqual(cb:GetWidth(), 24); assertEqual(cb:GetHeight(), 24)
    local stock = NS.Panel.stockFrame
    local _, _, _, _, ys = stock.checks.keyTargeting:GetPoint(1)
    local _, _, _, _, yt = cb:GetPoint(1)
    assertEqual(yt, ys - 4, "the smaller box moves down by half the difference")
    assertEqual(cb.__hitRect[2], stock.checks.keyTargeting.__hitRect[2] - 8, "the hit rect still reaches the label")
    local _, _, _, _, y1 = f:GetPoint(1)
    assertEqual(y1, 0)
    assertEqual(f.headerArt, nil, "the twin carries no metal header copies")
end)

test("skin: collapsed, the twin folds to the skin's title band", function()
    local NS, _, Skin = setup()
    NS.ApplySkinChoice("ka0s", "obsidian")
    local f = NS.Panel.frame
    NS.addon.db.profile.panelCollapsed = true
    NS.Panel.Refresh()
    assertEqual(f.__height, Skin:Token(OWNER, "title.height"))
end)

test("skin: the twin writes the skin's colors: locked boxes, the dimmed label, the readout", function()
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
    local hr = Skin:Color(OWNER, "text.highlight")
    assertTrue(close(f.copyLabel.__textColor[1], hr), "the copy label is the skin's text.highlight")
    m.mapTable = { 586 }
    m.mapUIInfo[586] = { name = "D586", mapID = 586 }; m.seasonBest[586] = { intime = { level = 13 } }
    NS.Filters.Get().keyLevel = 14
    NS.Panel.Refresh()
    assertTrue(f.readout:GetText():find(NS.SkinEscape("text.accent") .. "D 13|r", 1, true) ~= nil,
        f.readout:GetText())
end)

-- ── stand-down ──────────────────────────────────────────────────────────────────────────────────

test("skin: a pick while stood down builds nothing; the stand-up shows the skin's instance", function()
    -- D10: the library repaints recorded frames whatever the latch; the host builds no frame while
    -- stood down.
    local NS = setup()
    local stock = NS.Panel.frame
    NS.addon.Settings.Helpers.Set("enabled", false)
    assertFalse(stock:IsShown())
    NS.ApplySkinChoice("ka0s", "obsidian")
    assertEqual(NS.Panel.skinFrame, nil, "no twin is built while stood down")
    NS.addon.Settings.Helpers.Set("enabled", true)
    assertTrue(NS.Panel.skinFrame ~= nil and NS.Panel.skinFrame:IsShown(), "the stand-up shows the twin")
    assertFalse(stock:IsShown())
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
