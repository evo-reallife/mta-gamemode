-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/FactionRescue.lua
-- *  PURPOSE:     Faction Rescue Class
-- *
-- ****************************************************************************
FactionRescue = inherit(Singleton)
addRemoteEvents{
	"factionRescueToggleDuty", "factionRescueHealPlayerQuestion", "factionRescueDiscardHealPlayer", "factionRescueHealPlayer",
	"factionRescueWastedFinished", "factionRescueToggleStretcher", "factionRescuePlayerHealBase",
	"factionRescueReviveAbort", "factionRescueToggleLadder", "factionRescueToggleDefibrillator", "factionRescueFillFireExtinguisher",
	"factionRescueChangeRadioStatus"
}

function FactionRescue:constructor()
	-- Duty Pickup
	self:createDutyPickup(1076.30, -1374.01, 13.65, 0) -- Garage
	self:createDutyPickup(132.562, 163.525, 1186.05, 3) -- Garage

	self.m_VehicleFires = {}

	self.m_LastStrecher = {}
	self.m_DeathBlips = {}
	self.m_BankAccountServer = BankServer.get("faction.rescue")
	self.m_BankAccountServerCorpse = BankServer.get("player.corpse")

	self.m_GateHitBind = bind(self.onBarrierHit, self)
	-- Barriers
	Gate:new(968, Vector3(1138.5, -1384.88, 13.48), Vector3(0, 90, 0), Vector3(1138.5, -1384.88, 13.33), Vector3(0, 5, 0), false).onGateHit = self.m_GateHitBind
	Gate:new(968, Vector3(1138.4, -1291, 13.3), Vector3(0, 90, 0), Vector3(1138.4, -1291, 13.3), Vector3(0, 5, 0), false).onGateHit = self.m_GateHitBind

	--Garage doors
	self.m_Gates = {
		Gate:new(3037, Vector3(1125.7, -1384.5, 14.9), Vector3(0, 0, 90), Vector3(1125.7, -1381.9, 17), Vector3(0, 88, 90)), --one
		Gate:new(3037, Vector3(1125.7, -1371.1, 14.9), Vector3(0, 0, 270), Vector3(1125.7, -1374.2, 17), Vector3(0, 88, 270)), --one back

		Gate:new(3037, Vector3(1113.9, -1384.5, 14.9), Vector3(0, 0, 90), Vector3(1113.9, -1381.9, 17), Vector3(0, 88, 90)), --two
		Gate:new(3037, Vector3(1113.9, -1371.1, 14.9), Vector3(0, 0, 270), Vector3(1113.9, -1374.2, 17), Vector3(0, 88, 270)), --two back

		Gate:new(3037, Vector3(1102.1, -1384.5, 14.9), Vector3(0, 0, 90), Vector3(1102.1, -1381.9, 17), Vector3(0, 88, 90)), --three
		Gate:new(3037, Vector3(1102.1, -1371.1, 14.9), Vector3(0, 0, 270), Vector3(1102.1, -1374.2, 17), Vector3(0, 88, 270)), --three back

		Gate:new(3037, Vector3(1090.3, -1384.5, 14.9), Vector3(0, 0, 90), Vector3(1090.3, -1381.9, 17), Vector3(0, 88, 90)), --four
		Gate:new(3037, Vector3(1090.3, -1371.1, 14.9), Vector3(0, 0, 270), Vector3(1090.3, -1374.2, 17), Vector3(0, 88, 270)), --four back
	}

	for i,v in pairs(self.m_Gates) do
		v.onGateHit = self.m_GateHitBind
	end
	--[[local elevator = Elevator:new()
	elevator:addStation("Heliport", Vector3(1161.74, -1329.84, 31.49))
	elevator:addStation("Vordereingang", Vector3(1172.45, -1325.44, 15.41), 270)
	elevator:addStation("Hintereingang", Vector3(1144.70, -1322.30, 13.57), 90)]]

	InteriorEnterExit:new(Vector3(1172.45, -1325.44, 15.41), Vector3(145.1000, 119.400, 1186), 0, 270, 3, 0) -- front
	InteriorEnterExit:new(Vector3(1144.70, -1322.30, 13.57), Vector3(170.699, 167.3999, 1191.1999), 90, 90, 3, 0) -- back
	InteriorEnterExit:new(Vector3(1161.74, -1329.84, 31.49), Vector3(176.6999, 171.5, 1191.1999), 90, 0, 3, 0) -- heliport


	self.m_Faction = FactionManager.Map[4]

	self.m_LadderBind = bind(self.ladderFunction, self)
	self.m_MoveLadderBind = bind(self.moveLadder, self)
	self.m_RefreshAttachedStretcher = bind(self.refreshAttachedStretcher, self)

	nextframe(
		function ()
			local safe = createObject(2332, 1075.83, -1384.6, 13.21, 0, 0, 180)
			setElementDoubleSided(safe,true)
			FactionManager:getSingleton():getFromId(4):setSafe(safe)
		end
	)

	local blip = Blip:new("Rescue.png", 1172.08, -1323.38, root, 400)
	blip:setOptionalColor({factionColors[4].r, factionColors[4].g, factionColors[4].b})
	blip:setDisplayText(self.m_Faction:getName(), BLIP_CATEGORY.Faction)

	-- Events
	addEventHandler("factionRescueToggleDuty", root, bind(self.Event_toggleDuty, self))
	addEventHandler("factionRescueHealPlayerQuestion", root, bind(self.Event_healPlayerQuestion, self))
	addEventHandler("factionRescueDiscardHealPlayer", root, bind(self.Event_discardHealPlayer, self))
	addEventHandler("factionRescueHealPlayer", root, bind(self.Event_healPlayer, self))
	addEventHandler("factionRescueWastedFinished", root, bind(self.Event_OnPlayerWastedFinish, self))
	addEventHandler("factionRescueToggleStretcher", root, bind(self.Event_ToggleStretcher, self))
	addEventHandler("factionRescueToggleDefibrillator", root, bind(self.Event_ToggleDefibrillator, self))
	addEventHandler("factionRescuePlayerHealBase", root, bind(self.Event_healPlayerHospital, self))
	addEventHandler("factionRescueReviveAbort", root, bind(self.destroyDeathBlip, self))
	addEventHandler("factionRescueToggleLadder", root, bind(self.Event_toggleLadder, self))
	addEventHandler("factionRescueFillFireExtinguisher", root, bind(self.Event_fillFireExtinguisher, self))
	addEventHandler("factionRescueChangeRadioStatus", root, bind(self.Event_changeRadioStatus, self))


	PlayerManager:getSingleton():getQuitHook():register(
		function(player)
			if player.m_DeathPickup then
				player.m_DeathPickup:destroy()
				player.m_DeathPickup = nil
				if self.m_DeathBlips[player] then
					self.m_DeathBlips[player]:delete()
					self.m_DeathBlips[player] = nil
				end
			end

			if player.m_RescueStretcher then
				if player.m_RescueStretcher.player then
					local deadPlayer = player.m_RescueStretcher.player
					if isElement(deadPlayer) and getElementType(deadPlayer) == "ped" and not deadPlayer.despawn then
						deadPlayer:destroy()
					end
				end
				player.m_RescueStretcher:destroy()
			end
		end
	)


