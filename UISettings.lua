
local function FillRaidBots_OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == "FillRaidBots" then
        FillRaidBots_LoadSettings()
    elseif event == "PLAYER_LOGOUT" then
        FillRaidBots_SaveSettings()
    end
end

local settingsLoaded = false


function FillRaidBots_SaveSettings()
    if ToggleCheckAndRemoveCheckButton then
        FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = ToggleCheckAndRemoveCheckButton:GetChecked() and true or false
    end
    if BotMessagesCheckButton then
        FillRaidBotsSavedSettings.isBotMessagesEnabled = BotMessagesCheckButton:GetChecked() and true or false
    end
    if DebugMessagesCheckButton then
        FillRaidBotsSavedSettings.debugMessagesEnabled = DebugMessagesCheckButton:GetChecked() and true or false
    end
    if moveButtonsCheckButton then
        FillRaidBotsSavedSettings.moveButtonsEnabled = moveButtonsCheckButton:GetChecked() and true or false
    end
    if RefillButtonCheckButton then
        FillRaidBotsSavedSettings.isRefillEnabled = RefillButtonCheckButton:GetChecked() and true or false
    end
    if SmallButtonCheckButton then
        FillRaidBotsSavedSettings.isSmallEnabled = SmallButtonCheckButton:GetChecked() and true or false
    end

    if AutoFFACheckButton then
        FillRaidBotsSavedSettings.isFFAEnabled = AutoFFACheckButton:GetChecked() and true or false
    end
    if AutoGroupLootCheckButton then
        FillRaidBotsSavedSettings.isGroupLootEnabled = AutoGroupLootCheckButton:GetChecked() and true or false
    end	
    if AutoMasterLootCheckButton then
        FillRaidBotsSavedSettings.isMasterLootEnabled = AutoMasterLootCheckButton:GetChecked() and true or false
    end
    if ClickToFillCheckButton then
        FillRaidBotsSavedSettings.isClickToFillEnabled = ClickToFillCheckButton:GetChecked() and true or false
    end
    if AutoRepairCheckButton then
        FillRaidBotsSavedSettings.isAutoRepairEnabled = AutoRepairCheckButton:GetChecked() and true or false
    end
    if AutoJoinGuildCheckButton then
        FillRaidBotsSavedSettings.isAutoJoinGuildEnabled = AutoJoinGuildCheckButton:GetChecked() and true or false
    end
    if AutoMuteSoundCheckButton then
        FillRaidBotsSavedSettings.isAutoMuteSoundEnabled = AutoMuteSoundCheckButton:GetChecked() and true or false
    end	
    if removeDeadBotsButtonCheckButton then
        FillRaidBotsSavedSettings.isremoveDeadBotsButtonEnabled = removeDeadBotsButtonEnabled:GetChecked() and true or false
    end		
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", FillRaidBots_OnEvent)


function CreateUISectionHeader(parentFrame, anchorTo, label, offsetX, offsetY)
    local header = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX or 0, offsetY or -20)
    header:SetText(label)

    local separator = parentFrame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(2)
    separator:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    separator:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -10, 0)
    separator:SetTexture("Interface\\Buttons\\WHITE8x8")
    separator:SetVertexColor(1, 1, 1, 0.8)

    return header, separator
end

local function CreateToggleCheckButton()

	local mainHeader, mainSeparator = CreateUISectionHeader(UISettingsFrame, UISettingsFrame, "Main", 10, -20)
    
    local checkButton = CreateFrame("CheckButton", "ToggleCheckAndRemoveCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    checkButton:SetWidth(20)
    checkButton:SetHeight(20)
    checkButton:SetPoint("TOPLEFT", mainSeparator, "TOPLEFT", 0, -10)

    
    checkButton.text = checkButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkButton.text:SetPoint("LEFT", checkButton, "RIGHT", 5, 0)
    checkButton.text:SetText("Auto remove dead")

    checkButton:SetChecked(FillRaidBotsSavedSettings.isCheckAndRemoveEnabled)

	checkButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = isChecked
		
	
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Remove Dead Bots: "..status)
	end)

    checkButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(checkButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, dead bots will be automatically removed from the raid or party.")
        GameTooltip:Show()
    end)
    checkButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    
