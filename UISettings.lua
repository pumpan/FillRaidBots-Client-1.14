-- Event handler function
local function FillRaidBots_OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == "FillRaidBots" then
        FillRaidBots_LoadSettings()
    elseif event == "PLAYER_LOGOUT" then
        FillRaidBots_SaveSettings()
    end
end

local settingsLoaded = false

-- Save settings function
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

    DEFAULT_CHAT_FRAME:AddMessage("FillRaidBots settings saved.")
end

-- Frame for event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", FillRaidBots_OnEvent)

-- Create toggle check buttons
local function CreateToggleCheckButton()
    -- Ensure UISettingsFrame exists or create it
    if not UISettingsFrame then
        UISettingsFrame = CreateFrame("Frame", "UISettingsFrame", UIParent)
        UISettingsFrame:SetSize(200, 150)
        UISettingsFrame:SetPoint("CENTER")
    end

    -- Check for "Auto Remove Dead Bots"
    if not _G["ToggleCheckAndRemoveCheckButton"] then
        local checkButton = CreateFrame("CheckButton", "ToggleCheckAndRemoveCheckButton", UISettingsFrame, "UICheckButtonTemplate")
        checkButton:SetSize(30, 30)
        checkButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -10)
        checkButton.text = _G[checkButton:GetName() .. "Text"]
        checkButton.text:SetText("Auto Remove Dead Bots")
        checkButton:SetChecked(FillRaidBotsSavedSettings.isCheckAndRemoveEnabled)

        checkButton:SetScript("OnClick", function(self)
            FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = checkButton:GetChecked()
            checkButton.text:SetText(checkButton:GetChecked() and "Disable CheckAndRemoveDeadBots" or "Enable CheckAndRemoveDeadBots")
        end)

        checkButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(checkButton, "ANCHOR_RIGHT")
            GameTooltip:SetText("When enabled, dead bots will be automatically removed from the raid or party.")
            GameTooltip:Show()
        end)
        checkButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- Check for "Bot Messages"
    if not _G["BotMessagesCheckButton"] then
        local botMessagesCheckButton = CreateFrame("CheckButton", "BotMessagesCheckButton", UISettingsFrame, "UICheckButtonTemplate")
        botMessagesCheckButton:SetSize(30, 30)
        botMessagesCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -50)
        botMessagesCheckButton.text = _G[botMessagesCheckButton:GetName() .. "Text"]
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
    end

    -- Check for "Debug Messages"
    if not _G["DebugMessagesCheckButton"] then
        local debugMessagesCheckButton = CreateFrame("CheckButton", "DebugMessagesCheckButton", UISettingsFrame, "UICheckButtonTemplate")
        debugMessagesCheckButton:SetSize(30, 30)
        debugMessagesCheckButton:SetPoint("TOPLEFT", UISettingsFrame, "TOPLEFT", 10, -90)
        debugMessagesCheckButton.text = _G[debugMessagesCheckButton:GetName() .. "Text"]
        debugMessagesCheckButton.text:SetText("Enable Debug")
        debugMessagesCheckButton:SetChecked(FillRaidBotsSavedSettings.debugMessagesEnabled)

        debugMessagesCheckButton:SetScript("OnClick", function(self)
            FillRaidBotsSavedSettings.debugMessagesEnabled = debugMessagesCheckButton:GetChecked()
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
end

-- Load settings function
function FillRaidBots_LoadSettings()
    if settingsLoaded then return end
    settingsLoaded = true
    
    -- Initialize saved settings table if not present
    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    -- Set default values if keys are missing
    FillRaidBotsSavedSettings.isCheckAndRemoveEnabled = FillRaidBotsSavedSettings.isCheckAndRemoveEnabled or false
    FillRaidBotsSavedSettings.isBotMessagesEnabled = FillRaidBotsSavedSettings.isBotMessagesEnabled or true -- Default to enabled
    FillRaidBotsSavedSettings.debugMessagesEnabled = FillRaidBotsSavedSettings.debugMessagesEnabled or false -- Default to disabled

    -- Create the toggle check buttons
    CreateToggleCheckButton()
end
