-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Actions/WeaponTruck.lua
-- *  PURPOSE:     Weapon Truck Class
-- *
-- ****************************************************************************

WeaponTruck = inherit(Object)
WeaponTruck.Time = 20*60*1000 -- in ms
WeaponTruck.spawnPos = {
	["evil"] = {-1869.58, 1430.02, 7.62, 224},
	["state"] = {120.23, 1899.40, 18.97, 0}
}
WeaponTruck.loadMarkerPos = {
	["evil"] = Vector3(-1873.56, 1434.15, 7.18),
	["state"] = Vector3(120.26, 1894.21, 18.42)
}
WeaponTruck.attachCords = {
	Vector3(0.7, -0.1, 0.1), Vector3(-0.7, -0.1, 0.1), Vector3(0.7, -1.4, 0.1), Vector3(-0.7, -1.4, 0.1),
	Vector3(-0.7, -2.7, 0.1), Vector3(0.7, -2.7, 0.1), Vector3(-0.7, -4, 0.1), Vector3(0.7, -4, 0.1)
}
WeaponTruck.boxSpawnCords = {
	["evil"] = {
		Vector3(-1875.75, 1416, 6.2), Vector3(-1875.75, 1416, 6.9),
		Vector3(-1873.74, 1415, 6.2), Vector3(-1873.74, 1415, 6.9),
		Vector3(-1875.27, 1414, 6.2), Vector3(-1875.27, 1414, 6.9),
		Vector3(-1873.11, 1413, 6.2), Vector3(-1873.11, 1413, 6.9)
				},
	["state"] = {
		Vector3(124.81, 1894.03, 17.5), Vector3(124.81, 1894.03, 18.2),
		Vector3(123.61, 1897.85, 17.5), Vector3(123.61, 1897.85, 18.2),
		Vector3(125.19, 1896.54, 17.5), Vector3(125.19, 1896.54, 18.2),
		Vector3(125.37, 1892.65, 17.5), Vector3(125.37, 1892.65, 18.2)
				}
}

