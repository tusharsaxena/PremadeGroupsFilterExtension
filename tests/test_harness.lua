-- tests/test_harness.lua — the harness itself: factories, TOC-derived load list, mock fields.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

test("harness: the load list is derived from the TOC, in TOC order", function()
    local Loader = dofile("tests/_kit/loader.lua")
    local fresh = Loader.tocFiles("PremadeGroupsFilterExtension.toc")
    assertEqual(#T.loadAddon.tocFiles, #fresh)
    for i, rel in ipairs(fresh) do assertEqual(T.loadAddon.tocFiles[i], rel, "toc line " .. i) end
    assertEqual(fresh[1], "locales/enUS.lua")
end)

test("harness: every factory returns (NS, env, mock) with env and mock the same table", function()
    for _, name in ipairs({ "newAddon", "bootAddon", "enableAddon" }) do
        local NS, env, m = T[name]()
        assertTrue(NS.addon == NS, name .. ": NS is the addon object")
        assertTrue(env == m, name .. ": env and mock are one table")
        assertTrue(m._G == m, name .. ": the mock is its own _G")
    end
end)

test("harness: the PGF fake is installed before the addon loads", function()
    local _, _, m = T.newAddon()
    assertTrue(m.PremadeGroupsFilter and m.PremadeGroupsFilter.Debug ~= nil)
    assertTrue(m.PremadeGroupsFilterDialog == m.pgf.dialog)
    assertTrue(m.PremadeGroupsFilterDungeonPanel == m.pgf.panel)
    assertTrue(m.PremadeGroupsFilterState == m.pgf.state)
    assertNil(m.PremadeRegions)
end)

test("harness: factory opts seed the mock fields", function()
    local _, _, m = T.newAddon{ currentRegion = 3, realmName = "Silvermoon", specID = 262,
        role = "HEALER", classFile = "SHAMAN", inCombat = true, mapTable = { 1, 2 } }
    assertEqual(m.GetCurrentRegion(), 3)
    assertEqual(m.GetRealmName(), "Silvermoon")
    assertEqual(m.InCombatLockdown(), true)
    assertEqual(select(2, m.UnitClass("player")), "SHAMAN")
    assertEqual(m.GetSpecializationInfo(1), 262)
    assertEqual(select(5, m.GetSpecializationInfo(1)), "HEALER")
    assertEqual(#m.C_ChallengeMode.GetMapTable(), 2)
end)

test("harness: client-data mock fields answer through their APIs", function()
    local _, _, m = T.newAddon()
    assertNil(m.C_ChallengeMode.GetMapTable())
    m.mapUIInfo[588] = { name = "Altar of Fangs", mapID = 2993 }
    local name, id, _, _, _, mapID = m.C_ChallengeMode.GetMapUIInfo(588)
    assertEqual(name, "Altar of Fangs"); assertEqual(id, 588); assertEqual(mapID, 2993)
    m.seasonBest[588] = { intime = { level = 13 }, overtime = { level = 15 } }
    local intime, overtime = m.C_MythicPlus.GetSeasonBestForMap(588)
    assertEqual(intime.level, 13); assertEqual(overtime.level, 15)
    assertNil(m.C_MythicPlus.GetSeasonBestForMap(1))
end)

test("harness: hooksecurefunc is a real post-hook on a table member", function()
    local _, _, m = T.newAddon()
    local order = {}
    local t = { f = function(x) order[#order + 1] = "orig" .. x; return "r" end }
    m.hooksecurefunc(t, "f", function(x) order[#order + 1] = "hook" .. x end)
    assertEqual(t.f(1), "r")
    assertEqual(table.concat(order, ","), "orig1,hook1")
end)

test("harness: fireEvent dispatches to AceEvent handlers", function()
    local NS, _, m = T.bootAddon()
    local seen = 0
    function NS.addon.OnTestEvent() seen = seen + 1 end
    NS.addon:RegisterEvent("PLAYER_ENTERING_WORLD", "OnTestEvent")
    m.fireEvent("PLAYER_ENTERING_WORLD")
    assertEqual(seen, 1)
end)

test("harness: the explicit LibKa0s list matches LibKa0s.xml, in XML order (anti-pattern #48)", function()
    local fh = assert(io.open("libs/LibKa0s/LibKa0s.xml", "rb"))
    local xml = fh:read("*a")
    fh:close()
    local want = {}
    for file in xml:gmatch('<Script file="([^"]+)"') do want[#want + 1] = "libs/LibKa0s/" .. file end
    local got = T.loadAddon.libFiles
    assertEqual(#got, #want, "LibKa0s file count")
    for i, path in ipairs(want) do assertEqual(got[i], path, "LibKa0s.xml entry " .. i) end
end)

-- The raw TOC, CR stripped. Loader.tocFiles drops comments and every libs\ line, so the TOC
-- checks below read the file themselves.
local function rawTocLines()
    local fh = assert(io.open("PremadeGroupsFilterExtension.toc", "rb"))
    local text = fh:read("*a")
    fh:close()
    local lines = {}
    for line in (text:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
    return lines
end

-- The first line of the annotation block above lines[i], or "" when there is none.
local function annotationHead(lines, i)
    local first = i
    while first > 1 and lines[first - 1]:sub(1, 1) == "#" and lines[first - 1]:sub(1, 2) ~= "##" do
        first = first - 1
    end
    -- A section heading opens its block right after a blank line; it is not an annotation.
    while first < i and (first == 1 or lines[first - 1] == "") do first = first + 1 end
    return first < i and lines[first] or ""
end

-- C-21 / PGE-06/07/08/28: every addon file's TOC line says what it needs at load. The annotation is
-- the contiguous `#` block directly above the file line, minus a section heading (a comment line
-- right after a blank line). Its FIRST line carries the marker, so a two-line annotation passes.
-- red under: delete one per-line annotation (e.g. the `# Conventional:` above core\Database.lua)
test("harness: every addon file in the TOC is annotated", function()
    local lines = rawTocLines()
    local MARKERS = { "^# LOAD%-BEARING:", "^# Conventional", "^# LAST" }
    local checked = 0
    for i, line in ipairs(lines) do
        local isFile = line ~= "" and line:sub(1, 1) ~= "#"
        if isFile and not line:find("^libs\\") and not line:find("^locales\\") then
            local head = annotationHead(lines, i)
            local ok = false
            for _, m in ipairs(MARKERS) do if head:find(m) then ok = true end end
            assertTrue(ok, "toc:" .. i .. " " .. line .. " has no annotation (got '" .. head .. "')")
            checked = checked + 1
        end
    end
    assertTrue(checked > 20, "the TOC walk saw the addon files (" .. checked .. ")")
end)

-- C-35 / PGE-20: nothing schedules a timer, so AceTimer is neither mixed in nor loaded. The TOC half
-- reads the raw file: Loader.tocFiles drops every libs\ line, so it could never see the library.
-- red under: restore the AceTimer-3.0 mixin in core\PGFE.lua, or the TOC line
test("harness: AceTimer is not embedded", function()
    local NS = T.newAddon()
    assertNil(NS.addon.ScheduleTimer, "the AceTimer mixin is not embedded")
    for i, line in ipairs(rawTocLines()) do
        assertTrue(not line:find("AceTimer%-3%.0"), "toc:" .. i .. " names AceTimer-3.0")
    end
end)
