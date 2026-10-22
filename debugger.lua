local theme = {
    font = "Interface\\AddOns\\fillraidbots\\fonts\\PT-Sans-Narrow-Bold.ttf",
    fontSize = 10,
    fontMono = "Interface\\AddOns\\fillraidbots\\fonts\\Envy-Code-R.ttf",
    fontSizeMono = 9,
    spacing = 5,

    
    bg        = {0.06, 0.07, 0.09, 0.95},
    border    = {0.2, 0.55, 0.9, 1},
    titleBg   = {0.12, 0.2, 0.32, 1},
    panel     = {0.03, 0.04, 0.06, 1},
    panelEdge = {0.2, 0.55, 0.9, 0.35},
    label     = {0.7, 0.8, 0.9},
    gold      = {1, 0.82, 0},
    gear      = {0.4, 0.75, 1},
}


local levelColors = {
    debugfilling   = {0.40, 0.70, 1.00},
    debugdetection = {0.75, 0.60, 1.00},
    debugremove    = {1.00, 0.60, 0.25},
    debugerror     = {1.00, 0.30, 0.30},
    debuginfo      = {0.85, 0.90, 0.95},
    debugversion   = {0.35, 1.00, 0.45},
    debugzones     = {1.00, 0.82, 0.00},
}

local texturePath = "Interface\\AddOns\\fillraidbots\\img\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function ColorToHex(c)
    return string.format("|cff%02x%02x%02x",
        math.floor(c[1] * 255 + 0.5),
        math.floor(c[2] * 255 + 0.5),
        math.floor(c[3] * 255 + 0.5))
end

local levelHex = {}
for level, c in pairs(levelColors) do
    levelHex[level] = ColorToHex(c)
end
local dimHex = ColorToHex({0.50, 0.58, 0.70})
local defaultLevelHex = ColorToHex({0.85, 0.90, 0.95})

local backdrop = {
    bgFile   = WHITE,
    edgeFile = WHITE,
    edgeSize = 1,
}


local function CreateTitleBar(parent)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(26)
    bar:SetBackdrop({ bgFile = WHITE })
    bar:SetBackdropColor(unpack(theme.titleBg))
    return bar
end


local savedVarsReady = false

local function EnsureDebuggerSettings()

    if not savedVarsReady then
        return
    end

    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    if FillRaidBotsSavedSettings.debuggerShowTimestamps == nil then
        FillRaidBotsSavedSettings.debuggerShowTimestamps = true
    end

    if FillRaidBotsSavedSettings.debuggerLevels == nil then
        FillRaidBotsSavedSettings.debuggerLevels = {}
    end

    if FillRaidBotsSavedSettings.debuggerLevels.debugfilling == nil then
        FillRaidBotsSavedSettings.debuggerLevels.debugfilling = true
    end
    if FillRaidBotsSavedSettings.debuggerLevels.debugdetection == nil then
        FillRaidBotsSavedSettings.debuggerLevels.debugdetection = true
    end
    if FillRaidBotsSavedSettings.debuggerLevels.debugremove == nil then
        FillRaidBotsSavedSettings.debuggerLevels.debugremove = true
    end
    if FillRaidBotsSavedSettings.debuggerLevels.debugerror == nil then
        FillRaidBotsSavedSettings.debuggerLevels.debugerror = true
    end
    if FillRaidBotsSavedSettings.debuggerLevels.debuginfo == nil then
        FillRaidBotsSavedSettings.debuggerLevels.debuginfo = true
    end
    if FillRaidBotsSavedSettings.debuggerLevels.debugversion == nil then
        FillRaidBotsSavedSettings.debuggerLevels.debugversion = true
    end

    if FillRaidBotsSavedSettings.debuggerVisible == nil then
        FillRaidBotsSavedSettings.debuggerVisible = false
    end

    if FillRaidBotsSavedSettings.debuggerHeight == nil then
        FillRaidBotsSavedSettings.debuggerHeight = 300
    end
