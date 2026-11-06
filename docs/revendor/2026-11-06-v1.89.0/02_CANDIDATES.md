# Candidates

Sources: the CHANGELOG blocks v1.86.0 to v1.89.0 (`git -C ../LibKa0s show v1.89.0:CHANGELOG.md`, lines 13-108) and the API documents of every moved major, new against old.

## A. Delivered on the re-vendor alone (not offered)

- **DebugLogDiagnostics 7** (CHANGELOG v1.86.0, line 102): the diagnostics report names `LibKa0s-IconBrowser-1.0` among the majors. Reaches `/pgfe` diagnostics with the copy.
- **Widgets 23, the flat path** (CHANGELOG v1.87.0, line 66; `docs/api/Widgets/version-23.5.12.6.7.5-docs.md`, "Every single-level menu, a dropdown's and a host's, is unchanged"): `core/WidgetsSetup.lua`'s `W.Dropdown` menus draw what minor 22 drew, and `NS.CloseMenu` (`W.CloseMenu`) still closes the menu.
- **Kit revision 51** (CHANGELOG v1.89.0, line 21): the CallbackHandler unregister guard in `mock_ace.lua`, a flake fix; the consumer owes only the re-vendor.

## B. Host change required

- **Widgets 23 `submenu` / `radio` / `selected` / `opts.check`** (Widgets 23 document, row-options table): `W.ContextMenu` row options only, and "a dropdown's rows ignore all three". This addon opens no `W.ContextMenu` of its own: `git grep -n 'ContextMenu'` outside the payloads finds only the comment at `modules/Panel.lua:148`, which describes the shared row options a dropdown's options use for `tooltip`. **Not applicable**: there is no host menu to cascade or tick. Recommendation: record, no issue.
- **Toast 4 stack** (CHANGELOG v1.88.0, line 43): opt-in `stack` fields and three instance members. This addon sends no toast (no `LibKa0s-Toast-1.0` lookup). **Not applicable**.

## C. Whole-module adoption

- **`LibKa0s-IconBrowser-1.0`** (CHANGELOG v1.86.0, lines 90-95; `docs/api/IconBrowser/version-1.1.1-docs.md`): an icon chooser window for a host that lets the player pick an icon. This addon has no icon chooser and stores no icon choice. Blast radius would be a whole new surface with no host need. **Settled** by the owner's run ruling (IconBrowser for every addon without an icon chooser: recorded, no issue).

No candidate outside the run plan's decisions table was found.
