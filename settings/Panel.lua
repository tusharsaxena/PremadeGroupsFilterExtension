local addonName, NS = ...
-- settings/Panel.lua — the landing page body and the General page (Master controls, Filters,
-- Region tags, EllesmereUI skin, Skin).
--
-- The landing page is the host's own buildMain (logo, notes, slash command list) and draws no tab
-- strip (options-ui-§5/§13). The General page renders through the tabbed renderer, in five
-- tabs: `Master controls`, composed from one declaration and holding only its mandated rows
-- (options-ui-§15); `Filters`, the extension's filters switch and a line saying where the filter
-- options are (the attached panel); `Region tags`, the region-tag switch leading the tags'
-- colors; `EllesmereUI skin` (the optional skin's switch and status, below); and `Skin`, the
-- library's Skin tab over the skin.* rows (core/SkinSetup.lua), last. The addon draws no
-- positionable frame of its own -- the filter panel is anchored to PGF's dialog -- so the block is
-- frameless (no scale, alpha, lock or reset position) and carries no visibility row: when the panel
-- shows is decided by PGF's dialog and category, not by a setting (ratified: docs/ARCHITECTURE.md
-- -> Documented deviations). It has no test mode.

local PGFE     = NS.addon
local Settings = PGFE.Settings
local Helpers  = Settings.Helpers
local C        = NS.C

-- The landing page's logo: a larger render of the launcher logo, in the same folder.
local MAIN_LOGO_TEXTURE = ("Interface\\AddOns\\%s\\media\\logos\\premadegroupsfilterextension.logo.tga"):format(addonName)

-- The landing page body, through the library's builder (options-ui-§5): logo (at the library's
-- 300x300 default, so no logoSize), the TOC notes line,
-- then the Slash Commands heading and one row per NS.COMMANDS entry. It replaced a private copy
-- that drew the logo as a texture straight on a pooled AceGUI SimpleGroup frame and never took it
-- off: after a re-render the frame came back as another SimpleGroup (the spacer under the heading)
-- still carrying the logo, so the page showed it twice. The builder keeps one texture per frame
-- and hides it in the group's OnRelease.
function Helpers.BuildMainContent(ctx)
    Helpers.BuildLandingPage(ctx, {
        logo     = MAIN_LOGO_TEXTURE,
        notes    = function() return NS.Meta("Notes") or "" end,
        sections = { {
            heading = NS.L["Slash Commands"],
            rows    = function()
                local Sl = NS.SlashCommands
                return Sl and Sl:LandingRows() or {}
            end,
        } },
    })
end

local function showResetPopup()
    Settings.EnsureResetPopup()
    NS.ShowPopup("PREMADEGROUPSFILTEREXTENSION_RESET_ALL")
end

local MASTER_ROWS, MASTER_TAIL = Helpers.MasterControls{
    prefix           = "",
    page             = "general",
    addonName        = "Ka0s Premade Groups Filter Extension",
    frameless        = true,
    omit             = { visibility = true },
    debugConsolePath = "state.debugConsole",
    minimapPath      = "global.minimap.shown",
    defaults         = { enabled = C.PROFILE.enabled, debugConsole = false },
    onResetAll       = showResetPopup,
}

-- The Enable row drives the latch: the same Set the CLI, the launcher and a profile switch make.
local MASTER_HOOKS = {
    enabled = function(v)
        if NS.Lifecycle then NS.Lifecycle:Set(NS.HOLD_DISABLED, not v) end
    end,
}

for _, row in ipairs(MASTER_ROWS) do
    row.section  = "general"
    row.onChange = MASTER_HOOKS[row.path]
end
Settings.StampClosureRows(MASTER_ROWS)
NS.SchemaRuntime.AddRows(MASTER_ROWS, 1)

