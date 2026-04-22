local classes = {
  "warrior tank",
  "warrior meleedps",
  "paladin healer",
  "paladin tank",
  "paladin meleedps",
  "hunter rangedps",
  "rogue meleedps",
  "priest healer",
  "priest rangedps",
  "shaman healer",  
  "shaman rangedps",
  "shaman meleedps",
  "mage rangedps",
  "warlock rangedps",
  "druid tank",
  "druid healer",
  "druid meleedps",
  "druid rangedps"
}

local addonName = "FillRaidBots"
local addonPrefix = "FillRaid1142"
local versionNumber = "5.0.0"
local a = "5"
local botCount = 0
local initialBotRemoved = false
firstBotName = nil
local messageQueue = {}
local DebugMessageQueue = {}
local delay = 0.1 
local nextUpdateTime = 0 
local verifiedRealPlayers = {}
local classCounts = {}
local FillRaidFrame 
local fillRaidFrameManualClose = false 
local isCheckAndRemoveEnabled = false
local starterSequenceRunning = false
local continueFillAfterStarter = false


if FillRaidBotsSavedSettings == nil then
    FillRaidBotsSavedSettings = {}
end


local function InitializeSettings()
    
    if FillRaidBotsSavedSettings.isCheckAndRemoveEnabled == nil then
        FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = false  
    end
end
--=================================================
-- Generate toggle functions from UISettings.lua --
--=================================================
for _, section in ipairs(SettingsConfig.sections) do
    for _, item in ipairs(section.items) do
        if item.type == "checkbox" and item.toggle then

            local varName = item.toggle          
            local funcBase = string.gsub(varName, "Enabled$", "")
            local funcName = "Toggle"..funcBase 

            if not _G[funcName] then
                
                _G[funcName] = function(isChecked)
                    _G[varName] = isChecked
                end
            end
        end
    end
end




----------------------VIP Detector--------------------------
local vipFrame = CreateFrame("Frame", "VIPDetectorFrame")
local isVIP = false
local vipTimer = 0
local vipListening = true


local VIP_KEYWORDS = {
    "repaired.",
}


vipFrame:RegisterEvent("CHAT_MSG_SYSTEM")
vipFrame:RegisterEvent("PLAYER_ENTERING_WORLD")


local function IsVIPMessage(msg)
    for _, keyword in ipairs(VIP_KEYWORDS) do
        if string.find(msg, keyword) then
            return true
        end
    end
    return false
end

vipFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        if not FillRaidBotsSavedSettings.isVIP then
            SendChatMessage(".repair", "WHISPER", nil, UnitName("player"))
            vipTimer = 0
            vipListening = true
            self:SetScript("OnUpdate", function(self, delta)
                if vipListening and not FillRaidBotsSavedSettings.isVIP then
                    vipTimer = vipTimer + delta
                    if vipTimer > 10 then
                        vipListening = false
                        DebugMessage("|cffffff00[VIP SCAN DONE]|r No VIP detected.", "debuginfo")
                        self:SetScript("OnUpdate", nil)

						local cb = GetSettingsCheckbox("isAutoRepairEnabled")
						if cb then
							cb:SetChecked(false)
							cb:Disable()
							cb.text:SetTextColor(0.5, 0.5, 0.5)
							cb.text:SetText("Auto Repair (VIP ONLY)")
						end

						local vipCb = GetSettingsCheckbox("useVipPresets")
						if vipCb then
							vipCb:SetChecked(false)
							vipCb:Disable()
							vipCb.text:SetTextColor(0.5, 0.5, 0.5)
							vipCb.text:SetText("Use VIP Presets (VIP ONLY)")
						end
                    end
                end
            end)
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        if vipListening and not FillRaidBotsSavedSettings.isVIP then
            local msg = arg1
            if msg and IsVIPMessage(msg) then
                isVIP = true
                FillRaidBotsSavedSettings.isVIP = true

				local cb = GetSettingsCheckbox("isAutoRepairEnabled")
				if cb then
					cb:SetChecked(FillRaidBotsSavedSettings.isAutoRepairEnabled and true or false)
					cb:Enable()
					cb.text:SetTextColor(1, 1, 1)
					cb.text:SetText("Auto Repair")
				end

				local vipCb = GetSettingsCheckbox("useVipPresets")
				if vipCb then
					vipCb:SetChecked(FillRaidBotsSavedSettings.useVipPresets and true or false)
					vipCb:Enable()
					vipCb.text:SetTextColor(1, 1, 1)
					vipCb.text:SetText("Use VIP Presets")
				end

                print("|cff00ff00[VIP DETECTED]|r You have VIP status!")
				
                vipListening = false
                self:SetScript("OnUpdate", nil)
            end
        end
    end
end)

-- ==============
-- auto repair --
-- ==============
local durabilityFrame = CreateFrame("Frame", "DurabilityRepairFrame")
durabilityFrame:RegisterEvent("PLAYER_UNGHOST")
durabilityFrame:RegisterEvent("PLAYER_ALIVE")
durabilityFrame:RegisterEvent("PLAYER_ENTERING_WORLD")


local DURABLE_SLOTS = {
    "HeadSlot", "ShoulderSlot", "ChestSlot", "WaistSlot", "LegsSlot",
    "FeetSlot", "WristSlot", "HandsSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"
}

local scanTooltip = CreateFrame("GameTooltip", "DurabilityScannerTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function ParseDurability(text)
    local current, max = text:match("(%d+)%s*/%s*(%d+)")
    if current and max then
        return tonumber(current), tonumber(max)
    end
    return nil, nil
end

local function GetDurability(slotId)
    scanTooltip:ClearLines()
    scanTooltip:SetInventoryItem("player", slotId)

    for i = 2, scanTooltip:NumLines() do
        local leftText = _G["DurabilityScannerTooltipTextLeft" .. i]
        if leftText then
            local text = leftText:GetText()
            if text then
                local current, max = ParseDurability(text)
                if current and max then
                    return current, max
                end
            end
        end
    end
    return nil, nil
end

local function ColorPercent(pct)
    if pct > 80 then
        return "|cff00ff00" .. string.format("%.0f%%", pct) .. "|r"
    elseif pct > 50 then
        return "|cffffff00" .. string.format("%.0f%%", pct) .. "|r"
    else
        return "|cffff0000" .. string.format("%.0f%%", pct) .. "|r"
    end
end


local lastRepairTime = 0

local function CheckAndRepair()
    if not AutoRepairEnabled or UnitIsGhost("player") then return end

   
    if GetTime() - lastRepairTime < 3 then return end

    local totalCurrent, totalMax = 0, 0

    for _, slotName in ipairs(DURABLE_SLOTS) do
        local slotId = GetInventorySlotInfo(slotName)
        if slotId then
            local current, max = GetDurability(slotId)
            if current and max then
                totalCurrent = totalCurrent + current
                totalMax = totalMax + max
            end
        end
    end

    if totalMax > 0 then
        local avg = (totalCurrent / totalMax) * 100
        if avg < 100 then
            DEFAULT_CHAT_FRAME:AddMessage("Durability is " .. ColorPercent(avg) .. " Repairing...")
            C_Timer.After(0.5, function()
                SendChatMessage(".repair", "WHISPER", nil, UnitName("player"))
            end)
            lastRepairTime = GetTime()
        end
    end
end

durabilityFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self.ready = true
    elseif (event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE") and self.ready then
       
        C_Timer.After(1, function()
            CheckAndRepair()
        end)
    end
end)


------------------------auto invite guild-----------------------------
local guildCheckFrame = CreateFrame("Frame")
guildCheckFrame:RegisterEvent("PLAYER_ENTERING_WORLD") 

local delayguildcheck = 5
local waiting = false

guildCheckFrame:SetScript("OnEvent", function(self, event)
    if not AutoJoinGuildEnabled then return end

   
    C_Timer.After(delayguildcheck, function()
        local guildName = GetGuildInfo("player")
        if not guildName then
            print("FillRaidBots: You are not in a guild. Attempting to join.")
            SendChatMessage(".i", "WHISPER", nil, UnitName("player")) 
        else
            QueueDebugMessage("INFO: You are in a guild: " .. guildName, "debuginfo")
        end
    end)
end)

------------------------------------------------------------------------
function CreateSeparatorLine(parent, x, y, width, anchor)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetWidth(width or 100)
    if anchor then
        line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -6)
    else
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
    end
    line:SetTexture("Interface\\Buttons\\WHITE8x8")
    line:SetVertexColor(1, 1, 1, 0.5)
    return line
end


function QueueMessage(message, recipient, incrementBotCount)
    table.insert(messageQueue,
        { message = message, recipient = recipient or "none", incrementBotCount = incrementBotCount or false })
end
function QueueDebugMessage(message, recipient)
    table.insert(DebugMessageQueue,
        { message = message, recipient = recipient or "none" })
end

local CanManageRaidBots
local IsFillBlocked
local RefreshBotManagementPermissionState


local RoleDetector = CreateFrame("Frame")

RoleDetector:RegisterEvent("PLAYER_ENTERING_WORLD") 
RoleDetector:RegisterEvent("GROUP_ROSTER_UPDATE") 
RoleDetector:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")


local wasInGroup = false

local spellDictionary = {
    
    ["Defensive Stance"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Sunder Armor"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Taunt"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Revenge"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Shield Wall"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Last Stand"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Shield Block"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Mocking Blow"] = {class = "warrior", role = "tank", confidenceIncrease = 3},
    ["Greater Armor"] = {class = "warrior", role = "tank", confidenceIncrease = 3},	
   
    ["Mortal Strike"] = {class = "warrior", role = "meleedps", confidenceIncrease = 3},
    ["Bloodthirst"] = {class = "warrior", role = "meleedps", confidenceIncrease = 3},
    ["Whirlwind"] = {class = "warrior", role = "meleedps", confidenceIncrease = 3},

    
    ["Greater Heal"] = {class = "priest", role = "healer", confidenceIncrease = 3},
    ["Prayer of Healing"] = {class = "priest", role = "healer", confidenceIncrease = 3},
    ["Flash Heal"] = {class = "priest", role = "healer", confidenceIncrease = 3},
    ["Heal"] = {class = "priest", role = "healer", confidenceIncrease = 3},
    ["Holy Nova"] = {class = "priest", role = "healer", confidenceIncrease = 3},
    ["Shadow Word: Pain"] = {class = "priest", role = "rangedps", confidenceIncrease = 3},
    ["Mind Blast"] = {class = "priest", role = "rangedps", confidenceIncrease = 3},
    ["Mind Flay"] = {class = "priest", role = "rangedps", confidenceIncrease = 3},
    ["Shadowform"] = {class = "priest", role = "rangedps", confidenceIncrease = 3},
    ["Vampiric Embrace"] = {class = "priest", role = "rangedps", confidenceIncrease = 3},

    
    ["Dire Bear Form"] = {class = "druid", role = "tank", confidenceIncrease = 3},
    ["Maul"] = {class = "druid", role = "tank", confidenceIncrease = 3},
    ["Growl"] = {class = "druid", role = "tank", confidenceIncrease = 3},
    ["Swipe"] = {class = "druid", role = "tank", confidenceIncrease = 3},
    ["Cat Form"] = {class = "druid", role = "meleedps", confidenceIncrease = 3},
    ["Rake"] = {class = "druid", role = "meleedps", confidenceIncrease = 3},
    ["Ferocious Bite"] = {class = "druid", role = "meleedps", confidenceIncrease = 3},
    ["Shred"] = {class = "druid", role = "meleedps", confidenceIncrease = 3},
    ["Healing Touch"] = {class = "druid", role = "healer", confidenceIncrease = 3},
   
    ["Regrowth"] = {class = "druid", role = "healer", confidenceIncrease = 3},
    ["Tranquility"] = {class = "druid", role = "healer", confidenceIncrease = 3},
    ["Starfire"] = {class = "druid", role = "rangedps", confidenceIncrease = 3},
    ["Moonfire"] = {class = "druid", role = "rangedps", confidenceIncrease = 3},
    ["Hurricane"] = {class = "druid", role = "rangedps", confidenceIncrease = 3},
    ["Moonkin Form"] = {class = "druid", role = "rangedps", confidenceIncrease = 3},	

    
    ["Healing Wave"] = {class = "shaman", role = "healer", confidenceIncrease = 3},
    ["Chain Heal"] = {class = "shaman", role = "healer", confidenceIncrease = 3},
    ["Lesser Healing Wave"] = {class = "shaman", role = "healer", confidenceIncrease = 3},
    ["Lightning Bolt"] = {class = "shaman", role = "rangedps", confidenceIncrease = 3},
    ["Chain Lightning"] = {class = "shaman", role = "rangedps", confidenceIncrease = 3},
    ["Earth Shock"] = {class = "shaman", role = "rangedps", confidenceIncrease = 3},
    ["Flame Shock"] = {class = "shaman", role = "rangedps", confidenceIncrease = 3},
    ["Stormstrike"] = {class = "shaman", role = "meleedps", confidenceIncrease = 3},
    ["Lava Lash"] = {class = "shaman", role = "meleedps", confidenceIncrease = 3},
    ["Windfury Weapon"] = {class = "shaman", role = "meleedps", confidenceIncrease = 3},

    
    ["Holy Light"] = {class = "paladin", role = "healer", confidenceIncrease = 3},
    ["Flash of Light"] = {class = "paladin", role = "healer", confidenceIncrease = 3},
    ["Holy Shock"] = {class = "paladin", role = "healer", confidenceIncrease = 3},
    ["Righteous Fury"] = {class = "paladin", role = "tank", confidenceIncrease = 3},
    ["Seal of Righteousness"] = {class = "paladin", role = "tank", confidenceIncrease = 3},
    ["Shield of the Righteous"] = {class = "paladin", role = "tank", confidenceIncrease = 3},
    ["Consecration"] = {class = "paladin", role = "tank", confidenceIncrease = 3},
    ["Seal of Command"] = {class = "paladin", role = "meleedps", confidenceIncrease = 3},
    ["Crusader Strike"] = {class = "paladin", role = "meleedps", confidenceIncrease = 3},
    ["Judgement of Command"] = {class = "paladin", role = "meleedps", confidenceIncrease = 3},

    
    ["Arcane Missiles"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Arcane Power"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Arcane Explosion"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Fireball"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Frostbolt"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Ice Armor"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Blizzard"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Pyroblast"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Frost Nova"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Cone of Cold"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Scorch"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Flamestrike"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Fire Blast"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},
    ["Ice Block"] = {class = "mage", role = "rangedps", confidenceIncrease = 3},

    
    ["Shadow Bolt"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Incinerate"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Corruption"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Immolate"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Unstable Affliction"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Siphon Life"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Curse of Agony"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Curse of Doom"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Seed of Corruption"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Rain of Fire"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Life Tap"] = {class = "warlock", role = "rangedps", confidenceIncrease = 1},
    ["Hellfire"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Shadowburn"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Death Coil"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Drain Soul"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},
    ["Drain Life"] = {class = "warlock", role = "rangedps", confidenceIncrease = 3},


    
    ["Stealth"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},  
    ["Backstab"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Sinister Strike"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Eviscerate"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Ambush"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Slice and Dice"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Gouge"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Hemorrhage"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Rupture"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Kidney Shot"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Expose Armor"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Sprint"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Cloak of Shadows"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Vanish"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Distract"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Shadowstep"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Preparation"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},
    ["Blind"] = {class = "rogue", role = "meleedps", confidenceIncrease = 3},

    
    
    ["Aimed Shot"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Multi-Shot"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Arcane Shot"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Explosive Shot"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Serpent Sting"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Scatter Shot"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Feign Death"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Steady Shot"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Rapid Fire"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Kill Command"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Viper Sting"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Hunter's Mark"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
    ["Volley"] = {class = "hunter", role = "rangedps", confidenceIncrease = 3},
   
}


local patterns = {
    "^(.-) begins to cast",            
    "^(.-) casts",                     
    "fades from (.+)$",                
    "^(.-)'s ",                        
    "^(.-) gains",                     
    "^(.-) deals",                     
    "^(.-) hits",                      
    "^(.-) suffers",                   
    "^(.-) is hit by",                 
    "^(.-) heals",                     
    "^(.-) receives healing from",     
    "^(.-) crits",                     
    "^(.-) absorbs",                   
    "^(.-) resists",                   
}


function RemoveFirstBot()
    if firstBotName then
      

        if UnitExists(firstBotName) then
            QueueDebugMessage("Botname removed: True", "debugremove")
            initialBotRemoved = true
        end
    else
        QueueDebugMessage("Error: First bot's name not captured.", "debugremove")
    end
end



local playerData = playerData or {}
local detectedPlayers = detectedPlayers or {}  
local detectedPlayerCount = detectedPlayerCount or 0

function extractPlayerName(message)
    for _, pattern in ipairs(patterns) do
        local startIdx, endIdx, name = string.find(message, pattern)
        if startIdx then 
            return name or string.sub(message, startIdx, endIdx) 
        end
    end
    return nil
end

local function normalizePlayerName(playerName)
    if type(playerName) ~= "string" then
        return nil
    end

    local cleanName = ""
    for i = 1, #playerName do
        local char = string.sub(playerName, i, i)
        if (char >= "a" and char <= "z") or
           (char >= "A" and char <= "Z") or
           (char >= "0" and char <= "9") or
           char == "*" then
            cleanName = cleanName .. string.lower(char)
        end
    end

    return cleanName
end

local classColors = {
    warrior = "|cFFC79C6E",
    mage = "|cFF40C7EB",
    warlock = "|cFF8788EE",
    hunter = "|cFFABD473",
    rogue = "|cFFFFF569",
    paladin = "|cFFF58CBA",
    shaman = "|cFF0070DE",
    druid = "|cFFFF7D0A",
    priest = "|cFFFFFFFF",
}

local resetColor = "|r"

local function GetColoredClass(classRole)
    if not classRole then return "" end

    
    classRole = string.gsub(classRole, "^%s*(.-)%s*$", "%1")

    
    local spacePos = string.find(classRole, " ")

    local class
    if spacePos then
        class = string.sub(classRole, 1, spacePos - 1)
    else
        class = classRole
    end

    local lower = string.lower(class)

    
    local display = string.upper(string.sub(lower, 1, 1)) ..
                    string.sub(lower, 2)

    local color = classColors[lower]

    if color then
        return color .. display .. resetColor
    end

    return display
end


local function updateRoleConfidence(playerName, class, role, confidenceIncrease, spell)

    local normalizedPlayerName = normalizePlayerName(playerName)
    if not normalizedPlayerName then return end  

    local coloredClass = GetColoredClass(class)
    local plainClass = string.lower(class or "")

    local data = playerData[normalizedPlayerName] or {
        classColored = coloredClass,
        ClassNoColor = plainClass,
        role = role,
        roleConfidence = 0
    }

    data.roleConfidence = data.roleConfidence + confidenceIncrease

    if data.roleConfidence >= 3 then
        if not detectedPlayers[normalizedPlayerName] then
            detectedPlayers[normalizedPlayerName] = true
            detectedPlayerCount = detectedPlayerCount + 1

            QueueDebugMessage(
                "Detected:" .. detectedPlayerCount ..
                " - " .. playerName ..
                " is a " .. coloredClass ..
                " (" .. role .. ") using: " .. spell,
                "debugdetection"
            )
        end
    else
        QueueDebugMessage(
            "INFO: Updated confidence for " .. playerName ..
            ": " .. data.roleConfidence,
            "debugdetection"
        )
    end

    playerData[normalizedPlayerName] = data
end

local function isBotNameInGroup(playerName)
    local normalizedPlayerName = normalizePlayerName(playerName)
    if GetNumGroupMembers() > 0 then
        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and "raid" or "party") .. i
            if UnitName(unit) and normalizePlayerName(UnitName(unit)) == normalizedPlayerName then
                return true
            end
        end
    end
    return false
end

CanManageRaidBots = function()
    if not IsInGroup() then
        return true
    end

    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

local function DetectRole(event, ...)
    if not CanManageRaidBots() then
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then

        local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        if not sourceName or not spellName then return end

        local normalizedPlayerName = normalizePlayerName(sourceName)
        if not normalizedPlayerName then return end

        if not isBotNameInGroup(normalizedPlayerName) then
            return
        end

        if subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_CAST_START" then

            if spellDictionary[spellName] then
                local role = spellDictionary[spellName].role

                
                
                local existingData = playerData[normalizedPlayerName]
                if existingData and existingData.role == "tank" then
                    return
                end

                updateRoleConfidence(sourceName, spellDictionary[spellName].class, role, spellDictionary[spellName].confidenceIncrease, spellName)
            end

        end
    end
end




local warriorDetectionCount = {}


local function CheckRaidAuras()
    if not CanManageRaidBots() then
        return
    end

    local playerName = UnitName("player")  

    for i = 1, GetNumGroupMembers() do
        local unitId = "raid" .. i
        local unitName = UnitName(unitId)

        if unitName and unitName ~= playerName then  
            local unitClass, _ = UnitClass(unitId)  
            unitClass = string.lower(unitClass or "")  

            local hasTankBuff = false  

            if not detectedPlayers[unitName] then
                if unitClass == "mage" or unitClass == "warlock" or unitClass == "hunter" then
                    detectedPlayers[unitName] = true  
                    updateRoleConfidence(unitName, unitClass, "rangedps", 3, "Class Detection")
                elseif unitClass == "rogue" then
                    detectedPlayers[unitName] = true  
                    updateRoleConfidence(unitName, unitClass, "meleedps", 3, "Class Detection")
                end
            end

            for j = 1, 16 do
                local buffName = UnitBuff(unitId, j)
                if not buffName then break end  

                if buffName == "Greater Armor" then  
                    hasTankBuff = true  
                    if not detectedPlayers[unitName] then
                        detectedPlayers[unitName] = true  
                        updateRoleConfidence(unitName, unitClass, "tank", 3, "Greater Armor")
                    end
                    break 
                end
            end

            if unitClass == "warrior" and not hasTankBuff and not detectedPlayers[unitName] then
                if not warriorDetectionCount[unitName] then
                    warriorDetectionCount[unitName] = 1  
                else
                    warriorDetectionCount[unitName] = warriorDetectionCount[unitName] + 1  
                end

                
                
                
                if warriorDetectionCount[unitName] >= 2 then
                    detectedPlayers[unitName] = true  
                    updateRoleConfidence(unitName, "warrior", "meleedps", 3, "Checked 2 times")
                    warriorDetectionCount[unitName] = nil  
                end
            end
        end
    end
end














local checkRaidAurasTimer = nil
local checkRaidAurasSecondTimer = nil
local previousGroupSize = 0
local hadBotManagementPermission = true

local function CancelCheckRaidAurasTimers()
    if checkRaidAurasTimer then
        checkRaidAurasTimer:Cancel()
        checkRaidAurasTimer = nil
    end

    if checkRaidAurasSecondTimer then
        checkRaidAurasSecondTimer:Cancel()
        checkRaidAurasSecondTimer = nil
    end
end

local function ScheduleCheckRaidAuras()
    if not CanManageRaidBots() then
        CancelCheckRaidAurasTimers()
        previousGroupSize = GetNumGroupMembers()
        return
    end

    local currentSize = GetNumGroupMembers()

    
    if currentSize <= previousGroupSize then
        previousGroupSize = currentSize
        return
    end
    previousGroupSize = currentSize

    
    CancelCheckRaidAurasTimers()

    
    checkRaidAurasTimer = C_Timer.NewTimer(1, function()
        CheckRaidAuras()
        checkRaidAurasTimer = nil

        
        checkRaidAurasSecondTimer = C_Timer.NewTimer(3, function()
            CheckRaidAuras()
            checkRaidAurasSecondTimer = nil
        end)
    end)
end




RoleDetector:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        RefreshBotManagementPermissionState()
    end

    if event == "GROUP_ROSTER_UPDATE" then
        ScheduleCheckRaidAuras()
    else
        DetectRole(event, ...)
    end
end)

local RoleRemoverFrame = CreateFrame("Frame")

RoleRemoverFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
RoleRemoverFrame:RegisterEvent("RAID_ROSTER_UPDATE")


local wasInGroup = false

local groupMembers = {}
local ReplaceDeadBot = {}


local function normalizePlayerName(name)
    if type(name) ~= "string" then
        return nil
    end

    local cleanName = ""
    for i = 1, #name do
        local char = string.sub(name, i, i)
        if (char >= "a" and char <= "z") or
           (char >= "A" and char <= "Z") or
           (char >= "0" and char <= "9") or
           char == "*" then
            cleanName = cleanName .. string.lower(char)
        end
    end

    return cleanName
end

local function UpdateGroupMembers()
    
    groupMembers = {}

    
    local numGroupMembers = GetNumGroupMembers() 
    local prefix = IsInRaid() and "raid" or "party"

    for i = 1, numGroupMembers do
        local name = UnitName(prefix .. i)
        if name then
            groupMembers[normalizePlayerName(name)] = true
        end
    end
end


UpdateGroupMembers()
local ResetRefillLoopState
local FinishRefillLoop
local ScheduleRefillRecheck
local RecheckRefillState
local RunRefillPass
local refillLoopRunning = false
local refillRecheckPending = false
local PendingRefill = {}
local refillFinalCheckPending = false

RoleRemoverFrame:SetScript("OnEvent", function()
    RefreshBotManagementPermissionState()

    local oldGroupMembers = groupMembers

    
    UpdateGroupMembers()
    UpdateReFillButtonVisibility() 

    if refillLoopRunning and not refillRecheckPending then
        ScheduleRefillRecheck(0.2)
    end

    
    local isInGroup = GetNumGroupMembers() > 0
    if wasInGroup and not isInGroup then
        ReplaceDeadBot = {}
        ResetRefillLoopState()
        UpdateReFillButtonVisibility()
        resetData() 
        QueueDebugMessage("Cleared both lists", "debugdetection")
    end

    
    wasInGroup = isInGroup

    
    for name in pairs(oldGroupMembers) do
        local normalizedName = normalizePlayerName(name)

        
        if not groupMembers[normalizedName] then
            
            if detectedPlayers[normalizedName] then
               
                detectedPlayers[normalizedName] = nil
                detectedPlayerCount = detectedPlayerCount - 1
            end

            
            if playerData[normalizedName] then
                QueueDebugMessage("Removed: " .. normalizedName .. " from active player list!", "debugremove")
                playerData[normalizedName] = nil
            end
        end
    end
end)


local function GetRealGroupSize()
    local count = 0
    for i = 1, GetNumGroupMembers() do
        local unit = (IsInRaid() and "raid" or "party") .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name and name ~= UnitName("player") then
                count = count + 1
            end
        end
    end
    return count + 1
end
local alreadyRemoved = {}

local function markAsRemoved(name, timeout)
	alreadyRemoved[name] = true
	C_Timer.After(timeout or 15, function()
		alreadyRemoved[name] = nil
		
	end)
end

function UninviteMember(name, reason)
	local normalizedName = normalizePlayerName(name)
	if not normalizedName then
		QueueDebugMessage("ERROR: Could not normalize name for UninviteMember", "debugerror")
		return
	end

	if alreadyRemoved[normalizedName] then
		return
	end

	markAsRemoved(normalizedName)

	QueueDebugMessage("INFO: Attempting to uninvite member: " .. normalizedName .. " Reason: " .. reason, "debugremove")


	if playerData[normalizedName] then
		QueueDebugMessage("DEBUG: Player found in playerData and marked for removal: " .. normalizedName, "debugremove")
		ReplaceDeadBot[normalizedName] = playerData[normalizedName]
		playerData[normalizedName] = nil
	else
		QueueDebugMessage("WARNING: Player not found in playerData: " .. normalizedName, "debugremove")
	end

	if GetRealGroupSize() > 2 then
		SendChatMessage(".partybot remove " .. normalizedName, "GUILD")
	else
		DEFAULT_CHAT_FRAME:AddMessage("Saving last")
	end

	if reason == "dead" then
		QueueDebugMessage(normalizedName .. " has been uninvited because they are dead.", "debugremove")
	elseif reason == "firstBotRemoved" then
		QueueDebugMessage("10 bots added. Removing party bot: " .. normalizedName, "debugremove")
		firstBotName = nil
		ReplaceDeadBot[normalizedName] = nil
	else
		QueueDebugMessage(normalizedName .. " has been uninvited.", "debugremove")
	end
end

function resetData()
    playerData = {}
    detectedPlayers = {}
    detectedPlayerCount = 0
    QueueDebugMessage("INFO: All player data has been reset.", "debuginfo")
end

RefreshBotManagementPermissionState = function()
    local hasPermission = CanManageRaidBots()

    if hadBotManagementPermission and not hasPermission then
        resetData()
        warriorDetectionCount = {}
        previousGroupSize = 0
        CancelCheckRaidAurasTimers()
    elseif not hadBotManagementPermission and hasPermission then
        previousGroupSize = 0
    end

    hadBotManagementPermission = hasPermission
end

SLASH_ROLELIST1 = "/rolelist"
SlashCmdList["ROLELIST"] = function()
    QueueDebugMessage("Player Role List:", "debuginfo")
    local count = 0

    for playerName, data in pairs(playerData) do
        count = count + 1
        QueueDebugMessage(count .. ". " .. playerName .. " - Class: " .. data.classColored .. ", Role: " .. data.role, "debuginfo")
    end
end

local function CreateRemoveBotButton()
    
    local removeBotButton = CreateFrame("Button", "RemoveFirstBotButton", UIParent, "UIPanelButtonTemplate")
    removeBotButton:SetSize(120, 30) 
    removeBotButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100) 
    removeBotButton:SetText("Remove First Bot") 
    removeBotButton:Hide() 

    
    removeBotButton:SetMovable(true)
    removeBotButton:SetUserPlaced(true) 
    removeBotButton:EnableMouse(true)
    removeBotButton:RegisterForDrag("LeftButton")

    
    removeBotButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    removeBotButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    
    removeBotButton:SetScript("OnClick", function()
        RemoveFirstBot() 
        removeBotButton:Hide() 
    end)

    
    removeBotButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(removeBotButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to remove the first bot from the raid. Drag to move.")
        GameTooltip:Show()
    end)

    removeBotButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return removeBotButton 
end



local removeBotButton = CreateRemoveBotButton()

local combatCheckFrame = CreateFrame("Frame")
combatCheckFrame:SetScript("OnUpdate", nil)
local botCount = 0
local initialBotRemoved = false
local isInCombat = false
local retryTimerRunning = false
local checkInterval = 1 
local incombatmessagesent = false
local lastTimeChecked = 0




local function IsAnyGroupMemberInCombat()
    local groupSize = GetNumGroupMembers()
    local prefix = IsInRaid() and "raid" or "party"

    for i = 1, groupSize do
        if UnitAffectingCombat(prefix .. i) then
            return true 
        end
    end
    return false
end

local fillPausedByDeath = false

IsFillBlocked = function()
    if UnitIsDead("player") or UnitIsGhost("player") then
        return true, "dead"
    end

    if IsAnyGroupMemberInCombat() then
        return true, "combat"
    end

    return false, nil
end

function RetryMessageQueueProcessing()
    local currentTime = GetTime()
    if currentTime - lastTimeChecked >= checkInterval then
        local blocked, reason = IsFillBlocked()
        lastTimeChecked = currentTime 

        if not blocked then
            if fillPausedByDeath then
                QueueDebugMessage("INFO: Fill resumed after death.", "debugfilling")
                fillPausedByDeath = false
            else
                QueueDebugMessage("Resuming..", "none")
            end

            isInCombat = false
            retryTimerRunning = false
            incombatmessagesent = false    
            combatCheckFrame:SetScript("OnUpdate", nil) 
            ProcessMessageQueue() 
            ProcessDebugMessageQueue()
        elseif reason == "dead" and not fillPausedByDeath then
            QueueDebugMessage("INFO: Fill paused while player is dead.", "debugfilling")
            fillPausedByDeath = true
        end
    end
end


local firstBotRemovalFrame = CreateFrame("Frame")
firstBotRemovalFrame:RegisterEvent("GROUP_ROSTER_UPDATE")





firstBotRemovalFrame:SetScript("OnEvent", function()
    if not CanManageRaidBots() then
        return
    end

    if starterSequenceRunning then
        return
    end

    if not initialBotRemoved and GetNumGroupMembers() >= 3 then
        if firstBotName and totaly > 5 then
            initialBotRemoved = true
            QueueDebugMessage("Removed first bot: " .. firstBotName, "debuginfo")
            UninviteMember(firstBotName, "firstBotRemoved")
        end
    end
end)


local shouldStopBotAdding = false

local restrictionListener = CreateFrame("Frame")
restrictionListener:RegisterEvent("CHAT_MSG_SYSTEM")
restrictionListener:SetScript("OnEvent", function(_, _, msg)
    if msg == "You can only add bots in raid group while you are in an instance map or at world bosses." then
        DEFAULT_CHAT_FRAME:AddMessage("FillRaidBots: Bot adding stopped. You can only add up to 4 bots in this area.|r")
        shouldStopBotAdding = true
    end
end)
function ProcessMessageQueue()
    if next(messageQueue) ~= nil then 
        local messageInfo = table.remove(messageQueue, 1)
        local message = messageInfo.message
        local recipient = messageInfo.recipient


        if shouldStopBotAdding and string.find(message, "%.partybot add") then
            QueueDebugMessage("Blocked queued message due to instance/world boss restriction: " .. message, "debugfilling")
            return
        end

        if recipient == "SAY" then
            local blocked, reason = IsFillBlocked()

            if blocked then
                if reason == "dead" then
                    if not fillPausedByDeath then
                        QueueDebugMessage("INFO: Fill paused while player is dead.", "debugfilling")
                        fillPausedByDeath = true
                    end
                else
                    if not incombatmessagesent then 
                        QueueDebugMessage("Raid member in combat, waiting..", "none")
                        incombatmessagesent = true	
                    end
                end

                isInCombat = true
                if not retryTimerRunning then
                    combatCheckFrame:SetScript("OnUpdate", RetryMessageQueueProcessing)
                    retryTimerRunning = true
                end

                table.insert(messageQueue, 1, messageInfo)
                return
            else
                if fillPausedByDeath then
                    QueueDebugMessage("INFO: Fill resumed after death.", "debugfilling")
                    fillPausedByDeath = false
                end

                incombatmessagesent = false

                if recipient == "none" then
                    DEFAULT_CHAT_FRAME:AddMessage(message)
                else
                   
                    SendChatMessage(message, "GUILD")
                end					
            end
        end
    end
end

function ProcessDebugMessageQueue()
		if next(DebugMessageQueue) ~= nil then 
		local messageInfo = table.remove(DebugMessageQueue, 1)
		local message = messageInfo.message
		local recipient = messageInfo.recipient

		
		local colors = {
			["error"] = "|cFFFF0000",     
			["warning"] = "|cFFFFA500",  
			["info"] = "|cFFFFFF00",     
			["detected"] = "|cFF00FF00", 
			["added"] = "|cFF00FF00",  
			["adding"] = "|cFF00FF00",  			
			["removing"] = "|cFFADD8E6", 
			["removed"] = "|cFFADD8E6",  
			["fixgroups"] = "|cFFDDA0DD" 
		}
		local resetColor = "|r" 

		
		for keyword, color in pairs(colors) do
			
			message = string.gsub(message, "([%a]+)", function(word)
				if string.lower(word) == keyword then
					return color .. word .. resetColor
				else
					return word
				end
			end)
		end
        
        if recipient == "debug" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DebugMessage(message, "debuginfo")
            end
            return 
        end
        if recipient == "debuginfo" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DebugMessage(message, "debuginfo")
            end
            return 
        end
        if recipient == "debugfilling" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DebugMessage(message, "debugfilling")
            end
            return 
        end
        if recipient == "debugdetection" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DebugMessage(message, "debugdetection")
            end
            return 
        end
        if recipient == "debugremove" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DebugMessage(message, "debugremove")
            end
            return 
        end	
        if recipient == "debugerror" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DebugMessage(message, "debugerror")
            end
            return 
        end	
        if recipient == "debugversion" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DebugMessage(message, "debugversion")
            end
            return 
        end
        if recipient == "debugzones" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then
                DebugMessage(message, "debugzones")
            end
            return
        end
        if recipient == "none" then
            
            DEFAULT_CHAT_FRAME:AddMessage(message)
        else
            
            SendChatMessage(message, recipient)
        end

    end
end

local verifiedRealPlayers = {}
local messagecantremove = false
local hasWarnedNoPermission = false
local cantKickYourselfShown = false

local function CreateRemoveDeadBotsButton()
    local removeDeadBotsButton = CreateFrame("Button", "RemoveDeadBotsButton", UIParent, "UIPanelButtonTemplate")
    removeDeadBotsButton:SetSize(120, 30)
    removeDeadBotsButton:SetPoint("CENTER", UIParent, "CENTER", 0, -140)
    removeDeadBotsButton:SetText("Remove Dead Bots")
    removeDeadBotsButton:Hide()

    removeDeadBotsButton:SetMovable(true)
    removeDeadBotsButton:EnableMouse(true)
    removeDeadBotsButton:RegisterForDrag("LeftButton")
    removeDeadBotsButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
    removeDeadBotsButton:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local function IsBotName(name)
        return name and string.find(name, "%*") ~= nil
    end

    function removeDeadBotsFunction()
        if not CanManageRaidBots() then
            if not hasWarnedNoPermission then
                QueueDebugMessage("WARNING: You must be a raid leader or assistant to remove bots.", "debuginfo")
                hasWarnedNoPermission = true
            end
            return
        end
        hasWarnedNoPermission = false

        if not UnitIsDead("player") and not UnitIsGhost("player") then
            cantKickYourselfShown = false
        end

        local playerName = UnitName("player")
        local totalMemberCount = GetNumGroupMembers()
        local activeMemberCount = 0
        local deadBotsRemoved = false

        for i = 1, totalMemberCount do
            local unit = IsInRaid() and "raid" .. i or (i == 1 and "player" or "party" .. (i - 1))
            if UnitExists(unit) and not UnitIsGhost(unit) then
                activeMemberCount = activeMemberCount + 1
            end
        end

        QueueDebugMessage("Active members: " .. activeMemberCount .. ", Total members: " .. totalMemberCount, "debuginfo")

        for i = totalMemberCount, 1, -1 do
            local unit = IsInRaid() and "raid" .. i or (i == 1 and "player" or "party" .. (i - 1))
            local name = UnitName(unit)

            if name and UnitIsDead(unit) and not UnitIsGhost(unit) and name ~= playerName then
                if UnitIsUnit(unit, "player") then
                    QueueDebugMessage("INFO: CANNOT KICK YOURSELF", "debuginfo")
                elseif not UnitIsConnected(unit) then
                    QueueDebugMessage("INFO: CANNOT KICK OFFLINE UNIT: " .. name, "none")
                elseif not IsBotName(name) then
                    if not verifiedRealPlayers[name] then
                        QueueDebugMessage("INFO: Skipped real player (no *): " .. name, "debugremove")
                        verifiedRealPlayers[name] = true
                    end
                elseif activeMemberCount > 2 then
                    local shortName = name:match("([^%-]+)"):lower()
                    if playerData[shortName] then
                        ReplaceDeadBot[shortName] = playerData[shortName]
                        playerData[shortName] = nil
                    end
                    UninviteUnit(name)
                    deadBotsRemoved = true
                    activeMemberCount = activeMemberCount - 1
                    QueueDebugMessage("REMOVED: " .. name .. " (bot).", "debugremove")
                else
                    QueueDebugMessage("Cannot remove " .. name .. ": Not enough members left (minimum 2 required).", "debuginfo")
                end
            end
        end

        if deadBotsRemoved then
            QueueDebugMessage("Dead bots removed. Button will now hide.", "debuginfo")
            removeDeadBotsButton:Hide()
        else
            QueueDebugMessage("No dead bots were removed.", "debuginfo")
        end
    end

    removeDeadBotsButton:SetScript("OnClick", removeDeadBotsFunction)

    removeDeadBotsButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(removeDeadBotsButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to remove dead bots from the raid or party. Drag to move.")
        GameTooltip:Show()
    end)

    removeDeadBotsButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return removeDeadBotsButton
end


local removeDeadBotsButton = CreateRemoveDeadBotsButton()

local function RefreshRaidFrames()
    local refreshed = false

    if RaidFrame and RaidFrame:IsShown() then
        RaidFrame:Hide()
        RaidFrame:Show()
        QueueDebugMessage("DEBUG: Refreshed Classic RaidFrame", "debuginfo")
        refreshed = true
    end

    if CompactRaidFrameContainer and CompactRaidFrameContainer:IsShown() then
        CompactRaidFrameContainer:Hide()
        CompactRaidFrameContainer:Show()
        QueueDebugMessage("DEBUG: Refreshed Compact RaidFrame", "debuginfo")
        refreshed = true
    end

    if not refreshed then
        QueueDebugMessage("DEBUG: No visible raid frames found to refresh", "debuginfo")
    end

   
    if WorldFrame then
        WorldFrame:UnregisterEvent("RAID_ROSTER_UPDATE")
        WorldFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        QueueDebugMessage("DEBUG: Toggled RAID_ROSTER_UPDATE registration", "debuginfo")
    end
end



local removedDeadBots = {}
local isProcessing = false


local function RefreshRaidFrames()
   
    if InCombatLockdown() then
        QueueDebugMessage("DEBUG: Skipping refresh - in combat", "debuginfo")
        return
    end

   
    local function tryRefresh()
       
        if CompactRaidFrameContainer then
            if CompactRaidFrameContainer:IsShown() then
                CompactRaidFrameContainer:Hide()
                CompactRaidFrameContainer:Show()
            end
            if CompactRaidFrameManager then
                CompactRaidFrameManager_UpdateShown(CompactRaidFrameManager)
            end
        end

       
        if RaidFrame then
            if RaidFrame:IsShown() then
                RaidFrame:Hide()
                RaidFrame:Show()
            end
        end

       
        if CompactRaidFrameManager_UpdateAllFrames then
            CompactRaidFrameManager_UpdateAllFrames()
        end
        if UpdateRaidFrameOfflineStatus then
            UpdateRaidFrameOfflineStatus()
        end
    end

   
    local success, err = pcall(tryRefresh)
    if not success then
        QueueDebugMessage("DEBUG: Refresh failed: "..tostring(err), "debugerror")
    end
end
local guildDeadStatus = {}
local lastKickTime = 0
local KICK_COOLDOWN = 0.1 
local autoRemoveWaitingForRoster = false
local autoRemoveResumePending = false

local function CountRealGroupMembers()
    local count = 0
    if IsInRaid() then
        for i = 1, 40 do
            if UnitExists("raid" .. i) then
                count = count + 1
            end
        end
    elseif IsInGroup() then
        count = 1 
        for i = 1, 4 do
            if UnitExists("party" .. i) then
                count = count + 1
            end
        end
    end
    return count
end


local function CheckAndRemoveDeadBots()
	if InCombatLockdown() then return end

	if not UnitIsDead("player") and not UnitIsGhost("player") then
		cantKickYourselfShown = false
	end

	local settings = FillRaidBotsSavedSettings or {}
	local autoRemoveEnabled = settings.isCheckAndRemoveEnabled
	local showButtonEnabled = settings.isremoveDeadBotsButtonEnabled

	local function IsBotName(name)
		return name and string.find(name, "%*") ~= nil
	end

	if autoRemoveEnabled then
		if not CanManageRaidBots() then
			if not hasWarnedNoPermission then
				QueueDebugMessage("WARNING: You must be a raid leader or assistant to remove bots.", "debuginfo")
				hasWarnedNoPermission = true
			end
			return
		end
		hasWarnedNoPermission = false
		
		
		
		if not autoRemoveWaitingForRoster then
			local now = GetTime()
			
			
			
			

			local isInRaid = IsInRaid()
			local membersRemaining = CountRealGroupMembers()
			if membersRemaining == 0 then return end

			local minimumAllowed = 2
			local maxGroupSize = isInRaid and 40 or 5
			local maxKicks
			if isInRaid then 
				if membersRemaining > 20 then
					maxKicks = 18			
				elseif membersRemaining > 10 then
					maxKicks = 8
				elseif membersRemaining > 5 then
					maxKicks = 3
				else
					maxKicks = 1
				end
			else
				maxKicks = 1
			end
			local kicks = 0

			for i = 1, maxGroupSize do
				if kicks >= maxKicks then break end

				local unit = isInRaid and ("raid" .. i) or (i == 1 and "player" or "party" .. (i - 1))
				if UnitExists(unit) then
					if UnitIsUnit(unit, "player") then
						if UnitIsDead(unit) and not UnitIsGhost(unit) and not cantKickYourselfShown then
							QueueDebugMessage("INFO: CANNOT KICK YOURSELF", "debuginfo")
							cantKickYourselfShown = true
						end
					else
						local name = UnitName(unit)
						if name and UnitIsDead(unit) and not UnitIsGhost(unit) then
							if not UnitIsConnected(unit) then
								QueueDebugMessage("INFO: CANNOT KICK OFFLINE UNIT: " .. name, "debuginfo")
							elseif IsBotName(name) and membersRemaining > minimumAllowed then
								UninviteMember(name, "dead")
								membersRemaining = membersRemaining - 1
								kicks = kicks + 1
							elseif verifiedRealPlayers[name] then
							elseif not IsBotName(name) then
								QueueDebugMessage("INFO: Skipped real player (no *): " .. name, "debuginfo")
								verifiedRealPlayers[name] = true
							else
								if not messagecantremove then
									QueueDebugMessage("INFO: Stopped kicking. Members left: " .. membersRemaining .. ". Preventing group disband.", "debuginfo")
									messagecantremove = true
								end
								break
							end
						end
					end
				end
			end

			if kicks > 0 then
				lastKickTime = GetTime()
				autoRemoveWaitingForRoster = true
			end
		end
	end

	local hasDeadBots = false
	local activeMemberCount = 0
	local groupType = IsInRaid() and "raid" or "party"

	for i = 1, GetNumGroupMembers() do
		local unit = (groupType == "party" and i == 1) and "player" or (groupType .. i)
		if UnitExists(unit) and not UnitIsUnit(unit, "player") and UnitIsConnected(unit) then
			local name = UnitName(unit)
			if name and IsBotName(name) then
				if not UnitIsGhost(unit) then
					activeMemberCount = activeMemberCount + 1
				end
				if UnitHealth(unit) == 0 then
					hasDeadBots = true
				end
			end
		end
	end

	
	if showButtonEnabled and not autoRemoveEnabled then
		if hasDeadBots and activeMemberCount >= 2 then
			removeDeadBotsButton:Show()
		else
			removeDeadBotsButton:Hide()
		end
	elseif autoRemoveEnabled then
		removeDeadBotsButton:Hide()
	end

	isProcessing = false
end






local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_UNGHOST")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if not autoRemoveWaitingForRoster then
            C_Timer.After(2, CheckAndRemoveDeadBots)
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if autoRemoveWaitingForRoster then
            autoRemoveWaitingForRoster = false

            if not autoRemoveResumePending and not InCombatLockdown() then
                autoRemoveResumePending = true
                C_Timer.After(0, function() 
                    autoRemoveResumePending = false
                    CheckAndRemoveDeadBots()
                end)
            end
        end

        if not InCombatLockdown() then
            RefreshRaidFrames()
        end
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        cantKickYourselfShown = false
    elseif not InCombatLockdown() then
        RefreshRaidFrames()
    end
end)