end

function FactionRescue:destructor()
end

function FactionRescue:countPlayers(afkCheck, dutyCheck)
	return #self.m_Faction:getOnlinePlayers(afkCheck, dutyCheck)
end

function FactionRescue:getOnlinePlayers(afkCheck, dutyCheck)
	local players = {}

	for index, value in pairs(self.m_Faction:getOnlinePlayers(afkCheck, dutyCheck)) do
		table.insert(players, value)
	end

	return players
end

function FactionRescue:sendWarning(text, header, withOffDuty, pos, ...)
	for k, player in pairs(self:getOnlinePlayers(false, not withOffDuty)) do
		player:sendWarning(_(text, player, ...), 30000, header)
	end
	if pos and pos.x then pos = {pos.x, pos.y, pos.z} end -- serialiseVector conversion
	if pos and pos[1] and pos[2] then
		local blip = Blip:new("Fire.png", pos[1], pos[2], {factionType = "Rescue"}, 4000, BLIP_COLOR_CONSTANTS.Orange)
			blip:setDisplayText(header)
		if pos[3] then
			blip:setZ(pos[3])
		end
		setTimer(function()
			blip:delete()
		end, 30000, 1)
	end
end

function FactionRescue:onBarrierHit(player)
    if not player:getFaction() or not player:getFaction():isRescueFaction() then
        return false
    end
    return true
end

function FactionRescue:createDutyPickup(x,y,z,int)
	self.m_DutyPickup = createPickup(x,y,z, 3, 1275)
	setElementInterior(self.m_DutyPickup, int)
	addEventHandler("onPickupHit", self.m_DutyPickup,
		function(hitElement)
			if getElementType(hitElement) == "player" then
				local faction = hitElement:getFaction()
				if faction then
					if faction:isRescueFaction() == true then
						if not hitElement.vehicle then
							hitElement.m_CurrentDutyPickup = source
							faction:updateDutyGUI(hitElement)
						else
      						hitElement:sendError(_("You are not allowed to sit in a vehicle!", hitElement))
						end
					end
				end
			end
			cancelEvent()
		end
	)
end

function FactionRescue:Event_toggleDuty(type, wasted, prefSkin, dontChangeSkin, player)
	if not client then client = player end
	local faction = client:getFaction()
	if faction:isRescueFaction() then
		if getDistanceBetweenPoints3D(client.position, client.m_CurrentDutyPickup.position) <= 10 or wasted then
			if client:isFactionDuty() then
				if not dontChangeSkin then
					client:setCorrectSkin()
				end
				client:setFactionDuty(false)
				client:sendInfo(_("You are no longer in the service of your faction!", client))
				client:setPublicSync("Rescue:Type",false)
				client:getInventory():removeAllItem("Warnkegel")
				RadioCommunication:getSingleton():allowPlayer(client, false)
				client:setBadge()
				takeAllWeapons(client)
				if not wasted then faction:updateDutyGUI(client) end
				client:setPublicSync("RadioStatus", 6)
			else
				if wasted then return end
				if client:getPublicSync("Company:Duty") and client:getCompany() then
					--client:sendWarning(_("Bitte beende zuerst deinen Dienst im Unternehmen!", client))
					--return false
					--client:triggerEvent("companyForceOffduty")
					CompanyManager:getSingleton():companyForceOffduty(client)
				end
				takeAllWeapons(client)
				if type == "fire" then
					giveWeapon(client, 42, 0, true)
					client:setPublicSync("RadioStatus", 3)
				end
				client:setFactionDuty(true)
				client:sendInfo(_("You are now at the service of your faction!", client))
				client:setPublicSync("Rescue:Type",type)
				client:getInventory():removeAllItem("Warnkegel")
				client:getInventory():giveItem("Warnkegel", 10)
				faction:updateDutyGUI(client)
				faction:changeSkin(client, prefSkin)
				client:setBadge(FACTION_STATE_BADGES[faction:getId()], ("%s %s"):format(factionBadgeId[faction:getId()][faction:getPlayerRank(client)], client:getId()), nil)
				RadioCommunication:getSingleton():allowPlayer(client, true)
				client:setHealth(100)
				client:setArmor(100)
				StatisticsLogger:getSingleton():addHealLog(client, 100, "Faction Duty Heal")
				DamageManager:getSingleton():clearPlayer(client)
				client:checkLastDamaged()
			end
		else
			client:sendError(_("You're too far away!", client))
		end
	else
		client:sendError(_("You are not in the Rescue Faction!", client))
		return false
	end
end

