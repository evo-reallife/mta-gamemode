-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Gameplay/Jail.lua
-- *  PURPOSE:     Client Jail class
-- *
-- ****************************************************************************

local JailCenter = Vector3(2593.8, -1421.4, 1040.4)
local Jail = {}
local isPrisonBreak = false

addEvent("playerJailed", true)
addEventHandler("playerJailed", root,
	function(jailTime, bCutscene)
		-- Play arrest cutscene
		if bCutscene then
			CutscenePlayer:getSingleton():playCutscene("Arrest",
			function()
				Jail.startCountdown(jailTime)
			end)
		else
			Jail.startCountdown(jailTime)
		end
	end
)

function Jail.startCountdown(jailTime)
	InfoBox:new(_("You were locked up in prison for %d minutes!", jailTime))
	local countdown = Countdown:new(jailTime*60, "Free in:")
	countdown:addTickEvent(function()
		if isPrisonBreak == false then	
			toggleControl("fire", false)
			toggleControl("aim_weapon", false)
			toggleControl("jump", false)
		end
		if getDistanceBetweenPoints3D(localPlayer:getPosition(), JailCenter) > 100 then
			triggerServerEvent("Event_playerTryToBreakoutJail", localPlayer)
		end
	end)
end

addEvent("playerLeftJail", true)
addEventHandler("playerLeftJail", root,
	function()
		if Countdown.Map["Free in:"] then
			delete(Countdown.Map["Free in:"])
		end
	end
)

addEvent("setPrisonBreak", true)
addEventHandler("setPrisonBreak", root,
	function(state)
		isPrisonBreak = state
		toggleControl("fire", state)
		toggleControl("aim_weapon", state)
		toggleControl("jump", state)
	end
)