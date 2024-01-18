QuestManager = inherit(Singleton)
QuestManager.Quests = {
	[1] = {
		["Name"] = "Christmas-Bodyguard",
		["Description"] = "Bring Santa to the marked location in Montgomery!",
		["Packages"] = 5,
	},
	
	[2] = {
		["Name"] = "Santa Claus Selfie",
		["Description"] = "Find Santa Claus (he's in Los Santos) and take a photo of him!",
		["Packages"] = 10,
	},
	[3] = {
		["Name"] = "Christmas-Bodyguard",
		["Description"] = "Bring Santa to the marked location in Montgomery!",
		["Packages"] = 5,
	},
	[4] = {
		["Name"] = "Parcel transportation",
		["Description"] = "Deliver the parcels to the indicated location! Take good care of the trailer!",
		["Packages"] = 5,
	},
	[5] = {
		["Name"] = "Christmas Photographer",
		["Description"] = "Schieße ein Foto mit mindestens 3 Spielern darauf!",
		["Packages"] = 5,
	},
	[6] = {
		["Name"] = "Christmas murders",
		["Description"] = "Find the burglars in the areas marked in orange and kill them!",
		["Packages"] = 5,
	},
	[7] = {
		["Name"] = "Parcel finder",
		["Description"] = "Finde 5 Päckchen und klicke diese an!",
		["Packages"] = 5,
	},
	[8] = {
		["Name"] = "Parcel transportation",
		["Description"] = "Deliver the parcels to the indicated location! Take good care of the trailer!",
		["Packages"] = 5,
	},
	[9] = {
		["Name"] = "Wheel of fortune master",
		["Description"] = "Play the wheel of fortune 3 times! You must have started the quest in the meantime!",
		["Packages"] = 5,
	},
	[10] = {
		["Name"] = "End of the Day",
		["Description"] = "There's nothing to do today! Here's your reward!",
		["Packages"] = 5,
	},
	[11] = {
		["Name"] = "Parcel transportation",
		["Description"] = "Deliver the parcels to the indicated location! Take good care of the trailer!",
		["Packages"] = 5,
	},
	[12] = {
		["Name"] = "Ferris Wheel Rriver",
		["Description"] = "Ride two rounds on the Ferris wheel (the gondola must stop at the stairs again)!",
		["Packages"] = 5,
	},
	[13] = {
		["Name"] = "Christmas murders",
		["Description"] = "Find the burglars in the areas marked in orange and kill them!",
		["Packages"] = 5,
	},
	[14] = {
		["Name"] = "Cap photo",
		["Description"] = "Take a photo with at least 3 players wearing a Christmas hat!",
		["Packages"] = 5,
	},
	[15] = {
		["Name"] = "Christmas-Bodyguard",
		["Description"] = "Bring Santa Claus to the marked location in Los Santos!",
		["Packages"] = 5,
	},
	[16] = {
		["Name"] = "Parcel transportation",
		["Description"] = "Deliver the parcels to the indicated location! Take good care of the trailer!",
		["Packages"] = 5,
	},
	[17] = {
		["Name"] = "Looking forward",
		["Description"] = "There's nothing to do today! Here's your reward!",
		["Packages"] = 5,
	},
	[18] = {
		["Name"] = "Wheel of fortune master",
		["Description"] = "Play the wheel of fortune 3 times! You must have started the quest during this time!",
		["Packages"] = 5,
	},
	[19] = {
		["Name"] = "Parcel Finder",
		["Description"] = "Find 5 parcels and click on them!",
		["Packages"] = 5,
	},
	[20] = {
		["Name"] = "Administrative photographer",
		["Description"] = "Take a photo with at least 1 team member!",
		["Packages"] = 5,
	},
	[21] = {
		["Name"] = "Ferris Wheel Rriver",
		["Description"] = "Ride two rounds on the Ferris wheel (the gondola must stop at the stairs again)!",
		["Packages"] = 5,
	},
	[22] = {
		["Name"] = "Christmas Murders",
		["Description"] = "Find the burglars in the areas marked in orange and kill them!",
		["Packages"] = 5,
	},
	[23] = {
		["Name"] = "Wheel of fortune master",
		["Description"] = "Play the wheel of fortune 3 times! You must have started the quest during this time!",
		["Packages"] = 5,
	},
	[24] = {
		["Name"] = "Family Day",
		["Description"] = "We don't want to keep you any longer today! Here's your reward!",
		["Packages"] = 5,
	},
}

