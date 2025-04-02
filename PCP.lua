local version, build, date, tocversion = GetBuildInfo()

function PCPFrameRemake_OnLoad(self)
    
    if string.find(version, "^1.12") then
        DEFAULT_CHAT_FRAME:AddMessage("Running on WoW Vanilla: " .. version)
        
        
        this:SetMovable(true)
        this:SetUserPlaced(true)
        this:EnableMouse(true)
        this:RegisterForDrag("LeftButton")

        
        this:SetScript("OnDragStart", function()
            this:StartMoving()
        end)

        this:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
        end)
		PCPFrameRemake:Hide()
		
    else
        
        DEFAULT_CHAT_FRAME:AddMessage("Running on WoW Classic: " .. version)
        
        
        self:SetMovable(true)
        self:SetUserPlaced(true)
        self:EnableMouse(true)
        self:RegisterForDrag("LeftButton")

        
        self:SetScript("OnDragStart", function()
            self:StartMoving()
        end)

        self:SetScript("OnDragStop", function()
            self:StopMovingOrSizing()
        end)
		PCPFrameRemake:Hide()	
		
    end
end


if not PCPFrameRemake then
    local frame = CreateFrame("Frame", "PCPFrameRemake", UIParent, "BackdropTemplate")
    frame:SetSize(260, 550)
    frame:SetPoint("CENTER")

	function ToggleBackdrop(frame, enable)
		if enable then
			frame:SetBackdrop({
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
			})
			frame:SetBackdropColor(0, 0, 0, 0.5)
			frame:SetBackdropBorderColor(1, 1, 1, 1)
		else
			frame:SetBackdrop(nil)  
		end
	end
	function ToggletitlesBgCheck(PCPFrameRemake, isChecked)
		if isChecked then
			comeCommandTitleFrame.bg:Show()  
			moveCommandTitleFrame.bg:Show()
			stayCommandTitleFrame.bg:Show()
		else
			comeCommandTitleFrame.bg:Hide()  
			moveCommandTitleFrame.bg:Hide()
			stayCommandTitleFrame.bg:Hide()			
		end
	end	

	function TogglecontrollDeadBotsCheck(PCPFrameRemake, isChecked)
		controlDeadBotsEnabled = isChecked 
		DEFAULT_CHAT_FRAME:AddMessage(isChecked and "Dead bot control enabled" or "Dead bot control disabled")
	end	
    
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    
    frame:SetResizable(true)  
    frame:SetMinResize(200, 300)  

    
    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(16, 16)  
    resizeGrip:SetPoint("BOTTOMRIGHT")  
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

    
    resizeGrip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)

    resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    
    
    local overlayLayer = CreateFrame("Frame", nil, frame)
    overlayLayer:SetFrameLevel(2) 

    
    local titleFontString = overlayLayer:CreateFontString("AddCustomBot", "OVERLAY", "GameFontNormal")

    titleFontString:SetSize(220, 20)
    titleFontString:SetPoint("CENTER", 0, -25)


	
	local classNames = {"Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid"}
	local currentClassIndex = 1  

	
	local classDisplayFontString = overlayLayer:CreateFontString("classDisplay", "OVERLAY", "GameFontNormal")
	classDisplayFontString:SetText(classNames[currentClassIndex])
	classDisplayFontString:SetSize(220, 20)
	classDisplayFontString:SetPoint("CENTER", 0, -60)

	
	local function UpdateClassDisplay()
		classDisplayFontString:SetText(classNames[currentClassIndex])
	end


local isCustomAppearanceEnabled = false
local defaultColor = "originalButtons"  
local settingsLoaded = false


local function SaveSettings(color, backdropEnabled, titlesBgEnabled, controllDeadBotsEnabled)
    if not PCP_Settings then
        PCP_Settings = {}  
    end
    
    if color ~= nil then
        PCP_Settings.color = color
    end
    if backdropEnabled ~= nil then
        PCP_Settings.backdropEnabled = backdropEnabled
    end
    if titlesBgEnabled ~= nil then
        PCP_Settings.titlesBgEnabled = titlesBgEnabled  
    end
    if controllDeadBotsEnabled ~= nil then
        PCP_Settings.controllDeadBotsEnabled = controllDeadBotsEnabled  
    end	
end
function ShowReloadConfirmation(selectedColor)
    
    if PCPReloadFrame then
        PCPReloadFrame:Show()
        return
    end

    
    local reloadFrame = CreateFrame("Frame", "PCPReloadFrame", UIParent, "BackdropTemplate")
    reloadFrame:SetSize(300, 100)
    reloadFrame:SetPoint("CENTER", UIParent, "CENTER")
    reloadFrame:SetMovable(true)
    reloadFrame:EnableMouse(true)
    reloadFrame:RegisterForDrag("LeftButton")
    reloadFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    reloadFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    
    local bg = reloadFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(reloadFrame)
    bg:SetColorTexture(0, 0, 0, 0.8)

    
    local border = CreateFrame("Frame", nil, reloadFrame, "BackdropTemplate")
    border:SetAllPoints(reloadFrame)
    border:SetBackdrop({
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    
    local reloadText = reloadFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reloadText:SetPoint("TOP", reloadFrame, "TOP", 0, -10)
    reloadText:SetText("Reload UI to apply changes?")

    
    local yesButton = CreateFrame("Button", nil, reloadFrame, "UIPanelButtonTemplate")
    yesButton:SetSize(80, 30)
    yesButton:SetPoint("BOTTOMLEFT", reloadFrame, "BOTTOMLEFT", 40, 10)
    yesButton:SetText("Yes")
    yesButton:SetScript("OnClick", function()
        if InCombatLockdown() then
            print("Cannot reload UI while in combat!")
        else
            toggleButtonAppearance(true, selectedColor) 
            ReloadUI() 
        end
    end)

    
    local noButton = CreateFrame("Button", nil, reloadFrame, "UIPanelButtonTemplate")
    noButton:SetSize(80, 30)
    noButton:SetPoint("BOTTOMRIGHT", reloadFrame, "BOTTOMRIGHT", -40, 10)
    noButton:SetText("No")
    noButton:SetScript("OnClick", function()
        reloadFrame:Hide() 
    end)

    
    PCPReloadFrame = reloadFrame
end


local allButtons = {}

local closeButton = CreateFrame("Button", nil, PCPFrameRemake)
closeButton:SetHeight(16)  
closeButton:SetWidth(16)
closeButton:SetPoint("TOPRIGHT", PCPFrameRemake, "TOPRIGHT", -5, -5) 


closeButton:SetNormalTexture("Interface/AddOns/PCP/img/close.tga")


closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")


closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")


closeButton:SetScript("OnClick", function(self)
    PCPFrameRemake:Hide()
end)


closeButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Close", 1, 1, 1, 1, true)
    GameTooltip:Show()
end)
closeButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


table.insert(allButtons, closeButton)



local settingsButton = CreateFrame("Button", nil, PCPFrameRemake)
settingsButton:SetSize(16, 16)  
settingsButton:SetPoint("TOPLEFT", PCPFrameRemake, "TOPLEFT", 5, -5) 
settingsButton:SetNormalTexture("Interface/AddOns/PCP/img/settings.tga")

table.insert(allButtons, settingsButton)

settingsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Settings", 1, 1, 1, 1, true)
    GameTooltip:Show()
end)
settingsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


local settingsFrame = CreateFrame("Frame", "PCPSettingsFrame", PCPFrameRemake, "BackdropTemplate")
settingsFrame:SetSize(200, 150) 
settingsFrame:SetPoint("RIGHT", PCPFrameRemake, "LEFT", -10, 0) 
settingsFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
settingsFrame:SetBackdropColor(0, 0, 0, 0.8) 
settingsFrame:Hide() 


local versionText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
versionText:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -10, 10) 
versionText:SetText("Version 1.0") 
versionText:SetTextColor(1, 1, 1, 1) 


local ClickBlockerFrame = CreateFrame("Frame", "ClickBlockerFrame", UIParent)
ClickBlockerFrame:SetAllPoints(UIParent) 
ClickBlockerFrame:EnableMouse(true) 
ClickBlockerFrame:SetFrameStrata("DIALOG") 
ClickBlockerFrame:SetFrameStrata("BACKGROUND")  
ClickBlockerFrame:SetFrameLevel(1)  
ClickBlockerFrame:Hide() 

ClickBlockerFrame:SetScript("OnMouseDown", function()
    ClickBlockerFrame:Hide() 
    settingsFrame:Hide()  
end)


local function ToggleSettingsFrame()
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
        ClickBlockerFrame:Hide()  
    else
        settingsFrame:Show()
        ClickBlockerFrame:Show()  
    end
end

settingsButton:SetScript("OnClick", ToggleSettingsFrame)


local colorDropdown = CreateFrame("Frame", "PCPColorDropdown", settingsFrame, "UIDropDownMenuTemplate")
colorDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -10)


local colorOptions = {
    { text = "Original", color = "originalButtons" },
    { text = "Pink", color = "pink" },
    { text = "Pink solid", color = "solidpink" },	
    { text = "Green", color = "green" },
    { text = "Green solid", color = "solidgreen" },	
    { text = "Blue", color = "blue" },
    { text = "Blue solid", color = "solidblue" },	
    { text = "Gray", color = "gray" },
    { text = "Gray solid", color = "solidgray" },	
    { text = "Black", color = "black" }
}


