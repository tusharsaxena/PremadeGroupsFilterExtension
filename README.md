# Ka0s Premade Groups Filter Extension

![WoW](https://img.shields.io/badge/WoW-Midnight_12.1.0-purple)
![License](https://img.shields.io/badge/License-MIT-orange)
![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
![Tests](https://img.shields.io/badge/Tests-199%2F199_passing-green)

A small companion to [Premade Groups Filter](https://www.curseforge.com/wow/addons/premade-groups-filter) for Mythic+. You type the key level you want to push, and it ticks every dungeon you haven't timed at that level yet. It can also narrow the list to leaders from the server regions you pick, hide groups that already have your spec, ask for a leader who has timed the dungeon, and drop old listings. One Apply button sets all of it in Premade Groups Filter and runs the search.

It doesn't replace Premade Groups Filter's filtering. It sets the same checkboxes and the same advanced filter you could set by hand, so you can always see and edit what it did. Premade Groups Filter has to be installed; without it this addon doesn't load.

## Screenshots

I'll add screenshots of the panel under Premade Groups Filter's dialog here with the first CurseForge release.

## Usage

Open the Group Finder, start a Mythic+ search and open Premade Groups Filter's dialog on the dungeon category. The extension's panel sits right under that dialog and is exactly as wide. Switch Premade Groups Filter to another category, or close it, and the panel goes away with it.

Type a key level and the panel lists your best timed level in each dungeon this season. The ones you still need at that level show in gold, the rest in gray. Turn on whatever else you want (regions, composition, experienced leader, group age) and press **Apply**. Premade Groups Filter's dungeon checkboxes and advanced filter update, and the search runs.

The game doesn't let addons type into the Group Finder's search box, so the panel shows the key range as text, for example `14-14`. Click it, press Ctrl+C, click the search box and press Ctrl+V if you also want to search listings by title.

Filter choices are saved per character. Presets let you store a setup under a name and load it on any character. **Clear** takes the extension's part back out of the advanced filter and leaves anything you typed there yourself. If the panel is in your way, the button in its top corner folds it down to the title bar.

`/pgfe apply` does what the Apply button does, so it works in a macro. Like the button, it only runs while Premade Groups Filter is on the dungeon category.

Everything else is under **Settings → AddOns → Ka0s Premade Groups Filter Extension**, and `/pgfe help` (or `/premadegroupsfilterextension help`) prints the command list.

## How the filtering works

- The addon reads your season's dungeons and your best timed run in each one from the game.
- Every dungeon you haven't timed at your chosen level gets ticked in Premade Groups Filter, and the rest get unticked. Premade Groups Filter passes that list on to the game's own dungeon filter.
- Your other choices become a short block in Premade Groups Filter's advanced filter. The block is marked with comments, so you can see where it starts and ends, and anything you wrote yourself still applies on top of it.
- For each group in the results, the addon adds a few values Premade Groups Filter doesn't have on its own: the leader's server region, and whether the group already has your spec or your class in your role. The filter block uses those.
- Apply then presses Premade Groups Filter's search button for you.

## FAQ

| Question | Answer |
|---|---|
| Can it fill in the search box for me? | No. The game blocks addons from typing into it. Copy the range from the panel and paste it. |
| Do I need PremadeRegions? | No. If you have it, its region data is used. If you don't, the addon uses its own realm list. |
| Why does it need Premade Groups Filter? | It works through Premade Groups Filter's own checkboxes and advanced filter, so there is nothing for it to do on its own. |
| Does it change anything I typed in the advanced filter? | No. Apply adds its own marked block around your text, and Clear removes only that block. |
| Are my settings shared between characters? | Filter choices are per character. Presets are shared by all your characters. |

## Troubleshooting

| Symptom | Fix |
|---|---|
| The addon doesn't load | Premade Groups Filter must be installed and enabled. |
| The panel shows "PGF version not supported" | Premade Groups Filter changed in an update. Report it (see below) and include your Premade Groups Filter version. |
| Apply says it can't run in combat | Wait until combat ends and press it again. |
| Apply asks you to open Premade Groups Filter on the Dungeons category | Switch Premade Groups Filter's dialog to Dungeons, then press Apply again. |
| The panel says season data is loading | The game sends it a few seconds after login. Wait, then look again. |
| Apply says the [pgfe] block is damaged | The lines between the `-- [pgfe]` markers in the advanced filter were changed by hand. Delete the block, markers included, and press Apply again. |
| Something looks wrong and I want to report it | Follow [Reporting a bug](#reporting-a-bug) below. |

## Reporting a bug

- Type `/pgfe debug on` and reproduce the bug.
- Type `/pgfe diagnostics`.
- If the debug window isn't open, open it with `/pgfe debug`. Press **Copy**, copy the entire output, and include it with your bug report.

The report is added after the debug trace in the same window, so one copy carries both.

## Issues and feature requests

Please file bugs and ideas as [GitHub issues](https://github.com/tusharsaxena/PremadeGroupsFilterExtension/issues). That list is the backlog, so a request left in a comment somewhere else can get lost.

## Version History

| Version | Date | Highlights |
|---|---|---|
| 0.1.0 | in development | - First release: untimed-dungeon targeting by key level, server regions, composition and experienced-leader filters, group age, presets |

## Credits

- [Premade Groups Filter](https://www.curseforge.com/wow/addons/premade-groups-filter) by Bernhard Saumweber, which this addon extends.
- PremadeRegions, used as a reference when building the realm-to-region list.
