-- tests/test_settings_layout.lua — the General page's layout after item 020 (PG-LY): which row sits
-- on which tab, in what order, under which words.
--
-- Item 020 moves, regroups and relabels only. The first case is its guard: every stored path, its
-- type and its default, in /pgfe list order, pinned as they stood before the item's first edit, so
-- a moved key, a changed default or a lost or added setting fails here whatever else the item does.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse

-- The schema at HEAD before PG-LY (ff1650a): path, type, default. A color default is pinned as its
-- six-digit hex, the form defaults/Profile.lua's REGION_HEX writes it in.
local PINNED = {
    { "enabled",              "bool",  "true" },
    { "state.debugConsole",   "bool",  "false" },
    { "global.minimap.shown", "bool",  "true" },
    { "filtersActive",        "bool",  "true" },
    { "showRegionTags",       "bool",  "true" },
    { "regionColors.oce",     "color", "a330c9" },
    { "regionColors.la",      "color", "3399ff" },
    { "regionColors.chi",     "color", "ff4040" },
    { "regionColors.mex",     "color", "ff9f1c" },
    { "regionColors.bzl",     "color", "00ff98" },
    { "regionColors.eng",     "color", "ff4040" },
    { "regionColors.ger",     "color", "ff7c0a" },
    { "regionColors.fra",     "color", "ffff00" },
    { "regionColors.ita",     "color", "00ff98" },
    { "regionColors.spa",     "color", "3399ff" },
    { "regionColors.por",     "color", "8788ee" },
    { "regionColors.rus",     "color", "a330c9" },
    -- PG-01 (the skinning rollout): the Skin tab's seven rows, appended last (settings/Panel.lua).
    { "skin.source",          "string", "ka0s" },
    { "skin.skin",            "string", "ka0s" },
    { "skin.ignorePanel",     "bool",  "true" },
    { "skin.ignoreFonts",     "bool",  "false" },
    { "skin.font",            "string", "" },
    { "skin.texture",         "string", "" },
    { "skin.pickerSeen",      "bool",  "false" },
}

local function defaultText(row)
    local d = row.default
    if type(d) == "table" then
        local function byte(v) return math.floor(v * 255 + 0.5) end
        return ("%02x%02x%02x"):format(byte(d.r), byte(d.g), byte(d.b))
    end
    return tostring(d)
end

