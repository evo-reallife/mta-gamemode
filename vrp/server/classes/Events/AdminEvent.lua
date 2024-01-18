AdminEvent = inherit(Object)

function AdminEvent:constructor()
	self.m_Players = {}
    self.m_Vehicles = {}
    self.m_AuctionsPerEvent = {}
    self.m_VehiclesAmount = 0
    --[[self.m_WastedBind = bind(self.Event_WastedHandler, self)
    addEventHandler("onPlayerWasted", root, self.m_WastedBind)]]
end

function AdminEvent:destructor()
    for i, player in pairs(self.m_Players) do
        self:leaveEvent(player, true)
    end
    self.m_Players = {}
    self:deleteEventVehicles()
end

function AdminEvent:setTeleportPoint(eventManager)
	self.m_TeleportPoint = {eventManager:getPosition(), eventManager:getInterior(), eventManager:getDimension()}
	eventManager:sendInfo(_("You have set the event teleport point to your position!", eventManager))
end

function AdminEvent:sendGUIData(player)
	player:triggerEvent("adminEventReceiveData", true, self.m_Players, self.m_Vehicles, self.m_CurrentAuction)
end

function AdminEvent:joinEvent(player)
    if self:isPlayerInEvent(player) then player:sendError(_("You are already participating in the admin event! Please wait for further instructions!", player)) return end
	table.insert(self.m_Players, player)
    player:sendInfo(_("You are taking part in the admin event! Please wait for further instructions!", player))
    player:triggerEvent("adminEventPrepareClient")
    if self.m_CurrentAuction then
        triggerClientEvent(player, "adminEventSendAuctionData", resourceRoot, self.m_CurrentAuction)
    end
end

function AdminEvent:leaveEvent(player, dontModifyTable)
    if not dontModifyTable then table.removevalue(self.m_Players, player) end -- hack-fix if we remove every player in the table
    if isElement(player) then
        player:sendInfo(_("You no longer take part in the admin event!", player))
        player:triggerEvent("adminEventRemoveClient")
    end
end

function AdminEvent:isPlayerInEvent(player)
    return table.find(self.m_Players, player)
end

function AdminEvent:teleportPlayers(eventManager)
	if not self.m_TeleportPoint then
		eventManager:sendError(_("You have not set an event teleport point!", eventManager))
	end

	local pos, int, dim = unpack(self.m_TeleportPoint)
	local count = 0

	for index, player in pairs(self.m_Players) do
        if player.vehicle then removePedFromVehicle(player)	end
        player:setDimension(dim)
        player:setInterior(int)
        player:setPosition(pos.x + math.random(1,3), pos.y + math.random(1,3), pos.z)
        count = count + 1
	end
	eventManager:sendInfo(_("There have been %d players teleported!", eventManager, count))
end

function AdminEvent:createVehiclesInRow(player, amount, direction)
    local allowedDirections = {"V", "H", "L", "R"}

    if not table.find(allowedDirections, direction) then
        player:sendError(_("Invalid direction! Allowed are %s", player, table.concat(allowedDirections, ", ")))
        return
    end

    if not amount or not tonumber(amount) or tonumber(amount) > 20 then
        player:sendError(_("You can place a maximum of 20 vehicles!", player))
        return
    end

    if not player.vehicle then
        player:sendError(_("You have to be in a vehicle!", player))
        return
    end

    local veh
    local model = player.vehicle:getModel()
    local pos = player.vehicle:getPosition()
    local rot = player.vehicle:getRotation()
    local matrix = player.vehicle:getMatrix()
    amount = tonumber(amount)

    for i=0, amount do
            if direction == "V" then pos = pos + matrix.forward*7
        elseif direction == "H" then pos = pos - matrix.forward*7
        elseif direction == "R" then pos = pos + matrix.right*4
        elseif direction == "L" then pos = pos - matrix.right*4
        end

        veh = TemporaryVehicle.create(model, pos, rot)
        veh:setFrozen(true)
        veh.m_DisableToggleHandbrake = true
        self.m_Vehicles[self.m_VehiclesAmount] = veh
        self.m_VehiclesAmount = self.m_VehiclesAmount + 1
    end
end

function AdminEvent:freezeEventVehicles(player)
    local count = 0
    for index, veh in pairs(self.m_Vehicles) do
        if veh and isElement(veh) then
            veh:setFrozen(true)
            count = count+1
        else
            self.m_Vehicles[index] = nil
        end
    end
    player:sendInfo(_("You've freed up %d event vehicles!", player, count))
end

function AdminEvent:unfreezeEventVehicles(player)
    local count = 0
    for index, veh in pairs(self.m_Vehicles) do
        if veh and isElement(veh) then
            veh:setFrozen(false)
            count = count+1
        else
            self.m_Vehicles[index] = nil
        end
    end
    player:sendInfo(_("You have removed %d event vehicles!", player, count))
end

function AdminEvent:deleteEventVehicles(player)
    local count = 0
    for index, veh in pairs(self.m_Vehicles) do
        if veh and isElement(veh) then
            veh:destroy()
            count = count+1
        end
    end
	self.m_Vehicles = {}
	self.m_VehiclesAmount = 0
    if player and isElement(player) then player:sendInfo(_("You have deleted %d event vehicles!", player, count)) end
end

