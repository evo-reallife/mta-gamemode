-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Actions/MWeedTruck.lua
-- *  PURPOSE:     Weed Truck Manager Class
-- *
-- ****************************************************************************

MWeedTruck = inherit(Singleton)
MWeedTruck.Settings = {["costs"] = 10000}

function MWeedTruck:constructor()
	self:createStartPoint(-1095.50, -1614.75, 75.5)
	self.m_BankAccount = BankServer.get("action.trucks")
	createObject(3041, -1120.21, -1621.1, 75.3, 0, 0, 90) -- table for the drugs

	self.m_HelpColShape = createColSphere(-1095.50, -1614.75, 75.5, 5)
	addEventHandler("onColShapeHit", self.m_HelpColShape, bind(self.onHelpColHit, self))
	addEventHandler("onColShapeLeave", self.m_HelpColShape, bind(self.onHelpColHit, self))

	addRemoteEvents{"weedTruckStart"}
	addEventHandler("weedTruckStart", root, bind(self.Event_weedTruckStart, self))
end

function MWeedTruck:destructor()
end

function MWeedTruck:createStartPoint(x, y, z, type)
	--self.m_Blip = Blip:new("Waypoint.png", x, y, self.m_Driver)
	local marker = createMarker(x, y, z, "cylinder",1)
	addEventHandler("onMarkerHit", marker, bind(self.onStartPointHit, self))
end

function MWeedTruck:onHelpColHit(hitElement, matchingDimension)
	if hitElement:getType() == "player" and matchingDimension then
		hitElement:triggerEvent("setHelpBarLexiconPage", LexiconPages.ActionWeedTruck)
	end
end

function MWeedTruck:onHelpColLeave(hitElement, matchingDimension)
	if hitElement:getType() == "player" and matchingDimension then
		hitElement:triggerEvent("resetHelpBar")
	end
end

function MWeedTruck:onStartPointHit(hitElement, matchingDimension)
	if hitElement:getType() == "player" and matchingDimension then
		local faction = hitElement:getFaction()
		if faction then
			if faction:isEvilFaction() and hitElement:isFactionDuty() then
				if PermissionsManager:getSingleton():isPlayerAllowedToStart(hitElement, "faction", "WeedTruck") then
					if ActionsCheck:getSingleton():isActionAllowed(hitElement) then
						-- "AviRex" when the police is less then 2 members or following by WEEDTRUCK_MIN_MEMBERS so the evil faction can't make a weed truck action
						if FactionState:getSingleton():countPlayers() < WEEDTRUCK_MIN_MEMBERS then
							hitElement:sendError(_("There must be at least %d state factionists online!",hitElement, WEEDTRUCK_MIN_MEMBERS))
							return false
						end
						QuestionBox:new(hitElement, _("Would you like to start a weed truck? Costs: %s", hitElement, toMoneyString(MWeedTruck.Settings["costs"])), "weedTruckStart", false, source, 10)
					end
				else
					hitElement:sendError(_("You are not authorised to start a weed truck!",hitElement))
				end

			else
				hitElement:sendError(_("Only members of evil factions can start the weed truck!",hitElement))
			end
		else
			hitElement:sendError(_("Only faction members can start the weed truck!",hitElement))
		end
	end
end

function MWeedTruck:Event_weedTruckStart()
	local faction = source:getFaction()
	if faction then
		if faction:isEvilFaction() then
			if ActionsCheck:getSingleton():isActionAllowed(source) then
				if PermissionsManager:getSingleton():isPlayerAllowedToStart(source, "faction", "WeedTruck") then
					if faction:getMoney() >= MWeedTruck.Settings["costs"] then
						faction:transferMoney(self.m_BankAccount, MWeedTruck.Settings["costs"], "Weed-Truck", "Action", "WeedTruck")
						self.m_CurrentWeedTruck = WeedTruck:new(source)
						ActionsCheck:getSingleton():setAction("Weed-Truck")
						FactionState:getSingleton():sendMoveRequest(TSConnect.Channel.STATE)
						StatisticsLogger:getSingleton():addActionLog("Weed-Truck", "start", source, faction, "faction")
					else
						source:sendError(_("You don't have enough money in the faction vault! (%s)", source, toMoneyString(MWeedTruck.Settings["costs"])))
					end
				else
					source:sendError(_("You aren't authorised to start a weed truck!", source))
				end
			end
		end
	end
end
