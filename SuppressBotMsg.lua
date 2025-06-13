function SuppressBotMsg()

	if FillRaidSuppressBotMsg == nil then
		FillRaidSuppressBotMsg = {}
	end


	if not FillRaidSuppressBotMsg.messagesToHide then
		FillRaidSuppressBotMsg.messagesToHide = {
			["has come online."] = 0,
			["has gone offline."] = 0,
			["New party bot added."] = 0,
			["All party bots are casting AoE spells at"] = 10,
			["All party bots are now attacking"] = 60,
			["coming to your position."] = 60,
			["has joined the raid group"] = 60,
			["joins the party."] = 60,
			["All party bots unpaused."] = 60,
			["DPS will join in 30 seconds!"] = 60,
			["unpaused"] = 60,
			["staying."] = 60,
			["has left the raid group"] = 60,
			["All bots are moving."] = 60,
			["is moving"] = 60,
			["No valid target"] = 0,
		}

		QueueDebugMessage("INFO: Loaded default Suppress message settings.", "debuginfo")
	else
		QueueDebugMessage("INFO: Loaded saved Suppress message settings from SavedVariables.", "debuginfo")
	end
end
local SuppressBotMsgLoadOnEventFrame = CreateFrame("Frame")
SuppressBotMsgLoadOnEventFrame:RegisterEvent("PLAYER_LOGIN")
SuppressBotMsgLoadOnEventFrame:SetScript("OnEvent", function()
    SuppressBotMsg()
end)