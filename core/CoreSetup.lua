local addonName, NS = ...
-- core/CoreSetup.lua — NS.Print from LibKa0s-Core-1.0; every tagged chat line leaves through here.
--
-- A descriptor and a degradation stub, nothing else (library-stack-§7). First in # Core: every
-- later file captures the printer at load. NS.PREFIX is defined in core/PGFE.lua, which loads
-- later, so the prefix is handed over as a FUNCTION the library re-reads on every call.

-- The one cause clause every degraded seam appends its own "so <what> is unavailable" to, already
-- localized (locales/enUS.lua loads first). Each seam wraps it in its own whole-sentence key.
NS.LIBKA0S_MISSING = NS.L["The LibKa0s library is missing from this installation of %s (expected in libs/LibKa0s)"]
    :format("Ka0s Premade Groups Filter Extension")

NS.Util = NS.Util or {}

-- The HOST owns the rejected-event list (events-frames-taint-§1); the [Init] summary and the
-- diagnostics report surface it.
NS.rejectedEvents = NS.rejectedEvents or {}

local lib = LibStub and LibStub("LibKa0s-Core-1.0", true)

if not lib then
    -- Degrade, never error. The printer works (short pre-library fallback) and says "not
    -- installed" ONCE, on the first line printed.
    local function probeConcat(v) return table.concat({ v }) end
    function NS.IsConcatSafe(v) return (pcall(probeConcat, v)) end
    function NS.SafeToString(v)
        if v == nil then return "nil" end
        if type(v) == "boolean" then return tostring(v) end
        if NS.IsConcatSafe(v) then return tostring(v) end
        return "<secret>"
    end

    local announced = false
    function NS.Util.print(...)
        if not announced then
            announced = true
            print(NS.PREFIX, NS.L["%s; running on reduced built-in fallbacks."]:format(NS.LIBKA0S_MISSING))
        end
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = NS.SafeToString((select(i, ...))) end
        print(NS.PREFIX, table.concat(parts, " "))
    end
    NS.Print = NS.Util.print

    -- The chrome degrades to NOTHING rather than to a hand-copied backdrop (standalone-windows).
    NS.SKIN            = {}
    NS.ApplySkin       = function() end
    NS.MakeCloseButton = function() return nil end

    -- The SafeRegister* family as ONE-RUNG pcall bodies (events-frames-taint-§1).
    local function reject(rejected, event)
        if type(rejected) ~= "table" then return end
        for i = 1, #rejected do if rejected[i] == event then return end end
        rejected[#rejected + 1] = event
    end
    NS.SafeRegisterEvent = function(target, event, handler, rejected)
        local ok = pcall(target.RegisterEvent, target, event, handler)
        if not ok then reject(rejected, event) end
        return ok
    end
    NS.SafeRegisterUnitEvent = function(frame, event, rejected, unit1, unit2)
        local ok = pcall(frame.RegisterUnitEvent, frame, event, unit1, unit2)
        if not ok then reject(rejected, event) end
        return ok
    end
    NS.SafeRegisterEvents = function(target, events, handler, rejected)
        local n = 0
        for _, event in ipairs(events) do
            if NS.SafeRegisterEvent(target, event, handler, rejected) then n = n + 1 end
        end
        return n
    end
    return
end

NS.IsConcatSafe, NS.SafeToString = lib.IsConcatSafe, lib.SafeToString

NS.SafeRegisterEvent     = lib.SafeRegisterEvent
NS.SafeRegisterUnitEvent = lib.SafeRegisterUnitEvent
NS.SafeRegisterEvents    = lib.SafeRegisterEvents

NS.SKIN      = lib.SKIN
NS.ApplySkin = lib.ApplySkin

-- WRAPPED, TO SAY WHO IS ASKING (standalone-windows, a MUST). Every close control in the addon is
-- built through here, because a two-argument call to the factory silently draws the fallback glyph.
NS.MakeCloseButton = function(parent, onClick)
    return lib.MakeCloseButton(parent, onClick, addonName)
end

-- `sink` is the Lua global print so the headless harness captures every chat line.
local printer = lib:New({
    prefix = function() return NS.PREFIX end,
    sink   = function(line) print(line) end,
})

-- NS.Print and NS.Util.print MUST be the SAME function object: AceAddon:NewAddon(NS, ...,
-- "AceConsole-3.0") stamps AceConsole's :Print over NS.Print, and core/PGFE.lua reclaims it by
-- repointing NS.Print at NS.Util.print (architecture-§2, anti-pattern #36).
NS.Print = printer.Print
NS.Util.print = NS.Print