function WeaponTruck:constructor(driver, boxContent, totalAmount, type)
	self.m_Type = type
	self.m_Truck = TemporaryVehicle.create(455, unpack(WeaponTruck.spawnPos[type]))
	self.m_Truck:setData("WeaponTruck", true, true)
    self.m_Truck:setColor(0, 0, 0)
	self.m_Truck:setFrozen(true)
    self.m_Truck:setLocked(true)
	self.m_Truck:setVariant(255, 255)
	self.m_Truck:setMaxHealth(2000, true)
	self.m_Truck:setBulletArmorLevel(2)
	self.m_Truck:setRepairAllowed(false)
	self.m_Truck:toggleRespawn(false)
	self.m_Truck:setAlwaysDamageable(true)
	self.m_Truck.m_DisableToggleHandbrake = true
	-- edit handling to match Barracks' handling
	self.m_Truck:setHandling("engineInertia", 25)
	self.m_Truck:setHandling("dragCoeff", 4)
	self.m_Truck:setHandling("brakeBias", 0.4)
	self.m_Truck:setHandling("engineAcceleration", 8)
	self.m_Truck:setHandling("brakeDeceleration", 4)
	
	

	self.m_StartTime = getTickCount()
	self.m_DestinationBlips = {}
	self.m_DestinationMarkers = {}

	self.m_Boxes = {}
	self.m_StartPlayer = driver
	self.m_StartFaction = driver:getFaction()
	
	self.m_BankAccountServer = BankServer.get("action.weapon_truck")

	TollStation.openAll()

	local dest
	local EvilBlipVisible = {}
	if self.m_Type == "evil" then
		self.m_AmountPerBox = math.floor(WEAPONTRUCK_MAX_LOAD/8)
		table.insert(EvilBlipVisible, self.m_StartFaction:getId())
		for i, faction in pairs(FactionEvil:getSingleton():getFactions()) do
			if self.m_StartFaction:getDiplomacy(faction) == FACTION_DIPLOMACY["im Krieg"] then
				table.insert(EvilBlipVisible, faction:getId())
			end
		end

		for i, faction in pairs(FactionEvil:getSingleton():getFactions()) do
			if self.m_StartFaction == faction or self.m_StartFaction:getDiplomacy(faction) == FACTION_DIPLOMACY["im Krieg"] then
				dest = self:addDestinationMarker(faction, "evil")
				self.m_DestinationBlips[faction:getId()] = Blip:new("Marker.png", dest.x, dest.y, {factionType = "State", faction = EvilBlipVisible, duty = true}, 9999, BLIP_COLOR_CONSTANTS.Red)
				self.m_DestinationBlips[faction:getId()]:setDisplayText("Gun Truck Drop-off Point")
				self.m_DestinationBlips[faction:getId()]:setZ(dest.z)
			end
		end
	elseif self.m_Type == "state" then
		self.m_AmountPerBox = math.floor(WEAPONTRUCK_MAX_LOAD/8)

		for i, faction in pairs(FactionEvil:getSingleton():getFactions()) do
			dest = self:addDestinationMarker(faction, "evil")
			self.m_DestinationBlips[faction:getId()] = Blip:new("Marker.png", dest.x, dest.y, {factionType = "State", faction = faction:getId(), duty = true}, 9999, BLIP_COLOR_CONSTANTS.Red)
			self.m_DestinationBlips[faction:getId()]:setDisplayText("Gun Truck Drop-off Point")
			self.m_DestinationBlips[faction:getId()]:setZ(dest.z)
		end
	end

	dest = self:addDestinationMarker(self.m_Type == "state" and self.m_StartFaction or FactionManager:getSingleton():getFromId(3), "state") -- State
	self.m_DestinationBlips["state"] = Blip:new("Marker.png", dest.x, dest.y, {factionType = {"State", "Evil", duty = true}}, 9999, BLIP_COLOR_CONSTANTS.Red)
	self.m_DestinationBlips["state"]:setDisplayText("Weapons-Truck Tax (state)")
	self.m_DestinationBlips["state"]:setZ(dest.z)


	self.m_WeaponLoad = boxContent
	self.m_Event_onBoxClickFunc =bind(self.Event_onBoxClick,self)
	self.m_BoxesCount = 0
	for i, v in pairs(boxContent) do -- loop used to filter out empty boxes
		if table.size(v) > 0 then
			self.m_BoxesCount = self.m_BoxesCount + 1
		end
	end
	outputDebug("box count: ", self.m_BoxesCount)

	self.m_Timer = setTimer(bind(self.timeUp, self), WeaponTruck.Time, 1)
	self.m_Destroyed = false
	self.m_DestroyFunc = bind(self.Event_OnWeaponTruckDestroy,self)

	self.m_WaterCheckTimer = setTimer(bind(self.isWeaponTruckInWater, self), 10000, 0)
	self.m_IsSubmerged = false

	addRemoteEvents{"weaponTruckDeloadBox", "weaponTruckLoadBox"}

	self.m_Event_loadBox = bind(self.Event_DeloadBox,self)
	self.m_Event_deloadBox = bind(self.Event_LoadBox,self)
	addEventHandler("weaponTruckDeloadBox",root, self.m_Event_loadBox)
	addEventHandler("weaponTruckLoadBox",root, self.m_Event_deloadBox)


	addEventHandler("onVehicleStartEnter",self.m_Truck,bind(self.Event_OnWeaponTruckStartEnter,self))
	addEventHandler("onVehicleEnter",self.m_Truck,bind(self.Event_OnWeaponTruckEnter,self))
	addEventHandler("onVehicleExit",self.m_Truck,bind(self.Event_OnWeaponTruckExit,self))
	addEventHandler("onElementDestroy",self.m_Truck,self.m_DestroyFunc, false)
	addEventHandler("onVehicleExplode",self.m_Truck,self.m_DestroyFunc)

	self:spawnBoxes()
	self:createLoadMarker()


end

