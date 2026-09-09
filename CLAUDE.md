## Project Overview

BattleForAzerothUI is a World of Warcraft addon that reskins the default UI with a Battle for Azeroth-inspired look. It repositions action bars, the micro menu, and XP/reputation bars, and adds custom artwork overlays. No external libraries are used — it's pure WoW Lua/XML API.

Supported clients. The code splits **per UI engine** via `WOW_PROJECT_ID` guards
(each file loads only on its own engine):
- **Classic / progression** — every non-Mainline client: Classic Era 1.15.9 (`WOW_PROJECT_CLASSIC`, interface 11509), TBC Anniversary (`WOW_PROJECT_BURNING_CRUSADE_CLASSIC`, 20506), WotLK (`WOW_PROJECT_WRATH_CLASSIC`), Cata (`WOW_PROJECT_CATACLYSM_CLASSIC`), MoP (`WOW_PROJECT_MISTS_CLASSIC`) → `*_classic.lua`. All share the legacy UI engine: `MainMenuBar`, `MainMenuBar*EndCap`, `StatusTrackingBarManager`, `MicroMenuContainer`/`BagsBar`, `PetActionBar`/`StanceBar`, Edit Mode.
- **Modern retail / Midnight** — 12.0+ (interface 120100, `WOW_PROJECT_MAINLINE`) → `*_retail.lua`. Rebuilt UI: main bar is `MainActionBar` (buttons nested in `*ButtonContainer`), gryphons in `MainActionBar.EndCaps`, default art `MainActionBar.BorderArt`, no legacy `MainMenuBar*`/performance-bar globals. Positions bars via a dedicated Edit Mode layout applied by Blizzard (Midnight taints any insecure `SetPoint` on Edit Mode system frames); this file is overlay-only.

## Project Structure

The actual addon lives in `BattleForAzerothUI/` (the inner directory). The outer directory is the development repo.

```
BattleForAzerothUI/
  BattleForAzerothUI.toc       — metadata, SavedVariables, load order
  core.lua                     — entry point: version detection, saved variables, UIHider, frame cleanup
  artFrames.xml                — art overlay frames (ActionBarArt, ActionBarArtSmall, MicroMenuArt, XPBarBackground)
  optionsFrame.xml             — options panel container frame
  optionsFramePanels.xml       — options panel controls and checkboxes
  options_classic.lua          — slash commands, Settings API, pixel perfect, gryphons (Classic Era + TBC Anniversary)
  options_retail.lua           — slash commands, Settings API, pixel perfect, gryphons (retail engine)
  xpbar_classic.lua            — XP/rep bar system (Classic Era + TBC Anniversary)
  xpbar_retail.lua             — XP/rep bar system (retail engine)
  micromenu_classic.lua        — micro menu + bag layout (Classic Era + TBC Anniversary)
  micromenu_retail.lua         — micro menu + bag layout (retail engine)
  actionbars_classic.lua       — all action bar, pet bar, stance bar positioning (Classic Era + TBC Anniversary)
  actionbars_retail.lua        — all action bar, pet bar, stance bar positioning (retail engine)
  bags_classic.lua             — bag space indicator (Classic Era + TBC Anniversary)
  bags_retail.lua              — bag space indicator (retail engine)
  art/                         — TGA texture assets
```

## Architecture

### core.lua (entry point, loaded first)

1. **Version detection** — booleans (`WoWRetail`, `WoWClassic`, `WoWTBC`, `WoWWrath`, `WoWCata`, `WoWMists`, `WoWMidnight`) derived from `WOW_PROJECT_ID` and `GetBuildInfo()`. Per-file guards check `WOW_PROJECT_ID` directly.
2. **Saved variables init** — `BFAUI_SavedVars.Options` defaults: `PixelPerfect`, `XPBarText`, `HideGryphons`, `KeybindVisibility` (per-bar). On `ADDON_LOADED` and `PLAYER_ENTERING_WORLD`.
3. **UIHider / HideFrame** — `UIHider` is a permanently hidden frame. `HideFrame(frame)` unregisters all events and reparents to `UIHider`, making a frame invisible even if `Show()` is later called on it. Used instead of `Kill()` because the retail engine no-ops `Kill()`-style methods, making them insufficient.
4. **Frame cleanup** — `HideFrame` applied to `HonorWatchBar`, `MainMenuBarMaxLevelBar`, `ArtifactWatchBar`. `StatusTrackingBarManager` is left intact (used by both classic and retail xpbar files). `MainMenuBar.SetPositionForStatusBars` replaced with a no-op to prevent the bar being pushed upward.
5. **Texture hiding** — `MainMenuBarTexture0–3` hidden.

### Per-feature file pairs (`_classic.lua` / `_retail.lua`)

Each feature is implemented in two files — one per client family. Both are listed in the TOC; each file has a guard at line 1 that `return`s immediately on the wrong engine (Bartender4 pattern):

- `_classic.lua`: `if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end` — loads on **every** non-Mainline client (Classic Era, TBC, WotLK, Cata, MoP).
- `_retail.lua`: `if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end` — Mainline only.

Retail is guarded positively because it depends on Midnight-only globals (`MainActionBar`, etc.); classic is the catch-all for the legacy `MainMenuBar` engine every non-Mainline flavor shares. `core.lua` is shared and must stay nil-safe for `MainMenuBar` (nil on Midnight).

**options**: Slash commands (`/bfa`, `/bfaui`), `Settings.RegisterCanvasLayoutCategory` for the options panel, static popups (`WELCOME_POPUP`, `ReloadUI_Popup`), pixel perfect scaling, gryphon hiding.

