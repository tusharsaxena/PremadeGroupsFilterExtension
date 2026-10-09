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
