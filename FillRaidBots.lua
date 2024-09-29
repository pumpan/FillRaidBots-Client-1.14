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

local botCount = 0
local initialBotRemoved = false
local firstBotName = nil
local messageQueue = {}
local delay = 0.5 -- Delay between messages
local nextUpdateTime = 0 -- Initialize the next update time

local classCounts = {}
local FillRaidFrame -- Declare global reference for your frame
local fillRaidFrameManualClose = false -- State variable to track manual close
local isCheckAndRemoveEnabled = false


if FillRaidBotsSavedSettings == nil then
    FillRaidBotsSavedSettings = {}
end

-- Initialize the saved setting for the toggle button
local function InitializeSettings()
    -- Initialize the setting for isCheckAndRemoveEnabled if not already set
    if FillRaidBotsSavedSettings.isCheckAndRemoveEnabled == nil then
        FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = false  -- Default to false
    end
end

-- Add messages to the queue
local function QueueMessage(message, recipient, incrementBotCount)
  table.insert(messageQueue,
      { message = message, recipient = recipient or "none", incrementBotCount = incrementBotCount or false })
end

-- Function to process and send chat messages from the queue
local function RemoveFirstBot()
    if firstBotName then
        QueueMessage("Attempting to uninvite: " .. firstBotName, "debug")
        UninviteUnit(firstBotName)

        if UnitExists(firstBotName) then
            QueueMessage("Botname removed: True", "debug")
            initialBotRemoved = true
        else
            QueueMessage("Botname removed: False", "debug")
        end
    else
        QueueMessage("Error: First bot's name not captured.", "debug")
    end
end


local function CreateRemoveBotButton()
    -- Create the button
    local removeBotButton = CreateFrame("Button", "RemoveFirstBotButton", UIParent, "UIPanelButtonTemplate")
    removeBotButton:SetSize(120, 30) -- Set button size
    removeBotButton:SetPoint("CENTER", UIParent, "CENTER", 0, -100) -- Set button position
    removeBotButton:SetText("Remove First Bot") -- Set button label
    removeBotButton:Hide() -- Initially hide the button

    -- Make the button movable
    removeBotButton:SetMovable(true)
    removeBotButton:SetUserPlaced(true) -- Allow the frame to remember its position
    removeBotButton:EnableMouse(true)
    removeBotButton:RegisterForDrag("LeftButton")

    -- Dragging behavior
    removeBotButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    removeBotButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Button script for removing the first bot
    removeBotButton:SetScript("OnClick", function()
        RemoveFirstBot() -- Call the function to remove the first bot
        removeBotButton:Hide() -- Hide the button after clicking
    end)

    -- Optional: Add tooltip
    removeBotButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(removeBotButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to remove the first bot from the raid. Drag to move.")
        GameTooltip:Show()
    end)

    removeBotButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return removeBotButton -- Return the button
end


-- Create the button when the addon loads
local removeBotButton = CreateRemoveBotButton()

local function ProcessMessageQueue()
    if next(messageQueue) ~= nil then -- Check if the queue is not empty
        local messageInfo = table.remove(messageQueue, 1)
        local message = messageInfo.message
        local recipient = messageInfo.recipient

        -- Handle debug messages: only display if debug mode is enabled
        if recipient == "debug" then
            if FillRaidBotsSavedSettings.debugMessagesEnabled then  
                DEFAULT_CHAT_FRAME:AddMessage(message)
            end
            return 
        end

        if recipient == "none" then
            -- Handle notifications (not sent in chat)
            DEFAULT_CHAT_FRAME:AddMessage(message)
        else
            -- Handle chat messages
            SendChatMessage(message, recipient) 
        end

        if messageInfo.incrementBotCount then
            botCount = botCount + 1
            
            if botCount == 5 and not initialBotRemoved then
                -- Show the button when 3 bots have been added
                removeBotButton:Show()
            end
        end
    end
end


-- Function to uninvite a specific member by their name 
function UninviteMember(name, reason)
    if name then
        UninviteUnit(name) -- Changed to UninviteUnit
        if reason == "dead" then
            QueueMessage(name .. " has been uninvited because they are dead.", "debug")
        elseif reason == "firstBotRemoved" then
            QueueMessage("10 bots added. Removing party bot: " .. name, "debug")
			firstBotName = nil
        end
    end
