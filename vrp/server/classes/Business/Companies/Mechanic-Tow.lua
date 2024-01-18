MechanicTow = inherit(Company)
addRemoteEvents{"mechanicRepair", "mechanicRepairConfirm", "mechanicRepairCancel", "mechanicDetachFuelTank", "mechanicTakeFuelNozzle", "mechanicRejectFuelNozzle", "mechanicTakeVehicle", "mechanicOpenTakeGUI", "mechanicVehicleRequestFill", "mechanicAttachBike", "mechanicDetachBike"}

function MechanicTow:constructor()
	self.m_PendingQuestions = {}

	local safe = createObject(2332, 2456.191, -2106.406, 12.9, 0, 0, 270)
	safe:setScale(0.7)
	self:setSafe(safe)

	self.m_TowColShape = createColRectangle(2649.02, -2122.29, 18.5, 10.5)

	local blip = Blip:new("CarLot.png", 2465.677, -2093.584, root, 400)
	blip:setOptionalColor({150, 150, 150})
	blip:setDisplayText("Autohof", BLIP_CATEGORY.VehicleMaintenance)

	local id = self:getId()
	local blip = Blip:new("House.png", 2481.79, -2097.76, {company = id}, 400, {companyColors[id].r, companyColors[id].g, companyColors[id].b})
	blip:setDisplayText(self:getName(), BLIP_CATEGORY.Company)

	self.m_FillAccept = bind(MechanicTow.FillAccept, self)
	self.m_FillDecline = bind(MechanicTow.FillDecline, self)
	self.m_BankAccountServer = BankServer.get("company.mechanic")

	addEventHandler("onColShapeHit", self.m_TowColShape, bind(self.onEnterTowLot, self))
	addEventHandler("onColShapeLeave", self.m_TowColShape, bind(self.onLeaveTowLot, self))
	addEventHandler("mechanicRepair", root, bind(self.Event_mechanicRepair, self))
	addEventHandler("mechanicRepairConfirm", root, bind(self.Event_mechanicRepairConfirm, self))
	addEventHandler("mechanicRepairCancel", root, bind(self.Event_mechanicRepairCancel, self))
	addEventHandler("mechanicDetachFuelTank", root, bind(self.Event_mechanicDetachFuelTank, self))
	addEventHandler("mechanicTakeFuelNozzle", root, bind(self.Event_mechanicTakeFuelNozzle, self))
	addEventHandler("mechanicRejectFuelNozzle", root, bind(self.Event_mechanicRejectFuelNozzle, self))
	addEventHandler("mechanicVehicleRequestFill", root, bind(self.Event_mechanicVehicleRequestFill, self))
	addEventHandler("mechanicTakeVehicle", root, bind(self.Event_mechanicTakeVehicle, self))
	addEventHandler("mechanicOpenTakeGUI", root, bind(self.VehicleTakeGUI, self))
	addEventHandler("mechanicAttachBike", root, bind(self.Event_mechanicAttachBike, self))
	addEventHandler("mechanicDetachBike", root, bind(self.Event_mechanicDetachBike, self))
	addEventHandler("onTrailerAttach", root, bind(self.onAttachVehicleToTow, self))
	addEventHandler("onTrailerDetach", root, bind( self.onDetachVehicleFromTow, self))

	PlayerManager:getSingleton():getQuitHook():register(bind(self.onPlayerQuit, self))
end

function MechanicTow:destuctor()
end

function MechanicTow:onPlayerQuit(player)
	if isElement(player.mechanic_fuelNozzle) then
		player.mechanic_fuelNozzle:destroy()
	end
end

