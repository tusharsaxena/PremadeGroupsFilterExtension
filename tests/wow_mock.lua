-- tests/wow_mock.lua
--
-- This addon's THIN EXTENDER over the shared kit's mock_base (testing-§1). The base owns everything
-- universal: LibStub with a real NewLibrary, the Ace fakes, AceDB's merge-in-place defaults, the
-- AceGUI recorder, the Settings registrars, the timer queue and the event dispatch. This file adds
-- what Premade Groups Filter Extension reads that the base deliberately leaves out, as settable
-- fields on the mock so a suite seeds the client's answers before driving the addon.
--
-- Returns a BUILDER: each call is a fresh, isolated environment. `M._G = M`, so the table a suite
-- reads as `mock` and the table the addon's chunks read as `_G` are the same object, and a suite
-- that assigns `m.PremadeRegions = {...}` or `m.PremadeGroupsFilterDungeonPanel = nil` changes what
-- the addon sees as that global.
--
-- Mock fields (the plan's names; tests/run.lua copies the same keys from a factory's `opts`):
--   currentRegion  GetCurrentRegion()'s answer (1 = US, 3 = EU); default 1
--   realmName      GetRealmName()'s answer; default "Frostmourne"
--   mapTable       C_ChallengeMode.GetMapTable()'s answer (nil = not loaded yet)
--   mapUIInfo      [cmID] = { name = ..., mapID = ... } for C_ChallengeMode.GetMapUIInfo
--   seasonBest     [cmID] = { intime = {level=n}|nil, overtime = {level=n}|nil }
--   specID, role   GetSpecializationInfo(index)'s specID and role token
--   classFile      UnitClass("player")'s class token
--   inCombat       InCombatLockdown()'s answer
--   fireEvent      fireEvent(name, ...) dispatches a game event to AceEvent handlers
--   pgf            the PGF fake's handle (tests/pgf_fake.lua): calls, dialog, panel, state, PGF
--   hooks          every hooksecurefunc post-hook installed, in order: { target, name, fn }

local base = dofile("tests/_kit/mock_base.lua")
local pgfFake = assert(loadfile("tests/pgf_fake.lua"))()

local function build()
    local M = base()
    M._G = M

    M.currentRegion = 1
    M.realmName     = "Frostmourne"
    M.mapTable      = nil
    M.mapUIInfo     = {}
    M.seasonBest    = {}
    M.specID        = 253
    M.role          = "DAMAGER"
    M.classFile     = "HUNTER"
    M.inCombat      = false
    M.prints        = {}
    M.hooks         = {}

    M.GetCurrentRegion = function() return M.currentRegion end
    M.GetRealmName     = function() return M.realmName end
    M.InCombatLockdown = function() return M.inCombat == true end

    M.GetSpecialization     = function() return 1 end
    M.GetSpecializationInfo = function(index)
        if index ~= 1 then return nil end
        return M.specID, "x", "", 0, M.role
    end
    M.UnitClass = function() return "X", M.classFile end

    M.C_ChallengeMode = {
        GetMapTable  = function() return M.mapTable end,
        GetMapUIInfo = function(id)
            local info = M.mapUIInfo[id]
            if not info then return nil end
            return info.name, id, 1800, nil, nil, info.mapID
        end,
    }
    M.C_MythicPlus = {
        GetSeasonBestForMap = function(id)
            local sb = M.seasonBest[id]
            if not sb then return nil end
            return sb.intime, sb.overtime
        end,
        RequestMapInfo = function() end,
    }

    -- A REAL post-hook, not the base's no-op: the env injection is reachable only through PGF's
    -- own PutPremadeRegionInfo, so a recorder that never calls the hook would let a hook that was
    -- never installed pass every case. Both forms: hooksecurefunc(table, name, fn) and
    -- hooksecurefunc(name, fn) on a global.
    M.hooksecurefunc = function(a, b, c)
        local target, name, fn = a, b, c
        if type(a) == "string" then target, name, fn = M, a, b end
        local orig = target[name]
        assert(type(orig) == "function", "hooksecurefunc: " .. tostring(name) .. " is not a function")
        target[name] = function(...)
            local r = { orig(...) }
            fn(...)
            return unpack(r)
        end
        M.hooks[#M.hooks + 1] = { target = target, name = name, fn = fn }
    end

    -- The chat sink core/CoreSetup.lua hands the printer: captured, so a suite can read it back.
    M.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
        M.prints[#M.prints + 1] = table.concat(parts, " ")
    end

    M.fireEvent = function(event, ...) return M.__fireEvent(event, ...) end

    -- AceDB's `char` scope, which the kit's fake does not model: this addon keeps its filter
    -- options per character (owner requirement), so the scope is added here the way AceDB-3.0 keys
    -- it -- `sv.char["<name> - <realm>"]`, merged in place with `defaults.char`.
    local AceDB = M.__libs["AceDB-3.0"]
    local baseNew = AceDB.New
    local function copyDefaults(dest, src)
        for k, v in pairs(src or {}) do
            if type(v) == "table" then
                if type(dest[k]) ~= "table" then dest[k] = {} end
                copyDefaults(dest[k], v)
            elseif dest[k] == nil then
                dest[k] = v
            end
        end
    end
    AceDB.New = function(self, tbl, defaults, ...)
        local db = baseNew(self, tbl, defaults, ...)
        local key = M.UnitName("player") .. " - " .. M.GetRealmName()
        db.sv.char = db.sv.char or {}
        db.sv.char[key] = db.sv.char[key] or {}
        copyDefaults(db.sv.char[key], defaults and defaults.char)
        db.char = db.sv.char[key]
        db.keys = { char = key }
        return db
    end

    -- The launcher's two libraries (launcher-§1), present by default because both are vendored and
    -- TOC-listed. Their whole surface as LibKa0s-Launcher-1.0 uses it; a case that wants the
    -- degraded install clears one through the loader's `mock` option.
    M.ldbObjects = {}
    M.__libs["LibDataBroker-1.1"] = {
        NewDataObject = function(_, name, tbl)
            if M.ldbObjects[name] then return nil end
            M.ldbObjects[name] = tbl
            return tbl
        end,
        GetDataObjectByName = function(_, name) return M.ldbObjects[name] end,
    }
    M.minimapButtons = {}
    M.__libs["LibDBIcon-1.0"] = {
        Register = function(_, name, object, db)
            M.minimapButtons[name] = { object = object, db = db, shown = not (db and db.hide) }
        end,
        IsRegistered = function(_, name) return M.minimapButtons[name] ~= nil end,
        Show = function(_, name)
            local b = M.minimapButtons[name]
            if b then b.shown = true end
        end,
        Hide = function(_, name)
            local b = M.minimapButtons[name]
            if b then b.shown = false end
        end,
        GetMinimapButton = function(_, name) return M.minimapButtons[name] end,
    }

    -- Premade Groups Filter is a hard dependency (## Dependencies), so its globals exist before
    -- any of this addon's files load.
    M.pgf = pgfFake(M)

    return M
end

return build
