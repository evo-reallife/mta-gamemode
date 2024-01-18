DrivingSchool = inherit(Company)
DrivingSchool.LicenseCosts = {["car"] = 4500, ["bike"] = 2000, ["truck"] = 10000, ["heli"] = 50000, ["plane"] = 50000 }
DrivingSchool.TypeNames = {["car"] = "Car driver's license", ["bike"] = "Motorcycle license", ["truck"] = "Truck license", ["heli"] = "Helicopter license", ["plane"] = "Ticket"}
DrivingSchool.m_LessonVehicles = {}
DrivingSchool.testRoute =
{
	--{1355.07, -1621.64, 13.22, 90} .. start
	{1807.23, -1711.17, 13.37},
	{1807.27, -1730.13, 13.39},
	{1651.56, -1729.75, 13.38},
	{1327.79, -1730.02, 13.04},
	{1310.11, -1575.86, 13.04},
	{1349.55, -1399.87, 12.97},
	{1106.99, -1392.60, 13.12},
	{804.73, -1393.98, 13.14},
	{650.62, -1397.89, 13.04},
	{625.97, -1534.58, 14.72},
	{651.80, -1674.67, 14.15},
	{796.70, -1676.98, 13.01},
	{819.15, -1641.51, 13.04},
	{1019.96, -1574.58, 13.04},
	{1048.16, -1516.02, 13.04},
	{1065.41, -1419.91, 13.08},
	{1060.16, -1276.25, 13.40},
	{1060.41, -1161.71, 23.36},
	{1323.85, -1148.96, 23.3},
	{1444.42, -1163.26, 23.31},
	{1451.98, -1285.99, 13.04},
	{1700.87, -1305.06, 13.10},
	{1712.74, -1427.98, 13.04},
	{1468.86, -1438.64, 13.04},
	{1427.40, -1577.95, 13.02},
	{1515.72, -1595.33, 13.03},
	{1527.44, -1718.88, 13.04},
	{1592.89, -1734.80, 13.38},
	{1802.97, -1734.55, 13.39},
	{1761.76, -1687.31, 13.02},
}

addRemoteEvents{"drivingSchoolCallInstructor", "drivingSchoolStartTheory", "drivingSchoolPassTheory", "drivingSchoolStartAutomaticTest", "drivingSchoolHitRouteMarker",	"drivingSchoolStartLessionQuestion", "drivingSchoolEndLession", "drivingSchoolReceiveTurnCommand", "drivingSchoolReduceSTVO"}

