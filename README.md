# FillRaidBots Client 1.14

[![Version](https://img.shields.io/github/v/release/pumpan/FillRaidBots-Client-1.14?color=blue&label=version)](https://github.com/pumpan/FillRaidBots-Client-1.14/releases)
![WoW Version](https://img.shields.io/badge/WoW-1.14.2-ff69b4)
![License](https://img.shields.io/badge/license-MIT-green)
[![Total Downloads](https://img.shields.io/github/downloads/pumpan/FillRaidBots-Client-1.14/total?color=blue)](https://github.com/pumpan/FillRaidBots-Client-1.14/releases)
[![Latest ZIP](https://img.shields.io/badge/dynamic/json?color=success&label=Latest&query=$.assets[0].download_count&url=https://api.github.com/repos/pumpan/FillRaidBots-Client-1.14/releases/latest)](https://github.com/pumpan/FillRaidBots-Client-1.14/releases/latest)
<a href="https://www.paypal.com/donate/?hosted_button_id=JCVW2JFJMBPKE" target="_blank">
    <img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" 
         alt="Donate with PayPal" style="border: 0;">
</a>
<a href="https://www.paypal.com/donate/?hosted_button_id=JCVW2JFJMBPKE" class="paypal-button" target="_blank">
    💙 Support Me with PayPal
</a>
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
---

## 🧠 Overview

**FillRaidBots** is an advanced addon for the **PartyBot Command Panel (PCP)** for **World of Warcraft (WoW 1.14 / 1.12.1 environments)**.

It helps you:
- Quickly fill raids with bots  
- Use optimized presets for bosses and instances  
- Automatically manage bots (remove, refill, organize)  
- Customize everything directly in-game  


---
## 🛠️ Installation

1. **Download the Addon:**  
   -Download the ZIP file from GitHub.
   
    👉👉👉 [![⬇ DOWNLOAD](https://img.shields.io/github/downloads/pumpan/FillRaidBots-Client-1.14/total?style=for-the-badge&color=00b4d8&label=⬇+DOWNLOAD)](https://github.com/pumpan/FillRaidBots-Client-1.14/releases) 👈👈👈


3. **Extract Files:**  
   - Extract the contents to your WoW addons directory, typically located at:
     ```
     World of Warcraft/Interface/AddOns
     ```  
   - Rename the folder `FillRaidBots-1.14--main` to `FillRaidBots`.

4. **Enable the Addon:**  
   - Launch WoW and go to the AddOns menu from the character selection screen.  
   - Ensure that the addon is enabled in the list.

5. **IF YOU ARE HAVING TROUBLES**
   - 📘 [How to install addons](https://github.com/pumpan/howtoinstalladdons/wiki)

## ⚡ Features (Core Behavior)

- Automatically creates:
  - **Fill Raid button**
  - **Kick All button**
  - **Refill button**
- Appears when opening PartyBot Command Panel  

<p align="center">
   <img src="/ScreenShots/newbuttons.png">
   <img src="/ScreenShots/fillraidbots.png" width="400">
</p>

### 🧩 Party vs Raid Behavior

- The addon dynamically decides whether to stay in a party or convert to a raid

Rules:
- If total members (players + bots) ≤ 5 → stays a party  
- If total members > 5 → converts to a raid  

👉 No unnecessary raid conversion  
👉 Works even when filling an existing group of real players

---

### 🟢 Fill Raid Button

- Opens the main configuration UI  
- Lets you:
  - Manually set number of bots per role  
  - OR choose from predefined presets  

<p align="center">
  <img src="/ScreenShots/fillraidbots3.png" width="400">
</p>

---
### 🔴 Kick All Button

- Removes all bots from the raid  
- Keeps one bot to prevent disband  
- ✅ **Does NOT remove real players**

---

### 🔁 Refill Raid Button

- Replaces missing or dead bots automatically  
- Uses improved **multi-pass system**:
  - Continues until raid is fully restored  
  - Handles delayed bot removal correctly  

---

### 🧠 Smart Fill System (NEW)

- `Ctrl + Alt + Click boss` → loads correct preset  
- `Ctrl + Alt (no target)` → loads preset based on instance  
- If multiple presets match → **popup appears at cursor**

---



### ⚙️ Auto Remove Features (Now Quicker and more secure)

- **Auto Remove First Bot**
  - Removes the first bot (usually bad gear)

- **Remove Dead Bots Button**
  - Appears automatically when bots die  

- **Auto Remove Option (Settings)**
  - Can automatically:
    - Remove first bot  
    - Remove dead bots  

---

### ⚡ Fast Fill

- Quickly fills the raid using optimized presets  
- Minimal setup required  

---

## 🧩 Preset System

---

### 📦 Built-in Presets

Supports:
- Naxxramas  
- Blackwing Lair  
- Molten Core  
- AQ40 / AQ20  
- Zul'Gurub  
- Onyxia  

Each preset includes:
- Tanks / Healers / DPS distribution  
- Tooltip auto-generation  
- Boss mapping support  

---

### 🧠 Smart Preset Detection (NEW) (ctrl + alt)
   <img src="/ScreenShots/fastfill.png">
Old system only supported bosses for an example "Boss Name", "Another Boss" 

Presets now also support:

👉 **Instance-based detection**

- If no target → uses instance name  
- If multiple matches → shows selection popup  

---

### ✏️ Editable Presets (In-Game UI)

You can now:
- Edit presets directly in-game  
- Save changes  
- Save As (create new preset)  
- Delete presets  
- Restore defaults  

---

### 💾 Export / Import

- Export all presets + settings  
- Share between accounts  
- Import directly in-game  

---

## 🎥 Tutorial Videos System (NEW)
  <img src="/ScreenShots/tutorials.png">
- Integrated tutorial system via `Tutorials.lua`  
- Displays boss-specific guides inside the addon  

Supports:
- Alliance / Horde versions  
- VIP / non-VIP  
- Multiple creators per boss  
- Smart fallback system  

---

## ⚙️ Settings (UISettings.lua)

Fully rebuilt settings system:


  <img src="/ScreenShots/frbsettings.png">


---

### 🎛️ UI Customization
  <img src="/ScreenShots/themes.png">
- Button themes (Mini / Classic / AI / Nymz / etc.)  
- Button size slider  
- Button spacing slider  
- Layout modes:
  - Fixed  
  - Free  
  - Relative  

---

### 🔧 Feature Toggles

- Click-To-Fill  
- Zone Presets  
- Tutorial Links  
- Debug Messages  
- Auto Remove Bots  
- Loot Type  

---

### 🪙 Zone Presets
  <img src="/ScreenShots/zoneandbosses.png">
Opens the correct set of presets when you open the Fillraidbots frame.

---

### 🪙 Others button
If enabled a shortcut to the "Others presets" will be avalible on all instance frames.

---

### 🪙 Loot System (reworked)

Now also works if not using the addon to fill the raid.

- Automatically sets loot method:
  - Free For All  
  - Group Loot  
  - Master Loot  

(Only if player is leader)

---

### 💎 VIP Features

- Auto Repair  
- VIP preset support  

---

## 📊 Dynamic Raid Size / Spots Left (NEW)

The addon now automatically adapts to the current zone:

 <img src="/ScreenShots/spotsleft.png">
 
- 🟢 **No dungeon → 4 bots**
- 🟢 **5-man dungeons → 9 bots**
- 🟡 **UBRS → 14 bots**
- 🟠 **ZG / AQ20 → 19 bots**
- 🔴 **Raids → 39 bots**
- 🔴 **World Bosses → 39 bots**
- 
👉 The **“Spots Left” counter is always correct** based on:
- Current zone  
- Real players in group  
- Bots already present  

---

## 💬 Suppress Bot Messages

- Fully editable in-game  
- Controls bot spam messages  

---

## 🧪 Debug System

- Advanced debug window  
- Log filtering  
- Improved scrolling behavior  

---

## 🚀 Usage

### 1. Open PCP
Buttons appear automatically  

### 2. Fill Raid
- Click **Fill Raid**
- Choose preset OR manual setup  

### 3. Smart Fill

```
Ctrl + Alt + Click → Boss preset
Ctrl + Alt (no target) → Instance preset
```

### 4. Manage Bots

- Refill → replaces dead bots  
- Kick All → removes bots safely (keeps real players)  

### 5. Settings

- Open settings panel  
- Customize everything  

---

## 💻 Slash Commands

```
/frb                      → show help
/frb ua                   → uninvite all non-guild/friend raid members
/frb open                 → toggle/open FillRaid window
/frb refill               → replace recently removed bots
/frb fixgroups            → reorganize raid groups
/frb list                 → list all presets
/frb resetbuttons         → reset button positions to default
/frb <preset name>        → fill using a preset match Ex: onyxia
```

---

## 🆕 Major Changes (From Old Version)

- Instance-based preset detection  
- Ctrl+Alt with no target support  
- Preset selection popup at cursor  (ctrl+alt)
- Tutorial video system  
- Full UISettings overhaul  
- Improved refill logic (multi-pass, and better tank detection)  
- Editable presets UI  
- Export / Import system  
- Debug improvements  
- Button layout & movement rewrite  
- Dynamic raid size / spots left system  

---

## 📅 Changelog

See full changelog here:  
[Changelog](CHANGELOG.md)

---

## 📜 License

MIT License  

---

## 💬 Contact

GitHub: https://github.com/pumpan

