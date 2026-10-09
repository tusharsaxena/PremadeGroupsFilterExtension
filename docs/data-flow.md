# Data flow — Ka0s Premade Groups Filter Extension

The engineer view of the README's *How the filtering works*. Stages marked with a plan task are not
built yet.

## Apply (plan Task 7)

1. **Trigger.** The panel's Apply button `OnClick`, or a typed `/pgfe apply` (both hardware events).
2. **Guards.** Refuse in combat; refuse if a PGF seam is missing (`Bridge.Check`), or PGF's dialog is
   not on the dungeon category; validate the options (`Filters.Validate`).
3. **Targets.** `Season.GetDungeons()` (cmID, short name, best timed level) → `Targeting.Compute(…, N)`
   → the set of cmIDs with best timed < N. Empty → "you have timed every dungeon at +N".
4. **Dungeon checkboxes.** `Bridge.SetDungeons(set)` maps each cmID to PGF's positional `dungeonN`
   key by scanning the panel's rows. PGF's `UpdateAdvancedFilters` later copies the ticked dungeons
   into the game's own advanced filter.
5. **Expression.** `Expression.BuildClauses(opts)` → `Expression.Merge(userText, clauses)`: a block
   between `-- [pgfe] begin` / `-- [pgfe] end` markers, parenthesized together with the user's own
   text so precedence cannot leak. Over 2000 characters or a damaged block aborts.
6. **Commit.** Write PGF's state, `panel:Init(state)`, `panel:TriggerFilterExpressionChange()`.
7. **Search.** `PremadeGroupsFilterDialog.RefreshButton:Click()`.

## Per search result (plan Task 6)

PGF builds an `env` per result and calls `PGF.PutPremadeRegionInfo(env, leaderName)`. The addon's
`hooksecurefunc` post-hook (installed at file load) then sets `pgfe_samespec` and
`pgfe_sameclassrole` from the env's spec and role counts, and — only when PremadeRegions is not
loaded — the `region` variables from the addon's realm map. PGF then evaluates the expression.

## Clear

Strip the marked block, write the expression back, commit. Dungeon checkboxes are left alone.