-- Death System
function FactionRescue:Event_ToggleStretcher(vehicle)
	if client:getFaction() == self.m_Faction then
		if client:isFactionDuty() and client:getPublicSync("Rescue:Type") == "medic" then
			if not client.m_RescueDefibrillator then
				if not self.m_LastStrecher[client] or timestampCoolDown(self.m_LastStrecher[client], 1) then
					if client.m_RescueStretcher then
						self:removeStretcher(client, vehicle)
					else
						self:getStretcher(client, vehicle)
						setElementAlpha(client,255)
						if client:getExecutionPed() then
							destroyElement( client:getExecutionPed() )
						end
					end
				else
					client:sendError(_("You can't unload/load the stretcher so many times in a row!", client))
				end
			else

			end
		else
			client:sendError(_("You're not on Medical-Duty!", client))
		end
	end
end

function FactionRescue:Event_ToggleDefibrillator(vehicle)
	if client:getFaction() == self.m_Faction then
		if client:isFactionDuty() and client:getPublicSync("Rescue:Type") == "medic" then
			if not client.m_RescueStretcher then
				if client.m_RescueDefibrillator then
					self:removeDefibrillator(client, vehicle)
				else
					self:getDefibrillator(client, vehicle)
				end
			else

			end
		else
			client:sendError(_("You're not on Medical-Duty!", client))
		end
	end
end

function FactionRescue:getStretcher(player, vehicle)
	-- Open the doors
	self.m_LastStrecher[client] = getRealTime().timestamp
	vehicle:setDoorState(4, 0)
	vehicle:setDoorState(5, 0)
	vehicle:setDoorOpenRatio(4, 1)
	vehicle:setDoorOpenRatio(5, 1)

	-- Create the Stretcher
	if not player.m_RescueStretcher then
		player.m_RescueStretcher = createObject(2146, vehicle:getPosition() + vehicle.matrix.forward*-3, vehicle:getRotation())
		player.m_RescueStretcher:setCollisionsEnabled(false)
		player.m_RescueStretcher.m_Vehicle = vehicle
		
		addEventHandler("onElementDimensionChange", player, self.m_RefreshAttachedStretcher)
		addEventHandler("onElementInteriorChange", player, self.m_RefreshAttachedStretcher)
	end
	setElementAlpha(player,255)
	if player:getExecutionPed() then delete(player:getExecutionPed()) end
	-- Move the Stretcher to the Player
	moveObject(player.m_RescueStretcher, 3000, player:getPosition() + player.matrix.forward*1.4 + Vector3(0, 0, -0.5), Vector3(0, 0, player:getRotation().z - vehicle:getRotation().z), "InOutQuad")
	PickupWeaponManager:getSingleton():detachWeapons(player)
	player:setFrozen(true)

	setTimer(
		function (player)
			if isElement(player) then
				player.m_RescueStretcher:attach(player, Vector3(0, 1.4, -0.5))
				if player:getExecutionPed() then
					player:getExecutionPed():putOnStretcher( player.m_RescueStretcher )
				end
				player:toggleControlsWhileObjectAttached(false, true, true, false, true)
				player:setFrozen(false)
				setElementAlpha(player,255)
				if player:getExecutionPed() then delete(player:getExecutionPed()) end
			end
		end, 3000, 1, player
	)
end

function FactionRescue:refreshAttachedStretcher()
	if source.m_RescueStretcher then
		source.m_RescueStretcher:setInterior(source:getInterior())
		source.m_RescueStretcher:setDimension(source:getDimension())
	end
end

function FactionRescue:removeStretcher(player, vehicle)
	-- Move it into the Vehicle
	self.m_LastStrecher[client] = getRealTime().timestamp
	player.m_RescueStretcher:detach()
	player.m_RescueStretcher:setRotation(player:getRotation())
	player.m_RescueStretcher:setPosition(player:getPosition() + player.matrix.forward*1.4 + Vector3(0, 0, -0.5))
	moveObject(player.m_RescueStretcher, 3000, vehicle:getPosition() + vehicle.matrix.forward*-2, Vector3(0, 0, vehicle:getRotation().z - player:getRotation().z), "InOutQuad")
	setElementAlpha(player,255)
	removeEventHandler("onElementDimensionChange", player, self.m_RefreshAttachedStretcher)
	removeEventHandler("onElementInteriorChange", player, self.m_RefreshAttachedStretcher)

	-- Enable Controls
	player:toggleControlsWhileObjectAttached(true, true, true, false, true)

	setTimer(
		function(vehicle, player)
			-- Close the doors
			vehicle:setDoorOpenRatio(4, 0)
			vehicle:setDoorOpenRatio(5, 0)

			if player.m_RescueStretcher.player then
				local deadPlayer = player.m_RescueStretcher.player
				if isElement(deadPlayer) and getElementType(deadPlayer) == "ped" then
					local revMult = 1
					if deadPlayer.m_RevivalMult then revMult = deadPlayer.m_RevivalMult end

					deadPlayer:setPosition(vehicle.position - vehicle.matrix.forward*4)
					deadPlayer:setAnimation()
					if deadPlayer.despawn then
						deadPlayer:despawn()
					else
						deadPlayer:destroy()
					end
					player:sendShortMessage(_("You've successfully revived the citizen!", player))
					self.m_BankAccountServer:transferMoney(self.m_Faction, 100 * revMult, "Rescue Team Revival", "Faction", "Revive")
					self.m_BankAccountServer:transferMoney(player, 100 * revMult, "Rescue Team Revival", "Faction", "Revive")
					self.m_Faction:addLog(player, "Revival", "revived a civilian!")
				elseif isElement(deadPlayer) then
					if deadPlayer:isDead() then
						deadPlayer:triggerEvent("abortDeathGUI")
						local pos = vehicle.position - vehicle.matrix.forward*4
						deadPlayer:sendInfo(_("You were successfully revived!", deadPlayer))
						player:sendShortMessage(_("You successfully revived the player!", player))
						deadPlayer:setCameraTarget(player)
						deadPlayer:respawn(pos)
						deadPlayer:fadeCamera(true, 1)
						self.m_BankAccountServer:transferMoney(self.m_Faction, 100, "Rescue Team Revival", "Faction", "Revive")
						self.m_BankAccountServer:transferMoney(player, 50, "Rescue Team Revival", "Faction", "Revive")
						self.m_Faction:addLog(player, "Revival", ("revived %s!"):format(deadPlayer.name))
						if deadPlayer:giveReviveWeapons() then
							deadPlayer:sendSuccess(_("You have secured your weapons during bleeding out!", deadPlayer))
						end
						
						deadPlayer:clearReviveWeapons()
					else
						player:sendShortMessage(_("The player isn't dead!", player))
					end
				end
			end
			player.m_RescueStretcher:destroy()
			player.m_RescueStretcher = nil
		end, 3000, 1, vehicle, player
	)