-- ── Filters (the General page's second tab) ─────────────────────────────────────────────────────
--
-- The extension's filters switch, in its own group so its own tab (options-ui-§13): a feature
-- switch, not a Master controls row (options-ui-§15). Added after MASTER_ROWS and before
-- EUI_ROWS, so the tab sits between the two. The filter options themselves are on the attached
-- panel, not in the schema (settings/Schema.lua), so the tab ends with a line saying where.
local L = NS.L
local FILTER_GROUP = L["Filters"]
local REGION_GROUP = L["Region tags"]
local FILTER_ROWS = {
    -- The attached panel's first box. Separate from Enable: this one leaves the panel up and only
    -- takes the filters out of PGF.
    { path = "filtersActive", type = "bool", default = C.PROFILE.filtersActive,
      page = "general", section = "general", group = FILTER_GROUP,
      label = NS.L.FILTERS_ACTIVE, tooltip = NS.L.FILTERS_ACTIVE_TOOLTIP,
      onChange = function(v) NS.Apply.OnFiltersToggled(v and true or false) end },
}
Settings.StampClosureRows(FILTER_ROWS)
NS.SchemaRuntime.AddRows(FILTER_ROWS)

-- ── Region tags (the General page's third tab) ──────────────────────────────────────────────────
--
-- The region tag on Group Finder rows and applicants (modules/RegionTags.lua), switched on or off
-- by the tab's leading row, drawn unheaded above the portals (options-ui-§7). Read on every row
-- paint, so it needs no onChange: the next search or list refresh shows the change. Its OWN row
-- list, added before REGION_ROWS and never inside it: Settings.ResetRegionColors walks
-- REGION_ROWS, and Reset region tag colors resets the twelve colors, not this switch. Added
-- right after FILTER_ROWS, so its place in `/pgfe list` stays where it was.
local TAG_SWITCH_PATH = "showRegionTags"
local TAG_SWITCH_ROWS = {
    { path = TAG_SWITCH_PATH, type = "bool", default = C.PROFILE.showRegionTags,
      page = "general", section = "general", group = REGION_GROUP,
      label = L.SHOW_REGION_TAGS, tooltip = L.SHOW_REGION_TAGS_TOOLTIP },
}
Settings.StampClosureRows(TAG_SWITCH_ROWS)
NS.SchemaRuntime.AddRows(TAG_SWITCH_ROWS)

-- One color row per region bucket, `regionColors.<key>` (profile), so the tag colors go through
-- the schema like every other setting: the panel's picker, `/pgfe get|set|reset regionColors.oce`
-- and both resets. No alpha: a |c escape has none. Read on every row paint (modules/RegionTags.lua
-- caches the hex per stored table), so no onChange: the next search or list refresh shows it.
-- The tab is a host tab: per portal a heading, a line of every tag in its current color, then the
-- portal's pickers three to a line; a button under both puts the twelve defaults back. A
-- picker's label spells its code out (the REGION_PICKER_ locale keys); NS.Regions.LABELS stays
-- the tag text the Group Finder and the attached panel draw.
local PORTAL_HEADINGS = {
    US = L["Americas and Oceania (US realms)"],
    EU = L["Europe (EU realms)"],
}
local PICKERS_PER_LINE = 3

local REGION_ROWS = {}
for _, key in ipairs(NS.Regions.ALL_KEYS) do
    REGION_ROWS[#REGION_ROWS + 1] = {
        path = "regionColors." .. key, type = "color", hasAlpha = false,
        default = C.PROFILE.regionColors[key],
        page = "general", section = "general", group = REGION_GROUP,
        label = L["REGION_PICKER_" .. key:upper()],
        tooltip = L["REGION_TIP_" .. key:upper()] .. "\n\n" .. L.REGION_COLOR_TOOLTIP,
        regionKey = key,
    }
end
NS.SchemaRuntime.AddRows(REGION_ROWS)

--- Every tag of one portal in its current color, spaced: the tab's preview line.
function Settings.RegionPreviewText(portal)
    local RT, parts = NS.RegionTags, {}
    for _, key in ipairs(NS.Regions.KEYS[portal]) do parts[#parts + 1] = RT.Colored(key) end
    return table.concat(parts, "   ")
end

--- Put every region color back to its default, as one bulk act (one debug line, one refresh).
function Settings.ResetRegionColors()
    local S = NS.SchemaRuntime
    S.BulkRun("reset", "region colors", function()
        for _, row in ipairs(REGION_ROWS) do S.ApplyDefault(row) end
    end)
end

local function renderRegionTab(ctx, rows)
    local AceGUI, scroll = Helpers.AceGUI, Helpers.EnsureScroll(ctx)
    if not (AceGUI and scroll) then return end
    -- The switch is picked out by path, never indexed by regionKey (it has none), and drawn first.
    local byKey = {}
    for _, row in ipairs(rows or {}) do
        if row.path == TAG_SWITCH_PATH then
            Helpers.RenderField(ctx, row)
            ctx.lastGroup = TAG_SWITCH_PATH   -- so the first portal heading takes its top gap
        elseif row.regionKey then byKey[row.regionKey] = row end
    end
    for _, portal in ipairs({ "US", "EU" }) do
        Helpers.Section(ctx, PORTAL_HEADINGS[portal])
        local preview = Helpers.TextRow(ctx, Settings.RegionPreviewText(portal), { fontObject = "GameFontHighlightLarge" })
        if preview then
            ctx.refreshers[#ctx.refreshers + 1] = function() preview:SetText(Settings.RegionPreviewText(portal)) end
        end
        Helpers.AddSpacer(scroll, 6)
        local line = AceGUI:Create("SimpleGroup")
        line:SetLayout("Flow")
        line:SetFullWidth(true)
        for _, key in ipairs(NS.Regions.KEYS[portal]) do
            if byKey[key] then Helpers.RenderField(ctx, byKey[key], line, 1 / PICKERS_PER_LINE - 0.01) end
        end
        scroll:AddChild(line)
        ctx.lastGroup = portal
    end
    Helpers.AddSpacer(scroll, 12)
    Helpers.InlineButtonPair(ctx, {
        text    = L["Reset region tag colors"],
        tooltip = L["Put every region tag back to its default color. Your other settings are not touched."],
        onClick = Settings.ResetRegionColors,
    })
end

-- ── EllesmereUI skin (the General page's fourth tab) ────────────────────────────────────────────
--
-- Its own group, so its own tab (options-ui-§13): a feature switch with live status lines is not a
-- Master controls row (options-ui-§15). The tab is a host tab keyed by the group: a status line per
-- gate condition (core/EUIBridge.lua), a line saying what the skin is doing, then the one schema
-- row. The switch is drawn disabled while any condition fails and can never turn the skin on by
-- itself: modules/EUISkin.lua paints only when every condition AND the switch hold. The CLI keeps
-- parity with the disabled box: `/pgfe set euiSkin true` is refused, with the reason, while a
-- condition fails (slash-commands-§6); off is always accepted, and a bulk reset never refused.

local EUI_GROUP = L["EllesmereUI skin"]

local function euiGateOpen() return NS.EUIBridge ~= nil and (NS.EUIBridge.GateOpen()) end

local EUI_ROWS = {
    { path = "euiSkin", type = "bool", default = C.PROFILE.euiSkin,
      page = "general", section = "general", group = EUI_GROUP,
      label = L["Use the EllesmereUI skin"],
      tooltip = L["Paint the attached filter panel in your EllesmereUI theme, matching Premade Groups Filter's own EllesmereUI skin. Needs every condition listed below. Turning it off takes effect after a reload."],
      disabledIf = function() return not euiGateOpen() end,
      validate = function(v)
          local S = NS.SchemaRuntime
          if v ~= true or euiGateOpen() or S.InBulk() or S.Get("euiSkin") == true then return true end
          local why = NS.EUIBridge and NS.EUIBridge.WhyClosed() or ""
          return false, L["The EllesmereUI skin cannot be turned on until every condition is met:"] .. "\n" .. why
      end,
      onChange = function(v) if NS.EUISkin then NS.EUISkin.OnSwitch(v == true) end end,
    },
}
NS.SchemaRuntime.AddRows(EUI_ROWS)

local ICON_OK  = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t"
local ICON_BAD = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t"
-- An empty icon slot, the same 14x14 as the two above, so a line that carries no icon still starts
-- its text exactly under theirs (owner request: pixel-perfect, no space padding). It draws one
-- texel of the ready-check texture's fully transparent corner (texcoords 0..1 of 64), stretched
-- to the slot: nothing visible, the icon's exact footprint.
local ICON_BLANK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0:64:64:0:1:0:1|t"
local STATUS_GAP = 8   -- the space above the line saying what the skin is doing
local SWITCH_GAP = 12  -- the space between the switch (first) and the status lines below it

local function conditionText(c)
    if c.ok then return ICON_OK .. " " .. c.label end
    return ICON_BAD .. " " .. c.label .. "\n" .. ICON_BLANK .. " |cff999999" .. c.hint .. "|r"
end

--- What the skin is doing this session, in words: the line under the conditions.
function Settings.EUISkinStateText()
    local K = NS.EUISkin
    if not K then return "" end
    local on = NS.addon.db and NS.addon.db.profile and NS.addon.db.profile.euiSkin == true
    if K.IsApplied() then
        if on then return "|cff33ff33" .. L["The skin is applied."] .. "|r" end
        return L["The skin is applied until you reload the UI."]
    end
    if NS.IsStoodDown() then return L["The skin is not applied while the addon is disabled."] end
    if not euiGateOpen() then return L["The skin is not applied: a condition above is not met."] end
    if not on then return L["The skin is off."] end
    if not K.HasFacade() then return L["The skin is applied after a reload."] end
    return L["The skin is applied when the panel next shows."]
end

-- The checkbox's tooltip, live: the row's own text, then why it is disabled when it is.
local function euiTooltip(cb, row)
    return function()
        if not GameTooltip then return end
        GameTooltip:SetOwner(cb.frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(row.label, 1, 1, 1)
        GameTooltip:AddLine(row.tooltip, nil, nil, nil, true)
        local why = NS.EUIBridge and NS.EUIBridge.WhyClosed()
        if why then
            GameTooltip:AddLine(L["Disabled until every condition is met:"] .. "\n" .. why, 1, 0.25, 0.25, true)
        end
        GameTooltip:Show()
    end
end

-- The PGF skin's CurseForge link in a read-only edit box: anything typed puts the link back, and
-- focus selects it, ready for Ctrl+C. AceGUI pools the inner editbox frame, and HookScript cannot
-- be undone, so the frame is hooked once (`__pgfeLinkHook`) and the hook selects only while this
-- box owns the frame (`__pgfeLinkActive`). The box's OnRelease clears that flag before the frame
-- goes back to the pool, and forgets the box.
local function addPGFSkinLink(scroll)
    local AceGUI = Helpers.AceGUI
    if not AceGUI then return end
    local url = NS.EUIBridge.PGF_SKIN_URL
    local box = AceGUI:Create("EditBox")
    box:SetLabel(L["Get Premade Groups Filter - EllesmereUI Skin (select, then Ctrl+C):"])
    box:SetText(url)
    box:SetFullWidth(true)
    box:DisableButton(true)
    box:SetCallback("OnTextChanged", function(widget) widget:SetText(url) end)
    box:SetCallback("OnEnterPressed", function(widget) widget:SetText(url) end)
    local eb = box.editbox
    if eb and eb.HookScript and not eb.__pgfeLinkHook then
        eb.__pgfeLinkHook = true
        eb:HookScript("OnEditFocusGained", function(self)
            if self.__pgfeLinkActive then self:HighlightText() end
        end)
    end
    if eb then eb.__pgfeLinkActive = true end
    box:SetCallback("OnRelease", function(w)
        if w.editbox then w.editbox.__pgfeLinkActive = nil end
        if Settings.PGFSkinLinkBox == w then Settings.PGFSkinLinkBox = nil end
    end)
    scroll:AddChild(box)
    Settings.PGFSkinLinkBox = box
end

-- A status line: a TextRow re-read by its own refresher (options-ui-§11), so it follows changes
-- made in EllesmereUI's options, which never pass through our write seam.
-- An InteractiveLabel rather than the toolkit's TextRow (a plain Label takes no mouse): it carries
-- OnEnter/OnLeave as AceGUI callbacks, which AceGUI clears when the widget is released, so a pooled
-- frame never keeps a stale tooltip. `tipFn` answers title, body at hover time.
local function statusRow(ctx, textFn, tipFn)
    local AceGUI, scroll = Helpers.AceGUI, Helpers.EnsureScroll(ctx)
    if not (AceGUI and scroll) then return end
    local w = AceGUI:Create("InteractiveLabel")
    w:SetFullWidth(true)
    if w.SetFontObject and _G.GameFontHighlight then w:SetFontObject(_G.GameFontHighlight) end
    w:SetText(textFn())
    if tipFn then
        w:SetCallback("OnEnter", function(widget)
            if not GameTooltip then return end
            local title, body = tipFn()
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPLEFT")
            GameTooltip:SetText(title, 1, 1, 1, 1, true)
            GameTooltip:AddLine(body, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        w:SetCallback("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    scroll:AddChild(w)
    ctx.refreshers[#ctx.refreshers + 1] = function() w:SetText(textFn()) end
    return w
end

-- What / why / how for each condition line (owner request), and for the state line.
local CONDITION_TIPS = {
    eui = L["EllesmereUI paints windows through its Blizzard Skin module (EllesmereUIBlizzardSkin), which holds its skinning engine. Without both there is nothing to paint this panel with.\n\nHow: install EllesmereUI and keep EllesmereUI Blizzard Skin enabled in the AddOns list."],
    master = L["EllesmereUI's master switch for skinning other addons' windows. While it is off, EllesmereUI skins no third-party addon, this one included.\n\nHow: EllesmereUI options > Blizz UI Enhanced > Blizzard Window Skins > Third-Party Addons > Skin Third-Party Addons."],
    own = L["EllesmereUI lists every addon that registers a skin with it, each with its own switch. This is this addon's entry.\n\nHow: in the same Third-Party Addons list, tick PremadeGroupsFilterExtension. EllesmereUI applies a skin it turns on at once; one it turns off goes after a reload."],
    pgf = L["This panel sits under Premade Groups Filter's window, so the skin is only used while that window is skinned too: the two always match. That is Premade Groups Filter - EllesmereUI Skin, a separate addon.\n\nHow: install it from CurseForge (the link appears below when it is missing), enable it in the AddOns list, and tick PremadeGroupsFilter in EllesmereUI's Third-Party Addons list."],
}
local STATE_TIP = L["What the skin is doing this session. EllesmereUI applies a skin once per session: turning the skin on paints the panel at once, turning it off takes effect after a reload. It is never applied while a condition above is not met, whatever the switch says."]

-- The switch first (owner request), a gap, the four condition lines, the PGF skin's link right
-- under condition 4 (which points at it) when that skin is missing, a gap, and the state line.
local function renderEuiTab(ctx, rows)
    local B = NS.EUIBridge
    local scroll = Helpers.EnsureScroll(ctx)
    local row = rows and rows[1]
    if row then
        local cb = Helpers.RenderField(ctx, row)      -- binds the refresher and the disabledIf
        if cb and cb.SetCallback then cb:SetCallback("OnEnter", euiTooltip(cb, row)) end
        if scroll then Helpers.AddSpacer(scroll, SWITCH_GAP) end
    end
    for i = 1, #B.Conditions() do
        statusRow(ctx, function() return conditionText(B.Conditions()[i]) end, function()
            local c = B.Conditions()[i]
            return c.label, CONDITION_TIPS[c.key] or ""
        end)
    end
    -- Not installed: a box holding the CurseForge link to copy (the game cannot open a browser).
    -- Decided at render time: installing an addon needs a game restart, so it cannot change live.
    if scroll and B.PGFSkinState() == "missing" then addPGFSkinLink(scroll) end
    if scroll then Helpers.AddSpacer(scroll, STATUS_GAP) end
    statusRow(ctx, function() return ICON_BLANK .. " " .. Settings.EUISkinStateText() end,
        function() return Settings.EUISkinStateText(), STATE_TIP end)
end

-- ── Skin (the General page's last tab; skinning-§2, §3) ─────────────────────────────────────────
--
-- The skin this addon wears, per profile (core/SkinSetup.lua). The tab is the library's
-- O.AppearanceTab (key "Appearance", labeled "Skin"), which draws every row below as its own
-- controls, so each carries `skipRender`; they stay schema rows so the defaults resolve, both resets
-- reach them, and `/pgfe get|set skin.skin` validates against `values`. Declared last, so the
-- group, and with it the tab, is last: the page has no Keybindings tab (skinning-§3).
--
-- Each onChange applies ONLY its own half (core/SkinSetup.lua says why): the tab and another addon's
-- "Copy to every Ka0s addon" call Skin:SetChoice before they write, so the write is a no-op, and a
-- bare `/pgfe set` still repaints. Nothing skin-related keys off the announce refresh.
local SKIN_GROUP = "Appearance"
local SKIN_DEFAULTS = C.PROFILE.skin
local function skinRow(leaf, row)
    row.path, row.default = "skin." .. leaf, SKIN_DEFAULTS[leaf]
    row.page, row.section, row.group, row.skipRender = "general", "general", SKIN_GROUP, true
    return row
end
local SKIN_ROWS = {
    skinRow("source", { type = "string", widget = "Dropdown", values = NS.SKIN_SOURCE_OPTIONS,
        label = L["Skin source"],
        tooltip = L["Where this addon's look comes from: the Ka0s skin chosen below, or EllesmereUI."],
        onChange = function(v) NS.ApplySkinChoice(v, nil) end }),
    skinRow("skin", { type = "string", widget = "Dropdown", values = NS.SKIN_OPTIONS,
        label = L["Skin"],
        tooltip = L["The Ka0s skin this addon wears. Changes every window and panel right away."],
        onChange = function(v) NS.ApplySkinChoice(nil, v) end }),
    -- The Scope's two exceptions, drawn by the same tab as check boxes.
    skinRow("ignorePanel", { type = "bool", widget = "CheckBox",
        label = L["Ignore settings panel"],
        tooltip = L["Keep this addon's settings panel in the game's own look. Its windows still wear the skin."],
        onChange = function(v) NS.ApplySkinIgnore(v, nil) end }),
    skinRow("ignoreFonts", { type = "bool", widget = "CheckBox",
        label = L["Ignore fonts"],
        tooltip = L["Keep every font in this addon as the game draws it. The skin still colors the text."],
        onChange = function(v) NS.ApplySkinIgnore(nil, v) end }),
    -- The Font and texture section's two overrides, LibSharedMedia keys, "" for the skin's own.
    -- Free text, not a Dropdown with `values`: a media pack may register its keys after this file
    -- loads, and `/pgfe set` takes any key.
    skinRow("font", { type = "string", widget = "EditBox",
        label = L["Font"],
        tooltip = L["The font this addon's text uses, over the skin's own. Empty keeps the skin's."],
        onChange = function(v) NS.ApplySkinOverride(v, nil) end }),
    skinRow("texture", { type = "string", widget = "EditBox",
        label = L["Texture"],
        tooltip = L["The texture this addon's bars use, over the skin's own. Empty keeps the skin's."],
        onChange = function(v) NS.ApplySkinOverride(nil, v) end }),
    -- The first-run skin picker's memory: set when the picker closes, so it shows once per
    -- profile. Drawn by nothing; a reset puts it back to false.
    skinRow("pickerSeen", { type = "bool", widget = "CheckBox",
        label = L["Skin picker seen"],
        tooltip = L["Whether the first-run skin picker was closed on this profile."] }),
}
NS.SchemaRuntime.AddRows(SKIN_ROWS)

-- The library's tab entry: the source with EllesmereUI's four conditions, the nine skins, Font and
-- texture, the Scope, "Copy to every Ka0s addon..." and the note, drawn for the owner
-- core/SkinSetup.lua registered. `get` and `set` are that file's read and write seams. The own
-- condition names the FOLDER, as EllesmereUI's Third-Party list shows it, not the brand the other
-- lines print. The stub's AppearanceTab answers nil without the library: no tab is listed then.
local SKIN_TAB = Helpers.AppearanceTab({
    owner = addonName, get = NS.SkinChoice, set = NS.WriteSkinChoice,
    strings = {
        COND_own = L["PremadeGroupsFilterExtension is on in EllesmereUI's Third-Party Addons list"],
        COND_own_HINT = L["In EllesmereUI's Third-Party Addons list, turn on PremadeGroupsFilterExtension."],
    },
})

local GENERAL_OPTS = { tabs = {
    { key = REGION_GROUP, render = renderRegionTab },
    { key = EUI_GROUP,    render = renderEuiTab },
} }
if type(SKIN_TAB) == "table" then GENERAL_OPTS.tabs[#GENERAL_OPTS.tabs + 1] = SKIN_TAB end

local AFTER_GROUP = {}
if Helpers.MASTER_GROUP then AFTER_GROUP[Helpers.MASTER_GROUP] = MASTER_TAIL end
-- The Filters tab's closing line: a static pointer to the filter options, drawn, not a schema row,
-- so `/pgfe list` does not list it.
AFTER_GROUP[FILTER_GROUP] = function(ctx)
    Helpers.TextRow(ctx, L["The filter options are on the panel under Premade Groups Filter's window: open the Group Finder, choose Dungeons, and it appears below PGF's filters."])
end

local function buildGeneralPage(parentCategory)
    local ctx = Helpers.CreatePanel("PremadeGroupsFilterExtensionGeneralPanel", L["General"], {
        pageKey         = "general",
        defaultsButton  = true,
        -- The global reset: the library's words for Reset all settings (options-ui-§12).
        defaultsTooltip = Helpers.ResetAllTooltip(),
    })
    ctx.panel.defaultsOnClick = showResetPopup
    Helpers.SetRenderer(ctx, function(c)
        Helpers.ClearScroll(c)
        Helpers.RenderTabbedSchema(c, "general", AFTER_GROUP, nil, GENERAL_OPTS)
    end)
    -- AFTER SetRenderer, whose SetScript would drop an earlier hook: a re-show re-reads the
    -- EllesmereUI status lines and the switch's disabled state (the renderer only draws on the
    -- first show).
    ctx.panel:HookScript("OnShow", function() Helpers.RefreshPanel(ctx, false) end)
    return _G.Settings.RegisterCanvasLayoutSubcategory(parentCategory, ctx.panel, L["General"])
end

Helpers.RegisterOptionsPage("general", L["General"], buildGeneralPage)

--- Register the settings category. Idempotent; called from OnEnable and from `/pgfe config`.
function Settings.Register()
    if PGFE._settingsRegistered or not _G.Settings
       or not _G.Settings.RegisterCanvasLayoutCategory
       or not _G.Settings.RegisterCanvasLayoutSubcategory then
        return
    end
    Helpers.CreateOptionsPanel()
    PGFE._settingsRegistered = true
end
