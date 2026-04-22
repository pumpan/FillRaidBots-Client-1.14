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

local function clonePresetValues(values)
    local copy = {}

    if not values then
        return copy
    end

    for role, count in pairs(values) do
        copy[role] = count
    end

    return copy
end

local function applyVipValuesToPresetList(presetList)
    if not presetList then
        return
    end

    for _, preset in ipairs(presetList) do
        if preset.values and not preset.vipValues then
            preset.vipValues = clonePresetValues(preset.values)
        end
    end
end


local function regenerateTooltips()
    local presetTables = {naxxramasPresets, bwlPresets, mcPresets, onyxiaPresets, aq40Presets, aq20Presets, ZGPresets, otherPresets}
    local useVip = FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.useVipPresets

    for _, presets in ipairs(presetTables) do
        for _, preset in ipairs(presets) do
            local name = preset.fullname or preset.label
            local tooltipValues = preset.values

            if useVip and preset.vipValues then
                tooltipValues = preset.vipValues
            end

            preset.tooltip = name .. " (" .. generateTooltip(tooltipValues) .. ")"
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

local function clonePresetValues(values)
    local copy = {}

    if not values then
        return copy
    end

    for role, count in pairs(values) do
        copy[role] = count
    end

    return copy
end

local function applyVipValuesToPresetList(presetList)
    if not presetList then
        return
    end

    for _, preset in ipairs(presetList) do
        if preset.values and not preset.vipValues then
            preset.vipValues = clonePresetValues(preset.values)
        end
    end
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
    local useVip = FillRaidBotsSavedSettings and FillRaidBotsSavedSettings.useVipPresets

    for _, presets in ipairs(presetTables) do
        for _, preset in ipairs(presets) do
            local name = preset.fullname or preset.label
            local tooltipValues = preset.values

            if useVip and preset.vipValues then
                tooltipValues = preset.vipValues
            end

            preset.tooltip = name .. " (" .. generateTooltip(tooltipValues) .. ")"
        end
    end
end




local FILLRAID_PRESET_DATA_VERSION = 2

local function EnsurePresetMigrationMeta()
    if not FillRaidBotsSavedSettings then
        FillRaidBotsSavedSettings = {}
    end

    if FillRaidBotsSavedSettings.presetDataVersion == nil then
        FillRaidBotsSavedSettings.presetDataVersion = 0
    end
end

local function GetPresetDataVersion()
    EnsurePresetMigrationMeta()
    return FillRaidBotsSavedSettings.presetDataVersion or 0
end

local function SetPresetDataVersion(version)
    EnsurePresetMigrationMeta()
    FillRaidBotsSavedSettings.presetDataVersion = version
end

local function CloneTableShallow(source)
    local copy = {}
    local key, value

    if type(source) ~= "table" then
        return copy
    end

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

local function EnsurePresetDefaults(preset)
    local changed = false

    if type(preset) ~= "table" then
        return false
    end

    if preset.values == nil or type(preset.values) ~= "table" then
        preset.values = {}
        changed = true
    end

    if preset.vipValues == nil and type(preset.values) == "table" then
        preset.vipValues = CloneTableShallow(preset.values)
        changed = true
    end

    return changed
end

local function MigratePresetList(presetList, migratePresetFunc)
    local changed = false
    local i
    local preset

    if type(presetList) ~= "table" then
        return false
    end

    for i = 1, table.getn(presetList) do
        preset = presetList[i]
        if type(preset) == "table" then
            if EnsurePresetDefaults(preset) then
                changed = true
            end

            if migratePresetFunc and migratePresetFunc(preset) then
                changed = true
            end
        end
    end

    return changed
end

