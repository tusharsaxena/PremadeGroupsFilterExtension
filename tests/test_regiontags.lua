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
    assertEqual(row.ActivityName.text, "|cffa330c9OCE|r Ruby Life Pools (Mythic Keystone)")
    row = searchRow(m, 2, "Ann-Area52", "Altar of Fangs")
    assertEqual(row.ActivityName.text, "|cffff4040CHI|r Altar of Fangs")
end)

test("regiontags: a leader on the player's own realm, an unknown realm, an unsupported portal", function()
    local _, _, m = T.enableAddon{}
    assertEqual(searchRow(m, 1, "Bob", "X").ActivityName.text, "|cffa330c9OCE|r X", "no suffix: Frostmourne")
    assertEqual(searchRow(m, 2, "Bob-Nowhere", "X").ActivityName.text, "|cff9d9d9d?|r X")
    m.currentRegion = 2
    assertEqual(searchRow(m, 3, "Bob-Barthilas", "X").ActivityName.text, "X", "KR/TW/CN: no tag")
end)

test("regiontags: EU realms are tagged by language", function()
    local _, _, m = T.enableAddon{}
    m.currentRegion = 3
    assertEqual(searchRow(m, 1, "Hans-Antonidas", "X").ActivityName.text, "|cffff7c0aGER|r X")
end)

test("regiontags: an applicant gets their region in front of their name", function()
    local _, _, m = T.enableAddon{}
    m.applicants[7] = { "Zed-Barthilas" }
    local member = { Name = fontString("Zed") }
    -- red under: drop the LFGListApplicationViewer_UpdateApplicantMember hook
    m.LFGListApplicationViewer_UpdateApplicantMember(member, 7, 1, "applied", false)
    assertEqual(member.Name.text, "|cffa330c9OCE|r Zed")
end)

test("regiontags: a painter the client lacks is skipped, the other still installs", function()
    local NS, _, m = T.enableAddon{ mock = function(mock)
        mock.LFGListApplicationViewer_UpdateApplicantMember = nil
    end }
    -- red under: drop the RegionTags.hooked store
    assertTrue(type(NS.RegionTags.hooked) == "table", "installed painters are recorded")
    assertEqual(NS.RegionTags.hooked.LFGListSearchEntry_Update, true)
    assertNil(NS.RegionTags.hooked.LFGListApplicationViewer_UpdateApplicantMember)
    assertEqual(searchRow(m, 1, "Bob-Barthilas", "X").ActivityName.text, "|cffa330c9OCE|r X")
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

test("regiontags: every region bucket has a default color and a color row", function()
    local NS = T.newAddon()
    local H = NS.addon.Settings.Helpers
    for _, key in ipairs(NS.Regions.ALL_KEYS) do
        assertTrue(type(NS.C.REGION_HEX[key]) == "string" and #NS.C.REGION_HEX[key] == 6, key)
        -- red under: drop a key from REGION_ROWS in settings/Panel.lua
        local row = H.FindSchema("regionColors." .. key)
        assertTrue(row ~= nil, key .. " row")
        assertEqual(row.type, "color"); assertEqual(row.group, "Region colors"); assertEqual(row.page, "general")
        assertEqual(row.hasAlpha, false, "a |c escape has no alpha")
        assertEqual(NS.RegionTags.Hex(key), NS.C.REGION_HEX[key], key .. " default round-trips to its hex")
    end
end)

test("regiontags: a changed color paints the next tag, and reset puts the default back", function()
    local NS, _, m = T.enableAddon{}
    local H = NS.addon.Settings.Helpers
    H.Set("regionColors.oce", { r = 1, g = 0, b = 0.5, a = 1 })
    -- red under: read RegionTags.Tag's color from the defaults instead of the profile
    assertEqual(searchRow(m, 1, "Bob-Barthilas", "X").ActivityName.text, "|cffff0080OCE|r X")
    H.Set("regionColors.oce", { r = 0, g = 0, b = 1, a = 1 })
    -- red under: cache the hex per key without comparing the stored table
    assertEqual(searchRow(m, 2, "Bob-Barthilas", "X").ActivityName.text, "|cff0000ffOCE|r X")
    H.Set("regionColors.chi", { r = 0, g = 1, b = 0, a = 1 })
    NS.addon.Settings.ResetRegionColors()
    assertEqual(searchRow(m, 3, "Bob-Barthilas", "X").ActivityName.text, "|cffa330c9OCE|r X")
    assertEqual(NS.RegionTags.Hex("chi"), "ff4040")
end)

test("regiontags: /pgfe set takes a color in 0-255", function()
    local NS = T.enableAddon{}
    NS.addon:OnSlashCommand("set regionColors.rus 255 128 0")
    assertEqual(NS.RegionTags.Hex("rus"), "ff8000")
end)

test("regiontags: the Region colors tab shows each portal's tags and a picker per region", function()
    local NS, _, m = T.enableAddon{}
    local H = NS.addon.Settings.Helpers
    local p = m.__subcategories["General"]
    p:Show(); p:__fire("OnShow")
    local ctx = H.__panelFor("general")
    H.SelectTab("general", "Region colors")
    local pickers, labels, buttons = 0, {}, 0
    local function walk(w)
        if w.type == "ColorPicker" then pickers = pickers + 1 end
        if w.type == "Label" and type(w.text) == "string" then labels[#labels + 1] = w.text end
        if w.type == "Button" then buttons = buttons + 1 end
        for _, c in ipairs(w.children or {}) do walk(c) end
    end
    for _, w in ipairs(ctx.scroll.children) do walk(w) end
    -- red under: skip a portal's line in renderRegionTab
    assertEqual(pickers, #NS.Regions.ALL_KEYS)
    assertEqual(buttons, 1, "the reset button")
    local all = table.concat(labels, "\n")
    assertTrue(all:find("|cffa330c9OCE|r", 1, true) ~= nil, "US preview")
    assertTrue(all:find("|cffa330c9RUS|r", 1, true) ~= nil, "EU preview")
    -- The preview follows a write.
    H.Set("regionColors.rus", { r = 1, g = 1, b = 1, a = 1 })
    labels = {}
    for _, w in ipairs(ctx.scroll.children) do walk(w) end
    assertTrue(table.concat(labels, "\n"):find("|cffffffffRUS|r", 1, true) ~= nil, "preview refreshed")
end)
