local _, NS = ...
-- modules/Expression.lua — pure: filter options to PGF's Advanced Expression block.
--
-- The addon owns one marked block inside PGF's Advanced Filter Expression. Merge rewrites it,
-- Strip removes it, and the user's own text around it is kept byte for byte. When the user has
-- real (non-comment) text, it is wrapped as `( ours ) and (` … `)` so an `or` in it cannot leak.
-- `ours` is `( not pgfe_on or ( clauses ) )`: neutral whenever the env hook did not run.

local Expression = NS.Expression or {}
NS.Expression = Expression

Expression.MAX_LENGTH  = 2000 -- PGF's edit box limit (UI/Templates.xml)
Expression.MARK_BEGIN  = "-- [pgfe] begin: managed by Ka0s PGF Extension (Apply rewrites, Clear removes)"
Expression.MARK_END    = "-- [pgfe] end"
Expression.MARK_CLOSE  = "-- [pgfe] close"

local P_BEGIN, P_END, P_CLOSE = "^%s*%-%- %[pgfe%] begin", "^%s*%-%- %[pgfe%] end", "^%s*%-%- %[pgfe%] close"

local function splitLines(text)
    local out = {}
    for line in (text .. "\n"):gmatch("(.-)\r?\n") do out[#out + 1] = line end
    return out
end

local function trimBlankEdges(lines)
    local first, last = 1, #lines
    while first <= last and lines[first]:match("^%s*$") do first = first + 1 end
    while last >= first and lines[last]:match("^%s*$") do last = last - 1 end
    local out = {}
    for i = first, last do out[#out + 1] = lines[i] end
    return out
end

-- Mirror of PGF.UI_NormalizeExpression: drop comment lines, trim, join with spaces.
function Expression.Normalize(text)
    local parts = {}
    for line in (text or ""):gmatch("([^\n]+)") do
        if not line:match("^%s*%-%-") then
            local t = line:match("^%s*(.-)%s*$")
            if t ~= "" then parts[#parts + 1] = t end
        end
    end
    return table.concat(parts, " ")
end

-- Clause order is fixed: regions, playstyles, samespec, sameclassrole, experienced leader, age.
-- (No leader-rating clause: PGF's own M+ Rating row filters on mprating.)
function Expression.BuildClauses(opts)
    local c = {}
    if opts.regions and #opts.regions > 0 then
        c[#c + 1] = "( " .. table.concat(opts.regions, " or ") .. " )"
    end
    if opts.playstyles and #opts.playstyles > 0 then
        c[#c + 1] = "( " .. table.concat(opts.playstyles, " or ") .. " )"
    end
    if opts.noSameSpec then c[#c + 1] = "pgfe_samespec == 0" end
    if opts.noSameClassRole then c[#c + 1] = "pgfe_sameclassrole == 0" end
    if opts.experiencedLeader and opts.keyLevel then
        c[#c + 1] = ("( mpmapintime and mpmapmaxkey >= %d )"):format(opts.keyLevel)
    end
    if opts.maxAge then c[#c + 1] = ("age <= %d"):format(opts.maxAge) end
    return c
end

-- Returns the user's text with every managed line removed, and ok. A begin marker without an end
-- marker, or a close marker not followed by a `)` line, is damage: the input comes back unchanged
-- with ok = false so the caller never writes over text it cannot account for.
function Expression.Strip(text)
    text = text or ""
    local lines, out, i = splitLines(text), {}, 1
    while i <= #lines do
        local line = lines[i]
        if line:find(P_BEGIN) then
            local j = i + 1
            while j <= #lines and not lines[j]:find(P_END) do j = j + 1 end
            if j > #lines then return text, false end
            i = j + 1
        elseif line:find(P_CLOSE) then
            if not (lines[i + 1] and lines[i + 1]:match("^%s*%)%s*$")) then return text, false end
            i = i + 2
        else
            out[#out + 1] = line
            i = i + 1
        end
    end
    return table.concat(trimBlankEdges(out), "\n"), true
end

-- Returns the new expression text, or nil and "damaged" / "toolong".
function Expression.Merge(text, clauses)
    local user, ok = Expression.Strip(text)
    if not ok then return nil, "damaged" end
    if #clauses == 0 then return user end
    -- `not pgfe_on or`: the block lives in PGF's state, which outlives this addon's runtime (a
    -- stand-down, an AddOns-list disable, an uninstall). Only the env hook sets pgfe_on, so when it
    -- did not run the block passes every group instead of comparing nil pgfe_* values.
    local body = "( not pgfe_on or ( " .. table.concat(clauses, " and ") .. " ) )"
    local out
    if Expression.Normalize(user) == "" then
        -- Comment-only (or empty) user text: wrapping it would hand PGF `( … ) and ( )`.
        out = Expression.MARK_BEGIN .. "\n" .. body .. "\n" .. Expression.MARK_END
        if user ~= "" then out = out .. "\n" .. user end
    else
        out = table.concat({ Expression.MARK_BEGIN, body .. " and (", Expression.MARK_END,
            user, Expression.MARK_CLOSE, ")" }, "\n")
    end
    if #out > Expression.MAX_LENGTH then return nil, "toolong" end
    return out
end
