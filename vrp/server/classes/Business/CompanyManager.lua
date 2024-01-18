-- ****************************************************************************
-- *
-- *  PROJECT:     eXo
-- *  FILE:        server/classes/Business/CompanyManager.lua
-- *  PURPOSE:     CompanyManager class
-- *
-- ****************************************************************************
CompanyManager = inherit(Singleton)
CompanyManager.Map = {}

function CompanyManager:constructor()
	self:loadCompanies()

	-- Events
	addRemoteEvents{"getCompanies", "companyRequestInfo", "companyQuit", "companyDeposit", "companyWithdraw", "companyAddPlayer", 
		"companyDeleteMember", "companyInvitationAccept", "companyInvitationDecline", "companyRankUp", "companyRankDown", 
		"companySaveRank","companyRespawnVehicles", "companyChangeSkin", "companyToggleDuty", "companyToggleLoan", "companyRequestSkinSelection", 
		"companyPlayerSelectSkin", "companyUpdateSkinPermissions", "stopCompanyRespawnAnnouncement"}

	addEventHandler("getCompanies", root, bind(self.Event_getCompanies, self))
	addEventHandler("companyRequestInfo", root, bind(self.Event_companyRequestInfo, self))
	addEventHandler("companyDeposit", root, bind(self.Event_companyDeposit, self))
	addEventHandler("companyWithdraw", root, bind(self.Event_companyWithdraw, self))
	addEventHandler("companyAddPlayer", root, bind(self.Event_companyAddPlayer, self))
	addEventHandler("companyDeleteMember", root, bind(self.Event_companyDeleteMember, self))
	addEventHandler("companyInvitationAccept", root, bind(self.Event_companyInvitationAccept, self))
	addEventHandler("companyInvitationDecline", root, bind(self.Event_companyInvitationDecline, self))
	addEventHandler("companyRankUp", root, bind(self.Event_companyRankUp, self))
	addEventHandler("companyRankDown", root, bind(self.Event_companyRankDown, self))
	addEventHandler("companySaveRank", root, bind(self.Event_companySaveRank, self))
	addEventHandler("companyRespawnVehicles", root, bind(self.Event_companyRespawnVehicles, self))
	addEventHandler("companyChangeSkin", root, bind(self.Event_changeSkin, self))
	addEventHandler("companyToggleDuty", root, bind(self.Event_toggleDuty, self))
	addEventHandler("companyToggleLoan", root, bind(self.Event_toggleLoan, self))
	addEventHandler("companyRequestSkinSelection", root, bind(self.Event_requestSkins, self))
	addEventHandler("companyPlayerSelectSkin", root, bind(self.Event_setPlayerDutySkin, self))
	addEventHandler("companyUpdateSkinPermissions", root, bind(self.Event_UpdateSkinPermissions, self))
	addEventHandler("stopCompanyRespawnAnnouncement", root, bind(self.Event_stopRespawnAnnoucement, self))
end

function CompanyManager:destructor()
	for i, v in pairs(CompanyManager.Map) do
		delete(v)
	end
end

function CompanyManager:loadCompanies()
	local st, count = getTickCount(), 0
	local result = sql:queryFetch("SELECT * FROM ??_companies", sql:getPrefix())
	for i, row in pairs(result) do
		local result2 = sql:queryFetch("SELECT Id, CompanyRank, CompanyLoanEnabled, CompanyPermissions FROM ??_character WHERE CompanyId = ?", sql:getPrefix(), row.Id)
		local players, playerLoans, playerPermissions = {}, {}, {}
		for i, row2 in ipairs(result2) do
			players[row2.Id] = row2.CompanyRank
			playerLoans[row2.Id] = row2.CompanyLoanEnabled
			playerPermissions[row2.Id] = fromJSON(row2.CompanyPermissions)
		end

		if Company.DerivedClasses[row.Id] then
			self:addRef(Company.DerivedClasses[row.Id]:new(row.Id, row.Name, row.Name_Short, row.Name_Shorter, row.Creator, {players, playerLoans, playerPermissions}, row.lastNameChange, row.BankAccount, fromJSON(row.Settings) or {["VehiclesCanBeModified"]=false}, row.RankLoans, row.RankSkins, row.RankPermissions))
		else
			outputServerLog(("Company class for Id %s not found!"):format(row.Id))
			--self:addRef(Company:new(row.Id, row.Name, row.Name_Short, row.Creator, players, row.lastNameChange, row.BankAccount, fromJSON(row.Settings) or {["VehiclesCanBeModified"]=false}, row.RankLoans, row.RankSkins))
		end

		count = count + 1
	end
	if DEBUG_LOAD_SAVE then outputServerLog(("Created %s companies in %sms"):format(count, getTickCount()-st)) end
