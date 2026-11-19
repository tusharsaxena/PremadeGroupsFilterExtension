local addonName, NS = ...
-- core/WidgetsSetup.lua — NS.MakeDropdown / NS.CloseMenu from LibKa0s-Widgets-1.0: the attached
-- panel's flat dropdowns and the skinned menu they drop (cause A2 of Ka0sAddonsCommonTasks
-- docs/2026-11-01-FULL_SKINNING/).
--
-- A seam, nothing else (library-stack-§7). The factory names this addon's folder as the widget's
-- skin `owner`, so the library paints the button and the menu for the owner core/SkinSetup.lua
-- registered and follows a switch, and draws the owner's tinted confirm mark (CLAUDE.md's
-- `LibKa0s icons:` line keeps it). The arrow's art is the caller's: it tints what it is handed.
-- No glyph face: no option here carries a glyph.
--
-- THE POPUP IS A PROCESS-WIDE SINGLETON parented to UIParent, so hiding the panel does not reach
-- it. Every non-click close path calls NS.CloseMenu(): the panel's OnHide (which the stand-down
-- runs) and the collapse, which hides the row the menu dropped from.
--
-- DEGRADED (the library absent): NS.MakeDropdown answers nil and modules/Panel.lua builds the
-- client's WowStyle1DropdownTemplate instead, because the filters are unusable without their
-- lists. NS.CloseMenu is a no-op: there is no menu of ours that could be open.
--
-- NS.HeaderButtons (LibKa0s#86, standalone-windows *Title-bar controls*): the panel's title-bar marks
-- through W.HeaderButtons, with this addon's folder as the owner, so the settings mark opens the
-- opener core/LauncherSetup.lua registered under the same name. DEGRADED, the window's own extras
-- only, each a plain button wearing its glyph with its tooltip above it, and no settings mark: the
-- settings panel is the library's too (settings/Slash.lua says so in chat). NS.HEADER is the strip's
-- geometry, the library's figures or the same numbers without it.

local W = LibStub and LibStub("LibKa0s-Widgets-1.0", true)

--- One flat dropdown, or nil when the library is absent.
--- @param parent table the frame to parent it to
--- @param width number the collapsed button's width
--- @param chevron string the arrow's art, a resolved path
--- @return table|nil
function NS.MakeDropdown(parent, width, chevron)
    if not W then return nil end
    return W.Dropdown(parent, width, { owner = addonName, chevron = chevron })
end

--- Close the shared popup menu, if one is open. Safe when none ever opened.
function NS.CloseMenu()
    if W then W.CloseMenu() end
end

NS.HEADER = W and W.HEADER or { SIZE = 18, ART = 12, PAD = 6, GAP = 6 }

-- Degraded: the tooltip above the mark by a relative point, read from `btn.__tip` on each hover.
local function fallbackTip(btn)
    btn:SetScript("OnEnter", function(self)
        local words = self.__tip
        if type(words) ~= "string" or words == "" or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetText(words, nil, nil, nil, nil, true)
        GameTooltip:Show()
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 2)
    end)
    btn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

-- Degraded: `spec.extras` as glyph buttons, answered in W.HeaderButtons' shape (extras, order,
-- offsets, right), anchored nothing (the caller places them, as `place = false` asks).
local function fallbackButtons(bar, spec)
    local H = NS.HEADER
    local hb = { extras = {}, order = {}, offsets = {}, right = {} }
    local extras = type(spec.extras) == "table" and spec.extras or {}
    local off = H.PAD
    for i = #extras, 1, -1 do
        local x = extras[i]
        local b = CreateFrame("Button", nil, bar)
        b:SetSize(H.SIZE, H.SIZE)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("CENTER")
        fs:SetText(x.glyph or "")
        b.label, b.__tip = fs, x.tip
        fallbackTip(b)
        local onClick = x.onClick
        b:SetScript("OnClick", function(self, button) if onClick then onClick(self, button) end end)
        hb.extras[x.key] = b
        hb.offsets[x.key] = -off
        hb.right[#hb.right + 1] = { frame = b, x = off }
        off = off + H.SIZE + H.GAP
    end
    for i = 1, #extras do hb.order[i] = extras[i].key end
    if type(spec.frame) == "table" then spec.frame.headerButtons = hb end
    return hb
end

--- The title-bar mark strip on `bar`: W.HeaderButtons with this addon as the owner, else the
--- degraded extras above.
--- @param bar table the frame the marks are parented to
--- @param spec table W.HeaderButtons' spec, without `owner`
--- @return table hb  { settings, close, extras = { [key] = btn }, order, offsets, right }
function NS.HeaderButtons(bar, spec)
    spec.owner = addonName
    if W and W.HeaderButtons then return W.HeaderButtons(bar, spec) end
    return fallbackButtons(bar, spec)
end
