--==================================================
-- FillRaidBots - Dynamic Settings System 
-- With Headers + Separators
--==================================================

local settingsLoaded = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "FillRaidBots" then
            FillRaidBots_LoadSettings()
        end
    elseif event == "PLAYER_LOGOUT" then
        FillRaidBots_SaveSettings()
    end
end)


--==================================================
-- SETTINGS CONFIG 
--==================================================
function SetLootOption(isFFA, isGroup, isMaster)

    if isFFA then
        SetLootMethod("freeforall")
    elseif isGroup then
        SetLootMethod("group")
    elseif isMaster then
        SetLootMethod("master", UnitName("player"))
    end
end

local ADDON_PATH = "Interface\\AddOns\\FillRaidBots\\"
local IMG_PATH = ADDON_PATH.."img\\"
local HIGHLIGHT = "Interface\\Buttons\\UI-Common-MouseHilight"
local function CreateThemeButtons(folder, width, height)

    local path = IMG_PATH..folder.."\\"

    return {

        openFillRaidButton = {
            width = width,
            height = height,
            normal = path.."fillraid",
            highlight = HIGHLIGHT,
            pushed = path.."fillraid"
        },

        kickAllButton = {
            width = width,
            height = height,
            normal = path.."kickall",
            highlight = HIGHLIGHT,
            pushed = path.."kickall"
        },

        reFillButton = {
            width = width,
            height = height,
            normal = path.."refill",
            highlight = HIGHLIGHT,
            pushed = path.."refill"
        }

    }

end

