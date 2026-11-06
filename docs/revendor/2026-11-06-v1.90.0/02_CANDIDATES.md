# Candidates

Sources: the CHANGELOG block v1.90.0 (`git -C ../LibKa0s show v1.90.0:CHANGELOG.md`) and the API documents of every moved major, new against old.

## A. Delivered on the re-vendor alone (not offered)

- **Core 16 + Widgets 24 + WidgetsAutocomplete 8, one physical pixel** (CHANGELOG v1.90.0, *One physical pixel (`SF1-L1`)*; `docs/api/Widgets/version-24.5.12.6.8.5-docs.md`): `W.Dropdown`'s box and its shared menu take Core's pixel-exact backdrop. `core/WidgetsSetup.lua:29`'s `W.Dropdown` (every dropdown on the attached panel) gets a one-physical-pixel edge at any UI scale with no host change.
- **SkinPaint 19, SkinPaintExtras 18**: `P.px` and the pixel watch moved to Core; `P.pxEdge` sizes WoW Default's input edge on a pixel-exact holder. Internal.
- **OptionsAppearance 7**: a copy (*Apply to all* / *Copy to all*) leaves a `keepScope` owner's Scope alone. This addon is a copy target and source like any other; nothing changes for it.

## B. Host change required

- **Skin 17 `RegisterOwner(owner, { keepScope = true })`** (CHANGELOG v1.90.0, *A copy leaves a host's Scope alone (`SF1-L2`)*): an opt-out for a host whose documented Scope deviates from the library default. This addon registers at `core/SkinSetup.lua:519` with no documented Scope deviation, and the SF1 rulings give the opt-out to Ka0s Skin Tester alone (`SF1-ST`). **Not applicable**. Recommendation: record, no issue.

## C. Whole-module adoption

None: no new major in this range.