end


-- Function to check for dead bots and remove them
local messagecantremove = false

local function CreateRemoveDeadBotsButton()
    local removeDeadBotsButton = CreateFrame("Button", "RemoveDeadBotsButton", UIParent, "UIPanelButtonTemplate")
    removeDeadBotsButton:SetSize(120, 30)
    removeDeadBotsButton:SetPoint("CENTER", UIParent, "CENTER", 0, -140)
    removeDeadBotsButton:SetText("Remove Dead Bots")
    removeDeadBotsButton:Hide()

    -- Make the button movable
    removeDeadBotsButton:SetMovable(true)
    removeDeadBotsButton:EnableMouse(true)
    removeDeadBotsButton:RegisterForDrag("LeftButton")

    -- Define dragging behavior (removed Shift key condition)
    removeDeadBotsButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    removeDeadBotsButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Button functionality for removing dead bots
    removeDeadBotsButton:SetScript("OnClick", function()
        local deadBotsRemoved = false
        local playerName = UnitName("player")
        local activeMemberCount = 0
        local totalMemberCount = GetNumGroupMembers()

        -- Count active members
        for i = 1, totalMemberCount do
            local unit = "raid"..i
            if not UnitExists(unit) then
                unit = "party"..i
            end
            local name = UnitName(unit)

            if name and UnitExists(unit) and not UnitIsGhost(unit) then
                activeMemberCount = activeMemberCount + 1
            end
        end

        QueueMessage("Active members: " .. activeMemberCount, "debug")

        -- Remove dead bots
        if totalMemberCount > 2 then
            for i = 1, totalMemberCount do
                local unit = "raid"..i
                if not UnitExists(unit) then
                    unit = "party"..i
                end
                local name = UnitName(unit)

                if name and UnitIsDead(unit) and not UnitIsGhost(unit) and name ~= playerName then
                    if totalMemberCount > 2 then
                        UninviteUnit(name)
                        deadBotsRemoved = true
                        totalMemberCount = totalMemberCount - 1
                        QueueMessage("Removed dead bot: " .. name, "debug")
                    else
                        QueueMessage("Cannot remove, need at least 2 members in the raid.", "debug")
                    end
                end
            end
        else
            QueueMessage("Cannot remove dead bots, fewer than 2 members remain.", "debug")
        end

        if deadBotsRemoved then
            removeDeadBotsButton:Hide()
            QueueMessage("Dead bots removed. Button hidden.", "debug")
        end
    end)

    -- Tooltip for the button
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

local DeadBotsFrame = CreateFrame("Frame")

local function CheckAndRemoveDeadBots()
    if not FillRaidBotsSavedSettings.isCheckAndRemoveEnabled then return end
    local playerName = UnitName("player")
    local hasDeadBots = false
    local activeMemberCount = 0

	-- Check if we are in a raid and not the raid leader or officer
	if not UnitIsGroupLeader("player") and GetNumGroupMembers() > 0 and IsInRaid() then
		QueueMessage("You must be a raid leader to remove bots.", "debug")
		return

	end


    if GetNumGroupMembers() > 0 then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid"..i 
            if not UnitExists(unit) then 
                unit = "party"..i
            end
            local name = UnitName(unit)
            local health = UnitHealth(unit)

            -- Count active members (not dead or ghosts)
            if UnitExists(unit) and not UnitIsGhost(unit) and name ~= playerName then
                activeMemberCount = activeMemberCount + 1
            end

            -- Check if the member is dead and exists, but not the player
            if health == 0 and UnitExists(unit) and name ~= playerName then
                hasDeadBots = true
            end
        end
        
        -- Show the button only if there are dead bots and at least 2 active members remaining
        if hasDeadBots and activeMemberCount >= 2 then
            removeDeadBotsButton:Show() -- Show the button if there are dead bots
        else
            removeDeadBotsButton:Hide() -- Hide if no dead bots or not enough members
        end
    end
end

