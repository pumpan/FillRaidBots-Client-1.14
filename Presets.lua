----------------------------------------------------------------------------------------------------
----------------------USE FIND to find ALLIANCE/HORDE PRESETS---------------------------------------
-------------------------AND EDIT TO YOUR PREFERED PRESETS------------------------------------------
----------------------------------------------------------------------------------------------------


local function generateTooltip(values)
    local tooltipParts = {}
    for role, count in pairs(values) do
        table.insert(tooltipParts, count .. " " .. role)
    end
    return table.concat(tooltipParts, ", ")
end


local function regenerateTooltips()
    
    local presetTables = {naxxramasPresets, bwlPresets, mcPresets, onyxiaPresets, aq40Presets, aq20Presets, ZGPresets, otherPresets}

    
    for _, presets in ipairs(presetTables) do
        for _, preset in ipairs(presets) do
            local name = preset.fullname or preset.label  
            preset.tooltip = name .. " (" .. generateTooltip(preset.values) .. ")"  
        end
    end
end


if not FillRaidPresets then
    FillRaidPresets = {}
end

naxxramasPresets = {}
bwlPresets = {}
mcPresets = {}
onyxiaPresets = {}
aq40Presets = {}
aq20Presets = {}
ZGPresets = {}
otherPresets = {}

-------------------------------------------------------
-------------------------------------------------------
local function generateTooltip(values)
    local tooltipParts = {}
    for role, count in pairs(values) do
        table.insert(tooltipParts, count .. " " .. role)
    end
    return table.concat(tooltipParts, ", ")
end

local function regenerateTooltips()
    local presetTables = {
        naxxramasPresets,
        bwlPresets,
        mcPresets,
        onyxiaPresets,
        aq40Presets,
        aq20Presets,
        ZGPresets,
        otherPresets
    }

    for _, presets in ipairs(presetTables) do
        for _, preset in ipairs(presets) do
            local name = preset.fullname or preset.label
            preset.tooltip = name .. " (" .. generateTooltip(preset.values) .. ")"
        end
    end
end