local function InitializeDropdown(self, level)
    for _, option in ipairs(colorOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.func = function()
            UIDropDownMenu_SetSelectedName(colorDropdown, option.text)  
            toggleButtonAppearance(true, option.color)  
			ShowReloadConfirmation(option.color)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_Initialize(colorDropdown, InitializeDropdown)
UIDropDownMenu_SetWidth(colorDropdown, 120)
UIDropDownMenu_SetButtonWidth(colorDropdown, 140)
UIDropDownMenu_SetSelectedName(colorDropdown, "Select Color")
UIDropDownMenu_JustifyText(colorDropdown, "LEFT")


local function CloseSettingsOnClick(_, button)
    if button == "LeftButton" and settingsFrame:IsShown() then
        local x, y = GetCursorPosition()
        local scale = settingsFrame:GetEffectiveScale()
        local left, bottom, width, height = settingsFrame:GetRect()
        left, bottom = left * scale, bottom * scale
        width, height = width * scale, height * scale

        if not (x >= left and x <= left + width and y >= bottom and y <= bottom + height) then
            settingsFrame:Hide()
        end
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnMouseDown", CloseSettingsOnClick)
eventFrame:SetFrameStrata("TOOLTIP")
eventFrame:EnableMouse(true)


local backdropCheck = CreateFrame("CheckButton", "PCPBackdropCheck", settingsFrame, "UICheckButtonTemplate")
backdropCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -40)
backdropCheck.text = backdropCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
backdropCheck.text:SetPoint("LEFT", backdropCheck, "RIGHT", 5, 0)
backdropCheck.text:SetText("Enable Backdrop")
backdropCheck:SetChecked(true)  


backdropCheck:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    ToggleBackdrop(PCPFrameRemake, isChecked)
    SaveSettings(defaultColor, isChecked)  
end)

local titlesBgCheck = CreateFrame("CheckButton", "PCPtitlesBgCheck", settingsFrame, "UICheckButtonTemplate")
titlesBgCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -70)
titlesBgCheck.text = titlesBgCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titlesBgCheck.text:SetPoint("LEFT", titlesBgCheck, "RIGHT", 5, 0)
titlesBgCheck.text:SetText("Title background")
titlesBgCheck:SetChecked(true)  


titlesBgCheck:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()  
    ToggletitlesBgCheck(PCPFrameRemake, isChecked)
    SaveSettings(defaultColor, nil, isChecked)  
end)

local controllDeadBotsCheck = CreateFrame("CheckButton", "PCPcontrollDeadBotsCheck", settingsFrame, "UICheckButtonTemplate")
controllDeadBotsCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -100)
controllDeadBotsCheck.text = controllDeadBotsCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
controllDeadBotsCheck.text:SetPoint("LEFT", controllDeadBotsCheck, "RIGHT", 5, 0)
controllDeadBotsCheck.text:SetText("Dead Controll")
controllDeadBotsCheck:SetChecked(true)  
controllDeadBotsCheck:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Allows you to control bots even after dying.", 1, 1, 1, 1, true)
    GameTooltip:Show()
end)

controllDeadBotsCheck:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


controllDeadBotsCheck:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    TogglecontrollDeadBotsCheck(PCPFrameRemake, isChecked)
    SaveSettings(defaultColor, nil, nil, isChecked)  
end)


ToggleBackdrop(PCPFrameRemake, backdropCheck:GetChecked())

function LoadSavedSettings()
    if PCP_Settings then
        
        if PCP_Settings.color then
            defaultColor = PCP_Settings.color
        else
            defaultColor = "originalButtons"  
        end

        
        if PCP_Settings.backdropEnabled ~= nil then
            backdropCheck:SetChecked(PCP_Settings.backdropEnabled)
            ToggleBackdrop(PCPFrameRemake, PCP_Settings.backdropEnabled)
        end

        
        if PCP_Settings.titlesBgEnabled ~= nil then
            titlesBgCheck:SetChecked(PCP_Settings.titlesBgEnabled)  
            ToggletitlesBgCheck(PCPFrameRemake, PCP_Settings.titlesBgEnabled)  
        end
		
        if PCP_Settings.controllDeadBotsEnabled ~= nil then
            controllDeadBotsCheck:SetChecked(PCP_Settings.controllDeadBotsEnabled)  
            TogglecontrollDeadBotsCheck(PCPFrameRemake, PCP_Settings.controllDeadBotsEnabled)  
        end		
    end

    
    toggleButtonAppearance(true, defaultColor)
end


function createButton(name, text, xOffset, yOffset, onClickFunc, width, height, parentFrame)
    local button

        button = CreateFrame("Button", name, parentFrame)
        local fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
        fontString:SetPoint("CENTER")
        button:SetFontString(fontString) 


    button:SetSize(width, height)
    button:SetPoint("CENTER", parentFrame, "CENTER", xOffset, yOffset)
    button:SetText(text)
    button:SetScript("OnClick", onClickFunc)

    
    table.insert(allButtons, button)

    
    if parentFrame == ComeCommandFrame then 
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Come " .. text .. " ")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    elseif parentFrame == MoveCommandFrame then 
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move " .. text .. " ")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)    
    elseif parentFrame == StayCommandFrame then 
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Stay " .. text .. " ")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return button
end




function toggleButtonAppearance(enabled, color)
    isCustomAppearanceEnabled = enabled
    SaveSettings(color)

    for _, button in ipairs(allButtons) do
        
        button:SetNormalTexture(nil)
        button:SetHighlightTexture(nil)
        button:SetPushedTexture(nil)
        button:SetDisabledTexture(nil)

        if color == "originalButtons" then
            
            local normalTexture = button:CreateTexture(nil, "ARTWORK")
            normalTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
            normalTexture:SetTexCoord(0, 0.625, 0, 0.6875) 
            normalTexture:SetAllPoints(button) 
            button:SetNormalTexture(normalTexture)

            local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
			highlightTexture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            highlightTexture:SetTexCoord(0, 0.625, 0, 0.6875)
            highlightTexture:SetAllPoints(button)
            button:SetHighlightTexture(highlightTexture)

            local pushedTexture = button:CreateTexture(nil, "PUSHED")
            pushedTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down")
            pushedTexture:SetTexCoord(0, 0.625, 0, 0.6875)
            pushedTexture:SetAllPoints(button)
            button:SetPushedTexture(pushedTexture)

            local disabledTexture = button:CreateTexture(nil, "DISABLED")
            disabledTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
            disabledTexture:SetTexCoord(0, 0.625, 0, 0.6875)
            disabledTexture:SetAllPoints(button)
            button:SetDisabledTexture(disabledTexture)
        else
            
            local bgTexture = button:CreateTexture(nil, "BACKGROUND")
            bgTexture:SetAllPoints(button)
            bgTexture:SetTexture("Interface\\AddOns\\PCP\\img\\bg.tga")

            
            if color == "pink" then
                bgTexture:SetVertexColor(1, 0.75, 0.8, 0.1)
            elseif color == "solidpink" then
                bgTexture:SetVertexColor(1, 0.75, 0.8, 1)
            elseif color == "green" then
                bgTexture:SetVertexColor(0.25, 0.55, 0.25, 0.15)
            elseif color == "solidgreen" then
                bgTexture:SetVertexColor(0, 0.6, 0, 1)
            elseif color == "blue" then
                bgTexture:SetVertexColor(0, 0, 1, 0.1)
            elseif color == "solidblue" then
                bgTexture:SetVertexColor(0, 0, 1, 1)
            elseif color == "gray" then
                bgTexture:SetVertexColor(0.5, 0.5, 0.5, 0.2)
            elseif color == "solidgray" then
                bgTexture:SetVertexColor(0.5, 0.5, 0.5, 1)
            elseif color == "black" then
                bgTexture:SetVertexColor(0, 0, 0, 0.5)
                if button.Text then
                    button.Text:SetTextColor(1, 1, 1, 1)
                end
            else
                bgTexture:SetVertexColor(0, 0, 0, 1)
            end
			
			local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
			border:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
			border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
			border:SetBackdrop({
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				edgeSize = 6,
			})
			border:SetBackdropBorderColor(1, 1, 0, 1)
			border:SetFrameLevel(button:GetFrameLevel() + 1)			
        end

        
        if button.iconTexture then
            button.iconTexture:SetDrawLayer("OVERLAY")  
        end
		if button == settingsButton then
			local settingsIcon = button:CreateTexture(nil, "OVERLAY")
			settingsIcon:SetTexture("Interface/AddOns/PCP/img/settings.tga")
			
			
			local iconSize = 12  
			settingsIcon:SetWidth(iconSize)
			settingsIcon:SetHeight(iconSize)

			
			settingsIcon:SetPoint("CENTER", button, "CENTER", 0, 0)

			settingsIcon:SetDrawLayer("OVERLAY")  
		elseif button == closeButton then
			local closeIcon = button:CreateTexture(nil, "OVERLAY")
			closeIcon:SetTexture("Interface/AddOns/PCP/img/close.tga")
			
			
			local iconSize = 10  
			closeIcon:SetWidth(iconSize)
			closeIcon:SetHeight(iconSize)

			
			closeIcon:SetPoint("CENTER", button, "CENTER", 0, 0)

			closeIcon:SetDrawLayer("OVERLAY")  
		end

        

		local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
		highlightTexture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")  
		highlightTexture:SetAllPoints(button)
		highlightTexture:SetVertexColor(1, 1, 0, 0.1)  
		highlightTexture:SetDrawLayer("HIGHLIGHT")  
		button:SetHighlightTexture(highlightTexture)

        
        local pushedTexture = button:CreateTexture(nil, "PUSHED")
        pushedTexture:SetTexture("Interface/AddOns/PCP/img/bg.tga")
        pushedTexture:SetAllPoints(button)
        pushedTexture:SetVertexColor(0.8, 0.2, 0.2)
        button:SetPushedTexture(pushedTexture)


    end
end


