-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Factions/Actions/FireManager.lua
-- *  PURPOSE:     Fire Manager class
-- *
-- ****************************************************************************
FireManager = inherit(Singleton)

local FIRE_TIME_MIN = 15 -- in minutes
local FIRE_TIME_MAX = 30 -- in minutes

function FireManager:constructor()
	self.m_CurrentFire = nil
	self.m_Fires = {}
	self.m_EnabledFires = {} -- just enabled fires which should be switched out randomly

	self.m_FireUpdateBind = bind(FireManager.checkFire ,self)
	self.m_BankAccountServer = BankServer.get("action.fire")
	self.m_FireTimer = setTimer(self.m_FireUpdateBind, 1000 * 60 * math.random(FIRE_TIME_MIN, FIRE_TIME_MAX), 1)

	self.m_RandomFireStrings = { -- blablabla [...]
		"is on fire",
		"reports a fire",
		"has erupted in flames",
		"was evacuated due to a smoke alarm",
	}


	self:loadFirePlaces()

	addRemoteEvents{"receiveFires", "adminFireRequestData", "adminToggleFire", "adminCreateFire", "adminEditFire", "adminDeleteFire"}
	addEventHandler("receiveFires", root, bind(self.receiveFires, self))
	addEventHandler("adminFireRequestData", root, bind(self.Event_adminRequestData, self))
	addEventHandler("adminToggleFire", root, bind(self.Event_toggleFire, self))
	addEventHandler("adminCreateFire", root, bind(self.Event_createFire, self))
	addEventHandler("adminEditFire", root, bind(self.Event_editFire, self))
	addEventHandler("adminDeleteFire", root, bind(self.Event_deleteFire, self))
end

function FireManager:loadFirePlaces()
	local result = sql:queryFetch("SELECT * FROM ??_fires", sql:getPrefix())
	for i, row in pairs(result) do
		self.m_Fires[row.Id] = {
			["name"] = row.Name,
			["message"] = row.Message,
			["position"] = Vector3(row.PosX, row.PosY, row.PosZ),
			["positionTbl"] = {row.PosX, row.PosY, row.PosZ},
			["width"] = row.Width,
			["height"] = row.Height,
			["creator"] = row.Creator,
			["enabled"] = row.Enabled == 1 and true or false,
		}
		if row.Enabled == 1 then
			table.insert(self.m_EnabledFires, row.Id)
		end
	end
end

function FireManager:checkFire()
	if FactionRescue:getSingleton():countPlayers(true, false) >= MIN_PLAYERS_FOR_FIRE and not self.m_CurrentFire then
		local random = math.random(1, 4)
		if random == 4 then
			PlaneManager:getSingleton():createRoute(true)
		else
			self:startRandomFire()
		end
	else
		if isTimer(self.m_FireTimer) then killTimer(self.m_FireTimer) end
		self.m_FireTimer = setTimer(self.m_FireUpdateBind, 1000 * 60 * math.random(FIRE_TIME_MIN, FIRE_TIME_MAX), 1) --start a new fire
	end
end