function MechanicTow:respawnVehicle(vehicle)
	outputDebug("Respawning vehicle in mechanic base")
	local occs = vehicle:getOccupants()
	if occs then
		for i, occ in pairs(occs) do
			occ:removeFromVehicle()
		end
	end
	if vehicle.m_RcVehicleUser then
		for i, player in pairs(vehicle.m_RcVehicleUser) do
			vehicle:toggleRC(player, player:getData("RcVehicle"), false, true)
			player:removeFromVehicle()
		end
	end
	if instanceof(vehicle, FactionVehicle, true) then -- respawn faction vehicles immediately
		vehicle:respawn(true, true)
		vehicle:getFaction():transferMoney(self, 1500, "Vehicle bought free", "Company", "VehicleFreeBought", {silent = true, allowNegative = true})
		vehicle:getFaction():sendShortMessage(("The vehicle %s (%s) was towed away by the M&T and respawned at your base for %s!"):format(vehicle:getName(), vehicle:getPlateText(), toMoneyString(1500)))
	else
		if instanceof(vehicle, GroupVehicle, true) then
			GroupManager.Map[vehicle:getOwner()]:transferMoney({"company", self:getId(), true, true}, 500, "Mech&Tow towing costs", "Company", "VehicleTowed")
		end

		if instanceof(vehicle, PermanentVehicle, true) then
			Async.create( -- player:load()/:save() needs a aynchronous execution
				function()
					local player, isOffline = DatabasePlayer.get(vehicle:getOwner())

					if isOffline then
						player:load()
					end

					player:transferBankMoney({"company", self:getId(), true, true}, 500, "Mech&Tow towing costs", "Company", "VehicleTowed")

					if isOffline then
						delete(player)
					end
				end
			)()
		end
		
		vehicle:setPositionType(VehiclePositionType.Mechanic)
		vehicle:setDimension(PRIVATE_DIMENSION_SERVER)
	end
	vehicle:fix()
end

function MechanicTow:VehicleTakeGUI(vehicleType)
	local vehicleTable = {}

	if vehicleType == "permanentVehicle" then
		vehicleTable = VehicleManager:getSingleton():getPlayerVehicles(client)
	elseif vehicleType == "groupVehicle" then
		local group = client:getGroup()
		if not group then client:sendError(_("You are not in a group!", client)) return end
		vehicleTable = group:getVehicles()
	end

	-- Get a list of vehicles that need manual repairing
	local vehicles = {}
	for _, vehicle in pairs(vehicleTable) do
		if vehicle:getPositionType() == VehiclePositionType.Mechanic then
			table.insert(vehicles, vehicle)
		end
	end

	if #vehicles > 0 then
		-- Open "vehicle take GUI"
		-- Todo: Probably better: Trigger a vehicle table with different vehicle types and add specific tabs to VehicleTakeGUI
		client:triggerEvent("vehicleTakeMarkerGUI", vehicles, "mechanicTakeVehicle")
	else
		client:sendInfo(_("No vehicles available for collection!", client))
	end
end

function MechanicTow:Event_mechanicRepair()
	if client:getCompany() ~= self then
		return
	end
	if not client:isCompanyDuty() then
		client:sendError(_("You are not on duty!", client))
		return
	end

	local driver = source:getOccupant(0)
	if not driver then
		client:sendError(_("Someone must be in the driver's seat!", client))
		return
	end
	if driver == client then
		client:sendError(_("Get out of your vehicle and stand on the hood!", client))
		return
	end
	if source:getHealth() > 950 then
		client:sendError(_("This vehicle has no significant damage!", client))
		return
	end

	if not source:isRepairAllowed() then
		client:sendError(_("This vehicle cannot be repaired!", client))
		return
	end

	source.PendingMechanic = client
	local price = math.floor((1000 - getElementHealth(source))*0.5)

	if self.m_PendingQuestions[client] and not timestampCoolDown(self.m_PendingQuestions[client], 20) then
		client:sendError(_("You can only submit a repair request every 20 seconds!", client))
		return
	end

	self.m_PendingQuestions[client] = getRealTime().timestamp
	QuestionBox:new(driver,  _("May %s repair your vehicle? This currently costs you %d$!\nAt the next Pay'n'Spray, you will pay a surcharge of +33%%!", driver, getPlayerName(client), price), "mechanicRepairConfirm", "mechanicRepairCancel", client, 20, source)
end

