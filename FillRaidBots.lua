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
local versionNumber = "4.0.0"
local a = "4"
local botCount = 0
local initialBotRemoved = false
firstBotName = nil
local messageQueue = {}
local DebugMessageQueue = {}
local delay = 0.1 
local nextUpdateTime = 0 

local classCounts = {}
local FillRaidFrame 
local fillRaidFrameManualClose = false 
local isCheckAndRemoveEnabled = false

if FillRaidBotsSavedSettings == nil then
    FillRaidBotsSavedSettings = {}
end


local function InitializeSettings()
    
    if FillRaidBotsSavedSettings.isCheckAndRemoveEnabled == nil then
        FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = false  
    end
end

function ToggleAutoRepair(isChecked)
    AutoRepairEnabled = isChecked 
end
function ToggleAutoJoinGuild(isChecked)
    AutoJoinGuildEnabled = isChecked 
end
function ToggleAutoMuteSound(isChecked)
    AutoMuteSoundEnabled = isChecked 
end
function ToggleremoveDeadBots(isChecked)
    removeDeadBotsEnabled = isChecked 
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
                        AutoRepairCheckButton:SetChecked(false)
                        AutoRepairCheckButton:Disable()
                        AutoRepairCheckButton.text:SetTextColor(0.5, 0.5, 0.5)
                        AutoRepairCheckButton.text:SetText("Auto Repair (VIP ONLY)")
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
                AutoRepairCheckButton:SetChecked(true)
                print("|cff00ff00[VIP DETECTED]|r You have VIP status!")
				
                vipListening = false
                AutoRepairCheckButton:Enable()
                self:SetScript("OnUpdate", nil)
            end
        end
    end
end)



---------------------------------------------------- auto repair ----------------------------------------------
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




local RoleDetector = CreateFrame("Frame")
RoleDetector:RegisterEvent("UNIT_AURA") 
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
    for i = 1, string.len(playerName) do
        local char = string.sub(playerName, i, i) 
        if (char >= "a" and char <= "z") or (char >= "A" and char <= "Z") or (char >= "0" and char <= "9") then
            cleanName = cleanName .. string.lower(char) 
        end
    end
    return cleanName
end

local function updateRoleConfidence(playerName, class, role, confidenceIncrease, spell)
    local normalizedPlayerName = normalizePlayerName(playerName)
    if not normalizedPlayerName then return end  

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

    local coloredClass = classColors[string.lower(class)] and (classColors[string.lower(class)] .. class .. resetColor) or class
    local plainClass = string.lower(class)
    local data = playerData[normalizedPlayerName] or { classColored = coloredClass, ClassNoColor = plainClass, role = role, roleConfidence = 0 }

    data.roleConfidence = data.roleConfidence + confidenceIncrease

    if data.roleConfidence >= 3 then
        if not detectedPlayers[normalizedPlayerName] then
            detectedPlayers[normalizedPlayerName] = true
            detectedPlayerCount = detectedPlayerCount + 1

            QueueDebugMessage("Detected: " .. detectedPlayerCount .. " - " .. playerName .. " is a " .. coloredClass .. " (" .. role .. ") using: " .. spell, "debugdetection")
        end
    else
        QueueDebugMessage("INFO: Updated confidence for " .. playerName .. ": " .. data.roleConfidence, "debuginfo")
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

local function DetectRole(event, ...)
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

				
				if role ~= "tank" then
					
					updateRoleConfidence(sourceName, spellDictionary[spellName].class, role, spellDictionary[spellName].confidenceIncrease, spellName)
				end
			end

        end
    end
end




local warriorDetectionCount = {}
local function CheckRaidAuras()
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
                end

               
               
               
               
               
               
            end

            if unitClass == "warrior" and not hasTankBuff and not detectedPlayers[unitName] then
                if not warriorDetectionCount[unitName] then
                    warriorDetectionCount[unitName] = 1  
                else
                    warriorDetectionCount[unitName] = warriorDetectionCount[unitName] + 1  
                end

                if warriorDetectionCount[unitName] >= 10 then
                    detectedPlayers[unitName] = true  
                    updateRoleConfidence(unitName, "warrior", "meleedps", 3, "Checked 10 times")
                    warriorDetectionCount[unitName] = nil  
                end
            end
        end
    end
end



RoleDetector:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_AURA" then
         CheckRaidAuras() 
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
    return name and name:lower() or nil
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


