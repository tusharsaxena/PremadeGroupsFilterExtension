-- tests/test_surface_parity.lua — every degradation stub carries the live surface (testing-§8).
--
-- Each case loads the addon with the whole LibKa0s payload ABSENT (the loader skips its files)
-- and compares the stub against the live instance the runner registered by major name. A member
-- the live module has and the stub lacks is a crash moved to the one install the stub exists for.

local T = _G.PGFE_TEST
local test = T.test

local NO_LIBKA0S = T.loadAddon.libFiles

test("parity: the Core seam's namespace surface survives the library's absence", function()
    local live = T.newAddon()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(live, degraded, "the addon namespace (Core seam)")
    T.assertSurfaceParity(live.Util, degraded.Util, "NS.Util (Core printer seam)")
end)

test("parity: the DebugLog stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.DebugLog, "LibKa0s-DebugLog-1.0", {
        "FormatPlain", "FormatColored",
    })
end)

test("parity: the Slash stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.SlashCommands, "LibKa0s-Slash-1.0")
end)

test("parity: the Options helpers stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.addon.Settings.Helpers, "LibKa0s-Options-1.0", {
        "PADDING_X", "ROW_VSPACER", "SECTION_HEADING_H", "BUTTON_PAIR_REL",
        "CHROME_GAP", "TAB_H", "BANNER_H",
        "AceGUI",
        "BuildLandingPage", "RestoreDefaults",
        "FONT_FLAGS", "FONT_FLAGS_SORT", "VISIBILITY_VALUES", "VISIBILITY_SORT",
        "MASTER_GROUP", "CLASS_COLOR_NOTE",
    })
end)

test("parity: the Schema host stub's instance carries the whole live instance surface", function()
    local live = T.newAddon()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(live.SchemaRuntime, degraded.SchemaRuntime, "schema instance vs host stub")
end)

test("parity: the Schema host stub carries the library's own members", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.addon.Settings.SchemaLib, "LibKa0s-Schema-1.0", { "STRINGS" })
end)

test("parity: the Launcher stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.Launcher, "LibKa0s-Launcher-1.0")
end)

test("parity: the Lifecycle stub carries the whole live surface", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.Lifecycle, "LibKa0s-Lifecycle-1.0")
end)

test("parity: the Compat arm carries every library member the addon wires", function()
    local degraded = T.newAddon{ skip = NO_LIBKA0S }
    T.assertSurfaceParity(degraded.Compat, "LibKa0s-Compat-1.0", {
        "IsSecret", "CanAccess", "IsSafeKey",
        "GetSpellInfo", "GetSpellName", "GetSpellTexture", "GetSpellCooldown",
    })
end)

-- C-04: PGF internals are read only through core/PGFBridge.lua (and Diagnostics' presence check).
-- A structural guard over the two modules that used to reach past the bridge.
test("parity: no module reads PGF outside the bridge", function()
    for _, rel in ipairs({ "modules/Season.lua", "modules/EnvInject.lua" }) do
        local fh = assert(io.open(T.root .. "/" .. rel, "rb"))
        local src = fh:read("*a"); fh:close()
        -- red under: revert Season.lua to the direct C.MAP_ID_TO_KEYWORDS read
        T.assertTrue(src:find("PremadeGroupsFilter", 1, true) == nil, rel .. " names PremadeGroupsFilter")
    end
end)

-- C-11 (localization-§3): every locale key the code reads is defined in enUS, and every key enUS
-- defines is read. A static scan of the TOC's own files (libs\ and locales\ left out) collects the
-- literal keys: `NS.L["…"]` and `NS.L.IDENT` anywhere, and bare `L["…"]` / `L.IDENT` only in a file
-- that binds `local L = NS.L` (modules/Diagnostics.lua's `L` is the launcher). Each literal is
-- evaluated as Lua, so `\"`, `\n` and decimal escapes read the same on both sides. The `MSG_*`,
-- `REGION_TIP_*` and `PLAYSTYLE_*` families are read through computed keys, so they are exempt from
-- the "is read" direction.
local DYNAMIC = { "^MSG_", "^REGION_TIP_", "^PLAYSTYLE_" }

local function literalKeys(src, bare, out)
    local pos = 1
    while true do
        local s, e, sep = src:find("L([%[%.])", pos)
        if not s then break end
        pos = e + 1
        local before = s > 1 and src:sub(s - 1, s - 1) or ""
        local viaNS = s > 3 and src:sub(s - 3, s - 1) == "NS."
        local ok = viaNS or (bare and not before:find("[%w_%.]"))
        if ok and sep == "." then
            local ident = src:match("^([%a_][%w_]*)", e + 1)
            if ident then out[ident] = true end
        elseif ok and src:sub(e + 1, e + 1) == '"' then
            local i = e + 2
            while i <= #src do
                local c = src:sub(i, i)
                if c == "\\" then i = i + 2
                elseif c == '"' then break
                else i = i + 1 end
            end
            -- A literal followed by `..` is a computed key's prefix (the dynamic families), not a key.
            if src:find("^%s*%]", i + 1) then
                local raw = src:sub(e + 2, i - 1)
                out[assert(loadstring('return "' .. raw .. '"'))()] = true
            end
            pos = i + 1
        end
    end
end

-- red under: delete one of the new enUS lines
test("parity: every locale key used is defined in enUS, and every enUS key is used", function()
    local used = {}
    for _, rel in ipairs(T.loadAddon.tocFiles) do
        local norm = rel:gsub("\\", "/")
        if norm:find("%.lua$") and not norm:find("^libs/") and not norm:find("^locales/") then
            local fh = assert(io.open(T.root .. "/" .. norm, "rb"))
            local src = fh:read("*a"); fh:close()
            literalKeys(src, src:find("local L%s*=%s*NS%.L%f[^%w_]") ~= nil, used)
        end
    end
    local defined = {}
    for k in pairs(T.newAddon().L) do defined[k] = true end
    local missing, unused = {}, {}
    for k in pairs(used) do
        if not defined[k] then missing[#missing + 1] = k end
    end
    for k in pairs(defined) do
        local dynamic = false
        for _, p in ipairs(DYNAMIC) do if k:find(p) then dynamic = true end end
        if not used[k] and not dynamic then unused[#unused + 1] = k end
    end
    table.sort(missing); table.sort(unused)
    T.assertTrue(#missing == 0 and #unused == 0, ("%d missing from enUS:\n  %s\n%d defined but unused:\n  %s")
        :format(#missing, table.concat(missing, "\n  "), #unused, table.concat(unused, "\n  ")))
end)
