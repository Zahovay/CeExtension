# CeExtension (ConsumesManager CE)

Cold Embrace extension for ConsumesManager on Turtle WoW (Classic 1.12). It adds CE-specific presets and role/spec handling to help your raid track required consumables.

## Features
- Auto-selects class/talent when CE extension is enabled.
- Auto-adjusts potion magic damage type requirements by spec.
- Shows required counts alongside owned counts.
- Fully compatible with existing ConsumesManager features.
- CE presets and role/spec grouping in the Presets tab.
- CE toggle in the Settings tab.
- Non-destructive: base addon remains intact and CE changes are removed when disabled.

## Requirements
- Turtle WoW
- ConsumesManager (dependency)

## Installation
1. Download or clone this repository.
2. Copy the CeExtension folder into your addons directory:
   `TurtleWoW/Interface/AddOns/CeExtension`
3. Ensure ConsumesManager is installed in:
   `TurtleWoW/Interface/AddOns/ConsumesManager`
4. Start the game. On the character select screen, open AddOns and verify both are enabled.

## Usage
1. Open ConsumesManager in-game.
2. Go to the Settings tab.
3. Check "Enable Cold Embrace extension".
4. Open the Presets tab and select a class/talent.
5. CE groups and requirements will appear.

![CE Settings](images/settings.png)
*Enable the extension in Settings.*

![CE Presets](images/potion_list.png)
*View CE requirements in the Presets tab.*

## How to Switch On/Off
- On: Settings tab -> check "Enable Cold Embrace extension".
- Off: Settings tab -> uncheck it. The extension restores the original base addon state.

## Troubleshooting
- If the CE checkbox or groups do not show, confirm the addon is enabled at the character select AddOns menu.
- If you edit the `.toc` file, a full client restart is required (a /reload is not enough).
- If you see Lua errors, report the exact message and which action caused it.

## License
Specify your license here before publishing.