local function IsBotName(name)
    return name and string.find(name, "%*") ~= nil
end

function SaveRaidMembersAndSetFirstBot()
    local playerName = UnitName("player")
    firstBotName = nil

    local numRaidMembers = GetNumRaidMembers and GetNumRaidMembers() or GetNumGroupMembers()
    for i = 1, numRaidMembers do
        local unit = IsInRaid() and "raid" .. i or "party" .. i
        local name = UnitName(unit)

        if name and name ~= playerName and IsBotName(name) then
            firstBotName = name
            break
        end
    end

    if firstBotName then
        QueueDebugMessage("INFO: First bot in raid set to: " .. firstBotName, "debuginfo")
    else
        QueueDebugMessage("WARNING: No bot found in raid to set as first bot.", "debuginfo")
    end
end


local function SavePartyMembersAndSetFirstBot()
    local playerName = UnitName("player")
    firstBotName = nil

    if IsInRaid() then
        QueueDebugMessage("In a raid group.", "debuginfo")
        for i = 1, GetNumGroupMembers() do
            local name = UnitName("raid" .. i)
            if name then
                QueueDebugMessage("Found raid member: " .. name, "debuginfo")
            else
                QueueDebugMessage("No name found for raid unit " .. i, "debuginfo")
            end

            if name and name ~= playerName and IsBotName(name) then
                firstBotName = name
                break
            end
        end
    else
        QueueDebugMessage("In a party group.", "debuginfo")
        for i = 1, GetNumGroupMembers() - 1 do
            local name = UnitName("party" .. i)
            if not name then
                QueueDebugMessage("No name found for party unit " .. i, "debuginfo")
            end

            if name and name ~= playerName and IsBotName(name) then
                firstBotName = name
                break
            end
        end
    end

    if firstBotName then
        QueueDebugMessage("First bot set to: " .. firstBotName, "debuginfo")
    else
        QueueDebugMessage("Error: No bot found to set as the first bot.", "debuginfo")
    end
end







local function ResetStarterSequenceState()
    starterSequenceRunning = false
    continueFillAfterStarter = false
    starterSwapDone = false
    initialBotRemoved = false
    firstBotName = nil
    botCount = 0
end

function resetfirstbot_OnEvent(self, event)
    if event == "RAID_ROSTER_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
        if GetNumGroupMembers() == 0 then
            ResetStarterSequenceState()
            QueueDebugMessage("Bot state reset: No members in party or raid.", "debuginfo")
        end
    end
end


local resetBotFrame = CreateFrame("Frame")
resetBotFrame:RegisterEvent("RAID_ROSTER_UPDATE")
resetBotFrame:RegisterEvent("GROUP_ROSTER_UPDATE") 
resetBotFrame:SetScript("OnEvent", resetfirstbot_OnEvent)



local function ProcessMessages()
    ProcessMessageQueue()
	ProcessDebugMessageQueue()
    nextUpdateTime = GetTime() + delay 
end

local function StartTimer()
    C_Timer.After(delay, function()
        ProcessMessages()
		CheckAndRemoveDeadBots()
        StartTimer() 
    end)
end


StartTimer()


function FillRaid_OnLoad(self, event, ...)
    if event == "ADDON_LOADED" then
        
        self:RegisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent('RAID_ROSTER_UPDATE')
        self:RegisterEvent('GROUP_ROSTER_UPDATE')
        self:RegisterEvent("CHAT_MSG_SYSTEM")

        QueueDebugMessage("FillRaidBots [" .. versionNumber .. "]|cff00FF00 loaded|cffffffff", "none")
    end
end






--========================
-- Helper: Determine which loot method to apply
--========================
local function GetSelectedLootMethod()
    if FillRaidBotsSavedSettings.isFFAEnabled then
        return "freeforall"
    elseif FillRaidBotsSavedSettings.isGroupLootEnabled then
        return "group"
    elseif FillRaidBotsSavedSettings.isMasterLootEnabled then
        return "master"
    end
end

--========================
-- Loot Logic
--========================
local hasAppliedLoot = false

local function ApplySavedLootMethod()
    if not isLootTypeEnabled then return end
    if not UnitIsGroupLeader("player") then return end
    if hasAppliedLoot then return end

    local selectedMethod = GetSelectedLootMethod()
    if not selectedMethod then return end

    local currentMethod = GetLootMethod()

    if currentMethod ~= selectedMethod then
        if selectedMethod == "master" then
            SetLootMethod("master", UnitName("player"))
            DEFAULT_CHAT_FRAME:AddMessage("Loot set to Master Loot")
        else
            SetLootMethod(selectedMethod)
            DEFAULT_CHAT_FRAME:AddMessage("Loot set to " .. (selectedMethod == "group" and "Group Loot" or "FFA"))
        end
    end

    hasAppliedLoot = true
end

--==================================================
-- Event-frame
--==================================================
resetBotFrame:SetScript("OnEvent", function(self, event, arg1)

    resetfirstbot_OnEvent(self, event)

    if UnitIsGroupLeader("player") then
        if not hasAppliedLoot then
            ApplySavedLootMethod()
        end
    else
        hasAppliedLoot = false
    end
end)

local originalSFXVolume = nil

function ToggleSoundEffectsVolume(action)
	if AutoMuteSoundEnabled then
		if action == "lower" then
			if not originalSFXVolume then
				originalSFXVolume = GetCVar("Sound_SFXVolume")
				SetCVar("Sound_SFXVolume", "0.1")
				QueueDebugMessage("Sound effects volume lowered.", "debuginfo")
			else
			
			end
		elseif action == "restore" then
			if originalSFXVolume then
				C_Timer.After(2, function()
					SetCVar("Sound_SFXVolume", originalSFXVolume)
					QueueDebugMessage("Sound effects volume restored.", "debuginfo")
					originalSFXVolume = nil
				end)
			else
				QueueDebugMessage("No volume to restore.", "debuginfo")
			end
		end
	end	
end

local MAX_PLAYERS_PER_GROUP = 5
local MAX_GROUPS = 8
local isFixingGroups = false
local moveDelay = 0.1 
local lastMoveTime = 0
local moveQueue = {} 
local healerClasses = {"PALADIN", "PRIEST", "DRUID", "SHAMAN"} 
local currentPhase = 1
local FixGroups
pendingAddOthersFunc = nil
pendingAddOthersStarted = false
local starterSwapDone = false
local function TakeNextPresetBot(healers, others)
    if table.getn(healers) > 0 then
        return table.remove(healers, 1)
    end

    if table.getn(others) > 0 then
        return table.remove(others, 1)
    end

    return nil
end

local FillRaid



local function EnsureFirstBotFromCurrentGroup()
    if firstBotName then
        return true
    end

    if IsInRaid() then
        SaveRaidMembersAndSetFirstBot()
    else
        SavePartyMembersAndSetFirstBot()
    end

    if firstBotName then
        QueueDebugMessage("Using existing bot as starter bot: " .. firstBotName, "debugfilling")
        return true
    end

    QueueDebugMessage("Could not find an existing bot to use as starter bot.", "debugerror")
    return false
end

local function TakeNextPresetBot(healers, others)
    if table.getn(healers) > 0 then
        return table.remove(healers, 1)
    end

    if table.getn(others) > 0 then
        return table.remove(others, 1)
    end

    return nil
end

local function QueueRemainingBots(healers, others, totalExpected)
    QueueDebugMessage("Adding: Going to add healers:" .. table.getn(healers), "debugfilling")
    QueueDebugMessage("Adding: Going to add classes:" .. table.getn(others), "debugfilling")
    QueueDebugMessage("Adding: Totaly:" .. totalExpected, "debugfilling")

    for _, healer in ipairs(healers) do
        QueueMessage(".partybot add " .. string.lower(healer), "SAY", true)
        QueueDebugMessage("Added " .. healer, "debugfilling")
    end

    for _, other in ipairs(others) do
        QueueMessage(".partybot add " .. string.lower(other), "SAY", true)
        QueueDebugMessage("Added " .. other, "debugfilling")
    end
end





local function GroupHasAnyBot()
    local playerName = UnitName("player")

    if IsInRaid() then
        local numMembers = GetNumRaidMembers and GetNumRaidMembers() or GetNumGroupMembers()
        for i = 1, numMembers do
            local name = UnitName("raid" .. i)
            if name and name ~= playerName and IsBotName(name) then
                return true
            end
        end
    else
        local numMembers = GetNumGroupMembers() - 1
        for i = 1, numMembers do
            local name = UnitName("party" .. i)
            if name and name ~= playerName and IsBotName(name) then
                return true
            end
        end
    end

    return false
end





local function StartStarterBotSequence(healers, others)
    if not CanManageRaidBots() then
        QueueDebugMessage("Starter sequence blocked: you are not leader/assistant.", "debuginfo")
        return
    end

    if starterSequenceRunning then
        return
    end

    starterSequenceRunning = true
    continueFillAfterStarter = false
    initialBotRemoved = false

    local starterFrame = CreateFrame("Frame")
    local stage = 1
    local secondBotAdded = false
    local invitedStarterBot = false
    local replacementBot = nil
    local stage3StartMembers = 0

    starterFrame:SetScript("OnUpdate", function()
        
        
        
        if stage == 1 then
            if IsInRaid() then
                if not firstBotName then
                    SaveRaidMembersAndSetFirstBot()
                end

                if firstBotName then
                    QueueDebugMessage("Using existing raid bot as starter bot: " .. firstBotName, "debugfilling")
                    stage = 3
                else
                    QueueDebugMessage("Starter sequence aborted: no existing raid bot found to replace.", "debugerror")
                    ResetStarterSequenceState()
                    starterFrame:SetScript("OnUpdate", nil)
                    starterFrame:Hide()
                end

            elseif GetNumGroupMembers() == 0 then
                if not invitedStarterBot then
                    QueueMessage(".partybot add warrior tank", "SAY", true)
                    QueueDebugMessage("Inviting the first bot to start the party for a raid.", "none")
                    invitedStarterBot = true
                end

                if GetNumGroupMembers() > 0 then
                    SavePartyMembersAndSetFirstBot()
                    if firstBotName then
                        QueueDebugMessage("Starter bot joined. Saved first bot.", "debugfilling")
                        stage = 2
                    end
                end

            else
                if not firstBotName then
                    SavePartyMembersAndSetFirstBot()
                end

                if firstBotName then
                    QueueDebugMessage("Using existing party bot as starter bot: " .. firstBotName, "debugfilling")
                    stage = 2
                else
                    QueueDebugMessage("Starter sequence aborted: no existing party bot found to replace.", "debugerror")
                    ResetStarterSequenceState()
                    starterFrame:SetScript("OnUpdate", nil)
                    starterFrame:Hide()
                end
            end

        
        elseif stage == 2 then
            if not IsInRaid() then
                if GetNumGroupMembers() >= 2 then
                    ConvertToRaid()
                    QueueDebugMessage("Converted to raid.", "debugfilling")
                    stage = 3
                end
            else
                stage = 3
            end

        
        elseif stage == 3 then
            if IsInRaid() then
                if not secondBotAdded then
                    replacementBot = TakeNextPresetBot(healers, others)

                    if replacementBot then
                        stage3StartMembers = GetNumGroupMembers()
                        QueueMessage(".partybot add " .. string.lower(replacementBot), "SAY", true)
                        QueueDebugMessage("Added replacement bot: " .. replacementBot, "debugfilling")
                        secondBotAdded = true
                        stage = 4
                    else
                        QueueDebugMessage("No preset bot available for starter sequence.", "debugfilling")
                        ResetStarterSequenceState()
                        starterFrame:SetScript("OnUpdate", nil)
                        starterFrame:Hide()
                    end
                end
            end

        
        elseif stage == 4 then
            local currentMembers = GetNumGroupMembers()
            local replacementJoined = false

            if replacementBot and playerData then
                local normalizedReplacement = normalizePlayerName(replacementBot)
                replacementJoined = normalizedReplacement and playerData[normalizedReplacement] ~= nil
            end

            if replacementJoined or currentMembers >= (stage3StartMembers + 1) then
                if firstBotName and not initialBotRemoved then
                    initialBotRemoved = true
                    QueueDebugMessage("Removed starter bot: " .. firstBotName, "debuginfo")
                    UninviteMember(firstBotName, "firstBotRemoved")
                end

                stage = 5
                C_Timer.After(1, function()
                    continueFillAfterStarter = true
                end)
            end

        
        elseif stage == 5 then
            if continueFillAfterStarter then
                local remainingTotal = table.getn(healers) + table.getn(others)

                ResetStarterSequenceState()
                starterSwapDone = true
                starterFrame:SetScript("OnUpdate", nil)
                starterFrame:Hide()
                FillRaid(true, healers, others, remainingTotal)
            end
        end
    end)

    starterFrame:Show()
end