SLASH_TOGGLEBUTTON1 = "/tgl"
SlashCmdList["TOGGLEBUTTON"] = function(msg)
    local color = msg:match("^(%S+)")  

    if msg == "on" then
        toggleButtonAppearance(true, defaultColor)  
        print("Custom appearance enabled with last used color: " .. defaultColor)
    elseif msg == "off" then
        toggleButtonAppearance(false, defaultColor)  
        print("Custom appearance disabled")
    elseif color == "pink" or color == "green" or color == "blue" or color == "gray" or color == "black" or color == "originalButtons" then
        toggleButtonAppearance(true, color)  
        print("Custom appearance enabled with color: " .. color)
    else
        print("Usage: /tgl on | off | pink | green | blue | gray | black")
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event)

        LoadSavedSettings()

end)
LoadSavedSettings()




	
	local addBotFrame = CreateFrame("Frame", "AddBotFrame", frame)
	addBotFrame:SetSize(300, 100)  
	addBotFrame:SetPoint("TOP", frame, "TOP", 0, -10)  

	
	addBotFrame.bg = addBotFrame:CreateTexture(nil, "BACKGROUND")
	addBotFrame.bg:SetAllPoints(true)
	


	





	
function createClassRoleButton(name, text, xOffset, yOffset, onClickFunc, width, height, parentFrame)
    local button

        button = CreateFrame("Button", name, parentFrame)
        local fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
        fontString:SetPoint("CENTER")
        button:SetFontString(fontString) 


    button:SetSize(width, height)
    button:SetPoint("CENTER", parentFrame, "CENTER", xOffset, yOffset)
    button:SetText(text)
    button:SetScript("OnClick", onClickFunc)

    
    button:Hide()

    
    table.insert(allButtons, button)

    return button
end




classButton = createClassRoleButton("ClassButton", "Warrior", 0, 20, function() print("Warrior class selected!") end, 80, 30, addBotFrame)
classButton:Show()

roleButton = createClassRoleButton("RoleButton", "Tank", 0, -30, function() SubPartyBotAddAdvanced() end, 80, 30, addBotFrame)
roleButton:Show()
        roleButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Click to add", 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
		roleButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
	
createButton("SetClassADDButton", "+", 58, 10, function() SetClassADD() end, 30, 30, addBotFrame)
createButton("SetClassSUBButton", "-", -58, 10, function() SetClassSUB() end, 30, 30, addBotFrame)
	
	createButton("SetRoleADDButton", "+", 58, -10, function() SetRoleADD() end, 30, 30, addBotFrame)
	createButton("SetRoleSUBButton", "-", -58, -10, function() SetRoleSUB() end, 30, 30, addBotFrame)



	
	local commandsFrame = CreateFrame("Frame", "CommandsFrame", frame)
	commandsFrame:SetSize(300, 130)  
	commandsFrame:SetPoint("TOP", addBotFrame, "BOTTOM", 0, 0)  

	
	commandsFrame.bg = commandsFrame:CreateTexture(nil, "BACKGROUND")
	commandsFrame.bg:SetAllPoints(true)
	



	
	local commandsTitle = commandsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	commandsTitle:SetPoint("CENTER", commandsFrame, "TOP", 0, -5)  

	
	
local commands = {
    {"CmdCome", "Come", -65, 80, function() SetCommand("come") end, 80, 30},
    {"CmdStart", "Start", 0, 80, function() SetCommand("attackstart") end, 80, 30},
    {"CmdStop", "Stop", 65, 80, function() SetCommand("attackstop") end, 80, 30},

    {"CmdUse", "Object", -65, 50, function() SetCommand("use") end, 80, 30},
    {"CmdPause", "Pause", 0, 50, function() SetPause() end, 80, 30},
    {"CmdUnpause", "Unpause", 65, 50, function() SetUnpause() end, 80, 30},

    {"CmdAOE", "AoE", -65, 20, function() SetCommand("aoe") end, 80, 30},  
    {"CmdPauseAll", "Pause all", 0, 20, function() SetCommand("pause all") end, 80, 30},  
    {"CmdUnpauseAll", "Unpause all", 65, 20, function() SetCommand("unpause") end, 80, 30},  

    {"CmdStay", "Stay", -65, -10, function() SetCommand("stay") end, 80, 30},  
    {"CmdMove", "Move", 0, -10, function() SetCommand("move") end, 80, 30},   
    {"CmdPull", "Pull", 65, -10, function() SetCommand("pull") end, 80, 30},   
}


	for _, cmd in ipairs(commands) do
		createButton(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], commandsFrame)
	end


	
	local partyBotCommandsFrame = CreateFrame("Frame", "PartyBotCommandsFrame", frame)
	partyBotCommandsFrame:SetSize(300, 130)  
	partyBotCommandsFrame:SetPoint("TOP", commandsFrame, "BOTTOM", 0, 0)  

	
	partyBotCommandsFrame.bg = partyBotCommandsFrame:CreateTexture(nil, "BACKGROUND")
	partyBotCommandsFrame.bg:SetAllPoints(true)
	

	
	local partyBotCommandsTitle = partyBotCommandsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	partyBotCommandsTitle:SetPoint("TOP", partyBotCommandsFrame, "TOP", 0, -5)  

	
	local partyBotCommands = {
		{"PartyBotStayAll", "Stay All", -75, -5, function() SubPartyBotStayAll() end, 50, 30},  
		{"PartyBotMoveAll", "Move All", 75, -5, function() SubPartyBotMoveAll() end, 50, 30},
		{"PartyBotSpread", "Spread", -75, -5, function() SetCommand("spread") end, 50, 30},
		{"PartyBotSpreadStop", "Spread Stop", 50, -40, function() SetCommand("spreadoff") end, 50, 30},
		{"PartyBotDistance", "Distance", -50, -70, function() SetCommand("distance on") end, 50, 30},
		{"PartyBotDistanceOff", "Distance Off", 50, -70, function() SetCommand("distance off") end, 50, 30},
	}

	
	for _, cmd in ipairs(partyBotCommands) do
		createButton(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], partyBotCommandsFrame)
	end

	
	local comeCommandTitleFrame = CreateFrame("Frame", "comeCommandTitleFrame", commandsFrame)
	comeCommandTitleFrame:SetSize(300, 60)  
	comeCommandTitleFrame:SetPoint("TOP", partyBotCommandsFrame, "BOTTOM", 0, -2)  

	
	comeCommandTitleFrame.bg = comeCommandTitleFrame:CreateTexture(nil, "BACKGROUND")
	comeCommandTitleFrame.bg:SetAllPoints(true)
	comeCommandTitleFrame.bg:SetColorTexture(0.6, 0.4, 0.2, 0.5)  

	
	local comeTitle = comeCommandTitleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	comeTitle:SetText("Come Commands")
	comeTitle:SetPoint("CENTER", comeCommandTitleFrame, "TOP", 0, -5)  

	
	local comeCommandFrame = CreateFrame("Frame", "ComeCommandFrame", commandsFrame)
	comeCommandFrame:SetSize(300, 10)  
	comeCommandFrame:SetPoint("TOP", comeCommandTitleFrame, "BOTTOM", 0, -2)  

	
	comeCommandFrame.bg = comeCommandFrame:CreateTexture(nil, "BACKGROUND")
	comeCommandFrame.bg:SetAllPoints(true)
	

	
	local roleCommandButtons = {
		{"CmdCometank", "Tank", -75, -5, function() SetCommand("cometank") end, 50, 30},
		{"CmdComeheal", "Heal", -25, -5, function() SetCommand("comeheal") end, 50, 30},
		{"CmdComemelee", "Melee", 25, -5, function() SetCommand("comemelee") end, 50, 30},
		{"CmdComerange", "Range", 75, -5, function() SetCommand("comerange") end, 50, 30},
	}

	for _, cmd in ipairs(roleCommandButtons) do
		createButton(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], comeCommandFrame)
	end

	
	local moveCommandTitleFrame = CreateFrame("Frame", "moveCommandTitleFrame", commandsFrame)
	moveCommandTitleFrame:SetSize(300, 10)  
	moveCommandTitleFrame:SetPoint("TOP", comeCommandFrame, "BOTTOM", 0, -2)  

	
	moveCommandTitleFrame.bg = moveCommandTitleFrame:CreateTexture(nil, "BACKGROUND")
	moveCommandTitleFrame.bg:SetAllPoints(true)
	moveCommandTitleFrame.bg:SetColorTexture(0.4, 0.6, 0.2, 0.5)  

	
	local moveTitle = moveCommandTitleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	moveTitle:SetText("Move Commands")
	moveTitle:SetPoint("CENTER", moveCommandTitleFrame, "TOP", 0, -5)  
	
	local moveCommandFrame = CreateFrame("Frame", "MoveCommandFrame", commandsFrame)
	moveCommandFrame:SetSize(300, 60)  
	moveCommandFrame:SetPoint("TOP", moveCommandTitleFrame, "BOTTOM", 0, -2)  

	
	moveCommandFrame.bg = moveCommandFrame:CreateTexture(nil, "BACKGROUND")
	moveCommandFrame.bg:SetAllPoints(true)
	

	local moveRoleCommandButtons = {
		{"CmdMovetank", "Tank", -75, -5, function() SetCommand("movetank") end, 50, 30},
		{"CmdMoveheal", "Heal", -25, -5, function() SetCommand("moveheal") end, 50, 30},
		{"CmdMovemelee", "Melee", 25, -5, function() SetCommand("movemelee") end, 50, 30},
		{"CmdMoverange", "Range", 75, -5, function() SetCommand("moverange") end, 50, 30},
	}

	for _, cmd in ipairs(moveRoleCommandButtons) do
		createButton(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], moveCommandFrame)
	end

	local stayCommandTitleFrame = CreateFrame("Frame", "stayCommandTitleFrame", commandsFrame)
	stayCommandTitleFrame:SetSize(300, 60)  
	stayCommandTitleFrame:SetPoint("TOP", moveCommandFrame, "BOTTOM", 0, -2)  

	
	stayCommandTitleFrame.bg = stayCommandTitleFrame:CreateTexture(nil, "BACKGROUND")
	stayCommandTitleFrame.bg:SetAllPoints(true)
	stayCommandTitleFrame.bg:SetColorTexture(0.4, 0.2, 0.6, 0.5)  


	local stayTitle = stayCommandTitleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	stayTitle:SetText("Stay Commands")
	stayTitle:SetPoint("CENTER", stayCommandTitleFrame, "TOP", 0, -5)  


	
	local stayCommandFrame = CreateFrame("Frame", "StayCommandFrame", commandsFrame)
	stayCommandFrame:SetSize(300, 60)  
	stayCommandFrame:SetPoint("TOP", stayCommandTitleFrame, "BOTTOM", 0, -2)  

	
	stayCommandFrame.bg = stayCommandFrame:CreateTexture(nil, "BACKGROUND")
	stayCommandFrame.bg:SetAllPoints(true)
	

	
	local defaultButtonWidth = 50
	local defaultButtonHeight = 30


	
	local stayRoleCommandButtons = {
		{"CmdStaytank", "Tank", -75, -10, function() SetCommand("staytank") end},
		{"CmdStayheal", "Heal", -25, -10, function() SetCommand("stayheal") end},
		{"CmdStaymelee", "Melee", 25, -10, function() SetCommand("staymelee") end},
		{"CmdStayrange", "Range", 75, -10, function() SetCommand("stayrange") end},
	}

	for _, cmd in ipairs(stayRoleCommandButtons) do
		createButton(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], defaultButtonWidth, defaultButtonHeight, stayCommandFrame)
	end