SettingsConfig = {

    sections = {

        --------------------------------------------------
        -- GENERAL
        --------------------------------------------------
        {
            name = "General",
            items = {

                {
                    type = "checkbox",
                    key = "isCheckAndRemoveEnabled",
                    toggle = "removeDeadBotsEnabled",
                    label = "Auto Remove Dead Bots",
                    tooltip = "Automatically removes dead bots.\nWhen this is enabled, the manual Remove Dead Bots button stays hidden.",
                    default = true,
                    onApply = function()
                        if UpdateRemoveDeadBotsButtonVisibility then
                            UpdateRemoveDeadBotsButtonVisibility()
                        end
                    end
                },



                {
                    type = "checkbox",
                    key = "isBotMessagesEnabled",
                    toggle = "BotMessagesEnabled",
                    label = "Suppress Messages",
                    tooltip = "Suppress bot messages.",
                    default = true
                },

                {
                    type = "button",
                    label = "Suppress",
                    tooltip = "Add/Edit Messages to be Suppressed",
                    width = 80,
                    onClick = function()
                        if SuppressEditor:IsShown() then
                            SuppressEditor:Hide()
                        else
                            RefreshSuppressList()
                            SuppressEditor:Show()
                            SuppressEditor:SetFrameLevel(200)
                        end
                    end
                },

                {
                    type = "checkbox",
                    key = "isDailyTipEnabled",
                    toggle = "DailyTipEnabled",
                    label = "Daily Tip",
                    tooltip = "Shows a daily tip.",
                    default = true,
                    onApply = function(value) ToggleDailyTip(value) end
                },
				{
					type = "checkbox",
					key = "showTutorialLinks",
					label = "Tutorial Links",
					tooltip = "Shows a small tutorial link button beside default presets when a link exists.",
					default = true,
					onApply = function(value)
						if ToggleTutorialLinks then
							ToggleTutorialLinks(value)
						end

						if UpdateTutorialLinkButtons then
							UpdateTutorialLinkButtons()
						end
					end
				},				
            }
        },

        --------------------------------------------------
        -- AUTOMATION
        --------------------------------------------------
        {
            name = "Automation",
            items = {

                {
                    type = "checkbox",
                    key = "isClickToFillEnabled",
                    toggle = "ClickToFillEnabled",
                    label = "Click-To-Fill",
                    tooltip = "Hold ctrl+alt+click boss to fill raid.",
                    default = true,
                    onApply = function(value) ToggleClickToFill(value) end
                },

                {
                    type = "checkbox",
                    key = "isZonePresetsEnabled",
                    toggle = "ZonePresetsEnabled",
                    label = "Zone Presets",
                    tooltip = "Checks what zone you are in and opens the correct preset list.",
                    default = true,
                    onApply = function(value) ToggleZonePresets(value) end
                },

                {
                    type = "checkbox",
                    key = "isAutoRepairEnabled",
                    toggle = "AutoRepairEnabled",
                    label = "Auto Repair",
                    tooltip = "Automatically repair after resurrection.",
                    default = false,
                    onApply = function(value) ToggleAutoRepair(value) end
                },

                {
                    type = "checkbox",
                    key = "useVipPresets",
                    label = "Use VIP Presets",
                    tooltip = "Uses vip preset values when available. Falls back to normal preset values if no VIP version exists.",
                    default = false,
                    onApply = function(value)
                        QueueDebugMessage("VIP presets " .. (value and "enabled" or "disabled"), "debuginfo")
                        if ReapplyCurrentPreset then
                            ReapplyCurrentPreset()
                        end
                    end
                },

                {
                    type = "checkbox",
                    key = "isAutoJoinGuildEnabled",
                    toggle = "AutoJoinGuildEnabled",
                    label = "Auto Join Guild",
                    tooltip = "Automatically join the guild.",
                    default = true,
                    onApply = function(value) ToggleAutoJoinGuild(value) end
                },

                {
                    type = "checkbox",
                    key = "isAutoMuteSoundEnabled",
                    toggle = "AutoMuteSoundEnabled",
                    label = "Auto Mute Sound",
                    tooltip = "Automatically lower sound while filling raid.",
                    default = true,
                    onApply = function(value) ToggleAutoMuteSound(value) end
                },


            }
        },

        --------------------------------------------------
        -- ADVANCED
        --------------------------------------------------
        {
            name = "Advanced",
            items = {

                {
                    type = "checkbox",
                    key = "debugMessagesEnabled",
                    toggle = "debugMessagesEnabled",
                    label = "Enable Debug Messages",
                    tooltip = "Shows debug messages in chat for development.",
                    default = false,
                    onApply = function(value)
                        if value then
                            debuggerFrame:Show()
                        else
                            debuggerFrame:Hide()
                        end
                    end
                },

                {
                    type = "button",
                    label = "Factory Reset",
                    tooltip = "Shows a warning popup and wipes all FillRaidBots saved data except UserID, UserCount, and UniqueUsers.",
                    onClick = function()
                        if ShowFactoryResetPopup then
                            ShowFactoryResetPopup()
                        end
                    end
                },
            }
        },

        --------------------------------------------------
        -- BUTTONS
        --------------------------------------------------
        {
            name = "Buttons",
            items = {

                {
                    type = "checkbox",
                    key = "OthersButtonsEnabled",
                    toggle = "OthersButtonEnabled",
                    label = "Enable Others button",
                    tooltip = "Enables Others button on all instance frames.",
                    default = false,
                    onApply = function(value) ToggleOthersButton(value) end
                },

                
                
                {
                    type = "checkbox",
                    key = "isRefillEnabled",
                    toggle = "RefillEnabled",
                    label = "Enable Refill Button",
                    tooltip = "The Refill Button will be available.",
                    default = true,
                    onApply = function()
                        UpdateReFillButtonVisibility()
                    end
                },

                {
                    type = "checkbox",
                    key = "isremoveDeadBotsButtonEnabled",
                    toggle = "removeDeadBotsButtonEnabled",
                    label = "Enable Remove Dead Bots Button",
                    tooltip = "Shows a manual button when dead bots are found.\nOnly appears when Auto Remove Dead Bots is disabled.",
                    default = true,
                    onApply = function()
                        if UpdateRemoveDeadBotsButtonVisibility then
                            UpdateRemoveDeadBotsButtonVisibility()
                        end
                    end
                },                
                
                
                
                {
                    type = "radio",
                    group = "buttonMoveMode",
                    layout = "vertical",
                    options = {
                        {
                            key = "buttonMoveModeFixed",
                            label = "Fixed Buttons",
                            tooltip = "Buttons are locked to the PCP window position.",
                            default = true,
                        },
                        {
                            key = "buttonModeMoveFree",
                            label = "Move Buttons (Free)",
                            tooltip = "Drag buttons freely. Position saved in absolute screen coords.",
                            default = false,
                            showLockButton = true,  
                        },
                        {
                            key = "buttonMoveModeRelative",
                            label = "Move Buttons (Relative)",
                            tooltip = "Drag buttons freely. Position saved relative to the PCP window.",
                            default = false,
                        },
                    },
                    onApply = function(selectedKey)
                        
                        
                        FillRaidBotsSavedSettings.moveButtonsEnabled = (selectedKey == "buttonModeMoveFree")
                        FillRaidBotsSavedSettings.moveButtonsRelative = (selectedKey == "buttonMoveModeRelative")
                        
                        
                        
                        if selectedKey ~= "buttonModeMoveFree" then
                            FillRaidBotsSavedSettings.buttonMoveLocked = false
                        end
                        ToggleButtonMovement()
                    end
                },

				
				{
					type = "checkbox",
					label = "Horizontal layout",
					key = "ButtonLayout",
					tooltip = "Enables the buttons to be aligned Horizontaly.",

					get = function()
						return FillRaidBotsSavedSettings.ButtonLayout == "horizontal"
					end,

					set = function(value)
						if value then
							ApplyButtonLayout("horizontal")
						else
							ApplyButtonLayout("vertical")
						end
					end
				},

				
				{
					type = "slider",
					key = "ButtonSpacing",
					label = "Button Spacing",
					tooltip = "Adjust spacing between the FillRaid buttons.\nNegative values move buttons closer together.", 
					min = -50, 
					max = 50,
					step = 1,
					precision = 0,
					default = 4,

					onPreview = function()
						RepositionButtonsFromOffset()
					end,

					onApply = function(value)
						RepositionButtonsFromOffset()
					end
				},
				{
					type = "slider",
					key = "ButtonSize",
					label = "Button Size",
					tooltip = "Adjust the size of the FillRaid buttons.", 
					
					min = 10,
					max = 500,
					step = 1,
					precision = 0,
					default = 100, 

					onPreview = function(value)
						if not FillRaidBotsSavedSettings then return end
						FillRaidBotsSavedSettings.ButtonSize = value
						UpdateButtonSizes()
					end,

					onApply = function(value)
						if not FillRaidBotsSavedSettings then return end
						FillRaidBotsSavedSettings.ButtonSize = value
						UpdateButtonSizes()
					end
				},
                {
                    type = "button",
                    label = "Button Themes",
                    tooltip = "Button Themes",
                    width = 80,
                    createFrame = true,
                    frameWidth = 270,
                    frameTitle = "Button Themes"
                },

                {
                    type = "button",
                    label = "Reset Buttons",
                    tooltip = "Reset button positions to default.",
                    onClick = function()
                        FillRaidBots_ResetButtonPositions()
                    end
                },
			
            }
        },

        --------------------------------------------------
        -- LOOT TYPE
        --------------------------------------------------
        {
            name = "Loot Type",
            items = {

				{
					type = "checkbox",
					key = "isLootTypeEnabled",
					toggle = "LootType",
					label = "Loot type",
					tooltip = "Enables auto change loot type.",
					default = true,
					onApply = function(value) ToggleLootType(value) end
				},


                {
                    type = "radio",
                    group = "lootType",
                    textposition = "over",

                    options = {
                        { key = "isFFAEnabled", label = "FFA", default = false, tooltip = "Automatically set to \nFree For All loot" },
                        { key = "isGroupLootEnabled", label = "Group", default = true, tooltip = "Automatically set to \nGroup loot" },
                        { key = "isMasterLootEnabled", label = "Master", default = false, tooltip = "Automatically set to \nMaster loot" },
                    },

                    onApply = function(selectedKey)
                        SetLootOption(
                            selectedKey == "isFFAEnabled",
                            selectedKey == "isGroupLootEnabled",
                            selectedKey == "isMasterLootEnabled"
                        )
                    end
                },

                
				{
					type = "radio",
					group = "buttonTheme",
					framename = "FillRaidBots_ButtonThemes_Frame",
					layout = "vertical",
				
					options = {
						
						{
							key = "Mini",
							label = "Mini",
							tooltip = "Small compact buttons",
							default = true,
							buttons = CreateThemeButtons("Mini", 32, 32)
						},
						{
							key = "Classic",
							label = "Classic",
							tooltip = "Vertical tall buttons",
							default = false,
							buttons = CreateThemeButtons("Classic", 40, 100)
						},
						{
							key = "AI",
							label = "AI",
							tooltip = "AI Generated Buttons",
							default = false,
							buttons = CreateThemeButtons("AI", 40, 100)
						},
						{
							key = "AISmall",
							label = "AISmall",
							tooltip = "Small AI buttons",
							default = false,
							buttons = CreateThemeButtons("AISmall", 32, 32)
						},
						{
							key = "AIHorizontal",
							label = "AIHorizontal",
							tooltip = "Horizontal AI buttons",
							offsetX = 0,  











							offsetY = 0,    
							default = false,
							buttons = CreateThemeButtons("AIHorizontal", 100, 40)
						},
						{
							key = "Nymz",
							label = "Nymz",
							tooltip = "Nymz theme",
							default = false,
							spacing = -30,
							buttons = CreateThemeButtons("Nymz", 40, 100)
						},
						{
							key = "Nymzmini",
							label = "Nymz Mini",
							tooltip = "Nymz small buttons",
							default = false,
							buttons = CreateThemeButtons("Nymzmini", 32, 32)
						},
						{
							key = "Gemma",
							label = "Gemma",
							tooltip = "Gemma theme",
							default = false,
							buttons = CreateThemeButtons("Gemma", 40, 100)
						}						
					},

					onApply = function(selectedKey, item)

						
						
						FillRaidBotsSavedSettings.selectedButtonTheme = selectedKey

						local currentPct = FillRaidBotsSavedSettings.ButtonSize or 100
						for _, section in ipairs(SettingsConfig.sections) do
							for _, it in ipairs(section.items) do
								if it.type == "slider" and it.key == "ButtonSize" then
									if it.frame then
										it.frame:SetValue(currentPct + 0.001)
										it.frame:SetValue(currentPct)
									end
								end
							end
						end

						UpdateButtonSizes()
						RepositionButtonsFromOffset()
					end
				}				
            }
        },
    }
}