function MechanicTow:Event_mechanicRepairConfirm(vehicle)
	local price = math.floor((1000 - getElementHealth(vehicle))*0.5)
	if source:getBankMoney() >= price then
		vehicle:fix()
		source:transferBankMoney(self.m_BankAccountServer, price, "Mech&Tow repair", "Company", "Repair")

		if vehicle.PendingMechanic then
			if source ~= vehicle.PendingMechanic then
				self.m_PendingQuestions[vehicle.PendingMechanic] = getRealTime().timestamp

				self.m_BankAccountServer:transferMoney({vehicle.PendingMechanic, true}, price*0.3, "Repair", "Company", "Repair")
				vehicle.PendingMechanic:givePoints(2)
				vehicle.PendingMechanic:sendInfo(_("You have successfully repaired %s' vehicle! You have earned %s$!", vehicle.PendingMechanic, getPlayerName(source), price*0.3))
				source:sendInfo(_("%s has successfully repaired your vehicle!", source, getPlayerName(vehicle.PendingMechanic)))

				self.m_BankAccountServer:transferMoney({"company", CompanyStaticId.MECHANIC, true, true}, price*0.6, "Repair", "Company", "Repair")
			else
				source:sendInfo(_("You've successfully repaired your vehicle!", source))
			end
			vehicle.PendingMechanic = nil
		end
	else
		source:sendError(_("You don't have enough money! You need %d$!", source, price))
	end
end

function MechanicTow:Event_mechanicRepairCancel(vehicle)
	if vehicle.PendingMechanic then
		vehicle.PendingMechanic:sendWarning(_("The repair process was canceled by the other party!", vehicle.PendingMechanic))
		vehicle.PendingMechanic = nil
	end
end

function MechanicTow:Event_mechanicTakeVehicle()
	if instanceof(source, GroupVehicle, true) then
		if not client:getGroup():transferMoney(self, 1000, "Vehicle bought free", "Company", "VehicleFreeBought") then
			client:sendError(_("There is not enough money in the cash box of your %s! (1000$)", client, client:getGroup():getType()))
			return false
		end
	else
		if not client:transferBankMoney(self, 1000, "Vehicle bought free", "Company", "VehicleFreeBought") then
			client:sendError(_("You don't have enough money! (1000$)", client))
			return false
		end
	end
	source:fix()

	-- Spawn vehicle in non-collision zone
	source:setPositionType(VehiclePositionType.World)
	source:setDimension(0)
	source:setInterior(0)
	local x, y, z, rotation = unpack(Randomizer:getRandomTableValue(MechanicTow.SpawnPositions))
	local text = "in the backyard"
	if source:isAirVehicle() and source:getModel() ~= 460 then
		x, y, z, rotation = 2008.82, -2453.75, 13, 120 -- ls airport east
		text = "at the airport in Los Santos"
	elseif source:isWaterVehicle() or source:getModel() == 460 then
		x, y, z, rotation = 2350.26, -2523.06, 0, 180 -- ls docks
		text = "at the Ocean Docks"
	end

	source:setPosition(x, y, z + source:getBaseHeight())
	source:setRotation(0, 0, rotation)
	client:sendSuccess(_("Vehicle bought free, it's %s ready! The money has been deducted from your account.", client, text))
end

function MechanicTow:isValidTowableVehicle(veh)
	return instanceof(veh, PermanentVehicle, true) or instanceof(veh, GroupVehicle, true) or instanceof(veh, FactionVehicle, true) or veh.burned
end

