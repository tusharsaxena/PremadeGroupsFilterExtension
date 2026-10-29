-- tests/test_skin_picker.lua — the first-run skin picker and the owner-aware tool surfaces on this
-- addon's seam (core/SkinSetup.lua; LibKa0s OptionsSkinPicker 1, SkinAce; PG-04 of the skinning
-- rollout).
--
-- What this addon owes the picker, and nothing the library pins itself: the spec it hands
-- O.SkinPicker (its owner, its two seams, the General page's Skin tab, no eye, the close); WHEN it
-- shows (a profile whose `skin.pickerSeen` is false, once at login and after every profile event,
-- never stood down, never in combat: held to PLAYER_REGEN_ENABLED on a one-shot private frame); and
-- that only the player's close marks it seen. Then the AceGUI rows this addon acquires past the
-- Options proxy (the Profiles page's AceConfigDialog tree) painted for this owner, a host release
-- chained onto the skin's restore, and the debug console painted for this owner.
--
-- Every case builds its own instance, so nothing leaks between cases.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local OWNER = "PremadeGroupsFilterExtension"
local PATH = "skin.pickerSeen"

--- Replace the Options instance's SkinPicker with a recorder of each call's spec, calling nothing.
local function spy(NS)
    local H = NS.addon.Settings.Helpers
    local calls = {}
    H.SkinPicker = function(spec)
        calls[#calls + 1] = spec
        return { spy = true }
    end
    return calls
end

--- An enabled instance whose picker is a recorder from before OnEnable, so the login show counts.
local function spiedEnable(opts)
    local NS, _, m = T.bootAddon(opts)
    local calls = spy(NS)
    T.settleSkinLogin(m)
    NS.addon:OnEnable()
    return NS, m, calls
end

local function set(NS, path, v) NS.SchemaRuntime.Set(path, v) end
local function get(NS, path) return NS.SchemaRuntime.Get(path) end

-- ── the key and the spec ─────────────────────────────────────────────────────────────────────────

test("skin picker: skin.pickerSeen defaults to false, a skip-render row on the Skin tab", function()
    -- red under: a default of true (no profile would ever show it, against O3), or a row that draws
    -- itself.
    local NS = T.bootAddon()
    assertEqual(NS.C.PROFILE.skin.pickerSeen, false)
    local row = NS.SchemaRuntime.FindRow(PATH)
    assertTrue(row ~= nil, PATH .. " is not a schema row")
    assertEqual(row.type, "bool")
    assertEqual(row.group, "Appearance")
    assertTrue(row.skipRender == true, "nothing draws it")
end)

test("skin picker: the spec names this owner, its seams, the General page's Skin tab, and no eye", function()
    -- red under: a set that is not the write seam (a pick would never reach the profile), a page or
    -- tab key the gear cannot open, or an eye with nothing to preview in (X6).
    local NS = T.enableAddon()
    local spec = NS.SkinPickerSpec()
    assertEqual(spec.owner, OWNER)
    assertTrue(rawequal(spec.get, NS.SkinChoice), "get is the read seam")
    assertTrue(rawequal(spec.set, NS.WriteSkinChoice), "set is the write seam")
    assertEqual(spec.page, "general", "the key settings/Panel.lua registered the General page under")
    assertEqual(spec.tab, "Appearance", "the Skin tab's key")
    assertEqual(spec.onPreview, nil, "no window or test mode to preview in: no eye")
    assertEqual(type(spec.onClose), "function")
end)

-- ── when it shows ────────────────────────────────────────────────────────────────────────────────

test("skin picker: it shows once at login on an unseen profile, scheduling nothing", function()
    -- red under: dropping the call from OnEnable, or deferring it on a timer (the addon schedules
    -- nothing at rest, tests/test_disabled.lua).
    local NS, m, calls = spiedEnable()
    assertEqual(#calls, 1, "OnEnable shows the picker")
    assertEqual(calls[1].owner, OWNER)
    assertEqual(#m.__timers(), 0, "no timer")
    set(NS, PATH, true)
    NS.MaybeShowSkinPicker()
    assertEqual(#calls, 1, "pickerSeen true: it does not show again")
end)

test("skin picker: a profile that has seen it shows nothing at login", function()
    local NS, _, m = T.bootAddon()
    set(NS, PATH, true)
    local calls = spy(NS)
    T.settleSkinLogin(m)
    NS.addon:OnEnable()
    assertEqual(#calls, 0)
end)

test("skin picker: in combat a start waits for PLAYER_REGEN_ENABLED, once, on a private frame", function()
    -- red under: showing in combat, or a retry that stays registered after it fires.
    local NS, m, calls = spiedEnable({ inCombat = true })
    assertEqual(#calls, 0, "nothing shows in combat")
    NS.MaybeShowSkinPicker()
    m.inCombat = false
    m.__fire("PLAYER_REGEN_ENABLED")
    assertEqual(#calls, 1, "the combat edge shows it, once for two held starts")
    -- The profile is still unseen (the spy marks nothing), so a retry still registered would show
    -- it a second time here.
    m.__fire("PLAYER_REGEN_ENABLED")
    assertEqual(#calls, 1, "the one-shot frame let go of the event")
end)

test("skin picker: a held start is dropped by the stand-down", function()
    local NS, m, calls = spiedEnable({ inCombat = true })
    NS.addon:OnSlashCommand("disable")
    assertTrue(NS.IsStoodDown())
    m.inCombat = false
    m.__fire("PLAYER_REGEN_ENABLED")
    assertEqual(#calls, 0, "the stand-down dropped the held start")
end)

test("skin picker: a dropped held start lets go of its frame, and the next one makes its own", function()
    -- red under: a retry frame the addon keeps for the session once the deferral drops (D11).
    local NS, m, calls = spiedEnable({ inCombat = true })
    local made, base = 0, m.CreateFrame   -- the mock is the addon's _G
    m.CreateFrame = function(...) made = made + 1; return base(...) end
    NS.HideSkinPicker()                       -- drops the held start (a stand-down step)
    NS.MaybeShowSkinPicker()                  -- still in combat: held again
    m.CreateFrame = base
    assertEqual(made, 1, "the dropped deferral kept its frame, so no fresh one was made")
    m.inCombat = false
    m.__fire("PLAYER_REGEN_ENABLED")
    assertEqual(#calls, 1, "the fresh frame shows it on the combat edge")
end)

test("skin picker: never while the addon is switched off", function()
    local NS, _, m = T.bootAddon()
    NS.addon.db.profile.enabled = false
    local calls = spy(NS)
    T.settleSkinLogin(m)
    NS.addon:OnEnable()
    assertTrue(NS.IsStoodDown())
    NS.MaybeShowSkinPicker()
    assertEqual(#calls, 0, "a disabled addon shows no picker")
end)

test("skin picker: a new profile and a reset profile show it again; a seen one does not", function()
    -- red under: no call on the profile path, or one before the latch re-reads the new profile.
    local NS, _, calls = spiedEnable()
    local db = NS.addon.db
    set(NS, PATH, true)
    db:SetProfile("PickerProbe")
    assertEqual(#calls, 2, "a new profile shows the picker")
    set(NS, PATH, true)
    db:ResetProfile()
    assertEqual(#calls, 3, "a reset profile shows it again")
    set(NS, PATH, true)
    db:SetProfile("Default")
    assertEqual(#calls, 3, "back on a profile that has seen it: no picker")
end)

-- ── the real window ──────────────────────────────────────────────────────────────────────────────

test("skin picker: the player's close marks it seen; this addon's own hide does not", function()
    local NS = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    local f = NS.MaybeShowSkinPicker()
    assertTrue(f ~= nil and f:IsShown(), "the library's picker did not show")
    NS.HideSkinPicker()
    assertFalse(f:IsShown())
    assertEqual(get(NS, PATH), false, "this addon's hide is not the player's close")
    f = NS.MaybeShowSkinPicker()
    assertTrue(f ~= nil and f:IsShown(), "it shows again while unseen")
    H.HideSkinPicker()
    assertEqual(get(NS, PATH), true, "the player's close sets skin.pickerSeen")
    assertEqual(NS.MaybeShowSkinPicker(), nil, "and it does not show again")
end)

test("skin picker: the stand-down takes it down unmarked", function()
    local NS = T.enableAddon()
    local f = NS.MaybeShowSkinPicker()
    assertTrue(f ~= nil and f:IsShown())
    NS.addon:OnSlashCommand("disable")
    assertFalse(f:IsShown(), "the stand-down left the picker up")
    assertEqual(get(NS, PATH), false, "a stand-down is not the player's close")
end)

test("skin picker: a profile that has seen it takes a shown picker down, unmarked", function()
    local NS = T.enableAddon()
    local f = NS.MaybeShowSkinPicker()
    assertTrue(f ~= nil and f:IsShown())
    NS.addon.db.profile.skin.pickerSeen = true
    NS.MaybeShowSkinPicker()
    assertFalse(f:IsShown(), "the picker stayed up on a profile that has seen it")
end)

-- ── the AceGUI rows and the tool surfaces ────────────────────────────────────────────────────────

test("skin tools: the Options instance acquires through the library's owner proxy", function()
    -- The Region tags tab's SimpleGroup and every library maker's row come from Helpers.AceGUI, which
    -- paints on Create for this owner (SkinAce). red under: the proxy not attached (no owner).
    local NS, _, m = T.enableAddon()
    local H = NS.addon.Settings.Helpers
    assertTrue(H.AceGUI ~= nil and not rawequal(H.AceGUI, m.LibStub("AceGUI-3.0")),
        "Helpers.AceGUI is AceGUI itself: nothing it creates is painted for " .. OWNER)
end)

test("skin tools: the Profiles page paints AceConfigDialog's tree for this owner", function()
    -- AceConfigDialog acquires its widgets from AceGUI itself, past the proxy. The harness carries
    -- no AceConfig, so a fake Open records the container it draws into. red under: dropping
    -- NS.SkinPaintAceTree from the Profiles renderer.
    local opened = {}
    local NS, _, m = T.enableAddon({ mock = function(mm)
        local LS = mm.LibStub
        LS:NewLibrary("AceConfigDialog-3.0", 1).Open = function(_, _, c) opened[#opened + 1] = c end
        LS:NewLibrary("AceConfig-3.0", 1).RegisterOptionsTable = function() end
        LS:NewLibrary("AceDBOptions-3.0", 1).GetOptionsTable = function() return {} end
    end })
    local trees = {}
    local real = NS.SkinPaintAceTree
    NS.SkinPaintAceTree = function(c) trees[#trees + 1] = c; return real(c) end
    local p = m.__subcategories["Profiles"]
    assertTrue(p ~= nil, "the Profiles page was not registered")
    p:Show(); p:__fire("OnShow")
    assertEqual(#opened, 1, "AceConfigDialog drew the page")
    assertEqual(#trees, 1, "the Profiles renderer painted nothing")
    assertTrue(rawequal(trees[1], opened[1]), "the tree painted is the container AceConfigDialog drew into")
end)

test("skin tools: a host release is chained onto the skin's restore, both run", function()
    local NS, _, m = T.enableAddon()
    local AceGUI = m.LibStub("AceGUI-3.0")
    local w = AceGUI:Create("EditBox")
    local order = {}
    w:SetCallback("OnRelease", function() order[#order + 1] = "previous" end)
    NS.SkinOnRelease(w, function() order[#order + 1] = "host" end)
    AceGUI:Release(w)
    -- AceGUI fires the OnRelease callback, then calls the widget's OnRelease member, which the
    -- library's chain wraps: both run, and neither replaces the other.
    table.sort(order)
    assertEqual(table.concat(order, ","), "host,previous", "the host's work and the previous release")
end)

test("skin tools: the debug console is painted for this owner", function()
    -- LibKa0s-DebugLog-1.0 takes addonName as the skin owner while the descriptor sets neither
    -- `skin` nor `applySkin` (core/DebugLogSetup.lua). red under: a host applySkin.
    local NS, _, m = T.enableAddon()
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    NS.DebugLog:Show()
    local f = NS.DebugLog._frameForTest
    assertTrue(f ~= nil, "the console frame")
    local rec = Skin.painted[f]
    assertTrue(rec ~= nil and rec.owner == OWNER, "the console window is recorded for " .. OWNER)
    NS.DebugLog:Hide()
end)
