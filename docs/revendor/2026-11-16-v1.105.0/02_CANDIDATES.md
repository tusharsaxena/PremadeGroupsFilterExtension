# 02 Candidates, LibKa0s v1.93.0 -> v1.105.0

Sources: `git -C ../LibKa0s log --oneline v1.93.0..v1.105.0`; the LibKa0s CHANGELOG.md blocks v1.94.0 to v1.105.0 (v1.105.0's *What a consumer owes*); Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/03_ADOPTION_PLAN.md` and research note R8.

**Class A, delivered on the copy alone**
- Library tooltips placed by `LibKa0s-Tooltip-1.0` (#92 part B): dropdown entries, the launcher's tooltip, the debug console's marks.
- Header marks with a settings mark on every library window (#86 library half): the debug console, the copy window, the skin picker.
- The debug console's status line on `W.Footer` (#90) and plain-text Copy (#79 library half).
- Skin colors: Ka0s Default's rows (stripe .08, hover .16, selection .26) and seven skins' `icon.hot` (#82, #84). This addon copies no Ka0s Default fallback values.
- OptionsWidgets 46: a slider box reverts junk text on Enter and on focus loss.
- Media 13: two more faces in the font pickers (Bebas Neue, Russo One).

**Class B, host change required (candidates, owed in phase [3])**
- **#92** tooltip placers: `modules/Panel.lua:127` and `:154` call `GameTooltip:SetOwner(..., "ANCHOR_RIGHT")`; move both onto the placers.
- **DefaultSkin** (skinning-§2 MUST since v1.94.0, Skin minor 18): the profile default should name `Skin.DefaultSkin()`. On Retail the answer is still `"ka0s"`, so nothing changes on screen. It is a compliance gap, listed first in the adoption plan.
- **#79** `D:Report`: no multi-line report verb found besides diagnostics, which already writes to the console. Confirm at adoption.
- **#86** `W.HeaderButtons`: not applicable. The addon has no window of its own, only the panel attached to the LFG frame.
- **#87** `Sim.Sample`: not applicable. The addon has no sim or preview data.
- **#85, #88, #89**: not applicable (no Callout candidate, no test strip, no footer of its own).

**Class C, whole-module**: none offered. Majors in the payload this addon does not look up: Bus, Callout, Charts, Glow, IconBrowser, Item, Perf, Pool, Role, Sim, Toast, Tooltip (a #92 candidate above), WaypointArrow.

**Blockers (3g)**: none.
