# FillRaidBots

## Overview

This addon is an extension for the **PartyBot Command Panel (PCP)** for **World of Warcraft (WoW) 1.12.1** helps users efficiently fill a raid with bots and manage them through an intuitive command panel. It includes features for setting up bot configurations, managing presets for various dungeons and raids, and automating bot removal.

## Features

- **Automated Interface Creation:**
  - Automatically creates and opens the "Fill Raid" and "Kick All" buttons when the PartyBot Command Panel is accessed.
![Configuration Frame](ScreenShots/fillraidbots.png)
- **Fill Raid Button:**
  - Opens a frame where users can specify the number of bots they want to add.
  - Allows users to choose from predefined presets for various raid instances, simplifying setup.
![Preset Selection](ScreenShots/fillraidbots3.png)
- **Kick All Button:**
  - Removes all bots from the raid while keeping one bot to avoid disbanding the raid.

- **Settings Menu:**
  - Provides options to enable automatic dead bot removal.
  - Allows users to suppress bot messages for a cleaner interface.
![Preset Selection](ScreenShots/fillraidbots4.png)
## Installation

1. **Download the Addon:** 
   - Clone this repository or download the ZIP file from GitHub.

2. **Extract Files:**
   - Extract the contents to your WoW addons directory, typically located at `World of Warcraft/Interface/AddOns`.
   - Rename the map FillRaidBots--main to FillRaidBots

3. **Enable the Addon:**
   - Launch WoW and go to the AddOns menu from the character select screen.
   - Ensure that the addon is enabled in the list.

## Usage

1. **Open the PartyBot Command Panel:**
   - The addon automatically creates and opens the "Fill Raid" and "Kick All" buttons.

2. **Configure the Raid:**
   - Click the "Fill Raid" button to open a configuration frame.
   - Set the number of bots for each role or use the "Presets" button to select from predefined raid setups.

3. **Apply Presets:**
   - Use the preset options to quickly fill the raid with optimized configurations for different dungeons and raids.

4. **Kick All Bots:**
   - Click the "Kick All" button to remove all bots from the raid, ensuring that at least one bot remains to prevent disbanding.

5. **Adjust Settings:**
   - Access the settings menu to enable automatic dead bot removal and suppress bot messages as needed.

## Presets

The addon includes optimized presets for several dungeons and raids:

- **Onyxia:** 2 warrior tanks, 2 paladin healers, rest mages.
- **Molten Core (MC):** Detailed presets for each boss, including tanks, healers, and DPS roles.
- **AQ20:** Various presets for different bosses.
- **Zul'Gurub (ZG):** Specific presets for each boss, including tanks, healers, and DPS roles.
- **Blackwing Lair (BWL) and AQ40:** Configurations for raid encounters.

## Editing Presets or Suppress bot messages
- **SuppressBotMsg.lua** edit this file to add or change how often a message should be displayed
- **Presets.lua** edit this file to add or change a preset


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions or issues, please open an issue on GitHub or contact the repository owner.
