-- tests/test_skinsetup.lua — the LibKa0s-Skin-1.0 seam (core/SkinSetup.lua, skinning-§1..§3; PG-01).
--
-- What this addon owes the skin engine, and nothing the library pins itself: the owner is
-- registered under the folder name with this addon's read and write seams; the eight skin.* keys
-- default to Ka0s Default and are skip-render schema rows on the Skin tab; the tab is the library's
-- and the General page's last; the profile's skin is applied right after AceDB exists and on every
-- profile event; one pick from the tab, or from another addon's copy, is ONE effective SetChoice
-- (one OnLooksChanged, no reload request), however many store writes follow it; the window-edge
-- factory is handed the owner; and without the library the degraded facade answers every name the
-- live one carries, from a host copy of Ka0s Default that must equal the library's.
--
-- Every case builds its own instance, so nothing leaks between cases.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local OWNER = "PremadeGroupsFilterExtension"
local BRAND = "Ka0s Premade Groups Filter Extension"
local NO_LIBKA0S = T.loadAddon.libFiles

local KEYS = {
    { "source", "ka0s" }, { "skin", "ka0s" }, { "ignorePanel", true }, { "ignoreFonts", false },
    { "font", "" }, { "texture", "" }, { "outline", "all" }, { "pickerSeen", false },
}

--- An enabled instance, its Skin major and a counter of this owner's looks changes and reload
--- requests.
local function setup(opts)
    local NS, _, m = T.enableAddon(opts)
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    local counts = { looks = 0, reloads = 0 }
    NS.Skin.OnLooksChanged(function() counts.looks = counts.looks + 1 end)
    Skin:OnReloadRequest(OWNER, function() counts.reloads = counts.reloads + 1 end)
    return NS, m, Skin, counts
end