local markFrame = CreateFrame("Frame", "MarkFrame", PCPFrameRemake)
markFrame:SetSize(300, 50) 
markFrame:SetPoint("TOP", stayCommandFrame, "BOTTOM", 0, 2)




markFrame.bg = markFrame:CreateTexture(nil, "BACKGROUND")
markFrame.bg:SetAllPoints(true)



local function createMarkButton(name, text, xOffset, onClickFunc, width, height, parentFrame)
    local button

        button = CreateFrame("Button", name, parentFrame)
        local fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
        fontString:SetPoint("CENTER")
        button:SetFontString(fontString) 


    button:SetSize(width, height)
    button:SetPoint("TOP", parentFrame, "TOP", xOffset, -10) 
    button:SetText(text)
    button:SetScript("OnClick", onClickFunc)

	table.insert(allButtons, button)
    return button
end




Marks = { "CC Mark", "Focus Mark" }
MarkItr = 1 


local function UpdateMarkDisplay()
    markButton:SetText(Marks[MarkItr])
end
createButton("SetMarkADDButton", "+", 58, 10, function() MarkADD() end, 30, 30, markFrame)
createButton("SetMarkSUBButton", "-", -58, 10, function() MarkSUB() end, 30, 30, markFrame)
markButton = createMarkButton("MarkButton", Marks[MarkItr], 0, function() ShowMark() end, 95, 30, markFrame)



local markCommandFrame = CreateFrame("Frame", "MarkCommandFrame", PCPFrameRemake)
markCommandFrame:SetSize(300, 120)  
markCommandFrame:SetPoint("TOP", markFrame, "BOTTOM", 0, -2)  


markCommandFrame.bg = markCommandFrame:CreateTexture(nil, "BACKGROUND")
markCommandFrame.bg:SetAllPoints(true)






local function createMarkCommandButton(name, iconPath, tooltipText, xOffset, yOffset, onClickFunc, width, height, parentFrame)
    local button


        button = CreateFrame("Button", name, parentFrame)
        local fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
        fontString:SetPoint("CENTER")
        button:SetFontString(fontString) 


    button:SetSize(width, height)
    button:SetPoint("TOP", parentFrame, "TOP", xOffset, yOffset)

    
    local iconTexture = button:CreateTexture(nil, "OVERLAY")  
    iconTexture:SetTexture(iconPath)
    iconTexture:SetSize(width * 0.4, height * 0.4)  
    iconTexture:SetPoint("CENTER", button, "CENTER", 0, 0)  
    iconTexture:SetTexCoord(0.25, 0.75, 0.25, 0.75)  
    button.iconTexture = iconTexture  

    
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.1) 

    button:SetScript("OnClick", onClickFunc)

    
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltipText, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    table.insert(allButtons, button)
    return button
end



local iconCoords = {
    moon = {0.00, 0.25, 0.25, 0.50},
    star = {0.00, 0.25, 0.00, 0.25},
    circle = {0.25, 0.50, 0.00, 0.25},
    diamond = {0.50, 0.75, 0.00, 0.25},
    triangle = {0.75, 1.00, 0.00, 0.25},
    square = {0.25, 0.50, 0.25, 0.50},
    cross = {0.50, 0.75, 0.25, 0.50},
    skull = {0.75, 1.00, 0.25, 0.50},
}


local defaultButtonWidth = 40
local defaultButtonHeight = 30

local markCommandButtons = {
    {"PartyBotCCSkull", "skull", "Skull", 40, -50, function() SetMark("skull") end},
    {"PartyBotCCCross", "cross", "Cross", 0, -50, function() SetMark("cross") end},	
    {"PartyBotCCSquare", "square", "Square", -40, -50, function() SetMark("square") end},	
    {"PartyBotCCMoon", "moon", "Moon", -80, -10, function() SetMark("moon") end},
    {"PartyBotCCTriangle", "triangle", "Triangle", -80, -50, function() SetMark("triangle") end},
    {"PartyBotCCDiamond", "diamond", "Diamond", 40, -10, function() SetMark("diamond") end},
    {"PartyBotCCCircle", "circle", "Circle", 0, -10, function() SetMark("circle") end},
    {"PartyBotCCStar", "star", "Star", -40, -10, function() SetMark("star") end},






    {"PartyBotCCClear", "Interface\\Buttons\\UI-GroupLoot-Pass-Up", "Clear", 80, -10, function() ClearMark() end},
    {"PartyBotCCClearAll", "Interface\\Buttons\\UI-GroupLoot-Coin-Up", "Clear All", 80, -50, function() ClearAllMark() end},
}


for _, cmd in ipairs(markCommandButtons) do
    local button = createMarkCommandButton(
        cmd[1], 
        "Interface\\TargetingFrame\\UI-RaidTargetingIcons", 
        cmd[3], 
        cmd[4], 
        cmd[5], 
        cmd[6], 
        defaultButtonWidth, 
        defaultButtonHeight, 
        markCommandFrame
    )
    
    local coords = iconCoords[cmd[2]]
    if coords and button.iconTexture then
        button.iconTexture:SetTexCoord(unpack(coords))
    end
end




local function ResizeMarkCommandButtons(commandButtons, commandFrame, buttonsPerRow, extraWidth)
    buttonsPerRow = buttonsPerRow or 5  
    local buttonCount = #commandButtons
    local rows = math.ceil(buttonCount / buttonsPerRow)  
    local padding = 5  

    
    local totalHorizontalPadding = padding * (buttonsPerRow - 1)
    local availableWidth = commandFrame:GetWidth() - totalHorizontalPadding

    local totalVerticalPadding = padding * (rows - 1)
    local availableHeight = commandFrame:GetHeight() - totalVerticalPadding

    
    local baseButtonWidth = math.floor(availableWidth / buttonsPerRow)

    
    local buttonWidth = baseButtonWidth + (extraWidth or 0)
    local buttonHeight = math.floor(availableHeight / rows)

    
    buttonHeight = math.min(buttonWidth, buttonHeight)

    
    for i, cmd in ipairs(commandButtons) do
        local button = _G[cmd[1]]
        if button then
            
            button:SetWidth(buttonWidth)
            button:SetHeight(buttonHeight)

            
            local normalTexture = button:GetNormalTexture()
            if normalTexture then
                normalTexture:SetSize(buttonWidth * 0.4, buttonHeight * 0.4)  
            end

            
            local fontSize = math.max(10, math.min(buttonWidth / 4, 12))
            local font, _, flags = button:GetFontString():GetFont()
            button:GetFontString():SetFont(font, fontSize, flags)

            
            local row = math.floor((i - 1) / buttonsPerRow)  
            local col = (i - 1) % buttonsPerRow  

            if col == 0 then
                
                button:SetPoint("TOPLEFT", commandFrame, "TOPLEFT", 0, -(row * (buttonHeight + padding)))
            else
                
                local previousButton = _G[commandButtons[i - 1][1]]
                button:SetPoint("TOPLEFT", previousButton, "TOPRIGHT", padding, 0)
            end
        end
    end

    
    return rows * (buttonHeight + padding)
end




local defaultButtonWidth = 50
local defaultButtonHeight = 30
local padding = 10


local function ResizeRoleCommandButtons(commandButtons, commandFrame, buttonHeight)
    local width = commandFrame:GetWidth()
    local padding = 5 
    local buttonsPerRow = 4 
    local buttonCount = #commandButtons
    local rows = math.ceil(buttonCount / buttonsPerRow)
    local totalHorizontalPadding = padding * (buttonsPerRow - 1)
    local availableWidth = width - totalHorizontalPadding
    local buttonWidth = math.floor(availableWidth / buttonsPerRow)

    
    buttonHeight = buttonHeight or math.floor(commandFrame:GetHeight() / rows) - padding

    for i, cmd in ipairs(commandButtons) do
        local button = _G[cmd[1]]
        if button then
            button:SetSize(buttonWidth, buttonHeight)

            
            local fontSize = math.max(8, math.min(buttonWidth / 5, buttonHeight / 3))
            local font, _, flags = button:GetFontString():GetFont()
            button:GetFontString():SetFont(font, fontSize, flags)

            
            local row = math.floor((i - 1) / buttonsPerRow)
            local col = (i - 1) % buttonsPerRow

            if col == 0 then
                button:SetPoint("TOPLEFT", commandFrame, "TOPLEFT", 0, -row * (buttonHeight + padding))
            else
                local prevButton = _G[commandButtons[i - 1][1]]
                button:SetPoint("TOPLEFT", prevButton, "TOPRIGHT", padding, 0)
            end
        end
    end
