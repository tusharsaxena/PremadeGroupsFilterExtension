# Realm map maintenance

The server-region filter resolves a group leader's realm to one of twelve buckets through a static
map, `defaults/Realms.lua` (`NS.RealmLists`), read by `modules/Regions.lua`. Blizzard publishes no
in-client API for a realm's data center or language, so the map is data this repository owns and
has to keep current.

## What the map holds

| Portal | Bucket | Meaning |
|---|---|---|
| US | `oce` | Realms hosted in Sydney (Oceanic) |
| US | `la` | Realms hosted in the Los Angeles data center (US Pacific and US Mountain) |
| US | `chi` | Realms hosted in the Chicago data center (US Central and US Eastern), minus the two buckets below |
| US | `mex` | Blizzard's Latin America realms (hosted in Chicago) |
| US | `bzl` | Blizzard's Brazil realms (hosted in Chicago) |
| EU | `eng` `ger` `fra` `ita` `spa` `por` `rus` | Realm language |

The portal is `GetCurrentRegion()` (1 = US, 3 = EU). Korea, Taiwan and China answer `nil` and the
filter does nothing there. The same realm name on both portals is two different realms (Area 52 is
`chi` on US and `ger` on EU), which is why the map is keyed per portal.

Matching runs through `NS.Regions.Normalize`: ASCII lowercase, then every whitespace and ASCII
punctuation byte dropped. Leader names arrive as `Name-RealmWithoutSpaces`, so `Aman'Thul`,
`AmanThul` and `Aman Thul` all match. Non-ASCII bytes are compared exactly (Lua's `string.lower`
does not touch them), so accented and Cyrillic names must be spelled byte for byte as the client
spells them, including the case of a Cyrillic capital and the ASCII apostrophe.

## When to run the check

- At the start of each season (the same pass that updates the season dungeon data).
- After Blizzard announces new realms, realm connections that move a realm between data centers,
  realm renames, or realm closures.
- When a player reports a group landing in the wrong region bucket.

## How to run it

From the repo root:

```sh
python3 tools/realm_map_diff.py "<WoW>/_retail_/Interface/AddOns/PremadeRegions/Regions.lua"
```

An optional second argument points at a different copy of `defaults/Realms.lua`. The tool reads
both files as text, normalizes names exactly like `NS.Regions.Normalize`, and prints one line per
difference:

- `ADDED <portal> <key> <realm>`: PremadeRegions lists a realm this map lacks.
- `REMOVED <portal> <key> <realm>`: this map lists a realm PremadeRegions lacks.
- `MOVED <portal> <key> <realm> [ours: <key>]`: both list it, in different buckets.

Exit status is 0 when the maps agree, 1 when they differ, 2 on a usage or parse error. A difference
is a lead, not a verdict: PremadeRegions can be stale too.

## How to verify a difference

Check each line against warcraft.wiki.gg before changing the map:

- US data centers: <https://warcraft.wiki.gg/wiki/US_realm_list_by_datacenter> (Chicago, Los
  Angeles and Australia sections; Latin America and Brazil realms are listed under Chicago).
- US Latin America / Brazil / Oceanic membership and every EU language bucket:
  <https://warcraft.wiki.gg/wiki/Realms_list> ("Servers in the Americas and Oceania" and
  "Servers in Europe").
- A single realm's status (open, closed, connected, renamed): its `Server:<Name> US` or
  `Server:<Name> Europe` page on the same wiki.

Take the realm's spelling from the in-game realm list or the Blizzard realm status page when the
wiki and PremadeRegions disagree on spelling. Then edit `defaults/Realms.lua`: one name per line,
sorted case-insensitively within its bucket. Record the change and its reason in
**Source reconciliation** below.

## Gate

`lua tests/run.lua` must stay green after any change to the map. The `regions:` cases in
`tests/test_regions.lua` pin the lookup rules (suffix, no suffix, accents, unknown realm,
unsupported portal) and the data integrity rules: no realm in two buckets of one portal, no
unknown bucket key, no empty bucket. `luacheck .` must stay at 0 warnings / 0 errors. A realm name
the prose gate reads as a British spelling is game data: waive it per file and per word in
`tests/prose_waivers.lua` rather than respelling it.

## Source reconciliation

### 2026-10-09: initial map

Seed: PremadeRegions 3.0.7 (`Regions.lua`, `PR.US_REGION_REALMS` and `PR.EU_REGION_REALMS`),
used as a reference source for factual realm names only; no code was copied. Cross-checked against
warcraft.wiki.gg on 2026-10-09 (the datacenter page was last edited 27 July 2025).

Result: 246 US realms and 267 EU realms, identical to the seed.

| Area | Seed | warcraft.wiki.gg | Resolution |
|---|---|---|---|
| US `oce` | 12 realms | Australia section: the same 12 | Agree |
| US `la` | 96 realms | Los Angeles section: the same 96 (beta and test realms excluded) | Agree |
| US `chi` | 130 realms | Chicago section: 138 realms, the same 130 plus the 8 below | Agree. The wiki lists the Latin America and Brazil realms under Chicago because that is where they are hosted; the map keeps them in their own buckets |
| US `mex` | Drakkari, Quel'Thalas, Ragnaros | Latin America section: the same 3 | Agree |
| US `bzl` | Azralon, Gallywix, Goldrinn, Nemesis, Tol Barad | Brazil section: the same 5 | Agree |
| EU `ger` | 87 realms | German section: the same 87 | Agree (`Kil'jaeden` vs `Kil'Jaeden` differ in ASCII case only) |
| EU `fra` | 37 realms | French section: the same 37 | Agree (`Kael'thas` vs `Kael'Thas` and `Rive noire` vs `Rive Noire` differ in ASCII case only) |
| EU `spa` | 11 realms | Spanish section: the same 11 | Agree |
| EU `rus` | 20 realms | Russian section: the same 20 | Agree on membership. The wiki spells `Пиратская бухта` with a lowercase б; the seed spells `Пиратская Бухта`. Non-ASCII case is compared exactly, so the spelling matters: kept the seed's capital Б, which is the client's realm name |
| EU `ita` | Nemesis, Pozzo dell'Eternità | Italian section: the same 2 | Agree. The wiki writes a typographic apostrophe (’) in `Pozzo dell’Eternità`; the client uses the ASCII apostrophe, which `Normalize` drops. Kept the ASCII form |
| EU `por` | `Aggra (Português)` | No Portuguese section; `Aggra` is listed under English | Kept in `por`. The realm's wiki page describes it as the European Portuguese community realm (connected to Grim Batol), and the client names it `Aggra (Português)` |
| EU `eng` | 109 realms | English section: 114 realms | The seed's 109 plus `Aggra` (see `por` above) and Molten Core, Shadowmoon, Stonemaul, Warsong. Those four were Russian-migration realms closed shortly after Wrath of the Lich King launched in Europe (their `Server:<Name> Europe` pages say the realm no longer exists). Not added: a closed realm never appears on a listing |
