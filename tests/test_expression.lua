-- tests/test_expression.lua — NS.Expression (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 4).
--
-- Registered in tests/run.lua from the scaffold so the task that fills the module adds its cases
-- here without touching the suite list.

local T = _G.PGFE_TEST
local test, assertEqual = T.test, T.assertEqual

test("expression: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Expression), "table")
end)