end




local defaultButtonWidth = 50
local defaultButtonHeight = 30
local padding = 5


local function ResizeCommandButtons(commandButtons, commandFrame, buttonsPerRow, extraWidth, startingYOffset, isPartyBot)
    buttonsPerRow = buttonsPerRow or 3  
    local buttonCount = #commandButtons
    local rows = math.ceil(buttonCount / buttonsPerRow)  
    local padding = 2  

    local totalHorizontalPadding = padding * (buttonsPerRow - 1)  
    local availableWidth = commandFrame:GetWidth() - totalHorizontalPadding  

    local totalVerticalPadding = padding * (rows - 1)  
    local availableHeight = commandFrame:GetHeight() - totalVerticalPadding  

    
    local buttonWidth = math.floor((availableWidth - (extraWidth or 0)) / buttonsPerRow)  
    local buttonHeight = math.floor(availableHeight / rows)  

    
    local yOffset = startingYOffset or 0

    
    for i, cmd in ipairs(commandButtons) do
        local button = _G[cmd[1]]
        if button then
            button:SetWidth(buttonWidth + (extraWidth or 0))  
            button:SetHeight(buttonHeight)  

            
            local fontSize
            if isPartyBot then
                fontSize = math.max(6, math.min(buttonWidth / 4, buttonHeight / 2))  
            else
                fontSize = math.max(8, math.min(buttonWidth / 2, buttonHeight / 2))  
            end

            local font, _, flags = button:GetFontString():GetFont()  
            button:GetFontString():SetFont(font, fontSize, flags)  

            
            local row = math.floor((i - 1) / buttonsPerRow)  
            local col = (i - 1) % buttonsPerRow  

            if col == 0 then
                
                button:SetPoint("TOPLEFT", commandFrame, "TOPLEFT", 0, yOffset - (row * (buttonHeight + padding)))
            else
                
                local previousButton = _G[commandButtons[i - 1][1]]
                button:SetPoint("TOPLEFT", previousButton, "TOPRIGHT", padding, 0)
            end
        end
    end

    
    return rows * (buttonHeight + padding)
end

local function ResizeAddBotButtons()
    local width, height = addBotFrame:GetSize()     
    AddCustomBot:SetSize(width / 3, height / 4)  
    classButton:SetSize(width / 3 + 10, height / 4 + 5)  
    roleButton:SetSize(width / 3 + 10, height / 4 + 5)  

    
    local buttonWidth, buttonHeight = classButton:GetSize()
    local fontSize = math.max(9, math.min(buttonWidth / 5, buttonHeight / 3)) 
    local font, _, flags = classButton:GetFontString():GetFont()
    classButton:GetFontString():SetFont(font, fontSize, flags)

    buttonWidth, buttonHeight = roleButton:GetSize()
    fontSize = math.max(8, math.min(buttonWidth / 5, buttonHeight / 3))
    font, _, flags = roleButton:GetFontString():GetFont()
    roleButton:GetFontString():SetFont(font, fontSize, flags)

    
    local squareSize = math.min(width, height) / 3
    SetClassADDButton:SetSize(squareSize, squareSize)  
    SetClassSUBButton:SetSize(squareSize, squareSize)  
    SetRoleADDButton:SetSize(squareSize, squareSize)   
    SetRoleSUBButton:SetSize(squareSize, squareSize)   

    
    AddCustomBot:SetPoint("CENTER", addBotFrame, "CENTER", 0, -40)

    
    local buttonPadding = 5  
    classButton:SetPoint("CENTER", addBotFrame, "CENTER", 0, 10)
    roleButton:SetPoint("CENTER", classButton, "CENTER", 0, -(classButton:GetHeight() + buttonPadding))

    
    SetClassADDButton:ClearAllPoints()
    SetClassADDButton:SetPoint("LEFT", classButton, "RIGHT", 0, 0)  
    SetClassSUBButton:ClearAllPoints()
    SetClassSUBButton:SetPoint("RIGHT", classButton, "LEFT", 0, 0)
    SetRoleADDButton:ClearAllPoints()
    SetRoleADDButton:SetPoint("LEFT", roleButton, "RIGHT", 0, 0)
    SetRoleSUBButton:ClearAllPoints()
    SetRoleSUBButton:SetPoint("RIGHT", roleButton, "LEFT", 0, 0)  
end

local function ResizeMarkButtons()
    local width, height = addBotFrame:GetSize() 
    local squareSize = math.min(width, height) / 3
    SetMarkADDButton:SetSize(squareSize, squareSize)
    SetMarkSUBButton:SetSize(squareSize, squareSize)
    markButton:SetSize(squareSize * 2 + 50, squareSize)
    
    local padding = 0  

    markButton:ClearAllPoints()
    markButton:SetPoint("CENTER", markFrame, "CENTER", 0, 0)

    SetMarkADDButton:ClearAllPoints()
    SetMarkADDButton:SetPoint("LEFT", markButton, "RIGHT", padding, 0)
    SetMarkSUBButton:ClearAllPoints()
    SetMarkSUBButton:SetPoint("RIGHT", markButton, "LEFT", -padding, 0)
end



frame:SetScript("OnSizeChanged", function(self)
    local width, height = self:GetSize()

    
    local padding = height * 0.005 

    
    local totalHeight = height - padding * 2

    
local frameHeights = {
    addBotFrame = totalHeight * 0.12,          
    commandsFrame = totalHeight * 0.19,        
    partyBotCommandsFrame = totalHeight * 0.19, 
    comeCommandTitleFrame = 10,                
    comeCommandFrame = totalHeight * 0.05,     
    moveCommandTitleFrame = 10,                
    moveCommandFrame = totalHeight * 0.05,     
    stayCommandTitleFrame = 10,                
    stayCommandFrame = totalHeight * 0.05,     

    markFrame = totalHeight * 0.04,            
    markCommandFrame = totalHeight * 0.15      
}
    
    addBotFrame:SetHeight(frameHeights.addBotFrame)
    commandsFrame:SetHeight(frameHeights.commandsFrame)
    comeCommandTitleFrame:SetHeight(frameHeights.comeCommandTitleFrame)
    comeCommandFrame:SetHeight(frameHeights.comeCommandFrame)
    moveCommandTitleFrame:SetHeight(frameHeights.moveCommandTitleFrame)
    moveCommandFrame:SetHeight(frameHeights.moveCommandFrame)
    stayCommandTitleFrame:SetHeight(frameHeights.stayCommandTitleFrame)
    stayCommandFrame:SetHeight(frameHeights.stayCommandFrame)
    partyBotCommandsFrame:SetHeight(frameHeights.partyBotCommandsFrame)
    markFrame:SetHeight(frameHeights.markFrame)
    markCommandFrame:SetHeight(frameHeights.markCommandFrame)

    
    local frameWidth = width - padding * 2
    addBotFrame:SetWidth(frameWidth)
    commandsFrame:SetWidth(frameWidth)
    comeCommandTitleFrame:SetWidth(frameWidth)
    comeCommandFrame:SetWidth(frameWidth)
    moveCommandTitleFrame:SetWidth(frameWidth)
    moveCommandFrame:SetWidth(frameWidth)
    stayCommandTitleFrame:SetWidth(frameWidth)
    stayCommandFrame:SetWidth(frameWidth)
    partyBotCommandsFrame:SetWidth(frameWidth)
    markFrame:SetWidth(frameWidth)
    markCommandFrame:SetWidth(frameWidth)

    
    local yOffset = -padding 

    
    addBotFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.addBotFrame - padding

    
    commandsFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.commandsFrame - padding

    
    partyBotCommandsFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.partyBotCommandsFrame - padding

    
    comeCommandTitleFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.comeCommandTitleFrame - padding

    
    comeCommandFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.comeCommandFrame - padding

    
    moveCommandTitleFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.moveCommandTitleFrame - padding

    
    moveCommandFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.moveCommandFrame - padding

    
    stayCommandTitleFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.stayCommandTitleFrame - padding

    
    stayCommandFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.stayCommandFrame - padding

    
    markFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)
    yOffset = yOffset - frameHeights.markFrame - padding

    
    markCommandFrame:SetPoint("TOP", frame, "TOP", 0, yOffset)

    
    local commandsHeight = ResizeCommandButtons(commands, commandsFrame, 3, 0, 0, false)
    local partyBotHeight = ResizeCommandButtons(partyBotCommands, partyBotCommandsFrame, 2, 0, 0, true)
    local hej = commandsHeight / 4

    
    ResizeRoleCommandButtons(roleCommandButtons, comeCommandFrame, hej)
    ResizeRoleCommandButtons(moveRoleCommandButtons, moveCommandFrame, hej)
    ResizeRoleCommandButtons(stayRoleCommandButtons, stayCommandFrame, hej)
    ResizeMarkCommandButtons(markCommandButtons, markCommandFrame)

    
    ResizeMarkButtons()
    ResizeAddBotButtons()
end)
	frame:GetScript("OnSizeChanged")(frame) 
    PCPFrameRemake = frame
end	





