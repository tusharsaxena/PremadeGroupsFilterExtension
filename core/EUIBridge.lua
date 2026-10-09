local _, NS = ...
-- core/EUIBridge.lua — the only file that reads EllesmereUI state (the optional skin's gate).
--
-- Every seam below was read against EllesmereUI v9.4: its parent addon's RegisterSkin stub
-- (EllesmereUI_SharedHelpers.lua) and its window-skin child's dispatcher
-- (EllesmereUIBlizzardSkin_SkinAPI.lua). Each read happens at CALL time, nil-guarded, so an absent
-- or renamed seam reads as "off" instead of raising. NOTHING here writes EllesmereUI's state.
--
-- The four conditions the owner gated the skin on (docs/superpowers/plans/2026-10-09-eui-skin.md,
-- owner decision 1), in display order:
--   eui     the EllesmereUI global with RegisterSkin, and its window-skin child loaded (the child
--           holds the dispatcher; without it RegisterSkin only queues);
--   master  EllesmereUI's master third-party switch (EllesmereUIDB.thirdPartySkinsOff not truthy);
--   own     this addon's entry in its Third-Party Addons list
--           (EllesmereUIDB.thirdPartySkinAddons["PremadeGroupsFilterExtension"] not false);
--   pgf     Premade Groups Filter's own EllesmereUI skin: PremadeGroupsFilter_EllesmereUI loaded
--           and its entry (thirdPartySkinAddons["PremadeGroupsFilter"]) not false.
-- The two switch reads mirror the dispatcher's own MasterOn/AddonOn (SkinAPI.lua:32-41): nil = on.

local Bridge = NS.EUIBridge or {}
NS.EUIBridge = Bridge

local L = NS.L

--- The name this addon registers its skin under: the folder name (SKINNING_API.md FAQ). It is
--- also the key of our entry in EllesmereUI's Third-Party Addons list.
Bridge.SKIN_NAME = "PremadeGroupsFilterExtension"

local SKIN_CHILD     = "EllesmereUIBlizzardSkin"
local PGF_SKIN_ADDON = "PremadeGroupsFilter_EllesmereUI"
local PGF_SKIN_NAME  = "PremadeGroupsFilter"       -- PremadeGroupsFilter_EllesmereUI/Skin.lua SKIN_NAME

-- C_AddOns.IsAddOnLoaded answers (loadedOrLoading, loaded). Guarded: no reader, or a reader that
-- raises, reads as not loaded.
local function loaded(name)
    local api = C_AddOns and C_AddOns.IsAddOnLoaded
    if type(api) ~= "function" then return false end
    local ok, isLoaded = pcall(api, name)
    return ok and isLoaded == true
end

local function db()
    local d = EllesmereUIDB
    return type(d) == "table" and d or nil
end

--- EllesmereUI is loaded with its public RegisterSkin, and its window-skin child is loaded.
function Bridge.IsSuiteReady()
    local eui = EllesmereUI
    return type(eui) == "table" and type(eui.RegisterSkin) == "function" and loaded(SKIN_CHILD)
end

--- EllesmereUI's master third-party switch (nil = on). Any truthy value is off, exactly as the
--- dispatcher's MasterOn reads it: a 1 from an import must not show as on here and off there.
function Bridge.IsMasterOn()
    local d = db()
    return not (d and d.thirdPartySkinsOff)
end

--- One entry of EllesmereUI's Third-Party Addons list (nil = on; only an explicit false is off).
function Bridge.IsEntryOn(name)
    local d = db()
    local t = d and d.thirdPartySkinAddons
    return not (type(t) == "table" and t[name] == false)
end

--- Premade Groups Filter's own EllesmereUI skin: its addon loaded and its entry on.
function Bridge.IsPGFSkinOn()
    return loaded(PGF_SKIN_ADDON) and Bridge.IsEntryOn(PGF_SKIN_NAME)
end

--- The four conditions in display order: { key, ok, label, hint }. A switch read means nothing
--- without the suite, so every condition after the first also needs the suite ready.
--- @return table
function Bridge.Conditions()
    local suite = Bridge.IsSuiteReady() and true or false
    return {
        { key = "eui", ok = suite,
          label = L["EllesmereUI and its Blizzard Skin module are loaded"],
          hint  = L["Install and enable EllesmereUI, including EllesmereUI Blizzard Skin."] },
        { key = "master", ok = suite and Bridge.IsMasterOn(),
          label = L["EllesmereUI third-party skinning is on"],
          hint  = L["In EllesmereUI, turn on Blizz UI Enhanced > Blizzard Window Skins > Third-Party Addons > Skin Third-Party Addons."] },
        { key = "own", ok = suite and Bridge.IsEntryOn(Bridge.SKIN_NAME),
          label = L["PremadeGroupsFilterExtension is on in EllesmereUI's Third-Party Addons list"],
          hint  = L["In EllesmereUI's Third-Party Addons list, turn on PremadeGroupsFilterExtension."] },
        { key = "pgf", ok = suite and Bridge.IsPGFSkinOn(),
          label = L["Premade Groups Filter's own EllesmereUI skin is on"],
          hint  = L["Install and enable Premade Groups Filter - EllesmereUI Skin, and turn on PremadeGroupsFilter in EllesmereUI's Third-Party Addons list."] },
    }
end

--- Every condition holds?
--- @return boolean open
--- @return string|nil failing  the first failing condition's key
function Bridge.GateOpen()
    for _, c in ipairs(Bridge.Conditions()) do
        if not c.ok then return false, c.key end
    end
    return true
end

--- What to do about it: the failing conditions' hints, one per line, or nil when the gate is open.
--- @return string|nil
function Bridge.WhyClosed()
    local out = {}
    for _, c in ipairs(Bridge.Conditions()) do
        if not c.ok then out[#out + 1] = c.hint end
    end
    return #out > 0 and table.concat(out, "\n") or nil
end