end

function FactionRescue:getDefibrillator(player, vehicle)
	if not vehicle.m_RescueDefibrillator then
		vehicle:setDoorState(1, 0)
		vehicle:setDoorOpenRatio(1, 1)
		vehicle.m_RescueDefibrillator = client
		player.m_RescueDefibrillator = true

		vehicle.m_RescueDefibrillatorTimer = setTimer(function()
			if vehicle then
				vehicle.m_RescueDefibrillator = nil
			end
			if player then
				player.m_RescueDefibrillator = nil
			end
		end, 2 * 60 * 1000, 1)
	else
		player:sendError("A Defibrillator has already been unloaded from this vehicle!")
	end
end

function FactionRescue:removeDefibrillator(player, vehicle)
	if vehicle.m_RescueDefibrillator == player then
		vehicle:setDoorOpenRatio(1, 0)
		player.m_RescueDefibrillator = false
		vehicle.m_RescueDefibrillator = nil

		if vehicle.m_RescueDefibrillatorTimer then
			killTimer(vehicle.m_RescueDefibrillatorTimer)
			vehicle.m_RescueDefibrillatorTimer = nil
		end
	else
		player:sendError("The Defibrillator does not belong in this vehicle!")
	end
end

function FactionRescue:useDefibrillator(player, target)
	for index, rescuePlayer in pairs(self:getOnlinePlayers()) do
		rescuePlayer:sendShortMessage(_("%s tries to save %s from bleeding to death, an ambulance is urgently needed!\nPosition: %s - %s", rescuePlayer, player:getName(), target:getName(), getZoneName(player:getPosition()), getZoneName(player:getPosition(), true)))
	end

	local abort = function()
		unbindKey(player, "space", "down", abort)
		player:setAnimation(nil)
		if target and isElement(target) then
			target:triggerEvent("restartBleeding")
		end
	end
	local success = function()
		unbindKey(player, "space", "down", abort)
		player:setAnimation(nil)
	end

	player:sendShortMessage(_("Press 'Spacebar' to end the process!", player))
	player:setAnimation("medic", "cpr", -1, true, false, false, true)
	bindKey(player, "space", "down", abort)

	if target and isElement(target) then
		target:triggerEvent("stopBleeding")
		target.m_RescueDefibrillatorFunction = success
	else
		player:setAnimation(nil)
		unbindKey(player, "space", "down", abort)
		player:sendError("Internal Error occured!")
	end
end

--for player

function FactionRescue:createDeathPickup(player, ...)
	local pos = player:getPosition()

	player.m_DeathPickup = Pickup(pos, 3, 1254, 0)
	player.m_DeathPickup:setDimension(player.dimension)
	player.m_DeathPickup:setInterior(player.interior)

	if not player:isInGangwar() then
		if player:getInterior() == 0 and player:getDimension() == 0 then
			for index, rescuePlayer in pairs(self:getOnlinePlayers()) do
				local text = _("%s needs medical attention.\nPosition: %s - %s", rescuePlayer, player:getName(), getZoneName(player:getPosition()), getZoneName(player:getPosition(), true))
				if rescuePlayer:isFactionDuty() and rescuePlayer:getPublicSync("Rescue:Type") == "medic" then
					rescuePlayer:sendWarning(text, 10000, "Doctor needed")
				else
					rescuePlayer:sendShortMessage(text)
				end
			end
			if self.m_DeathBlips[player] then
				self.m_DeathBlips[player]:delete()
				self.m_DeathBlips[player] = nil
			end
			self.m_DeathBlips[player] = Blip:new("Rescue.png", player.position.x, player.position.y, {faction = 4, duty = true}, 2000, {200, 50, 0})
			self.m_DeathBlips[player]:setDisplayText("Injured Player")
		end
	end

	nextframe(function () if player.m_DeathPickup then player:setPosition(player.m_DeathPickup:getPosition()) end end)

	addEventHandler("onPickupHit", player.m_DeathPickup,
		function (hitPlayer)
			if hitPlayer:getType() == "player" and not hitPlayer.vehicle then
				if hitPlayer:getFaction() and hitPlayer:getFaction():isRescueFaction() then
					if hitPlayer:isFactionDuty() and hitPlayer:getPublicSync("Rescue:Type") == "medic" then
						if hitPlayer.m_RescueStretcher then
							if not hitPlayer.m_RescueStretcher.player then
								if player.m_RescueDefibrillatorFunction then
									player.m_RescueDefibrillatorFunction()
									player.m_RescueDefibrillatorFunction = nil
								end
								player:attach(hitPlayer.m_RescueStretcher, 0, -0.2, 1.4)
								setElementAlpha(player,255)
								if player:getExecutionPed() then delete(player:getExecutionPed()) end
								hitPlayer.m_RescueStretcher.player = player
								if source.m_DeathMoneyDrop and source.m_DeathMoneyDrop > 0 then
									Guns:getSingleton().m_BankAccountServerCorpse:transferMoney(hitPlayer, source.m_DeathMoneyDrop, "Get lost money back", "Player", "Corpse")
									source.m_DeathMoneyDrop = 0
								end

								source:destroy()
								player.m_DeathPickup = nil
								if self.m_DeathBlips[player] then
									self.m_DeathBlips[player]:delete()
									self.m_DeathBlips[player] = nil
								end
							else
								hitPlayer:sendError(_("There is already a player on the stretcher! (%s)", hitPlayer, inspect(hitPlayer.m_RescueStretcher.player)))
							end
						elseif hitPlayer.m_RescueDefibrillator then
							self:useDefibrillator(hitPlayer, player)
						else
							hitPlayer:sendError(_("You don't have a defibrillator or stretcher with you!", hitPlayer))
						end
					end
				else
					hitPlayer:sendShortMessage(("He's dead son.\nIn Memories of %s"):format(player:getName()))
				end
			end
		end
	)
	-- Create PlayerDeathTimeout
	--self:createDeathTimeout(player, ...)
