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

-- Pumpan:(20260324) Added saved debugger settings helpers so the debugger can remember
-- position, timestamp visibility and log level filters between reloads.
-- Nymz:(20260403) Size - EnsureDebuggerSettings must only run after PLAYER_LOGIN so that
-- SavedVariables are already loaded; calling it earlier (at addon load time) would overwrite
-- the persisted values with defaults because FillRaidBotsSavedSettings is still nil then.
local savedVarsReady = false

local function EnsureDebuggerSettings()
    -- Bail out silently before SavedVariables are available.
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

    -- Nymz:(20260403) DebugVisibility - persist whether the debugger window was open or closed
    if FillRaidBotsSavedSettings.debuggerVisible == nil then
        FillRaidBotsSavedSettings.debuggerVisible = false
    end

    -- Nymz:(20260403) Size - persist the debugger window height
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
        return true  -- default all levels on before SavedVars load
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

    -- SavedVariables are not available at addon load time; fall back to centre.
    -- Position will be properly restored in PLAYER_LOGIN once savedVarsReady is true.
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
-- Nymz:(20260403) LogLevelFilter - forward declaration so UpdateDebugMessages can call it before definition
local IsLogLevelEnabled
-- Nymz:(20260403) Size - forward declaration so ApplyDebuggerHeight can call it before definition
local UpdateDebugMessages

