-- tests/test_presets.lua — NS.Presets (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 5).

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

test("presets: save/load round-trip is a deep copy into the same table", function()
    local NS = T.bootAddon()
    local f = NS.Filters.Get()
    f.keyLevel = 14; f.regions.oce = true
    assertTrue(NS.Presets.Save("push 14"))
    f.keyLevel = 8; f.regions.oce = nil
    assertTrue(NS.Presets.Load("push 14"))
    assertEqual(NS.Filters.Get(), f)            -- identity preserved
    assertEqual(f.keyLevel, 14); assertTrue(f.regions.oce)
    f.regions.chi = true
    assertEqual(NS.addon.db.global.presets["push 14"].regions.chi, nil) -- not aliased
end)

test("presets: list sorted, delete, bad names, missing", function()
    local NS = T.bootAddon()
    NS.Presets.Save("b"); NS.Presets.Save("a")
    assertEqual(table.concat(NS.Presets.List(), ","), "a,b")
    NS.Presets.Delete("a")
    assertEqual(table.concat(NS.Presets.List(), ","), "b")
    local ok, err = NS.Presets.Save("   "); assertFalse(ok); assertEqual(err, "badName")
    ok, err = NS.Presets.Save(nil); assertFalse(ok); assertEqual(err, "badName")
    ok, err = NS.Presets.Load("zzz"); assertFalse(ok); assertEqual(err, "missing")
end)

test("presets: names are trimmed and saving overwrites", function()
    local NS = T.bootAddon()
    local f = NS.Filters.Get()
    f.keyLevel = 12; NS.Presets.Save("  mine  ")
    f.keyLevel = 18; NS.Presets.Save("mine")
    assertEqual(table.concat(NS.Presets.List(), ","), "mine")
    f.keyLevel = 5
    assertTrue(NS.Presets.Load(" mine "))
    assertEqual(f.keyLevel, 18)
end)

-- Review F-007: a preset saved before a filter key existed must not drop that key on Load.
test("presets: a preset missing keys loads over the current defaults", function()
    local NS = T.bootAddon()
    local f = NS.Filters.Get()
    NS.addon.db.global.presets.old = { keyLevel = 12, noSameSpec = true }
    assertTrue(NS.Presets.Load("old"))
    assertTrue(NS.Filters.Get() == f, "same live table")
    assertEqual(f.keyLevel, 12); assertTrue(f.noSameSpec)
    -- red under: wipe the live table and copy only the preset's keys in Presets.Load
    assertEqual(type(f.regions), "table"); assertEqual(next(f.regions), nil)
    assertEqual(f.maxAgeEnabled, false)
    assertTrue(NS.addon.db.global.presets.old.regions == nil, "the stored preset is not modified")
end)

test("presets: Smart travels with a preset; an older preset loads the default (on)", function()
    local NS = T.bootAddon()
    local f = NS.Filters.Get()
    f.smartKeyLevel = false
    NS.Presets.Save("manual")
    f.smartKeyLevel = true
    NS.Presets.Load("manual"); assertEqual(f.smartKeyLevel, false)
    NS.addon.db.global.presets.old = { keyLevel = 12 }
    assertEqual(NS.C.CHAR_DEFAULTS.filters.smartKeyLevel, true)
    NS.Presets.Load("old"); assertEqual(f.smartKeyLevel, true)
end)

-- ── debug lines (C-19 / review PGE-04) ──────────────────────────────────────────────────────────

-- How many console lines carry `needle` (plain find).
local function logged(NS, needle)
    local n = 0
    for _, line in ipairs(NS.DebugLog.buffer) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

-- red under: drop the NS.Debug lines in Presets.Save / Load / Delete
test("presets: save, load, delete and refusals each write one [Preset] line", function()
    local NS = T.bootAddon()
    NS.State.debug = true
    NS.DebugLog:Clear()
    NS.Presets.Save("  push  ")
    assertEqual(logged(NS, "[Preset] saved 'push'"), 1)
    NS.Presets.Load("push")
    assertEqual(logged(NS, "[Preset] loaded 'push'"), 1)
    NS.Presets.Delete("push")
    assertEqual(logged(NS, "[Preset] deleted 'push'"), 1)
    NS.Presets.Delete("push")
    assertEqual(logged(NS, "[Preset] delete 'push': absent"), 1)
    NS.Presets.Save("   ")
    assertEqual(logged(NS, "[Preset] save refused: badName"), 1)
    NS.Presets.Load("zzz")
    assertEqual(logged(NS, "[Preset] load 'zzz' refused: missing"), 1)
end)