end

local function GetDebuggerSetting(key, default)
    if not savedVarsReady or not FillRaidBotsSavedSettings then
        return default
    end
    EnsureDebuggerSettings()

    if FillRaidBotsSavedSettings[key] == nil then
        FillRaidBotsSavedSettings[key] = default
    end

    return FillRaidBotsSavedSettings[key]
end

local function SetDebuggerSetting(key, value)
    if not savedVarsReady or not FillRaidBotsSavedSettings then
        return
    end
    EnsureDebuggerSettings()
    FillRaidBotsSavedSettings[key] = value
end

local function GetDebuggerLevelSetting(level)
    if not savedVarsReady or not FillRaidBotsSavedSettings
            or not FillRaidBotsSavedSettings.debuggerLevels then
        return true
    end
    EnsureDebuggerSettings()
    return FillRaidBotsSavedSettings.debuggerLevels[level]
end

local function SetDebuggerLevelSetting(level, value)
    if not savedVarsReady or not FillRaidBotsSavedSettings then
        return
    end
    EnsureDebuggerSettings()
    FillRaidBotsSavedSettings.debuggerLevels[level] = value
end

local function SaveDebuggerFramePosition()
    if not debuggerFrame then
        return
    end
    if not savedVarsReady or not FillRaidBotsSavedSettings then
        return
    end
    EnsureDebuggerSettings()

    local point, _, relativePoint, xOfs, yOfs = debuggerFrame:GetPoint()
    FillRaidBotsSavedSettings.debuggerFramePosition = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    }
end

local function RestoreDebuggerFramePosition()
    local savedPosition

    if savedVarsReady and FillRaidBotsSavedSettings then
        savedPosition = FillRaidBotsSavedSettings.debuggerFramePosition
    end

    debuggerFrame:ClearAllPoints()
    if savedPosition and savedPosition.point and savedPosition.relativePoint then
        debuggerFrame:SetPoint(savedPosition.point, UIParent, savedPosition.relativePoint, savedPosition.x or 0, savedPosition.y or 0)
    else
        debuggerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end


local debugEditBox
local ClearDebugEditBoxFocus
local RefreshDebuggerCheckboxStates

local IsLogLevelEnabled

local UpdateDebugMessages

debuggerFrame = CreateFrame("Frame", "FillraidbotsDebuggerFrame", UIParent, "BackdropTemplate")
debuggerFrame:SetWidth(480)
debuggerFrame:SetHeight(300)
debuggerFrame:SetBackdrop(backdrop)
debuggerFrame:SetBackdropColor(unpack(theme.bg))
debuggerFrame:SetBackdropBorderColor(unpack(theme.border))
debuggerFrame:EnableMouse(true)
debuggerFrame:SetMovable(true)
debuggerFrame:SetClampedToScreen(true)
debuggerFrame:SetScript("OnMouseDown", function(self, button)
    if debugEditBox and debugEditBox:HasFocus() then
        debugEditBox:ClearFocus()
        debugEditBox:HighlightText(0, 0)
    end

    if button == "LeftButton" and not debuggerFrame.isMoving then
        debuggerFrame:StartMoving()
        debuggerFrame.isMoving = true
    end
end)
debuggerFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and debuggerFrame.isMoving then
        debuggerFrame:StopMovingOrSizing()
        debuggerFrame.isMoving = false
        SaveDebuggerFramePosition()
    end
end)

RestoreDebuggerFramePosition()

debuggerFrame:Hide()

local titleBar = CreateTitleBar(debuggerFrame)

local header = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetPoint("LEFT", 30, 0)
header:SetText("FillRaidBots  |  Debugger")

local counterText = debuggerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
counterText:SetPoint("BOTTOMLEFT", 10, 11)
counterText:SetTextColor(unpack(theme.label))
counterText:SetText("")