end

function FactionRescue:destroyDeathBlip()
	if client.m_DeathPickup then
		client:dropReviveMoney()
		client.m_DeathPickup:destroy()
		client.m_DeathPickup = nil
		if self.m_DeathBlips[client] then
			self.m_DeathBlips[client]:delete()
			self.m_DeathBlips[client] = nil
		end
	end
end

function FactionRescue:createDeathTimeout(player, callback)
	--player:triggerEvent("playerRescueDeathTimeout", PLAYER_DEATH_TIME)
	setTimer(
		function ()
			if player.m_DeathPickup then
				player.m_DeathPickup:destroy()
				player.m_DeathPickup = nil
			end
			return callback()
		end, 5000, 1
		-- PLAYER_DEATH_TIME
	)
end

--for peds

function FactionRescue:createPedDeathPickup(ped, pedname)
	local pos = ped:getPosition()

	ped.m_DeathPickup = Pickup(pos, 3, 1254, 0)

	for index, rescuePlayer in pairs(self:getOnlinePlayers()) do
		rescuePlayer:sendShortMessage(_("%s needs medical attention.\nPosition: %s - %s", rescuePlayer, pedname, getZoneName(pos), getZoneName(pos, true)))
	end
	if self.m_DeathBlips[ped] then
		self.m_DeathBlips[ped]:delete()
		self.m_DeathBlips[ped] = nil
	end
	self.m_DeathBlips[ped] = Blip:new("Rescue.png", ped.position.x, ped.position.y, {faction = 4, duty = true}, 2000, {150, 50, 0})
	self.m_DeathBlips[ped]:setDisplayText("Wounded citizen")

	nextframe(function () if ped.m_DeathPickup then ped:setPosition(ped.m_DeathPickup:getPosition()) end end)

	addEventHandler("onPickupHit", ped.m_DeathPickup,
		function (hitPlayer)
			if hitPlayer:getType() == "player" and not hitPlayer.vehicle then
				if hitPlayer:getFaction() and hitPlayer:getFaction():isRescueFaction() then
					if hitPlayer:isFactionDuty() and hitPlayer:getPublicSync("Rescue:Type") == "medic" then
						if hitPlayer.m_RescueStretcher then
							if not hitPlayer.m_RescueStretcher.player then
								if ped and isElement(ped) then
									ped:attach(hitPlayer.m_RescueStretcher, 0, -0.2, 1.4)

									hitPlayer.m_RescueStretcher.player = ped
									self:removePedDeathPickup(ped)
								else
									hitPlayer:sendError(_("The citizen could not be placed on the stretcher (%s)!", hitPlayer, ped))
								end
							else
								hitPlayer:sendError(_("There is already a citizen on the stretcher! (%s)", hitPlayer, inspect(hitPlayer.m_RescueStretcher.player)))
							end
						else
							hitPlayer:sendError(_("You don't have a stretcher with you!", hitPlayer))
						end
					end
				else
					hitPlayer:sendShortMessage(("He's dead son.\nIn Memories of %s"):format(pedname))
				end
			end
		end
	)
end

function FactionRescue:removePedDeathPickup(ped)
	if ped.m_DeathPickup and isElement(ped.m_DeathPickup) then
		ped.m_DeathPickup:destroy()
		ped.m_DeathPickup = nil
		if self.m_DeathBlips[ped] then
			self.m_DeathBlips[ped]:delete()
			self.m_DeathBlips[ped] = nil
		end
	end
end

function FactionRescue:Event_OnPlayerWastedFinish(spawnAtHospial)
	source:setCameraTarget(source)
	source:fadeCamera(true, 1)

	if source:getFaction() and source.m_WasOnDuty and not source.m_DeathInJail and source.m_JailTime == 0 then
		if not spawnAtHospial then 
			source.m_WasOnDuty = false
			local position = factionSpawnpoint[source:getFaction():getId()]
			source:respawn(position[1])
			source:setInterior(position[2])
			source:setDimension(position[3])
			return
		end
	end

	source:respawn()
end

function FactionRescue:Event_healPlayerQuestion(target)
	if isElement(target) then
		if target:getHealth() < 100 then
			local costs = math.floor(100-target:getHealth())
			QuestionBox:new(target, _("The Medic %s offers to healing you! \nThis costs %d$! Accept?", target, client.name, costs), "factionRescueHealPlayer", "factionRescueDiscardHealPlayer", client, 20, client, target)
		else
			client:sendError(_("The player is fully alive!", client))
		end
	else
		client:sendError(_("Interner Error: Argumente falsch @FactionRescue:Event_healPlayerQuestion!", client))
	end
end

function FactionRescue:Event_discardHealPlayer(medic, target)
    medic:sendError(_("Player %s has rejected the heal!", medic, target.name))
    target:sendError(_("You rejected the heal with %s!", target, medic.name))
end