function FillRaid(skipStarterSequence, existingHealers, existingOthers, existingTotal)
	shouldStopBotAdding = false

    if not skipStarterSequence then
        starterSwapDone = false
    end

    local healers = existingHealers or {}
    local others = existingOthers or {}
    local totalHealers = 0
    local totalOthers = 0

    ToggleSoundEffectsVolume("lower")

    if existingHealers and existingOthers then
        totalHealers = table.getn(healers)
        totalOthers = table.getn(others)
        totaly = existingTotal or (totalHealers + totalOthers)
    else
        for class, count in pairs(classCounts) do
            if string.find(class, "healer") then
                for i = 1, count do
                    table.insert(healers, class)
                end
                totalHealers = totalHealers + count
            else
                for i = 1, count do
                    table.insert(others, class)
                end
                totalOthers = totalOthers + count
            end
        end

        totaly = totalHealers + totalOthers
    end

	if IsInRaid() then
		if not starterSwapDone and totaly > 0 and GroupHasAnyBot() then
			if not firstBotName then
				SaveRaidMembersAndSetFirstBot()
			end
			StartStarterBotSequence(healers, others)
			return
		end
	else
 

		local currentMembers = GetNumGroupMembers() + 1
		local targetGroupSize = currentMembers + totaly
		
		if targetGroupSize > 5 then
			if GetNumGroupMembers() == 0 then
				StartStarterBotSequence(healers, others)
				return
			elseif GroupHasAnyBot() then
				if not firstBotName then
					SavePartyMembersAndSetFirstBot()
				end
				StartStarterBotSequence(healers, others)
				return
			else
				ConvertToRaid()
				QueueDebugMessage("Converted to raid with real players only. No starter bot needed.", "debugfilling")
				QueueRemainingBots(healers, others, totaly)
				C_Timer.After(3, function()
					ToggleSoundEffectsVolume("restore")
				end)
				return
			end
		end

		if GetNumGroupMembers() == 0 then
			QueueDebugMessage("Creating a party group.", "none")
			QueueRemainingBots(healers, others, totaly)
			C_Timer.After(3, function()
				ToggleSoundEffectsVolume("restore")
			end)
			return
		end

		if GetNumGroupMembers() >= 2 then
			ConvertToRaid()
			QueueDebugMessage("Converted to raid.", "debugfilling")
		else
			QueueDebugMessage("You need at least 2 players in the group to convert to a raid.", "debugfilling")
			return
		end
	end

	local function FinalizeFillCheck(totalExpected)
		local fillCompleteFrame = CreateFrame("Frame")
		local startTime = GetTime()
		local pausedTime = 0
		local pauseStart = 0

		local MAX_WAIT_TIME = 35
		local CHECK_INTERVAL = 1
		local lastCheckTime = 0
		local lastMemberCount = 0
		local inCombatPause = false

		fillCompleteFrame:SetScript("OnUpdate", function(_, elapsed)
			lastCheckTime = lastCheckTime + elapsed
			if lastCheckTime < CHECK_INTERVAL then return end
			lastCheckTime = 0

			local currentMembers = GetNumGroupMembers()

			if currentMembers >= totalExpected then
				fillCompleteFrame:SetScript("OnUpdate", nil)
				fillCompleteFrame:Hide()
				QueueDebugMessage("Raid filling complete. Total members: " .. currentMembers, "none")
				ToggleSoundEffectsVolume("restore")
				return
			end

			local inCombatNow = IsAnyGroupMemberInCombat()

			if inCombatNow and not inCombatPause then
				pauseStart = GetTime()
				inCombatPause = true
				QueueDebugMessage("Raid filling paused - group members in combat. Will resume after combat.", "debugfilling")
			elseif not inCombatNow and inCombatPause then
				pausedTime = pausedTime + (GetTime() - pauseStart)
				inCombatPause = false
				QueueDebugMessage("Combat ended, resuming raid fill checks...", "debugfilling")
			end

			local timeElapsed = GetTime() - startTime - pausedTime
			local fillTimedOut = timeElapsed >= MAX_WAIT_TIME
			local fillStalled = timeElapsed > 10 and currentMembers == lastMemberCount

			if not inCombatNow and (fillTimedOut or fillStalled) then
				fillCompleteFrame:SetScript("OnUpdate", nil)
				fillCompleteFrame:Hide()

				if shouldStopBotAdding then
					QueueDebugMessage("Bot adding stopped due to instance/world boss restriction", "debuginfo")
				elseif currentMembers < totalExpected then
					QueueDebugMessage("Raid filling incomplete. Only " .. currentMembers .. "/" .. totalExpected .. " members joined. Possibly due to combat or lag.", "none")
				end

				ToggleSoundEffectsVolume("restore")
				return
			end

			lastMemberCount = currentMembers
		end)

		fillCompleteFrame:Show()
	end

    local function addBot(class)
        local classColors = {
            warrior = "|cFFC79C6E",
            mage = "|cFF40C7EB",
            warlock = "|cFF8788EE",
            hunter = "|cFFABD473",
            rogue = "|cFFFFF569",
            paladin = "|cFFF58CBA",
            shaman = "|cFF0070DE",
            druid = "|cFFFF7D0A",
            priest = "|cFFFFFFFF",
        }
        local resetColor = "|r"

        local plainClass = string.lower(class)
        local coloredClass = plainClass

        for className, color in pairs(classColors) do
            if string.find(plainClass, className) then
                coloredClass = color .. plainClass .. resetColor
                break
            end
        end

        QueueMessage(".partybot add " .. plainClass, "SAY", true)
        QueueDebugMessage("Added " .. coloredClass, "debugfilling")
    end

    local function addOthers()
        QueueDebugMessage("addOthers called", "debuginfo")
        if #others == 0 then
            QueueDebugMessage("No other classes to add.", "debugfilling")
            return
        end

        for _, otherClass in ipairs(others) do
            addBot(otherClass)
        end
        FinalizeFillCheck(totaly)
    end

    if totalHealers == 0 then
        QueueDebugMessage("No healers found. Skipping healer addition.", "debugerror")
        addOthers()
        return
    end

    local healersAdded = 0
    for _, healerClass in ipairs(healers) do
        addBot(healerClass)
        healersAdded = healersAdded + 1

        if healersAdded == totalHealers then
            local waitForHealersFrame = CreateFrame("Frame")
            waitForHealersFrame:SetScript("OnUpdate", function()
                if GetNumGroupMembers() >= healersAdded + 1 then
                    waitForHealersFrame:SetScript("OnUpdate", nil)
                    waitForHealersFrame:Hide()
                    QueueDebugMessage("FixGroups: All healers are in the raid. Starting FixGroups.", "debuginfo")

                    C_Timer.After(1, function()
                        isFixingGroups = true
                        currentPhase = 1
                        lastMoveTime = 0
                        moveQueue = {}
                        pendingAddOthersFunc = addOthers
                        pendingAddOthersStarted = false
                        FixGroups()
                    end)
                end
            end)
            waitForHealersFrame:Show()
            break
        end
    end
end


-------------------------fixgroups ------------------------------------------


local b = "0"
local function QueueMove(player, group)
    table.insert(moveQueue, {player = player, group = group})
end



local function TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end


local function ProcessMoveQueue()
    local currentTime = GetTime()

    if currentTime >= (lastMoveTime + moveDelay) and #moveQueue > 0 then
        local nextMove = table.remove(moveQueue, 1) 
        local player = nextMove.player
        local group = nextMove.group

       
       

        if not player.index or player.index <= 0 then
            QueueDebugMessage("Error: Invalid player index for " .. player.name, "debugerror")
            return
        end

        if group < 1 or group > MAX_GROUPS then
            QueueDebugMessage("Error: Invalid target group " .. group, "debugerror")
            return
        end

        
        local currentGroup = select(3, GetRaidRosterInfo(player.index)) 
        if currentGroup == group then
            return
        end

        
        if not player.moved then
            SetRaidSubgroup(player.index, group)


            
            player.moved = true
            lastMoveTime = currentTime

        end

    end

    
    if #moveQueue == 0 then
        if currentPhase == 1 then
            QueueDebugMessage("FixGroups: Phase 1 complete, starting Phase 2", "debuginfo")
            currentPhase = 2
            FixGroups()
        else
            QueueDebugMessage("FixGroups: Phase 2 complete, groups organized", "debuginfo")
            isFixingGroups = false

            if pendingAddOthersFunc and not pendingAddOthersStarted then
                pendingAddOthersStarted = true
                QueueDebugMessage("Added: Adding other classes after healer grouping completed.", "debugfilling")
                pendingAddOthersFunc()
                pendingAddOthersFunc = nil
            end
        end
    end
end





function FixGroups()
    if not CanManageRaidBots() then
        QueueDebugMessage("FixGroups blocked: you are not leader/assistant.", "debuginfo")
        isFixingGroups = false
        return
    end

    local groupSizes = {}
    local groupClasses = {}
    local healers = {}

    for i = 1, MAX_GROUPS do
        groupSizes[i] = 0
        groupClasses[i] = {}
    end

    local playerName = UnitName("player")
    local healerCount = 0

    for i = 1, GetNumGroupMembers() do
        local name, _, subgroup, _, _, class, _, online = GetRaidRosterInfo(i)

        if subgroup and subgroup >= 1 and subgroup <= MAX_GROUPS then
            groupSizes[subgroup] = groupSizes[subgroup] + 1
        end

        if name ~= playerName and class and TableContains(healerClasses, class) then
            healerCount = healerCount + 1

            if subgroup and subgroup >= 1 and subgroup <= MAX_GROUPS and not TableContains(groupClasses[subgroup], class) then
                table.insert(groupClasses[subgroup], class)
            end

            if IsBotName(name) then
                table.insert(healers, {name = name, index = i, group = subgroup, class = class, online = online, moved = false})
            end
        elseif name ~= playerName then
            QueueDebugMessage("Non-healer or non-player found: " .. name .. " (" .. (class or "Unknown") .. ")", "debuginfo")
        end
    end

    QueueDebugMessage("Total healers found (excluding player): " .. healerCount, "debuginfo")

    if healerCount == 0 then
        QueueDebugMessage("Error: No healers found in the group.", "debuginfo")
    end

    local totalHealers = #healers
    local maxGroups = (totaly <= 20) and 4 or MAX_GROUPS

    QueueDebugMessage("Total movable bot healers: " .. totalHealers .. ", Max groups: " .. maxGroups, "debuginfo")

    if currentPhase == 1 then
        local healersByClass = {}
        local groupIndex = 1

        for _, healer in ipairs(healers) do
            healersByClass[healer.class] = healersByClass[healer.class] or {}
            table.insert(healersByClass[healer.class], healer)
        end

        for class, classHealers in pairs(healersByClass) do
            QueueDebugMessage("Class: " .. class .. " has " .. #classHealers .. " movable bot healers", "debuginfo")
        end

        for _, classHealers in pairs(healersByClass) do
            for _, healer in ipairs(classHealers) do
                local attempts = 0

                while TableContains(groupClasses[groupIndex], healer.class) and groupIndex <= maxGroups do
                    groupIndex = groupIndex % maxGroups + 1
                    attempts = attempts + 1
                    if attempts > 20 then
                        QueueDebugMessage("Error: Too many attempts to find a group for healer " .. healer.name .. " (" .. healer.class .. ")", "debugerror")
                        break
                    end
                end

                if attempts > 20 then
                    QueueDebugMessage("Error: Unable to assign healer " .. healer.name .. " (" .. healer.class .. ") after 20 attempts.", "debugerror")
                else
                    QueueMove(healer, groupIndex)
                    groupSizes[groupIndex] = groupSizes[groupIndex] + 1
                    if not TableContains(groupClasses[groupIndex], healer.class) then
                        table.insert(groupClasses[groupIndex], healer.class)
                    end
                    QueueDebugMessage("Assigned healer " .. healer.name .. " to group " .. groupIndex, "debuginfo")
                end

                groupIndex = groupIndex % maxGroups + 1
            end
        end

    elseif currentPhase == 2 then
        local groupIndex = 1

        
        
        
        
        
        
        
        for i = 1, maxGroups do
            groupSizes[i] = 0
            groupClasses[i] = {}
        end

        table.sort(healers, function(a, b)
            if a.class == b.class then
                return a.name < b.name
            end
            return a.class < b.class
        end)

        for _, healer in ipairs(healers) do
            QueueMove(healer, groupIndex)
            groupSizes[groupIndex] = groupSizes[groupIndex] + 1
            if not TableContains(groupClasses[groupIndex], healer.class) then
                table.insert(groupClasses[groupIndex], healer.class)
            end
            QueueDebugMessage("Rebalanced healer " .. healer.name .. " to group " .. groupIndex, "debuginfo")

            groupIndex = groupIndex % maxGroups + 1
        end
    end

end


local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
    if isFixingGroups then
        ProcessMoveQueue()
    end
end)


frame:Show()

SlashCmdList["FIXGROUPS"] = function()
    isFixingGroups = true
    currentPhase = 1
    lastMoveTime = 0
    moveQueue = {}
    FixGroups()
end

SLASH_FIXGROUPS1 = "/fixgroups"

-------------------------------help buttons -----------------------------
local function CreateHelpButton(parentFrame, relativeFrame, offsetX, offsetY, tooltipText, buttonText)
    local helpBtn = CreateFrame("Button", nil, parentFrame)
    helpBtn:SetWidth(16)
    helpBtn:SetHeight(16)
    helpBtn:SetPoint("LEFT", relativeFrame, "RIGHT", offsetX, offsetY)

   
    helpBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")

   
    helpBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    helpBtn:GetHighlightTexture():SetBlendMode("ADD")

   
    helpBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(helpBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText(buttonText)
        GameTooltip:AddLine(tooltipText, 1,1,1)
        GameTooltip:Show()
    end)

    helpBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

   
    helpBtn:SetScript("OnClick", function()
        
        local _, _, _, tocVersion = GetBuildInfo()
        if tocVersion == 11402 then
            PlaySound(856)
        else
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
    end)

    return helpBtn
end
----------------------------------------------------------THE UI------------------------------------------------------------------------------------
local function ShowStaticPopup(message, title, isConfirmation, onAccept)
    StaticPopupDialogs["FILLRAID_GENERIC_POPUP"] = {
        text = message,
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            if onAccept then
                onAccept()
            end

            if isConfirmation then
                ReloadUI()
            end
        end,
        OnCancel = function()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 4,
    }

    if not isConfirmation then
        StaticPopupDialogs["FILLRAID_GENERIC_POPUP"].button1 = "OK"
        StaticPopupDialogs["FILLRAID_GENERIC_POPUP"].button2 = nil
    end

    StaticPopup_Show("FILLRAID_GENERIC_POPUP", title)
end





local function PerformFactoryReset()
    local preservedUserID = FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.userID or nil
    local preservedUserCount = FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.userCount or 0
    local preservedUniqueUsers = FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.uniqueUsers or {}

    FillRaidBotsSavedSettings = {
        userID = preservedUserID,
        userCount = preservedUserCount,
        uniqueUsers = preservedUniqueUsers,
    }

    FillRaidPresets = nil
    FillRaidSuppressBotMsg = nil
end

function ShowFactoryResetPopup()
    ShowStaticPopup(
        "Factory Reset will wipe all FillRaidBots saved settings, presets, and suppress messages.\n\n"
            .. "This cannot be undone. Accept?",
        "Factory Reset",
        true,
        function()
            PerformFactoryReset()
        end
    )
end





local tutorialLinkPopup
local tutorialLinkPopupTitle
local tutorialLinkPopupDescription
local tutorialLinkPopupEditBox
local tutorialLinkPopupCopyButton
local UpdateTutorialLinkButtons




local TUTORIAL_POPUP_IMAGE_SIZE = 200
local TUTORIAL_POPUP_PADDING = 16
local TUTORIAL_POPUP_GAP = 14
local TUTORIAL_POPUP_TOP_OFFSET = -42
local TUTORIAL_POPUP_RIGHT_WIDTH = 360
local TUTORIAL_POPUP_BOTTOM_PADDING = 56
local TUTORIAL_POPUP_MIN_HEIGHT = 300
local TUTORIAL_POPUP_ROW_HEIGHT = 38
local TUTORIAL_POPUP_ROW_BUTTON_WIDTH = 90
local TUTORIAL_POPUP_ROW_BUTTON_GAP = 8
local TUTORIAL_POPUP_CLOSE_BUTTON_HEIGHT = 22
local TUTORIAL_POPUP_CLOSE_BUTTON_BOTTOM = 14
local TUTORIAL_BOSS_IMAGE_BASE_PATH = "Interface\\AddOns\\FillRaidBots\\img\\bosses\\"
local TUTORIAL_BOSS_IMAGE_DEFAULT = TUTORIAL_BOSS_IMAGE_BASE_PATH .. "default"

local function GetTutorialPopupLayout()
    local imageSize = TUTORIAL_POPUP_IMAGE_SIZE
    local padding = TUTORIAL_POPUP_PADDING
    local gap = TUTORIAL_POPUP_GAP
    local rightWidth = TUTORIAL_POPUP_RIGHT_WIDTH
    local buttonWidth = TUTORIAL_POPUP_ROW_BUTTON_WIDTH
    local buttonGap = TUTORIAL_POPUP_ROW_BUTTON_GAP
    local popupWidth = padding + imageSize + gap + rightWidth + padding
    local textLeft = padding + imageSize + gap
    local editBoxWidth = rightWidth - buttonWidth - buttonGap

    if editBoxWidth < 120 then
        editBoxWidth = 120
    end

    return {
        imageSize = imageSize,
        padding = padding,
        gap = gap,
        rightWidth = rightWidth,
        buttonWidth = buttonWidth,
        buttonGap = buttonGap,
        popupWidth = popupWidth,
        textLeft = textLeft,
        textRight = -padding,
        imageLeft = padding,
        imageTop = TUTORIAL_POPUP_TOP_OFFSET,
        topY = TUTORIAL_POPUP_TOP_OFFSET,
        editBoxWidth = editBoxWidth,
        rowHeight = TUTORIAL_POPUP_ROW_HEIGHT,
        bottomPadding = TUTORIAL_POPUP_BOTTOM_PADDING,
        minHeight = TUTORIAL_POPUP_MIN_HEIGHT,
        closeButtonHeight = TUTORIAL_POPUP_CLOSE_BUTTON_HEIGHT,
        closeButtonBottom = TUTORIAL_POPUP_CLOSE_BUTTON_BOTTOM,
    }
end

local function SetTutorialBossImage(texture, preset)
    local texturePath = nil
    local imageName = nil

    if preset then
        imageName = preset.fullname or preset.label
    end

    if imageName and imageName ~= "" then
        texturePath = TUTORIAL_BOSS_IMAGE_BASE_PATH .. imageName
    else
        texturePath = TUTORIAL_BOSS_IMAGE_DEFAULT
    end

    texture:SetTexture(texturePath)
end




local function EnsureTutorialLinkPopup()
    local i
    local row
    local layout = GetTutorialPopupLayout()

    if tutorialLinkPopup then
        return
    end

    tutorialLinkPopup = CreateFrame("Frame", "FillRaidTutorialLinkPopup", UIParent, "BackdropTemplate")
    tutorialLinkPopup:SetWidth(layout.popupWidth)
    tutorialLinkPopup:SetHeight(layout.minHeight)
    tutorialLinkPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    tutorialLinkPopup:SetFrameStrata("DIALOG")
	tutorialLinkPopup:SetFrameLevel(30)
    tutorialLinkPopup:SetMovable(true)
    tutorialLinkPopup:EnableMouse(true)
    tutorialLinkPopup:RegisterForDrag("LeftButton")
	tutorialLinkPopup.background = tutorialLinkPopup:CreateTexture(nil, "BACKGROUND")
	tutorialLinkPopup.background:SetAllPoints(tutorialLinkPopup)
	tutorialLinkPopup.background:SetColorTexture(0, 0, 0, 1) 



	tutorialLinkPopup.border = CreateFrame("Frame", nil, tutorialLinkPopup, BackdropTemplateMixin and "BackdropTemplate")
	tutorialLinkPopup.border:SetPoint("TOPLEFT", -4, 4)
	tutorialLinkPopup.border:SetPoint("BOTTOMRIGHT", 4, -4)
	tutorialLinkPopup.border:SetFrameStrata(tutorialLinkPopup:GetFrameStrata())
	tutorialLinkPopup.border:SetFrameLevel(tutorialLinkPopup:GetFrameLevel() - 1)
	tutorialLinkPopup.border:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
	})
	tutorialLinkPopup.border:SetBackdropBorderColor(0.8, 0.8, 0.8)


	
	

	tutorialLinkPopup.header = tutorialLinkPopup:CreateTexture(nil, "OVERLAY")
	tutorialLinkPopup.header:SetWidth(220)
	tutorialLinkPopup.header:SetHeight(48)
	tutorialLinkPopup.header:SetPoint("TOP", tutorialLinkPopup, "TOP", 0, 12)
	tutorialLinkPopup.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	tutorialLinkPopup.header:SetVertexColor(0.2, 0.2, 0.2)

	tutorialLinkPopup.headerText = tutorialLinkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tutorialLinkPopup.headerText:SetPoint("TOP", tutorialLinkPopup.header, 0, -12)
	tutorialLinkPopup.headerText:SetText("Tutorial")

	
    tutorialLinkPopup:Hide()
    table.insert(UISpecialFrames, "FillRaidTutorialLinkPopup")

    tutorialLinkPopup:SetScript("OnDragStart", function()
        tutorialLinkPopup:StartMoving()
    end)

    tutorialLinkPopup:SetScript("OnDragStop", function()
        tutorialLinkPopup:StopMovingOrSizing()
    end)



	
    tutorialLinkPopupTitle = tutorialLinkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tutorialLinkPopupTitle:SetPoint("TOP", tutorialLinkPopup, "TOP", 0, -12)
    tutorialLinkPopupTitle:SetText("Tutorial Link")

    tutorialLinkPopup.bossImage = tutorialLinkPopup:CreateTexture(nil, "ARTWORK")
    tutorialLinkPopup.bossImage:SetWidth(layout.imageSize)
    tutorialLinkPopup.bossImage:SetHeight(layout.imageSize)
    tutorialLinkPopup.bossImage:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.imageLeft, layout.imageTop)
    tutorialLinkPopup.bossImage:SetTexCoord(0, 1, 0, 1)

    tutorialLinkPopupDescription = tutorialLinkPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tutorialLinkPopupDescription:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, layout.topY)
    tutorialLinkPopupDescription:SetPoint("TOPRIGHT", tutorialLinkPopup, "TOPRIGHT", layout.textRight, layout.topY)
    tutorialLinkPopupDescription:SetWidth(layout.rightWidth)
    tutorialLinkPopupDescription:SetJustifyH("LEFT")
    tutorialLinkPopupDescription:SetJustifyV("TOP")
    tutorialLinkPopupDescription:SetText("")

	tutorialLinkPopupAudience = tutorialLinkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tutorialLinkPopupAudience:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, layout.topY - 58)
	tutorialLinkPopupAudience:SetPoint("TOPRIGHT", tutorialLinkPopup, "TOPRIGHT", layout.textRight, layout.topY - 58)
	tutorialLinkPopupAudience:SetJustifyH("LEFT")
	tutorialLinkPopupAudience:SetJustifyV("TOP")
	tutorialLinkPopupAudience:SetText("")

    tutorialLinkPopupSingleLabel = tutorialLinkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tutorialLinkPopupSingleLabel:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, layout.topY - 82)
    tutorialLinkPopupSingleLabel:SetText("Copy URL:")

    tutorialLinkPopupEditBox = CreateFrame("EditBox", "FillRaidTutorialLinkEditBox", tutorialLinkPopup, "InputBoxTemplate")
    tutorialLinkPopupEditBox:SetWidth(layout.editBoxWidth)
    tutorialLinkPopupEditBox:SetHeight(20)
    tutorialLinkPopupEditBox:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, layout.topY - 100)
    tutorialLinkPopupEditBox:SetAutoFocus(false)
    tutorialLinkPopupEditBox:SetTextInsets(4, 4, 0, 0)
    tutorialLinkPopupEditBox:SetScript("OnEscapePressed", function()
        tutorialLinkPopupEditBox:ClearFocus()
        tutorialLinkPopup:Hide()
    end)

    tutorialLinkPopupCopyButton = CreateFrame("Button", nil, tutorialLinkPopup, "GameMenuButtonTemplate")
    tutorialLinkPopupCopyButton:SetWidth(layout.buttonWidth)
    tutorialLinkPopupCopyButton:SetHeight(22)
    tutorialLinkPopupCopyButton:SetPoint("LEFT", tutorialLinkPopupEditBox, "RIGHT", layout.buttonGap, 0)
    tutorialLinkPopupCopyButton:SetText("Select")
    tutorialLinkPopupCopyButton:SetScript("OnClick", function()
        tutorialLinkPopupEditBox:SetFocus()
        tutorialLinkPopupEditBox:HighlightText()
    end)

    tutorialLinkPopupRows = {}

    for i = 1, 5 do
        row = {}

        row.label = tutorialLinkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.label:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, layout.topY - 82 - ((i - 1) * layout.rowHeight))
        row.label:SetJustifyH("LEFT")
        row.label:SetText("Guide")
        row.label:Hide()

        row.editBox = CreateFrame("EditBox", "FillRaidTutorialLinkEditBox" .. i, tutorialLinkPopup, "InputBoxTemplate")
        row.editBox:SetWidth(layout.editBoxWidth)
        row.editBox:SetHeight(20)
        row.editBox:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        row.editBox:SetAutoFocus(false)
        row.editBox:SetTextInsets(4, 4, 0, 0)
        row.editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            tutorialLinkPopup:Hide()
        end)
        row.editBox:Hide()

        row.copyButton = CreateFrame("Button", nil, tutorialLinkPopup, "GameMenuButtonTemplate")
        row.copyButton:SetWidth(layout.buttonWidth)
        row.copyButton:SetHeight(20)
        row.copyButton:SetPoint("LEFT", row.editBox, "RIGHT", layout.buttonGap, 0)
        row.copyButton:SetText("Select")
        row.copyButton:Hide()

        tutorialLinkPopupRows[i] = row
    end

    local closeButton = CreateFrame("Button", nil, tutorialLinkPopup, "GameMenuButtonTemplate")
    closeButton:SetWidth(100)
    closeButton:SetHeight(22)
    closeButton:SetPoint("BOTTOM", tutorialLinkPopup, "BOTTOM", 0, 14)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        tutorialLinkPopupEditBox:ClearFocus()
        tutorialLinkPopup:Hide()
    end)
end

local function CopyTutorialUrl(url, editBox)
    local targetBox = editBox or tutorialLinkPopupEditBox
    targetBox:SetText(url or "")
    targetBox:SetFocus()
    targetBox:HighlightText()
end





local function GetTutorialLinksForPlayer(linkInfo)
    local factionGroup
    local factionKey
    local vipKey
    local variant
    local fallbackVariant
    local fallbackFaction
    local factionText
    local vipText

    local RED = "|cffff4040"
    local GRAY = "|cffaaaaaa"
    local RESET = "|r"

    if not linkInfo then
        return nil, nil
    end

    if linkInfo.url then
        return {
            {
                label = "Tutorial",
                url = linkInfo.url,
            }
        }, "General"
    end

    factionGroup = UnitFactionGroup("player")
    factionKey = (factionGroup == "Horde") and "horde" or "alliance"
    vipKey = (FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.isVIP) and "vip" or "nonvip"

    factionText = (factionKey == "horde") and "Horde" or "Alliance"
    vipText = (vipKey == "vip") and "VIP" or "nonVIP"

    local requestedText = factionText .. " " .. vipText

    
    
    
    variant = linkInfo[factionKey]
    if variant and variant[vipKey] and table.getn(variant[vipKey]) > 0 then
        return variant[vipKey], requestedText
    end

    
    
    
    if variant then
        fallbackVariant = (vipKey == "vip") and variant.nonvip or variant.vip
        if fallbackVariant and table.getn(fallbackVariant) > 0 then
            local fallbackVipText = (vipKey == "vip") and "nonVIP" or "VIP"
            return fallbackVariant,
                RED .. "No " .. requestedText .. " tutorial found." .. RESET ..
                "\n" ..
                GRAY .. "Using fallback:" .. RESET .. " " .. factionText .. " " .. fallbackVipText
        end
    end

    
    
    
    fallbackFaction = (factionKey == "horde") and "alliance" or "horde"
    variant = linkInfo[fallbackFaction]
    local fallbackFactionText = (fallbackFaction == "horde") and "Horde" or "Alliance"

    if variant and variant[vipKey] and table.getn(variant[vipKey]) > 0 then
        return variant[vipKey],
            RED .. "No " .. requestedText .. " tutorial found." .. RESET ..
            "\n" ..
            GRAY .. "Using fallback:" .. RESET .. " " .. fallbackFactionText .. " " .. vipText
    end

    
    
    
    if variant then
        fallbackVariant = (vipKey == "vip") and variant.nonvip or variant.vip
        if fallbackVariant and table.getn(fallbackVariant) > 0 then
            local fallbackVipText = (vipKey == "vip") and "nonVIP" or "VIP"
            return fallbackVariant,
                RED .. "No " .. requestedText .. " tutorial found." .. RESET ..
                "\n" ..
                GRAY .. "Using fallback:" .. RESET .. " " .. fallbackFactionText .. " " .. fallbackVipText
        end
    end

    
    
    
    if linkInfo.alliance then
        if linkInfo.alliance.nonvip and table.getn(linkInfo.alliance.nonvip) > 0 then
            return linkInfo.alliance.nonvip,
                RED .. "No " .. requestedText .. " tutorial found." .. RESET ..
                "\n" ..
                GRAY .. "Using fallback:" .. RESET .. " Alliance nonVIP"
        end
        if linkInfo.alliance.vip and table.getn(linkInfo.alliance.vip) > 0 then
            return linkInfo.alliance.vip,
                RED .. "No " .. requestedText .. " tutorial found." .. RESET ..
                "\n" ..
                GRAY .. "Using fallback:" .. RESET .. " Alliance VIP"
        end
    end

    if linkInfo.horde then
        if linkInfo.horde.nonvip and table.getn(linkInfo.horde.nonvip) > 0 then
            return linkInfo.horde.nonvip,
                RED .. "No " .. requestedText .. " tutorial found." .. RESET ..
                "\n" ..
                GRAY .. "Using fallback:" .. RESET .. " Horde nonVIP"
        end
        if linkInfo.horde.vip and table.getn(linkInfo.horde.vip) > 0 then
            return linkInfo.horde.vip,
                RED .. "No " .. requestedText .. " tutorial found." .. RESET ..
                "\n" ..
                GRAY .. "Using fallback:" .. RESET .. " Horde VIP"
        end
    end

    return nil, nil
end





local function ShowTutorialLinkPopup(preset, linkInfo)
    local availableLinks
    local audienceText
    local rowIndex
    local row
    local guideInfo
    local visibleRowCount
    local descriptionText
    local descriptionHeight
    local audienceHeight
    local contentStartY
    local popupHeight
    local maxRows
    local layout
    local imageBottomY
    local contentBottomY
    local guideSectionTopY
	
    EnsureTutorialLinkPopup()

    layout = GetTutorialPopupLayout()
    tutorialLinkPopup:SetWidth(layout.popupWidth)

    tutorialLinkPopupTitle:SetText((preset and (preset.fullname or preset.label)) or "Tutorial")
    tutorialLinkPopup.bossImage:SetWidth(layout.imageSize)
    tutorialLinkPopup.bossImage:SetHeight(layout.imageSize)
    tutorialLinkPopup.bossImage:ClearAllPoints()
    tutorialLinkPopup.bossImage:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.imageLeft, layout.imageTop)
    SetTutorialBossImage(tutorialLinkPopup.bossImage, preset)

    availableLinks, audienceText = GetTutorialLinksForPlayer(linkInfo)

    descriptionText = (linkInfo and linkInfo.description) or ""
    tutorialLinkPopupDescription:SetText(descriptionText)
    tutorialLinkPopupDescription:SetWidth(layout.rightWidth)
    tutorialLinkPopupDescription:SetJustifyH("LEFT")
    tutorialLinkPopupDescription:SetJustifyV("TOP")
    tutorialLinkPopupDescription:ClearAllPoints()
    tutorialLinkPopupDescription:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, layout.topY)
    tutorialLinkPopupDescription:SetPoint("TOPRIGHT", tutorialLinkPopup, "TOPRIGHT", layout.textRight, layout.topY)

    tutorialLinkPopupAudience:SetText(audienceText and ("" .. audienceText) or "Showing: No matching guide")

    tutorialLinkPopupSingleLabel:Hide()
    tutorialLinkPopupEditBox:Hide()
    tutorialLinkPopupCopyButton:Hide()
    tutorialLinkPopupEditBox:SetText("")
    tutorialLinkPopupEditBox:ClearFocus()

    for rowIndex = 1, table.getn(tutorialLinkPopupRows) do
        row = tutorialLinkPopupRows[rowIndex]
        row.label:Hide()
        row.editBox:Hide()
        row.copyButton:Hide()
        row.label:SetText("")
        row.editBox:SetText("")
        row.editBox:ClearFocus()
    end

    descriptionHeight = tutorialLinkPopupDescription:GetStringHeight()
    if not descriptionHeight or descriptionHeight < 14 then
        descriptionHeight = 14
    end

    tutorialLinkPopupAudience:SetWidth(layout.rightWidth)
    tutorialLinkPopupAudience:ClearAllPoints()
    tutorialLinkPopupAudience:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, layout.topY - descriptionHeight - 12)
    tutorialLinkPopupAudience:SetPoint("TOPRIGHT", tutorialLinkPopup, "TOPRIGHT", layout.textRight, layout.topY - descriptionHeight - 12)

    audienceHeight = tutorialLinkPopupAudience:GetStringHeight()
    if not audienceHeight or audienceHeight < 14 then
        audienceHeight = 14
    end

    contentStartY = layout.topY - descriptionHeight - 12 - audienceHeight - 10
    guideSectionTopY = contentStartY

    tutorialLinkPopupSingleLabel:ClearAllPoints()
    tutorialLinkPopupSingleLabel:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, guideSectionTopY)

    tutorialLinkPopupEditBox:SetWidth(layout.editBoxWidth)
    tutorialLinkPopupEditBox:ClearAllPoints()
    tutorialLinkPopupEditBox:SetPoint("TOPLEFT", tutorialLinkPopupSingleLabel, "BOTTOMLEFT", 0, -4)

    tutorialLinkPopupCopyButton:SetWidth(layout.buttonWidth)
    tutorialLinkPopupCopyButton:ClearAllPoints()
    tutorialLinkPopupCopyButton:SetPoint("LEFT", tutorialLinkPopupEditBox, "RIGHT", layout.buttonGap, 0)

    maxRows = table.getn(tutorialLinkPopupRows)
    visibleRowCount = 0

    if availableLinks and table.getn(availableLinks) > 0 then
        visibleRowCount = math.min(table.getn(availableLinks), maxRows)

        for rowIndex = 1, visibleRowCount do
            row = tutorialLinkPopupRows[rowIndex]
            guideInfo = availableLinks[rowIndex]

            if not row or not guideInfo then
                break
            end

            row.label:ClearAllPoints()
            row.label:SetPoint("TOPLEFT", tutorialLinkPopup, "TOPLEFT", layout.textLeft, guideSectionTopY - ((rowIndex - 1) * layout.rowHeight))
            row.label:SetText("Tutorial: " .. (guideInfo.label or ("Guide " .. rowIndex)))

            row.editBox:SetWidth(layout.editBoxWidth)
            row.editBox:ClearAllPoints()
            row.editBox:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
            row.editBox:SetText(guideInfo.url or "")
            row.editBox:SetCursorPosition(0)

            row.copyButton:SetWidth(layout.buttonWidth)
            row.copyButton:ClearAllPoints()
            row.copyButton:SetPoint("LEFT", row.editBox, "RIGHT", layout.buttonGap, 0)

            row.label:Show()
            row.editBox:Show()
            row.copyButton:Show()

            do
                local targetEditBox = row.editBox
                row.copyButton:SetScript("OnClick", function()
                    CopyTutorialUrl(targetEditBox:GetText(), targetEditBox)
                end)
            end
        end
    end

    imageBottomY = math.abs(layout.topY) + layout.imageSize
    if visibleRowCount > 0 then
        contentBottomY = math.abs(guideSectionTopY) + (visibleRowCount * layout.rowHeight)
    else
        contentBottomY = math.abs(guideSectionTopY) + 8
    end

    popupHeight = math.max(imageBottomY, contentBottomY) + layout.bottomPadding
    if popupHeight < layout.minHeight then
        popupHeight = layout.minHeight
    end
    tutorialLinkPopup:SetHeight(popupHeight)

    tutorialLinkPopup:Show()