end

function CompanyManager:getFromId(Id)
	return CompanyManager.Map[Id]
end

function CompanyManager:addRef(ref)
	CompanyManager.Map[ref:getId()] = ref
end

function CompanyManager:removeRef(ref)
	CompanyManager.Map[ref:getId()] = nil
end

function CompanyManager:Event_companyRequestInfo()
	self:sendInfosToClient(client)
end

function CompanyManager:sendInfosToClient(client)
	local company = client:getCompany()

	if company then --use triggerLatentEvent to improve serverside performance
		if company:getPlayerRank(client) < CompanyRank.Manager and not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editLoan") then
        	client:triggerLatentEvent("companyRetrieveInfo",company:getId(), company:getName(), company:getPlayerRank(client), company:getMoney(), company:getPlayers(), company.m_RankNames)
		else
			client:triggerLatentEvent("companyRetrieveInfo",company:getId(), company:getName(), company:getPlayerRank(client), company:getMoney(), company:getPlayers(), company.m_RankNames, company.m_RankLoans)
		end
	else
		client:triggerEvent("companyRetrieveInfo")
	end
end

function CompanyManager:Event_companyQuit()
	local company = client:getCompany()
	if not company then return end

	if company:getPlayerRank(client) == CompanyRank.Leader then
		client:sendWarning(_("As a leader, you cannot leave the company!", client))
		return
	end
	company:removePlayer(client)
	client:sendSuccess(_("You have successfully left the company!", client))
	company:addLog(client, "Company", "has left the company!")

	self:sendInfosToClient(client)
	Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(client.m_Id)
end

function CompanyManager:Event_companyDeposit(amount)
	local company = client:getCompany()
	if not company then return end
    if not amount then return end

	if client:transferMoney(company, amount, "Unternehmen-Einlage", "Company", "Deposit") then
		company:addLog(client, "Kasse", "hat "..toMoneyString(amount).." in die Kasse gelegt!")
		self:sendInfosToClient(client)
		company:refreshBankAccountGUI(client)
	else
		client:sendError(_("You don't have enough money!", client))
	end
end

function CompanyManager:Event_companyWithdraw(amount)
    local company = client:getCompany()
    if not company then return end
    if not amount then return end

    if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "withdrawMoney") then
        client:sendError(_("You are not authorized to withdraw money!", client))
        -- Todo: Report possible cheat attempt
        return
    end

    if company:transferMoney(client, amount, "Company Expenses", "Company", "Withdraw") then
        company:addLog(client, "Cash Register", "has taken "..toMoneyString(amount).." from the cash register!")
        self:sendInfosToClient(client)
        company:refreshBankAccountGUI(client)
    else
        client:sendError(_("There is not enough money in the company's cash register!", client))
    end
end


function CompanyManager:Event_companyAddPlayer(player)
	if not player then return end
	local company = client:getCompany()
	if not company then return end

	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "invite"	) then
		client:sendError(_("You are not authorized to add members!", client))
		-- Todo: Report possible cheat attempt
		return
	end

	if player:getCompany() then
		client:sendError(_("This user is already in a company!", client))
		return
	end

	if not company:isPlayerMember(player) then
		if not company:hasInvitation(player) then
			company:invitePlayer(player)
            company:addLog(client, "Unternehmen", "hat den Spieler "..player:getName().." in das Unternehmen eingeladen!")
		else
			client:sendError(_("This user already has an invitation!", client))
		end
		--company:addPlayer(player)
		--client:triggerEvent("companyRetrieveInfo", company:getId(),company:getName(), company:getPlayerRank(client), company:getMoney(), company:getPlayers())
	else
		client:sendError(_("This player is already in the company!", client))
	end
end

function CompanyManager:Event_companyDeleteMember(playerId, reasonInternaly, reasonExternaly)
	if not playerId then return end
	local company = client:getCompany()
	if not company then return end

	if client:getId() == playerId then
		client:sendError(_("You can't throw yourself out of the company!", client))
		-- Todo: Report possible cheat attempt
		return
	end

	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "uninvite") then
		client:sendError(_("You can't kick the player out!", client))
		-- Todo: Report possible cheat attempt
		return
	end

	if company:getPlayerRank(client) <= company:getPlayerRank(playerId) then
		client:sendError(_("You can't kick the player out!", client))
		return
	end

	if company:getPlayerRank(playerId) == CompanyRank.Leader then
		client:sendError(_("You can't kick the company director out!", client))
		return
	end

	HistoryPlayer:getSingleton():addLeaveEntry(playerId, client.m_Id, company.m_Id, "company", company:getPlayerRank(playerId), reasonInternaly, reasonExternaly)

	company:removePlayer(playerId)

	company:addLog(client, "Company", "kicked player "..Account.getNameFromId(playerId).." out of the company!")

	self:sendInfosToClient(client)
	Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(playerId)
