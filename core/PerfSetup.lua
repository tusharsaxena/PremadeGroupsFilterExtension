local addonName, NS = ...
-- core/PerfSetup.lua — NS.Perf from LibKa0s-Perf-1.0 (performance).
--
-- One instance at load, after core/LifecycleSetup.lua: the harness suspends the addon by taking the
-- latch's `perf` hold, so the perf arm and the disable arm share one teardown (NS.StandDown).
--
-- BUCKETS. None are declared yet, deliberately: a declared bucket no bracket reaches reads 0.000 in
-- every report (performance-§3). The first hot path is the per-search-result env hook
-- (modules/EnvInject.lua); its bucket `envInject` is declared in the same change that adds its
-- bracket, in the frozen idiom:
--     local t0 = Perf.on and debugprofilestop()
--     ...
--     if t0 then Perf.Note("envInject", debugprofilestop() - t0) end

local lib = LibStub and LibStub("LibKa0s-Perf-1.0", true)

if not lib then
    -- Degrade, never error: every member the addon calls, and an honest line from `/pgfe perf`.
    NS.Perf = {
        on        = false,
        suspended = false,
        Note      = function() end,
        OnCommand = function()
            return { NS.LIBKA0S_MISSING .. ", so performance measurement is unavailable." }
        end,
    }
    return
end

NS.Perf = lib:New({
    name      = addonName,
    title     = "Ka0s Premade Groups Filter Extension",
    slash     = "/pgfe",
    version   = NS.version,
    sv        = "PremadeGroupsFilterExtensionPerfDB",   -- declared in the TOC (toc-file-§2)
    lifecycle = NS.Lifecycle,
    buckets   = {},

    -- Not gated on the debug flag: a perf run is explicit user action.
    log     = function(line)
        if NS.DebugLog and NS.DebugLog.Add then NS.DebugLog:Add("Perf", line) else NS.Print(line) end
    end,
    print   = function(line) NS.Print(line) end,
    showLog = function()
        if NS.DebugLog and NS.DebugLog.Show and not NS.DebugLog:IsShown() then NS.DebugLog:Show() end
    end,
})