local function MigrateFactionPresetBuckets(factionData, migratePresetFunc)
    local changed = false

    if type(factionData) ~= "table" then
        return false
    end

    if MigratePresetList(factionData.naxxramasPresets, migratePresetFunc) then changed = true end
    if MigratePresetList(factionData.bwlPresets, migratePresetFunc) then changed = true end
    if MigratePresetList(factionData.mcPresets, migratePresetFunc) then changed = true end
    if MigratePresetList(factionData.onyxiaPresets, migratePresetFunc) then changed = true end
    if MigratePresetList(factionData.aq40Presets, migratePresetFunc) then changed = true end
    if MigratePresetList(factionData.aq20Presets, migratePresetFunc) then changed = true end
    if MigratePresetList(factionData.ZGPresets, migratePresetFunc) then changed = true end
    if MigratePresetList(factionData.otherPresets, migratePresetFunc) then changed = true end

    return changed
end

local function MigrateAllFactionPresets(migratePresetFunc)
    local changed = false
    local factionName, factionData

    if type(FillRaidPresets) ~= "table" then
        return false
    end

    for factionName, factionData in pairs(FillRaidPresets) do
        if MigrateFactionPresetBuckets(factionData, migratePresetFunc) then
            changed = true
        end
    end

    return changed
end

local OLD_FULLNAME_MAP = {
    ["AbominationWing PatchWerk"] = "Patchwerk",
    ["AbominationWing Grobbulus"] = "Grobbulus",
    ["AbominationWing Gluth"] = "Gluth",
    ["AbominationWing Thaddius"] = "Thaddius",
    ["4 Horsemen"] = "The Four Horsemen",
    ["Frostwyrm Lair Sapphiron"] = "Sapphiron",
    ["Frostwyrm Lair Kel'Thuzad"] = "Kel'Thuzad",
    ["Golemagg"] = "Golemagg the Incinerator",
    ["Golemagg the incinerator"] = "Golemagg the Incinerator",
    ["Ossirian"] = "Ossirian the Unscarred",
    ["Melee group."] = "Melee group",
    ["Bug Trio (Princess Yauj, Vem, Lord Kri)"] = "Bug Trio",
}

local function MigrationV1_FixOldFullnames()
    return MigrateAllFactionPresets(function(preset)
        local newName

        if not preset.fullname then
            return false
        end

        newName = OLD_FULLNAME_MAP[preset.fullname]
        if newName and newName ~= preset.fullname then
            preset.fullname = newName
            return true
        end

        return false
    end)
end

local function MigrationV2_NormalizeBossesField()
    return MigrateAllFactionPresets(function(preset)
        if preset.bosses ~= nil and type(preset.bosses) ~= "table" then
            preset.bosses = { tostring(preset.bosses) }
            return true
        end

        return false
    end)
end

local function RunPresetMigrations()
    local currentVersion
    local changed = false

    EnsurePresetMigrationMeta()

    if type(FillRaidPresets) ~= "table" then
        FillRaidPresets = {}
    end

    currentVersion = GetPresetDataVersion()

    if currentVersion < 1 then
        if MigrationV1_FixOldFullnames() then
            changed = true
        end
        SetPresetDataVersion(1)
        currentVersion = 1
    end

    if currentVersion < 2 then
        if MigrationV2_NormalizeBossesField() then
            changed = true
        end
        SetPresetDataVersion(2)
        currentVersion = 2
    end

    if changed and QueueDebugMessage then
        QueueDebugMessage("INFO: Preset SavedVariables migrated to version " .. currentVersion, "debuginfo")
    end

    return changed
end

-------------------------------------------------------