function WeaponTruck:destructor()
	removeEventHandler("onElementDestroy",self.m_Truck,self.m_DestroyFunc)
	removeEventHandler("weaponTruckDeloadBox",root, self.m_Event_loadBox)
	removeEventHandler("weaponTruckLoadBox",root, self.m_Event_deloadBox)
	ActionsCheck:getSingleton():endAction()
	StatisticsLogger:getSingleton():addActionLog(WEAPONTRUCK_NAME[self.m_Type], "stop", self.m_StartPlayer, self.m_StartFaction, "faction")
	self.m_Truck:destroy()
	TollStation.closeAll()

	if isElement(self.m_LoadMarker) then self.m_LoadMarker:destroy() end
	if isTimer(self.m_Timer) then self.m_Timer:destroy() end

	for index, value in pairs(self.m_DestinationMarkers) do
		if isElement(value) then value:destroy() end
	end

	for index, value in pairs(self.m_DestinationBlips) do
		if value then delete(value) end
	end

	for index, value in pairs(self.m_Boxes) do
		if isElement(value) then
			if value:isAttached() and isElement(value:getAttachedTo()) and value:getAttachedTo():getType() == "player" then
				value:getAttachedTo():detachPlayerObject(value)
			end
		 	value:destroy()
		end
	end
	killTimer(self.m_WaterCheckTimer)
	if isTimer(self.m_WaterNotificationTimer) then killTimer(self.m_WaterNotificationTimer) end
end


function WeaponTruck:timeUp()
	PlayerManager:getSingleton():breakingNews("The %s has failed! (Time Expired)", WEAPONTRUCK_NAME[self.m_Type])
	Discord:getSingleton():outputBreakingNews(string.format("The %s has failed! (Time Expired)", WEAPONTRUCK_NAME[self.m_Type]))

	delete(self)
end

-- Marker methodes/events
function WeaponTruck:createLoadMarker()
	self.m_LoadMarker = createMarker(WeaponTruck.loadMarkerPos[self.m_Type],"corona",2)
	addEventHandler("onMarkerHit", self.m_LoadMarker, bind(self.Event_onLoadMarkerHit, self))
end



function WeaponTruck:Event_onLoadMarkerHit(hitElement, matchingDimension)
	if hitElement:getType() == "player" and matchingDimension then
		local faction = hitElement:getFaction()
		if faction then
			local box = hitElement:getPlayerAttachedObject()
			if box then
				hitElement:detachPlayerObject(box)
				self:loadBoxOnWeaponTruck(hitElement,box)
			else
				hitElement:sendError(_("You haven't brought a box!",hitElement))
			end
		end
	end
end

--Box methodes
function WeaponTruck:spawnBoxes()
	for i=1,self.m_BoxesCount do
		if WeaponTruck.boxSpawnCords[self.m_Type][i] then
			self:spawnBox(i, WeaponTruck.boxSpawnCords[self.m_Type][i])
		end
	end
end

function WeaponTruck:getRemainingBoxAmount()
	local count = 0
	for i,k in pairs(self.m_Boxes) do
		if isElement(k) then
			count = count +1
		end
	end
	return count
end

function WeaponTruck:spawnBox(i, position)
	if position then
		self.m_Boxes[i] = createObject(2912, position, 0, 0, math.random(0,360))
		addEventHandler("onElementClicked", self.m_Boxes[i], self.m_Event_onBoxClickFunc)
		self.m_Boxes[i].content = {}
		self.m_Boxes[i].id = i
		self:setBoxContent(i)
		self.m_Boxes[i]:setData("weaponBox", true, true)
		self.m_Boxes[i]:setData("content", self.m_Boxes[i].content, true)
		setElementData(self.m_Boxes[i], "clickable", true)
		--self:outputBoxContent(self.m_StartPlayer,i)
		return self.m_Boxes[i]
	else
		outputDebugString("Weapontruck Error: Spawning Weaponbox "..i.."! Position missing!")
	end
end

