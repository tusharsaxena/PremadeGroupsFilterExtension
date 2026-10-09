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

### test_regions.lua (10)

- regions: the module publishes its namespace table
- regions: normalize strips spaces, punctuation, case
- regions: suffixed leader resolves on US portal
- regions: leader without suffix uses the player's realm
- regions: EU realm with accent
- regions: unknown realm, nil/empty name, unsupported portal → nil
- regions: the same realm name resolves per portal
- regions: key and label tables cover all twelve buckets
- regions: data integrity — no realm in two buckets, only known keys
- regions: every bucket is populated

### test_targeting.lua (7)

- targeting: the module publishes its namespace table
- targeting: N=14 targets the four dungeons timed below 14
- targeting: N=15 targets all eight
- targeting: N=2 targets none
- targeting: never-timed counts as 0
- targeting: ToSet keys the targets by cmID
- targeting: level validation and range text

### test_season.lua (6)

- season: the module publishes its namespace table
- season: nil map table → nil (loading)
- season: empty map table → nil (loading)
- season: best timed from intimeInfo, untimed → 0, short from PGF keyword
- season: dungeon never run (GetSeasonBestForMap → nil) → best timed 0
- season: unknown mapID falls back to initials

### test_expression.lua (9)

- expression: clauses in fixed order
- expression: empty user text → bare block
- expression: user text is parenthesized so its OR cannot leak
- expression: re-apply is idempotent and replaces the block
- expression: strip restores the user text exactly
- expression: no clauses → user text only (block removed)
- expression: comment-only user text treated as empty (no `and ( )`)
- expression: damaged block (begin without end) → error, text untouched
- expression: over 2000 chars → toolong

### test_filters.lua (4)

- filters: clause opts honor enable flags and portal order
- filters: validation
- filters: set and region toggle write the live table
- filters: per-character defaults

### test_presets.lua (3)

- presets: save/load round-trip is a deep copy into the same table
- presets: list sorted, delete, bad names, missing
- presets: names are trimmed and saving overwrites

### test_envinject.lua (8)

- envinject: the module publishes its namespace table
- envinject: keywords follow PGF's formula
- envinject: unknown spec / role / missing table → nil keywords, no error
- envinject: samespec / sameclassrole from env counts
- envinject: spec change is picked up without re-apply
- envinject: PLAYER_SPECIALIZATION_CHANGED refreshes for the player only
- envinject: regions injected only without PremadeRegions
- envinject: stood down → hook is a no-op

### test_bridge.lua (12)

- bridge: the module publishes its namespace table
- bridge: seams present
- bridge: missing seam is named, no error
- bridge: SetDungeons maps cmID → positional key, shuffled order
- bridge: non-dungeon category → no state
- bridge: missing dungeon state table is created on the active category
- bridge: expression read clears focus first; commit inits + triggers; search clicks
- bridge: commit with minimized dialog writes state only
- bridge: dialog shown and accessor
- bridge: env hook installs once, as a post-hook on PGF's own function
- bridge: env hook refuses when the seam is missing
- bridge: HookDialog wires SwitchToPanel and both scripts

### test_apply.lua (10)

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

### test_panel.lua (25)

- panel: the module publishes its namespace table
- panel: anchored under PGF dialog, both edges
- panel: Create is idempotent
- panel: visible only for shown dialog on the dungeon category
- panel: created lazily, on the first UpdateVisibility that wants it
- panel: the dialog's SwitchToPanel is hooked at load
- panel: hidden when stood down, and the dialog hook is a no-op
- panel: region chips follow portal
- panel: a chip click toggles the region and its highlight
- panel: unsupported portal shows the note and no chips
- panel: range field shows N-N for the current level
- panel: typing into the range field puts the range back
- panel: typing a level writes keyLevel and updates the range; junk is ignored
- panel: readout highlights targeted dungeons, grays the rest
- panel: readout says loading until the season data arrives
- panel: checkboxes write their filter option
- panel: Refresh re-reads the filters into the widgets
- panel: Apply searches and prints; the range field follows
- panel: Apply does nothing while stood down
- panel: a missing PGF seam shows one line and disables Apply
- panel: collapse folds to the title bar and is remembered in the profile
- panel: preset Save as stores a named preset; Load refills the widgets
- panel: preset Delete removes the selected preset after confirming
- panel: Enter in the Save as box saves and closes the popup
- panel: a blank preset name is refused

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
| test_regions.lua | 10 |
| test_targeting.lua | 7 |
| test_season.lua | 6 |
| test_expression.lua | 9 |
| test_filters.lua | 4 |
| test_presets.lua | 3 |
| test_envinject.lua | 8 |
| test_bridge.lua | 12 |
| test_apply.lua | 10 |
| test_panel.lua | 25 |
| test_vendor_sync.lua | 3 |
| test_eol.lua | 2 |
| test_prose.lua | 15 |
| test_layout_cap.lua | 13 |
| test_diagnostics_contract.lua | 8 |
| test_lizard_sighted.lua | 8 |
| Skipped | 1 |
| **Total** | **186** |