function DrivingSchool:constructor()
	InteriorEnterExit:new(Vector3(1778.92, -1721.45, 13.37), Vector3(-2026.93, -103.89, 1035.17), 90, 180, 3, 0, false)
	InteriorEnterExit:new(Vector3(1778.78, -1709.76, 13.37), Vector3(-2029.75, -119.3, 1035.17), 0, 0, 3, 0, false)

	local leftDoor = createObject(3051, -2028.4250, -113.2535, 1035.1999, 0, 0, 284.6610)
	leftDoor:setScale(0.25, 1, 0.75)
	leftDoor:setInterior(3)
	leftDoor:setCollisionsEnabled(false)
	local rightDoor = createObject(3051, -2027.5666, -113.2525, 1035.1999, 0, 0, 284.6610)
	rightDoor:setScale(0.25, 1, 0.75)
	rightDoor:setInterior(3)
	rightDoor:setCollisionsEnabled(false)
	local elevator = Elevator:new()
	elevator:addStation("Roof - Heliports", Vector3(1765.87, -1718.25, 19.88), 180, 0, 0)
	elevator:addStation("Interior", Vector3(-2028.02, -113.8, 1035.17), 176, 3, 0)

	Gate:new(968, Vector3(1810.675, -1716, 13.19), Vector3(0, 90, 180), Vector3(1810.675, -1716, 13.19), Vector3(0, 0, 180), false).onGateHit = bind(self.onBarrierHit, self)
	Gate:new(968, Vector3(1811.2, -1691.275, 13.19), Vector3(0, 90, 90), Vector3(1811.2, -1691.275, 13.19), Vector3(0, 0, 90), false).onGateHit = bind(self.onBarrierHit, self)

    self.m_OnQuit = bind(self.Event_onQuit,self)
	self.m_StartLession = bind(self.startLession, self)
	self.m_DiscardLession = bind(self.discardLession, self)
	self.m_BankAccountServer = BankServer.get("company.driving_school")

    local safe = createObject(2332, -2032.70, -113.70, 1036.20)
    safe:setInterior(3)
	self:setSafe(safe)

	local id = self:getId()
	local blip = Blip:new("DrivingSchool.png", 1778.92, -1721.45, root, 400, {companyColors[id].r, companyColors[id].g, companyColors[id].b})
	blip:setDisplayText(self:getName(), BLIP_CATEGORY.Company)

	self.m_CurrentLessions = {}

	addEventHandler("drivingSchoolCallInstructor", root, bind(DrivingSchool.Event_callInstructor, self))
	addEventHandler("drivingSchoolStartTheory", root, bind(DrivingSchool.Event_startTheory, self))
	addEventHandler("drivingSchoolPassTheory", root, bind(DrivingSchool.Event_passTheory, self))

	addEventHandler("drivingSchoolStartAutomaticTest", root, bind(DrivingSchool.Event_startAutomaticTest, self))
	addEventHandler("drivingSchoolHitRouteMarker", root, bind(DrivingSchool.onHitRouteMarker, self))
	addEventHandler("drivingSchoolStartLessionQuestion", root, bind(DrivingSchool.Event_startLessionQuestion, self))

    addEventHandler("drivingSchoolEndLession", root, bind(DrivingSchool.Event_endLession, self))
    addEventHandler("drivingSchoolReceiveTurnCommand", root, bind(DrivingSchool.Event_receiveTurnCommand, self))
	addEventHandler("drivingSchoolReduceSTVO", root, bind(DrivingSchool.Event_reduceSTVO, self))
end

function DrivingSchool:destructor()
end

function DrivingSchool:onVehicleEnter(vehicle, player, seat)
	if seat == 0 then return end
	if not self.m_CurrentLessions[player] then return end

	if self.m_CurrentLessions[player].vehicle ~= vehicle then
		self.m_CurrentLessions[player].vehicle = vehicle
		self.m_CurrentLessions[player].startMileage = vehicle:getMileage()
		player:setPrivateSync("instructorData", {vehicle = vehicle, startMileage = vehicle:getMileage()})
	end
end

function DrivingSchool:onBarrierHit(player)
	if player.vehicle and player.vehicle.m_IsAutoLesson then
		return true
	end

	if player:getCompany() ~= self then
		return false
	end

	return true
end

function DrivingSchool:Event_callInstructor()
	client:sendInfo(_("The driving school has been contacted. A driving instructor will contact you soon!",client))
	self:sendShortMessage(_("The player %s is looking for a driving instructor! Please contact us!", client, client.name))
end

function DrivingSchool:Event_startTheory(ped)
	if client.m_HasTheory then
		client:sendWarning(_("You have already passed the theory test!", client))
		return
	end

	QuestionBox:new(client, _("Would you like to start the theory test? Cost: 300$", client),
		function(player)
			if not player:transferMoney(self.m_BankAccountServer, 300, "Driving school theory", "Company", "License") then
				player:sendError(_("You don't have enough money with you!", player))
				return
			end

			player:triggerEvent("showDrivingSchoolTest", ped)
		end,
		function() end,
		false, false,
		client
	)
end

function DrivingSchool:Event_passTheory(pass)
	if pass then
		client.m_HasTheory = true
		client:sendInfo(_("You can now take the practical exam!", client))
	else
		client:sendInfo(_("You have dropped out or failed! Try the exam again!", client))
	end
end

