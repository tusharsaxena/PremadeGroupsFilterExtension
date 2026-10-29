local addonName, NS = ...
-- core/SkinSetup.lua — the LibKa0s-Skin-1.0 seam: which skin this addon wears (skinning-§1, §3).
--
-- ── WHAT IT PUBLISHES ────────────────────────────────────────────────────────────────────────
--
--   NS.Skin                 the owner's facade, `Skin:For("PremadeGroupsFilterExtension")`: the
--                           painting vocabulary (Shell, Button, Checkbox, ...) and Token / Color /
--                           Resolve / OnLooksChanged. Every surface that draws reads its colors here.
--   NS.SkinChoice()         the stored (source, skin) pair, read through NS.SchemaRuntime.Get;
--                           "ka0s", "ka0s" before OnInitialize has built the profile store.
--   NS.WriteSkinChoice(s,k,i,m) the write seam: every half through NS.SchemaRuntime.Set, the one
--                           seam `/pgfe set` and the settings panel already write through
--                           (architecture-§5); `i`, the Scope's `{ panel, fonts }`, writes the two
--                           exceptions, and `m`, the Font and texture section's `{ font, texture }`,
--                           writes the two overrides ("" for false, the skin's own).
--   NS.SkinOverride()       the stored overrides: font, texture, each an LSM key or false for the
--                           skin's own; false, false before the store exists.
--   NS.ApplySkinChoice(s,k) moves the applied skin: `Skin:SetChoice`, which resolves, repaints every
--                           frame recorded for this owner and THEN fires OnLooksChanged. No argument
--                           applies the stored pair (OnInitialize, the profile events) and with it
--                           the stored exceptions and overrides; a nil half keeps that half (each
--                           Skin tab row's onChange).
--   NS.ApplySkinIgnore(p,f) moves the applied exceptions (`Skin:SetIgnore`); no argument applies the
--                           stored pair, a nil half keeps that half.
--   NS.ApplySkinOverride(f,t) moves the applied overrides (`Skin:SetOverride`); no argument applies
--                           the stored pair, a nil half keeps that half, false or "" clears it.
--   NS.SKIN_SOURCE_OPTIONS  the source row's values, and NS.SKIN_OPTIONS the skin row's (every
--   NS.SKIN_OPTIONS         registered skin, in the library's order). settings/Panel.lua reads both.
--   NS.SKIN_FALLBACK        the host copy of the Ka0s Default tokens the degraded facade answers.
--   NS.SkinDrawsDefault()   true while this owner draws Ka0s Default (and always without the
--                           library): modules/Panel.lua shows its never-painted metal instance then.
--   NS.SkinColor(name)      a color token as a call site writes it (three components when opaque).
--   NS.SkinEscape(name)     a color token as a "|cffrrggbb" escape, rounded to the byte, so markup
--                           written as a literal keeps its bytes on Ka0s Default (|cff808080).
--   NS.SkinPaintAce(w)      an AceGUI widget this addon acquired itself, painted for this owner:
--   NS.SkinPaintAceTree(c)  `Skin:PaintAce` / `Skin:PaintAceTree` with the owner bound (the facade
--                           carries neither). Nothing while the owner ignores its settings panel;
--                           release restores stock. A widget acquired through `Helpers.AceGUI` (the
--                           Options instance's owner proxy) is painted on Create already.
--   NS.SkinOnRelease(w, fn) host release work chained onto the widget's own OnRelease
--                           (`Skin:OnRelease`), so it and the skin's restore both run.
--   NS.MaybeShowSkinPicker() the first-run skin picker (LibKa0s OptionsSkinPicker 1): `O.SkinPicker`
--                           while the profile's `skin.pickerSeen` is false and the addon stands up;
--                           held to PLAYER_REGEN_ENABLED in combat. Answers the frame, or nil,
--                           "queued" behind another Ka0s addon's picker.
--   NS.HideSkinPicker()     takes a shown picker down (its pending preview put back) or out of the
--                           queue WITHOUT marking it seen: the stand-down, a profile that has seen
--                           it, and first on every profile event; drops a held combat deferral.
--   NS.SkinPickerSpec()     the spec MaybeShowSkinPicker hands O.SkinPicker.
--   NS.SkinEUIStatus()      `Skin:GetEUIStatus(owner)` ({ ok, painted, refused, conditions }), the
--                           one way this addon learns what EllesmereUI does (anti-pattern #107: it
--                           never reads EllesmereUI's saved variables); nil without the library.
--   NS.SkinEUIPainted()     true once EllesmereUI painted this owner this session: modules/Panel.lua
--                           folds the skinned twin to EllesmereUI's shell bar then.
--
-- No owner tokens (skinning-§1): every color the addon draws under Ka0s Default is a library token's
-- exact value (the M0 inventory's PG-G1..G3 were refuted, 01_INVENTORY.md), so RegisterOwner carries
-- no `tokens` table. A color a later surface needs that no library token holds is added here, as
-- `pg.<name>` with its Ka0s Default `default` and a `follow` role token, in the same change.
--
-- ── WHERE IT LOADS ───────────────────────────────────────────────────────────────────────────
--
-- Right under core/CoreSetup.lua, whose NS.ApplySkin the degraded facade's Shell routes to, and so
-- above settings/Panel.lua, which reads NS.SKIN_OPTIONS at file load; every other NS.* it reads
-- (NS.addon, NS.SchemaRuntime, NS.IsStoodDown, NS.SafeRegisterEvent's target) is read at call time.
-- Since PG-06 retired the addon's own EllesmereUI bridge (modules/EUISkin.lua, core/EUIBridge.lua),
-- this is the only registration of the folder name with EllesmereUI. AT FILE LOAD, never PLAYER_LOGIN (skinning-§1):
-- the EllesmereUI provider has to offer the owner to EllesmereUI before EllesmereUI dispatches its
-- skins, which `## OptionalDeps: EllesmereUI` makes it do after this file. Nothing here reads the
-- profile at load: RegisterOwner calls `get` once, before AceDB exists, and it answers Ka0s
-- Default; the profile's pair is applied by NS.ApplySkinChoice right after the store and its
-- migrations exist (core/PGFE.lua OnInitialize).
--
-- ── WHY A ROW'S onChange PASSES ONE HALF ─────────────────────────────────────────────────────
--
-- The Skin tab and another addon's "Copy to every Ka0s addon" both call Skin:SetChoice FIRST and
-- write the store after, one half at a time. A row reaction that re-applied the whole stored pair
-- would apply the half-written one in between: a second repaint, to a skin the player never picked.
-- Applying only the row's own half against the applied choice makes each write a no-op (SetChoice
-- is idempotent), so a pick is ONE effective SetChoice and one repaint, while a bare
-- `/pgfe set skin.skin obsidian` still repaints.

local Skin = LibStub and LibStub("LibKa0s-Skin-1.0", true)

local BRAND = "Ka0s Premade Groups Filter Extension"
local SOURCE_PATH, SKIN_PATH = "skin.source", "skin.skin"
local PANEL_PATH, FONTS_PATH = "skin.ignorePanel", "skin.ignoreFonts"
local FONT_PATH, TEXTURE_PATH = "skin.font", "skin.texture"
local DEFAULT = "ka0s"

-- The Ka0s Default tokens the DEGRADED facade answers, copied from the library and limited to the
-- ones this addon reads. Both arms publish the table, so tests/test_skinsetup.lua can hold each
-- entry to the live library's Ka0s Default value: a copy that drifts goes red there. A surface
-- converted to a token adds the token here in the same change.
NS.SKIN_FALLBACK = {
    ["title.text"]     = { 1, 0.82, 0, 1 },
    ["text.body"]      = { 0.9, 0.9, 0.9, 1 },
    ["text.accent"]    = { 1, 0.82, 0, 1 },
    ["text.highlight"] = { 1, 1, 1, 1 },
    ["text.disabled"]  = { 0.5, 0.5, 0.5, 1 },
    ["gtip.title"]     = { 1, 0.82, 0, 1 },
    ["gtip.value"]     = { 1, 1, 1, 1 },
}

--- A color token's components AS A CALL SITE WRITES THEM: r, g, b for an opaque color and r, g, b,
--- a otherwise (the library's own text and vertex rule), so a site that passed three components
--- before it read a token still passes three on Ka0s Default. nil for a token the skin leaves alone.
--- Read through NS.Skin at call time, so it answers the live skin, or the host copy degraded.
function NS.SkinColor(name)
    local r, g, b, a = NS.Skin.Color(name)
    if r == nil then return nil end
    if a == nil or a == 1 then return r, g, b end
    return r, g, b, a
end

--- A color token as a "|cffrrggbb" escape, each channel rounded to the nearest byte (.5 is 80), so
--- markup a call site wrote as a literal keeps its bytes on Ka0s Default. nil for a token the skin
--- leaves alone.
function NS.SkinEscape(name)
    local r, g, b = NS.Skin.Color(name)
    if r == nil then return nil end
    local function byte(v) return math.floor(v * 255 + 0.5) end
    return ("|cff%02x%02x%02x"):format(byte(r), byte(g), byte(b))
end

NS.SKIN_SOURCE_OPTIONS = {
    { value = "ka0s", text = NS.L["Ka0s skins"] },
    { value = "eui",  text = NS.L["EllesmereUI"] },
}

-- The skin row's values: every registered skin, Ka0s Default first. Without the library the one
-- skin the degraded facade can draw.
NS.SKIN_OPTIONS = {}
if Skin and type(Skin.Skins) == "function" then
    for _, def in ipairs(Skin:Skins()) do
        NS.SKIN_OPTIONS[#NS.SKIN_OPTIONS + 1] = { value = def.key, text = def.label or def.key }
    end
end
if #NS.SKIN_OPTIONS == 0 then NS.SKIN_OPTIONS[1] = { value = DEFAULT, text = "Ka0s Default" } end

-- The schema instance, nil-safely: settings/Schema.lua publishes it far below this file, and the
-- profile store exists from OnInitialize.
local function schema()
    local S = NS.SchemaRuntime
    if not (NS.db and S and S.Get and S.Set) then return nil end
    return S
end

--- The stored pair, lazily and nil-safely: Ka0s Default until the profile store exists.
function NS.SkinChoice()
    local S = schema()
    if not S then return DEFAULT, DEFAULT end
    return S.Get(SOURCE_PATH) or DEFAULT, S.Get(SKIN_PATH) or DEFAULT
end

--- A stored override as the profile keeps it: the LSM key, or "" for the skin's own (false, nil, "").
local function storedKey(v)
    if type(v) == "string" and v ~= "" then return v end
    return ""
end

--- The write seam: every half through NS.SchemaRuntime.Set (validate, store, the [Set] line,
--- onChange). `media` is `{ font = key|false, texture = key|false }`: the Skin tab's Font and
--- texture pick and another addon's copy both hand it here, after Skin:SetOverride moved the
--- applied pair, so each row's onChange re-applies its own half as a no-op.
function NS.WriteSkinChoice(source, skin, ignore, media)
    local S = schema()
    if not S then return end
    if source ~= nil then S.Set(SOURCE_PATH, source) end
    if skin ~= nil then S.Set(SKIN_PATH, skin) end
    if type(ignore) == "table" then
        S.Set(PANEL_PATH, ignore.panel == true)
        S.Set(FONTS_PATH, ignore.fonts == true)
    end
    if type(media) == "table" then
        S.Set(FONT_PATH, storedKey(media.font))
        S.Set(TEXTURE_PATH, storedKey(media.texture))
    end
end

--- The stored overrides, nil-safely: each an LSM key, or false for the skin's own; false, false
--- until the profile store exists.
function NS.SkinOverride()
    local S = schema()
    if not S then return false, false end
    local font, texture = storedKey(S.Get(FONT_PATH)), storedKey(S.Get(TEXTURE_PATH))
    return font ~= "" and font or false, texture ~= "" and texture or false
end

--- The stored exceptions, nil-safely: false, false until the profile store exists.
local function storedIgnore()
    local S = schema()
    if not S then return false, false end
    return S.Get(PANEL_PATH) == true, S.Get(FONTS_PATH) == true
end

-- ── the first-run skin picker (LibKa0s OptionsSkinPicker 1) ──────────────────────────────────
--
-- WHEN. Once at login (OnEnable, PLAYER_LOGIN, after the latch is taken, so only on an addon that
-- stands up), after OnInitialize applied the stored skin; and again after every profile event
-- (core/PGFE.lua reloadProfile), because a new, copied or reset profile carries its own
-- `skin.pickerSeen` (O3: false on every profile, old and new). Never while the addon stands down
-- (D10), and never in combat: a start in combat is held for the PLAYER_REGEN_ENABLED edge.
--
-- THE COMBAT RETRY IS A ONE-SHOT PRIVATE FRAME, NOT A FEATURE EVENT (D11). Every event the addon
-- reacts to lives in NS.FEATURE_EVENTS (core/PGFE.lua), registered for as long as the addon stands
-- up. This one is not a reaction the addon has while it runs: it exists only while a start is held,
-- is unregistered when it fires, and NS.HideSkinPicker (a stand-down step) drops it, so a stood-down
-- addon is registered for nothing (tests/test_disabled.lua).
--
-- SEEN. The library calls `onClose` once per showing, by any route the player takes (Apply, its
-- close control, the gear, Escape), and once for a picker still queued behind another Ka0s addon's
-- when that addon's "Apply to all Ka0s addons" dismisses it unshown; that is the one write of
-- `skin.pickerSeen`, through NS.SchemaRuntime.Set. A close this addon makes itself
-- (NS.HideSkinPicker: the stand-down, a profile event) is not the player's and writes nothing.
--
-- NO EYE (X6). The attached panel shows only under Premade Groups Filter's dialog, and the addon has
-- no window of its own and no test mode to preview in, so `onPreview` is omitted and the picker
-- draws no eye; the gear opens the General page on its Skin tab (key "Appearance").
--
-- QUEUED. One picker is up at a time across every Ka0s addon: while another addon's is up,
-- O.SkinPicker queues this one and answers nil, "queued", which NS.MaybeShowSkinPicker passes
-- through; it shows when the other closes.

local PICKER_PATH = "skin.pickerSeen"
local pickerTarget       -- the one-shot PLAYER_REGEN_ENABLED frame, while a start is held
local quietClose = false -- true while NS.HideSkinPicker takes the picker down

local function options()
    local S = NS.addon and NS.addon.Settings
    return S and S.Helpers
end

--- The player's close: the picker seen, and nothing else. The library's put-back already wears the
--- stored choice, so the skin is not this callback's to move.
local function pickerClosed()
    if quietClose then return end
    local S = schema()
    if S then S.Set(PICKER_PATH, true) end
end

function NS.SkinPickerSpec()
    return {
        owner = addonName, get = NS.SkinChoice, set = NS.WriteSkinChoice,
        page = "general", tab = "Appearance",
        onClose = pickerClosed,
    }
end

local function dropPickerDeferral()
    if pickerTarget then pickerTarget:UnregisterAllEvents() end
end

--- True while this profile has not closed the picker and the addon stands up.
local function pickerDue()
    local S = schema()
    if not S then return false end
    if NS.IsStoodDown and NS.IsStoodDown() then return false end
    return S.Get(PICKER_PATH) == false
end

function NS.HideSkinPicker()
    dropPickerDeferral()
    local O = options()
    if not (O and type(O.HideSkinPicker) == "function") then return end
    quietClose = true
    local ok, err = pcall(O.HideSkinPicker)
    quietClose = false
    if not ok then error(err, 0) end
end

local function inCombat()
    return type(_G.InCombatLockdown) == "function" and _G.InCombatLockdown() == true
end

--- Show the picker when this profile has not seen it: answers O.SkinPicker's frame, or nil, "queued"
--- while another Ka0s addon's picker is up (it shows when that one closes), or nil.
function NS.MaybeShowSkinPicker()
    local O = options()
    if not (O and type(O.SkinPicker) == "function") then return nil end
    if not pickerDue() then
        NS.HideSkinPicker()
        return nil
    end
    if inCombat() then
        if not pickerTarget then
            if type(_G.CreateFrame) ~= "function" then return nil end
            pickerTarget = _G.CreateFrame("Frame")
            pickerTarget:SetScript("OnEvent", function()
                dropPickerDeferral()
                NS.MaybeShowSkinPicker()
            end)
        end
        NS.SafeRegisterEvent(pickerTarget, "PLAYER_REGEN_ENABLED", nil, NS.rejectedEvents)
        return nil
    end
    return O.SkinPicker(NS.SkinPickerSpec())
end

-- The picker goes down unmarked with the addon, so it comes back on the next login the addon stands
-- up for. This file loads above core/PGFE.lua, which keeps the list it finds.
NS.STAND_DOWN = NS.STAND_DOWN or {}
NS.STAND_DOWN[#NS.STAND_DOWN + 1] = function() NS.HideSkinPicker() end

-- AceGUI keeps ONE callback per event name (options-ui-§19). Without the library's chain there is
-- no skin restore to share the release with, so the host's work takes the callback, as it did
-- before the skin engine.
local function releaseByCallback(widget, fn)
    if type(widget) ~= "table" or type(fn) ~= "function" or type(widget.SetCallback) ~= "function" then
        return nil
    end
    widget:SetCallback("OnRelease", function(w) fn(w) end)
    return fn
end

-- ── the degraded arm ─────────────────────────────────────────────────────────────────────────

if not Skin then
    local function color(name)
        local c = NS.SKIN_FALLBACK[name]
        if c then return c[1], c[2], c[3], c[4] or 1 end
    end
    local function noop() end
    local S = { owner = addonName, apiVersion = 3, FROM_SKIN = "@skin" }
    -- Every vocabulary name answers, and a primitive with no host meaning is a no-op that never
    -- raises. The list is LibKa0s-Skin-1.0's VOCAB; tests/test_skinsetup.lua holds this table to
    -- the live facade key for key.
    for _, name in ipairs({
        "Shell", "Panel", "Inset", "FadeRegions", "FadeNineSlice", "Button", "WhiteButtonLabel",
        "StateButtonLabel", "EditBox", "Checkbox", "Dropdown", "ScrollBar", "Tab", "SetTabSelection",
        "CloseButton", "PageButton", "SquareIcon", "SortHeaderBar", "Font", "White", "ApplyBarFill",
        "GetAccentColor", "GetPanelColor", "GetFont",
        "TitleBar", "Divider", "Footer", "Card", "Slider", "NavItem", "Drawer", "ListRow", "MenuFrame",
        "Tooltip", "Strip", "Cover", "Text", "ChartStyle", "BarStyle", "IconBorder", "GlowColor",
        "BarTexture",
    }) do S[name] = noop end

    S.Token = function(name) return NS.SKIN_FALLBACK[name] end
    S.Color = color
    S.Resolve = function(kind, value, fromSkin)
        if fromSkin or value == S.FROM_SKIN then return S.Token(kind) end
        return value
    end
    S.OnLooksChanged = function(fn) return fn end   -- the skin never changes without the library
    S.IsEnabled = function() return false end
    S.GetStyle = function() return "ka0s:" .. DEFAULT end
    -- The window edge is CoreSetup's: without the library that is nothing (core/CoreSetup.lua).
    S.Shell = function(frame) if NS.ApplySkin then NS.ApplySkin(frame) end end
    S.Text = function(fs, role)
        local r, g, b, a = color(role == "title" and "title.text" or ("text." .. tostring(role)))
        if r and fs and fs.SetTextColor then fs:SetTextColor(r, g, b, a) end
    end
    S.GetFont = function() return _G.STANDARD_TEXT_FONT end
    S.ChartStyle = function() return {} end
    S.BarStyle = function() return {} end

    NS.Skin = S
    function NS.SkinDrawsDefault() return true end
    function NS.ApplySkinChoice() return false, false end
    function NS.ApplySkinIgnore() return false, false end
    function NS.ApplySkinOverride() return false end
    -- Nothing to paint an AceGUI row with: stock AceGUI, as the client draws it.
    function NS.SkinPaintAce() return false end
    function NS.SkinPaintAceTree() return 0 end
    NS.SkinOnRelease = releaseByCallback
    function NS.SkinEUIStatus() return nil end
    function NS.SkinEUIPainted() return false end
    return
end

-- ── the live seam ────────────────────────────────────────────────────────────────────────────

NS.Skin = Skin:For(addonName)
Skin:RegisterOwner(addonName, {
    label = BRAND,
    get = NS.SkinChoice,
    set = NS.WriteSkinChoice,
})

--- True while the owner draws Ka0s Default: the key the library paints it by is Ka0s Default's. That
--- is `Skin:__DrawsKey`, the question `opts.stockDefault` asks, so an `eui` source before EllesmereUI
--- paints (the live Ka0s Default fallback) answers true, and an EllesmereUI that paints false. The
--- library documents it as internal and publishes no public form (reported upstream), so a copy
--- without it is read from the applied choice: Ka0s Default on the Ka0s source.
function NS.SkinDrawsDefault()
    if type(Skin.__DrawsKey) == "function" then return Skin:__DrawsKey(addonName) == Skin.DEFAULT end
    local source, skin = Skin:GetChoice(addonName)
    return source ~= "eui" and skin == DEFAULT
end

-- The one line a reload request earns on the path that has no popup of its own (a profile event
-- leaving an EllesmereUI that painted this session). The Skin tab raises the library's popup for
-- its own picks.
local RELOAD_LINE = NS.L["Reload your interface (/reload) to finish changing the skin."]

-- The AceGUI rows (SkinAce.lua). Helpers.AceGUI is the Options instance's owner proxy, which paints
-- on Create already; PaintAce for the same owner repaints in place, so a host call after it is
-- harmless, and it is what paints a widget acquired any other way (AceConfigDialog's, on the
-- Profiles page). Each guards on the member, so a copy whose SkinAce secondary did not attach
-- paints nothing.
function NS.SkinPaintAce(widget)
    if type(Skin.PaintAce) ~= "function" then return false end
    return Skin:PaintAce(addonName, widget)
end

function NS.SkinPaintAceTree(container)
    if type(Skin.PaintAceTree) ~= "function" then return 0 end
    return Skin:PaintAceTree(addonName, container)
end

function NS.SkinOnRelease(widget, fn)
    if type(Skin.OnRelease) ~= "function" then return releaseByCallback(widget, fn) end
    return Skin:OnRelease(widget, fn)
end

-- EllesmereUI, through the library's provider only (SkinEUI.lua is the one file that may read
-- EllesmereUI's saved variables, library-stack-§6). A copy without the provider answers nil / false.
function NS.SkinEUIStatus()
    if type(Skin.GetEUIStatus) ~= "function" then return nil end
    return Skin:GetEUIStatus(addonName)
end

function NS.SkinEUIPainted()
    local status = NS.SkinEUIStatus()
    return type(status) == "table" and status.painted == true
end

function NS.ApplySkinIgnore(panel, fonts)
    if type(Skin.SetIgnore) ~= "function" then return false, false end
    if panel == nil and fonts == nil then panel, fonts = storedIgnore() end
    local changed, reload = Skin:SetIgnore(addonName, panel, fonts)
    if reload and NS.Print then NS.Print(RELOAD_LINE) end
    return changed, reload
end

--- No argument applies the stored overrides; a nil half keeps that half, false or "" clears it
--- (the skin's own). A copy without SetOverride (a Skin major before minor 6) moves nothing.
function NS.ApplySkinOverride(font, texture)
    if type(Skin.SetOverride) ~= "function" then return false end
    if font == nil and texture == nil then font, texture = NS.SkinOverride() end
    return Skin:SetOverride(addonName, font, texture)
end

--- No argument applies the stored pair AND the stored exceptions and overrides (OnInitialize, the
--- profile events); a nil half keeps that half and leaves the rest alone (each Skin tab row).
function NS.ApplySkinChoice(source, skin)
    local whole = source == nil and skin == nil
    if whole then source, skin = NS.SkinChoice() end
    local changed, reload = Skin:SetChoice(addonName, source, skin)
    if reload and NS.Print then NS.Print(RELOAD_LINE) end
    if whole then
        NS.ApplySkinIgnore()
        NS.ApplySkinOverride()
    end
    return changed, reload
end