local scrollFrame = CreateFrame("ScrollFrame", "FillraidbotsScrollFrame", debuggerFrame, "BackdropTemplate")
scrollFrame:SetWidth(460)
scrollFrame:SetHeight(235)
scrollFrame:SetPoint("TOPLEFT", debuggerFrame, "TOPLEFT", 10, -33)
scrollFrame:SetBackdrop(backdrop)
scrollFrame:SetBackdropColor(unpack(theme.panel))
scrollFrame:SetBackdropBorderColor(unpack(theme.panelEdge))

local scrollChild = CreateFrame("EditBox", "FillraidbotsScrollChild", scrollFrame)
scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 6, -5)
scrollChild:SetWidth(440)
scrollChild:SetHeight(1)
scrollChild:SetMultiLine(true)
scrollChild:SetAutoFocus(false)
scrollChild:EnableMouse(true)
scrollChild:SetFont(theme.fontMono, theme.fontSizeMono)
scrollChild:SetTextInsets(0, 0, 0, 0)
scrollChild:SetJustifyH("LEFT")
scrollChild:SetText("")
scrollFrame:SetScrollChild(scrollChild)

debugEditBox = scrollChild

debugEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    self:HighlightText(0, 0)
end)

debugEditBox:SetScript("OnMouseDown", function(self)
    self:SetFocus()
end)

local scrollBar = CreateFrame("Slider", "FillraidbotsScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -5, -20)
scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -5, 20)
scrollBar:SetWidth(16)
scrollBar:SetMinMaxValues(0, 0)
scrollBar:SetValueStep(1)
scrollBar:SetValue(0)
scrollBar:SetScript("OnValueChanged", function()
    scrollFrame:SetVerticalScroll(scrollBar:GetValue())
end)






scrollFrame:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
    yrange = yrange or self:GetVerticalScrollRange()
    local _, sliderMax = scrollBar:GetMinMaxValues()
    if scrollBar:GetValue() >= sliderMax - 1 then
        scrollBar:SetMinMaxValues(0, yrange)
        scrollBar:SetValue(yrange)
        self:SetVerticalScroll(yrange)
    end
end)


local scrollStep = 20
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollBar:GetValue()
    local min, max = scrollBar:GetMinMaxValues()
    local newVal = math.max(min, math.min(max, current - delta * scrollStep))
    scrollBar:SetValue(newVal)
end)
debugEditBox:EnableMouseWheel(true)
debugEditBox:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollBar:GetValue()
    local min, max = scrollBar:GetMinMaxValues()
    local newVal = math.max(min, math.min(max, current - delta * scrollStep))
    scrollBar:SetValue(newVal)
end)

local debugMessages = {}
local visibleDebugMessages = {}
local lineHeight = 11 
local maxMessages = 140



local measureText = debuggerFrame:CreateFontString(nil, "ARTWORK")
measureText:SetFont(theme.fontMono, theme.fontSizeMono)
measureText:SetJustifyH("LEFT")
measureText:SetJustifyV("TOP")
measureText:SetWordWrap(true)
measureText:SetPoint("TOPLEFT", debuggerFrame, "TOPLEFT", 0, 0)
measureText:SetWidth(440)
measureText:SetAlpha(0)
local totalMessagesSeen = 0

local function GetTimestamp()
    return date("%H:%M:%S")
end


local function GetDisplayMessage(messageData, plain)
    local text = tostring(messageData.text or "")
    local indexText = tostring(messageData.index or 0) .. ":"
    local showTime = GetDebuggerSetting("debuggerShowTimestamps", true) and messageData.timestamp

    if plain then
        if showTime then
            return indexText .. " [" .. messageData.timestamp .. "] " .. text
        end
        return indexText .. " " .. text
    end

    local levelColor = levelHex[messageData.level] or defaultLevelHex
    local line = dimHex .. indexText .. "|r "
    if showTime then
        line = line .. dimHex .. "[" .. messageData.timestamp .. "]|r "
    end
    return line .. levelColor .. text .. "|r"