-------------------------------------------------------
-------------------------------------------------------
local function SetFactionPresets(factionName, factionGroup)
    DEFAULT_CHAT_FRAME:AddMessage("Your faction: " .. factionGroup)

   
    if FillRaidPresets == nil then
        FillRaidPresets = {}
    end

   
    if not FillRaidPresets[factionName] then
        DEFAULT_CHAT_FRAME:AddMessage("No saved presets found for " .. factionName .. ". Loading default presets...")

        FillRaidPresets[factionName] = {
			naxxramasPresets = {
				{
					label = "PatchW",
					values = {
						["warrior tank"] = 7,
						["warrior meleedps"] = 10,
						["rogue meleedps"] = 12,
						["paladin healer"] = factionName == "Alliance" and 6 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["priest healer"] = factionName == "Horde" and 6 or 2,
						["druid healer"] = 2,
					},
					fullname = "AbominationWing PatchWerk"
				},
				{
					label = "GrobB",
					values = {
						["warrior tank"] = 2,
						["rogue meleedps"] = 29,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["priest healer"] = factionName == "Alliance" and 2 or nil,
						["druid healer"] = factionName == "Alliance" and 1 or nil,
					},
					fullname = "AbominationWing Grobbulus"
				},
				{
					label = "Gluth",
					values = {
						["warrior tank"] = 8,
						["rogue meleedps"] = 22,
						["mage rangedps"] = 1,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["priest healer"] = factionName == "Horde" and 5 or 2,
						["druid healer"] = 1,
					},
					fullname = "AbominationWing Gluth"
				},
				{
					label = "Thadd",
					values = {
						["warrior tank"] = 3,
						["rogue meleedps"] = 27,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["priest healer"] = factionName == "Alliance" and 2 or nil,
						["druid healer"] = factionName == "Alliance" and 2 or nil,
					},
					fullname = "AbominationWing Thaddius",
					bosses = {"Stalagg", "Feugen", "Thaddius"}            
				},
				{
					label = "Razzuv",
					values = {
						["warrior tank"] = 10,
						["warrior meleedps"] = 10,
						["rogue meleedps"] = 10,
						["paladin healer"] = factionName == "Alliance" and 9 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
						["priest healer"] = factionName == "Horde" and 5 or nil,
						["druid healer"] = 0,
					},
					fullname = "Instructor Razuvious"
				},
				{
					label = "Gothik",
					values = {
						["warrior tank"] = 4,
						["warrior meleedps"] = 26,
						["mage rangedps"] = 1,
						["rogue meleedps"] = 0,
						["paladin healer"] = factionName == "Alliance" and 6 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
						["priest healer"] = factionName == "Horde" and 4 or 2,
						["druid healer"] = 0,
					},
					fullname = "Gothik the Harvester"
				},
				{
					label = "4 horse",
					values = {
						["warrior tank"] = 3,
						["warrior meleedps"] = 35,
						["rogue meleedps"] = 0,
						["paladin healer"] = factionName == "Alliance" and 1 or nil,
						["priest healer"] = factionName == "Horde" and 1 or nil,
						["druid healer"] = 0,
					},
					fullname = "4 Horsemen",
					bosses = {"Baron Rivendare", "Thane Korth'azz", "Lady Blaumeux", "Sir Zeliek"}
				},
				{
					label = "Anub'Rekhan",
					values = {
						["warrior tank"] = 3,
						["warrior meleedps"] = 25,
						["mage rangedps"] = 0,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 5 or nil,
						["rogue meleedps"] = 4,
						["priest healer"] = 1,
						["druid healer"] = 1,
					},
					fullname = "Anub'Rekhan"
				},
				{
					label = "Faerlina",
					values = {
						["warrior tank"] = 3,
						["mage rangedps"] = 25,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 1 or nil,
						["rogue meleedps"] = 0,
						["priest healer"] = factionName == "Horde" and 6 or 2,
						["druid healer"] = 4,
					},
					fullname = "Grand Widow Faerlina"
				},
				{
					label = "Maexxna",
					values = {
						["warrior tank"] = 9,
						["mage rangedps"] = 15,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["rogue meleedps"] = 3,
						["priest healer"] = factionName == "Horde" and 5 or 2,
						["priest rangedps"] = 3,
						["druid healer"] = 2,
					},
					fullname = "Maexxna"
				},
				{
					label = "Noth",
					values = {
						["warrior tank"] = 6,
						["mage rangedps"] = 16,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
						["rogue meleedps"] = 9,
						["priest healer"] = 0,
						["druid healer"] = 4,
					},
					fullname = "Noth the Plaguebringer"
				},
				{
					label = "Heigan",
					values = {
						["warrior tank"] = 5,
						["warrior meleedps"] = 10,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 1 or nil,
						["rogue meleedps"] = 16,
						["priest healer"] = factionName == "Horde" and 0 or 2,
						["druid healer"] = factionName == "Horde" and 0 or 2,
					},
					fullname = "Heigan the Unclean"
				},
				{
					label = "Loatheb",
					values = {
						["warrior tank"] = 4,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["rogue meleedps"] = 33,
					},
					fullname = "Loatheb"
				},
				{
					label = "Sapphiron",
					values = {
						["warrior tank"] = 4,
						["warrior meleedps"] = 8,
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["rogue meleedps"] = 17,
						["priest healer"] = factionName == "Horde" and 6 or nil,
						["druid healer"] = 2,
					},
					fullname = "Frostwyrm Lair Sapphiron"
				},
				{
					label = "Kel'Thuzad",
					values = {
						["warrior tank"] = 8,
						["mage rangedps"] = 3,
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
						["rogue meleedps"] = 16,
						["priest healer"] = factionName == "Horde" and 6 or 4,
					},
					fullname = "Frostwyrm Lair Kel'Thuzad"
				}
			},

			bwlPresets = {
				{
					label = "Razorgore",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["priest healer"] = factionName == "Horde" and 8 or nil,
						["mage rangedps"] = 29,
					},
					fullname = "Razorgore the Untamed"
				},
				{
					label = "Vaelastrasz",
					values = {
						["warrior tank"] = 2,
						["warrior meleedps"] = 10,
						["paladin healer"] = factionName == "Alliance" and 8 or nil, 
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["rogue meleedps"] = 17,
						["druid healer"] = 2,
						["priest healer"] = factionName == "Horde" and 1 or nil,
					},
					fullname = "Vaelastrasz the Corrupt"
				},
				{
					label = "Broodlord",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 6 or nil, 
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["druid healer"] = 2,              
						["rogue meleedps"] = 29,
					},
					fullname = "Broodlord Lashlayer"
				},
				{
					label = "Firemaw",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["warrior meleedps"] = 35,
					},
					fullname = "Firemaw"
				},
				{
					label = "Ebonroc",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["warrior meleedps"] = 29,
					},
					fullname = "Ebonroc"
				},
				{
					label = "Flamegor",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["warrior meleedps"] = 29,
					},
					fullname = "Flamegor"
				},
				{
					label = "Chromaggus",
					values = {
						["warrior tank"] = 4,
						["druid healer"] = 8,
						["priest healer"] = 2,
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["rogue meleedps"] = 17,
					},
					fullname = "Chromaggus"
				},
				{
					label = "Nefarian",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["priest healer"] = factionName == "Horde" and 1 or nil,
						["rogue meleedps"] = factionName == "Alliance" and 29 or 28,
					},
					fullname = "Nefarian"
				}
			},

			mcPresets = {
				{
					label = "Lucifron",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["warrior meleedps"] = 35,
					},
					fullname = "Lucifron"
				},
				{
					label = "Magmadar",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["priest healer"] = factionName == "Horde" and 4 or nil,
						["mage rangedps"] = 33,
					},
					fullname = "Magmadar"
				},
				{
					label = "Gehennas",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
						["druid healer"] = 1,
						["warrior meleedps"] = 32,
					},
					fullname = "Gehennas"
				},
				{
					label = "Garr",
					values = {
						["warrior tank"] = 8,
						["paladin healer"] = factionName == "Alliance" and 6 or nil,
						["priest healer"] = factionName == "Horde" and 6 or nil,
						["druid healer"] = 1,
						["mage rangedps"] = 24,
					},
					fullname = "Garr"
				},
				{
					label = "Geddon",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["priest healer"] = factionName == "Horde" and 2 or nil,
						["mage rangedps"] = 35,
					},
					fullname = "Baron Geddon"
				},
				{
					label = "Shazzrah",
					values = {
						["warrior tank"] = 2,
						["mage rangedps"] = 37,
					},
					fullname = "Shazzrah"
				},
				{
					label = "Sulfuron",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["druid healer"] = 1,
						["warrior meleedps"] = 34,
					},
					fullname = "Sulfuron Harbinger"
				},
				{
					label = "Golemagg",
					values = {
						["warrior tank"] = 3,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 1 or nil,
						["priest healer"] = factionName == "Horde" and 4 or nil,
						["druid healer"] = 1,
						["mage rangedps"] = 31,
					},
					fullname = "Golemagg"
				},
				{
					label = "Majordomo",
					values = {
						["warrior tank"] = 4,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["priest healer"] = factionName == "Horde" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 1 or nil,
						["mage rangedps"] = factionName == "Alliance" and 31 or 30,
					},
					fullname = "Majordomo Executus"
				},
				{
					label = "Ragnaros",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["priest healer"] = factionName == "Horde" and 8 or 4,
						["warlock rangedps"] = 2,
						["mage rangedps"] = 27,
					},
					fullname = "Ragnaros"
				}
			},

			onyxiaPresets = {
				{
					label = "Onyxia",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 1 or nil,
						["priest healer"] = factionName == "Horde" and 2 or nil,
						["mage rangedps"] = factionName == "Alliance" and 35 or 34,
					},
					fullname = "Onyxia"
				}
			},

			aq40Presets = {
				{
					label = "Skeram",
					values = {
						["warrior tank"] = 2,
						["warrior meleedps"] = 37,
					},
					fullname = "The Prophet Skeram"
				},
				{
					label = "Bug Trio",
					values = {
						["warrior tank"] = 4,
						["paladin healer"] = factionName == "Alliance" and 8 or nil, 
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["warrior meleedps"] = 27,
					},
					fullname = "Bug Trio (Princess Yauj, Vem, Lord Kri)",
					bosses = {"Princess Yauj", "Vem", "Lord Kri"}
				},
				{
					label = "Sartura",
					values = {
						["warrior tank"] = 1, 
						["paladin healer"] = factionName == "Alliance" and 6 or nil,
						["priest healer"] = factionName == "Horde" and 6 or nil,
						["druid healer"] = 2,
						["hunter rangedps"] = 30,
					},
					fullname = "Battleguard Sartura"
				},
				{
					label = "Fankriss",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
						["priest healer"] = factionName == "Horde" and 3 or nil,
						["druid healer"] = 3,
						["warrior meleedps"] = 15,
						["mage rangedps"] = 15,
					},
					fullname = "Fankriss the Unyielding"
				},
				{
					label = "Viscidus",
					values = {
						["warrior tank"] = 1,
						["paladin healer"] = factionName == "Alliance" and 3 or nil,
						["priest healer"] = factionName == "Horde" and 3 or nil,
						["warrior meleedps"] = 15,
						["mage rangedps"] = 20,
					},
					fullname = "Viscidus"
				},
				{
					label = "Huhuran",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 1 or nil,
						["priest healer"] = factionName == "Horde" and 1 or nil,
						["rogue meleedps"] = 10,              
						["warrior meleedps"] = 26,
					},
					fullname = "Princess Huhuran"
				},
				{
					label = "Twin Emperors",
					values = {
						["warrior tank"] = 6,
						["paladin healer"] = factionName == "Alliance" and 9 or nil,
						["priest healer"] = factionName == "Horde" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 3 or nil,
						["druid healer"] = 0,
						["mage rangedps"] = factionName == "Horde" and 14 or 0,
						["rogue meleedps"] = 24,
					},
					fullname = "The Twin Emperors",
					bosses = {"Emperor Vek'lor", "Emperor Vek'nilash"}
				},
				{
					label = "Ouro",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 5 or nil,
						["priest healer"] = factionName == "Horde" and 2 or nil,
						["warrior meleedps"] = factionName == "Alliance" and 32 or 30,
					},
					fullname = "Ouro"
				},
				{
					label = "C'Thun",
					values = {
						["paladin healer"] = factionName == "Alliance" and 8 or nil,
						["shaman healer"] = factionName == "Horde" and 8 or nil,
						["priest healer"] = factionName == "Horde" and 4 or nil,
						["rogue meleedps"] = factionName == "Alliance" and 32 or 27,
					},
					fullname = "C'Thun"
				}
			},

			aq20Presets = {
				{
					label = "Kurinnaxx",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["priest healer"] = factionName == "Horde" and 2 or nil,
						["mage rangedps"] = 15,
					},
					fullname = "Kurinnaxx"
				},
				{
					label = "General Rajaxx",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 5 or nil,
						["rogue meleedps"] = 12,
					},
					fullname = "General Rajaxx"
				},
				{
					label = "Moam",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["warrior meleedps"] = 15,
					},
					fullname = "Moam"
				},
				{
					label = "Ossirian",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 5 or nil,
						["rogue meleedps"] = 12,
					},
					fullname = "Ossirian"
				},
				{
					label = "Ayamiss",
					values = {
						["warrior tank"] = 2, 
						["paladin healer"] = factionName == "Alliance" and 3 or nil,
						["shaman healer"] = factionName == "Horde" and 3 or nil,
						["priest healer"] = 2,
						["mage rangedps"] = 12,
					},
					fullname = "Ayamiss the Hunter"
				},
				{
					label = "Buru",
					values = {
						["warrior tank"] = 2, 
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["priest healer"] = factionName == "Horde" and 2 or nil,
						["mage rangedps"] = 15,
					},
					fullname = "Buru the Gorger"
				}
			},
			ZGPresets = {
				{
					label = "Jeklik",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["warrior meleedps"] = 15,
					},
					fullname = "High Priestess Jeklik"
				},
				{
					label = "Venoxis",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["priest healer"] = factionName == "Horde" and 2 or nil,
						["mage rangedps"] = 15,
					},
					fullname = "High Priest Venoxis"
				},
				{
					label = "Mar'li",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["warrior meleedps"] = 15,
					},
					fullname = "High Priestess Mar'li"
				},
				{
					label = "Mandokir",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 7 or nil,
						["priest healer"] = factionName == "Horde" and 7 or nil,
						["mage rangedps"] = 10,
					},
					fullname = "Bloodlord Mandokir"
				},
				{
					label = "Thekal",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
						["warrior meleedps"] = 15,
					},
					fullname = "High Priest Thekal"
				},
				{
					label = "Arlokk",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
						["warrior meleedps"] = 13,
					},
					fullname = "High Priestess Arlokk"
				},
				{
					label = "Jin'do",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 5 or nil,
						["warrior meleedps"] = 12,
					},
					fullname = "Jin'do the Hexxer"
				},
				{
					label = "Hakkar",
					values = {
						["warrior tank"] = 2,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["shaman healer"] = factionName == "Horde" and 5 or nil,
						["rogue meleedps"] = 12,
					},
					fullname = "Hakkar the Soulflayer"
				},
			},

			otherPresets = {
				{
					label = "Melee group",
					values = {
						["warrior tank"] = 4,
						["warrior meleedps"] = 18,
						["rogue meleedps"] = 13,
						["paladin healer"] = factionName == "Alliance" and 4 or nil,
						["shaman healer"] = factionName == "Horde" and 4 or nil,
					},
					fullname = "Melee group."
				},
				{
					label = "Warrior group",
					values = {
						["warrior tank"] = 2,
						["warrior meleedps"] = 35,
						["rogue meleedps"] = 0,
						["paladin healer"] = factionName == "Alliance" and 2 or nil,
						["shaman healer"] = factionName == "Horde" and 2 or nil,
					},
					fullname = "Warrior group"
				},      
				{
					label = "Mage group",
					values = {
						["warrior tank"] = 4,
						["mage rangedps"] = 30,
						["paladin healer"] = factionName == "Alliance" and 5 or nil,
						["priest healer"] = factionName == "Horde" and 5 or nil,
					},
					fullname = "Mage group"
				},
			}
		}

    else
        QueueDebugMessage("INFO: Loaded saved presets for " .. factionName .. " from SavedVariables.", "debuginfo")

    end

   
    naxxramasPresets = FillRaidPresets[factionName].naxxramasPresets or {}
    bwlPresets = FillRaidPresets[factionName].bwlPresets or {}
    mcPresets = FillRaidPresets[factionName].mcPresets or {}
    onyxiaPresets = FillRaidPresets[factionName].onyxiaPresets or {}
    aq40Presets = FillRaidPresets[factionName].aq40Presets or {}
    aq20Presets = FillRaidPresets[factionName].aq20Presets or {}
    ZGPresets = FillRaidPresets[factionName].ZGPresets or {}
    otherPresets = FillRaidPresets[factionName].otherPresets or {}

	regenerateTooltips()
