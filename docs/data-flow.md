# Data flow — Ka0s Premade Groups Filter Extension

The engineer view of the README's *How the filtering works*. Four pipelines: Apply (and Clear),
the per-result env hook PGF calls during filtering, the attached panel's refresh, and the region tag
painted on Group Finder rows.

## Apply

`modules/Apply.lua`'s `Apply.Run(opts)`. Every refusal is decided before anything is written; each
return is `ok, msgKey, ...` and `Apply.Report` prints `NS.L[msgKey]:format(...)`.

1. **Trigger.** The panel's Apply button `OnClick` (`Apply.Run{ search = true }`), or a typed
   `/pgfe apply`. Both are hardware events, which the search needs.
2. **Prechecks.** `InCombatLockdown()` → `MSG_COMBAT`. `Bridge.Check()` names a missing PGF seam →
   `MSG_NO_PGF`. `Bridge.IsDungeonCategory()` false (the dialog is on another category, or was
   never opened) → `MSG_NOT_DUNGEONS`. `Bridge.IsDungeonPanelActive()` false (the dialog is
   minimized, so PGF filters with its mini panel and the dungeon state would not take effect) →
   `MSG_MINIMIZED`. *Toggle PGF Extension Filters* off (`profile.filtersActive`) →
   `MSG_INACTIVE`. Every write of that setting runs `Apply.OnFiltersToggled`: off runs Clear, on runs
   Apply without a search, both only while PGF's dungeon panel is up.
3. **Smart level.** With `smartKeyLevel` on, `Filters.ApplySmartLevel()` sets `keyLevel` to
   `Targeting.SmartLevel(Season.GetDungeons())`: the lowest best timed level + 1, clamped 2–40.
   No season data yet: the stored level stands (and step 5 refuses with `MSG_LOADING` when key
   targeting is on). Smart off: nothing changes. This is the one write before the refusals below,
   and it lands in `char.filters` only, never in PGF's state.
4. **Validation.** `Filters.Validate()`: key level an integer 2–40 (`MSG_BAD_LEVEL`), max age an
   integer 1–240 when on
   (`MSG_BAD_AGE`). Regions are never refused: on an unsupported portal, or on with Any
   selected for this portal (none, or every one), they add no clause; playstyles likewise.
5. **Targets** (only when key targeting is on). `Season.GetDungeons()` gives
   `{ cmID, name, short, bestTimed }` per season dungeon; nil while
   `C_ChallengeMode.GetMapTable()` is empty → `MSG_LOADING`. `Targeting.Compute(dungeons, N)` keeps
   the rows with `bestTimed < N` (never timed = 0). Empty → `MSG_ALL_TIMED`.
