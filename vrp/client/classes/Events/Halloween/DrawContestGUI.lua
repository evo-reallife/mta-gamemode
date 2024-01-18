-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        TODO
-- *  PURPOSE:     TODO
-- *
-- ****************************************************************************
DrawContestGUI = inherit(GUIForm)
inherit(Singleton, DrawContestGUI)

function DrawContestGUI:constructor(contest)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 21)
	self.m_Height = grid("y", 12)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Halloween drawing contest", true, true, self)

	self.m_Skribble = GUIGridSkribble:new(1, 1, 20, 10, self.m_Window)
	self.m_Skribble:setDrawingEnabled(true)
	self.m_Background = GUIGridRectangle:new(1, 1, 20, 10, Color.Clear, self.m_Window)
	self.m_InfoLabel = GUIGridLabel:new(1, 1, 20, 10, "", self.m_Window):setAlign("center", "center"):setFont(VRPFont(50)):setAlpha(0)

	self.m_Contest = contest

	local predefinedColors = {"Black", "Brown", "Red", "Orange", "Yellow", "Green", "LightBlue", "Blue", "Purple"}
	for i, color in pairs(predefinedColors) do
		local colorButton = GUIGridRectangle:new(i, 11, 1, 1, Color[color], self.m_Window)
		colorButton.onLeftClick =
			function()
				self.m_ChangeColor:setBackgroundColor(Color[color])
				self.m_Skribble:setDrawColor(Color[color])
			end

		GUIGridEmptyRectangle:new(i, 11, 1, 1, 1, Color.Black, self.m_Window)
	end

	self.m_ChangeColor = GUIGridIconButton:new(10, 11, FontAwesomeSymbols.Brush, self.m_Window):setBarEnabled(false):setBackgroundColor(Color.Primary)
	self.m_ChangeColor.onLeftClick = bind(DrawContestGUI.changeColor, self)

	local erase = GUIGridIconButton:new(11, 11, FontAwesomeSymbols.Erase, self.m_Window):setBarEnabled(false):setBackgroundColor(Color.Primary)
	erase.onLeftClick = function() self.m_Skribble:setDrawColor(Color.White) end

	local clearDraw = GUIGridIconButton:new(12, 11, FontAwesomeSymbols.Trash, self.m_Window):setBarEnabled(false):setBackgroundColor(Color.Primary)
	clearDraw.onLeftClick = function() self.m_Skribble:clear() end


	-- About the slider range:
	-- GUISkribble draws a FontAwesome text/symbol
	-- The FontAwesome font height will devided by 2. dxCreateFont height ist limited to 5 - 150 (https://github.com/multitheftauto/mtasa-blue/blob/b2227c359092ce530cdf9727466b88bec8282cd0/Client/core/Graphics/CRenderItem.DxFont.cpp#L96)
	local slider = GUIGridSlider:new(13, 11, 5, 1, self.m_Window):setRange(10, 300)
	slider.onUpdate = function(size) self.m_Skribble:setDrawSize(size) end

	local save = GUIGridButton:new(18, 11, 3, 1, "Submit", self.m_Window)
	save.onLeftClick = function()
		QuestionBox:new("Are you sure you want to submit the picture? Warning: You can only submit one picture for the event!", function()
			self.m_Skribble:setDrawingEnabled(false)

			self:showInfoText("The image is saved...")

			local options = {
				["postData"] =  ("secret=%s&playerId=%d&contest=%s&data=%s"):format("8H041OAyGYk8wEpIa1Fv", localPlayer:getPrivateSync("Id"), contest, toJSON(self.m_Skribble:getSyncData()))
			}

			fetchRemote(INGAME_WEB_PATH .. "/ingame/drawContest/addData.php", options,
				function(responseData, responseInfo)
					--outputConsole(inspect({data = responseData, info = responseInfo}))
					responseData = fromJSON(responseData)
					if not responseData["error"] then
						self:showInfoText("The image has been saved successfully!")
					else
						if responseData["error"] == "Already sent a image" then
							self:showInfoText("Error: You have already submitted a picture for this task!")
						else
							self:showInfoText("Error: "..responseData["error"])
						end
					end

				end
			)
		end)

	end
end

function DrawContestGUI:virtual_destructor()

end


function DrawContestGUI:showInfoText(text)
	if not text then self:hideInfoText() return end
	self.m_InfoLabel:setText(text)

	local backgroundAlpha = self.m_Background:getAlpha()
	if backgroundAlpha ~= 200 then
		Animation.FadeAlpha:new(self.m_Background, 250, backgroundAlpha, 200)
	end

	local posX, posY = self.m_InfoLabel:getPosition()
	self.m_InfoLabel:setPosition(posX, -posY)
	Animation.Move:new(self.m_InfoLabel, 250, posX, posY, "OutQuad")
	Animation.FadeAlpha:new(self.m_InfoLabel, 250, 0, 255)
end

function DrawContestGUI:hideInfoText()
	if self.m_InfoLabel:getText() == "" then return end

	Animation.FadeAlpha:new(self.m_Background, 250, 200, 0)
	Animation.FadeAlpha:new(self.m_InfoLabel, 250, 255, 0).onFinish =
		function()
			self.m_InfoLabel:setText("")
		end
end

function DrawContestGUI:changeColor()
	ColorPicker:new(
		function(r, g, b)
			self.m_ChangeColor:setBackgroundColor(tocolor(r, g, b))
			self.m_Skribble:setDrawColor(tocolor(r, g, b))
		end,
		function(r, g, b)
			self.m_ChangeColor:setBackgroundColor(tocolor(r, g, b))
		end,
		function(r, g, b)
			self.m_ChangeColor:setBackgroundColor(tocolor(r, g, b))
			self.m_Skribble:setDrawColor(tocolor(r, g, b))
		end,
		self.m_Skribble.m_DrawColor
	)
end
