-- tests/test_euibridge.lua — NS.EUIBridge, the one file that reads EllesmereUI state: the skin's
-- four-condition gate (docs/superpowers/plans/2026-10-09-eui-skin.md, Task 2). Driven against the
-- EllesmereUI fake in tests/wow_mock.lua (installEUI), which models EllesmereUI v9.4.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local function withEUI(spec, after)
    return T.newAddon{ mock = function(m)
        m.installEUI(spec)
        if after then after(m) end
    end }
end

local function okByKey(NS)
    local out, keys = {}, {}
    for i, c in ipairs(NS.EUIBridge.Conditions()) do
        out[c.key] = c.ok
        keys[i] = c.key
    end
    return out, table.concat(keys, ",")
end

test("euibridge: the module publishes its namespace table and the skin name", function()
    local NS = T.newAddon()
    assertEqual(type(NS.EUIBridge), "table")
    assertEqual(NS.EUIBridge.SKIN_NAME, "PremadeGroupsFilterExtension", "the folder name")
end)

test("euibridge: four conditions, in display order, each with a label and a hint", function()
    local NS = withEUI()
    local _, keys = okByKey(NS)
    assertEqual(keys, "eui,master,own,pgf")
    for _, c in ipairs(NS.EUIBridge.Conditions()) do
        assertEqual(type(c.label), "string", c.key .. " label")
        assertEqual(type(c.hint), "string", c.key .. " hint")
        assertEqual(type(c.ok), "boolean", c.key .. " ok is a boolean")
    end
end)

test("euibridge: everything on opens the gate, and there is no why", function()
    local NS = withEUI()
    local ok = okByKey(NS)
    assertTrue(ok.eui); assertTrue(ok.master); assertTrue(ok.own); assertTrue(ok.pgf)
    assertTrue((NS.EUIBridge.GateOpen()))
    assertNil(NS.EUIBridge.WhyClosed())
end)

-- red under: IsSuiteReady answering true without the EllesmereUI global
test("euibridge: EllesmereUI absent closes every condition, without raising", function()
    local NS = T.newAddon()
    local ok = okByKey(NS)
    assertFalse(ok.eui); assertFalse(ok.master); assertFalse(ok.own); assertFalse(ok.pgf)
    local open, failing = NS.EUIBridge.GateOpen()
    assertFalse(open); assertEqual(failing, "eui")
    assertTrue(NS.EUIBridge.WhyClosed():find("Install and enable EllesmereUI", 1, true) ~= nil)
end)

-- red under: IsSuiteReady not asking for the window-skin child
test("euibridge: the window-skin child not loaded closes the gate at eui", function()
    local NS = withEUI{ child = false }
    local open, failing = NS.EUIBridge.GateOpen()
    assertFalse(open); assertEqual(failing, "eui")
end)

-- red under: IsSuiteReady not checking RegisterSkin's type
test("euibridge: an EllesmereUI without RegisterSkin is not ready", function()
    local NS = withEUI(nil, function(m) m.EllesmereUI.RegisterSkin = nil end)
    assertFalse(NS.EUIBridge.IsSuiteReady())
end)

-- red under: IsMasterOn ignoring thirdPartySkinsOff
test("euibridge: the master switch off closes the gate at master, and only master", function()
    local NS = withEUI{ masterOff = true }
    local ok = okByKey(NS)
    assertTrue(ok.eui); assertFalse(ok.master); assertTrue(ok.own); assertTrue(ok.pgf)
    local open, failing = NS.EUIBridge.GateOpen()
    assertFalse(open); assertEqual(failing, "master")
    assertTrue(NS.EUIBridge.WhyClosed():find("Skin Third-Party Addons", 1, true) ~= nil)
end)

-- red under: Conditions reading the wrong entry name for "own"
test("euibridge: our own entry off closes the gate at own", function()
    local NS = withEUI{ entries = { PremadeGroupsFilterExtension = false } }
    local ok = okByKey(NS)
    assertTrue(ok.master); assertFalse(ok.own); assertTrue(ok.pgf)
    local _, failing = NS.EUIBridge.GateOpen()
    assertEqual(failing, "own")
end)

-- red under: IsPGFSkinOn ignoring the PremadeGroupsFilter entry
test("euibridge: PGF's skin entry off closes the gate at pgf", function()
    local NS = withEUI{ entries = { PremadeGroupsFilter = false } }
    local ok = okByKey(NS)
    assertTrue(ok.own); assertFalse(ok.pgf)
    local _, failing = NS.EUIBridge.GateOpen()
    assertEqual(failing, "pgf")
end)

-- red under: IsPGFSkinOn not asking whether PremadeGroupsFilter_EllesmereUI is loaded
test("euibridge: PGF's skin addon not loaded closes the gate at pgf", function()
    local NS = withEUI{ pgfSkin = false }
    local _, failing = NS.EUIBridge.GateOpen()
    assertEqual(failing, "pgf")
end)

test("euibridge: nil switches read as on (EllesmereUI's own nil = on)", function()
    local NS = withEUI(nil, function(m) m.EllesmereUIDB = nil end)
    assertTrue((NS.EUIBridge.GateOpen()))
    NS = withEUI(nil, function(m) m.EllesmereUIDB = { thirdPartySkinAddons = "junk" } end)
    assertTrue((NS.EUIBridge.GateOpen()), "a non-table entry list is no explicit false")
end)

test("euibridge: WhyClosed lists every failing hint, one per line", function()
    local NS = withEUI{ masterOff = true, entries = { PremadeGroupsFilter = false } }
    local why = NS.EUIBridge.WhyClosed()
    local lines = 0
    for _ in why:gmatch("[^\n]+") do lines = lines + 1 end
    assertEqual(lines, 2)
end)

test("euibridge: the reads are live, at call time", function()
    local NS, _, m = withEUI()
    assertTrue((NS.EUIBridge.GateOpen()))
    m.EllesmereUIDB.thirdPartySkinsOff = true
    assertFalse((NS.EUIBridge.GateOpen()))
    m.EllesmereUIDB.thirdPartySkinsOff = nil
    m.loadedAddons.PremadeGroupsFilter_EllesmereUI = false
    assertFalse((NS.EUIBridge.GateOpen()))
end)

-- red under: loaded() calling C_AddOns.IsAddOnLoaded unguarded
test("euibridge: a raising or absent C_AddOns reads as not loaded", function()
    local NS, _, m = withEUI()
    m.C_AddOns.IsAddOnLoaded = function() error("boom") end
    assertFalse(NS.EUIBridge.IsSuiteReady())
    m.C_AddOns = nil
    assertFalse(NS.EUIBridge.IsSuiteReady())
    assertFalse(NS.EUIBridge.IsPGFSkinOn())
end)

test("euibridge: nothing is ever written to EllesmereUI's saved variables", function()
    local NS, _, m = withEUI{ entries = { PremadeGroupsFilter = true } }
    local before = m.__deepcopy(m.EllesmereUIDB)
    NS.EUIBridge.Conditions(); NS.EUIBridge.GateOpen(); NS.EUIBridge.WhyClosed()
    NS.EUIBridge.IsEntryOn("Unknown")
    assertEqual(m.EllesmereUIDB.thirdPartySkinsOff, before.thirdPartySkinsOff)
    local n = 0
    for k, v in pairs(m.EllesmereUIDB.thirdPartySkinAddons) do
        n = n + 1
        assertEqual(v, before.thirdPartySkinAddons[k])
    end
    assertEqual(n, 1, "no key added to the entry list")
end)
