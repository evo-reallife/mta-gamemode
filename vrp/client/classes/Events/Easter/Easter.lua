-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Easter/Easter.lua
-- *  PURPOSE:     Easter class
-- *
-- ****************************************************************************

Easter = inherit(Singleton)

Easter.HidingRabbitPositions = {
    {2081.79, 1902.12, 14.85, 280},         --The Visage (M)
    {-1846.37, -1712.12, 41.11, 345},       --Whetstone (M)
    {-2706.46, 1930.05, 3.22, 142},         --Gant Bridge (M)
    {1530.45, 1937.2, 10.82, 180},          --Redsands West (D)
    {-154.94, -256.56, 3.91, 180},          --Fleischberg (M)
    {-2177.318, 712.2, 53.89, 180},         --Chinatown SF (M)
    {1635.26, 10.68, 9.24, 160},            --Redcounty Bridge (M)
    {-2510, -686.774, 139.32, 90},          --Missionary Hill (D)
    {-2475.60, 1553.74, 33.23, 180},        --SF Bay Boat (M)
    {249.32, -1465.10, 38.40, 275},         --LS Billboard (M)
    {2542.94, 1028.45, 10.82, 180},         --Come-A-Lot (M)
    {1297.765, 2605.634, 10.82, 0},         --Prickle Pine (D)
    {-1675.48, 1008.66, 7.92, 270},         --SF Labyrinth (SD)
    {679.17, -2621.65, 2.70, 90},           --Fisher Island (M)
    {-1528.61, 2656.57, 56.28, 90},         --El Quebrados (M)
}
Easter.RabbitHints = {
    {"Allow me, the Easter Bunny. May I ask you a favor?", "My 15 little helpers are not back yet...", "I sent one of my helpers to the middle of the city of adventures in the north.", "Could you go look for him? Otherwise he'll catch a cold...", "My little helpers are also a little short-sighted.", "If you find him, please stand directly in front of him, otherwise he won't see you."},
    {"Oh hello, have you found the first one yet?", "Unfortunately, the next one got lost on the way to San Fierro near this mountain...", "Its fur was already really black with dust. Where on earth did it end up?"},
    {"Oops, there you are again.", "Bad news. A little helper was supposed to go to this small town in the north-west...", "But now the little man is stuck and can't get away from this huge building.", "Can you find him as quickly as possible? Please please please."},
    {"Back again? Wonderful, just a moment, where was that...", "Oh yes, the next helper is near the first one. You know, in the town to the north.", "It's said to have fled from gangsters and hidden north of the airport.", "My little helper is probably scared, please hurry!"},
    {"Hi there.", "So this little helper was supposed to be fasting.", "And I caught it, enjoying a few cans of beer!", "Now it has probably hidden itself in shame; the beer was quite expensive too.", "Do you have any idea where it could be hiding?"},
    {"Hello again, this time it's going to be tricky.", "Unfortunately, I have no idea where my little helper from San Fierro has gone.", "But I know that there are culturally rich people with foreign roots living nearby.", "Maybe you can do something with the clue?"},
    {"*sniff sniff* Oh, it's you. I completely forgot that one little helper is still lingering north of Los Santos. Near there is the highway, and next door, the famous race of an old gang is said to have taken place... Where could it be?"},
    {"Good morning, I was hoping to see you.", "Another one of my little helpers got lost south of San Fierro.", "It's supposed to be at a slightly higher altitude and you're supposed to have pretty good reception there.", "Does that mean anything to you?"},
    {"Ahoy, nice to meet you here!", "This little cheeky boy... A little helper sent me a selfie of himself earlier.", "I don't know where it is, but there's a lot of electronics in the background in front of big windows.", "And through the window you can see... big, colored metal boxes or something?", "Please be so kind and take a look around."},
    {"Hello there.", "I saw the little helper last night, but I don't remember it.", "But it was here in town and I remember seeing an advertisement for burns...", "Strange, it must have burned itself into my memory.", "Never mind. Could you please be on your way?"},
    {"There you go again!", "I don't have any exact information this time, but my little helper was on vacation shortly before.", "It treated itself to a hotel stay in Las Venturas and then ended up in a shabby strip club...", "Please bring it back before I have to go to therapy, will you?"},
    {"Moin. Auf ein Neues!", "Ich glaube, eins meiner Helferchen will sich vor seiner Arbeit drücken.", "Er wohnt ebenfalls nördlich in der Stadt der Abenteuer, ruhige Gegend muss man sagen. Bis auf das regelmäßige Quietschen von Rädern.", "Du kannst ihm sicher Beine machen oder?"},
    {"Greetings, hello.", "Oh dear, maybe this time it's even my fault that it got lost.", "I sent my little helper to a labyrinth in San Fierro to find my hidden Easter eggs...", "Can you please get it out of there?"},
    {"Hello and good morning!", "Oh, this could be tricky.", "One of my little helpers radioed in that his boat gave up the ghost while fishing, and now it's stuck here.", "If you could help him, that would be fantastic."},
    {"A beautiful one.", "Phew, almost all the little helpers have now returned, now only one is missing.", "It's holed up in a village in far Bone County after stocking up on weapons at the Ammunation.", "Please bring it to its senses and then come back, will you?"},
}
addRemoteEvents{"Easter:loadHidingRabbit"}

