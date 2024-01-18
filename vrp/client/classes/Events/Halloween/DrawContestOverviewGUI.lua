-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        TODO
-- *  PURPOSE:     TODO
-- *
-- ****************************************************************************

--DEVELOP INFO:
-- Player Grid wird von Lokaler DB über MTA geladen
-- Bild wird über PHP auf Test-DB gespeichert/geladen

DrawContestOverviewGUI = inherit(GUIForm)
inherit(Singleton, DrawContestOverviewGUI)

addRemoteEvents{"drawContestReceivePlayers", "drawingContestReceiveVote"}

DrawContest = {}
function DrawContest.createPed(model, pos, rot, title, text)
	--Drawing Contest
	local ped = Ped.create(model, pos, rot)
	ped:setData("NPC:Immortal", true)
	ped:setFrozen(true)
	ped.SpeakBubble = SpeakBubble3D:new(ped, title, text)
	ped.SpeakBubble:setBorderColor(Color.Orange)
	ped.SpeakBubble:setTextColor(Color.Orange)
	setElementData(ped, "clickable", true)

	ped:setData("onClickEvent",
		function()
			DrawContestOverviewGUI:getSingleton():open()
		end
	)
end

function DrawContestOverviewGUI:constructor()
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 26)
	self.m_Height = grid("y", 13)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Halloween drawing contest", true, true, self)

	self.m_ContestNameLabel = GUIGridLabel:new(1, 1, 10, 1, "Current task: -", self.m_Window)
	self.m_ContestTypeLabel = GUIGridLabel:new(13, 1, 10, 1, "Current phase: -", self.m_Window)

	self.m_PlayersGrid = GUIGridGridList:new(1, 2, 5, 11, self.m_Window)
	self.m_PlayersGrid:addColumn(_"Drawings", 1)

	self.m_Skribble = GUIGridSkribble:new(6, 2, 20, 10, self.m_Window)
	self.m_Background = GUIGridRectangle:new(6, 2, 20, 10, Color.Clear, self.m_Window)
	self.m_InfoLabel = GUIGridLabel:new(6, 2, 20, 10, "", self.m_Window):setAlign("center", "center"):setFont(VRPFont(50)):setAlpha(0)

	self.m_SelectedPlayerId = 0
	self.m_SelectedPlayerName = ""

	self:showInfoText("EVo-Reallife Halloween drawing competition!\nDraw a picture on the specified theme.\n(Each user may only submit one picture per theme)\nOne day after the closing date, users can rate the picture.\nThere are 50 pumpkins and 1000 sweets to be won in each competition!")

	self.m_RatingLabel = GUIGridLabel:new(6, 12, 4, 1, "Deine Bewertung:", self.m_Window)
	self.m_Rating = GUIGridRating:new(10, 12, 5, 1, 5, self.m_Window)
	self.m_Rating.onChange = function(ratingValue)
		QuestionBox:new(_("Would you like to rate the picture of %s with %d star/s?", self.m_SelectedPlayerName, ratingValue),
		function() triggerServerEvent("drawContestRateImage", localPlayer, self.m_SelectedDrawId, ratingValue) self.m_SelectedDrawItem:setColor(Color.Orange) self.m_SelectedDrawItem.vote = ratingValue end,
		function() self.m_Rating:reset() end
	)
	end
	self.m_RatingAdmin = GUIGridLabel:new(15, 12, 10, 1, "", self.m_Window):setAlignX("right")

	self.m_RatingLabel:setVisible(false)
	self.m_Rating:setVisible(false)
	self.m_RatingAdmin:setVisible(false)

	self.m_HideAdmin = GUIGridIconButton:new(25, 12, FontAwesomeSymbols.Trash, self.m_Window):setTooltip(_"Admin: Deactivate image", "bottom"):setBackgroundColor(Color.Red)
	self.m_HideAdmin:setVisible(false)
	self.m_HideAdmin.onLeftClick = function()
		QuestionBox:new(_("Do you want to deactivate the image of %s?", self.m_SelectedPlayerName),
		function() triggerServerEvent("drawContestHideImage", localPlayer, self.m_SelectedDrawId) self:resetOverview("Select an image") end)
	end
	self.m_AddDrawBtn = GUIGridButton:new(6, 12, 5, 1, "Draw your own picture", self.m_Window)
	self.m_AddDrawBtn:setVisible(false)
	self.m_AddDrawBtn.onLeftClick = function()
		if self.m_Contest and self.m_ContestType == "draw" then
			DrawContestGUI:new(self.m_Contest)
			delete(self)
		end
	end

	triggerServerEvent("drawContestRequestPlayers", localPlayer)
	addEventHandler("drawContestReceivePlayers", root, bind(self.onReceivePlayers, self))
	addEventHandler("drawingContestReceiveVote", root, bind(self.onReceiveVote, self))
