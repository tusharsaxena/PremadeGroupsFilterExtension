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

-- options-ui-§15: Master controls holds the mandated rows and nothing else; the two filter
-- switches live on the General page's own Filters tab.
-- red under: put either back in MasterControls extra
test("setup: Master controls holds only the canonical rows", function()
    local NS = T.newAddon()
    local H = NS.addon.Settings.Helpers
    local canonical = { enabled = true, ["state.debugConsole"] = true, ["global.minimap.shown"] = true }
    for _, row in ipairs(NS.addon.Settings.Schema) do
        if row.group == H.MASTER_GROUP then
            assertTrue(canonical[row.path], tostring(row.path) .. " is not a Master controls row")
        end
    end
    for _, path in ipairs({ "filtersActive", "showRegionTags" }) do
        local row = H.FindSchema(path)
        assertTrue(row ~= nil, path)
        assertEqual(row.group, NS.L["Filters"], path .. " group")
        assertEqual(row.page, "general", path .. " page")
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

-- C-09 / PGE-09: the addon holds the performance-§12 no-combat-path exemption, so no harness is
-- wired: no NS.Perf, no `perf` hold, one SavedVariables global, no core\PerfSetup.lua line. The
-- library stays vendored whole (anti-patterns #48), Perf.lua included.
-- red under: restore the PerfDB SavedVariable, the PerfSetup TOC line or NS.HOLD_PERF
test("setup: no perf harness is wired (performance-§12)", function()
    local NS = T.newAddon()
    assertEqual(NS.Perf, nil, "NS.Perf")
    assertEqual(NS.HOLD_PERF, nil, "NS.HOLD_PERF")
    local fh = assert(io.open("PremadeGroupsFilterExtension.toc", "rb"))
    local toc = fh:read("*a"):gsub("\r", "")
    fh:close()
    assertEqual(toc:match("\n## SavedVariables: ([^\n]*)"), "PremadeGroupsFilterExtensionDB")
    for line in toc:gmatch("[^\n]+") do
        if line:sub(1, 1) ~= "#" then
            assertTrue(line ~= "core\\PerfSetup.lua", "the TOC loads core\\PerfSetup.lua")
        end
    end
    local lib = io.open("libs/LibKa0s/Perf.lua", "rb")
    assertTrue(lib ~= nil, "libs/LibKa0s/Perf.lua stays vendored")
    if lib then lib:close() end
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
    assertTrue(seen.logo:find("media\\logos\\premadegroupsfilterextension.logo.tga", 1, true) ~= nil, seen.logo)
    assertEqual(seen.logoSize, nil, "the library's 300x300 default (options-ui-§5)")
    assertEqual(#seen.sections, 1)
    assertEqual(#seen.sections[1].rows(), #NS.COMMANDS)
end)

-- C-23 / PGE-13: the logo assets are named after the addon folder (layout-§4) and rendered at the
-- sizes their consumers draw them: 128 for the TOC icon and the launcher, 512 for the landing page.
local LOGO_DIR = "media/logos/"

local function tgaHeader(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local h = fh:read(18)
    fh:close()
    if not h or #h < 18 then return nil end
    return {
        type   = h:byte(3),
        width  = h:byte(13) + 256 * h:byte(14),
        height = h:byte(15) + 256 * h:byte(16),
        bpp    = h:byte(17),
    }
end

-- red under: point ## IconTexture or the launcher ICON at another file
test("setup: the TOC icon is the launcher icon and the folder-named 128 TGA", function()
    local fh = assert(io.open("PremadeGroupsFilterExtension.toc", "rb"))
    local toc = fh:read("*a"):gsub("\r", "")
    fh:close()
    local icon = toc:match("\n## IconTexture: ([^\n]+)")
    assertTrue(icon ~= nil, "the TOC declares ## IconTexture")
    assertTrue(icon:find("premadegroupsfilterextension%.logo%.128%.tga$") ~= nil, icon)
    local NS = T.enableAddon()
    local obj = NS.Launcher:Object()
    assertTrue(obj ~= nil, "the launcher object is registered")
    assertEqual(obj.icon, icon)
end)

-- red under: skip the 512 render (the landing TGA left at 256x256)
test("setup: logo TGAs are uncompressed 32-bit at their sizes", function()
    for name, size in pairs({ ["premadegroupsfilterextension.logo.128.tga"] = 128,
                              ["premadegroupsfilterextension.logo.tga"] = 512 }) do
        local h = tgaHeader(LOGO_DIR .. name)
        assertTrue(h ~= nil, name .. " is readable")
        assertEqual(h.type, 2, name .. ": uncompressed true-color")
        assertEqual(h.bpp, 32, name .. ": 32 bpp")
        assertEqual(h.width, size, name .. ": width")
        assertEqual(h.height, size, name .. ": height")
    end
end)

-- red under: restore any media/logos/pgfe.logo.* file
test("setup: no pgfe.logo file remains", function()
    for _, ext in ipairs({ "128.tga", "tga", "png" }) do
        local fh = io.open(LOGO_DIR .. "pgfe.logo." .. ext, "rb")
        if fh then fh:close() end
        assertTrue(fh == nil, "media/logos/pgfe.logo." .. ext .. " still exists")
    end
end)
