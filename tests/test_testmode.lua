-- tests/test_testmode.lua — the session-only test mode (R7-PG, Ka0sAddonsCommonTasks
-- docs/2026-11-04-SMOKE_ROUND7, the lead's call 1): `/pgfe test` shows the attached panel on its own,
-- centered on UIParent with the current filters, while PGF's dialog does not show it. Apply and Clear
-- are disabled then (both act on PGF's dialog), nothing is saved, and leaving the mode docks the
-- panel back under the dialog (or hides it). The verb, the Master controls box, the launcher entry and
-- the skin picker's preview all write `state.testMode` through the schema seam.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local PATH = "state.testMode"

local function run(NS, m, input)
    local mark = #m.prints
    NS.addon:OnSlashCommand(input)
    local out = {}
    for i = mark + 1, #m.prints do out[#out + 1] = m.prints[i] end
    return out
end

local function anyLine(lines, fragment)
    for _, l in ipairs(lines) do if tostring(l):find(fragment, 1, true) then return true end end
    return false
end

--- Enabled, the first-run picker closed, PGF's dialog hidden: the panel has nowhere to show.
local function closedDialog()
    local NS, _, m = T.enableAddon()
    NS.addon.Settings.Helpers.HideSkinPicker()
    m.pgf.dialog.shown = false
    NS.Panel.UpdateVisibility()
    return NS, m
end

local function isAlone(NS, m)
    local f = NS.Panel.frame
    if not (f and f:IsShown()) then return false end
    local point, rel = f:GetPoint(1)
    return f:GetParent() == m.UIParent and point == "CENTER" and rel == m.UIParent
end

local function isDocked(NS, m)
    local f = NS.Panel.frame
    local p1, rel1, rp1 = f:GetPoint(1)
    local p2, rel2, rp2 = f:GetPoint(2)
    return f:GetParent() == m.PremadeGroupsFilterDialog
        and p1 == "TOPLEFT" and rel1 == m.PremadeGroupsFilterDialog and rp1 == "BOTTOMLEFT"
        and p2 == "TOPRIGHT" and rel2 == m.PremadeGroupsFilterDialog and rp2 == "BOTTOMRIGHT"
end

--- The tooltip a hover on `widget` draws, as its lines.
local function hoverLines(m, widget)
    local lines = {}
    local setText, addLine = m.GameTooltip.SetText, m.GameTooltip.AddLine
    m.GameTooltip.SetText = function(_, t) lines[#lines + 1] = t end
    m.GameTooltip.AddLine = function(_, t) lines[#lines + 1] = t end
    widget:__fire("OnEnter")
    m.GameTooltip.SetText, m.GameTooltip.AddLine = setText, addLine
    return lines
end

-- ── the verb ─────────────────────────────────────────────────────────────────────────────────────

test("test mode: /pgfe test shows the panel alone, centered on UIParent, and again puts it away", function()
    -- red under: no test row (the dispatcher answers "unknown command"), or a mode that shows the
    -- panel still parented to PGF's hidden dialog (a child of a hidden frame never draws).
    local NS, m = closedDialog()
    assertFalse(NS.Panel.frame ~= nil and NS.Panel.frame:IsShown(), "nothing shows with the dialog closed")
    local out = run(NS, m, "test")
    assertFalse(anyLine(out, "unknown command"), "a known verb")
    assertTrue(NS.Panel.IsTestMode(), "the mode is on")
    assertTrue(isAlone(NS, m), "the panel shows alone, centered")
    assertTrue(anyLine(out, NS.L.TEST_MODE_ON), "the verb says so")
    out = run(NS, m, "test")
    assertFalse(NS.Panel.IsTestMode(), "a second call turns it off")
    assertFalse(NS.Panel.frame:IsShown(), "the panel is put away")
    assertTrue(isDocked(NS, m), "and docked under the dialog again, ready for its next show")
    assertTrue(anyLine(out, NS.L.TEST_MODE_OFF), "the verb says so")
end)

test("test mode: /pgfe test on and off set it, and repeat calls change nothing", function()
    local NS, m = closedDialog()
    run(NS, m, "test on"); assertTrue(NS.Panel.IsTestMode())
    run(NS, m, "test on"); assertTrue(NS.Panel.IsTestMode(), "on stays on")
    run(NS, m, "test off"); assertFalse(NS.Panel.IsTestMode())
    run(NS, m, "test off"); assertFalse(NS.Panel.IsTestMode(), "off stays off")
end)

test("test mode: the verb is refused while the addon is disabled", function()
    -- red under: `test` added to the live verbs (it drives a feature, slash-commands-§7).
    local NS, m = closedDialog()
    run(NS, m, "disable")
    run(NS, m, "test")
    assertFalse(NS.Panel.IsTestMode(), "a disabled addon shows nothing")
end)

test("test mode: the help lists the verb, right after skin", function()
    local NS = T.newAddon()
    local at
    for i, c in ipairs(NS.COMMANDS) do if c[1] == "test" then at = i end end
    assertTrue(at ~= nil, "a test row")
    assertEqual(NS.COMMANDS[at - 1][1], "skin", "after skin")
    assertTrue(NS.COMMANDS[at][2]:find("on|off", 1, true) ~= nil, "the help names on|off")
end)

-- ── the box, through the write seam ──────────────────────────────────────────────────────────────

test("test mode: the Master controls box is a session row whose write is the mode", function()
    -- red under: no testModePath on MasterControls, or a row stored in the profile.
    local NS, m = closedDialog()
    local S = NS.SchemaRuntime
    local row = S.FindRow(PATH)
    assertTrue(row ~= nil, "a Test mode row")
    assertEqual(row.label, "Test mode")
    assertTrue(row.sessionOnly == true, "session state")
    assertEqual(S.Get(PATH), false)
    assertTrue(S.Set(PATH, true))
    assertTrue(NS.Panel.IsTestMode(), "ticking the box turns the mode on")
    assertTrue(isAlone(NS, m))
    assertEqual(S.Get(PATH), true, "the box reads the mode")
    assertEqual(NS.addon.db.profile.state, nil, "nothing is saved")
    run(NS, m, "test")
    assertEqual(S.Get(PATH), false, "the verb and the box are one switch")
end)

test("test mode: Reset all settings ends it", function()
    local NS = closedDialog()
    NS.SchemaRuntime.Set(PATH, true)
    NS.addon.Settings.Helpers.RestoreAllDefaults()
    assertFalse(NS.Panel.IsTestMode())
    assertFalse(NS.Panel.frame:IsShown())
end)

-- ── alone: Apply disabled, the plain title ─────────────────────────────────────────────────────

test("test mode: alone, Apply and Clear are disabled and their tooltips say why", function()
    -- red under: an Apply left enabled with no PGF dialog to search with, or a disabled button that
    -- shows no tooltip (motion scripts off while disabled) or the plain one.
    local NS, m = closedDialog()
    run(NS, m, "test")
    local f = NS.Panel.frame
    assertFalse(f.applyButton:IsEnabled(), "Apply is disabled")
    assertFalse(f.clearButton:IsEnabled(), "Clear is disabled")
    local tip = hoverLines(m, f.applyButton)
    assertEqual(tip[2], NS.L.TEST_MODE_APPLY_TOOLTIP, "Apply says why")
    tip = hoverLines(m, f.clearButton)
    assertEqual(tip[2], NS.L.TEST_MODE_CLEAR_TOOLTIP, "Clear says why")
    assertEqual(f.__title, NS.L.PANEL_TITLE, "the docked panel's plain title: the grayed buttons mark the mode")
end)

test("test mode: alone beside a minimized PGF dialog, the tooltips do not call the window closed", function()
    -- red under: a disabled-button tooltip that says PGF's window is closed while it is open, only
    -- minimized or on another category, so the panel shows alone beside it (R7-PG review).
    local NS, m = closedDialog()
    m.pgf.dialog.shown = true
    m.pgf.dialog.activePanel = { name = "mini" }
    run(NS, m, "test")
    assertTrue(isAlone(NS, m), "alone: the dialog does not show the panel")
    for _, b in ipairs({ NS.Panel.frame.applyButton, NS.Panel.frame.clearButton }) do
        local tip = hoverLines(m, b)
        assertFalse(tostring(tip[2]):find("closed", 1, true) ~= nil, "no claim the window is closed")
    end
end)

test("test mode: alone, the panel shows the current filters", function()
    local NS, m = closedDialog()
    NS.Filters.Set("smartKeyLevel", false)
    NS.Filters.Set("keyLevel", 17)
    run(NS, m, "test")
    assertEqual(NS.Panel.frame.levelBox:GetText(), "17")
end)

test("test mode: opening PGF's dialog docks the panel normally, closing it shows it alone again", function()
    -- red under: a test mode that keeps the panel centered over an open dialog, or one that ends when
    -- the dialog opens.
    local NS, m = closedDialog()
    run(NS, m, "test")
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    assertTrue(NS.Panel.IsTestMode(), "the mode stays on")
    assertTrue(NS.Panel.frame:IsShown())
    assertTrue(isDocked(NS, m), "docked under the dialog")
    assertTrue(NS.Panel.frame.applyButton:IsEnabled(), "Apply works again")
    assertTrue(NS.Panel.frame.clearButton:IsEnabled(), "and Clear")
    assertEqual(NS.Panel.frame.__title, NS.L.PANEL_TITLE, "the plain title")
    m.pgf.dialog.shown = false
    NS.Panel.UpdateVisibility()
    assertTrue(isAlone(NS, m), "alone again")
end)

-- ── alone, it looks like the docked panel (R7-PG2, smoke round 7 images 71 to 74) ──────────────────
--
-- In the client the panel alone came up narrower than docked: standAlone took PGF's dialog's width,
-- and a dialog that is not showing the dungeon panel is still at its template's Size x=300
-- (UI/Dialog.xml:7; SwitchToPanel sets 420 only on the dungeon panel, UI/Dialog.lua:200-202), so the
-- rows built for 420 overlapped (the dropdowns over their labels, the copy label over Clear) and the
-- "(test mode)" title ran into the arrow. Alone it now takes the docked width (the last one it was
-- docked at, else the dungeon panel's desired width) and the dialog's effective scale.

--- The title band and the header as docked: the skin's Shell, Band and Header recorded on the panel,
--- the band on the panel, the title and the arrow on the band's middle.
local function assertDockedHeader(NS, m, what)
    local f = NS.Panel.frame
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    local calls = Skin.painted[f] and Skin.painted[f].calls or {}
    assertTrue(calls.Shell ~= nil and calls.Header ~= nil and calls.Band ~= nil, what .. ": the skin's window paint")
    local band = NS.Skin.Band(f)
    local _, brel = band:GetPoint(1)
    assertTrue(brel == f, what .. ": the title band on the panel")
    local title = f.TitleContainer.TitleText
    local p, rel, _, _, y = title:GetPoint(1)
    assertEqual(p, "CENTER", what .. ": the title centered")
    assertTrue(rel == band and y == 0, what .. ": on the band's middle")
    local mp, mrel, _, mx = f.MaximizeMinimizeFrame:GetPoint(1)
    assertTrue(mp == "RIGHT" and mrel == band and mx == -4, what .. ": the arrow where it sits docked")
end

test("test mode: alone, the panel takes the docked width, not the hidden dialog's template width", function()
    -- red under: standAlone reading the dialog's GetWidth, which is PGF's template 300 until the
    -- dialog shows the dungeon panel (the owner's images 71 and 72).
    local NS, m = closedDialog()
    m.pgf.dialog.width = 300
    run(NS, m, "test")
    assertTrue(isAlone(NS, m))
    assertEqual(NS.Panel.frame:GetWidth(), 420, "the dungeon panel's dialog width, as docked")
end)

test("test mode: alone, the panel takes the width it was last docked at", function()
    -- red under: a width read off the dialog after it hid and went back to another panel's width.
    local NS, m = closedDialog()
    m.pgf.dialog.shown, m.pgf.dialog.width = true, 450
    NS.Panel.UpdateVisibility()
    m.pgf.dialog.shown, m.pgf.dialog.width = false, 300
    run(NS, m, "test")
    assertEqual(NS.Panel.frame:GetWidth(), 450, "the docked width it showed at")
end)

test("test mode: alone, the panel takes the dialog's effective scale; docked again, its own", function()
    -- red under: a panel on UIParent at UIParent's scale, while docked it drew at PGF's dialog's.
    local NS, m = closedDialog()
    m.pgf.dialog.scale = 0.9
    local uiScale = m.UIParent.GetEffectiveScale
    m.UIParent.GetEffectiveScale = function() return 1.5 end
    run(NS, m, "test")
    local alone = NS.Panel.frame:GetScale()
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    local docked = NS.Panel.frame:GetScale()
    m.UIParent.GetEffectiveScale = uiScale
    assertTrue(math.abs(alone - 0.6) < 1e-9, "the dialog's effective scale over UIParent's: " .. tostring(alone))
    assertEqual(docked, 1, "docked, the dialog's child at its own scale again")
end)

test("test mode: alone, the header is the docked one: the plain title centered, the arrow, the band", function()
    -- red under: the "(test mode)" title (it cannot fit the band), or a switch that leaves the header
    -- off the skin's band.
    local NS, m = closedDialog()
    run(NS, m, "test")
    assertEqual(NS.Panel.frame.__title, NS.L.PANEL_TITLE, "the plain title")
    assertEqual(rawget(NS.L, "PANEL_TITLE_TEST"), nil, "no test-mode title string")
    assertDockedHeader(NS, m, "alone")
end)

test("test mode: docking again restores the docked anchors, scale, title, header and buttons", function()
    -- red under: a dock that leaves the alone scale on the panel. UIParent's mock answers no number
    -- for GetEffectiveScale (so dockedScale falls back to 1), so it is armed here, or the alone scale
    -- would already be 1 and the reset would go unchecked (R7-PG2 review).
    local NS, m = closedDialog()
    m.pgf.dialog.width, m.pgf.dialog.scale = 300, 0.8
    local uiScale = m.UIParent.GetEffectiveScale
    m.UIParent.GetEffectiveScale = function() return 1 end
    run(NS, m, "test")
    local f = NS.Panel.frame
    local width, alone = f:GetWidth(), f:GetScale()
    m.pgf.dialog.shown, m.pgf.dialog.width = true, 420
    NS.Panel.UpdateVisibility()
    local docked = f:GetScale()
    m.UIParent.GetEffectiveScale = uiScale
    assertEqual(width, 420)
    assertTrue(math.abs(alone - 0.8) < 1e-9, "alone at the dialog's scale first: " .. tostring(alone))
    assertTrue(isDocked(NS, m), "docked")
    assertEqual(docked, 1, "its own scale")
    assertEqual(f.__title, NS.L.PANEL_TITLE)
    assertTrue(f.applyButton:IsEnabled() and f.clearButton:IsEnabled(), "Apply and Clear work")
    assertDockedHeader(NS, m, "docked")
end)

test("test mode: with PGF's dialog open it changes nothing on screen", function()
    local NS, _, m = T.enableAddon()
    NS.Panel.UpdateVisibility()
    assertTrue(isDocked(NS, m) and NS.Panel.frame:IsShown(), "docked and shown")
    run(NS, m, "test")
    assertTrue(isDocked(NS, m) and NS.Panel.frame:IsShown(), "still docked and shown")
    run(NS, m, "test")
    assertTrue(isDocked(NS, m) and NS.Panel.frame:IsShown(), "off: still docked and shown")
end)

-- ── combat and the stand-down ────────────────────────────────────────────────────────────────────

test("test mode: refused in combat, ended when combat starts, and nothing registered at rest", function()
    -- red under: a start in combat, a mode that survives the pull, or a combat watch left
    -- registered after the mode ended (the performance-§12 exemption: nothing in combat at rest).
    local NS, m = closedDialog()
    m.inCombat = true
    local out = run(NS, m, "test")
    assertFalse(NS.Panel.IsTestMode(), "no start in combat")
    assertTrue(anyLine(out, NS.L.TEST_MODE_COMBAT), "the refusal says why")
    m.inCombat = false
    run(NS, m, "test")
    assertTrue(NS.Panel.IsTestMode())
    m.inCombat = true
    m.__fire("PLAYER_REGEN_DISABLED")
    assertFalse(NS.Panel.IsTestMode(), "combat start ends it")
    assertFalse(NS.Panel.frame:IsShown(), "and the panel is put away")
    assertEqual(NS.SchemaRuntime.Get(PATH), false, "the box reads off")
    m.inCombat = false
    run(NS, m, "test")
    run(NS, m, "test")
    local mark = #m.prints
    m.__fire("PLAYER_REGEN_DISABLED")
    assertEqual(#m.prints, mark, "the watch let go of the event when the mode ended")
end)

test("test mode: the stand-down ends it and leaves the panel docked", function()
    local NS, m = closedDialog()
    run(NS, m, "test")
    run(NS, m, "disable")
    assertFalse(NS.Panel.IsTestMode(), "ended")
    assertFalse(NS.Panel.frame:IsShown())
    assertTrue(isDocked(NS, m), "docked")
    run(NS, m, "enable")
    assertFalse(NS.Panel.frame:IsShown(), "the stand-up does not bring the mode back")
end)

-- ── the launcher ─────────────────────────────────────────────────────────────────────────────────

test("test mode: the launcher passes the Test mode pair, onto the verb's switch", function()
    -- red under: no isTestMode / toggleTestMode on the descriptor (launcher-§2: an addon with a
    -- test mode passes both halves).
    local f = assert(io.open("core/LauncherSetup.lua", "r"))
    local src = f:read("*a")
    f:close()
    assertTrue(src:find("isTestMode%s*=%s*function") ~= nil, "isTestMode is passed")
    assertTrue(src:find("toggleTestMode%s*=%s*function") ~= nil, "toggleTestMode is passed")
    local NS, m = closedDialog()
    local obj = NS.Launcher:Object()
    local lines = {}
    local tt = { AddLine = function(_, t) lines[#lines + 1] = t end, AddDoubleLine = function() end,
        SetText = function(_, t) lines[#lines + 1] = t end, Show = function() end }
    run(NS, m, "test")
    obj.OnTooltipShow(tt)
    assertTrue(anyLine(lines, "Test mode"), "the tooltip has the Test mode line")
end)

-- ── the skin picker's preview (skinning-§10: mode test) ──────────────────────────────────────────

--- The picker `/pgfe skin` shows, and a close by the library's own route (the player's close).
local function skinVerb(NS)
    local f = NS.RunSkinVerb()
    assertTrue(f ~= nil and f:IsShown(), "the picker is up")
    return f
end
local function closePicker(NS) NS.addon.Settings.Helpers.HideSkinPicker() end

test("test mode: the picker's spec.preview is the test mode, entered and left through the seam", function()
    -- red under: the documented no-preview spec (R6-PV), or hooks that flip the panel without the
    -- schema seam (the box would read stale).
    local NS = closedDialog()
    local h = NS.SkinPickerSpec().preview
    assertTrue(type(h) == "table", "a spec.preview")
    assertEqual(h.mode, "test")
    assertFalse(h.isActive(), "off")
    assertFalse(h.isShown(), "the panel is hidden")
    h.enter("picker")
    assertTrue(NS.Panel.IsTestMode() and h.isActive(), "enter turns the mode on")
    assertTrue(h.isShown(), "the panel shows")
    assertEqual(NS.SchemaRuntime.Get(PATH), true, "through the seam the box reads")
    h.exit("picker")
    assertFalse(h.isActive() or h.isShown(), "exit puts it away")
end)

test("test mode: /pgfe skin with the panel hidden turns it on, and every close puts it back", function()
    -- red under: no spec.preview (nothing to preview the pick on), or a close that leaves the panel
    -- up in test mode.
    local NS, m = closedDialog()
    skinVerb(NS)
    assertTrue(NS.Panel.IsTestMode(), "the picker turned test mode on")
    assertTrue(isAlone(NS, m), "the panel shows alone under the picker")
    closePicker(NS)
    assertFalse(NS.Panel.IsTestMode(), "the library's close turned it off")
    assertFalse(NS.Panel.frame:IsShown(), "the panel is put away")
    local f = skinVerb(NS)
    assertTrue(NS.Panel.IsTestMode(), "on again")
    f:Hide()
    f:__fire("OnHide")   -- the client fires OnHide inside Hide(); the kit's stub does not
    assertFalse(NS.Panel.IsTestMode(), "a hide of the window (Escape, the close control) puts it back too")
    f = skinVerb(NS)
    assertTrue(NS.Panel.IsTestMode(), "on again")
    f.apply:__fire("OnClick")
    assertFalse(NS.Panel.IsTestMode(), "Apply closes the picker and puts it back too")
    assertFalse(NS.Panel.frame:IsShown(), "the panel is put away")
end)

test("test mode: with PGF's dialog open, /pgfe skin and its close change nothing", function()
    -- red under: an isShown that ignores the docked panel, so the picker turns the mode on over it.
    local NS, _, m = T.enableAddon()
    closePicker(NS)
    NS.Panel.UpdateVisibility()
    skinVerb(NS)
    assertFalse(NS.Panel.IsTestMode(), "the panel was shown: nothing entered")
    assertTrue(isDocked(NS, m) and NS.Panel.frame:IsShown(), "docked and shown")
    closePicker(NS)
    assertFalse(NS.Panel.IsTestMode())
    assertTrue(isDocked(NS, m) and NS.Panel.frame:IsShown(), "still docked and shown")
end)

test("test mode: the eye toggles it, and a mode the player turned on stays after the close", function()
    local NS, m = closedDialog()
    local f = skinVerb(NS)
    f.preview:__fire("OnClick")
    assertFalse(NS.Panel.IsTestMode(), "the eye turned it off")
    f.preview:__fire("OnClick")
    assertTrue(NS.Panel.IsTestMode(), "and on again")
    closePicker(NS)
    assertFalse(NS.Panel.IsTestMode(), "the close puts back the off it found")
    run(NS, m, "test")
    skinVerb(NS)
    closePicker(NS)
    assertTrue(NS.Panel.IsTestMode(), "a mode on before the picker stays on")
end)
