-- tests/test_glyphs.lua — the display-glyph guard over this addon's own Lua (LibKa0s v1.82.0, kit
-- revision 45's tests/_kit/glyphs.lua; PG-03 of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, ruling D-19).
--
-- Ten skins draw this addon's text in a dozen faces, and a character one of them lacks is a box in
-- that skin only. So every string literal in a tracked .lua file outside libs/ and tests/ carries
-- only characters every shipped face draws (the kit's safe set, read from their cmaps). The one
-- region outside it is defaults/Realms.lua's NS.RealmLists, marked `glyph: data`: the Russian
-- realm names are Cyrillic, which no shipped face draws, but they are lookup keys only. What the
-- player sees of a region is Regions.LABELS, pinned safe below.

local T = _G.PGFE_TEST
local test, assertTrue = T.test, T.assertTrue

test("glyphs: display strings use only characters every shipped skin face draws", function()
    -- red under: a character outside the kit's safe set in a string the addon paints in a skin face.
    T.assertDisplayGlyphs{ label = "PremadeGroupsFilterExtension" }
end)

test("glyphs: the region labels a tag or the panel paints are glyph-safe", function()
    -- red under: a label (RegionTags' row tag, the panel's region checkboxes) carrying a character a
    -- shipped face cannot draw, which the data mark over the realm lists would not excuse.
    local NS = T.newAddon()
    for _, key in ipairs(NS.Regions.ALL_KEYS) do
        local label = NS.Regions.LABELS[key]
        assertTrue(type(label) == "string", "a label for the " .. key .. " region key")
        T.assertGlyphSafe(label, "the " .. key .. " region label")
    end
    local n = 0
    for _ in pairs(NS.Regions.LABELS) do n = n + 1 end
    assertTrue(n == #NS.Regions.ALL_KEYS, "no label without a region key")
end)

test("glyphs: the realm lists' data mark is the only exemption the guard needs", function()
    -- red under: the mark dropped (the Cyrillic keys would fail the guard), or a hit found outside
    -- the RealmLists table (the mark would be hiding a displayed string).
    local f = assert(io.open(T.root .. "/defaults/Realms.lua", "rb"))
    local text = f:read("*a"); f:close()
    local stripped = text:gsub("%-%- glyph: data [^\r\n]*", "--")
    local hits = T.scanGlyphSource(stripped, "defaults/Realms.lua", {})
    assertTrue(#hits > 0, "the realm lists carry characters outside the safe set")
    local first = text:find("NS.RealmLists = {", 1, true)
    local startLine = select(2, text:sub(1, first):gsub("\n", "")) + 1
    local close = assert(text:find("\n}\r?\n%-%- glyph: data end", first), "the table closes before the end mark")
    local endLine = select(2, text:sub(1, close):gsub("\n", "")) + 1
    for _, h in ipairs(hits) do
        assertTrue(h.line > startLine and h.line < endLine,
            "hit at line " .. h.line .. " lies inside NS.RealmLists")
    end
end)
