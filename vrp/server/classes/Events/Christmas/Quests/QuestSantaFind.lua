QuestSantaFind = inherit(Quest)

QuestSantaFind.Targets = {
	[2] = {
		["SantaClaus"] = 1,
	},
	[3] = {
		["Players"] = 10,
	},
	[16] = {
		["PlayersWithHat"] = 5,
	}
}

function QuestSantaFind:constructor(id)
	Quest.constructor(self, id)

	self.m_Target = QuestSantaFind.Targets[id]

	self.m_TakePhotoBind = bind(self.onTakePhoto, self)

	addRemoteEvents{"questPhotograpyTakePhoto"}
	addEventHandler("questPhotograpyTakePhoto", root, self.m_TakePhotoBind)
end

function QuestSantaFind:destructor(id)
	Quest.destructor(self)
	removeEventHandler("questPhotograpyTakePhoto", root, self.m_TakePhotoBind)
end

function QuestSantaFind:addPlayer(player)
	Quest.addPlayer(self, player)
	player:giveWeapon(43, 50)
end

function QuestSantaFind:onTakePhoto(playersOnPhoto, pedsOnPhoto)

	if self.m_Target["SantaClaus"] then
		for index, ped in pairs(pedsOnPhoto) do
			if ped:getModel() == 244 then
				client:sendSuccess(_("Congratulations! You have photographed Santa Claus!", client))
				self:success(client)
				return
			end
		end
		client:sendError(_("There's no Santa Claus in your photo!", client))
		return
	elseif self.m_Target["Players"] then
		if #playersOnPhoto >= self.m_Target["Players"] then
			client:sendSuccess(_("You've successfully photographed 10 players!", client))
			self:success(client)
			return
		else
			client:sendError(_("There are not enough players in your photo (%d/%d)", client, #playersOnPhoto, self.m_Target["Players"]))
			return
		end
	elseif self.m_Target["PlayersWithHat"] then
		local count = 0
		for index, player in pairs(playersOnPhoto) do
			if player.m_IsWearingHelmet and player.m_IsWearingHelmet == "Weihnachtsmütze" then
				count = count +1
			end
		end
		if count > self.m_Target["PlayersWithHat"] then
			client:sendSuccess(_("You have successfully photographed 5 players with Christmas hats!", client))
			self:success(client)
			return
		else
			client:sendError(_("There are not enough players with Christmas hats in your photo! (%d/%d)", client, count, self.m_Target["PlayersWithHat"]))
			return
		end
	end

	client:sendError(_("Your photo doesn't match the quest task!", client))
end