function MechanicTow:onEnterTowLot(hitElement)
	if getElementType(hitElement) ~= "player" then return end
	if hitElement:getCompany() ~= self then return end
	if hitElement:isCompanyDuty() ~= true then return end
	if not hitElement.vehicle or not hitElement.vehicle.getCompany or hitElement.vehicle:getCompany() ~= self or (hitElement.vehicle:getModel() ~= 525 and hitElement.vehicle:getModel() ~= 417) then return end

	local towingBike = hitElement.vehicle:getData("towingBike")
	if isElement(towingBike) then

		if towingBike.burned then
			if towingBike.Blip then
				towingBike.Blip:delete()
			end
			self:addLog(hitElement, "Towing logs", ("has towed a vehicle wreck (%s)!"):format(towingBike:getName()))
			towingBike:destroy()
			hitElement.vehicle:setData("towingBike", nil, true)
			hitElement:sendInfo(_("You have successfully towed away a wrecked vehicle!", hitElement))
			self.m_BankAccountServer:transferMoney(hitElement, 200, "Vehicle wreck", "Company", "Towed")
		else

			towingBike:toggleRespawn(true)
			towingBike:setCollisionsEnabled(true)
			towingBike:detach()
			self:respawnVehicle(towingBike)

			towingBike:setData("towedByVehicle", nil, true)
			hitElement.vehicle:setData("towingBike", nil, true)

			StatisticsLogger:getSingleton():vehicleTowLogs(hitElement, towingBike)
			self:addLog(hitElement, "Towing logs", ("has towed a vehicle (%s) from %s!"):format(towingBike:getName(), getElementData(towingBike, "OwnerName") or "Unbekannt"))
		end
	else
		hitElement.vehicle:setData("towingBike", nil, true)
	end

	hitElement.m_InTowLot = true
	hitElement:sendInfo(_("You can unload towed vehicles here!", hitElement))
end

function MechanicTow:sendWarning(text, header, withOffDuty, pos, ...)
	for k, player in pairs(self:getOnlinePlayers(false, not withOffDuty)) do
		player:sendWarning(_(text, player, ...), 30000, header)
	end
	if pos and pos.x then pos = {pos.x, pos.y, pos.z} end -- serialiseVector conversion
	if pos and pos[1] and pos[2] then
		local blip = Blip:new("Warning.png", pos[1], pos[2], {company = self:getId()}, 4000, BLIP_COLOR_CONSTANTS.Orange)
			blip:setDisplayText(header)
		if pos[3] then
			blip:setZ(pos[3])
		end
		setTimer(function()
			blip:delete()
		end, 30000, 1)
	end
end

function MechanicTow:onLeaveTowLot(hitElement)
	if getElementType(hitElement) ~= "player" then return end
	hitElement.m_InTowLot = nil
end

function MechanicTow:onAttachVehicleToTow(towTruck)
	local driver = getVehicleOccupant(towTruck)
	if driver and getElementType(driver) == "player" then
		if driver:getCompany() == self and driver:isCompanyDuty() then
			if towTruck.getCompany and towTruck:getCompany() == self and towTruck:getModel() == 525 then
				if self:isValidTowableVehicle(source) then
					source:toggleRespawn(false)
					source.m_HasBeenUsed = 1 --disable despawn on logout
				else
					driver:sendInfo(_("This vehicle cannot be towed!", driver))
				end
			end
		end
	end
end

function MechanicTow:onDetachVehicleFromTow(towTruck, vehicle)
	local source = vehicle and vehicle or source
	source:toggleRespawn(true)

	local driver = getVehicleOccupant(towTruck)
	if driver and driver.m_InTowLot then
		if driver:getCompany() == self and driver:isCompanyDuty() then
			if towTruck.getCompany and towTruck:getCompany() == self then
				if self:isValidTowableVehicle(source) then
					if not source.burned then
						self:respawnVehicle(source)
						driver:sendInfo(_("The vehicle is now towed away!", driver))
						StatisticsLogger:getSingleton():vehicleTowLogs(driver, source)
						self:addLog(driver, "Towing logs", ("has towed a vehicle (%s) from %s!"):format(source:getName(), getElementData(source, "OwnerName") or "Unbekannt"))
					else
						if source.Blip then
							source.Blip:delete()
						end
						self:addLog(driver, "Towing logs", ("has towed away a wrecked vehicle (%s)!"):format(source:getName()))
						source:destroy()
						driver:sendInfo(_("You have successfully towed away a wrecked vehicle!", driver))
						self.m_BankAccountServer:transferMoney(driver, 200, "Vehicle wreck", "Company", "Towed")
					end
				else
					driver:sendWarning(_("This vehicle cannot be towed away!", driver))
				end
			end
		end
	end
end

function MechanicTow:Event_mechanicDetachFuelTank(vehicle)
	if client:getCompany() ~= self then
		return
	end
	if not client:isCompanyDuty() then
		client:sendError(_("You are not on duty!", client))
		return
	end

	if vehicle.getCompany and vehicle:getCompany() == self then
		vehicle:detachTrailer()
	end
