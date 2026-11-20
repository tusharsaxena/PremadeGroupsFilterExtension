-- tests/skin_surfaces.lua — the consumer facts of the kit's skin-switch test (skinning-§1, kit
-- revision 50), kept out of tests/run.lua for their length. Not a suite: the kit's inventory reads
-- test_*.lua only.
--
-- Every surface this addon paints itself: the attached panel under PGF's dialog, its menu and
-- tooltips, and the region tag on Blizzard's rows. Each answers the narrowest object that draws it,
-- because the spy also reads an object's regions and children, and a whole frame would pass on any
-- child's change. The panel is a window, so it keeps the skin under Ignore settings panel (D-01) and
-- no surface here takes `scope`. The Skin tab, the Region tags tab and the Launcher tooltip are the
-- library's, which runs this test over its own surfaces.
--
-- Kit revision 58 (SD-SK-PGFE): each family a surface draws moves on its own. The addon creates no
-- StatusBar and no data fill, so no surface takes `clear` and no ruling holds a family; the window's
-- bands and edge carry the skin's art (S.Shell's bands), so that surface takes `expect = "texture"`
-- and a band that stops following its skin's art fails even while its tint moves. The Region tags
-- tab's preview line (settings/Panel.lua renderRegionTab, an O.TextRow) is not declared: the kit's
-- AceGUI widgets are data recorders with no FontString to spy, so the line's face is the library's
-- to guard (OptionsWidgets applyLabelFont, under its own skin-switch suite), and its color is the
-- region hues, a meaning color (skinning-§9).
--
-- One instance, used by this file alone: the skin's choice is process state of that instance's
-- mock, and the test puts it back after every surface.

return function(enableAddon)
    local NS, _, m = enableAddon()
    m.currentRegion = 1
    m.pgf.dialog.shown = true
    NS.Panel.UpdateVisibility()
    local f = NS.Panel.frame

    local function bodyLabel(text)
        for _, r in ipairs({ f.body:GetRegions() }) do
            if r.__objType == "FontString" and r:GetText() == text then return r end
        end
    end

    --- Only `frame`'s own regions, not the children the other surfaces declare one by one.
    local function ownRegions(frame)
        return { GetRegions = function() return frame:GetRegions() end }
    end

    --- A surface GameTooltip draws, `draw` being what fills it.
    local function tooltip(name, draw)
        return { name = name, build = function() return m.GameTooltip end, paint = draw }
    end

    local function surface(name, object, paint)
        return { name = name, build = function() return object end, paint = paint }
    end

    local function refresh() NS.Panel.Refresh() end

    local tagged = { text = "X", GetText = function(self) return self.text end,
                     SetText = function(self, t) self.text = t end }
    m.searchResults[1] = { leaderName = "Bob-Nowhere" }
    local function drawTag()
        tagged.text = "X"
        m.LFGListSearchEntry_Update({ resultID = 1, ActivityName = tagged })
    end

    local anyRow = f.regionSelect._options[1]
    local entryRow = f.regionSelect._options[3]
    local rowFrame = m.CreateFrame("Button")

    return {
        owner = "PremadeGroupsFilterExtension",
        skin  = function() return m.LibStub("LibKa0s-Skin-1.0") end,
        reset = function() m.GameTooltip:Hide() end,
        surfaces = {
            { name = "the window's bands and edge", build = function() return ownRegions(f) end, expect = "texture" },
            surface("the title", f.TitleContainer.TitleText),
            -- The title-bar marks are W.HeaderButtons' (LibKa0s#86): no box, the art alone.
            surface("the collapse mark's chevron", f.collapseMark.icon),
            surface("the settings mark", f.settingsMark.icon),
            surface("a check button", f.activeCheck),
            surface("a row's label", bodyLabel(NS.L.EXPERIENCED_LEADER)),
            surface("the locked level box", f.levelBox, refresh),
            surface("the open copy box", f.rangeBox, refresh),
            surface("the copy label", f.copyLabel, refresh),
            surface("the dungeon readout", f.readout, refresh),
            surface("the unsupported-portal note", f.regionsUnsupported),
            surface("the unsupported-PGF note", f.unsupported),
            surface("a dropdown's button", f.regionSelect),
            surface("the Presets dropdown's button", f.presetDropdown),
            surface("an action button", f.applyButton),
            -- SD-SK-PGFE (Ka0sAddonsCommonTasks docs/2026-11-20-SKIN_DEFAULTS_AUDIT, the guard
            -- coverage holes of tables/PremadeGroupsFilterExtension.md): the rest of what the panel
            -- paints through the same calls, each declared so a regression on one cannot hide.
            surface("the age box", f.ageBox, refresh),
            surface("the Smart label", f.smartLabel),
            surface("the 'minutes' label", bodyLabel(NS.L.MINUTES)),
            surface("the playstyle dropdown's button", f.playstyleSelect),
            surface("the composition dropdown's button", f.compositionSelect),
            surface("the Save button", f.saveButton),
            surface("the Save as button", f.saveAsButton),
            surface("the Delete button", f.deleteButton),
            surface("the Clear button", f.clearButton),
            tooltip("a panel tooltip's name and body", function() f.applyButton:__fire("OnEnter") end),
            tooltip("the Any row's tooltip", function() anyRow.tooltip(rowFrame, anyRow) end),
            tooltip("a menu entry's tooltip", function() entryRow.tooltip(rowFrame, entryRow) end),
            surface("the unknown realm's tag on a Blizzard row", tagged, drawTag),
        },
    }
end