RoleRemoverFrame:SetScript("OnEvent", function()
    
    local oldGroupMembers = groupMembers

    
    UpdateGroupMembers()
    UpdateReFillButtonVisibility() 

    
    local isInGroup = GetNumGroupMembers() > 0
    if wasInGroup and not isInGroup then
        ReplaceDeadBot = {}
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

function UninviteMember(name, reason)
    local normalizedName = normalizePlayerName(name)
    if not normalizedName then
        QueueDebugMessage("ERROR: Could not normalize name for UninviteMember", "debugerror")
        return
    end

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


function RetryMessageQueueProcessing()
    local currentTime = GetTime()
    if currentTime - lastTimeChecked >= checkInterval then
        lastTimeChecked = currentTime 

        if not IsAnyGroupMemberInCombat() then
            QueueDebugMessage("Resuming..", "none")
            isInCombat = false
            retryTimerRunning = false
            incombatmessagesent = false    
            combatCheckFrame:SetScript("OnUpdate", nil) 
            ProcessMessageQueue() 
            ProcessDebugMessageQueue()
        else
            
        end
    end
end

local firstBotRemovalFrame = CreateFrame("Frame")
firstBotRemovalFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

firstBotRemovalFrame:SetScript("OnEvent", function()
    if not initialBotRemoved and GetNumGroupMembers() >= 3 then
    
        if firstBotName then
            QueueDebugMessage("Removed first bot: " .. firstBotName, "debuginfo")
			if totaly > 5 then 
            UninviteMember(firstBotName, "firstBotRemoved")
			end
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
            if IsAnyGroupMemberInCombat() then
                if not incombatmessagesent then 
                    QueueDebugMessage("Raid member in combat, waiting..", "none")
                    incombatmessagesent = true	
                end	
                isInCombat = true
                if not retryTimerRunning then
                    combatCheckFrame:SetScript("OnUpdate", RetryMessageQueueProcessing)
                    retryTimerRunning = true
                end

                table.insert(messageQueue, 1, messageInfo)
                return
            else
                if recipient == "none" then
                    DEFAULT_CHAT_FRAME:AddMessage(message)
                else
                   
                    SendChatMessage(message, GUILD)
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
        if recipient == "none" then
            
            DEFAULT_CHAT_FRAME:AddMessage(message)
        else
            
            SendChatMessage(message, recipient)
        end

    end
end

local function CreateRemoveDeadBotsButton()
    local removeDeadBotsButton = CreateFrame("Button", "RemoveDeadBotsButton", UIParent, "UIPanelButtonTemplate")
    removeDeadBotsButton:SetSize(120, 30)
    removeDeadBotsButton:SetPoint("CENTER", UIParent, "CENTER", 0, -140)
    removeDeadBotsButton:SetText("Remove Dead Bots")
    removeDeadBotsButton:Hide()

    removeDeadBotsButton:SetMovable(true)
    removeDeadBotsButton:EnableMouse(true)
    removeDeadBotsButton:RegisterForDrag("LeftButton")

    removeDeadBotsButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    removeDeadBotsButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

	function removeDeadBotsFunction()
		local deadBotsRemoved = false
		local playerName = UnitName("player")
		local totalMemberCount = GetNumGroupMembers()
		local activeMemberCount = 0

		
		local guildMembers = {}
		for i = 1, GetNumGuildMembers() do
			local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
			if name and online then
				local normalizedGuildName = name:match("([^%-]+)") 
				guildMembers[normalizedGuildName:lower()] = true
			end
		end

		
		local friends = {}
		local numFriends = C_FriendList.GetNumFriends()
		for i = 1, numFriends do
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			if friendInfo and friendInfo.name and friendInfo.connected then
				local normalizedFriendName = friendInfo.name:match("([^%-]+)")
				friends[normalizedFriendName:lower()] = true
			end
		end

		
		for i = 1, totalMemberCount do
			local unit = IsInRaid() and "raid" .. tostring(i) or "party" .. tostring(i)
			if UnitExists(unit) and not UnitIsGhost(unit) then
				activeMemberCount = activeMemberCount + 1
			end
		end

		
		QueueDebugMessage("Active members: " .. activeMemberCount .. ", Total members: " .. totalMemberCount, "debuginfo")

		
		for i = 1, totalMemberCount do
			local unit = IsInRaid() and "raid" .. tostring(i) or "party" .. tostring(i)
			local name = UnitName(unit)

			if name and UnitIsDead(unit) and not UnitIsGhost(unit) and name ~= playerName then
				local normalizedName = name:match("([^%-]+)"):lower()

				if guildMembers[normalizedName] then
					QueueDebugMessage("INFO: Skipped removing " .. name .. " (guild member).", "debugremove")
				elseif friends[normalizedName] then
					QueueDebugMessage("INFO: Skipped removing " .. name .. " (friend).", "debugremove")
				elseif UnitIsUnit(unit, "player") then
					QueueDebugMessage("INFO: CANNOT KICK YOURSELF", "debuginfo")

				elseif not UnitIsConnected(unit) then
					QueueDebugMessage("INFO: CANNOT KICK OFFLINE UNIT: " .. name, "none")					
				else
					if activeMemberCount > 2 then
						if playerData[normalizedName] then
							ReplaceDeadBot[normalizedName] = playerData[normalizedName]
							playerData[normalizedName] = nil
						end
						UninviteUnit(normalizedName)
						deadBotsRemoved = true
						activeMemberCount = activeMemberCount - 1
						totalMemberCount = totalMemberCount - 1
						QueueDebugMessage("REMOVED: " .. name .. " (not in guild or friends list).", "debugremove")
					else
						QueueDebugMessage("Cannot remove " .. name .. ": Not enough members left (minimum 2 required).", "debuginfo")
					end
				end
			end
		end

		
		if not deadBotsRemoved then
			QueueDebugMessage("No dead bots were removed.", "debuginfo")
		else
			QueueDebugMessage("Dead bots removed. Button will now hide.", "debuginfo")
			removeDeadBotsButton:Hide()
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
local messagecantremove = false
local hasWarnedNoPermission = false
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
local hasWarnedNoPermission = false
local messagecantremove = false
local guildDeadStatus = {}
local lastKickTime = 0
local KICK_COOLDOWN = 0.1 

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


local function buildGuildRoster()
	local members = {}
	for j = 1, GetNumGuildMembers() do
		local name = GetGuildRosterInfo(j)
		if name then
			name = Ambiguate(name, "short")
			members[name] = true
		end
	end

	return members
end

local function buildFriendList()
	local friends = {}
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.connected and info.name then
			local name = Ambiguate(info.name, "short")
			friends[name] = true
		end
	end

	return friends
end

local guildCache, friendsCache = {}, {}
local lastCacheTime = 0
local CACHE_DURATION = 5 

local function getCachedGuildRoster()
    if GetTime() - lastCacheTime > CACHE_DURATION then
        guildCache = buildGuildRoster()
        friendsCache = buildFriendList()
        lastCacheTime = GetTime()
    end
    return guildCache, friendsCache 
end



local function CheckAndRemoveDeadBots()
	if InCombatLockdown() then return end
	local settings = FillRaidBotsSavedSettings or {}
	local autoRemoveEnabled = settings.isCheckAndRemoveEnabled
	local showButtonEnabled = settings.isremoveDeadBotsButtonEnabled
	local guildMembers, friends = getCachedGuildRoster()	
	if autoRemoveEnabled then
		if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and IsInGroup() then
			if not hasWarnedNoPermission then
				QueueDebugMessage("WARNING: You must be a raid leader or assistant to remove bots.", "debuginfo")
				hasWarnedNoPermission = true
			end
			return
		end
		hasWarnedNoPermission = false

		local now = GetTime()
		if now - lastKickTime < KICK_COOLDOWN then
			QueueDebugMessage("Throttled: waiting for kick cooldown.", "debuginfo")
			return
		end

		local isInRaid = IsInRaid()
		local membersRemaining = CountRealGroupMembers()
		local minimumAllowed = isInRaid and 2 or 2
		if membersRemaining == 0 then return end

		local maxGroupSize = isInRaid and 40 or 5
		local maxKicks = (membersRemaining > 5) and 3 or 1
		local kicks = 0

		for i = 1, maxGroupSize do
			if kicks >= maxKicks then break end

			local unit = isInRaid and ("raid" .. i) or (i == 1 and "player" or "party" .. (i - 1))
			if UnitExists(unit) then
				local name = Ambiguate(UnitName(unit), "short")
				if name then
					if UnitIsDead(unit) and not UnitIsGhost(unit) then

						if guildMembers[name] then
							if not guildDeadStatus[name] then
								QueueDebugMessage("INFO: STOPPED FROM KICKING GUILD MEMBER: " .. name, "debuginfo")
								guildDeadStatus[name] = true
							end

						elseif friends[name] then
							if not guildDeadStatus[name] then
								QueueDebugMessage("INFO: STOPPED FROM KICKING FRIEND: " .. name, "debuginfo")
								guildDeadStatus[name] = true
							end

						elseif UnitIsUnit(unit, "player") then
							QueueDebugMessage("INFO: CANNOT KICK YOURSELF", "debuginfo")

						elseif not UnitIsConnected(unit) then
							QueueDebugMessage("INFO: CANNOT KICK OFFLINE UNIT: " .. name, "debuginfo")

						elseif membersRemaining > minimumAllowed then
							UninviteMember(name, "dead")
							membersRemaining = membersRemaining - 1
							kicks = kicks + 1
							

						else
							if not messagecantremove then
								QueueDebugMessage("INFO: Stopped kicking. Members left: " .. membersRemaining .. ". Preventing group disband.", "debuginfo")
								messagecantremove = true
							end
							break
						end
					else
						guildDeadStatus[name] = nil
					end
				else
					QueueDebugMessage("DEBUG: Name is nil for unit: " .. unit, "debugerror")
				end
			end
		end

		if kicks > 0 then
			lastKickTime = now
		end
	end

   
	if removeDeadBotsEnabled then
		local hasDeadBots = false
		local activeMemberCount = 0
		local groupType = IsInRaid() and "raid" or "party"



		for i = 1, GetNumGroupMembers() do
			local unit = (groupType == "party" and i == 1) and "player" or (groupType .. i)

			if UnitExists(unit) and not UnitIsUnit(unit, "player") then
				if UnitIsConnected(unit) then
					local name = UnitName(unit)
					if name then
						local baseName = Ambiguate(name, "short"):lower()

						if not guildMembers[baseName] and not friends[baseName] then
						
							if not UnitIsGhost(unit) then
								activeMemberCount = activeMemberCount + 1
							end
							if UnitHealth(unit) == 0 then
								hasDeadBots = true
							end
						end
					end
				end
			end
		end

		if hasDeadBots and activeMemberCount >= 2 then
			removeDeadBotsButton:Show()
		else
			removeDeadBotsButton:Hide()
		end
	end


    isProcessing = false
end





local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
       
        C_Timer.After(2, CheckAndRemoveDeadBots)
    elseif not InCombatLockdown() then
        RefreshRaidFrames()
    end
end)



function SaveRaidMembersAndSetFirstBot()
    local raidMembers = {}
    local playerName = UnitName("player")
    firstBotName = nil  

    local guildMembers = {}
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online then
            local normalizedGuildName = name:match("([^%-]+)"):lower() 
            guildMembers[normalizedGuildName] = true
        end
    end

    local friends = {}
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo and friendInfo.name and friendInfo.connected then
            local normalizedFriendName = friendInfo.name:match("([^%-]+)"):lower() 
            friends[normalizedFriendName] = true
        end
    end

    local numRaidMembers = GetNumRaidMembers and GetNumRaidMembers() or GetNumGroupMembers()
    for i = 1, numRaidMembers do
        local unit = IsInRaid() and "raid" .. i or "party" .. i
        local name = UnitName(unit)

       
        if name and name ~= playerName then
            table.insert(raidMembers, name)

            local normalizedName = name:match("([^%-]+)"):lower()

            if not firstBotName and not guildMembers[normalizedName] and not friends[normalizedName] then
                firstBotName = name
            end
        end
    end

    if firstBotName then
        QueueDebugMessage("INFO: First bot in raid set to: " .. firstBotName, "debuginfo")
    else
        QueueDebugMessage("WARNING: No eligible bot found to set as the first bot in raid.", "debuginfo")
    end
end




local function SavePartyMembersAndSetFirstBot()
    local partyMembers = {}
    local isInRaid = IsInRaid()  

    
    if isInRaid then
        QueueDebugMessage("In a raid group.", "debuginfo")
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local name = UnitName(unit)
            if name then
                table.insert(partyMembers, name)
                QueueDebugMessage("Found raid member: " .. name, "debuginfo")
            else
                QueueDebugMessage("No name found for raid unit " .. i, "debuginfo")
            end
        end
    else
        QueueDebugMessage("In a party group.", "debuginfo")
        for i = 1, GetNumGroupMembers() - 1 do  
            local unit = "party" .. i
            local name = UnitName(unit)
            if name then
                table.insert(partyMembers, name)
            else
                QueueDebugMessage("No name found for party unit " .. i, "debuginfo")
            end
        end
    end

    
    local playerName = UnitName("player")
    QueueDebugMessage("Player name is: " .. playerName, "debuginfo")

    for _, member in ipairs(partyMembers) do
        if member ~= playerName then
            firstBotName = member
            break
        end
    end

    if firstBotName then
        QueueDebugMessage("First bot set to: " .. firstBotName, "debuginfo")
    else
        QueueDebugMessage("Error: No bot found to set as the first bot.", "debuginfo")
    end
end




function resetfirstbot_OnEvent(self, event)
    if event == "RAID_ROSTER_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
        
        if GetNumGroupMembers() == 0 then
            initialBotRemoved = false
            firstBotName = nil
            botCount = 0
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

local function GetSelectedLootMethod()
    if AutoFFACheckButton:GetChecked() then
        return "freeforall"
    elseif AutoGroupLootCheckButton:GetChecked() then
        return "group"
    elseif AutoMasterLootCheckButton:GetChecked() then
        return "master"
    end
    return "freeforall" 
end

local originalSFXVolume = nil

function ToggleSoundEffectsVolume(action)
	if AutoMuteSoundEnabled then
		if action == "lower" then
			if not originalSFXVolume then
				originalSFXVolume = GetCVar("Sound_SFXVolume")
				SetCVar("Sound_SFXVolume", "0.1")
				QueueDebugMessage("Sound effects volume lowered.", "debuginfo")
			else
				--print("Sound already lowered.")
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



local function FillRaid()
	shouldStopBotAdding = false
    local healers = {}
    local others = {}
    local totalHealers = 0
    local totalOthers = 0

    ToggleSoundEffectsVolume("lower")

    
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
    
    if IsInRaid() then
        
        if GetNumGroupMembers() == 2 then
            SaveRaidMembersAndSetFirstBot()
            QueueDebugMessage("SaveRaidMembersAndSetFirstBot called", "debugfilling")
        end
    else
        
        if GetNumGroupMembers() == 0 then
			if totaly > 5 then
				QueueMessage(".partybot add warrior tank", "SAY", true)
				QueueDebugMessage("Inviting the first bot to start the party for a raid.", "none")
			else
			
				QueueDebugMessage("Creating a party group.", "none")
				for _, healer in ipairs(healers) do
					QueueMessage(".partybot add " .. string.lower(healer), "SAY", true)
				end
				for _, other in ipairs(others) do
					QueueMessage(".partybot add " .. string.lower(other), "SAY", true)
				end
				C_Timer.After(3, function()
					ToggleSoundEffectsVolume("restore")
				end)
			
			end				

            
            local waitForPartyFrame = CreateFrame("Frame")
            waitForPartyFrame:SetScript("OnUpdate", function()
                if GetNumGroupMembers() > 0 then
                    waitForPartyFrame:SetScript("OnUpdate", nil)
                    waitForPartyFrame:Hide()
                    SavePartyMembersAndSetFirstBot()
                    local selectedLoot = GetSelectedLootMethod()
                    if selectedLoot == "master" then
                       
                        local playerName = UnitName("player")
                        SetLootMethod("master", playerName)
                        QueueDebugMessage("Loot method set to Master Looter. Assigned to: " .. playerName, "debuginfo")
                    else
                        SetLootMethod(selectedLoot)
                        QueueDebugMessage("Loot method set to: " .. selectedLoot, "debuginfo")
                    end
					if totaly > 5 then
                    FillRaid() 
					end
                end
            end)
            waitForPartyFrame:Show()
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

    


    QueueDebugMessage("Adding: Going to add healers:" .. totalHealers, "debugfilling")
    QueueDebugMessage("Adding: Going to add classes:" .. totalOthers, "debugfilling")
    QueueDebugMessage("Adding: Totaly:" .. totaly, "debugfilling")

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
                        FixGroups()

                        
                        C_Timer.After(5, function()
                            QueueDebugMessage("Added: Adding other classes after healers.", "debugfilling")
                            addOthers()
                        end)
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
        end
    end
end





function FixGroups()


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

		
		if name ~= playerName and class and TableContains(healerClasses, class) then
			table.insert(healers, {name = name, index = i, group = subgroup, class = class, online = online, moved = false})
			healerCount = healerCount + 1
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

	
	QueueDebugMessage("Total healers: " .. totalHealers .. ", Max groups: " .. maxGroups, "debuginfo")

	if currentPhase == 1 then
		
		local healersByClass = {}
		for _, healer in ipairs(healers) do
			healersByClass[healer.class] = healersByClass[healer.class] or {}
			table.insert(healersByClass[healer.class], healer)
		end

		
		for class, classHealers in pairs(healersByClass) do
			QueueDebugMessage("Class: " .. class .. " has " .. #classHealers .. " healers", "debuginfo")
		end

		local groupIndex = 1
		for class, classHealers in pairs(healersByClass) do
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
					table.insert(groupClasses[groupIndex], healer.class)

					
					QueueDebugMessage("Assigned healer " .. healer.name .. " to group " .. groupIndex, "debuginfo")
				end

				
				groupIndex = groupIndex % maxGroups + 1
			end
		end

	elseif currentPhase == 2 then
		local healersByClass = {}
		for _, healer in ipairs(healers) do
			if not healersByClass[healer.class] then
				healersByClass[healer.class] = {}
			end
			table.insert(healersByClass[healer.class], healer)
		end

		local groupIndex = 1
		local allHealersAssigned = false 

		while not allHealersAssigned do
			allHealersAssigned = true

			for class, classHealers in pairs(healersByClass) do
				if #classHealers > 0 then

					local healer = table.remove(classHealers, 1)


					local attempts = 0
					while TableContains(groupClasses[groupIndex], healer.class) and attempts < maxGroups do
						groupIndex = groupIndex % maxGroups + 1
						attempts = attempts + 1
					end

					
					QueueMove(healer, groupIndex)
					groupSizes[groupIndex] = groupSizes[groupIndex] + 1
					table.insert(groupClasses[groupIndex], healer.class)

					
					QueueDebugMessage("Rebalanced healer " .. healer.name .. " to group " .. groupIndex, "debuginfo")

					
					groupIndex = groupIndex % maxGroups + 1
					allHealersAssigned = false 
				end
			end
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
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)

    return helpBtn
end
----------------------------------------------------------THE UI------------------------------------------------------------------------------------
local function ShowStaticPopup(message, title, isConfirmation)
    StaticPopupDialogs["FILLRAID_GENERIC_POPUP"] = {
        text = message,
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
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

    local versionText = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("BOTTOMRIGHT", FillRaidFrame, "BOTTOMRIGHT", -10, 8)  
	function newversion(newVersionDetected)
		if newVersionDetected then
			versionText:SetText("You are running:" .. versionNumber .. " - Update available: " .. newVersionDetected)
		else
			versionText:SetText("Version: " .. versionNumber)
		end
	end

	
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

    
    local totalBotLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    totalBotLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    totalBotLabel:SetText("Total Bots: 0")
    yOffset = yOffset - 25

    
    local spotsLeftLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    spotsLeftLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    spotsLeftLabel:SetText("Spots Left: 39") 
    yOffset = yOffset - 25

    
    local roleCountsLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    roleCountsLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    roleCountsLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    roleCountsLabel:SetText("Tanks: 0 Healers: 0 Melee DPS: 0 Ranged DPS: 0")
    yOffset = yOffset - 30

    
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

                    if totalBots < 40 then
                        totalBotLabel:SetText("Total Bots: " .. totalBots)
                        spotsLeftLabel:SetText("Spots Left: " .. (39 - totalBots))
                    else
                        totalBotLabel:SetText("Too many added: |cffff0000" .. totalBots .. "|r")
                        spotsLeftLabel:SetText("Spots Left: 0")
                    end

                    roleCountsLabel:SetText(string.format(
                        "Tanks: %d Healers: %d Melee DPS: %d Ranged DPS: %d",
                        roleCounts["tank"], roleCounts["healer"],
                        roleCounts["meleedps"], roleCounts["rangedps"]
                    ))
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
	UISettingsFrame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		edgeSize = 16,
	})
	UISettingsFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) 

	UISettingsFrame:SetFrameStrata("DIALOG")
	UISettingsFrame:SetFrameLevel(10)
	UISettingsFrame:Hide()
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
PresetPopup:SetSize(200, 250)
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
    inputBox:SetPoint(point, parent, "CENTER")
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

