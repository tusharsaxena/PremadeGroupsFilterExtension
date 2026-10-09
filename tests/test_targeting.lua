-- tests/test_targeting.lua — NS.Targeting (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 3).
--
-- Registered in tests/run.lua from the scaffold so the task that fills the module adds its cases
-- here without touching the suite list.

local T = _G.PGFE_TEST
local test, assertEqual = T.test, T.assertEqual

test("targeting: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Targeting), "table")
end)
