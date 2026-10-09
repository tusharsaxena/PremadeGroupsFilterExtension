local _, NS = ...
-- defaults/Profile.lua — every default VALUE the addon hardcodes (savedvariables-§2).
--
-- Three scopes, each one AceDB defaults table (settings/Schema.lua's Settings.BuildDefaults
-- assembles them):
--   profile  master settings (options-ui-§15) and the attached panel's collapsed state;
--   char     the filter options, PER CHARACTER by the owner's requirement;
--   global   the schema stamp, the named presets (shared by every character) and LibDBIcon's table.
--
-- The Master controls rows are composed by LibKa0s-Options-1.0, so their values live here too: with
-- the library absent the schema has no `enabled` row, and a schema-only defaults tree would hand
-- AceDB a profile whose `enabled` reads nil, turning the addon off on that install.

NS.C = {
    PROFILE = {
        enabled        = true,    -- master switch (the `disabled` hold reads it)
        panelCollapsed = false,   -- the attached panel folded to its title bar (modules/Panel.lua)
    },

    CHAR_DEFAULTS = {
        filters = {
            keyTargeting = true,  keyLevel = 10,
            regionsEnabled = false, regions = {},          -- set: { oce = true, chi = true }
            noSameSpec = false,   noSameClassRole = false,
            experiencedLeader = false,
            maxAgeEnabled = false, maxAge = 15,
        },
    },

    -- schemaVersion is 0, never the current version (savedvariables-§1).
    GLOBAL_DEFAULTS = { schemaVersion = 0, presets = {}, minimap = { hide = false } },
}