local function OnEvent(self, event, unit)
    if event == "UNIT_HEALTH" then
        CheckAndRemoveDeadBots() -- Call your function to check for dead bots
    elseif event == "GROUP_JOINED" or event == "GROUP_LEFT" then
        CheckAndRemoveDeadBots()
    end
end

-- Register events for health changes and group changes
DeadBotsFrame:RegisterEvent("GROUP_JOINED")
DeadBotsFrame:RegisterEvent("GROUP_LEFT")
DeadBotsFrame:RegisterEvent("UNIT_HEALTH")

-- Set the event handler
DeadBotsFrame:SetScript("OnEvent", OnEvent)




-- Function to save party member names and set the first bot's name
local function SavePartyMembersAndSetFirstBot()
    local partyMembers = {}
    local isInRaid = IsInRaid()  -- This function checks if you're in a raid in WoW Classic

    -- If in a raid, use "raid" units; otherwise, use "party" units
    if isInRaid then
        QueueMessage("In a raid group.", "debug")
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local name = UnitName(unit)
            if name then
                table.insert(partyMembers, name)
                QueueMessage("Found raid member: " .. name, "debug")
            else
                QueueMessage("No name found for raid unit " .. i, "debug")
            end
        end
    else
        QueueMessage("In a party group.", "debug")
        for i = 1, GetNumGroupMembers() - 1 do  -- -1 because "party1" to "party4", player is "player"
            local unit = "party" .. i
            local name = UnitName(unit)
            if name then
                table.insert(partyMembers, name)
            else
                QueueMessage("No name found for party unit " .. i, "debug")
            end
        end
    end

    -- Set firstBotName to the first party/raid member that's not the player
    local playerName = UnitName("player")
    QueueMessage("Player name is: " .. playerName, "debug")

    for _, member in ipairs(partyMembers) do
        if member ~= playerName then
            firstBotName = member
            break
        end
    end

    if firstBotName then
        QueueMessage("First bot set to: " .. firstBotName, "debug")
    else
        QueueMessage("Error: No bot found to set as the first bot.", "debug")
    end
end




function resetfirstbot_OnEvent(self, event)
    if event == "RAID_ROSTER_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
        -- Check if there are no party or raid members
        if GetNumGroupMembers() == 0 then
            initialBotRemoved = false
            firstBotName = nil
            botCount = 0
            QueueMessage("Bot state reset: No members in party or raid.", "debug")
        end
    end
end

-- Create a frame for handling the events
local resetBotFrame = CreateFrame("Frame")
resetBotFrame:RegisterEvent("RAID_ROSTER_UPDATE")
resetBotFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- Use GROUP_ROSTER_UPDATE instead
resetBotFrame:SetScript("OnEvent", resetfirstbot_OnEvent)


-- Function to handle the delayed sending of messages and notifications
local function ProcessMessages()
    ProcessMessageQueue()
    CheckAndRemoveDeadBots() -- Check for dead bots regularly
    nextUpdateTime = GetTime() + delay -- Set the next update time
end

local function StartTimer()
    C_Timer.After(delay, function()
        ProcessMessages()
		CheckAndRemoveDeadBots()
        StartTimer() -- Restart the timer
    end)
end

-- Start the timer for the first time
StartTimer()


function FillRaid_OnLoad(self, event, ...)
    if event == "ADDON_LOADED" and ... == "FillRaidBots" then
        -- Register other events
        self:RegisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent('RAID_ROSTER_UPDATE')
        self:RegisterEvent('GROUP_ROSTER_UPDATE')
        self:RegisterEvent("CHAT_MSG_SYSTEM")

        QueueMessage("FillRaid 1.0.0 Client 1.14 |cff00FF00 loaded|cffffffff", "none")
    end
end