function WeaponTruck:Event_onBoxClick(button, state, player)
	if button == "left" and state == "down" then
		if player.vehicle then return end
		if player:isDead() then return end
		if player:getFaction() and (player:getFaction():isStateFaction() or player:getFaction():isEvilFaction()) then
			if getDistanceBetweenPoints3D(player:getPosition(), source:getPosition()) < 3 then
				player:setAnimation("carry", "crry_prtial", 1, true, true, false, true)
				player:attachPlayerObject(source)
			else
				player:sendError(_("You're too far from the box!", player))
			end
		else
			player:sendError(_("Only factionists can pick up boxes!",player))
		end
	end
end

function WeaponTruck:loadBoxOnWeaponTruck(player,box)
	local boxesOnTruck = self:getAttachedBoxes(self.m_Truck) + 1
	player:detachPlayerObject(box)
	box:setScale(1.6)
	box:attach(self.m_Truck, WeaponTruck.attachCords[boxesOnTruck])
	box:setCollisionsEnabled(false)
	removeEventHandler("onElementClicked", box, self.m_Event_onBoxClickFunc)

	if boxesOnTruck >= self.m_BoxesCount then
		player:sendInfo(_("All boxes loaded! The truck is ready!",player))
		self.m_Truck:setFrozen(false)
		self.m_Truck:setLocked(false)
		if isElement(self.m_LoadMarker) then self.m_LoadMarker:destroy() end
	else
		player:sendInfo(_("%d/%d Boxes loaded!", player, boxesOnTruck, self.m_BoxesCount))
	end
end

function WeaponTruck:setBoxContent(boxId)
	local box = self.m_Boxes[boxId]
	local depotInfo =  self.m_StartFaction.m_WeaponDepotInfo

	box.content = self.m_WeaponLoad[boxId]
	--[[for weaponID,v in pairs(self.m_WeaponLoad) do
		for typ,amount in pairs(self.m_WeaponLoad[weaponID]) do
			if amount > 0 then
				for i=0,amount do
					if typ == "Waffe" then preisString = "WaffenPreis" elseif typ == "Munition" then preisString = "MagazinPreis" end
					if box.sum + depotInfo[weaponID][preisString] <= self.m_AmountPerBox or depotInfo[weaponID][preisString] >= self.m_AmountPerBox then
						if not box.content[weaponID] then box.content[weaponID] = { ["Waffe"] = 0, ["Munition"] = 0 } end

						box.sum = box.sum + depotInfo[weaponID][preisString]
						self.m_WeaponLoad[weaponID][typ] = self.m_WeaponLoad[weaponID][typ] - 1
						box.content[weaponID][typ] = box.content[weaponID][typ] + 1
						outputDebug(box.content)
						--outputChatBox("1 "..typ.." "..WEAPON_NAMES[weaponID].." in die Kiste "..boxId.." geladen! SUM: "..box.sum.."$") -- Debug
						self:setBoxContent(boxId)
						return
					else
						return
					end
				end
			end
		end
	end]]
end

function WeaponTruck:outputBoxContent(player, box)
	if box and isElement(box) and box.content then
		local weaponTable = box.content
		for weaponID,v in pairs(weaponTable) do
			for typ,amount in pairs(weaponTable[weaponID]) do
				if amount > 0 then
					if typ == "Waffe" then
						outputChatBox(_("Box: %s: %s %s Weapon/s", player, box.id, amount, WEAPON_NAMES[weaponID]),player,255,255,0)
					elseif typ == "Munition" then
						outputChatBox(_("Box: %s: %s %s Magazine/s", player, box.id, amount, WEAPON_NAMES[weaponID]),player,255,255,0)
					end
				end
			end
		end
	else
		outputDebug("Error WT:outputBoxContent BoxId: "..box.id)
	end
end

--Vehicle Events
function WeaponTruck:Event_OnWeaponTruckStartEnter(player,seat)
	if seat == 0 and not player:getFaction() then
		player:sendError(_("Only factionists can drive the weapons truck!",player))
		cancelEvent()
	end
end

