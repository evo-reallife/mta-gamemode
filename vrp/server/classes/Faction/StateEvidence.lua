-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/StateEvidence.lua
-- *  PURPOSE:     state evidence storage
-- *
-- ****************************************************************************

StateEvidence = inherit(Singleton)
addRemoteEvents{"State:startEvidenceTruck"}

--[[
    Id
    Type
    Object
    Amount
    UserId
    Date
]]

function StateEvidence:constructor()
    addEventHandler("State:startEvidenceTruck", root, bind(self.Event_startEvidenceTruck,self))
	
	self.m_Pickups = {}
	self:createEvidencePickup(233.47, 111.40, 1002.8, 10, 0)
	self:createEvidencePickup(1579.43, -1691.53, 5.92, 0, 5)
	self:loadObjectData()
end

function StateEvidence:loadObjectData()
	self.m_EvidenceRoomItems = sql:queryFetch("SELECT * FROM ??_state_evidence", sql:getPrefix()) or {}
	self.m_FillState = 0
	for i, v in pairs(self.m_EvidenceRoomItems) do
		self.m_EvidenceRoomItems[i].UserName = Account.getNameFromId(v.UserId) or "Unknown"
		self.m_FillState = self.m_FillState + self:getObjectPrice(v.Type, v.Object, v.Amount)
	end
end


function StateEvidence:createEvidencePickup( x,y,z, int, dim )
	local pickup = createPickup(x,y,z,3, 2061, 10)
	setElementInterior(pickup, int)
	setElementDimension(pickup, dim)
	addEventHandler("onPickupUse", pickup, function( hitElement )
		local dim = source:getDimension() == hitElement:getDimension()
		if hitElement:getType() == "player" and dim then
			if hitElement:getFaction() and hitElement:getFaction():isStateFaction() and hitElement:isFactionDuty() then
				hitElement.evidencePickup = source
				self:showEvidenceStorage( hitElement, source )
			else
				hitElement:sendError(_("Only for state factionists on duty!", hitElement))
			end
		end
	end)
	ElementInfo:new(pickup, "Asservatenkammer", 1 )
	table.insert(self.m_Pickups, pickup)
end

function StateEvidence:getEvidencePickups()
	return self.m_Pickups
end

function StateEvidence:getObjectPrice(type, object, amount)
	if type == "Item" then return STATE_EVIDENCE_OBJECT_PRICE.Item * amount end
	if type == "Waffe" then return STATE_EVIDENCE_OBJECT_PRICE.Waffe * amount * (factionWeaponDepotInfo[tonumber(object)] and factionWeaponDepotInfo[tonumber(object)].WaffenPreis or 0) end
	if type == "Munition" then return STATE_EVIDENCE_OBJECT_PRICE.Munition * (amount / (getWeaponProperty(tonumber(object), "pro", "maximum_clip_ammo") and getWeaponProperty(tonumber(object), "pro", "maximum_clip_ammo") > 0 and getWeaponProperty(tonumber(object), "pro", "maximum_clip_ammo") or 1)) * (factionWeaponDepotInfo[tonumber(object)] and factionWeaponDepotInfo[tonumber(object)].MagazinPreis or 0) end
end

--base function (do not call directly)
function StateEvidence:insertNewObject(type, object, amount, userid)
	local timeStamp = getRealTime().timestamp
    if self.m_EvidenceRoomItems then
		if self.m_FillState < STATE_EVIDENCE_MAX_OBJECTS  then
            sql:queryExec("INSERT INTO ??_state_evidence (Type, Object, Amount, UserId, Timestamp) VALUES(?, ?, ?, ?, ?)",
            sql:getPrefix(), type, object, amount, userid, timeStamp)
			table.insert(self.m_EvidenceRoomItems, {
				Type = type, 
				Object = object, 
				Amount = amount, 
				UserId = userid,
				Date = timeStamp, 
				UserName = Account.getNameFromId(userid),
				Id = sql:lastInsertId()
			})
			self.m_FillState = self.m_FillState + self:getObjectPrice(type, object, amount)
            return true
        else
            FactionState:getSingleton():sendShortMessage("The evidence room is full, the weapon could no longer be stored!")
        end
    end
end

--multiple weapons
function StateEvidence:addWeaponsToEvidence(player, weaponId, weaponCount, noMessage)	
	if tonumber(weaponId) and tonumber(weaponId) then
		if self:insertNewObject("Waffe", weaponId, weaponCount, player and player:getId() or 0) then
			player:getFaction():addLog(player, "Asservate", ("hat %s %s konfisziert!"):format(weaponCount, WEAPON_NAMES[weaponId or 0]))
        	if not noMessage then player:sendShortMessage(("Du hast %s %s konfisziert."):format(weaponCount, WEAPON_NAMES[weaponId or 0])) end
			return true
		end
    end
