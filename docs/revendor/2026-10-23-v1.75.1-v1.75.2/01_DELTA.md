Delta: LibKa0s v1.75.1 -> v1.75.2 (span: v1.75.1 v1.75.2)

# LibKa0s v1.75.1 and v1.75.2: carried by sweep (Ka0s Premade Groups Filter Extension)

A consolidated span bundle, written by item PG-RV of the 2026-10-23 run alongside
`docs/revendor/2026-10-23-v1.76.0/`. Both tags were vendored by the 2026-10-23 post-run fix branches
without a bundle of their own. Each re-vendor replaced `libs/LibKa0s/SimPanel.lua` only (kit 41
unchanged), and PGFE consumes no Sim surface.

The two listing commands (the 3h walk of `/dev-copilot:wow-revendor-libka0s`, horizon `2026-10-22`):

```sh
# vendored: the provenance tag at every payload commit and every CLAUDE.md roll since the horizon
v1.75.0
v1.75.1
v1.75.2
# recorded: the tags the store's bundles name
v1.75.0
# vendored, unrecorded
v1.75.1
v1.75.2
```

```sh
git log --format='%h %ad %s' --date=short 3975ef6^..3e12554 -- libs/LibKa0s tests/_kit CLAUDE.md
# 3e12554 2026-10-23 Re-vendor LibKa0s v1.75.2 (SimPanel minor 4)
# 0740b82 2026-10-23 Re-vendor LibKa0s v1.75.1 (SimPanel minor 3)
# 3975ef6 2026-10-23 PG-RV2: refresh LibKa0s v1.75.0 payload from the moved local tag
```
