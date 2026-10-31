Delta: LibKa0s v1.80.0 -> v1.83.0 (span: v1.80.0 v1.81.0 v1.82.0 v1.83.0)

# LibKa0s v1.80.0 to v1.83.0: the skin runs' re-vendors (Ka0s Premade Groups Filter Extension)

A consolidated span bundle, written by item FX-PG-DOCS of the 2026-10-31 findings remediation. Each
tag was vendored by a skin run, recorded in that run's Ka0sAddonsCommonTasks bundle, and given no
`docs/revendor/` folder here. The addon went from v1.77.0 straight to v1.80.0, so v1.78.0 and v1.79.0
were never vendored; their changes arrived inside v1.80.0.

The vendored commits (`git log --format='%h %ad %s' --date=short -- libs/LibKa0s tests/_kit`):

```text
44ccc1d 2026-10-29 PG-RV: Re-vendor LibKa0s v1.80.0 from the local tag
28dccb2 2026-10-30 PG-RV: Re-vendor LibKa0s v1.81.0 from the local tag
ad2b8fd 2026-10-30 PG-01: Re-vendor LibKa0s v1.82.0 with the stubs and facades it needs
b03ecb4 2026-10-31 PG-F01: Re-vendor LibKa0s v1.83.0, default the outline to HUD text only
253a183 2026-10-31 PG-RV2: Take the re-cut LibKa0s v1.83.0 (LK-A1, LK-A2)
e6bbce4 2026-10-31 PG-RV3: Take the re-cut LibKa0s v1.83.0 (LK-A3, the skin picker's rows)
```

The bundles that planned them are `docs/2026-10-29-SKINNING_ROLLOUT/`,
`docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/`, `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/` and
`docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/` in Ka0sAddonsCommonTasks.
