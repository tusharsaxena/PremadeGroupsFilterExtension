-- tests/test_regiontags.lua — NS.RegionTags, the server region on Group Finder rows (owner request:
-- replace PremadeRegions). The two hooks are reached only through Blizzard's own painters, which
-- tests/wow_mock.lua's hooksecurefunc genuinely wraps.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

-- A font string stand-in: GetText / SetText over one field.
local function fontString(text)
    return { text = text, GetText = function(self) return self.text end,
        SetText = function(self, t) self.text = t end }
end

local function searchRow(m, id, leader, activity)
    m.searchResults[id] = { leaderName = leader }
    local row = { resultID = id, ActivityName = fontString(activity) }
    m.LFGListSearchEntry_Update(row)
    return row
end

test("regiontags: a search row gets the leader's colored region in front of its activity", function()
    local _, _, m = T.enableAddon{}
    -- red under: drop the LFGListSearchEntry_Update hook in modules/RegionTags.lua
    local row = searchRow(m, 1, "Bob-Barthilas", "Ruby Life Pools (Mythic Keystone)")
    assertEqual(row.ActivityName.text, "|cff33cc66OCE|r Ruby Life Pools (Mythic Keystone)")
    row = searchRow(m, 2, "Ann-Area52", "Altar of Fangs")
    assertEqual(row.ActivityName.text, "|cffff4040CHI|r Altar of Fangs")
end)

test("regiontags: a leader on the player's own realm, an unknown realm, an unsupported portal", function()
    local _, _, m = T.enableAddon{}
    assertEqual(searchRow(m, 1, "Bob", "X").ActivityName.text, "|cff33cc66OCE|r X", "no suffix: Frostmourne")
    assertEqual(searchRow(m, 2, "Bob-Nowhere", "X").ActivityName.text, "|cff9d9d9d?|r X")
    m.currentRegion = 2
    assertEqual(searchRow(m, 3, "Bob-Barthilas", "X").ActivityName.text, "X", "KR/TW/CN: no tag")
end)

test("regiontags: EU realms are tagged by language", function()
    local _, _, m = T.enableAddon{}
    m.currentRegion = 3
    assertEqual(searchRow(m, 1, "Hans-Antonidas", "X").ActivityName.text, "|cffffd100GER|r X")
end)

test("regiontags: an applicant gets their region in front of their name", function()
    local _, _, m = T.enableAddon{}
    m.applicants[7] = { "Zed-Barthilas" }
    local member = { Name = fontString("Zed") }
    -- red under: drop the LFGListApplicationViewer_UpdateApplicantMember hook
    m.LFGListApplicationViewer_UpdateApplicantMember(member, 7, 1, "applied", false)
    assertEqual(member.Name.text, "|cff33cc66OCE|r Zed")
end)

test("regiontags: no tag while stood down, with the setting off, or with PremadeRegions loaded", function()
    local NS, _, m = T.enableAddon{}
    NS.addon:OnSlashCommand("disable")
    -- red under: drop the stand-down check in RegionTags' active()
    assertEqual(searchRow(m, 1, "Bob-Barthilas", "X").ActivityName.text, "X")
    NS.addon:OnSlashCommand("enable")
    NS.addon.Settings.Helpers.Set("showRegionTags", false)
    -- red under: drop the showRegionTags check
    assertEqual(searchRow(m, 2, "Bob-Barthilas", "X").ActivityName.text, "X")
    NS.addon.Settings.Helpers.Set("showRegionTags", true)
    m.PremadeRegions = {}
    -- red under: drop the PremadeRegions check (two tags would stack)
    assertEqual(searchRow(m, 3, "Bob-Barthilas", "X").ActivityName.text, "X")
end)

test("regiontags: the setting is a schema row, on by default", function()
    local NS = T.enableAddon{}
    local row = NS.addon.Settings.Helpers.FindSchema("showRegionTags")
    assertTrue(row ~= nil); assertEqual(row.default, true)
    assertTrue(NS.addon.Settings.Helpers.Get("showRegionTags"))
end)

test("regiontags: a name that is not a plain string gets no tag and raises nothing", function()
    local NS = T.enableAddon{}
    assertNil(NS.RegionTags.Tag(nil)); assertNil(NS.RegionTags.Tag(42))
    local real = NS.IsConcatSafe
    NS.IsConcatSafe = function() return false end -- a protected ("secret") name
    -- red under: drop the IsConcatSafe check in RegionTags.Tag
    assertNil(NS.RegionTags.Tag("Bob-Barthilas"))
    NS.IsConcatSafe = real
end)

test("regiontags: every region bucket has a color", function()
    local NS = T.newAddon()
    for _, key in ipairs(NS.Regions.ALL_KEYS) do
        assertTrue(type(NS.RegionTags.COLORS[key]) == "string" and #NS.RegionTags.COLORS[key] == 6, key)
    end
end)