end

function CompanyManager:Event_companyInvitationAccept(companyId)
    local company = self:getFromId(companyId)
    if not company then
        client:sendError(_("Company not found!", client))
        return
    end

    if company:hasInvitation(client) then
        if not client:getCompany() then
            company:addPlayer(client)

            company:sendMessage(_("#008888Company: #FFFFFF%s has just joined the company!", client, getPlayerName(client)), 200, 200, 200, true)
            company:addLog(client, "Company", "has joined the company!")
            HistoryPlayer:getSingleton():addJoinEntry(client.m_Id, company:hasInvitation(client), company.m_Id, "company")

            self:sendInfosToClient(client)
            Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(client.m_Id)
        else
            client:sendError(_("You are already in a company!", client))
        end
        company:removeInvitation(client)
    else
        client:sendError(_("You have no invitation for this company", client))
    end
end

function CompanyManager:Event_companyInvitationDecline(companyId)
    local company = self:getFromId(companyId)
    if not company then return end

    if company:hasInvitation(client) then
        company:removeInvitation(client)
        company:sendMessage(_("%s has declined the company invitation", client, getPlayerName(client)))
        company:addLog(client, "Company", "has declined the invitation!")
        self:sendInfosToClient(client)
    else
        client:sendError(_("You have no invitation for this company", client))
    end
end


function CompanyManager:Event_companyRankUp(playerId, leaderSwitch)
	if not playerId then return end
	local company = client:getCompany()
	if not company then return end

	if not company:isPlayerMember(client) or not company:isPlayerMember(playerId) then
		return
	end

	if client:getId() == playerId then
		client:sendError(_("You can't change your own rank!", client))
		return
	end

	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "changeRank") then
		client:sendError(_("You are not authorized to change the rank!", client))
		-- Todo: Report possible cheat attempt
		return
	end

	if company:getPlayerRank(client) ~= CompanyRank.Leader and company:getPlayerRank(client) <= company:getPlayerRank(playerId) + 1 then
		client:sendError(_("You are not authorized to change the rank!", client))
		return
	end

	if company:getPlayerRank(playerId) + 1 >= CompanyRank.Manager then
		if LeaderCheck:getSingleton():hasPlayerLeaderBan(playerId) then
			client:sendError(_("This player can't be promoted due to a leader ban!", client))
			return
		end
	end

	if company:getPlayerRank(playerId) < CompanyRank.Leader then
		if company:getPlayerRank(playerId) < company:getPlayerRank(client) then
			if leaderSwitch then
				self:switchLeaders(client, playerId)
			end
	
			company:setPlayerRank(playerId, company:getPlayerRank(playerId) + 1)
			HistoryPlayer:getSingleton():setHighestRank(playerId, company:getPlayerRank(playerId), company.m_Id, "company")
			company:addLog(client, "Company", "promoted player "..Account.getNameFromId(playerId).." to rank "..company:getPlayerRank(playerId).."!")
			local player = DatabasePlayer.getFromId(playerId)
			if player and isElement(player) and player:isActive() then
				player:sendShortMessage(_("You have been promoted to rank %d by %s!", company:getPlayerRank(playerId), client:getName()), company:getName())
				player:setPublicSync("CompanyRank", company:getPlayerRank(playerId))
			end
			self:sendInfosToClient(client)
			PermissionsManager:getSingleton():onRankChange("up", client, playerId, "company")
			Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(playerId)
		else
			client:sendError(_("With your rank, you can promote players to a maximum rank of %d!", company:getPlayerRank(client)))
		end
	else
		client:sendError(_("You cannot promote players higher than rank 5!", client))
	end
	
end

