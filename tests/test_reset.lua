-- tests/test_reset.lua — what "Reset all settings" and a page's Defaults reach (PGE-10).
--
-- The global reset IS a profile reset (options-ui-§12): only the active profile is reset, the
-- session-only rows are swept, and the minimap button, a per-installation display preference in
-- the global store, survives both resets (launcher-§3). The `enabled` latch is re-read after the
-- reset, so a profile reset while disabled comes back running.
--
-- The code reads correct today, so each case can only go red against the mutation it names.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local NAME = "PremadeGroupsFilterExtension"

-- red under: ResetProfile on every profile
test("reset: Reset all settings resets only the active profile", function()
    local NS = T.enableAddon()
    local db, H = NS.addon.db, NS.addon.Settings.Helpers
    db:SetProfile("Other")
    H.Set("filtersActive", false)
    db:SetProfile("Default")
    H.Set("filtersActive", false)
    H.RestoreAllDefaults()
    assertEqual(db:GetCurrentProfile(), "Default", "the current key survives")
    assertTrue(H.Get("filtersActive"), "the active profile is reset")
    local names = table.concat(db:GetProfiles(), ",")
    assertEqual(names, "Default,Other", "the profile list survives")
    db:SetProfile("Other")
    assertFalse(H.Get("filtersActive"), "the other profile keeps its value")
end)

-- red under: drop the sessionOnly sweep in RestoreAllDefaults
test("reset: Reset all settings sweeps the debug console off", function()
    local NS = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    H.Set("state.debugConsole", true)
    assertTrue(H.Get("state.debugConsole"))
    H.RestoreAllDefaults()
    assertFalse(H.Get("state.debugConsole"))
    assertFalse(NS.DebugLog:IsShown())
end)

-- red under: drop resetExempt (settings/Schema.lua:89) AND make Settings.VetoedFromResetAll return only row.page == "profiles" (:144)
-- Two layers protect the row on this path: db:ResetProfile() leaves `global` alone and the walk
-- reaches only sessionOnly rows (Settings.VetoedFromResetAll), and resetExempt vetoes it inside the
-- bracket (libs/LibKa0s/Schema.lua:649). Red-proved: either mutation alone keeps this case green;
-- both together turn it red.
test("reset: Reset all settings leaves the minimap button hidden", function()
    local NS, _, m = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    H.Set("global.minimap.shown", false)
    assertFalse(m.minimapButtons[NAME].shown)
    H.RestoreAllDefaults()
    assertTrue(NS.addon.db.global.minimap.hide, "hide stays true")
    assertFalse(H.Get("global.minimap.shown"))
    assertFalse(m.minimapButtons[NAME].shown, "the button stays hidden")
end)

-- red under: drop resetExempt on the minimap row (settings/Schema.lua:89)
-- The page Defaults path brackets its writes (bulkBegin), so resetExempt is its only layer.
test("reset: the General page's Defaults leaves the minimap button hidden", function()
    local NS, _, m = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    H.Set("global.minimap.shown", false)
    H.Set("filtersActive", false)
    H.RestoreDefaults("general")
    assertTrue(H.Get("filtersActive"), "the other General rows reset: the Defaults path ran")
    assertTrue(NS.addon.db.global.minimap.hide, "hide stays true")
    assertFalse(m.minimapButtons[NAME].shown, "the button stays hidden")
end)

-- red under: drop the Lifecycle:Set in reloadProfile
test("reset: Reset all settings while disabled comes back enabled and running", function()
    local NS = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    NS.addon:OnSlashCommand("disable")
    assertTrue(NS.Lifecycle:IsHeld(NS.HOLD_DISABLED))
    H.RestoreAllDefaults()
    assertTrue(NS.addon.db.profile.enabled)
    assertFalse(NS.Lifecycle:IsHeld(NS.HOLD_DISABLED), "the disabled hold is released")
    assertFalse(NS.IsStoodDown())
end)