local function FillRaid()
  -- Check if we are in a group (party or raid)
  if GetNumGroupMembers() == 0 then 
      -- Not in a group; add the first bot to create the party
      QueueMessage(".partybot add warrior tank", "SAY", true) 
      QueueMessage("Inviting the first bot to start the party.", "none")

      -- Create a frame to wait until the party is created, then continue filling
      local waitForPartyFrame = CreateFrame("Frame")
      waitForPartyFrame:SetScript("OnUpdate", function(self)
          if GetNumGroupMembers() > 0 then 
              self:SetScript("OnUpdate", nil) 
              self:Hide()
              SavePartyMembersAndSetFirstBot() -- Save party members and set the first bot
              FillRaid() -- Retry filling the raid now that the party is created
          end
      end)
      waitForPartyFrame:Show()
      return -- Exit temporarily to wait until the bot is added and the group is created
  end

  -- Check if we are in a raid
  if not IsInRaid() then
      -- In a party but not a raid; convert to raid if there are enough players
      if GetNumGroupMembers() >= 2 then
          ConvertToRaid()
          QueueMessage("Converted to raid.", "debug")
      else
          QueueMessage("You need at least 2 players in the group to convert to a raid.", "debug")
          return
      end
  end

  -- Now fill the raid based on the selected class counts
  for _, class in ipairs(classes) do
      local count = classCounts[class] or 0
      for i = 1, count do
          QueueMessage(".partybot add " .. class, "SAY", true) 
      end
  end

  QueueMessage("Raid filling complete.", "none")
end


