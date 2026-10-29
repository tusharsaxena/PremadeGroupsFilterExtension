local _, NS = ...
-- defaults/Profile.lua — every default VALUE the addon hardcodes (savedvariables-§2).
--
-- Three scopes, each one AceDB defaults table (settings/Schema.lua's Settings.BuildDefaults
-- assembles them):
--   profile  master settings (options-ui-§15), the General page's two feature switches, the
--            region tag colors (its Region tags tab) and the attached panel's collapsed state;
--   char     the filter options, PER CHARACTER by the owner's requirement;
--   global   the schema stamp, the named presets (shared by every character) and LibDBIcon's table.
--
-- The Master controls rows are composed by LibKa0s-Options-1.0, so their values live here too: with
-- the library absent the schema has no `enabled` row, and a schema-only defaults tree would hand
-- AceDB a profile whose `enabled` reads nil, turning the addon off on that install.

-- The region tags' default colors, one per bucket (modules/Regions.lua's keys), as hex. US: data
-- centers; EU: realm languages. The stored setting is a {r, g, b} table per key (below).
local REGION_HEX = {
    oce = "a330c9", la = "3399ff", chi = "ff4040", mex = "ff9f1c", bzl = "00ff98",
    eng = "ff4040", ger = "ff7c0a", fra = "ffff00", ita = "00ff98", spa = "3399ff",
    por = "8788ee", rus = "a330c9",
}

-- In the shape the settings panel's color picker and `/pgfe set` write: { r =, g =, b =, a = }, 0..1.
local function regionColors()
    local out = {}
    for key, hex in pairs(REGION_HEX) do
        out[key] = {
            r = tonumber(hex:sub(1, 2), 16) / 255,
            g = tonumber(hex:sub(3, 4), 16) / 255,
            b = tonumber(hex:sub(5, 6), 16) / 255,
            a = 1,
        }
    end
    return out
end

NS.C = {
    REGION_HEX = REGION_HEX,

    PROFILE = {
        enabled        = true,    -- master switch (the `disabled` hold reads it)
        filtersActive  = true,    -- Use the extension's filters (General > Filters)
        showRegionTags = true,    -- the region tag on Group Finder rows (General > Region tags)
        panelCollapsed = false,   -- the attached panel folded to its title bar (modules/Panel.lua)
        regionColors   = regionColors(), -- the region tags' colors (General > Region tags)
        -- The skin this addon wears (core/SkinSetup.lua; General > Skin, skinning-§2): Ka0s Default,
        -- the settings panel left the client's (the owner's call of 2026-10-27, as LootHistory), the
        -- fonts skinned, the skin's own font and texture, and the first-run picker not yet seen on
        -- any profile, old or new (owner ruling O3, 2026-10-29).
        skin = {
            source = "ka0s", skin = "ka0s", ignorePanel = true, ignoreFonts = false,
            font = "", texture = "", pickerSeen = false,
        },
    },

    CHAR_DEFAULTS = {
        filters = {
            keyTargeting = true,  keyLevel = 10,
            smartKeyLevel = true,                          -- the addon sets keyLevel (Targeting.SmartLevel)
            regionsEnabled = true,  regions = {},          -- set: { oce = true, chi = true }
            playstyleEnabled = true,  playstyles = {},     -- set: { relaxed = true }
            compositionEnabled = true,                     -- the Composition row's own box
            noSameSpec = false,   noSameClassRole = false,
            experiencedLeader = false,
            maxAgeEnabled = false, maxAge = 15,
        },
    },

    -- schemaVersion is 0, never the current version (savedvariables-§1).
    GLOBAL_DEFAULTS = { schemaVersion = 0, presets = {}, minimap = { hide = false } },
}
