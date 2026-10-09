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
