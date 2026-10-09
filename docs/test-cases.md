# Test Cases

The full inventory of every headless test case in this repo, grouped by the suite file it
lives in. The `## Totals` table below counts the cases that run: its **Total** is the
authoritative pass count, and the README test badge and any count quoted in the docs must equal
it. A declared skip is listed by name in its group and counted on the `Skipped` row, never in
Total.

**Generated — do not hand-edit.** Regenerate with `lua tests/run.lua --list > docs/test-cases.md`.

### test_harness.lua (8)

- harness: the load list is derived from the TOC, in TOC order
- harness: every factory returns (NS, env, mock) with env and mock the same table
- harness: the PGF fake is installed before the addon loads
- harness: factory opts seed the mock fields
- harness: client-data mock fields answer through their APIs
- harness: hooksecurefunc is a real post-hook on a table member
- harness: fireEvent dispatches to AceEvent handlers
- harness: the explicit LibKa0s list matches LibKa0s.xml, in XML order (anti-pattern #48)

### test_surface_parity.lua (10)

- parity: the Core seam's namespace surface survives the library's absence
- parity: the DebugLog stub carries the whole live surface
- parity: the Slash stub carries the whole live surface
- parity: the Options helpers stub carries the whole live surface
- parity: the Schema host stub's instance carries the whole live instance surface
- parity: the Schema host stub carries the library's own members
- parity: the Launcher stub carries the whole live surface
- parity: the Lifecycle stub carries the whole live surface
- parity: the Perf stub carries every member the addon calls
- parity: the Compat arm carries every library member the addon wires

### test_setup.lua (14)

- setup: NS is the AceAddon object, with the cyan [PGFE] tag
- setup: NS.Print is reclaimed from AceConsole and is NS.Util.print
- setup: per-character filter defaults (char.filters)
- setup: global defaults hold the presets store and LibDBIcon's table
- setup: profile defaults hold the master switch and the panel's collapsed state
- setup: migrations stamp the schema version
- setup: the Master controls rows are in the schema, frameless
- setup: the Minimap button row inverts onto LibDBIcon's hide
- setup: enable registers the settings category and the launcher, and stands up
- setup: the debug console is built with the addon's folder and brand
- setup: the perf harness is wired to the lifecycle latch, with no bucket declared yet
- setup: the Compat spec readers route through LibKa0s-Compat-1.0
- setup: the media seam names this addon's folder
- setup: the landing page lists every NS.COMMANDS row

### test_slash.lua (6)

- slash: NS.COMMANDS is ordered positional triples with every reserved verb
- slash: /pgfe and /premadegroupsfilterextension are registered through AceConsole
- slash: disable and enable write the Enable row through the write seam
- slash: perf answers through the harness and prints its lines
- slash: the library-absent stub pins the library's disabled line
- slash: the library-absent stub still answers version and refuses enable honestly

### test_disabled.lua (5)

- disabled: a feature event is registered at enable and UNREGISTERED at disable
- disabled: enable rebuilds from current state
- disabled: the perf hold stands the addon down through the same latch
- disabled: a profile stored disabled stands down at the next enable
- disabled: every verb keeps answering while disabled

### test_regions.lua (11)

- regions: the module publishes its namespace table
- regions: normalize strips spaces, punctuation, case
- regions: suffixed leader resolves on US portal
- regions: leader without suffix uses the player's realm
- regions: EU realm with accent
- regions: unknown realm, nil/empty name, unsupported portal → nil
- regions: a non-string leader name → nil, no error
- regions: the same realm name resolves per portal
- regions: key and label tables cover all twelve buckets
- regions: data integrity — no realm in two buckets, only known keys
- regions: every bucket is populated

### test_targeting.lua (9)

- targeting: the module publishes its namespace table
- targeting: N=14 targets the four dungeons timed below 14
- targeting: N=15 targets all eight
- targeting: N=2 targets none
- targeting: never-timed counts as 0
- targeting: ToSet keys the targets by cmID
- targeting: level validation and range text
- targeting: SmartLevel is the lowest best timed level + 1
- targeting: SmartLevel counts never-timed as 0, clamps to 2..40, nil without rows

### test_season.lua (6)

- season: the module publishes its namespace table
- season: nil map table → nil (loading)
- season: empty map table → nil (loading)
- season: best timed from intimeInfo, untimed → 0, short from PGF keyword
- season: dungeon never run (GetSeasonBestForMap → nil) → best timed 0
- season: unknown mapID falls back to initials

### test_expression.lua (11)

- expression: clauses in fixed order
- expression: empty user text → bare block
- expression: user text is parenthesized so its OR cannot leak
- expression: re-apply is idempotent and replaces the block
- expression: strip restores the user text exactly
- expression: no clauses → user text only (block removed)
- expression: comment-only user text treated as empty (no `and ( )`)
- expression: damaged block (begin without end) → error, text untouched
- expression: over 2000 chars → toolong
- expression: the block passes everything when the env hook did not run
- expression: without the hook, the user's own text still decides

### test_filters.lua (11)

- filters: clause opts honor enable flags and portal order
- filters: regions on with none selected for this portal filters on no region
- filters: playstyles on with some ticked filter on those, in the game's order
- filters: validation
- filters: set and region toggle write the live table
- filters: per-character defaults
- filters: ticking the last unticked option clears the set to Any
- filters: a stored all-ticked set is Any: no clause, and a tick selects that option alone
- filters: clearing empties this portal's regions and the playstyles
- filters: ApplySmartLevel sets the level from the season only when Smart is on
- filters: composition applies only while its box is on

### test_presets.lua (5)

- presets: save/load round-trip is a deep copy into the same table
- presets: list sorted, delete, bad names, missing
- presets: names are trimmed and saving overwrites
- presets: a preset missing keys loads over the current defaults
- presets: Smart travels with a preset; an older preset loads the default (on)

### test_envinject.lua (10)

- envinject: the module publishes its namespace table
- envinject: keywords follow PGF's formula
- envinject: unknown spec / role / missing table → nil keywords, no error
- envinject: samespec / sameclassrole from env counts
- envinject: the spec is read through Compat when the deprecated globals are gone
- envinject: spec change is picked up without re-apply
- envinject: PLAYER_SPECIALIZATION_CHANGED refreshes for the player only
- envinject: regions injected only without PremadeRegions
- envinject: stood down → hook is a no-op
- envinject: the block's guard is off while Toggle PGF Extension Filters is off

### test_regiontags.lua (8)

- regiontags: a search row gets the leader's colored region in front of its activity
- regiontags: a leader on the player's own realm, an unknown realm, an unsupported portal
- regiontags: EU realms are tagged by language
- regiontags: an applicant gets their region in front of their name
- regiontags: no tag while stood down, with the setting off, or with PremadeRegions loaded
- regiontags: the setting is a schema row, on by default
- regiontags: a name that is not a plain string gets no tag and raises nothing
- regiontags: every region bucket has a color

### test_bridge.lua (13)

- bridge: the module publishes its namespace table
- bridge: seams present
- bridge: missing seam is named, no error
- bridge: SetDungeons maps cmID → positional key, shuffled order
- bridge: non-dungeon category → no state
- bridge: missing dungeon state table is created on the active category
- bridge: expression read clears focus first; commit inits + triggers; search clicks
- bridge: commit with minimized dialog writes state only
- bridge: the dungeon panel is active only while maximized on Dungeons
- bridge: dialog shown and accessor
- bridge: env hook installs once, as a post-hook on PGF's own function
- bridge: env hook refuses when the seam is missing
- bridge: HookDialog wires SwitchToPanel and both scripts

### test_euibridge.lua (15)

- euibridge: the module publishes its namespace table and the skin name
- euibridge: four conditions, in display order, each with a label and a hint
- euibridge: everything on opens the gate, and there is no why
- euibridge: EllesmereUI absent closes every condition, without raising
- euibridge: the window-skin child not loaded closes the gate at eui
- euibridge: an EllesmereUI without RegisterSkin is not ready
- euibridge: the master switch off closes the gate at master, and only master
- euibridge: our own entry off closes the gate at own
- euibridge: PGF's skin entry off closes the gate at pgf
- euibridge: PGF's skin addon not loaded closes the gate at pgf
- euibridge: nil switches read as on (EllesmereUI's own nil = on)
- euibridge: WhyClosed lists every failing hint, one per line
- euibridge: the reads are live, at call time
- euibridge: a raising or absent C_AddOns reads as not loaded
- euibridge: nothing is ever written to EllesmereUI's saved variables

### test_apply.lua (16)

- apply: the module publishes its namespace table
- apply: N=14 ticks AOF/RLP/BV/KR, writes block, triggers, searches
- apply: everything timed → refuses, nothing written
- apply: combat, wrong category, missing PGF seam, loading
- apply: invalid options refuse before anything is written
- apply: key targeting off leaves checkboxes alone; no search when not requested
- apply: keeps user text; clear restores it
- apply: a damaged managed block refuses Apply and Clear
- apply: /pgfe apply searches and prints; /pgfe clear prints
- apply: /pgfe apply prints the refusal with its argument
- apply: after Apply then /pgfe disable, PGF's evaluation passes groups again
- apply: PGF minimized → refuses Apply and Clear, nothing written or searched
- apply: the message counts the rows ticked, and says so when targeting is off
- apply: with Smart on, Run sets the key level from the season bests first
- apply: refuses while Toggle PGF Extension Filters is off, writing nothing
- apply: the filtersActive setting is a schema row, and its writes remove / rewrite the block

### test_panel.lua (72)

- panel: the module publishes its namespace table
- panel: anchored under PGF dialog, both edges
- panel: Create is idempotent
- panel: visible only for shown dialog on the dungeon category
- panel: hidden while PGF's dialog is minimized
- panel: created lazily, on the first UpdateVisibility that wants it
- panel: the dialog's SwitchToPanel is hooked at load
- panel: hidden when stood down, and the dialog hook is a no-op
- panel: the dialog hook body returns at once while stood down
- panel: the region dropdown lists this portal's regions
- panel: ticking a region writes it and keeps the menu open; the button sums up
- panel: a long selection is summed up as a count
- panel: unsupported portal shows the note instead of the region dropdown
- panel: the playstyle dropdown uses the game's names and writes the playstyles
- panel: a tick while stood down writes nothing
- panel: range field shows N-N for the current level
- panel: typing into the range field puts the range back
- panel: a level commits on Enter / focus loss, never per keystroke
- panel: the age box commits whole values and re-syncs a rejected one
- panel: readout highlights targeted dungeons, grays the rest
- panel: readout says loading until the season data arrives
- panel: checkboxes write their filter option
- panel: Refresh re-reads the filters into the widgets
- panel: Apply searches and prints; the range field follows
- panel: after an Apply the range field still follows the level
- panel: Apply does nothing while stood down
- panel: a missing PGF seam shows one line and disables Apply
- panel: collapse folds to the title bar and is remembered in the profile
- panel: a profile switch refreshes the attached panel's layout
- panel: preset Save as stores a named preset; Load refills the widgets
- panel: preset Delete removes the selected preset after confirming
- panel: Enter in the Save as box saves and closes the popup
- panel: a blank preset name is refused
- panel: the score box commits a whole rating and re-syncs a rejected one
- panel: each number box is anchored to the right of its own label
- panel: the expanded height fits every row
- panel: the min/max arrow follows the stored collapsed state
- panel: collapsed shows only the header strip, drawn by two clipped border copies
- panel: expanded keeps the template's own border; the header copies hide
- panel: a saved collapsed state shows the header strip on the first Refresh
- panel: without NineSliceUtil the collapse still folds, with no header copies
- panel: the header copies sit at the panel's own level, under the arrow
- panel: a successful Apply focuses the range box; Enter there focuses the search box
- panel: the arrow art is swapped between the min/max buttons
- panel: the regions and playstyle dropdowns are 225 wide, right-aligned in one column
- panel: each menu opens with Any and a divider; Any is ticked with nothing ticked and clears
- panel: ticking every option stores Any and the button reads Any
- panel: a stored all-ticked set reads Any; a tick then selects that option alone
- panel: the readout is one row high, so the rows below keep the same pitch
- panel: a readout too wide for its row closes the gaps to one space
- panel: every checkbox has a tooltip, and its label hovers and clicks as the box
- panel: every number box, button and the copy box and its label have a tooltip
- panel: each dropdown and every menu entry has a tooltip
- panel: tooltips stay quiet while stood down
- panel: presets: one row, the dropdown up to three equal buttons right-aligned
- panel: Apply and Clear share one width, with extra space above their row
- panel: the copy box is right-aligned on the action row, its label before it, clear of Clear
- panel: Smart sits right of the level box; ticked, it locks the box and sets the level
- panel: the level box locked by Smart still shows its tooltip
- panel: Smart keeps the stored level until season data arrives, then follows it
- panel: with Smart off, season data leaves the level box alone
- panel: Smart writes nothing while stood down
- panel: the level row fits the body: label, box, Smart and its label
- panel: a fresh character sees the owner's default panel
- panel: the presets row has the same extra space above as below, buttons as tall as the dropdown
- panel: Composition is one dropdown; Any clears, both ticked stays both (not Any)
- panel: Toggle PGF Extension Filters is the first row, on by default
- panel: unticking Toggle PGF Extension Filters removes the block; ticking writes it back
- panel: presets never switch the extension on or off
- panel: the title is centered on the whole header
- panel: the copy box and its label dim and disable while key targeting is off
- panel: the panel's frame level is above PGF's dialog and its border

### test_euiskin.lua (22)

- euiskin: the module publishes its namespace table
- euiskin: registers once, at file load, under the folder name
- euiskin: EllesmereUI absent registers nothing and leaves the panel stock
- euiskin: every condition on, the login dispatch paints the built panel
- euiskin: a dispatch before the panel exists keeps S, and Panel.Create paints
- euiskin: TryApply is idempotent
- euiskin: any one failing condition keeps the panel stock
- euiskin: a condition turned off mid-session refuses a later paint
- euiskin: our switch off keeps S and paints nothing; turning it on paints live
- euiskin: turning the switch off after a paint asks for a reload and does not unpaint
- euiskin: turning the switch off before any paint asks for nothing
- euiskin: master off at login, turned on in EllesmereUI later, paints live
- euiskin: stood down, the callback paints nothing; the stand-up paints
- euiskin: a profile switch to one with the switch on paints
- euiskin: skinned, the collapsed panel is the shell's 25px bar and the metal copies are hidden
- euiskin: skinned, the panel hangs 2px below PGF's dialog, both edges
- euiskin: the min/max buttons get the minus (collapse) and the plus (expand)
- euiskin: checkboxes shrink to 24, row boxes stay on their row, hit rects follow the label
- euiskin: the accent ring follows the check, and not while stood down
- euiskin: only the title is whitened; readout, copy label and number boxes keep their color
- euiskin: live looks and scale changes repaint without raising
- euiskin: the diagnostics dependencies section reports the gate and the skin

### test_euisettings.lua (12)

- euisettings: euiSkin is a schema row, default on, in its own group on the General page
- euisettings: the General page's tabs are Master controls, then EllesmereUI skin
- euisettings: the tab draws a line per condition, a state line, then the switch
- euisettings: each failing condition disables the switch and is named on its line
- euisettings: a re-show re-reads the lines and the switch after EllesmereUI changed
- euisettings: the switch's tooltip says why it is disabled, live
- euisettings: /pgfe set euiSkin true is refused, with the reason, while a condition fails
- euisettings: a bulk reset is never refused
- euisettings: the switch on paints live through the write seam; off asks for a reload
- euisettings: the state line names what is waiting
- euisettings: a gate opened in EllesmereUI's options paints on the panel's next show
- euisettings: LibKa0s absent with EllesmereUI present loads, registers and keeps the row

### test_vendor_sync.lua (3)

- libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles
- tests/_kit is the test kit that shipped with that release
- the automated-test runner is recorded executable (100755)

### test_eol.lua (2)

- eol: every tracked file carries the terminator .gitattributes declares for it
- eol: .gitattributes is line-endings-§5's canonical body for this repo kind

### test_prose.lua (15)

- prose: no authored file carries a British spelling from localization-§5's published list
- prose: the gate carries localization-§5's two lists whole, and nothing of its own
- prose self-test: the carve-out suppresses the named generated folder, and only it
- prose self-test: a path the carve-out does not name is not covered by one that looks like it
- prose self-test: a carve-out that is not a set of path strings is a failure, not a silence
- prose self-test: a TOC's file lines are read as paths, and its directives and comments are not
- prose self-test: a .pkgmeta's ignore block is read, and the keys around it are not
- prose self-test: an ignore entry covers a path exactly, by folder, and by wildcard
- prose self-test: the carve-out admits a generated dump and refuses a file the TOC loads
- prose self-test: a waiver-file exclusion meets the same two refusals as the carve-out
- prose self-test: each list is refused on the matching rule its own scan uses
- prose self-test: the scan and the refusals read the added exclusions through one reader
- prose self-test: a narrowing is refused by what it suppresses, not by how it is written
- prose self-test: the disclosure names what each entry suppressed, and says when it is bounded
- prose self-test: a malformed waived is a failure, not a silence

### test_layout_cap.lua (13)

- layoutcap: every authored file over the 1500-line cap is named in the census
- layoutcap: no census row outlives the breach it records
- layoutcap: every over-cap census row carries one of layout-§1's three terminal states
- layoutcap: the census and the exempt set agree about which paths were exempted
- layoutcap: an empty census is written as a result rather than left standing empty
- layoutcap self-test: the parser reads the census nested under the register, and stops there
- layoutcap self-test: a census outside its register, or at the wrong level, is not read
- layoutcap self-test: an over-cap file missing from the census is reported, and an exempt one is not
- layoutcap self-test: a census row that outlives its breach is reported
- layoutcap self-test: an over-cap row that names no terminal state is reported
- layoutcap self-test: the census and the exempt set are held to naming the same paths
- layoutcap self-test: a census that states nothing is told apart from one that states none
- layoutcap self-test: the exempt set takes folders as well as paths

### test_diagnostics_contract.lua (9)

- diagnostics contract: both forms run the report
- diagnostics contract: the debug word is matched in any case
- diagnostics contract: both markers carry the brand and the end counts the report
- diagnostics contract: the report appends after what the console already holds
- diagnostics contract: the report lands with logging off and turns it on for the session
- diagnostics contract: an addon that opts out lands the report and leaves logging off (skipped: this addon keeps the default (Kit.diagnostics.enablesLogging is not false), so its report turns logging on; the case above holds it)
- diagnostics contract: with logging already on, the report writes no second enable line
- diagnostics contract: both forms run while the addon is disabled
- diagnostics contract: no other name runs the report

### test_lizard_sighted.lua (8)

- lizard sighted: every hazard lizard loses a function over is neutralized
- lizard sighted: fields, strings, comments and look-alike names come through unchanged
- lizard sighted: a method definition is rewritten to its dot form with self
- lizard sighted: no line is added or removed, CRLF included
- lizard sighted: countFunctions counts the keyword, not strings, comments or longer names
- lizard sighted: listedCounts reads the per-file table, once per file
- lizard sighted: parity names every file whose counts differ, and only those
- lizard sighted: lizard lists every function of a hazard fixture once it is sanitized

## Totals

| Suite | Cases |
|-------|------:|
| test_harness.lua | 8 |
| test_surface_parity.lua | 10 |
| test_setup.lua | 14 |
| test_slash.lua | 6 |
| test_disabled.lua | 5 |
| test_regions.lua | 11 |
| test_targeting.lua | 9 |
| test_season.lua | 6 |
| test_expression.lua | 11 |
| test_filters.lua | 11 |
| test_presets.lua | 5 |
| test_envinject.lua | 10 |
| test_regiontags.lua | 8 |
| test_bridge.lua | 13 |
| test_euibridge.lua | 15 |
| test_apply.lua | 16 |
| test_panel.lua | 72 |
| test_euiskin.lua | 22 |
| test_euisettings.lua | 12 |
| test_vendor_sync.lua | 3 |
| test_eol.lua | 2 |
| test_prose.lua | 15 |
| test_layout_cap.lua | 13 |
| test_diagnostics_contract.lua | 8 |
| test_lizard_sighted.lua | 8 |
| Skipped | 1 |
| **Total** | **313** |
