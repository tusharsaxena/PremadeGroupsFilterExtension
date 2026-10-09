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
local MAIN_LOGO_TEXTURE = ("Interface\\AddOns\\%s\\media\\logos\\pgfe.logo.tga"):format(addonName)

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
