# Changelog

All notable changes to BattleForAzerothUI are documented here.

---

## [2.4] - 2026-03-04

### Fixed
- **Retail engine:** Action bar, MultiBarBottomLeft/Right, pet bar, and stance bar now position correctly
- **Retail engine:** Added `ClearAllPoints()` before all `SetPoint()` calls on Edit Mode-managed bars, preventing conflicting anchors
- **Retail engine:** MultiBarBottomRight 2-row wrap now targets `MultiBarBottomRightButtonContainer` frames (correct retail API) instead of individual buttons
- **Retail engine:** Repositioning is now reactive — `hooksecurefunc` on bar `SetPoint` and the `EDIT_MODE_LAYOUTS_UPDATED` event reapply layout whenever Edit Mode or the game engine moves bars
- **Retail engine:** Combat handling improved via `PLAYER_REGEN_ENABLED` event to apply deferred layout changes after leaving combat
- **Retail engine:** Stance bar global corrected to `StanceBar` (retail) vs `StanceBarFrame` (Classic Era)

- **Classic Era:** Adjusted micro button and backpack button vertical positions (`y: 4→0` and `y: 47→43`) for better alignment in the bottom-right corner
- **Retail engine:** Fixed `MultiBarBottomRight` anchor point from `LEFT/RIGHT` to `TOPLEFT/TOPRIGHT` — incorrect anchor caused the frame to drift lower than expected after each hide/reshow cycle
- **Retail engine:** Fixed Lua error (`abs(nil)`) when toggling Bottom Left Bar — `PetActionBar` was left without any anchor after `ClearAllPoints()`, causing Edit Mode's layout calculation to fail; it now always receives a `SetPoint`

### Known Issues
- **Retail engine:** XP/reputation bar positioning is not yet functional (in progress)

---

## [2.3] - 2026-03-04

### Added
- **Retail engine support** (interface 20505). The addon now loads and functions on both Classic Era and retail engine servers.
- `xpbar_retail.lua`: Uses `C_Reputation.GetWatchedFactionData()` for reputation tracking (retail engine API). Max level defaults to 70.
- `micromenu_retail.lua`: `C_Timer.After(0)` deferral on all micro button hooks to prevent taint when Edit Mode exits. Loop skips `SocialsMicroButton` (hidden in BFAUI on retail).
- `actionbars_retail.lua`: `C_Timer.After(0)` deferral on `PLAYER_ENTERING_WORLD` to counteract Edit Mode overriding bar positions. Explicit anchoring of `MultiBarBottomLeft`, `MultiBarBottomRight`, and `PetActionBar` (retail engine does not auto-position these). `MultiBarBottomRightButton7` wrapped below button 1 to produce a 2×6 layout (`TOPLEFT` relative to `MultiBarBottomRightButton1.BOTTOMLEFT`).
- Bag buttons (`MainMenuBarBackpackButton`, `CharacterBag0-3Slot`) raised to `HIGH` frame strata so they render above action bar art frames on retail.

### Changed
- **Codebase refactor**: `core.lua` is now a lean entry point (version detection, saved variables, UIHider/HideFrame, texture cleanup). All feature logic has been split into separate files following Bartender4's self-guarding file pattern — each file returns immediately if the wrong client is detected.
  - `options_classic.lua` / `options_retail.lua` — slash commands, Settings API, static popups, pixel perfect scaling, gryphon hiding
  - `xpbar_classic.lua` / `xpbar_retail.lua` — XP/reputation bar positioning and display logic
  - `micromenu_classic.lua` / `micromenu_retail.lua` — micro menu repositioning, latency bar, bag layout
  - `actionbars_classic.lua` / `actionbars_retail.lua` — all action bar, pet bar, and stance bar positioning
  - `bags_classic.lua` / `bags_retail.lua` — bag space indicator
