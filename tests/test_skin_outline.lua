-- tests/test_skin_outline.lua — the font outline (LibKa0s v1.82.0, Skin minor 9; PG-01 of
-- Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, ruling D-06): stored as skin.outline
-- ("all", "hud", the default since v1.83.0 and D-10, "off"), written only through the skin write seam (NS.WriteSkinChoice's
-- `media.outline`), and applied with Skin:SetOutline at load, on every profile event and on the row's
-- own write.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local OWNER = "PremadeGroupsFilterExtension"

local function lib(m) return m.LibStub("LibKa0s-Skin-1.0") end
local function profileSkin(NS) return NS.addon.db.profile.skin end
local function set(NS, path, v) return NS.addon.Settings.Helpers.Set(path, v) end

test("outline: a fresh profile stores HUD text only, the library's default", function()
    local NS, _, m = T.bootAddon()
    assertEqual(profileSkin(NS).outline, "hud")
    assertEqual(profileSkin(NS).outline, lib(m).OUTLINE_DEFAULT)
    assertEqual(lib(m):GetOutline(OWNER), "hud")
end)

test("outline: a profile that stored All text keeps it, unmigrated (D-10)", function()
    -- red under: a load-time rewrite of the old default, which would take a player's choice.
    local first = T.bootAddon()
    set(first, "skin.outline", "all")
    local saved = _G.PremadeGroupsFilterExtensionDB
    local NS, _, m = T.bootAddon{ afterFile = function() _G.PremadeGroupsFilterExtensionDB = saved end }
    assertEqual(profileSkin(NS).outline, "all")
    assertEqual(lib(m):GetOutline(OWNER), "all")
end)

test("outline: the schema row offers the library's three modes, in its order", function()
    local NS, _, m = T.newAddon()
    local row = NS.addon.Settings.Helpers.FindSchema("skin.outline")
    assertTrue(row ~= nil, "a skin.outline row")
    assertTrue(row.skipRender == true, "the Skin tab draws it")
    local got = {}
    for _, opt in ipairs(row.values) do got[#got + 1] = opt.value end
    assertEqual(table.concat(got, ","), table.concat(lib(m).OUTLINE_MODES, ","))
end)

test("outline: the write seam stores media.outline, and leaves it alone when it is nil", function()
    -- red under: WriteSkinChoice dropping media.outline (the Skin tab's Font outline and the copy
    -- would move the look and never store it).
    local NS = T.bootAddon()
    NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false, outline = "hud" })
    assertEqual(profileSkin(NS).outline, "hud")
    NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false })
    assertEqual(profileSkin(NS).outline, "hud", "a media without outline leaves it")
    NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false, outline = "off" })
    assertEqual(profileSkin(NS).outline, "off")
end)

test("outline: another addon's copy reaches the store through WriteChoice", function()
    local NS, _, m = T.bootAddon()
    lib(m):WriteChoice(OWNER, "ka0s", "ember", nil, { font = false, texture = false, outline = "off" })
    assertEqual(profileSkin(NS).outline, "off")
end)

test("outline: the row's write applies the mode live", function()
    local NS, _, m = T.bootAddon()
    set(NS, "skin.outline", "hud")
    assertEqual(lib(m):GetOutline(OWNER), "hud")
    assertEqual(NS.Skin.Token("font.outline"), "", "window text loses its outline")
    assertEqual(NS.Skin.Token("hud.outline"), "OUTLINE", "the HUD keeps it")
    set(NS, "skin.outline", "off")
    assertEqual(NS.Skin.Token("hud.outline"), "", "Off takes both")
    set(NS, "skin.outline", "all")
    assertEqual(NS.Skin.Token("font.outline"), "OUTLINE")
end)

test("outline: /pgfe set refuses a mode the library does not know", function()
    local NS = T.bootAddon()
    NS.addon:OnSlashCommand("set skin.outline thick")
    assertEqual(profileSkin(NS).outline, "hud")
end)

test("outline: the stored mode is applied at load", function()
    -- red under: ApplySkinChoice's whole-pair path not applying the stored outline.
    local first = T.bootAddon()
    set(first, "skin.outline", "off")
    local saved = _G.PremadeGroupsFilterExtensionDB
    local _, _, m = T.bootAddon{ afterFile = function() _G.PremadeGroupsFilterExtensionDB = saved end }
    assertEqual(lib(m):GetOutline(OWNER), "off")
end)

test("outline: a profile switch applies the incoming profile's mode, and back", function()
    local NS, _, m = T.bootAddon()
    set(NS, "skin.outline", "all")
    NS.addon.db:SetProfile("Alt")
    assertEqual(lib(m):GetOutline(OWNER), "hud", "Alt keeps the default")
    NS.addon.db:SetProfile("Default")
    assertEqual(lib(m):GetOutline(OWNER), "all", "Default's is back")
end)

test("outline: without the skin engine the apply is a quiet no-op", function()
    local NS = T.bootAddon{ skip = { "libs/LibKa0s/Skin.lua" } }
    assertEqual(NS.ApplySkinOutline(), false)
    set(NS, "skin.outline", "off")
    assertEqual(profileSkin(NS).outline, "off", "the store still takes the write")
end)
