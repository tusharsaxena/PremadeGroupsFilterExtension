local _, NS = ...
-- modules/EUISkin.lua — paints the attached panel (modules/Panel.lua) in the user's EllesmereUI
-- theme, the way PremadeGroupsFilter_EllesmereUI paints PGF's own dialog, through EllesmereUI's
-- public skinning API (SKINNING_API.md: EllesmereUI.RegisterSkin, facade S, apiVersion 3).
--
-- Registered at FILE LOAD, presence-guarded, whatever our switch says: that lists this addon in
-- EllesmereUI's Third-Party Addons and hands us S. EllesmereUI calls back ONCE per session (at
-- PLAYER_LOGIN, or live from its options when a switch turns on), and only while its master switch
-- and our entry are on. The panel is built lazily, so S is KEPT and the paint happens when every
-- condition holds: from the callback, from Panel.Create, from our own switch turning on, a profile
-- switch or the stand-up. Painting is one-way: only a /reload removes it, so turning our switch off
-- after a paint asks for one.
--
-- Effective skin = S held AND every gate condition (core/EUIBridge.lua) AND our switch
-- (profile.euiSkin) AND not stood down. Never forced: nothing here writes any switch.
--
-- Own frames only: every primitive lands on a frame Panel.lua created. The primitives are alpha-only
-- art removal plus overlays (no Hide, no SetParent); the hooks below are on our own frames and
-- return at once while the addon is stood down.

local EUISkin = NS.EUISkin or {}
NS.EUISkin = EUISkin

local L   = NS.L
local TAG = "Skin"

local SHELL_HEADER_H = 25   -- WSkin.Shell's top bar: collapsed, the panel is that bar alone
local SHELL_GAP      = 0    -- flat shells sit exactly on their frame rects: 0 is flush with PGF's dialog
local CHECKBOX_SIZE, CHECKBOX_BORDER_INSET = 24, 4
local ACCENT_BORDER_SIZE, ACCENT_MARK_GAP, ACCENT_BORDER_LEVEL = 1, 2, 3
local ACCENT_BOX_SIZE  = CHECKBOX_SIZE - 2 * CHECKBOX_BORDER_INSET
local ACCENT_MARK_SIZE = ACCENT_BOX_SIZE - 2 * (ACCENT_BORDER_SIZE + ACCENT_MARK_GAP)
local COLLAPSE_ATLAS = "UI-QuestTrackerButton-Secondary-Collapse"   -- a minus
local EXPAND_ATLAS   = "UI-QuestTrackerButton-Secondary-Expand"     -- a plus
local GLYPH_SIZE, GLYPH_ALPHA, GLYPH_OFFSET_X = 16, 0.75, -2
local FONTSIZE_TEXTBOX, TEXT_INSET = 12, 4
local POPUP_RELOAD = "PGFE_EUI_SKIN_RELOAD"

EUISkin.SHELL_HEADER_H = SHELL_HEADER_H
EUISkin.SHELL_GAP      = SHELL_GAP
EUISkin.POPUP_RELOAD   = POPUP_RELOAD

local S             -- the facade, once EllesmereUI has called back
local applied = false
local lastSkip      -- the last skip reason logged: a panel re-show repeats it, the log does not
local checkBoxes, textBoxes = {}, {}
local accentBorders = setmetatable({}, { __mode = "k" })

local function stoodDown() return NS.IsStoodDown() end

-- Template parentKeys are tables in the client; anything else is a template that changed shape.
local function isTable(v) return type(v) == "table" end

local function switchOn()
    local db = NS.addon.db
    return db ~= nil and db.profile ~= nil and db.profile.euiSkin == true
end

--- Our switch is on and every gate condition holds (whether or not S has arrived).
function EUISkin.IsWanted() return switchOn() and (NS.EUIBridge.GateOpen()) end
function EUISkin.IsApplied() return applied end
function EUISkin.HasFacade() return S ~= nil end

-- ── checkboxes (PremadeGroupsFilter_EllesmereUI Skin.lua, adapted) ───────────────────────────────