end

local function UpdateDebugTextWidth()
    local contentWidth = scrollFrame:GetWidth() - 25
    if contentWidth < 50 then
        contentWidth = 50
    end

    scrollChild:SetWidth(contentWidth)
    debugEditBox:SetWidth(contentWidth)
    measureText:SetWidth(contentWidth)
end


local function UpdateDebuggerWidth()
    local baseWidth = 480
    local expandedWidth = 535
    local w = GetDebuggerSetting("debuggerShowTimestamps", true) and expandedWidth or baseWidth
    debuggerFrame:SetWidth(w)
    scrollFrame:SetWidth(w - 20)
    UpdateDebugTextWidth()
end


local defaultHeight = 300
local expandStep   = 100

ApplyDebuggerHeight = function(h)
    h = math.max(defaultHeight, h)

    local left = debuggerFrame:GetLeft()
    local top  = debuggerFrame:GetTop()
    if left and top then
        debuggerFrame:ClearAllPoints()
        debuggerFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end

    debuggerFrame:SetHeight(h)

    SaveDebuggerFramePosition()

    local newScrollHeight = h - 33 - 32
    if newScrollHeight < 60 then newScrollHeight = 60 end
    scrollFrame:SetHeight(newScrollHeight)
    SetDebuggerSetting("debuggerHeight", h)
    UpdateDebugMessages()
end

local function GetTextLineCount(text)
    local lineCount = 1
    local pos = 1
    local newPos

    if not text or text == "" then
        return 1
    end

    while true do
        newPos = string.find(text, "\n", pos, true)
        if not newPos then
            break
        end
        lineCount = lineCount + 1
        pos = newPos + 1
    end

    return lineCount
end

UpdateDebugMessages = function()
    local i
    local text = ""
    local currentScroll = scrollBar:GetValue()
    local minScroll, oldMaxScroll = scrollBar:GetMinMaxValues()
    local atBottom = false
    local contentHeight
    local maxScroll
    local plain = debugEditBox:HasFocus()

    local visibleCount = 0

    if currentScroll >= (oldMaxScroll - 5) then
        atBottom = true
    end

    visibleDebugMessages = {}

    for i = 1, table.getn(debugMessages) do
        if IsLogLevelEnabled(debugMessages[i].level) then
            table.insert(visibleDebugMessages, debugMessages[i])
            text = text .. GetDisplayMessage(debugMessages[i], plain) .. "\n"
            visibleCount = visibleCount + 1
        end
    end
    debugEditBox:SetText(text)

    counterText:SetText("Shown: " .. visibleCount .. "  |  Total: " .. totalMessagesSeen)

    measureText:SetText(text)
    contentHeight = measureText:GetStringHeight()
    if not contentHeight or contentHeight <= 0 then
        contentHeight = GetTextLineCount(text) * lineHeight
    end
    
    
    contentHeight = math.ceil(contentHeight + 20)

    if contentHeight < scrollFrame:GetHeight() then
        contentHeight = scrollFrame:GetHeight()
    end

    scrollChild:SetHeight(contentHeight)

    maxScroll = math.max(0, contentHeight - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, maxScroll)

    if atBottom then
        scrollBar:SetValue(maxScroll)
    else
        if currentScroll > maxScroll then
            currentScroll = maxScroll
        end
        if currentScroll < minScroll then
            currentScroll = minScroll
        end
        scrollBar:SetValue(currentScroll)
    end
end

debugEditBox:SetScript("OnEditFocusGained", function()
    UpdateDebugMessages()
end)
debugEditBox:SetScript("OnEditFocusLost", function()
    UpdateDebugMessages()
end)

UpdateDebuggerWidth()