end

--ammo without weapon
function StateEvidence:addMunitionToEvidence(player, weaponId, ammo, noMessage)	
	if tonumber(weaponId) and tonumber(weaponId) then
		if getWeaponProperty(tonumber(weaponId), "pro", "maximum_clip_ammo") then
			if tonumber(ammo) / getWeaponProperty(tonumber(weaponId), "pro", "maximum_clip_ammo") > STATE_EVIDENCE_MAX_CLIPS then
				ammo = getWeaponProperty(tonumber(weaponId), "pro", "maximum_clip_ammo") * STATE_EVIDENCE_MAX_CLIPS
			end
		end
		if self:insertNewObject("Munition", weaponId, ammo, player and player:getId() or 0) then
			player:getFaction():addLog(player, "Evidence", ("confiscated %s %s ammunition!"):format(ammo, WEAPON_NAMES[weaponId or 0]))
        	if not noMessage then player:sendShortMessage(("You have confiscated %s %s shot."):format(ammo, WEAPON_NAMES[weaponId or 0])) end
			return true
		end
    end
end

--one weapon with ammo (utility function, e.g. frisking)
function StateEvidence:addWeaponWithMunitionToEvidence(player, weaponId, ammo, noMessage)	
    if self:addWeaponsToEvidence(player, weaponId, 1, true) and self:addMunitionToEvidence(player, weaponId, ammo, true) then
		if not noMessage then player:sendShortMessage(("You have confiscated a %s with a %s shot."):format(WEAPON_NAMES[weaponId or 0], ammo)) end
		return true
    end
end

--one item with optional stack size
function StateEvidence:addItemToEvidence(player, itemName, amount, noMessage)
	if self:insertNewObject("Item", itemName, amount, player and player:getId() or 0) then
		player:getFaction():addLog(player, "Evidence", ("confiscated %s %s!"):format(amount, itemName))
		if not noMessage then player:sendShortMessage(("You've confiscated %s %s."):format(amount, itemName)) end
		return true
    end
end

function StateEvidence:showEvidenceStorage(player, storageElement)
	if player then
		if player:isFactionDuty() and player:getFaction() and player:getFaction():isStateFaction() then
			player:triggerEvent("State:sendEvidenceItems", self.m_EvidenceRoomItems, self.m_FillState, storageElement)
		end
	end
end

function StateEvidence:Event_startEvidenceTruck()
	if client:isFactionDuty() and client:getFaction() and client:getFaction():isStateFaction() then
		if PermissionsManager:getSingleton():isPlayerAllowedToStart(client, "faction", "StateEvidenceTruck") then
			if ActionsCheck:getSingleton():isActionAllowed(client) then
				if FactionEvil:getSingleton():countPlayers() >= EVIDENCETRUCK_MIN_MEMBERS then
					local evObj
					local totalMoney = 0
					local objToDelete = {}
					for i = 1, #self.m_EvidenceRoomItems do
						evObj = self.m_EvidenceRoomItems[i]
						local price = self:getObjectPrice(evObj.Type, evObj.Object, evObj.Amount)

						if(totalMoney + price <= EVIDENCETRUCK_MAX_LOAD) then
							totalMoney = totalMoney + price
							table.insert(objToDelete, evObj.Id)
						end
					end
					if totalMoney > 0 then
						ActionsCheck:getSingleton():setAction("MoneyTransport")
						FactionState:getSingleton():sendMoveRequest(TSConnect.Channel.STATE)
						StateEvidenceTruck:new(client, totalMoney)
						PlayerManager:getSingleton():breakingNews("A money transporter is on the way! Please stay away from the transport!")
						Discord:getSingleton():outputBreakingNews("A money transporter is on the way! Please stay away from the transport!")
						FactionState:getSingleton():sendShortMessage(client:getName().." has started a money transport!",10000)
						StatisticsLogger:getSingleton():addActionLog("Money-Transport", "start", client, client:getFaction(), "faction")
						sql:queryFetchSingle(function()
							self:loadObjectData()
						end, "DELETE FROM ??_state_evidence WHERE Id IN (??)",sql:getPrefix(), table.concat(objToDelete, ","))

					else
						client:sendError(_("There is not enough material in the evidence room!", client))
					end
				else
					client:sendError(_("There must be at least 3 players from evil factions online!", client))
				end
			end
		else
			client:sendError(_("You are not authorized to start a money truck!", client))
		end
	end
end
