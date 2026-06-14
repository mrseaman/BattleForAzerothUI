# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BattleForAzerothUI is a World of Warcraft Classic addon that reskins the default UI with a Battle for Azeroth-inspired look. It repositions action bars, the micro menu, and XP/reputation bars, and adds custom artwork overlays. No external libraries are used — it's pure WoW Lua/XML API.

Supported clients. The code splits **per UI engine**, three ways, via positive
`WOW_PROJECT_ID` guards (each file loads only on its own engine):
- **Classic Era** — vanilla 1.15.x (interface 11508, `WOW_PROJECT_CLASSIC`) → `*_classic.lua`. Vanilla UI: `MainMenuExpBar`/`ReputationWatchBar`, `MainMenuBarArtFrame`, `PetActionBarFrame`/`StanceBarFrame`.
- **TBC Classic Anniversary** — patch 2.5.5 (interface 20505, `WOW_PROJECT_BURNING_CRUSADE_CLASSIC`) → `*_anniversary.lua`. Has Edit Mode; uses `MainMenuBar`, `MainMenuBar*EndCap`, `StatusTrackingBarManager`, `MicroMenuContainer`/`BagsBar`. (These files are the *original* retail code, renamed — known-good on 20505, logic untouched.)
- **Modern retail / Midnight** — 12.0+ (interface 120005, `WOW_PROJECT_MAINLINE`) → `*_retail.lua`. Rebuilt UI: main bar is `MainActionBar` (buttons nested in `*ButtonContainer`), gryphons in `MainActionBar.EndCaps`, default art `MainActionBar.BorderArt`, no legacy `MainMenuBar*`/performance-bar globals. Forces the BfA layout over Edit Mode.

## Project Structure

The actual addon lives in `BattleForAzerothUI/` (the inner directory). The outer directory is the development repo.

```
BattleForAzerothUI/
  BattleForAzerothUI.toc       — metadata, SavedVariables, load order
  core.lua                     — entry point: version detection, saved variables, UIHider, frame cleanup
  artFrames.xml                — art overlay frames (ActionBarArt, ActionBarArtSmall, MicroMenuArt, XPBarBackground)
  optionsFrame.xml             — options panel container frame
  optionsFramePanels.xml       — options panel controls and checkboxes
  options_classic.lua          — slash commands, Settings API, pixel perfect, gryphons (Classic Era)
  options_retail.lua           — slash commands, Settings API, pixel perfect, gryphons (retail engine)
  xpbar_classic.lua            — XP/rep bar system (Classic Era)
  xpbar_retail.lua             — XP/rep bar system (retail engine)
  micromenu_classic.lua        — micro menu + bag layout (Classic Era)
  micromenu_retail.lua         — micro menu + bag layout (retail engine)
  actionbars_classic.lua       — all action bar, pet bar, stance bar positioning (Classic Era)
  actionbars_retail.lua        — all action bar, pet bar, stance bar positioning (retail engine)
  bags_classic.lua             — bag space indicator (Classic Era)
  bags_retail.lua              — bag space indicator (retail engine)
  art/                         — TGA texture assets
```

## Architecture

### core.lua (entry point, loaded first)

1. **Version detection** — `WOW_PROJECT_ID` constants stored as locals; used in per-file guards.
2. **Saved variables init** — `BFAUI_SavedVars.Options` defaults: `PixelPerfect`, `XPBarText`, `HideGryphons`, `KeybindVisibility` (per-bar). On `ADDON_LOADED` and `PLAYER_ENTERING_WORLD`.
3. **UIHider / HideFrame** — `UIHider` is a permanently hidden frame. `HideFrame(frame)` unregisters all events and reparents to `UIHider`, making a frame invisible even if `Show()` is later called on it. Used instead of `Kill()` because the retail engine no-ops `Kill()`-style methods, making them insufficient.
4. **Frame cleanup** — `HideFrame` applied to `HonorWatchBar`, `MainMenuBarMaxLevelBar`, `ArtifactWatchBar`, `StatusTrackingBarManager`. `MainMenuBar.SetPositionForStatusBars` replaced with a no-op to prevent the bar being pushed upward.
5. **Texture hiding** — `MainMenuBarTexture0–3` hidden.

### Per-feature file pairs (`_classic.lua` / `_retail.lua`)

Each feature is implemented in two files — one per client family. Both are listed in the TOC; each file has a guard at line 1 that `return`s immediately if the wrong client is detected (Bartender4 pattern):

- `_classic.lua`: `if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end`
- `_anniversary.lua`: `if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end`
- `_retail.lua`: `if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end`

All three guards are **positive** (`~= <own project>`), so untested Classic-progression clients (WotLK/Cata/MoP) load none of them rather than the wrong one. Do **not** revert to exclusion guards: `_anniversary.lua` is the *old* retail code (works on 20505); `_retail.lua` is the Midnight 12.0 port (`MainActionBar`-based). `core.lua` is shared and must stay nil-safe for `MainMenuBar` (nil on Midnight) and must not `HideFrame(StatusTrackingBarManager)` on Mainline (the Midnight xpbar repurposes it) — gated via the `WoWRetail` local.

**options**: Slash commands (`/bfa`, `/bfaui`), `Settings.RegisterCanvasLayoutCategory` for the options panel, static popups (`WELCOME_POPUP`, `ReloadUI_Popup`), pixel perfect scaling, gryphon hiding.

