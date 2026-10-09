-- tests/test_filters.lua — NS.Filters (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 5).

local T = _G.PGFE_TEST
local test, assertEqual, assertNil, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertNil, T.assertTrue, T.assertFalse

-- Boot an instance. Filters consumes NS.Regions.KEYS (Task 2) and NS.Targeting.IsValidLevel
-- (Task 3); while those modules are still stubs, publish the plan's exact contract for them so this
-- suite exercises Filters alone. Once the real modules land, their values are used untouched.
local function boot()
    local NS, _, m = T.bootAddon()
    NS.Regions.KEYS = NS.Regions.KEYS or {
        US = { "oce", "la", "chi", "mex", "bzl" },
        EU = { "eng", "ger", "fra", "ita", "spa", "por", "rus" },
    }
    NS.Targeting.IsValidLevel = NS.Targeting.IsValidLevel or function(n)
        return type(n) == "number" and n == math.floor(n) and n >= 2 and n <= 40
    end
    return NS, m
end

test("filters: clause opts honor enable flags and portal order", function()
    local NS = boot()
    local f = NS.Filters.Get()
    f.regionsEnabled = true; f.regions = { chi = true, oce = true, eng = true }
    f.maxAgeEnabled = false; f.maxAge = 30; f.keyLevel = 12
    local o = NS.Filters.ToClauseOpts("US")
    assertEqual(table.concat(o.regions, ","), "oce,chi")
    assertNil(o.maxAge); assertEqual(o.keyLevel, 12)
    assertNil(NS.Filters.ToClauseOpts(nil).regions)
    f.maxAgeEnabled = true
    assertEqual(NS.Filters.ToClauseOpts("US").maxAge, 30)
    f.regionsEnabled = false
    assertNil(NS.Filters.ToClauseOpts("US").regions)
    f.minScoreEnabled = false; f.minScore = 2400
    assertNil(NS.Filters.ToClauseOpts("US").minScore)
    f.minScoreEnabled = true
    assertEqual(NS.Filters.ToClauseOpts("US").minScore, 2400)
end)

-- Owner requirement: regions on with none selected behaves as all selected, not as a refusal.
test("filters: regions on with none selected for this portal filters on no region", function()
    local NS = boot()
    local f = NS.Filters.Get()
    f.regionsEnabled = true; f.regions = { eng = true }
    -- red under: return the selection list even when it is empty
    assertNil(NS.Filters.ToClauseOpts("US").regions)
    assertTrue((NS.Filters.Validate()))
    f.regions = {}
    assertNil(NS.Filters.ToClauseOpts("US").regions)
end)

test("filters: playstyles on with some ticked filter on those, in the game's order", function()
    local NS = boot()
    local f = NS.Filters.Get()
    NS.Filters.TogglePlaystyle("carry"); NS.Filters.TogglePlaystyle("learning")
    f.playstyleEnabled = false
    assertNil(NS.Filters.ToClauseOpts("US").playstyles, "off")
    f.playstyleEnabled = true
    assertEqual(table.concat(NS.Filters.ToClauseOpts("US").playstyles, ","), "learning,carry")
    NS.Filters.TogglePlaystyle("carry"); NS.Filters.TogglePlaystyle("learning")
    -- red under: return the selection list even when it is empty
    assertNil(NS.Filters.ToClauseOpts("US").playstyles, "none ticked behaves as all")
end)

test("filters: validation", function()
    local NS = boot()
    local f = NS.Filters.Get()
    f.keyLevel = 1; local ok, e = NS.Filters.Validate(); assertFalse(ok); assertEqual(e, "badLevel")
    f.keyLevel = 10; f.maxAgeEnabled = true; f.maxAge = 0
    ok, e = NS.Filters.Validate(); assertFalse(ok); assertEqual(e, "badAge")
    f.maxAge = 2.5; ok, e = NS.Filters.Validate(); assertFalse(ok); assertEqual(e, "badAge")
    f.maxAge = 241; ok, e = NS.Filters.Validate(); assertFalse(ok); assertEqual(e, "badAge")
    f.maxAge = 15; assertTrue((NS.Filters.Validate()))
    f.minScoreEnabled = true; f.minScore = 0
    ok, e = NS.Filters.Validate(); assertFalse(ok); assertEqual(e, "badScore")
    f.minScore = 5001; ok, e = NS.Filters.Validate(); assertFalse(ok); assertEqual(e, "badScore")
    f.minScore = 2000; assertTrue((NS.Filters.Validate()))
    f.minScoreEnabled = false; f.minScore = 0; assertTrue((NS.Filters.Validate()))
end)

