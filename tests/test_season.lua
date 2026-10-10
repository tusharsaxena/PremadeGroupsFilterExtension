-- tests/test_season.lua — NS.Season (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 3).

local T = _G.PGFE_TEST
local test, assertEqual, assertNil = T.test, T.assertEqual, T.assertNil

test("season: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Season), "table")
end)
test("season: nil map table → nil (loading)", function()
    local NS, _, m = T.newAddon(); m.mapTable = nil
    assertNil(NS.Season.GetDungeons())
end)
test("season: empty map table → nil (loading)", function()
    local NS, _, m = T.newAddon(); m.mapTable = {}
    assertNil(NS.Season.GetDungeons())
end)
test("season: best timed from intimeInfo, untimed → 0, short from PGF keyword", function()
    local NS, _, m = T.newAddon()
    m.mapTable = { 588, 586 }
    m.mapUIInfo[588] = { name = "Altar of Fangs", mapID = 2993 }
    m.mapUIInfo[586] = { name = "Den of Nalorakk", mapID = 2825 }
    m.seasonBest[588] = { intime = { level = 13 }, overtime = { level = 15 } }
    m.seasonBest[586] = { intime = nil, overtime = { level = 12 } }
    local d = NS.Season.GetDungeons()
    assertEqual(d[1].cmID, 588); assertEqual(d[1].bestTimed, 13); assertEqual(d[1].short, "AOF")
    assertEqual(d[2].bestTimed, 0); assertEqual(d[2].short, "DON")
end)
test("season: dungeon never run (GetSeasonBestForMap → nil) → best timed 0", function()
    local NS, _, m = T.newAddon()
    m.mapTable = { 588 }; m.mapUIInfo[588] = { name = "Altar of Fangs", mapID = 2993 }
    assertEqual(NS.Season.GetDungeons()[1].bestTimed, 0)
end)
test("season: unknown mapID falls back to initials", function()
    local NS, _, m = T.newAddon()
    m.mapTable = { 9999 }; m.mapUIInfo[9999] = { name = "New Shiny Place", mapID = 1 }
    assertEqual(NS.Season.GetDungeons()[1].short, "NSP")
end)

-- C-06: the request lives in Season.GetDungeons, so a caller with no panel still asks the server.
test("season: Apply with no panel still requests season data", function()
    local NS, _, m = T.enableAddon{}
    NS.Apply.Run{}
    assertNil(NS.Panel.frame)
    -- red under: move the RequestOnce from GetDungeons back to the panel's readout
    assertEqual(m.mapInfoRequests, 1)
end)