local botMessagesCheckButton = CreateFrame("CheckButton", "BotMessagesCheckButton", UISettingsFrame, "UICheckButtonTemplate")
botMessagesCheckButton:SetWidth(20)
botMessagesCheckButton:SetHeight(20)
botMessagesCheckButton:SetPoint("TOPLEFT", checkButton, "TOPLEFT", 0, -20)

botMessagesCheckButton.text = botMessagesCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
botMessagesCheckButton.text:SetPoint("LEFT", botMessagesCheckButton, "RIGHT", 5, 0)
botMessagesCheckButton.text:SetText("Suppress Messages")

botMessagesCheckButton:SetChecked(FillRaidBotsSavedSettings.isBotMessagesEnabled)

local SuppressEditorButton = CreateFrame("Button", nil, UISettingsFrame, "GameMenuButtonTemplate")
SuppressEditorButton:SetText("Suppress")
SuppressEditorButton:SetWidth(80)
SuppressEditorButton:SetHeight(20)
SuppressEditorButton:SetPoint("TOPLEFT", botMessagesCheckButton, "TOPLEFT", 0, -20)
SuppressEditorButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(SuppressEditorButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Add/Edit Messages to be Suppressed")
    GameTooltip:Show()
end)
SuppressEditorButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
SuppressEditorButton:SetScript("OnClick", function()
    if SuppressEditor:IsShown() then
        SuppressEditor:Hide()
    else
        RefreshSuppressList()
        SuppressEditor:Show()
    end
end)

if FillRaidBotsSavedSettings.isBotMessagesEnabled then
    SuppressEditorButton:Enable()
else
    SuppressEditorButton:Disable()
end

botMessagesCheckButton:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    FillRaidBotsSavedSettings.isBotMessagesEnabled = isChecked

   
    if isChecked then
        SuppressEditorButton:Enable()
    else
        SuppressEditorButton:Disable()
    end

    local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
    DEFAULT_CHAT_FRAME:AddMessage("Bot Messages: "..status)
end)

botMessagesCheckButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(botMessagesCheckButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("When enabled, bot messages will be suppressed.")
    GameTooltip:Show()
end)
botMessagesCheckButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


