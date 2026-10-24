local _, NS = ...
-- modules/RegionTags.lua — the leader's server region on Group Finder rows, and on applicants.
--
-- Replaces PremadeRegions' display half: a colored region tag (OCE, LA, CHI, ...) in front of each
-- search result's activity name and each applicant's name, from the same realm map the filter uses
-- (modules/Regions.lua). Both are post-hooks on Blizzard's row painters, installed at FILE LOAD
-- (never AceHook); each body returns at once while stood down, while the `showRegionTags` setting is
-- off, or while PremadeRegions itself is loaded (it paints the same tag; two would stack). The tag
-- goes onto Blizzard's font string through SetText with `..`, never string.format or table.concat,
-- so a protected ("secret") string passes through untouched; a leader or applicant name that is not
-- concat-safe gets no tag (Regions.GetRegion would have to match on it).

local RegionTags = NS.RegionTags or {}
NS.RegionTags = RegionTags

-- Each bucket's color is the profile's `regionColors.<key>` (the General page's Region tags tab,
-- or `/pgfe set regionColors.<key> r g b`), turned into the hex a |c escape takes. The hex is cached
-- per key against the stored table it came from: every write (picker, CLI, reset, profile switch)
-- puts a new table there, so a changed identity is a changed color, and a row paint costs one
-- table read and one compare rather than a string.format.
local hexCache = {} -- key -> { src = <stored table>, hex = "rrggbb" }

local function channel(v)
    v = tonumber(v) or 1
    if v < 0 then v = 0 elseif v > 1 then v = 1 end
    return math.floor(v * 255 + 0.5)
end

--- The six-digit hex for a region key: the stored color, else the default.
--- @return string
function RegionTags.Hex(key)
    local p = NS.addon.db and NS.addon.db.profile
    local src = p and type(p.regionColors) == "table" and p.regionColors[key] or nil
    local hit = hexCache[key]
    if hit and hit.src == src then return hit.hex end
    local hex
    if type(src) == "table" then
        hex = ("%02x%02x%02x"):format(channel(src.r), channel(src.g), channel(src.b))
    else
        hex = NS.C.REGION_HEX[key] or "ffffff"
    end
    hexCache[key] = { src = src, hex = hex }
    return hex
end

--- The region's label in its color, e.g. "|cff33cc66OCE|r".
function RegionTags.Colored(key)
    return "|cff" .. RegionTags.Hex(key) .. NS.Regions.LABELS[key] .. "|r"
end
local UNKNOWN = "|cff9d9d9d?|r" -- a supported portal, a realm the map does not know

local function active()
    if NS.IsStoodDown() or PremadeRegions then return false end
    local p = NS.addon.db and NS.addon.db.profile
    return not (p and p.showRegionTags == false)
end

--- The colored tag for a leader or applicant name, or nil: an unsupported portal (KR, TW, CN),
--- or a name that is not a plain string.
--- @return string|nil
function RegionTags.Tag(name)
    if type(name) ~= "string" or not NS.IsConcatSafe(name) or not NS.Regions.GetPortal() then return nil end
    local key = NS.Regions.GetRegion(name)
    if not key then return UNKNOWN end
    return RegionTags.Colored(key)
end

local function prefix(fontString, tag)
    if not (tag and fontString and fontString.GetText and fontString.SetText) then return end
    local text = fontString:GetText()
    if text == nil then return end
    fontString:SetText(tag .. " " .. text)
end

--- LFGListSearchEntry_Update(entry) post-hook: tag the activity name.
function RegionTags.OnSearchEntryUpdate(entry)
    if not active() or type(entry) ~= "table" or not entry.resultID then return end
    local info = C_LFGList.GetSearchResultInfo(entry.resultID)
    prefix(entry.ActivityName, RegionTags.Tag(info and info.leaderName))
end

--- LFGListApplicationViewer_UpdateApplicantMember(member, appID, memberIdx, ...) post-hook: tag the
--- applicant's name.
function RegionTags.OnApplicantMemberUpdate(member, appID, memberIdx)
    if not active() or type(member) ~= "table" then return end
    local name = C_LFGList.GetApplicantMemberInfo(appID, memberIdx)
    prefix(member.Name, RegionTags.Tag(name))
end

-- Installed at FILE LOAD. Blizzard's Group Finder painters are global functions present by the
-- time this addon loads (PremadeRegions hooks them the same way); a client without one skips it.
-- The table is hoisted out of the for-in header because lizard 1.24 crashes on function literals
-- there, which leaves the whole file unmeasured.
local PAINTER_HOOKS = {
    LFGListSearchEntry_Update = function(...) RegionTags.OnSearchEntryUpdate(...) end,
    LFGListApplicationViewer_UpdateApplicantMember = function(...) RegionTags.OnApplicantMemberUpdate(...) end,
}
-- name -> true for each painter actually hooked, read by /pgfe diagnostics.
RegionTags.hooked = {}
for name, fn in pairs(PAINTER_HOOKS) do
    if type(_G[name]) == "function" then
        hooksecurefunc(name, fn)
        RegionTags.hooked[name] = true
    end
end
