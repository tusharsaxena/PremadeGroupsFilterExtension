# Candidates: LibKa0s v1.75.2 -> v1.76.0 (Ka0s Premade Groups Filter Extension)

Sources: `git -C ../LibKa0s log --oneline v1.75.2..v1.76.0`, the v1.76.0 block of the tag's
`CHANGELOG.md` (lines 13-102), and the tag's `docs/api/` documents for the two majors whose minors
moved (`Widgets/version-14.1.4.3.2-docs.md`, `Sim/version-2.3.5-docs.md`). The run's item spec
(PG-RV, `Ka0sAddonsCommonTasks/docs/2026-10-23-SIM_PREVIEW_MODE_STRIPS/plan-data/items.json`) says to
list the candidates and not to interview or adopt; the run's own items carry every adoption, and none
of them is in PGFE. 3g found no blockers.

## A. Reached the addon on the re-vendor alone (delivered)

| Change | Evidence | Why it is free |
|---|---|---|
| Widgets 14: `TestStrip` without a `kind` draws exactly what it drew | `docs/api/Widgets/version-14.1.4.3.2-docs.md:27-37` | PGFE builds no strip; DebugLog's own Widgets use is unchanged |
| Docs-only: `docs/releasing.md` re-look step, standard v2.87.0 pointer | `CHANGELOG.md:70-82` | Library-side; no minor moves |

## B. Host change required (listed, not offered)

| Surface | Evidence | Not adopted, because |
|---|---|---|
| `W.TestStrip(parent, { kind = "sim" })`, `strip.kind` (Widgets 14) | `CHANGELOG.md:49-68`; `docs/api/Widgets/version-14.1.4.3.2-docs.md:27,33` | The run's adopters are BankLedger, DropWatcher, LootHistory, MultiMeters and KickCD. PGFE has no Show window, no test mode and no simulator. Additive if ever taken |

## C. Whole-module adoption (listed, not offered)

| Major | Evidence | Not adopted, because |
|---|---|---|
| `LibKa0s-Sim-1.0` (Sim 2.3.5: auto-run, Run all removed) | `CHANGELOG.md:26-47`; `docs/api/Sim/version-2.3.5-docs.md:347` | Settled at v1.75.0 (`docs/revendor/2026-10-22-v1.75.0/03_DECISIONS.md`): PGFE has no test mode and no simulator. The auto-run changes the verb layer of an existing host, not that premise |
| `LibKa0s-Widgets-1.0` as a direct lookup | as B | No PGFE surface draws a library widget; the only strip-shaped need is absent |