------------------------------------------------------------------------



	local ClickToFillCheackButton = CreateFrame("CheckButton", "ClickToFillCheackButton", UISettingsFrame, "UICheckButtonTemplate")
	ClickToFillCheackButton:SetSize(20, 20)
	ClickToFillCheackButton:SetPoint("TOPLEFT", SuppressEditorButton, "TOPLEFT", 0, -20)


	ClickToFillCheackButton.text = ClickToFillCheackButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ClickToFillCheackButton.text:SetPoint("LEFT", ClickToFillCheackButton, "RIGHT", 5, 0)
	ClickToFillCheackButton.text:SetText("Click-To-Fill")


	ClickToFillCheackButton:SetChecked(FillRaidBotsSavedSettings.isClickToFillEnabled)
	ToggleClickToFill(FillRaidBotsSavedSettings.isClickToFillEnabled)

	ClickToFillCheackButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isClickToFillEnabled = isChecked
		ToggleClickToFill(isChecked)
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Click-To-Fill mode: "..status)		
	end)

    ClickToFillCheackButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(ClickToFillCheackButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, will allow you to hold ctrl+alt+clicking the boss to fill the raid.")
        GameTooltip:Show()
    end)
    ClickToFillCheackButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
	local AutoRepairCheckButton = CreateFrame("CheckButton", "AutoRepairCheckButton", UISettingsFrame, "UICheckButtonTemplate")
	AutoRepairCheckButton:SetHeight(20)
	AutoRepairCheckButton:SetWidth(20)
	AutoRepairCheckButton:SetPoint("TOPLEFT", ClickToFillCheackButton, "TOPLEFT", 0, -20) 


	AutoRepairCheckButton.text = AutoRepairCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	AutoRepairCheckButton.text:SetPoint("LEFT", AutoRepairCheckButton, "RIGHT", 5, 0)
	AutoRepairCheckButton.text:SetText("Auto Repair")


	AutoRepairCheckButton:SetChecked(FillRaidBotsSavedSettings.isAutoRepairEnabled)
	ToggleAutoRepair(FillRaidBotsSavedSettings.isAutoRepairEnabled)

	AutoRepairCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isAutoRepairEnabled = isChecked
		ToggleAutoRepair(isChecked)
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Auto Repair: "..status)		
	end)

    AutoRepairCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(AutoRepairCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, allows FillRaidBots to automatically repair after resurrection. \nVIP ONLY")
        GameTooltip:Show()
    end)
    AutoRepairCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end) 
  
 
	local AutoJoinGuildCheckButton = CreateFrame("CheckButton", "AutoJoinGuildCheckButton", UISettingsFrame, "UICheckButtonTemplate")
	AutoJoinGuildCheckButton:SetHeight(20)
	AutoJoinGuildCheckButton:SetWidth(20)
	AutoJoinGuildCheckButton:SetPoint("TOPLEFT", AutoRepairCheckButton, "TOPLEFT", 0, -20)


	AutoJoinGuildCheckButton.text = AutoJoinGuildCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	AutoJoinGuildCheckButton.text:SetPoint("LEFT", AutoJoinGuildCheckButton, "RIGHT", 5, 0)
	AutoJoinGuildCheckButton.text:SetText("Auto Join Guild")


	AutoJoinGuildCheckButton:SetChecked(FillRaidBotsSavedSettings.isAutoJoinGuildEnabled)
	ToggleAutoJoinGuild(FillRaidBotsSavedSettings.isAutoJoinGuildEnabled)

	AutoJoinGuildCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isAutoJoinGuildEnabled = isChecked
		ToggleAutoJoinGuild(isChecked)
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Auto join guild: "..status)		
	end)

    AutoJoinGuildCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(AutoJoinGuildCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, will allow FillRaidBots to \nautomaticaly join the SoloCraft guild.")
        GameTooltip:Show()
    end)
    AutoJoinGuildCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end) 

	local AutoMuteSoundCheckButton = CreateFrame("CheckButton", "AutoMuteSoundCheckButton", UISettingsFrame, "UICheckButtonTemplate")
	AutoMuteSoundCheckButton:SetHeight(20)
	AutoMuteSoundCheckButton:SetWidth(20)
	AutoMuteSoundCheckButton:SetPoint("TOPLEFT", AutoJoinGuildCheckButton, "TOPLEFT", 0, -20)


	AutoMuteSoundCheckButton.text = AutoMuteSoundCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	AutoMuteSoundCheckButton.text:SetPoint("LEFT", AutoMuteSoundCheckButton, "RIGHT", 5, 0)
	AutoMuteSoundCheckButton.text:SetText("Auto Lower sound")


	AutoMuteSoundCheckButton:SetChecked(FillRaidBotsSavedSettings.isAutoMuteSoundEnabled)
	ToggleAutoMuteSound(FillRaidBotsSavedSettings.isAutoMuteSoundEnabled)

	AutoMuteSoundCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isAutoMuteSoundEnabled = isChecked
		ToggleAutoMuteSound(isChecked)
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Auto Lower sound: "..status)		
	end)

    AutoMuteSoundCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(AutoMuteSoundCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, will lower Sound effects \nautomaticaly while filling raid.")
        GameTooltip:Show()
    end)
    AutoMuteSoundCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end) 

	local ButtonsHeader, mainSeparator = CreateUISectionHeader(UISettingsFrame, AutoMuteSoundCheckButton, "Buttons", 0, -25)

	local removeDeadBotsCheckButton = CreateFrame("CheckButton", "removeDeadBotsCheckButton", UISettingsFrame, "UICheckButtonTemplate")
	removeDeadBotsCheckButton:SetHeight(20)
	removeDeadBotsCheckButton:SetWidth(20)
	removeDeadBotsCheckButton:SetPoint("TOPLEFT", ButtonsHeader, "TOPLEFT", 0, -20)


	removeDeadBotsCheckButton.text = removeDeadBotsCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	removeDeadBotsCheckButton.text:SetPoint("LEFT", removeDeadBotsCheckButton, "RIGHT", 5, 0)
	removeDeadBotsCheckButton.text:SetText("Dead bots Button")


	removeDeadBotsCheckButton:SetChecked(FillRaidBotsSavedSettings.isremoveDeadBotsButtonEnabled)
	ToggleremoveDeadBots(FillRaidBotsSavedSettings.isremoveDeadBotsButtonEnabled)

	removeDeadBotsCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isremoveDeadBotsButtonEnabled = isChecked
		ToggleremoveDeadBots(isChecked)
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Remove dead bots button: "..status)		
	end)

    removeDeadBotsCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(removeDeadBotsCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, A remove dead bots button will appear when there is dead bots.")
        GameTooltip:Show()
    end)
    removeDeadBotsCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end) 


    local moveButtonsCheckButton = CreateFrame("CheckButton", "moveButtonsCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    moveButtonsCheckButton:SetWidth(20)
    moveButtonsCheckButton:SetHeight(20)
    moveButtonsCheckButton:SetPoint("TOPLEFT", removeDeadBotsCheckButton, "TOPLEFT", 0, -20)

    moveButtonsCheckButton.text = moveButtonsCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moveButtonsCheckButton.text:SetPoint("LEFT", moveButtonsCheckButton, "RIGHT", 5, 0)
    moveButtonsCheckButton.text:SetText("Enable moving buttons")

    moveButtonsCheckButton:SetChecked(FillRaidBotsSavedSettings.moveButtonsEnabled)

	moveButtonsCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.moveButtonsEnabled = isChecked
		ToggleButtonMovement(OpenFillRaidButton)
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Button Movement: "..status)
	end)
    moveButtonsCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(moveButtonsCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Enable moving of fillraid and kick all buttons.")
        GameTooltip:Show()
    end)
    moveButtonsCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


    local refillCheckButton = CreateFrame("CheckButton", "RefillButtonCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    refillCheckButton:SetWidth(20)
    refillCheckButton:SetHeight(20)
    refillCheckButton:SetPoint("TOPLEFT", moveButtonsCheckButton, "TOPLEFT", 0, -20)

    refillCheckButton.text = refillCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    refillCheckButton.text:SetPoint("LEFT", refillCheckButton, "RIGHT", 5, 0)
    refillCheckButton.text:SetText("Enable Refill Button")

    refillCheckButton:SetChecked(FillRaidBotsSavedSettings.isRefillEnabled)

    refillCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isRefillEnabled = isChecked
		UpdateReFillButtonVisibility()
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Refill Button: "..status)
    end)

    refillCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(refillCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, the Refill Button will be available.")
        GameTooltip:Show()
    end)
    refillCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local SmallCheckButton = CreateFrame("CheckButton", "SmallButtonCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    SmallCheckButton:SetWidth(20)
    SmallCheckButton:SetHeight(20)
    SmallCheckButton:SetPoint("TOPLEFT", refillCheckButton, "TOPLEFT", 0, -20)

    SmallCheckButton.text = SmallCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SmallCheckButton.text:SetPoint("LEFT", SmallCheckButton, "RIGHT", 5, 0)
    SmallCheckButton.text:SetText("Enable Small Buttons")

    SmallCheckButton:SetChecked(FillRaidBotsSavedSettings.isSmallEnabled)
	if FillRaidBotsSavedSettings.isSmallEnabled then 
		ToggleSmallbuttonCheck(FillRaidBotsSavedSettings.isSmallEnabled)
	end

	SmallCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isSmallEnabled = isChecked
		ToggleSmallbuttonCheck(isChecked)
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Small Buttons: "..status)
	end)



    SmallCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(SmallCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, The buttons will be small.")
        GameTooltip:Show()
    end)
    SmallCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
 