end




local function GetTutorialLinkInfoForPreset(preset)
    local info

    if not preset or not FillRaidTutorialLinks then
        return nil
    end

    if preset.fullname and FillRaidTutorialLinks[preset.fullname] then
        return FillRaidTutorialLinks[preset.fullname]
    end

    if preset.label and FillRaidTutorialLinks[preset.label] then
        return FillRaidTutorialLinks[preset.label]
    end

    if preset.bosses then
        for _, bossName in ipairs(preset.bosses) do
            info = FillRaidTutorialLinks[bossName]
            if info then
                return info
            end
        end
    end

    return nil
end





local savedPositions = {}

function CreateFillRaidUI()
    
    FillRaidFrame = CreateFrame("Frame", "FillRaidFrame", UIParent)
    FillRaidFrame:SetWidth(310)
    FillRaidFrame:SetHeight(450)
    FillRaidFrame:SetPoint("CENTER", UIParent, "CENTER")
    FillRaidFrame:SetMovable(true)
    FillRaidFrame:EnableMouse(true)
    FillRaidFrame:RegisterForDrag("LeftButton")
    FillRaidFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    FillRaidFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    FillRaidFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not self.isMoving then
            self:StartMoving()
            self.isMoving = true
        end
    end)

    FillRaidFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
        end
    end)
	table.insert(UISpecialFrames, "FillRaidFrame")
    
	
	FillRaidFrame.background = FillRaidFrame:CreateTexture(nil, "BACKGROUND")
	FillRaidFrame.background:SetAllPoints(FillRaidFrame)
	FillRaidFrame.background:SetColorTexture(0, 0, 0, 0.8) 

	
	FillRaidFrame.border = CreateFrame("Frame", nil, FillRaidFrame, BackdropTemplateMixin and "BackdropTemplate")
	FillRaidFrame.border:SetPoint("TOPLEFT", -4, 4)
	FillRaidFrame.border:SetPoint("BOTTOMRIGHT", 4, -4)
	FillRaidFrame.border:SetFrameLevel(0)
	FillRaidFrame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
	})
	FillRaidFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) 

    FillRaidBotsVersionText = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    FillRaidBotsVersionText:SetPoint("BOTTOMRIGHT", FillRaidFrame, "BOTTOMRIGHT", -10, 8)
	function newversion(newVersionDetected)
		if newVersionDetected then
			FillRaidBotsVersionText:SetText("You are running:" .. versionNumber .. " - Update available: " .. newVersionDetected)
		else
			FillRaidBotsVersionText:SetText("Version: " .. versionNumber)
		end
	end

    FillRaidBotsVersionClickButton = CreateFrame("Button", "FillRaidBotsVersionClickButton", FillRaidFrame)
    FillRaidBotsVersionClickButton:SetPoint("TOPLEFT", FillRaidBotsVersionText, "TOPLEFT", -4, 2)
    FillRaidBotsVersionClickButton:SetPoint("BOTTOMRIGHT", FillRaidBotsVersionText, "BOTTOMRIGHT", 4, -2)
    FillRaidBotsVersionClickButton:EnableMouse(true)
    FillRaidBotsVersionClickButton:RegisterForClicks("LeftButtonUp")
    FillRaidBotsVersionClickButton:SetScript("OnClick", function()
        ShowUpdateVersionPopup(true)
    end)
    FillRaidBotsVersionClickButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Click to show update info.")
        GameTooltip:Show()
    end)
    FillRaidBotsVersionClickButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

	
	FillRaidFrame.header = FillRaidFrame:CreateTexture(nil, 'OVERLAY') 
	FillRaidFrame.header:SetWidth(250)
	FillRaidFrame.header:SetHeight(64)
	FillRaidFrame.header:SetPoint('TOP', FillRaidFrame, 0, 18)
	FillRaidFrame.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	FillRaidFrame.header:SetVertexColor(0.2, 0.2, 0.2)

	
	FillRaidFrame.headerText = FillRaidFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal') 
	FillRaidFrame.headerText:SetPoint('TOP', FillRaidFrame.header, 0, -14)
	FillRaidFrame.headerText:SetText('Fill Raid')
	



    local yOffset = -30
    local xOffset = 10
    local totalBots = 0 
	
	
	
	local raid20Zones = {
		["Zul'Gurub"] = true,
		["Ruins of Ahn'Qiraj"] = true,
	}

	local raid15Zones = {
	    ["Blackrock Spire"] = true,
		["Lower Blackrock Spire"] = true,
		["Upper Blackrock Spire"] = true,
	}

	local dungeonZones = {
		["Ragefire Chasm"] = true,
		["Wailing Caverns"] = true,
		["The Deadmines"] = true,
		["Shadowfang Keep"] = true,
		["Blackfathom Deeps"] = true,
		["The Stockade"] = true,
		["Gnomeregan"] = true,
		["Razorfen Kraul"] = true,
		["Scarlet Monastery"] = true,
		["Razorfen Downs"] = true,
		["Uldaman"] = true,
		["Zul'Farrak"] = true,
		["Maraudon"] = true,
		["The Temple of Atal'Hakkar"] = true,
		["Blackrock Depths"] = true,
		["Dire Maul"] = true,
		["Scholomance"] = true,
		["Stratholme"] = true,
	}

	
	local raid40Zones = {
		["Molten Core"] = true,
		["Blackwing Lair"] = true,
		["Ahn'Qiraj"] = true,
		["Naxxramas"] = true,
		["Onyxia's Lair"] = true,
		
	}

	
	local worldBossSubZones = {
		["The Tainted Scar"] = true,        -- Blasted Lands (Lord Kazzak)
		["Dream Bough"] = true,         -- Feralas (Emeriss)
		["Bough Shadow"] = true,        -- Ashenvale (Ysondre)
		["Seradane"] = true,            -- Hinterlands (Lethon)
		["Twilight Grove"] = true,      -- Duskwood (Taerar)
		["The Crystal Vale"] = true,    -- Silithus (Prince Thunderaan)
	}

	
	local lastZoneDebugText = nil

	local function GetMaxBotsForCurrentZone()
		local zone = GetRealZoneText()
		local subZone = GetSubZoneText()
		local maxBots
		local debugText

		if raid20Zones[zone] then
			maxBots = 19
		elseif raid15Zones[zone] then
			maxBots = 14
		elseif dungeonZones[zone] then
			maxBots = 9
		elseif raid40Zones[zone] then
			maxBots = 39
		elseif worldBossSubZones[subZone] then
			maxBots = 39
		elseif zone == "Azshara" and (not subZone or subZone == "") then
			maxBots = 39
		else
			maxBots = 4
		end

		debugText = "Zone: " .. (zone or "nil") .. " | SubZone: " .. (subZone or "nil") .. " | Max bots: " .. maxBots
		if debugText ~= lastZoneDebugText then
			lastZoneDebugText = debugText
			QueueDebugMessage(debugText, "debugzones")
		end

		return maxBots
	end

	local function GetOtherRealPlayerCount()
		local count = 0
		local playerName = UnitName("player")

		if IsInRaid() then
			for i = 1, GetNumGroupMembers() do
				local name = GetRaidRosterInfo(i)
				if name and name ~= playerName and not IsBotName(name) then
					count = count + 1
				end
			end
		else
			for i = 1, GetNumGroupMembers() do
				local name = UnitName("party" .. i)
				if name and not IsBotName(name) then
					count = count + 1
				end
			end
		end

		return count
	end	

    
    local totalBotLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    totalBotLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    totalBotLabel:SetText("Total Bots: 0")
    yOffset = yOffset - 25

    
    local spotsLeftLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    spotsLeftLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
	spotsLeftLabel:SetText("Spots left: " .. math.max(0, GetMaxBotsForCurrentZone() - GetOtherRealPlayerCount())) 
    yOffset = yOffset - 25

    
    local roleCountsLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    roleCountsLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    roleCountsLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    roleCountsLabel:SetText("Tanks: 0 Healers: 0 Melee DPS: 0 Ranged DPS: 0")
    yOffset = yOffset - 30


	
	
	local function UpdateSpotsLeft()
		local maxBots = GetMaxBotsForCurrentZone()
		local otherRealPlayers = GetOtherRealPlayerCount()
		local allowedBots = math.max(0, maxBots - otherRealPlayers)
		local botsLeftToAdd = math.max(0, allowedBots - totalBots)

		if totalBots <= allowedBots then
			totalBotLabel:SetText("Total Bots: " .. totalBots)
			spotsLeftLabel:SetText("Spots left: " .. botsLeftToAdd)
		else
			totalBotLabel:SetText("Too many: |cffff0000" .. totalBots .. "|r")
			spotsLeftLabel:SetText("Spots left: 0")
		end
	end
    
    local columns = 2
    local rowsPerColumn = 14
    local columnWidth = 150
    local rowHeight = 0
	local groupGap = 6

    
    local roleIcons = {
        ["tank"] = "Interface\\Icons\\Ability_Defend",
        ["meleedps"] = "Interface\\Icons\\Ability_DualWield",
        ["rangedps"] = "Interface\\Icons\\Ability_Marksmanship",
        ["healer"] = "Interface\\Icons\\Spell_Holy_Heal",
    }


    
    local roleCounts = {
        ["tank"] = 0,
        ["healer"] = 0,
        ["meleedps"] = 0,
        ["rangedps"] = 0,
    }

    
    local inputBoxes = {}

    
    
    
    local currentLoadedPreset = nil

    local function GetPresetValues(preset)
        if not preset then
            return nil
        end

        if FillRaidBotsSavedSettings
            and FillRaidBotsSavedSettings.useVipPresets
            and preset.vipValues then
            return preset.vipValues
        end

        return preset.values
    end

    function ReapplyCurrentPreset()
        local selectedValues
        local classRole
        local inputBox
        local value
        local onTextChanged

        if not currentLoadedPreset then
            return
        end

        for classRole, inputBox in pairs(inputBoxes) do
            if inputBox then
                inputBox:SetNumber(0)
                onTextChanged = inputBox:GetScript("OnTextChanged")
                if onTextChanged then
                    onTextChanged(inputBox)
                end
            end
        end

        selectedValues = GetPresetValues(currentLoadedPreset)
        if not selectedValues then
            return
        end

        for classRole, value in pairs(selectedValues) do
            inputBox = inputBoxes[classRole]
            if inputBox then
                inputBox:SetNumber(value)
                onTextChanged = inputBox:GetScript("OnTextChanged")
                if onTextChanged then
                    onTextChanged(inputBox)
                end
            end
        end

        if currentPresetLabel and currentLoadedPreset.label then
            currentPresetLabel:SetText("Preset: " .. currentLoadedPreset.label)
            currentPresetName = currentLoadedPreset.label
        end
    end

    
    local function SplitClassRole(classRole)
        local spaceIndex = string.find(classRole, " ")
        if spaceIndex then
            local class = string.sub(classRole, 1, spaceIndex - 1)
            local role = string.sub(classRole, spaceIndex + 1)
            return class, role
        end
        return classRole, nil
    end

	local currentIndex = 0 


        local currentColumn = 0
        local currentRowInColumn = 0
        local classGroupYOffset = yOffset 
        local lastClass = nil

        for i, classRole in ipairs(classes) do
            local class, role = SplitClassRole(classRole)
            local faction = UnitFactionGroup("player")

            if not ((faction == "Alliance" and class == "shaman") or (faction == "Horde" and class == "paladin")) then

               
                if lastClass ~= class then
                   
                    if currentRowInColumn > 0 then
                        classGroupYOffset = classGroupYOffset - groupGap
                        currentRowInColumn = currentRowInColumn + 1
                    end

                   
                    if currentRowInColumn >= rowsPerColumn then
                        currentColumn = currentColumn + 1
                        currentRowInColumn = 0
                        classGroupYOffset = yOffset 
                    end

                    local classXOffset = xOffset + (currentColumn * columnWidth)

                   

					CreateSeparatorLine(FillRaidFrame, classXOffset, classGroupYOffset - 12, columnWidth - 10)


                   
                    local classHeader = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    classHeader:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", classXOffset, classGroupYOffset)
                    classHeader:SetText(strupper(string.sub(class, 1, 1)) .. string.sub(class, 2))

                   
                    classGroupYOffset = classGroupYOffset - 18
                    currentRowInColumn = currentRowInColumn + 1

                    lastClass = class
                end

               
                local classXOffset = xOffset + (currentColumn * columnWidth)

               
                local roleIcon = FillRaidFrame:CreateTexture(nil, "OVERLAY")
                roleIcon:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", classXOffset, classGroupYOffset + 2)
                roleIcon:SetWidth(12)
                roleIcon:SetHeight(12)
                roleIcon:SetTexture(roleIcons[role] or "Interface\\Icons\\INV_Misc_QuestionMark")

               
                local classLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                classLabel:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", classXOffset + 16, classGroupYOffset + 2)
                classLabel:SetText(class .. " " .. (role or ""))

               
                local classInput = CreateFrame("EditBox", classRole .. "Input", FillRaidFrame, "InputBoxTemplate")
                classInput:SetWidth(25)
                classInput:SetHeight(14)
                classInput:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", classXOffset + 110, classGroupYOffset + 1)
                classInput:SetNumeric(true)
                classInput:SetNumber(0)
                classInput:SetAutoFocus(false)
                classInput:SetScript("OnEscapePressed", function()
                    openFillRaid()
                end)

                inputBoxes[classRole] = classInput

                local className = classRole

				
				
				
				classInput:SetScript("OnTextChanged", function()
					local newValue = tonumber(classInput:GetText()) or 0
					classCounts[className] = newValue

					totalBots = 0
					roleCounts["tank"] = 0
					roleCounts["healer"] = 0
					roleCounts["meleedps"] = 0
					roleCounts["rangedps"] = 0

								 
										  
					for role, _ in pairs(roleCounts) do
						for clsRole, count in pairs(classCounts) do
							if string.find(clsRole, role) then
								roleCounts[role] = roleCounts[role] + count
							end
						end
					end

													   
					for _, count in pairs(classCounts) do
						totalBots = totalBots + count
																		   
							   
					end
					   

					roleCountsLabel:SetText(string.format(
						"Tanks: %d Healers: %d Melee DPS: %d Ranged DPS: %d",
						roleCounts["tank"], roleCounts["healer"],
						roleCounts["meleedps"], roleCounts["rangedps"]
					))

					UpdateSpotsLeft()
				end)

               
                classGroupYOffset = classGroupYOffset - 18
                currentRowInColumn = currentRowInColumn + 1
            end
        end




	  
	  local fillRaidButton = CreateFrame("Button", nil, FillRaidFrame, "GameMenuButtonTemplate")
	  fillRaidButton:SetPoint("BOTTOM", FillRaidFrame, "BOTTOM", -60, 20)
	  fillRaidButton:SetWidth(120)
	  fillRaidButton:SetHeight(40)
	  fillRaidButton:SetText("Fill Raid")

	  fillRaidButton:SetScript("OnClick", function()
		  FillRaid()
		  ReplaceDeadBot = {}
		  resetData()
		  UpdateReFillButtonVisibility()		  
		  FillRaidFrame:Hide()  
	  end)


	  
	  local closeButton = CreateFrame("Button", nil, FillRaidFrame, "GameMenuButtonTemplate")
	  closeButton:SetPoint("BOTTOM", FillRaidFrame, "BOTTOM", 60, 20)
	  closeButton:SetWidth(120)
	  closeButton:SetHeight(40)
	  closeButton:SetText("Close")
	  closeButton:SetScript("OnClick", function()
		  FillRaidFrame:Hide()
		  fillRaidFrameManualClose = true 
	  end)

	
	
	
	if not FillRaidBotsZoneFrame then
	    FillRaidBotsZoneFrame = CreateFrame("Frame")
	    FillRaidBotsZoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	    FillRaidBotsZoneFrame:RegisterEvent("ZONE_CHANGED")
	    FillRaidBotsZoneFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
	
	    FillRaidBotsZoneFrame:SetScript("OnEvent", function()
	        UpdateSpotsLeft()
	    end)
	end
	
	local UISettingsFrame = CreateFrame("Frame", "UISettingsFrame", UIParent)
	UISettingsFrame:SetWidth(200)
	UISettingsFrame:SetHeight(380)
	UISettingsFrame:SetPoint("LEFT", FillRaidFrame, "RIGHT", 10, 0)

	
	UISettingsFrame.background = UISettingsFrame:CreateTexture(nil, "BACKGROUND")
	UISettingsFrame.background:SetAllPoints(UISettingsFrame)
	UISettingsFrame.background:SetColorTexture(0, 0, 0, 1) 

	
	UISettingsFrame.border = CreateFrame("Frame", nil, UISettingsFrame, BackdropTemplateMixin and "BackdropTemplate")
	UISettingsFrame.border:SetPoint("TOPLEFT", -4, 4)
	UISettingsFrame.border:SetPoint("BOTTOMRIGHT", 4, -4)
	UISettingsFrame.border:SetFrameStrata(UISettingsFrame:GetFrameStrata())
	UISettingsFrame.border:SetFrameLevel(UISettingsFrame:GetFrameLevel() - 1)	
	UISettingsFrame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		edgeSize = 16,
	})
	UISettingsFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) 

	UISettingsFrame:SetFrameStrata("DIALOG")
	UISettingsFrame:SetFrameLevel(10)

	
	

	UISettingsFrame.header = UISettingsFrame:CreateTexture(nil, "OVERLAY")
	UISettingsFrame.header:SetWidth(250)
	UISettingsFrame.header:SetHeight(64)
	UISettingsFrame.header:SetPoint("TOP", UISettingsFrame, "TOP", 0, 18)
	UISettingsFrame.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	UISettingsFrame.header:SetVertexColor(0.2, 0.2, 0.2)

	UISettingsFrame.headerText = UISettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	UISettingsFrame.headerText:SetPoint("TOP", UISettingsFrame.header, 0, -14)
	UISettingsFrame.headerText:SetText("Settings")	
	
	UISettingsFrame:Show()
	table.insert(UISpecialFrames, "UISettingsFrame")
	local openSettingsButton = CreateFrame("Button", "OpenSettingsButton", FillRaidFrame, "GameMenuButtonTemplate")
	openSettingsButton:SetWidth(80)
	openSettingsButton:SetHeight(20)
	openSettingsButton:SetText("Settings")
	openSettingsButton:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", 10, -10) 
	openSettingsButton:SetScript("OnClick", function()
		if UISettingsFrame:IsShown() then
			UISettingsFrame:Hide()
			ClickBlockerFrame:Hide() 
		else
			UISettingsFrame:Show()
			ClickBlockerFrame:Show()
		end
	end)

    local saveButton = CreateFrame("Button", "SaveButton", FillRaidFrame, "GameMenuButtonTemplate")
    saveButton:SetText("Save")
	saveButton:SetWidth(80)
	saveButton:SetHeight(20)
	saveButton:Hide()
	saveButton:SetPoint("BOTTOM", FillRaidFrame, "BOTTOM", -90, 60)
   
    saveButton:SetScript("OnClick", function()
       
        SavePresetValues() 
    end)

   
    saveButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(saveButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to save current preset values")
        GameTooltip:Show()
    end)

    saveButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

local KEY_ESCAPE = 27
local KEY_ENTER = 13


local PresetPopup = CreateFrame("Frame", "PresetPopupFrame", UIParent, "BackdropTemplate")
PresetPopup:SetSize(300, 250)
PresetPopup:SetPoint("CENTER", UIParent, "CENTER")
PresetPopup:SetFrameStrata("DIALOG")
PresetPopup:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
PresetPopup:SetBackdropColor(0, 0, 0, 1)
PresetPopup:Hide()
PresetPopup:SetMovable(true)
PresetPopup:EnableMouse(true)
PresetPopup:RegisterForDrag("LeftButton")


PresetPopup:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)


PresetPopup:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

local function CreateButton(parent, width, height, point, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetPoint(point, parent, "CENTER")
    
   
    local normalTexture = button:CreateTexture()
    normalTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
    normalTexture:SetTexCoord(0, 0.625, 0, 0.6875)
    normalTexture:SetAllPoints()
    button:SetNormalTexture(normalTexture)
    
   
    local pushedTexture = button:CreateTexture()
    pushedTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
    pushedTexture:SetTexCoord(0, 0.625, 0, 0.6875)
    pushedTexture:SetAllPoints()
    button:SetPushedTexture(pushedTexture)

   
    local highlightTexture = button:CreateTexture()
    highlightTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    highlightTexture:SetTexCoord(0, 0.625, 0, 0.6875)
    highlightTexture:SetAllPoints()
    button:SetHighlightTexture(highlightTexture)
    
   
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("CENTER", button, "CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(1, 1, 1)
    
    return button
end


local function CreateInputBox(parent, point, autoFocus)
    local inputBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    inputBox:SetSize(180, 20)
    inputBox:SetPoint("LEFT", parent, "LEFT", 20, 0)
    inputBox:SetAutoFocus(autoFocus)
    inputBox:SetFontObject(GameFontNormal)
    inputBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    inputBox:SetBackdropColor(0, 0, 0, 0.5)
    inputBox:SetBackdropBorderColor(0.6, 0.6, 0.6)
    inputBox:SetTextInsets(6, 6, 3, 3)

    return inputBox
end



local popupLabel = PresetPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
popupLabel:SetPoint("TOP", PresetPopup, "TOP", 0, -10)


local helpButton = CreateHelpButton(PresetPopup, popupLabel, 10, 0, "Enter name:\n  - Preset name to save the current setup\n\nBoss names:\n  - Name of the boss or mob for the Ctrl+Alt+Click function\n\nZone button:\n  - Adds your current zone to the boss list\n\nTip:\n  - Hold Alt and click a mob to add it to the list.", "Preset Help")


local presetInput = CreateInputBox(PresetPopup, "TOP", true)
presetInput:SetPoint("TOP", popupLabel, "BOTTOM", 0, -5)


local bossInput = CreateInputBox(PresetPopup, "TOP", false)
bossInput:SetWidth(120)
bossInput:SetPoint("TOP", presetInput, "BOTTOM", -30, -10)

local bossInputLabel = PresetPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bossInputLabel:SetPoint("TOP", bossInput, "TOP", 30, 12)
bossInputLabel:SetText("Boss Names or Zone: (optional)")


local addBossButton = CreateButton(PresetPopup, 60, 20, "LEFT", "Add")
addBossButton:SetPoint("LEFT", bossInput, "RIGHT", 5, 0)

local addZoneButton = CreateButton(PresetPopup, 60, 20, "LEFT", "Zone") 
addZoneButton:SetPoint("LEFT", addBossButton, "RIGHT", 5, 0)


local bossListScrollFrame = CreateFrame("ScrollFrame", "BossListScrollFrame", PresetPopup, "UIPanelScrollFrameTemplate")
bossListScrollFrame:SetPoint("TOPLEFT", 10, -80)
bossListScrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

local bossListScrollChild = CreateFrame("Frame", "BossListScrollChild", bossListScrollFrame)
bossListScrollChild:SetWidth(200)
bossListScrollChild:SetHeight(1)
bossListScrollFrame:SetScrollChild(bossListScrollChild)

local currentBosses = {}
local bossListItems = {}


local function tableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end


local AddBossDirectly
local AddCurrentZoneToBosses

function RefreshBossList()
    for i = 1, tableSize(bossListItems) do
        local item = bossListItems[i]
        if item and item.frame then
            item.frame:Hide()
            item.frame:SetParent(nil)
        end
    end
    bossListItems = {}

    local itemHeight = 28
    local spacing = 5
    local totalHeight = 0
    local width = bossListScrollFrame:GetWidth() - 20

    local index = 1
    for i, bossName in pairs(currentBosses) do
        local itemFrame = CreateFrame("Frame", nil, bossListScrollChild)
        itemFrame:SetWidth(width)
        itemFrame:SetHeight(itemHeight)
        itemFrame:SetPoint("TOPLEFT", 0, -((index - 1) * (itemHeight + spacing)))

        local label = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", itemFrame, "LEFT", 5, 0)
        label:SetText("- " .. bossName)
        label:SetJustifyH("LEFT")

        local removeButton = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        removeButton:SetWidth(25)
        removeButton:SetHeight(25)
        removeButton:SetText("X")
        removeButton:SetPoint("RIGHT", itemFrame, "RIGHT", -5, 0)
        removeButton:SetScript("OnClick", function()
            tremove(currentBosses, i)
            RefreshBossList()
        end)

        itemFrame:EnableMouse(true)
        itemFrame:SetScript("OnMouseDown", function(self, button)
            if IsAltKeyDown() then
                AddBossDirectly(bossName)
            end
        end)

        itemFrame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(itemFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText("ALT-click to add again")
            GameTooltip:Show()
        end)
        itemFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        bossListItems[index] = {
            frame = itemFrame,
            label = label,
            button = removeButton
        }

        totalHeight = totalHeight + itemHeight + spacing
        index = index + 1
    end

    local visibleHeight = bossListScrollFrame:GetHeight()
    bossListScrollChild:SetHeight(math.max(totalHeight, visibleHeight + 1))
    bossListScrollFrame:UpdateScrollChildRect()
    bossListScrollFrame:SetVerticalScroll(0)
end

AddBossDirectly = function(bossName)
    if not PresetPopup:IsVisible() then return end

    bossName = strtrim(bossName)
    if bossName == "" then return end

    local lowerName = strlower(bossName)
    for _, existing in pairs(currentBosses) do
        if strlower(existing) == lowerName then
            ShowStaticPopup(bossName .. " already in list!", "ERROR")
            return
        end
    end

    tinsert(currentBosses, bossName)
    RefreshBossList()
    DEFAULT_CHAT_FRAME:AddMessage(bossName .. " added to list!")
end

AddCurrentZoneToBosses = function()
    if not PresetPopup:IsVisible() then return end

    local zone = GetRealZoneText()
    if not zone or zone == "" then return end

    local lowerZone = strlower(zone)
    for _, existing in pairs(currentBosses) do
        if strlower(existing) == lowerZone then
            ShowStaticPopup(zone .. " already in list!", "ERROR")
            return
        end
    end

    tinsert(currentBosses, zone)
    RefreshBossList()
    DEFAULT_CHAT_FRAME:AddMessage(zone .. " added to list!")
end

addBossButton:SetScript("OnClick", function()
    local name = strtrim(bossInput:GetText())
    if name ~= "" then
        AddBossDirectly(name)
        bossInput:SetText("")
    end
end)

addZoneButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Add current zone")
    GameTooltip:Show()
end)

addZoneButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
addZoneButton:SetScript("OnClick", function()
    AddCurrentZoneToBosses()
end)

local targetScanFrame = CreateFrame("Frame")
targetScanFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetScanFrame:SetScript("OnEvent", function()
    if PresetPopup:IsVisible() and IsAltKeyDown() and UnitExists("target") and not UnitIsPlayer("target") then
        local bossName = UnitName("target")
        if bossName then
            AddBossDirectly(bossName)
        end
    end
end)


local keyboardFrame = CreateFrame("Frame")
keyboardFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
keyboardFrame:SetScript("OnEvent", function(_, _, key, state)
    if PresetPopup:IsVisible() and (key == "LALT" or key == "RALT") then
        if state == 1 and UnitExists("target") and not UnitIsPlayer("target") then
            local bossName = UnitName("target")
            if bossName then
                AddBossDirectly(bossName)
            end
        end
    end
end)


local saveButtonPresetPopup = CreateButton(PresetPopup, 80, 22, "BOTTOMLEFT", "Save")
saveButtonPresetPopup:SetPoint("BOTTOMLEFT", PresetPopup, "BOTTOMLEFT", 10, 10)

local cancelButton = CreateButton(PresetPopup, 80, 22, "BOTTOMRIGHT", "Cancel")
cancelButton:SetPoint("BOTTOMRIGHT", PresetPopup, "BOTTOMRIGHT", -10, 10)
cancelButton:SetScript("OnClick", function() PresetPopup:Hide() end)


saveButtonPresetPopup:SetScript("OnClick", function()
    local name = presetInput:GetText()
    local bosses = currentBosses

    if not name or name == "" then
        ShowStaticPopup("Please enter a name.", "Error")
        return
    end

    local instanceKey = "otherPresets"
    if not FillRaidPresets[faction] then
        FillRaidPresets[faction] = {}
    end
    if not FillRaidPresets[faction][instanceKey] then
        FillRaidPresets[faction][instanceKey] = {}
    end

    local presetList = FillRaidPresets[faction][instanceKey]
    
    if PresetPopup.mode == "edit" then
       
        for i, p in pairs(presetList) do
            if p.label == PresetPopup.editingPreset then
               
                presetList[i].label = name
                presetList[i].bosses = bosses
                
               
                for classRole, inputBox in pairs(inputBoxes) do
                    if inputBox then
                        local value = tonumber(inputBox:GetText())
                        if value and value > 0 then
                            presetList[i].values[classRole] = value
                        end
                    end
                end
                
                PresetPopup:Hide()
                DEFAULT_CHAT_FRAME:AddMessage("Updated preset: \"" .. name .. "\"")
                
                if currentPresetLabel then
                    currentPresetLabel:SetText("Preset: " .. name)
					currentPresetLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
                end
                currentPresetName = name
                return
            end
        end
    else
       
        for _, p in pairs(presetList) do
            if p.label == name then
                ShowStaticPopup("A preset with that name already exists.", "Error")
                return
            end
        end

        local newPreset = {
            label = name,
            values = {},
            bosses = bosses,
        }

       
        for classRole, inputBox in pairs(inputBoxes) do
            if inputBox then
                local value = tonumber(inputBox:GetText())
                if value and value > 0 then
                    newPreset.values[classRole] = value
                end
            end
        end

        table.insert(presetList, newPreset)
        PresetPopup:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("Saved new preset: \"" .. name .. "\"")
		ShowStaticPopup("Saved new preset: \"" .. name .. "\"\nYou need to reload the UI for changes to take effect.Or you can press No to add more. \n ReloadUI?", "import", true)


        if currentPresetLabel then
            currentPresetLabel:SetText("Preset: " .. name)
			currentPresetLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        end
        currentPresetName = name
    end
end)


presetInput:SetScript("OnEnterPressed", function()
    saveButtonPresetPopup:GetScript("OnClick")()
end)

presetInput:SetScript("OnEscapePressed", function()
    PresetPopup:Hide()
end)

PresetPopup:SetScript("OnKeyDown", function()
    if arg1 == KEY_ESCAPE then
        PresetPopup:Hide()
    end
end)


function OpenSaveAsPopup()
    PresetPopup.mode = "save"
    popupLabel:SetText("Enter preset name:")
    presetInput:SetText("")
    bossInput:SetText("")
    currentBosses = {}
    RefreshBossList()
    saveButton:SetText("Save")
    presetInput:SetFocus()
    if PresetPopup:IsShown() then
        PresetPopup:Hide()
    else
        PresetPopup:Show()
    end
end

function OpenEditPopup()
    if not currentPresetName then

		ShowStaticPopup("No preset selected to edit.", "Error")
        return
    end

   
    local instanceKey = "otherPresets"
    local presetList = FillRaidPresets[faction] and FillRaidPresets[faction][instanceKey] or {}
    local currentPreset
    
    for _, p in pairs(presetList) do
        if p.label == currentPresetName then
            currentPreset = p
            break
        end
    end
    
    if not currentPreset then
        ShowStaticPopup("You can only rename presets \n under Others.")
        return
    end
    
   
    PresetPopup.mode = "edit"
    PresetPopup.editingPreset = currentPresetName
    popupLabel:SetText("Edit preset:")
    presetInput:SetText(currentPresetName)
    currentBosses = {}
    
   
    if currentPreset.bosses then
        for _, boss in ipairs(currentPreset.bosses) do
            table.insert(currentBosses, boss)
        end
    end
    
    RefreshBossList()
    saveButton:SetText("Save")
    PresetPopup:Show()
    presetInput:SetFocus()
end



local ConfirmDeletePopup = CreateFrame("Frame", "ConfirmDeletePopup", UIParent, "BackdropTemplate")
ConfirmDeletePopup:SetSize(260, 100)
ConfirmDeletePopup:SetPoint("CENTER", UIParent, "CENTER")
ConfirmDeletePopup:SetFrameStrata("DIALOG")
ConfirmDeletePopup:SetFrameLevel(20)
ConfirmDeletePopup:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ConfirmDeletePopup:SetBackdropColor(1, 0, 0, 1)
ConfirmDeletePopup:Hide()


local confirmText = ConfirmDeletePopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmText:SetPoint("TOP", ConfirmDeletePopup, "TOP", 0, -20)

local yesButton = CreateFrame("Button", nil, ConfirmDeletePopup, "GameMenuButtonTemplate")
yesButton:SetWidth(60)
yesButton:SetHeight(20)
yesButton:SetPoint("BOTTOMLEFT", ConfirmDeletePopup, "BOTTOMLEFT", 20, 10)
yesButton:SetText("Yes")

local noButton = CreateFrame("Button", nil, ConfirmDeletePopup, "GameMenuButtonTemplate")
noButton:SetWidth(60)
noButton:SetHeight(20)
noButton:SetPoint("BOTTOMRIGHT", ConfirmDeletePopup, "BOTTOMRIGHT", -20, 10)
noButton:SetText("No")
noButton:SetScript("OnClick", function()
    ConfirmDeletePopup:Hide()
end)

function ShowConfirmDeletePopup(presetName)
    ConfirmDeletePopup:Show()
    confirmText:SetText("Delete preset: \"" .. presetName .. "\"?\nThis will also reload the UI.")

    yesButton:SetScript("OnClick", function()
        local presetList = FillRaidPresets[faction]["otherPresets"]
        for i = table.getn(presetList), 1, -1 do
            if presetList[i].label == presetName then
                table.remove(presetList, i)
                break
            end
        end
        ConfirmDeletePopup:Hide()
        PresetPopup:Hide()
        ReloadUI()
    end)
end


local saveAsButton = CreateButton(FillRaidFrame, 80, 20, "LEFT", "Save As")
saveAsButton:SetPoint("LEFT", saveButton, "RIGHT", 10, 0)
saveAsButton:SetScript("OnClick", OpenSaveAsPopup)

saveAsButton:Hide()
saveAsButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(saveAsButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Saves a new preset into Presets > Other")
    GameTooltip:Show()
end)

saveAsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local editButton2 = CreateButton(FillRaidFrame, 80, 20, "LEFT", "Rename")
editButton2:SetPoint("LEFT", saveAsButton, "RIGHT", 10, 0)
editButton2:SetScript("OnClick", OpenEditPopup)
editButton2:Hide()
editButton2:SetScript("OnEnter", function()
    GameTooltip:SetOwner(editButton2, "ANCHOR_RIGHT")
    GameTooltip:SetText("Rename the currently selected preset name and add bosses")
    GameTooltip:Show()
end)

editButton2:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)