debuggerFrame = CreateFrame("Frame", "FillraidbotsDebuggerFrame", UIParent, "BackdropTemplate")
debuggerFrame:SetWidth(480)
debuggerFrame:SetHeight(300)
debuggerFrame:SetBackdrop({
    bgFile = texturePath .. "bg.tga",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
debuggerFrame:SetBackdropColor(unpack(theme.backdropColor1))
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
-- Nymz:(20260403) Size - keep hidden until PLAYER_LOGIN restores the correct state
debuggerFrame:Hide()

local header = debuggerFrame:CreateFontString(nil, "OVERLAY")
header:SetFont(theme.font, theme.fontSize)
header:SetPoint("TOP", debuggerFrame, "TOP", 0, -10)
header:SetText("Fillraidbots Debugger")
header:SetTextColor(unpack(theme.textColor))

local counterText = debuggerFrame:CreateFontString(nil, "OVERLAY")
counterText:SetFont(theme.font, theme.fontSize)
counterText:SetPoint("TOPLEFT", debuggerFrame, "TOPLEFT", 40, -12)
counterText:SetText("")
counterText:SetTextColor(unpack(theme.textColor))

local scrollFrame = CreateFrame("ScrollFrame", "FillraidbotsScrollFrame", debuggerFrame, "BackdropTemplate")
scrollFrame:SetWidth(460)
scrollFrame:SetHeight(200)
scrollFrame:SetPoint("TOPLEFT", debuggerFrame, "TOPLEFT", 10, -40)
scrollFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
scrollFrame:SetBackdropColor(unpack(theme.backdropColor2))

-- Pumpan:(20260325) Use a real EditBox as the scroll child so the log text can be
-- selected/copied while still staying anchored to the debugger scroll area.
local scrollChild = CreateFrame("EditBox", "FillraidbotsScrollChild", scrollFrame)
scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 4, -4)
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
scrollBar:SetWidth(16)
scrollBar:SetHeight(160)
scrollBar:SetMinMaxValues(0, 0)
scrollBar:SetValueStep(1)
scrollBar:SetValue(0)
scrollBar:SetScript("OnValueChanged", function()
    scrollFrame:SetVerticalScroll(scrollBar:GetValue())
end)

-- Nymz:(20260403) MouseWheelScroll - enable mouse wheel scrolling on the log area
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
local lineHeight = 9
local maxMessages = 140
local totalMessagesSeen = 0

local function GetTimestamp()
    return date("%H:%M:%S")
end

local function GetDisplayMessage(messageData)
    local text = tostring(messageData.text or "")
    local indexPrefix = tostring(messageData.index or 0) .. ": "

    if GetDebuggerSetting("debuggerShowTimestamps", true) and messageData.timestamp then
        return indexPrefix .. "[" .. messageData.timestamp .. "] " .. text
    end

    return indexPrefix .. text
end

local function UpdateDebugTextWidth()
    local contentWidth = scrollFrame:GetWidth() - 25
    if contentWidth < 50 then
        contentWidth = 50
    end

    scrollChild:SetWidth(contentWidth)
    debugEditBox:SetWidth(contentWidth)
end

--Nymz: DebuggerWidth (20260327) Expand window when timestamps are enabled, shrink when disabled
local function UpdateDebuggerWidth()
    local baseWidth = 480
    local expandedWidth = 535
    local w = GetDebuggerSetting("debuggerShowTimestamps", true) and expandedWidth or baseWidth
    debuggerFrame:SetWidth(w)
    scrollFrame:SetWidth(w - 20)
    UpdateDebugTextWidth()
end

-- Nymz:(20260403) Size - apply a height to the debugger frame and reflow dependent elements
local defaultHeight = 300
local expandStep   = 100

ApplyDebuggerHeight = function(h)
    h = math.max(defaultHeight, h)

    -- Re-anchor to TOPLEFT using the current pixel position of the top-left corner
    -- before resizing, so the top of the window never moves regardless of the
    -- original anchor point.
    local left = debuggerFrame:GetLeft()
    local top  = debuggerFrame:GetTop()
    if left and top then
        debuggerFrame:ClearAllPoints()
        debuggerFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end

    debuggerFrame:SetHeight(h)

    -- Persist the new TOPLEFT anchor
    SaveDebuggerFramePosition()

    -- scrollFrame sits from y -40 to bottom buttons area (50px from bottom)
    local newScrollHeight = h - 40 - 50
    if newScrollHeight < 60 then newScrollHeight = 60 end
    scrollFrame:SetHeight(newScrollHeight)
    scrollBar:SetHeight(newScrollHeight - 40)
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
    -- Nymz:(20260403) LogLevelFilter - count only visible messages for display
    local visibleCount = 0

    if currentScroll >= (oldMaxScroll - 5) then
        atBottom = true
    end
-- Pumpan:(20260405) Debugger Scroll Fix
-- Fixed an issue where disabled log levels still affected the scroll height.
-- Messages are now filtered into a visible list before rendering, so hidden rows
-- no longer create invisible scroll space or force unwanted auto-scrolling.
-- Full message history is still preserved, and rows reappear correctly when
-- a log level is re-enabled.
    visibleDebugMessages = {}

    for i = 1, table.getn(debugMessages) do
        -- Nymz:(20260403) LogLevelFilter - skip entries whose level is currently disabled
        if IsLogLevelEnabled(debugMessages[i].level) then
            table.insert(visibleDebugMessages, debugMessages[i])
            text = text .. GetDisplayMessage(debugMessages[i]) .. "\n"
            visibleCount = visibleCount + 1
        end
    end
    debugEditBox:SetText(text)

    counterText:SetText("Shown: " .. visibleCount .. " / Total: " .. totalMessagesSeen)

    contentHeight = GetTextLineCount(text) * lineHeight
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

UpdateDebuggerWidth()

local clearButton = CreateFrame("Button", "FillraidbotsClearButton", debuggerFrame, "UIPanelButtonTemplate")
clearButton:SetPoint("BOTTOM", debuggerFrame, "BOTTOM", -60, 20)
clearButton:SetWidth(100)
clearButton:SetHeight(30)
clearButton:SetText("Clear Messages")
clearButton:SetScript("OnClick", function()
    ClearDebugEditBoxFocus()
    debugMessages = {}
    UpdateDebugMessages()
end)

local copyButton = CreateFrame("Button", "FillraidbotsCopyButton", debuggerFrame, "UIPanelButtonTemplate")
copyButton:SetPoint("LEFT", clearButton, "RIGHT", 8, 0)
copyButton:SetWidth(80)
copyButton:SetHeight(30)
copyButton:SetText("Copy All")
copyButton:SetScript("OnClick", function()
    debugEditBox:SetFocus()
    debugEditBox:HighlightText()
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
    ClearDebugEditBoxFocus()
    -- Nymz:(20260403) DebugVisibility - remember that the user closed the window
    SetDebuggerSetting("debuggerVisible", false)
    debuggerFrame:Hide()
end)

-- Nymz:(20260403) Size - helper to create a small text button near the close button
local function CreateSizeButton(name, label, offsetX, tooltipTitle, tooltipBody, onClick)
    local btn = CreateFrame("Button", name, debuggerFrame)
    btn:SetWidth(15)
    btn:SetHeight(15)
    btn:SetPoint("TOPRIGHT", debuggerFrame, "TOPRIGHT", offsetX, -10)

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(theme.font, theme.fontSize + 2, "OUTLINE")
    fs:SetAllPoints(btn)
    fs:SetText(label)
    fs:SetTextColor(unpack(theme.textColor))
    btn:SetFontString(fs)

    btn:SetScript("OnEnter", function(self)
        fs:SetTextColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltipTitle, 1, 1, 1)
        GameTooltip:AddLine(tooltipBody, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        fs:SetTextColor(unpack(theme.textColor))
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Nymz:(20260403) Size - expand button: grow window by expandStep px
local expandButton = CreateSizeButton(
    "FillraidbotsExpandButton", "v", -66,
    "Expand", "Increase the window height by " .. expandStep .. " px.",
    function()
        ClearDebugEditBoxFocus()
        local current = GetDebuggerSetting("debuggerHeight", defaultHeight)
        -- Only expand if the bottom of the frame won't go off-screen
        local bottom = debuggerFrame:GetBottom()
        if bottom and bottom - expandStep < 0 then
            return
        end
        ApplyDebuggerHeight(current + expandStep)
    end
)

-- Nymz:(20260403) Size - contract button: reduce height by expandStep px
local contractButton = CreateSizeButton(
    "FillraidbotsContractButton", "^", -48,
    "Contract", "Reduce the window height by " .. expandStep .. " px.",
    function()
        ClearDebugEditBoxFocus()
        local current = GetDebuggerSetting("debuggerHeight", defaultHeight)
        ApplyDebuggerHeight(current - expandStep)
    end
)

-- Nymz:(20260403) Size - reset button: restore the default height
local resetSizeButton = CreateSizeButton(
    "FillraidbotsResetSizeButton", "r", -30,
    "Reset Size", "Reset the window height to the default (" .. defaultHeight .. " px).",
    function()
        ClearDebugEditBoxFocus()
        ApplyDebuggerHeight(defaultHeight)
    end
)

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

local logLevelFrame = CreateFrame("Frame", "FillraidbotsLogLevelFrame", debuggerFrame, "BackdropTemplate")
logLevelFrame:SetWidth(200)
logLevelFrame:SetHeight(285)
logLevelFrame:SetPoint("TOPLEFT", debuggerFrame, "TOPRIGHT", 8, -20)
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

-- Nymz:(20260403) LogLevelTooltips - tooltip descriptors for each log level checkbox
local logLevelTooltips = {
    debugfilling    = "Fill loop lifecycle.\nStarting, pausing, resuming, progress and completion of raid fills.\nAlso covers combat blocks and starter bot sequences.",
    debugdetection  = "Bot and player list state.\nLogs when detection lists are cleared or rebuilt.",
    debugremove     = "Bot removal events.\nLogs every uninvite, kick and player removal from the group.",
    debugerror      = "Errors and aborted operations.\nLogs failed sequences, missing presets and internal errors.",
    debuginfo       = "General info.\nRole lists, FixGroups phases, sound state, misc warnings and state resets.",
    debugversion    = "Version handshake.\nAddon prefix registration, guild version broadcast, VIP auth and update checks.",
    debugzones      = "Zone detection.\nLogs current zone, subzone and the max bot cap applied.",
}

local function CreateLogLevelCheckbox(name, label, parent, offsetY, level)
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, offsetY)
    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY")
    checkbox.text:SetFont(theme.font, theme.fontSize)
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.text:SetText(label)
    checkbox.text:SetTextColor(unpack(theme.textColor))
    checkbox:SetChecked(GetDebuggerLevelSetting(level))
    checkbox:SetScript("OnClick", function(self)
        SetDebuggerLevelSetting(level, self:GetChecked() and true or false)
        -- Nymz:(20260403) LogLevelFilter - refresh display so messages for this level show/hide immediately
        UpdateDebugMessages()
    end)
    -- Nymz:(20260403) LogLevelTooltips - show what each level covers on hover
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

local debugFillingCheckbox = CreateLogLevelCheckbox("DebugFillingCheckbox", "Debug Filling", logLevelFrame, -40, "debugfilling")
local debugDetectionCheckbox = CreateLogLevelCheckbox("DebugDetectionCheckbox", "Debug Detection", logLevelFrame, -70, "debugdetection")
local debugRemoveCheckbox = CreateLogLevelCheckbox("DebugRemoveCheckbox", "Debug Remove", logLevelFrame, -100, "debugremove")
local debugErrorCheckbox = CreateLogLevelCheckbox("DebugErrorCheckbox", "Debug Error", logLevelFrame, -130, "debugerror")
local debugInfoCheckbox = CreateLogLevelCheckbox("DebugInfoCheckbox", "Debug Info", logLevelFrame, -160, "debuginfo")
local debugVersionCheckbox = CreateLogLevelCheckbox("DebugVersionCheckbox", "Debug Version", logLevelFrame, -190, "debugversion")
local debugZonesCheckbox = CreateLogLevelCheckbox("DebugZonesCheckbox", "Zones", logLevelFrame, -220, "debugzones")

-- Pumpan:(20260324) Added a timestamp toggle directly in the debugger so the user can
-- switch between compact logs and timestamped logs without editing code.
local timestampCheckbox = CreateFrame("CheckButton", "DebugTimestampCheckbox", logLevelFrame, "UICheckButtonTemplate")
timestampCheckbox:SetPoint("TOPLEFT", logLevelFrame, "TOPLEFT", 20, -250)
timestampCheckbox.text = timestampCheckbox:CreateFontString(nil, "OVERLAY")
timestampCheckbox.text:SetFont(theme.font, theme.fontSize)
timestampCheckbox.text:SetPoint("LEFT", timestampCheckbox, "RIGHT", 5, 0)
timestampCheckbox.text:SetText("Show Timestamps")
timestampCheckbox.text:SetTextColor(unpack(theme.textColor))
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

-- Nymz:(20260403) DebugVisibility - global so FillRaidBots.lua can persist visibility
-- when it shows/hides the debugger frame directly (e.g. Shift+Click Fill).
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

-- Nymz:(20260403) LogLevelFilter - always store messages regardless of level; filtering happens at render time
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
        -- Nymz:(20260403) DebugVisibility - remember closed state
        SetDebuggerSetting("debuggerVisible", false)
        debuggerFrame:Hide()
    else
        -- Nymz:(20260403) DebugVisibility - remember open state
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
        -- Nymz:(20260403) Size - SavedVariables are guaranteed loaded by PLAYER_LOGIN;
        -- flip the flag so EnsureDebuggerSettings can safely read/write them from here on.
        savedVarsReady = true
        EnsureDebuggerSettings()
        RestoreDebuggerFramePosition()
        RefreshDebuggerCheckboxStates()
        UpdateDebuggerWidth()
        UpdateDebugMessages()
        DebugMessage("Player logged in.", "debuginfo")

        -- Nymz:(20260403) DebugVisibility - restore window open/closed state from last session
        -- Nymz:(20260403) Size - restore debugger height from last session
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


-- Pumpan:(20260405) Debugger Scroll Fix
-- Fixed an issue where disabled log levels still affected the scroll height.
-- Messages are now filtered into a visible list before rendering, so hidden rows
-- no longer create invisible scroll space or force unwanted auto-scrolling.
-- Full message history is still preserved, and rows reappear correctly when
-- a log level is re-enabled.
--
-- Nymz:(20260403) Size
-- debugger window height now persists across /rl via SavedVariables
-- added v button: expands window height by 100 px
-- added ^ button: contracts window height by 100 px (floor: default 300 px)
-- added r button: resets window height to default 300 px
-- all three buttons are blue, have tooltips, and are placed near the close button
-- resizing preserves window position; clamping at screen edges is handled gracefully

-- Nymz:(20260403) DebugVisibility
-- debugger window now remembers its open/closed state across /rl
-- window stays hidden after close; Shift+Click Fill or /frbdebug to reopen
-- works even when closed: messages are always buffered when option is enabled

-- Nymz:(20260403) LogLevelFilter
-- messages are always stored regardless of log level
-- enabling/disabling a log level in the Log Levels panel now shows/hides
-- those entries live in the debugger window without needing a reload

-- Nymz:(20260403) LogLevelTooltips
-- added hover tooltips to all log level checkboxes in the Log Levels panel
-- each tooltip describes what category of messages that level covers

-- Nymz:(20260403) MouseWheelScroll
-- added mouse wheel scrolling to the log area
-- scrolling over both the scroll frame and the text box moves the scrollbar

-- Pumpan:(20260325)
-- Use a real EditBox as the scroll child so the log text can be selected/copied

-- Pumpan:(20260324)
-- fixed the broken timestamp/message formatting
-- keep a lifetime counter so the log does not look stuck at 70
-- only auto-scroll when already near the bottom
-- added a Show Timestamps checkbox with SavedVariables support
-- save debugger frame position between reloads
-- tightened scroll text anchoring to the debugger UI
-- restored selectable log text and a Copy All button beside Clear Messages