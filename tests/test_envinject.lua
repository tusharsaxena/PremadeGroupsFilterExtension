-- tests/test_envinject.lua — NS.EnvInject, the post-hook body on PGF's PutPremadeRegionInfo
-- (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 6). The hook is reached only through
-- PGF's own function, which tests/wow_mock.lua's hooksecurefunc genuinely wraps.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local function runHook(m, env, leader) m.pgf.PGF.PutPremadeRegionInfo(env, leader); return env end

test("envinject: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.EnvInject), "table")
end)

test("envinject: keywords follow PGF's formula", function()
    local NS, _, m = T.bootAddon()
    local s, cr = NS.EnvInject.PlayerKeywords(253, "DAMAGER", "HUNTER", m.pgf.PGF.C.SPECIALIZATIONS)
    assertEqual(s, "beastmastery_hunters"); assertEqual(cr, "dps_hunters")
    s, cr = NS.EnvInject.PlayerKeywords(262, "HEALER", "SHAMAN", m.pgf.PGF.C.SPECIALIZATIONS)
    assertEqual(s, "elemental_shamans"); assertEqual(cr, "heal_shamans")
end)

test("envinject: unknown spec / role / missing table → nil keywords, no error", function()
    local NS = T.bootAddon()
    local s, cr = NS.EnvInject.PlayerKeywords(nil, nil, nil, nil)
    assertNil(s); assertNil(cr)
    s, cr = NS.EnvInject.PlayerKeywords(999, "DAMAGER", "HUNTER", {})
    assertNil(s); assertEqual(cr, "dps_hunters")
end)

test("envinject: samespec / sameclassrole from env counts", function()
    local _, _, m = T.enableAddon{ specID = 253, role = "DAMAGER", classFile = "HUNTER" }
    local env = runHook(m, { beastmastery_hunters = 1, dps_hunters = 2 }, "Bob-Frostmourne")
    assertEqual(env.pgfe_samespec, 1); assertEqual(env.pgfe_sameclassrole, 2)
    assertTrue(env.pgfe_on)
    env = runHook(m, {}, "Bob-Frostmourne")
    assertEqual(env.pgfe_samespec, 0); assertEqual(env.pgfe_sameclassrole, 0)
end)

-- Review F-002 / audit PGE-01: the spec read goes through NS.Compat, so a client without the
-- deprecated globals still answers through C_SpecializationInfo.
test("envinject: the spec is read through Compat when the deprecated globals are gone", function()
    local _, _, m = T.enableAddon{ specID = 253, role = "DAMAGER", classFile = "HUNTER" }
    m.GetSpecialization = nil; m.GetSpecializationInfo = nil
    m.fireEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
    -- red under: read GetSpecialization/GetSpecializationInfo directly in EnvInject.RefreshPlayer
    local env = runHook(m, { beastmastery_hunters = 1, dps_hunters = 2 }, "Bob")
    assertEqual(env.pgfe_samespec, 1); assertEqual(env.pgfe_sameclassrole, 2)
end)

test("envinject: spec change is picked up without re-apply", function()
    local _, _, m = T.enableAddon{ specID = 253, role = "DAMAGER", classFile = "HUNTER" }
    m.specID = 262; m.role = "DAMAGER"; m.classFile = "SHAMAN"
    m.fireEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
    local env = runHook(m, { elemental_shamans = 1, dps_shamans = 1 }, "Bob")
    assertEqual(env.pgfe_samespec, 1)
end)

test("envinject: PLAYER_SPECIALIZATION_CHANGED refreshes for the player only", function()
    local _, _, m = T.enableAddon{ specID = 253, role = "DAMAGER", classFile = "HUNTER" }
    m.specID = 262; m.classFile = "SHAMAN"
    m.fireEvent("PLAYER_SPECIALIZATION_CHANGED", "party1")
    local env = runHook(m, { beastmastery_hunters = 1, elemental_shamans = 1 }, "Bob")
    assertEqual(env.pgfe_samespec, 1, "still the cached hunter keyword")
    m.fireEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    env = runHook(m, { beastmastery_hunters = 0, elemental_shamans = 2 }, "Bob")
    assertEqual(env.pgfe_samespec, 2)
end)

-- PGF's own PutPremadeRegionInfo (Plugins/PremadeRegions.lua:25-46) resets every region key to
-- false and fills them from PremadeRegions when it is loaded; this addon fills them itself only
-- when it is not. Frostmourne is an OCE realm in this addon's map, so `oce` staying false below
-- proves the addon's own lookup did not run over PremadeRegions' answer.
test("envinject: regions injected only without PremadeRegions", function()
    local _, _, m = T.enableAddon{}
    m.currentRegion = 1
    local env = runHook(m, {}, "Bob-Frostmourne")
    assertEqual(env.region, "oce"); assertTrue(env.oce); assertFalse(env.chi); assertFalse(env.eng)
    m.PremadeRegions = { GetRegion = function() return "la" end }
    env = runHook(m, {}, "Bob-Frostmourne")
    assertEqual(env.region, "la"); assertTrue(env.la); assertFalse(env.oce)
end)

test("envinject: stood down → hook is a no-op", function()
    local NS, _, m = T.enableAddon{}
    NS.addon:OnSlashCommand("disable")
    assertTrue(NS.IsStoodDown())
    local env = runHook(m, { beastmastery_hunters = 1 }, "Bob-Frostmourne")
    -- red under: drop the IsStoodDown return in EnvInject.Apply
    assertNil(env.pgfe_on)
    assertNil(env.pgfe_samespec); assertNil(env.pgfe_sameclassrole)
    assertNil(env.region); assertFalse(env.oce)
end)

test("envinject: the block's guard is off while Toggle PGF Extension Filters is off", function()
    local NS, _, m = T.enableAddon{}
    local env = runHook(m, {}, "Leader-Barthilas")
    assertTrue(env.pgfe_on)
    NS.Filters.SetActive(false)
    env = runHook(m, {}, "Leader-Barthilas")
    -- red under: env.pgfe_on = true unconditionally in EnvInject.Apply
    assertFalse(env.pgfe_on)
end)

-- Review C-10 / #7: the install result is stored so Diagnostics can report it.
test("envinject: the env hook's install result is stored", function()
    local NS = T.newAddon()
    -- red under: drop the store at the InstallEnvHook call in modules/EnvInject.lua
    assertTrue(NS.EnvInject.hooked == true)
end)

-- Review C-32: without PremadeRegions, a protected leader name leaves every region key false.
test("envinject: a protected leader name injects no region", function()
    local NS, _, m = T.enableAddon{}
    m.currentRegion = 1; m.PremadeRegions = nil
    NS.IsConcatSafe = function() return false end
    local env = runHook(m, {}, "Bob-Frostmourne")
    -- red under: drop the IsConcatSafe clause in Regions.GetRegion
    assertNil(env.region)
    for _, k in ipairs(NS.Regions.ALL_KEYS) do assertFalse(env[k], k) end
end)