-- Create the UI frame for class selection and the Fill Raid button
function CreateFillRaidUI()
    -- Create the main UI frame
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

    -- Manually add a background
	-- Create the FillRaidFrame background
	FillRaidFrame.background = FillRaidFrame:CreateTexture(nil, "BACKGROUND")
	FillRaidFrame.background:SetAllPoints(FillRaidFrame)
	FillRaidFrame.background:SetColorTexture(0, 0, 0, 0.8) -- Black background with 80% opacity

	-- Manually add a border
	FillRaidFrame.border = CreateFrame("Frame", nil, FillRaidFrame, BackdropTemplateMixin and "BackdropTemplate")
	FillRaidFrame.border:SetPoint("TOPLEFT", -4, 4)
	FillRaidFrame.border:SetPoint("BOTTOMRIGHT", 4, -4)
	FillRaidFrame.border:SetFrameLevel(0)
	FillRaidFrame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
	})
	FillRaidFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) -- Light gray border

	-- Add header background texture to FillRaidFrame
	FillRaidFrame.header = FillRaidFrame:CreateTexture(nil, 'OVERLAY') -- Change to OVERLAY to be above the border
	FillRaidFrame.header:SetWidth(250)
	FillRaidFrame.header:SetHeight(64)
	FillRaidFrame.header:SetPoint('TOP', FillRaidFrame, 0, 18)
	FillRaidFrame.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	FillRaidFrame.header:SetVertexColor(0.2, 0.2, 0.2)

	-- Add header text to FillRaidFrame
	FillRaidFrame.headerText = FillRaidFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal') -- Change to OVERLAY
	FillRaidFrame.headerText:SetPoint('TOP', FillRaidFrame.header, 0, -14)
	FillRaidFrame.headerText:SetText('Fill Raid')
	



    local yOffset = -30
    local xOffset = 20
    local totalBots = 0 

    -- Label to display the total number of bots
    local totalBotLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    totalBotLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    totalBotLabel:SetText("Total Bots: 0")
    yOffset = yOffset - 25

    -- Label to display the spots left
    local spotsLeftLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    spotsLeftLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    spotsLeftLabel:SetText("Spots Left: 39") -- Default value
    yOffset = yOffset - 25

    -- Label to display the role counts
    local roleCountsLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    roleCountsLabel:SetPoint("TOP", FillRaidFrame, "TOP", 0, yOffset)
    roleCountsLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    roleCountsLabel:SetText("Tanks: 0 Healers: 0 Melee DPS: 0 Ranged DPS: 0")
    yOffset = yOffset - 30

    -- Number of columns and rows
    local columns = 2
    local rowsPerColumn = 9
    local columnWidth = 150
    local rowHeight = 30

    -- Define role-based icons using built-in paths
    local roleIcons = {
        ["tank"] = "Interface\\Icons\\Ability_Defend",
        ["meleedps"] = "Interface\\Icons\\Ability_DualWield",
        ["rangedps"] = "Interface\\Icons\\Ability_Marksmanship",
        ["healer"] = "Interface\\Icons\\Spell_Holy_Heal",
    }


    -- Initialize role counts
    local roleCounts = {
        ["tank"] = 0,
        ["healer"] = 0,
        ["meleedps"] = 0,
        ["rangedps"] = 0,
    }

    -- Table to store input box references
    local inputBoxes = {}

    -- Function to split class and role using string.find
    local function SplitClassRole(classRole)
        local spaceIndex = string.find(classRole, " ")
        if spaceIndex then
            local class = string.sub(classRole, 1, spaceIndex - 1)
            local role = string.sub(classRole, spaceIndex + 1)
            return class, role
        end
        return classRole, nil
    end

    -- Create input boxes for each class with role
    for i, classRole in ipairs(classes) do
        local class, role = SplitClassRole(classRole)

        local index = i - 1
        local column = math.floor(index / rowsPerColumn)
        local row = index - column * rowsPerColumn

        local classXOffset = xOffset + (column * columnWidth)
        local classYOffset = yOffset - (row * rowHeight)

        local roleIcon = FillRaidFrame:CreateTexture(nil, "OVERLAY")
        roleIcon:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", classXOffset - 10, classYOffset)
        roleIcon:SetWidth(15)
        roleIcon:SetHeight(15)
        roleIcon:SetTexture(roleIcons[role] or "Interface\\Icons\\INV_Misc_QuestionMark")

		local classLabel = FillRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		classLabel:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", classXOffset + 10, classYOffset)
		classLabel:SetText(class .. " " .. (role or ""))
		classLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE") -- Set font, size, and outline


        local classInput = CreateFrame("EditBox", classRole .. "Input", FillRaidFrame, "InputBoxTemplate")
        classInput:SetWidth(20)
        classInput:SetHeight(15)
        classInput:SetPoint("TOPLEFT", FillRaidFrame, "TOPLEFT", classXOffset + 100, classYOffset)
        classInput:SetNumeric(true)
        classInput:SetNumber(0)

        -- Store reference in the table
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
                totalBotLabel:SetText("Too many added: " .. totalBots)
                spotsLeftLabel:SetText("Spots Left: 0")
            end
            roleCountsLabel:SetText(string.format("Tanks: %d Healers: %d Melee DPS: %d Ranged DPS: %d",
                roleCounts["tank"], roleCounts["healer"], roleCounts["meleedps"], roleCounts["rangedps"]))
        end)
    end

	  -- Create the Fill Raid button
	  local fillRaidButton = CreateFrame("Button", nil, FillRaidFrame, "GameMenuButtonTemplate")
	  fillRaidButton:SetPoint("BOTTOM", FillRaidFrame, "BOTTOM", -60, 20)
	  fillRaidButton:SetWidth(120)
	  fillRaidButton:SetHeight(40)
	  fillRaidButton:SetText("Fill Raid")

	  fillRaidButton:SetScript("OnClick", function()
		  FillRaid()  
		  FillRaidFrame:Hide()  
	  end)


	  -- Create the Close button
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
	UISettingsFrame:SetHeight(350)
	UISettingsFrame:SetPoint("LEFT", FillRaidFrame, "RIGHT", 10, 0)

	-- Manually create the background
	UISettingsFrame.background = UISettingsFrame:CreateTexture(nil, "BACKGROUND")
	UISettingsFrame.background:SetAllPoints(UISettingsFrame)
	UISettingsFrame.background:SetColorTexture(0, 0, 0, 1) -- Solid black background

	-- Manually create the border
	UISettingsFrame.border = CreateFrame("Frame", nil, UISettingsFrame, BackdropTemplateMixin and "BackdropTemplate")
	UISettingsFrame.border:SetPoint("TOPLEFT", -4, 4)
	UISettingsFrame.border:SetPoint("BOTTOMRIGHT", 4, -4)
	UISettingsFrame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", -- Same edge file as before
		edgeSize = 16,
	})
	UISettingsFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) -- Light gray border

	UISettingsFrame:SetFrameStrata("DIALOG")
	UISettingsFrame:SetFrameLevel(10)
	UISettingsFrame:Hide()

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


    -- Create the Instance Buttons Frame
	local InstanceButtonsFrame = CreateFrame("Frame", "InstanceButtonsFrame", UIParent)
	InstanceButtonsFrame:SetWidth(200)
	InstanceButtonsFrame:SetHeight(350)
	InstanceButtonsFrame:SetPoint("LEFT", FillRaidFrame, "RIGHT", 10, 0)

	-- Manually create the background
	InstanceButtonsFrame.background = InstanceButtonsFrame:CreateTexture(nil, "BACKGROUND")
	InstanceButtonsFrame.background:SetAllPoints(InstanceButtonsFrame)
	InstanceButtonsFrame.background:SetColorTexture(0, 0, 0, 1) -- Solid black background

	-- Manually create the border
	InstanceButtonsFrame.border = CreateFrame("Frame", nil, InstanceButtonsFrame, BackdropTemplateMixin and "BackdropTemplate")
	InstanceButtonsFrame.border:SetPoint("TOPLEFT", -4, 4)
	InstanceButtonsFrame.border:SetPoint("BOTTOMRIGHT", 4, -4)
	InstanceButtonsFrame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", -- Same edge file as before
		edgeSize = 16,
	})
	InstanceButtonsFrame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) -- Light gray border

	InstanceButtonsFrame:SetFrameStrata("DIALOG")
	InstanceButtonsFrame:SetFrameLevel(10)
	InstanceButtonsFrame:Hide()


    local instanceButtons = {}
    local function CreateInstanceButton(label, yOffset, frameName)
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
            local frame = instanceFrames[frameName]
            if frame then
                frame:Show()
            else
                print("Error: Frame '" .. frameName .. "' not found.")
            end
        end)
        return button
    end

    -- Create instance buttons
    CreateInstanceButton("Naxxramas", -10, "PresetDungeounNaxxramas")
    CreateInstanceButton("BWL", -50, "PresetDungeounBWL")
    CreateInstanceButton("MC", -90, "PresetDungeounMC")
    CreateInstanceButton("Onyxia", -130, "PresetDungeounOnyxia")
    CreateInstanceButton("AQ40", -170, "PresetDungeounAQ40")
    CreateInstanceButton("AQ20", -210, "PresetDungeounAQ20")	
    CreateInstanceButton("ZG", -250, "PresetDungeounZG")	
	CreateInstanceButton("Other", -290, "PresetDungeounOther")


    -- Function to create instance frames with error checking