-- red under: any key, type or default change, or a row added, dropped or reordered in the schema
test("layout: every stored path, its type and its default are unchanged by item 020", function()
    local NS = T.newAddon()
    local schema = NS.addon.Settings.Schema
    assertEqual(#schema, #PINNED, "the set of settings")
    for i, pin in ipairs(PINNED) do
        local row = schema[i]
        assertEqual(row.path, pin[1], "row " .. i .. "'s path")
        assertEqual(row.type, pin[2], pin[1] .. "'s type")
        assertEqual(defaultText(row), pin[3], pin[1] .. "'s default")
    end
end)

-- Render the General page as the client does and select one tab; answer the ctx.
local function openTab(NS, m, tab)
    local H = NS.addon.Settings.Helpers
    local p = m.__subcategories["General"]
    p:Show(); p:__fire("OnShow")
    local ctx = H.__panelFor("general")
    H.SelectTab("general", tab)
    return ctx
end

-- Every widget the tab drew, depth first, in draw order.
local function flatten(ctx)
    local out = {}
    local function walk(w)
        out[#out + 1] = w
        for _, c in ipairs(w.children or {}) do walk(c) end
    end
    for _, w in ipairs(ctx.scroll.children) do walk(w) end
    return out
end

local function firstIndex(list, pred)
    for i, w in ipairs(list) do if pred(w) then return i end end
end

test("layout: the region-tag switch leads the Region tags tab, unheaded, beside its colors", function()
    local NS, _, m = T.enableAddon{}
    local H = NS.addon.Settings.Helpers
    local row = H.FindSchema("showRegionTags")
    -- red under: showRegionTags left in FILTER_ROWS
    assertEqual(row.group, "Region tags")
    assertEqual(H.FindSchema("regionColors.oce").group, "Region tags")
    local all = flatten(openTab(NS, m, "Region tags"))
    local boxAt = firstIndex(all, function(w) return w.type == "CheckBox" end)
    local headAt = firstIndex(all, function(w) return w.type == "Heading" end)
    -- red under: renderRegionTab drawing the switch after the portal sections (or not at all)
    assertTrue(boxAt ~= nil, "the switch is drawn")
    assertEqual(all[boxAt].labelText, "Show region tags in the Group Finder")
    assertTrue(boxAt < headAt, "the switch comes before the first portal heading")
    local headings = {}
    for _, w in ipairs(all) do if w.type == "Heading" then headings[#headings + 1] = w.text end end
    -- red under: a "Display" heading over the switch; the old portal headings
    assertEqual(table.concat(headings, " | "), "Americas and Oceania (US realms) | Europe (EU realms)")
end)

test("layout: the color pickers say what each code means; the tag text is unchanged", function()
    local NS, _, m = T.enableAddon{}
    local labels = {}
    for _, w in ipairs(flatten(openTab(NS, m, "Region tags"))) do
        if w.type == "ColorPicker" then labels[#labels + 1] = w.labelText end
    end
    -- red under: the pickers labeled from NS.Regions.LABELS
    assertEqual(table.concat(labels, " | "),
        "OCE \226\128\148 Oceanic | LA \226\128\148 Los Angeles | CHI \226\128\148 Chicago"
        .. " | MEX \226\128\148 Latin America | BZL \226\128\148 Brazil"
        .. " | ENG \226\128\148 English | GER \226\128\148 German | FRA \226\128\148 French"
        .. " | ITA \226\128\148 Italian | SPA \226\128\148 Spanish | POR \226\128\148 Portuguese"
        .. " | RUS \226\128\148 Russian")
    assertEqual(NS.Regions.LABELS.oce, "OCE", "the Group Finder tag text")
end)

test("layout: Reset region tag colors resets the twelve colors only, never the switch", function()
    local NS, _, m = T.enableAddon{}
    local H = NS.addon.Settings.Helpers
    local button
    for _, w in ipairs(flatten(openTab(NS, m, "Region tags"))) do
        if w.type == "Button" then button = w end
    end
    -- red under: the old "Reset region colors" text
    assertEqual(button and button.text, "Reset region tag colors")
    H.Set("showRegionTags", false)
    H.Set("regionColors.oce", { r = 1, g = 1, b = 1, a = 1 })
    -- red under: the switch's row added inside REGION_ROWS
    NS.addon.Settings.ResetRegionColors()
    assertFalse(H.Get("showRegionTags"), "the switch is not a color")
    assertEqual(NS.RegionTags.Hex("oce"), "a330c9")
end)

test("layout: the Filters tab holds the extension's switch and says where the filters are", function()
    local NS, _, m = T.enableAddon{}
    local all = flatten(openTab(NS, m, "Filters"))
    local boxes, texts = {}, {}
    for _, w in ipairs(all) do
        if w.type == "CheckBox" then boxes[#boxes + 1] = w.labelText end
        if w.type == "Label" and type(w.text) == "string" and w.text ~= "" then texts[#texts + 1] = w.text end
    end
    -- red under: the old label, or showRegionTags still on the tab
    assertEqual(table.concat(boxes, " | "), "Use the extension's filters")
    -- red under: drop AFTER_GROUP[FILTER_GROUP]
    assertEqual(texts[#texts], "The filter options are on the panel under Premade Groups Filter's window: "
        .. "open the Group Finder, choose Dungeons, and it appears below PGF's filters.")
end)

test("layout: the filters switch reads true on both surfaces", function()
    local NS = T.newAddon()
    local L = NS.L
    -- red under: the old "Toggle PGF Extension Filters" strings
    assertEqual(L.FILTERS_ACTIVE, "Use the extension's filters")
    assertEqual(L.MSG_INACTIVE, "The extension's filters are off; tick Use the extension's filters first.")
    assertEqual(L.FILTERS_ACTIVE_TOOLTIP, "Off: removes this addon's block from Premade Groups Filter's "
        .. "advanced filter, and Apply does nothing until you tick it again. Your own filter text and the "
        .. "dungeon ticks are left as they are. On: writes the block back from the filter panel's options. "
        .. "The same switch is on the filter panel and in Settings (General > Filters). Separate from "
        .. "Enable, which turns the whole addon off.")
    assertEqual(L.SHOW_REGION_TAGS_TOOLTIP, "Put the group leader's region tag (OCE, LA, CHI, ENG, GER, ...) "
        .. "in front of each Group Finder listing, and each applicant's tag in front of their name. Does "
        .. "nothing while PremadeRegions is loaded, which shows the same tag.")
    assertEqual(L.REGIONS, "Server regions", "the panel's filter keeps its name")
end)

-- The Filters tab's pointer to Premade Groups Filter's own EllesmereUI skin (PG-06, DECISIONS D2):
-- advice, not a gate, and only while EllesmereUI is loaded.
local function filtersTexts(NS, m)
    local texts, boxes = {}, {}
    for _, w in ipairs(flatten(openTab(NS, m, "Filters"))) do
        if w.type == "Label" and type(w.text) == "string" and w.text ~= "" then texts[#texts + 1] = w.text end
        if w.type == "EditBox" then boxes[#boxes + 1] = w end
    end
    return texts, boxes
end

test("layout: without EllesmereUI the Filters tab carries no PGF skin pointer", function()
    local NS, _, m = T.enableAddon{}
    local texts, boxes = filtersTexts(NS, m)
    assertEqual(#boxes, 0)
    for _, t in ipairs(texts) do assertTrue(t:find("EllesmereUI", 1, true) == nil, t) end
end)

test("layout: under EllesmereUI a missing PGF skin is named, with its link right under it", function()
    local NS, _, m = T.enableAddon{ mock = function(mm) mm.installEUI{ pgfSkin = "missing" } end }
    local texts, boxes = filtersTexts(NS, m)
    -- red under: renderPGFSkinAdvice dropped from AFTER_GROUP[FILTER_GROUP]
    assertTrue(texts[#texts]:find("Premade Groups Filter - EllesmereUI Skin is not installed", 1, true) ~= nil,
        texts[#texts])
    assertEqual(#boxes, 1, "the CurseForge link box")
    assertEqual(boxes[1].text, "https://www.curseforge.com/wow/addons/premade-groups-filter-ellesmereui")
end)

test("layout: the link box selects on focus and leaves the pooled editbox frame as it found it", function()
    -- red under: a HookScript (it cannot be undone) or a field left on AceGUI's pooled frame.
    local NS, _, m = T.enableAddon{ mock = function(mm) mm.installEUI{ pgfSkin = "missing" } end }
    local AceGUI = m.LibStub("AceGUI-3.0")
    -- One inner editbox frame for every EditBox, as AceGUI's pool hands it back, with AceGUI's own
    -- focus script on it.
    local pooled, highlights = m.CreateFrame("EditBox"), 0
    pooled.HighlightText = function() highlights = highlights + 1 end
    local aceFocus = function() end
    pooled:SetScript("OnEditFocusGained", aceFocus)
    local function ctor()
        AceGUI.WidgetRegistry.EditBox = nil
        local w = AceGUI:Create("EditBox")
        AceGUI.WidgetRegistry.EditBox = ctor
        w.editbox = pooled
        return w
    end
    AceGUI.WidgetRegistry.EditBox = ctor
    local _, boxes = filtersTexts(NS, m)
    AceGUI.WidgetRegistry.EditBox = nil
    assertEqual(#boxes, 1)
    pooled:__fire("OnEditFocusGained")
    assertEqual(highlights, 1, "focus selects the link")
    boxes[1]:Release()
    assertTrue(rawequal(pooled:GetScript("OnEditFocusGained"), aceFocus), "AceGUI's focus script is back")
    pooled:__fire("OnEditFocusGained")
    assertEqual(highlights, 1, "the next owner of the frame inherits nothing")
    for k in pairs(pooled) do
        assertTrue(type(k) ~= "string" or k:find("pgfe", 1, true) == nil, "field left on the frame: " .. tostring(k))
    end
end)

test("layout: under EllesmereUI a disabled or loaded PGF skin is named, with no link", function()
    for state, words in pairs({ [false] = "is installed but disabled", [true] = "is loaded" }) do
        local NS, _, m = T.enableAddon{ mock = function(mm) mm.installEUI{ pgfSkin = state } end }
        local texts, boxes = filtersTexts(NS, m)
        assertTrue(texts[#texts]:find(words, 1, true) ~= nil, texts[#texts])
        assertEqual(#boxes, 0)
    end
end)

test("layout: the header Defaults describes the reset in Reset all settings' own words", function()
    local NS, _, m = T.enableAddon{}
    local H = NS.addon.Settings.Helpers
    local ctx = openTab(NS, m, H.MASTER_GROUP)
    -- red under: the host's own "Reset every %s setting to its default" string
    assertEqual(ctx.panel.defaultsTooltip, H.ResetAllTooltip())
    assertTrue(H.ResetAllTooltip() ~= "", "a real tooltip from the library")
end)