function QuestManager:constructor()
	-- Also add it client side if the quest requires a clientside script
	-- The client side quest automatically starts on startQuestForPlayer if the class is setted on clientside Questmanager
	self.m_Quests = {
		[1] = QuestNPCTransport,
		[2] = QuestPhotography,
		[3] = QuestNPCTransport,
		[4] = QuestPackageTransport,
		[5] = QuestPhotography,
		[6] = QuestSantaKill,
		[7] = QuestPackageFind,
		[8] = QuestPackageTransport,
		[9] = QuestFortuneWheel,
		[10] = QuestNoQuest,
		[11] = QuestPackageTransport,
		[12] = QuestFerrisRide,
		[13] = QuestSantaKill,
		[14] = QuestPhotography,
		[15] = QuestNPCTransport,
		[16] = QuestPackageTransport,
		[17] = QuestNoQuest,
		[18] = QuestFortuneWheel,
		[19] = QuestPackageFind,
		[20] = QuestPhotography,
		[21] = QuestFerrisRide,
		[22] = QuestSantaKill,
		[23] = QuestFortuneWheel,
		[24] = QuestNoQuest,
	}
	self.m_CurrentQuest = false


	addRemoteEvents{"questOnPedClick", "questStartClick", "questShortMessageClick"}
	addEventHandler("questOnPedClick", root, bind(self.onPedClick, self))
	addEventHandler("questStartClick", root, bind(self.onStartClick, self))
	addEventHandler("questShortMessageClick", root, bind(self.onShortMessageClick, self))

	PlayerManager:getSingleton():getQuitHook():register(bind(self.onPlayerQuit, self))
	PlayerManager:getSingleton():getWastedHook():register(bind(self.onPlayerQuit, self))
	PlayerManager:getSingleton():getAFKHook():register(bind(self.onPlayerQuit, self))

	if DEBUG then
		addCommandHandler("quest", function(player, cmd, id)
			local id = tonumber(id)
			if (id and id >= 1 and id <= 24) then
				self:startQuest(id)
				player:sendInfo(_("Quest %s started", player, id))
			else
				player:sendError(_("Please provide a valid quest number (1-24)!", player))
			end
		end)
	else
		self:getTodayQuest()
	end
	GlobalTimer:getSingleton():registerEvent(bind(self.getTodayQuest, self), "Christmas-Quests", nil, 00, 5)

end

function QuestManager:startQuest(questId)
	if not self.m_Quests[questId] then return end
	if self.m_CurrentQuest then self:stopQuest() end

	self.m_CurrentQuest = self.m_Quests[questId]:new(questId)
end

function QuestManager:getTodayQuest()
	local day = getRealTime().monthday
	local month = getRealTime().month+1

	if month ~= 12 then	return end
	if not self.m_Quests[day] then return end

	self:startQuest(day)
end

function QuestManager:startQuestForPlayer(player)
	if not self.m_CurrentQuest then
		return false
	end
	if table.find(self.m_CurrentQuest:getPlayers(), player) then
		player:sendError("You've already started the quest!")
		return
	end

	if self.m_CurrentQuest:isQuestDone(player) then
		player:sendError("You've already completed the quest!")
		return
	end

	self.m_CurrentQuest:addPlayer(player)
end

function QuestManager:endQuestForPlayer(player)
	self.m_CurrentQuest:removePlayer(player)
end


function QuestManager:onStartClick()
	if not self.m_CurrentQuest then
		client:sendError("No quest is currently running!")
		return false
	end
	self:startQuestForPlayer(client)
end

function QuestManager:onPedClick()
	if not self.m_CurrentQuest then
		client:sendError("No quest is currently running!")
		return false
	end
	self.m_CurrentQuest:onClick(client)
end

function QuestManager:stopQuest()
	for index, player in pairs(self.m_CurrentQuest:getPlayers()) do
		if player and isElement(player) then
			self:endQuestForPlayer(player)
		end
	end

	delete(self.m_CurrentQuest)
	self.m_CurrentQuest = false
end

function QuestManager:onShortMessageClick()
	QuestionBox:new(client, "Do you want to abort the quest " .. self.m_CurrentQuest.m_Name .. "? You can start it again anytime.",
	function()
		self:endQuestForPlayer(client)
	end,
	function()
		self:endQuestForPlayer(client)
		self:startQuestForPlayer(client)
	end
)
end

function QuestManager:onPlayerQuit(player)
	if self.m_CurrentQuest then
		if table.find(self.m_CurrentQuest:getPlayers(), player) then
			self:endQuestForPlayer(player)
		end
	end
end

--[[
Quest System:

1) Bring Santa Claus to one point
2) Take a picture of Santa Claus (somewhere on the map)
3) Take a photo with at least 10 players in the picture
4) Draw a nice Santa Claus (will be confirmed by admins)
5) Bring Santa Claus to one point
6) Bring the package to a drop-off point
7) Find 5 packages (will only be distributed on this day)
8) Kill 3 Santas (spawn at NPC positions)
9) Complete the course (mapped)
10) Draw a snowman (confirmed by admins)
11) Find the package using the radar (radar from treasure hunter job) several random positions that change after each find
12) Take a picture of Santa Claus (located somewhere on the map)
13) Bring a wrapping paper to Santa Claus
14) Play the wheel of fortune 5 times
15) Complete the course (mapped)
16) Take a photo with at least 5 players with hats in the picture
17.) Bring Santa Claus to one point
18) Bring the package to a drop-off point
19) Kill 3 Santas (spawn at NPC positions)
20.) Play the wheel of fortune 5 times
21) Bring the package to a drop-off location
22) Get alcohol poisoning from the mulled wine
23) Find the package using the radar (radar from treasure hunter job) several random positions that change after each find
24) No task today, spend the day with your family - free parcel!

]]