local function CreateInstanceFrame(name, presets)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetWidth(200)
	frame:SetHeight(350)
	frame:SetPoint("LEFT", FillRaidFrame, "RIGHT", 10, 0)

	-- Manually create the background
	frame.background = frame:CreateTexture(nil, "BACKGROUND")
	frame.background:SetAllPoints(frame)
	frame.background:SetColorTexture(0, 0, 0, 1) -- Solid black background

	-- Manually create the border
	frame.border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	frame.border:SetPoint("TOPLEFT", -4, 4)
	frame.border:SetPoint("BOTTOMRIGHT", 4, -4)
	frame.border:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", -- Same edge file as before
		edgeSize = 16,
	})
	frame.border:SetBackdropBorderColor(0.8, 0.8, 0.8) -- Light gray border

	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(10)
	frame:Hide()

	local buttonWidth = 80
	local buttonHeight = 30
	local padding = 10
	local maxButtonsPerColumn = 8


    -- Calculate total width and height needed for buttons
    local totalButtonWidth = buttonWidth + padding
    local totalButtonHeight = buttonHeight + padding
    local numButtons = table.getn(presets)
    local numColumns = math.ceil(numButtons / maxButtonsPerColumn)
    local fixedStartY = -10 

    -- Function to create preset buttons
    local function CreatePresetButton(preset, index)
        local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        button:SetWidth(buttonWidth)
        button:SetHeight(buttonHeight)
        button:SetText(preset.label or "Unknown preset") 

        -- Calculate column and row based on index
        local column = math.floor((index - 1) / maxButtonsPerColumn)
        local row = (index - 1) - (column * maxButtonsPerColumn)

        -- Position the button
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", (frame:GetWidth() - (numColumns * totalButtonWidth - padding)) / 2 + (column * totalButtonWidth), fixedStartY - (row * totalButtonHeight))

        -- OnClick function with additional debug info
        button:SetScript("OnClick", function()
            -- Reset all input boxes to zero
            for classRole, inputBox in pairs(inputBoxes) do
                if inputBox then
                    inputBox:SetNumber(0)
                    local onTextChanged = inputBox:GetScript("OnTextChanged")
                    if onTextChanged then
                        onTextChanged(inputBox) 
                    end
                end
            end

            -- Populate the input boxes with preset values
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
        end)

        -- OnEnter function to show tooltip
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(preset.tooltip or "No tooltip available")
            GameTooltip:Show()
        end)

        -- OnLeave function to hide tooltip
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- Create buttons
    for index, preset in ipairs(presets) do
        CreatePresetButton(preset, index)
    end

    return frame
