-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/PlayerPermissionsGUI.lua
-- *  PURPOSE:     PlayerPermissionsGUI class
-- *
-- ****************************************************************************
PlayerPermissionsGUI = inherit(GUIForm)
inherit(Singleton, PlayerPermissionsGUI)

addRemoteEvents{"showPlayerPermissionsList"}
function PlayerPermissionsGUI:constructor(permissionsType, rank, type, playerId)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 12) 
	self.m_Height = grid("y", 15)

	self.m_Changes = {}
	self.m_PermissionsType = permissionsType
	self.m_Rank = rank
	self.m_Type = type
	self.m_PlayerId = playerId

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, "Manage permissions", true, true, self)

	self.m_PermissionsList = GUIGridGridList:new(1, 1, 11, 10, self.m_Window)

	if permissionsType == "permission" then
		self.m_PermissionsList:addColumn(_"Permission", 0.7)
	elseif permissionsType == "action" then
		self.m_PermissionsList:addColumn(_"Action", 0.7)
	elseif permissionsType == "weapon" then
		self.m_PermissionsList:addColumn(_"Weapon", 0.7)
	end
	self.m_PermissionsList:addColumn(_"Status", 0.3)

	self.m_SaveButton = GUIGridButton:new(1, 14, 11, 1, _"Save", self.m_Window):setBackgroundColor(Color.Accent)
	self.m_SaveButton.onLeftClick = bind(self.saveButton_Click, self)
	addEventHandler("showPlayerPermissionsList", localPlayer, bind(self.updateList, self))

	triggerServerEvent("requestPlayerPermissionsList", localPlayer, permissionsType, type, playerId)
end

function PlayerPermissionsGUI:destructor()
	GUIForm.destructor(self)
end

function PlayerPermissionsGUI:updateList(data, permissionsType)
	self.m_PermissionsList:clear()
	for name, info in pairs(data) do
		local item
		if permissionsType == "permission" then
			item = self.m_PermissionsList:addItem(PERMISSION_NAMES[name], (info == "default" and _"Rank standard") or (info and _"Allowed" or _"Forbidden"))
		elseif permissionsType == "action" then
			item = self.m_PermissionsList:addItem(ACTION_PERMISSION_NAMES[name], (info == "default" and _"Rank standard") or (info and _"Allowed" or _"Forbidden"))
		elseif permissionsType == "weapon" then
			item = self.m_PermissionsList:addItem(WEAPON_NAMES[name], (info == "default" and _"Rank standard") or (info and _"Allowed" or _"Forbidden"))
		end
		item:setColor((info == "default" and Color.Orange) or (info and Color.Green or Color.Red))
		item.name = name
		item.info = info
		item.onLeftDoubleClick = bind(self.onItemDoubleClick, self)
	end
end

function PlayerPermissionsGUI:onItemDoubleClick()
	local item = self.m_PermissionsList:getSelectedItem()
	
	if self.m_PlayerId then
		if item.info == true then
			item:setColumnText(2, _"Forbidden")
			item:setColor(Color.Red)
			item.info = false
			self.m_Changes[item.name] = false
		elseif item.info == false then
			item:setColumnText(2, _"Rank standard")
			item:setColor(Color.Orange)
			item.info = "default"
			self.m_Changes[item.name] = "default"
		elseif item.info == "default" then
			item:setColumnText(2, _"Allowed")
			item:setColor(Color.Green)
			item.info = true
			self.m_Changes[item.name] = true
		end
	end
end

function PlayerPermissionsGUI:saveButton_Click()
	triggerServerEvent("changePlayerPermissions", localPlayer, self.m_PermissionsType, self.m_Changes, self.m_Type, self.m_PlayerId)
	self.m_Changes = {}
end