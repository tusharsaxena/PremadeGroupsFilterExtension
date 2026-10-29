local _, NS = ...
-- modules/Panel.lua — the filter panel attached under PGF's dialog.
--
-- Rows are stacked top-down by the builders below; each input sits a fixed gap to the right of its
-- own label, so a longer (or translated) label pushes its input along instead of under it, and the
-- expanded height is measured from the stack. The dropdowns share one right-aligned column.
--
-- Styled like PGF's own dialog (PGF UI/Dialog.xml: PortraitFrameTemplateMinimizable, the
-- ButtonFrameTemplateNoPortraitMinimizable border, portrait hidden, the dialog's strata) and its
-- filter rows (PGF UI/Templates.xml PremadeGroupsFilterBasicTemplate: a UICheckButtonTemplate at
-- y+4 and a GameFontHighlight title at x+35, 23px rows) (ratified: docs/ARCHITECTURE.md ->
-- Documented deviations). Anchored across the dialog's bottom edge,
-- so its width follows PGF's. Shown only while the dialog is shown on the Dungeons category and the
-- addon is not stood down; built lazily the first time it is wanted. Collapsed, only the title
-- strip is left.
--
-- Every option has a hover tooltip. A checkbox's hit rect is stretched over its label, so hovering
-- or clicking the label acts on the box.
--
-- No code here calls SetText on a Blizzard frame: every SetText below lands on a frame or font
-- string this file created. Searching goes through Apply.Run{ search = true }, called only from the
-- Apply button's OnClick (a hardware event).
--
-- ── THE SKIN: TWO INSTANCES OF ONE BUILDER (skinning-§1, §2; the rollout's PG-02) ──────────────
--
-- Under Ka0s Default the panel is PGF's metal chrome, exactly as above (the ratified deviation). Under
-- every other skin, and under the eui source once EllesmereUI paints this owner, it follows the skin.
-- Since LibKa0s-Skin-1.0's SkinPaint minor 6 every primitive paints Ka0s Default too, and v1.80.0's
-- `opts.stockDefault` covers the window and some controls but not Checkbox, PageButton, FadeRegions or
-- Text, so one frame cannot be both. The panel is therefore built twice from the same BUILDERS:
--
--   Panel.stockFrame  the metal instance, named FRAME_NAME, NEVER handed to any NS.Skin primitive, so
--                     no repaint ever touches it: Ka0s Default is today's pixels by construction.
--   Panel.skinFrame   the skinned twin, built lazily the first time the owner draws another skin,
--                     painted once through NS.Skin (paintSkinned) and recorded, so the library
--                     replays every later switch onto it.
--   Panel.frame       the instance on show, the one every other function here reads.
--
-- NS.SkinDrawsDefault() (core/SkinSetup.lua) picks the instance at build, on every show and on
-- NS.Skin.OnLooksChanged, which the library fires after it repainted the recorded frames. A swap hides
-- the other instance, clears its edit-box focus and refreshes the one it shows from NS.Filters, the
-- one store both read. The colors this file writes (the locked boxes, the dimmed copy label, the
-- readout markup, the tooltip lines) are tokens read at write time, Ka0s Default's exact values on the
-- metal instance, so no look value is typed here (anti-pattern #107).

local Panel = NS.Panel or {}
NS.Panel = Panel

local L = NS.L
local LEVEL = NS.Constants.LAYERS.LEVEL   -- the panel's level band: core/Constants.lua

local FRAME_NAME    = "PremadeGroupsFilterExtensionPanel"
local BORDER_LAYOUT = "ButtonFrameTemplateNoPortraitMinimizable"
-- One pitch for every row, checkbox, dropdown and button rows alike (owner requirement); only the
-- gap under the Toggle row, the gaps around the Presets row and the gap above Apply are wider
-- (ACTION_GAP).
local ROW_H         = 26
local SELECT_ROW_H  = ROW_H       -- a row holding a dropdown
local BUTTON_ROW_H  = ROW_H
local BODY_TOP      = -28
-- How far the panel sits up into PGF's dialog's bottom edge. At 0 the two metal borders left ~4 UI
-- units of world between them (owner screenshot, 5px at that UI scale); 5 made them meet. Raised 2
-- the owner asked for 1px less of a gap, so the panel is raised by 3.
local ATTACH_RAISE  = 3
local BODY_BOTTOM   = 12
local LABEL_X       = 35
local CHECK_SIZE    = 32          -- UICheckButtonTemplate's size; the label starts LABEL_X - 32 past it
-- The skinned twin's check button: Checkbox draws its box `CHECK_INSET` inside the frame, so 24 gives a
-- 16px box (PGF's EllesmereUI skin's). Rows keep their centers and labels; the hit rect still
-- reaches the label.
local SKIN_CHECK_SIZE = 24
local CHECK_INSET   = 4
local INPUT_GAP     = 10
-- The level box to the Smart box's frame. Both skins draw the box ~4px inside its frame (EllesmereUI's
-- borderInset; Blizzard's art margin) and keep its left edge, so the visible gap is SMART_GAP + 4:
-- 60 at the owner's request (20, doubled to 40, then 50% more).
local SMART_GAP     = 56
local BUTTON_GAP    = 4
local BUTTON_PAD    = 20          -- a button's width past its text
local READOUT_PULL  = 6           -- the dungeon readout sits this much closer under the key-level row
local ACTION_GAP    = 8           -- the extra space under the Toggle row, around the Presets row and above Apply
local DROPDOWN_H    = 26          -- WowStyle1DropdownTemplate's height when the client does not say
local ACTION_W      = 88          -- Apply and Clear, at least
local SELECT_W      = 225         -- the regions, playstyle and composition dropdowns
local PRESET_BUTTON_MIN_W = 64     -- Save / Save as / Delete never narrower than this
-- The readout's two colors: a dungeon still to time in the accent, a timed one disabled. Read from
-- the skin at write time (ffd100 and 808080 on Ka0s Default, NS.SkinEscape's byte rounding).
local TARGETED_TOKEN, NOT_TARGETED_TOKEN = "text.accent", "text.disabled"
local POPUP_SAVE_AS = "PGFE_PRESET_SAVE_AS"
local POPUP_DELETE  = "PGFE_PRESET_DELETE"


local function stoodDown() return NS.IsStoodDown() end

local function trim(s) return type(s) == "string" and s:match("^%s*(.-)%s*$") or "" end

-- The copy box's N-N, or empty while "Untimed dungeons at key level" is off: there is no key level
-- to search for then (owner request), and the box is dimmed and disabled anyway.
local function rangeText()
    local f = NS.Filters.Get()
    if not f.keyTargeting then return "" end
    return NS.Targeting.RangeText(f.keyLevel)
end

-- ── tooltips ────────────────────────────────────────────────────────────────────────────────────

-- The option's name in white, then what it does, wrapped, in gold: the Blizzard settings convention.
-- The lines take the skin's tooltip colors (skinning-§7; the frame stays GameTooltip's). The names
-- read crossed on purpose: the name is `gtip.value` (white) and the body `gtip.title` (gold), the
-- exact pixels of Ka0s Default.
local function fillTooltip(tip, title, text)
    local tr, tg, tb = NS.SkinColor("gtip.value")
    tip:SetText(title, tr, tg, tb)
    if text then
        local r, g, b = NS.SkinColor("gtip.title")
        tip:AddLine(text, r, g, b, true)
    end
end

-- A hover tooltip on a widget this file built. HookScript, not SetScript: UIPanelButtonTemplate
-- has its own OnEnter/OnLeave, which keep running.
local function tooltip(widget, title, text)
    widget:HookScript("OnEnter", function(self)
        if stoodDown() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        fillTooltip(GameTooltip, title, text)
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function()
        if stoodDown() then return end
        GameTooltip:Hide()
    end)
end

-- A dropdown button or a menu entry (Blizzard_Menu SetTooltip): the menu owns, shows and hides the
-- tooltip; this only fills it. A WowStyle1DropdownTemplate's own OnEnter/OnLeave drive its hover art,
-- so a dropdown never gets the script hooks above.
local function menuTooltip(obj, title, text)
    obj:SetTooltip(function(tip)
        if stoodDown() then return end
        fillTooltip(tip, title, text)
    end)
end

-- ── small builders ──────────────────────────────────────────────────────────────────────────────

local function label(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetHeight(ROW_H)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

local function button(parent, text, tip, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetHeight(22)
    b:SetText(text)
    b:SetScript("OnClick", function()
        if stoodDown() then return end
        onClick()
    end)
    tooltip(b, text, tip)
    return b
end

local function textWidth(b)
    local w = b:GetTextWidth()
    return type(w) == "number" and w or 0
end

-- One width for a row of buttons: the widest text plus padding, never under `minW`.
local function sameWidth(buttons, minW)
    local w = minW
    for _, b in ipairs(buttons) do w = math.max(w, textWidth(b) + BUTTON_PAD) end
    for _, b in ipairs(buttons) do b:SetWidth(w) end
    return w
end

-- Lays `buttons` out right to left from the body's right edge, BUTTON_GAP apart.
local function rightAligned(buttons, y)
    local n = #buttons
    buttons[n]:SetPoint("TOPRIGHT", 0, y)
    for i = n - 1, 1, -1 do buttons[i]:SetPoint("RIGHT", buttons[i + 1], "LEFT", -BUTTON_GAP, 0) end
end

-- A checkbox's hit rect stretched right over its label (a negative inset grows it), so hovering or
-- clicking the label acts on the box. `gap` is the space from the box's right edge to the label.
local function stretchHitRect(cb, fs, gap)
    local w = fs:GetStringWidth()
    if type(w) ~= "number" then return end
    cb:SetHitRectInsets(0, -(gap + w), 0, 0)
end

-- ── readout and range ───────────────────────────────────────────────────────────────────────────

local function updateReadout(f)
    local dungeons = NS.Season.GetDungeons()
    if not dungeons then
        f.readout:SetText(L.READOUT_LOADING) -- Season.GetDungeons already asked the server
        return
    end
    local level, parts = NS.Filters.Get().keyLevel, {}
    local on, off = NS.SkinEscape(TARGETED_TOKEN) or "", NS.SkinEscape(NOT_TARGETED_TOKEN) or ""
    for i, d in ipairs(dungeons) do
        parts[i] = ("%s%s %d|r"):format((d.bestTimed < level) and on or off, d.short, d.bestTimed)
    end
    f.readout:SetText(table.concat(parts, "  "))
    -- One line, no wrap: when a season's names do not fit with two spaces, close them to one.
    local w = f.readout:GetWidth()
    if type(w) == "number" and w > 0 and f.readout:GetStringWidth() > w then
        f.readout:SetText(table.concat(parts, " "))
    end
end

local function updateRange(f) f.rangeBox:SetText(rangeText()) end

-- Smart key level: the addon sets the level itself (Filters.ApplySmartLevel). Nothing is written
-- while stood down.
local function applySmart()
    if not stoodDown() then NS.Filters.ApplySmartLevel() end
end

local function isSmart() return NS.Filters.Get().smartKeyLevel == true end

-- With Smart on the level box is locked: no focus, no typing, grayed text. The mouse stays on so
-- its tooltip still says why. The two colors are the skin's (white and 0.5 gray on Ka0s Default),
-- written after S.EditBox's own text color, and again on every Refresh, which a skin switch runs.
local function dimText(fs, dim)
    fs:SetTextColor(NS.SkinColor(dim and "text.disabled" or "text.highlight"))
end

local function setLocked(box, on)
    if on then box:ClearFocus() end
    box:SetEnabled(not on)
    dimText(box, on)
end

-- ── row builders (each returns the next row's y) ────────────────────────────────────────────────

local function checkButton(f, parent, key)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    if f.checkSize ~= CHECK_SIZE then cb:SetSize(f.checkSize, f.checkSize) end
    cb:SetScript("OnClick", function(self)
        if stoodDown() then return end
        NS.Filters.Set(key, self:GetChecked() and true or false)
        Panel.Refresh()
    end)
    f.checks[key] = cb
    return cb
end

-- A row's check button sits 4 above its row top at the template's 32px; a smaller (skinned) one moves
-- down by half the difference, so both are centered on the row.
local function checkTop(f, y) return y + 4 - (CHECK_SIZE - f.checkSize) / 2 end

local function checkRow(f, parent, key, text, y, tip)
    local cb = checkButton(f, parent, key)
    cb:SetPoint("TOPLEFT", 0, checkTop(f, y))
    local fs = label(parent, text, LABEL_X, y)
    stretchHitRect(cb, fs, LABEL_X - f.checkSize)
    tooltip(cb, text, tip)
    return cb, fs
end

-- A numeric box of `digits` digits over filter option `key`, INPUT_GAP right of `after` (its row's
-- label). A value is committed only whole: on Enter or when the box loses focus, never per
-- keystroke (typing `45` would otherwise store `4` first). `accept(n)` stores a valid number and
-- returns true; anything rejected puts the stored value back, so the box never shows a value that
-- is not stored. Escape reverts. Nothing is written while stood down, or while `locked()` answers
-- true (the level box under Smart).
local function numberBox(parent, after, digits, key, accept, tip, locked)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(12 + 8 * digits, 20)
    box:SetPoint("LEFT", after, "RIGHT", INPUT_GAP, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(digits)
    local function resync(self) self:SetText(tostring(NS.Filters.Get()[key] or "")) end
    local function commit(self)
        if stoodDown() then return end
        if locked and locked() then return resync(self) end
        local n = tonumber(self:GetText())
        if not (n and accept(n)) then resync(self) end
    end
    box:SetScript("OnEnterPressed", function(self) commit(self); self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", commit)
    box:SetScript("OnEscapePressed", function(self) resync(self); self:ClearFocus() end)
    tooltip(box, after:GetText(), tip)
    return box
end

-- The Smart checkbox, right of the level box, with its own label. The label starts the rows'
-- LABEL_X - CHECK_SIZE past the box's right edge, so the box-to-text gap matches every row's.
local function buildSmart(f, body, after)
    local cb = checkButton(f, body, "smartKeyLevel")
    cb:SetPoint("LEFT", after, "RIGHT", SMART_GAP, 0)
    local fs = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", LABEL_X - f.checkSize, 0)
    fs:SetText(L.SMART)
    stretchHitRect(cb, fs, LABEL_X - f.checkSize)
    tooltip(cb, L.SMART, L.SMART_TOOLTIP)
    f.smartLabel = fs
end

-- The first row: "Use the extension's filters", the panel face of the `filtersActive` setting
-- (settings/Panel.lua; the same row is on the settings page). The click writes through the schema
-- seam, whose onChange (Apply.OnFiltersToggled) removes or rewrites the managed block and refreshes
-- this panel. Separate from the addon's master Enable, which hides the panel altogether.
local function buildActiveRow(f, body, y)
    local cb = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    if f.checkSize ~= CHECK_SIZE then cb:SetSize(f.checkSize, f.checkSize) end
    cb:SetPoint("TOPLEFT", 0, checkTop(f, y))
    cb:SetScript("OnClick", function(self)
        if stoodDown() then return end
        NS.Filters.SetActive(self:GetChecked() and true or false)
    end)
    local fs = label(body, L.FILTERS_ACTIVE, LABEL_X, y)
    stretchHitRect(cb, fs, LABEL_X - f.checkSize)
    tooltip(cb, L.FILTERS_ACTIVE, L.FILTERS_ACTIVE_TOOLTIP)
    f.activeCheck = cb
    return y - ROW_H - ACTION_GAP
end

local function buildKeyRow(f, body, y)
    local _, text = checkRow(f, body, "keyTargeting", L.KEY_TARGETING, y, L.KEY_TARGETING_TOOLTIP)
    f.levelBox = numberBox(body, text, 2, "keyLevel", function(n)
        if not NS.Targeting.IsValidLevel(n) then return false end
        NS.Filters.Set("keyLevel", n)
        updateReadout(f)
        updateRange(f)
        return true
    end, L.LEVEL_TOOLTIP, isSmart)
    buildSmart(f, body, f.levelBox)
    -- The readout is one row like the others: one line, centered on it.
    local readout = body:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    readout:SetPoint("TOPLEFT", LABEL_X, y - ROW_H + READOUT_PULL)
    readout:SetPoint("TOPRIGHT", 0, y - ROW_H + READOUT_PULL)
    readout:SetHeight(ROW_H)
    readout:SetJustifyH("LEFT")
    readout:SetJustifyV("MIDDLE")
    readout:SetWordWrap(false)
    f.readout = readout
    return y - 2 * ROW_H + READOUT_PULL
end

-- ── multi-select dropdowns (server regions, playstyle) ──────────────────────────────────────────
--
-- A checkbox list in a Blizzard dropdown (Blizzard_Menu CreateCheckbox), right-aligned on its row so
-- every dropdown shares one column. An Any entry heads the list, above a divider: checked when the
-- selection means Any (none ticked, or every one ticked, Filters.IsAny), and a click on it clears the
-- selection. A checkbox answers MenuResponse.Refresh, so the menu stays open and every entry's tick
-- is re-read. The button shows our own summary (OverrideText), not the menu's selection text: Any,
-- the labels when they fit, else a count.

local SELECT_TEXT_MAX = 30

-- A multi-select whose options narrow together (regions, playstyles: any of them passes) reads
-- all-ticked as Any; one whose options stack (composition: each excludes more) does not, so its
-- `total` is huge and only an empty set is Any.
local function anyTotal(spec)
    return spec.allIsAny == false and math.huge or #spec.keys()
end

local function selectionSummary(selected, total, labels)
    if NS.Filters.IsAny(selected, total) then return L.SELECT_ANY end
    local names = {}
    for i, key in ipairs(selected) do names[i] = labels[key] or key end
    local text = table.concat(names, ", ")
    if #text > SELECT_TEXT_MAX then return L.SELECT_COUNT:format(#selected) end
    return text
end

-- spec = { keys = fn() -> ordered keys, labels = { [key] = text }, tips = { [key] = text },
--          isOn = fn(key), toggle = fn(key), clear = fn(), selected = fn() -> ordered selected keys }
local function multiSelect(body, y, spec)
    local dd = CreateFrame("DropdownButton", nil, body, "WowStyle1DropdownTemplate")
    dd:SetWidth(SELECT_W)
    dd:SetPoint("TOPRIGHT", 0, y)
    local function isAny() return NS.Filters.IsAny(spec.selected(), anyTotal(spec)) end
    -- An all-ticked set reads as Any, so its entries show unticked, as an empty one's do.
    local function isOn(key) return spec.isOn(key) and not isAny() end
    local function refreshText() dd:OverrideText(selectionSummary(spec.selected(), anyTotal(spec), spec.labels)) end
    local function respond(write, key)
        if not stoodDown() then
            write(key)
            refreshText()
        end
        return MenuResponse and MenuResponse.Refresh
    end
    local function setOn(key) return respond(spec.toggle, key) end
    local function setAny() return respond(spec.clear) end
    dd:SetupMenu(function(_, root)
        menuTooltip(root:CreateCheckbox(L.SELECT_ANY, isAny, setAny), L.SELECT_ANY, L.SELECT_ANY_TOOLTIP)
        root:CreateDivider()
        for _, key in ipairs(spec.keys()) do
            local text = spec.labels[key] or key
            menuTooltip(root:CreateCheckbox(text, isOn, setOn, key), text, spec.tips[key])
        end
    end)
    dd.RefreshSummary = refreshText
    return dd
end

local function keyedTips(keys, prefix)
    local out = {}
    for _, key in ipairs(keys) do out[key] = L[prefix .. key:upper()] end
    return out
end

local function buildRegionRow(f, body, y)
    checkRow(f, body, "regionsEnabled", L.REGIONS, y, L.REGIONS_TOOLTIP)
    local portal = NS.Regions.GetPortal()
    local keys = (portal and NS.Regions.KEYS[portal]) or {}
    f.regionSelect = multiSelect(body, y, {
        keys = function() return keys end,
        labels = NS.Regions.LABELS,
        tips = keyedTips(keys, "REGION_TIP_"),
        isOn = function(key) return NS.Filters.Get().regions[key] == true end,
        toggle = function(key) NS.Filters.ToggleRegion(key, portal) end,
        clear = function() NS.Filters.ClearRegions(portal) end,
        selected = function() return NS.Filters.SelectedRegions(portal) end,
    })
    menuTooltip(f.regionSelect, L.REGIONS, L.REGIONS_SELECT_TOOLTIP)
    f.regionSelect:SetShown(portal ~= nil)
    f.regionsUnsupported = body:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    f.regionsUnsupported:SetPoint("TOPRIGHT", 0, y - 5)
    f.regionsUnsupported:SetText(L.REGIONS_UNSUPPORTED)
    f.regionsUnsupported:SetShown(portal == nil)
    return y - SELECT_ROW_H
end

-- The game's own localized playstyle names (GROUP_FINDER_GENERAL_PLAYSTYLE1..4, Blizzard
-- LFGList.lua), read at build time; enUS fallbacks if a global is absent.
local function playstyleLabels()
    local out = {}
    for i, key in ipairs(NS.Filters.PLAYSTYLES) do
        out[key] = _G["GROUP_FINDER_GENERAL_PLAYSTYLE" .. i] or L["PLAYSTYLE_" .. key:upper()]
    end
    return out
end

local function buildPlaystyleRow(f, body, y)
    checkRow(f, body, "playstyleEnabled", L.PLAYSTYLE, y, L.PLAYSTYLE_TOOLTIP)
    f.playstyleSelect = multiSelect(body, y, {
        keys = function() return NS.Filters.PLAYSTYLES end,
        labels = playstyleLabels(),
        tips = keyedTips(NS.Filters.PLAYSTYLES, "PLAYSTYLE_TIP_"),
        isOn = function(key) return NS.Filters.Get().playstyles[key] == true end,
        toggle = NS.Filters.TogglePlaystyle,
        clear = NS.Filters.ClearPlaystyles,
        selected = NS.Filters.SelectedPlaystyles,
    })
    menuTooltip(f.playstyleSelect, L.PLAYSTYLE, L.PLAYSTYLE_SELECT_TOOLTIP)
    return y - SELECT_ROW_H
end

-- Composition: the two exclusions as one multi-select (owner request). The options stack (each hides
-- more groups), so ticking both is a filter of its own, not Any.
local function buildCompositionRow(f, body, y)
    checkRow(f, body, "compositionEnabled", L.COMPOSITION, y, L.COMPOSITION_TOOLTIP)
    local keys = NS.Filters.COMPOSITION
    f.compositionSelect = multiSelect(body, y, {
        keys = function() return keys end,
        labels = { noSameSpec = L.NO_SAME_SPEC, noSameClassRole = L.NO_SAME_CLASSROLE },
        tips = { noSameSpec = L.NO_SAME_SPEC_TOOLTIP, noSameClassRole = L.NO_SAME_CLASSROLE_TOOLTIP },
        allIsAny = false,
        isOn = function(key) return NS.Filters.Get()[key] == true end,
        toggle = NS.Filters.ToggleComposition,
        clear = NS.Filters.ClearComposition,
        selected = NS.Filters.SelectedComposition,
    })
    menuTooltip(f.compositionSelect, L.COMPOSITION, L.COMPOSITION_SELECT_TOOLTIP)
    return y - SELECT_ROW_H
end

local function buildLeaderRow(f, body, y)
    checkRow(f, body, "experiencedLeader", L.EXPERIENCED_LEADER, y, L.LEADER_TOOLTIP)
    return y - ROW_H
end

local function buildAgeRow(f, body, y)
    local _, text = checkRow(f, body, "maxAgeEnabled", L.MAX_AGE, y, L.MAX_AGE_TOOLTIP)
    f.ageBox = numberBox(body, text, 3, "maxAge", function(n)
        if not NS.Filters.IsWholeInRange(n, NS.Filters.MAX_AGE) then return false end
        NS.Filters.Set("maxAge", n)
        return true
    end, L.AGE_BOX_TOOLTIP)
    local minutes = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    minutes:SetPoint("LEFT", f.ageBox, "RIGHT", 6, 0)
    minutes:SetText(L.MINUTES)
    return y - ROW_H
end

-- ── presets ─────────────────────────────────────────────────────────────────────────────────────

local function isSelectedPreset(name) return name == NS.Presets.GetSelected() end

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
    NS.Print(L.PRESET_SAVED:format(name))
    Panel.Refresh()
end

local function deletePreset(name)
    NS.Presets.Delete(name)
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
        OnHide = NS.RestorePopupStrata,   -- puts back a lift over the panel (core/Popup.lua)
    }
    StaticPopupDialogs[POPUP_DELETE] = {
        text = L.PRESET_DELETE_CONFIRM, button1 = YES, button2 = NO,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        OnAccept = function(_, name)
            if name and not stoodDown() then deletePreset(name) end
        end,
        OnHide = NS.RestorePopupStrata,
    }
end

-- One row (owner requirement): Save / Save as / Delete at one width that fits their text,
-- right-aligned; the dropdown takes the rest of the row, from the body's left edge to Save.
-- One row, set apart by ACTION_GAP above as below (owner request); the three buttons are as tall as
-- the dropdown beside them.
local function buildPresetRow(f, body, y)
    y = y - ACTION_GAP
    f.saveButton = button(body, L.SAVE, L.SAVE_TOOLTIP, function()
        local name = NS.Presets.GetSelected()
        if name then saveAs(name) end
    end)
    f.saveAsButton = button(body, L.SAVE_AS, L.SAVE_AS_TOOLTIP, function() NS.ShowPopup(POPUP_SAVE_AS) end)
    f.deleteButton = button(body, L.DELETE, L.DELETE_TOOLTIP, function()
        local name = NS.Presets.GetSelected()
        if name then NS.ShowPopup(POPUP_DELETE, name, nil, name) end
    end)
    local row = { f.saveButton, f.saveAsButton, f.deleteButton }
    sameWidth(row, PRESET_BUTTON_MIN_W)
    rightAligned(row, y)
    local dd = CreateFrame("DropdownButton", nil, body, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", 4, y)
    dd:SetPoint("RIGHT", f.saveButton, "LEFT", -BUTTON_GAP, 0)
    dd:SetDefaultText(L.PRESET_NONE)
    dd:SetupMenu(presetMenu)
    menuTooltip(dd, L.PRESETS, L.PRESETS_TOOLTIP)
    f.presetDropdown = dd
    local h = dd:GetHeight()
    h = (type(h) == "number" and h > 0) and h or DROPDOWN_H
    for _, b in ipairs(row) do b:SetHeight(h) end
    return y - BUTTON_ROW_H
end

-- ── apply / clear / copy box ────────────────────────────────────────────────────────────────────

-- Blizzard's Group Finder search box refuses SetText from addon code (securityDisableSetText), so
-- the range can never be written into it. Only keyboard focus is moved there, from the copy box's
-- Enter, so the player's own Ctrl+V and Enter fill it and search. Guarded: a client that refuses
-- the focus change leaves focus where it was.
local function focusSearchBox()
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    local box = panel and panel.SearchBox
    if box and box.SetFocus and box:IsVisible() then pcall(box.SetFocus, box) end
end

local function reportResult(...)
    NS.Apply.Report(...)
    return (...)
end

-- The copy box (N-N) and its label, right-aligned at the end of the action row. A font string takes
-- no mouse, so a frame over the label carries the label's tooltip.
local function buildCopyBox(f, body, y)
    local box = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
    box:SetSize(56, 20)
    box:SetJustifyH("CENTER")
    box:SetPoint("TOPRIGHT", 0, y - 1)
    box:SetAutoFocus(false)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        self:SetText(rangeText())
        self:HighlightText()
    end)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if not stoodDown() then focusSearchBox() end
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    tooltip(box, L.COPY_SEARCH, L.COPY_SEARCH_TOOLTIP)
    f.rangeBox = box
    local fs = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("RIGHT", box, "LEFT", -INPUT_GAP, 0)
    fs:SetText(L.COPY_SEARCH)
    f.copyLabel = fs
    local hover = CreateFrame("Frame", nil, body)
    hover:SetAllPoints(fs)
    hover:EnableMouse(true)
    tooltip(hover, L.COPY_SEARCH, L.COPY_SEARCH_TOOLTIP)
    f.copyLabelHover = hover
end

-- The copy box only means something while dungeons are targeted by key level: with "Untimed
-- dungeons at key level" off, the box and its label are dimmed and the box disabled (owner request).
-- Their tooltips still show.
local function setCopyEnabled(f, on)
    setLocked(f.rangeBox, not on)
    dimText(f.copyLabel, not on)
end

-- Apply leaves keyboard focus alone: taking it into the copy box held the keyboard (movement, chat)
-- until the player clicked away (owner request). Clicking the copy box selects its text; then
-- Ctrl+C, Enter (focus jumps to the search box), Ctrl+V, Enter.
local function buildActionRow(f, body, y)
    y = y - ACTION_GAP
    f.applyButton = button(body, L.APPLY, L.APPLY_TOOLTIP, function()
        reportResult(NS.Apply.Run{ search = true })
        Panel.Refresh()
    end)
    f.clearButton = button(body, L.CLEAR, L.CLEAR_TOOLTIP, function()
        NS.Apply.Report(NS.Apply.Clear())
        Panel.Refresh()
    end)
    sameWidth({ f.applyButton, f.clearButton }, ACTION_W)
    f.applyButton:SetPoint("TOPLEFT", 4, y)
    f.clearButton:SetPoint("LEFT", f.applyButton, "RIGHT", BUTTON_GAP, 0)
    buildCopyBox(f, body, y)
    return y - BUTTON_ROW_H
end

-- ── layout and collapse ─────────────────────────────────────────────────────────────────────────

-- Collapsed, the panel shows only its title strip: the title, the arrow and the closing metal bar.
local HEADER_H    = 32   -- collapsed height: the title band plus the closing bar
-- The skinned twin's collapsed height while EllesmereUI paints it: EllesmereUI's Shell draws a 25px
-- top bar whatever the Ka0s `title.height` token says (host geometry, DECISIONS D4).
local EUI_SHELL_HEADER_H = 25
local HEADER_SEAM = 24   -- below the frame top: the top art is cut here and the bottom art starts here
local ART_SPAN    = 128  -- each border copy's laid-out height; more than the top and bottom corners stacked (~75+32)
local CLIP_PAD    = 24   -- clip margin past the border overhangs (corners: x -12/+4, y +16/-3)

-- Each metal corner is about as tall as a collapsed frame, so the template's NineSlice cannot be
-- shrunk to fit (its corners overlap). Two copies of the same layout are laid out full size instead,
-- each inside a clipping frame: the top copy is cut at HEADER_SEAM and the bottom copy shows only
-- what lies below it. The template's NineSlice is left untouched for the expanded look.
-- Both frames sit at the panel's own level (LEVEL.HEADER_ART): a child defaults to one above it,
-- which ties with the MaximizeMinimize frame and the close button and leaves their draw order to
-- chance. Set once, at build: anything that later re-levels the panel must re-sink them.
local function sinkToParentLevel(frame, parent)
    local level = parent:GetFrameLevel()
    if type(level) == "number" then frame:SetFrameLevel(level + LEVEL.HEADER_ART) end
end

local function buildHeaderHalf(f, util, layout, top)
    local clip = CreateFrame("Frame", nil, f)
    clip:SetClipsChildren(true)
    sinkToParentLevel(clip, f)
    local slice = CreateFrame("Frame", nil, clip)
    sinkToParentLevel(slice, f)
    slice:SetHeight(ART_SPAN)
    if top then
        clip:SetPoint("TOPLEFT", f, "TOPLEFT", -CLIP_PAD, CLIP_PAD)
        clip:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", CLIP_PAD, -HEADER_SEAM)
        slice:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        slice:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    else
        clip:SetPoint("TOPLEFT", f, "TOPLEFT", -CLIP_PAD, -HEADER_SEAM)
        clip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", CLIP_PAD, -CLIP_PAD)
        slice:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        slice:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    end
    util.ApplyLayout(slice, layout)
    clip:Hide()
    return clip
end

local function buildHeaderArt(f)
    local util = NineSliceUtil
    if type(util) ~= "table" or type(util.ApplyLayout) ~= "function" or type(util.GetLayout) ~= "function" then return end
    local layout = util.GetLayout(BORDER_LAYOUT)
    if type(layout) ~= "table" then return end
    f.headerArt = { buildHeaderHalf(f, util, layout, true), buildHeaderHalf(f, util, layout, false) }
end

local function setHeaderOnly(f, on)
    if f.headerArt then
        for _, clip in ipairs(f.headerArt) do clip:SetShown(on) end
        if type(f.NineSlice) == "table" and f.NineSlice.SetShown then f.NineSlice:SetShown(not on) end
    end
    -- The streaks hang 21px below the title band, which a collapsed frame does not have.
    if type(f.TopTileStreaks) == "table" and f.TopTileStreaks.SetShown then f.TopTileStreaks:SetShown(not on) end
end

-- Owner request: expanded shows the up-right arrow, collapsed the down-left one. The template pairs
-- them the other way (MaximizeButton RedButton-Expand, MinimizeButton RedButton-Condense), so the art
-- is swapped between the two buttons once, at build; which button shows, and what a click does, stay
-- the template's.
local function setArrowArt(b, base, disabledSuffix)
    if type(b) ~= "table" or type(b.SetNormalAtlas) ~= "function" then return end
    b:SetNormalAtlas(base)
    b:SetPushedAtlas(base .. "-Pressed")
    b:SetDisabledAtlas(base .. disabledSuffix)
end

-- PGF's wiring (UI/Dialog.lua MaximizeMinimize): expanded calls SetMinimizedLook, collapsed
-- SetMaximizedLook. Set from the stored state on every layout, because the template's own buttons
-- flip the arrow on click even when setCollapsed refuses (stood down), and a profile switch changes
-- the state without a click.
local function syncMinMax(f, collapsed)
    local mm = f.MaximizeMinimizeFrame
    if not mm then return end
    mm.isMinimized = collapsed
    if collapsed then mm:SetMaximizedLook() else mm:SetMinimizedLook() end
end

-- The collapsed height. The skinned twin folds to the skin's title band (`title.height`, read live,
-- so a switch to a skin with another band refolds), or to EllesmereUI's shell bar once EllesmereUI
-- paints this owner; the metal instance to HEADER_H.
local function collapsedHeight(f)
    if not f.skinned then return HEADER_H end
    if NS.SkinEUIPainted() then return EUI_SHELL_HEADER_H end
    local h = NS.Skin.Token("title.height")
    return type(h) == "number" and h or HEADER_H
end

local function applyLayout(f)
    local collapsed = NS.addon.db.profile.panelCollapsed == true
    local ok, missing = NS.Bridge.Check()
    f:SetHeight(collapsed and collapsedHeight(f) or f.expandedHeight)
    setHeaderOnly(f, collapsed)
    syncMinMax(f, collapsed)
    f.body:SetShown(ok and not collapsed)
    f.unsupported:SetShown(not ok and not collapsed)
    if not ok then f.unsupported:SetText(L.PGF_UNSUPPORTED:format(missing)) end
    f.applyButton:SetEnabled(ok and NS.Filters.IsActive())
end

local function setCollapsed(on)
    if not Panel.frame then return end
    if not stoodDown() then NS.addon.db.profile.panelCollapsed = on and true or false end
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
    -- The skinned twin's arrows are the skin's (paintSkinned); only the metal one swaps the art.
    if not f.skinned then
        setArrowArt(mm.MinimizeButton, "RedButton-Expand", "-Disabled")
        setArrowArt(mm.MaximizeButton, "RedButton-Condense", "-disabled")
    end
    f.MaximizeMinimizeFrame = mm -- which arrow shows is set by applyLayout
end

-- The header strip toggles too (owner request): a click anywhere on the title band does what the
-- arrow does. It spans the band from the left edge to just short of the arrow, so the arrow keeps
-- its own click; the title text above it takes no mouse, so clicks reach this button.
local HEADER_CLICK_RT = 30   -- room left at the right for the arrow button

local function buildHeaderClick(f)
    local b = CreateFrame("Button", nil, f)
    b:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    b:SetPoint("TOPRIGHT", f, "TOPRIGHT", -HEADER_CLICK_RT, 0)
    b:SetHeight(HEADER_SEAM)   -- the title band (the skinned bar is 25)
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", function()
        if stoodDown() then return end
        setCollapsed(NS.addon.db.profile.panelCollapsed ~= true)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
    end)
    f.headerClick = b
end

local BUILDERS = { buildActiveRow, buildKeyRow, buildRegionRow, buildPlaystyleRow, buildCompositionRow, buildLeaderRow,
    buildAgeRow, buildPresetRow, buildActionRow }

-- PortraitFrameBaseTemplate starts its TitleContainer 58px in from the left (room for the portrait,
-- hidden here) but only 24px in from the right (Blizzard SharedUIPanelTemplates.xml), so the title
-- sat ~17px right of center. Re-anchored 24px in on both sides: centered on the whole header, and
-- still clear of the min/max button.
local TITLE_INSET = 24

local function centerTitle(f)
    local tc = f.TitleContainer
    if type(tc) ~= "table" or not tc.ClearAllPoints then return end
    tc:ClearAllPoints()
    tc:SetPoint("TOPLEFT", f, "TOPLEFT", TITLE_INSET, -1)
    tc:SetPoint("TOPRIGHT", f, "TOPRIGHT", -TITLE_INSET, -1)
end

-- A host-matched surface (frame-layering-§1): the panel takes PGF's dialog strata by reading it,
-- so a PGF release that moves its dialog takes the panel along; a dialog that cannot say leaves it
-- inheriting, as a child does. Its level is the dialog's + LEVEL.ABOVE_HOST, set before any of the
-- panel's own frames are built, so they are born in the band core/Constants.lua names.
local function layerWithDialog(f, dialog)
    local strata = type(dialog.GetFrameStrata) == "function" and dialog:GetFrameStrata()
    if type(strata) == "string" then f:SetFrameStrata(strata) end
    local dialogLevel = type(dialog.GetFrameLevel) == "function" and dialog:GetFrameLevel()
    if type(dialogLevel) == "number" then f:SetFrameLevel(dialogLevel + LEVEL.ABOVE_HOST) end
end

-- ── the skinned twin's paint ────────────────────────────────────────────────────────────────────

-- Every font string of `frame`, the role each takes: the dimmed notes `disabled`, the copy label its
-- face only (its color is dimText's), every other label and the readout `body`.
local function paintTexts(S, f, frame)
    for _, r in ipairs({ frame:GetRegions() }) do
        if type(r) == "table" and r.IsObjectType and r:IsObjectType("FontString") then
            if r == f.copyLabel then S.Font(r)
            elseif r == f.unsupported or r == f.regionsUnsupported then S.Text(r, "disabled")
            else S.Text(r, "body") end
        end
    end
end

-- The twin through the owner's facade, once, at build: each call is recorded, so the library replays
-- it on every later switch (and hands it to EllesmereUI's facade under the eui source). The metal
-- border, its Bg and the title streaks fade under the skin's window; the template's title takes the
-- title role; the arrows are paging arrows (expanded shows the collapse button: up). The panel's own
-- SetScript calls all ran in the builders, before any primitive hooked a script.
local function paintSkinned(f)
    local S = NS.Skin
    S.Shell(f, { stock = { f.Bg, f.TopTileStreaks } })
    local title = type(f.TitleContainer) == "table" and f.TitleContainer.TitleText
    if title then S.Text(title, "title") end
    local mm = f.MaximizeMinimizeFrame
    if mm then
        S.PageButton(mm.MinimizeButton, "up")
        S.PageButton(mm.MaximizeButton, "down")
    end
    S.Checkbox(f.activeCheck, { borderInset = CHECK_INSET })
    for _, cb in pairs(f.checks) do S.Checkbox(cb, { borderInset = CHECK_INSET }) end
    for _, box in ipairs({ f.levelBox, f.ageBox, f.rangeBox }) do S.EditBox(box) end
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect, f.compositionSelect, f.presetDropdown }) do
        S.Dropdown(dd)
    end
    for _, b in ipairs({ f.saveButton, f.saveAsButton, f.deleteButton, f.applyButton, f.clearButton }) do
        S.Button(b)
    end
    paintTexts(S, f, f)
    paintTexts(S, f, f.body)
end

-- `skinned` builds the twin: no name, no metal header copies, 24px check buttons, flush under the
-- dialog (a flat window sits on its rect; the metal border overhung it, hence ATTACH_RAISE), painted.
local function buildFrame(dialog, skinned)
    local f = CreateFrame("Frame", not skinned and FRAME_NAME or nil, dialog, "PortraitFrameTemplateMinimizable")
    f.skinned = skinned and true or false
    f.checkSize = skinned and SKIN_CHECK_SIZE or CHECK_SIZE
    layerWithDialog(f, dialog)
    f:SetBorder(BORDER_LAYOUT)
    if not skinned then buildHeaderArt(f) end
    f:SetPortraitShown(false)
    f:SetTitle(L.PANEL_TITLE)
    centerTitle(f)
    f:EnableMouse(true)
    local raise = skinned and 0 or ATTACH_RAISE
    f:SetPoint("TOPLEFT", dialog, "BOTTOMLEFT", 0, raise)
    f:SetPoint("TOPRIGHT", dialog, "BOTTOMRIGHT", 0, raise)
    f.checks = {}
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", 12, BODY_TOP)
    body:SetPoint("BOTTOMRIGHT", -10, 8)
    f.body = body
    local y = 0
    for _, build in ipairs(BUILDERS) do y = build(f, body, y) end
    f.expandedHeight = -BODY_TOP - y + BODY_BOTTOM
    f.unsupported = label(f, "", 14, BODY_TOP, "GameFontDisable")
    buildMinMax(f)
    buildHeaderClick(f)
    if skinned then paintSkinned(f) end
    return f
end

-- ── which instance shows ────────────────────────────────────────────────────────────────────────

local function wantSkinned() return not NS.SkinDrawsDefault() end

-- The instance the skin wants, built on first want, hidden until a show.
local function instance(dialog, skinned)
    local key = skinned and "skinFrame" or "stockFrame"
    if not Panel[key] then
        Panel[key] = buildFrame(dialog, skinned)
        Panel[key]:Hide()
    end
    return Panel[key]
end

local function clearFocus(f)
    for _, box in ipairs({ f.levelBox, f.ageBox, f.rangeBox }) do box:ClearFocus() end
end

-- Point Panel.frame at the instance the skin wants. The one it leaves is hidden, its focus dropped,
-- and the one it takes shown when the other was. Answers true on a swap.
local function choose(dialog)
    local f = instance(dialog, wantSkinned())
    local was = Panel.frame
    Panel.frame = f
    if not was or was == f then return false end
    local shown = was:IsShown()
    clearFocus(was)
    was:Hide()
    if shown then f:Show() end
    return true
end

-- A skin change (the library fires it after the repaint): the instance follows, and the shown one is
-- refreshed, which re-writes the colors read from tokens. Nothing is built while stood down; the
-- stand-up's UpdateVisibility chooses again.
local function onLooksChanged()
    if not Panel.frame or stoodDown() then return end
    local dialog = NS.Bridge.GetDialog()
    if not dialog then return end
    choose(dialog)
    Panel.Refresh()
end

-- ── public surface ──────────────────────────────────────────────────────────────────────────────

--- Build the panel under PGF's dialog. Idempotent.
--- @return table|nil frame  nil when PGF's dialog is absent
function Panel.Create()
    if Panel.frame then return Panel.frame end
    local dialog = NS.Bridge.GetDialog()
    if not dialog then return nil end
    definePopups()
    -- The skin's listener goes in with the first instance (no panel, nothing to follow before it).
    NS.Skin.OnLooksChanged(onLooksChanged)
    choose(dialog)
    Panel.Refresh()
    return Panel.frame
end

--- Re-read the filter options into every widget and rebuild the readout. With Smart on, the key
--- level is recomputed first.
function Panel.Refresh()
    local f = Panel.frame
    if not f then return end
    applySmart()
    local filters = NS.Filters.Get()
    for key, cb in pairs(f.checks) do cb:SetChecked(filters[key] and true or false) end
    f.activeCheck:SetChecked(NS.Filters.IsActive())
    f.levelBox:SetText(tostring(filters.keyLevel or ""))
    setLocked(f.levelBox, filters.smartKeyLevel == true)
    f.ageBox:SetText(tostring(filters.maxAge or ""))
    f.regionSelect.RefreshSummary()
    f.playstyleSelect.RefreshSummary()
    f.compositionSelect.RefreshSummary()
    setCopyEnabled(f, filters.keyTargeting == true)
    local selected = NS.Presets.GetSelected() ~= nil
    f.saveButton:SetEnabled(selected)
    f.deleteButton:SetEnabled(selected)
    f.presetDropdown:GenerateMenu()
    updateReadout(f)
    updateRange(f)
    applyLayout(f)
end

--- Shown iff the dialog is shown, maximized, on the Dungeons category (its active panel is the
--- dungeon panel) and the addon is not stood down. The
--- Bridge.HookDialog callback; also runs on PLAYER_ENTERING_WORLD.
function Panel.UpdateVisibility()
    local want = not stoodDown() and NS.Bridge.IsDialogShown() and NS.Bridge.IsDungeonCategory()
        and NS.Bridge.IsDungeonPanelActive()
    if want and not Panel.frame then Panel.Create() end
    if not Panel.frame then return end
    -- A skin change made while stood down (or before the panel's listener existed) takes effect here.
    local dialog = want and NS.Bridge.GetDialog()
    if dialog then choose(dialog) end
    local f = Panel.frame
    f:SetShown(want and true or false)
    -- Written on a change only: the dialog hook and PLAYER_ENTERING_WORLD re-run this often.
    NS.DebugChanged("panel.vis", "Panel", want and "shown" or "hidden")
    if want then Panel.Refresh() end
end

--- Load a preset into the filter options and show it as selected (the dropdown's setSelected).
function Panel.SelectPreset(name)
    if stoodDown() then return end
    if NS.Presets.Load(name) then Panel.Refresh() end
end

-- ── events, stand-down, hooks ───────────────────────────────────────────────────────────────────

local addon = NS.addon

-- Season data arrived or changed: Smart recomputes the level (the panel need not exist), then the
-- readout is rebuilt. The level box and copy box are rewritten only under Smart, so a level the
-- player is typing is not overwritten.
function addon.OnPanelSeasonData()
    if stoodDown() then return end
    NS.Filters.ApplySmartLevel()
    local f = Panel.frame
    if not f then return end
    if isSmart() then
        f.levelBox:SetText(tostring(NS.Filters.Get().keyLevel or ""))
        updateRange(f)
    end
    updateReadout(f)
end

-- A loading screen re-arms the season-data request, so one lost on the way recovers here.
function addon.OnPanelEnteringWorld()
    NS.Season.ResetRequest()
    Panel.UpdateVisibility()
end

NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "CHALLENGE_MODE_MAPS_UPDATE", "OnPanelSeasonData" }
NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "CHALLENGE_MODE_COMPLETED", "OnPanelSeasonData" }
NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE", "OnPanelSeasonData" }
NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "PLAYER_ENTERING_WORLD", "OnPanelEnteringWorld" }
NS.STAND_DOWN[#NS.STAND_DOWN + 1] = function()
    -- The tooltip handlers gate on the stand-down, so OnLeave can no longer hide a tooltip the
    -- panel showed: hide it here, when its owner is the panel or a frame inside it. The walk stops
    -- at a frame whose GetParent answers itself.
    if Panel.frame and GameTooltip and GameTooltip.GetOwner then
        local o = GameTooltip:GetOwner()
        while o and o ~= Panel.frame do
            local p = o:GetParent()
            if p == o then o = nil else o = p end
        end
        if o then GameTooltip:Hide() end
    end
    if Panel.frame then Panel.frame:Hide() end
    -- Re-arm the visibility line, so the stand-up's "shown" is written rather than held as a
    -- repeat. DebugForget is on the instance only (core/DebugLogSetup.lua publishes no bare name).
    NS.DebugLog.DebugForget("panel.vis")
end
NS.STAND_UP[#NS.STAND_UP + 1] = Panel.UpdateVisibility

-- Installed at FILE LOAD (hooks at load; never AceHook). The callback returns at once while stood
-- down (the stand-down already hid the panel; the stand-up re-runs UpdateVisibility). Whether the
-- hook went in is kept on Panel.dialogHooked, for Diagnostics.
Panel.dialogHooked = NS.Bridge.HookDialog(function()
    if stoodDown() then return end
    Panel.UpdateVisibility()
end)
