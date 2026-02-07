# CeExtension (ConsumesManager CE)

Cold Embrace extension for [ConsumesManager](https://github.com/Cinecom/ConsumesManager?tab=readme-ov-file#) on Turtle WoW. It adds CE-specific presets and role/spec handling to help your raid track required consumables.

## Features
- Auto-selects class/talent when CE extension is enabled.
- Auto-adjusts potion magic damage type requirements by spec.
- Shows required counts alongside owned counts.
- Includes additional consumables not present in the base addon for comprehensive CE readiness.
- Fully compatible with existing ConsumesManager features.
- CE presets and role/spec grouping in the Presets tab.
- CE toggle in the Settings tab.
- Non-destructive: base addon remains intact and CE changes are removed when disabled.

## Requirements
- Turtle WoW
- [ConsumesManager](https://github.com/Cinecom/ConsumesManager?tab=readme-ov-file#) (dependency)

## License
This project is released under a non-commercial open source license.
See [LICENSE](LICENSE).

## Installation
1. Download or clone this repository.
2. Copy the CeExtension folder into your addons directory:
   `TurtleWoW/Interface/AddOns/CeExtension`
3. Ensure [ConsumesManager](https://github.com/Cinecom/ConsumesManager?tab=readme-ov-file#) is installed
4. Start the game. On the character select screen, open AddOns and verify both are enabled.

**Preferred: Git Addon Manager**
1. Add this repository to Git Addon Manager.
2. Install/update CeExtension through the manager.
3. Ensure [ConsumesManager](https://github.com/Cinecom/ConsumesManager?tab=readme-ov-file#) is installed and enabled.

## Usage
1. Open [ConsumesManager](https://github.com/Cinecom/ConsumesManager?tab=readme-ov-file#) in-game.
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

