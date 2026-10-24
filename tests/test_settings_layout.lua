-- tests/test_settings_layout.lua — the General page's layout after item 020 (PG-LY): which row sits
-- on which tab, in what order, under which words.
--
-- Item 020 moves, regroups and relabels only. The first case is its guard: every stored path, its
-- type and its default, in /pgfe list order, pinned as they stood before the item's first edit, so
-- a moved key, a changed default or a lost or added setting fails here whatever else the item does.

local T = _G.PGFE_TEST
local test, assertEqual = T.test, T.assertEqual

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
    { "euiSkin",              "bool",  "true" },
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
