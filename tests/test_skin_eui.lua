-- tests/test_skin_eui.lua — EllesmereUI through LibKa0s's `eui` source (PG-06 of the skinning
-- rollout, owner ruling O4).
--
-- The addon's own bridge (core/EUIBridge.lua, modules/EUISkin.lua) is gone. What this suite pins is
-- the host half of the swap: the one-time migration carries the stored `euiSkin` choice to
-- `skin.source` on every profile (DECISIONS D3); the library is the one thing that registers the
-- folder with EllesmereUI; once EllesmereUI paints this owner the panel's skinned twin shows and is
-- handed to EllesmereUI's facade while the metal instance never is; the twin folds to EllesmereUI's
-- 25px shell bar (D4); the diagnostics read EllesmereUI through the library only; and no addon file
-- reads EllesmereUIDB (anti-pattern #107).
--
-- Every case builds its own instance.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse

local OWNER = "PremadeGroupsFilterExtension"
local SV = "PremadeGroupsFilterExtensionDB"

--- An instance booted over a SavedVariables file at schema 1 (before this step) holding `profiles`,
--- with EllesmereUI installed per `eui` (false: no EllesmereUI at all).
local function migrated(profiles, eui)
    local opts = {}
    if eui ~= false then opts.mock = function(mm) mm.installEUI(eui) end end
    local NS, _, m = T.newAddon(opts)
    _G[SV] = { global = { schemaVersion = 1 }, profileKeys = {}, profiles = profiles }
    NS.addon:OnInitialize()
    return NS, m, NS.addon.db.sv.profiles
end

local function source(p) return type(p.skin) == "table" and rawget(p.skin, "source") or nil end

-- ── the migration (D3) ───────────────────────────────────────────────────────────────────────────

test("eui migration: with EllesmereUI, every profile but an explicit false moves to skin.source eui", function()
    -- euiSkin defaulted to true and AceDB strips defaults, so a profile without the key chose it.
    -- red under: a step that reads only `euiSkin == true`, or one that walks the active profile only.
    local NS, _, profiles = migrated({
        Default = { panelCollapsed = true }, On = { euiSkin = true }, Off = { euiSkin = false },
    })
    assertEqual(NS.addon.db.global.schemaVersion, 2)
    assertEqual(source(profiles.Default), "eui", "no key: the old default, on")
    assertEqual(source(profiles.On), "eui")
    assertEqual(source(profiles.Off), nil, "an explicit false keeps the Ka0s source")
    for name, p in pairs(profiles) do assertEqual(p.euiSkin, nil, name .. " still carries euiSkin") end
    assertEqual(NS.SchemaRuntime.Get("skin.source"), "eui", "the active profile reads it through the schema")
end)

test("eui migration: without EllesmereUI every profile keeps the Ka0s source", function()
    local _, _, profiles = migrated({ Default = {}, On = { euiSkin = true } }, false)
    assertEqual(source(profiles.On), nil, "no EllesmereUI: nothing to select")
    assertEqual(profiles.On.euiSkin, nil, "the old key goes either way")
end)

test("eui migration: EllesmereUI without its Blizzard Skin child is not present", function()
    -- The library's `eui` condition: RegisterSkin only queues without the child (SkinEUI.lua).
    local _, _, profiles = migrated({ On = { euiSkin = true } }, { child = false })
    assertEqual(source(profiles.On), nil)
end)

test("eui migration: the store is applied as migrated, and the step runs once", function()
    local NS, m = migrated({ Default = {} })
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    assertEqual((Skin:GetChoice(OWNER)), "eui", "OnInitialize applied the migrated source")
    NS.addon.db.profile.skin.source = "ka0s"
    NS.addon:RunMigrations()
    assertEqual(NS.addon.db.profile.skin.source, "ka0s", "a later run never moves a player's pick back")
end)

-- ── the library is the bridge ────────────────────────────────────────────────────────────────────

test("eui: the folder is registered with EllesmereUI once, by the library", function()
    local _, _, m = T.enableAddon({ mock = function(mm) mm.installEUI() end })
    assertTrue(type(m.eui.registry[OWNER]) == "function", "the owner is in EllesmereUI's list")
    local n = 0
    for _, name in ipairs(m.eui.order) do if name == OWNER then n = n + 1 end end
    assertEqual(n, 1)
end)

test("eui: no addon file reads EllesmereUIDB or registers with EllesmereUI itself", function()
    -- skinning-§5, anti-pattern #107: SkinEUI.lua is the one reader. red under: a host gate copy.
    local files = { "core/SkinSetup.lua", "core/Database.lua", "core/PGFE.lua", "modules/Panel.lua",
        "modules/Diagnostics.lua", "settings/Panel.lua" }
    for _, rel in ipairs(files) do
        local fh = assert(io.open(T.root .. "/" .. rel, "rb"))
        local src = fh:read("*a"); fh:close()
        assertTrue(src:find("EllesmereUIDB", 1, true) == nil, rel .. " reads EllesmereUIDB")
        assertTrue(src:find("RegisterSkin(", 1, true) == nil, rel .. " registers with EllesmereUI itself")
    end
    for _, gone in ipairs({ "core/EUIBridge.lua", "modules/EUISkin.lua" }) do
        local fh = io.open(T.root .. "/" .. gone, "rb")
        if fh then fh:close() end
        assertTrue(fh == nil, gone .. " is retired")
    end
end)

--- An enabled instance on the eui source with EllesmereUI's facade delivered, the panel shown.
local function painted(spec)
    local NS, _, m = T.enableAddon({ mock = function(mm) mm.installEUI(spec) end })
    NS.SchemaRuntime.Set("skin.source", "eui")
    m.eui.dispatch(OWNER)
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    return NS, m
end

test("eui: once EllesmereUI paints the owner, the skinned twin shows and goes to its facade", function()
    local NS, m = painted()
    assertTrue(NS.SkinEUIPainted(), "EllesmereUI painted the owner")
    assertFalse(NS.SkinDrawsDefault())
    local P = NS.Panel
    assertTrue(P.skinFrame ~= nil and P.frame == P.skinFrame, "the twin is the instance on show")
    assertTrue(P.frame:IsShown())
    assertEqual(#m.eui.callsFor("Shell", P.skinFrame), 1, "the twin's window went to EllesmereUI's Shell")
    assertEqual(#m.eui.callsFor("Checkbox", P.skinFrame.activeCheck), 1, "and its check buttons")
    for _, c in ipairs(m.eui.calls) do
        assertTrue(P.stockFrame == nil or c.target ~= P.stockFrame, "the metal instance went to EllesmereUI")
    end
end)

test("eui: before EllesmereUI paints, the eui source wears the metal instance (Ka0s Default)", function()
    -- The library's live fallback while the gate is closed: the master switch off here.
    local NS = painted({ masterOff = true })
    assertFalse(NS.SkinEUIPainted())
    assertTrue(NS.SkinDrawsDefault())
    assertTrue(NS.Panel.frame == NS.Panel.stockFrame, "the never-painted metal instance shows")
end)

test("eui: which instance shows is read from public API only, never the library's __DrawsKey", function()
    local fh = assert(io.open(T.root .. "/core/SkinSetup.lua", "rb"))
    local src = fh:read("*a")
    fh:close()
    assertTrue(src:find("Skin:__DrawsKey", 1, true) == nil and src:find("Skin.__DrawsKey", 1, true) == nil,
        "core/SkinSetup.lua calls the library-internal __DrawsKey")
end)

test("eui: the public answer matches the key the library draws by, in every state", function()
    -- The library's own answer (internal) is the oracle here, and only here.
    local NS, m = painted({ masterOff = true })
    local Skin = m.LibStub("LibKa0s-Skin-1.0")
    local function agrees(label)
        assertEqual(NS.SkinDrawsDefault(), Skin:__DrawsKey(OWNER) == Skin.DEFAULT, label)
    end
    agrees("eui source, EllesmereUI not painted")
    assertTrue(NS.SkinDrawsDefault(), "an unpainted eui source wears Ka0s Default")
    Skin:SetChoice(OWNER, "ka0s", "obsidian")
    agrees("a registered skin")
    assertFalse(NS.SkinDrawsDefault(), "a registered skin is not Ka0s Default")
    Skin:SetChoice(OWNER, "ka0s", "no-such-skin")
    agrees("a key the library does not know")
    assertTrue(NS.SkinDrawsDefault(), "an unknown key draws as Ka0s Default")
    Skin:SetChoice(OWNER, "eui", "obsidian")
    agrees("eui source over a registered skin, EllesmereUI not painted")
    local NS2, m2 = painted()
    assertTrue(NS2.SkinEUIPainted())
    assertEqual(NS2.SkinDrawsDefault(), m2.LibStub("LibKa0s-Skin-1.0"):__DrawsKey(OWNER) == "ka0s",
        "eui source, EllesmereUI painted")
end)

test("eui: the twin folds to EllesmereUI's 25px shell bar", function()
    -- DECISIONS D4: EllesmereUI's Shell draws a 25px top bar whatever title.height says.
    local NS = painted()
    NS.addon.db.profile.panelCollapsed = true
    NS.Panel.Refresh()
    assertEqual(NS.Panel.frame:GetHeight(), 25)
end)

-- ── diagnostics ──────────────────────────────────────────────────────────────────────────────────

local function skinSection(NS)
    local lines = {}
    local out = {}
    function out.add(_, _, fmt, ...)
        local args = { ... }
        for i = 1, select("#", ...) do args[i] = tostring(args[i]) end
        lines[#lines + 1] = (fmt:gsub("%%s", function() return table.remove(args, 1) end))
    end
    function out.joined(self, tag, lead, parts)
        local strs = {}
        for i = 1, #(parts or {}) do strs[i] = tostring(parts[i]) end
        return self:add(tag, "%s %s", lead, #strs > 0 and table.concat(strs, ", ") or "-")
    end
    for _, sec in ipairs(NS.Diagnostics.Sections()) do
        if sec[1] == "skin" then sec[2](out) end
    end
    return table.concat(lines, "\n")
end

test("eui diagnostics: the skin section reports the choice and the library's EllesmereUI gate", function()
    local NS = painted()
    local text = skinSection(NS)
    -- red under: no skin section, or the retired bridge's lines
    assertTrue(text:find("skin applied=eui:ka0s stored=eui:ka0s", 1, true) ~= nil, text)
    assertTrue(text:find("EllesmereUI conditions eui=true, master=true, own=true, facade=true", 1, true) ~= nil, text)
    assertTrue(text:find("EllesmereUI ok=true painted=true refused=none", 1, true) ~= nil, text)
end)
