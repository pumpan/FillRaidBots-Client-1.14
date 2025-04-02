
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
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", FillRaidBots_OnEvent)


local function CreateToggleCheckButton()
    
    local checkButton = CreateFrame("CheckButton", "ToggleCheckAndRemoveCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    checkButton:SetWidth(20)
    checkButton:SetHeight(20)
    checkButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -10)

    
    checkButton.text = checkButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkButton.text:SetPoint("LEFT", checkButton, "RIGHT", 5, 0)
    checkButton.text:SetText("Remove Dead Bots Button")

    checkButton:SetChecked(FillRaidBotsSavedSettings.isCheckAndRemoveEnabled)

	checkButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = isChecked
		
		
		local status = isChecked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
		DEFAULT_CHAT_FRAME:AddMessage("Remove Dead Bots button: "..status)
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
    botMessagesCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -50)

    botMessagesCheckButton.text = botMessagesCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    botMessagesCheckButton.text:SetPoint("LEFT", botMessagesCheckButton, "RIGHT", 5, 0)
    botMessagesCheckButton.text:SetText("Suppress Messages")

    botMessagesCheckButton:SetChecked(FillRaidBotsSavedSettings.isBotMessagesEnabled)

	botMessagesCheckButton:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked()
		FillRaidBotsSavedSettings.isBotMessagesEnabled = isChecked
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

    local SmallCheckButton = CreateFrame("CheckButton", "SmallButtonCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    SmallCheckButton:SetWidth(20)
    SmallCheckButton:SetHeight(20)
    SmallCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -200)

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
  



local LootTypeHeader = UISettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
LootTypeHeader:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -230)
LootTypeHeader:SetText("Loot Type")


local LootTypeSeparator = UISettingsFrame:CreateTexture(nil, "ARTWORK")
LootTypeSeparator:SetHeight(2)  
LootTypeSeparator:SetPoint("TOPLEFT", LootTypeHeader, "BOTTOMLEFT", 0, -2)
LootTypeSeparator:SetPoint("TOPRIGHT", UISettingsFrame, "TOPRIGHT", -10, -232) 
LootTypeSeparator:SetTexture("Interface\\Buttons\\WHITE8x8")  
LootTypeSeparator:SetVertexColor(1, 1, 1, 0.8)  


local checkboxYOffset = -270  



local AutoFFACheckButton = CreateFrame("CheckButton", "AutoFFACheckButton", UISettingsFrame, "UICheckButtonTemplate")
AutoFFACheckButton:SetSize(20, 20)
AutoFFACheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, checkboxYOffset)
    AutoFFACheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(AutoFFACheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, puts FFA automaticaly on raid creation")
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
        GameTooltip:SetText("When enabled, puts Group loot automaticaly on raid creation")
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
        GameTooltip:SetText("When enabled, puts Master loot automaticaly on raid creation")
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







  
    local refillCheckButton = CreateFrame("CheckButton", "RefillButtonCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    refillCheckButton:SetWidth(20)
    refillCheckButton:SetHeight(20)
    refillCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -130)

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

    local moveButtonsCheckButton = CreateFrame("CheckButton", "moveButtonsCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    moveButtonsCheckButton:SetWidth(20)
    moveButtonsCheckButton:SetHeight(20)
    moveButtonsCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -170)

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

	local ClickToFillCheackButton = CreateFrame("CheckButton", "ClickToFillCheackButton", UISettingsFrame, "UICheckButtonTemplate")
	ClickToFillCheackButton:SetSize(20, 20)
	ClickToFillCheackButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -90)

	
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
    
    local debugMessagesCheckButton = CreateFrame("CheckButton", "DebugMessagesCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    debugMessagesCheckButton:SetWidth(20)
    debugMessagesCheckButton:SetHeight(20)
    debugMessagesCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -300)

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
