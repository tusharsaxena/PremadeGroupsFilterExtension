# Common tasks — Ka0s Premade Groups Filter Extension

## Add a master setting (a schema row)

1. Add the default value to `NS.C.PROFILE` in `defaults/Profile.lua`.
2. Add the row in `settings/Schema.lua` (or as a composed row in `settings/Panel.lua`) with a
   `section`, `group`, `label` and `tooltip`, and an `enUS` key for every label and tooltip.
3. Cover it in a suite; `lua tests/run.lua`, `luacheck .`.

## Add a filter option (per character)

1. Add the default to `NS.C.CHAR_DEFAULTS.filters` in `defaults/Profile.lua`.
2. Read and write it through `modules/Filters.lua`; feed it to `Expression.BuildClauses` via
   `Filters.ToClauseOpts`; add its widget in `modules/Panel.lua`.
3. Update `docs/schema.md`.

## Add a slash verb

Append a positional triple `{ "verb", L["description"], function(rest) ... end }` to `NS.COMMANDS`
in `settings/Slash.lua`, add the `enUS` key, and test it through `NS.addon:OnSlashCommand("verb")`.
The landing page and `/pgfe help` pick it up automatically.

## React to a game event

Append `{ "EVENT_NAME", "MethodName" }` to `NS.FEATURE_EVENTS` at file load and define
`NS.addon:MethodName()`. It is registered on enable, unregistered on stand-down and re-registered on
stand-up. Put any teardown in `NS.STAND_DOWN` and its rebuild in `NS.STAND_UP`.

## Hook PGF

Only in `core/PGFBridge.lua`, with `hooksecurefunc` at file load, nil-guarded, and a body that
returns at once when `NS.IsStoodDown()`. Record the seam (PGF file:line) in `docs/ARCHITECTURE.md`.

## Add a locale string

Add `L["English text"] = "English text"` to `locales/enUS.lua` and use `NS.L["English text"]`.

## Re-vendor LibKa0s

Run `/dev-copilot:wow-revendor-libka0s`; it copies both payloads and moves the `CLAUDE.md` provenance
line in the same commit. Never edit `libs/` or `tests/_kit/` by hand.
