
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
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", FillRaidBots_OnEvent)


local function CreateToggleCheckButton()
    
    local checkButton = CreateFrame("CheckButton", "ToggleCheckAndRemoveCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    checkButton:SetWidth(30)
    checkButton:SetHeight(30)
    checkButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -10)

    
    checkButton.text = checkButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkButton.text:SetPoint("LEFT", checkButton, "RIGHT", 5, 0)
    checkButton.text:SetText("Auto Remove Dead Bots")

    checkButton:SetChecked(FillRaidBotsSavedSettings.isCheckAndRemoveEnabled)

    checkButton:SetScript("OnClick", function(self)
        FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = checkButton:GetChecked()

        if FillRaidBotsSavedSettings.isCheckAndRemoveEnabled then
            checkButton.text:SetText("Disable CheckAndRemoveDeadBots")
        else
            checkButton.text:SetText("Enable CheckAndRemoveDeadBots")
        end
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
    botMessagesCheckButton:SetWidth(30)
    botMessagesCheckButton:SetHeight(30)
    botMessagesCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -50)

    botMessagesCheckButton.text = botMessagesCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    botMessagesCheckButton.text:SetPoint("LEFT", botMessagesCheckButton, "RIGHT", 5, 0)
    botMessagesCheckButton.text:SetText("Suppress Messages")

    botMessagesCheckButton:SetChecked(FillRaidBotsSavedSettings.isBotMessagesEnabled)

    botMessagesCheckButton:SetScript("OnClick", function(self)
        FillRaidBotsSavedSettings.isBotMessagesEnabled = botMessagesCheckButton:GetChecked()
    end)

    botMessagesCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(botMessagesCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, bot messages will be suppressed.")
        GameTooltip:Show()
    end)
    botMessagesCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


    
    local refillCheckButton = CreateFrame("CheckButton", "RefillButtonCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    refillCheckButton:SetWidth(30)
    refillCheckButton:SetHeight(30)
    refillCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -170)

    refillCheckButton.text = refillCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    refillCheckButton.text:SetPoint("LEFT", refillCheckButton, "RIGHT", 5, 0)
    refillCheckButton.text:SetText("Enable Refill Button")

    refillCheckButton:SetChecked(FillRaidBotsSavedSettings.isRefillEnabled)

    refillCheckButton:SetScript("OnClick", function(self)
        FillRaidBotsSavedSettings.isRefillEnabled = refillCheckButton:GetChecked()
		UpdateReFillButtonVisibility()
    end)

    refillCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(refillCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, the Refill Button will be available.")
        GameTooltip:Show()
    end)
    refillCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    
    local debugMessagesCheckButton = CreateFrame("CheckButton", "DebugMessagesCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    debugMessagesCheckButton:SetWidth(30)
    debugMessagesCheckButton:SetHeight(30)
    debugMessagesCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -90)

    debugMessagesCheckButton.text = debugMessagesCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugMessagesCheckButton.text:SetPoint("LEFT", debugMessagesCheckButton, "RIGHT", 5, 0)
    debugMessagesCheckButton.text:SetText("Enable Debug")

    debugMessagesCheckButton:SetChecked(FillRaidBotsSavedSettings.debugMessagesEnabled)

    debugMessagesCheckButton:SetScript("OnClick", function(self)
        FillRaidBotsSavedSettings.debugMessagesEnabled = debugMessagesCheckButton:GetChecked()
		debuggerFrame:Show()
    end)

    debugMessagesCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(debugMessagesCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("When enabled, debug messages will be shown.")
        GameTooltip:Show()
    end)
    debugMessagesCheckButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local moveButtonsCheckButton = CreateFrame("CheckButton", "moveButtonsCheckButton", UISettingsFrame, "UICheckButtonTemplate")
    moveButtonsCheckButton:SetWidth(30)
    moveButtonsCheckButton:SetHeight(30)
    moveButtonsCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -130)

    moveButtonsCheckButton.text = moveButtonsCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moveButtonsCheckButton.text:SetPoint("LEFT", moveButtonsCheckButton, "RIGHT", 5, 0)
    moveButtonsCheckButton.text:SetText("Enable moving buttons")

    moveButtonsCheckButton:SetChecked(FillRaidBotsSavedSettings.moveButtonsEnabled)

    moveButtonsCheckButton:SetScript("OnClick", function(self)
        FillRaidBotsSavedSettings.moveButtonsEnabled = moveButtonsCheckButton:GetChecked()
		ToggleButtonMovement(OpenFillRaidButton)
    end)
    moveButtonsCheckButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(moveButtonsCheckButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Enable moving of fillraid and kick all buttons.")
        GameTooltip:Show()
    end)
    moveButtonsCheckButton:SetScript("OnLeave", function()
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
        DEFAULT_CHAT_FRAME:AddMessage("Defaulting CheckAndRemove to enabled") 
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