--==================================================
-- SECTION HEADER + SEPARATOR
--==================================================

local function CreateUISectionHeader(parentFrame, anchorTo, label, offsetX, offsetY)

    local header = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX or 10, offsetY or -20)
    header:SetText(label)

    local separator = parentFrame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(2)
    separator:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    separator:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -10, 0)
    separator:SetTexture("Interface\\Buttons\\WHITE8x8")
    separator:SetVertexColor(1, 1, 1, 0.8)

    return header, separator
end

--==================================================
-- DEFAULT INITIALIZATION
--==================================================

local function InitializeDefaults()

    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    for _, section in ipairs(SettingsConfig.sections) do
        for _, item in ipairs(section.items) do

            if item.type == "checkbox" then

                if FillRaidBotsSavedSettings[item.key] == nil then
                    FillRaidBotsSavedSettings[item.key] = item.default
                end

            elseif item.type == "radio" then

                for _, option in ipairs(item.options) do
                    if FillRaidBotsSavedSettings[option.key] == nil then
                        FillRaidBotsSavedSettings[option.key] = option.default
                    end
                end
            elseif item.type == "slider" then

                if FillRaidBotsSavedSettings[item.key] == nil then
                    FillRaidBotsSavedSettings[item.key] = item.default or item.min or 0
                end

           
            end
        end
    end

    
    if FillRaidBotsSavedSettings.buttonMoveLocked == nil then
        FillRaidBotsSavedSettings.buttonMoveLocked = false
    end