if not PCPButtonFrame then

    if string.find(version, "^1.14") then
		PCPButtonFrame = CreateFrame("Button", "PCPButtonFrame", Minimap, "BackdropTemplate")	
	else 
		PCPButtonFrame = CreateFrame("Button", "PCPButtonFrame", Minimap)

		PCPButtonFrame:SetWidth(100)
		PCPButtonFrame:SetHeight(100)

		PCPButtonFrame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})

		PCPButtonFrame:SetBackdropColor(0, 0, 0, 0.5)
		PCPButtonFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
		
	end
    

	PCPButtonFrame:SetWidth(32)
	PCPButtonFrame:SetHeight(32)

    PCPButtonFrame:SetPoint("TOP", Minimap, "TOP", 0, 0)  
    PCPButtonFrame:EnableMouse(true)
    PCPButtonFrame:SetMovable(true)
    PCPButtonFrame:SetUserPlaced(true)
    PCPButtonFrame:RegisterForDrag("RightButton")  
    PCPButtonFrame:SetFrameStrata("LOW")
    PCPButtonFrame:Show()

    
    PCPButtonFrame:SetNormalTexture("Interface\\AddOns\\PCP\\img\\Solocraft3")
    PCPButtonFrame:SetPushedTexture("Interface\\AddOns\\PCP\\img\\Solocraft3")
    PCPButtonFrame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")



    
    local function SaveButtonPosition()
        local point, relativeTo, relativePoint, xOffset, yOffset = PCPButtonFrame:GetPoint()
        PCPButtonFrame.position = {point, relativeTo, relativePoint, xOffset, yOffset}
    end

    local function RestoreButtonPosition()
        if PCPButtonFrame.position then
            local point, relativeTo, relativePoint, xOffset, yOffset = unpack(PCPButtonFrame.position)
            PCPButtonFrame:ClearAllPoints()
            PCPButtonFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
        end
    end

    


    if string.find(version, "^1.12") then
		
		PCPButtonFrame:SetScript("OnDragStart", function()
			this:StartMoving()
		end)

		PCPButtonFrame:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			SaveButtonPosition()
		end)

		
		PCPButtonFrame:SetScript("OnClick", function()
			PCPButtonFrame_Toggle() 
		end)

		
		PCPButtonFrame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText("PartyBot Control Panel \nPress Left Click to Open/Close \nHold Right Click to move the icon")
			GameTooltip:Show()
		end)

		PCPButtonFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

	else
		
		PCPButtonFrame:SetScript("OnDragStart", function(self)
			self:StartMoving()
		end)

		PCPButtonFrame:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			SaveButtonPosition()
		end)

		PCPButtonFrame:SetScript("OnClick", function(self)
			PCPButtonFrame_Toggle()  
		end)


		PCPButtonFrame:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("PartyBot Control Panel \nPress Left Click to Open/Close \nHold Right Click to move the icon")
			GameTooltip:Show()
		end)

		PCPButtonFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end


    
    RestoreButtonPosition()

end

PCPFrameRemake:Hide()


local PCPFrameRemakeShown = false


function PCPButtonFrame_Toggle()
    if PCPFrameRemakeShown then
        PCPFrameRemake:Hide()
    else
        PCPFrameRemake:Show()
    end
    PCPFrameRemakeShown = not PCPFrameRemakeShown  
end







BINDING_HEADER_CCP = "PartyBot Control Panel";
BINDING_NAME_CP = "Show/Hide PCP";


CMD_PARTYBOT_CLONE = ".partybot clone";
CMD_PARTYBOT_REMOVE = ".partybot remove";
CMD_PARTYBOT_ADD = ".partybot add ";
CMD_PARTYBOT_MAll = ".partybot moveall";
CMD_PARTYBOT_SAll = ".partybot stayall";
CMD_BATTLEGROUND_GO = ".go ";
CMD_BATTLEBOT_ADD = ".battlebot add ";
CMD_TOGGLE_HELM = ".partybot togglehelm ";
CMD_TOGGLE_CLOAK = ".partybot togglecloak ";
CMD_GENERAL = ".partybot ";

AddCmd = ""
CmdItr = 1
function CmdStackHide()
	CmdAll:Hide()
	CmdTank:Hide()
	CmdHealer:Hide()
	CmdDPS:Hide()
	CmdMDPS:Hide()
	CmdRDPS:Hide()
	CmdWarrior:Hide()
	CmdPaladin:Hide()
	CmdHunter:Hide()
	CmdRogue:Hide()
	CmdPriest:Hide()
	CmdShaman:Hide()
	CmdMage:Hide()
	CmdWarlock:Hide()
	CmdDruid:Hide()
end