local removeButton = CreateButton(FillRaidFrame, 80, 20, "LEFT", "Remove")
removeButton:SetPoint("TOPLEFT", editButton2, "BOTTOMLEFT", 0, -10)
removeButton:Hide()

removeButton:SetScript("OnClick", function()
    if currentPresetName then
        ShowConfirmDeletePopup(currentPresetName)
    else
        ShowStaticPopup("No preset selected to Remove.", "Error")
    end
end)

removeButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(removeButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Remove the currently selected preset")
    GameTooltip:Show()
end)

removeButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


function OpenEditPopup()
    if not currentPresetName then
        ShowStaticPopup("No preset selected to edit.", "Error")
        return
    end

   
    local instanceKey = "otherPresets"
    local presetList = FillRaidPresets[faction] and FillRaidPresets[faction][instanceKey] or {}
    local currentPreset
    
    for _, p in pairs(presetList) do
        if p.label == currentPresetName then
            currentPreset = p
            break
        end
    end
    
    if not currentPreset then
        DEFAULT_CHAT_FRAME:AddMessage("Preset not found.")
        return
    end
    
   
    PresetPopup.mode = "edit"
    PresetPopup.editingPreset = currentPresetName
    popupLabel:SetText("Edit preset:")
    presetInput:SetText(currentPresetName)
    currentBosses = {}
    
   
    if currentPreset.bosses then
        for _, boss in ipairs(currentPreset.bosses) do
            table.insert(currentBosses, boss)
        end
    end
    
    RefreshBossList()
    saveButton:SetText("Update")
    removeButton:Show()
    PresetPopup:Show()
    presetInput:SetFocus()
end




local function OnPresetSelected(presetName)
    currentPresetName = presetName
    if presetName then
        removeButton:Show()
    else
        removeButton:Hide()
    end
   
end


PresetPopup:SetScript("OnHide", function()
    if not currentPresetName then
        removeButton:Show()
    end
end)
-------------------------------------------export suppress -----------------------------------------------------------------------
local SuppressExportFrame = CreateFrame("Frame", "FillRaidSuppressExportFrame", UIParent, "BackdropTemplate")
SuppressExportFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})


SuppressExportFrame:SetBackdropColor(0, 0, 0, 1)
SuppressExportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
SuppressExportFrame:SetWidth(400)
SuppressExportFrame:SetHeight(300)
SuppressExportFrame:SetFrameStrata("DIALOG")
SuppressExportFrame:SetFrameLevel(9999)
SuppressExportFrame:SetToplevel(true)
SuppressExportFrame:Hide()

SuppressExportFrame.background = SuppressExportFrame:CreateTexture(nil, "BACKGROUND")
SuppressExportFrame.background:SetAllPoints(SuppressExportFrame)
SuppressExportFrame.background:SetColorTexture(0, 0, 0, 1)

SuppressExportFrame:SetMovable(true)
SuppressExportFrame:EnableMouse(true)
SuppressExportFrame:RegisterForDrag("LeftButton")
SuppressExportFrame:SetScript("OnDragStart", SuppressExportFrame.StartMoving)
SuppressExportFrame:SetScript("OnDragStop", SuppressExportFrame.StopMovingOrSizing)

table.insert(UISpecialFrames, "SuppressExportFrame")

local suppressTitle = SuppressExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
suppressTitle:SetPoint("TOP", SuppressExportFrame, "TOP", 0, -10)
suppressTitle:SetText("Export/Import Suppressed Bot Messages")

local helpSuppress = CreateHelpButton(SuppressExportFrame, suppressTitle, 10, 0, "To export select all and Ctrl+C.\nTo import, replace content and click Import.", "Help")

local suppressScroll = CreateFrame("ScrollFrame", "FillRaidSuppressScrollFrame", SuppressExportFrame, "UIPanelScrollFrameTemplate")
suppressScroll:SetPoint("TOPLEFT", SuppressExportFrame, "TOPLEFT", 16, -40)
suppressScroll:SetPoint("BOTTOMRIGHT", SuppressExportFrame, "BOTTOMRIGHT", -30, 50)

local suppressScrollChild = CreateFrame("Frame", nil, suppressScroll)
suppressScrollChild:SetWidth(suppressScroll:GetWidth())
suppressScroll:SetScrollChild(suppressScrollChild)

local suppressEditBox = CreateFrame("EditBox", "FillRaidSuppressEditBox", suppressScrollChild)
suppressEditBox:SetMultiLine(true)
suppressEditBox:SetWidth(340)
suppressEditBox:SetHeight(1000)
suppressEditBox:SetFontObject(GameFontHighlight)
suppressEditBox:SetAutoFocus(false)
suppressEditBox:SetScript("OnEscapePressed", function() suppressEditBox:ClearFocus() end)
suppressEditBox:SetPoint("TOPLEFT", suppressScrollChild, "TOPLEFT", 0, 0)

local function SerializeTable(tbl, indent)
    indent = indent or ""
    local str = "{\n"
    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = string.format("[%q]", k) 
        else 
            key = string.format("[%d]", k) 
        end
        
        str = str .. indent .. "  " .. key .. " = "
        
       
        if type(v) == "table" then
            str = str .. SerializeTable(v, indent .. "  ")
        elseif type(v) == "string" then
            str = str .. string.format("%q", v)
        elseif type(v) == "boolean" then
            str = str .. (v and "true" or "false")
        else 
            str = str .. tostring(v)
        end
        str = str .. ",\n"
    end
    return str .. indent .. "}"
end


local function OpenSuppressExportFrame()
    if FillRaidSuppressBotMsg then
        suppressEditBox:SetText("FillRaidSuppressBotMsg = " .. SerializeTable(FillRaidSuppressBotMsg))
    else
        suppressEditBox:SetText("FillRaidSuppressBotMsg is nil.")
    end

    local text = suppressEditBox:GetText()
    local lineCount = 1
    local pos = 1

    while true do
        local newPos = string.find(text, "\n", pos)
        if not newPos then break end
        lineCount = lineCount + 1
        pos = newPos + 1
    end

    local contentHeight = lineCount * 16
    suppressScrollChild:SetHeight(math.max(contentHeight, suppressScroll:GetHeight()))

    SuppressExportFrame:Show()
    suppressEditBox:SetFocus()
end



local selectAllSuppress = CreateFrame("Button", nil, SuppressExportFrame, "GameMenuButtonTemplate")
selectAllSuppress:SetText("Select All")
selectAllSuppress:SetWidth(100)
selectAllSuppress:SetHeight(20)
selectAllSuppress:SetPoint("BOTTOMLEFT", SuppressExportFrame, "BOTTOMLEFT", 10, 10)
selectAllSuppress:SetScript("OnClick", function()
    suppressEditBox:HighlightText()
    suppressEditBox:SetFocus()
end)

local importSuppressButton = CreateFrame("Button", nil, SuppressExportFrame, "GameMenuButtonTemplate")
importSuppressButton:SetText("Import")
importSuppressButton:SetWidth(80)
importSuppressButton:SetHeight(20)
importSuppressButton:SetPoint("BOTTOM", SuppressExportFrame, "BOTTOM", 0, 10)
importSuppressButton:SetScript("OnClick", function()
    local text = suppressEditBox:GetText()

    if not text or strtrim(text) == "" then
        ShowStaticPopup("Import failed: No data to import", "import")
        return
    end

    text = string.gsub(text, "([%[%]])%s*=%s*", "%1 = ")
    text = string.gsub(text, "(%d+)%s*=%s*", "[%1] = ")

    if strsub(strtrim(text), 1, 1) == "{" then
        text = "return " .. text
    end

    local env = {}
    local func, err = loadstring(text)

    if not func then
        ShowStaticPopup("Import failed: "..(err or "Syntax error"), "import")
        return
    end

    setfenv(func, env)
    local success, result = pcall(func)

    if success then
        local importedTable = result or env.FillRaidSuppressBotMsg
        if type(importedTable) == "table" then
            FillRaidSuppressBotMsg = importedTable
            ShowStaticPopup("SuppressBotMsg imported! Reloading UI...", "import", true)
        else
            ShowStaticPopup("Import failed: No valid table data found", "import")
        end
    else
        ShowStaticPopup("Import failed: "..(result or "Execution error"), "import")
    end
end)

local closeSuppressButton = CreateFrame("Button", nil, SuppressExportFrame, "GameMenuButtonTemplate")
closeSuppressButton:SetText("Close")
closeSuppressButton:SetWidth(80)
closeSuppressButton:SetHeight(20)
closeSuppressButton:SetPoint("BOTTOMRIGHT", SuppressExportFrame, "BOTTOMRIGHT", -10, 10)
closeSuppressButton:SetScript("OnClick", function()
    SuppressExportFrame:Hide()
end)


--------------------------------------------SuppressBotMsgList-------------------------------------------------------------------


SuppressEditor = CreateFrame("Frame", "SuppressEditorFrame", UIParent, "BackdropTemplate")
SuppressEditor:SetSize(370, 450)
SuppressEditor:SetPoint("CENTER")
SuppressEditor:SetFrameStrata("DIALOG")
	SuppressEditor.background = SuppressEditor:CreateTexture(nil, "BACKGROUND")
	SuppressEditor.background:SetAllPoints(SuppressEditor)
	SuppressEditor.background:SetColorTexture(0, 0, 0, 1) 
SuppressEditor:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
SuppressEditor:SetBackdropColor(0, 0, 0, 1)
SuppressEditor:SetMovable(true)
SuppressEditor:EnableMouse(true)
SuppressEditor:RegisterForDrag("LeftButton")
SuppressEditor:SetScript("OnDragStart", SuppressEditor.StartMoving)
SuppressEditor:SetScript("OnDragStop", SuppressEditor.StopMovingOrSizing)
SuppressEditor:Show()
table.insert(UISpecialFrames, "SuppressEditorFrame")



local title = SuppressEditor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("SuppressBotMsg Editor")
local helpButton = CreateHelpButton(SuppressEditorFrame, title, 10, 0, "Enter a message pattern to suppress.\n\nCooldown:\n - Time (in seconds) to wait before showing the same message again.\n - Set to 0 to fully suppress that message.\n\nTip:\n - Partial matches are supported. For example, 'joins the party' matches \nmessages like 'Bot123 joins the party.", "Suppress Message Help")


local patternLabel = SuppressEditor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
patternLabel:SetPoint("TOPLEFT", 20, -40)
patternLabel:SetText("Message Pattern:")


local patternInput = CreateFrame("EditBox", nil, SuppressEditor, "InputBoxTemplate")
patternInput:SetSize(260, 20)
patternInput:SetAutoFocus(false)
patternInput:SetPoint("TOPLEFT", patternLabel, "BOTTOMLEFT", 0, -5)
patternInput:SetScript("OnEscapePressed", patternInput.ClearFocus)


local cooldownLabel = SuppressEditor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cooldownLabel:SetPoint("TOPLEFT", patternInput, "BOTTOMLEFT", 0, -10)
cooldownLabel:SetText("Cooldown (seconds):")


local cooldownInput = CreateFrame("EditBox", nil, SuppressEditor, "InputBoxTemplate")
cooldownInput:SetSize(80, 20)
cooldownInput:SetAutoFocus(false)
cooldownInput:SetPoint("TOPLEFT", cooldownLabel, "BOTTOMLEFT", 0, -5)
cooldownInput:SetNumeric(true)
cooldownInput:SetScript("OnEscapePressed", cooldownInput.ClearFocus)

CreateSeparatorLine(SuppressEditor, 0, -6, 336, cooldownInput)

local addButton = CreateFrame("Button", nil, SuppressEditor, "UIPanelButtonTemplate")
addButton:SetSize(100, 24)
addButton:SetText("Add/Update")
addButton:SetPoint("LEFT", cooldownInput, "RIGHT", 10, 0)


local scrollFrame = CreateFrame("ScrollFrame", nil, SuppressEditor, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -140)
scrollFrame:SetPoint("BOTTOMRIGHT", -45, 60)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(260, 1)
scrollFrame:SetScrollChild(scrollChild)

local listItems = {}

function RefreshSuppressList()
    for _, item in ipairs(listItems) do item:Hide() end
    wipe(listItems)

    local list = FillRaidSuppressBotMsg and FillRaidSuppressBotMsg.messagesToHide or {}
    local y = 0

    for pattern, cooldown in pairs(list) do
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(290, 20)
        row:SetPoint("TOPLEFT", 0, -y)

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetText(pattern .. " (" .. cooldown .. "s)")
        text:SetPoint("LEFT")

        local delButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delButton:SetSize(20, 20)
        delButton:SetText("X")
        delButton:SetPoint("RIGHT")
        delButton:SetScript("OnClick", function()
            FillRaidSuppressBotMsg.messagesToHide[pattern] = nil
            RefreshSuppressList()
        end)

        table.insert(listItems, row)
        y = y + 24
    end

    scrollChild:SetHeight(y + 10)
end
CreateSeparatorLine(SuppressEditor, 0, -6, 336, scrollFrame)

addButton:SetScript("OnClick", function()
    local pattern = patternInput:GetText()
    local cooldown = tonumber(cooldownInput:GetText()) or 0

    if pattern == "" then return end
    FillRaidSuppressBotMsg = FillRaidSuppressBotMsg or {}
    FillRaidSuppressBotMsg.messagesToHide = FillRaidSuppressBotMsg.messagesToHide or {}

    FillRaidSuppressBotMsg.messagesToHide[pattern] = cooldown
    patternInput:SetText("")
    cooldownInput:SetText("")
    RefreshSuppressList()
end)


local saveButtonSuppressEditor = CreateFrame("Button", nil, SuppressEditor, "GameMenuButtonTemplate")
saveButtonSuppressEditor:SetSize(80, 24)
saveButtonSuppressEditor:SetText("Save")
saveButtonSuppressEditor:SetPoint("BOTTOMLEFT", 10, 20)
saveButtonSuppressEditor:SetScript("OnClick", function()
    ShowStaticPopup("Saved new Suppress message\nYou need to reload the UI for changes to take effect.Or you can press No to add more. \n ReloadUI?", "import", true)
end)

local restoreSuppressDefaultsButton = CreateFrame("Button", nil, SuppressEditor, "GameMenuButtonTemplate")
restoreSuppressDefaultsButton:SetText("Defaults")
restoreSuppressDefaultsButton:SetSize(80, 24)
restoreSuppressDefaultsButton:SetPoint("LEFT", saveButtonSuppressEditor, "RIGHT", 10, 0)

restoreSuppressDefaultsButton:SetScript("OnClick", function()
    StaticPopupDialogs["CONFIRM_RESTORE_SUPPRESS_DEFAULTS"] = {
        text = "Are you sure you want to restore the default suppress message settings? This will delete your custom entries.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            FillRaidSuppressBotMsg = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("CONFIRM_RESTORE_SUPPRESS_DEFAULTS")
end)

restoreSuppressDefaultsButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(restoreSuppressDefaultsButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Restores all suppress message patterns to default.\n\nWill reload your UI.")
    GameTooltip:Show()
end)
restoreSuppressDefaultsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local openSuppressButton = CreateFrame("Button", nil, SuppressEditor, "GameMenuButtonTemplate")
openSuppressButton:SetText("Export")
openSuppressButton:SetWidth(80)
openSuppressButton:SetHeight(24)
openSuppressButton:SetPoint("LEFT", restoreSuppressDefaultsButton, "RIGHT", 10, 0)
openSuppressButton:SetScript("OnClick", OpenSuppressExportFrame)
openSuppressButton:Show()


local cancelButtonSuppressEditor = CreateFrame("Button", nil, SuppressEditor, "GameMenuButtonTemplate")
cancelButtonSuppressEditor:SetSize(80, 24)
cancelButtonSuppressEditor:SetText("Cancel")
cancelButtonSuppressEditor:SetPoint("LEFT", openSuppressButton, "RIGHT", 10, 0)
cancelButtonSuppressEditor:SetScript("OnClick", function()
    SuppressEditor:Hide()
end)



--------------------------------------------Restore default-----------------------------------------------------------------------
local restoreDefaultsButton = CreateFrame("Button", nil, FillRaidFrame, "GameMenuButtonTemplate")
restoreDefaultsButton:SetText("Defaults")
restoreDefaultsButton:SetWidth(80)
restoreDefaultsButton:SetHeight(20)
restoreDefaultsButton:SetPoint("TOP", saveButton, "BOTTOM", 0, -10)
restoreDefaultsButton:Hide()

restoreDefaultsButton:SetScript("OnClick", function()
    if not faction then
        print("Faction not set.")
        return
    end

    StaticPopupDialogs["CONFIRM_RESTORE_DEFAULTS"] = {
        text = "Are you sure you want to restore the default presets for " .. faction .. "? This will delete all your custom presets.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            FillRaidPresets[faction] = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("CONFIRM_RESTORE_DEFAULTS")
end)

restoreDefaultsButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(restoreDefaultsButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Restores all preset to default")
    GameTooltip:Show()
end)
restoreDefaultsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)



-------------------------export/import................................

local ExportFrame = CreateFrame("Frame", "FillRaidExportFrame", UIParent, "BackdropTemplate")
ExportFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ExportFrame:SetBackdropColor(0, 0, 0, 0.8)
ExportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ExportFrame:SetWidth(400)
ExportFrame:SetHeight(300)
ExportFrame:SetFrameStrata("DIALOG")
ExportFrame:Hide()


local title = ExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", ExportFrame, "TOP", 0, -10)
title:SetText("Export / Import FillRaidPresets")
local helpexport = CreateHelpButton(ExportFrame, title, 10, 0, "To export Select all and ctrl+c to copy to a document\n To import remove everything and paste your saved settings", "Another Help")

local scrollFrame = CreateFrame("ScrollFrame", "FillRaidExportScrollFrame", ExportFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", ExportFrame, "TOPLEFT", 16, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", ExportFrame, "BOTTOMRIGHT", -30, 50)


local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(scrollFrame:GetWidth()) 
scrollFrame:SetScrollChild(scrollChild)


local editBox = CreateFrame("EditBox", "FillRaidExportEditBox", scrollChild)
editBox:SetMultiLine(true)
editBox:SetWidth(340)
editBox:SetHeight(1000) 
editBox:SetFontObject(GameFontHighlight)
editBox:SetAutoFocus(false)
editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
editBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)


local function SerializeTable(tbl, indent)
    indent = indent or ""
    local str = "{\n"
    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = string.format("[%q]", k) 
        else 
            key = string.format("[%d]", k) 
        end
        
        str = str .. indent .. "  " .. key .. " = "
        
       
        if type(v) == "table" then
            str = str .. SerializeTable(v, indent .. "  ")
        elseif type(v) == "string" then
            str = str .. string.format("%q", v)
        elseif type(v) == "boolean" then
            str = str .. (v and "true" or "false")
        else 
            str = str .. tostring(v)
        end
        str = str .. ",\n"
    end
    return str .. indent .. "}"
end



local function OpenExportFrame()
    if FillRaidPresets then
        editBox:SetText("FillRaidPresets = " .. SerializeTable(FillRaidPresets))
    else
        editBox:SetText("FillRaidPresets is nil.")
    end
    
   
    local text = editBox:GetText()
    local lineCount = 1
    local pos = 1
    
   
    while true do
        local newPos = string.find(text, "\n", pos)
        if not newPos then break end
        lineCount = lineCount + 1
        pos = newPos + 1
    end
    
   
    local contentHeight = lineCount * 16
    scrollChild:SetHeight(math.max(contentHeight, scrollFrame:GetHeight()))
    
    ExportFrame:Show()
    editBox:SetFocus()
end


local openExportButton = CreateFrame("Button", nil, FillRaidFrame, "GameMenuButtonTemplate")
openExportButton:SetText("Export")
openExportButton:SetWidth(80)
openExportButton:SetHeight(20)
openExportButton:SetPoint("LEFT", restoreDefaultsButton, "RIGHT", 10, 0)
openExportButton:SetScript("OnClick", OpenExportFrame)
openExportButton:Hide()



























local copyButton = CreateFrame("Button", nil, ExportFrame, "GameMenuButtonTemplate")
copyButton:SetText("Select All")
copyButton:SetWidth(100)
copyButton:SetHeight(20)
copyButton:SetPoint("BOTTOMLEFT", ExportFrame, "BOTTOMLEFT", 10, 10)
copyButton:SetScript("OnClick", function()
    editBox:HighlightText()
    editBox:SetFocus()
end)


local importButton = CreateFrame("Button", nil, ExportFrame, "GameMenuButtonTemplate")
importButton:SetText("Import")
importButton:SetWidth(80)
importButton:SetHeight(20)
importButton:SetPoint("BOTTOM", ExportFrame, "BOTTOM", 0, 10)
importButton:SetScript("OnClick", function()
    local text = editBox:GetText()
    
   
    if not text or strtrim(text) == "" then
        ShowStaticPopup("Import failed: No data to import", "import")
        return
    end
    
   
    text = string.gsub(text, "([%[%]])%s*=%s*", "%1 = ")
    text = string.gsub(text, "(%d+)%s*=%s*", "[%1] = ")
    
   
    if strsub(strtrim(text), 1, 1) == "{" then
        text = "return " .. text
    end
    
   
    local env = {}
    local func, err = loadstring(text)
    
    if not func then
        ShowStaticPopup("Import failed: "..(err or "Syntax error"), "import")
        return
    end
    
    setfenv(func, env)
    local success, result = pcall(func)
    
    if success then
       
        local importedTable = result or env.FillRaidPresets
        if type(importedTable) == "table" then
            FillRaidPresets = importedTable
            ShowStaticPopup("Presets imported successfully! Reloading UI...", "import", true)

        else
            ShowStaticPopup("Import failed: No valid table data found", "import")
        end
    else
        ShowStaticPopup("Import failed: "..(result or "Execution error"), "import")
    end
end)


local closeButton4 = CreateFrame("Button", nil, ExportFrame, "GameMenuButtonTemplate")
closeButton4:SetText("Close")
closeButton4:SetWidth(80)
closeButton4:SetHeight(20)
closeButton4:SetPoint("BOTTOMRIGHT", ExportFrame, "BOTTOMRIGHT", -10, 10)
closeButton4:SetScript("OnClick", function()
    ExportFrame:Hide()
end)













-------------------------------------------------------------------------------------------------------------------------------------
	local editmodeshown = false
	local editButton = CreateFrame("Button", nil, FillRaidFrame, "GameMenuButtonTemplate")
	editButton:SetPoint("TOPRIGHT", FillRaidFrame, "TOPRIGHT", -10, -50)
	editButton:SetWidth(80)
	editButton:SetHeight(20)
	editButton:SetText("Edit")
	editButton:SetScript("OnClick", function()
		if saveButton:IsShown() then
			saveButton:Hide()
			saveAsButton:Hide()
			openExportButton:Hide()
			removeButton:Hide()
			restoreDefaultsButton:Hide()
			editButton2:Hide()
			saveAsButton:Hide()
			currentInstanceLabel:Hide()
			currentPresetLabel:Hide()
		
			fillRaidButton:Show()
			closeButton:Show()
			editButton:SetText("Edit")
		else
			saveButton:Show()
			saveAsButton:Show()
			openExportButton:Show()
			removeButton:Show()
			restoreDefaultsButton:Show()
			editButton2:Show()
			saveAsButton:Show()
			currentInstanceLabel:Show()
			currentPresetLabel:Show()
		
			fillRaidButton:Hide()
			closeButton:Hide()
			editButton:SetText("Back")
			if not editmodeshown then
			ShowStaticPopup("Edit mode activated. You can now save your changes.", "Preset Saved")
			editmodeshown = true
			end
		end
	end)

	currentPresetLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	currentPresetLabel:SetPoint("TOPLEFT", openSettingsButton, "BOTTOMLEFT", 0, -15)
	currentPresetLabel:SetText("Preset: None")
	currentPresetLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
	currentPresetName = nil
	currentPresetLabel:Hide()
	
	currentInstanceLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

	currentInstanceLabel:SetPoint("TOPLEFT", openSettingsButton, "BOTTOMLEFT", 0, -5) 
	currentInstanceLabel:SetText("Instance: None") 
	currentInstanceLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
	currentInstanceName = nil
	currentInstanceLabel:Hide()


local CreditsFrame = CreateFrame("Frame", "CreditsFrame", UIParent)
CreditsFrame:SetWidth(300)
CreditsFrame:SetHeight(230)
CreditsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CreditsFrame:SetFrameStrata("DIALOG")  
CreditsFrame:SetFrameLevel(1)  

CreditsFrame:EnableMouse(true)
CreditsFrame:SetMovable(true)


CreditsFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)

CreditsFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:StopMovingOrSizing()
    end
end)


CreditsFrame.background = CreditsFrame:CreateTexture(nil, "BACKGROUND")
CreditsFrame.background:SetAllPoints(CreditsFrame)
CreditsFrame.background:SetColorTexture(0, 0, 0, 0.9) 


CreditsFrame.border = CreateFrame("Frame", nil, CreditsFrame, BackdropTemplateMixin and "BackdropTemplate")
CreditsFrame.border:SetPoint("TOPLEFT", -4, 4)
CreditsFrame.border:SetPoint("BOTTOMRIGHT", 4, -4)
CreditsFrame.border:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
    edgeSize = 16,
})
CreditsFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8)
CreditsFrame.border:SetFrameLevel(CreditsFrame:GetFrameLevel() + 1)  