local helpButton = CreateHelpButton(PresetPopup, popupLabel, 10, 0, "Enter name:\n  - Preset name to save the current setup\n\nBoss names:\n  - Name of the boss or mob for the Ctrl+Alt+Click function\n\nTip:\n  - Hold Alt and click a mob to add it to the list.", "Preset Help")

local presetInput = CreateInputBox(PresetPopup, "TOP", true)
presetInput:SetPoint("TOP", popupLabel, "BOTTOM", 0, -5)

local bossInput = CreateInputBox(PresetPopup, "TOP", false)
bossInput:SetWidth(120)
bossInput:SetPoint("TOP", presetInput, "BOTTOM", -30, -10)

local bossInputLabel = PresetPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bossInputLabel:SetPoint("TOP", bossInput, "TOP", 0, 10)
bossInputLabel:SetText("Boss Names: (optional)")

local addBossButton = CreateButton(PresetPopup, 60, 20, "LEFT", "Add")
addBossButton:SetPoint("LEFT", bossInput, "RIGHT", 5, 0)

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
        itemFrame:SetPoint("TOPLEFT", 0, -((index-1) * (itemHeight + spacing)))
        
       
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

local function AddBossDirectly(bossName)
    if not PresetPopup:IsVisible() then return end
    
    bossName = strtrim(bossName)
    if bossName == "" then return end
    
    local lowerName = strlower(bossName)
    for _, existing in pairs(currentBosses) do
        if strlower(existing) == lowerName then 
            ShowStaticPopup(bossName.." already in list!", "ERROR")
            return 
        end
    end
    
    tinsert(currentBosses, bossName)
    RefreshBossList()
    DEFAULT_CHAT_FRAME:AddMessage(bossName.." added to list!")
