-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/DrivingSchoolChooseLicenseGUI.lua
-- *  PURPOSE:     House GUI class
-- *
-- ****************************************************************************
DrivingSchoolChooseLicenseGUI = inherit(GUIButtonMenu)

function DrivingSchoolChooseLicenseGUI:constructor(target)
	self.m_Target = target
	GUIButtonMenu.constructor(self, "Select driving License")

	self:addItem(_"Car License",Color.Green ,
		function()
			triggerServerEvent("drivingSchoolStartLessionQuestion", localPlayer, self.m_Target, "car")
			self:delete()
		end
	)
	self:addItem(_"Motorcycle License",Color.Blue ,
		function()
			triggerServerEvent("drivingSchoolStartLessionQuestion", localPlayer, self.m_Target, "bike")
			self:delete()
		end
	)
	self:addItem(_"Truck License",Color.LightRed ,
		function()
			triggerServerEvent("drivingSchoolStartLessionQuestion", localPlayer, self.m_Target, "truck")
			self:delete()
		end
	)
	--self:addItem(_"Helikopterschein",Color.Orange ,
	--	function()
	--		triggerServerEvent("drivingSchoolstartLessionQuestion", localPlayer, self.m_Target, "heli")
	--		self:delete()
	--	end
	--)
	self:addItem(_"Helicopter License",Color.Accent ,
		function()
			triggerServerEvent("drivingSchoolStartLessionQuestion", localPlayer, self.m_Target, "plane")
			self:delete()
		end
	)
end