end





    -- Create instance frames
    instanceFrames = {}

    instanceFrames["PresetDungeounNaxxramas"] = CreateInstanceFrame("PresetDungeounNaxxramas", naxxramasPresets)
    instanceFrames["PresetDungeounBWL"] = CreateInstanceFrame("PresetDungeounBWL", bwlPresets)
    instanceFrames["PresetDungeounMC"] = CreateInstanceFrame("PresetDungeounMC", mcPresets)
    instanceFrames["PresetDungeounOnyxia"] = CreateInstanceFrame("PresetDungeounOnyxia", onyxiaPresets)
    instanceFrames["PresetDungeounAQ40"] = CreateInstanceFrame("PresetDungeounAQ40", aq40Presets)
    instanceFrames["PresetDungeounAQ20"] = CreateInstanceFrame("PresetDungeounAQ20", aq20Presets)	
    instanceFrames["PresetDungeounZG"] = CreateInstanceFrame("PresetDungeounZG", ZGPresets)	
	instanceFrames["PresetDungeounOther"] = CreateInstanceFrame("PresetDungeounOther", otherPresets)

    -- Modify the button to open InstanceButtonsFrame
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
	

		

-- Create the Reset button
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

    -- Reset total bot counts and role counts
    totalBotLabel:SetText("Total Bots: 0")
    spotsLeftLabel:SetText("Spots Left: 39")
    roleCountsLabel:SetText("Tanks: 0 Healers: 0 Melee DPS: 0 Ranged DPS: 0")
end)



  -- Create a full-screen ClickBlockerFrame to handle clicks outside PresetFrame