-- UICheckButtonTemplate is 32px; the skin's box is drawn CHECKBOX_BORDER_INSET in from the frame,
-- so the frame shrinks to 24 for a 16px box. A TOP-anchored row box moves down by half what it
-- loses, so it stays centered on its row. Its label is pinned to the body, so the box's right edge
-- moved away from it: the hit rect stretches by what was lost. The Smart box's label rides the box
-- (`labelOnBox`), so its hit rect stays.
local function shrinkCheckBox(cb, labelOnBox)
    local size = cb:GetHeight()
    if type(size) ~= "number" or size <= CHECKBOX_SIZE then return end
    local lost = size - CHECKBOX_SIZE
    local point, rel, relPoint, x, y = cb:GetPoint(1)
    cb:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    if point and point:find("TOP", 1, true) then
        cb:ClearAllPoints()
        if rel then cb:SetPoint(point, rel, relPoint, x, y - lost / 2)
        else cb:SetPoint(point, x, y - lost / 2) end
    end
    if not labelOnBox then
        local l, r, t, b = cb:GetHitRectInsets()
        if type(r) == "number" then cb:SetHitRectInsets(l, r - lost, t, b) end
    end
end

local EDGES = {
    { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
    { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false },
}

-- The accent ring shown while a box is checked: four strips on a frame above the skin's border.
local function createAccentBorder(cb)
    local border = CreateFrame("Frame", nil, cb)
    border:SetPoint("TOPLEFT", CHECKBOX_BORDER_INSET, -CHECKBOX_BORDER_INSET)
    border:SetPoint("BOTTOMRIGHT", -CHECKBOX_BORDER_INSET, CHECKBOX_BORDER_INSET)
    local level = cb:GetFrameLevel()
    if type(level) == "number" then border:SetFrameLevel(level + ACCENT_BORDER_LEVEL) end
    border:Hide()
    border.edges = {}
    for i, e in ipairs(EDGES) do
        local t = border:CreateTexture(nil, "OVERLAY")
        t:SetPoint(e[1])
        t:SetPoint(e[2])
        t.isHorizontal = e[3]
        border.edges[i] = t
    end
    return border
end

local function updateAccentBorder(cb)
    local border = accentBorders[cb]
    if border then border:SetShown(cb:GetChecked() and true or false) end
end

-- The hooks' body: nothing while stood down (the stand-up's refresh re-runs SetChecked).
local function onCheckChanged(cb)
    if stoodDown() then return end
    updateAccentBorder(cb)
end

-- The size nearest `want` covering whole physical pixels, with the box's parity, so the block sits
-- centered at any UI scale.
local function centeredSize(region, boxSize, want)
    local upp, scale = PixelUtil.GetPixelToUIUnitFactor(), region:GetEffectiveScale()
    if type(scale) ~= "number" or scale <= 0 or type(upp) ~= "number" or upp <= 0 then return want end
    local boxPx, markPx = Round(boxSize * scale / upp), Round(want * scale / upp)
    if markPx % 2 ~= boxPx % 2 then markPx = markPx - 1 end
    return math.max(markPx, 1) * upp / scale
end

local function layoutAccentMark(cb)
    local border = accentBorders[cb]
    if border then
        for _, t in ipairs(border.edges) do
            if t.isHorizontal then PixelUtil.SetHeight(t, ACCENT_BORDER_SIZE, ACCENT_BORDER_SIZE)
            else PixelUtil.SetWidth(t, ACCENT_BORDER_SIZE, ACCENT_BORDER_SIZE) end
        end
    end
    local mark = cb:GetCheckedTexture()
    if mark then
        mark:ClearAllPoints()
        mark:SetPoint("CENTER")
        local size = centeredSize(mark, ACCENT_BOX_SIZE, ACCENT_MARK_SIZE)
        mark:SetSize(size, size)
    end
end

local function paintAccentMark(cb)
    local r, g, b = S.GetAccentColor()
    local mark = cb:GetCheckedTexture()
    if mark then
        mark:SetVertexColor(1, 1, 1, 1)
        mark:SetColorTexture(r, g, b, 1)
    end
    local border = accentBorders[cb]
    if border then
        for _, t in ipairs(border.edges) do t:SetColorTexture(r, g, b, 1) end
    end
end

