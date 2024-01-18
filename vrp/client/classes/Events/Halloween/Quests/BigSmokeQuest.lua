-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Halloween/Quests/BigSmokeQuest.lua
-- *  PURPOSE:     Ghost Finder Quest class
-- *
-- ****************************************************************************

BigSmokeQuest = inherit(HalloweenQuest)

function BigSmokeQuest:constructor()
    self.m_Ghost = HalloweenGhost:new(Vector3(2260.347, -1224.271, 1049.023), 180, 10, 13, false, false)
    self.m_ColShape = createColRectangle(2259.034, -1221.085, 3, 1)
    addEventHandler("onClientColShapeHit", self.m_ColShape, bind(self.onClientColShapeHit, self))
end

function BigSmokeQuest:virtual_destructor()
    if self.m_Ghost then
        delete(self.m_Ghost)
    end
end

function BigSmokeQuest:startQuest()
    self:createDialog(bind(self.onStart, self),
        "You came just in time!",
        "I have information about a ghost that is haunting a house in Idlewood!",
        "Take the spirit distributor and drive him away!"
    )
end

function BigSmokeQuest:onStart()
    triggerServerEvent("Halloween:giveGhostCleaner", localPlayer)
    self.m_QuestMessage = ShortMessage:new("Drive the ghost out of the house in Idlewood!", "Halloween: Quest", Color.Orange, -1, false, false, Vector2(2058.01, -1697.27), {{path="Marker.png", pos=Vector2(2058.01, -1697.27)}}, true)
end

function BigSmokeQuest:onClientColShapeHit(hitElement)
    if hitElement == localPlayer then
        toggleAllControls(false)
        self:createDialog(bind(self.removeDisguise, self), 
            "I knew you would come.",
            "You will not hinder us in our plan."
        )
        self.m_ColShape:destroy()
    end
end

function BigSmokeQuest:removeDisguise()
    fadeCamera(false, 0.1)
    setTimer(
        function()
            self.m_Ghost.m_Ped:setModel(311)
            self.m_Ghost.m_Ped:setAlpha(150)
        end
    , 200, 1)
    setTimer(
        function()
            fadeCamera(true, 0.1)
        end
    , 600, 1)
    setTimer(
        function()
            self:createDialog(bind(self.moveGhost, self), 
                "Now if you'll excuse me, I have to go."
            )
        end
    , 700, 1)
end

function BigSmokeQuest:moveGhost()
    self.m_Ghost.m_MoveObject:move(4000, 2260.347, -1226.271, 1049.023)
    
    toggleAllControls(true)
    delete(self.m_QuestMessage)
    self.m_QuestMessage = ShortMessage:new("Now return to the cemetery!", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
    self:setSucceeded()
end

function BigSmokeQuest:endQuest()
    self:createDialog(false, 
        "The ghost spoke of a plan and then fled?",
        "Strange...",
        "Nevertheless, a reward for your work!"
    )
end