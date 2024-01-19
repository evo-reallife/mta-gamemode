-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/ActionsCheck.lua
-- *  PURPOSE:     ActionsCheck Class
-- *
-- ****************************************************************************
ActionsCheck = inherit(Singleton)
ActionsCheck.Pause = 10*60 -- Amount in Seconds

function ActionsCheck:constructor()
	self:reset()
end

function ActionsCheck:isActionAllowed(player)
	if self.m_CurrentAction == false then
		local now = getRealTime()
		local next = self.m_LastAction+ActionsCheck.Pause
		if now.timestamp > next then
			return true
		else
			player:sendError(_("A promotion was recently started! The next action is only possible at %s!",player,getRealTime(next).hour..":"..getRealTime(next).minute))
		end
	else
		player:sendError(_("A %s is currently running! No further action can be started until then!",player,self.m_CurrentAction))
	end
	return false
end

function ActionsCheck:setAction(action)
	self.m_CurrentAction = action
end

function ActionsCheck:isCurrentAction()
	return self.m_CurrentAction
end

function ActionsCheck:getStatus()
	return {["current"] = self.m_CurrentAction, ["next"] = self.m_LastAction+ActionsCheck.Pause}
end

function ActionsCheck:endAction()
	self.m_LastAction = getRealTime().timestamp
	self.m_CurrentAction = false
end

function ActionsCheck:reset()
	self.m_LastAction = getRealTime().timestamp - ActionsCheck.Pause - 60
	self.m_CurrentAction = false
end
