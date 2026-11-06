# Candidates

Sources: the CHANGELOG block v1.91.0 (`git -C ../LibKa0s show v1.91.0:CHANGELOG.md`) and the API documents of every moved major, new against old.

## A. Delivered on the re-vendor alone (not offered)

- **WidgetsLineChart 7, line-chart lines in physical pixels** (CHANGELOG v1.91.0, *The line chart's lines in physical pixels (`FU-L1`)*): the chart's axis, grid, markers, crosshair and series draw in physical pixels. This addon draws no line chart, so nothing changes on its screens.
- **Core 17 + CorePixel 1, Widgets 26 + WidgetsDropdown 1, SkinPaintExtras 19 + SkinPaintHud 1 + SkinAceConfirm 1** (CHANGELOG v1.91.0, *The band files peeled (`FU-L2`)*): pure moves of code into new files. No member, option or behavior changes. The only thing the host owes is the loader list (01_DELTA, Blockers).

## B. Host change required

None. No new public surface, descriptor field or row type in this range.

## C. Whole-module adoption

None: no new major in this range.
