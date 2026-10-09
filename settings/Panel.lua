local addonName, NS = ...
-- settings/Panel.lua — the landing page body and the General page (Master controls).
--
-- The landing page is the host's own buildMain (logo, notes, slash command list) and draws no tab
-- strip (options-ui-§5/§13). The General page renders through the tabbed renderer; its first tab is
-- `Master controls`, composed from one declaration (options-ui-§15), its second `EllesmereUI skin`
-- (the optional skin's status and switch, below). The addon draws no
-- positionable frame of its own -- the filter panel is anchored to PGF's dialog -- so the block is
-- frameless (no scale, alpha, lock or reset position) and carries no visibility row: when the panel
-- shows is decided by PGF's dialog and category, not by a setting. It has no test mode.

local PGFE     = NS.addon
local Settings = PGFE.Settings
local Helpers  = Settings.Helpers
local C        = NS.C

-- The landing page's logo: a larger render of the launcher logo, in the same folder.
local MAIN_LOGO_TEXTURE   = ("Interface\\AddOns\\%s\\media\\logos\\pgfe.logo.tga"):format(addonName)
local MAIN_LOGO_SIZE      = 256
local MAIN_GAP_AFTER_LOGO = 8
local MAIN_GAP_AFTER_DESC = 12
local MAIN_GAP_BELOW_HEAD = 6

local function justifyLeft(widget)
    local fs = widget.label
    if fs and fs.SetJustifyH then fs:SetJustifyH("LEFT") end
end

local function addLogo(AceGUI, scroll)
    local logoGroup = AceGUI:Create("SimpleGroup")
    logoGroup:SetLayout(nil)
    logoGroup:SetFullWidth(true)
    logoGroup:SetHeight(MAIN_LOGO_SIZE)
    local logoTex = logoGroup.frame:CreateTexture(nil, "ARTWORK")
    logoTex:SetTexture(MAIN_LOGO_TEXTURE)
    logoTex:SetSize(MAIN_LOGO_SIZE, MAIN_LOGO_SIZE)
    logoTex:SetPoint("TOPLEFT", logoGroup.frame, "TOPLEFT", 0, 0)
    scroll:AddChild(logoGroup)
    Helpers.AddSpacer(scroll, MAIN_GAP_AFTER_LOGO)
end

local function addNotesLine(AceGUI, scroll)
    local desc = AceGUI:Create("Label")
    desc:SetFullWidth(true)
    desc:SetText(NS.Meta("Notes") or "")
    if desc.label and desc.label.SetFontObject and _G.GameFontHighlight then
        desc.label:SetFontObject(_G.GameFontHighlight)
    end
    justifyLeft(desc)
    scroll:AddChild(desc)
    Helpers.AddSpacer(scroll, MAIN_GAP_AFTER_DESC)
end

-- One Label per NS.COMMANDS row, rendered by the slash library so the two lists cannot drift.
local function addCommandRows(AceGUI, scroll)
    local Sl = NS.SlashCommands
    for _, line in ipairs(Sl and Sl:LandingRows() or {}) do
        local row = AceGUI:Create("Label")
        row:SetFullWidth(true)
        row:SetText(line)
        justifyLeft(row)
        scroll:AddChild(row)
    end
end

function Helpers.BuildMainContent(ctx)
    local AceGUI = Helpers.AceGUI
    local scroll = Helpers.EnsureScroll(ctx)
    if not (AceGUI and scroll) then return end
    Helpers.ClearScroll(ctx)
    scroll = Helpers.EnsureScroll(ctx)
    addLogo(AceGUI, scroll)
    addNotesLine(AceGUI, scroll)
    Helpers.Section(ctx, NS.L["Slash Commands"])
    Helpers.AddSpacer(scroll, MAIN_GAP_BELOW_HEAD)
    addCommandRows(AceGUI, scroll)
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
    -- A legitimate extra (options-ui-§16), after the mandated rows: the attached panel's first box.
    -- Separate from Enable: this one leaves the panel up and only takes the filters out of PGF.
    extra            = {
        { path = "filtersActive", type = "bool", default = C.PROFILE.filtersActive,
          label = NS.L.FILTERS_ACTIVE, tooltip = NS.L.FILTERS_ACTIVE_TOOLTIP },
        -- The region tag on Group Finder rows and applicants (modules/RegionTags.lua); read on every
        -- row paint, so it needs no onChange: the next search or list refresh shows the change.
        { path = "showRegionTags", type = "bool", default = C.PROFILE.showRegionTags,
          label = NS.L.SHOW_REGION_TAGS, tooltip = NS.L.SHOW_REGION_TAGS_TOOLTIP },
    },
}

-- The Enable row drives the latch: the same Set the CLI, the launcher and a profile switch make.
local MASTER_HOOKS = {
    enabled = function(v)
        if NS.Lifecycle then NS.Lifecycle:Set(NS.HOLD_DISABLED, not v) end
    end,
    filtersActive = function(v) NS.Apply.OnFiltersToggled(v and true or false) end,
}

for _, row in ipairs(MASTER_ROWS) do
    row.section  = "general"
    row.onChange = MASTER_HOOKS[row.path]
end
Settings.StampClosureRows(MASTER_ROWS)
NS.SchemaRuntime.AddRows(MASTER_ROWS, 1)

-- ── EllesmereUI skin (the General page's second tab) ────────────────────────────────────────────
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

local function conditionText(c)
    if c.ok then return ICON_OK .. " " .. c.label end
    return ICON_BAD .. " " .. c.label .. "\n      |cff999999" .. c.hint .. "|r"
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
-- focus selects it, ready for Ctrl+C.
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
    if box.editbox and box.editbox.HookScript then
        box.editbox:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
    end
    scroll:AddChild(box)
    Settings.PGFSkinLinkBox = box
end

-- A status line: a TextRow re-read by its own refresher (options-ui-§11), so it follows changes
-- made in EllesmereUI's options, which never pass through our write seam.
local function statusRow(ctx, textFn)
    local w = Helpers.TextRow(ctx, textFn(), { fontObject = "GameFontHighlight" })
    if not w then return end
    ctx.refreshers[#ctx.refreshers + 1] = function() w:SetText(textFn()) end
end

local function renderEuiTab(ctx, rows)
    local B = NS.EUIBridge
    for i = 1, #B.Conditions() do
        statusRow(ctx, function() return conditionText(B.Conditions()[i]) end)
    end
    statusRow(ctx, Settings.EUISkinStateText)
    local scroll = Helpers.EnsureScroll(ctx)
    -- Not installed: a box holding the CurseForge link to copy (the game cannot open a browser).
    -- Decided at render time: installing an addon needs a game restart, so it cannot change live.
    if scroll and B.PGFSkinState() == "missing" then addPGFSkinLink(scroll) end
    if scroll then Helpers.AddSpacer(scroll, Helpers.ROW_VSPACER or 8) end
    local row = rows and rows[1]
    if not row then return end
    local cb = Helpers.RenderField(ctx, row)      -- binds the refresher and the disabledIf
    if cb and cb.SetCallback then cb:SetCallback("OnEnter", euiTooltip(cb, row)) end
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
