local addonName, NS = ...
-- core/WidgetsSetup.lua — NS.MakeDropdown / NS.CloseMenu from LibKa0s-Widgets-1.0: the attached
-- panel's flat dropdowns and the skinned menu they drop (cause A2 of Ka0sAddonsCommonTasks
-- docs/2026-11-01-FULL_SKINNING/).
--
-- A seam, nothing else (library-stack-§7). The factory names this addon's folder as the widget's
-- skin `owner`, so the library paints the button and the menu for the owner core/SkinSetup.lua
-- registered and follows a switch, and draws the owner's tinted chevron-down and confirm marks
-- (CLAUDE.md's `LibKa0s icons:` line keeps both). No glyph face: no option here carries a glyph.
--
-- THE POPUP IS A PROCESS-WIDE SINGLETON parented to UIParent, so hiding the panel does not reach
-- it. Every non-click close path calls NS.CloseMenu(): the panel's OnHide (which the stand-down
-- runs) and the collapse, which hides the row the menu dropped from.
--
-- DEGRADED (the library absent): NS.MakeDropdown answers nil and modules/Panel.lua builds the
-- client's WowStyle1DropdownTemplate instead, because the filters are unusable without their
-- lists. NS.CloseMenu is a no-op: there is no menu of ours that could be open.

local W = LibStub and LibStub("LibKa0s-Widgets-1.0", true)

--- One flat dropdown, or nil when the library is absent.
--- @param parent table the frame to parent it to
--- @param width number the collapsed button's width
--- @return table|nil
function NS.MakeDropdown(parent, width)
    if not W then return nil end
    return W.Dropdown(parent, width, { owner = addonName })
end

--- Close the shared popup menu, if one is open. Safe when none ever opened.
function NS.CloseMenu()
    if W then W.CloseMenu() end
end