function CompanyManager:Event_companyRankDown(playerId)
	if not playerId then return end
	local company = client:getCompany()
	if not company then return end

	if not company:isPlayerMember(client) or not company:isPlayerMember(playerId) then
		client:sendError(_("You or the target are no longer in the company!", client))
		return
	end

	if client:getId() == playerId then
		client:sendError(_("You can't change your own rank!", client))
		return
	end

	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "changeRank") then
		client:sendError(_("You are not authorized to change the rank!", client))
		-- Todo: Report possible cheat attempt
		return
	end

	if company:getPlayerRank(client) ~= CompanyRank.Leader and company:getPlayerRank(client) <= company:getPlayerRank(playerId) then
		client:sendError(_("You are not authorized to change the rank!", client))
		return
	end

    if company:getPlayerRank(playerId)-1 >= CompanyRank.Normal then
		if company:getPlayerRank(playerId) <= company:getPlayerRank(client) then
			HistoryPlayer:getSingleton():setHighestRank(playerId, company:getPlayerRank(playerId), company.m_Id, "company")
			company:setPlayerRank(playerId, company:getPlayerRank(playerId) - 1)
			company:addLog(client, "Unternehmen", "hat den Spieler "..Account.getNameFromId(playerId).." auf Rang "..company:getPlayerRank(playerId).." degradiert!")
			local player = DatabasePlayer.getFromId(playerId)
			if player and isElement(player) and player:isActive() then
				player:sendShortMessage(_("You have been demoted from %s to rank %d!", player, client:getName(), company:getPlayerRank(playerId), company:getName()))
				player:setPublicSync("CompanyRank", company:getPlayerRank(playerId))
			end
			self:sendInfosToClient(client)
			PermissionsManager:getSingleton():onRankChange("down", client, playerId, "company")
			Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(playerId)
		else
			client:sendError(_("You can't demote higher-ranking members!", client))
		end
	end
end

function CompanyManager:switchLeaders(oldLeader, newLeader)
	Async.create(
		function(oldLeader)
			local company = oldLeader:getCompany()
			
			company:setPlayerRank(oldLeader, company:getPlayerRank(oldLeader) - 1)
			company:addLog(newLeader, "Company", "demoted player "..oldLeader:getName().." to rank "..company:getPlayerRank(oldLeader).."!")
			
			if isElement(oldLeader) then
				oldLeader:sendShortMessage(_("You have been demoted to rank %d by %s!", company:getPlayerRank(oldLeader), Account.getNameFromId(newLeader)), company:getName())
				oldLeader:setPublicSync("CompanyRank", company:getPlayerRank(oldLeader))
			end
			
			self:sendInfosToClient(oldLeader)
			PermissionsManager:getSingleton():onRankChange("down", oldLeader, oldLeader:getId(), "company")
			Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(oldLeader:getId())
		end
	)(oldLeader)
end

function CompanyManager:Event_companyRespawnVehicles(instant)
	if client:getCompany() then	
		local company = client:getCompany()

		if PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "vehicleRespawnAll") then
			if not client:getCompany().m_RespawnTimer or not isTimer(client:getCompany().m_RespawnTimer) then
				if instant then
					company:respawnVehicles()
				else
					company:startRespawnAnnouncement(client)
				end
			else
				client:sendError(_("A respawn announcement has already been made.", client))
			end
		else
			client:sendError(_("You are not authorized to do so.", client))
		end
	end
end

function CompanyManager:Event_companySaveRank(rank, loan)
    local company = client:getCompany()
    if company then
        if tonumber(loan) > COMPANY_MAX_RANK_LOANS[rank] then
            client:sendError(_("The maximum salary for this rank is %d$", client, COMPANY_MAX_RANK_LOANS[rank]))
            return
        end

        if tonumber(company.m_RankLoans[tostring(rank)]) ~= tonumber(loan) then
            if PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editLoan") then
                if company:getPlayerRank(client) > rank or company:getPlayerRank(client) == CompanyRank.Leader then
                    company:setRankLoan(rank, loan)
                    company:save()
                    client:sendInfo(_("The settings for rank %d have been saved!", client, rank))
                    company:addLog(client, "Company", "changed settings for rank "..rank.."!")
                else
                    client:sendError(_("You cannot change the salary for this rank!", client))
                end
            else
                client:sendError(_("You are not authorized to change the salary", client))
            end
        end

        self:sendInfosToClient(client)
    end
end


function CompanyManager:Event_changeSkin()
	if client:isCompanyDuty() then
		client:getCompany():changeSkin(client)
	end
end