test("filters: set and region toggle write the live table", function()
    local NS = boot()
    local f = NS.Filters.Get()
    NS.Filters.Set("keyLevel", 16); assertEqual(f.keyLevel, 16)
    NS.Filters.ToggleRegion("oce"); assertTrue(f.regions.oce)
    NS.Filters.ToggleRegion("oce"); assertNil(f.regions.oce)
    assertEqual(#NS.Filters.SelectedRegions(nil), 0)
end)

test("filters: per-character defaults", function()
    local NS = boot()
    local f = NS.Filters.Get()
    assertEqual(f, NS.addon.db.char.filters)
    assertTrue(f.keyTargeting); assertEqual(f.keyLevel, 10); assertTrue(f.regionsEnabled)
end)

-- Owner request: every option ticked means Any, the same as none.
test("filters: ticking the last unticked option clears the set to Any", function()
    local NS = boot()
    local f = NS.Filters.Get()
    for _, k in ipairs(NS.Filters.PLAYSTYLES) do NS.Filters.TogglePlaystyle(k) end
    -- red under: drop the isFull clear after the toggle in Filters' toggleIn
    assertNil(next(f.playstyles))
    for _, k in ipairs(NS.Regions.KEYS.US) do NS.Filters.ToggleRegion(k, "US") end
    assertNil(next(f.regions))
    -- Without a portal there is no option list: a plain toggle.
    NS.Filters.ToggleRegion("oce"); assertTrue(f.regions.oce)
end)

test("filters: a stored all-ticked set is Any: no clause, and a tick selects that option alone", function()
    local NS = boot()
    local f = NS.Filters.Get()
    f.playstyleEnabled = true; f.regionsEnabled = true
    f.playstyles = { learning = true, relaxed = true, competitive = true, carry = true }
    f.regions = { oce = true, la = true, chi = true, mex = true, bzl = true, eng = true }
    assertTrue(NS.Filters.IsAny(NS.Filters.SelectedPlaystyles(), #NS.Filters.PLAYSTYLES))
    -- red under: build the clause whenever something is selected
    assertNil(NS.Filters.ToClauseOpts("US").playstyles)
    assertNil(NS.Filters.ToClauseOpts("US").regions)
    NS.Filters.TogglePlaystyle("carry")
    assertEqual(table.concat(NS.Filters.SelectedPlaystyles(), ","), "carry")
    NS.Filters.ToggleRegion("chi", "US")
    assertEqual(table.concat(NS.Filters.SelectedRegions("US"), ","), "chi")
    assertTrue(f.regions.eng, "another portal's region is left as stored")
end)

test("filters: clearing empties this portal's regions and the playstyles", function()
    local NS = boot()
    local f = NS.Filters.Get()
    f.regions = { oce = true, chi = true, eng = true }; f.playstyles = { relaxed = true }
    NS.Filters.ClearRegions("US")
    assertNil(f.regions.oce); assertNil(f.regions.chi); assertTrue(f.regions.eng)
    NS.Filters.ClearRegions(nil); assertTrue(f.regions.eng)
    NS.Filters.ClearPlaystyles(); assertNil(next(f.playstyles))
end)

test("filters: ApplySmartLevel sets the level from the season only when Smart is on", function()
    local NS, m = boot()
    local f = NS.Filters.Get()
    m.mapTable = { 1, 2 }
    m.mapUIInfo[1] = { name = "One", mapID = 1 }; m.mapUIInfo[2] = { name = "Two", mapID = 2 }
    m.seasonBest[1] = { intime = { level = 12 } }; m.seasonBest[2] = { intime = { level = 15 } }
    assertTrue(f.smartKeyLevel, "on by default (owner requirement)")
    f.smartKeyLevel = false
    assertEqual(NS.Filters.ApplySmartLevel(), 10); assertEqual(f.keyLevel, 10)
    f.smartKeyLevel = true
    assertEqual(NS.Filters.ApplySmartLevel(), 13); assertEqual(f.keyLevel, 13)
    m.mapTable = nil
    f.keyLevel = 9
    assertEqual(NS.Filters.ApplySmartLevel(), 9, "no season data: the stored level stands")
end)

test("filters: composition applies only while its box is on", function()
    local NS = T.enableAddon{}
    local filt = NS.Filters.Get()
    filt.compositionEnabled = false; filt.noSameSpec = true
    assertEqual(NS.Filters.ToClauseOpts("US").noSameSpec, nil)
    filt.compositionEnabled = true
    -- red under: pass f.noSameSpec through regardless of compositionEnabled
    assertTrue(NS.Filters.ToClauseOpts("US").noSameSpec)
end)
