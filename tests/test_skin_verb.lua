-- tests/test_skin_verb.lua — the reserved `skin` verb (LibKa0s v1.82.0, OptionsSkinPicker minor 3's
-- O.SkinVerb; PG-01 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, ruling D-16):
-- a `skin` row after `config` runs NS.RunSkinVerb, which hands O.SkinVerb the first-run spec, so
-- `/pgfe skin` shows the picker a new profile shows whatever skin.pickerSeen says. Refused while the
-- addon is disabled (the dispatcher's gate), a gray line on every call in combat (the library's),
-- and the library-absent line without LibKa0s.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local NO_LIBKA0S = T.loadAddon.libFiles

local function run(NS, m, input)
    local mark = #m.prints
    NS.addon:OnSlashCommand(input)
    local out = {}
    for i = mark + 1, #m.prints do out[#out + 1] = m.prints[i] end
    return out
end

local function anyLine(lines, fragment)
    for _, l in ipairs(lines) do if l:find(fragment, 1, true) then return true end end
    return false
end

local function strings(m) return m.LibStub("LibKa0s-Options-1.0").SKIN_PICKER_STRINGS end

--- Logged in, the first-run picker closed, so only the verb can bring it back. Answers the picker
--- frame the first run showed (the library reuses one frame per owner).
local function seenProfile()
    local NS, _, m = T.enableAddon()
    local f = NS.MaybeShowSkinPicker()
    assertTrue(f ~= nil, "the first-run picker")
    NS.addon.Settings.Helpers.HideSkinPicker()
    assertEqual(NS.addon.db.profile.skin.pickerSeen, true, "the player's close marked it seen")
    assertFalse(f:IsShown(), "the first-run picker is down")
    return NS, m, f
end

test("skin verb: the row sits right after config, with the library's help words", function()
    local NS, _, m = T.newAddon()
    local at
    for i, c in ipairs(NS.COMMANDS) do
        if c[1] == "skin" then at = i end
    end
    assertTrue(at ~= nil, "a skin row")
    assertEqual(NS.COMMANDS[at - 1][1], "config", "after config")
    assertEqual(NS.COMMANDS[at][2], strings(m).VERB_HELP, "one wording for every host")
end)

test("skin verb: /pgfe skin shows the picker on a profile that has closed it", function()
    -- red under: no skin row (the dispatcher answers "unknown command").
    local NS, m, f = seenProfile()
    local out = run(NS, m, "skin")
    assertFalse(anyLine(out, "unknown command"), "a known verb")
    assertTrue(f:IsShown(), "the picker is up")
end)

test("skin verb: NS.RunSkinVerb hands O.SkinVerb this addon's first-run spec", function()
    local NS = seenProfile()
    local H = NS.addon.Settings.Helpers
    local live, seen = H.SkinVerb, nil
    H.SkinVerb = function(spec) seen = spec; return nil, "queued" end
    local win, why = NS.RunSkinVerb()
    H.SkinVerb = live
    assertTrue(type(seen) == "table", "a spec")
    assertEqual(seen.owner, "PremadeGroupsFilterExtension")
    assertTrue(seen.get == NS.SkinChoice and seen.set == NS.WriteSkinChoice, "the two seams")
    assertEqual(seen.tab, "Appearance", "the gear opens the Skin tab")
    assertEqual(win, nil, "nothing shown")
    assertEqual(why, "queued", "the library's reason, passed on")
end)

test("skin verb: in combat every call prints the library's gray line and shows nothing", function()
    local NS, m, f = seenProfile()
    m.inCombat = true
    local first = run(NS, m, "skin")
    local second = run(NS, m, "skin")
    assertFalse(f:IsShown(), "no picker mid-combat")
    assertTrue(anyLine(first, strings(m).VERB_COMBAT), "the first call says why")
    assertTrue(anyLine(second, strings(m).VERB_COMBAT), "and so does every later one")
end)

test("skin verb: refused while the addon is disabled, and no picker shows", function()
    local NS, m, f = seenProfile()
    NS.addon:OnSlashCommand("disable")
    local out = run(NS, m, "skin")
    assertEqual(#out, 1, "one refusal line")
    assertTrue(out[1]:find("is disabled", 1, true) ~= nil, "the disabled line")
    assertFalse(f:IsShown())
end)

test("skin verb: without LibKa0s the verb prints the library-absent line", function()
    local NS, _, m = T.bootAddon{ skip = NO_LIBKA0S }
    local out = run(NS, m, "skin")
    assertTrue(anyLine(out, "/pgfe skin is unavailable: the LibKa0s library did not load."), "names the verb")
end)