function CompanyManager:Event_toggleDuty(wasted, preferredSkin, dontChangeSkin, player)
	if not client then client = player end
	if getPedOccupiedVehicle(client) and not wasted then
		return client:sendError("Get out of the vehicle first!")
	end
	local company = client:getCompany()
	if company then
		if getDistanceBetweenPoints3D(client.position, company.m_DutyPickup.position) <= 10 or wasted then
			if client:isCompanyDuty() then
				if not dontChangeSkin then
					client:setCorrectSkin(true)
				end
				client:setCompanyDuty(false)
				company:updateCompanyDutyGUI(client)
				client:sendInfo(_("You are no longer in company service!", client))
				client:setPublicSync("Company:Duty",false)
				takeAllWeapons(client)
				client:restoreStorage()
				if company.stop then
					company:stop(client)
				end
			else
				if client:isFactionDuty() then
					--client:sendWarning(_("Bitte beende zuerst deinen Dienst in deiner Fraktion!", client))
					--return false
					FactionManager:getSingleton():factionForceOffduty(client)
				end
				company:changeSkin(client, preferredSkin) 
				client:setCompanyDuty(true)

				company:updateCompanyDutyGUI(client)
				client:sendInfo(_("You are now at the service of your company!", client))
				client:setPublicSync("Company:Duty",true)
				client:createStorage()
				if company.m_Id == CompanyStaticId.SANNEWS then
					giveWeapon(client, 43, 50) -- Camera
				end
				if company.start then
					company:start(client)
				end
			end
		else
			client:sendError(_("You are too far away!", client))
		end
	else
		client:sendError(_("You are not in any company!", client))
        return false
	end
end

function CompanyManager:Event_toggleLoan(playerId)
	if not playerId then return end
	local company = client:getCompany()
	if not company then return end

	if not company:isPlayerMember(client) or not company:isPlayerMember(playerId) then
		client:sendError(_("You or the target are no longer in the company!", client))
		return
	end

	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "toggleLoan") then
		client:sendError(_("You are not authorized to do so!", client))
		return
	end

	local current = company:isPlayerLoanEnabled(playerId)
	if company:getPlayerRank(client) <= company:getPlayerRank(playerId) and company:getPlayerRank(client) ~= CompanyRank.Leader then
		client:sendError(_("You cannot %sactivate the salary of the player", client, current and "de" or ""))
		return
	end
	
	company:setPlayerLoanEnabled(playerId, current and 0 or 1)
	self:sendInfosToClient(client)
	
	company:addLog(client, "Company", ("has %sactivated the salary of player %s!"):format(current and "de" or "", Account.getNameFromId(playerId)))	
end

function CompanyManager:Event_getCompanies()
	for id, company in pairs(CompanyManager.Map) do
		client:triggerEvent("loadClientCompany", company:getId(), company:getName(), company:getShortName(), company.m_RankNames, companyColors[company:getId()])
	end
end


function CompanyManager:Event_requestSkins()
	if not client:getCompany() then
		client:sendError(_("You don't belong to a company!", client))
		return false
	end
	local c = client:getCompany()
	local r = c:getPlayerRank(client)
	triggerClientEvent(client, "openSkinSelectGUI", client, c:getSkinsForRank(r), c:getId(), "company", PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editRankSkins"), c:getAllSkins())
end

function CompanyManager:Event_setPlayerDutySkin(skinId)
	if not client:getCompany() then
		client:sendError(_("You don't belong to a company!", client))
		return false
	end
	if not client:isCompanyDuty() then
		client:sendError(_("You are not active in the service of your company!", client))
		return
	end
	client:sendInfo(_("Changed clothes.", client))
	client:getCompany():changeSkin(client, skinId)
end

function CompanyManager:Event_UpdateSkinPermissions(skinTable)
	if not client:getCompany() then
		client:sendError(_("You don't belong to a company!", client))
		return false
	end
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editRankSkins") then
		client:sendError(_("Your rank is too low!", client))
		return false
	end
	for i, v in pairs(skinTable) do
		client:getCompany():setSetting("Skin", i, v)
	end
	client:sendSuccess(_("Settings saved!", client))

	local c = client:getCompany()
	local r = c:getPlayerRank(client)
	triggerClientEvent(client, "openSkinSelectGUI", client, c:getSkinsForRank(r), c:getId(), "company", PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editRankSkins"), c:getAllSkins())
end

function CompanyManager:getFromName(name)
	for k, company in pairs(CompanyManager.Map) do
		if company:getName() == name then
			return company
		end
	end
	return false
end

function CompanyManager:companyForceOffduty(player)
	if player:getPublicSync("Company:Duty") and player:getCompany() then
		self:Event_toggleDuty(true, false, true, player)
	end
end

function CompanyManager:Event_stopRespawnAnnoucement()
	if client:getCompany() then
		client:getCompany():stopRespawnAnnouncement(client)
	end
end