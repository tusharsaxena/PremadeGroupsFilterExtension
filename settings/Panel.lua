local addonName, NS = ...
-- settings/Panel.lua — the landing page body and the General page (Master controls).
--
-- The landing page is the host's own buildMain (logo, notes, slash command list) and draws no tab
-- strip (options-ui-§5/§13). The General page renders through the tabbed renderer; its first and
-- only tab is `Master controls`, composed from one declaration (options-ui-§15). The addon draws no
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
        Helpers.RenderTabbedSchema(c, "general", AFTER_GROUP)
    end)
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