-----------------------------------------auto loot option --------------------------------
local LootTypeHeader = UISettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
LootTypeHeader:SetPoint("TOPLEFT", SmallCheckButton, "TOPLEFT", 0, -20)
LootTypeHeader:SetText("Loot Type")

local LootTypeSeparator = UISettingsFrame:CreateTexture(nil, "ARTWORK")
LootTypeSeparator:SetHeight(2) 
LootTypeSeparator:SetPoint("TOPLEFT", LootTypeHeader, "BOTTOMLEFT", 0, -2)
LootTypeSeparator:SetPoint("TOPRIGHT", UISettingsFrame, "TOPRIGHT", -10, -232)
LootTypeSeparator:SetTexture("Interface\\Buttons\\WHITE8x8") 
LootTypeSeparator:SetVertexColor(1, 1, 1, 0.8) 

local checkboxYOffset = -20 


local AutoFFACheckButton = CreateFrame("CheckButton", "AutoFFACheckButton", UISettingsFrame, "UICheckButtonTemplate")
AutoFFACheckButton:SetSize(20, 20)
AutoFFACheckButton:SetPoint("TOPLEFT", LootTypeSeparator, "TOPLEFT", 10, checkboxYOffset)
    AutoFFACheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(AutoFFACheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, puts FFA automatically on raid creation")
        GameTooltip:Show()
    end)
    AutoFFACheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
