-- tests/test_layers.lua — frame layering (frame-layering, standard v2.88.0; item 030 of the
-- 2026-10-24 run): the one layers table in core/Constants.lua, the attached panel's host-matched
-- strata and its level band, and the borrowed StaticPopups lifted over the panel while it shows.
--
-- The kit's frame-layer recorder (tests/_kit/mock_layers.lua) is installed after the addon loads:
-- every PGFE file reaches CreateFrame through the global at call time, so the frames the panel
-- builds answer strata and level back.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

-- An enabled instance whose PGF dialog stands at `strata` / `level`, with the recorder installed.
local function layered(strata, level)
    local NS, _, m = T.enableAddon{}
    m.NineSliceUtil = { GetLayout = function() return {} end, ApplyLayout = function() end }
    local restore = dofile("tests/_kit/mock_layers.lua")(m)
    local dialog = m.pgf.dialog
    dialog.GetFrameLevel = function() return level or 20 end
    if strata then dialog.GetFrameStrata = function() return strata end end
    return NS, m, restore
end

local function readSource(rel)
    local fh = assert(io.open(T.root .. "/" .. rel, "rb"))
    local src = fh:read("*a"); fh:close()
    return src
end

local SOURCES = {
    "core/Constants.lua", "core/Popup.lua", "modules/Panel.lua",
    "settings/Panel.lua", "settings/Slash.lua", "settings/Schema.lua",
}

test("layers: one table names the strata and every level offset", function()
    local NS = T.newAddon()
    local LAYERS = NS.Constants and NS.Constants.LAYERS
    -- red under: no core/Constants.lua
    assertEqual(type(LAYERS), "table")
    assertEqual(LAYERS.STRATA.POPUP, "FULLSCREEN_DIALOG", "a borrowed confirmation lifted while shown (T8)")
    assertEqual(LAYERS.LEVEL.ABOVE_HOST, 5)
    assertEqual(LAYERS.LEVEL.HEADER_ART, 0, "sunk to the panel's own level")
    -- red under: an offset left behind by the retired EllesmereUI bridge (PG-06)
    assertEqual(LAYERS.LEVEL.ACCENT_RING, nil)
end)

-- PRE-Z01: the panel reads its host's strata; a PGF release that moves its dialog takes the panel along.
test("layers: the panel takes PGF's dialog strata by reading it, never a literal", function()
    local NS, m, restore = layered("HIGH", 20)
    local f = NS.Panel.Create()
    local got = m.__layers(f)
    restore()
    -- red under: f:SetFrameStrata("FULLSCREEN")
    assertEqual(got.strata, "HIGH")
    assertEqual(got.level, 25, "the dialog's level + ABOVE_HOST")
end)

test("layers: a host that cannot answer its strata leaves the panel inheriting it", function()
    local NS, m, restore = layered(nil, 20)
    local f = NS.Panel.Create()
    local own = rawget(f, "__strata")
    restore()
    assertNil(own, "no strata written")
    assertEqual(m.__layers(f).level, 25)
end)

-- PRE-Z06: the band the panel's frames sit in, in one place.
test("layers: the panel's level band (L, header art L, chrome L+1, widgets L+2)", function()
    local NS, m, restore = layered("FULLSCREEN", 20)
    local f = NS.Panel.Create()
    local L = m.__layers(f).level
    local lv = function(fr) return m.__layers(fr).level end
    local got = {
        strata = m.__layers(f).strata,
        clips = { lv(f.headerArt[1]), lv(f.headerArt[2]) },
        slices = { lv(f.headerArt[1].__children[1]), lv(f.headerArt[2].__children[1]) },
        body = lv(f.body), minmax = lv(f.MaximizeMinimizeFrame), header = lv(f.headerClick),
        check = lv(f.checks[1] or f.body.__children[1]), apply = lv(f.applyButton),
    }
    restore()
    assertEqual(L, 25)
    assertEqual(got.strata, "FULLSCREEN")
    for i = 1, 2 do
        assertEqual(got.clips[i], L, "header clip " .. i)
        assertEqual(got.slices[i], L, "header slice " .. i)
    end
    assertEqual(got.body, L + 1); assertEqual(got.minmax, L + 1); assertEqual(got.header, L + 1)
    assertEqual(got.check, L + 2); assertEqual(got.apply, L + 2)
end)

