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


local function SetFactionPresets(factionGroup)
    if factionGroup == "Alliance" then

----------------------------------------------------------------------------------------------------
-----------------------------------ALLIANCE PRESETS-------------------------------------------------
----------------------------------------------------------------------------------------------------
	if not factionGroup then
		DEFAULT_CHAT_FRAME:AddMessage("You are Alliance!")
	end	
	naxxramasPresets = {
		{
			label = "PatchW",
			values = {
				["warrior tank"] = 7,
				["warrior meleedps"] = 10,
				["rogue meleedps"] = 12,
				["paladin healer"] = 6,
				["priest healer"] = 2,
				["druid healer"] = 2,
			},
			fullname = "AbominationWing PatchWerk"
		},
		{
			label = "GrobB",
			values = {
				["warrior tank"] = 2,
				["rogue meleedps"] = 29,
				["paladin healer"] = 5,
				["priest healer"] = 2,
				["druid healer"] = 1,
			},
			fullname = "AbominationWing Grobbulus"
		},
		{
			label = "Gluth",
			values = {
				["warrior tank"] = 8,
				["rogue meleedps"] = 22,
				["mage rangedps"] = 1,
				["paladin healer"] = 5,
				["priest healer"] = 2,
				["druid healer"] = 1,
			},
			fullname = "AbominationWing Gluth"
		},
		{
			label = "Thadd",
			values = {
				["warrior tank"] = 3,
				["rogue meleedps"] = 27,
				["paladin healer"] = 5,
				["priest healer"] = 2,
				["druid healer"] = 2,
			},
			fullname = "AbominationWing Thaddius"
		},

		{
			label = "Razzuv",
			values = {
				["warrior tank"] = 8,
				["warrior meleedps"] = 12,
				["rogue meleedps"] = 10,
				["paladin healer"] = 9,
				["priest healer"] = 0,
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
				["paladin healer"] = 6,
				["priest healer"] = 2,
				["druid healer"] = 0,
			},
			fullname = "Gothik the Harvester"
		},
		{
			label = "4 horse",
			values = {
				["warrior tank"] = 3,
				["warrior meleedps"] = 32,
				["rogue meleedps"] = 0,
				["paladin healer"] = 4,
				["priest healer"] = 0,
				["druid healer"] = 0,
			},
			fullname = "4 Horsemen"
		},

		{
			label = "Anub'Rekhan",
			values = {
				["warrior tank"] = 3,
				["warrior meleedps"] = 25,
				["mage rangedps"] = 0,
				["paladin healer"] = 5,
				["rogue meleedps"] = 4,
				["priest healer"] = 1,
				["druid healer"] = 1,
			},
			fullname = "SpiderWing Anub'Rekhan"
		},
		{
			label = "Faerlina",
			values = {
				["warrior tank"] = 3,
				["mage rangedps"] = 25,
				["paladin healer"] = 5,
				["rogue meleedps"] = 0,
				["priest healer"] = 2,
				["druid healer"] = 4,
			},
			fullname = "SpiderWing Grand Widow Faerlina"
		},
		{
			label = "Maexxna",
			values = {
				["warrior tank"] = 9,
				["mage rangedps"] = 15,
				["paladin healer"] = 5,
				["rogue meleedps"] = 3,
				["priest healer"] = 2,
				["priest rangedps"] = 3,
				["druid healer"] = 2,
			},
			fullname = "SpiderWing Maexxna"
		},
		{
			label = "Noth",
			values = {
				["warrior tank"] = 6,
				["mage rangedps"] = 15,
				["paladin healer"] = 4,
				["rogue meleedps"] = 6,
				["priest healer"] = 2,
				["druid healer"] = 6,
			},
			fullname = "PlagueWing Noth the Plaguebringer"
		},
		{
			label = "Heigan",
			values = {
				["warrior tank"] = 5,
				["mage rangedps"] = 21,
				["paladin healer"] = 4,
				["rogue meleedps"] = 5,
				["priest healer"] = 2,
				["druid healer"] = 2,
			},
			fullname = "PlagueWing Heigan the Unclean"
		},
		{
			label = "Loatheb",
			values = {
				["warrior tank"] = 4,
				["mage rangedps"] = 21,
				["paladin healer"] = 5,
				["rogue meleedps"] = 4,
				["priest healer"] = 3,
				["druid healer"] = 2,
			},
			fullname = "PlagueWing Loatheb"
		},
		{
			label = "Sapphiron",
			values = {
				["warrior tank"] = 10,
				["mage rangedps"] = 12,
				["paladin healer"] = 5,
				["rogue meleedps"] = 5,
				["priest healer"] = 4,
				["druid healer"] = 3,
			},
			fullname = "Frostwyrm Lair Sapphiron"
		},
		{
			label = "Kel'Thuzad",
			values = {
				["warrior tank"] = 12,
				["mage rangedps"] = 7,
				["paladin healer"] = 6,
				["rogue meleedps"] = 6,
				["priest healer"] = 4,
				["druid healer"] = 4,
			},
			fullname = "Frostwyrm Lair Kel'Thuzad"
		}

		
	}

	bwlPresets = {
		{
			label = "Razorgore",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 8,
				["mage rangedps"] = 29,
			},
			fullname = "Razorgore the Untamed(BWL)"
		},
		{
			label = "Vaelastrasz",
			values = {
				["warrior tank"] = 2,
				["warrior meleedps"] = 10,
				["paladin healer"] = 8, 
				["rogue meleedps"] = 17,
				["druid healer"] = 2,
			},
			fullname = "Vaelastrasz the Corrupt (BWL)"
		},
		{
			label = "Broodlord",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 6, 
				["druid healer"] = 2, 				
				["rogue meleedps"] = 29,
			},
			fullname = "Broodlord Lashlayer (BWL)"
		},
		{
			label = "Ebonroc",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 8,
				["warrior meleedps"] = 29,
			},
			fullname = "Ebonroc (BWL)"
		},
		{
			label = "Firemaw",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["warrior meleedps"] = 35,
			},
			fullname = "Firemaw (BWL)"
		},
		{
			label = "Chromaggus",
			values = {
				["warrior tank"] = 4,
				["druid healer"] = 8,
				["priest healer"] = 2,
				["paladin healer"] = 8,
				["rogue meleedps"] = 17,
			},
			fullname = "Chromaggus (BWL)"
		},
		{
			label = "Nefarian",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 8,
				["rogue meleedps"] = 29,
			},
			fullname = "Nefarian (BWL)"
		}
	}


	mcPresets = {
		{
			label = "Lucifron",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["warrior meleedps"] = 35,
			},
			fullname = "Lucifron"
		},
		{
			label = "Magmadar",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 4,
				["mage rangedps"] = 33,
			},
			fullname = "Magmadar"
		},
		{
			label = "Gehennas",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 4,
				["druid healer"] = 1,
				["warrior meleedps"] = 32,
			},
			fullname = "Gehennas"
		},
		{
			label = "Garr",
			values = {
				["warrior tank"] = 8,
				["paladin healer"] = 6,
				["druid healer"] = 1,
				["mage rangedps"] = 24,
			},
			fullname = "Garr"
		},
		{
			label = "Geddon",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
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
				["paladin healer"] = 2,
				["druid healer"] = 1,
				["warrior meleedps"] = 34,
			},
			fullname = "Sulfuron Harbinger"
		},
		{
			label = "Golemagg",
			values = {
				["warrior tank"] = 3,
				["paladin healer"] = 4,
				["druid healer"] = 1,
				["mage rangedps"] = 31,
			},
			fullname = "Golemagg"
		},
		{
			label = "Majordomo",
			values = {
				["warrior tank"] = 4,
				["paladin healer"] = 4,
				["druid healer"] = 1,
				["mage rangedps"] = 30,
			},
			fullname = "Majordomo Executus"
		},
		{
			label = "Ragnaros",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 4,
				["priest healer"] = 4,
				["warlock rangedps"] = 2,
				["mage rangedps"] = 27,
			},
			fullname = "Ragnaros"
		}
	}

	onyxiaPresets = {
		{
			label = "Onyxia",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["mage rangedps"] = 35,
			},
			fullname = "Onyxia"

		}
	}




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
				["paladin healer"] = 8,
				["warrior meleedps"] = 27,
			},
			fullname = "Bug Trio"
		},
		{
			label = "Sartura",
			values = {
				["warrior tank"] = 1, 
				["paladin healer"] = 6,
				["druid healer"] = 2,
				["mage rangedps"] = 30,
			},
			fullname = "Battleguard Sartura"
		},
		{
			label = "Fankriss",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 4,
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
				["paladin healer"] = 3,
				["warrior meleedps"] = 15,
				["mage rangedps"] = 20,
			},
			fullname = "Viscidus"
		},
		{
			label = "Huhuran",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 1,
				["warrior meleedps"] = 36,
			},
			fullname = "Princess Huhuran"
		},
		{
			label = "Twin Emperors",
			values = {
				["warrior tank"] = 4,
				["paladin healer"] = 4,
				["druid healer"] = 3,
				["mage rangedps"] = 14,
				["rogue meleedps"] = 14,
			},
			fullname = "The Twin Emperors"
		},
		{
			label = "Ouro",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 5,
				["druid healer"] = 2,
				["warrior meleedps"] = 30,
			},
			fullname = "Ouro"
		},
		{
			label = "C'Thun",
			values = {
				["paladin healer"] = 8,
				["druid healer"] = 4,
				["rogue meleedps"] = 27,
			},
			fullname = "C'Thun"
		}
	}

	aq20Presets = {
		{
			label = "Kurinnaxx",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["mage rangedps"] = 15,
			},
			fullname = "Kurinnaxx"
		},
		{
			label = "General Rajaxx",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 5,
				["rogue meleedps"] = 12,
			},
			fullname = "General Rajaxx"
		},
		{
			label = "Moam",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Moam"
		},
		{
			label = "Ossirian",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 5,
				["rogue meleedps"] = 12,
			},
			fullname = "Ossirian)"
		},
		{
			label = "Ayamiss",
			values = {
				["warrior tank"] = 2, 
				["paladin healer"] = 3,
				["priest healer"] = 2,
				["mage rangedps"] = 14,
			},
			fullname = "Ayamiss the Hunter)"
		},
		{
			label = "Buru",
			values = {
				["warrior tank"] = 2, 
				["paladin healer"] = 2,
				["mage rangedps"] = 15,
			},
			fullname = "Buru the Gorger"
		}
	}


	ZGPresets = {
		{
			label = "Jeklik",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Jeklik"
		},
		{
			label = "Venoxis",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["mage rangedps"] = 15,
			},
			fullname = "Venoxis"
		},
		{
			label = "Mar'li",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Mar'li"
		},
		{
			label = "Mandokir",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 7,
				["mage rangedps"] = 10,
			},
			fullname = "Mandokir"
		},
		{
			label = "Thekal",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Thekal"
		},
		{
			label = "Arlokk",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 4,
				["warrior meleedps"] = 14,
			},
			fullname = "Arlokk"
		},
		{
			label = "Jin'do",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 5,
				["warrior meleedps"] = 12,
			},
			fullname = "Jin'do"
		},
		{
			label = "Hakkar",
			values = {
				["warrior tank"] = 2,
				["paladin healer"] = 5,
				["rogue meleedps"] = 12,
			},
			fullname = "Hakkar"
		},
	}


	otherPresets = {

		{
			label = "Melee group",
			values = {
				["warrior tank"] = 4,
				["warrior meleedps"] = 18,
				["rogue meleedps"] = 13,
				["paladin healer"] = 4,
			},
			fullname = "Melee group."
		},
		{
			label = "Warrior group",
			values = {
				["warrior tank"] = 2,
				["warrior meleedps"] = 35,
				["rogue meleedps"] = 0,
				["paladin healer"] = 2,
			},
			fullname = "Warrior group"
		},		
		{
			label = "Mage group",
			values = {
				["warrior tank"] = 4,
				["mage rangedps"] = 30,
				["paladin healer"] = 5,
			},
			fullname = "Mage group"
		},
	}
    regenerateTooltips()

    elseif factionGroup == "Horde" then
        ----------------------------------------------------------------------------------------------------
        -----------------------------------HORDE PRESETS-------------------------------------------------
        ----------------------------------------------------------------------------------------------------
 	if not factionGroup then
		DEFAULT_CHAT_FRAME:AddMessage("You are Horde!")
	end	
	naxxramasPresets = {
		{
			label = "PatchW",
			values = {
				["warrior tank"] = 7,
				["warrior meleedps"] = 10,
				["rogue meleedps"] = 12,
				["shaman healer"] = 2,
				["priest healer"] = 6,
				["druid healer"] = 2,
			},
			fullname = "AbominationWing PatchWerk"
		},
		{
			label = "GrobB",
			values = {
				["warrior tank"] = 2,
				["rogue meleedps"] = 29,
				["shaman healer"] = 8,
			},
			fullname = "AbominationWing Grobbulus"
		},
		{
			label = "Gluth",
			values = {
				["warrior tank"] = 8,
				["rogue meleedps"] = 22,
				["mage rangedps"] = 1,
				["shaman healer"] = 2,
				["priest healer"] = 5,
				["druid healer"] = 1,
			},
			fullname = "AbominationWing Gluth"
		},
		{
			label = "Thadd",
			values = {
				["warrior tank"] = 3,
				["rogue meleedps"] = 27,
				["shaman healer"] = 8,

			},
			fullname = "AbominationWing Thaddius"
		},

		{
			label = "Razzuv",
			values = {
				["warrior tank"] = 8,
				["warrior meleedps"] = 12,
				["rogue meleedps"] = 10,
				["shaman healer"] = 4,
				["priest healer"] = 5,
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
				["shaman healer"] = 4,
				["priest healer"] = 4,
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
				["priest healer"] = 1,
				["druid healer"] = 0,
			},
			fullname = "4 Horsemen"
		},

		{
			label = "Anub'Rekhan",
			values = {
				["warrior tank"] = 3,
				["warrior meleedps"] = 25,
				["mage rangedps"] = 0,
				["shaman healer"] = 5,
				["rogue meleedps"] = 4,
				["priest healer"] = 1,
				["druid healer"] = 1,
			},
			fullname = "SpiderWing Anub'Rekhan"
		},
		{
			label = "Faerlina",
			values = {
				["warrior tank"] = 3,
				["mage rangedps"] = 25,
				["shaman healer"] = 1,
				["rogue meleedps"] = 0,
				["priest healer"] = 6,
				["druid healer"] = 4,
			},
			fullname = "SpiderWing Grand Widow Faerlina"
		},
		{
			label = "Maexxna",
			values = {
				["warrior tank"] = 9,
				["mage rangedps"] = 15,
				["shaman healer"] = 2,
				["rogue meleedps"] = 3,
				["priest healer"] = 5,
				["priest rangedps"] = 3,
				["druid healer"] = 2,
			},
			fullname = "SpiderWing Maexxna"
		},
		{
			label = "Noth",
			values = {
				["warrior tank"] = 6,
				["mage rangedps"] = 15,
				["shaman healer"] = 4,
				["rogue meleedps"] = 6,
				["priest healer"] = 2,
				["druid healer"] = 6,
			},
			fullname = "PlagueWing Noth the Plaguebringer"
		},
		{
			label = "Heigan",
			values = {
				["warrior tank"] = 5,
				["mage rangedps"] = 21,
				["shaman healer"] = 2,
				["rogue meleedps"] = 5,
				["priest healer"] = 4,
				["druid healer"] = 2,
			},
			fullname = "PlagueWing Heigan the Unclean"
		},
		{
			label = "Loatheb",
			values = {
				["warrior tank"] = 4,
				["mage rangedps"] = 21,
				["shaman healer"] = 2,
				["rogue meleedps"] = 4,
				["priest healer"] = 6,
				["druid healer"] = 2,
			},
			fullname = "PlagueWing Loatheb"
		},
		{
			label = "Sapphiron",
			values = {
				["warrior tank"] = 10,
				["mage rangedps"] = 12,
				["shaman healer"] = 3,
				["rogue meleedps"] = 5,
				["priest healer"] = 6,
				["druid healer"] = 3,
			},
			fullname = "Frostwyrm Lair Sapphiron"
		},
		{
			label = "Kel'Thuzad",
			values = {
				["warrior tank"] = 12,
				["mage rangedps"] = 7,
				["shaman healer"] = 4,
				["rogue meleedps"] = 6,
				["priest healer"] = 6,
				["druid healer"] = 4,
			},
			fullname = "Frostwyrm Lair Kel'Thuzad"
		}

		
	}

	bwlPresets = {
		{
			label = "Razorgore",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 8,
				["mage rangedps"] = 29,
			},
			fullname = "Razorgore the Untamed(BWL)"
		},
		{
			label = "Vaelastrasz",
			values = {
				["warrior tank"] = 2,
				["warrior meleedps"] = 10,
				["shaman healer"] = 8, 
				["rogue meleedps"] = 18,
				["priest healer"] = 1,
			},
			fullname = "Vaelastrasz the Corrupt (BWL)"
		},
		{
			label = "Broodlord",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 8, 	
				["rogue meleedps"] = 29,
			},
			fullname = "Broodlord Lashlayer (BWL)"
		},
		{
			label = "Ebonroc",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 8,
				["warrior meleedps"] = 29,
			},
			fullname = "Ebonroc (BWL)"
		},
		{
			label = "Firemaw",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 2,
				["warrior meleedps"] = 35,
			},
			fullname = "Firemaw (BWL)"
		},
		{
			label = "Chromaggus",
			values = {
				["warrior tank"] = 4,
				["druid healer"] = 8,
				["shaman healer"] = 2,
				["priest healer"] = 8,
				["rogue meleedps"] = 17,
			},
			fullname = "Chromaggus (BWL)"
		},
		{
			label = "Nefarian",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 8,
				["priest healer"] = 1,
				["rogue meleedps"] = 28,
			},
			fullname = "Nefarian (BWL)"
		}
	}


	mcPresets = {
		{
			label = "Lucifron",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 2,
				["warrior meleedps"] = 35,
			},
			fullname = "Lucifron"
		},
		{
			label = "Magmadar",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 4,
				["mage rangedps"] = 33,
			},
			fullname = "Magmadar"
		},
		{
			label = "Gehennas",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 4,
				["priest healer"] = 1,
				["warrior meleedps"] = 32,
			},
			fullname = "Gehennas"
		},
		{
			label = "Garr",
			values = {
				["warrior tank"] = 8,
				["priest healer"] = 6,
				["druid healer"] = 1,
				["mage rangedps"] = 24,
			},
			fullname = "Garr"
		},
		{
			label = "Geddon",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 2,
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
				["shaman healer"] = 2,
				["priest healer"] = 1,
				["warrior meleedps"] = 34,
			},
			fullname = "Sulfuron Harbinger"
		},
		{
			label = "Golemagg",
			values = {
				["warrior tank"] = 3,
				["shaman healer"] = 1,
				["priest healer"] = 4,
				["mage rangedps"] = 31,
			},
			fullname = "Golemagg"
		},
		{
			label = "Majordomo",
			values = {
				["warrior tank"] = 4,
				["priest healer"] = 4,
				["shaman healer"] = 1,
				["mage rangedps"] = 30,
			},
			fullname = "Majordomo Executus"
		},
		{
			label = "Ragnaros",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 8,
				["warlock rangedps"] = 2,
				["mage rangedps"] = 27,
			},
			fullname = "Ragnaros"
		}
	}

	onyxiaPresets = {
		{
			label = "Onyxia",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 1,
				["priest healer"] = 2,
				["mage rangedps"] = 34,
			},
			fullname = "Onyxia"

		}
	}




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
				["shaman healer"] = 8,
				["warrior meleedps"] = 27,
			},
			fullname = "Bug Trio"
		},
		{
			label = "Sartura",
			values = {
				["warrior tank"] = 1, 
				["priest healer"] = 6,
				["druid healer"] = 2,
				["mage rangedps"] = 30,
			},
			fullname = "Battleguard Sartura"
		},
		{
			label = "Fankriss",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 4,
				["priest healer"] = 3,
				["warrior meleedps"] = 15,
				["mage rangedps"] = 15,
			},
			fullname = "Fankriss the Unyielding"
		},
		{
			label = "Viscidus",
			values = {
				["warrior tank"] = 1,
				["priest healer"] = 3,
				["warrior meleedps"] = 15,
				["mage rangedps"] = 20,
			},
			fullname = "Viscidus"
		},
		{
			label = "Huhuran",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 1,
				["warrior meleedps"] = 36,
			},
			fullname = "Princess Huhuran"
		},
		{
			label = "Twin Emperors",
			values = {
				["warrior tank"] = 4,
				["priest healer"] = 4,
				["shaman healer"] = 3,
				["mage rangedps"] = 14,
				["rogue meleedps"] = 14,
			},
			fullname = "The Twin Emperors"
		},
		{
			label = "Ouro",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 5,
				["priest healer"] = 2,
				["warrior meleedps"] = 30,
			},
			fullname = "Ouro"
		},
		{
			label = "C'Thun",
			values = {
				["shaman healer"] = 8,
				["priest healer"] = 4,
				["rogue meleedps"] = 27,
			},
			fullname = "C'Thun"
		}
	}

	aq20Presets = {
		{
			label = "Kurinnaxx",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 2,
				["mage rangedps"] = 15,
			},
			fullname = "Kurinnaxx"
		},
		{
			label = "General Rajaxx",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 5,
				["rogue meleedps"] = 12,
			},
			fullname = "General Rajaxx"
		},
		{
			label = "Moam",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Moam"
		},
		{
			label = "Ossirian",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 5,
				["rogue meleedps"] = 12,
			},
			fullname = "Ossirian)"
		},
		{
			label = "Ayamiss",
			values = {
				["warrior tank"] = 2, 
				["shaman healer"] = 3,
				["priest healer"] = 2,
				["mage rangedps"] = 14,
			},
			fullname = "Ayamiss the Hunter)"
		},
		{
			label = "Buru",
			values = {
				["warrior tank"] = 2, 
				["priest healer"] = 2,
				["mage rangedps"] = 15,
			},
			fullname = "Buru the Gorger"
		}
	}


	ZGPresets = {
		{
			label = "Jeklik",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Jeklik"
		},
		{
			label = "Venoxis",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 2,
				["mage rangedps"] = 15,
			},
			fullname = "Venoxis"
		},
		{
			label = "Mar'li",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Mar'li"
		},
		{
			label = "Mandokir",
			values = {
				["warrior tank"] = 2,
				["priest healer"] = 7,
				["mage rangedps"] = 10,
			},
			fullname = "Mandokir"
		},
		{
			label = "Thekal",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 2,
				["warrior meleedps"] = 15,
			},
			fullname = "Thekal"
		},
		{
			label = "Arlokk",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 4,
				["warrior meleedps"] = 14,
			},
			fullname = "Arlokk"
		},
		{
			label = "Jin'do",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 5,
				["warrior meleedps"] = 12,
			},
			fullname = "Jin'do"
		},
		{
			label = "Hakkar",
			values = {
				["warrior tank"] = 2,
				["shaman healer"] = 5,
				["rogue meleedps"] = 12,
			},
			fullname = "Hakkar"
		},
	}


	otherPresets = {

		{
			label = "Melee group",
			values = {
				["warrior tank"] = 4,
				["warrior meleedps"] = 18,
				["rogue meleedps"] = 13,
				["shaman healer"] = 4,
			},
			fullname = "Melee group."
		},
		{
			label = "Warrior group",
			values = {
				["warrior tank"] = 2,
				["warrior meleedps"] = 35,
				["rogue meleedps"] = 0,
				["shaman healer"] = 2,
			},
			fullname = "Warrior group"
		},		
		{
			label = "Mage group",
			values = {
				["warrior tank"] = 4,
				["mage rangedps"] = 30,
				["priest healer"] = 5,
			},
			fullname = "Mage group"
		},
	}
    regenerateTooltips()
    end
end
--------------------------------------------------------------------------------------------
--------------------------dont edit below  this line----------------------------------------
--------------------------------------------------------------------------------------------


local function CheckFaction()
    local factionName, factionGroup = UnitFactionGroup("player")
    SetFactionPresets(factionGroup)


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

SLASH_CHECKFACTION1 = "/checkfaction"
SlashCmdList["CHECKFACTION"] = function()
    CheckFaction()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    CheckFaction() 
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
	if not factionGroup then
		CheckFaction() 
	end
end)



naxxramasPresets = {}
bwlPresets = {}
mcPresets = {}
onyxiaPresets = {}
aq40Presets = {}
aq20Presets = {}
ZGPresets = {}
otherPresets = {}