end

--==================================================
-- CHECKBUTTON CREATOR 
--==================================================
local function ShowSettingsTooltip(owner, tooltip)
    local startPos, lineStart, lineEnd, lineText, firstLine

    if not tooltip or tooltip == "" then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    startPos = 1
    firstLine = true

    while true do
        lineStart, lineEnd = string.find(tooltip, "\n", startPos, true)
        if lineStart then
            lineText = string.sub(tooltip, startPos, lineStart - 1)
        else
            lineText = string.sub(tooltip, startPos)
        end

        if firstLine then
            GameTooltip:SetText(lineText, 1, 1, 1, 1, true)
            firstLine = false
        else
            if lineText == "" then
                GameTooltip:AddLine(" ")
            else
                GameTooltip:AddLine(lineText, 0.8, 0.8, 0.8, true)
            end
        end

        if not lineStart then
            break
        end
        startPos = lineEnd + 1
    end

    GameTooltip:Show()
end

local function CreateCheckButton(parent, name, anchor, x, y, label, tooltip, value, onClick, framename)

    
    local parentForItem = parent
    if framename then
        local globalFrame = getglobal(framename)
        if globalFrame then
            parentForItem = globalFrame
        end
    end

    local cb = CreateFrame("CheckButton", name, parentForItem, "UICheckButtonTemplate")
    cb:SetWidth(20)
    cb:SetHeight(20)
    cb:SetPoint("TOPLEFT", parentForItem, "TOPLEFT", x, y)

    
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	cb.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	cb.text:SetPoint("TOPLEFT", cb, "TOPRIGHT", 5, -2)
	cb.text:SetWidth(120) -- adjust to your column width
	cb.text:SetJustifyH("LEFT")
    cb.text:SetText(label)

    
    cb:SetChecked(value and true or false)

    
    cb:SetScript("OnClick", function()
        local checked = cb:GetChecked() and true or false

        if name and FillRaidBotsSavedSettings then
            FillRaidBotsSavedSettings[name] = checked
        end

        if onClick then
            onClick(checked)
        end

        local status = checked and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
        DEFAULT_CHAT_FRAME:AddMessage((label or name) .. ": " .. status)
    end)

    
    cb:SetScript("OnEnter", function()
        if tooltip and tooltip ~= "" then
            ShowSettingsTooltip(cb, tooltip)
        end
    end)

    cb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return cb
end
--==================================================
-- UI CREATION
--==================================================
local function GenerateSafeFrameName(label)

    if not label then
        return nil
    end

    
    local clean = string.gsub(label, "[^%w]", "")

    
    return "FillRaidBots_" .. clean .. "_Frame"
end

