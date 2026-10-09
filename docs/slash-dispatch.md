# Slash dispatch — Ka0s Premade Groups Filter Extension

`/pgfe` and `/premadegroupsfilterextension` are registered with AceConsole in `OnInitialize` and
route to `LibKa0s-Slash-1.0`'s dispatcher (`settings/Slash.lua`), which owns parsing, help rendering,
the `key = value` formatting and the disabled refusal. `NS.COMMANDS` is the addon's ordered table of
positional triples `{name, desc, fn}`, passed in.

| Verb | Does | Answers while disabled |
|---|---|---|
| *(bare)* | Opens the settings panel | yes |
| `help` | Prints the command list | yes |
| `config` | Opens the settings panel | yes |
| `enable` / `disable` | Writes `enabled` through the write seam (the latch follows) | yes |
| `version` | Prints the version | yes |
| `list` / `get` / `set` / `reset` / `resetall` | The schema CLI | yes |
| `profile` | Lists profiles, or switches to one | yes (added to the live verbs) |
| `debug` | `debug` toggles the console window; `debug on|off` the logging flag; `debug diagnostics` the report | yes |
| `diagnostics` | Writes the diagnostics report to the console | yes |
| `perf` | The perf harness's workflow (`LibKa0s-Perf-1.0` answers) | yes |
| `apply` | `NS.Apply.Run{ search = true }`, then prints its message (a typed command is a hardware event, so it may search) | no |
| `clear` | `NS.Apply.Clear()`, then prints its message | no |

`apply` and `clear` are feature verbs, refused with the library's disabled line while the addon is
off. Their messages are the `MSG_*` keys in `locales/enUS.lua`, printed by `NS.Apply.Report`.

With LibKa0s absent the host stub routes the verbs itself, the schema CLI names the missing library,
and `enable` / `disable` / `profile` print the library-absent line without writing.