end

addBossButton:SetScript("OnClick", function()
    local name = strtrim(bossInput:GetText())
    if name ~= "" then
       
        for _, existing in ipairs(currentBosses) do
            if existing == name then return end
        end
       
        table.insert(currentBosses, name)
        bossInput:SetText("")
        RefreshBossList()
    end
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
        ShowStaticPopup("You can only edit presets \n under Others.")
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


---SuppressEditorButton:SetScript("OnEnter", function()



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
CreditsFrame:SetHeight(200)
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
    {name = "|cffffd700Dedirtyone|r", contribution = "Special thanks to Dedirtyone for his incredible generosity\nin donating €50 to help me get VIP status.\nYour support means so much and has truly motivated me \nto keep contributing to the community. \nThis addon wouldn’t be the same without people like you!"},  
	{name = "|cffffd700TheSamurai206|r", contribution = "A huge thank you to TheSamurai206 (Zugginator) for his generous donation of €20.\nYour support means a lot and helps me continue improving this addon.\nIt's supporters like you that keep this project going!"},
    {name = "|cffffffffGemma|r", contribution = "Thanks for Beta testing, and bug reports!"},  
    {name = "|cffffffffTO EVERYONE ELSE!|r", contribution = "To everyone who has been supporting! \nIf you are interested in contributing in any way, \nbug reporting, beta testing, or whatever, \nplease contact me on the forum, Discord, or in-game."},  
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
    local function CreateInstanceButton(label, yOffset, frameName, presetName)
        local button = CreateFrame("Button", nil, InstanceButtonsFrame, "GameMenuButtonTemplate")
        button:SetPoint("TOP", InstanceButtonsFrame, "TOP", 0, yOffset)
        button:SetWidth(180)
        button:SetHeight(30)
        button:SetText(label)
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(label)
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


  
function CreateInstanceFrame(name, presets, label)
	local buttonWidth = 80
	local buttonHeight = 30
	local padding = 10
	local maxButtonsPerColumn = 8

	local totalButtonWidth = buttonWidth + padding
	local totalButtonHeight = buttonHeight + padding
	local numButtons = table.getn(presets)
	local numColumns = math.ceil(numButtons / maxButtonsPerColumn)
	local numRows = math.min(numButtons, maxButtonsPerColumn)

	local dynamicWidth = (totalButtonWidth * numColumns) + padding
	local dynamicHeight = (totalButtonHeight * numRows) + padding

	local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	setglobal(name, frame)
	table.insert(UISpecialFrames, name)	
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



	local fixedStartY = -10

	local function CreatePresetButton(preset, index)
		local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		button:SetWidth(buttonWidth)
		button:SetHeight(buttonHeight)
		button:SetText(preset.label or "Unknown preset")
		local fontString = button:GetFontString()
		fontString:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
		local column = math.floor((index - 1) / maxButtonsPerColumn)
		local row = (index - 1) - column * maxButtonsPerColumn

		local xOffset = (frame:GetWidth() - (numColumns * totalButtonWidth - padding)) / 2 + (column * totalButtonWidth)
		local yOffset = fixedStartY - (row * totalButtonHeight)

		button:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)

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

			if preset.values then
				for classRole, value in pairs(preset.values) do
					local inputBox = inputBoxes[classRole]
					if inputBox then
						inputBox:SetNumber(value)
						local onTextChanged = inputBox:GetScript("OnTextChanged")
						if onTextChanged then
							onTextChanged(inputBox)
						end
					end
				end
			end

			if currentPresetLabel and (preset.label or preset.fullname) then
				currentPresetLabel:SetText("Preset: " .. preset.label)
				currentPresetName = preset.label
			end
		end)

		button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:SetText(preset.tooltip or "No tooltip available")
			GameTooltip:Show()
		end)

		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	for index, preset in ipairs(presets) do
		CreatePresetButton(preset, index)
	end

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

    msg = string.lower(msg)
    local foundPreset = false

    for _, presetTable in pairs(allPresets) do
        if type(presetTable) == "table" then
            for _, preset in ipairs(presetTable) do
                local matchFound = 
                    (preset.label and string.find(string.lower(preset.label), msg, 1, true)) or
                    (preset.fullname and string.find(string.lower(preset.fullname), msg, 1, true))
                
                if not matchFound and preset.bosses then
                    for _, bossName in ipairs(preset.bosses) do
                        if string.find(string.lower(bossName), msg, 1, true) then
                            matchFound = true
                            break
                        end
                    end
                end

                if matchFound then
                    DEFAULT_CHAT_FRAME:AddMessage("Applying preset: " .. (preset.fullname or preset.label), "debugfilling")
                    
                   
                    for classRole, inputBox in pairs(inputBoxes) do
                        if inputBox then
                            inputBox:SetNumber(0)
                            local onTextChanged = inputBox:GetScript("OnTextChanged")
                            if onTextChanged then
                                onTextChanged(inputBox)
                            end
                        end
                    end
                    
                   
                    if preset.values then
                        for classRole, value in pairs(preset.values) do
                            if inputBoxes[classRole] then
                                inputBoxes[classRole]:SetNumber(value)
                                local onTextChanged = inputBoxes[classRole]:GetScript("OnTextChanged")
                                if onTextChanged then
                                    onTextChanged(inputBoxes[classRole])
                                end
                            end
                        end
                    end
                    
                    FillRaid()
                    foundPreset = true
                    return
                end
            end
        end
    end

    if not foundPreset then
        QueueDebugMessage("Preset not found: " .. msg, "debugerror")
    end