CreditsFrame.header = CreateFrame("Frame", nil, CreditsFrame)
CreditsFrame.header:SetWidth(250)
CreditsFrame.header:SetHeight(64)
CreditsFrame.header:SetPoint('TOP', CreditsFrame, 0, 18)
CreditsFrame.header:SetFrameLevel(CreditsFrame:GetFrameLevel() + 2)  

CreditsFrame.header.texture = CreditsFrame.header:CreateTexture(nil, 'ARTWORK')
CreditsFrame.header.texture:SetAllPoints(CreditsFrame.header)
CreditsFrame.header.texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
CreditsFrame.header.texture:SetVertexColor(0.2, 0.2, 0.2)

CreditsFrame.header.text = CreditsFrame.header:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
CreditsFrame.header.text:SetPoint('TOP', CreditsFrame.header, 0, -14)
CreditsFrame.header.text:SetText('Credits')


local creditsData = {
    {name = "|cffffd700Pumpan|r", contribution = "Creator of the addon"},  

    {name = "|cffffd700Dedirtyone|r", contribution = "Special thanks to Dedirtyone for his incredible generosity\nin donating 50EUR to help me get VIP status.\nYour support means so much and has truly motivated me\nto keep contributing to the community.\nThis addon wouldn't be the same without people like you!"},  

    {name = "|cffffd700TheSamurai206|r", contribution = "A huge thank you to TheSamurai206 (Zugginator) for his generous donation of 20EUR.\nYour support means a lot and helps me continue improving this addon.\nIt's supporters like you that keep this project going!"},

    {name = "|cffffd700Spinach|r", contribution = "A heartfelt thank you to Spinach for the generous 20EU<R donation.\nYour support truly means a lot and motivates me to keep improving this addon.\nAmazing supporters like you are what keep this project alive!"},

    {name = "|cffffffffGemma|r", contribution = "Has been part of the project from the very beginning.\nContributed many great ideas, helped with extensive beta testing,\nand created one of the button themes used in the addon.\nYour support and feedback have been invaluable!"},  

    {name = "|cffffffffNymz|r", contribution = "Since 2026, Nymz has contributed with great ideas,\ncode improvements for the 1.14 client version, bug reports,\nand also created a button theme.\nThese contributions have helped improve both the addon\nand the overall user experience."},	

    {name = "|cffffffffTO EVERYONE ELSE!|r", contribution = "To everyone who has been supporting!\nIf you are interested in contributing in any way,\nbug reporting, beta testing, or whatever,\nplease contact me on the forum, Discord, or in-game."},  
}




local yOffset = -40 
for i, data in ipairs(creditsData) do
    local nameButton = CreateFrame("Button", nil, CreditsFrame)
    nameButton:SetSize(200, 20)
    nameButton:SetPoint("TOP", CreditsFrame, "TOP", 0, yOffset)

    
    local nameText = nameButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameText:SetText(data.name)
    nameText:SetPoint("CENTER", nameButton, "CENTER")

    
    nameButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(nameButton, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.contribution, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    nameButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    yOffset = yOffset - 25 
end


local openCreditsButton = CreateFrame("Button", "OpenCreditsButton", FillRaidFrame, "UIPanelButtonTemplate")
openCreditsButton:SetWidth(60)  
openCreditsButton:SetHeight(15)  
openCreditsButton:SetText("Credits")
openCreditsButton:SetPoint("BOTTOMLEFT", FillRaidFrame, "BOTTOMLEFT", 0, 0)


openCreditsButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10)  


openCreditsButton:SetScript("OnClick", function()
    if CreditsFrame:IsShown() then
        CreditsFrame:Hide()
        ClickBlockerFrame:Hide()
    else
        CreditsFrame:Show()
        ClickBlockerFrame:Show()
    end
end)


CreditsFrame:Hide()



    
	local InstanceButtonsFrame = CreateFrame("Frame", "InstanceButtonsFrame", UIParent)
	InstanceButtonsFrame:SetWidth(200)
	InstanceButtonsFrame:SetHeight(350)
	InstanceButtonsFrame:SetPoint("LEFT", FillRaidFrame, "RIGHT", 10, 0)
	table.insert(UISpecialFrames, "InstanceButtonsFrame")
	
	InstanceButtonsFrame.background = InstanceButtonsFrame:CreateTexture(nil, "BACKGROUND")
	InstanceButtonsFrame.background:SetAllPoints(InstanceButtonsFrame)
	InstanceButtonsFrame.background:SetColorTexture(0, 0, 0, 1) 

	
	InstanceButtonsFrame.border = CreateFrame("Frame", nil, InstanceButtonsFrame, BackdropTemplateMixin and "BackdropTemplate")
	InstanceButtonsFrame.border:SetPoint("TOPLEFT", -4, 4)
	InstanceButtonsFrame.border:SetPoint("BOTTOMRIGHT", 4, -4)
	InstanceButtonsFrame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		edgeSize = 16,
	})
	InstanceButtonsFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) 

	InstanceButtonsFrame:SetFrameStrata("DIALOG")
	InstanceButtonsFrame:SetFrameLevel(10)
	InstanceButtonsFrame:Hide()


    local instanceButtons = {}
    local instanceFullNameMap = {
        ["BWL"] = "Blackwing Lair",
        ["MC"] = "Molten Core",
        ["AQ40"] = "Temple of Ahn'Qiraj",
        ["AQ20"] = "Ruins of Ahn'Qiraj",
        ["ZG"] = "Zul'Gurub",
        ["Other"] = "Other Presets",
    }

    local function CreateInstanceButton(label, yOffset, frameName, presetName)
        local button = CreateFrame("Button", nil, InstanceButtonsFrame, "GameMenuButtonTemplate")
        button:SetPoint("TOP", InstanceButtonsFrame, "TOP", 0, yOffset)
        button:SetWidth(180)
        button:SetHeight(30)
        button:SetText(label)
        button.fullName = instanceFullNameMap[label] or label
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(button.fullName or label, 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        button:SetScript("OnClick", function()
            InstanceButtonsFrame:Hide()
            ClickBlockerFrame:Show()
			
			if currentInstanceLabel then
				currentInstanceLabel:SetText("Instance: " .. label)
				currentInstanceLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
				currentInstanceName = presetName
				
			end			
			
            local frame = instanceFrames[frameName]
            if frame then
                frame:Show()
            else
                QueueDebugMessage("Error: Frame '" .. frameName .. "' not found.", "debugerror")
            end
			if frame.headerText then
				frame.headerText:SetText(label)
			end
			
        end)
        return button
    end

    
    CreateInstanceButton("Naxxramas", -10, "PresetDungeounNaxxramas", "naxxramasPresets")
    CreateInstanceButton("BWL", -50, "PresetDungeounBWL", "bwlPresets")
    CreateInstanceButton("MC", -90, "PresetDungeounMC", "mcPresets")
    CreateInstanceButton("Onyxia", -130, "PresetDungeounOnyxia", "onyxiaPresets")
    CreateInstanceButton("AQ40", -170, "PresetDungeounAQ40", "aq40Presets")
    CreateInstanceButton("AQ20", -210, "PresetDungeounAQ20", "aq20Presets")	
    CreateInstanceButton("ZG", -250, "PresetDungeounZG", "ZGPresets")	
	CreateInstanceButton("Other", -290, "PresetDungeounOther", "otherPresets")


  
local function TruncateToFit(button, text, maxWidth)
    if not text then
        return "", false
    end

    local fontString = button:GetFontString()
    if not fontString then
        return text, false
    end

    fontString:SetText(text)

    if fontString:GetStringWidth() <= maxWidth then
        return text, false
    end

    local truncated = text
    local ellipsis = "..."

    while string.len(truncated) > 0 do
        truncated = string.sub(truncated, 1, string.len(truncated) - 1)
        fontString:SetText(truncated .. ellipsis)

        if fontString:GetStringWidth() <= maxWidth then
            return truncated .. ellipsis, true
        end
    end

    return ellipsis, true
end


function CreateInstanceFrame(name, presets, label)
    local buttonWidth = 80
    local buttonHeight = 30
    local padding = 10
    local maxButtonsPerColumn = 8
    
    
    
    local tutorialButtonSize = 18

    local totalButtonWidth = buttonWidth + padding
    local totalButtonHeight = buttonHeight + padding

    local function GetEffectiveButtonCount()
        local count = table.getn(presets)

        if name ~= "PresetDungeounOther" and OthersButtonEnabled then
            count = count + 1
        end

        return count
    end

    local numButtons = GetEffectiveButtonCount()
    local numColumns = math.ceil(numButtons / maxButtonsPerColumn)
    local numRows = math.min(numButtons, maxButtonsPerColumn)

    local dynamicWidth = (totalButtonWidth * numColumns) + padding
    local dynamicHeight = (totalButtonHeight * numRows) + padding
    local tutorialWidthBonus = tutorialButtonSize + 4

    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    setglobal(name, frame)
    table.insert(UISpecialFrames, name)

    frame.baseWidth = dynamicWidth
    frame.baseHeight = dynamicHeight
    frame.tutorialWidthBonus = tutorialWidthBonus
    frame.presetButtons = {}
    frame:SetWidth(dynamicWidth)
    frame:SetHeight(dynamicHeight)
    frame:SetPoint("LEFT", FillRaidFrame, "RIGHT", 10, 0)

    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(10)
    frame:Hide()

    frame.header = frame:CreateTexture(nil, 'ARTWORK')
    frame.header:SetWidth(dynamicWidth)
    frame.header:SetHeight(64)
    frame.header:SetPoint('TOP', frame, 0, 18)
    frame.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    frame.header:SetVertexColor(.2, .2, .2)

    frame.headerText = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    frame.headerText:SetPoint('TOP', frame.header, 0, -14)
    frame.headerText:SetText(name)

    frame.tutorialButtons = {}

    local function IsTutorialLinksEnabled()
        return FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.showTutorialLinks and true or false
    end

    local function ColumnHasVisibleTutorial(column)
        local info

        if not IsTutorialLinksEnabled() then
            return false
        end

        if not frame.presetButtons then
            return false
        end

        for _, buttonInfo in ipairs(frame.presetButtons) do
            if buttonInfo.column == column and buttonInfo.tutorialButton then
                return true
            end
        end

        return false
    end

    local function GetColumnWidth(column)
        local width = totalButtonWidth

        if ColumnHasVisibleTutorial(column) then
            width = width + tutorialWidthBonus
        end

        return width
    end

    local function GetLayoutWidth()
        local width = padding
        local column
        local effectiveColumns = math.ceil(GetEffectiveButtonCount() / maxButtonsPerColumn)

        for column = 0, effectiveColumns - 1 do
            width = width + GetColumnWidth(column)
        end

        return width
    end

    local fixedStartY = -10

    local function LayoutInstanceButtons()
        local xOffset = padding
        local columnOffsets = {}
        local column
        local buttonInfo
        local yOffset
        local targetWidth = GetLayoutWidth()
        local effectiveButtonCount = GetEffectiveButtonCount()
        local effectiveColumns = math.ceil(effectiveButtonCount / maxButtonsPerColumn)
        local effectiveRows = math.min(effectiveButtonCount, maxButtonsPerColumn)
        local targetHeight = (totalButtonHeight * effectiveRows) + padding

        frame:SetWidth(targetWidth)
        frame:SetHeight(targetHeight)
        frame.baseHeight = targetHeight

        if frame.header then
            frame.header:SetWidth(targetWidth)
        end

        for column = 0, effectiveColumns - 1 do
            columnOffsets[column] = xOffset
            xOffset = xOffset + GetColumnWidth(column)
        end

        if frame.presetButtons then
            for _, buttonInfo in ipairs(frame.presetButtons) do
                yOffset = fixedStartY - (buttonInfo.row * totalButtonHeight)

                buttonInfo.button:ClearAllPoints()
                buttonInfo.button:SetPoint("TOPLEFT", frame, "TOPLEFT", columnOffsets[buttonInfo.column] or padding, yOffset)

                if buttonInfo.tutorialButton then
                    buttonInfo.tutorialButton:ClearAllPoints()
                    buttonInfo.tutorialButton:SetPoint("LEFT", buttonInfo.button, "RIGHT", 2, 0)
                end
            end
        end

        if frame.othersButton then
            yOffset = fixedStartY - ((frame.othersButtonRow or 0) * totalButtonHeight)
            frame.othersButton:ClearAllPoints()
            frame.othersButton:SetPoint("TOPLEFT", frame, "TOPLEFT", columnOffsets[frame.othersButtonColumn or 0] or padding, yOffset)
        end
    end

    frame.UpdateTutorialWidth = LayoutInstanceButtons

    local function CreatePresetButton(preset, index)
        local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        button:SetWidth(buttonWidth)
        button:SetHeight(buttonHeight)

        local column = math.floor((index - 1) / maxButtonsPerColumn)
        local row = (index - 1) - column * maxButtonsPerColumn

        local yOffset = fixedStartY - (row * totalButtonHeight)

        button:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, yOffset)

        
        local originalText = preset.label or "Unknown preset"
        local maxTextWidth = buttonWidth - 16  

        local finalText, wasTruncated = TruncateToFit(button, originalText, maxTextWidth)

        button:SetText(finalText)
        button.originalText = originalText
        button.wasTruncated = wasTruncated

        button:SetScript("OnClick", function()
            for classRole, inputBox in pairs(inputBoxes) do
                if inputBox then
                    inputBox:SetNumber(0)
                    local onTextChanged = inputBox:GetScript("OnTextChanged")
                    if onTextChanged then
                        onTextChanged(inputBox)
                    end
                end
            end

            currentLoadedPreset = preset
            ReapplyCurrentPreset()

            
            
            
            if IsShiftKeyDown() then
                FillRaid()
                ReplaceDeadBot = {}
                resetData()
                UpdateReFillButtonVisibility()
                FillRaidFrame:Hide()
            end
        end)

		button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

			local labelText = button.originalText or ""
			local fullName = preset.fullname
			GameTooltip:SetText(fullName or labelText, 1, 0.82, 0) 

			local selectedValues = GetPresetValues(preset)

			if selectedValues then
				GameTooltip:AddLine(" ")

				for classRole, value in pairs(selectedValues) do
					if value and value > 0 then

						local spacePos = string.find(classRole, " ")

						local class, role

						if spacePos then
							class = string.sub(classRole, 1, spacePos - 1)
							role  = string.sub(classRole, spacePos + 1)
						else
							class = classRole
						end

						local coloredClass = GetColoredClass(classRole)

						if role then
							GameTooltip:AddLine(value .. " " .. coloredClass .. " (" .. role .. ")")
						else
							GameTooltip:AddLine(value .. " " .. coloredClass)
						end
					end
				end
			end

			GameTooltip:Show()
		end)

        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        
        
        
        if name ~= "PresetDungeounOther" then
            local tutorialInfo = GetTutorialLinkInfoForPreset(preset)
            if tutorialInfo then
                local tutorialButton = CreateFrame("Button", nil, frame)
                tutorialButton:SetWidth(tutorialButtonSize)
                tutorialButton:SetHeight(tutorialButtonSize)
                tutorialButton:SetPoint("LEFT", button, "RIGHT", 2, 0)

                local tutorialTexture = tutorialButton:CreateTexture(nil, "ARTWORK")
                tutorialTexture:SetWidth(tutorialButtonSize)
                tutorialTexture:SetHeight(tutorialButtonSize)
                tutorialTexture:SetPoint("CENTER", tutorialButton, "CENTER", 0, 0)
                tutorialTexture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
                tutorialButton.texture = tutorialTexture

                local tutorialHighlight = tutorialButton:CreateTexture(nil, "HIGHLIGHT")
                tutorialHighlight:SetAllPoints(tutorialButton)
                tutorialHighlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                tutorialHighlight:SetBlendMode("ADD")

                tutorialButton:SetScript("OnClick", function()
                    ShowTutorialLinkPopup(preset, tutorialInfo)
                end)

                tutorialButton:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(tutorialButton, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Tutorial Link")
                    GameTooltip:AddLine("Open a popup with faction/VIP-aware tutorial links.", 1, 1, 1, 1)
                    GameTooltip:Show()
                end)

                tutorialButton:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                tutorialButton.linkInfo = tutorialInfo
                table.insert(frame.tutorialButtons, tutorialButton)
                button.tutorialButton = tutorialButton
            end
        end

        table.insert(frame.presetButtons, {
            button = button,
            tutorialButton = button.tutorialButton,
            column = column,
            row = row,
            preset = preset,
        })
    end

    for index, preset in ipairs(presets) do
        CreatePresetButton(preset, index)
    end



if name ~= "PresetDungeounOther" then
    local othersIndex = table.getn(presets) + 1

    local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    button:SetWidth(buttonWidth)
    button:SetHeight(buttonHeight)

    local column = math.floor((othersIndex - 1) / maxButtonsPerColumn)
    local row = (othersIndex - 1) - column * maxButtonsPerColumn

    local yOffset = fixedStartY - (row * totalButtonHeight)

    button:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, yOffset)

    button:SetText("Others")

    
    frame.othersButton = button
    frame.othersButtonColumn = column
    frame.othersButtonRow = row

    
    if not OthersButtonEnabled then
        button:Hide()
    end

    button:SetScript("OnClick", function()
        frame:Hide()
        if instanceFrames and instanceFrames["PresetDungeounOther"] then
            instanceFrames["PresetDungeounOther"]:Show()
        end
    end)
end

    LayoutInstanceButtons()



function ToggleOthersButton(value)
    OthersButtonEnabled = value
    for _, frame in pairs(instanceFrames) do
        if frame.othersButton then
            if value then
                frame.othersButton:Show()
            else
                frame.othersButton:Hide()
            end
        end

        if frame.UpdateTutorialWidth then
            frame.UpdateTutorialWidth()
        end
    end
end




UpdateTutorialLinkButtons = function()
    local enabled = FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.showTutorialLinks

    if not instanceFrames then
        return
    end

    for _, frame in pairs(instanceFrames) do
        if frame.tutorialButtons then
            for _, tutorialButton in ipairs(frame.tutorialButtons) do
                if enabled then
                    tutorialButton:Show()
                else
                    tutorialButton:Hide()
                end
            end
        end

        if frame.UpdateTutorialWidth then
            frame.UpdateTutorialWidth(enabled)
        end
    end
end

function ToggleTutorialLinks(value)
    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    FillRaidBotsSavedSettings.showTutorialLinks = value and true or false

    if UpdateTutorialLinkButtons then
        UpdateTutorialLinkButtons()
    end
end

-- ==================
-- open zone presets
-- ==================
local ZoneToPreset = {
    ["Naxxramas"] = "PresetDungeounNaxxramas",
    ["Blackwing Lair"] = "PresetDungeounBWL",
    ["Molten Core"] = "PresetDungeounMC",
    ["Onyxia's Lair"] = "PresetDungeounOnyxia",
    ["Ahn'Qiraj"] = "PresetDungeounAQ40",      
    ["Ruins of Ahn'Qiraj"] = "PresetDungeounAQ20",
    ["Zul'Gurub"] = "PresetDungeounZG",
}
function OpenPresetForCurrentZone()
    local zone = GetRealZoneText()
    local frameName = ZoneToPreset[zone]

    if frameName then
        local frame = getglobal(frameName)
        if frame then
		    frame.headerText:SetText(zone)
            frame:Show()
			ClickBlockerFrame:Show() 
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("No preset mapped for this zone.")
    end
end	
-- ================================
-- add bots with a slash command --
-- ================================
local allPresets = {
    naxxramasPresets,
    bwlPresets,
    mcPresets,
    onyxiaPresets,
    aq40Presets,
    aq20Presets,
    ZGPresets,
    otherPresets
}

SLASH_FILLRAID1 = "/fillraid"

local function CollectMatchingPresets(msg, exactMatchOnly)
    local matches = {}
    local lowerMsg

    if not msg or type(msg) ~= "string" then
        return matches
    end

    lowerMsg = string.lower(strtrim(msg))
    if lowerMsg == "" then
        return matches
    end

    for _, presetTable in pairs(allPresets) do
        if type(presetTable) == "table" then
            for _, preset in ipairs(presetTable) do
                local matchFound = false

                if exactMatchOnly then
                    matchFound =
                        (preset.label and string.lower(strtrim(preset.label)) == lowerMsg) or
                        (preset.fullname and string.lower(strtrim(preset.fullname)) == lowerMsg)

                    if not matchFound and preset.bosses then
                        for _, bossName in ipairs(preset.bosses) do
                            if string.lower(strtrim(bossName)) == lowerMsg then
                                matchFound = true
                                break
                            end
                        end
                    end
                else
                    matchFound =
                        (preset.label and string.find(string.lower(preset.label), lowerMsg, 1, true)) or
                        (preset.fullname and string.find(string.lower(preset.fullname), lowerMsg, 1, true))

                    if not matchFound and preset.bosses then
                        for _, bossName in ipairs(preset.bosses) do
                            if string.find(string.lower(bossName), lowerMsg, 1, true) then
                                matchFound = true
                                break
                            end
                        end
                    end
                end

                if matchFound then
                    table.insert(matches, preset)
                end
            end
        end
    end

    return matches
end

local function ApplyPresetAndFill(preset)
    if not preset then
        QueueDebugMessage("FillRaid: ApplyPresetAndFill called with nil preset.", "debugerror")
        return
    end

    
    DEFAULT_CHAT_FRAME:AddMessage("Applying preset: " .. (preset.fullname or preset.label))
    QueueDebugMessage("FillRaid: Applying preset -> " .. (preset.fullname or preset.label), "debugfilling")

    for classRole, inputBox in pairs(inputBoxes) do
        if inputBox then
            inputBox:SetNumber(0)
            local onTextChanged = inputBox:GetScript("OnTextChanged")
            if onTextChanged then
                onTextChanged(inputBox)
            end
        end
    end

    currentLoadedPreset = preset
    ReapplyCurrentPreset()
    FillRaid()
end

_G.CollectMatchingPresets = CollectMatchingPresets
_G.ApplyPresetAndFill = ApplyPresetAndFill

SlashCmdList["FILLRAID"] = function(msg)
    if not msg or type(msg) ~= "string" or strtrim(msg) == "" then
        DEFAULT_CHAT_FRAME:AddMessage("Available presets:")

        for _, presetTable in pairs(allPresets) do
            if type(presetTable) == "table" then
                for _, preset in ipairs(presetTable) do
                    local displayText = preset.fullname or preset.label
                    if preset.bosses then
                        displayText = displayText .. " (" .. table.concat(preset.bosses, ", ") .. ")"
                    end
                    DEFAULT_CHAT_FRAME:AddMessage("- " .. displayText)
                end
            end
        end
        return
    end

    local matches = CollectMatchingPresets(msg)
    QueueDebugMessage("FillRaid: Search matches for '" .. msg .. "' -> " .. table.getn(matches), "debuginfo")

    if table.getn(matches) > 0 then
        ApplyPresetAndFill(matches[1])
        return
    end

    QueueDebugMessage("Error: Preset not found: " .. string.lower(msg), "debugerror")
end



    return frame
end




function ToggleClickToFill(isChecked)
    ClickToFillEnabled = isChecked 
end

local detectBossFrame = CreateFrame("Frame")

local lastDetectedBoss = nil
local keyPressCooldown = false
ClickToFillEnabled = ClickToFillEnabled or false

local function ResetCooldown()
    keyPressCooldown = false
    lastDetectedBoss = nil
end

local clickToFillChooser = CreateFrame("Frame", "FillRaidBotsClickToFillChooser", UIParent, "BackdropTemplate")
clickToFillChooser:SetWidth(210)
clickToFillChooser:SetHeight(46)
clickToFillChooser:SetFrameStrata("DIALOG")
clickToFillChooser:SetFrameLevel(120)
clickToFillChooser:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})

clickToFillChooser:SetBackdropColor(0, 0, 0, 0.95)
clickToFillChooser:EnableMouse(true)
clickToFillChooser:Hide()

local chooserLeftButton = CreateFrame("Button", nil, clickToFillChooser, "GameMenuButtonTemplate")
chooserLeftButton:SetWidth(95)
chooserLeftButton:SetHeight(24)
chooserLeftButton:SetPoint("LEFT", clickToFillChooser, "LEFT", 8, 0)

local chooserRightButton = CreateFrame("Button", nil, clickToFillChooser, "GameMenuButtonTemplate")
chooserRightButton:SetWidth(95)
chooserRightButton:SetHeight(24)
chooserRightButton:SetPoint("RIGHT", clickToFillChooser, "RIGHT", -8, 0)

local clickToFillListChooser = CreateFrame("Frame", "FillRaidBotsClickToFillListChooser", UIParent, "BackdropTemplate")
clickToFillListChooser:SetWidth(170)
clickToFillListChooser:SetHeight(40)
clickToFillListChooser:SetFrameStrata("DIALOG")
clickToFillListChooser:SetFrameLevel(160)
clickToFillListChooser:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
clickToFillListChooser:SetBackdropColor(0, 0, 0, 0.95)
clickToFillListChooser:EnableMouse(true)
clickToFillListChooser:Hide()

local clickToFillListButtons = {}
local chooserTimeoutToken = 0

local clickToFillListTitle = clickToFillListChooser:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
clickToFillListTitle:SetPoint("TOP", clickToFillListChooser, "TOP", 0, -8)
clickToFillListTitle:SetText("Choose preset")

local function HideClickToFillChooser()
    local i

    chooserTimeoutToken = chooserTimeoutToken + 1

    clickToFillChooser:Hide()
    clickToFillChooser.leftPreset = nil
    clickToFillChooser.rightPreset = nil
    clickToFillChooser.sourceText = nil

    clickToFillListChooser:Hide()
    clickToFillListChooser.sourceText = nil
    clickToFillListChooser.matches = nil

    for i = 1, table.getn(clickToFillListButtons) do
        clickToFillListButtons[i]:Hide()
        clickToFillListButtons[i].preset = nil
    end
end

local function StartClickToFillChooserTimeout()
    local token = chooserTimeoutToken + 1
    chooserTimeoutToken = token

    C_Timer.After(6, function()
        if chooserTimeoutToken == token and (clickToFillChooser:IsShown() or clickToFillListChooser:IsShown()) then
            QueueDebugMessage("Error: Chooser: Preset chooser timed out.", "debugerror")
            HideClickToFillChooser()
        end
    end)
end

local function GetClickToFillCursorPosition()
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()

    return cursorX / scale, cursorY / scale
end

local function PositionClickToFillChooser()
    local cursorX, cursorY = GetClickToFillCursorPosition()

    clickToFillChooser:ClearAllPoints()
    clickToFillChooser:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cursorX - 105, cursorY)
end

local function PositionClickToFillListChooser()
    local cursorX, cursorY = GetClickToFillCursorPosition()

    clickToFillListChooser:ClearAllPoints()
    clickToFillListChooser:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cursorX - 85, cursorY + 14)
end

local function ChooseClickToFillPreset(preset, sourceText)
    if not preset then
        HideClickToFillChooser()
        return
    end

    HideClickToFillChooser()
    keyPressCooldown = true
    lastDetectedBoss = sourceText or preset.label or preset.fullname
    QueueDebugMessage("Info: Chooser: Chosen zone preset -> " .. (preset.fullname or preset.label), "debuginfo")
    ApplyPresetAndFill(preset)
end

chooserLeftButton:SetScript("OnClick", function()
    ChooseClickToFillPreset(clickToFillChooser.leftPreset, clickToFillChooser.sourceText)
end)

chooserRightButton:SetScript("OnClick", function()
    ChooseClickToFillPreset(clickToFillChooser.rightPreset, clickToFillChooser.sourceText)
end)

local function GetOrCreateClickToFillListButton(index)
    local button

    if clickToFillListButtons[index] then
        return clickToFillListButtons[index]
    end

    button = CreateFrame("Button", nil, clickToFillListChooser, "GameMenuButtonTemplate")
    button:SetWidth(150)
    button:SetHeight(20)
    button:SetPoint("TOP", clickToFillListChooser, "TOP", 0, -24 - ((index - 1) * 22))
    button:SetScript("OnClick", function()
        ChooseClickToFillPreset(button.preset, clickToFillListChooser.sourceText)
    end)

    clickToFillListButtons[index] = button
    return button
end

local function ShowClickToFillChooser(matches, sourceText)
    local count = table.getn(matches)
    local i
    local button

    if count < 2 then
        return false
    end

    HideClickToFillChooser()

    if count == 2 then
        clickToFillChooser.leftPreset = matches[1]
        clickToFillChooser.rightPreset = matches[2]
        clickToFillChooser.sourceText = sourceText

        chooserLeftButton:SetText(matches[1].label or matches[1].fullname or "Preset 1")
        chooserRightButton:SetText(matches[2].label or matches[2].fullname or "Preset 2")

        PositionClickToFillChooser()
        clickToFillChooser:Show()
        StartClickToFillChooserTimeout()
        QueueDebugMessage("Info: Chooser: Two zone presets found for " .. sourceText .. ". Waiting for left/right choice.", "debuginfo")
        return true
    end

    clickToFillListChooser.sourceText = sourceText
    clickToFillListChooser.matches = matches
    clickToFillListTitle:SetText("Choose preset (" .. count .. ")")
    clickToFillListChooser:SetHeight(34 + (count * 22))

    for i = 1, count do
        button = GetOrCreateClickToFillListButton(i)
        button.preset = matches[i]
        button:SetText(matches[i].label or matches[i].fullname or ("Preset " .. i))
        button:Show()
    end

    for i = count + 1, table.getn(clickToFillListButtons) do
        clickToFillListButtons[i]:Hide()
        clickToFillListButtons[i].preset = nil
    end

    PositionClickToFillListChooser()
    clickToFillListChooser:Show()
    StartClickToFillChooserTimeout()
    QueueDebugMessage("Info: FillRaid: " .. count .. " zone presets found for " .. sourceText .. ". Waiting for popup list choice.", "debuginfo")
    return true
end








