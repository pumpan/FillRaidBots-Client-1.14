# 📦 FillRaidBots — Changelog

## 🆕 Version 5.0

---

## 🚀 Added

### 🎯 Click-To-Fill System (Pumpan & Nymz)
- Hold **Ctrl + Alt** to trigger Fast Fill
- With target → fills boss preset instantly
- Without target → zone-based fallback
- Supports multiple presets per zone with chooser UI
- Debug messages for match counts and selection flow

---

### 📺 Tutorial System (Pumpan)
- Multi-link tutorial popup per preset
- Supports Alliance / Horde + VIP / non-VIP
- Automatic fallback if missing category
- Includes boss descriptions and copyable links
- Uses preset.fullname for display

---

### ⚙️ Settings System Overhaul (Pumpan & Nymz)
- New structured UI sections
- Added:
  - Use VIP Presets
  - Zone Presets
  - Click-To-Fill
  - Tutorial Links toggle
  - Daily Tip
  - Auto Repair (VIP)
  - Auto Join Guild
  - Auto Mute Sound
  - Debug toggle
- Factory Reset (preserves user stats)

---

### 🎨 Button System (Pumpan & Nymz)
- Multiple themes (Mini, Classic, AI, etc.)
- Horizontal layout support
- Button spacing slider (supports negative)
- Button size as % (10–500%)
- Movement modes: Fixed / Free / Relative
- Free-mode lock button

---

### 🔁 Preset System (Pumpan)
- values + vipValues support
- Save / Save As / Delete / Restore
- Instance-based presets
- Migration system with versioning

---

### 🔄 Export / Import (Pumpan)
- Export/import all presets in-game
- Scrollable edit box with copy support

---

### 🧠 Debugger (Nymz & Pumpan)
- Scrollable, filterable debug window
- Timestamp toggle
- Persistent position, size, visibility
- Mouse wheel scrolling
- Visible vs total message counter

---

## 🔧 Changed

### ⚔️ Fast Fill Behavior (Pumpan & Nymz)
- Ctrl+Alt works without click
- Improved zone fallback chooser
- Added boss remapping:
  - Ossirian
  - Rajaxx (Andorov)
  - Mandokir / Thekal adds
  - Onyxia zone mapping

---

### 📺 Tutorial UI (Pumpan)
- Always on top (strata fix)
- Solid background
- Header added
- Dynamic resizing based on boss image
- Auto layout refresh on open
- URLs show beginning instead of end

---

### 🎛️ Button Layout (Pumpan & Nymz)
- Rebuilt positioning logic
- Fixed reload inconsistencies
- Horizontal layout uses UIParent
- Stable with ElvUI

---

### 👥 Raid Logic (Pumpan)
- Smart raid conversion using targetGroupSize
- Works with real-player-only groups
- Improved starter bot sequence

---

### 📊 Zone Scaling (Pumpan)
- Dynamic caps:
  - 39 (raid)
  - 19 (ZG/AQ20)
  - 14 (UBRS)
  - 9 (dungeons)
- World boss + subzone support

---

### 🔁 Refill System (Pumpan)
- Improved batching
- Reliable re-check loop
- Stable across group sizes

---

### 💰 Loot System (Pumpan)
- Applies only when needed
- Triggers on leader change
- Prevents spam

---

## 🐛 Fixed

### 💾 Preset Saving (Pumpan)
- Fixed VIP save logic:
  - Saves to vipValues when enabled
  - Saves to values otherwise
- Fixes presets reverting after reload

---

### 🗺️ AQ Matching (Pumpan)
- Fixed "Ahn'Qiraj" matching AQ20 incorrectly

---

### 💀 Dead Target Fill (Pumpan)
- Fast Fill aborts if target is dead

---

### 🧹 UI Behavior (Nymz)
- Remove Dead Bots button hidden when auto-remove enabled

---

### 🐞 Debugger (Nymz & Pumpan)
- Fixed invisible rows affecting scroll
- Proper log filtering

---

### 🎛️ Button Bugs (Nymz & Pumpan)
- Fixed checkbox state issues
- Fixed anchor loops
- Fixed scaling inconsistencies

---

### 📺 Tutorial Layout (Pumpan)
- Fixed overlapping UI
- Fixed layout refresh issues

---

### ⚔️ Automation (Pumpan)
- Prevented "Cannot kick yourself" spam
- Fill pauses when dead and resumes
- Safe fail when lacking permissions

---

### 🧪 Misc Fixes
- DetectRole fix (Pumpan)
- Refill consistency fixes (Pumpan)
- Starter bot detection fixes (Pumpan)
- Azuregos/Kazzak zone fixes (Pumpan)
- PlaySound Classic fix (Nymz)

---

## ✨ UI / UX Improvements

### 🎯 Interaction (Nymz)
- Shift+Click Fill toggles debugger
- Shift+Click preset = load + fill

---

### 📊 UI Clarity (Pumpan)
- BotsLeft UI only subtracts real players

---

### 🔘 Live Updates (Pumpan & Nymz)
- Tutorial links toggle live update
- Others button toggle live update
- Dynamic frame resizing

---

### 🎨 Polish (Pumpan & Nymz)
- Improved spacing and alignment
- Cleaner labels and tooltips
- Consistent UI headers

---

## 👥 Credits

- **Pumpan** — Core systems, UI, presets, tutorial system, raid logic  
- **Nymz** — Debugger, button system, movement system, architecture
