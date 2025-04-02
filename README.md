# FillRaidBots Client 1.14

![Version](https://img.shields.io/badge/version-3.0.0-blue)
![WoW Version](https://img.shields.io/badge/WoW-1.14-ff69b4)
![License](https://img.shields.io/badge/license-MIT-green)

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Presets](#presets)
- [Editing Presets or Suppress Bot Messages](#editing-presets-or-suppress-bot-messages)
- [Changelog](#changelog)
- [License](#license)
- [Contact](#contact)

## 📝 Overview

This addon is an extension for the **PartyBot Command Panel (PCP)** for **World of Warcraft (WoW) 1.14**. 
It helps users efficiently fill a raid with bots and manage them through an intuitive command panel. The addon 
includes features for setting up bot configurations, managing presets for various dungeons and raids, and automating 
bot removal. **Note:** This addon works best on the **1.12.1 client**, where bots are automatically removed.

## ✨ Features

- **Automated Interface Creation:**
  - Automatically creates and opens the "Fill Raid" and "Kick All" buttons when accessing the PartyBot Command Panel.

<p align="center">
   <img src="/ScreenShots/newbuttons.png" alt="Configuration Frame">
  <img src="/ScreenShots/fillraidbots.png" alt="Configuration Frame" width="400">
</p>

- **Fill Raid Button:**
  - Opens a configuration frame to specify the number of bots to add.
  - Allows users to choose from predefined presets for different raid instances.

<p align="center">
  <img src="/ScreenShots/fillraidbots3.png" alt="Preset Selection" width="400">
</p>

- **Refill Raid Button:**
  - Replaces bots that die and are removed during gameplay.

- **Kick All Button:**
  - Removes all bots from the raid while keeping one bot to avoid disbanding the raid.

- **Remove First Bot Button:**
  - Removes the first bot (party bot with bad gear). The button appears when you start filling the raid.

- **Remove Dead Bots Button:**
  - Removes the dead bots. The button appears when a bot dies.

- **Fast Fill:**
  - Quickly fills the raid with bots using optimized settings.
    Add bots using `Ctrl + Alt + Mouse Click` on bosses to instantly load the preset raid setup.

- **Loot Type Option:**
  - Automatically changes the loot type on raid creation to the selected one.

- **Settings Menu:**
  - Provides options to enable the "Remove Dead Bots" button.
  - Allows users to suppress bot messages for a cleaner interface.

<p align="center">
  <img src="/ScreenShots/frbsettings.png" alt="Settings Menu">
</p>

## 🛠️ Installation

1. **Download the Addon:**  
   - Clone this repository or download the ZIP file from GitHub.
     https://github.com/pumpan/FillRaidBots-Client-1.14/releases/tag/v3.0.0

2. **Extract Files:**  
   - Extract the contents to your WoW addons directory, typically located at:
     ```
     World of Warcraft/Interface/AddOns
     ```  
   - Rename the folder `FillRaidBots-1.14--main` to `FillRaidBots`.

3. **Enable the Addon:**  
   - Launch WoW and go to the AddOns menu from the character selection screen.  
   - Ensure that the addon is enabled in the list.

## 🚀 Usage

1. **Open the PartyBot Command Panel:**  
   - The addon automatically creates and opens the "Fill Raid" and "Kick All" buttons.

2. **Configure the Raid:**  
   - Click the "Fill Raid" button to open a configuration frame.  
   - Set the number of bots for each role or use the "Presets" button to choose from predefined raid setups.

3. **Apply Presets:**  
   - Use the preset options to quickly fill the raid with optimized configurations for various dungeons and raids.

4. **Kick All Bots:**  
   - Click the "Kick All" button to remove all bots, while keeping one to prevent raid disbanding.

5. **Refill Raid:**  
   - Use the "Refill Raid" button to replace bots that have died and been removed.

6. **Adjust Settings:**  
   - Access the settings menu to enable automatic dead bot removal and suppress bot messages as needed.

7. **Slash Commands:**  
   - You can create macros for the following commands:
     ```
     /frb - for avalible commands
     /frb ua or /frb uninvite all – Uninvite all raid members but saves Friends and guild members.
     /frb (preset) – Fills the raid with the preset.
     /frb open – Open the Fill Raid frame.
     /frb rdb - Removes dead bots.
     /frb refill – Refill the raid.
     /frb fixgroups – Fix raid groups.
     ```

## 🗺️ Presets

The addon includes optimized presets for several dungeons and raids:

- **Onyxia:** 2 warrior tanks, 2 paladin healers, rest mages.
- **Molten Core (MC):** Detailed presets for each boss, including tanks, healers, and DPS roles.
- **AQ20:** Various presets for different bosses.
- **Zul'Gurub (ZG):** Specific presets for each boss, including tanks, healers, and DPS roles.
- **Blackwing Lair (BWL) and AQ40:** Configurations for raid encounters.

## 📝 Editing Presets or Suppress Bot Messages

- To edit how often a message should be displayed, modify the `SuppressBotMsg.lua` file.
- To add or change a preset, modify the `Presets.lua` file.

## 📅 Changelog

  ### **FillRaidBots 3.0.0**


    🔄 Version updated: to 3.0.0, Since FillRaidBots now introduces multiple usability upgrades, UI options, new commands, 
    and extended compatibility, it’s a big leap forward, making 3.0.0 the right version number.
    🆕 Edited: you can now use /frb (bossname or part of bossname eg: ony or /frb mage group) (suggestion by Gemma)
    🆕 Added: A new feature to add preset bots with ctrl+alt+mouse click on bosses
    🆕 Added: Settings to chose if you want big or small (round) Buttons (fill raid, Kick all etc)
    🆕 Added: You can now Select automatic loot type on raid creation in the settings menu.
    🆕 Added: Works with both PCP and PCPRemake
    🆕 Added: You can now reload ui with /rl /reloadui /reload    
🛠 Improvements:
  
    🆕 Edited: you can now use /frb (bossname or part of bossname eg: ony) instead of /frb fill

### **Previous Versions**
## Changelog
**FillRaidBots 2.1.0**

    🔄 Version updated: to 2.1.0, introducing multiple improvements to performance, user experience, and new features.
    🆕 Added: A Credits frame showcasing everyone who has helped in the development of the addon.
    🆕 Added: Slash commands to improve raid management:
        /frb ua or /frb uninvite all – Uninvite all raid members.
        /frb fill – Automatically fill the raid.
        /frb open – Open the Fill Raid frame.
        /frb rdb - Removes dead bots
        /frb refill – Refill the raid.
        /frb fixgroups – Fix raid groups.
    🆕 Fixed: Players on the raid leader's friend list are no longer removed when adding bots, removing dead bots, or using the "Kick All" button (previously, this only applied to guild members).

🛠 Improvements:

    Improved: Debug messages are now separated from commands, enhancing command responsiveness and speed.
    Improved: Enhanced the process of matching player names, fixing an issue where a mismatch would cause a nil value error.

🐞 Bug Fixes:

    Fixed: An error where player names weren’t matched, which previously led to nil values.

**FillraidBots 2.0.2**

    🔄 Version updated: to 2.0.2. marking this as a major update due to significant new features and functionality improvements.
    🆕 Now detects the player's faction and load the appropriate presets for Horde or Alliance.
    🛠 Improved: Healing sorting.
    🆕 Improved: Made the process of adding bots a little faster.
    🆕 Added: Bots are now added in a new way: healers are added first, sorted into different groups, and then all other classes are added.
    🛠 Fixed: Adjusted and fixed some presets for better functionality.
    🆕 Added: A debugger window for when debugging is enabled. All debug messages are now sent here instead of cluttering the chat window.
    🆕 Added: A version checker that notifies you if a newer version of the addon is available.
    🆕 Added: Logic to distribute healers evenly across the raid when bots are added.
    🆕 Added: Class and role detection in the raid, enabling new functionality such as managing bots based on their roles.
    🆕 Added: A new "Refill Raid" button, which replaces bots that die and are removed during gameplay.
    🛠 Fixed: The /uninviteraid slash handler to prevent conflicts with WoW's native commands like /kick and /uninvite, which were unintentionally uninviting the entire raid. (Reported by Gemma)
    🛠 Fixed: Since the latest server update, which prevents adding bots while in combat, an issue occurred where adding certain bots, such as warriors or hunters, caused you to enter combat for a few seconds. This created a problem where the addon attempted to add bots when they couldn't be added. I have now fixed it so that the addon detects when you're in combat and pauses until you're out of combat.
    🛠 Added: The ability to move the 'fill raid' and 'kick all' buttons if this is enabled in the settings."
    🛠 Added: A version number to the FillRaidFrame so that it's easier to see which version you're using.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 📧 Contact

For any questions or issues, please open an issue on GitHub or contact the repository owner.