local function skinCheckBox(cb, labelOnBox)
    if not cb then return 0 end
    shrinkCheckBox(cb, labelOnBox)
    S.Checkbox(cb, { borderInset = CHECKBOX_BORDER_INSET })
    checkBoxes[#checkBoxes + 1] = cb
    accentBorders[cb] = createAccentBorder(cb)
    layoutAccentMark(cb)
    paintAccentMark(cb)
    -- A click toggles the state without calling SetChecked; Panel.Refresh calls SetChecked.
    cb:HookScript("OnClick", onCheckChanged)
    hooksecurefunc(cb, "SetChecked", onCheckChanged)
    updateAccentBorder(cb)
    return 1
end

-- ── inputs, dropdowns, buttons ──────────────────────────────────────────────────────────────────

local function applyTextBoxFont(box)
    local path, flag = S.GetFont()
    if path then box:SetFont(path, FONTSIZE_TEXTBOX, flag or "") end
end

-- No padInput: the copy box is anchored TOPRIGHT, and EllesmereUI's input padding would pull it
-- 3px off the right column. S.EditBox and S.Font never set a text color, so the grayed locked
-- level box and the dimmed copy box keep their gray.
local function skinEditBox(box)
    if not box then return 0 end
    S.EditBox(box)
    S.Font(box)
    applyTextBoxFont(box)
    box:SetTextInsets(TEXT_INSET, 0, 0, 0)
    textBoxes[#textBoxes + 1] = box
    return 1
end

-- A modern DropdownButton is itself the box: S.Dropdown fades its art and draws the flat box,
-- border, hover and arrow over the button. The menus it opens are EllesmereUI's to skin.
local function skinDropdown(dd)
    if not dd then return 0 end
    S.Dropdown(dd)
    if isTable(dd.Text) then S.Font(dd.Text) end
    return 1
end

-- The label keeps Blizzard's font (EllesmereUI's own policy); StateButtonLabel colors it white
-- enabled and gray disabled, which Save, Delete and Apply rely on.
local function skinButton(b)
    if not b then return 0 end
    S.Button(b)
    S.StateButtonLabel(b)
    return 1
end

-- The min/max arrows become EllesmereUI's minus and plus: the state art goes to alpha 0 and a
-- desaturated glyph is drawn over it, brightening on hover. Which button shows, and what a click
-- does, stay the template's. A missing atlas keeps the arrow.
local function skinMinMaxButton(b, atlas)
    if not isTable(b) or not (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)) then return 0 end
    S.FadeRegions(b)
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }) do
        local t = b[getter] and b[getter](b)
        if t then t:SetAlpha(0) end
    end
    local glyph = b:CreateTexture(nil, "OVERLAY")
    glyph:SetAtlas(atlas, false)
    glyph:SetSize(GLYPH_SIZE, GLYPH_SIZE)
    glyph:SetPoint("CENTER", GLYPH_OFFSET_X, 0)
    glyph:SetDesaturated(true)
    glyph:SetVertexColor(1, 1, 1, GLYPH_ALPHA)
    b:HookScript("OnEnter", function()
        if stoodDown() then return end
        glyph:SetVertexColor(1, 1, 1, 1)
    end)
    b:HookScript("OnLeave", function()
        if stoodDown() then return end
        glyph:SetVertexColor(1, 1, 1, GLYPH_ALPHA)
    end)
    b.pgfeGlyph = glyph
    return 1
end

-- The theme font on every font string of `frame`, keeping its size and color.
local function fontRegions(frame)
    local n = 0
    for _, r in ipairs({ frame:GetRegions() }) do
        if r.IsObjectType and r:IsObjectType("FontString") then
            S.Font(r)
            n = n + 1
        end
    end
    return n
end

-- ── the panel ───────────────────────────────────────────────────────────────────────────────────

