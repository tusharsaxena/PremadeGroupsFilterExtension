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
    assertTrue(printed(m, "0.1.0"))
    NS.addon:OnSlashCommand("enable")
    assertTrue(printed(m, "unavailable"))
end)