-------------------------------------------------------
local function SetFactionPresets(factionName, factionGroup)
    DEFAULT_CHAT_FRAME:AddMessage("Your faction: " .. factionGroup)

   
    if FillRaidPresets == nil then
        FillRaidPresets = {}
    end

    RunPresetMigrations()

   
    if not FillRaidPresets[factionName] then
        DEFAULT_CHAT_FRAME:AddMessage("No saved presets found for " .. factionName .. ". Loading default presets...")


        FillRaidPresets[factionName] = {
			naxxramasPresets = {
				{
					label = "PatchW",
					values = {
					["warrior tank"] = factionName == "Horde" and 6 or 7,
					["warrior meleedps"] = factionName == "Alliance" and 10 or nil,
					["rogue meleedps"] = factionName == "Horde" and 23 or 12,
					["paladin healer"] = factionName == "Alliance" and 6 or nil,
					["priest healer"] = factionName == "Horde" and 10 or 2,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					},
					vipValues = {
					["warrior tank"] = factionName == "Horde" and 7 or 1,
					["warrior meleedps"] = 10,
					["rogue meleedps"] = 12,
					["paladin healer"] = factionName == "Alliance" and 6 or nil,
					["shaman healer"] = factionName == "Horde" and 2 or nil,
					["priest healer"] = factionName == "Horde" and 6 or 2,
					["druid healer"] = 2,
					},
					fullname = "Patchwerk"
				},
				{
					label = "GrobB",
					values = {
					["warrior tank"] = factionName == "Horde" and 1 or 2,
					["rogue meleedps"] = factionName == "Horde" and 32 or 29,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 6 or nil,
					["priest healer"] = factionName == "Alliance" and 2 or nil,
					["druid healer"] = factionName == "Alliance" and 1 or nil,
					},
					vipValues = {
					["warrior tank"] = 2,
					["rogue meleedps"] = 29,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["priest healer"] = factionName == "Alliance" and 2 or nil,
					["druid healer"] = factionName == "Alliance" and 1 or nil,
					},
					fullname = "Grobbulus"
				},
				{
					label = "Gluth",
					values = {
					["warrior tank"] = factionName == "Horde" and 6 or 8,
					["rogue meleedps"] = factionName == "Horde" and 25 or 22,
					["mage rangedps"] = factionName == "Alliance" and 1 or nil,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["priest healer"] = factionName == "Horde" and 8 or 2,
					["druid healer"] = factionName == "Alliance" and 1 or nil,
					},
					vipValues = {
					["warrior tank"] = 8,
					["rogue meleedps"] = 22,
					["mage rangedps"] = 1,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 2 or nil,
					["priest healer"] = factionName == "Horde" and 5 or 2,
					["druid healer"] = 1,
					},
					fullname = "Gluth"
				},
				{
					label = "Thadd",
					values = {
					["warrior tank"] = factionName == "Horde" and 2 or 3,
					["rogue meleedps"] = 28,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["priest healer"] = factionName == "Alliance" and 2 or 9,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					},
					vipValues = {
					["warrior tank"] = 3,
					["rogue meleedps"] = factionName == "Horde" and 27 or 28,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["priest healer"] = factionName == "Alliance" and 2 or nil,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					},
					fullname = "Thaddius"
				},
				{
					label = "Razzuv",
					values = {
					["warrior tank"] = factionName == "Horde" and 8 or 10,
					["warrior meleedps"] = factionName == "Horde" and 23 or 10,
					["rogue meleedps"] = factionName == "Alliance" and 10 or nil,
					["paladin healer"] = factionName == "Alliance" and 9 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["druid healer"] = factionName == "Alliance" and 0 or nil,
					},
					vipValues = {
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
					["warrior meleedps"] = factionName == "Horde" and 27 or 26,
					["mage rangedps"] = factionName == "Alliance" and 1 or nil,
					["rogue meleedps"] = factionName == "Alliance" and 0 or nil,
					["paladin healer"] = factionName == "Alliance" and 6 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["priest healer"] = factionName == "Alliance" and 2 or nil,
					["druid healer"] = factionName == "Alliance" and 0 or nil,
					},
					vipValues = {
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
					vipValues = {
					["warrior tank"] = 3,
					["warrior meleedps"] = 35,
					["rogue meleedps"] = 0,
					["paladin healer"] = factionName == "Alliance" and 1 or nil,
					["priest healer"] = factionName == "Horde" and 1 or nil,
					["druid healer"] = 0,
					},
					fullname = "The Four Horsemen"
				},
				{
					label = "Anub'Rekhan",
					values = {
					["warrior tank"] = 3,
					["warrior meleedps"] = factionName == "Alliance" and 25 or nil,
					["mage rangedps"] = factionName == "Alliance" and 0 or nil,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 5 or nil,
					["rogue meleedps"] = factionName == "Horde" and 28 or 4,
					["priest healer"] = factionName == "Horde" and 3 or 1,
					["druid healer"] = factionName == "Alliance" and 1 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 4 or 3,
					["mage rangedps"] = 25,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["rogue meleedps"] = factionName == "Alliance" and 0 or nil,
					["priest healer"] = factionName == "Horde" and 6 or 2,
					["druid healer"] = 4,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 8 or 9,
					["mage rangedps"] = factionName == "Horde" and 6 or 15,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["rogue meleedps"] = factionName == "Horde" and 17 or 3,
					["priest healer"] = factionName == "Horde" and 4 or 2,
					["priest rangedps"] = factionName == "Alliance" and 3 or nil,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 4 or 6,
					["mage rangedps"] = 16,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["rogue meleedps"] = factionName == "Horde" and 11 or 9,
					["priest healer"] = factionName == "Horde" and 4 or 0,
					["druid healer"] = 4,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 2 or 5,
					["warrior meleedps"] = factionName == "Horde" and 29 or 10,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["rogue meleedps"] = factionName == "Alliance" and 16 or nil,
					["priest healer"] = factionName == "Alliance" and 2 or nil,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 6 or 4,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["shaman healer"] = factionName == "Horde" and 1 or nil,
					["rogue meleedps"] = factionName == "Horde" and 32 or 33,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 3 or 4,
					["warrior meleedps"] = factionName == "Alliance" and 8 or nil,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["rogue meleedps"] = factionName == "Horde" and 28 or 17,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["druid healer"] = 2,
					},
					vipValues = {
					["warrior tank"] = factionName == "Horde" and 10 or 4,
					["warrior meleedps"] = factionName == "Horde" and 6 or 8,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 3 or nil,
					["rogue meleedps"] = 17,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["druid healer"] = 2,
					},
					fullname = "Sapphiron"
				},
				{
					label = "Kel'Thuzad",
					values = {
					["warrior tank"] = factionName == "Horde" and 8 or 10,
					["mage rangedps"] = 3,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 3 or nil,
					["rogue meleedps"] = factionName == "Horde" and 15 or 14,
					["priest healer"] = factionName == "Horde" and 8 or 4,
					["druid healer"] = factionName == "Horde" and 2 or nil,
					},
					vipValues = {
					["warrior tank"] = factionName == "Horde" and 8 or 10,
					["mage rangedps"] = 3,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["rogue meleedps"] = factionName == "Horde" and 16 or 14,
					["priest healer"] = factionName == "Horde" and 6 or 4,
					},
					fullname = "Kel'Thuzad"
				},
			},
			bwlPresets = {
				{
					label = "Razorgore",
					values = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["mage rangedps"] = 29,
					["druid healer"] = factionName == "Horde" and 4 or nil,
					},
					vipValues = {
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
					["warrior meleedps"] = factionName == "Alliance" and 10 or nil,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["rogue meleedps"] = factionName == "Horde" and 29 or 17,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 6 or nil,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					["rogue meleedps"] = factionName == "Horde" and 28 or 29,
					["priest healer"] = factionName == "Horde" and 8 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 4 or 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["warrior meleedps"] = factionName == "Horde" and 31 or 35,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 4 or 2,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["warrior meleedps"] = factionName == "Horde" and 31 or 29,
					},
					vipValues = {
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
					vipValues = {
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
					["rogue meleedps"] = factionName == "Horde" and 23 or 17,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["rogue meleedps"] = factionName == "Alliance" and 29 or 28,
					},
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["priest healer"] = factionName == "Horde" and 1 or nil,
					["rogue meleedps"] = factionName == "Alliance" and 29 or 28,
					},
					fullname = "Nefarian"
				},
			},
			mcPresets = {
				{
					label = "Lucifron",
					values = {
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["warrior meleedps"] = factionName == "Horde" and 32 or 35,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					},
					vipValues = {
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["warrior meleedps"] = factionName == "Horde" and 32 or 35,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					},
					fullname = "Lucifron"
				},
				{
					label = "Magmadar",
					values = {
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["mage rangedps"] = factionName == "Horde" and 30 or 33,
					},
					vipValues = {
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["mage rangedps"] = factionName == "Horde" and 30 or 33,
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
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 10 or 8,
					["paladin healer"] = factionName == "Alliance" and 6 or nil,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["druid healer"] = factionName == "Alliance" and 1 or nil,
					["mage rangedps"] = factionName == "Horde" and 23 or 24,
					},
					vipValues = {
					["warrior tank"] = factionName == "Horde" and 10 or 8,
					["paladin healer"] = factionName == "Alliance" and 6 or nil,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["druid healer"] = factionName == "Alliance" and 1 or nil,
					["mage rangedps"] = factionName == "Horde" and 23 or 24,
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
					vipValues = {
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
					["mage rangedps"] = factionName == "Alliance" and 37 or nil,
					["warrior meleedps"] = factionName == "Horde" and 37 or nil,
					},
					vipValues = {
					["warrior tank"] = 2,
					["mage rangedps"] = factionName == "Alliance" and 37 or nil,
					["warrior meleedps"] = factionName == "Horde" and 37 or nil,
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
					vipValues = {
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
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["druid healer"] = factionName == "Alliance" and 1 or nil,
					["mage rangedps"] = factionName == "Alliance" and 31 or nil,
					["warrior meleedps"] = factionName == "Horde" and 32 or nil,
					},
					vipValues = {
					["warrior tank"] = 3,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["shaman healer"] = factionName == "Horde" and 1 or nil,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["druid healer"] = 1,
					["mage rangedps"] = 31,
					},
					fullname = "Golemagg the Incinerator"
				},
				{
					label = "Majordomo",
					values = {
					["warrior tank"] = 4,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["mage rangedps"] = 31,
					},
					vipValues = {
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
					["warlock rangedps"] = factionName == "Alliance" and 2 or nil,
					["mage rangedps"] = factionName == "Horde" and 29 or 27,
					},
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["priest healer"] = factionName == "Horde" and 8 or 4,
					["warlock rangedps"] = factionName == "Alliance" and 2 or nil,
					["mage rangedps"] = factionName == "Horde" and 29 or 27,
					},
					fullname = "Ragnaros"
				},
			},
			onyxiaPresets = {
				{
					label = "Onyxia",
					values = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["mage rangedps"] = factionName == "Alliance" and 35 or 33,
					},
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["shaman healer"] = factionName == "Horde" and 1 or nil,
					["priest healer"] = factionName == "Horde" and 2 or nil,
					["mage rangedps"] = factionName == "Alliance" and 35 or 34,
					},
					fullname = "Onyxia",
					bosses = {
						"Onyxia's Lair",
					},
				},
			},
			aq40Presets = {
				{
					label = "Skeram",
					values = {
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["warrior meleedps"] = factionName == "Horde" and 36 or 37,
					},
					vipValues = {
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
					vipValues = {
					["warrior tank"] = 4,
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["warrior meleedps"] = 27,
					},
					fullname = "Bug Trio"
				},
				{
					label = "Sartura",
					values = {
					["warrior tank"] = 1,
					["paladin healer"] = factionName == "Alliance" and 6 or nil,
					["druid healer"] = factionName == "Alliance" and 2 or nil,
					["hunter rangedps"] = 30,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["priest healer"] = factionName == "Horde" and 8 or nil,
					["druid healer"] = factionName == "Alliance" and 3 or nil,
					["warrior meleedps"] = factionName == "Horde" and 28 or 15,
					["mage rangedps"] = factionName == "Alliance" and 15 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 5 or 1,
					["paladin healer"] = factionName == "Alliance" and 3 or nil,
					["warrior meleedps"] = factionName == "Alliance" and 15 or nil,
					["mage rangedps"] = factionName == "Horde" and 16 or 20,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["rogue meleedps"] = factionName == "Horde" and 10 or nil,
					},
					vipValues = {
					["warrior tank"] = factionName == "Horde" and 5 or 1,
					["paladin healer"] = factionName == "Alliance" and 3 or nil,
					["warrior meleedps"] = factionName == "Alliance" and 15 or nil,
					["mage rangedps"] = factionName == "Horde" and 16 or 20,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["rogue meleedps"] = factionName == "Horde" and 10 or nil,
					},
					fullname = "Viscidus"
				},
				{
					label = "Huhuran",
					values = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 1 or nil,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["rogue meleedps"] = factionName == "Horde" and 31 or 10,
					["warrior meleedps"] = factionName == "Alliance" and 26 or nil,
					},
					vipValues = {
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
					["warrior tank"] = factionName == "Horde" and 9 or 6,
					["paladin healer"] = factionName == "Alliance" and 9 or nil,
					["priest healer"] = factionName == "Horde" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 3 or nil,
					["druid healer"] = factionName == "Horde" and 3 or 0,
					["rogue meleedps"] = factionName == "Horde" and 19 or 24,
					},
					vipValues = {
					["warrior tank"] = 6,
					["paladin healer"] = factionName == "Alliance" and 9 or nil,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["shaman healer"] = factionName == "Horde" and 3 or nil,
					["druid healer"] = 0,
					["rogue meleedps"] = 24,
					["mage rangedps"] = factionName == "Horde" and 14 or nil,
					},
					fullname = "The Twin Emperors"
				},
				{
					label = "Ouro",
					values = {
					["warrior tank"] = factionName == "Horde" and 3 or 2,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["priest healer"] = factionName == "Horde" and 6 or nil,
					["warrior meleedps"] = factionName == "Alliance" and 32 or nil,
					["rogue meleedps"] = factionName == "Horde" and 30 or nil,
					},
					vipValues = {
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
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["priest healer"] = factionName == "Horde" and 2 or nil,
					["rogue meleedps"] = factionName == "Alliance" and 31 or nil,
					["warrior meleedps"] = factionName == "Horde" and 33 or nil,
					},
					vipValues = {
					["paladin healer"] = factionName == "Alliance" and 8 or nil,
					["shaman healer"] = factionName == "Horde" and 8 or nil,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["rogue meleedps"] = factionName == "Alliance" and 31 or 27,
					},
					fullname = "C'Thun"
				},
			},
			aq20Presets = {
				{
					label = "Kurinnaxx",
					values = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["priest healer"] = factionName == "Horde" and 3 or nil,
					["mage rangedps"] = factionName == "Horde" and 14 or 15,
					},
					vipValues = {
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
					vipValues = {
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
					vipValues = {
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
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["shaman healer"] = factionName == "Horde" and 5 or nil,
					["rogue meleedps"] = 12,
					},
					fullname = "Ossirian the Unscarred"
				},
				{
					label = "Ayamiss",
					values = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 3 or nil,
					["shaman healer"] = factionName == "Horde" and 3 or nil,
					["priest healer"] = 2,
					["mage rangedps"] = factionName == "Horde" and 14 or 12,
					},
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 3 or nil,
					["shaman healer"] = factionName == "Horde" and 3 or nil,
					["priest healer"] = 2,
					["mage rangedps"] = factionName == "Horde" and 14 or 12,
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
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["priest healer"] = factionName == "Horde" and 2 or nil,
					["mage rangedps"] = 15,
					},
					fullname = "Buru the Gorger"
				},
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
					vipValues = {
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
					["priest healer"] = factionName == "Horde" and 3 or nil,
					["mage rangedps"] = factionName == "Horde" and 14 or 15,
					},
					vipValues = {
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
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["warrior meleedps"] = factionName == "Horde" and 13 or 15,
					},
					vipValues = {
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
					["priest healer"] = factionName == "Horde" and 4 or nil,
					["mage rangedps"] = factionName == "Horde" and 13 or 10,
					},
					vipValues = {
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
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["warrior meleedps"] = factionName == "Horde" and 13 or 15,
					},
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					["warrior meleedps"] = factionName == "Horde" and 13 or 15,
					},
					fullname = "High Priest Thekal"
				},
				{
					label = "Arlokk",
					values = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["warrior meleedps"] = 13,
					["priest healer"] = factionName == "Horde" and 4 or nil,
					},
					vipValues = {
					["warrior tank"] = 2,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["warrior meleedps"] = 13,
					["priest healer"] = factionName == "Horde" and 4 or nil,
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
					vipValues = {
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
					vipValues = {
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
					vipValues = {
					["warrior tank"] = 4,
					["warrior meleedps"] = 18,
					["rogue meleedps"] = 13,
					["paladin healer"] = factionName == "Alliance" and 4 or nil,
					["shaman healer"] = factionName == "Horde" and 4 or nil,
					},
					fullname = "Melee group"
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
					vipValues = {
					["warrior tank"] = 2,
					["warrior meleedps"] = 35,
					["rogue meleedps"] = 0,
					["paladin healer"] = factionName == "Alliance" and 2 or nil,
					["shaman healer"] = factionName == "Horde" and 2 or nil,
					},
					fullname = "Warrior group",
					bosses = {
						"Molten Core",
						"Blackwing Lair",
						"Temple of Ahn'Qiraj",
						"Naxxramas",
						"Onyxia's Lair",
					},
				},
				{
					label = "Mage group",
					values = {
					["warrior tank"] = 4,
					["mage rangedps"] = 30,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["priest healer"] = factionName == "Horde" and 5 or nil,
					},
					vipValues = {
					["warrior tank"] = 4,
					["mage rangedps"] = 30,
					["paladin healer"] = factionName == "Alliance" and 5 or nil,
					["priest healer"] = factionName == "Horde" and 5 or nil,
					},
					fullname = "Mage group",
					bosses = {
						"Molten Core",
						"Blackwing Lair",
						"Temple of Ahn'Qiraj",
						"Naxxramas",
						"Onyxia's Lair",
					},
				},
			}
		}


        RunPresetMigrations()
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

	applyVipValuesToPresetList(FillRaidPresets[factionName].naxxramasPresets)
	applyVipValuesToPresetList(FillRaidPresets[factionName].bwlPresets)
	applyVipValuesToPresetList(FillRaidPresets[factionName].mcPresets)
	applyVipValuesToPresetList(FillRaidPresets[factionName].onyxiaPresets)
	applyVipValuesToPresetList(FillRaidPresets[factionName].aq40Presets)
	applyVipValuesToPresetList(FillRaidPresets[factionName].aq20Presets)
	applyVipValuesToPresetList(FillRaidPresets[factionName].ZGPresets)
	applyVipValuesToPresetList(FillRaidPresets[factionName].otherPresets)
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
SLASH_CHECKFACTION1 = "/checkfaction"
SlashCmdList["CHECKFACTION"] = function()
    CheckFaction()
end

local factionEventFrame = CreateFrame("Frame")
factionEventFrame:RegisterEvent("PLAYER_LOGIN")
factionEventFrame:SetScript("OnEvent", function()
    CheckFaction()
end)