function FactionRescue:Event_healPlayer(medic, target)
	if isElement(target) then
		if target:getHealth() < 100 then

			local costs = math.floor(100-target:getHealth())
			if target:getMoney() >= costs then
				medic:sendInfo(_("You have healed player %s for %d$!", medic, target.name, costs))
				target:sendInfo(_("You have been healed by medic %s for %d$!", target, medic.name, costs))
				target:setHealth(100)
				StatisticsLogger:getSingleton():addHealLog(client, 100, "Rescue Team "..medic.name)
				client:checkLastDamaged()
				target:transferMoney(self.m_Faction, costs, "Rescue Team Healing", "Faction", "Healing")
			
				self.m_Faction:addLog(medic, "Healing", ("healed %s!"):format(target.name))
			else
				medic:sendError(_("The player does not have enough money! (%d$)", medic, costs))
				target:sendError(_("You do not have enough money! (%d$)", target, costs))
			end
			
		else
			medic:sendError(_("The player is fully alive!", medic))
		end
	else
		medic:sendError(_("Interner Error: Argumente falsch @FactionRescue:Event_healPlayer!", medic))
	end
end

function FactionRescue:Event_healPlayerHospital()
	if isElement(client) then
		if client:getHealth() < 100 then
			local costs = math.floor(100-client:getHealth())
			if client:getMoney() >= costs then
				client:setHealth(100)
				StatisticsLogger:getSingleton():addHealLog(client, 100, "Rescue Team [Heal-Bot]")
				client:checkLastDamaged()
				client:sendInfo(_("You were healed by the doctor for %s$!", client, costs))

				client:transferMoney(self.m_Faction, costs, "Rescue Team Healing", "Faction", "Healing")
			else
				client:sendError(_("You don't have enough money with you! (%s$)", client, costs))
			end
		else
			client:sendError(_("You are already fully alive.", client))
		end
	end
end

function FactionRescue:onLadderTruckEnter(player, seat)
	if seat > 0 then return end
	if not source.LadderEnabled then
		player:sendShortMessage(_("Click on the vehicle to operate the ladder!", player))
	else
		player:sendShortMessage(_("You are in ladder mode. Controls:\nW, A, S, D - Rotate ladder, move up/down\nCTRL, SHIFT - Extend/Retract ladder\nMouse wheel - Change camera zoom\nClick on the ladder - Exit mode", player), _("Ladder Truck", player), {0, 50, 100}, 12000)
		self:toggleLadder(source, player, true)
	end
end

function FactionRescue:disableLadderBinds(player)
	if player and isElement(player) and getElementType(player) == "player" then
		unbindKey(player, "w", "both", self.m_LadderBind)
		unbindKey(player, "a", "both", self.m_LadderBind)
		unbindKey(player, "s", "both", self.m_LadderBind)
		unbindKey(player, "d", "both", self.m_LadderBind)
		unbindKey(player, "lctrl", "both", self.m_LadderBind)
		unbindKey(player, "lshift", "both", self.m_LadderBind)
		self:disableControlsForLadder(player, false)
	end
end

function FactionRescue:onLadderTruckExit(player, seat)
	if seat > 0 then return end
	if source.LadderEnabled then
		self:disableLadderBinds(player)
		player:triggerEvent("stopCenteredFreecam", source)
		if source.LadderTimer and isTimer(source.LadderTimer) then
			killTimer(source.LadderTimer)
		end
	end
end

function FactionRescue:onLadderTruckReset(veh)
	if veh.Ladder then
		veh.Ladder["main"]:setAttachedOffsets(0, 0.5, 1.1)
		veh.Ladder["ladder1"]:setAttachedOffsets(-0.08, 0, 0)
		veh.Ladder["ladder2"]:setAttachedOffsets(0, -0.5, 0.1)
		veh.Ladder["ladder3"]:setAttachedOffsets(0, -0.5, 0.1)
		veh.LadderEnabled = false
		veh.m_DisableToggleHandbrake = false
	else
		addEventHandler("onVehicleEnter", veh, bind(self.onLadderTruckEnter, self))
		addEventHandler("onVehicleStartExit", veh, bind(self.onLadderTruckExit, self))

		veh.LadderEnabled = false
		veh.LadderMove = {}

		veh.Ladder = {}
		veh.Ladder["main"] = createObject(1932, veh:getPosition())
		veh.Ladder["main"]:attach(veh, 0, 0.5, 1.1)
		veh.Ladder["mainAttachOffset"] = Vector3(0, 0.5, 1.1)

		veh.Ladder["ladder1"] = createObject(1931, veh:getPosition())
		veh.Ladder["ladder1"]:attach(veh.Ladder["main"], -0.08, 0, 0)

		veh.Ladder["ladder2"] = createObject(1931, veh:getPosition())
		veh.Ladder["ladder2"]:setScale(0.92)
		veh.Ladder["ladder2"]:attach(veh.Ladder["ladder1"], 0, -0.5, 0.1)

		veh.Ladder["ladder3"] = createObject(1931, veh:getPosition())
		veh.Ladder["ladder3"]:setScale(0.84)
		veh.Ladder["ladder3"]:attach(veh.Ladder["ladder2"], 0, -0.5, 0.1)
		for i,v in pairs(veh.Ladder) do
			if isElement(v) then
				if i ~= "main" then
					setElementCollisionsEnabled(v, true)
				end
				setElementData(v, "vehicle-attachment", veh) --register as a clickable object of the fire truck (mouse menu)
			end
		end
	end

	for i,v in pairs(veh.Ladder) do
		if isElement(v) then
			setElementCollisionsEnabled(v, false)
		end
	end

	if veh.LadderTimer and isTimer(veh.LadderTimer) then
		killTimer(veh.LadderTimer)
	end
end

function FactionRescue:disableControlsForLadder(player, disabling)
	toggleControl(player, "vehicle_left", not disabling)
	toggleControl(player, "vehicle_right", not disabling)
	toggleControl(player, "accelerate", not disabling)
	toggleControl(player, "brake_reverse", not disabling)
end