-- PRE-Z03: a PGFE popup shown while the FULLSCREEN panel is up is lifted over it, and put back.
local function popupFrame(m)
    local p = m.CreateFrame("Frame", "StaticPopup1", m.UIParent)
    p:SetFrameStrata("DIALOG")
    return p
end

test("layers: a popup shown over the visible panel is lifted, and put back to what it was", function()
    local NS, m, restore = layered("FULLSCREEN", 20)
    NS.Panel.Create(); NS.Panel.UpdateVisibility()
    assertTrue(NS.Panel.frame:IsVisible())
    local p = popupFrame(m)
    p:SetFrameStrata("HIGH")   -- whatever the shared frame held, not a hard-coded DIALOG
    local shown
    m.StaticPopup_Show = function(which, ...) shown = { which, ... }; return p end
    -- red under: no NS.ShowPopup
    assertEqual(NS.ShowPopup("PGFE_PRESET_DELETE", "Farm", nil, "Farm"), p)
    assertEqual(table.concat(shown, ",", 1, 2), "PGFE_PRESET_DELETE,Farm")
    assertEqual(shown[4], "Farm", "the data argument passes through")
    assertEqual(p:GetFrameStrata(), "FULLSCREEN_DIALOG")
    NS.ShowPopup("PGFE_PRESET_DELETE", "Farm", nil, "Farm")   -- shown again while lifted
    m.StaticPopupDialogs.PGFE_PRESET_DELETE.OnHide(p)
    assertEqual(p:GetFrameStrata(), "HIGH", "the recorded strata, not FULLSCREEN_DIALOG")
    m.StaticPopupDialogs.PGFE_PRESET_DELETE.OnHide(p)          -- a second hide is a no-op
    assertEqual(p:GetFrameStrata(), "HIGH")
    restore()
end)

test("layers: with the panel not visible the popup keeps the client's strata", function()
    local NS, m, restore = layered("FULLSCREEN", 20)
    local p = popupFrame(m)
    m.StaticPopup_Show = function() return p end
    NS.ShowPopup("PREMADEGROUPSFILTEREXTENSION_RESET_ALL")          -- panel never built
    assertEqual(p:GetFrameStrata(), "DIALOG")
    NS.Panel.Create(); NS.Panel.frame:Hide()
    NS.ShowPopup("PREMADEGROUPSFILTEREXTENSION_RESET_ALL")          -- built, hidden
    assertEqual(p:GetFrameStrata(), "DIALOG")
    m.StaticPopup_Show = function() return nil end                  -- the client refused it
    NS.Panel.UpdateVisibility()
    assertNil(NS.ShowPopup("PREMADEGROUPSFILTEREXTENSION_RESET_ALL"))
    restore()
end)

test("layers: every PGFE popup spec restores on hide", function()
    local NS, _, m = T.enableAddon{}
    NS.Panel.Create()
    NS.addon.Settings.EnsureResetPopup()
    -- red under: no NS.RestorePopupStrata (nil == nil would pass the loop below)
    assertEqual(type(NS.RestorePopupStrata), "function")
    for _, which in ipairs({ "PGFE_PRESET_SAVE_AS", "PGFE_PRESET_DELETE",
            "PREMADEGROUPSFILTEREXTENSION_RESET_ALL" }) do
        local spec = m.StaticPopupDialogs[which]
        assertTrue(spec ~= nil, which .. " defined")
        assertTrue(spec.OnHide == NS.RestorePopupStrata, which .. " OnHide")
    end
end)

-- frame-layering-§5: every strata and level write reads the table; every popup goes through the lift.
test("layers: no strata literal, no absolute level, no direct StaticPopup_Show", function()
    for _, rel in ipairs(SOURCES) do
        local src = readSource(rel)
        assertFalse(src:find('SetFrameStrata%("') ~= nil, rel .. " restates a strata")
        assertFalse(src:find("SetFrameLevel%(%s*%d") ~= nil, rel .. " sets an absolute level")
        if rel ~= "core/Popup.lua" then
            -- red under: StaticPopup_Show(POPUP_SAVE_AS) in modules/Panel.lua
            assertFalse(src:find("StaticPopup_Show%(") ~= nil, rel .. " calls StaticPopup_Show directly")
        end
    end
end)
