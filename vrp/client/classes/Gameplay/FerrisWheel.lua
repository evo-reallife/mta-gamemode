-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        TODO
-- *  PURPOSE:     TODO
-- *
-- ****************************************************************************

FerrisWheel = {}

function FerrisWheel.onClientClickedGond(ele)
    triggerServerEvent("onFerrisWheelGondClicked", ele)
end



FerrisWheelGUI = inherit(GUIForm)
inherit(Singleton, FerrisWheelGUI)

function FerrisWheelGUI:constructor()
	GUIWindow.updateGrid()			-- initialise the grid function to use a window
	self.m_Width = grid("x", 10) 	-- width of the window
	self.m_Height = grid("y", 5) 	-- height of the window

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Ferris wheel", true, true, self)
	self.m_Label = GUIGridLabel:new(1,1,9,3, _"With a height of 32m and 10 gondolas, this Ferris wheel is probably the most spectacular in the whole of San Andreas! Click on a gondola to ride up to 2 laps for only 10$.", self.m_Window)
	self.m_Btn = GUIGridButton:new(3, 4, 5, 1, "Got it!", self.m_Window):setBarEnabled(false)
	self.m_Btn.onLeftClick = function ()
		self:delete()
	end
end

function FerrisWheelGUI:destructor()
	GUIForm.destructor(self)
end