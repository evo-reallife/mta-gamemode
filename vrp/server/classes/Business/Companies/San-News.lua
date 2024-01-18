SanNews = inherit(Company)

function SanNews:constructor()
	self.m_isInterview = false
	self.m_InterviewPlayer = {}
	self.m_Blips = {}
	self.m_NextAd = getRealTime().timestamp
	self.m_onInterviewColshapeLeaveFunc = bind(self.onInterviewColshapeLeave, self)
	self.m_onPlayerChatFunc = bind(self.Event_onPlayerChat, self)
	self.m_SanNewsMessageEnabled = false
	self.m_RunningEvent = false

	local safe = createObject(2332, 732.40, -1341.90, 13, 0, 0, 90)
 	self:setSafe(safe)

	local id = self:getId()
	local blip = Blip:new("House.png", 732.40, -1339.90, {company = id}, 400, {companyColors[id].r, companyColors[id].g, companyColors[id].b})
	blip:setDisplayText(self:getName(), BLIP_CATEGORY.Company)

   	Gate:new(968, Vector3(781.40, -1384.60, 13.50), Vector3(0, 90, 180), Vector3(781.40, -1384.60, 13.50), Vector3(0, 5, 180), false).onGateHit = bind(self.onBarrierHit, self)
	Gate:new(968, Vector3(781.30, -1330.30, 13.40), Vector3(0, 90, 180), Vector3(781.30, -1330.30, 13.40), Vector3(0, 5, 180), false).onGateHit = bind(self.onBarrierHit, self)

	-- Register in Player Hooks
	Player.getQuitHook():register(bind(self.Event_onPlayerQuit, self))
	Player.getChatHook():register(bind(self.Event_onPlayerChat, self))

	addRemoteEvents{"sanNewsStartInterview", "sanNewsStopInterview", "sanNewsAdvertisement", "sanNewsToggleMessage", "sanNewsStartStreetrace", "sanNewsAddBlip", "sanNewsDeleteBlips"}
	addEventHandler("sanNewsStartInterview", root, bind(self.Event_startInterview, self))
	addEventHandler("sanNewsStopInterview", root, bind(self.Event_stopInterview, self))
	addEventHandler("sanNewsAdvertisement", root, bind(self.Event_advertisement, self))
	addEventHandler("sanNewsToggleMessage", root, bind(self.Event_toggleMessage, self))
	addEventHandler("sanNewsStartStreetrace", root, bind(self.Event_startStreetrace, self))
	addEventHandler("sanNewsAddBlip", root, bind(self.Event_addBlip, self))
	addEventHandler("sanNewsDeleteBlips", root, bind(self.Event_deleteBlips, self))

	addCommandHandler("news", bind(self.Event_news, self))
	addCommandHandler("sannews", bind(self.Event_sanNewsMessage, self), false, false)
end

function SanNews:destuctor()

end

function SanNews:onBarrierHit(player)
    if player:getCompany() ~= self then
        return false
    end
    return true
end