function FireManager:startRandomFire()
	--//TODO
	self:startFire(self.m_EnabledFires[math.random(1, #self.m_EnabledFires)])
end

function FireManager:startFire(id)
	if self.m_CurrentFire then self:stopCurrentFire() end
	local fireTable = self.m_Fires[id]
	self.m_CurrentFire = FireRoot:new(fireTable.position.x, fireTable.position.y, fireTable.position.z, fireTable["width"] or 20, fireTable["height"] or 20)
	self.m_CurrentFire.m_Id = id
	self.m_CurrentFire:setName(self.m_Fires[id].name)
	self.m_CurrentFire.Blip = Blip:new("Warning.png", fireTable.position.x + fireTable.width/2, fireTable.position.y + fireTable.height/2, root, 400)
	self.m_CurrentFire.Blip:setOptionalColor(BLIP_COLOR_CONSTANTS.Orange)
	self.m_CurrentFire.Blip:setDisplayText("Verkehrsbehinderung")

	self.m_CurrentFire:setOnUpdateHook(bind(self.onUpdateHandler, self))

	self.m_CurrentFire:setOnFinishHook(bind(self.stopCurrentFire, self))
	FactionRescue:getSingleton():sendWarning(fireTable["message"], "Brand-Meldung", true, fireTable.position + Vector3(fireTable.width/2, fireTable.height/2, 0))
	FactionState:getSingleton():sendWarning(fireTable["message"], "Absperrung erforderlich", false, fireTable.position + Vector3(fireTable.width/2, fireTable.height/2, 0))
end

function FireManager:onUpdateHandler(stats)
	if self.m_CurrentFire then
		local activeRescue, acitveState = self.m_CurrentFire:countUsersAtSight()
		if (stats.firesActive >= 20) and (stats.firesActive > math.floor(self.m_CurrentFire:getMaxFireCount()/3)) and (getTickCount() - stats.startTime) > 1000*60*2 then --filter too small and too new fires
			if not self.m_NewsSent then --send initial overview
				self:sendNews(self.m_Fires[self.m_CurrentFire.m_Id]["message"])

				if activeRescue > 0 then
					self:sendNews(("There Are already %d rescue teams on site to fight the fire"):format(activeRescue))
				else
					self:sendNews("No Rescue services have arrived yet")
				end
				if acitveState > 0 then
					if activeRescue > 0 then
						self:sendNews(("In Addition, %d police patrols cordon off the surrounding streets"):format(acitveState))
					else
						self:sendNews(("Nevertheless, the police have stationed %d patrols to cordon off the area"):format(acitveState))
					end
				end
			end
		end
		if (getTickCount() - stats.startTime) > 1000*60*2 and math.random(0, 5) == 0 then
			local size, lastSize = self.m_CurrentFire:getFireSpreadSize()
			if size == lastSize then
				self:sendNews(("There are already %s m² burning"):format(size))
			elseif size < lastSize then
				if activeRescue == 0 then
					self:sendNews(("Only %s m² are still covered with flames"):format(size))
				else
					self:sendNews(("The fire brigade has contained the fire so that only %s m² are still burning"):format(size))
				end
			else
				self:sendNews(("The fire is spreading rapidly, currently it already covers %s m²"):format(size))
			end
		end
	else
		self:sendNews(("The fire was extinguished and the traffic obstruction was cancelled"):format(activeRescue))
	end
end

function FireManager:sendNews(text) -- adapted from PlayerManager
	--[[local fire = self.m_CurrentFire -- DO THIS SOME OTHER TIME!!!!!!!!!!
	local textFinish
	if fire then
		for k, v in pairs(PlayerManager:getSingleton():getReadyPlayers()) do
			if self.m_NewsSent then
				textFinish = _("%s-Brand: %s", v, fire.m_Name, text)
			else
				self.m_NewsSent = true
				textFinish = _("%s", v, text)
			end
			v:triggerEvent("breakingNews", textFinish, "Verkehrsbehinderung")
		end
	end]]
end


function FireManager:getCurrentFire()
	return self.m_CurrentFire
end

function FireManager:stopCurrentFire(stats)
	if stats then
		local playersByID = {}
		local moneyForFaction = 0
		local mostPoints = {}
		for player, score in pairs(stats.pointsByPlayer) do
			if isElement(player) and player:getFaction() and player:getFaction():isRescueFaction() then
				player:giveCombinedReward("Feuer gelöscht", {
					money = {
						mode = "give",
						bank = true,
						amount = score*12,
						toOrFrom = self.m_BankAccountServer,
						category = "Faction",
						subcategory = "Fire"
					},
					points = math.round(score/10),
				})
				playersByID[player:getId()] = score
				moneyForFaction = moneyForFaction + score*32
				table.insert(mostPoints, score)
			end
		end
		self.m_BankAccountServer:transferMoney(FactionRescue:getSingleton().m_Faction, moneyForFaction * table.size(stats.pointsByPlayer), "Fire Extinguished", "Event", "Fire")

		StatisticsLogger:getSingleton():addFireLog(self.m_CurrentFire.m_Id, math.floor(getTickCount()-stats.startTime)/1000, toJSON(playersByID), (table.size(stats.pointsByPlayer) > 0) and 1 or 0, moneyForFaction * table.size(stats.pointsByPlayer))
		
		table.sort(mostPoints, function(a, b) return a > b end)
		local groupLogMessage = self.m_CurrentFire.m_Id == 1000 and ("has extinguished burning crash debris (%s min.) (+%s$).") or ("has extinguished a fire that has broken out (%s min.) (+%s$).")
		FactionRescue:getSingleton().m_Faction:addLog(table.find(playersByID, mostPoints[1]), "Brand", (groupLogMessage):format(math.floor((getTickCount()-stats.startTime)/1000/60), moneyForFaction))
	else -- fire got deleted elsewhere (e.g. admin panel)
		delete(self.m_CurrentFire)
	end
	if self.m_CurrentFire then
		delete(self.m_CurrentFire.Blip)
	end
	self.m_CurrentFire = nil
	self.m_NewsSent = nil

	if isTimer(self.m_FireTimer) then killTimer(self.m_FireTimer) end
	self.m_FireTimer = setTimer(self.m_FireUpdateBind, 1000 * 60 * math.random(FIRE_TIME_MIN, FIRE_TIME_MAX), 1) --start a new fire
end

function FireManager:receiveFires()
	if self.m_CurrentFire then
		self.m_CurrentFire:syncFires(client)
	end
end

--Admin / Dev methods

function FireManager:Event_adminRequestData()
	if client:getRank() < ADMIN_RANK_PERMISSION["fireMenu"] then
		client:sendError(_("You are not authorised to use this function!", client))
		return
	end
	self:sendAdminFireData(client)
end

function FireManager:sendAdminFireData(player)
	player:triggerEvent("adminFireReceiveData", self.m_Fires, self.m_CurrentFire and self.m_CurrentFire.m_Id)
end

function FireManager:Event_toggleFire(id)
	if client:getRank() < ADMIN_RANK_PERMISSION["toggleFire"] then
		client:sendError(_("You are not authorised to use this function!", client))
		return
	end
	if self:getCurrentFire() then
		if self:getCurrentFire().m_Id == id then
			self:stopCurrentFire()
		else
			self:startFire(id)
		end
	else
		self:startFire(id)
	end
	self:sendAdminFireData(client)
end

function FireManager:Event_createFire()
	if client:getRank() < ADMIN_RANK_PERMISSION["editFire"] then
		client:sendError(_("You are not authorised to use this function!", client))
		return
	end

	if sql:queryExec("INSERT INTO ??_fires (Name, Creator) VALUES(?, ?);", sql:getPrefix(), "neues Feuer",	client:getName()) then
		self.m_Fires[sql:lastInsertId()] = {
				["name"] = "neues Feuer",
				["message"] = "",
				["position"] = Vector3(0, 0, 4),
				["positionTbl"] = {0, 0, 4},
				["width"] = 10,
				["height"] = 10,
				["creator"] = client:getName(),
				["enabled"] = false,
			}

		client:sendSuccess(_("fire with the ID %d, you can now edit it.", client, sql:lastInsertId()))
		self:sendAdminFireData(client)
	else
		client:sendError(_("New fire could not be added to the database.", client))
	end
end

function FireManager:Event_editFire(id, tblArgs)
	if client:getRank() < ADMIN_RANK_PERMISSION["editFire"] then
		client:sendError(_("You are not authorised to use this function!", client))
		return
	end
	if tblArgs.generateMsg then
		tblArgs.message = self:generateMessage(tblArgs.position, tblArgs.width, tblArgs.height)
	end
	--update db
	sql:queryExec("UPDATE ??_fires SET Name = ?, Message = ?, Enabled = ?, PosX = ?, PosY = ?, PosZ = ?, Width = ?, Height = ? WHERE Id = ?;", sql:getPrefix(),
		tostring(tblArgs.name) or "name failed to save",
		tostring(tblArgs.message) or "msg failed to save",
		tblArgs.enabled and 1 or 0,
		tblArgs.position.x,
		tblArgs.position.y,
		tblArgs.position.z,
		tblArgs.width,
		tblArgs.height,
		id
	)


	--update InGame fire cache
	self.m_Fires[id]["name"] = tblArgs.name
	self.m_Fires[id]["message"] = tblArgs.message
	self.m_Fires[id]["enabled"] = tblArgs.enabled
	self.m_Fires[id]["position"] = normaliseVector(tblArgs.position)
	self.m_Fires[id]["positionTbl"] = {tblArgs.position.x, tblArgs.position.y, tblArgs.position.z}
	self.m_Fires[id]["width"] = tblArgs.width
	self.m_Fires[id]["height"] = tblArgs.height

	if self.m_Fires[id]["enabled"] then
		table.insert(self.m_EnabledFires, Id)
	else
		table.removevalue(self.m_EnabledFires, Id)
	end

	client:sendSuccess(_("Fire %d saved.", client, id))
	self:sendAdminFireData(client) -- resend data (update client UI)
end


function FireManager:generateMessage(position, width, height)
	local tempArea = createColRectangle(position.x, position.y, width, height)
	local zoneName = getZoneName(position.x, position.y, position.z)
	for i, v in pairs(getElementsWithinColShape(tempArea, "pickup")) do
		outputDebug(v)
		if v.m_PickupType == "House" then -- TODO: add more types
			return ("%s in %s %s"):format(
				((zoneName == "Mulholland" or zoneName == "Richman") and ("Eine Villa" or "Ein Haus")),
				zoneName,
				self.m_RandomFireStrings[math.random(1, #self.m_RandomFireStrings)])
		elseif v.m_PickupType == "GroupProperty" then
			return ("The property '%s' in %s %s"):format(
				v.m_PickupName,
				zoneName,
				self.m_RandomFireStrings[math.random(1, #self.m_RandomFireStrings)])
		end
	end
	return "No suitable properties found"
end

function FireManager:Event_deleteFire(id)
	if client:getRank() < ADMIN_RANK_PERMISSION["editFire"] then
		client:sendError(_("You are not authorised to use this function!", client))
		return
	end
	sql:queryExec("DELETE FROM ??_fires  WHERE Id = ?;", sql:getPrefix(), id)
	if self:getCurrentFire() and self:getCurrentFire().m_Id == id then
		self:stopCurrentFire()
	end
	self.m_Fires[id] = nil
	client:sendSuccess(_("Fire %d extinguished.", client, id))
	self:sendAdminFireData(client)
end