function CreateSettingsUI()

    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    --------------------------------------------------
    -- LAYOUT BASE SETTINGS
    --------------------------------------------------
    local columnWidth = 170
    local columnSpacing = 8 
    local startX = 20
    local startY = -20
    local sectionSpacing = 8
    local maxColumns = 2

    --------------------------------------------------
    -- ESTIMATE TOTAL HEIGHT (for auto-balance)
    --------------------------------------------------
    local totalHeight = 0

    for _, section in ipairs(SettingsConfig.sections) do
        local estimatedHeight = 40

        for _, item in ipairs(section.items) do
            if item.type == "checkbox" then
                estimatedHeight = estimatedHeight + 25
            elseif item.type == "radio" then
                estimatedHeight = estimatedHeight + 50
            elseif item.type == "button" then
                estimatedHeight = estimatedHeight + 30
			elseif item.type == "slider" then
				estimatedHeight = estimatedHeight + 40				
            end
        end

        totalHeight = totalHeight + estimatedHeight + sectionSpacing
    end

    
    
    local maxColumnHeight = math.ceil(totalHeight / maxColumns) + 15

    --------------------------------------------------
    -- COLUMN STATE
    --------------------------------------------------
    local currentColumnX = startX
    local currentColumnHeight = 0
    local columnsUsed = 1
    local columnHeights = {}
    columnHeights[1] = 0

    --------------------------------------------------
    -- BUILD SECTIONS
    --------------------------------------------------
    for _, section in ipairs(SettingsConfig.sections) do

        local sectionFrame = CreateFrame("Frame", nil, UISettingsFrame, "BackdropTemplate")
        sectionFrame:SetWidth(columnWidth)

        
        sectionFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        sectionFrame:SetBackdropColor(0,0,0,0.6)

        local sectionY = -12

        local header = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 8, sectionY)
        header:SetText(section.name)

        sectionY = sectionY - 15

        local separator = sectionFrame:CreateTexture(nil, "ARTWORK")
        separator:SetHeight(1)
        separator:SetTexture(1,1,1,0.2)
        separator:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 8, sectionY)
        separator:SetPoint("TOPRIGHT", sectionFrame, "TOPRIGHT", -8, sectionY)

        sectionY = sectionY - 12

        for _, item in ipairs(section.items) do

            --------------------------------------------------
            -- CHECKBOX
            --------------------------------------------------
			if item.type == "checkbox" then

				local key = item.key
				local currentItem = item

				local parentFrame = sectionFrame
				local posY = sectionY
				local posX = 8
				local usePopupLayout = false

				
				if currentItem.framename then
					local customParent = getglobal(currentItem.framename)
					if customParent then
						parentFrame = customParent
						usePopupLayout = true

						posX = 10
						posY = customParent.nextY or -30

						
						customParent.nextY = posY - 25
						customParent.contentHeight = customParent.contentHeight + 25
						customParent:SetHeight(customParent.contentHeight + 10)
					end
				end

				
				
				local initValue = currentItem.get and currentItem.get() or FillRaidBotsSavedSettings[key]
				local cb = CreateCheckButton(
					parentFrame,
					key,
					parentFrame,
					posX,
					posY,
					currentItem.label,
					currentItem.tooltip,
					initValue,
					function(value)

						if currentItem.set then
							currentItem.set(value)
						else
							FillRaidBotsSavedSettings[key] = value
							if currentItem.onApply then
								currentItem.onApply(value)
							end
						end

					end,
					nil
				)

				currentItem.frame = cb

				
				if not usePopupLayout then
					sectionY = sectionY - 25
				end
			

            --------------------------------------------------
            -- RADIO
            --------------------------------------------------
			elseif item.type == "radio" then

				local currentItem = item
				local parentFrame = sectionFrame
				local usePopupLayout = false
				local posX = 8
				local posY = sectionY

				if currentItem.framename then
					local customParent = getglobal(currentItem.framename)
					if customParent then
						parentFrame = customParent
						usePopupLayout = true
						posX = 10
						posY = customParent.nextY or -30

						if not customParent.contentHeight then
							customParent.contentHeight = 0
						end
					end
				end

				local layout = currentItem.layout or "horizontal"
				local textPosition = currentItem.textposition or "side"

				local extraLabelHeight = 0
				if textPosition == "over" then
					extraLabelHeight = 14
				end

				local spacingX = 50
				local spacingY = 28 + extraLabelHeight
				local optionCount = table.getn(currentItem.options)

				--------------------------------------------------
				-- PREVIEW GROUP
				--------------------------------------------------

				local groupPreview = {}

				for i = 1, optionCount do
					if currentItem.options[i].buttons then

						groupPreview.fill = parentFrame:CreateTexture(nil, "ARTWORK")
						groupPreview.kick = parentFrame:CreateTexture(nil, "ARTWORK")
						groupPreview.refill = parentFrame:CreateTexture(nil, "ARTWORK")

						break
					end
				end

				--------------------------------------------------
				-- CREATE RADIO BUTTONS
				--------------------------------------------------

				local i
				for i = 1, optionCount do

					local option = currentItem.options[i]

					local xOffset = posX
					local yOffset = posY

					if layout == "horizontal" then
						xOffset = posX + ((i - 1) * spacingX)
					else
						yOffset = posY - ((i - 1) * spacingY)
					end

					local cb = CreateFrame("CheckButton", nil, parentFrame, "UICheckButtonTemplate")
					cb:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOffset, yOffset - extraLabelHeight)
					cb:SetWidth(20)
					cb:SetHeight(20)

					cb:SetChecked(FillRaidBotsSavedSettings[option.key] and true or false)

					local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
					label:SetText(option.label)

					if textPosition == "over" then
						label:SetPoint("BOTTOM", cb, "TOP", 0, 2)
					else
						label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
					end

					local tooltipText = option.tooltip or currentItem.tooltip

					if tooltipText then
						cb:SetScript("OnEnter", function(self)
							ShowSettingsTooltip(self, tooltipText)
						end)

						cb:SetScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					end

					cb:SetScript("OnClick", function()

						for j = 1, optionCount do
							local opt = currentItem.options[j]
							FillRaidBotsSavedSettings[opt.key] = false
							if opt.frame then
								opt.frame:SetChecked(false)
							end
						end

						FillRaidBotsSavedSettings[option.key] = true
						FillRaidBotsSavedSettings.buttonStyle = option.key
						cb:SetChecked(true)

						ApplyButtonStyle(option.key)
						DEFAULT_CHAT_FRAME:AddMessage(currentItem.group .. ": |cFF00FF00" .. option.label .. " selected|r")
						--------------------------------------------------
						-- UPDATE PREVIEW
						--------------------------------------------------

						if groupPreview.fill and option.buttons then

							local fill = option.buttons["openFillRaidButton"]
							local kick = option.buttons["kickAllButton"]
							local refill = option.buttons["reFillButton"]

							if fill then

								local isHorizontal = fill.width >= fill.height

								groupPreview.fill:ClearAllPoints()
								groupPreview.kick:ClearAllPoints()
								groupPreview.refill:ClearAllPoints()

								if isHorizontal then

									groupPreview.fill:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", posX + 120, posY)
									groupPreview.kick:SetPoint("TOPLEFT", groupPreview.fill, "BOTTOMLEFT", 0, -2)
									groupPreview.refill:SetPoint("TOPLEFT", groupPreview.kick, "BOTTOMLEFT", 0, -2)

								else

									groupPreview.fill:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", posX + 120, posY)
									groupPreview.kick:SetPoint("LEFT", groupPreview.fill, "RIGHT", 4, 0)
									groupPreview.refill:SetPoint("LEFT", groupPreview.kick, "RIGHT", 4, 0)

								end

								groupPreview.fill:SetTexture(fill.normal)
								groupPreview.fill:SetWidth(fill.width)
								groupPreview.fill:SetHeight(fill.height)

							end

							if kick then
								groupPreview.kick:SetTexture(kick.normal)
								groupPreview.kick:SetWidth(kick.width)
								groupPreview.kick:SetHeight(kick.height)
							end

							if refill then
								groupPreview.refill:SetTexture(refill.normal)
								groupPreview.refill:SetWidth(refill.width)
								groupPreview.refill:SetHeight(refill.height)
							end

						end

						if currentItem.onApply then
							currentItem.onApply(option.key, currentItem)
						end

						
						
						
						if option.showLockButton then
							FillRaidBotsSavedSettings.buttonMoveLocked = false
							if FRB_ShowLockButton then FRB_ShowLockButton() end
							if ToggleButtonMoveLock then ToggleButtonMoveLock(false) end
						elseif currentItem.group == "buttonMoveMode" then
							
							
							
							
							
							if FRB_ResetLockButton then FRB_ResetLockButton() end
						end

					end)

					option.frame = cb

					--------------------------------------------------
					-- LOCK BUTTON (Free mode only)
					-- Nymz: a red/green lock icon to the right of the
					-- "Moving Buttons (Free)" radio.  Red = locked in
					-- place, Green = free to drag.
					-- Hidden until Free mode is active.
					-- State: FillRaidBotsSavedSettings.buttonMoveLocked
					--------------------------------------------------
					if option.showLockButton then

						local SIZE = 18

						local lockBtn = CreateFrame("Button", "FRB_FreeModeLocBtn", parentFrame)
						lockBtn:SetWidth(SIZE)
						lockBtn:SetHeight(SIZE)
						
						
						
						lockBtn:SetPoint("LEFT", cb, "RIGHT", 118, 0)

						
						local lockTex = lockBtn:CreateTexture(nil, "ARTWORK")
						lockTex:SetWidth(SIZE)
						lockTex:SetHeight(SIZE)
						lockTex:SetPoint("CENTER", lockBtn, "CENTER", 3, 0)
						lockTex:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK")

						
						local hlTex = lockBtn:CreateTexture(nil, "HIGHLIGHT")
						hlTex:SetAllPoints(lockBtn)
						hlTex:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
						hlTex:SetBlendMode("ADD")

						
						local function RefreshLockIcon()
							local locked = FillRaidBotsSavedSettings.buttonMoveLocked
							if locked then
								
								lockTex:SetVertexColor(1, 0.15, 0.15, 1)
							else
								
								lockTex:SetVertexColor(0.15, 1, 0.15, 1)
							end
						end

						
						local function ResetLockButton()
							FillRaidBotsSavedSettings.buttonMoveLocked = false
							RefreshLockIcon()
							lockBtn:Hide()
						end

						
						local isFreeActive = FillRaidBotsSavedSettings.moveButtonsEnabled
						if isFreeActive then
							RefreshLockIcon()
							lockBtn:Show()
						else
							lockBtn:Hide()
						end

						
						lockBtn:SetScript("OnEnter", function(self)
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
							if FillRaidBotsSavedSettings.buttonMoveLocked then
								GameTooltip:SetText("|cFFFF4444Buttons Locked|r\nClick to unlock and allow free dragging.")
							else
								GameTooltip:SetText("|cFF44FF44Buttons Unlocked|r\nClick to lock buttons in their current position.")
							end
							GameTooltip:Show()
						end)
						lockBtn:SetScript("OnLeave", function()
							GameTooltip:Hide()
						end)

						
						lockBtn:SetScript("OnClick", function()
							FillRaidBotsSavedSettings.buttonMoveLocked =
								not FillRaidBotsSavedSettings.buttonMoveLocked
							RefreshLockIcon()
							
							if ToggleButtonMoveLock then
								ToggleButtonMoveLock(FillRaidBotsSavedSettings.buttonMoveLocked)
							end
							
							if GameTooltip:IsShown() then
								if FillRaidBotsSavedSettings.buttonMoveLocked then
									GameTooltip:SetText("|cFFFF4444Buttons Locked|r\nClick to unlock and allow free dragging.")
								else
									GameTooltip:SetText("|cFF44FF44Buttons Unlocked|r\nClick to lock buttons in their current position.")
								end
							end
						end)

						
						FRB_FreeModeLocBtn_Refresh = RefreshLockIcon
						
						
						FRB_ResetLockButton = ResetLockButton
						
						
						
						FRB_ShowLockButton = function()
							RefreshLockIcon()
							lockBtn:Show()
						end

					end
				end

				--------------------------------------------------
				-- DEFAULT PREVIEW
				--------------------------------------------------

				for i = 1, optionCount do
					local opt = currentItem.options[i]

					if FillRaidBotsSavedSettings[opt.key] and opt.buttons and groupPreview.fill then

						local fill = opt.buttons["openFillRaidButton"]
						local kick = opt.buttons["kickAllButton"]
						local refill = opt.buttons["reFillButton"]

						local isHorizontal = fill.width > fill.height

						if isHorizontal then
							groupPreview.fill:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", posX + 120, posY)
							groupPreview.kick:SetPoint("TOPLEFT", groupPreview.fill, "BOTTOMLEFT", 0, -2)
							groupPreview.refill:SetPoint("TOPLEFT", groupPreview.kick, "BOTTOMLEFT", 0, -2)
						else
							groupPreview.fill:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", posX + 120, posY)
							groupPreview.kick:SetPoint("LEFT", groupPreview.fill, "RIGHT", 4, 0)
							groupPreview.refill:SetPoint("LEFT", groupPreview.kick, "RIGHT", 4, 0)
						end

						groupPreview.fill:SetTexture(fill.normal)
						groupPreview.fill:SetWidth(fill.width)
						groupPreview.fill:SetHeight(fill.height)

						groupPreview.kick:SetTexture(kick.normal)
						groupPreview.kick:SetWidth(kick.width)
						groupPreview.kick:SetHeight(kick.height)

						groupPreview.refill:SetTexture(refill.normal)
						groupPreview.refill:SetWidth(refill.width)
						groupPreview.refill:SetHeight(refill.height)

					end
				end

				local totalHeight = 0

				if layout == "horizontal" then
					totalHeight = spacingY
				else
					totalHeight = optionCount * spacingY
				end

				if usePopupLayout then
					parentFrame.nextY = posY - totalHeight - 10
					parentFrame.contentHeight = parentFrame.contentHeight + totalHeight
					parentFrame:SetHeight(parentFrame.contentHeight + 20)
				else
					sectionY = sectionY - totalHeight 
				end

            --------------------------------------------------
            -- BUTTON
            --------------------------------------------------
			elseif item.type == "button" then

				local currentItem = item

				local btn = CreateFrame("Button", nil, sectionFrame, "GameMenuButtonTemplate")
				btn:SetWidth(currentItem.width or 120)
				btn:SetHeight(20)
				btn:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 8, sectionY)
				btn:SetText(currentItem.label)
				local textWidth = btn:GetFontString():GetStringWidth()
				btn:SetWidth(textWidth + 20)
				--------------------------------------------------
				-- AUTO CREATE FRAME (WITH GLOBAL NAME)
				--------------------------------------------------
				if currentItem.createFrame then

					
					local frameName = currentItem.frameName
					if not frameName then
						local clean = string.gsub(currentItem.label or "", "[^%w]", "")
						frameName = "FillRaidBots_" .. clean .. "_Frame"
					end

					
					
					local popup = CreateFrame("Frame", frameName, btn, "BackdropTemplate")

					popup:SetWidth(currentItem.frameWidth or 200)
					popup:SetHeight(40) 

					popup:SetBackdrop({
						bgFile = "Interface/Buttons/WHITE8X8",
						edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
						tile = true,
						tileSize = 16,
						edgeSize = 12,
						insets = { left = 3, right = 3, top = 3, bottom = 3 }
					})
					popup:SetBackdropColor(0,0,0,0.9)

					popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
					popup:Hide()

					
					popup.nextY = -30
					popup.contentHeight = 0 

					
					if currentItem.frameTitle then
						local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						title:SetPoint("TOP", popup, "TOP", 0, -8)
						title:SetText(currentItem.frameTitle)

						popup.contentHeight = popup.contentHeight + 20
					end

					
					currentItem.generatedFrameName = frameName
					currentItem.popupFrame = popup

					btn:SetScript("OnClick", function()
						if popup:IsShown() then
							popup:Hide()
						else
							popup:Show()
						end
					end)

				else
					
					btn:SetScript("OnClick", function()
						if currentItem.onClick then
							currentItem.onClick()
						end
					end)
				end

				btn:SetScript("OnEnter", function()
					if currentItem.tooltip then
						ShowSettingsTooltip(btn, currentItem.tooltip)
					end
				end)

				btn:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)

				sectionY = sectionY - 30
			--------------------------------------------------
			-- SLIDER
			--------------------------------------------------
			elseif item.type == "slider" then

				local currentItem = item
				local sliderName = "FillRaidSlider_" .. currentItem.key

				local slider = CreateFrame("Slider", sliderName, sectionFrame, "OptionsSliderTemplate")

				slider:SetWidth(currentItem.width or 140)
				slider:SetHeight(16)
				slider:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 8, sectionY -10) 

				local min = currentItem.min or 0
				local max = currentItem.max or 100
				local step = currentItem.step or 1
				local precision = currentItem.precision or 2

				slider:SetMinMaxValues(min, max)
				slider:SetValueStep(step)

				local saved = FillRaidBotsSavedSettings[currentItem.key]
				if saved == nil then
					saved = currentItem.default or min
				end

				slider:SetValue(saved)
				currentItem.frame = slider
				local label = getglobal(sliderName.."Text")
				local low = getglobal(sliderName.."Low")
				local high = getglobal(sliderName.."High")

				label:SetText(currentItem.label)
				low:SetText(min)
				high:SetText(max)

				
				local valueText = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				
				valueText:SetPoint("TOP", slider, "BOTTOM", 0, 2)

				local formatString = "%."..precision.."f"

				local function SnapToStep(value)
					return min + math.floor((value - min) / step + 0.5) * step
				end

				local function UpdateSliderValue(value)
					
					if currentItem.key == "ButtonSize" then
						valueText:SetText(math.floor(value) .. "%")
						return
					end
					valueText:SetText(string.format(formatString, value))
				end

				UpdateSliderValue(saved)
				
				if currentItem.tooltip then
				    slider:SetScript("OnEnter", function(self)
				        ShowSettingsTooltip(self, currentItem.tooltip)
				    end)
				
				    slider:SetScript("OnLeave", function()
				        GameTooltip:Hide()
				    end)
				end
				
				slider:SetScript("OnValueChanged", function(self)

					local value = SnapToStep(self:GetValue())

					UpdateSliderValue(value)

					FillRaidBotsSavedSettings[currentItem.key] = value

					if currentItem.onPreview then
						currentItem.onPreview(value)
					end

				end)

				slider:SetScript("OnMouseUp", function(self)

					local value = SnapToStep(self:GetValue())

					self:SetValue(value)

					FillRaidBotsSavedSettings[currentItem.key] = value

					if currentItem.onApply then
						currentItem.onApply(value)
					end

				end)

				sectionY = sectionY - 40				
			end
        end

        local sectionHeight = -sectionY + 6
        sectionFrame:SetHeight(sectionHeight)


        if currentColumnHeight + sectionHeight > maxColumnHeight then
            columnsUsed = columnsUsed + 1
            currentColumnX = startX + (columnsUsed - 1) * (columnWidth + columnSpacing)
            currentColumnHeight = 0
            columnHeights[columnsUsed] = 0
        end

        sectionFrame:SetPoint(
            "TOPLEFT",
            UISettingsFrame,
            "TOPLEFT",
            currentColumnX,
            startY - currentColumnHeight
        )

        currentColumnHeight = currentColumnHeight + sectionHeight + sectionSpacing
        columnHeights[columnsUsed] = currentColumnHeight
    end

    local tallest = 0
    for i = 1, columnsUsed do
        if columnHeights[i] and columnHeights[i] > tallest then
            tallest = columnHeights[i]
        end
    end

    UISettingsFrame:SetWidth(startX + columnsUsed * columnWidth + ((columnsUsed - 1) * columnSpacing) + 20)
    UISettingsFrame:SetHeight(tallest + 30)
