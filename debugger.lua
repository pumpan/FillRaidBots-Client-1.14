
local theme = {
    backdropColor1 = {0.15, 0.15, 0.15, 1}, 
    backdropColor2 = {0.2, 0.2, 0.2, 0.95}, 
    textColor = {0.20, 1, 0.8, 1}, 
    font = "Interface\\AddOns\\fillraidbots\\fonts\\PT-Sans-Narrow-Bold.ttf",
    fontSize = 10,
    fontMono = "Interface\\AddOns\\fillraidbots\\fonts\\Envy-Code-R.ttf",
    fontSizeMono = 9,
    spacing = 5, 
}


local texturePath = "Interface\\AddOns\\fillraidbots\\img\\"


debuggerFrame = CreateFrame("Frame", "FillraidbotsDebuggerFrame", UIParent, "BackdropTemplate")
debuggerFrame:SetWidth(470)
debuggerFrame:SetHeight(300)
debuggerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
debuggerFrame:SetBackdrop({
    bgFile = texturePath .. "bg.tga", 
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
debuggerFrame:SetBackdropColor(unpack(theme.backdropColor1)) 
debuggerFrame:EnableMouse(true)
debuggerFrame:SetMovable(true)
debuggerFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not debuggerFrame.isMoving then
        debuggerFrame:StartMoving()
        debuggerFrame.isMoving = true
    end
end)
debuggerFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and debuggerFrame.isMoving then
        debuggerFrame:StopMovingOrSizing()
        debuggerFrame.isMoving = false
    end
end)


local header = debuggerFrame:CreateFontString(nil, "OVERLAY")
header:SetFont(theme.font, theme.fontSize)
header:SetPoint("TOP", debuggerFrame, "TOP", 0, -10)
header:SetText("Fillraidbots Debugger")
header:SetTextColor(unpack(theme.textColor))


local scrollFrame = CreateFrame("ScrollFrame", "FillraidbotsScrollFrame", debuggerFrame, "BackdropTemplate")
scrollFrame:SetWidth(450)
scrollFrame:SetHeight(200)
scrollFrame:SetPoint("TOPLEFT", debuggerFrame, "TOPLEFT", 10, -40)
scrollFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
scrollFrame:SetBackdropColor(unpack(theme.backdropColor2)) 


local scrollChild = CreateFrame("Frame", "FillraidbotsScrollChild", scrollFrame)
scrollChild:SetWidth(410)
scrollChild:SetHeight(1) 
scrollFrame:SetScrollChild(scrollChild)


local debugText = scrollChild:CreateFontString(nil, "ARTWORK")
debugText:SetFont(theme.fontMono, theme.fontSizeMono)
debugText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
debugText:SetWidth(410)
debugText:SetJustifyH("LEFT")
debugText:SetJustifyV("TOP")
debugText:SetText("") 