end

-------------------------------------------------------
-------------------------------------------------------
local function CheckFaction()
    local factionName, factionGroup = UnitFactionGroup("player")
    SetFactionPresets(factionName, factionGroup)
	faction = factionGroup
    if instanceFrame then
        instanceFrame:Hide()
    end

    instanceFrames["PresetDungeounNaxxramas"] = CreateInstanceFrame("PresetDungeounNaxxramas", naxxramasPresets)
    instanceFrames["PresetDungeounBWL"] = CreateInstanceFrame("PresetDungeounBWL", bwlPresets)
    instanceFrames["PresetDungeounMC"] = CreateInstanceFrame("PresetDungeounMC", mcPresets)
    instanceFrames["PresetDungeounOnyxia"] = CreateInstanceFrame("PresetDungeounOnyxia", onyxiaPresets)
    instanceFrames["PresetDungeounAQ40"] = CreateInstanceFrame("PresetDungeounAQ40", aq40Presets)
    instanceFrames["PresetDungeounAQ20"] = CreateInstanceFrame("PresetDungeounAQ20", aq20Presets)
    instanceFrames["PresetDungeounZG"] = CreateInstanceFrame("PresetDungeounZG", ZGPresets)
    instanceFrames["PresetDungeounOther"] = CreateInstanceFrame("PresetDungeounOther", otherPresets)
end

-------------------------------------------------------
-------------------------------------------------------
SLASH_CHECKFACTION1 = "/checkfaction"
SlashCmdList["CHECKFACTION"] = function()
    CheckFaction()
end

local factionEventFrame = CreateFrame("Frame")
factionEventFrame:RegisterEvent("PLAYER_LOGIN")
factionEventFrame:SetScript("OnEvent", function()
    CheckFaction()
end)