end



    return frame
end


local detectBossFrame = CreateFrame("Frame")
detectBossFrame:Hide() 

local lastDetectedBoss = nil 
local keyPressCooldown = false 

function ToggleClickToFill(isChecked)
    ClickToFillEnabled = isChecked 

end
local function DetectBossAndFillRaid()
    if keyPressCooldown then return end 

    if ClickToFillEnabled and IsControlKeyDown() and IsAltKeyDown() then 
        local bossName = UnitName("target") or UnitName("mouseover") 
        if bossName and bossName ~= lastDetectedBoss then
            lastDetectedBoss = bossName 
            keyPressCooldown = true 
            
            SlashCmdList["FILLRAID"](bossName)
            detectBossFrame:Hide() 
        end
    end
end

local function ResetCooldown()
    keyPressCooldown = false 
    lastDetectedBoss = nil 
end

local function CheckAndEnableDetection()
    if ClickToFillEnabled and IsControlKeyDown() and IsAltKeyDown() then  
        detectBossFrame:Show()
        DetectBossAndFillRaid() 
    else
        detectBossFrame:Hide()
        ResetCooldown() 
    end
end


detectBossFrame:SetScript("OnUpdate", DetectBossAndFillRaid)

local detectBossEventFrame = CreateFrame("Frame")
detectBossEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
detectBossEventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
detectBossEventFrame:RegisterEvent("MODIFIER_STATE_CHANGED") 
detectBossEventFrame:SetScript("OnEvent", function(_, event, key)
    if event == "MODIFIER_STATE_CHANGED" then
        if not IsControlKeyDown() and not IsAltKeyDown() then
            ResetCooldown() 
        end
    end
    CheckAndEnableDetection()
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

   
    for classRole, inputBox in pairs(inputBoxes) do
        if inputBox then
            local value = inputBox:GetText()
            local numValue = tonumber(value)
            if numValue and numValue > 0 then
                presetList[presetIndex].values[classRole] = numValue
            else
                presetList[presetIndex].values[classRole] = nil
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

		
		totalBotLabel:SetText("Total Bots: 0")
		spotsLeftLabel:SetText("Spots Left: 39")
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


		
local savedPositions = {}

local openFillRaidButton = CreateFrame("Button", "OpenFillRaidButton", PCPFrame)  
openFillRaidButton:SetMovable(true)  
openFillRaidButton:EnableMouse(true)  
openFillRaidButton:RegisterForDrag("LeftButton")  


local defaultPosition = {x = -20, y = 250}


function InitializeButtonPosition()
    local position = savedPositions["OpenFillRaidButton"] or defaultPosition
    if PCPFrame then 
        openFillRaidButton:SetPoint("CENTER", PCPFrame, "LEFT", position.x, position.y)
    elseif PCPFrameRemake then
        openFillRaidButton:SetPoint("LEFT", PCPFrameRemake, "LEFT", position.x -20, 0 + 100) 
    end
end




function ToggleButtonMovement(button)
    if FillRaidBotsSavedSettings.moveButtonsEnabled then
        openFillRaidButton:SetMovable(true)

        openFillRaidButton:SetScript("OnDragStart", function(self)
            self:StartMoving()
            self.isMoving = true  
        end)

        openFillRaidButton:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            self.isMoving = false  
            local point, _, _, x, y = self:GetPoint()
            savedPositions["OpenFillRaidButton"] = {x = x, y = y}
            QueueDebugMessage("Coordinates saved: x = " .. tostring(x) .. ", y = " .. tostring(y), "debuginfo")
        end)
    else
        
        openFillRaidButton:SetScript("OnDragStart", nil)
        openFillRaidButton:SetScript("OnDragStop", nil)
    end