function CmdADD()
	Cmds = { "", "tank", "healer", "dps", "mdps", "rdps", "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }

	CmdItr = CmdItr + 1	
	if CmdItr >= table.getn(Cmds) + 1 then CmdItr = 1 end
	AddCmd = Cmds[CmdItr]

	if Cmds[CmdItr] == "" then CmdStackHide() CmdAll:Show() end
	if Cmds[CmdItr] == "tank" then CmdStackHide() CmdroleButton:SetText("Tank") end
	if Cmds[CmdItr] == "healer" then CmdStackHide() CmdroleButton:SetText("Healer") end
	if Cmds[CmdItr] == "dps" then CmdStackHide() CmdDPS:Show() end
	if Cmds[CmdItr] == "mdps" then CmdStackHide() CmdMDPS:Show() end
	if Cmds[CmdItr] == "rdps" then CmdStackHide() CmdRDPS:Show() end
	if Cmds[CmdItr] == "warrior" then CmdStackHide() CmdroleButton:SetText("Warrior") end
	if Cmds[CmdItr] == "paladin" then CmdStackHide() CmdroleButton:SetText("Paladin") end
	if Cmds[CmdItr] == "hunter" then CmdStackHide() CmdroleButton:SetText("Hunter") end
	if Cmds[CmdItr] == "rogue" then CmdStackHide() CmdroleButton:SetText("Rogue") end
	if Cmds[CmdItr] == "priest" then CmdStackHide() CmdroleButton:SetText("Priest") end
	if Cmds[CmdItr] == "shaman" then CmdStackHide() CmdroleButton:SetText("Shaman") end
	if Cmds[CmdItr] == "mage" then CmdStackHide() CmdroleButton:SetText("Mage") end
	if Cmds[CmdItr] == "warlock" then CmdStackHide() CmdroleButton:SetText("Warlock") end
	if Cmds[CmdItr] == "druid" then CmdStackHide() CmdroleButton:SetText("Druid") end
end

function CmdSUB()
	Cmds = { "", "tank", "healer", "dps", "mdps", "rdps", "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }

	CmdItr = CmdItr - 1	
	if CmdItr <= 0 then CmdItr = table.getn(Cmds) end
	AddCmd = Cmds[CmdItr]

	if Cmds[CmdItr] == "" then CmdStackHide() CmdAll:Show() end
	if Cmds[CmdItr] == "tank" then CmdStackHide() CmdroleButton:SetText("Tank") end
	if Cmds[CmdItr] == "healer" then CmdStackHide() CmdroleButton:SetText("Healer") end
	if Cmds[CmdItr] == "dps" then CmdStackHide() CmdDPS:Show() end
	if Cmds[CmdItr] == "mdps" then CmdStackHide() CmdMDPS:Show() end
	if Cmds[CmdItr] == "rdps" then CmdStackHide() CmdRDPS:Show() end
	if Cmds[CmdItr] == "warrior" then CmdStackHide() CmdroleButton:SetText("Warrior") end
	if Cmds[CmdItr] == "paladin" then CmdStackHide() CmdroleButton:SetText("Paladin") end
	if Cmds[CmdItr] == "hunter" then CmdStackHide() CmdroleButton:SetText("Hunter") end
	if Cmds[CmdItr] == "rogue" then CmdStackHide() CmdroleButton:SetText("Rogue") end
	if Cmds[CmdItr] == "priest" then CmdStackHide() CmdroleButton:SetText("Priest") end
	if Cmds[CmdItr] == "shaman" then CmdStackHide() CmdroleButton:SetText("Shaman") end
	if Cmds[CmdItr] == "mage" then CmdStackHide() CmdroleButton:SetText("Mage") end
	if Cmds[CmdItr] == "warlock" then CmdStackHide() CmdroleButton:SetText("Warlock") end
	if Cmds[CmdItr] == "druid" then CmdStackHide() CmdroleButton:SetText("Druid") end
end

function GetChatChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    else
        return "SAY"  
    end
end

function SetCommand(arg)
    local chatChannel = GetChatChannel()

    if controlDeadBotsEnabled then
        SendChatMessage(CMD_GENERAL .. arg, chatChannel)
		
    else
        SendChatMessage(CMD_GENERAL .. arg, chatChannel)
        
    end
end

function SetPause()
    local chatChannel = GetChatChannel()

    if controlDeadBotsEnabled then
        SendChatMessage(CMD_GENERAL .. " pause ", chatChannel)
		
    else
        SendChatMessage(CMD_GENERAL .. " pause ", chatChannel)
        
    end
end


function SetUnpause()
    local chatChannel = GetChatChannel()

    if controlDeadBotsEnabled then
        SendChatMessage(CMD_GENERAL .. " unpause ", chatChannel)
        
    else
        SendChatMessage(CMD_GENERAL .. " unpause ", chatChannel)
        
    end
end

AddMark = "ccmark"
MarkItr = 1
function MarkStackHide()
	ccmark:Hide()
	focusmark:Hide()
end

function MarkADD()
    
    Marks = { "ccmark", "focusmark" }

    
	MarkItr = MarkItr + 1	
	if MarkItr >= table.getn(Marks) + 1 then MarkItr = 1 end
	AddMark = Marks[MarkItr]
    if Marks[MarkItr] == "ccmark" then
        markButton:SetText("CC Mark")
    elseif Marks[MarkItr] == "focusmark" then
        markButton:SetText("Focus Mark")
    end
end

function MarkSUB()
    
    Marks = { "ccmark", "focusmark" }

    
	MarkItr = MarkItr - 1	
	if MarkItr <= 0 then MarkItr = table.getn(Marks) end
	AddMark = Marks[MarkItr]
	
    
    if Marks[MarkItr] == "ccmark" then
        markButton:SetText("CC Mark")
    elseif Marks[MarkItr] == "focusmark" then
        markButton:SetText("Fokus Mark")
    end
end

function SetMark(arg)
	SendChatMessage(CMD_GENERAL .. AddMark .. " " .. arg);
end

function ShowMark()
	SendChatMessage(CMD_GENERAL .. AddMark);
end

function ClearMark()
	SendChatMessage(CMD_GENERAL .. "clear " .. AddMark);
end

function ClearAllMark()
	SendChatMessage(CMD_GENERAL .. "clear");
end

AddToggle = "aoe"
ToggleItr = 1
function ToggleStackHide()
	ToggleAOE:Hide()
	ToggleHelmCloak:Hide()
	helm:Hide()
	cloak:Hide()
end

function ToggleADD()
	Toggles = { "aoe", "ToggleHelmCloak", "helm", "cloak" }

	ToggleItr = ToggleItr + 1	
	if ToggleItr >= table.getn(Toggles) + 1 then ToggleItr = 1 end
	AddToggle = Toggles[ToggleItr]

	if Toggles[ToggleItr] == "aoe" then ToggleStackHide() ToggleAOE:Show() end
	if Toggles[ToggleItr] == "ToggleHelmCloak" then ToggleStackHide() ToggleHelmCloak:Show() end
	if Toggles[ToggleItr] == "helm" then ToggleStackHide() helm:Show() end
	if Toggles[ToggleItr] == "cloak" then ToggleStackHide() cloak:Show() end
end

function ToggleSUB()
	Toggles = { "aoe", "ToggleHelmCloak", "helm", "cloak" }

	ToggleItr = ToggleItr - 1	
	if ToggleItr <= 0 then ToggleItr = table.getn(Toggles) end
	AddToggle = Toggles[ToggleItr]

	if Toggles[ToggleItr] == "aoe" then ToggleStackHide() ToggleAOE:Show() end
	if Toggles[ToggleItr] == "ToggleHelmCloak" then ToggleStackHide() ToggleHelmCloak:Show() end
	if Toggles[ToggleItr] == "helm" then ToggleStackHide() helm:Show() end
	if Toggles[ToggleItr] == "cloak" then ToggleStackHide() cloak:Show() end
end

function SetToggle()
	SendChatMessage(CMD_GENERAL .."toggle " .. AddToggle);
end

function SubPartyBotClone(self)
	SendChatMessage(CMD_PARTYBOT_CLONE);
end

function SubPartyBotRemove(self)
	SendChatMessage(CMD_PARTYBOT_REMOVE);
end

function SubPartyBotMoveAll()
    local chatChannel = GetChatChannel()

    if controlDeadBotsEnabled then
        SendChatMessage(CMD_PARTYBOT_MAll, chatChannel)
        
    else
        SendChatMessage(CMD_PARTYBOT_MAll, chatChannel)
        
    end
end

function SubPartyBotStayAll()
    local chatChannel = GetChatChannel()

    if controlDeadBotsEnabled then
        SendChatMessage(CMD_PARTYBOT_SAll, chatChannel)
        
    else
        SendChatMessage(CMD_PARTYBOT_SAll, chatChannel)
        
    end
end



AddClass = "warrior"
ClassItr = 1
function SetClassADD()
	Classes = { "warrior" , "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }
		
	ClassItr = ClassItr + 1	
	if ClassItr == 10 then ClassItr = 1 end
	
	if UnitFactionGroup("player") == "Alliance" then
		if Classes[ClassItr] == "shaman" then 
			ClassItr = ClassItr + 1 
			AddClass = Classes[ClassItr]
		end
	else AddClass = Classes[ClassItr]
	end
	
	if UnitFactionGroup("player") == "Horde" then
		if Classes[ClassItr] == "paladin" then 
			ClassItr = ClassItr + 1 
			AddClass = Classes[ClassItr]
		end
	else AddClass = Classes[ClassItr]
	end	
	
	if Classes[ClassItr] == "warrior" then classButton:SetText("Warrior") end
	if UnitFactionGroup("player") == "Alliance" then 
		if Classes[ClassItr] == "paladin" then classButton:SetText("Paladin") end
		if Classes[ClassItr] == "hunter" then classButton:SetText("Hunter") end	
	else
		if Classes[ClassItr] == "hunter" then classButton:SetText("Hunter") end
	end	
	if Classes[ClassItr] == "rogue" then classButton:SetText("Rogue") end
	if Classes[ClassItr] == "priest" then classButton:SetText("Priest") end
	if UnitFactionGroup("player") == "Horde" then 
		if Classes[ClassItr] == "shaman" then classButton:SetText("Shaman")end
		if Classes[ClassItr] == "mage" then classButton:SetText("Mage") end	
	else
		if Classes[ClassItr] == "mage" then classButton:SetText("Mage") end
	end	
	if Classes[ClassItr] == "warlock" then classButton:SetText("Warlock") end
	if Classes[ClassItr] == "druid" then classButton:SetText("Druid") end
	
	RoleUpdate()
	RoleItr = 1
end

function SetClassSUB()
    Classes = { "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }
    
    ClassItr = ClassItr - 1
    if ClassItr == 0 then ClassItr = 9 end
    
    if UnitFactionGroup("player") == "Alliance" then
        if Classes[ClassItr] == "shaman" then 
            ClassItr = ClassItr - 1
            if ClassItr == 0 then ClassItr = 9 end
            AddClass = Classes[ClassItr]
        end
    else 
        AddClass = Classes[ClassItr]
    end
    
    if UnitFactionGroup("player") == "Horde" then
        if Classes[ClassItr] == "paladin" then 
            ClassItr = ClassItr - 1
            if ClassItr == 0 then ClassItr = 9 end
            AddClass = Classes[ClassItr]
        end
    else 
        AddClass = Classes[ClassItr]
    end
    
    if Classes[ClassItr] == "warrior" then classButton:SetText("Warrior") end
    if UnitFactionGroup("player") == "Alliance" then
        if Classes[ClassItr] == "paladin" then classButton:SetText("Paladin") end
        if Classes[ClassItr] == "hunter" then classButton:SetText("Hunter") end
    else
        if Classes[ClassItr] == "hunter" then classButton:SetText("Hunter") end
    end
    if Classes[ClassItr] == "rogue" then classButton:SetText("Rogue") end
    if Classes[ClassItr] == "priest" then classButton:SetText("Priest") end
    if UnitFactionGroup("player") == "Horde" then
        if Classes[ClassItr] == "shaman" then classButton:SetText("Shaman") end
        if Classes[ClassItr] == "mage" then classButton:SetText("Mage") end
    else
        if Classes[ClassItr] == "mage" then classButton:SetText("Mage") end
    end
    if Classes[ClassItr] == "warlock" then classButton:SetText("Warlock") end
    if Classes[ClassItr] == "druid" then classButton:SetText("Druid") end
    
    RoleUpdate()
    RoleItr = 1
end


function RaceUpdate()
	if Classes[ClassItr] == "warrior" then 
		if UnitFactionGroup("player") == "Alliance" then 
			RaceStackHide()
			human:Show()
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end
	end

	if Classes[ClassItr] == "paladin" then 
		RaceStackHide()
		human:Show()		
		AddRace = "human" 
	end

	if Classes[ClassItr] == "hunter" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			dwarf:Show()			
			AddRace = "dwarf" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()		
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end	
	end
	if Classes[ClassItr] == "rogue" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()		
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		
	end
	if Classes[ClassItr] == "priest" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			undead:Show()		
			AddRace = "undead"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		
	end
	if Classes[ClassItr] == "shaman" then 
		RaceStackHide()
		orc:Show()		
		AddRace = "orc"
	end
	if Classes[ClassItr] == "mage" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			undead:Show()		
			AddRace = "undead"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		 
	end
	if Classes[ClassItr] == "warlock" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()		
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		
	end
	if Classes[ClassItr] == "druid" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			nightelf:Show()			
			AddRace = "nightelf" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			tauren:Show()		
			AddRace = "tauren"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end	
	end
end



function RaceStackHide()
	race:Hide()
	human:Hide()
	dwarf:Hide()
	nightelf:Hide()
	gnome:Hide()
	orc:Hide()
	undead:Hide()
	tauren:Hide()
	troll:Hide()	
end

AddRace = "race"
RaceItr = 0
function SetRaceADD()
	if AddClass == "warrior" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "tauren", "troll", "race" }		
		end		
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end		
		
	elseif AddClass == "paladin" then		
		Races = { "human", "dwarf", "race" }
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		
	elseif AddClass == "hunter" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "dwarf", "nightelf", "race" }			
		else 			
			Races = { "orc", "tauren", "troll", "race" }		
		end		
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "rogue" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "troll", "race" }		
		end
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]	

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "priest" then
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "shaman" then			
		Races = { "orc", "tauren", "troll", "race" }
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "mage" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end

		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end	

	elseif AddClass == "warlock" then			
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "race" }		
		end
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]		

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end		

	elseif AddClass == "druid" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "nightelf" }			
		else 			
			Races = { "tauren" }		
		end

		AddRace = Races[RaceItr]		
	
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
	end
end

function SetRaceSUB()
	if RaceItr == 0 then RaceItr = 5 end

	if AddClass == "warrior" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "tauren", "troll", "race" }		
		end
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end	

	elseif AddClass == "paladin" then		
		Races = { "human", "dwarf", "race" }
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end

	elseif AddClass == "hunter" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "dwarf", "nightelf", "race" }			
		else 			
			Races = { "orc", "tauren", "troll", "race" }		
		end		
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "rogue" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "troll", "race" }		
		end
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]	

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "priest" then
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "shaman" then		
		Races = { "orc", "tauren", "troll", "race" }
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "mage" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end

		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end	

	elseif AddClass == "warlock" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "race" }		
		end
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]		

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end		

	elseif AddClass == "druid" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "nightelf" }			
		else 			
			Races = { "tauren" }		
		end

		AddRace = Races[RaceItr]		
	
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end			
	end
end





