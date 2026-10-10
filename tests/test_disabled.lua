-- tests/test_disabled.lua — disabled means the addon is not running (slash-commands-§7).
--
-- The standard's ten steps, every one built from T.enableAddon() and the kit recorders
-- (tests/_kit/mock_record.lua): `__registrations`, `__timers()` (the live set), `__shownFrames`,
-- `__svWrites` / `__resetSvWrites`, `__printed` / `__resetPrinted`, `__fire` and
-- `__fireUnconditional`. Nothing is injected into NS.FEATURE_EVENTS or NS.STAND_*: the suite
-- asserts on the addon's own rows. The addon prints through the Lua global `print`, which
-- tests/wow_mock.lua captures in `m.prints`, so "nothing said" is asserted on both sinks.
--
-- Production takes only the `disabled` hold (the addon holds the performance-§12 exemption, so no
-- perf harness is wired). Step 10 and the C-16 case take the library's other reserved hold, `perf`,
-- by its library constant, as a test-only second holder production never takes.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local HOLD_PERF = (T.LibStub("LibKa0s-Lifecycle-1.0", true) or {}).HOLD_PERF or "perf"

local NAME = "PremadeGroupsFilterExtension"

-- The eight game events the addon owns, pinned as literals (sorted).
local PINNED = {
    "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "CHALLENGE_MODE_COMPLETED", "CHALLENGE_MODE_MAPS_UPDATE",
    "DISPLAY_SIZE_CHANGED", "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE", "PLAYER_ENTERING_WORLD",
    "PLAYER_SPECIALIZATION_CHANGED", "UI_SCALE_CHANGED",
}

-- ── helpers ─────────────────────────────────────────────────────────────────────────────────────