end

function MechanicTow:Event_mechanicTakeFuelNozzle(vehicle)
	if client:getCompany() ~= self then
		return
	end
	if not client:isCompanyDuty() then
		client:sendError(_("You are not on duty!", client))
		--return
	end

	if vehicle.getCompany and vehicle:getCompany() == self then
		if isElement(client.mechanic_fuelNozzle) then
			toggleControl(client, "fire", true)
			client:setPrivateSync("hasMechanicFuelNozzle", false)
			client:triggerEvent("closeFuelTankGUI")
			client:triggerEvent("forceCloseVehicleFuel")
			client.mechanic_fuelNozzle:destroy()
			return
		end

		if not vehicle.towingVehicle then return end

		client.mechanic_fuelNozzle = createObject(1909, client.position)
		client.mechanic_fuelNozzle:setData("attachedToVehicle", vehicle, true)
		client.mechanic_fuelNozzle.vehicle = vehicle
		exports.bone_attach:attachElementToBone(client.mechanic_fuelNozzle, client, 12, -0.03, 0.02, 0.05, 180, 320, 0)

		client:setPrivateSync("hasMechanicFuelNozzle", vehicle)
		client:triggerEvent("showFuelTankGUI", vehicle, vehicle:getFuel(), vehicle:getFuelTankSize(true))
		toggleControl(client, "fire", false)
	end
end

function MechanicTow:Event_mechanicRejectFuelNozzle()
	if isElement(client.mechanic_fuelNozzle) then
		toggleControl(client, "fire", true)
		client:setPrivateSync("hasMechanicFuelNozzle", false)
		client:triggerEvent("closeFuelTankGUI")
		client:triggerEvent("forceCloseVehicleFuel")
		client.mechanic_fuelNozzle:destroy()
		return
	end
end

function MechanicTow:Event_mechanicVehicleRequestFill(vehicle, fuel)
	if client:getCompany() ~= self then return end
	if not client:isCompanyDuty() then client:sendError(_("You are not on duty!", client)) return end
	if not vehicle then return end
	if not vehicle.controller then return end

	if vehicle.controller.fillRequest then
		client:sendError("The player has already received a request")
		return
	end

	local fuel = vehicle:getFuel() + fuel > 100 and math.floor(100 - vehicle:getFuel()) or math.floor(fuel)
	local price = math.floor(fuel * 1.5)

	if fuel == 0 then
		client:sendError("The vehicle is already fully fueled!")
		return
	end

	local fuelTank = client:getPrivateSync("hasMechanicFuelNozzle")
	local fuelTrailer = vehicle:getModel()
	if (fuelTrailer == 611 and fuel > fuelTank:getFuel()*5) or (fuelTrailer == 584 and fuel > fuelTank:getFuel()*15) then
		client:sendError("There is not enough gasoline in the tank trailer!")
		return
	end

	QuestionBox:new(vehicle.controller,  _("%s would like to refuel your vehicle. %s liters for the price of %s$", vehicle.controller, client:getName(), fuel, price), self.m_FillAccept, self.m_FillDecline, client, 20, client, vehicle.controller, vehicle, fuel, price)
	client:sendInfo("Your service was offered to the player..")
	vehicle.controller.fillRequest = true
end

