local addonName, NS = ...
-- settings/OptionsSetup.lua — the panel descriptor; Settings.Helpers IS the LibKa0s-Options instance.
--
-- The canvas shell, widget makers, flow engine, tab strip, header, Defaults button and scrollbar
-- patch are the library's (options-ui-§1). This file says where values live (the schema seam) and
-- what the landing page shows. The library-absent branch is LOAD-COMPLETING: every member a
-- settings file touches at load answers, the composers are hollow ({}), and opening the panel says
-- once that it is unavailable.
local PGFE = NS.addon
local Settings  = PGFE.Settings
local lib = LibStub and LibStub("LibKa0s-Options-1.0", true)
if not lib then
    local missing = NS.L["%s, so the settings panel is unavailable."]:format(NS.LIBKA0S_MISSING)
    local function announcer()
        local said = false
        return function()
            if said then return end
            said = true
            if NS.Print then NS.Print(missing) end
        end
    end
    local sayAtLoad, sayOnConfig = announcer(), announcer()
    local H = Settings.Helpers
    H.CreatePanel          = function() return { refreshers = {} } end
    H.EnsureDefaultsButton = function() end
    H.EnsureScroll         = function() return nil end
    H.ClearScroll          = function() end
    H.AddSpacer            = function() end
    H.Section              = function() end
    H.TextRow              = function() end
    H.AttachTooltip        = function() end
    H.InlineButtonPair     = function() end
    H.RenderField          = function() end
    H.SessionCheckbox      = function() end
    H.RenderRows           = function() end
    H.RenderSchema         = function() end
    H.RenderGrid           = function() end
    H.RenderTabbedSchema   = function() end
    H.TabStrip             = function() end
    H.PageBanner           = function() end
    H.PageHeader           = function() end
    H.SubTabStrip          = function() end
    H.SetChromeHeight      = function() end
    H.__bannerBand         = function() end
    H.__tabBand            = function() end
    H.__tabPlacement       = function() end
    H.__layoutTabs         = function() end
    H.__scrollTopInset     = function() end
    H.__releaseSubTabs     = function() end
    H.__tabArtHeight       = function() return 0 end
    H.__resetTabArtHeight  = function() end
    H.ColorPair            = function() return {} end
    H.FontGroup            = function() return {} end
    H.BorderGroup          = function() return {} end
    H.BarGroup             = function() return {} end
    H.MasterControls       = function() return {}, function() end end
    H.ChoiceGrid           = function() end
    H.Drawer               = function() end
    H.IdInput              = function() end
    H.IdList               = function() end
    H.ResolveId            = function() return nil end
    H.UnnamedCandidates    = function() return nil end
    H.KeybindingsTab       = function() return nil end
    H.KeybindRows          = function() return nil end
    H.KEYBINDS_UNCHANGED   = "Key bindings are not changed."
    -- LibKa0s v1.78.0 (OptionsAppearance) and v1.79.0 (OptionsSkinPicker): no Skin tab and no
    -- first-run picker without the library; a tab built from AppearanceTab's nil is never listed.
    H.AppearanceTab        = function() return nil end
    H.AppearanceRows       = function() return nil end
    H.SkinPicker           = function() return nil end
    H.HideSkinPicker       = function() end
    H.StrataTooltip        = function() return "" end
    H.ResetAllTooltip      = function() return "" end
    H.ID_NAME_HINT         = {}
    H.SelectTab            = function() end
    H.NavRail              = function() end
    H.SetRenderer          = function() end
    H.RegisterOptionsPage  = function() end
    H.RefreshAllPanels     = function() end
    H.RefreshPanel         = function() end
    H.RefreshScalars       = function() end
    H.RestoreAllDefaults   = H.RestoreAllDefaults or function() end
    H.LSMValues            = function() return function() return {} end end
    H.PatchAlwaysShowScrollbar = function() end
    H.__pages              = function() return {} end
    H.__panels             = function() return {} end
    H.__panelFor           = function() return nil end
    H.CreateOptionsPanel   = function() sayAtLoad() end
    H.OpenOptionsPanel     = function() sayOnConfig() end
    return
end
local host = Settings.Helpers
local O = lib:New({
    parentTitle = "Ka0s Premade Groups Filter Extension",
    mainPanelName = "PremadeGroupsFilterExtensionParentPanel",
    addonName = addonName,
    print = function(line) NS.Print(line) end,
    debug = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,
    get          = NS.SchemaRuntime.Get,
    set          = NS.SchemaRuntime.Set,
    applyDefault = NS.SchemaRuntime.ApplyDefault,
    rowsForPage = function() return Settings.Schema end,
    allRows     = function() return Settings.Schema end,
    validate = function() host.ValidateSchema() end,
    buildMain = function(ctx) Settings.Helpers.BuildMainContent(ctx) end,
    -- Backs the color picker's 50 ms drag throttle (the Region tags tab). The addon embeds no
    -- AceTimer, so the client's C_Timer.After; without it the drag commits every frame.
    scheduleTimer = function(fn, delay)
        if C_Timer and C_Timer.After then return C_Timer.After(delay, fn) end
        fn()
    end,
    -- No colorDecode/colorEncode: the library's default keyed shape { r =, g =, b =, a = } is what
    -- defaults/Profile.lua stores and what `/pgfe set` parses a color into.
    bulkBegin = NS.SchemaRuntime.BulkBegin,
    bulkEnd   = NS.SchemaRuntime.BulkEnd,
    resetProfile = function() PGFE.db:ResetProfile() end,
    profilesPage = true,
    skipRestoreAll = Settings.VetoedFromResetAll,
})
for k, v in pairs(host) do
    O[k] = v
end
Settings.Helpers = O
function O.RefreshAll() O.RefreshScalars() end