6. **Expression.** `Filters.ToClauseOpts(portal)` → `Expression.BuildClauses` →
   `Expression.Merge(Bridge.GetExpression(), clauses)`. The read clears the edit box's focus first,
   so text the player is still typing is committed by PGF before it is read. A damaged block →
   `MSG_DAMAGED`; over 2000 characters → `MSG_TOOLONG`. Block format:
   [`ARCHITECTURE.md` → Expression block format](ARCHITECTURE.md#expression-block-format).
7. **Writes.** `Bridge.SetDungeons(Targeting.ToSet(targets))` ticks row `i` when its `cmId` is a
   target and clears it otherwise (positional keys `dungeon1..8`, mapped by scanning the rows, never
   hard-coded). `Bridge.SetExpression(text)`. Both land in `activeState.dungeon`.
8. **Commit.** `Bridge.Commit()`: when the dungeon panel is the active panel, `panel:Init(state)` and
   `panel:TriggerFilterExpressionChange()`, which re-filters and has PGF copy the ticked dungeons into
   the game's own advanced filter (`UpdateAdvancedFilters`). Minimized: nothing more; PGF re-reads the
   stored state on the next `SwitchToPanel`.
9. **Search.** `Apply.LastRange = "N-N"` with key targeting on, and `nil` with it off (no range was
   targeted); with `opts.search`, `Bridge.Search()` clicks
   `PremadeGroupsFilterDialog.RefreshButton`. Returns `MSG_APPLIED` with the count of PGF rows actually ticked (`Bridge.SetDungeons`' return) and
   the range, or `MSG_APPLIED_NO_TARGETING` when key targeting is off; that message carries no range. The panel's copy box
   (*Copy into search box*) shows the level box's `N-N`, not the last applied one, and is empty
   (dimmed and disabled) while key targeting is off.

With key targeting off, step 5 is skipped and PGF's dungeon checkboxes are left as they are.

## Clear

`Apply.Clear()`: the same prechecks, then `Expression.Merge(text, {})` (strip only), write the
expression back, commit. Dungeon checkboxes are untouched; a damaged block refuses (`MSG_DAMAGED`).

## Per search result

PGF builds one `env` per result, counts the members into it (`<spec>_<class>s`,
`<roleprefix>_<class>s`, …) and then calls `PGF.PutPremadeRegionInfo(env, leaderName)`. The
`hooksecurefunc` post-hook installed at file load runs `EnvInject.Apply(env, leaderName)`:

1. Stood down → return.
2. `env.pgfe_on = Filters.IsActive()` (the managed block's guard: `not pgfe_on or ( … )` is neutral
   while *Toggle PGF Extension Filters* is off and when the hook did not run).
3. `PremadeRegions` not loaded → every region key `false`, then
   `Regions.GetRegion(leaderName)`: portal from `GetCurrentRegion()` (1 US, 3 EU, else nil), realm
   from the `-Realm` suffix or `GetRealmName()` when there is none, `Regions.Normalize` (lowercase,
   whitespace and ASCII punctuation dropped), lookup in the per-portal table built once from
   `NS.RealmLists`. Sets `env.region` and `env[region] = true`.
4. `env.pgfe_samespec` and `env.pgfe_sameclassrole` from the two cached player keywords.

PGF then evaluates the expression, including the addon's block, against that env.

## The attached panel

`modules/Panel.lua`. `Panel.UpdateVisibility()` runs from the dialog hook (`SwitchToPanel`,
`OnShow`, `OnHide`), on `PLAYER_ENTERING_WORLD` and on stand-up. It shows the panel iff the addon is
not stood down, the dialog is shown, and its active panel is the dungeon panel (on Dungeons and not
minimized); the frame is built on the
first call that wants it. Every show runs `Panel.Refresh()`, which first recomputes the Smart level
(`Filters.ApplySmartLevel`, when on and not stood down), then reads `char.filters` into the widgets
(the level box locked and grayed under Smart), rebuilds the best-timed readout (one line, its gaps closed to one space when it overflows; gold for
targets, gray otherwise, and "loading…" while season data is missing) and the copy box, and lays the frame out (collapsed: the title strip only, drawn by two
clipped copies of the border layout; or the "not supported" line when `Bridge.Check()` fails, which
also disables Apply). Three events, `CHALLENGE_MODE_MAPS_UPDATE`, `CHALLENGE_MODE_COMPLETED` and
`MYTHIC_PLUS_CURRENT_AFFIX_UPDATE`, recompute the Smart level (the panel need not exist) and rebuild
the readout; under Smart they also rewrite the level box and copy box.

The season-data request (`C_MythicPlus.RequestMapInfo()`) belongs to `Season.GetDungeons()`, not to
the readout, so every reader (the panel, Apply, Smart) asks and none asks twice. It goes out once per
episode: `Season.RequestOnce()` sends only while unarmed. It is re-armed on `PLAYER_ENTERING_WORLD`
(`Season.ResetRequest()`, so a lost request recovers on the next loading screen) and on the
full -> empty rollover of the map table (the first empty read after a full one resets and sends in
the same call; later empty reads send nothing). The reply event never triggers a second request,
which is what kept off-season clients in a request/reply loop before. Widget handlers write through `Filters.Set` / `Filters.ToggleRegion` /
`Filters.TogglePlaystyle` / `Filters.ToggleComposition` / the three `Filters.Clear*` functions
(`ClearRegions`, `ClearPlaystyles`, `ClearComposition`: each dropdown's Any entry) /
`Filters.SetActive` (the first box, through the schema write seam) / `Presets.*` and return at once
when stood down; so do the tooltip handlers.

## Region tags

Blizzard repaints a Group Finder row through `LFGListSearchEntry_Update(entry)` and an applicant
through `LFGListApplicationViewer_UpdateApplicantMember(member, appID, memberIdx, …)`. The
`hooksecurefunc` post-hooks `modules/RegionTags.lua` installs at file load run after each:

1. Stood down, `showRegionTags` off, or `PremadeRegions` loaded (it paints the same tag) → return.
2. The name: `C_LFGList.GetSearchResultInfo(entry.resultID).leaderName`, or the first return of
   `C_LFGList.GetApplicantMemberInfo(appID, memberIdx)`.
3. `RegionTags.Tag(name)`: nil for a non-string or not concat-safe name (events-frames-taint-§8) or
   an unsupported portal; `Regions.GetRegion` (the same lookup as the env hook) gives the bucket,
   colored from `RegionTags.COLORS`; an unknown realm gives a gray `?`.
4. The row's own font string (`ActivityName`, `Name`) gets `SetText(tag .. " " .. text)`.