function DrivingSchool:Event_startAutomaticTest(type)
	if not client.m_HasTheory then
		client:sendWarning(_("You have not yet passed the theory test!", client))
		return
	end

	if #self:getOnlinePlayers() >= 3 then
		client:sendWarning(_("There are enough driving instructors online!", client))
		return
	end

	local valid = {["car"]= true, ["bike"] = true }
	if not valid[type] then return end

	if type == "car" and client.m_HasDrivingLicense then
		client:sendWarning(_("You already have a driver's license", client))
		return
	end

	if type == "bike" and client.m_HasBikeLicense then
		client:sendWarning(_("You already have a motorcycle license", client))
		return
	end

	QuestionBox:new(client, _("Would you like to start the automatic driving test? Costs: %s$", client, DrivingSchool.LicenseCosts[type]),
		function(player, type)
			if player:getMoney() <  DrivingSchool.LicenseCosts[type] then
				player:sendError(_("You don't have enough money with you!", player))
				return
			end
			player:transferMoney(self.m_BankAccountServer, DrivingSchool.LicenseCosts[type], ("%s-Examination"):format(DrivingSchool.TypeNames[type]), "Company", "License")

			player.m_AutoTestMode = type
			self:startAutomaticTest(player, type)
		end,
		function() end,
		false, false,
		client, type
	)
end

function DrivingSchool:checkPlayerLicense(player, type)
	if type == "car" then
		return player.m_HasDrivingLicense
	elseif type == "bike" then
		return player.m_HasBikeLicense
	elseif type == "truck" then
		return player.m_HasTruckLicense
	elseif type == "heli" then
		return player.m_HasPilotsLicense
	elseif type == "plane" then
		return player.m_HasPilotsLicense
	end
end

function DrivingSchool:setPlayerLicense(player, type, bool)
	if type == "car" then
		player.m_HasDrivingLicense = bool
	elseif type == "bike" then
		player.m_HasBikeLicense = bool
	elseif type == "truck" then
		player.m_HasTruckLicense = bool
	elseif type == "heli" then
		player.m_HasPilotsLicense = bool
	elseif type == "plane" then
		player.m_HasPilotsLicense = bool
	end
end

function DrivingSchool:getLessionFromStudent(player)
	for index, key in pairs(self.m_CurrentLessions) do
		if key["target"] == player then return key end
	end
	return false
end

