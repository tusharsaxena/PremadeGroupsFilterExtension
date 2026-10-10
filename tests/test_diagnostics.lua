-- tests/test_diagnostics.lua — the addon's `/pgfe diagnostics` sections report running state
-- (review C-10 / #7): the PGF seams Bridge.Check reads, which hooks actually went in, the filter
-- options, and whether the feature events are registered or only declared.
--
-- The `out` here captures lines the way the library's does (libs/LibKa0s/DebugLogDiagnostics.lua):
-- `add` stringifies every argument into a %s-only format, and `joined`/`list` write
-- `lead part, part`, or `lead -` for an empty list.

local T = _G.PGFE_TEST
local test, assertTrue = T.test, T.assertTrue

local function capture()
    local lines = {}
    local out = {}
    function out.add(_, _, fmt, ...)
        local args = { ... }
        for i = 1, select("#", ...) do args[i] = tostring(args[i]) end
        lines[#lines + 1] = (fmt:gsub("%%s", function() return table.remove(args, 1) end))
        return true
    end
    function out.joined(self, tag, lead, parts)
        if type(parts) ~= "table" or #parts == 0 then return self:add(tag, "%s -", lead) end
        local strs = {}
        for i = 1, #parts do strs[i] = tostring(parts[i]) end
        return self:add(tag, "%s %s", lead, table.concat(strs, ", "))
    end
    function out.list(self, tag, lead, items) return self:joined(tag, lead, items) end
    return out, lines
end

-- The text one section writes, as a single string.
local function section(NS, name)
    local out, lines = capture()
    for _, sec in ipairs(NS.Diagnostics.Sections()) do
        if sec[1] == name then sec[2](out) end
    end
    return table.concat(lines, "\n")
end

local function has(text, s) return text:find(s, 1, true) ~= nil end

-- red under: drop the Bridge.Check line from dependencies()
test("diagnostics: dependencies reports the PGF seams as present", function()
    local NS = T.enableAddon{}
    local text = section(NS, "dependencies")
    assertTrue(has(text, "PGF seams ok=true missing=none"), text)
end)

-- red under: drop the store at EnvInject:89 (EnvInject.hooked = NS.Bridge.InstallEnvHook(...))
test("diagnostics: dependencies reports every hook as installed", function()
    local NS = T.enableAddon{}
    local text = section(NS, "dependencies")
    assertTrue(has(text, "hooks: env=true dialog=true searchRow=true applicantRow=true"), text)
end)

-- red under: print `missing` as a constant "none" instead of Bridge.Check's second result
test("diagnostics: a missing PGF seam is named", function()
    local NS = T.enableAddon{ mock = function(m) m.pgf.PGF.PutPremadeRegionInfo = nil end }
    local text = section(NS, "dependencies")
    assertTrue(has(text, "PGF seams ok=false missing=PutPremadeRegionInfo"), text)
end)

-- red under: out:add the regions set as a raw value instead of its sorted keys
test("diagnostics: the filters section prints a set's keys, not a table", function()
    local NS = T.enableAddon{}
    NS.Filters.Get().regions = { oce = true }
    local text = section(NS, "filters")
    assertTrue(has(text, "oce"), text)
    assertTrue(not has(text, "table:"), text)
end)

-- red under: pass the empty set to out:joined as is (prints `regions -`)
test("diagnostics: an empty filter set reads Any", function()
    local NS = T.enableAddon{}
    NS.Filters.Get().playstyles = {}
    local text = section(NS, "filters")
    assertTrue(has(text, "playstyles Any"), text)
    assertTrue(has(text, "keyLevel=10"), text)
end)

-- red under: print `feature events registered=true` unconditionally
test("diagnostics: stood down, the feature events are declared but not registered", function()
    local NS = T.enableAddon{}
    NS.addon:OnSlashCommand("disable")
    local text = section(NS, "registration")
    assertTrue(has(text, "feature events registered=false"), text)
    assertTrue(has(text, "feature events (declared) "), text)
    NS.addon:OnSlashCommand("enable")
    assertTrue(has(section(NS, "registration"), "feature events registered=true"))
end)