local AutoFFAText = UISettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AutoFFAText:SetPoint("BOTTOM", AutoFFACheckButton, "TOP", 0, 2)
AutoFFAText:SetText("FFA")

local AutoGroupLootCheckButton = CreateFrame("CheckButton", "AutoGroupLootCheckButton", UISettingsFrame, "UICheckButtonTemplate")
AutoGroupLootCheckButton:SetSize(20, 20)
AutoGroupLootCheckButton:SetPoint("LEFT", AutoFFACheckButton, "RIGHT", 40, 0)
    AutoGroupLootCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(AutoFFACheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, puts Group loot automatically on raid creation")
        GameTooltip:Show()
    end)
    AutoGroupLootCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
local AutoGroupLootText = UISettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AutoGroupLootText:SetPoint("BOTTOM", AutoGroupLootCheckButton, "TOP", 0, 2)
AutoGroupLootText:SetText("Group")

local AutoMasterLootCheckButton = CreateFrame("CheckButton", "AutoMasterLootCheckButton", UISettingsFrame, "UICheckButtonTemplate")
AutoMasterLootCheckButton:SetSize(20, 20)
AutoMasterLootCheckButton:SetPoint("LEFT", AutoGroupLootCheckButton, "RIGHT", 40, 0)
    AutoMasterLootCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(AutoFFACheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, puts Master loot automatically on raid creation")
        GameTooltip:Show()
    end)
    AutoMasterLootCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
local AutoMasterLootText = UISettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AutoMasterLootText:SetPoint("BOTTOM", AutoMasterLootCheckButton, "TOP", 0, 2)
AutoMasterLootText:SetText("Master")

local function SetLootOption(selectedLootType)
    AutoFFACheckButton:SetChecked(selectedLootType == "freeforall")
    AutoGroupLootCheckButton:SetChecked(selectedLootType == "group")
    AutoMasterLootCheckButton:SetChecked(selectedLootType == "master")
end

AutoFFACheckButton:SetScript("OnClick", function(self)
    SetLootOption("freeforall")
    DEFAULT_CHAT_FRAME:AddMessage("Loot Method set to |cFF00FF00Free-for-All|r")
end)

AutoGroupLootCheckButton:SetScript("OnClick", function(self)
    SetLootOption("group")
    DEFAULT_CHAT_FRAME:AddMessage("Loot Method set to |cFF00FF00Group Loot|r")
end)

AutoMasterLootCheckButton:SetScript("OnClick", function(self)
    SetLootOption("master")
    DEFAULT_CHAT_FRAME:AddMessage("Loot Method set to |cFF00FF00Master Loot|r")
end)

if FillRaidBotsSavedSettings.isFFAEnabled then
    SetLootOption("freeforall")
elseif FillRaidBotsSavedSettings.isGroupLootEnabled then
    SetLootOption("group")
