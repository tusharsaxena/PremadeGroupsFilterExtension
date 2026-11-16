local _, NS = ...
-- core/Compat.lua — the sole home of every version-variant client call this addon makes (compat).
--
-- Retail only: shims cross-patch API differences, never game flavors. The player's specialization
-- moved to C_SpecializationInfo in 11.x, so the reader is routed through LibKa0s-Compat-1.0, which
-- prefers C_SpecializationInfo and falls back to the global. modules/EnvInject.lua is the caller.

NS.Compat = NS.Compat or {}
local Compat = NS.Compat

local CompatLib = LibStub and LibStub("LibKa0s-Compat-1.0", true)

-- Contract: the active specialization index, or nil. Library absent: nil (its documented answer).
Compat.GetSpecialization = CompatLib and CompatLib.GetSpecialization or function() return nil end

-- Contract: the rung's own returns (specID, name, description, icon, role, ...), or a single nil.
Compat.GetSpecializationInfo = CompatLib and CompatLib.GetSpecializationInfo
    or function() return nil end

-- The identity readers (LibKa0s v1.94.0, Compat minor 4), wired so any future character- or
-- realm-keyed read goes through them. No caller in this tree yet. Library absent: the Retail
-- answers (no regional names, UnitName, "Name - Realm", GetRealmName()).
Compat.RegionalNames = CompatLib and CompatLib.RegionalNames or function() return false end

Compat.UnitCharacterName = CompatLib and CompatLib.UnitCharacterName or function(unit)
    if not unit or not UnitName then return nil, nil end
    return UnitName(unit)
end

Compat.CharacterKey = CompatLib and CompatLib.CharacterKey or function()
    local name = UnitName and UnitName("player")
    local realm = GetRealmName and GetRealmName()
    if type(name) ~= "string" or name == "" or type(realm) ~= "string" or realm == "" then return nil end
    return name .. " - " .. realm
end

Compat.RealmKey = CompatLib and CompatLib.RealmKey or function()
    local realm = GetRealmName and GetRealmName()
    if type(realm) ~= "string" or realm == "" then return nil end
    return realm
end
