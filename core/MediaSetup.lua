local addonName, NS = ...
-- core/MediaSetup.lua — NS.Icon / NS.MediaFont from LibKa0s-Media-1.0 and the one RegisterLSM call.
--
-- The monospace face ships inside the vendored payload (library-stack-§8); of the icon catalog, the
-- payload ships only the icons CLAUDE.md's `LibKa0s icons:` line declares (library-stack-§7).
-- Every call passes the addon's own FOLDER name: the library is vendored and cannot know which
-- folder it was copied into, and a wrong texture path draws nothing and raises nothing.

local Media = LibStub and LibStub("LibKa0s-Media-1.0", true)

--- The texture path for one shipped icon, or nil (library absent, or no such name).
--- @param name string
--- @return string|nil
function NS.Icon(name)
    if not Media then return nil end
    return Media.Icon(addonName, name)
end

--- The path of one shipped face, or nil when the library is absent.
--- @param name string
--- @return string|nil
function NS.MediaFont(name)
    if not Media then return nil end
    return Media.Font(addonName, name)
end

-- At FILE LOAD: LibSharedMedia is vendored under libs/ and has already run.
if Media then Media.RegisterLSM(addonName) end