elseif FillRaidBotsSavedSettings.isMasterLootEnabled then
    SetLootOption("master")
else
   
    SetLootOption("group")
end

----------------------------------------------------------------------------------------------
 
    local debugMessagesCheckButton = CreateFrame("CheckButton", "DebugMessagesCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    debugMessagesCheckButton:SetWidth(20)
    debugMessagesCheckButton:SetHeight(20)
    debugMessagesCheckButton:SetPoint("TOPLEFT", AutoFFACheckButton, "TOPLEFT", -5, -20)

    debugMessagesCheckButton.text = debugMessagesCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugMessagesCheckButton.text:SetPoint("LEFT", debugMessagesCheckButton, "RIGHT", 5, 0)
    debugMessagesCheckButton.text:SetText("Enable Debug")

    debugMessagesCheckButton:SetChecked(FillRaidBotsSavedSettings.debugMessagesEnabled)

	debugMessagesCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.debugMessagesEnabled = isChecked
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Debugging: " .. status)
		if isChecked then
			debuggerFrame:Show()
		else
			debuggerFrame:Hide()
		end
	end)


    debugMessagesCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(debugMessagesCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, debug messages will be shown.")
        GameTooltip:Show()
    end)
    debugMessagesCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


	
end


function FillRaidBots_LoadSettings()
    if settingsLoaded then return end
    settingsLoaded = true

    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    
    if FillRaidBotsSavedSettings.isCheckAndRemoveEnabled == nil then
        FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = true 
    end

    if FillRaidBotsSavedSettings.isBotMessagesEnabled == nil then
        FillRaidBotsSavedSettings.isBotMessagesEnabled = true
    end

    if FillRaidBotsSavedSettings.debugMessagesEnabled == nil then
        FillRaidBotsSavedSettings.debugMessagesEnabled = false
    end

    if FillRaidBotsSavedSettings.moveButtonsEnabled == nil then
        FillRaidBotsSavedSettings.moveButtonsEnabled = false
    end

    if FillRaidBotsSavedSettings.isRefillEnabled == nil then
        FillRaidBotsSavedSettings.isRefillEnabled = true 
    end
    if FillRaidBotsSavedSettings.isSmallEnabled == nil then
        FillRaidBotsSavedSettings.isSmallEnabled = false 
    end
    if FillRaidBotsSavedSettings.isFFAEnabled == nil then
        FillRaidBotsSavedSettings.isFFAEnabled = false
    end	
    if FillRaidBotsSavedSettings.isGroupLootEnabled == nil then
        FillRaidBotsSavedSettings.isGroupLootEnabled = true 
    end	
    if FillRaidBotsSavedSettings.isMasterLootEnabled == nil then
        FillRaidBotsSavedSettings.isMasterLootEnabled = false
    end
    if FillRaidBotsSavedSettings.isClickToFillEnabled == nil then
        FillRaidBotsSavedSettings.isClickToFillEnabled = true
    end	
    if FillRaidBotsSavedSettings.isAutoRepairEnabled == nil then
        FillRaidBotsSavedSettings.isAutoRepairEnabled = false 
    end
    if FillRaidBotsSavedSettings.isAutoJoinGuildEnabled == nil then
        FillRaidBotsSavedSettings.isAutoJoinGuildEnabled = true 
    end
    if FillRaidBotsSavedSettings.isAutoMuteSoundEnabled == nil then
        FillRaidBotsSavedSettings.isAutoMuteSoundEnabled = true 
    end	
    if FillRaidBotsSavedSettings.isremoveDeadBotsButtonEnabled == nil then
        FillRaidBotsSavedSettings.isremoveDeadBotsButtonEnabled = true 
    end		
    CreateToggleCheckButton()
    InitializeButtonPosition()
    ToggleButtonMovement(openFillRaidButton)


	if FillRaidBotsSavedSettings.debugMessagesEnabled then  
		debuggerFrame:Show()
	else
		debuggerFrame:Hide()
	end

    
    ToggleCheckAndRemoveCheckButton:SetChecked(FillRaidBotsSavedSettings.isCheckAndRemoveEnabled)
end
