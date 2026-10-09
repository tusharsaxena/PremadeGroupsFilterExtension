-- tests/prose_waivers.lua -- the per-file, per-word waivers the kit's prose gate reads
-- (tests/_kit/test_prose.lua, localization-§5).
--
-- A waiver is localization-§5's MAY for a British spelling that is not this repository's English to
-- correct: per file AND per word, with the reason beside it. The kit skips this file by name, so a
-- reason may name the word it is about.

return {
    waived = {
        -- Game data: "Greymane" is a US realm name (Chicago data center), spelled by Blizzard. The
        -- map matches the client's realm name, so respelling it is a realm that never resolves.
        ["defaults/Realms.lua"] = { grey = true },
    },
}