local function DetectBossAndFillRaid()
    if keyPressCooldown then return end
    if not (IsControlKeyDown() and IsAltKeyDown()) then return end

    local targetName = UnitName("target")
    local bossName = targetName or UnitName("mouseover")
    local zone = GetRealZoneText()
    local matches

    





    
    
    if targetName and UnitIsDead("target") then
        HideClickToFillChooser()
        keyPressCooldown = true
        QueueDebugMessage("FillRaid: Won't fill because target is dead -> " .. targetName .. " (probably already killed / misclick).", "debugfilling")
        return
    end

    
    if bossName then
        if bossName == "Ossirian the Unscarred" then
            bossName = "Ossirian"
        elseif bossName == "Lieutenant General Andorov" then
            bossName = "General Rajaxx"
        elseif bossName == "Vilebranch Speaker" then
            bossName = "Bloodlord Mandokir"
        elseif bossName == "Zealot Zath" then
            bossName = "High Priest Thekal"
        elseif bossName == "Zealot Lor'Khan" then
            bossName = "High Priest Thekal"
        end
    end
    
    
    if bossName then
        HideClickToFillChooser()
        if bossName ~= lastDetectedBoss then
            lastDetectedBoss = bossName
            keyPressCooldown = true
            QueueDebugMessage("FillRaid: Boss detected -> " .. bossName, "debuginfo")
            SlashCmdList["FILLRAID"](bossName)
        else
            QueueDebugMessage("FillRaid: Same boss, skipping -> " .. bossName, "debuginfo")
        end
        return
    
    
    elseif zone then
        
        if zone == "Onyxia's Lair" then
            zone = "Onyxia"
        end

        if CollectMatchingPresets then
            matches = CollectMatchingPresets(zone, true)
        elseif _G.CollectMatchingPresets then
            QueueDebugMessage("Info: Chooser: Using global CollectMatchingPresets fallback.", "debuginfo")
            matches = _G.CollectMatchingPresets(zone, true)
        else
            QueueDebugMessage("Error: Chooser: CollectMatchingPresets is missing.", "debugerror")
            matches = {}
        end

        QueueDebugMessage("Info: Chooser: Zone match count for " .. zone .. " -> " .. table.getn(matches), "debuginfo")

        if table.getn(matches) == 1 then
            HideClickToFillChooser()
            keyPressCooldown = true
            QueueDebugMessage("Info: Chooser: Single zone preset found -> " .. (matches[1].fullname or matches[1].label or zone), "debuginfo")
            ApplyPresetAndFill(matches[1])
            return
        elseif table.getn(matches) == 2 then
            QueueDebugMessage("Info: Chooser: Two zone presets found for " .. zone .. ". Showing left/right chooser.", "debuginfo")
            ShowClickToFillChooser(matches, zone)
            return
        elseif table.getn(matches) > 2 then
            QueueDebugMessage("Info: Chooser: " .. table.getn(matches) .. " zone presets found for " .. zone .. ". Showing popup list.", "debuginfo")
            ShowClickToFillChooser(matches, zone)
            return
        end

        HideClickToFillChooser()
        keyPressCooldown = true
        QueueDebugMessage("Info: Chooser: Zone fallback -> " .. zone .. " (no preset match)", "debuginfo")
        SlashCmdList["FILLRAID"](zone)
    end
end


detectBossFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
detectBossFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
detectBossFrame:RegisterEvent("MODIFIER_STATE_CHANGED")






detectBossFrame:SetScript("OnEvent", function(_, event, key, state)

    if event == "MODIFIER_STATE_CHANGED" then
        if IsControlKeyDown() and IsAltKeyDown() then
            
            if ClickToFillEnabled then
                DetectBossAndFillRaid()
            end
        else
            
            HideClickToFillChooser()
            ResetCooldown()
        end
        return
    end

    if ClickToFillEnabled then
        DetectBossAndFillRaid()
    else
        HideClickToFillChooser()
    end

end)






WorldFrame:HookScript("OnMouseDown", function(_, button)

    if not (IsControlKeyDown() and IsAltKeyDown()) then
        if clickToFillChooser:IsShown() then
            HideClickToFillChooser()
        end
    end

end)

function SavePresetValues()
    local missing = {}

    if not faction then
        table.insert(missing, "faction")
    end
    if not currentPresetName then
        table.insert(missing, "preset name")
    end
    if not currentInstanceName then
        table.insert(missing, "instance")
    end


    if #missing > 0 then
        local message = "Error: Missing " .. table.concat(missing, ", ") .. "."
        ShowStaticPopup(message, "Error") 
        return
    end


   
    if not FillRaidPresets[faction] then
        FillRaidPresets[faction] = {}
    end

    if not FillRaidPresets[faction][currentInstanceName] then
        FillRaidPresets[faction][currentInstanceName] = {}
    end

    local presetList = FillRaidPresets[faction][currentInstanceName]

   
    local presetIndex = nil
    for index, p in ipairs(presetList) do
        if p.label == currentPresetName then
            presetIndex = index
            break
        end
    end

    if not presetIndex then
        presetIndex = table.getn(presetList) + 1
        presetList[presetIndex] = {
            label = currentPresetName,
            values = {},
        }
    end







   
    local useVipPresets = FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.useVipPresets
    local targetValuesKey = useVipPresets and "vipValues" or "values"

    if type(presetList[presetIndex][targetValuesKey]) ~= "table" then
        presetList[presetIndex][targetValuesKey] = {}
    end

    for classRole, inputBox in pairs(inputBoxes) do
        if inputBox then
            local value = inputBox:GetText()
            local numValue = tonumber(value)
            if numValue and numValue > 0 then
                presetList[presetIndex][targetValuesKey][classRole] = numValue
            else
                presetList[presetIndex][targetValuesKey][classRole] = nil
            end
        end
    end

    ShowStaticPopup("Preset \"" .. currentPresetName .. "\" saved for |cff00ccff" .. faction .. "|r - |cff88ff88" .. currentInstanceName .. "|r", "Preset Saved")
end
    
    instanceFrames = {}

    instanceFrames["PresetDungeounNaxxramas"] = CreateInstanceFrame("PresetDungeounNaxxramas", naxxramasPresets)
    instanceFrames["PresetDungeounBWL"] = CreateInstanceFrame("PresetDungeounBWL", bwlPresets)
    instanceFrames["PresetDungeounMC"] = CreateInstanceFrame("PresetDungeounMC", mcPresets)
    instanceFrames["PresetDungeounOnyxia"] = CreateInstanceFrame("PresetDungeounOnyxia", onyxiaPresets)
    instanceFrames["PresetDungeounAQ40"] = CreateInstanceFrame("PresetDungeounAQ40", aq40Presets)
    instanceFrames["PresetDungeounAQ20"] = CreateInstanceFrame("PresetDungeounAQ20", aq20Presets)	
    instanceFrames["PresetDungeounZG"] = CreateInstanceFrame("PresetDungeounZG", ZGPresets)	
	instanceFrames["PresetDungeounOther"] = CreateInstanceFrame("PresetDungeounOther", otherPresets)

    if UpdateTutorialLinkButtons then
        UpdateTutorialLinkButtons()
    end

    
    local openPresetButton = CreateFrame("Button", "OpenPresetButton", FillRaidFrame, "GameMenuButtonTemplate")
    openPresetButton:SetWidth(80)
    openPresetButton:SetHeight(20)
    openPresetButton:SetText("Presets")
    openPresetButton:SetPoint("TOPRIGHT", FillRaidFrame, "TOPRIGHT", -10, -10)
    openPresetButton:SetScript("OnClick", function()
        if InstanceButtonsFrame:IsShown() then
            InstanceButtonsFrame:Hide()
            ClickBlockerFrame:Hide()
        else
            InstanceButtonsFrame:Show()
            ClickBlockerFrame:Show() 
        end
    end)
	

		

	
	local resetButton = CreateFrame("Button", nil, FillRaidFrame, "GameMenuButtonTemplate")
	resetButton:SetPoint("TOPRIGHT", FillRaidFrame, "TOPRIGHT", -10, -30)
	resetButton:SetWidth(80)
	resetButton:SetHeight(20)
	resetButton:SetText("Reset")
	resetButton:SetScript("OnClick", function()
		for _, inputBox in pairs(inputBoxes) do
			inputBox:SetNumber(0) 
			local onTextChanged = inputBox:GetScript("OnTextChanged")
			if onTextChanged then
				onTextChanged(inputBox) 
			end
		end

		totalBots = 0
		UpdateSpotsLeft() 
		roleCountsLabel:SetText("Tanks: 0 Healers: 0 Melee DPS: 0 Ranged DPS: 0")			

	end)


	  
	local ClickBlockerFrame = CreateFrame("Frame", "ClickBlockerFrame", UIParent)
	ClickBlockerFrame:SetAllPoints(UIParent) 
	ClickBlockerFrame:EnableMouse(true) 
	ClickBlockerFrame:SetFrameStrata("DIALOG") 
	ClickBlockerFrame:SetFrameLevel(1) 
	ClickBlockerFrame:SetScript("OnMouseDown", function()
		ClickBlockerFrame:Hide() 
		InstanceButtonsFrame:Hide() 
		UISettingsFrame:Hide()
		CreditsFrame:Hide()
		for frameName, frame in pairs(instanceFrames) do
			if frame:IsShown() then
				frame:Hide()
			end
		end
	end)
	ClickBlockerFrame:Hide() 


		
local openFillRaidButton = CreateFrame("Button", "OpenFillRaidButton", PCPFrame)  

FRB_openFillRaidButton = openFillRaidButton
openFillRaidButton:SetMovable(true)  
openFillRaidButton:EnableMouse(true)  


openFillRaidButton:SetUserPlaced(true)
openFillRaidButton:RegisterForDrag("LeftButton")  


local defaultPosition = {x = -20, y = 250}

local function GetPCPFrame()
    return PCPFrame or PCPFrameRemake
end



function InitializeButtonPosition()
    if not savedPositions["OpenFillRaidButton"] then
        local saved = FillRaidBotsSavedSettings.buttonPositionRelative
        if saved then
            savedPositions["OpenFillRaidButton"] = saved
        end
    end
    local savedPosition = savedPositions["OpenFillRaidButton"]
    local PCPVersionCheck = GetPCPFrame()

    local offsetX = 0
    local offsetY = 0

    if FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.buttonStyle then
        local styleKey = FillRaidBotsSavedSettings.buttonStyle
        for _, section in ipairs(SettingsConfig.sections) do
            for _, item in ipairs(section.items) do
                if item.type == "radio" and item.group == "buttonTheme" then
                    for _, option in ipairs(item.options) do
                        if option.key == styleKey then
                            offsetX = option.offsetX or 0
                            offsetY = option.offsetY or 0
                            break
                        end
                    end
                end
            end
        end
    end

    if PCPVersionCheck then
        openFillRaidButton:ClearAllPoints()

        if savedPosition and savedPosition.offsetX then
            local uiScale = UIParent:GetEffectiveScale()
            if FillRaidBotsSavedSettings.moveButtonsRelative then
                
                local pcp = PCPVersionCheck
                local pcpPhysX = pcp:GetLeft() * pcp:GetEffectiveScale()
                local pcpPhysY = pcp:GetTop()  * pcp:GetEffectiveScale()
                openFillRaidButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                    (pcpPhysX + savedPosition.offsetX) / uiScale,
                    (pcpPhysY + savedPosition.offsetY) / uiScale)
            elseif savedPosition.absX then
                
                openFillRaidButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                    savedPosition.absX / uiScale, savedPosition.absY / uiScale)
            end
        elseif PCPVersionCheck == PCPFrameRemake then
			
            openFillRaidButton:SetPoint("RIGHT", PCPVersionCheck, "LEFT",
                defaultPosition.x + 10 + offsetX, 100 + offsetY)
        else
            openFillRaidButton:SetPoint("CENTER", PCPVersionCheck, "LEFT",
                defaultPosition.x + offsetX, defaultPosition.y + offsetY)
        end
		
		
		
		
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
    end
end









function ToggleButtonMovement()
    local isFree     = FillRaidBotsSavedSettings.moveButtonsEnabled
    local isRelative = FillRaidBotsSavedSettings.moveButtonsRelative

    if isFree or isRelative then
        
        openFillRaidButton:SetParent(UIParent)
        openFillRaidButton:SetMovable(true)

        
        
        if openFillRaidButton:GetLeft() then
            local physX  = openFillRaidButton:GetLeft() * openFillRaidButton:GetEffectiveScale()
            local physY  = openFillRaidButton:GetTop()  * openFillRaidButton:GetEffectiveScale()
            local uiScale = UIParent:GetEffectiveScale()
            openFillRaidButton:ClearAllPoints()
            openFillRaidButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", physX / uiScale, physY / uiScale)
        end
		
		
		
        if isFree and openFillRaidButton:GetLeft() then
            local btnPhysX = openFillRaidButton:GetLeft() * openFillRaidButton:GetEffectiveScale()
            local btnPhysY = openFillRaidButton:GetTop()  * openFillRaidButton:GetEffectiveScale()

            local pcp = GetPCPFrame()
            if pcp then
                local pcpPhysX = pcp:GetLeft() * pcp:GetEffectiveScale()
                local pcpPhysY = pcp:GetTop()  * pcp:GetEffectiveScale()
                local offsetX  = btnPhysX - pcpPhysX
                local offsetY  = btnPhysY - pcpPhysY

                savedPositions["OpenFillRaidButton"] = {
                    offsetX = offsetX,
                    offsetY = offsetY,
                    absX = btnPhysX,
                    absY = btnPhysY
                }

                FillRaidBotsSavedSettings.buttonPositionRelative = {
                    offsetX = offsetX,
                    offsetY = offsetY,
                    absX = btnPhysX,
                    absY = btnPhysY
                }
            end
        end
        if isRelative then
            
            
            local pcp = GetPCPFrame()
            if pcp and openFillRaidButton:GetLeft() then
                local btnPhysX = openFillRaidButton:GetLeft() * openFillRaidButton:GetEffectiveScale()
                local btnPhysY = openFillRaidButton:GetTop()  * openFillRaidButton:GetEffectiveScale()
                local pcpPhysX = pcp:GetLeft() * pcp:GetEffectiveScale()
                local pcpPhysY = pcp:GetTop()  * pcp:GetEffectiveScale()
                local offsetX  = btnPhysX - pcpPhysX
                local offsetY  = btnPhysY - pcpPhysY
                savedPositions["OpenFillRaidButton"] = {offsetX = offsetX, offsetY = offsetY}
                FillRaidBotsSavedSettings.buttonPositionRelative = {offsetX = offsetX, offsetY = offsetY}
            end
        end

        openFillRaidButton:SetScript("OnDragStart", function(self)
            self:StartMoving()
            self.isMoving = true
        end)

        openFillRaidButton:SetScript("OnDragStop", function(self)
            
            local btnPhysX = self:GetLeft() * self:GetEffectiveScale()
            local btnPhysY = self:GetTop()  * self:GetEffectiveScale()
            self:StopMovingOrSizing()
            
            self:SetParent(UIParent)

            local uiScale = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", btnPhysX / uiScale, btnPhysY / uiScale)

            
            
            local pcp = GetPCPFrame()
            local pcpPhysX = pcp:GetLeft() * pcp:GetEffectiveScale()
            local pcpPhysY = pcp:GetTop()  * pcp:GetEffectiveScale()
            local offsetX  = btnPhysX - pcpPhysX
            local offsetY  = btnPhysY - pcpPhysY

            savedPositions["OpenFillRaidButton"] = {offsetX = offsetX, offsetY = offsetY, absX = btnPhysX, absY = btnPhysY}
            FillRaidBotsSavedSettings.buttonPositionRelative = {offsetX = offsetX, offsetY = offsetY, absX = btnPhysX, absY = btnPhysY}

            
            
            self.isMoving = false
        end)

        
        
        
        if isFree and FillRaidBotsSavedSettings.buttonMoveLocked then
            openFillRaidButton:SetScript("OnDragStart", nil)
            openFillRaidButton:SetScript("OnDragStop",  nil)
            openFillRaidButton:SetMovable(false)
        end

    else
        
        openFillRaidButton:SetScript("OnDragStart", nil)
        openFillRaidButton:SetScript("OnDragStop", nil)
        openFillRaidButton:SetMovable(false)
        savedPositions["OpenFillRaidButton"] = nil
        FillRaidBotsSavedSettings.buttonPosition = nil
        FillRaidBotsSavedSettings.buttonPositionRelative = nil
		
		
		
        local pcp    = GetPCPFrame()
        local layout = FillRaidBotsSavedSettings.ButtonLayout or "vertical"

		if layout == "horizontal" then
			if FRB_openFillRaidButton then FRB_openFillRaidButton:SetParent(UIParent) end
			if FRB_kickAllButton      then FRB_kickAllButton:SetParent(UIParent) end
			if FRB_reFillButton       then FRB_reFillButton:SetParent(UIParent) end

			ApplyButtonStyle(FillRaidBotsSavedSettings.selectedButtonTheme)
			UpdateButtonSizes()
		else
			if pcp then
				if FRB_openFillRaidButton then FRB_openFillRaidButton:SetParent(pcp) end
				if FRB_kickAllButton      then FRB_kickAllButton:SetParent(pcp) end
				if FRB_reFillButton       then FRB_reFillButton:SetParent(pcp) end
			end
		end


        InitializeButtonPosition()
    end
end


InitializeButtonPosition()
ToggleButtonMovement()






function ToggleButtonMoveLock(isLocked)
    local isFree = FillRaidBotsSavedSettings.moveButtonsEnabled

    
    
    if not isFree then
        if FRB_FreeModeLocBtn_Refresh then FRB_FreeModeLocBtn_Refresh() end
        return
    end

    if isLocked then
        openFillRaidButton:SetScript("OnDragStart", nil)
        openFillRaidButton:SetScript("OnDragStop",  nil)
        openFillRaidButton:SetMovable(false)
    else
        openFillRaidButton:SetMovable(true)

        openFillRaidButton:SetScript("OnDragStart", function(self)
            self:StartMoving()
            self.isMoving = true
        end)

        openFillRaidButton:SetScript("OnDragStop", function(self)
            local btnPhysX = self:GetLeft() * self:GetEffectiveScale()
            local btnPhysY = self:GetTop()  * self:GetEffectiveScale()
            self:StopMovingOrSizing()
            self:SetParent(UIParent)

            local uiScale = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", btnPhysX / uiScale, btnPhysY / uiScale)

            local pcp = GetPCPFrame()
            local pcpPhysX = pcp:GetLeft() * pcp:GetEffectiveScale()
            local pcpPhysY = pcp:GetTop()  * pcp:GetEffectiveScale()
            local offsetX  = btnPhysX - pcpPhysX
            local offsetY  = btnPhysY - pcpPhysY

            savedPositions["OpenFillRaidButton"] = {offsetX = offsetX, offsetY = offsetY, absX = btnPhysX, absY = btnPhysY}
            FillRaidBotsSavedSettings.buttonPositionRelative = {offsetX = offsetX, offsetY = offsetY, absX = btnPhysX, absY = btnPhysY}

            self.isMoving = false
        end)
    end

    if FRB_FreeModeLocBtn_Refresh then FRB_FreeModeLocBtn_Refresh() end
end





function openFillRaid()
    if FillRaidFrame:IsShown() then
        FillRaidFrame:Hide()
		ClickBlockerFrame:Hide() 
		InstanceButtonsFrame:Hide() 
		CreditsFrame:Hide()
		UISettingsFrame:Hide()
		for frameName, frame in pairs(instanceFrames) do
			if frame:IsShown() then
				frame:Hide()
			end
		end		
        fillRaidFrameManualClose = true
    else
        FillRaidFrame:Show()
        fillRaidFrameManualClose = false
        UpdateSpotsLeft() 
		if FillRaidBotsSavedSettings.isZonePresetsEnabled then
			OpenPresetForCurrentZone()			
		end			
		
    end
end




openFillRaidButton:SetScript("OnClick", function()
    if IsShiftKeyDown() then
        if debuggerFrame then
            if debuggerFrame:IsShown() then
                if SetDebuggerVisibility then SetDebuggerVisibility(false) end
                debuggerFrame:Hide()
            else
                if SetDebuggerVisibility then SetDebuggerVisibility(true) end
                debuggerFrame:Show()
            end
        end
        return
    end
	
	
	
	
	if UpdateTutorialLinkButtons then
		UpdateTutorialLinkButtons()
	end			
    openFillRaid()
end)


	openFillRaidButton:Hide()

	

	local kickAllButton = CreateFrame("Button", "KickAllButton", GetPCPFrame())
	
	FRB_kickAllButton = kickAllButton
	kickAllButton:SetScript("OnClick", function()
		UninviteAllRaidMembers()
		ReplaceDeadBot = {}
		resetData()
		UpdateReFillButtonVisibility()	
	end)
	kickAllButton:Hide() 

local reFillButton = CreateFrame("Button", "reFillButton", GetPCPFrame())

FRB_reFillButton = reFillButton
function ToggleSmallbuttonCheck(isChecked)
    SmallbuttonEnabled = isChecked
end

function ApplyButtonStyle(styleKey)
    local selectedStyle = nil

    
    local buttonThemeSection = nil
    for _, section in ipairs(SettingsConfig.sections) do
        for _, item in ipairs(section.items) do
            if item.type == "radio" and item.group == "buttonTheme" then
                buttonThemeSection = item
                break
            end
        end
        if buttonThemeSection then break end
    end

    if not buttonThemeSection then
        print("Fel: ButtonTheme-radio group saknas!")
        return
    end

    local options = buttonThemeSection.options or {}
    for _, style in ipairs(options) do
        if style.key == styleKey then
            selectedStyle = style
            break
        end
    end

    if not selectedStyle then return end
    local buttons = selectedStyle.buttons or {}

    
    if buttons.openFillRaidButton then
        openFillRaidButton:SetWidth(buttons.openFillRaidButton.width)
        openFillRaidButton:SetHeight(buttons.openFillRaidButton.height)
        openFillRaidButton:SetNormalTexture(buttons.openFillRaidButton.normal)
        openFillRaidButton:SetHighlightTexture(buttons.openFillRaidButton.highlight)
        openFillRaidButton:SetPushedTexture(buttons.openFillRaidButton.pushed)
    end

    
    if buttons.kickAllButton then
        kickAllButton:SetWidth(buttons.kickAllButton.width)
        kickAllButton:SetHeight(buttons.kickAllButton.height)
        kickAllButton:SetNormalTexture(buttons.kickAllButton.normal)
        kickAllButton:SetHighlightTexture(buttons.kickAllButton.highlight)
        kickAllButton:SetPushedTexture(buttons.kickAllButton.pushed)
    end

    
    if buttons.reFillButton then
        reFillButton:SetWidth(buttons.reFillButton.width)
        reFillButton:SetHeight(buttons.reFillButton.height)
        reFillButton:SetNormalTexture(buttons.reFillButton.normal)
        reFillButton:SetHighlightTexture(buttons.reFillButton.highlight)
        reFillButton:SetPushedTexture(buttons.reFillButton.pushed)
    end
end

function UpdateButtonSizes()
    if not FillRaidBotsSavedSettings then return end

    local pct = FillRaidBotsSavedSettings.ButtonSize or 100
    local themeKey = FillRaidBotsSavedSettings.selectedButtonTheme or "Mini"
    
    local defaultSize = GetThemeDefaultSize()
    local size = math.floor(defaultSize * (pct / 100) + 0.5)

    local w, h = size, size 

    
    for _, section in ipairs(SettingsConfig.sections) do
        for _, item in ipairs(section.items) do
            if item.type == "radio" and item.group == "buttonTheme" then
                for _, option in ipairs(item.options) do
                    if option.key == themeKey and option.buttons then
                        local btn = option.buttons.openFillRaidButton
                        if btn then
                            local origW = btn.width or 32
                            local origH = btn.height or 32

                            if origW >= origH then
                                
                                w = size
                                h = math.floor(size * (origH / origW) + 0.5)
                            else
                                
                                h = size
                                w = math.floor(size * (origW / origH) + 0.5)
                            end

                        end
                        break
                    end
                end
            end
        end
    end

    
    for _, btn in pairs({openFillRaidButton, kickAllButton, reFillButton}) do
        btn:SetWidth(w)
        btn:SetHeight(h)
    end

    RepositionButtonsFromOffset()
end








function ApplyButtonLayout(layout)
    FillRaidBotsSavedSettings.ButtonLayout = layout
    
    ToggleButtonMovement()

    RepositionButtonsFromOffset()
end

ToggleSmallbuttonCheck(SmallbuttonEnabled or false) 




ResetRefillLoopState = function()
    refillLoopRunning = false
    refillRecheckPending = false
    PendingRefill = {}
    refillFinalCheckPending = false
end

FinishRefillLoop = function()
    ResetRefillLoopState()
    ToggleSoundEffectsVolume("restore")
    UpdateReFillButtonVisibility()
end

function UpdateReFillButtonVisibility()
    if refillLoopRunning or next(ReplaceDeadBot) ~= nil or next(PendingRefill) ~= nil then
        if refillLoopRunning then
            reFillButton:Hide()
        else
            if FillRaidBotsSavedSettings.isRefillEnabled then
                reFillButton:Show()
            end
        end
    else
        reFillButton:Hide()
    end
end




local function GetRefillDelay()
    local maxBots = GetMaxBotsForCurrentZone()

    if maxBots == 39 then
        return 0
    elseif maxBots == 19 then
        return 0.3
    elseif maxBots == 14 then
        return 0.5
    elseif maxBots == 9 then
        return 0.5
    end

    return 0
end





local function GetRefillBatchLimit()
    local maxBots = GetMaxBotsForCurrentZone()

    if maxBots == 39 then
        return nil
    elseif maxBots == 19 then
        return 3
    elseif maxBots == 14 then
        return 2
    elseif maxBots == 9 then
        return 1
    end

    return 1
end

ScheduleRefillRecheck = function(delay)
    if refillRecheckPending then
        return
    end

    refillRecheckPending = true
    C_Timer.After(delay or 0.8, function()
        refillRecheckPending = false

        if not refillLoopRunning then
            UpdateReFillButtonVisibility()
            return
        end

        RecheckRefillState()
    end)
end

RecheckRefillState = function()
    local playerName, pendingData
    local retryCount = 0

    if not refillLoopRunning then
        return
    end

    UpdateGroupMembers()

    for playerName, pendingData in pairs(PendingRefill) do
        if not groupMembers[playerName] then
            PendingRefill[playerName] = nil
            QueueDebugMessage("Refill settled for: " .. playerName, "debugfilling")
        elseif GetTime() - pendingData.requestedAt >= 2.5 then
            if pendingData.attempts < 3 then
                ReplaceDeadBot[playerName] = pendingData.data
                retryCount = retryCount + 1
                QueueDebugMessage("Refill retry queued for: " .. playerName, "debugfilling")
            else
                QueueDebugMessage("Refill gave up after 3 attempts for: " .. playerName, "debugerror")
            end
            PendingRefill[playerName] = nil
        end
    end

    if next(ReplaceDeadBot) ~= nil then
        QueueDebugMessage("Refill pass incomplete, running another pass.", "debugfilling")
        RunRefillPass()
        return
    end

    if next(PendingRefill) ~= nil then
        QueueDebugMessage("Refill waiting for pending removals to settle.", "debugfilling")
        ScheduleRefillRecheck(0.8)
        return
    end

    if not refillFinalCheckPending then
        refillFinalCheckPending = true
        QueueDebugMessage("Refill looks complete, doing one final safety check.", "debugfilling")
        ScheduleRefillRecheck(0.6)
        return
    end

    QueueDebugMessage("Refill finished with no missing bots left.", "debugfilling")
    FinishRefillLoop()
end

RunRefillPass = function()
    local count = 0
    local delay
    local batchLimit = GetRefillBatchLimit()
    local playerName, data, pendingData

    if not refillLoopRunning then
        return
    end

    if next(ReplaceDeadBot) == nil then
        if next(PendingRefill) ~= nil then
            ScheduleRefillRecheck(0.8)
        else
            QueueDebugMessage("Refill complete. Replaced Bot List is empty.", "debugfilling")
            FinishRefillLoop()
        end
        return
    end

    QueueDebugMessage("Replaced Bot List:", "debugfilling")

    for playerName, data in pairs(ReplaceDeadBot) do
        if batchLimit and count >= batchLimit then
            break
        end

        if data and data.ClassNoColor and data.role then
            pendingData = PendingRefill[playerName]

            if pendingData then
                QueueDebugMessage("Refill already pending for: " .. playerName, "debugfilling")
            else
                count = count + 1
                QueueDebugMessage(playerName .. " - Class: " .. data.classColored .. ", Role: " .. data.role, "debugfilling")
                QueueMessage(".partybot add " .. data.ClassNoColor .. " " .. data.role, "SAY", true)

                PendingRefill[playerName] = {
                    data = data,
                    requestedAt = GetTime(),
                    attempts = (data._refillAttempts or 0) + 1
                }
                data._refillAttempts = PendingRefill[playerName].attempts
                ReplaceDeadBot[playerName] = nil
            end
        else
            ReplaceDeadBot[playerName] = nil
        end
    end

    QueueDebugMessage("Processed refill batch: " .. count, "debugfilling")

    
    delay = GetRefillDelay() + math.max(0, (count - 1) * 0.2)
    ScheduleRefillRecheck(delay)
end

function RefillBots()
    if refillLoopRunning then
        QueueDebugMessage("Refill already running.", "debugfilling")
        return
    end

    if next(ReplaceDeadBot) == nil and next(PendingRefill) == nil then
        QueueDebugMessage("Replaced Bot List is empty.", "debugfilling")
        UpdateReFillButtonVisibility()
        return
    end

    refillLoopRunning = true
    refillRecheckPending = false
    refillFinalCheckPending = false
    ToggleSoundEffectsVolume("lower")
    UpdateReFillButtonVisibility()

    if next(ReplaceDeadBot) ~= nil then
        RunRefillPass()
    else
        ScheduleRefillRecheck(0.2)
    end
end

reFillButton:SetScript("OnClick", RefillBots)

UpdateReFillButtonVisibility()
--=====================================================
-- GetButtonLayout - vertical or horizontal
--=====================================================
function GetButtonLayout()

    if FillRaidBotsSavedSettings
    and FillRaidBotsSavedSettings.ButtonLayout ~= nil then

        if FillRaidBotsSavedSettings.ButtonLayout == true then
            return "horizontal"
        end

        return FillRaidBotsSavedSettings.ButtonLayout
    end

    return "vertical"
end
-- =====================================================
-- Refractored to allow spacing from the UIsettings file
-- =====================================================


function GetButtonSpacing()
    
    if FillRaidBotsSavedSettings
    and FillRaidBotsSavedSettings.ButtonSpacing ~= nil then
        return FillRaidBotsSavedSettings.ButtonSpacing
    end

    
    local spacing = 10

    if FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.selectedButtonTheme then
        local styleKey = FillRaidBotsSavedSettings.selectedButtonTheme

        for _, section in ipairs(SettingsConfig.sections) do
            for _, item in ipairs(section.items) do
                if item.type == "radio" and item.group == "buttonTheme" then
                    for _, option in ipairs(item.options) do
                        if option.key == styleKey then
                            spacing = option.spacing or spacing
                            break
                        end
                    end
                end
            end
        end
    end

    return spacing
end






function RepositionButtonsFromOffset()
    if openFillRaidButton.isMoving then return end

    local savedPosition = savedPositions["OpenFillRaidButton"]
    local uiScale = UIParent:GetEffectiveScale()
    local layout = GetButtonLayout()
    local spacing = GetButtonSpacing()

    local pcp = GetPCPFrame()
    if not pcp then return end

    local pcpPhysX = pcp:GetLeft() * pcp:GetEffectiveScale()
    local pcpPhysY = pcp:GetTop()  * pcp:GetEffectiveScale()

    local handled = false

    if FillRaidBotsSavedSettings.moveButtonsRelative then
        
        if not savedPosition or not savedPosition.offsetX then return end

        openFillRaidButton:ClearAllPoints()
        openFillRaidButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
            (pcpPhysX + savedPosition.offsetX) / uiScale,
            (pcpPhysY + savedPosition.offsetY) / uiScale)

    elseif FillRaidBotsSavedSettings.moveButtonsEnabled then
        
        if not savedPosition or not savedPosition.absX then return end

        openFillRaidButton:ClearAllPoints()
        openFillRaidButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
            savedPosition.absX / uiScale,
            savedPosition.absY / uiScale)

    else



        if layout == "horizontal" then
            
            reFillButton:ClearAllPoints()
            reFillButton:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT",
                pcpPhysX / uiScale,
                pcpPhysY / uiScale)

            kickAllButton:ClearAllPoints()
            kickAllButton:SetPoint("RIGHT", reFillButton, "LEFT", -spacing, 0)

            openFillRaidButton:ClearAllPoints()
            openFillRaidButton:SetPoint("RIGHT", kickAllButton, "LEFT", -spacing, 0)

            handled = true
        end
    end
	
	
	
	
	
	if not handled then
		
		kickAllButton:ClearAllPoints()
		reFillButton:ClearAllPoints()

		if layout == "horizontal" then
			kickAllButton:SetPoint("LEFT", openFillRaidButton, "RIGHT", spacing, 0)
			reFillButton:SetPoint("LEFT", kickAllButton, "RIGHT", spacing, 0)
		else
			InitializeButtonPosition()
			kickAllButton:SetPoint("TOP", openFillRaidButton, "BOTTOM", 0, -spacing)
			reFillButton:SetPoint("TOP", kickAllButton, "BOTTOM", 0, -spacing)
		end
	end
