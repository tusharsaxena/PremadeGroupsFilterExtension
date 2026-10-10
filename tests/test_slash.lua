-- tests/test_slash.lua — NS.COMMANDS and the host verbs (slash-commands).

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local function verbs(NS)
    local out = {}
    for i, row in ipairs(NS.COMMANDS) do
        assertEqual(type(row[1]), "string"); assertEqual(type(row[3]), "function")
        out[i] = row[1]
    end
    return out
end

local function printed(m, needle)
    for _, line in ipairs(m.prints) do
        if line:find(needle, 1, true) then return true end
    end
    return false
end

test("slash: NS.COMMANDS is ordered positional triples with every reserved verb", function()
    local NS = T.newAddon()
    assertEqual(table.concat(verbs(NS), ","),
        "help,config,enable,disable,version,list,get,set,reset,resetall,profile,debug,diagnostics,apply,clear")
    assertTrue(NS.addon.COMMANDS == NS.COMMANDS)
end)

test("slash: /pgfe and /premadegroupsfilterextension are registered through AceConsole", function()
    local NS, _, m = T.bootAddon()
    m.prints = {}
    NS.addon:OnSlashCommand("version")
    assertTrue(printed(m, "1.0.0"))
end)

test("slash: disable and enable write the Enable row through the write seam", function()
    local NS = T.enableAddon()
    NS.addon:OnSlashCommand("disable")
    assertFalse(NS.addon.db.profile.enabled)
    assertTrue(NS.IsStoodDown())
    NS.addon:OnSlashCommand("enable")
    assertTrue(NS.addon.db.profile.enabled)
    assertFalse(NS.IsStoodDown())
end)