--- Run a slash line (its chat lines land in the mock's `prints`, tests/wow_mock.lua).
local function slash(NS, line) NS.addon:OnSlashCommand(line) end

--- Render the General page as the client does, select `tab`, and answer the ctx.
local function openTab(NS, m, tab)
    local H = NS.addon.Settings.Helpers
    local p = m.__subcategories["General"]
    p:Show(); p:__fire("OnShow")
    local ctx = H.__panelFor("general")
    H.SelectTab("general", tab)
    return ctx
end

--- Every widget the tab drew, depth first.
local function flatten(ctx)
    local out = {}
    local function walk(w)
        out[#out + 1] = w
        for _, c in ipairs(w.children or {}) do walk(c) end
    end
    for _, w in ipairs(ctx.scroll.children) do walk(w) end
    return out
end

--- The Skin tab's check box (a radio choice or a Scope box) whose label ends with `name`.
local function choiceNamed(NS, m, name)
    local ctx = openTab(NS, m, "Appearance")
    for _, w in ipairs(flatten(ctx)) do
        local label = tostring(w.labelText or "")
        if w.type == "CheckBox" and label:sub(-#name) == name then return w, ctx end
    end
    return nil, ctx
end

-- ── the owner ────────────────────────────────────────────────────────────────────────────────────

test("skin seam: the owner is the folder name, and NS.Skin is its facade", function()
    -- red under: registering under the brand or a typo (the library keys every frame and every
    -- listener by owner), or publishing a facade of some other owner.
    local NS, _, Skin = setup()
    assertTrue(Skin:IsOwner(OWNER), "core/SkinSetup.lua did not register the owner")
    assertTrue(rawequal(NS.Skin, Skin:For(OWNER)), "NS.Skin is not Skin:For(\"" .. OWNER .. "\")")
    assertEqual(NS.Skin.owner, OWNER)
    assertEqual(Skin:OwnerLabel(OWNER), BRAND, "the copy confirmation names the addon by its brand")
end)

test("skin seam: the owner is registered at file load, before the profile store exists", function()
    -- skinning-§1: at FILE LOAD, so the EllesmereUI provider offers it before EllesmereUI dispatches.
    -- red under: RegisterOwner moved into OnInitialize or OnEnable.
    local NS, m = T.newAddon()
    assertTrue(NS.addon.db == nil, "nothing has run OnInitialize")
    assertTrue(m.LibStub("LibKa0s-Skin-1.0"):IsOwner(OWNER), "not registered at file load")
end)

test("skin seam: the read answers Ka0s Default before the profile store exists", function()
    -- RegisterOwner calls `get` at FILE LOAD; a getter that raised there would be a Lua error on
    -- every login.
    local NS = T.newAddon()
    local ok, source, skin = pcall(NS.SkinChoice)
    assertTrue(ok, "NS.SkinChoice raised without a store: " .. tostring(source))
    assertEqual(source, "ka0s")
    assertEqual(skin, "ka0s")
    local font, texture = NS.SkinOverride()
    assertEqual(font, false); assertEqual(texture, false)
end)

test("skin seam: Core's window edge is handed the owner", function()
    -- skinning-§1: every library factory that takes an owner is given one. red under:
    -- NS.ApplySkin = lib.ApplySkin (an owner-less call draws Ka0s Default whatever the skin).
    local NS, m = setup()
    local core = m.LibStub("LibKa0s-Core-1.0")
    local real, seen = core.ApplySkin, nil
    core.ApplySkin = function(_, _, owner) seen = owner end
    local ok, err = pcall(NS.ApplySkin, m.CreateFrame("Frame"))
    core.ApplySkin = real
    if not ok then error(err, 0) end
    assertEqual(seen, OWNER)
end)

-- ── the keys and the rows ────────────────────────────────────────────────────────────────────────

test("skin seam: the eight skin keys default to Ka0s Default, the picker unseen", function()
    -- red under: a default other than today's look, or pickerSeen true (owner ruling O3: every
    -- profile, old and new, gets the first-run picker).
    local NS = T.bootAddon()
    local p = NS.addon.db.profile.skin
    for _, kv in ipairs(KEYS) do assertEqual(p[kv[1]], kv[2], "skin." .. kv[1]) end
end)

test("skin seam: every skin key is a skip-render schema row on the Skin tab", function()
    -- red under: a row that renders itself on top of the library's controls, or one outside the
    -- tab's group (the host tab keyed "Appearance" takes that group's place in the strip).
    local NS = T.newAddon()
    local H = NS.addon.Settings.Helpers
    for _, kv in ipairs(KEYS) do
        local path = "skin." .. kv[1]
        local row = H.FindSchema(path)
        assertTrue(row ~= nil, path .. " is not a schema row")
        assertEqual(row.page, "general", path .. ": page")
        assertEqual(row.group, "Appearance", path .. ": group")
        assertTrue(row.skipRender == true, path .. ": the tab draws it, so it must be skipRender")
        assertEqual(row.default, kv[2], path .. ": default")
    end
end)

test("skin seam: the skin row's values are every registered skin, in the library's order", function()
    local NS, m = T.newAddon()
    local values = NS.addon.Settings.Helpers.FindSchema("skin.skin").values
    local skins = m.LibStub("LibKa0s-Skin-1.0"):Skins()
    assertEqual(#values, #skins, "one value per registered skin")
    for i, def in ipairs(skins) do assertEqual(values[i].value, def.key, "value " .. i) end
    assertEqual(values[1].value, "ka0s", "Ka0s Default first")
end)

test("skin seam: /pgfe set refuses a skin that is not registered and applies one that is", function()
    local NS, _, Skin, counts = setup()
    slash(NS, "set skin.skin no-such-skin")
    assertEqual(NS.addon.db.profile.skin.skin, "ka0s", "an unknown skin was stored")
    assertEqual(counts.looks, 0, "a refused set repainted")
    slash(NS, "set skin.skin obsidian")
    assertEqual(NS.addon.db.profile.skin.skin, "obsidian", "a registered skin was refused")
    local _, applied = Skin:GetChoice(OWNER)
    assertEqual(applied, "obsidian", "a bare set must move the applied skin (the row's onChange)")
    assertEqual(counts.looks, 1, "one set, one repaint")
end)

test("skin seam: /pgfe set reaches an exception, and only its own half", function()
    local NS, _, Skin = setup()
    slash(NS, "set skin.ignoreFonts true")
    local panel, fonts = Skin:GetIgnore(OWNER)
    assertEqual(fonts, true, "the set applied")
    assertEqual(panel, true, "the other half untouched (the default ignores the settings panel)")
end)

-- ── the tab ──────────────────────────────────────────────────────────────────────────────────────

test("skin seam: the Skin tab is the library's, last on the General page", function()
    -- skinning-§3: last where the page has no Keybindings tab. red under: no AppearanceTab entry,
    -- or the skin rows declared ahead of another group.
    local NS, m = setup()
    local order, seen = {}, {}
    for _, row in ipairs(NS.addon.Settings.Schema) do
        if row.page == "general" and row.group and not seen[row.group] then
            seen[row.group] = true
            order[#order + 1] = row.group
        end
    end
    assertEqual(order[#order], "Appearance", "the skin rows' group is the last")
    local ctx = openTab(NS, m, "Appearance")
    assertEqual(ctx.activeTab, "Appearance")
    assertTrue(choiceNamed(NS, m, "Obsidian") ~= nil, "the tab drew no Obsidian choice")
end)

test("skin seam: one tab pick is one effective SetChoice, one repaint and no reload", function()
    -- The tab calls SetChoice first, then the write seam, which writes both rows through
    -- NS.SchemaRuntime.Set; each row's onChange applies only its own half and finds it applied.
    -- red under: an onChange that re-applies the whole stored pair, or a seam around the schema.
    local NS, m, Skin, counts = setup()
    local cb = choiceNamed(NS, m, "Obsidian")
    assertTrue(cb ~= nil, "the Skin tab drew no Obsidian choice")
    cb:SetValue(true); cb:__fire("OnValueChanged", true)
    assertEqual(counts.looks, 1, "one pick must repaint exactly once")
    assertEqual(counts.reloads, 0, "a Ka0s-to-Ka0s pick asks for no reload")
    local source, skin = Skin:GetChoice(OWNER)
    assertEqual(source, "ka0s")
    assertEqual(skin, "obsidian", "the pick did not move the applied skin")
    assertEqual(NS.addon.db.profile.skin.skin, "obsidian", "the pick did not reach the profile")
end)

test("skin seam: the tab's Ignore fonts reaches the library and the profile, one repaint", function()
    local NS, m, Skin, counts = setup()
    local cb = choiceNamed(NS, m, "Ignore fonts")
    assertTrue(cb ~= nil, "the Skin tab drew no Ignore fonts box")
    cb:SetValue(true); cb:__fire("OnValueChanged", true)
    local panel, fonts = Skin:GetIgnore(OWNER)
    assertEqual(fonts, true, "the library's exception moved")
    assertEqual(panel, true, "and the other kept")
    assertEqual(NS.addon.db.profile.skin.ignoreFonts, true, "the profile holds it")
    assertEqual(counts.looks, 1, "one toggle repaints once")
end)

test("skin seam: the own condition names the folder, as EllesmereUI's list shows it", function()
    -- DECISIONS D8: the other lines print the brand (opts.label); EllesmereUI's Third-Party list
    -- shows the folder. red under: no spec.strings override on the tab.
    local NS, m = setup()
    local found = false
    for _, w in ipairs(flatten(openTab(NS, m, "Appearance"))) do
        local text = tostring(w.text or w.labelText or "")
        if text:find(OWNER .. " is on in EllesmereUI's Third-Party Addons list", 1, true) then found = true end
    end
    assertTrue(found, "the own condition does not name the folder")
end)

test("skin seam: another addon's copy to every Ka0s addon repaints this one once", function()
    -- The library's copy calls SetChoice for this owner, then WriteChoice, which reaches this addon's
    -- registered setter. Driven through a fake second owner.
    local NS, _, Skin, counts = setup()
    Skin:RegisterOwner("SkinProbeAddon", { label = "Skin Probe",
        get = function() return "ka0s", "ember" end, set = function() end })
    Skin:SetChoice(OWNER, "ka0s", "ember")
    assertTrue(Skin:WriteChoice(OWNER, "ka0s", "ember"), "the copy's write did not reach this addon's setter")
    assertEqual(counts.looks, 1, "a copy must repaint this addon exactly once")
    assertEqual(NS.addon.db.profile.skin.skin, "ember", "the copy did not land in the profile")
    assertEqual(select(2, Skin:GetChoice(OWNER)), "ember")
end)

-- ── the profile: login and the profile events ────────────────────────────────────────────────────

test("skin seam: login applies the stored skin, exceptions and overrides", function()
    -- red under: no NS.ApplySkinChoice() in OnInitialize, or one that applies only the pair.
    local first = T.bootAddon()
    local p = first.addon.db.profile.skin
    p.skin, p.ignorePanel, p.ignoreFonts, p.texture = "glass", false, true, "Blizzard"
    local saved = _G.PremadeGroupsFilterExtensionDB
    local _, m = T.bootAddon{ afterFile = function() _G.PremadeGroupsFilterExtensionDB = saved end }
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    assertEqual(select(2, Skin:GetChoice(OWNER)), "glass", "the stored skin")
    local panel, fonts = Skin:GetIgnore(OWNER)
    assertEqual(panel, false, "the stored panel exception")
    assertEqual(fonts, true, "the stored fonts exception")
    assertEqual(select(2, Skin:GetOverride(OWNER)), "Blizzard", "the stored texture override")
end)

test("skin seam: a profile switch applies the new profile's skin, panel built or not", function()
    -- red under: applying the skin inside Panel.Refresh (the panel may never have been built), or
    -- not at all on a switch.
    local NS, _, Skin, counts = setup()
    local db = NS.addon.db
    db:SetProfile("SkinProbe")
    db.profile.skin.skin = "glass"
    db:SetProfile("Default")
    assertEqual(select(2, Skin:GetChoice(OWNER)), "ka0s", "back on Default, Default's skin")
    counts.looks = 0
    db:SetProfile("SkinProbe")
    assertEqual(select(2, Skin:GetChoice(OWNER)), "glass", "the switch did not move the applied skin")
    assertEqual(counts.looks, 1, "one switch, one repaint")
end)

test("skin seam: Reset all settings puts the skin back on Ka0s Default and applies it", function()
    -- skinning-§3: a reset reaches the choice as a profile value, and re-applies it.
    local NS, _, Skin = setup()
    slash(NS, "set skin.skin ember")
    assertEqual(select(2, Skin:GetChoice(OWNER)), "ember")
    NS.addon.Settings.Helpers.RestoreAllDefaults()
    assertEqual(NS.addon.db.profile.skin.skin, "ka0s", "the stored skin reset")
    assertEqual(select(2, Skin:GetChoice(OWNER)), "ka0s", "the applied skin followed")
end)

-- ── without the library ──────────────────────────────────────────────────────────────────────────

test("skin seam: the degraded facade answers every name the live facade carries", function()
    -- skinning-§1, testing-§8: without LibKa0s NS.Skin is a host table whose primitives are no-ops
    -- and whose Token / Color / Text answer the host copy NS.SKIN_FALLBACK.
    local live = T.newAddon()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(live.Skin, degraded.Skin, "Skin facade vs host stub", {})
    assertEqual(degraded.Skin.owner, OWNER)
    local r, g, b = degraded.SkinColor("text.disabled")
    assertEqual(r, 0.5); assertEqual(g, 0.5); assertEqual(b, 0.5)
    assertEqual(degraded.SkinEscape("text.accent"), "|cffffd100")
    assertEqual(degraded.ApplySkinChoice(), false, "nothing to apply without the library")
end)

-- PG-01 review: the degraded FontFlags takes the library's `where`, as the library does while the
-- owner ignores fonts (nothing to resolve a Font outline through): stock flags ("") for window text,
-- "OUTLINE" for the HUD. HudFontSize answers the stored size, or 12 for none.
test("skin seam: the degraded FontFlags and HudFontSize answer as the library does unskinned", function()
    -- red under: a FontFlags that ignores `where` (window text drew OUTLINE)
    local S = T.newAddon{ skip = NO_LIBKA0S }.Skin
    assertEqual(S.FontFlags("THICKOUTLINE"), "THICKOUTLINE", "a picked flag stands")
    assertEqual(S.FontFlags("", "window"), "", "a picked empty flag stands")
    assertEqual(S.FontFlags(S.FROM_SKIN), "OUTLINE", "From skin on the HUD")
    assertEqual(S.FontFlags(nil), "OUTLINE", "nothing stored on the HUD")
    assertEqual(S.FontFlags(S.FROM_SKIN, "window"), "", "From skin on window text")
    assertEqual(S.FontFlags(nil, "window"), "", "nothing stored on window text")
    assertEqual(S.HudFontSize(24), 24, "the stored size")
    assertEqual(S.HudFontSize(0), 12, "zero is none")
    assertEqual(S.HudFontSize(nil), 12, "none")
end)

test("skin seam: each host-copy skin token is the live library's Ka0s Default value", function()
    -- A copy that drifts from the library goes red here, so a degraded install draws Ka0s Default.
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    local _, m = T.newAddon()
    local live = m.LibStub("LibKa0s-Skin-1.0"):ResolveSkin("ka0s")
    local n = 0
    for name, c in pairs(degraded.SKIN_FALLBACK) do
        n = n + 1
        local want = live[name]
        assertTrue(type(want) == "table", name .. " is not a library color token")
        for i = 1, 4 do
            assertTrue(math.abs((c[i] or 1) - (want[i] or 1)) < 1e-6,
                ("%s[%d]: host %s, library %s"):format(name, i, tostring(c[i]), tostring(want[i])))
        end
    end
    assertTrue(n > 0, "the host copy is empty")
end)
