-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/ShopManageGUI.lua
-- *  PURPOSE:     ShopManageGUI
-- *
-- ****************************************************************************
ShopManageGUI = inherit(GUIButtonMenu)
inherit(Singleton, ShopManageGUI)
ShopManageGUI.Texts = {["Bar"] = "this Bar", ["Shop"] = "this Shop"}


addRemoteEvents{"shopOpenManageGUI", "shopCloseManageGUI", "updateShopManageGUI"}

function ShopManageGUI:constructor(shopId, name, type, ownerId, ownerName, price, streamUrl, stripper)
	GUIButtonMenu.constructor(self, _("%s: %s", type, name))

	self.m_ShopId = shopId
	self.m_Type = type

	self.m_OwnerId = ownerId
	self.m_OwnerName = ownerName
	self.m_Stream = streamUrl or ""
	self.m_Price = price or 0
	self.m_Stripper = stripper or false

	-- Add the Items
	self:addItems()

	-- Events
	--addEventHandler("updateShopManageGUI", root, bind(self.Event_updateShopManageGUI, self))
	addEventHandler("shopCloseManageGUI", root, bind(self.Event_close, self))
end

function ShopManageGUI:addItems()
	self:addItemNoClick("Owner: "..self.m_OwnerName, Color.Accent)
	self:addItemNoClick("Value: "..self.m_Price.."$", Color.White)
	if self.m_OwnerId == 0 then
		self:addItem(_("%s Buy", self.m_Type), Color.Blue, bind(self.itemCallback, self, 2))
	else
		if self.m_OwnerId == localPlayer:getGroupId() then
			self:addItem(_("%s Sell", self.m_Type), Color.Red, bind(self.itemCallback, self, 3))
			self:addItem(_"Manage Cash", Color.Blue, bind(self.itemCallback, self, 4))

			if self.m_Type == "Bar" then

				self:addItem(_"Manage music", Color.Green, bind(self.itemCallback, self, 1))

				if self.m_Stripper then
					self:addItem(_"Strippers Dismissed", Color.Red, bind(self.itemCallback, self, 6))
				else
					self:addItem(_"Hiring strippers", Color.Red, bind(self.itemCallback, self, 5))
				end
			end
		end
	end
end

function ShopManageGUI:itemCallback(type)
	if type == 1 then
		self.m_StreamGUI = StreamGUI:new("Change Bar Music",
		function(url)
			triggerServerEvent("barShopMusicChange", localPlayer, self.m_ShopId , url)
		end,
		function()
			triggerServerEvent("barShopMusicStop", localPlayer, self.m_ShopId )
		end,
		self.m_Stream
		)
	elseif type == 2 then
		QuestionBox:new(_("Do you really want to buy %s for your company for %d$?", ShopManageGUI.Texts[self.m_Type], self.m_Price),
		function() 	triggerServerEvent("shopBuy", localPlayer, self.m_ShopId) end
		)
	elseif type == 3 then
		QuestionBox:new(_("Do you really want to sell %s of your company for %d$?", ShopManageGUI.Texts[self.m_Type], math.floor(self.m_Price*0.75)),
		function() 	triggerServerEvent("shopSell", localPlayer, self.m_ShopId) end
		)
	elseif type == 4 then
		triggerServerEvent("shopOpenBankGUI", localPlayer, self.m_ShopId)
	elseif type == 5 then
		QuestionBox:new(_("Do you really want to hire strippers? (Cost 15$ per 15 minutes!)"),
		function() 	triggerServerEvent("barShopStartStripper", localPlayer, self.m_ShopId) end
		)
	elseif type == 6 then
		triggerServerEvent("barShopStopStripper", localPlayer, self.m_ShopId)
	end
	delete(self)
end

function ShopManageGUI:Event_close()
	if self.m_StreamGUI then
		delete(self.m_StreamGUI)
	end
	delete(self)
end

addEventHandler("shopOpenManageGUI", root,
		function(shopId, name, type, ownerId, ownerName, price, streamUrl, stripper)
			if ShopManageGUI:isInstantiated() then
				delete(ShopManageGUI:getSingleton())
			end
			ShopManageGUI:new(shopId, name, type, ownerId, ownerName, price, streamUrl, stripper)
		end
	)