-- C-09: `perf` is a reserved verb (slash-commands-§2) that this addon never registers, because it
-- holds the performance-§12 exemption. LibKa0s Slash minor 14+ answers an unregistered reserved
-- verb with the unknown-command line and the index, the same enabled and disabled.
-- red under: restore the perf COMMANDS row
test("slash: perf is reserved but not registered", function()
    local NS, _, m = T.enableAddon()
    for _, row in ipairs(NS.COMMANDS) do
        assertTrue(row[1] ~= "perf", "NS.COMMANDS registers perf")
    end
    m.prints = {}
    NS.addon:OnSlashCommand("perf")
    assertTrue(#m.prints > 1, "the unknown-command line and the index")
    assertTrue(m.prints[1]:find("unknown command 'perf'", 1, true) ~= nil, m.prints[1])
    assertTrue(printed(m, "/pgfe help"), "the index follows")
    local enabled = table.concat(m.prints, "\n")
    NS.addon:OnSlashCommand("disable")
    m.prints = {}
    NS.addon:OnSlashCommand("perf")
    -- The library's index carries its own disabled-status banner while disabled; apart from that
    -- one index line the answer is the same, and it opens on the unknown-command line, not a refusal.
    local banner = NS.SlashCommands:DisabledLine()
    local disabled, banners = {}, 0
    for _, line in ipairs(m.prints) do
        if line:find(banner, 1, true) then banners = banners + 1 else disabled[#disabled + 1] = line end
    end
    assertEqual(banners, 1, "one index banner, no refusal line")
    assertTrue(m.prints[1]:find("unknown command 'perf'", 1, true) ~= nil, m.prints[1])
    assertEqual(table.concat(disabled, "\n"), enabled)
end)

test("slash: the library-absent stub pins the library's disabled line", function()
    local NS = T.newAddon{ skip = T.loadAddon.libFiles }
    local Sl = NS.SlashCommands
    T.assertLibraryConstant(Sl.__disabledLineFormat, "LibKa0s-Slash-1.0", "DISABLED_LINE_FORMAT")
    assertEqual(Sl:DisabledLine(), T.newAddon().SlashCommands:DisabledLine())
end)

test("slash: the library-absent stub still answers version and refuses enable honestly", function()
    local NS, _, m = T.bootAddon{ skip = T.loadAddon.libFiles }
    m.prints = {}
    NS.addon:OnSlashCommand("version")
    assertTrue(printed(m, "1.0.0"))
    NS.addon:OnSlashCommand("enable")
    assertTrue(printed(m, "unavailable"))
end)

-- C-25 (localization-§2): every player-facing line goes through NS.L. A swap "before loading" is
-- not reachable (tests/loader.lua builds NS, and locales/enUS.lua builds NS.L at load), and a swap
-- after load misses the strings built at load time. So the loader's afterFile hook wipes NS.L IN
-- PLACE right after locales/enUS.lua and gives it a sentinel __index: every later `local L = NS.L`
-- capture is the same table, and every key read answers "<<key>>".
local function sentinel(opts)
    opts = opts or {}
    opts.afterFile = function(path, NS)
        if path ~= "locales/enUS.lua" then return end
        for k in pairs(NS.L) do NS.L[k] = nil end
        setmetatable(NS.L, { __index = function(_, k) return "<<" .. tostring(k) .. ">>" end })
    end
    return opts
end

-- A localized line ENDS in the sentinel's close: a literal tail glued onto an already-localized
-- part (the "<cause>, so X is unavailable." family wraps the localized cause clause) would
-- otherwise still contain "<<".
local function localized(s) return type(s) == "string" and s:find(">>%s*$") ~= nil end

-- Run `fn`, then require it printed at least one line and that every line it printed is localized.
local function allLocalized(m, what, fn)
    m.prints = {}
    fn()
    assertTrue(#m.prints > 0, what .. ": printed nothing")
    for _, line in ipairs(m.prints) do
        assertTrue(localized(line), what .. ": a literal line: " .. line)
    end
end

-- red under: revert any site to a literal
test("slash: player-facing lines go through NS.L (LibKa0s absent, the stub paths)", function()
    local NS, _, m = T.bootAddon(sentinel{ skip = T.loadAddon.libFiles })
    local addon, H = NS.addon, NS.addon.Settings.Helpers
    assertTrue(localized(NS.LIBKA0S_MISSING), NS.LIBKA0S_MISSING)
    allLocalized(m, "/pgfe bogus", function() addon:OnSlashCommand("bogus") end)
    allLocalized(m, "help header", function() addon:OnSlashCommand("help") end)
    assertTrue(localized(NS.SlashCommands:HelpHeader()), "HelpHeader")
    allLocalized(m, "bare /pgfe reset", function() addon:OnSlashCommand("reset") end)
    allLocalized(m, "settings CLI", function() addon:OnSlashCommand("list") end)
    allLocalized(m, "settings panel", function() addon:OnSlashCommand("config") end)
    allLocalized(m, "launcher", function() NS.Launcher.Register() end)
    allLocalized(m, "debug logging on", function() NS.DebugLog:SetEnabled(true) end)
    allLocalized(m, "debug logging off", function() NS.DebugLog:SetEnabled(false) end)
    local cb = NS.DebugLog:ConsoleCheckbox()
    assertTrue(localized(cb.label), cb.label)
    assertTrue(localized(cb.tooltip), cb.tooltip)
    H.OpenOptionsPanel = nil
    allLocalized(m, "OpenSettings without the helper", function() addon:OpenSettings() end)
    NS.DebugLog = nil
    allLocalized(m, "/pgfe debug, no console", function() addon:OnSlashCommand("debug") end)
end)

-- With the library loaded, `/pgfe bogus` and the help header are the library's own lines, so only
-- the sites this addon still prints on that path are asserted.
-- red under: revert any site to a literal
test("slash: player-facing lines go through NS.L (LibKa0s present)", function()
    local NS, _, m = T.enableAddon(sentinel())
    local addon, H = NS.addon, NS.addon.Settings.Helpers
    allLocalized(m, "bare /pgfe reset", function() addon:OnSlashCommand("reset") end)
    local page = m.__subcategories["<<General>>"]
    assertTrue(page ~= nil, "the General page is registered under its localized name")
    assertTrue(localized(page.defaultsTooltip), tostring(page.defaultsTooltip))
    H.OpenOptionsPanel = nil
    allLocalized(m, "OpenSettings without the helper", function() addon:OpenSettings() end)
    NS.DebugLog = nil
    allLocalized(m, "/pgfe debug, console not ready", function() addon:OnSlashCommand("debug") end)
end)