end


InitializeButtonPosition()
ToggleButtonMovement(openFillRaidButton)





SLASH_RFB1 = "/rfb"
SlashCmdList["RFB"] = function()
    savedPositions["OpenFillRaidButton"] = defaultPosition
    InitializeButtonPosition()
    QueueDebugMessage("OpenFillRaidButton position reset to default: x = " .. tostring(defaultPosition.x) .. ", y = " .. tostring(defaultPosition.y), "debuginfo")
end



ToggleButtonMovement(openFillRaidButton)


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
    end
end

openFillRaidButton:SetScript("OnClick", openFillRaid)


	openFillRaidButton:Hide()

	
	local kickAllButton = CreateFrame("Button", "OpenFillRaidButton", UIParent)

	kickAllButton:SetScript("OnClick", function()
		UninviteAllRaidMembers()
		ReplaceDeadBot = {}
		resetData()
		UpdateReFillButtonVisibility()	
	end)
	kickAllButton:Hide() 

local reFillButton = CreateFrame("Button", "reFillButton", UIParent)
function ToggleSmallbuttonCheck(isChecked)
    SmallbuttonEnabled = isChecked

   
    if SmallbuttonEnabled then 
		openFillRaidButton:SetWidth(32)  
		openFillRaidButton:SetHeight(32) 
        openFillRaidButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\fillraidmini")
		openFillRaidButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        openFillRaidButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\fillraidmini")

		kickAllButton:SetWidth(32)  
		kickAllButton:SetHeight(32) 
		kickAllButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\kickallmini")
		kickAllButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")  
		kickAllButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\kickallmini")  

		reFillButton:SetWidth(32)  
		reFillButton:SetHeight(32) 

		reFillButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\refillmini")
		reFillButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")  
		reFillButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\refillmini")  		
    else
		openFillRaidButton:SetWidth(40)  
		openFillRaidButton:SetHeight(100) 
        openFillRaidButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\fillraid")
		openFillRaidButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        openFillRaidButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\fillraid")
		kickAllButton:SetWidth(40)  
		kickAllButton:SetHeight(100) 

		kickAllButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\kickall")
		kickAllButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")  
		kickAllButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\kickall") 
		reFillButton:SetWidth(40)  
		reFillButton:SetHeight(100) 

		reFillButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\refill")
		reFillButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")  
		reFillButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\refill")   		
    end  
