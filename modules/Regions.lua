local _, NS = ...
-- modules/Regions.lua — leader realm to server region lookup, per portal.
--
-- The portal comes from GetCurrentRegion() (1 = US, 3 = EU; every other portal answers nil). A
-- leader name with no "-Realm" suffix is on the player's own realm. Lookup tables are built once
-- per portal from NS.RealmLists (defaults/Realms.lua) and cached.

local Regions = NS.Regions or {}
NS.Regions = Regions

Regions.KEYS = {
    US = { "oce", "la", "chi", "mex", "bzl" },
    EU = { "eng", "ger", "fra", "ita", "spa", "por", "rus" },
}
Regions.ALL_KEYS = {}
for _, portal in ipairs({ "US", "EU" }) do
    for _, k in ipairs(Regions.KEYS[portal]) do Regions.ALL_KEYS[#Regions.ALL_KEYS + 1] = k end
end
Regions.LABELS = { oce = "OCE", la = "LA", chi = "CHI", mex = "MEX", bzl = "BZL",
    eng = "ENG", ger = "GER", fra = "FRA", ita = "ITA", spa = "SPA", por = "POR", rus = "RUS" }

local PORTALS = { [1] = "US", [3] = "EU" }
local lookups = {}

-- Same rule as PremadeRegions: lowercase, drop whitespace and punctuation (incl. - and ').
-- Byte-wise: non-ASCII letters (accents, Cyrillic) pass through unchanged.
function Regions.Normalize(realm)
    return (realm:lower():gsub("[%s%p]", ""))
end

function Regions.GetPortal()
    return PORTALS[GetCurrentRegion()]
end

function Regions.Lookup(portal)
    local cached = lookups[portal]
    if cached then return cached end
    cached = {}
    for key, realms in pairs(NS.RealmLists[portal] or {}) do
        for _, realm in ipairs(realms) do cached[Regions.Normalize(realm)] = key end
    end
    lookups[portal] = cached
    return cached
end

function Regions.GetRegion(leaderName)
    -- A type check, not a pcall: this runs once per search result inside PGF's loop.
    if type(leaderName) ~= "string" or leaderName == "" then return nil end
    local portal = Regions.GetPortal()
    if not portal then return nil end
    local realm = leaderName:match("%-(.+)") or GetRealmName()
    if not realm then return nil end
    return Regions.Lookup(portal)[Regions.Normalize(realm)]
end
