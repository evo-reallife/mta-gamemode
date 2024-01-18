QuestPhotography = inherit(Quest)

QuestPhotography.Targets = {
	[2] = {
		["SantaClaus"] = 1,
	},
	[5] = {
		["Players"] = 3,
	},
	[14] = {
		["PlayersWithHat"] = 3,
	},
	[20] = {
		["Admins"] = 1,
	}
}

function QuestPhotography:constructor(id)
	Quest.constructor(self, id)

	self.m_Target = QuestPhotography.Targets[id]

	if id == 2 then
		--setGarageOpen(9, true)
		self.m_NPC = NPC:new(244, 2151.49, -1015.52, 69.04, 129)
		self.m_NPC:setImmortal(true)
		self.m_NPC:setFrozen(true)
	end

	self.m_TakePhotoBind = bind(self.onTakePhoto, self)

	addRemoteEvents{"questPhotograpyTakePhoto"}
	addEventHandler("questPhotograpyTakePhoto", root, self.m_TakePhotoBind)
end

function QuestPhotography:destructor(id)
	Quest.destructor(self)
	if self.m_NPC and isElement(self.m_NPC) then
		setGarageOpen(9, false)
		self.m_NPC:destroy()
	end
	removeEventHandler("questPhotograpyTakePhoto", root, self.m_TakePhotoBind)
end

function QuestPhotography:addPlayer(player)
	Quest.addPlayer(self, player)
	player:giveWeapon(43, 50)
end

function QuestPhotography:onTakePhoto(playersOnPhoto, pedsOnPhoto)
	if table.find(self:getPlayers(), client) then
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
				client:sendSuccess(_("You've successfully photographed 3 players!", client))
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
			if count >= self.m_Target["PlayersWithHat"] then
				client:sendSuccess(_("You have successfully photographed 3 players with Christmas hats!", client))
				self:success(client)
				return
			else
				client:sendError(_("There are not enough players with Christmas hats in your photo! (%d/%d)", client, count, self.m_Target["PlayersWithHat"]))
				return
			end
		elseif self.m_Target["Admins"] then
			local count = 0
			for index, player in pairs(playersOnPhoto) do
				if player:getRank() > 0 then
					count = count +1
				end
			end
			if count >= self.m_Target["Admins"] then
				client:sendSuccess(_("You have successfully photographed a team member!", client))
				self:success(client)
				return
			else
				client:sendError(_("There are too few team members in your photo! (%d/%d)", client, count, self.m_Target["Admins"]))
				return
			end
		end
		client:sendError(_("Your photo doesn't match the quest task!", client))
	end
end