function WeaponTruck:Event_OnWeaponTruckDestroy()
	if self and not self.m_Destroyed then
		self.m_Destroyed = true
		self:Event_OnWeaponTruckExit(self.m_Driver,0)
		PlayerManager:getSingleton():breakingNews("The %s has been destroyed!", WEAPONTRUCK_NAME[self.m_Type])
		Discord:getSingleton():outputBreakingNews(string.format("The %s has been destroyed!", WEAPONTRUCK_NAME[self.m_Type]))
		self:delete()
	end
end

function WeaponTruck:Event_OnWeaponTruckEnter(player,seat)
	if seat == 0 and player:getFaction() then
		self.m_Driver = player
		player:triggerEvent("Countdown", math.floor((WeaponTruck.Time-(getTickCount()-self.m_StartTime))/1000), WEAPONTRUCK_NAME_SHORT[self.m_Type])
		player:triggerEvent("VehicleHealth")
	end
end

function WeaponTruck:addDestinationMarker(faction, type)
	local markerId = #self.m_DestinationMarkers+1
	local color = factionColors[faction:getId()]
	local destination = factionWTDestination[faction:getId()]
	self.m_DestinationMarkers[markerId] = createMarker(destination,"cylinder",8, color.r, color.g, color.b, 100)
	self.m_DestinationMarkers[markerId].type = type
	self.m_DestinationMarkers[markerId].faction = faction

	addEventHandler("onMarkerHit", self.m_DestinationMarkers[markerId], bind(self.Event_onDestinationMarkerHit, self))
	return destination
end

function WeaponTruck:Event_OnWeaponTruckExit(player,seat)
	if seat == 0 and player and isElement(player) then
		player:triggerEvent("CountdownStop", WEAPONTRUCK_NAME_SHORT[self.m_Type])
		player:triggerEvent("VehicleHealthStop")
	end
end

function WeaponTruck:Event_DeloadBox(veh)
	if not veh then return end
	if client:getFaction() then
		if veh == self.m_Truck or VEHICLE_BOX_LOAD[veh.model] then
			if getDistanceBetweenPoints3D(veh.position, client.position) < 7 then
				if not client:getPlayerAttachedObject() then
					if not client.vehicle and not client:isDead() then
						for key, box in pairs (getAttachedElements(veh)) do
							if box.model == 2912 then
								box:setScale(1)
								box:detach(self.m_Truck)
								client:setAnimation("carry", "crry_prtial", 1, true, true, false, true)
								client:attachPlayerObject(box)
								addEventHandler("onElementClicked", box, self.m_Event_onBoxClickFunc)
								return
							end
						end
						client:sendError(_("There is no crate on the truck!",client))
						return
					else
						client:sendError(_("You are not allowed to sit in any vehicle!",client))
					end
				else
					client:sendError(_("You already have an object!",client))
				end
			else
				client:sendError(_("You are too far away from the truck!",client))
			end
		else
			client:sendError(_("This vehicle can't be unloaded!",client))
		end
	else
		client:sendError(_("Only factionists can unload boxes!",client))
	end
end

function WeaponTruck:isWeaponTruckInWater()
	if not self.m_IsSubmerged then
		if isElementInWater(self.m_Truck) then
			self:forceBoxesToDrop()
			self.m_WaterNotificationTimer = setTimer(
				function()
					PlayerManager:getSingleton():breakingNews("Latest sources report that the gun truck had an accident and drove into the water!")
				end
			, 180000, 1)
			self.m_IsSubmerged = true
		end
	end
end

function WeaponTruck:forceBoxesToDrop()
	for key, box in pairs (getAttachedElements(self.m_Truck)) do
		if box.model == 2912 then
			box:setScale(1)
			box:detach(self.m_Truck)
			nextframe(function() --to "prevent" it from spawning in another player / vehicle (added for RTS)
				box:setCollisionsEnabled(true)
			end)
			addEventHandler("onElementClicked", box, self.m_Event_onBoxClickFunc)
		end
	end
end

function WeaponTruck:getAttachedBoxes(element)
	local count = 0
	if getAttachedElements(element) then
		for index, ele in pairs(getAttachedElements(element)) do
			if ele:getModel() == 2912 and ele:getData("weaponBox") then
				count = count + 1
			end
		end
	end
	return count
