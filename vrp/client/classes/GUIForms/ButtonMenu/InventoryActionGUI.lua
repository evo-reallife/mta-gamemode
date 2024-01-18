-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/InventoryActionGUI.lua
-- *  PURPOSE:     Inventory Action GUI
-- *
-- ****************************************************************************
InventoryActionGUI = inherit(GUIButtonMenu)

function InventoryActionGUI:constructor(action)
	GUIButtonMenu.constructor(self, "Inventory - Item "..action, nil, nil, nil, screenHeight*0.2)

	-- Add the Items
	self:addItems()
end

function InventoryActionGUI:addItems()
	self:addItem(_"Yes", Color.Green, bind(self.itemCallback, self, 1))
	self:addItem(_"No", Color.Green, bind(self.itemCallback, self, 2))
end

function InventoryActionGUI:itemCallback(type)
	if type == 1 then
		Inventory:getSingleton():acceptPrompt(self)
	elseif type == 2 then
		self:close()
	end
end
