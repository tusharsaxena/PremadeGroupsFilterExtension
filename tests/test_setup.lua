-- tests/test_setup.lua — the addon object, the AceDB defaults and the setup seams' wiring.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

test("setup: NS is the AceAddon object, with the cyan [PGFE] tag", function()
    local NS = T.newAddon()
    assertTrue(NS.addon == NS)
    assertEqual(NS.PREFIX, "|cff00ffff[PGFE]|r")
    assertEqual(NS.version, "0.1.0")
end)

test("setup: NS.Print is reclaimed from AceConsole and is NS.Util.print", function()
    local NS, _, m = T.newAddon()
    assertTrue(NS.Print == NS.Util.print)
    NS.Print("hello")
    assertTrue(m.prints[#m.prints]:find("hello", 1, true) ~= nil)
    assertTrue(m.prints[#m.prints]:find("[PGFE]", 1, true) ~= nil)
end)

test("setup: per-character filter defaults (char.filters)", function()
    local NS = T.bootAddon()
    local f = NS.addon.db.char.filters
    assertTrue(f.keyTargeting); assertEqual(f.keyLevel, 10)
    assertTrue(f.regionsEnabled); assertEqual(next(f.regions), nil)
    assertTrue(f.playstyleEnabled); assertEqual(next(f.playstyles), nil)
    assertTrue(f.compositionEnabled)
    assertFalse(f.noSameSpec); assertFalse(f.noSameClassRole); assertFalse(f.experiencedLeader)
    assertEqual(f.minScoreEnabled, nil); assertEqual(f.minScore, nil) -- removed: PGF's M+ Rating row
    assertFalse(f.maxAgeEnabled); assertEqual(f.maxAge, 15)
end)

test("setup: global defaults hold the presets store and LibDBIcon's table", function()
    local NS = T.bootAddon()
    local g = NS.addon.db.global
    assertEqual(type(g.presets), "table")
    assertEqual(g.minimap.hide, false)
end)

test("setup: profile defaults hold the master switch and the panel's collapsed state", function()
    local NS = T.bootAddon()
    assertTrue(NS.addon.db.profile.enabled)
    assertFalse(NS.addon.db.profile.panelCollapsed)
end)

test("setup: migrations stamp the schema version", function()
    local NS = T.bootAddon()
    assertEqual(NS.addon.db.global.schemaVersion, NS.SCHEMA_VERSION)
    assertEqual(NS.SCHEMA_VERSION, 1)
end)

test("setup: the Master controls rows are in the schema, frameless", function()
    local NS = T.newAddon()
    local H = NS.addon.Settings.Helpers
    assertTrue(H.FindSchema("enabled") ~= nil)
    assertTrue(H.FindSchema("state.debugConsole") ~= nil)
    assertTrue(H.FindSchema("global.minimap.shown") ~= nil)
    for _, absent in ipairs({ "scale", "alpha", "locked", "visibility", "state.testMode" }) do
        assertEqual(H.FindSchema(absent), nil, absent .. " is not a row")
    end
end)

test("setup: the Minimap button row inverts onto LibDBIcon's hide", function()
    local NS = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    assertTrue(H.Get("global.minimap.shown"))
    H.Set("global.minimap.shown", false)
    assertTrue(NS.addon.db.global.minimap.hide)
    assertEqual(NS.addon.db.global.minimap.shown, nil)
end)

test("setup: enable registers the settings category and the launcher, and stands up", function()
    local NS, _, m = T.enableAddon()
    assertTrue(NS.addon._settingsRegistered)
    assertTrue(m.__mainPanel ~= nil)
    assertTrue(NS.Launcher:IsRegistered())
    assertFalse(NS.IsStoodDown())
end)

test("setup: the debug console is built with the addon's folder and brand", function()
    local NS = T.newAddon()
    assertEqual(type(NS.DebugLog.Debug), "function")
    assertTrue(NS.Debug == NS.DebugLog.Debug)
    assertEqual(type(NS.DebugAtEnable), "function")
end)

test("setup: the perf harness is wired to the lifecycle latch, with no bucket declared yet", function()
    local NS = T.newAddon()
    assertFalse(NS.Perf.on)
    assertFalse(NS.Perf.suspended)
    assertEqual(#NS.Perf.BUCKET_ORDER, 0)
end)

test("setup: the Compat spec readers route through LibKa0s-Compat-1.0", function()
    local NS = T.newAddon{ specID = 262, role = "HEALER" }
    assertEqual(NS.Compat.GetSpecialization(), 1)
    local specID, _, _, _, role = NS.Compat.GetSpecializationInfo(1)
    assertEqual(specID, 262); assertEqual(role, "HEALER")
end)

test("setup: the media seam names this addon's folder", function()
    local NS = T.newAddon()
    local path = NS.Icon("close")
    assertTrue(path and path:find("PremadeGroupsFilterExtension", 1, true) ~= nil)
    assertTrue(type(NS.FONT_MONO) == "string")
end)

test("setup: the landing page lists every NS.COMMANDS row", function()
    local NS = T.newAddon()
    local rows = NS.SlashCommands:LandingRows()
    assertEqual(#rows, #NS.COMMANDS)
end)

-- Owner report: the landing page showed the logo twice, the second under the Slash Commands
-- heading. A private body drew it on a pooled AceGUI frame and never took it off; the library's
-- BuildLandingPage hides it on release. The page body must go through the library's builder.
test("setup: the landing page is drawn by the library's BuildLandingPage, logo and commands", function()
    local NS = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    local seen
    local real = H.BuildLandingPage
    H.BuildLandingPage = function(ctx, spec) seen = spec; return real(ctx, spec) end
    H.BuildMainContent({})
    H.BuildLandingPage = real
    -- red under: the private addLogo / addCommandRows body in settings/Panel.lua
    assertTrue(seen ~= nil, "BuildMainContent delegates to the library")
    assertTrue(seen.logo:find("media\\logos\\pgfe.logo.tga", 1, true) ~= nil, seen.logo)
    assertEqual(seen.logoSize, nil, "the library's 300x300 default (options-ui-§5)")
    assertEqual(#seen.sections, 1)
    assertEqual(#seen.sections[1].rows(), #NS.COMMANDS)
end)