local function paintShell(f)
    S.Shell(f)
    if isTable(f.NineSlice) then S.FadeNineSlice(f.NineSlice) end
    local pc = f.PortraitContainer
    if isTable(pc) and isTable(pc.portrait) then pc.portrait:SetAlpha(0) end
    -- The clipped metal header copies are child frames, which Shell's fade never reaches, and the
    -- collapse shows them: alpha 0 survives every SetShown.
    for _, clip in ipairs(f.headerArt or {}) do clip:SetAlpha(0) end
    local tc = f.TitleContainer
    local title = isTable(tc) and tc.TitleText
    if isTable(title) then
        S.Font(title)
        S.White(title)
    end
    f.headerHeight = SHELL_HEADER_H                 -- read by Panel's applyLayout
    -- The metal border overhung the frame, so the panel sat raised into PGF's dialog. Both flat
    -- shells sit on their frame rects, so 0 is flush, as the metal look is (owner request).
    local dialog = f:GetParent()
    if dialog then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", dialog, "BOTTOMLEFT", 0, -SHELL_GAP)
        f:SetPoint("TOPRIGHT", dialog, "BOTTOMRIGHT", 0, -SHELL_GAP)
    end
    local mm = f.MaximizeMinimizeFrame
    local n = 1
    if isTable(mm) then          -- expanded shows MinimizeButton (Panel's syncMinMax): collapse = minus
        n = n + skinMinMaxButton(mm.MinimizeButton, COLLAPSE_ATLAS)
        n = n + skinMinMaxButton(mm.MaximizeButton, EXPAND_ATLAS)
    end
    return n
end

local function paintBody(f)
    local n = skinCheckBox(f.activeCheck, false)
    for key, cb in pairs(f.checks or {}) do n = n + skinCheckBox(cb, key == "smartKeyLevel") end
    for _, box in ipairs({ f.levelBox, f.ageBox, f.rangeBox }) do n = n + skinEditBox(box) end
    for _, dd in ipairs({ f.regionSelect, f.playstyleSelect, f.compositionSelect, f.presetDropdown }) do
        n = n + skinDropdown(dd)
    end
    for _, b in ipairs({ f.saveButton, f.saveAsButton, f.deleteButton, f.applyButton, f.clearButton }) do
        n = n + skinButton(b)
    end
    n = n + fontRegions(f) + fontRegions(f.body)
    return n
end

-- Why the paint does not happen now, or nil when it can.
local function blocked()
    if stoodDown() then return "stood down" end
    if not S then return "EllesmereUI has not called back (a condition was off at login)" end
    if not switchOn() then return "switch off" end
    local open, failing = NS.EUIBridge.GateOpen()
    if not open then return "condition '" .. tostring(failing) .. "' not met" end
    if not (NS.Panel and NS.Panel.frame) then return "panel not built yet" end
    return nil
end

--- Paint the panel when every condition holds. Idempotent; one-way. Called from the EllesmereUI
--- callback, Panel.Create, every panel show (Panel.UpdateVisibility), the switch, a profile switch
--- and the stand-up; cheap when it refuses.
--- @return boolean painted  true only on the call that painted
function EUISkin.TryApply()
    if applied then return false end
    local why = blocked()
    if why then
        if why ~= lastSkip then NS.Debug(TAG, "skipped: %s", why) end
        lastSkip = why
        return false
    end
    applied = true
    local f = NS.Panel.frame
    local n = paintShell(f) + paintBody(f)
    NS.Panel.Refresh()          -- re-runs applyLayout (header height) and SetChecked (accent rings)
    NS.Debug(TAG, "applied: %d widgets", n)
    return true
end

--- The euiSkin switch's onChange. On paints now (when S is held); off after a paint asks for a
--- reload, since a skin cannot be taken off live.
function EUISkin.OnSwitch(on)
    if on then
        EUISkin.TryApply()
    elseif applied then
        StaticPopup_Show(POPUP_RELOAD)
    end
end

-- Re-read the getters' colors and font after a live theme change (S.OnLooksChanged).
local function repaintLooks()
    if stoodDown() or not S then return end
    for _, box in ipairs(textBoxes) do applyTextBoxFont(box) end
    for _, cb in ipairs(checkBoxes) do
        paintAccentMark(cb)
        updateAccentBorder(cb)
    end
end

local function relayout()
    for _, cb in ipairs(checkBoxes) do layoutAccentMark(cb) end
end

-- The accent ring and block are sized in whole pixels: re-laid out after a scale change.
function NS.addon.OnEUISkinScale()
    if stoodDown() then return end
    relayout()
end

NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "UI_SCALE_CHANGED", "OnEUISkinScale" }
NS.FEATURE_EVENTS[#NS.FEATURE_EVENTS + 1] = { "DISPLAY_SIZE_CHANGED", "OnEUISkinScale" }
-- On the way back up: a paint that waited out a stand-down happens now, and an existing paint
-- catches up on any theme or scale change its guarded handlers ignored while it was down.
NS.STAND_UP[#NS.STAND_UP + 1] = function()
    if EUISkin.TryApply() or not applied then return end
    repaintLooks()
    relayout()
end

StaticPopupDialogs[POPUP_RELOAD] = {
    text = L["The EllesmereUI skin comes off after a reload. Reload the UI now?"],
    button1 = L["Reload"], button2 = L["Later"],
    OnAccept = function() C_UI.Reload() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- EllesmereUI's callback: keep S, follow live theme changes, and paint if everything holds.
-- EllesmereUI pcalls it. RegisterSkin cannot be undone, so the body never paints while stood
-- down (TryApply refuses; the stand-up retries).
local function onFacade(facade)
    S = facade
    if type(S.OnLooksChanged) == "function" then S.OnLooksChanged(repaintLooks) end
    NS.Debug(TAG, "EllesmereUI called back (apiVersion %s)", tostring(S.apiVersion))
    EUISkin.TryApply()
end

if type(EllesmereUI) == "table" and type(EllesmereUI.RegisterSkin) == "function" then
    EllesmereUI.RegisterSkin(NS.EUIBridge.SKIN_NAME, onFacade)
    EUISkin.registered = true
end
