-- tests/loader.lua
--
-- The instance factory: builds one fully ISOLATED addon in a fresh mock environment and returns
-- `(NS, env, mock)`, where `env` and `mock` are the same table (tests/wow_mock.lua sets `_G` to
-- itself). The sandbox and the TOC reader come from the shared kit (testing-§9); what stays here is
-- isolation, because nearly every case builds a fresh addon so no file-local state leaks between
-- cases. Chunks are compiled once and re-run per instance.

local Loader = dofile("tests/_kit/loader.lua")

-- Every file of libs/LibKa0s/LibKa0s.xml, in XML order: the TOC pulls them in through the .xml,
-- which tocFiles cannot see, and a module missing its floor dependency silently leaves the host
-- measuring its own degradation stub (testing-§9, anti-pattern #48).
local LIBKA0S = {
    "libs/LibKa0s/Core.lua",
    "libs/LibKa0s/Env.lua",
    "libs/LibKa0s/Compat.lua",
    "libs/LibKa0s/Lifecycle.lua",
    "libs/LibKa0s/Bus.lua",
    "libs/LibKa0s/Schema.lua",
    "libs/LibKa0s/Pool.lua",
    "libs/LibKa0s/Item.lua",
    "libs/LibKa0s/Media.lua",
    "libs/LibKa0s/Widgets.lua",
    "libs/LibKa0s/WidgetsReorder.lua",
    "libs/LibKa0s/WidgetsDragHandle.lua",
    "libs/LibKa0s/WidgetsLineChart.lua",
    "libs/LibKa0s/WidgetsAutocomplete.lua",
    "libs/LibKa0s/DebugLog.lua",
    "libs/LibKa0s/DebugLogDiagnostics.lua",
    "libs/LibKa0s/DebugLogGates.lua",
    "libs/LibKa0s/Slash.lua",
    "libs/LibKa0s/SlashParse.lua",
    "libs/LibKa0s/Launcher.lua",
    "libs/LibKa0s/Options.lua",
    "libs/LibKa0s/OptionsRegistry.lua",
    "libs/LibKa0s/OptionsWidgets.lua",
    "libs/LibKa0s/OptionsIds.lua",
    "libs/LibKa0s/OptionsIdList.lua",
    "libs/LibKa0s/OptionsTabs.lua",
    "libs/LibKa0s/OptionsCombat.lua",
    "libs/LibKa0s/OptionsCompose.lua",
    "libs/LibKa0s/OptionsScroll.lua",
    "libs/LibKa0s/OptionsNav.lua",
    "libs/LibKa0s/Perf.lua",
    "libs/LibKa0s/PerfSampler.lua",
    "libs/LibKa0s/PerfCommands.lua",
    "libs/LibKa0s/PerfPanel.lua",
}

-- Mock fields a factory's `opts` may seed before any source loads (see tests/wow_mock.lua).
local MOCK_OPTS = { "currentRegion", "realmName", "mapTable", "specID", "role", "classFile",
    "inCombat" }

return function(root, mockBuilder)
    local function abs(rel) return root .. "/" .. rel end

    -- The addon's own files, in TOC order, derived rather than restated.
    local tocFiles = Loader.tocFiles(abs("PremadeGroupsFilterExtension.toc"))

    local sources = {}
    for _, rel in ipairs(LIBKA0S) do sources[#sources + 1] = { path = rel, lib = true } end
    for _, rel in ipairs(tocFiles) do sources[#sources + 1] = { path = rel, lib = false } end

    local compiled = {}
    local function chunkFor(rel)
        local c = compiled[rel]
        if c == nil then
            local err
            c, err = loadfile(abs(rel))
            if not c then error(("loadfile(%s) failed: %s"):format(rel, tostring(err))) end
            compiled[rel] = c
        end
        return c
    end

    --- Build one instance.
    ---   opts.skip      = { "<relative path>", ... } omits those files: the degraded-install cases
    ---                    load the addon with the library genuinely ABSENT (testing-§8).
    ---   opts.mock      = function(mock) end runs against the fresh mock before any source loads.
    ---   opts.addonName = "<folder>" changes the first vararg the addon's own files receive.
    ---   opts.<field>   for each MOCK_OPTS name, seeds that mock field.
    local function build(opts)
        opts = opts or {}
        local skipSet = {}
        for _, rel in ipairs(opts.skip or {}) do skipSet[rel] = true end

        local mock = mockBuilder()
        for _, k in ipairs(MOCK_OPTS) do
            if opts[k] ~= nil then mock[k] = opts[k] end
        end
        if type(opts.mock) == "function" then opts.mock(mock) end
        local env = Loader.makeEnv(mock)
        local NS  = {}

        -- The kit's AceDB fake resolves a SavedVariables NAME against the real _G, so a previous
        -- instance's saved table would otherwise be adopted by this one.
        _G.PremadeGroupsFilterExtensionDB = nil
        _G.PremadeGroupsFilterExtensionPerfDB = nil

        for _, src in ipairs(sources) do
            if not skipSet[src.path] then
                local chunk = chunkFor(src.path)
                setfenv(chunk, env)
                if src.lib then chunk() else chunk(opts.addonName or "PremadeGroupsFilterExtension", NS) end
            end
        end

        return NS, mock, mock
    end

    return setmetatable({
        sources  = sources,
        tocFiles = tocFiles,
        libFiles = LIBKA0S,
        root     = root,
    }, { __call = function(_, opts) return build(opts) end })
end