end


local lastPcpPhysX, lastPcpPhysY

local visibilityFrame = CreateFrame("Frame")

visibilityFrame:SetScript("OnUpdate", function(self, elapsed)
	local PCPVersionCheck = GetPCPFrame()

	if PCPVersionCheck and PCPVersionCheck:IsVisible() then

		
		if not fillRaidFrameManualClose and not openFillRaidButton:IsShown() then
			openFillRaidButton:Show()
		end
		if not kickAllButton:IsShown() then
			kickAllButton:Show()
		end

		if not reFillButton:IsShown() then
			UpdateReFillButtonVisibility()
		end

		
		RepositionButtonsFromOffset()

		
		
		if not openFillRaidButton.isMoving then
			local pcpPhysX = PCPVersionCheck:GetLeft() * PCPVersionCheck:GetEffectiveScale()
			local pcpPhysY = PCPVersionCheck:GetTop()  * PCPVersionCheck:GetEffectiveScale()
			if pcpPhysX ~= lastPcpPhysX or pcpPhysY ~= lastPcpPhysY then
				lastPcpPhysX = pcpPhysX
				lastPcpPhysY = pcpPhysY
				RepositionButtonsFromOffset()
			end
		end

	else
		openFillRaidButton:Hide()
		kickAllButton:Hide()
		FillRaidFrame:Hide()
		fillRaidFrameManualClose = false
	end
end)
visibilityFrame:Show()

end


CreateFillRaidUI()
InitializeSettings()
InitializeButtonPosition() 


local fillRaidInitFrame = CreateFrame("Frame")
fillRaidInitFrame:RegisterEvent("PLAYER_LOGIN")
fillRaidInitFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")

    
	
    
    if FRB_openFillRaidButton then FRB_openFillRaidButton:SetParent(UIParent) end
    if FRB_kickAllButton      then FRB_kickAllButton:SetParent(UIParent) end
    if FRB_reFillButton       then FRB_reFillButton:SetParent(UIParent) end

    
    InitializeButtonPosition()
    ApplyButtonStyle(FillRaidBotsSavedSettings.selectedButtonTheme)
    UpdateButtonSizes() 
    RepositionButtonsFromOffset()

    
    
    
    
    ToggleButtonMovement()

    local isFree = FillRaidBotsSavedSettings.moveButtonsEnabled
    if isFree then
        
        
        local lockBtn = getglobal("FRB_FreeModeLocBtn")
        if lockBtn then lockBtn:Show() end
        if FRB_FreeModeLocBtn_Refresh then FRB_FreeModeLocBtn_Refresh() end
    else
        local lockBtn = getglobal("FRB_FreeModeLocBtn")
        if lockBtn then lockBtn:Hide() end
    end
end)


local messageCooldowns = {}
local SuppressBotMsgList = {}

local function removeColorCodes(message)
    
    return string.gsub(message, "|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function InitializeSuppressBotMsg()
    FillRaidSuppressBotMsg = FillRaidSuppressBotMsg or {}
    FillRaidSuppressBotMsg.messagesToHide = FillRaidSuppressBotMsg.messagesToHide or {}
    SuppressBotMsgList = FillRaidSuppressBotMsg.messagesToHide
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    InitializeSuppressBotMsg()
end)


local function shouldShowMessage(message)
    local currentTime = GetTime()
    local cleanMessage = removeColorCodes(message)

    for pattern, cooldown in pairs(SuppressBotMsgList) do
        if string.find(cleanMessage, pattern) then
            if cooldown == 0 then
                return false
            end

            local lastShown = messageCooldowns[pattern] or 0
            if currentTime - lastShown >= cooldown then
                messageCooldowns[pattern] = currentTime
                return true
            else
                return false
            end
        end
    end
    return true
end




local function HideBotMessages(self, message, r, g, b, id)
    
    if not FillRaidBotsSavedSettings.isBotMessagesEnabled then
        self:OriginalAddMessage(message, r, g, b, id)
        return
    end

    
    if not shouldShowMessage(message) then
        return 
    end

    self:OriginalAddMessage(message, r, g, b, id)
end


for i = 1, 7 do
    local chatFrame = getglobal("ChatFrame" .. i)
    if chatFrame and not chatFrame.OriginalAddMessage then
        chatFrame.OriginalAddMessage = chatFrame.AddMessage
        chatFrame.AddMessage = HideBotMessages
    end
end


function UninviteAllRaidMembers()
	local myName = UnitName("player")
	ResetStarterSequenceState()

	local function IsBotName(name)
		return name and string.find(name, "%*") ~= nil
	end


	local remainingMembers = {}
	for i = 1, GetNumGroupMembers() do
		local unit = IsInRaid() and "raid" .. tostring(i) or "party" .. tostring(i)
		local name = UnitName(unit)
		if name and name ~= myName then
			table.insert(remainingMembers, name)
		end
	end


	for i = #remainingMembers, 1, -1 do
		local name = remainingMembers[i]
		if name then
			if IsBotName(name) then
				if #remainingMembers > 1 then
					QueueDebugMessage("REMOVING BOT: " .. name, "debugremove")
					UninviteUnit(name)
					table.remove(remainingMembers, i)
				else
					QueueDebugMessage("INFO: Kept " .. name .. " to prevent disband.", "debugremove")
				end
			else
				QueueDebugMessage("SKIPPED REAL PLAYER: " .. name .. " (no *)", "debugremove")
			end
		else
			QueueDebugMessage("ERROR: Unknown or nil player in group slot " .. i, "debugremove")
		end
	end
end

local c = 0



function GetThemeDefaultSize()

    local themeKey = FillRaidBotsSavedSettings.selectedButtonTheme or "Mini"

    for _, section in ipairs(SettingsConfig.sections) do
        for _, item in ipairs(section.items) do
            if item.type == "radio" and item.group == "buttonTheme" then
                for _, option in ipairs(item.options) do
                    if option.key == themeKey and option.buttons then
                        local btn = option.buttons.openFillRaidButton
                        if btn then
                            local w = btn.width or 32
                            local h = btn.height or 32
                            return math.max(w, h) 
                        end
                    end
                end
            end
        end
    end

    return 40
end





function FillRaidBots_ResetButtonPositions()

    FillRaidBotsSavedSettings.buttonMoveModeFixed    = true
    FillRaidBotsSavedSettings.buttonModeMoveFree     = false
    FillRaidBotsSavedSettings.buttonMoveModeRelative = false
    FillRaidBotsSavedSettings.moveButtonsEnabled     = false
    FillRaidBotsSavedSettings.moveButtonsRelative    = false

    savedPositions["OpenFillRaidButton"] = nil
    FillRaidBotsSavedSettings.buttonPosition = nil
    FillRaidBotsSavedSettings.buttonPositionRelative = nil

    
    
    FillRaidBotsSavedSettings.ButtonSize = 100

    
    FillRaidBotsSavedSettings.ButtonSpacing = 4
    FillRaidBotsSavedSettings.ButtonLayout = "vertical"

    
    
    
    
    
    
    if FRB_openFillRaidButton then FRB_openFillRaidButton:SetParent(UIParent) end
    if FRB_kickAllButton      then FRB_kickAllButton:SetParent(UIParent) end
    if FRB_reFillButton       then FRB_reFillButton:SetParent(UIParent) end

    if ApplySavedSettings then
        ApplySavedSettings()
    end

    
    
    
    local layoutCb = GetSettingsCheckbox("ButtonLayout")
    if layoutCb then
        layoutCb:SetChecked(FillRaidBotsSavedSettings.ButtonLayout == "horizontal")
    end

    
    
    InitializeButtonPosition()
    ApplyButtonStyle(FillRaidBotsSavedSettings.selectedButtonTheme)
    UpdateButtonSizes()
    RepositionButtonsFromOffset()

    DEFAULT_CHAT_FRAME:AddMessage("FillRaidBots: Buttons reset to theme default.", 0.0, 1.0, 0.0)

    
    FillRaidBotsSavedSettings.buttonMoveLocked = false
    if FRB_ResetLockButton then FRB_ResetLockButton() end
    if ToggleButtonMoveLock then ToggleButtonMoveLock(false) end

end

SLASH_FRB1 = "/frb"
SlashCmdList["FRB"] = function(cmd)
    cmd = cmd and string.lower(strtrim(cmd)) or ""

    if cmd == "ua" or cmd == "uninvite all" then
        UninviteAllRaidMembers()
    elseif cmd == "open" then
        openFillRaid()
    elseif cmd == "refill" then
        RefillBots()
    elseif cmd == "fixgroups" then
        isFixingGroups = true
        currentPhase = 1
        lastMoveTime = 0
        moveQueue = {}
        FixGroups()
	elseif cmd == "list" then
        SlashCmdList["FILLRAID"]("")
    
    elseif cmd == "resetbuttons" then
        FillRaidBots_ResetButtonPositions()
    else
       
        if cmd == "" or cmd == "help" then
            DEFAULT_CHAT_FRAME:AddMessage("FillRaidBots Commands:", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb ua - Uninvite all non-guild/friend raid members", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb (preset name) - Fill raid with optimal composition", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb list - lists all presets", 1.0, 1.0, 0.0)			
            DEFAULT_CHAT_FRAME:AddMessage("/frb open - Toggle FillRaid window", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb refill - Replace recently removed bots", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb fixgroups - Reorganize raid groups", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb resetbuttons - Reset button position to default", 1.0, 1.0, 0.0) 

        else
           
			ReplaceDeadBot = {}
			resetData()
			UpdateReFillButtonVisibility()
            SlashCmdList["FILLRAID"](cmd)
        end
    end
end
--------------------------------------------------------------------------------------------------------------------
local function ShowVersionPopupOnce()
    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

   
    if FillRaidBotsSavedSettings.lastPopupVersionSeen ~= versionNumber then
	local versionDetails = {
		{"Fast Fill", "Hold Ctrl + Alt and click a boss to automatically fill using presets."},
		{"Refill System", "Automatically replaces dead bots until your group is full again."},
		{"Auto Remove", "Automatically removes the starter bot and dead bots."},
		{"Auto Repair", "Automatically repairs after resurrection (VIP only)."},
		{"Auto Join Guild", "Joins SoloCraft automatically if you are not in a guild."},

		{"Party Bots", "Adding fewer than 5 bots keeps the group as a party."},
		{"Edit Presets In-Game", "Edit and save presets directly in-game."},
		{"VIP Presets", "Use enhanced preset values when VIP mode is enabled."},

		{"Tutorial Links", "Optional in-game boss guides with multiple sources and fallback support."},
		{"Export / Import", "Share presets between accounts using export/import."},

		{"Customizable Buttons", "Move, resize, and change button layouts in settings."},

		{"Reload UI", "Reload UI using /rl or /reload without /console."},
		{"Release Notes", "Shown once after updating to a new version."},
		{"Other Fixes", "Improved \"raid filling complete\" accuracy."}
	}

       
        local message = "|cffffff00FillRaidBots v" .. versionNumber .. "|r\n\n"

       
        for _, details in ipairs(versionDetails) do
            local headline = details[1]
            local content = details[2]
            message = message .. "|cffffff00" .. headline .. "|r:\n" .. content .. "\n\n"
        end

       
        ShowStaticPopup(message, nil, false)
        
       
        FillRaidBotsSavedSettings.lastPopupVersionSeen = versionNumber
    end
end


local popupFrame = CreateFrame("Frame")
popupFrame:RegisterEvent("PLAYER_LOGIN")
popupFrame:SetScript("OnEvent", function()
    ShowVersionPopupOnce()
end)

frbGITHUB_URL = "https://github.com/pumpan/FillRaidBots-Client-1.14"
frbUpdateVersionPopup = frbUpdateVersionPopup or nil
frbUpdateVersionPopupLinkBox = frbUpdateVersionPopupLinkBox or nil
frbUpdateVersionPopupCurrentText = frbUpdateVersionPopupCurrentText or nil
frbUpdateVersionPopupLatestText = frbUpdateVersionPopupLatestText or nil
frbVersionClickButton = frbVersionClickButton or nil

function HasTrackedUpdateVersion()
    if not FillRaidBotsSavedSettings then
        return false
    end
    if not FillRaidBotsSavedSettings.lastNotifiedVersion or FillRaidBotsSavedSettings.lastNotifiedVersion == "" then
        return false
    end
    return isNewerVersion(versionNumber, FillRaidBotsSavedSettings.lastNotifiedVersion)
end

function EnsureUpdateVersionPopup()
    if frbUpdateVersionPopup then
        return frbUpdateVersionPopup
    end

    frbUpdateVersionPopup = CreateFrame("Frame", "FillRaidBotsUpdateVersionPopup", UIParent, "BackdropTemplate")
    frbUpdateVersionPopup:SetWidth(460)
    frbUpdateVersionPopup:SetHeight(180)
    frbUpdateVersionPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frbUpdateVersionPopup:SetFrameStrata("DIALOG")
    frbUpdateVersionPopup:SetMovable(true)
    frbUpdateVersionPopup:EnableMouse(true)
    frbUpdateVersionPopup:RegisterForDrag("LeftButton")
    frbUpdateVersionPopup:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frbUpdateVersionPopup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frbUpdateVersionPopup:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frbUpdateVersionPopup:SetBackdropColor(0, 0, 0, 1)
    frbUpdateVersionPopup:Hide()
    table.insert(UISpecialFrames, "FillRaidBotsUpdateVersionPopup")

    frbUpdateVersionPopup.header = frbUpdateVersionPopup:CreateTexture(nil, "ARTWORK")
    frbUpdateVersionPopup.header:SetWidth(220)
    frbUpdateVersionPopup.header:SetHeight(64)
    frbUpdateVersionPopup.header:SetPoint("TOP", frbUpdateVersionPopup, 0, 18)
    frbUpdateVersionPopup.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    frbUpdateVersionPopup.header:SetVertexColor(.2, .2, .2)

    frbUpdateVersionPopup.headerText = frbUpdateVersionPopup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frbUpdateVersionPopup.headerText:SetPoint("TOP", frbUpdateVersionPopup.header, 0, -14)
    frbUpdateVersionPopup.headerText:SetText("Update Available")

    frbUpdateVersionPopupCurrentText = frbUpdateVersionPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frbUpdateVersionPopupCurrentText:SetPoint("TOPLEFT", frbUpdateVersionPopup, "TOPLEFT", 20, -42)
    frbUpdateVersionPopupCurrentText:SetJustifyH("LEFT")

    frbUpdateVersionPopupLatestText = frbUpdateVersionPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frbUpdateVersionPopupLatestText:SetPoint("TOPLEFT", frbUpdateVersionPopupCurrentText, "BOTTOMLEFT", 0, -12)
    frbUpdateVersionPopupLatestText:SetJustifyH("LEFT")

    frbUpdateVersionPopup.linkLabel = frbUpdateVersionPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frbUpdateVersionPopup.linkLabel:SetPoint("TOPLEFT", frbUpdateVersionPopupLatestText, "BOTTOMLEFT", 0, -18)
    frbUpdateVersionPopup.linkLabel:SetJustifyH("LEFT")
    frbUpdateVersionPopup.linkLabel:SetText("GitHub:")

    frbUpdateVersionPopupLinkBox = CreateFrame("EditBox", "frbUpdateVersionPopupLinkBox", frbUpdateVersionPopup, "InputBoxTemplate")
    frbUpdateVersionPopupLinkBox:SetPoint("TOPLEFT", frbUpdateVersionPopup.linkLabel, "BOTTOMLEFT", 0, -6)
    frbUpdateVersionPopupLinkBox:SetWidth(410)
    frbUpdateVersionPopupLinkBox:SetHeight(20)
    frbUpdateVersionPopupLinkBox:SetAutoFocus(false)
    frbUpdateVersionPopupLinkBox:SetText(frbGITHUB_URL)
    frbUpdateVersionPopupLinkBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:HighlightText(0, 0)
    end)
    frbUpdateVersionPopupLinkBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    frbUpdateVersionPopupLinkBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    frbUpdateVersionPopup.okButton = CreateFrame("Button", nil, frbUpdateVersionPopup, "UIPanelButtonTemplate")
    frbUpdateVersionPopup.okButton:SetWidth(100)
    frbUpdateVersionPopup.okButton:SetHeight(22)
    frbUpdateVersionPopup.okButton:SetPoint("BOTTOMRIGHT", frbUpdateVersionPopup, "BOTTOMRIGHT", -20, 16)
    frbUpdateVersionPopup.okButton:SetText("OK")
    frbUpdateVersionPopup.okButton:SetScript("OnClick", function()
        frbUpdateVersionPopup:Hide()
    end)

    frbUpdateVersionPopup.ignoreButton = CreateFrame("Button", nil, frbUpdateVersionPopup, "UIPanelButtonTemplate")
    frbUpdateVersionPopup.ignoreButton:SetWidth(140)
    frbUpdateVersionPopup.ignoreButton:SetHeight(22)
    frbUpdateVersionPopup.ignoreButton:SetPoint("RIGHT", frbUpdateVersionPopup.okButton, "LEFT", -10, 0)
    frbUpdateVersionPopup.ignoreButton:SetText("Ignore this version")
    frbUpdateVersionPopup.ignoreButton:SetScript("OnClick", function()
        if not FillRaidBotsSavedSettings then
            FillRaidBotsSavedSettings = {}
        end
        if HasTrackedUpdateVersion() then
            FillRaidBotsSavedSettings.ignoredUpdateVersion = FillRaidBotsSavedSettings.lastNotifiedVersion
        end
        frbUpdateVersionPopup:Hide()
    end)

    return frbUpdateVersionPopup
end

function ShowUpdateVersionPopup()
    EnsureUpdateVersionPopup()
    frbUpdateVersionPopupCurrentText:SetText("You are using: " .. versionNumber)
    frbUpdateVersionPopupLatestText:SetText("Latest version: " .. (FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.lastNotifiedVersion or versionNumber))
    frbUpdateVersionPopupLinkBox:SetText(frbGITHUB_URL)
    frbUpdateVersionPopupLinkBox:ClearFocus()
    frbUpdateVersionPopupLinkBox:HighlightText(0, 0)
    frbUpdateVersionPopup:Show()
end

function MaybeShowUpdateVersionPopup()
    if not HasTrackedUpdateVersion() then
        return
    end
    if FillRaidBotsSavedSettings.ignoredUpdateVersion == FillRaidBotsSavedSettings.lastNotifiedVersion then
        return
    end
    ShowUpdateVersionPopup()
end

function HookVersionTextUpdatePopup()
    if not FillRaidFrame or not FillRaidBotsVersionText then
        return
    end
    if frbVersionClickButton then
        return
    end
    frbVersionClickButton = CreateFrame("Button", "frbVersionClickButton114", FillRaidFrame)
    frbVersionClickButton:SetPoint("TOPLEFT", FillRaidBotsVersionText, "TOPLEFT", -4, 2)
    frbVersionClickButton:SetPoint("BOTTOMRIGHT", FillRaidBotsVersionText, "BOTTOMRIGHT", 4, -2)
    frbVersionClickButton:EnableMouse(true)
    frbVersionClickButton:RegisterForClicks("LeftButtonUp")
    frbVersionClickButton:SetScript("OnClick", function()
        ShowUpdateVersionPopup()
    end)
    frbVersionClickButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Click to show update info.")
        GameTooltip:Show()
    end)
    frbVersionClickButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local frbUpdatePopupInitFrame = CreateFrame("Frame")
frbUpdatePopupInitFrame:RegisterEvent("PLAYER_LOGIN")
frbUpdatePopupInitFrame:SetScript("OnEvent", function()
    HookVersionTextUpdatePopup()
    MaybeShowUpdateVersionPopup()
end)
-- ================== ==
-- Daily tips in chat --
-- =====================
local function ShowDailyTipInChat()
	if not DailyTipEnabled then return end

    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    local today = date("%Y-%m-%d")
    if FillRaidBotsSavedSettings.lastDailyTipDate == today then
        return
    end

    C_Timer.After(15, function()

	local CMD  = "|cff00ccff"   
	local FEAT = "|cff00ff00"   
	local END  = "|r"

	local tips = {
		"Adding fewer than 5 bots keeps you in party mode.",
		"Large fills (5+ bots) automatically convert your group to a raid.",
		"Auto Repair works automatically if you're VIP.",
		"You can edit presets directly in-game.",
		"Use SuppressEditor to silence bot spam.",
		"Dead bots are automatically replaced when using Refill.",
		"Refill continues until all dead bots are replaced.",

		"Use " .. CMD .. "/frb help" .. END .. " to see available commands.",
		"Use " .. FEAT .. "Fast Fill" .. END .. " (Ctrl + Alt + click a boss) to automatically fill the raid.",
		"Fast Fill will not trigger if the target is already dead.",
		"You can use boss, mob, or instance names in presets for Fast Fill.",
		"You can use instance names to create default presets.",

		"Kick All will not remove real players.",
		"Use " .. CMD .. "/frb fixgroups" .. END .. " to rebalance raid groups.",
		"Use " .. CMD .. "/frb refill" .. END .. " to instantly replace dead bots.",

		"You can export and import presets between accounts.",
		"VIP presets can override normal presets if enabled.",
		"You must be leader or assistant for some features to work.",
		"Zone-based presets automatically adjust raid size limits.",

		"You can move and resize buttons in the settings.",
		"You can enable tutorial links in settings to see boss guides.",
		"Negative button spacing allows compact layouts.",
		"Enable the debugger in settings for advanced troubleshooting.",

		"Support the addon to get your name in the credits."
	}

        if not FillRaidBotsSavedSettings.usedDailyTips then
            FillRaidBotsSavedSettings.usedDailyTips = {}
        end

        local used = FillRaidBotsSavedSettings.usedDailyTips
        local availableIndexes = {}

        for i = 1, #tips do
            if not used[i] then
                table.insert(availableIndexes, i)
            end
        end

        if #availableIndexes == 0 then
            FillRaidBotsSavedSettings.usedDailyTips = {}
            used = FillRaidBotsSavedSettings.usedDailyTips

            for i = 1, #tips do
                table.insert(availableIndexes, i)
            end
        end

        local randomPoolIndex = math.random(1, #availableIndexes)
        local selectedTipIndex = availableIndexes[randomPoolIndex]
        local selectedTip = tips[selectedTipIndex]

        used[selectedTipIndex] = true
        FillRaidBotsSavedSettings.lastDailyTipDate = today

        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[FillRaidBots Tip]|r " .. selectedTip)

    end)
end

--------------------------------------------------------------------------------------------------------------------


local Guard = string.format("%d.%d.%d", a, b, c)

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_LOGIN")


FillRaidBotsSavedSettings = FillRaidBotsSavedSettings or {}
FillRaidBotsSavedSettings.userCount = FillRaidBotsSavedSettings.userCount or 0
FillRaidBotsSavedSettings.uniqueUsers = FillRaidBotsSavedSettings.uniqueUsers or {}


local SessionUniqueUsers = {}


local function generateUserID()
    return math.random(1000000, 9999999)  
end


local function registerAddonPrefix()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(addonPrefix) then
        C_ChatInfo.RegisterAddonMessagePrefix(addonPrefix)
    end
end

local function sendVersionMessage(version, userID)
    
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(addonPrefix) then
        QueueDebugMessage("ERROR: Addon prefix not registered: " .. addonPrefix, "debugversion")
        return
    end
    
    if not IsInGuild() then
        QueueDebugMessage("ERROR: Cannot send version message. You are not in a guild.", "debugversion")
        return
    end

    
    local message = version .. ";" .. userID
    
    C_ChatInfo.SendAddonMessage(addonPrefix, message, "GUILD")

    
    QueueDebugMessage("INFO: Version message sent successfully to GUILD. Message: " .. message, "debugversion")
	newversion()
end


local function OnEvent(self, event, ...)
   

    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
       
      

        QueueDebugMessage("Addon message received. Prefix: " .. prefix .. ", Sender: " .. sender .. ", Message: " .. message, "debugversion")

        if prefix == addonPrefix then
            QueueDebugMessage("Received addon message from " .. sender .. ": " .. message, "debugversion")
        else
            QueueDebugMessage("Received message with incorrect prefix: " .. prefix, "debugversion")
        end
    elseif event == "PLAYER_LOGIN" then
       
        registerAddonPrefix()  
        local userID = generateUserID()
			if versionNumber == Guard then
				sendVersionMessage(versionNumber, userID)
			else
				QueueDebugMessage("ERROR: A, a, a, you didnt say the magic word.", "debugversion")
			end
    end
end



C_ChatInfo.RegisterAddonMessagePrefix(addonPrefix)
QueueDebugMessage("INFO: Addon prefix registered:" .. addonPrefix, "debugversion")

local function strsplit(delimiter, input)
    local result = {}
    local start_pos = 1
    local delim_pos = strfind(input, delimiter, start_pos)
    
    while delim_pos do
        
        local part = strsub(input, start_pos, delim_pos - 1)  
        table.insert(result, part)  
        
        
        start_pos = delim_pos + 1  
        
        
        delim_pos = strfind(input, delimiter, start_pos)  
    end

    
    local last_part = strsub(input, start_pos)
    table.insert(result, last_part)

    return unpack(result)  
end





local function splitVersion(version)
    local major, minor, patch = 0, 0, 0
    local dot1 = strfind(version, "%.")
    local dot2 = dot1 and strfind(version, "%.", dot1 + 1)

    if dot1 then
        major = tonumber(strsub(version, 1, dot1 - 1)) or 0
        if dot2 then
            minor = tonumber(strsub(version, dot1 + 1, dot2 - 1)) or 0
            patch = tonumber(strsub(version, dot2 + 1)) or 0
        else
            minor = tonumber(strsub(version, dot1 + 1)) or 0
        end
    else
        major = tonumber(version) or 0
    end

    return major, minor, patch
end


function isNewerVersion(current, received)
    local cMajor, cMinor, cPatch = splitVersion(current)
    local rMajor, rMinor, rPatch = splitVersion(received)

    if rMajor > cMajor then
        return true
    elseif rMajor == cMajor and rMinor > cMinor then
        return true
    elseif rMajor == cMajor and rMinor == cMinor and rPatch > cPatch then
        return true
    end

    return false
end

local SessionUserID



local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_ADDON")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
		ShowDailyTipInChat()
        if not FillRaidBotsSavedSettings.userID then
            FillRaidBotsSavedSettings.userID = generateUserID()
        end
        SessionUserID = FillRaidBotsSavedSettings.userID  

        if not FillRaidBotsSavedSettings.lastNotifiedVersion then
            FillRaidBotsSavedSettings.lastNotifiedVersion = versionNumber  
        end
        if not FillRaidBotsSavedSettings.userCount or FillRaidBotsSavedSettings.userCount == "" then
            FillRaidBotsSavedSettings.userCount = 0
        end
        if not FillRaidBotsSavedSettings.uniqueUsers then
            FillRaidBotsSavedSettings.uniqueUsers = {}
        end

        
        QueueDebugMessage(addonName .. " loaded. Current version: " .. versionNumber, "debuginfo")
        QueueDebugMessage("INFO: Total unique users detected: " .. FillRaidBotsSavedSettings.userCount, "debuginfo")
        QueueDebugMessage("Userid: " .. SessionUserID, "debuginfo")
        
        
        if isNewerVersion(versionNumber, FillRaidBotsSavedSettings.lastNotifiedVersion) then
            QueueDebugMessage("INFO: New update available: " .. FillRaidBotsSavedSettings.lastNotifiedVersion, "debuginfo")
            sendVersionMessage(FillRaidBotsSavedSettings.lastNotifiedVersion, SessionUserID)  
            newversion(FillRaidBotsSavedSettings.lastNotifiedVersion) 
            MaybeShowUpdateVersionPopup()
        else
			if versionNumber == Guard then
				sendVersionMessage(versionNumber, SessionUserID)
			else
				QueueDebugMessage("ERROR: A, a, a, you didnt say the magic word.", "debugversion")
			end
        end

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, sender = ...

        if prefix == addonPrefix then
            if sender ~= UnitName("player") then
                
                if not message or message == "" then
                    QueueDebugMessage("ERROR: Received an empty or nil message", "debugversion")
                    return
                end
                
                
                local receivedVersion, userID = strsplit(";", message)

                
                QueueDebugMessage("ReceivedVersion: [" .. receivedVersion .. "], from userID: [" .. tostring(userID) .. "]", "debugversion")

                
                if not tonumber(userID) then
                    QueueDebugMessage("ERROR: UserID is not a valid number: " .. tostring(userID), "debugversion")
                    return
                end

                
                local versionPattern = "^%d+%.%d+%.%d+$"
                if not strfind(receivedVersion, versionPattern) then
                    QueueDebugMessage("ERROR: Version format is invalid: " .. tostring(receivedVersion), "debugversion")
                    return
                end

                
                if not SessionUniqueUsers[userID] and not FillRaidBotsSavedSettings.uniqueUsers[userID] then
                    SessionUniqueUsers[userID] = true
                    FillRaidBotsSavedSettings.uniqueUsers[userID] = true
                    FillRaidBotsSavedSettings.userCount = FillRaidBotsSavedSettings.userCount + 1
                    QueueDebugMessage("INFO: New user detected. Total unique users: " .. FillRaidBotsSavedSettings.userCount, "debugversion")
                end

                
                if isNewerVersion(versionNumber, receivedVersion) then
                    local lastNotifiedVersion = FillRaidBotsSavedSettings.lastNotifiedVersion or ""
                    if isNewerVersion(lastNotifiedVersion, receivedVersion) then
                        QueueDebugMessage("INFO: New version detected: " .. receivedVersion, "debuginfo")
                        FillRaidBotsSavedSettings.lastNotifiedVersion = receivedVersion
                        sendVersionMessage(receivedVersion, SessionUserID)  
                        newversion(receivedVersion) 
                        MaybeShowUpdateVersionPopup()
                    else
                        QueueDebugMessage("INFO: Version " .. receivedVersion .. " already notified.", "debugversion")
                        MaybeShowUpdateVersionPopup()						
                    end
                else
                    QueueDebugMessage("INFO: Your version is up to date.", "debugversion")
					FillRaidBotsSavedSettings.lastNotifiedVersion = receivedVersion
                end
            end
        end
    end
end)



SLASH_RL1 = "/rl"
SLASH_RL2 = "/reload"
SLASH_RL3 = "/reloadui"
SlashCmdList["RL"] = function()
    ReloadUI()
end



----------------------------------------------------------------------------------------------------------------------
