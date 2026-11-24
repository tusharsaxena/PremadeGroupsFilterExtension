-- tests/test_sample_names.lua — one source of sample names (FB2-PGFE-01 of Ka0sAddonsCommonTasks
-- docs/2026-11-24-FEEDBACK_BATCH/, decision D1, LibKa0s#104; LibKa0s v1.113.0, Sim minor 5).
--
-- The owner, 2026-11-24: "adopt the predefined test mode names consistently across all addon's
-- test/sim modes". Every named sample person an addon draws (test mode, sim, preview, unlock
-- stand-ins, sample chat lines or toasts) comes from the library: `Sim.Sample()`'s five
-- protagonists and `Sim.SampleCrowd()`, never a hand-kept list or a hand-copied literal. This addon
-- draws no sample person at all: its test mode shows the filter panel alone (modules/Panel.lua,
-- THE TEST MODE), with nobody in it. So the guard is that it stays that way: no `Sample*` or
-- `Mock*` name literal (the convention's shape, a capitalized word starting "Sample" or "Mock" and
-- then lower-case letters: `Samplehunter`, `Mockrealm`) in any tracked file outside tests/,
-- libs/ (the library is the source) and the frozen bundles. A plain English word that happens to
-- fit the shape ("Samples", "Mocked") is not a name and is listed.

local T = _G.PGFE_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local SKIP_DIRS = { "libs/", "tests/", "docs/audits/", "docs/reviews/", "docs/automated-tests/",
                    "docs/perf-analysis/", "docs/revendor/", "docs/superpowers/" }
local WORDS = { Samples = true, Sampled = true, Sampler = true, Samplers = true, Sampling = true,
                Mocks = true, Mocked = true, Mocking = true, Mockup = true, Mockups = true }

local function skipped(path)
    for _, dir in ipairs(SKIP_DIRS) do
        if path:sub(1, #dir) == dir then return true end
    end
    return false
end

--- Every `Sample*`/`Mock*` name literal in `text`, as "line:word".
local function namesIn(text)
    local hits, n = {}, 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1
        for word in line:gmatch("%f[%a]([SM][%a]+)%f[%A]") do
            local name = word:match("^Sample%l+$") or word:match("^Mock%l+$")
            if name and #name <= 12 and not WORDS[name] then hits[#hits + 1] = n .. ":" .. name end
        end
    end
    return hits
end

local function trackedFiles()
    assertTrue(io.popen ~= nil, "io.popen is available, so the guard can look")
    local p = io.popen("git ls-files 2>/dev/null")
    assertTrue(p ~= nil, "git ls-files ran")
    local out = {}
    for path in p:lines() do
        if not skipped(path) and not path:match("%.tga$") and not path:match("%.ttf$")
            and not path:match("%.ogg$") and not path:match("%.png$") then
            out[#out + 1] = path
        end
    end
    p:close()
    assertTrue(#out > 20, "git ls-files named the addon's files, got " .. #out)
    return out
end

test("sample names: the guard sees a name literal and lets an English word through", function()
    -- red under: a pattern that misses the convention's shape, or flags plain prose.
    assertEqual(table.concat(namesIn('local who = "Samplehunter-Samplerealm"\nMock fields'), ","),
        "1:Samplehunter,1:Samplerealm")
    assertEqual(table.concat(namesIn("Samples were Mocked, SampleCrowd(n) and MockField"), ","), "")
    assertEqual(table.concat(namesIn("x\npet = 'Mockfang'"), ","), "2:Mockfang")
end)

test("sample names: no Sample*/Mock* name literal lives outside tests/, libs/ and the frozen bundles", function()
    -- red under: a hand-kept sample name in the addon's code or living docs (LibKa0s#104: take it
    -- from Sim.Sample() or Sim.SampleCrowd() instead).
    local found = {}
    for _, path in ipairs(trackedFiles()) do
        local fh = io.open(path, "rb")
        if fh then
            local text = fh:read("*a")
            fh:close()
            for _, hit in ipairs(namesIn(text)) do found[#found + 1] = path .. ":" .. hit end
        end
    end
    assertEqual(table.concat(found, "; "), "", "sample names outside the library")
end)