end
local savedPositions = {}




ToggleSmallbuttonCheck(SmallbuttonEnabled or false) 



function UpdateReFillButtonVisibility()
    if next(ReplaceDeadBot) == nil then
	
        reFillButton:Hide()
    else
	if FillRaidBotsSavedSettings.isRefillEnabled then
        reFillButton:Show()
		
	end
    end
end


function RefillBots()
    if next(ReplaceDeadBot) == nil then
        QueueDebugMessage("Replaced Bot List is empty.", "debugfilling")
    else
        ToggleSoundEffectsVolume("lower")
        QueueDebugMessage("Replaced Bot List:", "debugfilling")

        local count = 0
        for playerName, data in pairs(ReplaceDeadBot) do
            count = count + 1
            QueueDebugMessage(playerName .. " - Class: " .. data.classColored .. ", Role: " .. data.role, "debugfilling")
            QueueMessage(".partybot add " .. data.ClassNoColor .. " " .. data.role, "SAY", true)
        end

        ReplaceDeadBot = {}
        QueueDebugMessage("Replaced Bot List has been cleared.", "debugfilling")

       
        local delay = 1 + math.max(0, (count - 1) * 0.5)
        C_Timer.After(delay, function()
            ToggleSoundEffectsVolume("restore")
        end)

        UpdateReFillButtonVisibility()
    end  