function AdminEvent:startAuction(player, name)
    if not self.m_CurrentAuction then
        self.m_CurrentAuction = {
            name = name,
            bids = {},
        }
        triggerClientEvent(self.m_Players, "adminEventSendAuctionData", resourceRoot, self.m_CurrentAuction)
        triggerClientEvent(self.m_Players, "infoBox", resourceRoot, "A new round of auctions has been started.")
        Admin:getSingleton():sendShortMessage(_("%s has started a round of auctions for %s!", player, player:getName(), name))
    else
        player:sendError(_("An auction is already taking place!", player))
    end
end

function AdminEvent:registerBid(player, bid)
    if self.m_CurrentAuction then
        if not self.m_CurrentAuction.bids[1] or bid > self.m_CurrentAuction.bids[1][2] then
            QuestionBox:new(player, ("Attention binding! Do you really want to bid %s on %s? (There will be administrative penalties if you cannot pay after the auction)"):format(toMoneyString(bid), self.m_CurrentAuction.name), function(player, bid)
                if self.m_CurrentAuction then
                    if not self.m_CurrentAuction.bids[1] or bid > self.m_CurrentAuction.bids[1][2] then
                        local updated = false
                        for i,v in ipairs(self.m_CurrentAuction.bids) do
                            if v[1] == player:getName() then
                                self.m_CurrentAuction.bids[i] = {player:getName(), bid}
                                updated = true
                                break;
                            end
                        end
                        if not updated then
                            table.insert(self.m_CurrentAuction.bids, {player:getName(), bid})
                        end
                
                        table.sort(self.m_CurrentAuction.bids, function(a,b)
                            return a[2] > b[2]
                        end)
                        
                        player:sendSuccess(_("You have bid %s on %s and are now the highest bidder!", player, toMoneyString(bid), self.m_CurrentAuction.name))
                        triggerClientEvent(self.m_Players, "adminEventSendAuctionData", resourceRoot, self.m_CurrentAuction)
                    else
                        player:sendError(_("Your bid is too low, the highest bid for %s is %s!", player, self.m_CurrentAuction.name, toMoneyString(bid)))
                    end
                else
                    player:sendError(_("There is no auction running!", player))
                end
            end, false, false, false, player, bid)
        else
            player:sendError(_("Your bid is too low, the highest bid for %s is %s!", player, self.m_CurrentAuction.name, toMoneyString(bid)))
        end
    else
        player:sendError(_("There is no auction running!", player))
    end
end

function AdminEvent:removeHighestBid(admin)
    if self.m_CurrentAuction then
        if self.m_CurrentAuction.bids[1] then
            table.remove(self.m_CurrentAuction.bids, 1)
            triggerClientEvent(self.m_Players, "adminEventSendAuctionData", resourceRoot, self.m_CurrentAuction)
            Admin:getSingleton():sendShortMessage(_("%s removed the highest bid!", admin, admin:getName()))
        else
            admin:sendError(_("There are no bids yet!", admin))
        end
    else
        admin:sendError(_("There is no auction running!", admin))
    end
end

function AdminEvent:stopAuction(admin)
    if self.m_CurrentAuction then
        local msg = ""
        local name, bid = "nobody", 0
        if self.m_CurrentAuction.bids[1] then
            name, bid = self.m_CurrentAuction.bids[1][1], self.m_CurrentAuction.bids[1][2]
            msg = ("The call for %s has ended, the highest bidder is %s with %s!"):format(self.m_CurrentAuction.name, name, toMoneyString(bid))
        else
            msg = ("The call for %s has ended, the item was not auctioned!"):format(self.m_CurrentAuction.name)
        end
        for index, player in pairs(self.m_Players) do
            player:sendInfo(msg)
        end
        Admin:getSingleton():sendShortMessage(_("%s ended the call for %s!", admin, admin:getName(), self.m_CurrentAuction.name))
        table.insert(self.m_AuctionsPerEvent, {self.m_CurrentAuction.name, name, bid})
        self.m_CurrentAuction = nil
        triggerClientEvent(self.m_Players, "adminEventSendAuctionData", resourceRoot, self.m_CurrentAuction)
    else
        admin:sendError(_("There is no auction running!", admin))
    end
end

function AdminEvent:outputAuctionDataToPlayer(player)
    if isElement(player) and getElementType(player) == "player" then
        for i,v in ipairs(self.m_AuctionsPerEvent) do
            outputConsole(inspect(v), player)
        end
    end

end

--EASTER EVENT: BATTLE ROYALE--
--[[
function AdminEvent:activateBattleRoyaleTextures()
    for key, player in ipairs(self.m_Players) do
        if player and isElement(player) then
            player:triggerEvent("adminEventCreateBattleRoyaleTextures", player)
        end
    end
end

function AdminEvent:deactivateBattleRoyaleTextures()
    for key, player in ipairs(self.m_Players) do
        if player and isElement(player) then
            player:triggerEvent("adminEventDeleteBattleRoyaleTextures", player)
        end
    end
end

function AdminEvent:Event_WastedHandler(ammo, killer, killerWeapon, bodypart)
    if self:isPlayerInEvent(source) then
        for key, player in ipairs(self.m_Players) do
            if player and isElement(player) then
                outputChatBox("[EVENT]: #EE2222"..source:getName().." #FFFFFFist gefallen!", player, 255, 255, 255, true)
                player:triggerEvent("adminEventBattleRoyaleDeath", player, source)
            end
        end
    end
end
]]