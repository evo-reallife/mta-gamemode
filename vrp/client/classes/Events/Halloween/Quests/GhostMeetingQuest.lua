-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Halloween/Quests/GhostMeetingQuest.lua
-- *  PURPOSE:     Ghost Meeting Quest class
-- *
-- ****************************************************************************

GhostMeetingQuest = inherit(HalloweenQuest)

function GhostMeetingQuest:constructor()
    self.m_Ghosts = {
        HalloweenGhost:new(Vector3(-730.738, 1546.295, 41), 270, 0, 0, false, false),
        HalloweenGhost:new(Vector3(-725.308, 1548.575, 41), 111, 0, 0, false, false),
        HalloweenGhost:new(Vector3(-722.573, 1546.523, 41), 90, 0, 0, false, false),
        HalloweenGhost:new(Vector3(-725.308, 1544.481, 41), 64, 0, 0, false, false)
    }
    self.m_ColShape = createColCuboid(-724.774, 1532.279, 39.091, 6, 2, 2)
    addEventHandler("onClientColShapeHit", self.m_ColShape, bind(self.onClientColShapeHit, self))
end

function GhostMeetingQuest:virtual_destructor()
    
end

function GhostMeetingQuest:startQuest()
    self:createDialog(bind(self.onStart, self), 
        "There you are again!",
        "You must find this source of spirits!",
        "It's best to have a look around the ruins..."
    )
end

function GhostMeetingQuest:onStart()
    triggerServerEvent("Halloween:giveGhostCleaner", localPlayer)
    self.m_QuestMessage = ShortMessage:new("Find the source of the spirits!", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
end

function GhostMeetingQuest:onClientColShapeHit(hitElement)
    if hitElement == localPlayer then
        toggleAllControls(false)
        self:createDialog(bind(self.onDialogEnd, self), 
            "You distribute the totems, I'll take care of the rest!",
            "Got it!"
        )
        self.m_ColShape:destroy()
    end
end

function GhostMeetingQuest:onDialogEnd()
    self.m_Ghosts[1].m_MoveObject:move(20000, self.m_Ghosts[1].m_MoveObject.position + self.m_Ghosts[1].m_MoveObject.matrix.forward * 1000)
    self.m_Ghosts[2].m_MoveObject:move(20000, self.m_Ghosts[2].m_MoveObject.position + self.m_Ghosts[2].m_MoveObject.matrix.forward * 1000)
    self.m_Ghosts[3].m_MoveObject:move(20000, self.m_Ghosts[3].m_MoveObject.position + self.m_Ghosts[3].m_MoveObject.matrix.forward * 1000)
    self.m_Ghosts[4].m_MoveObject:move(20000, self.m_Ghosts[4].m_MoveObject.position + self.m_Ghosts[4].m_MoveObject.matrix.forward * 1000)
    setTimer(
        function()
            toggleAllControls(true)
            delete(self.m_QuestMessage)
            self.m_QuestMessage = ShortMessage:new("Now return to the cemetery!", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
            self:setSucceeded()
            for key, ghost in pairs(self.m_Ghosts) do
                delete(ghost)
            end
        end
    , 5000, 1)
end

function GhostMeetingQuest:endQuest()
    self:createDialog(false, 
        "Do you distribute totems?",
        "For what?"
    )
end