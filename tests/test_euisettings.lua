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
        if w.type == "InteractiveLabel" and type(w.text) == "string" and w.text ~= "" then labels[#labels + 1] = w end
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

test("euisettings: the tab draws the switch, a line per condition, then a state line", function()
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

-- The kit's AceGUI fake gives an EditBox no inner `editbox` frame, so the link box's focus hook
-- would never run under the harness. Wrap the lib's Create (the table Helpers.AceGUI points at, so
-- addPGFSkinLink sees the wrap) to hand every EditBox ONE shared stub frame, the way AceGUI's pool
-- hands a released frame to the next widget. Answers the frame, a focus counter, the EditBox
-- create count, and the restore.
local function wrapEditBoxes(NS, m)
    local AG = NS.addon.Settings.Helpers.AceGUI
    local eb, hits, creates = m.__stubFrame(), { n = 0 }, { n = 0 }
    rawset(eb, "HighlightText", function() hits.n = hits.n + 1 end)
    local orig = AG.Create
    AG.Create = function(self, t, ...)
        local w = orig(self, t, ...)
        if t == "EditBox" then w.editbox = eb; creates.n = creates.n + 1 end
        return w
    end
    return eb, hits, creates, function() AG.Create = orig end
end

-- red under: drop the OnEditFocusGained hook from addPGFSkinLink
test("euisettings: focusing the PGF-skin link box selects the link", function()
    local NS, _, m = setup{ pgfSkin = "missing" }
    local eb, hits, _, restore = wrapEditBoxes(NS, m)
    openTab(NS, m)
    eb:__fire("OnEditFocusGained")
    restore()
    assertEqual(hits.n, 1)
end)

-- red under: delete the OnRelease callback
test("euisettings: a released PGF-skin link box no longer selects, and is forgotten", function()
    local NS, _, m = setup{ pgfSkin = "missing" }
    local eb, hits, _, restore = wrapEditBoxes(NS, m)
    openTab(NS, m)
    local box = NS.addon.Settings.PGFSkinLinkBox
    assertTrue(box ~= nil, "the link box")
    box:Release()
    eb:__fire("OnEditFocusGained")
    restore()
    assertEqual(hits.n, 0, "the pooled frame no longer selects for a released widget")
    assertEqual(NS.addon.Settings.PGFSkinLinkBox, nil)
end)

-- red under: drop the __pgfeLinkHook guard
test("euisettings: a re-rendered PGF-skin link box hooks its pooled frame once", function()
    local NS, _, m = setup{ pgfSkin = "missing" }
    local eb, hits, creates, restore = wrapEditBoxes(NS, m)
    openTab(NS, m)
    NS.addon.Settings.Helpers.SelectTab("general", GROUP)
    assertEqual(creates.n, 2, "the second SelectTab re-rendered the tab")
    eb:__fire("OnEditFocusGained")
    restore()
    assertEqual(hits.n, 1, "one selection per focus, not one per render")
end)

-- Owner request: a gap above the state line, and the state line (and a failing condition's hint)
-- starting in an empty icon slot the size of the status icons, so its text sits under theirs.
test("euisettings: the state line sits below a gap, in an empty icon slot like the hints", function()
    local NS, _, m = setup{ entries = { PremadeGroupsFilter = false } }
    m.eui.dispatch(NAME)
    NS.Panel.Create()
    local ctx = openTab(NS, m)
    local kids, stateAt = ctx.scroll.children, nil
    local BLANK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0:64:64:0:1:0:1|t "
    for i, w in ipairs(kids) do
        if w.type == "InteractiveLabel" and type(w.text) == "string" and w.text:find("The skin is", 1, true) then stateAt = i end
    end
    assertTrue(stateAt ~= nil, "the state line")
    -- red under: drop the STATUS_GAP spacer in renderEuiTab
    local gapAt = stateAt - 1
    assertEqual(kids[gapAt].type, "SimpleGroup"); assertEqual(kids[gapAt].height, 8)
    -- red under: the state line without ICON_BLANK in front
    assertEqual(kids[stateAt].text:sub(1, #BLANK), BLANK)
    -- The failing pgf condition's hint line uses the same slot, not spaces.
    local pgfLine = kids[gapAt - 1].text
    assertTrue(pgfLine:find("\n" .. BLANK, 1, true) ~= nil, pgfLine)
end)

-- Owner request: the switch first, with a gap before the status lines.
test("euisettings: the switch comes first, then a gap, then the condition lines", function()
    local NS, _, m = setup()
    local ctx = openTab(NS, m)
    local kids = ctx.scroll.children
    local boxAt
    for i, w in ipairs(kids) do if w.type == "CheckBox" then boxAt = boxAt or i end end
    -- red under: render the switch after the status lines
    assertEqual(boxAt, 1, "the switch is the tab's first widget")
    assertEqual(kids[2].type, "SimpleGroup"); assertEqual(kids[2].height, 12)
    assertEqual(kids[3].type, "InteractiveLabel")
end)

-- Owner request: every status line explains itself on hover: what, why, how.
test("euisettings: each condition line and the state line have a what / why / how tooltip", function()
    local NS, _, m = setup{ masterOff = true }
    local _, labels = openTab(NS, m)
    assertEqual(#labels, 5)
    for i, w in ipairs(labels) do
        local title, body
        m.GameTooltip.SetText = function(_, t) title = t end
        m.GameTooltip.AddLine = function(_, t) body = t end
        -- red under: statusRow without the OnEnter callback
        assertTrue(type(w.callbacks.OnEnter) == "function", "line " .. i)
        w:__fire("OnEnter")
        assertTrue(type(title) == "string" and title ~= "", "line " .. i .. " title")
        assertTrue(type(body) == "string" and #body > 60, "line " .. i .. " body: " .. tostring(body))
    end
    local body2
    m.GameTooltip.AddLine = function(_, t) body2 = t end
    labels[2]:__fire("OnEnter")
    assertTrue(body2:find("Skin Third-Party Addons", 1, true) ~= nil, "the master line says how")
end)