function SanNews:Event_news(player, cmd, ...)
	if player:getCompany() == self then
		if player:isCompanyDuty() then
			local argTable = { ... }
			local text = table.concat ( argTable , " " )
			outputChatBox(_("#FE8D14Reporter %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)

    		local receivedPlayers = {}
			for k, targetPlayer in pairs(PlayerManager:getSingleton():getReadyPlayers()) do
				if targetPlayer ~= player then
					if targetPlayer:isLoggedIn() then
						receivedPlayers[#receivedPlayers+1] = targetPlayer
					end
				end
			end
			StatisticsLogger:getSingleton():addChatLog(player, "news", text, receivedPlayers)
		else
			player:sendError(_("You are not on duty!", player))
		end
	end
end

function SanNews:Event_startInterview(target)
	if client:getCompany() == self then
		if client:isCompanyDuty() then
			if not self.m_isInterview then
				self.m_isInterview = true
				self.m_InterviewColshape = createColSphere(client.position, 4)
				self.m_InterviewColshape:attach(client)

				client:sendInfo(_("You have started an interview with %s!", client, target.name))
				target:sendInfo(_("Reporter %s has started an interview with you!", target, client.name))
				target:sendShortMessage(_("Interview: Everything you write in the chat is now public! (Exception: @l [text])", target))
				self:addInterviewPlayer(client)
				self:addInterviewPlayer(target)
			else
				client:sendError(_("An interview is already taking place!", client))
			end
		else
			client:sendError(_("You are not on duty!", client))
		end
	end
end

function SanNews:addInterviewPlayer(player)
	table.insert(self.m_InterviewPlayer, player)
	player:setPublicSync("inInterview", true)
end

function SanNews:Event_stopInterview(target)
    if client:getCompany() == self then
        if client:isCompanyDuty() then
            client:sendInfo(_("You have ended the interview with %s!", client, target.name))
            target:sendInfo(_("Reporter %s has ended the interview with you!", target, client.name))
            self:stopInterview()
        else
            client:sendError(_("You are not on duty!", client))
        end
    end
end


function SanNews:Event_onPlayerQuit()
	if table.find(self.m_InterviewPlayer, source) then
		for index, player in pairs(self.m_InterviewPlayer) do
			player:sendInfo(_("Interview finished! A player has gone offline!", player))
		end
		self:stopInterview()
	end
end

function SanNews:onInterviewColshapeLeave(leaveElement)
	if table.find(self.m_InterviewPlayer, leaveElement) then
		for index, player in pairs(self.m_InterviewPlayer) do
			player:sendInfo(_("Interview finished! You have strayed too far!", player))
		end
		self:stopInterview()
	end
end

function SanNews:stopInterview()
	for index, player in pairs(self.m_InterviewPlayer) do
		player:setPublicSync("inInterview", false)
	end
	self.m_isInterview = false
	self.m_InterviewPlayer = {}
	self.m_InterviewColshape:destroy()
end

function SanNews:Event_onPlayerChat(player, text, type)
	if type == 0 then
		if table.find(self.m_InterviewPlayer, player) then
			if text:sub(1, 2):lower() ~= "@l" then
				if player:getCompany() == self and player:isCompanyDuty() then
					outputChatBox(_("#FE8D14Reporter %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)
				else
					outputChatBox(_("#FE8D14[Interview] %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)
				end

				local receivedPlayers = {}
				for k, targetPlayer in pairs(getElementsByType("player")) do
					if targetPlayer ~= player then
						if targetPlayer:isLoggedIn() then
							receivedPlayers[#receivedPlayers+1] = targetPlayer
						end
					end
				end
				StatisticsLogger:getSingleton():addChatLog(player, "interview", text, receivedPlayers)
				return true
			end
		end
	end
end

function SanNews:Event_advertisement(senderIndex, text, color, duration)
	local length = text:len()
	if length <= 50 and length >= 5 then
		local durationExtra = (AD_DURATIONS[duration] - 20) * 2
		local colorMultiplicator = 1
		if color ~= "Schwarz" then
			colorMultiplicator = 2
		end

		local costs = (length*AD_COST_PER_CHAR + AD_COST + durationExtra) * colorMultiplicator

		if client:getBankMoney() >= costs then
			if self.m_NextAd < getRealTime().timestamp then
				client:transferBankMoney({self, nil, true}, costs, "San News Ad", "Company", "Ads")
				self.m_NextAd = getRealTime().timestamp + AD_DURATIONS[duration] + AD_BREAK_TIME
				StatisticsLogger:getSingleton():addAdvert(client, text)

				local sender = {referenz = "player", name = client:getName()}
				if senderIndex == 2 and client:getGroup() and client:getGroup():getName() then
					sender = {referenz = "group", name = client:getGroup():getName(), number = client:getGroup():getPhoneNumber()}
				elseif senderIndex == 3 and client:getFaction() and client:getFaction():getShortName() then
					sender = {referenz = "faction", name = client:getFaction():getShortName(), number = client:getFaction():getPhoneNumber()}
				elseif senderIndex == 4 and client:getCompany() and client:getCompany():getShortName() then
					sender = {referenz = "company", name = client:getCompany():getShortName(), number = client:getCompany():getPhoneNumber()}
				end

				triggerClientEvent("showAd", client, sender, text, color, duration)
			else
				local next = self.m_NextAd - getRealTime().timestamp
				client:sendError(_("The next advertisement can only be sent in %d seconds!", client, next))
			end
		else
			client:sendError(_("You don't have enough money with you! (%s$)", client, costs))
		end
	end
end

function SanNews:Event_toggleMessage()
	if self.m_SanNewsMessageEnabled then
		self.m_SanNewsMessageEnabled = false
		self:sendShortMessage(("%s hat /sannews deactivated!"):format(client:getName()))
	else
		self.m_SanNewsMessageEnabled = true
		self:sendShortMessage(("%s hat /sannews activated!"):format(client:getName()))
	end
end

function SanNews:Event_startStreetrace()
	if PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "startStreetRace") then
		if not EventManager:getSingleton():isEvent(self.m_RunningEvent) then
			self.m_RunningEvent = EventManager:getSingleton():openRandomEvent()
			self:addLog(client, "Events", "has started a street race!")
		else
			client:sendError("An event is already running!")
		end
	else
		client:sendError(_("You are not authorized to start a road race!", client))
	end
end

function SanNews:Event_addBlip(posX, posY, text)
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "addBlip") then
		client:sendError("You are not authorized to create markers!")
		return
	end

	local id = self:getId()
	local color = {companyColors[id].r, companyColors[id].g, companyColors[id].b}
	local blipName = ("San News - %s"):format(text or "Marker")
	local blip = Blip:new("Marker.png", posX, posY, root, 10000, color)
	blip:setDisplayText(blipName, BLIP_CATEGORY.Default)
	table.insert(self.m_Blips, blip)

	self:addLog(client, "Marker", ("created a marker: %s"):format(blipName))
	--PlayerManager:getSingleton():sendShortMessage("Die San News hat einen Ort auf der Karte markiert!", ("San News - %s"):format(text or "Marker"), color, 15000)
end

function SanNews:Event_deleteBlips()
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "addBlip") then
		client:sendError("You are not authorized to remove markers!")
		return
	end

	for _, blip in pairs(self.m_Blips) do
		blip:delete()
	end
	self.m_Blips = {}

	client:sendInfo("All blips removed!")
end

function SanNews:Event_sanNewsMessage(player, cmd, ...)
	if self.m_SanNewsMessageEnabled then
		local argTable = {...}
		local msg = table.concat(argTable, " ")
		StatisticsLogger:getSingleton():addChatLog(player, "sannews", msg, self:getOnlinePlayers())
		self:sendMessage(("#9cff00[SanNews-Message] %s: #FFFFFF%s"):format(player:getName(), msg), 255, 255 ,0, true)
		player:sendMessage(("#9cff00[Msg an Sannews]: #FFFFFF%s"):format(msg), 255, 255 ,0, true)
	else
		player:sendError(_("Die SanNews hat /sannews currently deactivated!", player))
	end
end
