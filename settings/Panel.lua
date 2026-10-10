local addonName, NS = ...
-- settings/Panel.lua — the landing page body and the General page (Master controls, Filters,
-- EllesmereUI skin).
--
-- The landing page is the host's own buildMain (logo, notes, slash command list) and draws no tab
-- strip (options-ui-§5/§13). The General page renders through the tabbed renderer, in three
-- tabs: `Master controls`, composed from one declaration and holding only its mandated rows
-- (options-ui-§15); `Filters`, the attached panel's two switches; and `EllesmereUI skin` (the
-- optional skin's status and switch, below). The addon draws no
-- positionable frame of its own -- the filter panel is anchored to PGF's dialog -- so the block is
-- frameless (no scale, alpha, lock or reset position) and carries no visibility row: when the panel
-- shows is decided by PGF's dialog and category, not by a setting. It has no test mode.

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
    StaticPopup_Show("PREMADEGROUPSFILTEREXTENSION_RESET_ALL")
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
-- The attached panel's two switches, in their own group so their own tab (options-ui-§13): they
-- are feature switches, not Master controls rows (options-ui-§15). Added after MASTER_ROWS and
-- before EUI_ROWS, so the tab sits between the two.
local FILTER_GROUP = NS.L["Filters"]
local FILTER_ROWS = {
    -- The attached panel's first box. Separate from Enable: this one leaves the panel up and only
    -- takes the filters out of PGF.
    { path = "filtersActive", type = "bool", default = C.PROFILE.filtersActive,
      page = "general", section = "general", group = FILTER_GROUP,
      label = NS.L.FILTERS_ACTIVE, tooltip = NS.L.FILTERS_ACTIVE_TOOLTIP,
      onChange = function(v) NS.Apply.OnFiltersToggled(v and true or false) end },
    -- The region tag on Group Finder rows and applicants (modules/RegionTags.lua); read on every
    -- row paint, so it needs no onChange: the next search or list refresh shows the change.
    { path = "showRegionTags", type = "bool", default = C.PROFILE.showRegionTags,
      page = "general", section = "general", group = FILTER_GROUP,
      label = NS.L.SHOW_REGION_TAGS, tooltip = NS.L.SHOW_REGION_TAGS_TOOLTIP },
}
Settings.StampClosureRows(FILTER_ROWS)
NS.SchemaRuntime.AddRows(FILTER_ROWS)

-- ── EllesmereUI skin (the General page's third tab) ────────────────────────────────────────────
--
-- Its own group, so its own tab (options-ui-§13): a feature switch with live status lines is not a
-- Master controls row (options-ui-§15). The tab is a host tab keyed by the group: a status line per
-- gate condition (core/EUIBridge.lua), a line saying what the skin is doing, then the one schema
-- row. The switch is drawn disabled while any condition fails and can never turn the skin on by
-- itself: modules/EUISkin.lua paints only when every condition AND the switch hold. The CLI keeps
-- parity with the disabled box: `/pgfe set euiSkin true` is refused, with the reason, while a
-- condition fails (slash-commands-§6); off is always accepted, and a bulk reset never refused.

local L = NS.L
local EUI_GROUP = L["EllesmereUI skin"]

local function euiGateOpen() return NS.EUIBridge ~= nil and (NS.EUIBridge.GateOpen()) end

local EUI_ROWS = {
    { path = "euiSkin", type = "bool", default = C.PROFILE.euiSkin,
      page = "general", section = "general", group = EUI_GROUP,
      label = L["Use the EllesmereUI skin"],
      tooltip = L["Paint the attached filter panel in your EllesmereUI theme, matching Premade Groups Filter's own EllesmereUI skin. Needs every condition listed above. Turning it off takes effect after a reload."],
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

-- The switch first (owner request), a gap, then the four condition lines, a gap, and the state line.
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
    if scroll then Helpers.AddSpacer(scroll, STATUS_GAP) end
    statusRow(ctx, function() return ICON_BLANK .. " " .. Settings.EUISkinStateText() end,
        function() return Settings.EUISkinStateText(), STATE_TIP end)
    -- Not installed: a box holding the CurseForge link to copy (the game cannot open a browser).
    -- Decided at render time: installing an addon needs a game restart, so it cannot change live.
    if scroll and B.PGFSkinState() == "missing" then addPGFSkinLink(scroll) end
end

local GENERAL_OPTS = { tabs = { { key = EUI_GROUP, render = renderEuiTab } } }

local AFTER_GROUP = {}
if Helpers.MASTER_GROUP then AFTER_GROUP[Helpers.MASTER_GROUP] = MASTER_TAIL end

local function buildGeneralPage(parentCategory)
    local ctx = Helpers.CreatePanel("PremadeGroupsFilterExtensionGeneralPanel", "General", {
        pageKey         = "general",
        defaultsButton  = true,
        defaultsTooltip = "Reset every Ka0s Premade Groups Filter Extension setting to its default. "
            .. "Asks for confirmation.",
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
    return _G.Settings.RegisterCanvasLayoutSubcategory(parentCategory, ctx.panel, "General")
end

Helpers.RegisterOptionsPage("general", "General", buildGeneralPage)

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
