-- tests/test_bridge.lua — NS.Bridge, the one file that touches Premade Groups Filter internals
-- (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 6). Driven against tests/pgf_fake.lua,
-- which models only the PGF v7.6.2 seams core/PGFBridge.lua reads.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

test("bridge: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Bridge), "table")
end)

test("bridge: seams present", function()
    local NS = T.bootAddon()
    assertTrue((NS.Bridge.Check()))
end)

test("bridge: missing seam is named, no error", function()
    local NS, _, m = T.bootAddon()
    m.PremadeGroupsFilterDungeonPanel = nil
    local ok, missing = NS.Bridge.Check()
    assertFalse(ok); assertEqual(missing, "PremadeGroupsFilterDungeonPanel")
end)

test("bridge: SetDungeons maps cmID → positional key, shuffled order", function()
    local NS, _, m = T.bootAddon()
    local n = NS.Bridge.SetDungeons({ [588] = true, [249] = true })
    local s = NS.Bridge.GetDungeonState()
    assertEqual(n, 2)
    assertTrue(s.dungeon5); assertTrue(s.dungeon8); assertFalse(s.dungeon1)
    assertEqual(s, m.pgf.panel.state)
end)

test("bridge: non-dungeon category → no state", function()
    local NS, _, m = T.bootAddon()
    m.pgf.dialog.activeId = "c3f0"
    assertFalse(NS.Bridge.IsDungeonCategory()); assertNil(NS.Bridge.GetDungeonState())
    assertEqual(NS.Bridge.SetDungeons({ [588] = true }), 0)
end)

test("bridge: missing dungeon state table is created on the active category", function()
    local NS, _, m = T.bootAddon()
    m.pgf.dialog.activeState.dungeon = nil
    local s = NS.Bridge.GetDungeonState()
    assertEqual(type(s), "table")
    assertEqual(m.pgf.state.c2f4.dungeon, s)
end)

test("bridge: expression read clears focus first; commit inits + triggers; search clicks", function()
    local NS, _, m = T.bootAddon()
    m.pgf.panel.Advanced.Expression.EditBox.focus = true
    NS.Bridge.SetExpression("voice")
    assertEqual(NS.Bridge.GetExpression(), "voice")
    assertFalse(m.pgf.panel.Advanced.Expression.EditBox.focus)
    NS.Bridge.Commit(); assertEqual(m.pgf.calls.trigger, 1); assertEqual(m.pgf.calls.init, 1)
    NS.Bridge.Search(); assertEqual(m.pgf.calls.refresh, 1)
end)

test("bridge: commit with minimized dialog writes state only", function()
    local NS, _, m = T.bootAddon()
    m.pgf.dialog.activePanel = { name = "mini" }
    NS.Bridge.Commit(); assertEqual(m.pgf.calls.trigger, 0); assertEqual(m.pgf.calls.init, 0)
end)

test("bridge: the dungeon panel is active only while maximized on Dungeons", function()
    local NS, _, m = T.bootAddon()
    assertTrue(NS.Bridge.IsDungeonPanelActive())
    m.pgf.dialog.activePanel = { name = "mini" }
    assertFalse(NS.Bridge.IsDungeonPanelActive())
    assertTrue(NS.Bridge.IsDungeonCategory(), "minimized still answers the category")
end)

test("bridge: dialog shown and accessor", function()
    local NS, _, m = T.bootAddon()
    assertTrue(NS.Bridge.IsDialogShown())
    m.pgf.dialog.shown = false
    assertFalse(NS.Bridge.IsDialogShown())
    assertEqual(NS.Bridge.GetDialog(), m.pgf.dialog)
end)

test("bridge: env hook installs once, as a post-hook on PGF's own function", function()
    local NS, _, m = T.newAddon()
    local n = 0
    for _, h in ipairs(m.hooks) do
        if h.target == m.pgf.PGF and h.name == "PutPremadeRegionInfo" then n = n + 1 end
    end
    assertEqual(n, 1, "modules/EnvInject.lua installs it at file load")
    local before = #m.hooks
    assertTrue(NS.Bridge.InstallEnvHook(function() end), "a second install is a no-op success")
    assertEqual(#m.hooks, before)
end)

test("bridge: env hook refuses when the seam is missing", function()
    local NS = T.newAddon{ mock = function(m) m.pgf.PGF.PutPremadeRegionInfo = nil end }
    assertFalse(NS.Bridge.InstallEnvHook(function() end))
end)

test("bridge: HookDialog wires SwitchToPanel and both scripts", function()
    local NS, _, m = T.bootAddon()
    local scripts, seen = {}, 0
    m.pgf.dialog.HookScript = function(_, name) scripts[#scripts + 1] = name end
    assertTrue(NS.Bridge.HookDialog(function() seen = seen + 1 end))
    m.pgf.dialog:SwitchToPanel()
    assertEqual(seen, 1)
    assertEqual(table.concat(scripts, ","), "OnShow,OnHide")
end)
