-- tests/test_surface_parity.lua — every degradation stub carries the live surface (testing-§8).
--
-- Each case loads the addon with the whole LibKa0s payload ABSENT (the loader skips its files)
-- and compares the stub against the live instance the runner registered by major name. A member
-- the live module has and the stub lacks is a crash moved to the one install the stub exists for.

local T = _G.PGFE_TEST
local test = T.test

local NO_LIBKA0S = T.loadAddon.libFiles

test("parity: the Core seam's namespace surface survives the library's absence", function()
    local live = T.newAddon()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(live, degraded, "the addon namespace (Core seam)")
    T.assertSurfaceParity(live.Util, degraded.Util, "NS.Util (Core printer seam)")
end)

test("parity: the DebugLog stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.DebugLog, "LibKa0s-DebugLog-1.0", {
        "FormatPlain", "FormatColored",
    })
end)

test("parity: the Slash stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.SlashCommands, "LibKa0s-Slash-1.0")
end)

test("parity: the Options helpers stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.addon.Settings.Helpers, "LibKa0s-Options-1.0", {
        "PADDING_X", "ROW_VSPACER", "SECTION_HEADING_H", "BUTTON_PAIR_REL",
        "CHROME_GAP", "TAB_H", "BANNER_H",
        "AceGUI",
        "BuildLandingPage", "RestoreDefaults",
        "FONT_FLAGS", "FONT_FLAGS_SORT", "VISIBILITY_VALUES", "VISIBILITY_SORT",
        "MASTER_GROUP", "CLASS_COLOR_NOTE",
    })
end)

test("parity: the Schema host stub's instance carries the whole live instance surface", function()
    local live = T.newAddon()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(live.SchemaRuntime, degraded.SchemaRuntime, "schema instance vs host stub")
end)

test("parity: the Schema host stub carries the library's own members", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.addon.Settings.SchemaLib, "LibKa0s-Schema-1.0", { "STRINGS" })
end)

test("parity: the Launcher stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.Launcher, "LibKa0s-Launcher-1.0")
end)

test("parity: the Lifecycle stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.Lifecycle, "LibKa0s-Lifecycle-1.0")
end)

-- The Perf stub answers only what the addon calls: the bracket idiom (`on`, `Note`), the latch
-- view (`suspended`) and the `perf` verb (`OnCommand`). Everything else on the instance is the
-- library's own capture machinery, reached by nothing in this addon.
test("parity: the Perf stub carries every member the addon calls", function()
    local live = T.newAddon().Perf
    local degraded = T.newAddon{ skip = NO_LIBKA0S }.Perf
    for _, k in ipairs({ "on", "Note", "OnCommand" }) do
        T.assertEqual(type(degraded[k]), type(live[k]), "Perf." .. k)
    end
    T.assertEqual(degraded.suspended, false)
    T.assertEqual(live.suspended, false)
end)

test("parity: the Compat arm carries every library member the addon wires", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.Compat, "LibKa0s-Compat-1.0", {
        "IsSecret", "CanAccess", "IsSafeKey",
        "GetSpellInfo", "GetSpellName", "GetSpellTexture", "GetSpellCooldown",
    })
end)
