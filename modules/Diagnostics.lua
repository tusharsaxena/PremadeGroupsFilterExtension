local _, NS = ...
-- modules/Diagnostics.lua — the addon's sections of `/pgfe diagnostics` (debug-logging-§14).
--
-- Sections only: the markers, the identity header's library half, the per-section pcall, the cap
-- and the Add loop are LibKa0s-DebugLog-1.0's. Every section READS state and never acts: no hold,
-- no event, no timer, safe in combat and while stood down. `out:add` formats %s-only and runs every
-- argument through safeToString, so raw values are passed, never pre-built strings.

NS.Diagnostics = NS.Diagnostics or {}

local TAG = "Diag"

local function stoodDown() return NS.IsStoodDown and NS.IsStoodDown() or false end

local function read(fn, ...)
    if type(fn) ~= "function" then return "unavailable" end
    local ok, v = pcall(fn, ...)
    if not ok then return "unreadable" end
    return v
end

local function identity(out)
    local db = NS.addon and NS.addon.db
    local LC = NS.Lifecycle
    out:add(TAG, "schema stored=%s code=%s", db and db.global and db.global.schemaVersion,
        NS.SCHEMA_VERSION)
    out:add(TAG, "profile=%s", db and db.GetCurrentProfile and db:GetCurrentProfile())
    out:add(TAG, "enabled=%s stoodDown=%s", db and db.profile and db.profile.enabled, stoodDown())
    out:joined(TAG, "holds", LC and LC.Holds and LC:Holds() or {})
end

local function settings(out)
    local S = NS.SchemaRuntime
    local Settings = NS.addon and NS.addon.Settings
    out:nonDefaults(Settings and Settings.Schema, function(row) return S.Get(row.path) end, nil, nil,
        { always = { "enabled" } })
end

-- The character's filter options (char.filters). Scalars as one sorted `key=value` list; each set
-- (regions, playstyles) as its sorted keys, and an empty set reads Any, as the panel shows it.
-- table.insert rather than t[#t + 1] in the one-line ifs below: lizard 1.24 loses both functions
-- on the latter and leaves them unmeasured.
local function setKeys(set)
    local keys = {}
    for k, on in pairs(set) do
        if on then table.insert(keys, tostring(k)) end
    end
    table.sort(keys)
    if keys[1] == nil then keys[1] = "Any" end
    return keys
end

local function filters(out)
    local f = read(NS.Filters and NS.Filters.Get)
    if type(f) ~= "table" then return out:add(TAG, "filters %s", f) end
    local scalars, sets = {}, {}
    for k, v in pairs(f) do
        table.insert(type(v) == "table" and sets or scalars, k)
    end
    table.sort(scalars); table.sort(sets)
    for i, k in ipairs(scalars) do scalars[i] = ("%s=%s"):format(tostring(k), tostring(f[k])) end
    out:joined(TAG, "filters", scalars)
    for _, k in ipairs(sets) do out:joined(TAG, k, setKeys(f[k])) end
end

-- Which of the addon's hooks actually went in: each module stores its install result at load.
local function hooks(out)
    local E, P, R = NS.EnvInject, NS.Panel, NS.RegionTags
    local rows = R and R.hooked or {}
    out:add(TAG, "hooks: env=%s dialog=%s searchRow=%s applicantRow=%s",
        E and E.hooked == true or false, P and P.dialogHooked == true or false,
        rows.LFGListSearchEntry_Update == true, rows.LFGListApplicationViewer_UpdateApplicantMember == true)
end

-- The two addons this one reads: PGF is a hard dependency, PremadeRegions optional.
local function dependencies(out)
    out:add(TAG, "PremadeGroupsFilter namespace=%s dialog=%s dungeonPanel=%s",
        _G.PremadeGroupsFilter ~= nil, _G.PremadeGroupsFilterDialog ~= nil,
        _G.PremadeGroupsFilterDungeonPanel ~= nil)
    -- Bridge.Check walks the seams this addon reads and calls no PGF function.
    local ok, missing = NS.Bridge.Check()
    out:add(TAG, "PGF seams ok=%s missing=%s", ok, missing or "none")
    hooks(out)
    out:add(TAG, "PremadeRegions loaded=%s", _G.PremadeRegions ~= nil)
    -- The optional EllesmereUI skin: its four gate conditions, our switch, and what happened.
    local B, K = NS.EUIBridge, NS.EUISkin
    if B then
        out:add(TAG, "EllesmereUI suite=%s master=%s ownEntry=%s pgfSkin=%s", read(B.IsSuiteReady),
            read(B.IsMasterOn), read(B.IsEntryOn, B.SKIN_NAME), read(B.IsPGFSkinOn))
    end
    if K then
        out:add(TAG, "EllesmereUI skin: registered=%s facade=%s wanted=%s applied=%s", K.registered == true,
            read(K.HasFacade), read(K.IsWanted), read(K.IsApplied))
    end
end

local function registration(out)
    local names = {}
    for i, row in ipairs(NS.FEATURE_EVENTS or {}) do names[i] = row[1] end
    out:joined(TAG, "feature events (declared)", names)
    -- Stood down, the latch has unregistered them; the declared list is printed either way.
    out:add(TAG, "feature events registered=%s", not stoodDown())
    out:list(TAG, "rejected events", NS.rejectedEvents or {})
end

local function launcher(out)
    local L = NS.Launcher
    out:add(TAG, "launcher: registered=%s shown=%s", L and read(L.IsRegistered, L),
        L and read(L.IsShown, L))
end

function NS.Diagnostics.Sections()
    return {
        { "identity",     identity },
        { "settings",     settings },
        { "filters",      filters },
        { "dependencies", dependencies },
        { "registration", registration },
        { "launcher",     launcher },
    }
end
