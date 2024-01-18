-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Halloween/Quests/TotemCleanseQuest.lua
-- *  PURPOSE:     Totem Cleanse Quest class
-- *
-- ****************************************************************************

TotemCleanseQuest = inherit(HalloweenQuest)

function TotemCleanseQuest:constructor()
    self.m_Totems = {
        HalloweenTotem:new(Vector3(288.45, -1512.53, 24.93), Vector3(0, 0, 235.14), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(1544.55, -1374.61, 330.06), Vector3(0, 0, 178.49), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(1133.84, -1619.05, 18.53), Vector3(0, 0, 270.18), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(756.18, -1261.58, 13.56), Vector3(0, 0, 0.15), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(813.20, -1102.05, 25.79), Vector3(0, 0, 268.12), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(2328.71, -1229.96, 22.52), Vector3(0, 0, 359.25), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(1515.93, -1461.22, 9.50), Vector3(0, 0, 178.54), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(1409.68, -1304.34, 9.30), Vector3(0, 0, 186.26), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(1243.23, -1257.65, 13.15), Vector3(0, 0, 272.70), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(1274.97, -1666.69, 19.73), Vector3(0, 0, 179.30), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(154.31, -1932.26, 3.77), Vector3(0, 0, 358.77), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(369.78, -2047.58, 7.84), Vector3(0, 0, 359.35), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(835.51, -2064.30, 12.87), Vector3(0, 0, 359.61), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(2172.98, -1732.13, 17.29), Vector3(0, 0, 90.71), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(2522.13, -1482.38, 24.00), Vector3(0, 0, 94.02), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(2290.78, -1528.59, 26.88), Vector3(0, 0, 181.36), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(2587.84, -2220.98, 13.55), Vector3(0, 0, 180.93), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(2941.68, -2051.63, 3.55), Vector3(0, 0, 91.17), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(673.76, -1672.03, 8.70), Vector3(0, 0, 265.79), bind(self.onTotemBreak, self)),
        HalloweenTotem:new(Vector3(830.20, -1360.13, -0.50), Vector3(0, 0, 133.85), bind(self.onTotemBreak, self))
    }
    self.m_TotemsBroken = 0
end

function TotemCleanseQuest:virtual_destructor()
    for k, totem in pairs(self.m_Totems) do
        delete(totem)
    end
end

function TotemCleanseQuest:startQuest()
    self:createDialog(bind(self.onStart, self),
        "Look around for more totems!",
        "I suspect they are connected to the giant totem!",
        "Perhaps you can get closer to the totem by destroying the small totems?"
    )
end

function TotemCleanseQuest:onStart()
    triggerServerEvent("Halloween:giveGhostCleaner", localPlayer)
    self.m_QuestMessage = ShortMessage:new("Destroy the totems! (20 remaining)", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
end

function TotemCleanseQuest:onTotemBreak()
    self.m_TotemsBroken = self.m_TotemsBroken + 1
    self.m_QuestMessage:setText(("Destroy the totems! (%s remaining)"):format(#self.m_Totems-self.m_TotemsBroken))
    if self.m_TotemsBroken == #self.m_Totems then
        delete(self.m_QuestMessage)
        self.m_QuestMessage = ShortMessage:new("Now return to the cemetery!", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
        self:setSucceeded()
    end
end

function TotemCleanseQuest:endQuest()
    self:createDialog(false, 
        "Have you found any other totems?",
        "Perhaps you can approach the totem now?"
    )
end