function MechanicTow:FillAccept(player, target, vehicle, fuel, price)
	target.fillRequest = false

	local fuelTank = player:getPrivateSync("hasMechanicFuelNozzle")
	if fuelTank then
		local fuelTrailerId = fuelTank:getModel()

		if (fuelTrailerId == 611 and fuel > fuelTank:getFuel() * 5) or (fuelTrailerId == 584 and fuel > fuelTank:getFuel() * 15) then
			player:sendError("There is not enough gasoline in the tank trailer!")
			return
		end

		if target:getBankMoney() >= price then
			target:transferBankMoney(self.m_BankAccountServer, price, "Mech&Tow tanken", "Company", "Refill")
			vehicle:setFuel(vehicle:getFuel() + fuel)

			self.m_BankAccountServer:transferMoney({player, true}, math.floor(price*0.3), "Mech&Tow tanken", "Company", "Refill")
			self.m_BankAccountServer:transferMoney(self, math.floor(price*0.7), "Tanken", "Company", "Refill")

			local fuelDiff
			if fuelTrailerId == 611 then
				fuelDiff = fuel / 5
			elseif fuelTrailerId == 584 then
				fuelDiff = fuel / 15
			end

			fuelTank:setFuel(fuelTank:getFuel() - fuelDiff)
			player:triggerEvent("updateFuelTankGUI", math.floor(fuelTank:getFuel()))
		else
			target:sendError(_("You don't have enough money! You need %d$!", target, price))
			player:sendError(_("The player doesn't have enough money!", player))
		end
	else
		player:sendError(_("The tank trailer was no longer recognized, please repeat the refuelling process!", player))
	end
end

function MechanicTow:FillDecline(player, target)
	target.fillRequest = false
	player:sendError(_("The player does not wish to use your service.", player))
end

function MechanicTow:Event_mechanicAttachBike(vehicle)
	if client:getCompany() ~= self then return end
	if not client:isCompanyDuty() then return end
	if not client.vehicle then return end
	if client.vehicle:getData("towingBike") then return end

	if vehicle and vehicle:isEmpty() then
		if self:isValidTowableVehicle(vehicle) then
			vehicle:toggleRespawn(false)
			client.vehicle:setData("towingBike", vehicle, true)
			vehicle:setData("towedByVehicle", client.vehicle, true)

			-- Following is all cause of the animation. Shit happens..
			local object = createObject(1337, vehicle.position, vehicle.rotation)
			local diffRotation = client.vehicle.rotation.z - vehicle.rotation.z
			object:setAlpha(0)
			object:setCollisionsEnabled(false)

			vehicle:setCollisionsEnabled(false)
			vehicle:attach(object)

			client.vehicle:setFrozen(true)
			client.vehicle.m_DisableToggleHandbrake = true

			object:move(2500, client.vehicle.matrix:transformPosition(Vector3(0, -1.1, .8)), 0, 0, diffRotation + 90, "InOutQuad")

			client.vehicle.towTimer = setTimer(
				function(towTruck, bike, object)
					object:destroy()
					towTruck:setFrozen(false)
					towTruck.m_DisableToggleHandbrake = false
					bike:attach(towTruck, 0, -1.1, .8, 0, 0, 90)
					bike.m_HasBeenUsed = 1 --disable despawn on logout
				end, 2500, 1, client.vehicle, vehicle, object
			)
		else
			client:sendWarning(_("This %s cannot be towed!", client, vehicle:getVehicleType() == VehicleType.Bike and "Motorrad" or "Fahrrad"))
		end
	end
end

function MechanicTow:Event_mechanicDetachBike()
	if client:getCompany() ~= self then return end
	if not client:isCompanyDuty() then return end
	if not client.vehicle then return end

	if isTimer(client.vehicle.towTimer) then
		client:sendWarning("Please wait a moment while the vehicle is being fueled!")
		return
	end

	local towingBike = client.vehicle:getData("towingBike")
	if towingBike then
		towingBike:toggleRespawn(true)
		towingBike:detach()
		towingBike:setPosition(client.vehicle.matrix:transformPosition(Vector3(-2, 0, 0)))
		towingBike:setRotation(client.vehicle.rotation)
		towingBike:setCollisionsEnabled(true)

		towingBike:setData("towedByVehicle", nil, true)
		client.vehicle:setData("towingBike", nil, true)
	end
end

function MechanicTow:checkLeviathanTowing(player, vehicle)
	if player.vehicle and vehicle then
		self:onDetachVehicleFromTow(player.vehicle, vehicle)
	end
end

MechanicTow.SpawnPositions = {
	{2434.95, -2130.05, 12.5, 270},
	{2434.95,  -2138.81, 12.5, 270},
	--{833.2, -1198.1, 17.70, 180},
	--{1091.7, -1198.3, 17.70, 180},
	--
}
