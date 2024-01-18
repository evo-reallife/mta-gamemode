-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Actions/ExplosiveTruck/ExplosiveTruckManager.lua
-- *  PURPOSE:     C4 Truck Class
-- *
-- ****************************************************************************

ExplosiveTruckManager = inherit(Singleton)

function ExplosiveTruckManager:constructor()
	self.m_Ped = Ped(27, Vector3(638.9, 851.66, -42.96), 180)
	self.m_Ped:setData("NPC:Immortal", true)
	self.m_Ped.m_Bubble = SpeakBubble3D:new(self.m_Ped, "Illegal purchase", "I offer explosives!")
	setElementData(self.m_Ped, "clickable", true)

	self.m_Ped:setData("onClickEvent", function()
		QuestionBox:new("Would you like to buy explosives for $5,000?", bind(self.start, self), nil, self.m_Ped)
	end)
end

function ExplosiveTruckManager:start()
	triggerServerEvent("ExplosiveTruckManager:start", localPlayer)
end
