-- tests/test_regions.lua — NS.Regions and NS.RealmLists
-- (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 2; Review Focus 2).

local T = _G.PGFE_TEST
local test, assertEqual, assertNil, assertTrue = T.test, T.assertEqual, T.assertNil, T.assertTrue

test("regions: the module publishes its namespace table", function()
    local NS = T.newAddon()
    assertEqual(type(NS.Regions), "table")
end)

test("regions: normalize strips spaces, punctuation, case", function()
    local NS = T.newAddon()
    assertEqual(NS.Regions.Normalize("Aman'Thul"), "amanthul")
    assertEqual(NS.Regions.Normalize("Area 52"), "area52")
end)

test("regions: suffixed leader resolves on US portal", function()
    local NS, _, m = T.newAddon(); m.currentRegion = 1
    assertEqual(NS.Regions.GetRegion("Bob-Frostmourne"), "oce")
    assertEqual(NS.Regions.GetRegion("Bob-Aman'Thul"), "oce")
    assertEqual(NS.Regions.GetRegion("Bob-AmanThul"), "oce")
end)

test("regions: leader without suffix uses the player's realm", function()
    local NS, _, m = T.newAddon(); m.currentRegion = 1; m.realmName = "Frostmourne"
    assertEqual(NS.Regions.GetRegion("Bob"), "oce")
end)

test("regions: EU realm with accent", function()
    local NS, _, m = T.newAddon(); m.currentRegion = 3
    assertEqual(NS.Regions.GetRegion("Bob-Pozzodell'Eternità"), "ita")
end)

test("regions: unknown realm, nil/empty name, unsupported portal → nil", function()
    local NS, _, m = T.newAddon(); m.currentRegion = 1
    assertNil(NS.Regions.GetRegion("Bob-NotARealm"))
    assertNil(NS.Regions.GetRegion(nil)); assertNil(NS.Regions.GetRegion(""))
    m.currentRegion = 2
    assertNil(NS.Regions.GetRegion("Bob-Frostmourne"))
    assertNil(NS.Regions.GetPortal())
end)

-- Review F-011: the hook runs inside PGF's per-result loop; a non-string leader must not raise.
test("regions: a non-string leader name → nil, no error", function()
    local NS = T.bootAddon{ currentRegion = 1 }
    -- red under: drop the type check in Regions.GetRegion
    T.assertNil(NS.Regions.GetRegion(42)); T.assertNil(NS.Regions.GetRegion({}))
end)

-- Review C-32: a protected ("secret") leader name must not reach :match inside PGF's loop.
test("regions: a protected leader name is not matched", function()
    local NS = T.bootAddon{ currentRegion = 1 }
    assertEqual(NS.Regions.GetRegion("Bob-Frostmourne"), "oce")
    NS.IsConcatSafe = function() return false end
    -- red under: drop the IsConcatSafe clause in Regions.GetRegion
    assertNil(NS.Regions.GetRegion("Bob-Frostmourne"))
end)

test("regions: the same realm name resolves per portal", function()
    local NS, _, m = T.newAddon(); m.currentRegion = 1
    assertEqual(NS.Regions.GetPortal(), "US")
    assertEqual(NS.Regions.GetRegion("Bob-Area52"), "chi")
    m.currentRegion = 3
    assertEqual(NS.Regions.GetPortal(), "EU")
    assertEqual(NS.Regions.GetRegion("Bob-Area52"), "ger")
end)

test("regions: key and label tables cover all twelve buckets", function()
    local NS = T.newAddon()
    assertEqual(#NS.Regions.ALL_KEYS, 12)
    assertEqual(NS.Regions.ALL_KEYS[1], "oce")
    assertEqual(NS.Regions.ALL_KEYS[6], "eng")
    for _, k in ipairs(NS.Regions.ALL_KEYS) do
        assertEqual(NS.Regions.LABELS[k], k:upper(), "label for " .. k)
    end
end)

test("regions: data integrity — no realm in two buckets, only known keys", function()
    local NS = T.newAddon()
    for portal, buckets in pairs(NS.RealmLists) do
        local seen, known = {}, {}
        for _, k in ipairs(NS.Regions.KEYS[portal]) do known[k] = true end
        for key, realms in pairs(buckets) do
            assertTrue(known[key], portal .. " has unknown key " .. key)
            for _, r in ipairs(realms) do
                local n = NS.Regions.Normalize(r)
                assertNil(seen[n], portal .. " duplicate " .. r); seen[n] = key
            end
        end
    end
end)

test("regions: every bucket is populated", function()
    local NS = T.newAddon()
    for _, portal in ipairs({ "US", "EU" }) do
        for _, k in ipairs(NS.Regions.KEYS[portal]) do
            local list = NS.RealmLists[portal][k]
            assertTrue(type(list) == "table" and #list > 0, portal .. " bucket " .. k .. " is empty")
        end
    end
end)
