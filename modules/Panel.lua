local _, NS = ...
-- modules/Panel.lua — the filter panel attached under PGF's dialog.
--
-- Styled like PGF's own dialog (PGF UI/Dialog.xml: PortraitFrameTemplateMinimizable, the
-- ButtonFrameTemplateNoPortraitMinimizable border, portrait hidden, strata FULLSCREEN) and its
-- filter rows (PGF UI/Templates.xml PremadeGroupsFilterBasicTemplate: a UICheckButtonTemplate at
-- y+4 and a GameFontHighlight title at x+35, 23px rows). Anchored across the dialog's bottom edge,
-- so its width follows PGF's. Shown only while the dialog is shown on the Dungeons category and the
-- addon is not stood down; built lazily the first time it is wanted.
--
-- No code here calls SetText on a Blizzard frame: every SetText below lands on a frame or font
-- string this file created. Searching goes through Apply.Run{ search = true }, called only from the
-- Apply button's OnClick (a hardware event).

local Panel = NS.Panel or {}
NS.Panel = Panel

local L = NS.L

local FRAME_NAME    = "PremadeGroupsFilterExtensionPanel"
local ROW_H         = 23
local COLLAPSED_H   = 24
local BODY_TOP      = -28
local EXPANDED_H    = 280
local LABEL_X       = 35
local TARGETED      = "|cffffd100%s %d|r"
local NOT_TARGETED  = "|cff808080%s %d|r"
local POPUP_SAVE_AS = "PGFE_PRESET_SAVE_AS"
local POPUP_DELETE  = "PGFE_PRESET_DELETE"

-- The preset the dropdown shows as selected (session only).
local selectedPreset

local function stoodDown() return NS.IsStoodDown() end

local function trim(s) return type(s) == "string" and s:match("^%s*(.-)%s*$") or "" end

local function rangeText()
    return NS.Apply.LastRange or NS.Targeting.RangeText(NS.Filters.Get().keyLevel)
end

