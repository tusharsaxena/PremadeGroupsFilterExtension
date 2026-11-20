# 04 Execution plan, LibKa0s v1.107.0 -> v1.108.0

1. SD-RV-PGFE: copy both payloads from the tag, roll `CLAUDE.md:52` to v1.108.0, keep the `LibKa0s icons:` line, prune, gate; restamp the vendored quirks catalog in `docs/midnight-quirks.md` to v2.116.0 (its text is unchanged since v2.115.0); regenerate `docs/test-cases.md` and the README badge for the kit's new case. One commit.
2. SD-SK-PGFE: declare every painted surface in `tests/skin_surfaces.lua` per kit revision 58 (the audit's guard coverage holes), with smoke checks for anything that moves on screen. Its own commit.

No addon Lua changes in item 1; no characterization test owed.
