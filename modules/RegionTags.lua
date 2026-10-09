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

-- One color per bucket. US: data centers; EU: realm languages.
RegionTags.COLORS = {
    oce = "33cc66", la = "3399ff", chi = "ff4040", mex = "ff9f1c", bzl = "e6d600",
    eng = "66ccff", ger = "ffd100", fra = "ff6b6b", ita = "40e080", spa = "ff9933",
    por = "bb88ff", rus = "e0e0e0",
}
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
    return "|cff" .. RegionTags.COLORS[key] .. NS.Regions.LABELS[key] .. "|r"
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
for name, fn in pairs({
    LFGListSearchEntry_Update = function(...) RegionTags.OnSearchEntryUpdate(...) end,
    LFGListApplicationViewer_UpdateApplicantMember = function(...) RegionTags.OnApplicantMemberUpdate(...) end,
}) do
    if type(_G[name]) == "function" then hooksecurefunc(name, fn) end
end