end

reFillButton:SetScript("OnClick", RefillBots)

UpdateReFillButtonVisibility()



	
	local function UpdateButtonPosition()
		if (PCPFrame and PCPFrame:IsVisible()) or (PCPFrameRemake and PCPFrameRemake:IsVisible()) then

			InitializeButtonPosition()

			
			kickAllButton:ClearAllPoints()
			kickAllButton:SetPoint("TOP", openFillRaidButton, "BOTTOM", 0, -10) 
			reFillButton:ClearAllPoints()
			reFillButton:SetPoint("TOP", kickAllButton, "BOTTOM", 0, -10) 			
		end
	end

	
	local visibilityFrame = CreateFrame("Frame")
	visibilityFrame:SetScript("OnUpdate", function()
		if (PCPFrame and PCPFrame:IsVisible()) or (PCPFrameRemake and PCPFrameRemake:IsVisible()) then
			UpdateButtonPosition()
			if not fillRaidFrameManualClose and not openFillRaidButton:IsShown() then
				openFillRaidButton:Show()
			end
			if not kickAllButton:IsShown() then
				kickAllButton:Show()
			end
			if not reFillButton:IsShown() then

				UpdateReFillButtonVisibility()
			end				
		elseif (PCPFrame and not PCPFrame:IsVisible()) or (PCPFrameRemake and not PCPFrameRemake:IsVisible()) then
			openFillRaidButton:Hide()
			kickAllButton:Hide()
			FillRaidFrame:Hide()   
			fillRaidFrameManualClose = false
		else
			if openFillRaidButton:IsShown() and not fillRaidFrameManualClose then
				openFillRaidButton:Hide()
			end
			if kickAllButton:IsShown() then
				kickAllButton:Hide()
			end
		end
	end)
	visibilityFrame:Show()

end


CreateFillRaidUI()
InitializeSettings()



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
    initialBotRemoved = false
    firstBotName = nil
    botCount = 0    

    
    local guildMembers = {}
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and name ~= myName and online then  
            local playerName = name:match("([^%-]+)")  
            guildMembers[playerName:lower()] = true  
        end
    end

	
	local friends = {}
	local numFriends = C_FriendList.GetNumFriends()
	for i = 1, numFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo and friendInfo.name and friendInfo.connected then
			local normalizedFriendName = friendInfo.name:match("([^%-]+)")
			friends[normalizedFriendName:lower()] = true  

			
			QueueDebugMessage("INFO: Friends online: " .. friendInfo.name, "debugremove")
		end
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
            local normalizedName = name:match("([^%-]+)"):lower()  

            if name == myName then
                QueueDebugMessage("INFO: Kept " .. name .. " because it's you.", "debugremove")
            elseif guildMembers[normalizedName] then
                QueueDebugMessage("INFO: Kept " .. name .. " because they are in your guild.", "debugremove")
            elseif friends[normalizedName] then
                QueueDebugMessage("INFO: Kept " .. name .. " because they are in your friends list.", "debugremove")
            else
                if #remainingMembers > 1 then
                    QueueDebugMessage("REMOVING: " .. name .. " because they are not in your guild or friends list.", "debugremove")
                    UninviteUnit(name)
                    table.remove(remainingMembers, i)  
                else
                    QueueDebugMessage("INFO: Kept " .. name .. " because they are the last member.", "debugremove")
                end
            end
        else
            QueueDebugMessage("ERROR: Skipped uninviting an unknown or nil player in group.", "debugremove")
        end
    end
end

local c = 0


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
    else
       
        if cmd == "" or cmd == "help" then
            DEFAULT_CHAT_FRAME:AddMessage("FillRaidBots Commands:", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb ua - Uninvite all non-guild/friend raid members", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb (preset name) - Fill raid with optimal composition", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb list - lists all presets", 1.0, 1.0, 0.0)			
            DEFAULT_CHAT_FRAME:AddMessage("/frb open - Toggle FillRaid window", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb refill - Replace recently removed bots", 1.0, 1.0, 0.0)
            DEFAULT_CHAT_FRAME:AddMessage("/frb fixgroups - Reorganize raid groups", 1.0, 1.0, 0.0)

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
			{"Auto Remove", "Auto removes first bot and auto remove dead bots"},
            {"Auto Repair", "Auto repairs when you ress (VIP only option)"},
            {"Auto Join Guild", "Automatically checks if you are in a guild on login. If not, it joins SoloCraft (to prevent removal after inactivity)."},
            {"Reload UI", "Now you can reload UI using /rl or /reload ui without /console."},
            {"Party Bots", "(Add less than 5 bots won’t convert to raid) – useful for leveling."},
            {"Edit Presets In-Game", "You can now edit presets directly in-game."},
            {"Release Notes", "Only shown on first login for new releases."},
            {"Other Fixes", "• More accurate \"raid filling complete\" message."}
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


local function isNewerVersion(current, received)
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
                    else
                        QueueDebugMessage("INFO: Version " .. receivedVersion .. " already notified.", "debugversion")
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