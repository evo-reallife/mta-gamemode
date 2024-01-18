QuestDraw = inherit(Quest)

QuestDraw.Targets = {
	[4] = "SantaClaus",
	[10] = "SnowMan",
	[17] = "ChristmasTree"
}

function QuestDraw:constructor(id)
	Quest.constructor(self, id)

	self.m_Target = QuestPhotography.Targets[id]

	self.m_RequestPlayersBind = bind(self.requestPlayers, self)
	self.m_AcceptImageBind = bind(self.acceptImage, self)
	self.m_DeclineImageBind = bind(self.declineImage, self)
	self.m_PictureSavedImageBind = bind(self.savedImage, self)
	self.m_NoScreenshotAllowedBind = bind(self.noScreenShot, self)

	addCommandHandler("drawquest", function(player)
		if player:getRank() >= RANK.Moderator then
			player:triggerEvent("questDrawShowAdminGUI")
		end
	end)

	addRemoteEvents{"questDrawRequestPlayers", "questDrawReceiveAcceptImage", "questDrawReceiveDeclineImage", "questDrawPictureSaved", "questDrawNoScreenshotAllowed"}
	addEventHandler("questDrawRequestPlayers", root, self.m_RequestPlayersBind)
	addEventHandler("questDrawReceiveAcceptImage", root, self.m_AcceptImageBind)
	addEventHandler("questDrawReceiveDeclineImage", root, self.m_DeclineImageBind)
	addEventHandler("questDrawPictureSaved", root, self.m_PictureSavedImageBind)
	addEventHandler("questDrawNoScreenshotAllowed", root, self.m_NoScreenshotAllowedBind)

end

function QuestDraw:destructor(id)
	Quest.destructor(self)

	removeEventHandler("questDrawRequestPlayers", root, self.m_RequestPlayersBind)
	removeEventHandler("questDrawReceiveAcceptImage", root, self.m_AcceptImageBind)
	removeEventHandler("questDrawReceiveDeclineImage", root, self.m_DeclineImageBind)
	removeEventHandler("questDrawPictureSaved", root, self.m_PictureSavedImageBind)
	removeEventHandler("questDrawNoScreenshotAllowed", root, self.m_NoScreenshotAllowedBind)

end

function QuestDraw:requestPlayers()
	self:sendToClient(client)
end

function QuestDraw:addPlayer(player)
	Quest.addPlayer(self, player)
	local contestName = self.m_Name
	local result = sql:queryFetchSingle("SELECT Accepted FROM ??_drawContest WHERE Contest = ? AND UserId = ?", sql:getPrefix(), contestName, player:getId())
	if result then
		if not result["Accepted"] or result["Accepted"] == 0 then -- Picture Pending
			player:sendWarning("Your submitted drawing has not yet been approved by an admin!")
			self:removePlayer(player)
		elseif result["Accepted"] == 1 then
			player:sendSuccess("Congratulations! Your drawing has been approved by an admin! Here is your reward!")
			sql:queryExec("UPDATE ??_drawContest SET Accepted = 2 WHERE Contest = ? AND UserId = ?", sql:getPrefix(), contestName, player:getId())
			self:success(client)

		elseif result["Accepted"] == 2 then
			player:sendError("You have already received your reward for this quest!")
			self:removePlayer(player)
		elseif result["Accepted"] == 3 then
			player:sendError("Your drawing was rejected! You didn't draw nicely enough!")
			self:removePlayer(player)
		end
	else
		player:triggerEvent("questDrawShowSkribble")
	end
end

function QuestDraw:sendToClient(player)
	local contestName = self.m_Name
	local players = {}
	local result = sql:queryFetch("SELECT Id, UserId, ImageUrl FROM ??_drawContest WHERE Contest = ? AND (Accepted IS NULL OR Accepted = 0)", sql:getPrefix(), contestName)
    if not result then return end

	for i, row in pairs(result) do
		players[row.UserId] = {drawId = row.Id, name = Account.getNameFromId(row.UserId), url = row.ImageUrl}
	end

	player:triggerEvent("questDrawReceivePlayers", contestName, players)
end

function QuestDraw:acceptImage(drawId)
	if client:getRank() < RANK.Moderator then
		return
	end

	local contestName = self.m_Name
	if not contestName then client:sendError("Currently there is no drawing competition!") return end

	sql:queryExec("UPDATE ??_drawContest SET Accepted = 1 AND Hidden = 0 WHERE Id = ?", sql:getPrefix(), drawId)
	client:sendSuccess("You have successfully accepted the drawing!")
	self:sendToClient(client)
end

function QuestDraw:declineImage(drawId)
	if client:getRank() < RANK.Moderator then
		return
	end

	local contestName = self.m_Name
	if not contestName then client:sendError("Currently there is no drawing competition!") return end

	sql:queryExec("UPDATE ??_drawContest SET Accepted = 3 WHERE Id = ?", sql:getPrefix(), drawId)
	client:sendSuccess("You have rejected the drawing!")
	self:sendToClient(client)
end

function QuestDraw:savedImage()
	client:sendShortMessage("Your drawing must be confirmed!\nCome back later and start the quest again!")
	self:removePlayer(client)
end

function QuestDraw:noScreenShot()
	client:sendError("Please activate the option \"Allow screenshots\" under MTA -> Settings to do the quest!")
	self:removePlayer(client)
end
