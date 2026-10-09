-- tests/test_filters.lua — NS.Filters (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 5).

local T = _G.PGFE_TEST
local test, assertEqual, assertNil, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertNil, T.assertTrue, T.assertFalse

-- Boot an instance. Filters consumes NS.Regions.KEYS (Task 2) and NS.Targeting.IsValidLevel
-- (Task 3); while those modules are still stubs, publish the plan's exact contract for them so this
-- suite exercises Filters alone. Once the real modules land, their values are used untouched.
local function boot()
    local NS = T.bootAddon()
    NS.Regions.KEYS = NS.Regions.KEYS or {
        US = { "oce", "la", "chi", "mex", "bzl" },
        EU = { "eng", "ger", "fra", "ita", "spa", "por", "rus" },
    }
    NS.Targeting.IsValidLevel = NS.Targeting.IsValidLevel or function(n)
        return type(n) == "number" and n == math.floor(n) and n >= 2 and n <= 40
    end
    return NS
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
end)

test("filters: validation", function()
    local NS = boot()
    local f = NS.Filters.Get()
    f.keyLevel = 1; local ok, e = NS.Filters.Validate("US"); assertFalse(ok); assertEqual(e, "badLevel")
    f.keyLevel = 10; f.regionsEnabled = true; f.regions = { eng = true }
    ok, e = NS.Filters.Validate("US"); assertFalse(ok); assertEqual(e, "noRegions")
    f.regionsEnabled = false; f.maxAgeEnabled = true; f.maxAge = 0
    ok, e = NS.Filters.Validate("US"); assertFalse(ok); assertEqual(e, "badAge")
    f.maxAge = 2.5; ok, e = NS.Filters.Validate("US"); assertFalse(ok); assertEqual(e, "badAge")
    f.maxAge = 241; ok, e = NS.Filters.Validate("US"); assertFalse(ok); assertEqual(e, "badAge")
    f.maxAge = 15; assertTrue((NS.Filters.Validate("US")))
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
    assertTrue(f.keyTargeting); assertEqual(f.keyLevel, 10); assertFalse(f.regionsEnabled)
end)