end
--==================================================
-- APPLY SETTINGS
--==================================================

function ApplySavedSettings()
    for _, section in ipairs(SettingsConfig.sections) do
        for _, item in ipairs(section.items) do

            if item.type == "checkbox" then
                local value = FillRaidBotsSavedSettings[item.key]

                
                if item.frame then
                    item.frame:SetChecked(value)
                end

                
                if item.onApply then
                    item.onApply(value)
                end

            elseif item.type == "radio" then
                local selectedKey = nil

                
                for _, option in ipairs(item.options) do
                    local checked = FillRaidBotsSavedSettings[option.key]
                    if option.frame then
                        option.frame:SetChecked(checked)
                    end
                    if checked then
                        selectedKey = option.key
                    end
                end

                
                if item.onApply and selectedKey then
                    item.onApply(selectedKey)
                end
			elseif item.type == "slider" then

				local value = FillRaidBotsSavedSettings[item.key]

				if item.frame then
					item.frame:SetValue(value)
				end

				if item.onApply then
					item.onApply(value)
				end				
            end
        end
    end
end
--==================================================
-- LOAD SETTINGS
--==================================================
function FillRaidBots_LoadSettings()

    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

	if not FillRaidBotsSavedSettings.selectedButtonTheme then
		for _, section in ipairs(SettingsConfig.sections) do
			for _, item in ipairs(section.items) do
				if item.type == "radio" and item.group == "buttonTheme" then
					for _, option in ipairs(item.options) do
						if option.default then
							FillRaidBotsSavedSettings.selectedButtonTheme = option.key
							break
						end
					end
				end
			end
		end
	end

	if FillRaidBotsSavedSettings.isAutoRepairEnabled == nil then
		for _, section in ipairs(SettingsConfig.sections) do
			for _, item in ipairs(section.items) do
				if item.type == "checkbox" and item.key == "isAutoRepairEnabled" then
					FillRaidBotsSavedSettings.isAutoRepairEnabled = item.default
					break
				end
			end
		end
	end

    InitializeDefaults()

    if not settingsLoaded then
        settingsLoaded = true
        CreateSettingsUI()
    end
	
	ApplyButtonStyle(FillRaidBotsSavedSettings.selectedButtonTheme)
    ApplySavedSettings()
    
    
    local layoutCb = GetSettingsCheckbox("ButtonLayout")
    if layoutCb then
        layoutCb:SetChecked(FillRaidBotsSavedSettings.ButtonLayout == "horizontal")
    end

    if UpdateVIPSettingsState then
        UpdateVIPSettingsState()
    end
end

--==================================================
-- EVENT HANDLER
--==================================================
function GetSettingsCheckbox(key)

    for _, section in ipairs(SettingsConfig.sections) do
        for _, item in ipairs(section.items) do
            if item.type == "checkbox" and item.key == key then
                return item.frame
            end
        end
    end

end

function GetSetting(key)
    if FillRaidBotsSavedSettings then
        return FillRaidBotsSavedSettings[key]
    end
    return nil
end

