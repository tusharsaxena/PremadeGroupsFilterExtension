# Region colors setting — design (2026-10-15)

## Ask

Owner: "add a setting to display all the region colors, and add a color selector to change them."

## Design

- **Storage.** One profile key per region bucket, `regionColors.<key>` (`oce`, `la`, `chi`, `mex`,
  `bzl`, `eng`, `ger`, `fra`, `ita`, `spa`, `por`, `rus`), each `{ r, g, b, a }` in 0..1: the
  library color widget's default shape and what `/pgfe set` parses a color into, so no codec. The
  defaults move from `RegionTags.COLORS` to `defaults/Profile.lua` (`REGION_HEX`, savedvariables-§2).
  Profile scope, like `showRegionTags`. Additive: no migration.
- **Schema.** Twelve `type = "color"` rows, `hasAlpha = false` (a `|c` escape has no alpha), in a
  new General-page group *Region colors*, between *Filters* and *EllesmereUI skin*. They get the
  CLI (`/pgfe get|set|reset regionColors.<key>`) and both resets for free.
- **Display.** A host tab: per portal a heading, a preview line with every tag in its current
  color (a refresher, so it follows every write), then the portal's pickers three to a line. A
  *Reset region colors* button puts the twelve defaults back as one bulk act.
- **Paint.** `RegionTags.Hex(key)` reads the stored color and caches the hex per stored table:
  every write stores a new table, so the row-paint hot path stays one read and one compare.
- **Throttle.** The descriptor gains `scheduleTimer` (C_Timer.After) so a picker drag commits at
  most every 50 ms.

## Standard

No deviation: schema-driven settings (architecture-§5), defaults in `defaults/`, locale strings in
`locales/enUS.lua`, the tab is its own group (options-ui-§13), Master controls untouched (§15).
