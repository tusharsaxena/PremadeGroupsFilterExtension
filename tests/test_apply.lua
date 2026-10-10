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
    NS.Filters.Get().smartKeyLevel = false -- a manually set level
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
    f.smartKeyLevel = false -- a manually set level
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
    local f = NS.Filters.Get(); f.keyLevel = 14; f.compositionEnabled = true; f.noSameSpec = true
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
    NS.Filters.Get().smartKeyLevel = false -- a manually set level
    NS.Filters.Get().keyLevel = 2
    m.prints = {}
    NS.addon:OnSlashCommand("apply")
    assertTrue(printed(m, NS.L.MSG_ALL_TIMED:format(2)))
end)

-- Review F-001: after an Apply, a stand-down must not leave PGF hiding every listing.
test("apply: after Apply then /pgfe disable, PGF's evaluation passes groups again", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get(); f.keyLevel = 14; f.compositionEnabled = true
    f.noSameSpec = true; f.noSameClassRole = true
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

-- Review F-004 / Review Focus 3 / spec-adversary #1: minimized, PGF filters with its mini panel
-- (UI/Dialog.lua:244-247), so writing the dungeon state and searching would apply nothing.
test("apply: PGF minimized → refuses Apply and Clear, nothing written or searched", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get(); f.keyLevel = 14; f.noSameSpec = true
    m.pgf.dialog.activePanel = { name = "mini" }
    -- red under: drop the IsDungeonPanelActive check in Apply's precheck
    assertEqual(select(2, NS.Apply.Run{ search = true }), "MSG_MINIMIZED")
    assertEqual(select(2, NS.Apply.Clear()), "MSG_MINIMIZED")
    assertEqual(m.pgf.calls.refresh, 0); assertEqual(m.pgf.calls.trigger, 0)
    assertEqual(m.pgf.panel.state.dungeon5, nil); assertEqual(m.pgf.panel.state.expression, nil)
    m.prints = {}
    NS.addon:OnSlashCommand("apply")
    assertTrue(printed(m, NS.L.MSG_MINIMIZED)); assertEqual(m.pgf.calls.refresh, 0)
end)

-- Review F-009 / spec-adversary #6: the message reports the PGF rows actually ticked.
test("apply: the message counts the rows ticked, and says so when targeting is off", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.Get().keyLevel = 14
    m.pgf.panel.Dungeons.Dungeon5.cmId = nil -- a target PGF has no row for
    local ok, key, n = NS.Apply.Run{}
    assertTrue(ok); assertEqual(key, "MSG_APPLIED")
    -- red under: report #targets instead of SetDungeons' return
    assertEqual(n, 3)
    assertEqual(NS.Apply.LastRange, "14-14")
    NS.Filters.Get().keyTargeting = false
    local ok2, key2, extra = NS.Apply.Run{}
    assertTrue(ok2); assertEqual(key2, "MSG_APPLIED_NO_TARGETING"); assertEqual(extra, nil)
    -- red under: skip the LastRange write instead of resetting it
    assertEqual(NS.Apply.LastRange, nil)
end)

-- Review F-009 (C-28): with targeting off no range was targeted, so the message names none.
test("apply: the targeting-off message prints no key range", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get(); f.keyLevel = 14; f.keyTargeting = false
    m.prints = {}
    NS.Apply.Report(NS.Apply.Run{})
    -- red under: keep %s in the locale string
    assertTrue(printed(m, NS.L.MSG_APPLIED_NO_TARGETING))
    assertFalse(printed(m, "14-14"))
end)

-- Owner request: with Smart on, `/pgfe apply` uses the computed level too.
test("apply: with Smart on, Run sets the key level from the season bests first", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get(); f.keyLevel = 5; f.smartKeyLevel = true
    local ok, key, ticked, range = NS.Apply.Run{}
    -- red under: drop ApplySmartLevel from Apply.Run
    assertTrue(ok); assertEqual(key, "MSG_APPLIED"); assertEqual(ticked, 4); assertEqual(range, "14-14")
    assertEqual(f.keyLevel, 14)
end)

test("apply: refuses while Toggle PGF Extension Filters is off, writing nothing", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    NS.Filters.SetActive(false) -- its own Clear commits once
    local trigger = m.pgf.calls.trigger
    local ok, key = NS.Apply.Run{ search = true }
    -- red under: drop the IsActive check in Apply.Run
    assertFalse(ok); assertEqual(key, "MSG_INACTIVE")
    assertEqual(m.pgf.calls.trigger, trigger); assertEqual(m.pgf.calls.refresh, 0)
end)

-- Owner request: the toggle is a setting too, on the settings page, separate from Enable.
test("apply: the filtersActive setting is a schema row, and its writes remove / rewrite the block", function()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local H = NS.addon.Settings.Helpers
    local row = H.FindSchema("filtersActive")
    -- red under: drop the filtersActive row from settings/Panel.lua's FILTER_ROWS
    assertTrue(row ~= nil); assertEqual(row.default, true); assertEqual(row.label, NS.L.FILTERS_ACTIVE)
    assertTrue(H.FindSchema("enabled") ~= row, "separate from the master Enable")
    local f = NS.Filters.Get(); f.smartKeyLevel = false; f.keyLevel = 14
    f.maxAgeEnabled = true; f.maxAge = 20
    m.pgf.panel.state.expression = "voice"
    assertTrue((NS.Apply.Run{}))
    H.Set("filtersActive", false)
    assertEqual(m.pgf.panel.state.expression, "voice")
    assertTrue(NS.addon.db.profile.filtersActive == false)
    H.Set("filtersActive", true)
    assertTrue(m.pgf.panel.state.expression:find("age <= 20", 1, true) ~= nil)
    assertEqual(m.pgf.calls.refresh, 0, "no search")
end)

-- ── debug lines (C-19 / review PGE-04) ──────────────────────────────────────────────────────────

-- How many console lines carry `needle` (plain find).
local function logged(NS, needle)
    local n = 0
    for _, line in ipairs(NS.DebugLog.buffer) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

-- An enabled instance at a level some dungeons are untimed at, with the console on and empty.
local function debugReady()
    local NS, _, m = T.enableAddon{}
    seasonFromScreenshot(m)
    local f = NS.Filters.Get(); f.smartKeyLevel = false; f.keyLevel = 14
    NS.State.debug = true
    NS.DebugLog:Clear()
    return NS, m, f
end

-- Each refusal, set up from the precheck mocks the cases above use.
local REFUSALS = {
    { "MSG_COMBAT",       function(_, m) m.inCombat = true end },
    { "MSG_NO_PGF",       function(_, m) m.pgf.dialog.RefreshButton = nil end, "Dialog.RefreshButton" },
    { "MSG_NOT_DUNGEONS", function(_, m) m.pgf.dialog.activeId = "c3f0" end },
    { "MSG_MINIMIZED",    function(_, m) m.pgf.dialog.activePanel = { name = "mini" } end },
    { "MSG_INACTIVE",     function(NS) NS.Filters.SetActive(false) end },
    { "MSG_BAD_LEVEL",    function(_, _, f) f.keyLevel = 99 end },
    { "MSG_BAD_AGE",      function(_, _, f) f.maxAgeEnabled = true; f.maxAge = 0 end },
    { "MSG_LOADING",      function(_, m) m.mapTable = nil end },
    { "MSG_ALL_TIMED",    function(_, _, f) f.keyLevel = 2 end },
    { "MSG_DAMAGED",      function(NS, m)
        m.pgf.panel.state.expression = NS.Expression.MARK_BEGIN .. "\n( age <= 5 )" end },
    -- Past Expression.MAX_LENGTH (2000) once the managed block is merged in front.
    { "MSG_TOOLONG",      function(_, m, f)
        f.noSameSpec = true; m.pgf.panel.state.expression = ("voice or "):rep(250) .. "voice" end },
}

for _, row in ipairs(REFUSALS) do
    local key, arrange, extra = row[1], row[2], row[3]
    test("apply: a " .. key .. " refusal writes an [Apply] refused line", function()
        local NS, m, f = debugReady()
        arrange(NS, m, f)
        NS.DebugLog:Clear()
        local ok, got = NS.Apply.Run{}
        assertFalse(ok); assertEqual(got, key)
        -- red under: drop the done() logging
        assertEqual(logged(NS, "[Apply] refused: " .. key), 1)
        if extra then assertEqual(logged(NS, extra), 1, "the missing seam is named") end
    end)
end

test("apply: a success writes the wrote and ok lines, and search only when searching", function()
    local NS = debugReady()
    assertTrue((NS.Apply.Run{}))
    -- red under: drop the done() logging
    assertEqual(logged(NS, "[Apply] wrote 4 dungeon rows"), 1)
    assertEqual(logged(NS, "range 14-14"), 1)
    assertEqual(logged(NS, "[Apply] ok: MSG_APPLIED"), 1)
    assertEqual(logged(NS, "[Apply] search"), 0)
    NS.DebugLog:Clear()
    assertTrue((NS.Apply.Run{ search = true }))
    assertEqual(logged(NS, "[Apply] search"), 1)
end)

test("apply: a targeting-off success says the dungeon rows were untouched", function()
    local NS, _, f = debugReady()
    f.keyTargeting = false
    assertTrue((NS.Apply.Run{}))
    -- red under: drop the done() logging
    assertEqual(logged(NS, "[Apply] wrote untouched dungeon rows"), 1)
    assertEqual(logged(NS, "range nil"), 1)
end)

-- C-03 end to end: a wrapped block whose close marker was deleted is refused by Clear, through
-- Apply.lua unchanged (Task 2 case (b)'s input). The bridge reads the edit box's committed text
-- from the dungeon state (core/PGFBridge.lua GetExpression), so the text is written there.
test("apply: Clear refuses a wrapped block with its close marker deleted, and logs it", function()
    local NS, m = debugReady()
    local d = NS.Expression.Merge("voice or myrealm", { "age <= 15" }):gsub("%-%- %[pgfe%] close\n", "")
    m.pgf.panel.state.expression = d
    m.pgf.panel.Advanced.Expression.EditBox.focus = true
    local ok, key = NS.Apply.Clear()
    -- red under: drop the wrapped-and-not-closed check in Expression.Strip
    assertFalse(ok); assertEqual(key, "MSG_DAMAGED")
    -- red under: drop the done() logging
    assertEqual(logged(NS, "[Clear] refused: MSG_DAMAGED"), 1)
    assertEqual(m.pgf.panel.state.expression, d, "nothing written")
end)

test("apply: a Clear refusal and a Clear success each write one [Clear] line", function()
    local NS, m = debugReady()
    m.inCombat = true
    assertEqual(select(2, NS.Apply.Clear()), "MSG_COMBAT")
    -- red under: drop the done() logging
    assertEqual(logged(NS, "[Clear] refused: MSG_COMBAT"), 1)
    m.inCombat = false
    NS.DebugLog:Clear()
    assertTrue((NS.Apply.Clear()))
    assertEqual(logged(NS, "[Clear] ok: MSG_CLEARED"), 1)
end)

test("apply: a filtersActive toggle writes one [Apply] toggled line", function()
    local NS = debugReady()
    NS.Apply.OnFiltersToggled(false)
    -- red under: drop the OnFiltersToggled debug line
    assertEqual(logged(NS, "[Apply] filters toggled off"), 1)
    NS.Apply.OnFiltersToggled(true)
    assertEqual(logged(NS, "[Apply] filters toggled on"), 1)
end)
