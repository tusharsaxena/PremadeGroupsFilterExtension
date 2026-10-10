-- tests/test_disabled.lua — disabled means the addon is not running (slash-commands-§7).
--
-- Every feature event actually unregistered (not gated), every module teardown run, through the
-- one latch; setup (the chat command, the dispatcher, the settings category) stays up and every
-- verb keeps answering. Production takes only the `disabled` hold (the addon holds the
-- performance-§12 exemption, so no perf harness is wired); the `perf` case below takes the
-- library's other reserved hold as a test-only second holder.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local HOLD_PERF = (T.LibStub("LibKa0s-Lifecycle-1.0", true) or {}).HOLD_PERF or "perf"

-- A fresh addon carrying one feature event and one teardown/rebuild pair of the test's own, wired
-- exactly the way a feature module wires its rows at file load.
local function wired(opts)
    local NS, env, m = T.newAddon(opts)
    local seen = { event = 0, down = 0, up = 0 }
    function NS.addon.OnProbeEvent() seen.event = seen.event + 1 end
    NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "PLAYER_ENTERING_WORLD", "OnProbeEvent" }
    NS.STAND_DOWN[#NS.STAND_DOWN + 1] = function() seen.down = seen.down + 1 end
    NS.STAND_UP[#NS.STAND_UP + 1] = function() seen.up = seen.up + 1 end
    NS.addon:OnInitialize()
    NS.addon:OnEnable()
    return NS, env, m, seen
end

test("disabled: a feature event is registered at enable and UNREGISTERED at disable", function()
    local NS, _, m, seen = wired()
    m.fireEvent("PLAYER_ENTERING_WORLD")
    assertEqual(seen.event, 1)
    NS.addon:OnSlashCommand("disable")
    assertEqual(m.fireEvent("PLAYER_ENTERING_WORLD"), 0, "no handler runs while disabled")
    assertEqual(seen.event, 1)
    assertEqual(seen.down, 1)
end)

test("disabled: enable rebuilds from current state", function()
    local NS, _, m, seen = wired()
    NS.addon:OnSlashCommand("disable")
    NS.addon:OnSlashCommand("enable")
    assertEqual(seen.up, 1)
    m.fireEvent("PLAYER_ENTERING_WORLD")
    assertEqual(seen.event, 1)
end)

test("disabled: the perf hold stands the addon down through the same latch", function()
    local NS, _, m, seen = wired()
    NS.Lifecycle:Hold(HOLD_PERF)
    assertTrue(NS.IsStoodDown())
    assertEqual(seen.down, 1)
    assertEqual(m.fireEvent("PLAYER_ENTERING_WORLD"), 0)
    NS.Lifecycle:Release(HOLD_PERF)
    assertFalse(NS.IsStoodDown())
    assertEqual(seen.up, 1)
end)

test("disabled: a profile stored disabled stands down at the next enable", function()
    local NS, _, _, seen = wired()
    NS.addon.db.profile.enabled = false
    NS.addon:OnEnable()
    assertTrue(NS.IsStoodDown())
    assertEqual(seen.down, 1)
end)

test("disabled: every verb keeps answering while disabled", function()
    local NS, _, m = wired()
    NS.addon:OnSlashCommand("disable")
    m.prints = {}
    NS.addon:OnSlashCommand("version")
    assertTrue(#m.prints > 0)
    m.prints = {}
    NS.addon:OnSlashCommand("list")
    assertTrue(#m.prints > 0)
end)

-- The launcher's Enabled line, read off the LDB object's own OnTooltipShow with a collecting tooltip.
local function tooltipEnabledLine(NS)
    local lines = {}
    NS.Launcher:Object().OnTooltipShow({ AddLine = function(_, text) lines[#lines + 1] = text end })
    for _, line in ipairs(lines) do
        if line:find("Enabled: ", 1, true) then return line end
    end
end

-- C-16 (launcher-§1): the Enabled line reads the same accessor the Master-controls row reads, the
-- stored `enabled` setting, not the latch.
-- red under: revert LauncherSetup:55 to not NS.IsStoodDown()
test("disabled: while another hold stands the addon down, the launcher reports the stored setting", function()
    local NS = T.enableAddon()
    NS.Lifecycle:Hold(HOLD_PERF)
    assertTrue(NS.IsStoodDown())
    local line = tooltipEnabledLine(NS)
    NS.Lifecycle:Release(HOLD_PERF)
    assertTrue(line ~= nil and line:find("Yes", 1, true) ~= nil, tostring(line))
end)

test("disabled: after /pgfe disable the launcher's Enabled line says No", function()
    local NS = T.enableAddon()
    NS.addon:OnSlashCommand("disable")
    local line = tooltipEnabledLine(NS)
    assertTrue(line ~= nil and line:find("No", 1, true) ~= nil, tostring(line))
end)
