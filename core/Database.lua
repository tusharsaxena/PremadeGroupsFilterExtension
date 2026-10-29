local _, NS = ...
-- core/Database.lua — the schemaVersion migration runner (savedvariables-§1).
--
-- The defaults tree is built by settings/Schema.lua's Settings.BuildDefaults (profile rows from the
-- schema, plus defaults/Profile.lua's char and global tables) and handed to AceDB in OnInitialize.
-- global.schemaVersion defaults to 0, never the current version: AceDB strips a value equal to its
-- default at logout and would backfill it onto a legacy account.

-- The runner's target: the highest step below.
NS.SCHEMA_VERSION = 2

--- True when EllesmereUI is here to skin with: the library provider's `eui` condition
--- (EllesmereUI.RegisterSkin and its Blizzard Skin child loaded), read at OnInitialize, which
--- `## OptionalDeps: EllesmereUI` puts after EllesmereUI loaded. Never a read of EllesmereUI's saved variables.
local function euiPresent()
    local status = NS.SkinEUIStatus and NS.SkinEUIStatus()
    for _, c in ipairs(type(status) == "table" and status.conditions or {}) do
        if c.key == "eui" then return c.ok == true end
    end
    return false
end

-- 1 -> 2 (the skinning rollout's PG-06, owner ruling O4): the addon's own EllesmereUI bridge is
-- retired for LibKa0s's `eui` source, and the player's stored choice carries over. `euiSkin`
-- defaulted to true and AceDB strips defaults, so a profile WITHOUT the key chose the skin too: every
-- profile but an explicit `false` moves to `skin.source = "eui"`, but only when EllesmereUI is here
-- (DECISIONS D3), so a player without it does not find EllesmereUI selected on the Skin tab. Without
-- EllesmereUI, or switched off, the profile keeps the default Ka0s source, written as nothing. No
-- released version stored `skin.*` before this step (AceDB has already copied the defaults into the
-- active profile, so a stored "ka0s" could not be told from the default anyway). The old key goes
-- either way. Walks every profile raw (db.sv.profiles): the step is global, run once per account.
local function migrateEUISkin(db)
    local profiles = db and db.sv and db.sv.profiles
    if type(profiles) ~= "table" then return end
    local present = euiPresent()
    for _, p in pairs(profiles) do
        if type(p) == "table" then
            local was = p.euiSkin
            p.euiSkin = nil
            if was ~= false and present then
                if type(p.skin) ~= "table" then p.skin = {} end
                p.skin.source = "eui"
            end
        end
    end
end

-- Each step is idempotent against a fresh default database.
NS.MIGRATIONS = {
    [1] = function(_db) end,  -- 0 -> 1: the stamp itself; nothing to reshape
    [2] = migrateEUISkin,     -- 1 -> 2: profile.euiSkin -> profile.skin.source (PG-06)
}

function NS:RunMigrations()
    local g = self.db and self.db.global
    if not g then return end
    local from = g.schemaVersion or 0
    local v = from
    while v < NS.SCHEMA_VERSION do
        local step = NS.MIGRATIONS[v + 1]
        if step then step(self.db) end
        v = v + 1
        g.schemaVersion = v   -- the runner owns the stamp; reached only if the step returned
    end
    local D = NS.DebugLog
    if from ~= g.schemaVersion and D and D.DebugAtEnable then
        D.DebugAtEnable("Migrate", "v%s -> v%s", from, g.schemaVersion)
    end
end
