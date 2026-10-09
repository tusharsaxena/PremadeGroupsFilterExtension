-- tests/test_apply.lua — NS.Apply (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 7).

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local function seasonFromScreenshot(m)
    m.mapTable = { 586, 587, 250, 585, 588, 399, 584, 249 }
    local best = { [586]=14, [587]=14, [250]=14, [585]=14, [588]=13, [399]=13, [584]=13, [249]=13 }
    for id, lvl in pairs(best) do
        m.mapUIInfo[id] = { name = "D" .. id, mapID = id }
        m.seasonBest[id] = { intime = { level = lvl } }
    end
end

local function printed(m, needle)
    for _, line in ipairs(m.prints) do
        if line:find(needle, 1, true) then return true end
    end
    return false
end

test("apply: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Apply), "table")
end)

test("apply: N=14 ticks AOF/RLP/BV/KR, writes block, triggers, searches", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get(); f.keyLevel = 14; f.maxAgeEnabled = true; f.maxAge = 15
    local ok = NS.Apply.Run{ search = true }
    assertTrue(ok)
    local s = m.pgf.panel.state
    assertTrue(s.dungeon5 and s.dungeon6 and s.dungeon7 and s.dungeon8)
    assertFalse(s.dungeon1 or s.dungeon2 or s.dungeon3 or s.dungeon4)
    assertEqual(NS.Expression.Normalize(s.expression), "( not pgfe_on or ( age <= 15 ) )")
    assertEqual(m.pgf.calls.trigger, 1); assertEqual(m.pgf.calls.refresh, 1)
    assertEqual(NS.Apply.LastRange, "14-14")
end)

test("apply: everything timed → refuses, nothing written", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().keyLevel = 2
    local ok, key = NS.Apply.Run{ search = true }
    assertFalse(ok); assertEqual(key, "MSG_ALL_TIMED"); assertEqual(m.pgf.calls.trigger, 0)
end)

test("apply: combat, wrong category, missing PGF seam, loading", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    m.inCombat = true
    assertEqual(select(2, NS.Apply.Run{}), "MSG_COMBAT"); m.inCombat = false
    m.pgf.dialog.activeId = "c3f0"
    assertEqual(select(2, NS.Apply.Run{}), "MSG_NOT_DUNGEONS"); m.pgf.dialog.activeId = "c2f4"
    local refresh = m.pgf.dialog.RefreshButton
    m.pgf.dialog.RefreshButton = nil
    local _, key, missing = NS.Apply.Run{}
    assertEqual(key, "MSG_NO_PGF"); assertEqual(missing, "Dialog.RefreshButton")
    m.pgf.dialog.RefreshButton = refresh
    m.mapTable = nil
    assertEqual(select(2, NS.Apply.Run{}), "MSG_LOADING")
    assertEqual(m.pgf.calls.trigger, 0)
end)

test("apply: invalid options refuse before anything is written", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get()
    f.keyLevel = 99
    assertEqual(select(2, NS.Apply.Run{}), "MSG_BAD_LEVEL"); f.keyLevel = 14
    f.maxAgeEnabled = true; f.maxAge = 0
    assertEqual(select(2, NS.Apply.Run{}), "MSG_BAD_AGE")
    assertEqual(m.pgf.calls.trigger, 0)
end)

test("apply: key targeting off leaves checkboxes alone; no search when not requested", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    m.pgf.panel.state.dungeon1 = true
    local f = NS.Filters.Get(); f.keyTargeting = false; f.noSameSpec = true
    assertTrue((NS.Apply.Run{ search = false }))
    assertTrue(m.pgf.panel.state.dungeon1); assertEqual(m.pgf.calls.refresh, 0)
end)

test("apply: keeps user text; clear restores it", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    m.pgf.panel.state.expression = "voice or myrealm"
    -- keyLevel 14: at the default 10 every screenshot dungeon is timed and Run refuses.
    local f = NS.Filters.Get(); f.keyLevel = 14; f.noSameSpec = true
    NS.Apply.Run{}
    assertEqual(NS.Expression.Normalize(m.pgf.panel.state.expression),
        "( not pgfe_on or ( pgfe_samespec == 0 ) ) and ( voice or myrealm )")
    NS.Apply.Clear()
    assertEqual(m.pgf.panel.state.expression, "voice or myrealm")
end)

test("apply: a damaged managed block refuses Apply and Clear", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    m.pgf.panel.state.expression = NS.Expression.MARK_BEGIN .. "\n( age <= 5 )"
    local f = NS.Filters.Get(); f.keyLevel = 14; f.noSameSpec = true
    assertEqual(select(2, NS.Apply.Run{}), "MSG_DAMAGED")
    assertEqual(select(2, NS.Apply.Clear()), "MSG_DAMAGED")
end)

test("apply: /pgfe apply searches and prints; /pgfe clear prints", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().keyLevel = 14
    m.prints = {}
    NS.addon:OnSlashCommand("apply")
    assertEqual(m.pgf.calls.refresh, 1)
    assertTrue(printed(m, NS.L.MSG_APPLIED:format(4, "14-14")))
    m.prints = {}
    NS.addon:OnSlashCommand("clear")
    assertTrue(printed(m, NS.L.MSG_CLEARED))
end)

test("apply: /pgfe apply prints the refusal with its argument", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().keyLevel = 2
    m.prints = {}
    NS.addon:OnSlashCommand("apply")
    assertTrue(printed(m, NS.L.MSG_ALL_TIMED:format(2)))
end)

-- Review F-001: after an Apply, a stand-down must not leave PGF hiding every listing.
test("apply: after Apply then /pgfe disable, PGF's evaluation passes groups again", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get(); f.keyLevel = 14; f.noSameSpec = true; f.noSameClassRole = true
    assertTrue((NS.Apply.Run{}))
    local function pgfAccepts()
        local env = {}
        m.pgf.PGF.PutPremadeRegionInfo(env, "Bob-Frostmourne")
        local fn = assert(loadstring("return " .. NS.Expression.Normalize(m.pgf.panel.state.expression)))
        setfenv(fn, env)
        return fn() and true or false
    end
    assertTrue(pgfAccepts())
    NS.addon:OnSlashCommand("disable")
    -- red under: drop the `not pgfe_on or` guard in Expression.Merge
    assertTrue(pgfAccepts())
end)