end

function WeaponTruck:Event_LoadBox(veh)
	if client:getFaction() then
		if veh == self.m_Truck or VEHICLE_BOX_LOAD[veh.model] then
			if getDistanceBetweenPoints3D(veh.position,client.position) < 7 then
				if not client.vehicle then
					local box = client:getPlayerAttachedObject()
					if veh == self.m_Truck then
						self:loadBoxOnWeaponTruck(client,box)
						return
					end
					if self:getAttachedBoxes(veh) < VEHICLE_BOX_LOAD[veh.model]["count"] then
						if box then
							local count = self:getAttachedBoxes(veh)
							client:detachPlayerObject(box)
							box:attach(veh, VEHICLE_BOX_LOAD[veh.model][count+1])
							removeEventHandler("onElementClicked", box, self.m_Event_onBoxClickFunc)
						else
							client:sendError(_("You haven't brought a box!",client))
						end
					else
						client:sendError(_("The vehicle is already fully laden!",client))
					end
				else
					client:sendError(_("You are not allowed to sit in any vehicle!",client))
				end
			else
				client:sendError(_("You are too far away from the truck!",client))
			end
		else
			client:sendError(_("This vehicle can't be loaded!",client))
		end
	else
		client:sendError(_("Only factionists can unload boxes!",client))
	end
end

