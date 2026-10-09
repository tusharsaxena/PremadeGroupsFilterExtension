-- tests/test_euisettings.lua — the EllesmereUI skin's settings: the `euiSkin` schema row and the
-- General page's `EllesmereUI skin` tab (docs/superpowers/plans/2026-10-09-eui-skin.md, Task 4).
-- The page is reached the way the client reaches it: the General canvas's OnShow renders it, and
-- the kit's AceGUI recorder keeps every widget the tab drew.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse

local NAME  = "PremadeGroupsFilterExtension"
local GROUP = "EllesmereUI skin"

local function setup(spec)
    return T.enableAddon{ mock = function(m) if spec ~= false then m.installEUI(spec) end end }
end

-- The client's show: the canvas is shown, then its OnShow runs.
local function show(m)
    local p = m.__subcategories["General"]
    p:Show()
    p:__fire("OnShow")
end

-- Render the General page and select the skin tab; answer the ctx and the tab's widgets.
local function openTab(NS, m)
    local H = NS.addon.Settings.Helpers
    show(m)
    local ctx = H.__panelFor("general")
    H.SelectTab("general", GROUP)
    local labels, box = {}, nil
    for _, w in ipairs(ctx.scroll.children) do
        if w.type == "Label" and type(w.text) == "string" and w.text ~= "" then labels[#labels + 1] = w end
        if w.type == "CheckBox" then box = w end
    end
    return ctx, labels, box
end

local function countBad(labels)
    local n = 0
    for _, w in ipairs(labels) do
        if w.text:find("ReadyCheck-NotReady", 1, true) then n = n + 1 end
    end
    return n
end

test("euisettings: euiSkin is a schema row, default on, in its own group on the General page", function()
    local NS = T.newAddon()
    local row = NS.addon.Settings.Helpers.FindSchema("euiSkin")
    assertEqual(row.type, "bool"); assertTrue(row.default)
    assertEqual(row.default, NS.C.PROFILE.euiSkin, "the default lives in defaults/Profile.lua")
    assertEqual(row.page, "general"); assertEqual(row.group, GROUP)
end)

-- options-ui-§15: Master controls stays the first tab.
test("euisettings: the General page's tabs are Master controls, then EllesmereUI skin", function()
    local NS = T.newAddon()
    local H, seen, order = NS.addon.Settings.Helpers, {}, {}
    for _, row in ipairs(NS.addon.Settings.Schema) do
        if row.page == "general" and row.group and not seen[row.group] then
            seen[row.group] = true
            order[#order + 1] = row.group
        end
    end
    assertEqual(table.concat(order, " | "), H.MASTER_GROUP .. " | " .. GROUP)
end)

test("euisettings: the tab draws a line per condition, a state line, then the switch", function()
    local NS, _, m = setup()
    m.eui.dispatch(NAME)
    NS.Panel.Create()
    local _, labels, box = openTab(NS, m)
    assertEqual(#labels, 5, "four conditions and the state line")
    assertEqual(countBad(labels), 0)
    assertTrue(labels[1].text:find("EllesmereUI and its Blizzard Skin module are loaded", 1, true) ~= nil)
    assertTrue(labels[5].text:find("The skin is applied.", 1, true) ~= nil)
    assertTrue(box ~= nil, "the switch")
    assertTrue(box.value); assertFalse(box.disabled)
end)

-- red under: dropping disabledIf from the euiSkin row
test("euisettings: each failing condition disables the switch and is named on its line", function()
    local cases = {
        { { child = false }, 4 },
        { { masterOff = true }, 1 },
        { { entries = { [NAME] = false } }, 1 },
        { { entries = { PremadeGroupsFilter = false } }, 1 },
        { { pgfSkin = false }, 1 },
        { false, 4 },
    }
    for i, case in ipairs(cases) do
        local NS, _, m = setup(case[1])
        local _, labels, box = openTab(NS, m)
        assertTrue(box.disabled, "case " .. i .. " disabled")
        assertEqual(countBad(labels), case[2], "case " .. i .. " failing lines")
        assertTrue(labels[5].text:find("a condition above is not met", 1, true) ~= nil, "case " .. i)
    end
end)

-- red under: dropping the OnShow HookScript from settings/Panel.lua's buildGeneralPage
test("euisettings: a re-show re-reads the lines and the switch after EllesmereUI changed", function()
    local NS, _, m = setup()
    local _, labels, box = openTab(NS, m)
    assertFalse(box.disabled)
    m.EllesmereUIDB.thirdPartySkinsOff = true
    show(m)
    assertTrue(box.disabled)
    assertEqual(countBad(labels), 1)
    m.EllesmereUIDB.thirdPartySkinsOff = nil
    show(m)
    assertFalse(box.disabled); assertEqual(countBad(labels), 0)
end)

test("euisettings: the switch's tooltip says why it is disabled, live", function()
    local NS, _, m = setup{ entries = { PremadeGroupsFilter = false } }
    local _, _, box = openTab(NS, m)
    local lines = {}
    m.GameTooltip.AddLine = function(_, text) lines[#lines + 1] = text end
    box:__fire("OnEnter")
    local text = table.concat(lines, "\n")
    assertTrue(text:find("Disabled until every condition is met", 1, true) ~= nil, text)
    assertTrue(text:find("turn on PremadeGroupsFilter", 1, true) ~= nil, text)
    lines = {}
    m.EllesmereUIDB.thirdPartySkinAddons.PremadeGroupsFilter = nil
    box:__fire("OnEnter")
    assertFalse(table.concat(lines, "\n"):find("Disabled until", 1, true) ~= nil)
end)

-- slash-commands-§6: the CLI cannot turn on what the disabled box cannot.
-- red under: dropping the euiSkin row's validate
test("euisettings: /pgfe set euiSkin true is refused, with the reason, while a condition fails", function()
    local NS, _, m = setup{ masterOff = true }
    local S = NS.SchemaRuntime
    assertTrue((S.Set("euiSkin", false)), "off is always accepted")
    m.prints = {}
    NS.addon:OnSlashCommand("set euiSkin true")
    assertFalse(S.Get("euiSkin"), "nothing stored")
    local out = table.concat(m.prints, "\n")
    assertTrue(out:find("Skin Third-Party Addons", 1, true) ~= nil, out)
    m.EllesmereUIDB.thirdPartySkinsOff = nil
    assertTrue((S.Set("euiSkin", true)), "accepted once every condition holds")
    assertTrue(S.Get("euiSkin"))
end)

test("euisettings: a bulk reset is never refused", function()
    local NS = setup(false)
    local S, H = NS.SchemaRuntime, NS.addon.Settings.Helpers
    S.Set("euiSkin", false)
    H.RestoreAllDefaults()
    assertTrue(S.Get("euiSkin"))
end)

test("euisettings: the switch on paints live through the write seam; off asks for a reload", function()
    local NS, _, m = setup()
    local S = NS.SchemaRuntime
    S.Set("euiSkin", false)
    NS.Panel.Create()
    m.eui.dispatch(NAME)
    assertFalse(NS.EUISkin.IsApplied())
    S.Set("euiSkin", true)
    assertTrue(NS.EUISkin.IsApplied())
    S.Set("euiSkin", false)
    assertEqual(#m.popupsShown, 1)
    assertEqual(NS.addon.Settings.EUISkinStateText(), "The skin is applied until you reload the UI.")
end)

test("euisettings: the state line names what is waiting", function()
    local NS, _, m = setup()
    local text = NS.addon.Settings.EUISkinStateText
    assertEqual(text(), "The skin is applied after a reload.", "no facade yet")
    m.eui.dispatch(NAME)
    assertEqual(text(), "The skin is applied when the panel next shows.")
    NS.SchemaRuntime.Set("euiSkin", false)
    assertEqual(text(), "The skin is off.")
    NS.addon:OnSlashCommand("disable")
    assertEqual(text(), "The skin is not applied while the addon is disabled.")
end)

test("euisettings: a gate opened in EllesmereUI's options paints on the panel's next show", function()
    local NS, _, m = setup{ entries = { PremadeGroupsFilter = false } }
    NS.Panel.Create()
    m.eui.dispatch(NAME)
    assertFalse(NS.EUISkin.IsApplied())
    m.EllesmereUIDB.thirdPartySkinAddons.PremadeGroupsFilter = nil
    -- red under: dropping the TryApply call from Panel.UpdateVisibility
    NS.Panel.UpdateVisibility()
    assertTrue(NS.EUISkin.IsApplied())
end)

test("euisettings: LibKa0s absent with EllesmereUI present loads, registers and keeps the row", function()
    local NS = T.newAddon{ skip = T.loadAddon.libFiles, mock = function(m) m.installEUI() end }
    assertTrue(NS.EUISkin.registered)
    assertTrue(NS.SchemaRuntime.FindRow("euiSkin") ~= nil)
end)

-- Owner request: with the PGF skin not installed, offer it: a box holding its CurseForge link.
test("euisettings: a missing PGF skin gets a box with its CurseForge link; installed, no box", function()
    local NS, _, m = setup{ pgfSkin = "missing" }
    openTab(NS, m)
    local box = NS.addon.Settings.PGFSkinLinkBox
    -- red under: drop addPGFSkinLink from renderEuiTab
    assertTrue(box ~= nil, "the link box")
    assertEqual(box:GetText(), "https://www.curseforge.com/wow/addons/premade-groups-filter-ellesmereui")
    box.text = "junk"; box:__fire("OnTextChanged")
    assertEqual(box:GetText(), NS.EUIBridge.PGF_SKIN_URL, "typing puts the link back")
    local NS2, _, m2 = setup{ pgfSkin = false }
    openTab(NS2, m2)
    assertEqual(NS2.addon.Settings.PGFSkinLinkBox, nil, "installed but disabled: no link")
end)