local scrollBar = CreateFrame("Slider", "FillraidbotsScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -5, -20)
scrollBar:SetWidth(16)
scrollBar:SetHeight(160)
scrollBar:SetMinMaxValues(0, 0)
scrollBar:SetValueStep(1)
scrollBar:SetValue(0)
scrollBar:SetScript("OnValueChanged", function()
    scrollFrame:SetVerticalScroll(scrollBar:GetValue())
end)


local debugMessages = {}
local lineHeight = 10 
local maxMessages = 70 

local function GetTimestamp()
    return date("%H:%M:%S") 
end

local function UpdateDebugMessages()
    local text = ""
    for i = 1, #debugMessages do
        text = text .. "" .. tostring(i) .. ": " .. debugMessages[i] .. "\n"
    end
    debugText:SetText(text)

    
    local contentHeight = #debugMessages * lineHeight
    scrollChild:SetHeight(math.max(contentHeight, scrollFrame:GetHeight()))

    
    local maxScroll = math.max(0, contentHeight - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, maxScroll)

    
    scrollBar:SetValue(maxScroll)
end


local clearButton = CreateFrame("Button", "FillraidbotsClearButton", debuggerFrame, "UIPanelButtonTemplate")
clearButton:SetPoint("BOTTOM", debuggerFrame, "BOTTOM", -60, 20)
clearButton:SetWidth(100)
clearButton:SetHeight(30)
clearButton:SetText("Clear Messages")
clearButton:SetScript("OnClick", function()
    debugMessages = {}
    DebugMessage("Cleared messages", "debuginfo")
end)



local closeButton = CreateFrame("Button", "FillraidbotsCloseButton", debuggerFrame)
closeButton:SetPoint("TOPRIGHT", debuggerFrame, "TOPRIGHT", -10, -10)
closeButton:SetWidth(15)
closeButton:SetHeight(15)


local normalTexture = closeButton:CreateTexture(nil, "BACKGROUND")
normalTexture:SetTexture(texturePath .. "close.tga")
normalTexture:SetAllPoints(closeButton)
normalTexture:SetVertexColor(1, 0, 0) 
closeButton:SetNormalTexture(normalTexture)


local highlightTexture = closeButton:CreateTexture(nil, "HIGHLIGHT")
highlightTexture:SetTexture(texturePath .. "close.tga")
highlightTexture:SetAllPoints(closeButton)
highlightTexture:SetVertexColor(1, 0.5, 0.5) 
closeButton:SetHighlightTexture(highlightTexture)


local pushedTexture = closeButton:CreateTexture(nil, "PUSHED")
pushedTexture:SetTexture(texturePath .. "close.tga")
pushedTexture:SetAllPoints(closeButton)
pushedTexture:SetVertexColor(0.8, 0, 0) 
closeButton:SetPushedTexture(pushedTexture)


closeButton:SetScript("OnClick", function()
    debuggerFrame:Hide()
end)



local logLevelButton = CreateFrame("Button", "FillraidbotsLogLevelButton", debuggerFrame)
logLevelButton:SetPoint("BOTTOM", debuggerFrame, "TOPLEFT", 25, -30)
logLevelButton:SetWidth(15) 
logLevelButton:SetHeight(15)


local logLevelNormalTexture = logLevelButton:CreateTexture(nil, "BACKGROUND")
logLevelNormalTexture:SetTexture(texturePath .. "editor.tga")
logLevelNormalTexture:SetAllPoints(logLevelButton)
logLevelButton:SetNormalTexture(logLevelNormalTexture)


local logLevelHighlightTexture = logLevelButton:CreateTexture(nil, "HIGHLIGHT")
logLevelHighlightTexture:SetTexture(texturePath .. "editor.tga")
logLevelHighlightTexture:SetAllPoints(logLevelButton)
logLevelHighlightTexture:SetVertexColor(1, 1, 0) 
logLevelButton:SetHighlightTexture(logLevelHighlightTexture)


local logLevelPushedTexture = logLevelButton:CreateTexture(nil, "PUSHED")
logLevelPushedTexture:SetTexture(texturePath .. "editor.tga")
logLevelPushedTexture:SetAllPoints(logLevelButton)
logLevelPushedTexture:SetVertexColor(0.8, 0.2, 0.2) 
logLevelButton:SetPushedTexture(logLevelPushedTexture)


logLevelButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Log Level", 1, 1, 1) 
    GameTooltip:AddLine("Adjust log level settings.", 0.8, 0.8, 0.8) 
    GameTooltip:Show()
end)

logLevelButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)



logLevelButton:SetScript("OnClick", function()
    
    print("Log Level button clicked!")
end)




