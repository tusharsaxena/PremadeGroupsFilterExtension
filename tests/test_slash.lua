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
        "help,config,enable,disable,version,list,get,set,reset,resetall,profile,debug,diagnostics,perf")
    assertTrue(NS.addon.COMMANDS == NS.COMMANDS)
end)

test("slash: /pgfe and /premadegroupsfilterextension are registered through AceConsole", function()
    local NS, _, m = T.bootAddon()
    m.prints = {}
    NS.addon:OnSlashCommand("version")
    assertTrue(printed(m, "0.1.0"))
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

test("slash: perf answers through the harness and prints its lines", function()
    local NS, _, m = T.enableAddon()
    m.prints = {}
    NS.addon:OnSlashCommand("perf status")
    assertTrue(#m.prints > 0)
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
    assertTrue(printed(m, "0.1.0"))
    NS.addon:OnSlashCommand("enable")
    assertTrue(printed(m, "unavailable"))
end)