local copyButton = CreateFrame("Button", "FillraidbotsCopyButton", debuggerFrame, "UIPanelButtonTemplate")
copyButton:SetSize(70, 20)
copyButton:SetPoint("BOTTOMRIGHT", debuggerFrame, "BOTTOMRIGHT", -8, 6)
copyButton:SetText("Copy All")
copyButton:SetScript("OnClick", function()
    debugEditBox:SetFocus()
    debugEditBox:HighlightText()
end)

local clearButton = CreateFrame("Button", "FillraidbotsClearButton", debuggerFrame, "UIPanelButtonTemplate")
clearButton:SetSize(96, 20)
clearButton:SetPoint("RIGHT", copyButton, "LEFT", -6, 0)
clearButton:SetText("Clear Messages")
clearButton:SetScript("OnClick", function()
    ClearDebugEditBoxFocus()
    debugMessages = {}
    UpdateDebugMessages()
end)


local closeButton = CreateFrame("Button", "FillraidbotsCloseButton", titleBar, "UIPanelCloseButton")
closeButton:SetPoint("RIGHT", 2, 0)
closeButton:SetSize(24, 24)
closeButton:SetScript("OnClick", function()
    ClearDebugEditBoxFocus()

    SetDebuggerSetting("debuggerVisible", false)
    debuggerFrame:Hide()
end)



