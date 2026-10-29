local addonName, NS = ...
-- settings/Panel.lua — the landing page body and the General page (Master controls, Filters,
-- Region tags, Skin).
--
-- The landing page is the host's own buildMain (logo, notes, slash command list) and draws no tab
-- strip (options-ui-§5/§13). The General page renders through the tabbed renderer, in four
-- tabs: `Master controls`, composed from one declaration and holding only its mandated rows
-- (options-ui-§15); `Filters`, the extension's filters switch and a line saying where the filter
-- options are (the attached panel), and while EllesmereUI is loaded a pointer to Premade Groups
-- Filter's own EllesmereUI skin; `Region tags`, the region-tag switch leading the tags'
-- colors; and `Skin`, the
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
-- switch, not a Master controls row (options-ui-§15). Added right after MASTER_ROWS, so the tab
-- sits second. The filter options themselves are on the attached
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

-- ── Premade Groups Filter's own EllesmereUI skin (an advisory on the Filters tab) ───────────────
--
-- Under the `eui` source the attached panel is EllesmereUI's (LibKa0s's provider paints it), but PGF's
-- dialog above it is skinned by a separate addon, Premade Groups Filter - EllesmereUI Skin. The
-- addon's own bridge gated its paint on that addon; the library's gate has exactly four conditions
-- (skinning-§5), so the pointer is kept as ADVICE, not a gate (PG-G2, DECISIONS D2): while
-- EllesmereUI is loaded, the Filters tab says whether that addon is loaded, installed but disabled,
-- or missing, and offers its CurseForge link when missing. It reads only C_AddOns: whether its entry
-- is on in EllesmereUI's own list would take a read of EllesmereUI's saved variables, which only the
-- library's provider may make (library-stack-§6).

local PGF_SKIN_ADDON = "PremadeGroupsFilter_EllesmereUI"
local PGF_SKIN_URL = "https://www.curseforge.com/wow/addons/premade-groups-filter-ellesmereui"

-- C_AddOns.IsAddOnLoaded's second answer (loaded, not merely loading), the first on a client that
-- answers one.
local function loaded(name)
    local api = C_AddOns
    if type(api) ~= "table" or type(api.IsAddOnLoaded) ~= "function" then return false end
    local ok, first, second = pcall(api.IsAddOnLoaded, name)
    if not ok then return false end
    if second ~= nil then return second == true end
    return first == true
end

-- Installed at all: C_AddOns.DoesAddOnExist, else GetAddOnInfo's reason ("MISSING" when it is not in
-- the AddOns folder). A client without either reads as installed, so it never claims one missing.
local function installed(name)
    local api = C_AddOns
    if type(api) ~= "table" then return true end
    if type(api.DoesAddOnExist) == "function" then
        local ok, exists = pcall(api.DoesAddOnExist, name)
        if ok then return exists == true end
    end
    if type(api.GetAddOnInfo) == "function" then
        local ok, _, _, _, _, reason = pcall(api.GetAddOnInfo, name)
        if ok then return reason ~= "MISSING" end
    end
    return true
end

--- Premade Groups Filter's own EllesmereUI skin: "loaded", "disabled" (installed, not loaded) or
--- "missing"; nil while EllesmereUI itself is not loaded (nothing to advise).
function Settings.PGFSkinState()
    if not loaded("EllesmereUI") then return nil end
    if loaded(PGF_SKIN_ADDON) then return "loaded" end
    return installed(PGF_SKIN_ADDON) and "disabled" or "missing"
end

local PGF_SKIN_TEXT = {
    loaded   = L["Premade Groups Filter - EllesmereUI Skin is loaded, so Premade Groups Filter's window can match this panel under the EllesmereUI skin source."],
    disabled = L["Premade Groups Filter - EllesmereUI Skin is installed but disabled"] .. ". "
        .. L["Enable it in the AddOns list, then reload."],
    missing  = L["Premade Groups Filter - EllesmereUI Skin is not installed"] .. ". "
        .. L["Install it from CurseForge (copy the link below), then restart the game."],
}

-- The PGF skin's CurseForge link in a read-only edit box: anything typed puts the link back, and
-- focus selects it, ready for Ctrl+C. AceGUI pools the inner editbox frame, and HookScript cannot
-- be undone, so the frame is hooked once (`__pgfeLinkHook`) and the hook selects only while this
-- box owns the frame (`__pgfeLinkActive`). The box's release clears that flag before the frame
-- goes back to the pool, and forgets the box.
local function addPGFSkinLink(scroll)
    local AceGUI = Helpers.AceGUI
    if not AceGUI then return end
    local box = AceGUI:Create("EditBox")
    box:SetLabel(L["Get Premade Groups Filter - EllesmereUI Skin (select, then Ctrl+C):"])
    box:SetText(PGF_SKIN_URL)
    box:SetFullWidth(true)
    box:DisableButton(true)
    box:SetCallback("OnTextChanged", function(widget) widget:SetText(PGF_SKIN_URL) end)
    box:SetCallback("OnEnterPressed", function(widget) widget:SetText(PGF_SKIN_URL) end)
    local eb = box.editbox
    if eb and eb.HookScript and not eb.__pgfeLinkHook then
        eb.__pgfeLinkHook = true
        eb:HookScript("OnEditFocusGained", function(self)
            if self.__pgfeLinkActive then self:HighlightText() end
        end)
    end
    if eb then eb.__pgfeLinkActive = true end
    -- Chained onto the skin's own release restore (AceGUI keeps one callback per event name).
    NS.SkinOnRelease(box, function(w)
        if w.editbox then w.editbox.__pgfeLinkActive = nil end
        if Settings.PGFSkinLinkBox == w then Settings.PGFSkinLinkBox = nil end
    end)
    scroll:AddChild(box)
    Settings.PGFSkinLinkBox = box
end

-- Decided at render time: installing or enabling an addon needs a restart or a reload, so the
-- state cannot change live.
local function renderPGFSkinAdvice(ctx)
    local state = Settings.PGFSkinState()
    if not state then return end
    local scroll = Helpers.EnsureScroll(ctx)
    if scroll then Helpers.AddSpacer(scroll, 12) end
    Helpers.TextRow(ctx, PGF_SKIN_TEXT[state])
    if scroll and state == "missing" then addPGFSkinLink(scroll) end
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
} }
if type(SKIN_TAB) == "table" then GENERAL_OPTS.tabs[#GENERAL_OPTS.tabs + 1] = SKIN_TAB end

local AFTER_GROUP = {}
if Helpers.MASTER_GROUP then AFTER_GROUP[Helpers.MASTER_GROUP] = MASTER_TAIL end
-- The Filters tab's closing line: a static pointer to the filter options, drawn, not a schema row,
-- so `/pgfe list` does not list it.
AFTER_GROUP[FILTER_GROUP] = function(ctx)
    Helpers.TextRow(ctx, L["The filter options are on the panel under Premade Groups Filter's window: open the Group Finder, choose Dungeons, and it appears below PGF's filters."])
    renderPGFSkinAdvice(ctx)
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
    -- AFTER SetRenderer, whose SetScript would drop an earlier hook: a re-show re-reads every row's
    -- refresher and disabled state (the renderer only draws on the first show).
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
