#!/usr/bin/env lua
-- tests/perf.lua — the offline performance scenarios (performance-§9's rules).
--
--   lua tests/perf.lua [--out <path>] [--label <text>]
--
-- OUTSIDE THE GREEN GATE: `lua tests/run.lua` never runs it, and no commit depends on it. It asserts
-- only deterministic quantities, API calls and bytes allocated per iteration, each measured loop
-- isolated by a full collect on either side with the collector stopped inside it. Timings are
-- printed for orientation only: compare scenarios within a run, never across runs or machines.
--
-- WHY THIS FILE EXISTS UNDER THE performance-§12 EXEMPTION. The addon holds the no-combat-path
-- exemption (`docs/ARCHITECTURE.md` -> `## Documented deviations`; the sweep is in
-- `docs/performance.md`): no `core/PerfSetup.lua`, no PerfDB, no `perf` verb, no suspend. That
-- exemption suspends §9 as a MUST, so shipping this file is a choice (the WhatGroup precedent).
-- Offline scenarios suspend nothing, ship nothing to the client and add no SavedVariable. They
-- measure exactly what the exemption rests on: the per-result env hook and the two row painters
-- are cheap, the stood-down hook is free, and an in-combat event costs a fixed, small number of
-- calls (`combatEvents`, the measured backing of criterion (a)). §9's zero-overhead scenario has no
-- subject here, because nothing is bracketed; `envStoodDown` takes its place on the hottest path.
--
-- WHAT "api" COUNTS: calls into the client's global functions and C_ namespaces listed in
-- API_GLOBALS / API_NAMESPACES below, plus GetText / SetText on the row font strings this file
-- builds. Widget calls on the addon's own panel frames are not counted; their cost shows in the
-- bytes. PGF's own work inside PutPremadeRegionInfo (including its PremadeRegions lookup) is PGF's,
-- not counted. Region lookups (`NS.Regions.GetRegion`) are counted separately as `lookups`.
--
-- CEILINGS (measured 2026-10-10, Lua 5.1.5). A byte ceiling is the measured figure rounded up plus
-- 24 bytes, smaller than one extra table per iteration (64 bytes here), so the smallest added
-- allocation trips it. `envStoodDown` is pinned hard at 0 bytes and 0 calls: the early return must
-- cost nothing. Call counts are pinned exactly. Raise one only by re-measuring and saying why; a
-- rise is the finding.
--
--   scenario           bytes/iter  ceiling  api/iter (pinned)
--   envNoPR                 80.1       105  1.2  (1 GetCurrentRegion; GetRealmName for 1 leader in 5)
--   envWithPR                0.0        24  0
--   envStoodDown             0.0         0  0
--   searchRowPaint         160.4       185  5.2  (2 GetCurrentRegion, 1 GetSearchResultInfo,
--                                                 1 GetText, 1 SetText; GetRealmName 1 in 5)
--   applicantRowPaint      160.4       185  5.2  (the same, GetApplicantMemberInfo for the read)
--   combatEvents         28161.1     28186  143  (one firing of each event; EVENT_API has the split)
--
-- envNoPR's 80 bytes and the row painters' 160 are the C-32 concat probe and nothing else:
-- LibKa0s's IsConcatSafe (`libs/LibKa0s/Core.lua:54`) builds a one-element table per call, once in
-- Regions.GetRegion and once more in RegionTags.Tag. combatEvents is dominated by the three
-- season-data events and PLAYER_ENTERING_WORLD, each rebuilding the panel's readout over the
-- eight dungeons (about 7 KB each).

local BYTE_CEILING = {
    envNoPR = 105, envWithPR = 24, envStoodDown = 0,
    searchRowPaint = 185, applicantRowPaint = 185, combatEvents = 28186,
}
local API_PER_ITER = {
    envNoPR = 1.2, envWithPR = 0, envStoodDown = 0,
    searchRowPaint = 5.2, applicantRowPaint = 5.2, combatEvents = 143,
}
-- combatEvents: the calls ONE firing of each event makes, with InCombatLockdown answering true.
-- The sweep in docs/performance.md names the work behind each figure.
local EVENT_API = {
    ACTIVE_PLAYER_SPECIALIZATION_CHANGED = 3,    -- RefreshPlayer: spec index, spec info, UnitClass
    PLAYER_SPECIALIZATION_CHANGED        = 3,    -- the same, for unit "player"
    CHALLENGE_MODE_MAPS_UPDATE           = 34,   -- Smart level + readout: 2 x (map table + 8 x 2)
    CHALLENGE_MODE_COMPLETED             = 34,   -- the same handler
    MYTHIC_PLUS_CURRENT_AFFIX_UPDATE     = 34,   -- the same handler
    PLAYER_ENTERING_WORLD                = 35,   -- re-arm the request, visibility, refresh
    UI_SCALE_CHANGED                     = 0,    -- the skin's relayout; returns before a paint
    DISPLAY_SIZE_CHANGED                 = 0,    -- the same handler
    PLAYER_REGEN_DISABLED                = 0,    -- not registered: no handler, no call
}

local N = 1000
local USAGE = "usage: lua tests/perf.lua [--out <path>] [--label <text>]\n"

local opts = { out = nil, label = "offline" }
do
    local i = 1
    while arg and arg[i] do
        local a = arg[i]
        if a == "--out" and arg[i + 1] then opts.out = arg[i + 1]; i = i + 2
        elseif a == "--label" and arg[i + 1] then opts.label = arg[i + 1]; i = i + 2
        else
            io.stderr:write("unknown argument: " .. tostring(a) .. "\n")
            io.stderr:write(USAGE)
            os.exit(2)
        end
    end
end

-- ── environment ─────────────────────────────────────────────────────────────────────────────

local mockf = dofile("tests/wow_mock.lua")
local loadAddon = dofile("tests/loader.lua")(".", mockf)

-- The mock's hooksecurefunc packs every call's returns into a table, which would charge the mock's
-- allocation to the addon. This one is the same real post-hook at fixed arity (every hooked
-- function here takes at most four arguments), so the harness allocates nothing per call.
local function installHook(m, target, name, fn)
    local orig = target[name]
    assert(type(orig) == "function", "hooksecurefunc: " .. tostring(name) .. " is not a function")
    target[name] = function(a1, a2, a3, a4)
        orig(a1, a2, a3, a4)
        fn(a1, a2, a3, a4)
    end
    m.hooks[#m.hooks + 1] = { target = target, name = name, fn = fn }
end

-- Blizzard's painters set the row's text before the post-hook runs; these do the same, so each
-- iteration tags the row's base text rather than a text that grows by one tag per call.
local function paintSearchEntry(entry) entry.ActivityName.text = entry.ActivityName.base end
local function paintApplicant(member) member.Name.text = member.Name.base end

local SEASON = { 586, 587, 250, 585, 588, 399, 584, 249 }

local function seedMock(m)
    m.hooksecurefunc = function(a, b, c)
        if type(a) == "string" then return installHook(m, m, a, b) end
        return installHook(m, a, b, c)
    end
    m.LFGListSearchEntry_Update = paintSearchEntry
    m.LFGListApplicationViewer_UpdateApplicantMember = paintApplicant
    m.mapTable = SEASON
    for i, id in ipairs(SEASON) do
        m.mapUIInfo[id] = { name = "Dungeon " .. i, mapID = 2000 + i }
        m.seasonBest[id] = { intime = { level = 10 + i } }
    end
end

local NS, _, mock = loadAddon{ mock = seedMock }
NS.addon:OnInitialize()
NS.addon:OnEnable()

-- ── the counting layer ──────────────────────────────────────────────────────────────────────
--
-- Fixed-arity wrappers (a vararg wrapper allocates under Lua 5.1, and its bytes would be the
-- shim's). Every label is pre-seeded at 0, so a counted call never grows a table.

local API_GLOBALS = { "GetCurrentRegion", "GetRealmName", "InCombatLockdown", "UnitClass", "UnitName",
    "GetSpecialization", "GetSpecializationInfo" }
local API_NAMESPACES = { "C_LFGList", "C_ChallengeMode", "C_MythicPlus", "C_SpecializationInfo" }

local counts = { api = 0, lookups = 0, by = {} }

local function counted(label, orig)
    counts.by[label] = 0
    return function(a1, a2, a3, a4)
        counts.api = counts.api + 1
        counts.by[label] = counts.by[label] + 1
        return orig(a1, a2, a3, a4)
    end
end

local function countNamespace(nsName)
    local t = mock[nsName]
    if type(t) ~= "table" then return end
    local names = {}
    for k, v in pairs(t) do if type(v) == "function" then names[#names + 1] = k end end
    for _, k in ipairs(names) do t[k] = counted(nsName .. "." .. k, t[k]) end
end

for _, name in ipairs(API_GLOBALS) do
    if type(mock[name]) == "function" then mock[name] = counted(name, mock[name]) end
end
for _, nsName in ipairs(API_NAMESPACES) do countNamespace(nsName) end

local realGetRegion = NS.Regions.GetRegion
NS.Regions.GetRegion = function(leaderName)
    counts.lookups = counts.lookups + 1
    return realGetRegion(leaderName)
end

counts.by.GetText, counts.by.SetText = 0, 0
local function fsGetText(self)
    counts.api = counts.api + 1
    counts.by.GetText = counts.by.GetText + 1
    return self.text
end
local function fsSetText(self, t)
    counts.api = counts.api + 1
    counts.by.SetText = counts.by.SetText + 1
    self.text = t
end
local function fontString(base)
    return { base = base, text = base, GetText = fsGetText, SetText = fsSetText }
end

local function resetCounts()
    counts.api, counts.lookups = 0, 0
    for k in pairs(counts.by) do counts.by[k] = 0 end
end

-- ── payloads (built once, outside every measured loop: the client's data, not the addon's) ──

-- Five leaders: four realms of the US map (one with no suffix, the player's own realm) and one the
-- map does not know.
local LEADERS = { "Bob-Barthilas", "Ann-Area52", "Cid", "Dee-Nowhere", "Eve-Frostmourne" }
local ENV = {}
local PGF_NS = mock.PremadeGroupsFilter.Debug

local ENTRIES, MEMBERS = {}, {}
for i, leader in ipairs(LEADERS) do
    mock.searchResults[i] = { leaderName = leader }
    ENTRIES[i] = { resultID = i, ActivityName = fontString("Activity " .. i) }
    mock.applicants[i] = { [1] = leader }
    MEMBERS[i] = { Name = fontString("Applicant" .. i) }
end

-- ── measurement ─────────────────────────────────────────────────────────────────────────────

local results, failures = {}, {}

local function check(cond, msg)
    if not cond then failures[#failures + 1] = msg end
    return cond
end

-- One warm-up call first (first-touch table growth is a one-off, not per-iteration cost), then
-- the measured loop with the collector stopped, between two full collects.
local function measure(name, iterations, fn)
    fn(1)
    resetCounts()
    collectgarbage("collect"); collectgarbage("collect")
    collectgarbage("stop")
    local kbBefore = collectgarbage("count")
    local t0 = os.clock()
    for i = 1, iterations do fn(i) end
    local elapsed = os.clock() - t0
    local kbAfter = collectgarbage("count")
    collectgarbage("restart")
    collectgarbage("collect")
    local r = {
        name = name, iterations = iterations,
        totalMs = elapsed * 1000, msPerIter = (elapsed * 1000) / iterations,
        apiCalls = counts.api, apiPerIter = counts.api / iterations,
        lookupsPerIter = counts.lookups / iterations,
        bytesPerIter = ((kbAfter - kbBefore) * 1024) / iterations,
    }
    for k, v in pairs(counts.by) do r[k] = v / iterations end
    results[#results + 1] = r
    return r
end

local function envCall(i) PGF_NS.PutPremadeRegionInfo(ENV, LEADERS[(i % #LEADERS) + 1]) end
local function searchPaint(i) mock.LFGListSearchEntry_Update(ENTRIES[(i % #ENTRIES) + 1]) end
local function applicantPaint(i)
    local k = (i % #MEMBERS) + 1
    mock.LFGListApplicationViewer_UpdateApplicantMember(MEMBERS[k], k, 1)
end

-- (a) The per-result env hook without PremadeRegions: injectRegions, Regions.GetRegion and the
--     C-32 concat probe, once per search result PGF filters.
mock.PremadeRegions = nil
local envNoPR = measure("envNoPR", N, envCall)
check(envNoPR.lookupsPerIter == 1,
    ("envNoPR made %.2f region lookups/iter, expected 1"):format(envNoPR.lookupsPerIter))

-- (b) The same with PremadeRegions loaded: PGF fills the region keys, the addon makes no lookup.
local PR_FAKE = { GetRegion = function() return "oce" end }
mock.PremadeRegions = PR_FAKE
local envWithPR = measure("envWithPR", N, envCall)
check(envWithPR.lookupsPerIter == 0,
    ("envWithPR made %.2f region lookups/iter, expected 0"):format(envWithPR.lookupsPerIter))
mock.PremadeRegions = nil

-- (c) Stood down: the hook cannot be removed (hooksecurefunc has no un-hook), so it returns at once.
NS.addon:OnSlashCommand("disable")
local envStoodDown = measure("envStoodDown", N, envCall)
check(envStoodDown.lookupsPerIter == 0, "envStoodDown made a region lookup")
NS.addon:OnSlashCommand("enable")

-- (d) / (e) Blizzard's row painters, post-hooked by modules/RegionTags.lua.
local searchRow = measure("searchRowPaint", N, searchPaint)
check(searchRow["C_LFGList.GetSearchResultInfo"] == 1,
    ("searchRowPaint: %.2f GetSearchResultInfo/iter, expected 1"):format(
        searchRow["C_LFGList.GetSearchResultInfo"]))
check(searchRow.SetText == 1, ("searchRowPaint: %.2f SetText/iter, expected 1"):format(searchRow.SetText))
local applicantRow = measure("applicantRowPaint", N, applicantPaint)
check(applicantRow["C_LFGList.GetApplicantMemberInfo"] == 1,
    ("applicantRowPaint: %.2f GetApplicantMemberInfo/iter, expected 1"):format(
        applicantRow["C_LFGList.GetApplicantMemberInfo"]))
check(applicantRow.SetText == 1,
    ("applicantRowPaint: %.2f SetText/iter, expected 1"):format(applicantRow.SetText))

-- (f) In combat: every FEATURE_EVENTS event and PLAYER_REGEN_DISABLED, which nothing registers.
local COMBAT_EVENTS, seen = {}, {}
for _, row in ipairs(NS.FEATURE_EVENTS) do
    if not seen[row[1]] then seen[row[1]] = true; COMBAT_EVENTS[#COMBAT_EVENTS + 1] = row[1] end
end
COMBAT_EVENTS[#COMBAT_EVENTS + 1] = "PLAYER_REGEN_DISABLED"
mock.inCombat = true

local function fireAll()
    for _, event in ipairs(COMBAT_EVENTS) do mock.fireEvent(event) end
end

local perEvent = {}
local function measureEvent(event)
    mock.fireEvent(event)                -- warm-up: a first PLAYER_ENTERING_WORLD builds the panel
    resetCounts()
    local handlers = mock.fireEvent(event)
    perEvent[event] = { api = counts.api, handlers = handlers }
end
for _, event in ipairs(COMBAT_EVENTS) do measureEvent(event) end
for _, event in ipairs(COMBAT_EVENTS) do
    local want = EVENT_API[event]
    check(want ~= nil, event .. " has no pinned call count in EVENT_API")
    check(want == nil or perEvent[event].api == want,
        ("%s made %d API calls in combat, pinned at %s"):format(event, perEvent[event].api, tostring(want)))
end
check(perEvent.PLAYER_REGEN_DISABLED.handlers == 0, "PLAYER_REGEN_DISABLED reached a handler")
local combat = measure("combatEvents", N, fireAll)
mock.inCombat = false

-- ── ceilings ────────────────────────────────────────────────────────────────────────────────

for _, r in ipairs(results) do
    local ceiling = BYTE_CEILING[r.name]
    check(ceiling ~= nil and r.bytesPerIter <= ceiling,
        ("%s allocated %.1f bytes/iter, over its %s-byte ceiling"):format(r.name, r.bytesPerIter, tostring(ceiling)))
    local api = API_PER_ITER[r.name]
    check(api == nil or math.abs(r.apiPerIter - api) < 1e-9,
        ("%s made %.2f API calls/iter, pinned at %s"):format(r.name, r.apiPerIter, tostring(api)))
end
local _ = combat

-- ── report ──────────────────────────────────────────────────────────────────────────────────

print(("Ka0s Premade Groups Filter Extension \226\128\148 offline perf  (v%s, label '%s')"):format(
    tostring(NS.version or "?"), opts.label))
print()
-- Five columns, exactly: tests/_kit/run-automated-tests.sh counts scenarios structurally as the
-- five-field rows under this header, so a sixth column makes every row invisible to it.
print(("%-20s %8s %11s %9s %11s"):format("scenario", "iters", "ms/iter", "api/iter", "bytes/iter"))
for _, r in ipairs(results) do
    print(("%-20s %8d %11.5f %9.2f %11.1f"):format(
        r.name, r.iterations, r.msPerIter, r.apiPerIter, r.bytesPerIter))
end
print()
print("combatEvents, per event (InCombatLockdown true):")
for _, event in ipairs(COMBAT_EVENTS) do
    print(("  %-40s handlers %d  api %d"):format(event, perEvent[event].handlers or 0, perEvent[event].api))
end
print()
print("timings are for orientation only \226\128\148 compare scenarios within a run, never across machines")
if #failures > 0 then
    print()
    print(("%d assertion%s FAILED:"):format(#failures, #failures == 1 and "" or "s"))
    for _, f in ipairs(failures) do print("  - " .. f) end
end

-- ── the record ──────────────────────────────────────────────────────────────────────────────
--
-- Written by hand: there is no NS.Perf (performance-§12), so the library instance's encoder is
-- not wired. The shape is the collection's shared offline record schema.

local ESCAPES = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n" }
local function escapeChar(c) return ESCAPES[c] or string.format("\\u%04x", c:byte()) end

local encode

local function encodeScalar(v)
    local t = type(v)
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "0" end
        if v == math.floor(v) then return string.format("%d", v) end
        return string.format("%.4f", v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return '"' .. v:gsub('[%c"\\]', escapeChar) .. '"'
    end
    return "null"
end

local function encodeArray(v, indent)
    local pad, inner = string.rep("  ", indent), string.rep("  ", indent + 1)
    local out = {}
    for _, item in ipairs(v) do out[#out + 1] = inner .. encode(item, indent + 1) end
    if #out == 0 then return "[]" end
    return "[\n" .. table.concat(out, ",\n") .. "\n" .. pad .. "]"
end

local function encodeObject(v, indent)
    local pad, inner = string.rep("  ", indent), string.rep("  ", indent + 1)
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys)   -- sorted, so two runs of the same code diff clean
    local out = {}
    for _, k in ipairs(keys) do
        out[#out + 1] = inner .. encodeScalar(tostring(k)) .. ": " .. encode(v[k], indent + 1)
    end
    return "{\n" .. table.concat(out, ",\n") .. "\n" .. pad .. "}"
end

function encode(v, indent)
    if type(v) ~= "table" then return encodeScalar(v) end
    if v[1] ~= nil or next(v) == nil then return encodeArray(v, indent) end
    return encodeObject(v, indent)
end

local function writeRecord(path)
    local buckets = {}
    for _, r in ipairs(results) do
        buckets[r.name] = { calls = r.iterations, totalMs = r.totalMs, maxMs = r.msPerIter,
                            apiPerIter = r.apiPerIter, bytesPerIter = r.bytesPerIter }
    end
    local fh, err = io.open(path, "w")
    if not fh then
        io.stderr:write("cannot write " .. path .. ": " .. tostring(err) .. "\n")
        os.exit(2)
    end
    fh:write(encode({
        schema = 1, addon = "PremadeGroupsFilterExtension", source = "offline",
        version = tostring(NS.version or "?"), interface = 0, timestamp = os.time(),
        label = opts.label, buckets = buckets, failures = failures,
    }, 0), "\n")
    fh:close()
    print("wrote " .. path)
end

if opts.out then writeRecord(opts.out) end

os.exit(#failures == 0 and 0 or 1)