**xpbar**: Dynamic XP/rep bar stacking. Bars resize between 798px (long bar, both extra bars visible) and 542px (short bar, only MLB visible). Width is driven by `BFAUI_SetBarWidth(width, offset)`, a global set in the xpbar file and called from actionbars. Classic uses `GetWatchedFactionInfo()`; retail uses `C_Reputation.GetWatchedFactionData()`.

**micromenu**: Repositions micro buttons to the bottom-right. Classic hooks fire synchronously. Retail wraps all hooks in `C_Timer.After(0)` to avoid taint from Edit Mode's protected execution context. Both skip one hidden button (`GuildMicroButton` on Classic, `SocialsMicroButton` on retail) and iterate `#MICRO_BUTTONS-1`.

**actionbars**: Manages `MainMenuBar`, `MultiBarBottomLeft`, `MultiBarBottomRight`, pet bar, and stance bar. `ActivateLongBar` / `ActivateShortBar` switch the art overlay and reposition bars. `UpdateActionBars` is called on bar visibility changes (`OnShow`/`OnHide` hooks) and on world entry.

- **Classic**: `InitializeBars` on `PLAYER_LOGIN` anchors `MultiBarBottomLeftButton1` explicitly to `(MultiBarBottomLeft, 0, -6)`. This is required because the game resets `MultiBarBottomLeft` to `{'BOTTOMLEFT', 'ActionButton1', 'TOPLEFT', 0, 17}` every time a Warrior switches stances, which misaligns the pet bar. Pet bar global is `PetActionBarFrame`.
- **Retail**: `UpdateActionBars` is deferred via `C_Timer.After(0)` on `PLAYER_ENTERING_WORLD` to run after Edit Mode applies its saved positions. Pet bar global is `PetActionBar`. `MultiBarBottomRightButton7` is explicitly anchored to `MultiBarBottomRightButton1.BOTTOMLEFT` to wrap the single-row 12-button frame into a 2×6 layout.

**bags**: Shows free slot count on the backpack button. Uses `C_Container.GetContainerNumFreeSlots()`. On retail, bag frames are raised to `HIGH` strata so they render above the action bar art frames (which are children of `MainMenuBar` in `MEDIUM` strata).

## Key Patterns

- **Self-guarding files**: Each `_classic.lua` / `_retail.lua` file returns immediately if loaded on the wrong client. Both are listed unconditionally in the TOC. (Bartender4 pattern.)
- **UIHider**: Reparenting to a hidden frame is the canonical retail-engine method for permanently hiding frames. `Kill()`-style no-ops are insufficient on the retail engine.
- **Frame hooking**: `hooksecurefunc()` is used to re-apply positioning after Blizzard code repositions elements (e.g., `MoveMicroButtons`, `UpdateMicroButtons`).
- **Edit Mode deferral (retail only)**: `C_Timer.After(0)` defers callbacks past Edit Mode's synchronous `PLAYER_ENTERING_WORLD` handlers and breaks taint chains from Edit Mode's protected exit context.
- **Bar size modes**: Long bar (798px, `MainMenuBar` at x=110) when `MultiBarBottomRight` is visible; short bar (542px, `MainMenuBar` at x=237) when only `MultiBarBottomLeft` is visible. XP/rep bars follow the same width via `BFAUI_SetBarWidth`.
- **Cross-file globals**: `BFAUI_SetBarWidth` is defined in `xpbar_*.lua` and called from `actionbars_*.lua`. Load order in the TOC ensures xpbar loads first.

## WoW API Notes

- **Settings API**: Both clients use `Settings.RegisterCanvasLayoutCategory()` (modern API, not legacy `InterfaceOptions`).
- **Container API**: `C_Container.GetContainerNumFreeSlots()` — available on both Classic Anniversary and retail via the modern engine backport.
- **Reputation API**: Classic uses `GetWatchedFactionInfo()` (multi-return). Retail uses `C_Reputation.GetWatchedFactionData()` (returns a table).
- **Max level**: `GetMaxPlayerLevel()` — returns 60 on Classic Era, 70 on retail.
- **Pet bar global**: `PetActionBarFrame` on Classic Era 1.x; `PetActionBar` on the retail engine.

## Interface Versions

All `WOW_PROJECT_*` constants are defined on every client; `WOW_PROJECT_ID` holds
the running one, so positive guards are reliable everywhere.

| Constant | Client | Interface | File path |
|---|---|---|---|
| `WOW_PROJECT_CLASSIC` | Classic Era (vanilla 1.15.x) | 11508 | `*_classic.lua` |
| `WOW_PROJECT_BURNING_CRUSADE_CLASSIC` | TBC Classic Anniversary (2.5.5) | 20505 | `*_anniversary.lua` |
| `WOW_PROJECT_MAINLINE` | Modern retail / Midnight (12.0+) | 120005 | `*_retail.lua` |

## Packaging

No build system. To install: copy the `BattleForAzerothUI/` folder into the WoW `_classic_/Interface/AddOns/` directory. The `.zip` in the repo root is a pre-packaged distribution artifact (git-ignored).

## Testing

No automated tests. Test by loading the addon in the WoW client and verifying:
- UI layout (bars, micro menu, art overlays)
- Bar visibility toggling (long bar ↔ short bar transition)
- Options panel opens via `/bfa`
- XP/rep bar behavior at various levels and with a watched faction
- Keybind visibility toggles apply correctly
- Warrior stance switching does not misalign the pet bar (Classic only)
- No taint errors when entering/exiting Edit Mode (retail only)