function FactionRescue:toggleLadder(veh, player, force)
	if veh.LadderEnabled and not force then
		if veh.LadderTimer and isTimer(veh.LadderTimer) then
			killTimer(veh.LadderTimer)
		end
		if player then
			player:sendShortMessage(_("Ladder deactivated! You can drive the vehicle again!", player))
			self:disableLadderBinds(player)
			player:triggerEvent("stopCenteredFreecam", veh)
		end
		self:onLadderTruckReset(veh)
		veh:setFrozen(false)
		triggerClientEvent("rescueLadderUpdateCollision", veh, false)
	else
		if (veh.rotation.x < 5 or veh.rotation.x > 355) and (veh.rotation.y < 10 or veh.rotation.y > 350) then
			player:sendShortMessage(_("You are in ladder mode. Controls:\nW, A, S, D - Rotate ladder, move up/down\nCTRL, SHIFT - Extend/Retract ladder\nMouse wheel - Change camera zoom\nClick on the ladder - Exit mode", player), _("Ladder Truck", player), {0, 50, 100}, 10000)
			veh.LadderEnabled = true
			bindKey(player, "w", "both", self.m_LadderBind)
			bindKey(player, "a", "both", self.m_LadderBind)
			bindKey(player, "s", "both", self.m_LadderBind)
			bindKey(player, "d", "both", self.m_LadderBind)
			self:disableControlsForLadder(player, true)
			bindKey(player, "lctrl", "both", self.m_LadderBind)
			bindKey(player, "lshift", "both", self.m_LadderBind)
			veh.LadderTimer = setTimer(self.m_MoveLadderBind, 50, 0, veh)
			veh:setFrozen(true)
			veh:setRotation(0, 0, veh.rotation.z)
			veh.m_DisableToggleHandbrake = true
			triggerClientEvent("rescueLadderUpdateCollision", veh, true)
			player:triggerEvent("startCenteredFreecam", veh, 25)
		else
			player:sendError(_("Find a more even surface!", player))
		end
	end
end


function FactionRescue:Event_toggleLadder()
	self:toggleLadder(source, client)
end

function FactionRescue:ladderFunction(player, key, state)
	local veh = player.vehicle
	if not veh then self:disableLadderBinds(player) return end
	if veh:getModel() ~= 544 then self:disableLadderBinds(player) return end

	if key == "d" then	veh.LadderMove["left"] = state == "down" and true or false end
	if key == "a" then	veh.LadderMove["right"] = state == "down" and true or false end
	if key == "w" then	veh.LadderMove["up"] = state == "down" and true or false end
	if key == "s" then	veh.LadderMove["down"] = state == "down" and true or false end
	if key == "lctrl" then	veh.LadderMove["in"] = state == "down" and true or false end
	if key == "lshift" then	veh.LadderMove["out"] = state == "down" and true or false end
end

function FactionRescue:moveLadder(veh)
	local x, y, z, rx, ry, rz = getElementAttachedOffsets(veh.Ladder["main"])
	local x1, y1, z1, rx1, ry1, rz1 = getElementAttachedOffsets(veh.Ladder["ladder1"])
	local x2, y2, z2, rx2, ry2, rz2 = getElementAttachedOffsets(veh.Ladder["ladder2"])
	local x3, y3, z3, rx3, ry3, rz3 = getElementAttachedOffsets(veh.Ladder["ladder3"])


	if veh.LadderMove["right"] then
		veh.Ladder["main"]:setAttachedOffsets(x, y, z, rx, ry, rz+0.7)
	elseif veh.LadderMove["left"] then
		veh.Ladder["main"]:setAttachedOffsets(x, y, z, rx, ry, rz-0.7)
	end
	--[[
		veh.Ladder["ladder1"]:setAttachedOffsets(0, 0, 0)
		veh.Ladder["ladder2"]:setAttachedOffsets(0, -0.5, 0.03)
		veh.Ladder["ladder3"]:setAttachedOffsets(0, -0.5, 0.03)
	]]
	if veh.LadderMove["up"] then
		if rx1 > -50 then
			veh.Ladder["ladder1"]:setAttachedOffsets(x1, y1, z1, rx1-0.5, ry1, rz1)
		end
	elseif veh.LadderMove["down"] then
		if rx1 < 0 then
			veh.Ladder["ladder1"]:setAttachedOffsets(x1, y1, z1, rx1+0.5, ry1, rz1)
		end
	end

	if veh.LadderMove["in"] then
		if y3 < -0.5 then
			veh.Ladder["ladder3"]:setAttachedOffsets(x3, y3+0.1, z3, rx3, ry3, rz3)
		elseif y2 < -0.5 then
			veh.Ladder["ladder2"]:setAttachedOffsets(x2, y2+0.1, z2, rx2, ry2, rz2)
		end
	elseif veh.LadderMove["out"] then
		if y2 > -5.5 then
			veh.Ladder["ladder2"]:setAttachedOffsets(x2, y2-0.05, z2, rx2, ry2, rz2)
		elseif y3 > -5 then
			veh.Ladder["ladder3"]:setAttachedOffsets(x3, y3-0.05, z3, rx3, ry3, rz3)
		end
	end

	if not veh.controller then
		killTimer(sourceTimer)
	end
end

function FactionRescue:Event_fillFireExtinguisher()
	giveWeapon(client, 42, (10000 - getPedTotalAmmo(client, 9)), true)
end