end

function DrawContestOverviewGUI:showInfoText(text)
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

function DrawContestOverviewGUI:hideInfoText()
	if self.m_InfoLabel:getText() == "" then return end

	Animation.FadeAlpha:new(self.m_Background, 250, 200, 0)
	Animation.FadeAlpha:new(self.m_InfoLabel, 250, 255, 0).onFinish =
		function()
			self.m_InfoLabel:setText("")
		end
end

function DrawContestOverviewGUI:onReceivePlayers(contestName, contestType, players)
	self.m_Contest = contestName
	self.m_ContestType = contestType
	self.m_ContestNameLabel:setText(_("Current task: %s", contestName))
	self.m_ContestTypeLabel:setText(_("Current phase: %s", contestType == "draw" and "Drawing phase" or "Voting phase"))

	if self.m_ContestType == "draw" then
		self.m_AddDrawBtn:setVisible(true)
		self.m_RatingLabel:setVisible(false)
		self.m_Rating:setVisible(false)
		self.m_RatingAdmin:setVisible(false)
	else
		self.m_AddDrawBtn:setVisible(false)
	end

	self.m_PlayersGrid:clear()
	local item
	for id, drawing in pairs(players) do
		item = self.m_PlayersGrid:addItem(drawing.name)

		if drawing.vote then
			item:setColor(Color.Orange)
			item.vote = drawing.vote
		end

		item.onLeftClick = function(item)
			if item == self.m_SelectedDrawItem then return end

			if not localPlayer.LastRequest then
				self.m_SelectedDrawItem = item
				self.m_SelectedDrawId = drawing.drawId
				self.m_SelectedDrawVote = item.vote

				self.m_SelectedPlayerName = drawing.name
				self.m_SelectedPlayerId = id

				self:resetOverview("The image is loading...")
				localPlayer.LastRequest = true

				triggerServerEvent("drawContestRequestRating", localPlayer, drawing.drawId)
				fetchRemote((INGAME_WEB_PATH .. "/ingame/drawContest/getData.php?playerId=%s&contest=%s"):format(id, contestName), bind(self.onReceiveImage, self))
			else
				WarningBox:new("Please wait until the last request has been processed")
			end
		end
	end
end

function DrawContestOverviewGUI:resetOverview(labelText)
	self.m_Skribble:clear(true)
	self.m_RatingLabel:setVisible(false)
	self.m_Rating:setVisible(false)
	self.m_RatingAdmin:setVisible(false)
	self.m_HideAdmin:setVisible(false)
	self.m_Rating:reset()
	self:showInfoText(labelText)
end

function DrawContestOverviewGUI:onReceiveVote(admin)
	self.m_RatingAdmin:setText("")

	if admin then
		self.m_RatingAdmin:setText(admin)
	end
end

function DrawContestOverviewGUI:onReceiveImage(drawData)
	localPlayer.LastRequest = false

	self:hideInfoText()
	self.m_Skribble:drawSyncData(fromJSON(drawData))

	if localPlayer:getRank() >= RANK.Moderator then
		self.m_HideAdmin:setVisible(true)
	end

	if self.m_SelectedDrawVote then
		self.m_Rating:setRating(self.m_SelectedDrawVote)
	end

	if self.m_ContestType == "vote" then
		self.m_RatingLabel:setVisible(true)
		self.m_Rating:setVisible(true)
		if localPlayer:getRank() >= RANK.Moderator then
			self.m_RatingAdmin:setVisible(true)
		end
	end
end
