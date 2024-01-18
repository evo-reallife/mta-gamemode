-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Faction.lua
-- *  PURPOSE:     Faction Client
-- *
-- ****************************************************************************

Faction = inherit(Object)

function Faction:constructor(Id, name, name_short, rankNames, factionType, color, navigationPosition, diplomacy)
	self.m_Id = Id
	self.m_Name = name
	self.m_NameShort = name_short
	self.m_RankNames = rankNames
	self.m_Type = factionType
	self.m_Color = color
	self.m_NavigationPosition = normaliseVector(navigationPosition)
	self.m_Diplomacy = diplomacy
end

function Faction:getId()
	return self.m_Id
end

function Faction:isStateFaction()
	return self.m_Type == "State"
end

function Faction:isEvilFaction()
	return self.m_Type == "Evil"
end

function Faction:isRescueFaction()
	return self.m_Type == "Rescue"
end

function Faction:isInsurgentFaction()
	return self.m_Type == "Insurgent"
end

function Faction:getName()
	return self.m_Name
end

function Faction:getShortName()
	return self.m_NameShort
end

function Faction:getColor()
	return self.m_Color
end

function Faction:getNavigationPosition()
	return self.m_NavigationPosition
end

function Faction:setDiplomacy(diplomacy)
	self.m_Diplomacy = diplomacy
end

function Faction:getDiplomacy(targetFaction)
	local factionId, status
	for index, data in pairs(self.m_Diplomacy) do
		factionId, status = unpack(data)
		if factionId == targetFaction:getId() then
			return status
		end
	end
end

function Faction:getAllianceFaction()
	local factionId, status
	if not self.m_Diplomacy then return false end
	for index, data in pairs(self.m_Diplomacy) do
		factionId, status = unpack(data)
		if status == FACTION_DIPLOMACY["Allied"] then
			if FactionManager:getSingleton():getFromId(factionId) then
				return FactionManager:getSingleton():getFromId(factionId)
			end
		end
	end
	return false
end

function Faction:hasWarWith(faction)
	local factionId, status
	if not self.m_Diplomacy then return false end
	for index, data in pairs(self.m_Diplomacy) do
		factionId, status = unpack(data)
		if factionId == faction:getId() then
			if status == FACTION_DIPLOMACY["At war"] then
				return true
			end
		end
	end
	return false
end

function Faction:startRespawnAnnouncement(announcer)
	local seconds = 15
	local whoAnnouncedText = _("%s announced a respawn.", announcer == localPlayer and "You have" or _("%s has", announcer:getName())) 
	local secondsLeftText = _("All vehicles are respawned in %d seconds!", seconds)
	local stopRespawnText = _"Click here to stop the respawn."

	self.m_RespawnAnnouncement = ShortMessage:new(_("%s %s\n %s", whoAnnouncedText, secondsLeftText, stopRespawnText), 
	_"Vehicle respawn", 
	tocolor(self:getColor().r, self:getColor().g, self:getColor().b), 
	15000, function()
		triggerServerEvent("stopFactionRespawnAnnouncement", localPlayer, self:getId())
	end)

	self.m_RespawnCountdown = setTimer(function() 
		seconds = seconds - 1
		secondsLeftText = _("All vehicles are respawned in %d second%s!", seconds, seconds ~= 1 and "n" or "")
		self.m_RespawnAnnouncement:setText(_("%s %s\n%s", whoAnnouncedText, secondsLeftText, stopRespawnText))
	end, 1000, 15)
end

function Faction:stopRespawnAnnoucement(stopper)
	local whoStoppedText
	if stopper == localPlayer then
		whoStoppedText = _"You have stopped the respawn."
	else
		whoStoppedText = _("%s has stopped the respawn.", stopper:getName())
	end
	killTimer(self.m_RespawnCountdown)
	self.m_RespawnAnnouncement:delete()
	self.m_RespawnAnnouncement = ShortMessage:new(whoStoppedText, _"Vehicle respawn")
end