AddRole = "tank"
RoleItr = 1
function SetRoleADD()
	if AddClass == "warrior" then
		Roles = { "tank", "meleedps" }
		
		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
		if Roles[RoleItr] == "meleedps" then roleButton:SetText("Melee") end

	elseif AddClass == "paladin" then
		Roles = { "tank", "healer", "meleedps" }
		
		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
		if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
		if Roles[RoleItr] == "meleedps" then roleButton:SetText("Meleedps") end		
	
	elseif AddClass == "hunter" then		
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end

	elseif AddClass == "rogue" then
		Roles = { "meleedps" }

		AddRole = "meleedps" 

		if Roles[RoleItr] == "meleedps" then roleButton:SetText("Meleedps") end
		
	elseif AddClass == "priest" then
		Roles = { "healer", "rangedps" }

		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
		if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end

	elseif AddClass == "shaman" then
		Roles = { "tank", "healer", "meleedps", "rangedps" }

		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
		if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
		if Roles[RoleItr] == "meleedps" then roleButton:SetText("Meleedps") end
		if Roles[RoleItr] == "rangedps" then roleButton:SetText("Rangedps") end
		
	elseif AddClass == "mage" then	
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end	
		
	elseif AddClass == "warlock" then
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end
	
	elseif AddClass == "druid" then	
		Roles = { "tank", "healer", "meleedps", "rangedps" }
		
		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]
	
		if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
		if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
		if Roles[RoleItr] == "meleedps" then roleButton:SetText("MeleeDps") end		
		if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end
	end
end
function RoleUpdate()
	if Classes[ClassItr] == "warrior" then 
		
		roleButton:SetText("Tank")
		AddRole = "tank"
	end
	if Classes[ClassItr] == "paladin" then 
		
		roleButton:SetText("Tank")
		AddRole = "tank"
	end
	if Classes[ClassItr] == "hunter" then 
		
		roleButton:SetText("Rangedps")
		AddRole = "rangedps"
	end
	if Classes[ClassItr] == "rogue" then 
		
		roleButton:SetText("Meleedps")
		AddRole = "meleedps"
	end
	if Classes[ClassItr] == "priest" then 
		
		roleButton:SetText("Healer")
		AddRole = "healer"
	end
	if Classes[ClassItr] == "shaman" then 
		
		roleButton:SetText("Tank")
		AddRole = "tank"
	end
	if Classes[ClassItr] == "mage" then 
		
		roleButton:SetText("RangeDps")
		AddRole = "rangedps" 
	end
	if Classes[ClassItr] == "warlock" then 
		
		roleButton:SetText("RangeDps")
		AddRole = "rangedps"	
	end
	if Classes[ClassItr] == "druid" then 
		
		roleButton:SetText("Tank")
		AddRole = "tank"
	end	
end
function SetRoleSUB()
    if AddClass == "warrior" then
        Roles = { "tank", "meleedps" }

        RoleItr = RoleItr - 1
        if RoleItr <= 0 then RoleItr = table.getn(Roles) end
        AddRole = Roles[RoleItr]

        if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
        if Roles[RoleItr] == "meleedps" then roleButton:SetText("MeleeDps") end

    elseif AddClass == "paladin" then
        Roles = { "tank", "healer", "meleedps" }

        RoleItr = RoleItr - 1
        if RoleItr <= 0 then RoleItr = table.getn(Roles) end
        AddRole = Roles[RoleItr]

        if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
        if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
        if Roles[RoleItr] == "meleedps" then roleButton:SetText("MeleeDps") end

    elseif AddClass == "hunter" then
        Roles = { "rangedps" }

        AddRole = "rangedps"

        if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end

    elseif AddClass == "rogue" then
        Roles = { "meleedps" }

        AddRole = "meleedps"

        if Roles[RoleItr] == "meleedps" then roleButton:SetText("MeleeDps") end

    elseif AddClass == "priest" then
        Roles = { "healer", "rangedps" }

        RoleItr = RoleItr - 1
        if RoleItr <= 0 then RoleItr = table.getn(Roles) end
        AddRole = Roles[RoleItr]

        if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
        if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end

    elseif AddClass == "shaman" then
        Roles = { "tank", "healer", "meleedps", "rangedps" }

        RoleItr = RoleItr - 1
        if RoleItr <= 0 then RoleItr = table.getn(Roles) end
        AddRole = Roles[RoleItr]

        if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
        if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
        if Roles[RoleItr] == "meleedps" then roleButton:SetText("MeleeDps") end
        if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end

    elseif AddClass == "mage" then
        Roles = { "rangedps" }

        AddRole = "rangedps"

        if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end

    elseif AddClass == "warlock" then
        Roles = { "rangedps" }

        AddRole = "rangedps"

        if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end

    elseif AddClass == "druid" then
        Roles = { "tank", "healer", "meleedps", "rangedps" }

        RoleItr = RoleItr - 1
        if RoleItr <= 0 then RoleItr = table.getn(Roles) end
        AddRole = Roles[RoleItr]

        if Roles[RoleItr] == "tank" then roleButton:SetText("Tank") end
        if Roles[RoleItr] == "healer" then roleButton:SetText("Healer") end
        if Roles[RoleItr] == "meleedps" then roleButton:SetText("MeleeDps") end
        if Roles[RoleItr] == "rangedps" then roleButton:SetText("RangeDps") end
    end
end

function GenderStackHide()
	gender:Hide()
	male:Hide()
	female:Hide()
end

AddGender = "gender"
GenderItr = 1
function SetGenderADD()
		Genders = { "gender", "male", "female" }
		
		GenderItr = GenderItr + 1	
		if GenderItr >= table.getn(Genders) + 1 then GenderItr = 1 end
		AddGender = Genders[GenderItr]

		if Genders[GenderItr] == "gender" then GenderStackHide() gender:Show() end
		if Genders[GenderItr] == "male" then GenderStackHide() male:Show() end
		if Genders[GenderItr] == "female" then GenderStackHide() female:Show() end
end

function SetGenderSUB()
		Genders = { "gender", "male", "female" }

		GenderItr = GenderItr - 1	
		if GenderItr <= 0 then GenderItr = table.getn(Genders) end
		AddGender = Genders[GenderItr]

		if Genders[GenderItr] == "gender" then GenderStackHide() gender:Show() end
		if Genders[GenderItr] == "male" then GenderStackHide() male:Show() end
		if Genders[GenderItr] == "female" then GenderStackHide() female:Show() end
end

AddBG = "warsong"
BGItr = 1
function BGStackHide()
	warsong:Hide()
	arathi:Hide()
	alterac:Hide()
end

function SetBGADD()
	BGS = { "warsong", "arathi", "alterac" }
	
	BGItr = BGItr + 1	
	if BGItr == 4 then BGItr = 1 end
	AddBG = BGS[BGItr]
	
	if BGS[BGItr] == "warsong" then BGStackHide() warsong:Show() end
	if BGS[BGItr] == "arathi" then BGStackHide() arathi:Show() end
	if BGS[BGItr] == "alterac" then BGStackHide() alterac:Show() end
end

function SetBGSUB()
	BGS = { "warsong", "arathi", "alterac" }
	
	BGItr = BGItr - 1	
	if BGItr == 0 then BGItr = 3 end
	AddBG = BGS[BGItr]
	
	if BGS[BGItr] == "warsong" then BGStackHide() warsong:Show() end
	if BGS[BGItr] == "arathi" then BGStackHide() arathi:Show() end
	if BGS[BGItr] == "alterac" then BGStackHide() alterac:Show() end
end

function SubPartyBotAddAdvanced(self)
	SendChatMessage(CMD_PARTYBOT_ADD .. AddClass .. " " .. AddRole .. " " .. AddGender);
end

function SubPartyBotAdd(self, arg)
	SendChatMessage(CMD_PARTYBOT_ADD .. arg);
end

function Brackets()
	if UnitLevel("player") >= 10 and UnitLevel("player") <= 19 then return math.random(10,19) 
	elseif UnitLevel("player") >= 20 and UnitLevel("player") <= 29 then return math.random(20,29)
	elseif UnitLevel("player") >= 30 and UnitLevel("player") <= 39 then return math.random(30,39)
	elseif UnitLevel("player") >= 40 and UnitLevel("player") <= 49 then return math.random(40,49)
	elseif UnitLevel("player") >= 50 and UnitLevel("player") <= 59 then return math.random(50,59)
	elseif UnitLevel("player") == 60 then return 60
	else return math.random(10,19)
	end
end

function SubBattleBotAdd(self, arg1, arg2)
	RanBotLevel = Brackets()
	SendChatMessage(CMD_BATTLEBOT_ADD .. arg1 .. " " .. arg2 .. " " .. RanBotLevel);
end

function SubBattleGo(self, arg1)
	SendChatMessage(CMD_BATTLEGROUND_GO .. arg1);
end

function CloseFrame()
	PCPFrameRemake:Hide();
end

function OpenFrame()
	DEFAULT_CHAT_FRAME:AddMessage("Loading PartyBot Control Panel...");
	DEFAULT_CHAT_FRAME:RegisterEvent('CHAT_MSG_SYSTEM')
	PCPFrameRemake:Show();
end


SLASH_PCP1 = '/PCP'
function SlashCmdList.PCP(msg, editbox) 
    if (msg == "" or msg == "cp") then
        if (PCPFrameRemake:IsVisible()) then
            PCPFrameRemake:Hide()
        else
			PCPFrameRemake:Show()
        end
    end
end

function ShowToggle()
	if (PCPFrameRemake:IsVisible()) then
		PCPFrameRemake:Hide()
	else
		PCPFrameRemake:Show()
	end
end

function JoinWorld()
	id, name = GetChannelName(1)
	if (name ~= "World") then
		JoinChannelByName("World", nil, ChatFrame1:GetID(), 0)
	end
end