function WeaponTruck:Event_onDestinationMarkerHit(hitElement, matchingDimension)
	if isElement(hitElement) and matchingDimension then
		if hitElement.type == "player" then
			local faction = hitElement:getFaction()
			if faction then
				if (hitElement.vehicle and #getAttachedElements(hitElement.vehicle) > 0 ) or hitElement:getPlayerAttachedObject() then
					if faction:isEvilFaction() and source.type == "evil" and (source.faction == faction or source.faction == faction:getAllianceFaction()) then
						self:onDestinationMarkerHit(hitElement)
					elseif faction:isStateFaction() and source.type == "state" then
						self:onDestinationMarkerHit(hitElement)
					else
						hitElement:sendError(_("You can't hand in here!",hitElement))
					end
				end
			end
		end
	end
end

function WeaponTruck:onDestinationMarkerHit(hitElement)
	local faction = source.faction
	local box
	if isPedInVehicle(hitElement) and getPedOccupiedVehicle(hitElement) == self.m_Truck then
		hitElement:sendInfo(_("Please get off to unload the boxes!", hitElement))
		return
	end
	
	if hitElement:getPlayerAttachedObject() then
		if self:getAttachedBoxes(hitElement) > 0 then
			box = hitElement:getPlayerAttachedObject()
			PlayerManager:getSingleton():breakingNews("Weapons box %d from %d was handed in to %s!", self.m_BoxesCount-self:getRemainingBoxAmount()+1, self.m_BoxesCount, faction:getShortName())
			hitElement:sendInfo(_("You have successfully handed in a crate! The weapons are now in the faction depot!",hitElement))
			self:addWeaponsToDepot(hitElement, faction, box.content)
			hitElement:detachPlayerObject(box)
			box:destroy()
		end
	elseif hitElement:getOccupiedVehicle() then
		hitElement:sendInfo(_("You have to unload the boxes by hand!", hitElement))
		return
	end

	if self:getRemainingBoxAmount() == 0  then
		delete(self)
	end
end

function WeaponTruck:mergeBoxes(boxes)
	local weaponTable
	local mergeTable = {}
	for key, box in pairs (boxes) do
		if box:getModel() == 2912 and box:getData("weaponBox") then
			weaponTable = box.content
			for weaponID, v in pairs(weaponTable) do
				if not mergeTable[weaponID] then mergeTable[weaponID] = { ["Waffe"] = 0, ["Munition"] = 0 } end
				for typ, amount in pairs(weaponTable[weaponID]) do
					mergeTable[weaponID][typ] =  mergeTable[weaponID][typ] + amount
				end
			end
		end
	end
	return mergeTable
end

function WeaponTruck:addWeaponsToDepot(player, faction, weaponTable)
	local insertAmount
	local shortMessage = {}
	local money = 0
	local depot = faction.m_Depot

	local depotInfo = faction:isStateFaction() and factionWeaponDepotInfoState or factionWeaponDepotInfo
	local allowedWeapons = factionWeapons[faction:getId()]

	for weaponID, v in pairs(weaponTable) do
		for typ, amount in pairs(weaponTable[weaponID]) do
			insertAmount = 0
			if not weaponTable[weaponID]["Waffe"] then weaponTable[weaponID]["Waffe"] = 0 end
			if not weaponTable[weaponID]["Munition"] then weaponTable[weaponID]["Munition"] = 0 end
			if amount > 0 then
				if (faction:isStateFaction() and allowedWeapons[weaponID]) or faction:isEvilFaction() then
					if typ == "Waffe" then
						if depotInfo[weaponID]["Waffe"] >= depot.m_Weapons[weaponID]["Waffe"] + amount then
							insertAmount = amount
						else
							insertAmount = depotInfo[weaponID]["Waffe"] - depot.m_Weapons[weaponID]["Waffe"]
						end
						depot:addWeaponD(weaponID, insertAmount)
						weaponTable[weaponID]["Waffe"] = weaponTable[weaponID]["Waffe"] - insertAmount
						shortMessage[#shortMessage+1] = {WEAPON_NAMES[weaponID], insertAmount}
					elseif typ == "Munition" then
						if depotInfo[weaponID]["Magazine"] >= depot.m_Weapons[weaponID]["Munition"] + amount then
							insertAmount = amount
						else
							insertAmount = depotInfo[weaponID]["Magazine"] - depot.m_Weapons[weaponID]["Munition"]
						end
						depot:addMagazineD(weaponID,insertAmount)
						weaponTable[weaponID]["Munition"] = weaponTable[weaponID]["Munition"] - insertAmount
						shortMessage[#shortMessage+1] = {WEAPON_NAMES[weaponID].." Magazine/s", insertAmount}
					end
				end
			end
		end
	end

	--Remaining Weapons evidence/money
	local evidenceString = {}	

	for weaponID, v in pairs(weaponTable) do
		for typ, amount in pairs(weaponTable[weaponID]) do
			if amount > 0 then
				if faction:isStateFaction() then -- state evidence
					if typ == "Waffe" then
						StateEvidence:getSingleton():addWeaponsToEvidence(player, weaponID, amount, true)
						evidenceString[#evidenceString+1] = amount.." "..WEAPON_NAMES[weaponID].."\n"
					elseif typ == "Munition" then
						StateEvidence:getSingleton():addMunitionToEvidence(player, weaponID, amount, true)
						evidenceString[#evidenceString+1] = amount.." "..WEAPON_NAMES[weaponID].."-Magazines\n"
					end
				else
					if typ == "Waffe" then
						money = money + amount * factionWeaponDepotInfo[weaponID]["WaffenPreis"]
					elseif typ == "Munition" then
						money = money + amount * factionWeaponDepotInfo[weaponID]["MagazinPreis"]
					end
				end
			end
		end
	end
	if money > 0 then
		self.m_BankAccountServer:transferMoney(faction, money, "Weapon-Truck Boxs", "Action", "WeaponTruck")
	end

	local shortmessageString = "Placed in the depot:"
	for index, data in pairs(shortMessage) do
		shortmessageString = shortmessageString.."\n"..table.concat(data, ": ")
	end

	-- "AviRex Dev" Don't Know what is that exactly but okay its no problem
	if evidenceString and table.size(evidenceString) > 0 then
		shortmessageString = shortmessageString.."Placed in the evidence room:"
		shortmessageString = shortmessageString.."\n"..table.concat(evidenceString)
	end

	if money > 0 then
		shortmessageString = shortmessageString..("Geld: %d$"):format(money)
	end
	player:sendShortMessage(shortmessageString, "Weapon-Truck Box", nil, 15000)

	depot:save()
end