-- Every live registration's event name, sorted and joined: "" when nothing is registered.
local function registered(m)
    local out = {}
    for _, r in ipairs(m.__registrations()) do out[#out + 1] = r.event end
    table.sort(out)
    return table.concat(out, ",")
end

-- The names NS.FEATURE_EVENTS declares, de-duplicated, sorted and joined.
local function declared(NS)
    local seen, out = {}, {}
    for _, row in ipairs(NS.FEATURE_EVENTS) do
        if not seen[row[1]] then seen[row[1]] = true; out[#out + 1] = row[1] end
    end
    table.sort(out)
    return table.concat(out, ",")
end

local function shownSet(m)
    local set = {}
    for _, f in ipairs(m.__shownFrames()) do set[f] = true end
    return set
end

-- Frames shown now that were not shown in `before`.
local function newlyShown(m, before)
    local n = 0
    for _, f in ipairs(m.__shownFrames()) do
        if not before[f] then n = n + 1 end
    end
    return n
end

-- Forget what has been written and said so far.
local function quiet(m)
    m.__resetSvWrites()
    m.__resetPrinted()
    m.prints = {}
end

local function said(m) return #m.prints + #m.__printed() end

-- The two ways a player disables the addon: the slash verb, and the write seam the Master
-- controls checkbox uses.
local DISABLES = {
    { "/pgfe disable", function(NS) NS.addon:OnSlashCommand("disable") end },
    { "the write seam", function(NS) NS.SchemaRuntime.Set("enabled", false) end },
}

-- An enabled instance with the attached panel built and shown, and its snapshot: R_on (what is
-- registered), T_on (live timers) and F_on (what is on screen).
local function running(opts)
    local NS, _, m = T.enableAddon(opts)
    NS.Panel.UpdateVisibility()
    return NS, m, { R = registered(m), T = #m.__timers(), F = shownSet(m) }
end

-- The launcher's Enabled line, read off the LDB object's own OnTooltipShow with a collecting tooltip.
local function tooltipEnabledLine(NS)
    local lines = {}
    NS.Launcher:Object().OnTooltipShow({ AddLine = function(_, text) lines[#lines + 1] = text end })
    for _, line in ipairs(lines) do
        if line:find("Enabled: ", 1, true) then return line end
    end
end

local function fontString(text)
    return { text = text, GetText = function(self) return self.text end,
        SetText = function(self, t) self.text = t end }
end

-- Count calls to `tbl[key]`, calling through.
local function counted(tbl, key)
    local real, box = tbl[key], { n = 0 }
    tbl[key] = function(...) box.n = box.n + 1; return real(...) end
    return box
end

-- ── step 1: the running snapshot ────────────────────────────────────────────────────────────────

test("disabled 1: enabled, the addon registers exactly the eight events it declares", function()
    local NS, m, on = running()
    assertEqual(on.R, declared(NS), "R_on is NS.FEATURE_EVENTS")
    assertEqual(on.R, table.concat(PINNED, ","))
    assertEqual(on.T, 0, "nothing scheduled at rest")
    assertTrue(NS.Panel.frame ~= nil and NS.Panel.frame:IsShown(), "the panel is up under PGF's dialog")
    assertTrue(on.F[NS.Panel.frame])
    assertEqual(m.__fire("PLAYER_ENTERING_WORLD"), 1, "a registered event reaches its handler")
end)

-- ── steps 2-5: disabled both ways, nothing registered, scheduled or shown ───────────────────────

for _, way in ipairs(DISABLES) do
    test("disabled 2-5: through " .. way[1] .. ", nothing is registered, scheduled or shown", function()
        local NS, m, on = running()
        way[2](NS)
        assertTrue(NS.IsStoodDown())
        assertFalse(NS.addon.db.profile.enabled, "the stored setting is the source")
        -- red under: drop the UnregisterEvent loop in NS.StandDown (core/PGFE.lua:120)
        assertEqual(registered(m), "", "every feature event unregistered, by name")
        for _, event in ipairs(PINNED) do assertEqual(m.__fire(event), 0, event) end
        assertEqual(#m.__timers(), 0, "no live timer")
        assertFalse(NS.Panel.frame:IsShown(), "the stand-down hid the panel")
        local before = shownSet(m)
        for f in pairs(before) do assertTrue(on.F[f], "nothing newly shown by the stand-down") end
        -- Showing PGF's dialog on the Dungeons category shows no panel frame.
        m.pgf.dialog.shown = true
        m.pgf.dialog:SwitchToPanel()
        NS.Panel.UpdateVisibility()
        assertFalse(NS.Panel.frame:IsShown())
        assertEqual(newlyShown(m, before), 0)
    end)
end

-- ── step 6: survivors reached anyway write, say and show nothing ────────────────────────────────

-- Every feature handler fired unconditionally (AceEvent's recorded handler is gone, so the method
-- each NS.FEATURE_EVENTS row names is called too), plus PLAYER_REGEN_DISABLED; every hook body
-- that cannot be unhooked, driven through the function it hooks; and every panel widget callback.
test("disabled 6: survivors reached anyway write, say and show nothing", function()
    local NS, m = running()
    local f = NS.Panel.frame
    NS.addon:OnSlashCommand("disable")
    local before = shownSet(m)
    quiet(m)

    for _, row in ipairs(NS.FEATURE_EVENTS) do
        m.__fireUnconditional(NS.addon, row[1], "player")
        NS.addon[row[2]](NS.addon, row[1], "player")
    end
    m.__fireUnconditional(NS.addon, "PLAYER_REGEN_DISABLED")

    -- The PGF env hook.
    local env = { beastmastery_hunters = 1 }
    m.pgf.PGF.PutPremadeRegionInfo(env, "Bob-Barthilas")
    -- red under: remove NS.IsStoodDown() in EnvInject.Apply (modules/EnvInject.lua:63)
    assertEqual(env.pgfe_on, nil, "the env hook wrote nothing into PGF's env")
    assertEqual(env.region, nil)

    -- The dialog hook.
    m.pgf.dialog:SwitchToPanel()
    assertFalse(f:IsShown())

    -- Both RegionTags painters.
    m.searchResults[1] = { leaderName = "Bob-Barthilas" }
    local row = { resultID = 1, ActivityName = fontString("X") }
    m.LFGListSearchEntry_Update(row)
    -- red under: remove NS.IsStoodDown() in RegionTags' active() (modules/RegionTags.lua:25)
    assertEqual(row.ActivityName.text, "X", "no tag on a search row")
    m.applicants[7] = { "Zed-Barthilas" }
    local member = { Name = fontString("Zed") }
    m.LFGListApplicationViewer_UpdateApplicantMember(member, 7, 1, "applied", false)
    assertEqual(member.Name.text, "Zed", "no tag on an applicant")

    -- The panel's widget callbacks.
    for _, cb in pairs(f.checks) do cb:SetChecked(not cb:GetChecked()); cb:__fire("OnClick") end
    f.activeCheck:SetChecked(not f.activeCheck:GetChecked()); f.activeCheck:__fire("OnClick")
    f.headerClick:__fire("OnClick")
    for _, b in ipairs({ f.saveButton, f.saveAsButton, f.deleteButton, f.applyButton, f.clearButton }) do
        b:__fire("OnClick")
    end
    for _, box in ipairs({ f.levelBox, f.ageBox }) do
        box.__text = "3"
        box:__fire("OnEnterPressed")
        box:__fire("OnEditFocusLost")
    end
    for _, w in ipairs({ f.applyButton, f.activeCheck }) do w:__fire("OnEnter"); w:__fire("OnLeave") end

    assertEqual(#m.__svWrites(), 0, "no SavedVariables write")
    assertEqual(said(m), 0, "nothing said")
    assertEqual(newlyShown(m, before), 0, "nothing shown")
    assertEqual(registered(m), "", "nothing re-registered")
    assertEqual(#m.__timers(), 0, "nothing scheduled")
end)

-- C-37's survivor: EllesmereUI's RegisterSkin cannot be undone, so its callback can arrive while
-- the addon is stood down, and an EUISkin SetChecked hook outlives the stand-down.
test("disabled 6: the EllesmereUI callback and the skin's SetChecked hook paint nothing", function()
    local opts = { mock = function(mm) mm.installEUI() end }
    -- The callback, first fired while stood down.
    local NS, m = running(opts)
    NS.addon:OnSlashCommand("disable")
    local before = shownSet(m)
    quiet(m)
    m.eui.dispatch(NAME)
    -- red under: remove the stoodDown() check from EUISkin blocked() (modules/EUISkin.lua:310)
    assertEqual(#m.eui.calls, 0, "nothing painted")
    assertFalse(NS.EUISkin.IsApplied())
    assertEqual(#m.__svWrites(), 0)
    assertEqual(said(m), 0)
    assertEqual(newlyShown(m, before), 0)

    -- The hook on a skinned box, after a paint while enabled.
    local NS2, m2 = running(opts)
    m2.eui.dispatch(NAME)
    assertTrue(NS2.EUISkin.IsApplied())
    local cb = NS2.Panel.frame.checks.experiencedLeader
    local ring = cb.__children[#cb.__children]
    cb:SetChecked(false)
    NS2.addon:OnSlashCommand("disable")
    quiet(m2)
    cb:SetChecked(true)
    assertFalse(ring:IsShown(), "the accent ring did not follow")
    assertEqual(#m2.__svWrites(), 0)
    assertEqual(said(m2), 0)
end)

-- ── step 7: every verb keeps answering ──────────────────────────────────────────────────────────

local function disabledLine(NS) return NS.SlashCommands:DisabledLine() end

local function onlyLine(m, line)
    return #m.prints == 1 and m.prints[1]:find(line, 1, true) ~= nil
end

local function oneWrite(m, key, value)
    local w = m.__svWrites()
    return #w == 1 and w[1].path:sub(-#key) == key and w[1].value == value
end

-- How each verb answers while disabled. `args` follows the verb, `before` runs first, and
-- `check(NS, m, ctx)` runs after the dispatch. Every NS.COMMANDS verb must have a row, so a new
-- verb fails the walk until it says how it answers.
local VERBS = {
    help        = { check = function(_, m) return #m.prints > 1 end },
    config      = { check = function(_, _, ctx) return ctx.opened.n == 1 end },
    enable      = { check = function(NS) return not NS.IsStoodDown() end },
    disable     = { check = function(NS, m) return NS.IsStoodDown() and #m.prints == 1 end },
    version     = { check = function(_, m) return m.prints[1] ~= nil and m.prints[1]:find("0.1.0", 1, true) ~= nil end },
    list        = { check = function(_, m) return #m.prints > 1 end },
    get         = { args = "enabled",
                    check = function(_, m) return #m.prints == 1 and m.prints[1]:find("false", 1, true) ~= nil end },
    set         = { args = "showRegionTags false", check = function(_, m) return oneWrite(m, "showRegionTags", false) end },
    reset       = { before = "set showRegionTags false", args = "showRegionTags",
                    check = function(_, m) return oneWrite(m, "showRegionTags", true) end },
    resetall    = { check = function(_, m)
                        local p = m.popupsShown[#m.popupsShown]
                        return p ~= nil and p[1] == "PREMADEGROUPSFILTEREXTENSION_RESET_ALL"
                    end },
    profile     = { check = function(_, m) return #m.prints > 0 end },
    debug       = { check = function(_, m, ctx) return newlyShown(m, ctx.before) > 0 end },
    diagnostics = { check = function(_, _, ctx) return ctx.diag.n == 1 end },
    apply       = { check = function(NS, m, ctx) return onlyLine(m, disabledLine(NS)) and ctx.run.n == 0 end },
    clear       = { check = function(NS, m, ctx) return onlyLine(m, disabledLine(NS)) and ctx.clear.n == 0 end },
}

-- A fresh, disabled instance per dispatch, so `enable` cannot change what the next verb meets.
local function dispatchDisabled(line, before)
    local NS, m = running()
    NS.addon:OnSlashCommand("disable")
    if before then NS.addon:OnSlashCommand(before) end
    local ctx = {
        before = shownSet(m),
        opened = counted(NS.addon, "OpenSettings"),
        diag   = counted(NS.DebugLog, "RunDiagnostics"),
        run    = counted(NS.Apply, "Run"),
        clear  = counted(NS.Apply, "Clear"),
    }
    quiet(m)
    NS.addon:OnSlashCommand(line)
    return NS, m, ctx
end

local WRITERS = { set = true, reset = true, enable = true, disable = true }

test("disabled 7: every verb answers while disabled; apply and clear refuse with one line", function()
    local commands = T.enableAddon().COMMANDS
    assertTrue(#commands > 0)
    for _, row in ipairs(commands) do
        assertTrue(VERBS[row[1]] ~= nil, "the walk has no row for /pgfe " .. row[1])
    end
    for _, row in ipairs(commands) do
        local verb, spec = row[1], VERBS[row[1]]
        local line = spec.args and (verb .. " " .. spec.args) or verb
        local NS, m, ctx = dispatchDisabled(line, spec.before)
        assertTrue(spec.check(NS, m, ctx), "/pgfe " .. line .. " did not answer as expected")
        if verb ~= "enable" then
            assertTrue(NS.IsStoodDown(), "/pgfe " .. line .. " left the addon down")
            assertEqual(registered(m), "", "/pgfe " .. line .. " registered nothing")
            assertEqual(#m.__timers(), 0, "/pgfe " .. line .. " scheduled nothing")
        end
        if not WRITERS[verb] then
            assertEqual(#m.__svWrites(), 0, "/pgfe " .. line .. " wrote nothing")
        end
        m.__resetSvWrites()
    end
end)

test("disabled 7: bare /pgfe and /pgfe debug diagnostics answer while disabled", function()
    local NS, m, ctx = dispatchDisabled("")
    assertTrue(NS.IsStoodDown())
    assertEqual(ctx.opened.n, 1, "bare opens the settings")
    assertEqual(#m.__svWrites(), 0)
    assertEqual(registered(m), "")
    NS, m, ctx = dispatchDisabled("debug diagnostics")
    assertEqual(ctx.diag.n, 1, "the report runs")
    assertTrue(NS.IsStoodDown())
    assertEqual(registered(m), "")
end)

-- `perf` is reserved and never registered (performance-§12): the unknown-command line and the
-- index, the same as when enabled apart from the index's own disabled banner.
test("disabled 7: /pgfe perf answers as an unknown command, the same as when enabled", function()
    local NS, m = running()
    for _, row in ipairs(NS.COMMANDS) do assertTrue(row[1] ~= "perf", "NS.COMMANDS registers perf") end
    quiet(m)
    NS.addon:OnSlashCommand("perf")
    local enabled = table.concat(m.prints, "\n")
    assertTrue(m.prints[1]:find("unknown command 'perf'", 1, true) ~= nil, tostring(m.prints[1]))
    assertTrue(#m.prints > 1, "the index follows")
    NS.addon:OnSlashCommand("disable")
    quiet(m)
    NS.addon:OnSlashCommand("perf")
    local banner, rest, banners = disabledLine(NS), {}, 0
    for _, line in ipairs(m.prints) do
        if line:find(banner, 1, true) then banners = banners + 1 else rest[#rest + 1] = line end
    end
    assertEqual(banners, 1, "one index banner, no refusal line")
    assertTrue(m.prints[1]:find("unknown command 'perf'", 1, true) ~= nil, tostring(m.prints[1]))
    assertEqual(table.concat(rest, "\n"), enabled)
    assertEqual(registered(m), "")
end)

-- ── step 8: the launcher ────────────────────────────────────────────────────────────────────────

-- A recording MenuUtil: the generator runs against a root that keeps every checkbox.
local function installMenu(m)
    local menu = { boxes = {} }
    m.MenuUtil = { CreateContextMenu = function(owner, gen)
        local root = {
            CreateTitle = function(_, text) menu.title = text end,
            CreateCheckbox = function(_, label, isSelected, onSelect)
                local box = { label = label, isSelected = isSelected, onSelect = onSelect, enabled = true }
                box.SetEnabled = function(self, on) self.enabled = on and true or false end
                menu.boxes[#menu.boxes + 1] = box
                return box
            end,
        }
        gen(owner, root)
    end }
    return menu
end

test("disabled 8: left-click opens settings; the menu keeps Enabled, which writes only enabled", function()
    local NS, m, on = running()
    NS.addon:OnSlashCommand("disable")
    local before = shownSet(m)
    local opened = counted(NS.addon, "OpenSettings")
    quiet(m)
    local obj = NS.Launcher:Object()
    obj.OnClick(nil, "LeftButton")
    assertEqual(opened.n, 1, "left-click opens the settings, in either state")
    assertEqual(#m.__svWrites(), 0)
    assertEqual(newlyShown(m, before), 0)

    local menu = installMenu(m)
    obj.OnClick(nil, "RightButton")
    assertEqual(#menu.boxes, 1, "the one entry this addon supplies")
    local box = menu.boxes[1]
    assertEqual(box.label, "Enabled")
    assertTrue(box.enabled, "Enabled stays clickable while disabled")
    assertFalse(box.isSelected(), "unchecked: the stored setting is false")
    assertEqual(#m.__svWrites(), 0, "opening the menu writes nothing")

    box.onSelect()
    local w = m.__svWrites()
    assertEqual(#w, 1, "toggling writes one value")
    assertEqual(w[1].path, "PremadeGroupsFilterExtensionDB.profiles.Default.enabled")
    assertEqual(w[1].value, true)
    assertFalse(NS.IsStoodDown())
    assertEqual(registered(m), on.R)
end)

-- C-16 (launcher-§1): the Enabled line reads the same accessor the Master-controls row reads, the
-- stored `enabled` setting, not the latch.
-- red under: revert LauncherSetup:55 to not NS.IsStoodDown()
test("disabled 8: while another hold stands the addon down, the launcher reports the stored setting", function()
    local NS = T.enableAddon()
    NS.Lifecycle:Hold(HOLD_PERF)
    assertTrue(NS.IsStoodDown())
    local line = tooltipEnabledLine(NS)
    NS.Lifecycle:Release(HOLD_PERF)
    assertTrue(line ~= nil and line:find("Yes", 1, true) ~= nil, tostring(line))
end)

test("disabled 8: after /pgfe disable the launcher's Enabled line says No", function()
    local NS = T.enableAddon()
    NS.addon:OnSlashCommand("disable")
    local line = tooltipEnabledLine(NS)
    assertTrue(line ~= nil and line:find("No", 1, true) ~= nil, tostring(line))
end)

-- ── step 9: enable rebuilds from current state ──────────────────────────────────────────────────

test("disabled 9: a setting changed while disabled is what the enable rebuilds from", function()
    local NS, m, on = running()
    assertTrue(NS.Panel.frame.activeCheck:GetChecked())
    NS.addon:OnSlashCommand("disable")
    NS.addon:OnSlashCommand("set filtersActive false")
    assertEqual(registered(m), "", "the write registered nothing")
    NS.addon:OnSlashCommand("enable")
    assertEqual(registered(m), on.R, "R_on restored")
    assertTrue(NS.Panel.frame:IsShown(), "the stand-up re-ran the visibility")
    assertFalse(NS.Panel.frame.activeCheck:GetChecked(), "the rebuild read the new value")
    local env = {}
    m.pgf.PGF.PutPremadeRegionInfo(env, "Bob-Barthilas")
    assertFalse(env.pgfe_on, "the env hook reads it too")
end)

-- ── step 10: one latch, both orders ─────────────────────────────────────────────────────────────

-- red under: replace the Lifecycle Set path in the `enabled` row's onChange (settings/Panel.lua:63) with a direct NS.StandUp()
test("disabled 10: a perf hold then disable, and disable then a perf hold, share one latch", function()
    -- perf hold, then disable: releasing the perf hold leaves the disable standing.
    local NS, m, on = running()
    NS.Lifecycle:Hold(HOLD_PERF)
    assertTrue(NS.IsStoodDown())
    assertEqual(registered(m), "")
    NS.addon:OnSlashCommand("disable")
    NS.Lifecycle:Release(HOLD_PERF)
    assertTrue(NS.IsStoodDown(), "disabled still holds")
    assertEqual(registered(m), "")
    NS.addon:OnSlashCommand("enable")
    assertFalse(NS.IsStoodDown())
    assertEqual(registered(m), on.R)

    -- disable, then a perf hold: enabling leaves the perf hold standing.
    NS, m, on = running()
    NS.addon:OnSlashCommand("disable")
    NS.Lifecycle:Hold(HOLD_PERF)
    NS.addon:OnSlashCommand("enable")
    assertTrue(NS.IsStoodDown(), "the perf hold still holds")
    assertEqual(registered(m), "", "enable did not stand up past the other hold")
    assertFalse(NS.Panel.frame:IsShown())
    NS.Lifecycle:Release(HOLD_PERF)
    assertFalse(NS.IsStoodDown())
    assertEqual(registered(m), on.R)
end)

-- ── the stored path ─────────────────────────────────────────────────────────────────────────────

test("disabled: a profile stored disabled stands down at the next enable", function()
    local NS, _, m = T.bootAddon()
    NS.addon.db.profile.enabled = false
    NS.addon:OnEnable()
    assertTrue(NS.IsStoodDown())
    assertEqual(registered(m), "", "registered at enable, then unregistered by the latch")
    assertEqual(#m.__timers(), 0)
    local line = tooltipEnabledLine(NS)
    assertTrue(line ~= nil and line:find("No", 1, true) ~= nil, tostring(line))
end)