local logLevelFrame = CreateFrame("Frame", "FillraidbotsLogLevelFrame", FillraidbotsLogLevelButton, "BackdropTemplate")
logLevelFrame:SetWidth(200)
logLevelFrame:SetHeight(230)
logLevelFrame:SetPoint("BOTTOMLEFT", FillraidbotsLogLevelButton, "BOTTOMLEFT", 15, -200)
logLevelFrame:SetBackdrop({
    bgFile = texturePath .. "bg.tga",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 32, edgeSize = 12,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
logLevelFrame:SetBackdropColor(unpack(theme.backdropColor2))
logLevelFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) 
logLevelFrame:Hide() 


local logLevelHeader = logLevelFrame:CreateFontString(nil, "OVERLAY")
logLevelHeader:SetFont(theme.font, theme.fontSize)
logLevelHeader:SetPoint("TOP", logLevelFrame, "TOP", 0, -10)
logLevelHeader:SetText("Log Levels")
logLevelHeader:SetTextColor(unpack(theme.textColor))


local function CreateLogLevelCheckbox(name, label, parent, offsetY)
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, offsetY)
    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY")
    checkbox.text:SetFont(theme.font, theme.fontSize)
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.text:SetText(label)
    checkbox.text:SetTextColor(unpack(theme.textColor))
    return checkbox
end


local debugFillingCheckbox = CreateLogLevelCheckbox("DebugFillingCheckbox", "Debug Filling", logLevelFrame, -40)
local debugDetectionCheckbox = CreateLogLevelCheckbox("DebugDetectionCheckbox", "Debug Detection", logLevelFrame, -70)
local debugRemoveCheckbox = CreateLogLevelCheckbox("DebugRemoveCheckbox", "Debug Remove", logLevelFrame, -100)
local debugErrorCheckbox = CreateLogLevelCheckbox("DebugErrorCheckbox", "Debug Error", logLevelFrame, -130)
local debugInfoCheckbox = CreateLogLevelCheckbox("DebugInfoCheckbox", "Debug Info", logLevelFrame, -160)
local debugVersionCheckbox = CreateLogLevelCheckbox("DebugVersionCheckbox", "Debug Version", logLevelFrame, -190)


debugFillingCheckbox:SetChecked(true)
debugDetectionCheckbox:SetChecked(true)
debugRemoveCheckbox:SetChecked(true)
debugErrorCheckbox:SetChecked(true)
debugInfoCheckbox:SetChecked(true)
debugVersionCheckbox:SetChecked(true)

logLevelButton:SetScript("OnClick", function()
    if logLevelFrame:IsShown() then
        logLevelFrame:Hide()
    else
        logLevelFrame:Show()
    end
end)


local function IsLogLevelEnabled(level)
    if level == "debugfilling" then
        return debugFillingCheckbox:GetChecked()
    elseif level == "debugdetection" then
        return debugDetectionCheckbox:GetChecked()
    elseif level == "debugremove" then
        return debugRemoveCheckbox:GetChecked()
    elseif level == "debugerror" then
        return debugErrorCheckbox:GetChecked()
    elseif level == "debuginfo" then
        return debugInfoCheckbox:GetChecked()
    elseif level == "debugversion" then
        return debugVersionCheckbox:GetChecked()
    end
    return false
end


function DebugMessage(message, level)
    if not IsLogLevelEnabled(level) then return end

    
    local timestampedMessage = "[" .. message

    
    table.insert(debugMessages, timestampedMessage)

    
    if table.getn(debugMessages) > maxMessages then
        table.remove(debugMessages, 1)
    end

    
    UpdateDebugMessages()
end


SLASH_FILLRAIDBOTSDEBUG1 = "/frbdebug" 


SlashCmdList["FILLRAIDBOTSDEBUG"] = function()
    if debuggerFrame:IsShown() then
        debuggerFrame:Hide()
        print("FillRaidBots Debugger Frame hidden.")
    else
        debuggerFrame:Show()
        print("FillRaidBots Debugger Frame shown.")
    end
end


DebugMessage("Debugger initialized.", "debuginfo")
DebugMessage("Fillraidbots loaded successfully.", "debuginfo")


local eventFrame = CreateFrame("Frame", "FillraidbotsEventFrame", UIParent)
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        DebugMessage("Player logged in.", "debuginfo")

    elseif event == "PLAYER_ENTERING_WORLD" then
        DebugMessage("Player entering the world.", "debuginfo")
    end
end)