**xpbar**: Both classic clients use `StatusTrackingBarManager` for XP/rep bar display. Retail uses `C_Reputation.GetWatchedFactionData()`.

**micromenu**: Repositions micro buttons to the bottom-right. Classic repositions `MicroMenuContainer` and `BagsBar` as container frames. Retail don't modify the micromenu or bags.

**actionbars**: Manages the main bar, `MultiBarBottomLeft`, `MultiBarBottomRight`, pet bar, and stance bar — but the two engines take opposite approaches:

- **Classic** (`actionbars_classic.lua`): repositions the bars directly with `:SetPoint`. `ActivateLongBar`/`ActivateShortBar` set the art and bar anchors (`MainMenuBar` based); `UpdateActionBars` runs on bar `OnShow`/`OnHide` and world entry. `skipAutomaticPositioning` opts the bars out of the combat auto-reposition manager, and `SetPoint` hooks reapply layout when Edit Mode moves them. `MultiBarBottomRightButtonContainer7–12` anchored below 1–6 for the 2×6.
- **Retail / Midnight** (`actionbars_retail.lua`): does **not** `:SetPoint` the bars — an insecure `SetPoint` on a registered Edit Mode system frame taints the Edit Mode enter pass (blocks `ClearTarget`, party-frame health, and the logout callback). Instead it writes bar positions + `NumRows` into a dedicated custom Edit Mode layout ("BattleForAzerothUI") via `C_EditMode.SaveLayouts` and lets Blizzard apply it securely (`ApplyBfALayout` / `/bfalayout` / the options checkbox; `MakeNewLayout` can't be called cold, so the layout is built by copying the active one). The file is otherwise **overlay-only** — art plate, gryphons, page-number relocation, flat icon slots — all anchored to the action BUTTONS so they track the bars wherever the layout parks them. The one runtime bar touch is `ApplyRowGap` lifting `MultiBarBottomRightButtonContainer7–12` to widen the 2×6 row gap (child frames, taint-free). "Show Bottom Right Bar" syncs both ways with the system `SetActionBarToggles`/`GetActionBarToggles` and re-centers the main bar.

**bags**: Shows free slot count on the backpack button. Uses `C_Container.GetContainerNumFreeSlots()`.

## Key Patterns

- **Self-guarding files**: Each `_classic.lua` / `_retail.lua` file returns immediately if loaded on the wrong client. Both are listed unconditionally in the TOC. (Bartender4 pattern.)
- **UIHider**: Reparenting to a hidden frame is the canonical retail-engine method for permanently hiding frames. `Kill()`-style no-ops are insufficient on the retail engine.
- **Frame hooking**: `hooksecurefunc()` is used to re-apply positioning after Blizzard code repositions elements (e.g., `MoveMicroButtons`, `UpdateMicroButtons`).
- **Bar size modes**: Long bar (798px) when `MultiBarBottomRight` is visible; short bar (542px) when only `MultiBarBottomLeft` is. XP/rep bars follow the same width via `BFAUI_SetBarWidth`. Classic drives this with `:SetPoint` (`MainMenuBar` at x=110 long / x=237 short) and swaps the art in `ActivateLongBar`/`ActivateShortBar`. Retail drives it through the Edit Mode layout (main bar shifted for the centered main+bar3 cluster when bar 3 is on, centered when off) and swaps only the art plate in `ApplyLongArt`/`ApplyShortArt`, keyed on `MultiBarBottomRight:IsShown()`.
- **Cross-file globals**: `BFAUI_SetBarWidth` is defined in `xpbar_*.lua` and called from `actionbars_*.lua`. Load order in the TOC ensures xpbar loads first.

## WoW API Notes

- **Settings API**: Both clients use `Settings.RegisterCanvasLayoutCategory()`.
- **Container API**: `C_Container.GetContainerNumFreeSlots()` — available on both Classic Anniversary and retail via the modern engine backport.
- **Reputation API**: Retail uses `C_Reputation.GetWatchedFactionData()` (returns a table). Classic clients use `StatusTrackingBarManager`.
- **Max level**: `GetMaxPlayerLevel()` — returns 60 on Classic Era, 70 on retail.
- **Pet bar global**: `PetActionBar` on all clients.

## Interface Versions

All `WOW_PROJECT_*` constants are defined on every client; `WOW_PROJECT_ID` holds
the running one. Retail loads only on `WOW_PROJECT_MAINLINE`; classic loads on
everything else.

| Constant | Client | Interface | File path |
|---|---|---|---|
| `WOW_PROJECT_CLASSIC` | Classic Era (1.15.9) | 11509 | `*_classic.lua` |
| `WOW_PROJECT_BURNING_CRUSADE_CLASSIC` | TBC Anniversary (2.5.6) | 20506 | `*_classic.lua` |
| `WOW_PROJECT_WRATH_CLASSIC` | WotLK Classic (3.4.x) | 38000 | `*_classic.lua` |
| `WOW_PROJECT_CATACLYSM_CLASSIC` | Cataclysm Classic (4.4.x) | 40402 | `*_classic.lua` |
| `WOW_PROJECT_MISTS_CLASSIC` | MoP Classic (5.5.x) | 50503 | `*_classic.lua` |
| `WOW_PROJECT_MAINLINE` | Modern retail / Midnight (12.0+) | 120100 | `*_retail.lua` |

## Packaging

No build system. To install: copy the `BattleForAzerothUI/` folder into the WoW `_classic_/Interface/AddOns/` directory. The `.zip` in the repo root is a pre-packaged distribution artifact (git-ignored).

## Testing

No automated tests. Test by loading the addon in the WoW client. `DevSuite` is available, which can run lua functions to probe game variables.
