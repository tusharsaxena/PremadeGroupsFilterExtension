local _, NS = ...
-- core/Constants.lua — NS.Constants.LAYERS, the one layers table (frame-layering-§5).
--
-- Every strata and frame-level write in the addon reads this table; no SetFrameStrata takes a
-- literal and no SetFrameLevel takes an absolute number. The addon's whole stack, lowest first
-- ("host" is PGF's dialog, PremadeGroupsFilterDialog, FULLSCREEN in PGF's UI/Dialog.xml today):
--
--   minimap button          MEDIUM, LibDBIcon's own level                  (library, not ours)
--   Settings canvas pages   HIGH, the Blizzard SettingsPanel; levels inside are LibKa0s-Options'
--   StaticPopups            DIALOG (Blizzard), when no panel is visible
--   debug console           DIALOG, toplevel (LibKa0s-DebugLog-1.0); its copy window FULLSCREEN
--   the attached panel      the HOST's strata, read (host-matched surface, frame-layering-§1),
--                           at host level + LEVEL.ABOVE_HOST = L
--     header art clips and their NineSlice copies   L + LEVEL.HEADER_ART (sunk to the panel)
--     body, min/max arrow, header click, template   L + 1 (child default)
--     body widgets (checks, edit boxes, dropdowns, buttons, hover frame)   L + 2
--   PGFE StaticPopups shown while the panel is visible   STRATA.POPUP, lifted and put back
--                           (core/Popup.lua; a borrowed confirmation, T8)
--   dropdown menus          FULLSCREEN_DIALOG (Blizzard_Menu)
--   tooltips                TOOLTIP (GameTooltip)
--
-- The panel covers the Settings panel when both are open (FULLSCREEN over HIGH): it layers with
-- its host, a ratified row in docs/ARCHITECTURE.md -> Documented deviations. The debug console can
-- sit under the panel for the same reason (developer-facing; the descriptor takes no strata yet).

NS.Constants = NS.Constants or {}

NS.Constants.LAYERS = {
    STRATA = {
        -- A PGFE StaticPopup shown while the FULLSCREEN panel is visible: one strata above it, so
        -- the Save as edit box is never drawn under PGF's dialog or the panel.
        POPUP = "FULLSCREEN_DIALOG",
    },
    LEVEL = {
        -- Over the host's level. A child defaults to its parent + 1, which is where PGF's own
        -- border (its NineSlice) sits; with the two borders overlapping by the panel's raise, the
        -- client drew PGF's bottom border over the panel's title strip in no fixed order (owner
        -- screenshot). Raised clear of it, the panel always draws on top.
        ABOVE_HOST  = 5,
        -- The two clipped header-art copies sit AT the panel's level: a child default (+1) ties
        -- with the min/max arrow and the close button and leaves their draw order to chance.
        HEADER_ART  = 0,
    },
}
