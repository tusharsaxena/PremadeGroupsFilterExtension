# Dependencies — Ka0s Premade Groups Filter Extension

What you need installed to build, run, test or release this addon. Commands are for
**WSL2 / Ubuntu** (the collection's development environment). How to *verify* the addon once you
are set up is [`docs/testing.md`](docs/testing.md); this file only covers *what to install*.

Every entry says what needs it and how that is known. Anything only plausibly required is marked as
such rather than listed as a requirement.

## Runtime (in-game) — what a player needs

- **World of Warcraft (Retail).** Single `## Interface: 120100` line in
  `PremadeGroupsFilterExtension.toc` — Retail only.
- **Premade Groups Filter — required.** `## Dependencies: PremadeGroupsFilter` in the TOC: the
  client will not load this addon without it. This addon drives PGF's own dungeon checkboxes and
  Advanced Filter Expression and hooks PGF's per-result filter environment, so it has no function
  without PGF. A hard dependency is a documented deviation from `library-stack-§6` / `toc-file-§1`
  (`docs/ARCHITECTURE.md` -> `## Documented deviations`). Verified against PGF 7.6.2.
- **PremadeRegions — not needed.** This addon replaces it: its own realm map fills PGF's `region`
  variables, and `modules/RegionTags.lua` puts the region tag on Group Finder rows and applicants.
  It stays first in `## OptionalDeps:` only so that, if a player still has it loaded, this addon
  sees it at load and steps aside (PGF's variables come from it, and this addon paints no second
  tag).
- **EllesmereUI, EllesmereUI Blizzard Skin and Premade Groups Filter - EllesmereUI Skin —
  optional.** `## OptionalDeps: EllesmereUI`, presence-guarded (library-stack-§6): without them the
  panel keeps its Blizzard look and nothing else changes. With all three (EllesmereUI's third-party
  skinning and both addons' Third-Party Addons entries on) the attached panel is painted in the
  EllesmereUI theme (`modules/EUISkin.lua`). Read against EllesmereUI 9.4 and
  PremadeGroupsFilter_EllesmereUI 1.1.0.
- **Nothing else.** Every library is vendored under `libs/` and committed (library-stack), so the
  player installs no separate library addon. The rest of `## OptionalDeps:` names the vendored libs
  for load ordering, not as things to download.

## Development — the contributor toolchain

| Tool | Version | Needed for | Evidence |
|---|---|---|---|
| `lua5.1` (+ `luac`) | **5.1 exactly** | the headless suite, `lua tests/run.lua` | `tests/_kit/loader.lua` and `tests/loader.lua` use `setfenv` |
| `luacheck` | any recent | `luacheck .`, the other half of the green gate | `.luacheckrc` at the repo root |
| `lizard` | any recent | the `complexity` suite of `tests/_kit/run-automated-tests.sh`, which runs it over a sanitized shadow because `lizard` alone is blind in Lua (automated-tests-§3) | `lizard --version` |
| `git` | any recent | vendoring, the vendor gate's comparison against the LibKa0s checkout, the line-ending gate | `tests/_kit/vendor_sync.lua`, `tests/_kit/test_eol.lua` |
| POSIX shell (`bash`) | any | the automated-test runner and the commands in this file | `tests/_kit/run-automated-tests.sh` |

**Lua 5.1 is a requirement, not a preference.** The harness sandboxes each source file with
`setfenv`, which was removed in 5.2 — "5.2 will probably work" is false and costs an hour to
disprove.

The vendor gate (`tests/test_vendor_sync.lua`) compares `libs/LibKa0s/` and `tests/_kit/` against a
sibling checkout of [LibKa0s](https://github.com/tusharsaxena/LibKa0s) at `../LibKa0s`. Without that
checkout its two payload cases report SKIP with the reason, never PASS.

```sh
# Lua 5.1 and luacheck
sudo apt-get update
sudo apt-get install -y lua5.1 luarocks
sudo luarocks install luacheck

# lizard — via pipx, NOT pip. Ubuntu 24.04 marks its Python EXTERNALLY-MANAGED (PEP 668),
# so `pip install lizard` fails; pipx installs it into its own venv and puts it on PATH.
sudo apt-get install -y pipx
pipx ensurepath          # then open a new shell, or: source ~/.bashrc
pipx install lizard

# verify — each of these must print a version
lua5.1 -v                # Lua 5.1.5 …   (if `lua` is not 5.1, use lua5.1 explicitly)
luacheck --version
lizard --version
git --version
```

Versions are pinned only where a version matters: `lua5.1` is hard, `luacheck` and `lizard` are
"any recent" and pinning them would be false precision.

## Release / assets

**One entry: Python 3 with Pillow**, and only for **regenerating** the launcher logo from its
source. `media/logos/premadegroupsfilterextension.logo.128.tga` (128×128, uncompressed 32-bit) and the larger landing-page
render `media/logos/premadegroupsfilterextension.logo.tga` are committed, so nothing is generated at package time. The
recipe (layout-§4), run by hand when `media/logos/premadegroupsfilterextension.logo.png` changes:

```sh
sudo apt-get install -y python3-pil
python3 -c 'from PIL import Image; Image.open("media/logos/premadegroupsfilterextension.logo.png").convert("RGBA").resize((128, 128), Image.LANCZOS).save("media/logos/premadegroupsfilterextension.logo.128.tga", format="TGA")'
python3 -c 'import PIL; print(PIL.__version__)'   # verify
```

**None of this group is required to build, run or test the addon.**

## Am I set up correctly?

```sh
lua tests/run.lua                                     # the suite — must be green
luacheck .                                            # must be 0 warnings / 0 errors
bash tests/_kit/run-automated-tests.sh --suite complexity   # the sighted complexity report (release-time);
                                                      # never raw `lizard`, which is blind in Lua (automated-tests-§3)
```

See `docs/testing.md` for what those commands mean and when each is run.
