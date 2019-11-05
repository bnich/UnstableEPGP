UnstableEPGP = LibStub("AceAddon-3.0"):NewAddon("UnstableEPGP", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0", "AceSerializer-3.0")
local UnstableEPGP = UnstableEPGP
local VERSION = GetAddOnMetadata('UnstableEPGP', 'Version')
local updateNotified = false
local ProtocolVersion = 110
local ScrollingTable = LibStub("ScrollingTable")
local GP = LibStub("LibGearPoints-1.0")
local ItemUtils = LibStub("LibItemUtils-1.0")
local SmoothBar = LibStub("LibSmoothStatusBar-1.0")
local ArtTexturePaths = LibStub("ArtTexturePaths-1.0")
local icon = LibStub("LibDBIcon-1.0")

-- Create minimap button using LibDBIcon
local TT_H_1, TT_H_2 = "|cff00FF00".."Unstable EPGP".."|r", string.format("|cffFFFFFF%s|r", VERSION)
local TT_ENTRY = "|cFFCFCFCF%s:|r %s" --|cffFFFFFF%s|r"
local minimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("UnstableEPGP", {
	type = "data source",
	text = "UnstableEPGP",
	icon = "Interface\\Icons\\INV_capybara",
	OnClick = function(self, button)
		if button == "RightButton" then
			DEFAULT_CHAT_FRAME.editBox:SetText("/un test") ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		else
			DEFAULT_CHAT_FRAME.editBox:SetText("/epgp") ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddDoubleLine(TT_H_1, TT_H_2);
		tooltip:AddLine(format(TT_ENTRY, "Left Click", "Open Standings"))
		tooltip:AddLine(format(TT_ENTRY, "Right Click", "Test Loot Window"))
	end,
})

-- Cache some functions locally for quicker access
local mathRandom	= math.random
local mathFloor 	= math.floor

function UnstableEPGP:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("UnstableEPGPDB")
	self:RegisterChatCommand("un", "SlashProcessor")

	self.recycledFrames = {}
	self.msgCache = {}
	self.lootTable = {}
	self.lootCache = {}
	self.lootHist = {}
	self.frameCount = 0
	self.frameNum = 1
	self.currentTab = 0
	self.autoAnnounce = true
		
	self.awardPopupMenu = CreateFrame("Frame", "AwardPopupMenu", UIParent, "UIDropDownMenuTemplate")
	
	self.db:RegisterDefaults(
	{	profile = {
			buttonNum			= 4,
			button1				= "Mainspec",
			button1_GP			= "",
			button1_perc		= false,
			button1_color		= "00FF34",
			button2				= "Minor Upgrade",
			button2_GP			= "",
			button2_perc		= false,
			button2_color		= "ABD473",
			button3				= "Raid Offspec",
			button3_GP			= "",
			button3_perc		= false,
			button3_color		= "FF7D0A",
			button4				= "Greed",
			button4_GP			= "",
			button4_perc		= false,
			button4_color		= "C41F3B",
			button5				= "Button 5",
			button5_GP			= "",
			button5_perc		= false,
			button5_color		= "FFFFFF",
			button6				= "Button 6",
			button6_GP			= "",
			button6_perc		= false,
			button6_color		= "FFFFFF",
			button7				= "Button 7",
			button7_GP			= "",
			button7_perc		= false,
			button7_color		= "FFFFFF",

			tabbedFrame			= "yes",
			announceButton		= 2,
			lootThreshold		= 4,
			announceConfirm		= false,
			allowReselect		= true,
			autoAdvance			= true,
			autoCancel			= false,
			hideResponses		= true,
			lootTimeout			= 90,
			useUnstableEPGP		= true,
			
			minimap				= { hide = false, minimapPos = 218}, 
		}
	})

	self.equipSlot = {
		["INVTYPE_HEAD"]			= {1},
		["INVTYPE_NECK"]			= {2},
		["INVTYPE_SHOULDER"]		= {3},
		["INVTYPE_BODY"]			= {4},
		["INVTYPE_CHEST"]			= {5},
		["INVTYPE_ROBE"]			= {5},
		["INVTYPE_WAIST"]			= {6},
		["INVTYPE_LEGS"]			= {7},
		["INVTYPE_FEET"]			= {8},
		["INVTYPE_WRIST"]			= {9},
		["INVTYPE_HAND"]			= {10},
		["INVTYPE_FINGER"]			= {11,12},
		["INVTYPE_TRINKET"]			= {13,14},
		["INVTYPE_CLOAK"]			= {15},
		["INVTYPE_WEAPON"]			= {16,17},
		["INVTYPE_SHIELD"]			= {17},
		["INVTYPE_2HWEAPON"]		= {16},
		["INVTYPE_WEAPONMAINHAND"]	= {16},
		["INVTYPE_WEAPONOFFHAND"]	= {17},
		["INVTYPE_HOLDABLE"]		= {17},
		["INVTYPE_RANGED"]			= {18},
		["INVTYPE_THROWN"]			= {18},
		["INVTYPE_RANGEDRIGHT"]		= {18},
		["INVTYPE_RELIC"]			= {18},
		["INVTYPE_TABARD"]			= {19},		
	}
	
	self.RESPONSE = {
		["waiting"]		= {["text"] = "02 Waiting...",		["color"] = "FFFFFF",	["message"] = ""},
		["outdated"]	= {["text"] = "03 Outdated",		["color"] = "999999",	["message"] = ""},		
		["selecting"]	= {["text"] = "04 Selecting...",	["color"] = "FFFFFF",	["message"] = ""},
		["selected"]	= {["text"] = "05 Selected",		["color"] = "C79C6E",	["message"] = ""},
		["winner"]		= {["text"] = "06 WINNER",			["color"] = "FFF569",	["message"] = "%s was awarded %s for %s GP."},
		["disenchant"]	= {["text"] = "06 Disenchanted",	["color"] = "69CCF0",	["message"] = "%s received %s for disenchantment."},
		["bank"]		= {["text"] = "06 Guild Bank",		["color"] = "69CCF0",	["message"] = "%s received %s for deposit to guild bank."},
		["free"]		= {["text"] = "06 FREE",			["color"] = "C79C6E",	["message"] = "%s received %s for 0 GP."},
		["pass"]		= {["text"] = "21 Pass",			["color"] = "999999",	["message"] = ""},
		["autopass"]	= {["text"] = "22 Auto-Pass",		["color"] = "999999",	["message"] = ""},
		["n/a"] 		= {["text"] = "22 Not Eligible",	["color"] = "999999",	["message"] = ""},
	}
	
	self.scrollFrameCols = {
		{["name"] = "Candidate",	["width"] = 75,	["align"] = "LEFT",
			["DoCellUpdate"] = function(...) UnstableEPGP:DoCellUpdate(...) end},
		{["name"] = "ilvl",			["width"] = 30,	["align"] = "LEFT"},	
		{["name"] = "Response",		["width"] = 88,	["align"] = "LEFT",		["defaultsort"] = "dsc",	["sort"] = "dsc",	["sortnext"] = 4,
			["DoCellUpdate"] = function(...) UnstableEPGP:DoCellUpdate(...) end},	
		{["name"] = " PR",			["width"] = 45,	["align"] = "LEFT",		["defaultsort"] = "asc",
			["DoCellUpdate"] = function(...) UnstableEPGP:DoCellUpdate(...) end},
		{["name"] = "Roll",			["width"] = 30,	["align"] = "LEFT"},
		{["name"] = "",				["width"] = 21,	["align"] = "LEFT",
			["DoCellUpdate"] = function(...) UnstableEPGP:DoCellUpdate(...) end},
		{["name"] = "",				["width"] = 21,	["align"] = "LEFT",
			["DoCellUpdate"] = function(...) UnstableEPGP:DoCellUpdate(...) end},
	}

	StaticPopupDialogs["CloseTabbedFrame"] = {
		text = "Are you sure you want to close ALL tabs?",
		button1 = "Yes",
		button2 = "Cancel",
		OnAccept = function(self, data) UnstableEPGP:CloseTabbedFrame(data) end,
		timeout = 0,
		whileDead	= true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["AutoAnnounce"] = {
		text = "There are %s eligible items based on\nyour loot threshold settings.\nWould you like to announce ALL items?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function() self.autoAnnounce = true UnstableEPGP:OPEN_MASTER_LOOT_LIST(true) end,
		OnCancel = function() self.autoAnnounce = false UnstableEPGP:OPEN_MASTER_LOOT_LIST(true) end,
		timeout = 0,
		whileDead	= true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["NewMasterLooter"] = {
		text = "You are Master Looter. Would you like to use \"UnstableEPGP\" to distribute loot?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function() UnstableEPGP.db.profile.useUnstableEPGP = true UnstableEPGP:DisableEPGPPopup() end,
		OnCancel = function() UnstableEPGP.db.profile.useUnstableEPGP = false end,
		timeout = 0,
		whileDead	= true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	
	-- Warning if we're in a guild and we can edit officer notes but EPGP is not installed.
    if IsInGuild() and CanEditOfficerNote() and not EPGP then
        StaticPopupDialogs["EPGP_NotInstalled"] = {
            text = "UnstableEPGP Notice! \r\n\r\n|cFFFF8080WARNING:|r You have \"UnstableEPGP\" enabled without the EPGP addon. \r\n\r\nPlease make sure you have EPGP installed and enabled. If you fail to do so, no GP can be awarded for looted items.",
            button1 = OKAY,
            OnAccept = function() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
			preferredIndex = 3
        }
        StaticPopup_Show("EPGP_NotInstalled")
    end
	
	-- Registered Events
	self:RegisterEvent("OPEN_MASTER_LOOT_LIST")
    --self:RegisterEvent("UPDATE_MASTER_LOOT_LIST")
	self:RegisterEvent("LOOT_OPENED")
	self:RegisterEvent("LOOT_CLOSED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "GroupUpdate")
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", "GroupUpdate")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "GroupUpdate")
	self:RegisterEvent("UNIT_NAME_UPDATE", "GroupUpdate")
	
	-- Register Communications
	self:RegisterComm("UN_NewItem")
	self:RegisterComm("UN_Acknowledge")
	self:RegisterComm("UN_Response")
	self:RegisterComm("UN_Update")
	self:RegisterComm("UN_Award")	
	self:RegisterComm("UN_Close")
	self:RegisterComm("UN_Version")		
	
	-- Hooks
	self:Hook("GiveMasterLoot", true)

	-- Modify OnClick script of loot buttons to allow for alt + click
	for slot = 1, LOOTFRAME_NUMBUTTONS do
		local button = getglobal("LootButton"..slot)
        if button and not button.originalScript then
			button.originalScript = button:GetScript("OnClick")
			button:SetScript("OnClick", function(self, ...)
				if IsAltKeyDown() then
					return LootButton_OnClick(self, ...)
				else
					return self.originalScript(self, ...)
				end
			end)
		end
	end
	
	--register minimap button
	icon:Register("UnstableEPGP", minimapLDB, UnstableEPGP.db.profile.minimap) 
	
end

function UnstableEPGP:OnEnable()
	if self.currentML and UnitIsUnit(self.currentML, "player") then
		self:ScheduleTimer("DisableEPGPPopup", 2)
	end

    if EPGP and EPGP.RegisterCallback then
        EPGP.RegisterCallback(self, "StandingsChanged")
    end
	
	self:SendMessage("UN_Version", "GUILD", "getversion")
end

function UnstableEPGP:OnDisable()
	self:Print("Addon Disabled")
end

function UnstableEPGP:SlashProcessor(input)
	local command, arg1, arg2 = self:GetArgs(input, 3, 1)
	-- Changes all input to lowercase.
	if command then
		command = command:lower()
		if command == "test" then
			if self.currentML and UnitIsUnit(self.currentML, "player") or not self.groupType then
				self:TestLoot()
			else
				self:Print(format("The [%s] command is only available to Master Looter.", command))
			end
		elseif command == "config" or command == "c" or command == "options" or command == "o" then
			-- Due to a Blizzard bug, you have to call this twice to open the correct panel the first time
			InterfaceOptionsFrame_OpenToCategory("UnstableEPGP")
			InterfaceOptionsFrame_OpenToCategory("UnstableEPGP")			
		elseif command == "announce" or command == "add" then
			-- Only Master Looter can manually announce items
			if self.currentML and UnitIsUnit(self.currentML, "player") or not self.groupType then
				if arg1 and arg1:match("Hitem:.+|h%[(.-)%]|h|r") then
					self:NewLoot(arg1, nil, "manual")
				else
					self:Print(format("Usage: /un %s [lootlink]", command))
				end
			else
				self:Print(format("The [%s] command is only available to Master Looter.", command))
			end
		elseif command == "version" or command == "ver" then
		    updateNotified = false
			-- Displays version of addon from everyone in guild
			self:Print(format("Version: %s", VERSION))
			if self.groupType then
				self:SendMessage("UN_Version", nil, "getversion")
			else
				self:SendMessage("UN_Version", "GUILD", "getversion")
			end
		else
			self:Print("Invalid Command")
		end
	end
end

function UnstableEPGP:TestLoot()
	-- Get test item (item link) from player
	local item = GetInventoryItemLink("player", mathRandom(1, 19))
	while not item do
		item = GetInventoryItemLink("player", mathRandom(1, 19))
	end
	self:NewLoot(item, nil, "test")	
end
	
function UnstableEPGP:NewLoot(item, slot, announceType)
	local gp1, gp2 = GP:GetValue(item)	
	local name, link, quality, ilevel, reqLevel, itemType, itemSubType, maxStack, equipLoc, texture, price = GetItemInfo(item)
	local itemData = {name, link, quality, ilevel, reqLevel, itemType, itemSubType, maxStack, equipLoc, texture, price, announceType, gp1, gp2}

	-- Get Button Data
	local configData = {self.db.profile.lootTimeout, self.db.profile.buttonNum, self.db.profile.allowReselect, self.db.profile.hideResponses}
	for x = 1, 7 do
		tinsert(configData, self.db.profile["button"..x])
		tinsert(configData, self.db.profile["button"..x.."_color"])
	end
	
	-- Get candidate data; structure of [candidateData]: candidate, class, candidate, class, ...
	local candidateData = {}
	if slot then
		for candidateID = 1, 40 do
			if GetMasterLootCandidate(slot, candidateID) then
				local candidate = GetMasterLootCandidate(slot, candidateID)
				local _, class = UnitClass(candidate)
				candidate = self:Disambiguate(candidate)
				tinsert(candidateData, {candidate, class})
			end
		end
	else	
		if self.groupType == "raid" then
			-- Player is in a Raid
			for x = 1, self.groupSize do
				local _, class = UnitClass("raid"..x)
				tinsert(candidateData, {self:Disambiguate(GetUnitName("raid" .. x, true)), class})
			end
		else
			if self.groupType == "party" then
				-- Player is in a Party
				for x = 1, self.groupSize - 1 do
					local _, class = UnitClass("party"..x)
					tinsert(candidateData, {self:Disambiguate(GetUnitName("party" .. x, true)), class})
				end
			end
			local _, class = UnitClass("player")
			tinsert(candidateData, {self:Disambiguate(GetUnitName("player", true)), class})
		end
	end
	self:RegisterLoot(nil, itemData, candidateData, configData, GetUnitName("player", true))
end

function UnstableEPGP:RegisterLoot(itemID, itemData, candidateData, configData, owner)
	-- Get owner class and class color
	local _, ownerClass = UnitClass(owner)
	local ownerColor = RAID_CLASS_COLORS[ownerClass]

	-- Am I eligible for the loot?
	if not self:EligibleCandidate(candidateData) then
		self:Print(format("%s has been announced to your %s, but you were ineligible.", itemData[2], self.groupType))
		return
	end
	
	-- Can I use the item?
	local _, class = UnitClass("player")
	local retOK, eligible = pcall(ItemUtils.ClassCanUse, self, class, itemData[2])
	local lootTimeout = configData[1]
	if retOK and not eligible then
		-- If not eligible for loot, display a message and set timer to zero
		if(self.currentML and UnitIsUnit(self.currentML, "player")) then
		  eligible = true
		else
		  self:Print(format("Auto-Passed: %s (not eligible)", itemData[2]))
		  lootTimeout = 0
		end
	else
		eligible = true
	end

	-- Generate unique itemID, based on time and date.
	if not itemID then
		itemID = date("%Y%m%d:%H%M%S:")..mathRandom(1, 9999)
		while self.lootTable[itemID] do
			itemID = date("%Y%m%d:%H%M%S:")..mathRandom(1, 9999)
		end
	end
	
	-- If loot already exists in table, then quit	
	if self.lootTable[itemID] then
		return
	end

	tinsert(self.lootTable, itemID)
	self.lootTable[itemID] = {
		["name"] 			= itemData[1],		
		["link"] 			= itemData[2],
		["quality"] 		= itemData[3],
		["ilevel"] 			= itemData[4],
		["reqLevel"] 		= itemData[5],
		["type"] 			= itemData[6],
		["subType"] 		= itemData[7],
		["maxStack"] 		= itemData[8],
		["equipLoc"]		= itemData[9],
		["texture"] 		= itemData[10],
		["price"] 			= itemData[11],
		["announceType"]	= itemData[12],
		["gp1"] 			= itemData[13],
		["gp2"] 			= itemData[14],
		["gpCost"]			= itemData[13] or 0,
		["eligible"]		= eligible,
		["owner"]			= owner,
		["ownerColor"]		= ownerColor,
		["lootTimeout"]		= tonumber(lootTimeout),
		["buttonNum"] 		= tonumber(configData[2]),
		["allowReselect"]	= configData[3],
		["hideResponses"]	= configData[4],
		["button1"] 		= configData[5],
		["button1c"]	 	= configData[6],
		["button2"] 		= configData[7],
		["button2c"]		= configData[8],
		["button3"] 		= configData[9],
		["button3c"] 		= configData[10],
		["button4"] 		= configData[11],
		["button4c"] 		= configData[12],
		["button5"] 		= configData[13],
		["button5c"] 		= configData[14],
		["button6"] 		= configData[15],
		["button6c"] 		= configData[16],
		["button7"] 		= configData[17],
		["button7c"] 		= configData[18],
		["candidates"] = {},
		["candidateIndex"] = {},
		["scrollData"] = {}
	}

	-- Register list of candidates and add data to scroll table
	for index = 1, #candidateData do
		local player = candidateData[index][1]
		local PR, EP, GP = self:GetPR(player)
		-- Get class color
		local color = RAID_CLASS_COLORS[candidateData[index][2]]
		-- If no class color, set to default color
		if not color then
			color = {["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0}
		else
			color.a = 1.0
		end
		local rowData = {
			["cols"] 	= { 
				[1] = {["value"] = player, ["color"] = color},
				[3] = {["value"] = self.RESPONSE["waiting"].text},
				[4] = {["value"] = PR}},
			["class"] 		= candidateData[index][2],
			["ep"]			= EP,
			["gp"]			= GP}			
		tinsert(self.lootTable[itemID].scrollData, rowData)
		tinsert(self.lootTable[itemID].candidates, candidateData[index][1])
	end
	-- Invert candidates table so we can lookup keys later
	self.lootTable[itemID].candidateIndex = self:TableInvert(self.lootTable[itemID].candidates)

	-- Open loot window
	self:ShowLoot(itemID)
	-- Announce loot to candidates (this action should only be performed by the distributor/lootmaster)
	if UnitIsUnit(owner, "player") then
		local playerData = self:GetPlayerData(itemID)
		-- Store raw data so we can re-announce to candidates later
		self.lootTable[itemID].itemData = itemData
		self.lootTable[itemID].candidateData = candidateData
		self.lootTable[itemID].configData = configData
		-- Send "New Loot" message to candidates
		self:SendMessage("UN_NewItem", nil, itemID, itemData, candidateData, configData, ProtocolVersion)
		self:SendMessage("UN_Acknowledge", nil, playerData)
		self:UN_Acknowledge(playerData, self:Disambiguate(UnitName("player")))
	end
end

function UnstableEPGP:SendMessage(command, target, ...)
	local serializedData = self:Serialize(...)
	if target and target ~= "PARTY" and target ~= "RAID" and target ~= "GUILD" and target ~= "OFFICER" and target ~= "BATTLEGROUND"  then
		self:SendCommMessage(command, serializedData, "WHISPER", target)
	elseif target then
		self:SendCommMessage(command, serializedData, target)	
	elseif self.groupType then
		self:SendCommMessage(command, serializedData, self.groupType)
	else
		self:SendCommMessage(command, serializedData, "WHISPER", GetUnitName("player", true))
	end
end

function UnstableEPGP:OnCommReceived(prefix, message, distribution, sender, cachedMsg)
	local senderFullName = self:Disambiguate(sender)
	local cMessage = {prefix, message, distribution, sender}
	
	if prefix == "UN_NewItem" and not UnitIsUnit(sender, "player") then
		local success, itemID, itemData, candidateData, configData, protocol = self:Deserialize(message)
		if not success then
			self:Print("Error: "..itemID)
			return
		end
		
		if protocol ~= ProtocolVersion then
			self:SendMessage("UN_Response", nil, itemID, self.RESPONSE["outdated"].text, self.RESPONSE["outdated"].color)	
			return
		end
		
		if not self.lootTable[itemID] then
			-- Register loot, candidates, and open loot window
			if not UnitIsUnit(sender, "player") then
				self:RegisterLoot(itemID, itemData, candidateData, configData, sender)
			end
		
			-- Get player ilvl and equipped item(s) for display
			if self.lootTable[itemID] then
				-- Send Response
				local playerData = self:GetPlayerData(itemID)
				self:SendMessage("UN_Acknowledge", nil, playerData)
				self:UN_Acknowledge(playerData, self:Disambiguate(UnitName("player")))
				
				if self.msgCache[itemID] then
					self:ProcessMsgCache(itemID)
				end
			end
		end
		
	elseif prefix == "UN_Acknowledge" and not UnitIsUnit(sender, "player") then
		local success, playerData = self:Deserialize(message)
		if not success then
			self:Print("Error: "..playerData)
			return
		end

		local itemID = playerData[1]
		-- Cache Message
		if not cachedMsg then
			self:CacheMessage(itemID, cMessage)
		end
		-- Only update response if the loot window is open	
		if self.lootTable[itemID] then
			self:UN_Acknowledge(playerData, senderFullName)
		end
		
	elseif prefix == "UN_Response" and not UnitIsUnit(sender, "player") then
		local success, itemID, response, color, updateTarget = self:Deserialize(message)
		if not success then
			self:Print("Error: "..itemID)
			return
		end

		-- Cache Message
		if not cachedMsg then
			self:CacheMessage(itemID, cMessage)
		end
		-- Only update response if the loot window is open	
		if self.lootTable[itemID] then
			if updateTarget then
				self:UN_Response(itemID, response, color, updateTarget)
			else
				self:UN_Response(itemID, response, color, senderFullName)
			end
		end
		
	elseif prefix == "UN_Award" then
		local success, itemID, itemLink, player, response, GP = self:Deserialize(message)
			if not success then
				self:Print("Error: "..itemID)
			return
		end
		-- Show message that loot has been awarded
		self:Print(format(self.RESPONSE[response].message, player, itemLink, GP or ""))
		-- If loot has been awarded, close window after 4 seconds
		if self.lootTable[itemID] then
			self:ScheduleTimer("DiscardLoot", 4, itemID, true)
		end

	elseif prefix == "UN_Close" and not UnitIsUnit(sender, "player") then
		local success, itemID = self:Deserialize(message)
		if not success then
			self:Print("Error: "..itemID)
			return
		end

		if self.lootTable[itemID] then
			self:DiscardLoot(itemID, false)
		end
	
	elseif prefix == "UN_Version" and not UnitIsUnit(sender, "player") then
		local success, version = self:Deserialize(message)
		if not success then
			self:Print("Error: "..version)
			return
		end

		if version == "getversion" then
			self:SendMessage("UN_Version", sender, VERSION)
		else
			if(self.currentML and UnitIsUnit(self.currentML, "player")) then
				self:Print(format("%s: %s", sender, version))
			end
		    UnstableEPGP:HandleVersion(version)
		end	
	end
end

function UnstableEPGP:HandleVersion(incVersion)
	if(not updateNotified) then
		local incMajor, incMinor = string.split(".", incVersion)
		local curMajor, curMinor = string.split(".", VERSION)
		if incMajor..incMinor > curMajor..curMinor then
			self:Print(format("New version available: %s", incVersion))
			updateNotified = true
		end
	end
end

function UnstableEPGP:UN_Acknowledge(playerData, senderFullName)
	local itemID, response, color, randomNum, itemLevel, itemIcon1, itemLink1, itemIcon2, itemLink2 = unpack(playerData)
	local frame = self.lootTable[itemID].frame 
	local r, g, b = UnstableEPGP:HexToRGBPerc(color)
	local responseColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = 1.0}
		
	if self.lootTable[itemID] then
		local candidate = self.lootTable[itemID].candidateIndex[senderFullName]
		self.lootTable[itemID].scrollData[candidate].cols[2] = {["value"] = itemLevel}
		self.lootTable[itemID].scrollData[candidate].cols[3].value = response
		self.lootTable[itemID].scrollData[candidate].cols[3].color = responseColor
		self.lootTable[itemID].scrollData[candidate].cols[5] = {["value"] = mathFloor(randomNum)}
		if itemIcon1 and itemLink1 then
			local equipped = {itemIcon1, itemLink1}
			self.lootTable[itemID].scrollData[candidate].cols[6] = {["value"] = equipped}
		end
		if itemIcon2 and itemLink2 then
			local equipped = {itemIcon2, itemLink2}
			self.lootTable[itemID].scrollData[candidate].cols[7] = {["value"] = equipped}
		end
		-- Only sort data if the item is visible
		if itemID and frame and itemID == frame.itemID then
			self.lootTable[itemID].frame.scrollTable:SortData()
		end
	end
end

function UnstableEPGP:UN_Response(itemID, response, color, updateTarget)
	if self.lootTable[itemID] then
		local candidate = self.lootTable[itemID].candidateIndex[updateTarget]
		local r, g, b = UnstableEPGP:HexToRGBPerc(color)
		local responseColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = 1.0}
		self.lootTable[itemID].scrollData[candidate].cols[3].value = response
		self.lootTable[itemID].scrollData[candidate].cols[3].color = responseColor
		
		-- Only sort data if the frame is still visible
		if self.lootTable[itemID].frame then
			self.lootTable[itemID].frame.scrollTable:SortData()
		end
	end
end

function UnstableEPGP:GetPlayerData(itemID)
	-- Get player ilvl and equipped item(s) for display
	local equipLoc = self.lootTable[itemID].equipLoc
	local _, itemLevel = 0
	local randomNum = mathRandom() + mathRandom(1, 99)
	local response = "selecting"

	-- Determine if we should Auto-Pass or not	
	if self.lootTable[itemID].eligible == false then
		response = "n/a"
		self:UpdateSelectionButtons(itemID, 9)
		self:CancelTimer(self.lootTable[itemID].timer)
	end
	
	local playerData = {itemID, self.RESPONSE[response].text, self.RESPONSE[response].color, randomNum, 0}
	if self.equipSlot[equipLoc] then
		for x = 1, #self.equipSlot[equipLoc] do
			if GetInventoryItemLink("player", self.equipSlot[equipLoc][x]) then
				tinsert(playerData, GetInventoryItemTexture("player", self.equipSlot[equipLoc][x]))
				tinsert(playerData, GetInventoryItemLink("player", self.equipSlot[equipLoc][x]))
			end
		end
	end
	return playerData
end

function UnstableEPGP:GetTableCount(table)
	local count = 0
	for k, v in pairs(table) do
		count = count + 1
	end
	return count
end

function UnstableEPGP:ClearTable(table)
	for k, v in pairs(table) do
		table[k] = nil
	end
end

function UnstableEPGP:CacheMessage(item, message)
	if not self.msgCache[item] then
		self.msgCache[item] = {}
	end
	tinsert(self.msgCache[item], message)
	--self:Print(format("There are %s messages in queue %s", #self.msgCache[item], item))
end

function UnstableEPGP:ProcessMsgCache(itemID)
	--self:Print("Trying to process cached items...")
	if self.lootTable[itemID] then
		for x = 1, #self.msgCache[itemID] do
			--message = tremove(self.msgCache[itemID])
			message = self.msgCache[itemID][x]
			self:OnCommReceived(message[1], message[2], message[3], message[4], true)
			--self:Print("Processed "..x.." item(s).")
		end
		--self.msgCache[itemID] = nil
	end
end

function UnstableEPGP:DisableEPGPPopup()
    -- Disable "automatic loot tracking" popup in EPGP - Let UnstableEPGP handle all the GP stuff
    if EPGP and IsInGuild() then
		if EPGP.db then
			EPGP.db.profile.auto_loot = false
        end
    end
end

function UnstableEPGP:StandingsChanged()
	-- Update EP, GP, and PR data
	if #self.lootTable > 0 then
		for item = 1, #self.lootTable do
			local itemID = self.lootTable[item]
			local frame = self.lootTable[itemID].frame
			for candidate, index in pairs(self.lootTable[itemID].candidateIndex) do
				local pr, ep, gp = self:GetPR(candidate)
				self.lootTable[itemID].scrollData[index].cols[4].value = pr
				self.lootTable[itemID].scrollData[index].ep = ep
				self.lootTable[itemID].scrollData[index].gp = gp
			end

			-- Only sort data if the item is visible
			if itemID and frame and itemID == frame.itemID then
				self.lootTable[itemID].frame.scrollTable:SortData()
			end	
		end
	end
end

function UnstableEPGP:GetEPGP(player)
    if not EPGP or not EPGP.GetEPGP then
		return nil, nil, nil, nil, nil
	end

	local ambiguatedName = player

    local retOK, ep, gp, alt = pcall(EPGP.GetEPGP, EPGP, player)
	if not retOK then
		return nil, nil, nil, nil, nil
	end

	if ep == nil then
		ambiguatedName = Ambiguate(player, "guild")
		retOK, ep, gp, alt = pcall(EPGP.GetEPGP, EPGP, ambiguatedName)
	end
	if ep == nil then
		ambiguatedName = Ambiguate(player, "none")
		retOK, ep, gp, alt = pcall(EPGP.GetEPGP, EPGP, ambiguatedName)
	end
	if ep == nil then
		ambiguatedName = Ambiguate(player, "short")
		retOK, ep, gp, alt = pcall(EPGP.GetEPGP, EPGP, ambiguatedName)
	end

    local retOK, minEP = pcall(EPGP.GetMinEP, EPGP)
    if not retOK or not minEP then
		minEP = 0
	end

	return ep, gp, alt, minEP, player
end

function UnstableEPGP:GetEP(player)
    local ep, gp = self:GetEPGP(player)
    if not ep then
		return -1
	end
    return ep or 0
end

function UnstableEPGP:GetGP(player)
    local ep, gp = self:GetEPGP(player)
    if not gp then
		return -1
	end
    return gp or 1
end

function UnstableEPGP:GetPR(player)
    local ep, gp = self:GetEPGP(player)
    if not gp or not ep then
		return 0, 0, 0
	end
	if gp ~= 0 then
		return tonumber(format("%.2f", ep/gp)), ep, gp
	else
		return 0, ep, gp
	end
end

function UnstableEPGP:DoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
	if column == 1 then
		-- Call the original DoCellUpdate function, then modify the cell after default update
		table.DoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
		local player = data[realrow]["cols"][column]["value"]
		cellFrame.text:SetText(Ambiguate(player, "short"))

	elseif column == 3 then
		-- Call the original DoCellUpdate function, then modify the cell after default update
		table.DoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
		local response = data[realrow]["cols"][column]["value"]
		local color = data[realrow]["cols"][column]["color"]
		local prefix = tonumber(string.sub(data[realrow]["cols"][column]["value"], 1, 2))
		-- Hide Responses until a selection has been made
		if self.lootTable[table.itemID].hideResponses and not self.lootTable[table.itemID].buttonState and not UnitIsUnit(self.lootTable[table.itemID].owner, "player") and prefix > 9 then
			cellFrame.text:SetText(string.sub(self.RESPONSE["selected"].text, 4))
			cellFrame.text:SetTextColor(UnstableEPGP:HexToRGBPerc(self.RESPONSE["selected"].color))			
		else
			cellFrame.text:SetText(string.sub(response, 4))
			if color then
				cellFrame.text:SetTextColor(color.r, color.g, color.b, color.a)
			end
		end
		
	elseif column == 4 then
		-- Call the original DoCellUpdate function, then modify the cell after default update
		table.DoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
	
		if fShow then 
			local ep = data[realrow]["ep"]
			local gp = data[realrow]["gp"]
			local pr = data[realrow]["cols"][4]["value"]
			local player = data[realrow]["cols"][1]["value"]	
			cellFrame:SetScript("OnEnter", function()
				GameTooltip:SetOwner(cellFrame, "ANCHOR_RIGHT", -5, 3)
				GameTooltip:SetText(player)
				GameTooltip:AddLine(format("EP: %d\rGP: %d\rPR: %.3f", ep, gp, pr))
				GameTooltip:Show()
			end)
			cellFrame:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		else
			cellFrame:SetScript("OnEnter", nil)
			cellFrame:SetScript("OnLeave", nil)
		end	
	
	elseif column == 6 or column == 7 then
		if fShow and data[realrow]["cols"][column] then 
			local itemTexture = data[realrow]["cols"][column]["value"][1]
			local itemLink = data[realrow]["cols"][column]["value"][2]
			
			
			itemTexture = ArtTexturePaths:GetTexture(itemTexture)
			
			cellFrame:SetBackdrop({bgFile = itemTexture, insets = {left = 3, right = 3, top = 1, bottom = 1}})
			cellFrame:SetScript("OnEnter", function()
				GameTooltip:SetOwner(cellFrame, "ANCHOR_RIGHT", -5, 3)
				GameTooltip:SetHyperlink(itemLink)
				GameTooltip:Show()
			end)
			cellFrame:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			cellFrame:SetScript("OnClick", function()
				if IsModifiedClick() then
					HandleModifiedItemClick(itemLink)
				end
			end)
		else
			cellFrame:SetBackdrop({bgFile = nil})
			cellFrame:SetScript("OnEnter", nil)
			cellFrame:SetScript("OnLeave", nil)
			cellFrame:SetScript("OnClick", nil)		
		end		
	end
end

function UnstableEPGP:ShowScrollMenu(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, itemID, button, ...)
	if DropDownList1:IsShown() then
		CloseDropDownMenus()
	else
		if realrow and button == "RightButton" then
			local buttonDisabled = false
			local candidate = data[realrow].cols[1].value
			local buttonNum = self.lootTable[itemID].buttonNum
			
			-- Only enable GP award options if EPGP is available
			if not EPGP then
				buttonDisabled = true
			end
			
			if not self.lootTable[itemID].menuTable then
				-- Create New Menu
				self.lootTable[itemID].menuTable = {
					{text = "", isTitle = true, notCheckable = true},
					{text = "", disabled = true, notCheckable = true},
					{text = "Award Loot", isTitle = true, notCheckable = true},
					{text = "Free", notCheckable = true, func = function() self:AwardLoot(itemID, candidate, "free") end},
					{text = "Bank Deposit", notCheckable = true, func = function() self:AwardLoot(itemID, data[realrow].cols[1].value, "bank") end},
					{text = "Disenchant", notCheckable = true, func = function() self:AwardLoot(itemID, data[realrow].cols[1].value, "disenchant") end},
					{text = "", disabled = true, notCheckable = true},
					{text = "Other Options", isTitle = true, notCheckable = true},
					{text = "Re-announce Loot", notCheckable = true, func = function()
						self:SendMessage("UN_NewItem", candidate, itemID, self.lootTable[itemID].itemData, self.lootTable[itemID].candidateData, self.lootTable[itemID].configData, ProtocolVersion)
					end},
					{text = "Change Response", notCheckable = true, hasArrow = true, menuList = {}},
					{text = "Cancel", notCheckable = true, func = function() CloseDropDownMenus() end},
				}
				-- Create GP Award buttons
				for x = 1, buttonNum do
					tinsert(self.lootTable[itemID].menuTable, 4, {text = x, notCheckable = true, disabled = buttonDisabled, func = ""})
					tinsert(self.lootTable[itemID].menuTable[10 + x].menuList, {text = x, notCheckable = true, func = ""}) 
				end
			end
			
			-- Load menu with item/player specific data
			if self.lootTable[itemID].menuTable then
				self.lootTable[itemID].menuTable[1].text = candidate
				self.lootTable[itemID].menuTable[4 + buttonNum].func = function() self:AwardLoot(itemID, candidate, "free") end
				self.lootTable[itemID].menuTable[5 + buttonNum].func = function() self:AwardLoot(itemID, candidate, "bank") end
				self.lootTable[itemID].menuTable[6 + buttonNum].func = function() self:AwardLoot(itemID, candidate, "disenchant") end
				self.lootTable[itemID].menuTable[9 + buttonNum].func = function()
					self:SendMessage("UN_NewItem", candidate, itemID,	self.lootTable[itemID].itemData, self.lootTable[itemID].candidateData, self.lootTable[itemID].configData, ProtocolVersion)
				end
				
				local cost = self.lootTable[itemID].gpCost
				for x = 1, buttonNum do
					local buttonGP = self.db.profile["button"..x.."_GP"]
					local number, percent = strmatch(buttonGP, '^(%d+)(%%?)$')
					local trueCost = 0
					if number and percent then
						trueCost =  mathFloor((number * .01) * cost)
					elseif number and percent == "" then
						trueCost = number
					else
						trueCost = cost
					end
					
					self.lootTable[itemID].menuTable[3 + x].text = format("%s - %s GP", self.lootTable[itemID]["button"..x], trueCost)
					self.lootTable[itemID].menuTable[3 + x].func = function() self:AwardLoot(itemID, candidate, "winner", trueCost) end
					self.lootTable[itemID].menuTable[10 + buttonNum].menuList[x].text = self.lootTable[itemID]["button"..x] 
					self.lootTable[itemID].menuTable[10 + buttonNum].menuList[x].func = function()
						self:SendMessage("UN_Response", nil, itemID, format("1%s %s", x, self.lootTable[itemID]["button"..x]), self.lootTable[itemID]["button"..x.."c"], candidate)
						self:UN_Response(itemID, format("1%s %s", x, self.lootTable[itemID]["button"..x]), self.lootTable[itemID]["button"..x.."c"], candidate)
						CloseDropDownMenus()
					end
				end

				EasyMenu(self.lootTable[itemID].menuTable, self.awardPopupMenu, "cursor", 0, 0, "MENU", 5)
			end
		end
	end
end

function UnstableEPGP:UpdateSelectionButtons(itemID, state)
	if state then
		self.lootTable[itemID].buttonState = state
	end
	local frame = self.lootTable[itemID].frame
	local buttonNum = self.lootTable[itemID].buttonNum
	-- Set state and visibility of selection buttons
	if frame and frame.itemID == itemID then
		for num = 1, 7 do
			if num <= buttonNum then
				frame["button" .. num]:Show()
				if not self.lootTable[itemID].allowReselect and self.lootTable[itemID].buttonState or self.lootTable[itemID].buttonState == 9 then
					frame["button"..num]:Disable()
				else
					frame["button"..num]:Enable()
				end
			else
				frame["button"..num]:Hide()
			end
		end
		-- If reselection is allowed, only disable selected button
		if self.lootTable[itemID].allowReselect and self.lootTable[itemID].buttonState and self.lootTable[itemID].buttonState <= 7 then
			frame["button"..self.lootTable[itemID].buttonState]:Disable()
		end	
		-- Set state of Pass Button
		if self.lootTable[itemID].buttonState and self.lootTable[itemID].buttonState >= 8 then
			frame.buttonPass:Disable()
		else
			frame.buttonPass:Enable()
		end
	end
	
	if self.db.profile.tabbedFrame == "yes" and #self.lootTable > 1 and self.tabbedFrame then
		self:UpdateTabs()
	end
end

function UnstableEPGP:SelectionAutoAdvance()
	for x = 1, #self.lootTable do
		if not self.lootTable[self.lootTable[x]].buttonState then
			self:UpdateFrame(self.lootTable[x], x)
			break
		end
	end
end

function UnstableEPGP:ChangeDisplayMode()
	if self.db.profile.tabbedFrame == "yes" then
		if #self.lootTable > 0 then
			for x = 1, #self.lootTable do
				local frame = self.lootTable[self.lootTable[x]].frame
				self.lootTable[self.lootTable[x]].frame = nil
				frame:Hide()
				tinsert(self.recycledFrames, frame)
				self:ShowLoot(self.lootTable[x])
			end	
		end
	else
		if #self.lootTable > 0 and self.tabbedFrame then
			local frame = self.tabbedFrame
			frame:Hide()
			tinsert(self.recycledFrames, frame)
			self.tabbedFrame = nil
			for x = 1, #self.lootTable do
				self.lootTable[self.lootTable[x]].frame = nil
				self:ShowLoot(self.lootTable[x])	
			end
		end	
	end
end

function UnstableEPGP:SecToMin(seconds)
	seconds = mathFloor(seconds)
	if seconds > 59 then
		myMinutes = mathFloor(seconds/60)
		mySeconds = string.format("%02.0f", seconds-(mathFloor(seconds/60)*60))
		myTime = myMinutes..":"..mySeconds
	else
		mySeconds = string.format("%02.0f", seconds)
		myTime = "0:"..mySeconds
	end
	return myTime
end

function UnstableEPGP:TimerFeedback(itemID)
	self.lootTable[itemID].timeRemaining = self.lootTable[itemID].timeRemaining - 1
	local frame = self.lootTable[itemID].frame
	local timerValue = (self.lootTable[itemID].timeRemaining/self.lootTable[itemID].lootTimeout)*100
	if itemID and frame and itemID == frame.itemID then
		frame.timerBar:SetValue(timerValue)
		frame.timerBar.time:SetText(self:SecToMin(self.lootTable[itemID].timeRemaining))
		-- Change bar color at 25%
		if timerValue < 25 then
			frame.timerBar:SetStatusBarColor(1,0,0)	
		end
	end
	if timerValue <= 0 then
		if not self.lootTable[itemID].allowReselect or not self.lootTable[itemID].buttonState then
			self.lootTable[itemID].buttonState = 9
			self:SendMessage("UN_Response", nil, itemID, self.RESPONSE["autopass"].text, self.RESPONSE["autopass"].color)
			self:UN_Response(itemID, self.RESPONSE["autopass"].text, self.RESPONSE["autopass"].color, self:Disambiguate(UnitName("player")))
		end
		self:UpdateSelectionButtons(itemID, 9)
		self:CancelTimer(self.lootTable[itemID].timer)
	end
end

-- Makes all character names consistent
function UnstableEPGP:Disambiguate(name)
	-- Get realm name; remove dashes and spaces so other functions will work
	local realmName = gsub(gsub(GetRealmName(), '-', ''), ' ', '')
	local playerName = Ambiguate(name, "none")
	
	-- If playerName contains no realm, add it
	if strfind(playerName, "-", nil, true) == nil then
		playerName = playerName .. "-" .. realmName
	end
	return playerName
end

function UnstableEPGP:AnnounceButton(buttonName)
	if self.db.profile.announceButton == 1 and IsLeftAltKeyDown() then
		return true
	elseif self.db.profile.announceButton == 2 and buttonName == "LeftButton" then
		return true
	else
		return false
	end		
end

function UnstableEPGP:GetLootIDFromLink(itemLink)
    if not itemLink then
		return
	end
	local lootID = string.match(itemLink, "item:[%-?%d:]+")
    if not lootID then
		return
	end
	-- Make sure UniqueID is set to zero
	local splitID = {strsplit(':', lootID)}
	splitID[9] = 0
	lootID = strjoin(':', unpack(splitID))
    return lootID
end

function UnstableEPGP:GetLootThreshold()
    return self.db.profile.lootThreshold
end

function UnstableEPGP:OPEN_MASTER_LOOT_LIST(announce)
buttonName = GetMouseButtonClicked()
	if self.db.profile.useUnstableEPGP and self.currentML then
		-- Close default Blizzard popup unless RIGHT ALT key is pressed
		if not IsRightAltKeyDown() then
			CloseDropDownMenus()
		end
		-- Only Master Looter can announce (LEFT ALT + click must be used) 
		if self:AnnounceButton(buttonName) and self.currentML and UnitIsUnit(self.currentML, "player") or announce == true then
			CloseDropDownMenus()
			local numLootItems = GetNumLootItems()

			if self:GetTableCount(self.lootCache) == 0 then
				self:LOOT_OPENED()
				--self.autoAnnounce = nil
			end

			-- Should we automatically announce ALL items?
			if self.autoAnnounce == "" or self.autoAnnounce == nil then
				-- Find the number of items that match the loot threshold
				local qualifiedItems = 0
				for slot = 1, numLootItems do
					local _,_,_, rarity = GetLootSlotInfo(slot)
					if rarity and rarity >= UnstableEPGP:GetLootThreshold() then
						qualifiedItems = qualifiedItems + 1
					end
				end
				if qualifiedItems > 1 and self.db.profile.announceConfirm == true then
					StaticPopup_Show("AutoAnnounce", qualifiedItems)
					return
				else
					self.autoAnnounce = true
				end
			end
		
			if self.autoAnnounce == false then
				local itemSlot = LootFrame.selectedSlot
				local itemIcon, itemName, itemQuantity, itemRarity, locked = GetLootSlotInfo(itemSlot)
				local itemLink = GetLootSlotLink(itemSlot)
				local lootID = self:GetLootIDFromLink(itemLink)
				-- Announce loot to candidates
				if self.lootCache[lootID] and self.lootCache[lootID].quantity > 0 then
					self:NewLoot(itemLink, itemSlot, "drop")
					self.lootCache[lootID].quantity = self.lootCache[lootID].quantity - 1
				-- If NEW item already exists in lootCache, add as duplicate (this should happen very infrequently)	
				elseif self.lootCache[lootID] and self.lootCache[lootID].duplicate and self.lootCache[lootID].duplicate > 0 then
					self.lootCache[lootID].duplicate = self.lootCache[lootID].duplicate - 1
					self.lootCache[lootID].undistributed = self.lootCache[lootID].undistributed + 1	
					self:NewLoot(itemLink, itemSlot, "drop")
				else
					self:Print(format("%s has already been announced.", itemLink))
				end
			elseif self.autoAnnounce == true then
				self.autoAnnounce = false
				UnstableEPGP:AnnounceLoot()
			end
		end
	end
end

function UnstableEPGP:AnnounceLoot()
	local itemNum = 0
	for lootID, lootInfo in pairs(self.lootCache) do
		if self.lootCache[lootID] and lootInfo.quantity > 0 then
			for x = 1, lootInfo.quantity do
				-- Announce loot to candidates
				self:ScheduleTimer("NewLoot", .6*(itemNum), lootInfo.link, lootInfo.slot, "drop")
				lootInfo.quantity = lootInfo.quantity - 1
				itemNum = itemNum + 1
			end
		elseif self.lootCache[lootID] and lootInfo.duplicate and lootInfo.duplicate > 0 then
			self:Print(format("%s (x%s) has already been announced. If this is a NEW duplicate item, please reclick to announce.", self.lootCache[lootID].link, self.lootCache[lootID].undistributed))
		else
			self:Print(format("%s has already been announced.", self.lootCache[lootID].link))
		end
	end
end

function UnstableEPGP:LOOT_OPENED(event, arg)
	if self.db.profile.useUnstableEPGP and self.currentML and UnitIsUnit(self.currentML, "player") then
		local numLootItems = GetNumLootItems()

		for itemSlot = 1, numLootItems do
			local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(itemSlot)
			local itemLink = GetLootSlotLink(itemSlot)
			local lootID = self:GetLootIDFromLink(itemLink)
            --check rarity threshold
			if lootName and lootQuality and lootQuality >= UnstableEPGP:GetLootThreshold() then			
				-- Find out if there are any duplicates
				local itemQuantity = 0
				for slot = 1, numLootItems do
					local link = GetLootSlotLink(slot)
					local ID = self:GetLootIDFromLink(link)
					if ID == lootID then
						itemQuantity = itemQuantity + 1
					end
				end
				if not self.lootCache[lootID] then 
					self.lootCache[lootID] = {["link"] = itemLink, ["slot"] = itemSlot, ["quantity"] = itemQuantity, ["undistributed"] = itemQuantity, ["frameCount"] = self.frameCount}
				elseif self.lootCache[lootID] and self.lootCache[lootID].frameCount < self.frameCount then
					self.lootCache[lootID].duplicate = itemQuantity
				end
			end
		end
		
		UnstableEPGP:AnnounceLoot()
		
	end
end

function UnstableEPGP:LOOT_CLOSED()
	if self.db.profile.useUnstableEPGP and self.currentML and UnitIsUnit(self.currentML, "player") then
		-- Reset Auto Announce once loot frame is closed
		self.autoAnnounce = nil
		-- Counts the number of times the loot window has been opened between lootCache resets
		self.frameCount = self.frameCount + 1	
	end

	if self.db.profile.autoCancel and self.currentML and UnitIsUnit(self.currentML, "player") then
		-- Clear lootCache when loot window closes
		if self.lootCache then
			self.lootCache = {}
		end
		
		if self.db.profile.tabbedFrame == "yes" then
			self:CloseTabbedFrame(self.tabbedFrame)
		else
			local itemCount = #self.lootTable
			for x = itemCount, 1, -1 do
				local itemID = self.lootTable[x]
				self:DiscardLoot(itemID, false)
				self:SendMessage("UN_Close", nil, itemID)
			end
		end
	end
end

function UnstableEPGP:AwardLoot(itemID, candidate, response, GP)
	-- Ignore test items
	if self.lootTable[itemID].announceType == "test" then
		return
	end
	
	-- Look for lootIndex
	local lootID = self:GetLootIDFromLink(self.lootTable[itemID].link)
	local lootIndex = 0
	for slot = 1, GetNumLootItems() do
		local currentItem = GetLootSlotLink(slot)
		if currentItem then
			local itemID = self:GetLootIDFromLink(currentItem)
			if itemID and itemID == lootID then
				lootIndex = slot
				break
			end
		end
	end

	-- Look for the candidateIndex
	local candidateIndex = 0
	for cIndex = 1, 40 do
		local name = GetMasterLootCandidate(lootIndex, cIndex)
		if name and self:Disambiguate(name) == candidate then
			candidateIndex = cIndex
			break
		end
	end

	if GP then
		local retOK, dataOK  = pcall(EPGP.CanIncGPBy, EPGP, self.lootTable[itemID].link, GP)
		if retOK and not dataOK then
			self:Print("Unable to distribute loot. Please make sure the item is available with a GP cost > 0.")
			return
		end
	end

	local retOK = pcall(GiveMasterLoot, lootIndex, candidateIndex, lootID)
	
	if retOK or self.lootTable[itemID].announceType == "manual" then
		if response == "winner" then
			--EPGP:IncGPBy(Ambiguate(candidate, "none"), self.lootTable[itemID].link, GP)
			EPGP:IncGPBy(candidate, self.lootTable[itemID].link, GP)
		end
		self.lootTable[itemID].winner = candidate
		self:SendMessage("UN_Response", nil, itemID, self.RESPONSE[response].text, self.RESPONSE[response].color, candidate)
		self:SendMessage("UN_Award", nil, itemID, self.lootTable[itemID].link, candidate, response, GP)		
		if self.lootTable[itemID].announceType == "manual" then
			self:Print(format("Manually announced items must be delivered via trade. Please deliver %s to %s.", self.lootTable[itemID].link, candidate))
		end
		self:DiscardLoot(itemID, true)
	else
		self:Print("Cannot award loot. Please ensure the loot window is open, the item is available, and the recipient is within range.")
		return nil
	end
end

function UnstableEPGP:GiveMasterLoot(lootIndex, candidateIndex, lootID)
	if lootID and self.lootCache[lootID] then
		self.lootCache[lootID].undistributed = self.lootCache[lootID].undistributed - 1
		if self.lootCache[lootID].quantity == 0 and self.lootCache[lootID].undistributed == 0 then
			self.lootCache[lootID] = nil
		end
	end
end

function UnstableEPGP:EligibleCandidate(candidateData)
	if not candidateData then
		return false
	end	
	local player = self:Disambiguate(UnitName("player"))
	for x = 1, #candidateData do
		if player == candidateData[x][1] then
			return true
		end
	end
	return false
end

-- Close ALL tabs and frame
function UnstableEPGP:CloseTabbedFrame(frame)
	if frame then
		frame:Hide()
		StaticPopup_Hide("CloseTabbedFrame")
		CloseDropDownMenus()
		tinsert(self.recycledFrames, frame)
		
		for x = #self.lootTable, 1, -1 do
			local itemID = self.lootTable[x]
			if UnitIsUnit(self.lootTable[itemID].owner, "player") then
				self:SendMessage("UN_Close", nil, itemID)
			else
				-- When closing the window, only update response to "Pass" if no selection was made
				if not self.lootTable[itemID].buttonState then
					self:SendMessage("UN_Response", nil, itemID, self.RESPONSE["pass"].text, self.RESPONSE["pass"].color)
				end
				tinsert(self.lootHist, self.lootTable[itemID])
			end
			tremove(self.lootTable, x)
			self.lootTable[itemID].frame = nil
			self.lootTable[itemID] = nil
		end

		-- For Master Looter: if lootTable is empty then delete lootCache and close lootFrame as well
		if #self.lootTable == 0 and self:GetTableCount(self.lootCache) > 0 then
			self.lootCache = {}
			self.frameCount = 0
		end	
				
		self.tabbedFrame = nil
		self:CancelAllTimers()
	end
end

-- Hide and recycle old frames
function UnstableEPGP:DiscardLoot(itemID, addToHistory)
	if itemID then
		CloseDropDownMenus()
		local frame = self.lootTable[itemID].frame
		local itemNum = 1

		-- Find the location of item in lootTable (this is so tabs can be updated and the correct item can be removed)
		for x = 1, #self.lootTable do
			if self.lootTable[x] == itemID then
				itemNum = x
			end
		end
		
		-- Should the loot be added to history?
		if addToHistory and self.lootTable[itemID].announceType ~= "test" then
			tinsert(self.lootHist, self.lootTable[itemID])
		elseif UnitIsUnit(self.lootTable[itemID].owner, "player") and self.lootTable[itemID].announceType == "drop" then
			-- If the loot is NOT added to history and it's NOT test loot, it should probably be added back to lootCache for possible re-annoucement 
			local itemLink = self.lootTable[itemID].link
			local lootID = self:GetLootIDFromLink(itemLink)
			if self.lootCache and self.lootCache[lootID] then
				self.lootCache[lootID].quantity = self.lootCache[lootID].quantity + 1
			end
		end
			
		if self.tabbedFrame then
			tremove(self.lootTable, itemNum)
			self:CancelTimer(self.lootTable[itemID].timer)
			self.lootTable[itemID].frame = nil
			self.lootTable[itemID] = nil
			self:UpdateTabs()
			
			local count = #self.lootTable
			if count > 1 and itemNum <= count then
				if self.currentTab == itemNum then
					self:UpdateFrame(self.lootTable[itemNum], itemNum)
				elseif self.currentTab > itemNum then
					self:UpdateFrame(self.lootTable[self.currentTab - 1], self.currentTab - 1)
				end					
			elseif count > 1 and itemNum - 1 <= count then
				if self.currentTab > itemNum - 1 then
					self:UpdateFrame(self.lootTable[itemNum - 1], itemNum - 1)
				end
			elseif count == 1 then
				self:UpdateFrame(self.lootTable[1], 1)
			else
				self:CloseTabbedFrame(frame)
			end
		else	
			frame:Hide()
			tinsert(self.recycledFrames, frame)
			
			tremove(self.lootTable, itemNum)
			self:CancelTimer(self.lootTable[itemID].timer)
			self.lootTable[itemID].frame = nil
			self.lootTable[itemID] = nil
			
			-- For Master Looter: if lootTable is empty then delete lootCache and close lootFrame as well
			if #self.lootTable == 0 and self:GetTableCount(self.lootCache) > 0 then
				self.lootCache = {}
				self.frameCount = 0
			end				
		end
	end
end

function UnstableEPGP:TableInvert(table)
	local inverted = {}
	for key, value in pairs(table) do
		inverted[value] = key
	end
	return inverted
end

function UnstableEPGP:GroupUpdate()
	local lootMethod, ML_PartyID, ML_RaidID = GetLootMethod()
	local inInstance, instanceType = IsInInstance()
	self.groupSize = GetNumGroupMembers()

	-- Determine group type
	if self.groupSize == 0 then
		-- No group; player is solo
		if self.groupType then
			self.groupType = nil
		end
	elseif self.groupSize > 0 and UnitInRaid("player") then
		-- Raid group
		if inInstance and instanceType == "pvp" then
			self.groupType = "battleground"
		else
			self.groupType = "raid"
		end
	else
		-- Party group
		self.groupType = "party"
	end

	
	if self.groupType and lootMethod == "master" then
		--self:Print("You are in a " .. self.groupType .. " group with a Master Looter.")
		if ML_RaidID then
			self:MasterLooterUpdate(UnitName('raid'..ML_RaidID))
		elseif ML_PartyID == 0 then
			-- Player is MasterLooter
			self:MasterLooterUpdate(UnitName("player"))
		elseif ML_PartyID then
			-- Someone else in party is MasterLooter
			self:MasterLooterUpdate(UnitName('party'..ML_PartyID))
		end
	else
		--self:Print("You are in a " .. self.groupType .. " group with NO Master Looter.")
		self.db.profile.useUnstableEPGP = false
		if self.currentML then
			self.currentML = nil
		end
	end
end

function UnstableEPGP:MasterLooterUpdate(masterLooter, realm)
	if masterLooter and masterLooter ~= "Unknown" then
		if realm and realm ~= nil and realm ~= "" then
			masterLooter = masterLooter.."-"..realm
		end
		if self.currentML ~= masterLooter then
			self.currentML = masterLooter
			if UnitIsUnit(self.currentML, "player") then
				if not self.db.profile.useUnstableEPGP then
					StaticPopup_Show("NewMasterLooter")
				end
			else
				self.db.profile.useUnstableEPGP = false
			end
		end
	end
end

function UnstableEPGP:UpdateTabs()
	local lootCount = #self.lootTable
	local frame = self.tabbedFrame
	
	if lootCount > 14 then
		lootCount = 14
	end
	
	if lootCount > 1 then
		for x = 1, lootCount do
			frame["tab"..x].icon:SetTexture(self.lootTable[self.lootTable[x]].texture)
			frame["tab"..x].icon:SetDesaturated(not self.lootTable[self.lootTable[x]].eligible)	
			if self.lootTable[self.lootTable[x]].eligible and not self.lootTable[self.lootTable[x]].buttonState then
				AutoCastShine_AutoCastStart(frame["tab"..x].shine)
			else
				AutoCastShine_AutoCastStop(frame["tab"..x].shine)
			end
			frame["tab"..x]:Show()
			self:SetButtonScripts(frame["tab"..x], self.lootTable[x], x)
		end
		if lootCount < 14 then
			for x = lootCount + 1, 14 do
				frame["tab"..x]:Hide()
			end
		end
	else
		for x = 1, 14 do
			frame["tab"..x]:Hide()
		end		
	end		
end

function UnstableEPGP:ShowLoot(itemID)
	if self.db.profile.tabbedFrame == "yes" then
		if not self.tabbedFrame then
			self:GetLootFrame(itemID)
			self.tabbedFrame = self.lootTable[itemID].frame
		else
			self:UpdateTabs()
			if not self.lootTable[itemID].timer then
				self.lootTable[itemID].timeRemaining = self.lootTable[itemID].lootTimeout
				self.lootTable[itemID].timer = self:ScheduleRepeatingTimer("TimerFeedback", 1, itemID)
			end
		end
	else
		self:GetLootFrame(itemID)
	end	
end

function UnstableEPGP:GetLootFrame(itemID)
	local frame = tremove(self.recycledFrames)
	if not frame then
		-- Create Main Frame
		frame = CreateFrame("Frame", "Mimic EPGP UnstableEPGP", UIParent, "BasicFrameTemplate")
		frame.number = self.frameNum
		
		frame:SetFrameStrata("HIGH")
		frame:SetToplevel(true)
		frame:SetFrameLevel((self.frameNum + 2) * 2)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:SetPoint("CENTER")

		-- Make the frame draggable
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
					
		frame.title = frame:CreateFontString("UN_Title", "BORDER", "GameFontNormal")
		frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
		frame.title:SetText("UnstableEPGP")
		
		-- Create Loot Button and Icon
		local lootButton = CreateFrame("Button", "UN_LootButton", frame, "ActionButtonTemplate")
		lootButton:SetSize(40, 40)
		lootButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 19, -45)
		lootButton:RegisterForClicks("AnyUp")
		frame.lootButton = lootButton
	
		-- Create Item Label
		local label = lootButton:CreateFontString("UN_LootLabel"..self.frameNum, "OVERLAY", "GameTooltipHeaderText")
		label:SetPoint("LEFT", lootButton, "RIGHT", 10, 14)
		frame.lootButton.label = label
		
		-- Create GP Label
		local GP_Label = lootButton:CreateFontString("UN_LootLabel"..self.frameNum, "OVERLAY", "GameFontNormal")
		GP_Label:SetPoint("TOPLEFT", frame, "TOPLEFT", 69, -61)
		frame.lootButton.GP_Label = GP_Label
		
		-- Create ML Label
		local ML_Label = lootButton:CreateFontString("UN_LootLabel"..self.frameNum, "OVERLAY", "GameFontNormalSmall")
		ML_Label:SetPoint("TOPLEFT", GP_Label, "BOTTOMLEFT", 1, -2)
		frame.lootButton.ML_Label = ML_Label
	
		-- Create Owner Label
		local OwnerLabel = lootButton:CreateFontString("UN_LootLabel"..self.frameNum, "OVERLAY", "GameFontNormalSmall")
		OwnerLabel:SetPoint("LEFT", ML_Label, "RIGHT", 0, 0)
		frame.lootButton.OwnerLabel = OwnerLabel
	
		-- Create Item Border - Left
		local texBorderLeft = lootButton:CreateTexture(nil, "BACKGROUND", nil, -5)
		texBorderLeft:SetSize(283, 57)--271, 57 
		texBorderLeft:SetPoint("TOPLEFT", lootButton, "TOPLEFT", -10, 8)
		texBorderLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-DetailHeaderLeft")
		texBorderLeft:SetTexCoord(0, 1, 0, 0.8)
		frame.lootButton.texBorderLeft = texBorderLeft
		
		-- Create Item Border - Right
		local texBorderRight = lootButton:CreateTexture(nil, "BACKGROUND", nil, -5)
		texBorderRight:SetSize(64, 57)
		texBorderRight:SetPoint("TOPLEFT", lootButton, "TOPLEFT", 273, 8) --261
		texBorderRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-DetailHeaderRight")
		texBorderRight:SetTexCoord(0, 1, 0, 0.8)
		frame.lootButton.texBorderRight = texBorderRight
		
		-- Create Timer Bar and Texture
		local timerBar = CreateFrame("StatusBar", nil, frame)
		timerBar:SetSize(190, 10)
		timerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 60, -103)
		timerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		timerBar:GetStatusBarTexture():SetHorizTile(false)
		timerBar:SetStatusBarColor(0,1,0)	
		timerBar:SetMinMaxValues(0, 100)
		SmoothBar:SmoothBar(timerBar)
		
		timerBar.border = timerBar:CreateTexture(nil, "OVERLAY")
		timerBar.border:SetSize(256, 64)
		timerBar.border:SetPoint("TOPLEFT", timerBar, "TOPLEFT", -33, 27) -- 82 -78
		timerBar.border:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
		timerBar.border:SetTexCoord(0, 1, 0, 1)
		
		timerBar.time = timerBar:CreateFontString("UN_LootLabel"..self.frameNum, "OVERLAY", "GameFontNormal")
		timerBar.time:SetPoint("LEFT", timerBar, "RIGHT", 20, 0)
		frame.timerBar = timerBar

		-- Create Selection Buttons 1-6 (Need, Greed, Minor Upgrade, etc.)
		frame.button1 = CreateFrame("Button", "UN_Button1", frame, "UIPanelButtonTemplate")
		frame.button1:SetSize(145,23)
		frame.button1:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -123)
				
		frame.button2 = CreateFrame("Button", "UN_Button2", frame, "UIPanelButtonTemplate")
		frame.button2:SetSize(145,23)
		frame.button2:SetPoint("TOPLEFT", frame.button1, "TOPRIGHT", 10, 0)
				
		frame.button3 = CreateFrame("Button", "UN_Button3", frame, "UIPanelButtonTemplate")
		frame.button3:SetSize(145,23)
		frame.button3:SetPoint("TOPLEFT", frame.button1, "BOTTOMLEFT", 0, -1)
				
		frame.button4 = CreateFrame("Button", "UN_Button4", frame, "UIPanelButtonTemplate")
		frame.button4:SetSize(145,23)
		frame.button4:SetPoint("TOPLEFT", frame.button2, "BOTTOMLEFT", 0, -1)
			
		frame.button5 = CreateFrame("Button", "UN_Button5", frame, "UIPanelButtonTemplate")
		frame.button5:SetSize(145,23)
		frame.button5:SetPoint("TOPLEFT", frame.button3, "BOTTOMLEFT", 0, -1)
				
		frame.button6 = CreateFrame("Button", "UN_Button6", frame, "UIPanelButtonTemplate")
		frame.button6:SetSize(145,23)
		frame.button6:SetPoint("TOPLEFT", frame.button4, "BOTTOMLEFT", 0, -1)
		
		frame.button7 = CreateFrame("Button", "UN_Button7", frame, "UIPanelButtonTemplate")
		frame.button7:SetSize(145,23)
		frame.button7:SetPoint("TOPLEFT", frame.button5, "BOTTOMLEFT", 0, -1)
		
		-- Create Pass Button
		local buttonPass = CreateFrame("Button", "Pass_Button", frame, "UIPanelButtonTemplate")
		buttonPass:SetSize(145,23)
		buttonPass:SetText("Pass")
		frame.buttonPass = buttonPass
				
		-- Create Scrollframe		
		local scrollTable = ScrollingTable:CreateST(self.scrollFrameCols, 11, 17, nil, frame)
		scrollTable.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 24)
		scrollTable.frame:SetSize(342, 200)
		frame.scrollTable = scrollTable

		-- Create Cancel Loot Button
		local buttonCancel = CreateFrame("Button", "UN_Button6", frame, "UIPanelButtonTemplate")
		buttonCancel:SetSize(100,23)
		buttonCancel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)
		buttonCancel:SetText("Cancel Loot")
		frame.buttonCancel = buttonCancel
		
		-- GP Edit Box and Label
		local editBox = CreateFrame("EditBox", "GP_EditBox"..self.frameNum, frame, "InputBoxTemplate")
		editBox:SetSize(40, 40)
		editBox:SetPoint("LEFT", buttonCancel, "RIGHT", 31, 0)
		editBox:SetAutoFocus(false)
		
		editBox.label = editBox:CreateFontString("UN_LootLabel"..self.frameNum, "OVERLAY", "GameFontNormal")
		editBox.label:SetPoint("RIGHT", editBox, "LEFT", -5, -1)
		editBox.label:SetText("GP:")
		frame.editBox = editBox
		
		-- Create Discard Button
		local buttonDiscard = CreateFrame("Button", "UN_Button6", frame, "UIPanelButtonTemplate")
		buttonDiscard:SetSize(85,23)
		buttonDiscard:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 3)
		buttonDiscard:SetText("Discard")
		frame.buttonDiscard = buttonDiscard

		-- Create Tabs 1-14
		frame.tab1 = self:CreateTab(frame, 1)
		frame.tab1:SetPoint("TOPRIGHT", frame, "TOPLEFT", -5, -35)
				
		frame.tab2 = self:CreateTab(frame, 2)
		frame.tab2:SetPoint("TOPRIGHT", frame.tab1, "BOTTOMRIGHT", 0, -21)
		
		frame.tab3 = self:CreateTab(frame, 3)
		frame.tab3:SetPoint("TOPRIGHT", frame.tab2, "BOTTOMRIGHT", 0, -21)
				
		frame.tab4 = self:CreateTab(frame, 4)
		frame.tab4:SetPoint("TOPRIGHT", frame.tab3, "BOTTOMRIGHT", 0, -21)
				
		frame.tab5 = self:CreateTab(frame, 5)
		frame.tab5:SetPoint("TOPRIGHT", frame.tab4, "BOTTOMRIGHT", 0, -21)
		
		frame.tab6 = self:CreateTab(frame, 6)
		frame.tab6:SetPoint("TOPRIGHT", frame.tab5, "BOTTOMRIGHT", 0, -21)

		frame.tab7 = self:CreateTab(frame, 7)
		frame.tab7:SetPoint("TOPRIGHT", frame.tab6, "BOTTOMRIGHT", 0, -21)
			
		frame.tab8 = self:CreateTab(frame, 8)
		frame.tab8:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, -35)
		
		frame.tab9 = self:CreateTab(frame, 9)
		frame.tab9:SetPoint("TOPLEFT", frame.tab8, "BOTTOMLEFT", 0, -21)
		
		frame.tab10 = self:CreateTab(frame, 10)
		frame.tab10:SetPoint("TOPLEFT", frame.tab9, "BOTTOMLEFT", 0, -21)
		
		frame.tab11 = self:CreateTab(frame, 11)
		frame.tab11:SetPoint("TOPLEFT", frame.tab10, "BOTTOMLEFT", 0, -21)
		
		frame.tab12 = self:CreateTab(frame, 12)
		frame.tab12:SetPoint("TOPLEFT", frame.tab11, "BOTTOMLEFT", 0, -21)
		
		frame.tab13 = self:CreateTab(frame, 13)
		frame.tab13:SetPoint("TOPLEFT", frame.tab12, "BOTTOMLEFT", 0, -21)
		
		frame.tab14 = self:CreateTab(frame, 14)
		frame.tab14:SetPoint("TOPLEFT", frame.tab13, "BOTTOMLEFT", 0, -21)
		
		self.frameNum = self.frameNum + 1
	end

	-- Make sure frame doesn't have an old itemID; make some default assignments
	frame.itemID = nil
	self.lootTable[itemID].frame = frame
	
	-- Hide tabs by default
	for x = 1, 14 do
		frame["tab"..x]:Hide()
	end

	-- Set timer bar starting values and start timer; only create the timer if it doesn't exist
	if not self.lootTable[itemID].timer then
		frame.timerBar:SetValue(100)
		self.lootTable[itemID].timeRemaining = self.lootTable[itemID].lootTimeout
		self.lootTable[itemID].timer = self:ScheduleRepeatingTimer("TimerFeedback", 1, itemID)
	end

	self:UpdateFrame(itemID, 1, frame)
