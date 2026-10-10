local _, NS = ...
-- modules/Apply.lua — Apply and Clear orchestration over the bridge.
--
-- Every refusal is decided BEFORE anything is written: combat, a missing PGF seam, the dialog not
-- on the dungeon category, the dialog minimized (PGF then filters with its mini panel, so the
-- dungeon state would not take effect), invalid options, season data still loading, nothing untimed, and an expression
-- the merge refuses. Each return is `ok, msgKey, ...` where `...` are the format arguments of
-- NS.L[msgKey]. With Smart on, Run recomputes the key level once the prechecks pass
-- (Filters.ApplySmartLevel), so `/pgfe apply` and the button target the same level. Search() is
-- called only when the caller is inside a hardware event (opts.search). Every return passes through
-- done(), which writes one `[Apply]` / `[Clear]` debug line (`ok: KEY` or `refused: KEY`).

local Apply = NS.Apply or {}
NS.Apply = Apply

--- "N-N" of the last successful Apply with key targeting on; nil before one, and after an Apply
--- with targeting off (no range was targeted).
Apply.LastRange = nil

local VALIDATION_MSG = { badLevel = "MSG_BAD_LEVEL", badAge = "MSG_BAD_AGE" }
local EXPR_MSG = { damaged = "MSG_DAMAGED", toolong = "MSG_TOOLONG" }

-- One debug line per Run/Clear outcome; the arguments pass through unchanged. MSG_NO_PGF names
-- the missing seam.
local function done(tag, ok, key, ...)
    if ok then
        NS.Debug(tag, "ok: %s", key)
    elseif key == "MSG_NO_PGF" then
        NS.Debug(tag, "refused: %s (missing %s)", key, tostring((...)))
    else
        NS.Debug(tag, "refused: %s", key)
    end
    return ok, key, ...
end

local function precheck()
    if InCombatLockdown() then return "MSG_COMBAT" end
    local ok, missing = NS.Bridge.Check()
    if not ok then return "MSG_NO_PGF", missing end
    if not NS.Bridge.IsDungeonCategory() then return "MSG_NOT_DUNGEONS" end
    if not NS.Bridge.IsDungeonPanelActive() then return "MSG_MINIMIZED" end
end

-- nil when key targeting is off (checkboxes left alone); nil, errKey when it cannot proceed.
local function dungeonTargets(f)
    if not f.keyTargeting then return nil end
    local dungeons = NS.Season.GetDungeons()
    if not dungeons then return nil, "MSG_LOADING" end
    local targets = NS.Targeting.Compute(dungeons, f.keyLevel)
    if #targets == 0 then return nil, "MSG_ALL_TIMED" end
    return targets
end

--- Write the options into PGF's dungeon state and expression, then optionally search.
--- @param opts table|nil  { search = bool }
--- @return boolean ok
--- @return string msgKey
function Apply.Run(opts)
    local err, arg = precheck()
    if err then return done("Apply", false, err, arg) end
    if not NS.Filters.IsActive() then return done("Apply", false, "MSG_INACTIVE") end
    NS.Filters.ApplySmartLevel()
    local portal = NS.Regions.GetPortal()
    local valid, why = NS.Filters.Validate()
    if not valid then return done("Apply", false, VALIDATION_MSG[why]) end
    local f = NS.Filters.Get()
    local targets, tErr = dungeonTargets(f)
    if tErr then return done("Apply", false, tErr, f.keyLevel) end
    local text, xErr = NS.Expression.Merge(NS.Bridge.GetExpression(),
        NS.Expression.BuildClauses(NS.Filters.ToClauseOpts(portal)))
    if not text then return done("Apply", false, EXPR_MSG[xErr]) end
    -- The rows PGF actually has for the targets, not #targets (a row without a cmId is skipped).
    local ticked = targets and NS.Bridge.SetDungeons(NS.Targeting.ToSet(targets))
    NS.Bridge.SetExpression(text)
    NS.Bridge.Commit()
    Apply.LastRange = targets and NS.Targeting.RangeText(f.keyLevel) or nil
    NS.Debug("Apply", "wrote %s dungeon rows, %d expr chars, range %s", tostring(ticked or "untouched"),
        #text, tostring(Apply.LastRange))
    if opts and opts.search then
        NS.Debug("Apply", "search")
        NS.Bridge.Search()
    end
    if not targets then return done("Apply", true, "MSG_APPLIED_NO_TARGETING") end
    return done("Apply", true, "MSG_APPLIED", ticked, Apply.LastRange)
end

--- Remove the managed block, restoring the user's own expression text.
--- @return boolean ok
--- @return string msgKey
function Apply.Clear()
    local err, arg = precheck()
    if err then return done("Clear", false, err, arg) end
    local text, xErr = NS.Expression.Merge(NS.Bridge.GetExpression(), {})
    if not text then return done("Clear", false, EXPR_MSG[xErr]) end
    NS.Bridge.SetExpression(text)
    NS.Bridge.Commit()
    NS.Debug("Clear", "wrote %d expr chars", #text)
    return done("Clear", true, "MSG_CLEARED")
end

--- The `filtersActive` row's onChange (settings/Panel.lua): every write of "Toggle PGF Extension
--- Filters" lands here, from the panel, the settings page or `/pgfe set`. Off removes the managed block;
--- on writes it back without a search. Only while PGF's dungeon panel is up: otherwise (PGF closed,
--- a profile reset from the settings page) nothing is written or printed, and the block's guard
--- (`pgfe_on`, modules/EnvInject.lua) keeps a block left in PGF's state neutral while it is off.
function Apply.OnFiltersToggled(on)
    if NS.IsStoodDown() then return end
    NS.Debug("Apply", "filters toggled %s", on and "on" or "off")
    if NS.Bridge.IsDungeonPanelActive() then
        if on then Apply.Report(Apply.Run{}) else Apply.Report(Apply.Clear()) end
    end
    if NS.Panel and NS.Panel.Refresh then NS.Panel.Refresh() end
end

--- Print a Run/Clear result through NS.Print.
function Apply.Report(_, key, ...)
    if key then NS.Print(NS.L[key]:format(...)) end
end
