-- tests/panel_helpers.lua — what tests/test_panel.lua and tests/test_panel_layout.lua share. Not a
-- suite: the kit's inventory reads test_*.lua only.

local H = {}

function H.seasonFromScreenshot(m)
    m.mapTable = { 586, 587, 250, 585, 588, 399, 584, 249 }
    local best = { [586]=14, [587]=14, [250]=14, [585]=14, [588]=13, [399]=13, [584]=13, [249]=13 }
    for id, lvl in pairs(best) do
        m.mapUIInfo[id] = { name = "D" .. id, mapID = id }
        m.seasonBest[id] = { intime = { level = lvl } }
    end
end

-- A library dropdown's menu entries, as the row clicks reach them: every option entry in order as
-- { text, isOn, set, data }, the Any entry as `.any`. `set` does what a row's click does: the
-- library's ToggleSelected, then the host's onMultiSelect, the order Widgets.lua's rowOnClick runs.
local function flatEntries(dd)
    local entries = {}
    for _, opt in ipairs(dd._options) do
        local e = {
            text = opt.label, data = opt.value,
            isOn = function() return opt.isActive(dd) end,
            set = function()
                dd:ToggleSelected(opt.value)
                if dd.onMultiSelect then dd.onMultiSelect(dd._selected) end
            end,
        }
        if opt.value == "all" then entries.any = e else entries[#entries + 1] = e end
    end
    return entries
end

-- A dropdown's entries. The library's, or with the library absent, the client template's menu
-- generator run against a recording root: as { text, isOn, set, data, tooltip }, and the kinds in
-- build order as `.order` ("any", "divider", "entry").
function H.menuEntries(dd)
    if dd._options then return flatEntries(dd) end
    local entries = { order = {} }
    local root = {
        CreateCheckbox = function(_, text, isSelected, setSelected, data)
            local e = { text = text, isOn = isSelected, set = setSelected, data = data }
            e.SetTooltip = function(self, fn) self.tooltip = fn end
            if #entries.order == 0 and data == nil then
                entries.any = e; entries.order[1] = "any"
            else
                entries[#entries + 1] = e; entries.order[#entries.order + 1] = "entry"
            end
            return e
        end,
        CreateDivider = function() entries.order[#entries.order + 1] = "divider" end,
    }
    dd.__menuGen(dd, root)
    return entries
end

-- What a library dropdown's closed button reads.
function H.ddText(dd) return dd.text:GetText() end

-- Keystroke by keystroke, as the client fires OnTextChanged(userInput = true) per character.
function H.typeInto(box, text)
    for i = 1, #text do box.__text = text:sub(1, i); box:__fire("OnTextChanged", true) end
end

return H