function FactionRescue:addVehicleFire(veh)
	if not instanceof(veh, PermanentVehicle) then return end

	local pos = veh:getPosition()
	local zone = getZoneName(pos).."/"..getZoneName(pos, true)
	self:sendWarning("A car has caught fire! Position: %s", "Fire-Alarm", true, pos, zone)
	self.m_VehicleFires[veh] = FireRoot:new(pos.x-4, pos.y-4, pos.z, 8, 8)
	self.m_VehicleFires[veh]:setName("Fahrzeug-Brand "..zone)

	if veh.controller then
		veh.controller:sendWarning(_("Your vehicle has caught fire! Get out quickly!", veh.controller))
	end

	local model = veh:getModel()
	local pos = veh:getPosition()
	local rx, ry, rz = getElementRotation(veh)
	local r1, g1, b1, r2, g2, b2 = veh:getColor(true)
	setTimer(function(veh)
		if instanceof(veh, FactionVehicle) or instanceof(veh, CompanyVehicle) then
			local occs = veh:getOccupants()
			if occs then
				for i, occ in pairs(occs) do
					occ:removeFromVehicle()
				end
			end
			veh:respawn(true)
		else
			CompanyManager:getSingleton():getFromId(CompanyStaticId.MECHANIC):respawnVehicle(veh)
		end

		self.m_VehicleFires[veh].Blip = Blip:new("Warning.png", pos.x, pos.y, root, 400)
		self.m_VehicleFires[veh].Blip:setOptionalColor(BLIP_COLOR_CONSTANTS.Orange)
		self.m_VehicleFires[veh].Blip:setDisplayText("Traffic Obstruction")

		local tempVehicle = TemporaryVehicle.create(model, pos.x, pos.y, pos.z, rz)
		tempVehicle:setHealth(300)
		tempVehicle:setColor(r1, g1, b1, r2, g2, b2)
		tempVehicle:disableRespawn(true)
		tempVehicle:setLocked(true)
		tempVehicle:setData("Burned", true, true)
		tempVehicle.burned = true
		tempVehicle.Blip = Blip:new("CarShop.png", 0, 0, {company = CompanyStaticId.MECHANIC}, 400)
		tempVehicle.Blip:setColor({150, 150, 150}) -- gets deleted on tow
		tempVehicle.Blip:setDisplayText("Wrecked-Car")
		tempVehicle.Blip:attachTo(tempVehicle)

		CompanyManager:getSingleton():getFromId(CompanyStaticId.MECHANIC):sendWarning("A burnt car wreck must be towed away! Position: %s", "Wrecked-Car", true, pos, zone)
		for i= 0, 5 do tempVehicle:setDoorState(i, chance(50) and 2 or 4) end
		tempVehicle:setWheelStates(chance(50) and 1 or 0, chance(50) and 1 or 0, chance(50) and 1 or 0, chance(50) and 1 or 0)

	end, 10000, 1, veh)

	self.m_VehicleFires[veh]:setOnFinishHook(function(stats)
		self.m_VehicleFires[veh].Blip:delete()
		local moneyForFaction = 0
		local playersByID = {}
		local mostPoints = {}
		for player, score in pairs(stats.pointsByPlayer) do
			if isElement(player) then
				player:giveCombinedReward("Vehicle Fire Extinguished", {
					money = {
						mode = "give",
						bank = true,
						amount = score*120,
						toOrFrom = self.m_BankAccountServer,
						category = "Faction",
						subcategory = "Fire"
					},
					points = math.random(5, 10)
				})
				playersByID[player:getId()] = score
				moneyForFaction = moneyForFaction + score*120
				table.insert(mostPoints, score)
			end
		end
		FactionRescue:getSingleton().m_BankAccountServer:transferMoney(FactionRescue:getSingleton().m_Faction, moneyForFaction * table.size(stats.pointsByPlayer), "Vehicle Fire Put Out", "Faction", "VehicleFire")
		StatisticsLogger:getSingleton():addFireLog(-1, math.floor(self.m_VehicleFires[veh]:getTimeSinceStart()/1000), toJSON(playersByID), (table.size(stats.pointsByPlayer) > 0) and 1 or 0, moneyForFaction)
		
		table.sort(mostPoints, function(a, b) return a > b end)
		FactionRescue:getSingleton().m_Faction:addLog(table.find(playersByID, mostPoints[1]), "Brand", ("has extinguished a burned vehicle (%s min.) (+%s$)."):format(math.floor((getTickCount()-stats.startTime)/1000/60), moneyForFaction))

		self.m_VehicleFires[veh] = nil
	end, zone)
end

function FactionRescue:outputMegaphone(player, ...)
	local faction = player:getFaction()
	if faction and faction:isRescueFaction() == true then
		if player:isFactionDuty() then
			if player:getOccupiedVehicle() and player:getOccupiedVehicle():getFaction() and player:getOccupiedVehicle():getFaction():isRescueFaction() then
				local playerId = player:getId()
				local playersToSend = player:getPlayersInChatRange(3)
				local receivedPlayers = {}
				local text = ("[[ %s %s: %s ]]"):format(faction:getShortName(), player:getName(), table.concat({...}, " "))
				for index = 1,#playersToSend do
					playersToSend[index]:sendMessage(text, 255, 255, 0)
					if playersToSend[index] ~= player then
						receivedPlayers[#receivedPlayers+1] = playersToSend[index]
					end
				end

				StatisticsLogger:getSingleton():addChatLog(player, "chat", text, receivedPlayers)
				FactionState:getSingleton():addBugLog(player, "(Megaphone)", text)
				return true
			else
				player:sendError(_("You're not in a faction vehicle!", player))
			end
		else
			player:sendError(_("You're not on duty!", player))
		end
	end
	return false
end

function FactionRescue:Event_changeRadioStatus(status)
	if client:getFaction() and client:getFaction():isRescueFaction() and client:isFactionDuty() then
		if not client.lastStatusChange then client.lastStatusChange = 0 end
		if client.lastStatusChange + 3 < getRealTime().timestamp then
			local faction = client:getFaction()
			local rankName = faction:getRankName(faction:getPlayerRank(client))
			for i, player in pairs(self:getOnlinePlayers(false, true)) do
				if player ~= client then
					player:sendShortMessage(_("%s %s Reports Status %s", player, rankName, client:getName(), status))
				else
					client:sendInfo(_("You Report Status %s", client, status))
				end
			end
			client.lastStatusChange = getRealTime().timestamp
			client:setPublicSync("RadioStatus", status)
		end
	else
		if client:getFaction() and client:getFaction():isRescueFaction() then
			client:sendError(_("You're not on duty!", client))
		end
	end
end