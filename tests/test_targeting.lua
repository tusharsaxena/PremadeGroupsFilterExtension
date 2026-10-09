-- tests/test_targeting.lua — NS.Targeting (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 3).

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

-- The user's character (screenshot): best TIMED level per dungeon.
local function sample()
    return {
        { cmID = 586, short = "DON", bestTimed = 14 }, { cmID = 587, short = "MR",  bestTimed = 14 },
        { cmID = 250, short = "TOS", bestTimed = 14 }, { cmID = 585, short = "VSA", bestTimed = 14 },
        { cmID = 588, short = "AOF", bestTimed = 13 }, { cmID = 399, short = "RLP", bestTimed = 13 },
        { cmID = 584, short = "BV",  bestTimed = 13 }, { cmID = 249, short = "KR",  bestTimed = 13 },
    }
end
local function shorts(t) local o = {} for _, d in ipairs(t) do o[#o + 1] = d.short end return table.concat(o, ",") end

test("targeting: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Targeting), "table")
end)
test("targeting: N=14 targets the four dungeons timed below 14", function()
    local NS = T.newAddon()
    assertEqual(shorts(NS.Targeting.Compute(sample(), 14)), "AOF,RLP,BV,KR")
end)
test("targeting: N=15 targets all eight", function()
    local NS = T.newAddon()
    assertEqual(#NS.Targeting.Compute(sample(), 15), 8)
end)
test("targeting: N=2 targets none", function()
    local NS = T.newAddon()
    assertEqual(#NS.Targeting.Compute(sample(), 2), 0)
end)
test("targeting: never-timed counts as 0", function()
    local NS = T.newAddon()
    assertEqual(#NS.Targeting.Compute({ { cmID = 1, bestTimed = 0 } }, 2), 1)
end)
test("targeting: ToSet keys the targets by cmID", function()
    local NS = T.newAddon()
    local set = NS.Targeting.ToSet(NS.Targeting.Compute(sample(), 14))
    assertTrue(set[588]); assertTrue(set[249]); assertEqual(set[586], nil)
end)
test("targeting: level validation and range text", function()
    local NS = T.newAddon()
    assertTrue(NS.Targeting.IsValidLevel(2)); assertTrue(NS.Targeting.IsValidLevel(40))
    assertFalse(NS.Targeting.IsValidLevel(1)); assertFalse(NS.Targeting.IsValidLevel(14.5))
    assertFalse(NS.Targeting.IsValidLevel(nil))
    assertEqual(NS.Targeting.RangeText(14), "14-14")
end)
