local addonName, NS = ...
-- core/LifecycleSetup.lua — the stand-down latch (slash-commands-§7), LibKa0s-Lifecycle-1.0.
--
-- ONE latch with two named holds: `disabled` (taken from the stored `enabled` path) and `perf`
-- (taken by the perf harness's suspend). Either hold stands the addon down through NS.StandDown;
-- releasing the last one stands it up through NS.StandUp (core/PGFE.lua). There is no second
-- teardown path.
--
-- THE STAND-DOWN ACCESSOR is NS.IsStoodDown(): every hook body and handler that cannot be
-- unregistered (hooksecurefunc has no un-hook) returns at once when it answers true.

local lib = LibStub and LibStub("LibKa0s-Lifecycle-1.0", true)

--- True while any hold is taken on the latch.
--- @return boolean
function NS.IsStoodDown()
    return NS.Lifecycle ~= nil and NS.Lifecycle:IsDown() == true
end

if not lib then
    local held, down = {}, false
    local function reevaluate()
        local anyHeld = next(held) ~= nil
        if anyHeld == down then return false end
        down = anyHeld
        if down then NS.StandDown() else NS.StandUp() end
        return true
    end
    NS.Lifecycle = {
        name    = addonName,
        Hold    = function(_, key) held[key] = true; return reevaluate() end,
        Release = function(_, key) held[key] = nil;  return reevaluate() end,
        Set     = function(self, key, on) if on then return self:Hold(key) end return self:Release(key) end,
        IsHeld  = function(_, key) return held[key] == true end,
        IsDown  = function() return down end,
        Holds   = function()
            local out = {}
            for k in pairs(held) do out[#out + 1] = k end
            table.sort(out)
            return out
        end,
        Reevaluate = function() return reevaluate() end,
        PrintHolds = function() return false end,
    }
    NS.HOLD_DISABLED = "disabled"
    NS.HOLD_PERF     = "perf"
    return
end

NS.HOLD_DISABLED = lib.HOLD_DISABLED
NS.HOLD_PERF     = lib.HOLD_PERF

NS.Lifecycle = lib:New({
    name      = addonName,
    standDown = function() NS.StandDown() end,
    standUp   = function() NS.StandUp() end,
    print     = function(line) NS.Print(line) end,
    debug     = function(tag, message) NS.Debug(tag, message) end,
})
