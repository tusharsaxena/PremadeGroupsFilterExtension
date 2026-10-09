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
--   specID, role   GetSpecializationInfo(index)'s specID and role token (the deprecated globals
--                  and C_SpecializationInfo answer the same; a suite nils either rung)
--   classFile      UnitClass("player")'s class token
--   inCombat       InCombatLockdown()'s answer
--   fireEvent      fireEvent(name, ...) dispatches a game event to AceEvent handlers
--   pgf            the PGF fake's handle (tests/pgf_fake.lua): calls, dialog, panel, state, PGF
--   hooks          every hooksecurefunc post-hook installed, in order: { target, name, fn }
--   installEUI     installEUI(spec) installs the EllesmereUI fake (see below); m.eui is its handle

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
    M.C_SpecializationInfo = {
        GetSpecialization     = function() return 1 end,
        GetSpecializationInfo = function(index)
            if index ~= 1 then return nil end
            return M.specID, "x", "", 0, M.role
        end,
    }
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

    -- Blizzard's Group Finder row painters and the two C_LFGList reads modules/RegionTags.lua makes:
    -- present at load (the hooks install then), answering from searchResults / applicants.
    M.searchResults = {}   -- [resultID] = { leaderName = ... }
    M.applicants    = {}   -- [appID] = { [memberIdx] = name }
    M.LFGListSearchEntry_Update = function() end
    M.LFGListApplicationViewer_UpdateApplicantMember = function() end
    M.C_LFGList = {
        GetSearchResultInfo = function(id) return M.searchResults[id] end,
        GetApplicantMemberInfo = function(appID, idx) return (M.applicants[appID] or {})[idx] end,
    }

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

    -- PANEL FRAMES. The kit's frame answers every unmodeled getter with the frame itself, so "the
    -- panel is anchored under the dialog" and "the range field reads 14-14" could not fail. Frames
    -- built under PGF's dialog (the attached panel, modules/Panel.lua, and everything inside it)
    -- are decorated with the state the panel reads back. Scoped to that subtree so the library's
    -- own frames keep the kit's behavior every other suite was written against.
    local function decorate(f)
        f.__panelFrame, f.__points, f.__children = true, {}, {}
        f.SetPoint = function(self, point, a, b, c, d)
            local pt = (type(a) == "number" or a == nil)
                and { point, nil, point, a or 0, b or 0 } or { point, a, b or point, c or 0, d or 0 }
            self.__points[#self.__points + 1] = pt
            return self
        end
        f.ClearAllPoints = function(self) self.__points = {}; return self end
        f.GetPoint = function(self, i)
            local pt = self.__points[i or 1]
            if pt then return pt[1], pt[2], pt[3], pt[4], pt[5] end
        end
        f.SetHeight = function(self, h) self.__height = h; return self end
        f.SetTextColor = function(self, r, g, b, a) self.__textColor = { r, g, b, a }; return self end
        f.SetWidth = function(self, w) self.__width = w; return self end
        f.SetSize = function(self, w, h) self.__width, self.__height = w, h; return self end
        -- Text measures 6px a byte, so a width built from a label or a button's text is checkable.
        f.GetStringWidth = function(self) return #(self.__text or "") * 6 end
        f.GetTextWidth = function(self) return #(self.__text or "") * 6 end
        f.SetHitRectInsets = function(self, l, r, t, b) self.__hitRect = { l, r, t, b }; return self end
        -- Blizzard_Menu's SetTooltip on a dropdown button: the fill function, kept for a case to call.
        f.SetTooltip = function(self, fn) self.__tooltip = fn; return self end
        f.SetNormalAtlas = function(self, a) self.__normalAtlas = a; return self end
        f.SetPushedAtlas = function(self, a) self.__pushedAtlas = a; return self end
        f.SetDisabledAtlas = function(self, a) self.__disabledAtlas = a; return self end
        -- An EditBox's SetText fires OnTextChanged with userInput false, as in the client.
        f.SetText = function(self, t)
            self.__text = t
            local h = self.__scripts.OnTextChanged
            if h then h(self, false) end
            return self
        end
        f.GetText = function(self) return self.__text end
        f.SetChecked = function(self, v) self.__checked = v and true or false; return self end
        f.GetChecked = function(self) return self.__checked == true end
        f.LockHighlight = function(self) self.__highlightLocked = true; return self end
        f.UnlockHighlight = function(self) self.__highlightLocked = false; return self end
        f.Click = function(self, ...) return self:__fire("OnClick", ...) end
        f.SetupMenu = function(self, gen) self.__menuGen = gen; return self end
        f.OverrideText = function(self, t) self.__text = t; return self end
        f.SetOnMaximizedCallback = function(self, fn) self.__onMaximized = fn; return self end
        f.SetOnMinimizedCallback = function(self, fn) self.__onMinimized = fn; return self end
        f.CreateFontString = function(self)
            local fs = decorate(M.__stubFrame())
            self.__children[#self.__children + 1] = fs
            return fs
        end
        return f
    end
    -- StaticPopup_Hide(which), recorded: the preset popups close themselves through it.
    M.popupsHidden = {}
    M.StaticPopup_Hide = function(which) M.popupsHidden[#M.popupsHidden + 1] = which end

    local baseCreateFrame = M.CreateFrame
    M.CreateFrame = function(frameType, name, parent, template)
        local f = baseCreateFrame(frameType, name, parent, template)
        if parent ~= nil and (parent == M.PremadeGroupsFilterDialog or parent.__panelFrame) then
            decorate(f)
            parent.__children = parent.__children or {}
            parent.__children[#parent.__children + 1] = f
            -- PortraitFrameTemplate's own close button (a parentKey in the template's XML).
            if template and template:find("PortraitFrameTemplate", 1, true) then
                f.CloseButton = decorate(M.__stubFrame())
                f.NineSlice = decorate(M.__stubFrame())   -- the border art's container
                f.TitleContainer = decorate(M.__stubFrame()) -- the title text's container
            end
            -- MaximizeMinimizeButtonFrameTemplate's two arrow buttons (parentKeys in its XML).
            if template == "MaximizeMinimizeButtonFrameTemplate" then
                f.MinimizeButton = decorate(M.__stubFrame())
                f.MaximizeButton = decorate(M.__stubFrame())
            end
        end
        return f
    end

    -- ELLESMEREUI, OPT-IN. Absent by default, as on a client without it: a case installs it from the
    -- loader's `mock` option (before any source loads), `m.installEUI{ ... }`. Modeled on EllesmereUI
    -- v9.4: the parent's RegisterSkin stub queues (first name wins), the window-skin child's
    -- dispatcher fires each entry ONCE, and only while the master switch and that entry are on
    -- (nil = on), handing it a facade S. The facade RECORDS every primitive call rather than
    -- no-opping it, so a case can ask what was painted.
    --   spec.child = false    EllesmereUIBlizzardSkin not loaded
    --   spec.pgfSkin = false  PremadeGroupsFilter_EllesmereUI not loaded
    --   spec.masterOff        EllesmereUIDB.thirdPartySkinsOff = true
    --   spec.entries          EllesmereUIDB.thirdPartySkinAddons (e.g. { PremadeGroupsFilter = false })
    -- Installs C_AddOns too (the base deliberately leaves it out), answering from `m.loadedAddons`,
    -- with this addon's own folder loaded. Handle: m.eui = { registry, order, fired, calls, looks,
    -- dispatch(name), dispatchAll(), callsFor(fn, target), count(fn) }.
    M.installEUI = function(spec)
        spec = spec or {}
        local eui = { registry = {}, order = {}, fired = {}, calls = {}, looks = {} }
        M.eui = eui
        M.loadedAddons = {
            PremadeGroupsFilterExtension = true, PremadeGroupsFilter = true, EllesmereUI = true,
            EllesmereUIBlizzardSkin = spec.child ~= false,
            PremadeGroupsFilter_EllesmereUI = spec.pgfSkin ~= false,
        }
        M.C_AddOns = {
            IsAddOnLoaded = function(name)
                local on = M.loadedAddons[name] == true
                return on, on
            end,
            GetAddOnMetadata = function() return nil end,
        }
        M.EllesmereUIDB = {
            thirdPartySkinsOff = spec.masterOff and true or nil,
            thirdPartySkinAddons = spec.entries or {},
        }
        local function masterOn()
            local d = M.EllesmereUIDB
            return not (d and d.thirdPartySkinsOff)
        end
        local function addonOn(name)
            local t = M.EllesmereUIDB and M.EllesmereUIDB.thirdPartySkinAddons
            return not (t and t[name] == false)
        end
        local PRIMITIVES = { "Shell", "Panel", "Inset", "FadeRegions", "FadeNineSlice", "Button",
            "WhiteButtonLabel", "StateButtonLabel", "EditBox", "Checkbox", "Dropdown", "ScrollBar",
            "CloseButton", "Font", "White" }
        local function facade(name)
            local S = { apiVersion = 3 }
            for _, fname in ipairs(PRIMITIVES) do
                S[fname] = function(target, opts)
                    eui.calls[#eui.calls + 1] = { fn = fname, target = target, opts = opts, skin = name }
                end
            end
            S.GetAccentColor = function() return 0.05, 0.8, 0.6 end
            S.GetFont = function() return "Fonts\\EUI.ttf", "" end
            S.GetStyle = function() return "eui" end
            S.OnLooksChanged = function(fn) eui.looks[#eui.looks + 1] = fn end
            S.IsEnabled = function() return masterOn() and addonOn(name) end
            return S
        end
        function eui.dispatch(name)
            local fn = eui.registry[name]
            if not fn or eui.fired[name] or not (masterOn() and addonOn(name)) then return false end
            if M.loadedAddons.EllesmereUIBlizzardSkin ~= true then return false end
            eui.fired[name] = true
            fn(facade(name))
            return true
        end
        function eui.dispatchAll()
            local any = false
            for _, name in ipairs(eui.order) do any = eui.dispatch(name) or any end
            return any
        end
        function eui.callsFor(fname, target)
            local out = {}
            for _, c in ipairs(eui.calls) do
                if c.fn == fname and (target == nil or c.target == target) then out[#out + 1] = c end
            end
            return out
        end
        function eui.count(fname) return #eui.callsFor(fname) end
        M.EllesmereUI = {
            RegisterSkin = function(name, fn)
                if type(name) ~= "string" or type(fn) ~= "function" or eui.registry[name] then return end
                eui.registry[name] = fn
                eui.order[#eui.order + 1] = name
            end,
        }
        return eui
    end

    return M
end

return build
