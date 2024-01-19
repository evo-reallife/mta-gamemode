-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Actions/ExplosiveTruck/ExplosiveTruckManager.lua
-- *  PURPOSE:     C4 Truck Manager Class
-- *
-- ****************************************************************************

addRemoteEvents{"ExplosiveTruckManager:start"}

ExplosiveTruckManager = inherit(Singleton)
ExplosiveTruckManager.Active = {}

function ExplosiveTruckManager:constructor()
	addEventHandler("ExplosiveTruckManager:start", root, bind(self.start, self))
end

function ExplosiveTruckManager:destructor()
	removeEventHandler("ExplosiveTruckManager:start", root, self.start)
end

function ExplosiveTruckManager:start()
	local faction = client:getFaction()

	if not faction or not faction:isEvilFaction() then
		client:sendError(_("You're not in an evil faction!", client))

		return
	end

	local factionId = faction:getId()

	if ExplosiveTruckManager.Active[factionId] then
		client:sendError(_("A Transport of your faction is already underway!", client))

		return
	end

	if faction:getMoney() < ExplosiveTruck.Price then
		client:sendError(_("Your Faction doesn't have enough money!", client))

		return
	end

	if not PermissionsManager:getSingleton():isPlayerAllowedToStart(client, "faction", "ExplosiveTruck") then
		client:sendError(_("You are not authorised to buy explosives!", client))
		return
	end

	ExplosiveTruckManager.Active[factionId] = ExplosiveTruck:new(faction, client)
end
