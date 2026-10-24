local _, NS = ...
-- core/Popup.lua — NS.ShowPopup, the one StaticPopup_Show site of the addon.
--
-- Blizzard's StaticPopups are DIALOG; the attached panel layers with PGF's dialog, FULLSCREEN today.
-- A popup shown while the panel is visible would draw UNDER the panel and PGF's dialog wherever
-- they overlap, with the Save as edit box holding keyboard focus out of sight. So while the panel
-- is visible the popup frame is lifted to NS.Constants.LAYERS.STRATA.POPUP, one strata above it.
--
-- StaticPopupN frames are SHARED with Blizzard and every other addon, so a lift is put back: the
-- strata found on show is recorded (in a weak-keyed table of this file's, so no field is written
-- onto a Blizzard frame), and every PGFE popup spec carries
-- NS.RestorePopupStrata as its OnHide, which restores that recorded value (never a hard-coded
-- "DIALOG") — the lift-and-restore frame-layering-§4 allows for a borrowed shared frame.

local lifted = setmetatable({}, { __mode = "k" })   -- popup frame -> the strata found on show

local function panelVisible()
    local f = NS.Panel and NS.Panel.frame
    return type(f) == "table" and type(f.IsVisible) == "function" and f:IsVisible() == true
end

--- StaticPopup_Show, lifted over the attached panel while it is visible.
--- @return table|nil popup  the shown popup frame, as StaticPopup_Show returns it
function NS.ShowPopup(which, text1, text2, data)
    local popup = StaticPopup_Show(which, text1, text2, data)
    if type(popup) ~= "table" or not panelVisible() then return popup end
    if type(popup.GetFrameStrata) ~= "function" or type(popup.SetFrameStrata) ~= "function" then return popup end
    -- Shown again while already lifted: keep the strata recorded the first time.
    if lifted[popup] == nil then lifted[popup] = popup:GetFrameStrata() end
    popup:SetFrameStrata(NS.Constants.LAYERS.STRATA.POPUP)
    return popup
end

--- Every PGFE popup spec's OnHide: put a lifted frame back to the strata it had on show.
function NS.RestorePopupStrata(popup)
    if type(popup) ~= "table" then return end
    local was = lifted[popup]
    if was == nil then return end
    lifted[popup] = nil
    popup:SetFrameStrata(was)
end
