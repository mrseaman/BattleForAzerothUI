# BattleForAzerothUI

A World of Warcraft addon that brings the Battle for Azeroth UI aesthetic to Classic Era and retail engine servers.

## What it does

- Replaces the default action bar artwork with BfA-style art overlays
- Moves the micro menu (character, spellbook, talents, etc.) to the bottom-right of the screen
- Repositions bag buttons next to the micro menu
- Stacks the XP bar and reputation bar at the bottom of the screen, resizing dynamically based on which action bars are visible
- Hides redundant Blizzard UI elements (honor bar, artifact bar, status tracking bar)

## Supported clients

| Client | Interface version | Addon version |
|---|---|---|
| Classic Era (Vanilla / Season of Discovery / Hardcore) | 11508 | 2.4.1 |
| Burning Crusade Classic | 20505 | 2.4.1 |
| Wrath of the Lich King Classic / Titan Reforged | 38000 | 2.4.1 |
| Cataclysm Classic | 40402 | 2.4.1 |
| Mists of Pandaria Classic | 50503 | 2.4.1 |
| Retail (Midnight) | 120001 | 2.4.1 |

> **Known issue — XP/reputation bar (retail engine):** The XP and reputation bars are not yet positioned correctly on the retail engine client. Action bar, micro menu, and bag layouts are fully functional. XP bar fix is in progress.

## Installation

Copy the `BattleForAzerothUI/` folder into your WoW AddOns directory:

```
wow_version/Interface/AddOns/BattleForAzerothUI/
```

## Options

Type `/bfa` or `/bfaui` in-game, or go to **Game Menu → Options → AddOns → BattleForAzerothUI**.

Available options:
- **Pixel Perfect** — automatically sets UI scale based on your monitor resolution
- **XP Bar Text** — shows numeric XP values on the experience bar
- **Hide Gryphons** — hides the gryphon end-cap decorations on the action bar
- **Keybind Visibility** — toggle hotkey text visibility per action bar

## Credits

Originally created by EsreverWoW. Updated for WoW Classic Anniversary and retail by zeechn.