- Classic Era uses `PetActionBarFrame` (correct global name for 1.x); retail uses `PetActionBar`.
- `micromenu_classic.lua`: Micro button loop changed to `#MICRO_BUTTONS-1` and skips `GuildMicroButton` (hidden in BFAUI on Classic Era).
- `actionbars_classic.lua`: `InitializeBars` anchors `MultiBarBottomLeftButton1` explicitly to `MultiBarBottomLeft` at offset `(0, -6)`. This fixes a misalignment that occurred when Warriors switch stances — the game resets `MultiBarBottomLeft` to `{'BOTTOMLEFT', 'ActionButton1', 'TOPLEFT', 0, 17}` on each stance change.
- `actionbars_classic.lua`: `MultiBarBottomRight` positioned at `("LEFT", MultiBarBottomLeft, "RIGHT", 43, -6)`. Page arrow and page number anchors moved outside the `InCombatLockdown()` guard so they are always set in `ActivateLongBar`.

### Fixed
- `core.lua`: `StaticPopup_Show(WELCOME_POPUP)` corrected to `StaticPopup_Show("WELCOME_POPUP")` — the variable was nil, causing a Lua error on the first login of a new character.
- `core.lua`: `BottomRightBarAlpha` was incorrectly set from the `BottomLeftBar` saved variable (copy-paste bug). `MultiBarBottomRightButton` keybind visibility was always driven by the BottomLeft setting instead of BottomRight.

---

## [2.2] - 2026-02-10

- Fixed an issue where the options panel was not properly loaded.
- Fixed the button linking to Blizzard action bar settings.

---

## [2.1] - 2026-01-26

- Fixed XP bar not hiding at level 60 (max level).
- Migrated options panel to WoW's Settings API (`Settings.RegisterCanvasLayoutCategory`). Options accessible via `/bfa` or Game Menu > Options > AddOns.
- Fixed reputation bar display — can now show reputation progress when a faction is tracked.

---

## [1.12] - 2025-10-24

- Fixed errors to make the addon work on WoW Classic Anniversary servers (client 1.15.8).

---

## [1.11]

- Added free bag space count on the backpack button.
- Potential fix for XP bar visibility.

---

## [1.10]

- Updated art assets to match current BfA artwork.
- Added option to hide gryphons on the main action bar.

---

## [1.09]

- Fixed frame strata being too low for the XP bar.

---

## [1.08]

- Changed MicroMenuArt texture to a shorter width (three slots removed).
- Fixed QuestLogMicroButton placement/sizing for characters below level 10.
- Small fix to pixel perfect scaling for a bug present in 8.1/Classic.
- Cleanup and refactoring.

---

## [1.07]

- Modified to restore the BfA UI to WoW Classic. Removed retail-only code.

---

## [1.06]

- Objective Tracker now positions correctly beneath Blizzard Arena Frames.
- Vehicle Seat Indicator positions correctly when Objective Tracker or Arena Frames are visible.
- Pixel Perfect Mode fixed.
- Refactored code.

---

## [1.05]

- Enabling Right Bar while Right Bar 2 is disabled now enlarges and repositions the Right Bar.
- Fixed visual issue where the Artifact bar moved randomly during battlegrounds.
- Fixed stance bar positioning for single stance when Bottom Left Bar is hidden.
- Fixed Exhaustion Tick not repositioning correctly on XP bar resize.
- Fixed Vehicle Seat Indicator appearing over the Objective/Quest frame.
- Refactored code.

---

## [1.04]

- Fixed visual issue when unequipping artifact weapon at max level.
- Fixed visual issue when logging in at max level with no artifact weapon equipped.

---

## [1.03]

- Fixed Pet ActionBar positioning and art when Bottom Left ActionBar is hidden.
- Fixed `[ADDON_ACTION_BLOCKED]` errors — addon now only calls protected functions outside of combat.

---

## [1.02]

- Recreated Pixel Perfect Mode; now works on resolutions above 1080p.

---

## [1.01]

- Fixed issue where the artifact bar appeared on `UPDATE_EXHAUSTION` event for levels 98–109.