function DrivingSchool:startAutomaticTest(player, type)
	if DrivingSchool.m_LessonVehicles[player] then
		player:triggerEvent("DrivingLesson:endLesson")
		if DrivingSchool.m_LessonVehicles[player].m_NPC then
			if isElement(DrivingSchool.m_LessonVehicles[player].m_NPC ) then
				destroyElement(DrivingSchool.m_LessonVehicles[player].m_NPC)
			end
		end
		destroyElement(DrivingSchool.m_LessonVehicles[player])
	end

	local veh  = TemporaryVehicle.create(type == "car" and 410 or 586, 1761.76, -1687.31, 13.02, 180)
	veh:setColor(255, 255, 255)
	veh.m_Driver = player
	veh.m_CurrentNode = 1
	veh.m_IsAutoLesson = true
	veh.m_TestMode = type

	player:setPosition(Vector3(1766.50, -1687.10, 13.37))
	player:setRotation(0, 0, 90)
	player:setInterior(0)
	player:setCameraTarget(player)

	local randomName =	{"Nero Soliven", "Kempes Waldemar", "Avram Vachnadze", "Klaus Schweiger", "Luca Pasqualini", "Peter Schmidt", "Mohammed Vegas", "Isaha Rosenberg"}
	local name = randomName[math.random(1, #randomName)]
	veh.m_NPC = createPed(295, 1765.50, -1687.10, 15.37)
	veh.m_NPC:setData("NPC:Immortal", true, true)
	veh.m_NPC:setData("isBuckeled", true, true)
	veh.m_NPC:setData("Ped:fakeNameTag", name, true)
	veh.m_NPC:setData("isDrivingCoach", true)
	veh.m_NPC:warpIntoVehicle(veh, 1)

	player:sendInfo("Get in the vehicle in front of you.")

	addEventHandler("onVehicleStartEnter", veh,
    function(player, seat)
        if source.m_Driver == player then
            if seat == 0 then
                outputChatBox(_("Drive the designated route and make sure your vehicle is not damaged!", player), player, 200, 200, 0)
                outputChatBox(_("%s says: Turn on the engine with 'X'.", player, name), player, 200, 200, 200)

                setTimer(outputChatBox, 2000, 1, _("%s says: Then turn on the lights with 'L'.", player, name), player, 200, 200, 200)
                setTimer(outputChatBox, 8000, 1, _("%s says: And off you go! Don't forget to activate the limiter with the 'K' key.", player, name), player, 200, 200, 200)
                setTimer(outputChatBox, 12000, 1, _("%s says: Open the barrier with #C8C800'H'#C8C8C8. Please close it later.", player, name), player, 200, 200, 200, true)

                if player.m_AutoTestMode == "car" then
                    setTimer(outputChatBox, 4000, 1, _("%s says: Now buckle up with 'M'", player, name), player, 200, 200, 200)
                else
                    setTimer(outputChatBox, 4000, 1, _("%s says: Put on your helmet.", player, name), player, 200, 200, 200)
                end
            end
        else
            cancelEvent()
        end
    end)


	addEventHandler("onVehicleExit", veh,
		function(player, seat)
			if seat ~= 0 then return end
			if not source.m_IsFinished then
				outputChatBox(_("You have left the vehicle and completed the test!", player), player, 200,0,0)
			end
			if DrivingSchool.m_LessonVehicles[player] == source then
				DrivingSchool.m_LessonVehicles[player] = nil
				if source.m_NPC then
					destroyElement(source.m_NPC)
				end
				destroyElement(source)
			end
			player:triggerEvent("DrivingLesson:endLesson")
			fadeCamera(player,false,0.5)
			setTimer(setElementPosition,1000,1,player,1759.05, -1690.22, 13.37)
			setTimer(fadeCamera,1500,1, player,true,0.5)
		end
	)

	addEventHandler("onVehicleExplode",veh,
		function()
			local player = getVehicleOccupant(source)
			if DrivingSchool.m_LessonVehicles[player] == source then
			local alreadyFinished = source.m_IsFinished
				DrivingSchool.m_LessonVehicles[player] = nil
				if source.m_NPC then
					destroyElement(source.m_NPC)
				end
				destroyElement(source)
			end
			player:triggerEvent("DrivingLesson:endLesson")
			fadeCamera(player,false,0.5)
			setTimer(setElementPosition,1000,1,player,1759.05, -1690.22, 13.37)
			setTimer(fadeCamera,1500,1, player,true,0.5)
			if not alreadyFinished then
				outputChatBox(_("Du hast das Fahrzeug zerstört!", player), player, 200,0,0)
			end
		end
	)

	addEventHandler("onElementDestroy", veh,
		function()
			local player = getVehicleOccupant(source)
			if player then
				if DrivingSchool.m_LessonVehicles[player] == source then
					DrivingSchool.m_LessonVehicles[player] = nil
					if not source.m_IsFinished then
						outputChatBox(_("You have left the vehicle and completed the test!", player), player, 200,0,0)
					end
					if source.m_NPC then
						if isElement(source.m_NPC) then
							destroyElement(source.m_NPC)
						end
					end
				end
				player:triggerEvent("DrivingLesson:endLesson")
				fadeCamera(player,false,0.5)
				setTimer(setElementPosition,1000,1,player,1759.05, -1690.22, 13.37)
				setTimer(fadeCamera,1500,1, player,true,0.5)
			end
		end, false
	)

	player:triggerEvent("DrivingLesson:setMarker", DrivingSchool.testRoute[veh.m_CurrentNode], veh)
	DrivingSchool.m_LessonVehicles[player] = veh
end

function DrivingSchool:onHitRouteMarker()
	if DrivingSchool.m_LessonVehicles[client] then
		local veh = DrivingSchool.m_LessonVehicles[client]
		veh.m_CurrentNode = veh.m_CurrentNode + 1
		if veh.m_CurrentNode <= #DrivingSchool.testRoute then
			client:triggerEvent("DrivingLesson:setMarker",DrivingSchool.testRoute[veh.m_CurrentNode], veh)
		else
			veh.m_IsFinished = true
			if getElementHealth(veh) >= 500 then
				if veh.m_TestMode == "car" then
					client.m_HasDrivingLicense = true
				else
					client.m_HasBikeLicense = true
				end
				outputChatBox(_("You have passed the test and your vehicle is in a satisfactory condition!", client), client, 0, 200, 0)
				if veh.m_NPC then
					destroyElement(veh.m_NPC)
				end
				destroyElement(veh)
				DrivingSchool.m_LessonVehicles[client] = nil
				client:triggerEvent("DrivingLesson:endLesson")
			else
				client.m_HasDrivingLicense = false
				outputChatBox(_("Since your vehicle was too damaged, you did not pass!", client), client, 200, 0, 0)
				if veh.m_NPC then
					destroyElement(veh.m_NPC)
				end
				destroyElement(veh)
				DrivingSchool.m_LessonVehicles[client] = nil
				client:triggerEvent("DrivingLesson:endLesson")
			end
		end
	end
end

function DrivingSchool:Event_startLessionQuestion(target, type)
    local costs = DrivingSchool.LicenseCosts[type]
    if costs and target then
        if not self:checkPlayerLicense(target, type) then
            if target.m_HasTheory then
                if target:getMoney() >= costs then
                    if not target:getPublicSync("inDrivingLesson") then
                        if not self.m_CurrentLessions[client] then
                            QuestionBox:new(target, _("The driving instructor %s wants to start the %s test with you!\nThis costs %d$. Do you want to start the test?", target, client.name, DrivingSchool.TypeNames[type], costs), self.m_StartLession, self.m_DiscardLession, client, 10, client, target, type)
                        else
                            client:sendError(_("You are already in a driving test!", client))
                        end
                    else
                        client:sendError(_("Player %s is already in a test!", client, target.name))
                    end
                else
                    client:sendError(_("Player %s does not have enough money! (%d$)", client, target.name, costs))
                end
            else
                client:sendError(_("Player %s must pass the theoretical driving test first!", client, target.name))
            end
        else
            client:sendError(_("Player %s already has the %s!", client, target.name, DrivingSchool.TypeNames[type]))
        end
    else
        client:sendError(_("Internal error: Incorrect arguments @DrivingSchool:Event_startLessonQuestion!", client))
    end
end

function DrivingSchool:discardLession(instructor, target, type)
    instructor:sendError(_("Player %s has declined the %s test!", instructor, target.name, DrivingSchool.TypeNames[type]))
    target:sendError(_("You have declined the %s test with %s!", DrivingSchool.TypeNames[type], instructor.name))
end


function DrivingSchool:startLession(instructor, target, type)
    local costs = DrivingSchool.LicenseCosts[type]
    if costs and target then
        if self:checkPlayerLicense(target, type) == false then
            if target:getMoney() >= costs then
                if not target:getPublicSync("inDrivingLession") == true then
                    if not self.m_CurrentLessions[instructor] then
                        self.m_CurrentLessions[instructor] = {
                            ["target"] = target,
                            ["type"] = type,
                            ["instructor"] = instructor,
                            ["vehicle"] = false,
                            ["startMileage"] = false,
                        }

                        target:transferMoney(self.m_BankAccountServer, costs, ("%s-Prüfung"):format(DrivingSchool.TypeNames[type]), "Company", "License")
                        self.m_BankAccountServer:transferMoney({self, nil, true}, costs * 0.85, ("%s-Prüfung"):format(DrivingSchool.TypeNames[type]), "Company", "License")
                        self.m_BankAccountServer:transferMoney(instructor, costs * 0.15, ("%s-Prüfung"):format(DrivingSchool.TypeNames[type]), "Company", "License")

                        target:setPublicSync("inDrivingLession", true)
                        instructor:sendInfo(_("You have started the %s test with %s!", instructor, DrivingSchool.TypeNames[type], target.name))
                        target:sendInfo(_("Driving instructor %s has started the %s test with you, follow his instructions!", target, instructor.name, DrivingSchool.TypeNames[type]))
                        target:triggerEvent("showDrivingSchoolStudentGUI", DrivingSchool.TypeNames[type])
                        instructor:triggerEvent("showDrivingSchoolInstructorGUI", DrivingSchool.TypeNames[type], target)
                        self:addLog(instructor, "Driving School", ("has started a %s test with %s!"):format(DrivingSchool.TypeNames[type], target:getName()))
                        addEventHandler("onPlayerQuit", instructor, self.m_OnQuit)
                        addEventHandler("onPlayerQuit", target, self.m_OnQuit)
                    else
                        instructor:sendError(_("You are already in a driving test!", instructor))
                    end
                else
                    instructor:sendError(_("Player %s is already in a test!", instructor, target.name))
                    target:sendError(_("You are already in a test!", target))
                end
            else
                instructor:sendError(_("Player %s does not have enough money! (%d$)", instructor, target.name, costs))
                target:sendError(_("You do not have enough money! (%d$)", target, costs))
            end
        else
            instructor:sendError(_("Player %s already has the %s!", instructor, target.name, DrivingSchool.TypeNames[type]))
            target:sendError(_("You already have the %s!", target, DrivingSchool.TypeNames[type]))
        end
    else
        instructor:sendError(_("Internal error: Incorrect arguments @DrivingSchool:Event_startLesson!", instructor))
    end
end


function DrivingSchool:Event_onQuit()
    if self.m_CurrentLessions[source] then
        local lession = self.m_CurrentLessions[source]
		self:Event_endLession(lession["target"], false, source)
        lession["target"]:sendError(_("The driving instructor %s has gone offline!",lession["target"], source.name))
    elseif self:getLessionFromStudent(source) then
        local lession = self:getLessionFromStudent(source)
        self:Event_endLession(source, false, lession["instructor"])
        lession["instructor"]:sendError(_("The learner driver %s has gone offline!",lession["instructor"], source.name))
    end
end

function DrivingSchool:Event_endLession(target, success, clientServer)
    if not client and clientServer then client = clientServer end
    local type = self.m_CurrentLessions[client]["type"]
    if success == true then
		local vehicle = self.m_CurrentLessions[client].vehicle
		if not vehicle then return end

		local startMileage = self.m_CurrentLessions[client].startMileage
		local mileageDiff = math.round((vehicle:getMileage()-startMileage)/1000, 1)

		if mileageDiff < 2 then
			client:sendWarning("You must drive at least 2km with the learner driver!")
			return
		end
		self:setPlayerLicense(target, type, true)
		target:sendInfo(_("You have successfully passed the %s test and obtained the license!", target, DrivingSchool.TypeNames[type]))
		client:sendInfo(_("You have successfully completed the %s test with %s!", client, DrivingSchool.TypeNames[type], target.name))
		self:addLog(client, "Driving School", ("has successfully completed the %s test with %s (%s km)!"):format(DrivingSchool.TypeNames[type], target:getName(), mileageDiff))		
	else
        target:sendError(_("You did not pass the %s test! Good luck next time!", target, DrivingSchool.TypeNames[type]))
		client:sendInfo(_("You have canceled the %s test with %s!", client, DrivingSchool.TypeNames[type], target.name))
		self:addLog(client, "Driving School", ("has canceled the %s test with %s!"):format(DrivingSchool.TypeNames[type], target:getName()))
    end

	target:removeFromVehicle()
    target:triggerEvent("hideDrivingSchoolStudentGUI")
    client:triggerEvent("hideDrivingSchoolInstructorGUI")
    removeEventHandler("onPlayerQuit", client, self.m_OnQuit)
    removeEventHandler("onPlayerQuit", target, self.m_OnQuit)
    target:setPublicSync("inDrivingLession", false)
    self.m_CurrentLessions[client] = nil
end

function DrivingSchool:Event_receiveTurnCommand(turnCommand, arg)
    local target = self.m_CurrentLessions[client]["target"]
    if target then
        target:triggerEvent("drivingSchoolChangeDirection", turnCommand, arg)
    end
end

function DrivingSchool:Event_reduceSTVO(category, amount)
	if tonumber(client:getSTVO(category)) < tonumber(amount) then
		client:sendError(_("You don't have that many RTR-Points!", client))
		return false
	end

	local stvoPricing = 250 * amount

	if not client:transferMoney(self.m_BankAccountServer, stvoPricing, "Reduce RTR-Points", "Driving School", "ReduceSTVO") then
		client:sendError(_("You don't have enough money! ("..tostring(stvoPricing).."$)", client))
		return false
	end

	client:setSTVO(category, client:getSTVO(category) - amount)
	self.m_BankAccountServer:transferMoney({self, nil, true}, stvoPricing*0.85, "RTR-Points abbauen", "Driving School", "ReduceSTVO")
	triggerClientEvent(client, "hideDrivingSchoolReduceSTVO", resourceRoot)
end