local ClickBlockerFrame = CreateFrame("Frame", "ClickBlockerFrame", UIParent)
ClickBlockerFrame:SetAllPoints(UIParent) -- Covers the entire screen
ClickBlockerFrame:EnableMouse(true) -- Captures mouse clicks
ClickBlockerFrame:SetFrameStrata("DIALOG") -- Same strata as PresetFrame
ClickBlockerFrame:SetFrameLevel(1) -- Below PresetFrame
ClickBlockerFrame:SetScript("OnMouseDown", function()
    ClickBlockerFrame:Hide() 
    InstanceButtonsFrame:Hide() 
	UISettingsFrame:Hide()
    for frameName, frame in pairs(instanceFrames) do
        if frame:IsShown() then
            frame:Hide()
        end
    end
end)
ClickBlockerFrame:Hide() 


	-- Create the "Open FillRaid" button
	local openFillRaidButton = CreateFrame("Button", "OpenFillRaidButton", UIParent)
	openFillRaidButton:SetWidth(40)
	openFillRaidButton:SetHeight(100)


	-- Set the button's texture to the .tga image
	openFillRaidButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\fillraid")
	-- Optional: You can also set different textures for button states (hover, clicked)
	openFillRaidButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")  -- Hover effect
	openFillRaidButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\fillraid")  -- Click effect

	-- Set the OnClick behavior
	openFillRaidButton:SetScript("OnClick", function()
		if FillRaidFrame:IsShown() then
			FillRaidFrame:Hide()
			fillRaidFrameManualClose = true
		else
			FillRaidFrame:Show()
			fillRaidFrameManualClose = false
		end
	end)

	openFillRaidButton:Hide()

	-- Create the "Kick All" button below OpenFillRaidButton
	local kickAllButton = CreateFrame("Button", "OpenFillRaidButton", UIParent)
	kickAllButton:SetWidth(40)
	kickAllButton:SetHeight(100)
	
	kickAllButton:SetNormalTexture("Interface\\AddOns\\fillraidbots\\img\\kickall")
	-- Optional: You can also set different textures for button states (hover, clicked)
	kickAllButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")  -- Hover effect
	kickAllButton:SetPushedTexture("Interface\\AddOns\\fillraidbots\\img\\kickall")  -- Click effect


	kickAllButton:SetScript("OnClick", function()
		UninviteAllRaidMembers()  
	end)
	kickAllButton:Hide() 

	-- Function to update the position of the openFillRaidButton and kickAllButton relative to PCPFrame
	local function UpdateButtonPosition()
		if PCPFrame and PCPFrame:IsVisible() then
			-- Position OpenFillRaidButton
			openFillRaidButton:ClearAllPoints()
			openFillRaidButton:SetPoint("RIGHT", PCPFrame, "LEFT", 0, 250)

			-- Position KickAllButton below OpenFillRaidButton
			kickAllButton:ClearAllPoints()
			kickAllButton:SetPoint("TOP", openFillRaidButton, "BOTTOM", 0, -10) -- Adjust position to be under OpenFillRaidButton
		end
	end

	-- Create a frame to periodically check the visibility of PCPFrame
	local visibilityFrame = CreateFrame("Frame")
	visibilityFrame:SetScript("OnUpdate", function()
		if PCPFrame and PCPFrame:IsVisible() then
			UpdateButtonPosition()
			if not fillRaidFrameManualClose and not openFillRaidButton:IsShown() then
				openFillRaidButton:Show()
			end
			if not kickAllButton:IsShown() then
				kickAllButton:Show()
			end
		elseif PCPFrame and not PCPFrame:IsVisible() then
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

-- Call the function to create the UI when the addon is loaded
CreateFillRaidUI()
InitializeSettings()


-- Table to keep track of the last time a message was shown
local messageCooldowns = {}

-- Function to check if the message should be shown based on cooldown
local function shouldShowMessage(message)
    local currentTime = GetTime() 
    for pattern, cooldown in pairs(messagesToHide) do
        if string.find(message, pattern) then
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

-- Hook the default chat frame's AddMessage function
local function HideBotMessages(self, message, r, g, b, id)
    -- Only hide messages if the setting is enabled
    if not FillRaidBotsSavedSettings.isBotMessagesEnabled then
        self:OriginalAddMessage(message, r, g, b, id)
        return
    end

    -- Proceed with the normal message filtering logic
    if not shouldShowMessage(message) then
        return -- Do nothing, effectively hiding the message
    end

    self:OriginalAddMessage(message, r, g, b, id)
end

-- Apply the hook to all chat frames
for i = 1, 7 do
    local chatFrame = getglobal("ChatFrame" .. i)
    if chatFrame and not chatFrame.OriginalAddMessage then
        chatFrame.OriginalAddMessage = chatFrame.AddMessage
        chatFrame.AddMessage = HideBotMessages
    end
end


function UninviteAllRaidMembers()
    initialBotRemoved = false
    firstBotName = nil
    botCount = 0
    local playerName = UnitName("player")
    local remainingMembers = {}

    -- Gather all valid members except the player
    for i = 1, GetNumGroupMembers() do
        local unit = "raid"..i
        if not UnitExists(unit) then
            unit = "party"..i
        end
        local name = UnitName(unit)
        if name and name ~= playerName then
            table.insert(remainingMembers, name)
        end
    end

    -- If only one member remains, stop to avoid disbanding the raid
    if #remainingMembers < 1 then
        QueueMessage("Cannot remove members, only 1 member left.", "debug")
        return
    end

    -- Uninvite all except the first one to prevent disbanding
    for i = 2, #remainingMembers do
        UninviteUnit(remainingMembers[i])
    end

    -- Debug message
    QueueMessage("Removed " .. (#remainingMembers - 1) .. " members. 1 remains.", "debug")
end


SLASH_UNINVITE1 = "/uninviteraid"
SlashCmdList["UNINVITE"] = UninviteAllRaidMembers