end

function UnstableEPGP:UpdateFrame(itemID, tabNum, frame)
	if not frame and self.db.profile.tabbedFrame == "yes" then
		frame = self.tabbedFrame
		self.lootTable[itemID].frame = self.tabbedFrame
	end
	
	-- If tabbed frame, highlight SELECTED tab
	if tabNum then
		self.currentTab = tabNum
		if self.db.profile.tabbedFrame == "yes" then
			for x = 1, 14 do
				frame["tab"..x].glow:Hide()
			end
			frame["tab"..tabNum].glow:Show()
		end
	end

	if not frame.itemID or frame.itemID ~= itemID then
		frame.itemID = itemID

		local buttonNum = self.lootTable[itemID].buttonNum
		
		-- Set Frame Size
		if buttonNum <= 5 then
			frame:SetSize(350, 440)		
		else
			frame:SetSize(350, 465)
		end
		
		-- Set Close Button script
		frame.CloseButton:SetScript("OnClick", function()
			if self.db.profile.tabbedFrame == "yes" and #self.lootTable > 1 then
				local staticPopup = StaticPopup_Show("CloseTabbedFrame")
				if staticPopup then
					staticPopup.data = frame
				end
			else
				if UnitIsUnit(self.lootTable[itemID].owner, "player") then
					self:DiscardLoot(itemID, false)
					self:SendMessage("UN_Close", nil, itemID)
				else
					-- When closing the window, only update response to "Pass" if no selection was made
					if not self.lootTable[itemID].buttonState then
						self:SendMessage("UN_Response", nil, itemID, self.RESPONSE["pass"].text, self.RESPONSE["pass"].color)
					end
					self:DiscardLoot(itemID, true)
				end
			end
		end)

		-- Set loot button icon and scripts
		frame.lootButton.icon:SetTexture(self.lootTable[itemID].texture)
		self:SetButtonScripts(frame.lootButton, itemID)
	
		-- Set item name, quality, and font size
		frame.lootButton.label:SetText(self.lootTable[itemID].name)
		frame.lootButton.label:SetTextColor(GetItemQualityColor(self.lootTable[itemID].quality))

		local font = GameFontNormal:GetFont()
		if string.len(self.lootTable[itemID].name) > 30 then	
			frame.lootButton.label:SetFont(font, 12)
		else
			frame.lootButton.label:SetFont(font, 14)
		end

		-- Set GP text
		local GP_Label = format("Item Level: %s, GP: %s", self.lootTable[itemID].ilevel, self.lootTable[itemID].gp1 or 0)
		if self.lootTable[itemID].gp2 then
			GP_Label = GP_Label..format(" or %s", self.lootTable[itemID].gp2)
		end
		frame.lootButton.GP_Label:SetText(GP_Label)

		-- Set ML text and class color
		if self.currentML and UnitIsUnit(self.currentML, self.lootTable[itemID].owner) then
			frame.lootButton.ML_Label:SetText("Master Looter: ")
		else
			frame.lootButton.ML_Label:SetText("Distributor: ")
		end
		frame.lootButton.OwnerLabel:SetText(self:Disambiguate(self.lootTable[itemID].owner))
		frame.lootButton.OwnerLabel:SetTextColor(self.lootTable[itemID].ownerColor.r, self.lootTable[itemID].ownerColor.g, self.lootTable[itemID].ownerColor.b)
		
		-- Set Timer Bar values
		frame.timerBar:SetValue((self.lootTable[itemID].timeRemaining/self.lootTable[itemID].lootTimeout)*100)
		frame.timerBar.time:SetText(self:SecToMin(self.lootTable[itemID].timeRemaining))
		-- Change Timer Bar color at 25%
		if (self.lootTable[itemID].timeRemaining/self.lootTable[itemID].lootTimeout)*100 < 25 then
			frame.timerBar:SetStatusBarColor(1,0,0)	
		else
			frame.timerBar:SetStatusBarColor(0,1,0)	
		end
	
		-- Set text and OnClick of Selection Buttons
		for x = 1, 7 do
			frame["button"..x]:SetText(self.lootTable[itemID]["button"..x])
			frame["button"..x]:SetScript("OnClick", function()
				self:UpdateSelectionButtons(itemID, x)
				self:SendMessage("UN_Response", nil, itemID, "1"..x.." "..self.lootTable[itemID]["button"..x], self.lootTable[itemID]["button"..x.."c"])
				self:UN_Response(itemID, format("1%d %s", x, self.lootTable[itemID]["button"..x]), self.lootTable[itemID]["button"..x.."c"], self:Disambiguate(UnitName("player")))
				if not self.lootTable[itemID].allowReselect then
					self:CancelTimer(self.lootTable[itemID].timer)
				end
				if self.db.profile.tabbedFrame == "yes" and self.db.profile.autoAdvance then
					self:ScheduleTimer("SelectionAutoAdvance", 1)
				end
			end)
		end
		
		-- Set number and state of selection buttons, including Pass button
		self:UpdateSelectionButtons(itemID)
		
		-- Set Pass Button Location
		if buttonNum % 2 == 0 then
			frame.buttonPass:SetPoint("TOPLEFT", frame["button" .. buttonNum - 1], "BOTTOMLEFT", 78, -1)
		else
			frame.buttonPass:SetPoint("TOPLEFT", frame["button" .. buttonNum - 1], "BOTTOMLEFT", 0, -1)
		end
		-- Set Pass Button script
		frame.buttonPass:SetScript("OnClick", function()
			self:UpdateSelectionButtons(itemID, 8)
			self:SendMessage("UN_Response", nil, itemID, self.RESPONSE["pass"].text, self.RESPONSE["pass"].color)
			self:UN_Response(itemID, self.RESPONSE["pass"].text, self.RESPONSE["pass"].color, self:Disambiguate(UnitName("player")))
			if not self.lootTable[itemID].allowReselect then
				self:CancelTimer(self.lootTable[itemID].timer)
			end
			if self.db.profile.tabbedFrame == "yes" and self.db.profile.autoAdvance then
				self:ScheduleTimer("SelectionAutoAdvance", 1)
			end
		end)
	
		-- Set Scrolling Data
		frame.scrollTable.itemID = itemID
		frame.scrollTable:SetData(self.lootTable[itemID].scrollData, false)
		frame.scrollTable:RegisterEvents({
			["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
				-- Conditions for showing scroll menu
				if UnitIsUnit(self.lootTable[itemID].owner, "player") and IsInGuild() and CanEditOfficerNote() and EPGP or UnitIsUnit(self.lootTable[itemID].owner, "player") and not EPGP then
					self:ShowScrollMenu(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, itemID, ...)
					return false					
				end
			end,
		})		
	
		-- Set Cancel and Discard Button script
		frame.buttonCancel:SetScript("OnClick", function() self:DiscardLoot(itemID, false) self:SendMessage("UN_Close", nil, itemID) end)
		frame.buttonDiscard:SetScript("OnClick", function()
			-- When closing the window, only update response to "Pass" if no selection was made
			if not self.lootTable[itemID].buttonState then
				self:SendMessage("UN_Response", nil, itemID, self.RESPONSE["pass"].text, self.RESPONSE["pass"].color)
			end
			if self.db.profile.autoAdvance then
				self:ScheduleTimer("SelectionAutoAdvance", 1)
			end
			self:DiscardLoot(itemID, true)
		end)
				
		-- Set GP EditBox value and script
		frame.editBox:SetText(self.lootTable[itemID].gpCost)
		frame.editBox:SetScript("OnLeave", function()
			local value = tonumber(frame.editBox:GetText())
			if type(value) == "number" and value < 100000 and value >= 0 then
				self.lootTable[itemID].gpCost = value
			else
				frame.editBox:SetText(self.lootTable[itemID].gpCost)
			end
			frame.editBox:ClearFocus()
		end)
		
		-- Set state of "Cancel Loot"/"Discard" buttons
		if UnitIsUnit(self.lootTable[itemID].owner, "player") and not self.lootTable[itemID].winner then
			frame.buttonDiscard:Disable()
			frame.buttonCancel:Enable()
		else
			frame.buttonDiscard:Enable()
			frame.buttonCancel:Disable()	
		end

		-- Set visibility of "Cancel Loot"/"Discard" buttons and GP Edit Box
		if UnitIsUnit(self.lootTable[itemID].owner, "player") then
			frame.buttonCancel:Show()
			frame.editBox:Show()
			frame.editBox.label:Show()
			frame.buttonDiscard:Hide()
		else
			frame.buttonCancel:Hide()
			frame.editBox:Hide()
			frame.editBox.label:Hide()
			frame.buttonDiscard:Show()
		end

		frame:Show()
	end
end

function UnstableEPGP:SetButtonScripts(owner, itemID, tabNum)
	if self.lootTable[itemID].link then
		owner:SetScript("OnEnter", function()
			GameTooltip:SetOwner(owner, "ANCHOR_LEFT", -5, 3)
			GameTooltip:SetHyperlink(self.lootTable[itemID].link)
			GameTooltip:Show()
		end)
		owner:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		owner:SetScript("OnClick", function()
			if IsModifiedClick() then
				HandleModifiedItemClick(self.lootTable[itemID].link)
			end
			self:UpdateFrame(itemID, tabNum)
		end)
	else
		owner:SetScript("OnEnter", nil)
		owner:SetScript("OnLeave", nil)
		owner:SetScript("OnClick", nil)
	end
end

function UnstableEPGP:CreateTab(frame, tabNum)
	local tab = CreateFrame("Button", "UN_Tab", frame, "ActionButtonTemplate, AutoCastShineTemplate")
	tab:SetSize(35, 35)
	-- Check Button Glow
	tab.glow = tab:CreateTexture(nil, "OVERLAY", nil)
	tab.glow:SetSize(60, 60)
	tab.glow:SetPoint("CENTER", tab, "CENTER")
	tab.glow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
	tab.glow:Hide()
	-- Shine Stuff
	--ActionButton_HideOverlayGlow, ActionButton_ShowOverlayGlow		
	--AutoCastShine_AutoCastStop, AutoCastShine_AutoCastStart
	tab.shine = SpellBook_GetAutoCastShine()
	tab.shine:Show()
	tab.shine:SetParent(tab)
	tab.shine:SetPoint("CENTER", tab, "CENTER")
	-- Create Tab Border
	tab.border = tab:CreateTexture(nil, "BACKGROUND", nil, -8)
	tab.border:SetSize(75, 72) 
	tab.border:SetTexture("Interface\\SPELLBOOK\\SpellBook-SkillLineTab")
	if tabNum <= 7 then
		tab.border:SetPoint("TOPLEFT", tab, "TOPLEFT", -35, 14)
		tab.border:SetTexCoord(1, 0, 0, 1)
	else
		tab.border:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 34, 14)
		tab.border:SetTexCoord(0, 1, 0, 1)
	end
	return tab
end