local function tooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function label(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetHeight(ROW_H)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

local function button(parent, text, width, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", function()
        if stoodDown() then return end
        onClick()
    end)
    return b
end

-- ── readout and range ───────────────────────────────────────────────────────────────────────────

local function updateReadout(f)
    local dungeons = NS.Season.GetDungeons()
    if not dungeons then
        f.readout:SetText(L.READOUT_LOADING)
        if C_MythicPlus.RequestMapInfo then C_MythicPlus.RequestMapInfo() end
        return
    end
    local level, parts = NS.Filters.Get().keyLevel, {}
    for i, d in ipairs(dungeons) do
        parts[i] = ((d.bestTimed < level) and TARGETED or NOT_TARGETED):format(d.short, d.bestTimed)
    end
    f.readout:SetText(table.concat(parts, "  "))
end

local function updateRange(f) f.rangeBox:SetText(rangeText()) end

-- ── row builders (each returns the next row's y) ────────────────────────────────────────────────

local function checkRow(f, parent, key, text, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 0, y + 4)
    cb:SetScript("OnClick", function(self)
        if stoodDown() then return end
        NS.Filters.Set(key, self:GetChecked() and true or false)
        Panel.Refresh()
    end)
    f.checks[key] = cb
    label(parent, text, LABEL_X, y)
    return cb
end

-- A 3-digit numeric box. `accept(n)` decides whether a typed number is stored; nothing is written
-- for programmatic SetText (userInput false) or while stood down.
local function numberBox(parent, x, y, accept)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(32, 20)
    box:SetPoint("TOPLEFT", x, y - 1)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(3)
    box:SetScript("OnTextChanged", function(self, userInput)
        if not userInput or stoodDown() then return end
        local n = tonumber(self:GetText())
        if n then accept(n) end
    end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function buildKeyRow(f, body, y)
    checkRow(f, body, "keyTargeting", L.KEY_TARGETING, y)
    f.levelBox = numberBox(body, 190, y, function(n)
        if not NS.Targeting.IsValidLevel(n) then return end
        NS.Filters.Set("keyLevel", n)
        updateReadout(f)
        updateRange(f)
    end)
    local readout = body:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    readout:SetPoint("TOPLEFT", LABEL_X, y - ROW_H)
    readout:SetPoint("TOPRIGHT", 0, y - ROW_H)
    readout:SetHeight(26)
    readout:SetJustifyH("LEFT")
    readout:SetJustifyV("TOP")
    f.readout = readout
    return y - ROW_H - 28
end

local function paintChip(chip, on)
    if on then
        chip:LockHighlight()
        chip:SetNormalFontObject("GameFontNormalSmall")
    else
        chip:UnlockHighlight()
        chip:SetNormalFontObject("GameFontDisableSmall")
    end
end

local function buildRegionRow(f, body, y)
    checkRow(f, body, "regionsEnabled", L.REGIONS, y)
    f.regionChips = {}
    local portal = NS.Regions.GetPortal()
    for i, key in ipairs((portal and NS.Regions.KEYS[portal]) or {}) do
        local chip = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
        chip:SetSize(32, 18)
        chip:SetPoint("TOPLEFT", 22 + (i - 1) * 34, y - ROW_H)
        chip:SetText(NS.Regions.LABELS[key])
        chip:SetScript("OnClick", function(self)
            if stoodDown() then return end
            NS.Filters.ToggleRegion(key)
            paintChip(self, NS.Filters.Get().regions[key])
        end)
        f.regionChips[key] = chip
    end
    f.regionsUnsupported = label(body, L.REGIONS_UNSUPPORTED, 22, y - ROW_H, "GameFontDisableSmall")
    f.regionsUnsupported:SetShown(portal == nil)
    return y - ROW_H - 22
end

local function buildCompositionRows(f, body, y)
    checkRow(f, body, "noSameSpec", L.NO_SAME_SPEC, y)
    checkRow(f, body, "noSameClassRole", L.NO_SAME_CLASSROLE, y - ROW_H)
    return y - 2 * ROW_H
end

local function buildLeaderRow(f, body, y)
    tooltip(checkRow(f, body, "experiencedLeader", L.EXPERIENCED_LEADER, y), L.LEADER_TOOLTIP)
    return y - ROW_H
end

local function buildAgeRow(f, body, y)
    checkRow(f, body, "maxAgeEnabled", L.MAX_AGE, y)
    f.ageBox = numberBox(body, 190, y, function(n)
        if n >= 1 and n <= 240 then NS.Filters.Set("maxAge", n) end
    end)
    label(body, L.MINUTES, 228, y)
    return y - ROW_H - 3
end

-- ── presets ─────────────────────────────────────────────────────────────────────────────────────

local function isSelectedPreset(name) return name == selectedPreset end

local function presetMenu(_, root)
    local names = NS.Presets.List()
    if #names == 0 then
        root:CreateTitle(L.PRESET_EMPTY)
        return
    end
    for _, name in ipairs(names) do
        root:CreateRadio(name, isSelectedPreset, Panel.SelectPreset, name)
    end
end

local function saveAs(name)
    name = trim(name)
    if not NS.Presets.Save(name) then
        NS.Print(L.PRESET_BAD_NAME)
        return
    end
    selectedPreset = name
    NS.Print(L.PRESET_SAVED:format(name))
    Panel.Refresh()
end

local function deletePreset(name)
    NS.Presets.Delete(name)
    if selectedPreset == name then selectedPreset = nil end
    NS.Print(L.PRESET_DELETED:format(name))
    Panel.Refresh()
end

local function popupBox(popup) return popup and (popup.EditBox or popup.editBox) end

local function definePopups()
    StaticPopupDialogs[POPUP_SAVE_AS] = {
        text = L.PRESET_SAVE_AS_PROMPT, button1 = L.SAVE, button2 = L.CANCEL,
        hasEditBox = true, maxLetters = 32, timeout = 0, whileDead = true, hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function(popup)
            local box = popupBox(popup)
            if box and not stoodDown() then saveAs(box:GetText()) end
        end,
        EditBoxOnEnterPressed = function(box)
            if not stoodDown() then saveAs(box:GetText()) end
            StaticPopup_Hide(POPUP_SAVE_AS)
        end,
        EditBoxOnEscapePressed = function() StaticPopup_Hide(POPUP_SAVE_AS) end,
    }
    StaticPopupDialogs[POPUP_DELETE] = {
        text = L.PRESET_DELETE_CONFIRM, button1 = YES, button2 = NO,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        OnAccept = function(_, name)
            if name and not stoodDown() then deletePreset(name) end
        end,
    }
end

local function buildPresetRow(f, body, y)
    local dd = CreateFrame("DropdownButton", nil, body, "WowStyle1DropdownTemplate")
    dd:SetWidth(100)
    dd:SetPoint("TOPLEFT", 4, y)
    dd:SetDefaultText(L.PRESET_NONE)
    dd:SetupMenu(presetMenu)
    f.presetDropdown = dd
    f.saveButton = button(body, L.SAVE, 44, 108, y, function()
        if selectedPreset then saveAs(selectedPreset) end
    end)
    button(body, L.SAVE_AS, 60, 154, y, function() StaticPopup_Show(POPUP_SAVE_AS) end)
    f.deleteButton = button(body, L.DELETE, 52, 216, y, function()
        if selectedPreset then StaticPopup_Show(POPUP_DELETE, selectedPreset, nil, selectedPreset) end
    end)
    return y - 28
end

-- ── apply / clear / range ───────────────────────────────────────────────────────────────────────

local function buildActionRow(f, body, y)
    f.applyButton = button(body, L.APPLY, 76, 4, y, function()
        NS.Apply.Report(NS.Apply.Run{ search = true })
        Panel.Refresh()
    end)
    button(body, L.CLEAR, 60, 84, y, function()
        NS.Apply.Report(NS.Apply.Clear())
        Panel.Refresh()
    end)
    label(body, L.RANGE, 156, y)
    local box = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
    box:SetSize(56, 20)
    box:SetPoint("TOPLEFT", 206, y - 1)
    box:SetAutoFocus(false)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        self:SetText(rangeText())
        self:HighlightText()
    end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    tooltip(box, L.RANGE_TOOLTIP)
    f.rangeBox = box
    return y - 28
end

-- ── layout and collapse ─────────────────────────────────────────────────────────────────────────

local function applyLayout(f)
    local collapsed = NS.addon.db.profile.panelCollapsed == true
    local ok, missing = NS.Bridge.Check()
    f:SetHeight(collapsed and COLLAPSED_H or EXPANDED_H)
    f.body:SetShown(ok and not collapsed)
    f.unsupported:SetShown(not ok and not collapsed)
    if not ok then f.unsupported:SetText(L.PGF_UNSUPPORTED:format(missing)) end
    f.applyButton:SetEnabled(ok)
end

local function setCollapsed(on)
    if stoodDown() or not Panel.frame then return end
    NS.addon.db.profile.panelCollapsed = on and true or false
    applyLayout(Panel.frame)
end

-- PGF's MaximizeMinimize wiring (UI/Dialog.lua OnLoad and MaximizeMinimize), on our own frame. The
-- template's close button would hide the panel under a dialog that stays open, so it is hidden and
-- the toggle takes its place.
local function buildMinMax(f)
    if f.CloseButton then f.CloseButton:Hide() end
    local mm = CreateFrame("Frame", nil, f, "MaximizeMinimizeButtonFrameTemplate")
    if f.CloseButton then mm:SetPoint("RIGHT", f.CloseButton, "RIGHT", 0, 0) end
    mm:SetOnMaximizedCallback(function() setCollapsed(false) end)
    mm:SetOnMinimizedCallback(function() setCollapsed(true) end)
    if NS.addon.db.profile.panelCollapsed then
        mm.isMinimized = true
        mm:SetMaximizedLook()
    else
        mm:SetMinimizedLook()
    end
    f.MaximizeMinimizeFrame = mm
end

local BUILDERS = { buildKeyRow, buildRegionRow, buildCompositionRows, buildLeaderRow, buildAgeRow,
    buildPresetRow, buildActionRow }

local function buildFrame(dialog)
    local f = CreateFrame("Frame", FRAME_NAME, dialog, "PortraitFrameTemplateMinimizable")
    f:SetBorder("ButtonFrameTemplateNoPortraitMinimizable")
    f:SetPortraitShown(false)
    f:SetTitle(L.PANEL_TITLE)
    f:SetFrameStrata("FULLSCREEN")
    f:EnableMouse(true)
    f:SetPoint("TOPLEFT", dialog, "BOTTOMLEFT", 0, 0)
    f:SetPoint("TOPRIGHT", dialog, "BOTTOMRIGHT", 0, 0)
    f.checks = {}
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", 12, BODY_TOP)
    body:SetPoint("BOTTOMRIGHT", -10, 8)
    f.body = body
    local y = 0
    for _, build in ipairs(BUILDERS) do y = build(f, body, y) end
    f.unsupported = label(f, "", 14, BODY_TOP, "GameFontDisable")
    buildMinMax(f)
    return f
end

-- ── public surface ──────────────────────────────────────────────────────────────────────────────

--- Build the panel under PGF's dialog. Idempotent.
--- @return table|nil frame  nil when PGF's dialog is absent
function Panel.Create()
    if Panel.frame then return Panel.frame end
    local dialog = NS.Bridge.GetDialog()
    if not dialog then return nil end
    definePopups()
    Panel.frame = buildFrame(dialog)
    Panel.frame:Hide()
    Panel.Refresh()
    return Panel.frame
end

--- Re-read the filter options into every widget and rebuild the readout.
function Panel.Refresh()
    local f = Panel.frame
    if not f then return end
    local filters = NS.Filters.Get()
    for key, cb in pairs(f.checks) do cb:SetChecked(filters[key] and true or false) end
    f.levelBox:SetText(tostring(filters.keyLevel or ""))
    f.ageBox:SetText(tostring(filters.maxAge or ""))
    for key, chip in pairs(f.regionChips) do paintChip(chip, filters.regions[key]) end
    f.saveButton:SetEnabled(selectedPreset ~= nil)
    f.deleteButton:SetEnabled(selectedPreset ~= nil)
    f.presetDropdown:GenerateMenu()
    updateReadout(f)
    updateRange(f)
    applyLayout(f)
end

--- Shown iff the dialog is shown on the Dungeons category and the addon is not stood down. The
--- Bridge.HookDialog callback; also runs on PLAYER_ENTERING_WORLD.
function Panel.UpdateVisibility()
    local want = not stoodDown() and NS.Bridge.IsDialogShown() and NS.Bridge.IsDungeonCategory()
    if want and not Panel.frame then Panel.Create() end
    local f = Panel.frame
    if not f then return end
    f:SetShown(want and true or false)
    if want then Panel.Refresh() end
end

--- Load a preset into the filter options and show it as selected (the dropdown's setSelected).
function Panel.SelectPreset(name)
    if stoodDown() then return end
    if NS.Presets.Load(name) then
        selectedPreset = trim(name)
        Panel.Refresh()
    end
end

-- ── events, stand-down, hooks ───────────────────────────────────────────────────────────────────

local addon = NS.addon

function addon.OnPanelSeasonData()
    if Panel.frame then updateReadout(Panel.frame) end
end

function addon.OnPanelEnteringWorld()
    Panel.UpdateVisibility()
end

NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "CHALLENGE_MODE_MAPS_UPDATE", "OnPanelSeasonData" }
NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "CHALLENGE_MODE_COMPLETED", "OnPanelSeasonData" }
NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "PLAYER_ENTERING_WORLD", "OnPanelEnteringWorld" }
NS.STAND_DOWN[#NS.STAND_DOWN + 1] = function()
    if Panel.frame then Panel.frame:Hide() end
end
NS.STAND_UP[#NS.STAND_UP + 1] = Panel.UpdateVisibility

-- Installed at FILE LOAD (hooks at load; never AceHook). The callback returns at once while stood
-- down: UpdateVisibility's first test is the stand-down accessor, and it only hides.
NS.Bridge.HookDialog(function() Panel.UpdateVisibility() end)