local function CreateSizeButton(name, label, offsetX, tooltipTitle, tooltipBody, onClick)
    local btn = CreateFrame("Button", name, titleBar)
    btn:SetSize(16, 20)
    btn:SetPoint("RIGHT", titleBar, "RIGHT", offsetX, 0)

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetAllPoints(btn)
    fs:SetText(label)
    btn:SetFontString(fs)

    btn:SetScript("OnEnter", function(self)
        fs:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltipTitle, 1, 1, 1)
        GameTooltip:AddLine(tooltipBody, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        fs:SetTextColor(unpack(theme.gold))
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end


local expandButton = CreateSizeButton(
    "FillraidbotsExpandButton", "v", -62,
    "Expand", "Increase the window height by " .. expandStep .. " px.",
    function()
        ClearDebugEditBoxFocus()
        local current = GetDebuggerSetting("debuggerHeight", defaultHeight)

        local bottom = debuggerFrame:GetBottom()
        if bottom and bottom - expandStep < 0 then
            return
        end
        ApplyDebuggerHeight(current + expandStep)
    end
)


local contractButton = CreateSizeButton(
    "FillraidbotsContractButton", "^", -44,
    "Contract", "Reduce the window height by " .. expandStep .. " px.",
    function()
        ClearDebugEditBoxFocus()
        local current = GetDebuggerSetting("debuggerHeight", defaultHeight)
        ApplyDebuggerHeight(current - expandStep)
    end
)


local resetSizeButton = CreateSizeButton(
    "FillraidbotsResetSizeButton", "r", -26,
    "Reset Size", "Reset the window height to the default (" .. defaultHeight .. " px).",
    function()
        ClearDebugEditBoxFocus()
        ApplyDebuggerHeight(defaultHeight)
    end
)


local logLevelButton = CreateFrame("Button", "FillraidbotsLogLevelButton", titleBar)
logLevelButton:SetPoint("LEFT", 9, 0)
logLevelButton:SetSize(15, 15)

local logLevelTexture = logLevelButton:CreateTexture(nil, "ARTWORK")
logLevelTexture:SetTexture(texturePath .. "editor.tga")
logLevelTexture:SetAllPoints(logLevelButton)
logLevelTexture:SetVertexColor(unpack(theme.gear))

logLevelButton:SetScript("OnEnter", function(self)
    logLevelTexture:SetVertexColor(1, 1, 1)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Log Level", 1, 1, 1)
    GameTooltip:AddLine("Adjust log level settings.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

logLevelButton:SetScript("OnLeave", function()
    logLevelTexture:SetVertexColor(unpack(theme.gear))
    GameTooltip:Hide()
end)

logLevelButton:SetScript("OnMouseDown", function()
    logLevelTexture:SetVertexColor(0.8, 0.2, 0.2)
end)

logLevelButton:SetScript("OnMouseUp", function()
    logLevelTexture:SetVertexColor(1, 1, 1)
end)



local logLevelFrame = CreateFrame("Frame", "FillraidbotsLogLevelFrame", debuggerFrame, "BackdropTemplate")
logLevelFrame:SetPoint("TOPLEFT", logLevelButton, "BOTTOMLEFT", -6, -8)
logLevelFrame:SetWidth(300)
logLevelFrame:SetHeight(140)
logLevelFrame:SetFrameStrata("DIALOG")
logLevelFrame:EnableMouse(true) 
logLevelFrame:SetBackdrop(backdrop)
logLevelFrame:SetBackdropColor(theme.bg[1], theme.bg[2], theme.bg[3], 1)
logLevelFrame:SetBackdropBorderColor(unpack(theme.border))
logLevelFrame:Hide()

local logLevelBar = CreateTitleBar(logLevelFrame)

local logLevelHeader = logLevelBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
logLevelHeader:SetPoint("LEFT", 10, 0)
logLevelHeader:SetText("FillRaidBots  |  Log Levels")


local logLevelTooltips = {
    debugfilling    = "Fill loop lifecycle.\nStarting, pausing, resuming, progress and completion of raid fills.\nAlso covers combat blocks and starter bot sequences.",
    debugdetection  = "Bot and player list state.\nLogs when detection lists are cleared or rebuilt.",
    debugremove     = "Bot removal events.\nLogs every uninvite, kick and player removal from the group.",
    debugerror      = "Errors and aborted operations.\nLogs failed sequences, missing presets and internal errors.",
    debuginfo       = "General info.\nRole lists, FixGroups phases, sound state, misc warnings and state resets.",
    debugversion    = "Version handshake.\nAddon prefix registration, guild version broadcast, VIP auth and update checks.",
    debugzones      = "Zone detection.\nLogs current zone, subzone and the max bot cap applied.",
}

local function CreateCheckbox(name, label, parent, x, y, color)
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetSize(22, 22)
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    checkbox:SetHitRectInsets(0, -110, 0, 0)

    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    checkbox.text:SetText(label)
    checkbox.text:SetTextColor(color[1], color[2], color[3])

    return checkbox
end

local function CreateLogLevelCheckbox(name, label, parent, x, y, level)
    local checkbox = CreateCheckbox(name, label, parent, x, y, levelColors[level] or theme.label)
    checkbox:SetChecked(GetDebuggerLevelSetting(level))
    checkbox:SetScript("OnClick", function(self)
        SetDebuggerLevelSetting(level, self:GetChecked() and true or false)

        UpdateDebugMessages()
    end)

    if logLevelTooltips[level] then
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(logLevelTooltips[level], 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    return checkbox
end


local col1, col2 = 12, 160
local debugFillingCheckbox = CreateLogLevelCheckbox("DebugFillingCheckbox", "Debug Filling", logLevelFrame, col1, -34, "debugfilling")
local debugDetectionCheckbox = CreateLogLevelCheckbox("DebugDetectionCheckbox", "Debug Detection", logLevelFrame, col1, -58, "debugdetection")
local debugRemoveCheckbox = CreateLogLevelCheckbox("DebugRemoveCheckbox", "Debug Remove", logLevelFrame, col1, -82, "debugremove")
local debugErrorCheckbox = CreateLogLevelCheckbox("DebugErrorCheckbox", "Debug Error", logLevelFrame, col1, -106, "debugerror")
local debugInfoCheckbox = CreateLogLevelCheckbox("DebugInfoCheckbox", "Debug Info", logLevelFrame, col2, -34, "debuginfo")
local debugVersionCheckbox = CreateLogLevelCheckbox("DebugVersionCheckbox", "Debug Version", logLevelFrame, col2, -58, "debugversion")
local debugZonesCheckbox = CreateLogLevelCheckbox("DebugZonesCheckbox", "Zones", logLevelFrame, col2, -82, "debugzones")

local timestampCheckbox = CreateCheckbox("DebugTimestampCheckbox", "Show Timestamps", logLevelFrame, col2, -106, theme.label)
timestampCheckbox:SetChecked(GetDebuggerSetting("debuggerShowTimestamps", true))
timestampCheckbox:SetScript("OnClick", function(self)
    SetDebuggerSetting("debuggerShowTimestamps", self:GetChecked() and true or false)
    UpdateDebuggerWidth()
    UpdateDebugMessages()
end)

RefreshDebuggerCheckboxStates = function()
    debugFillingCheckbox:SetChecked(GetDebuggerLevelSetting("debugfilling"))
    debugDetectionCheckbox:SetChecked(GetDebuggerLevelSetting("debugdetection"))
    debugRemoveCheckbox:SetChecked(GetDebuggerLevelSetting("debugremove"))
    debugErrorCheckbox:SetChecked(GetDebuggerLevelSetting("debugerror"))
    debugInfoCheckbox:SetChecked(GetDebuggerLevelSetting("debuginfo"))
    debugVersionCheckbox:SetChecked(GetDebuggerLevelSetting("debugversion"))
    debugZonesCheckbox:SetChecked(GetDebuggerLevelSetting("debugzones"))
    timestampCheckbox:SetChecked(GetDebuggerSetting("debuggerShowTimestamps", true))
end

ClearDebugEditBoxFocus = function()
    if debugEditBox and debugEditBox:HasFocus() then
        debugEditBox:ClearFocus()
        debugEditBox:HighlightText(0, 0)
    end
end



function SetDebuggerVisibility(visible)
    SetDebuggerSetting("debuggerVisible", visible and true or false)
end

logLevelButton:SetScript("OnClick", function()
    ClearDebugEditBoxFocus()

    if logLevelFrame:IsShown() then
        logLevelFrame:Hide()
    else
        RefreshDebuggerCheckboxStates()
        logLevelFrame:Show()
    end
end)

IsLogLevelEnabled = function(level)
    return GetDebuggerLevelSetting(level) and true or false
end


function DebugMessage(message, level)
    local entry

    totalMessagesSeen = totalMessagesSeen + 1

    entry = {
        index = totalMessagesSeen,
        timestamp = GetTimestamp(),
        text = message,
        level = level,
    }

    table.insert(debugMessages, entry)

    if table.getn(debugMessages) > maxMessages then
        table.remove(debugMessages, 1)
    end

    UpdateDebugMessages()
end

SLASH_FILLRAIDBOTSDEBUG1 = "/frbdebug"

SlashCmdList["FILLRAIDBOTSDEBUG"] = function()
    ClearDebugEditBoxFocus()

    if debuggerFrame:IsShown() then

        SetDebuggerSetting("debuggerVisible", false)
        debuggerFrame:Hide()
    else

        SetDebuggerSetting("debuggerVisible", true)
        RefreshDebuggerCheckboxStates()
        debuggerFrame:Show()
        UpdateDebuggerWidth()
        UpdateDebugMessages()
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

        savedVarsReady = true
        EnsureDebuggerSettings()
        RestoreDebuggerFramePosition()
        RefreshDebuggerCheckboxStates()
        UpdateDebuggerWidth()
        UpdateDebugMessages()
        DebugMessage("Player logged in.", "debuginfo")

        ApplyDebuggerHeight(GetDebuggerSetting("debuggerHeight", 300))
        if GetDebuggerSetting("debuggerVisible", false) then
            debuggerFrame:Show()
            UpdateDebuggerWidth()
            UpdateDebugMessages()
        else
            debuggerFrame:Hide()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        DebugMessage("Player entering the world.", "debuginfo")
    end
end)