function Easter:constructor()
    RabbitManager:new()

    self.m_Blip = Blip:new("BunnyHead.png", 1477.5, -1663, 200, {177, 162, 133})
    self.m_Blip:setDisplayText("Osterhase")

    self.m_Rabbit = createPed(304, 1480.62, -1673.24, 14.05, 180)
    RabbitManager:getSingleton():setPedRabbit(self.m_Rabbit)
    RabbitManager:getSingleton():setPedIdleStance(self.m_Rabbit)
    RabbitManager:getSingleton():addPedEggBasket(self.m_Rabbit)

    self.m_Marker = createMarker(1480.53, -1675.5, 13.1, "cylinder", 1, 255, 255, 255, 255)
    triggerEvent("elementInfoCreate", localPlayer, self.m_Marker, "Osterhase", 1, "Egg", true)
    addEventHandler("onClientMarkerHit", self.m_Marker, bind(self.onClientMarkerHit, self))

    self.m_HidingRabbits = {}
    addEventHandler("Easter:loadHidingRabbit", root, bind(self.loadHidingRabbit, self))
    triggerServerEvent("Easter:requestHidingRabbits", localPlayer) 

    for index, object in pairs(getElementsByType("object")) do
        if object:getModel() == 3095 then
            local x, y, z = getElementPosition(object)
            if getDistanceBetweenPoints3D(x, y, z, -1677, 1006, 5) < 100 then
                FileTextureReplacer:new(object, "files/images/Textures/JetdoorMetal.png", "sam_camo", {}, true, true)
            end
        end
    end
end

function Easter:loadHidingRabbit(rabbitsFound)
    local rabbit = rabbitsFound+1
    if rabbit <= #Easter.HidingRabbitPositions then
        self.m_HidingRabbitId = rabbit
        self.m_HidingRabbit = createPed(304, unpack(Easter.HidingRabbitPositions[rabbit]))
        RabbitManager:getSingleton():setPedRabbit(self.m_HidingRabbit)
        RabbitManager:getSingleton():setPedIdleStance(self.m_HidingRabbit)
        RabbitManager:getSingleton():addPedEggBasket(self.m_HidingRabbit)
        self.m_HidingRabbit.colshape = createColSphere(self.m_HidingRabbit.position + self.m_HidingRabbit.matrix.forward*2, 1)
        addEventHandler("onClientColShapeHit", self.m_HidingRabbit.colshape, 
            function(hitElement, matchingDim)
                if matchingDim then
                    if hitElement == localPlayer then
                        DialogGUI:new(bind(self.onHidingRabbitFound, self),
                            "You found me, thank you!",
                            "I am now returning to Pershing Square!"
                        )
                    end
                end
            end
        )
    end
end

function Easter:destroyHidingRabbit()
    RabbitManager:getSingleton():removePedIdleStance(self.m_HidingRabbit)
    RabbitManager:getSingleton():removePedEggBasket(self.m_HidingRabbit)
    self.m_HidingRabbit.colshape:destroy()
    self.m_HidingRabbit:destroy()
    self.m_HidingRabbit = nil
    self.m_HidingRabbitId = nil
end

function Easter:onClientMarkerHit(hitElement, matchingDim)
    if matchingDim then
        if hitElement == localPlayer then
            if self.m_HidingRabbitId then
                DialogGUI:new(false,
                    unpack(Easter.RabbitHints[self.m_HidingRabbitId])
                )
            else
                DialogGUI:new(false,
                    "Thank you very much for your help!"
                )
            end
        end
    end
end

function Easter:onHidingRabbitFound()
    fadeCamera(false, 0.001)
    setTimer(
        function()
            triggerServerEvent("Easter:onHidingRabbitFound", localPlayer, self.m_HidingRabbitId)
            self:destroyHidingRabbit()
            triggerServerEvent("Easter:requestHidingRabbits", localPlayer) 
            fadeCamera(true)
        end
    , 500, 1)
end

function Easter.updateTextures() 
	Easter.Textures = {}
	function Easter.updateTexture(texname, file, object)
		if not Easter.Textures[file] then
			Easter.Textures[file] = {}
			Easter.Textures[file].shader = dxCreateShader("files/shader/texreplace.fx")
			Easter.Textures[file].tex = dxCreateTexture(file)
			dxSetShaderValue(Easter.Textures[file].shader, "gTexture", Easter.Textures[file].tex)
		end

		engineApplyShaderToWorldTexture(Easter.Textures[file].shader, texname, object)
	end

	for index, object in pairs(getElementsByType("object")) do
		if object:getModel() == 2347 and getElementData(object, "EasterSlotmachine") then
			Easter.updateTexture("cj_wheel_69256", "files/images/Events/Easter/slot_1.png", object) -- 69
			Easter.updateTexture("cj_wheel_B1256", "files/images/Events/Easter/slot_2.png", object) -- Gold 1
			Easter.updateTexture("cj_wheel_B2256", "files/images/Events/Easter/slot_7.png", object) -- Gold 2
			Easter.updateTexture("cj_wheel_Bell256", "files/images/Events/Easter/slot_4.png", object) -- Glocke
			Easter.updateTexture("cj_wheel_Cherry256", "files/images/Events/Easter/slot_5.png", object) -- Kirsche
			Easter.updateTexture("cj_wheel_Grape256", "files/images/Events/Easter/slot_6.png", object) -- Traube
		elseif object:getModel() == 2325 and object:getData("Easter") then
			Easter.updateTexture("slot5_ind", "files/images/Events/Easter/slotmachine"..math.random(1,2)..".jpg", object)
		end
	end
end