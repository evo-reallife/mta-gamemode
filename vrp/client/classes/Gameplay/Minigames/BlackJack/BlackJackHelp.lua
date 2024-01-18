-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Minigames/BlackJackHelp.lua
-- *  PURPOSE:     BlackJackHelp
-- *
-- ****************************************************************************

BlackJackHelp = inherit(GUIForm) 
inherit(Singleton, BlackJackHelp)

local cardPath = "files/images/CardDeck/"
local soundPath = "files/audio/"

blackjackHelpGeneral = [[
	You receive two cards from the dealer and the dealer then deals himself two cards (one face up).
		Now you have to decide whether you want to draw another card (hit) or whether it is the dealer's turn to draw his cards (stand).
		If you already have a blackjack with the first two cards, you will receive 2.5 times your stake as winnings. 
		Otherwise, you will get your stake back twice as a regular win.
		In the event of a draw, you get your stake back.
]]

blackjackGoalGeneral = [[
	The aim of the game is to outbid the dealer with the value of the cards you draw but at the same time stay under the value of 21.
	You therefore have the option of either drawing a card (hit) or stopping and letting the dealer draw (stand).
	As soon as you decide to let the dealer draw, you can no longer use the hit option.

	The dealer stops as soon as he reaches 17 and then your and his cards are compared, unless you have already lost by exceeding 21.
	
	If the dealer exceeds 21 when drawing his cards or reaches 17 and has fewer cards than you when comparing them, you win.
]]


blackjackInsuranceGeneral = [[
	Assuming you guess that the dealer already has a blackjack from the two initial cards (ace and a 10), you can place an insurance bet, which will return your stake twice if the dealer really has a blackjack with both cards, 
	that the dealer really does have a blackjack with both cards, your stake is returned twice. 
	When you place the bet, you pay in your current stake and receive it twice if you win, but lose the original stake.
]]

function BlackJackHelp:constructor(mainInstance) -- soz, for not using gridsystem

	GUIForm.constructor(self, screenWidth/2 - 700/2, screenHeight/2-600/2, 700, 600, false)
	
	GUIRectangle:new(0, 0, self.m_Width, self.m_Height, tocolor(51,120,37), self)

	self.m_Page = 1
	GUILabel:new(0, 20, self.m_Width, self.m_Height-40, "Blackjack - Rules of the game", self):setAlignX("center"):setFont(VRPFont(36))
	GUIRectangle:new(0, 0, 10, self.m_Height, Color.Wood, self)
	GUIRectangle:new(self.m_Width-10, 0, 10, self.m_Height, Color.Wood, self)
	GUIRectangle:new(0, 0, self.m_Width, 10, Color.Wood, self)
	GUIRectangle:new(0, self.m_Height-10, self.m_Width, 10, Color.Wood, self)

	self.m_Pages = {}

	self.m_Pages[1] = {}
	self.m_Pages[1].title = GUILabel:new(60, 100, self.m_Width-120, 26, "Goal", self):setAlignX("left"):setFont(VRPFont(26, Fonts.EkMukta_Bold))
	self.m_Pages[1].content = GUILabel:new(60, 140, self.m_Width-120, self.m_Height-110, blackjackGoalGeneral, self):setAlignX("left"):setFont(VRPFont(24))


	self.m_Pages[3] = {}
	self.m_Pages[3].title = GUILabel:new(60, 100, self.m_Width-120, 26, "Procedure", self):setAlignX("left"):setFont(VRPFont(26, Fonts.EkMukta_Bold))
	self.m_Pages[3].content = GUILabel:new(60, 140, self.m_Width-120, self.m_Height-110, blackjackHelpGeneral, self):setAlignX("left"):setFont(VRPFont(24))

	self.m_Pages[4] = {}
	self.m_Pages[4].title = GUILabel:new(60, 100, self.m_Width-120, 26, "Insurance", self):setAlignX("left"):setFont(VRPFont(26, Fonts.EkMukta_Bold))
	self.m_Pages[4].content = GUILabel:new(60, 140, self.m_Width-120, self.m_Height-110, blackjackInsuranceGeneral, self):setAlignX("left"):setFont(VRPFont(24))


	self.m_Pages[2] = {}
	self.m_Pages[2].title = GUILabel:new(60, 100, self.m_Width-120, 26, "Cards", self):setAlignX("left"):setFont(VRPFont(26, Fonts.EkMukta_Bold))
	self.m_Pages[2].image = GUIImage:new(60, 140, 72, 100, self:makeCardPath("h11"), self)
	self.m_Pages[2].image2 = GUIImage:new(60+80, 140, 72, 100, self:makeCardPath("h12"), self)
	self.m_Pages[2].image3 = GUIImage:new(60+160, 140, 72, 100, self:makeCardPath("h13"), self)
	self.m_Pages[2].label1 = GUILabel:new(60+240, 140, 300, 100, "= Value 10", self):setAlignX("center"):setFont(VRPFont(32, Fonts.EkMukta_Bold)):setAlignY("center")


	self.m_Pages[2].image4 = GUIImage:new(60, 270, 72, 100, self:makeCardPath("h01"), self)
	self.m_Pages[2].label2 = GUILabel:new(60+140, 270, 450, 100, "= Value 11 or 1 depending on which is better", self):setAlignX("center"):setFont(VRPFont(32, Fonts.EkMukta_Bold)):setAlignY("center")

	self.m_Pages[2].image5 = GUIImage:new(60, 400, 72, 100, self:makeCardPath("h02"), self)
	self.m_Pages[2].image6 = GUIImage:new(60+30, 400, 72, 100, self:makeCardPath("h03"), self)
	self.m_Pages[2].image7 = GUIImage:new(60+30*2, 400, 72, 100, self:makeCardPath("h04"), self)
	self.m_Pages[2].image8 = GUIImage:new(60+30*3, 400, 72, 100, self:makeCardPath("h05"), self)
	self.m_Pages[2].image9 = GUIImage:new(60+30*4, 400, 72, 100, self:makeCardPath("h06"), self)
	self.m_Pages[2].image10 = GUIImage:new(60+30*5, 400, 72, 100, self:makeCardPath("h07"), self)
	self.m_Pages[2].image11 = GUIImage:new(60+30*6, 400, 72, 100, self:makeCardPath("h08"), self)
	self.m_Pages[2].image12 = GUIImage:new(60+30*7, 400, 72, 100, self:makeCardPath("h09"), self)
	self.m_Pages[2].image13 = GUIImage:new(60+30*8, 400, 72, 100, self:makeCardPath("h10"), self)
	self.m_Pages[2].label3 = GUILabel:new(60+30*9, 400, 340, 100, "= 1,2,3 ... 10", self):setAlignX("center"):setFont(VRPFont(32, Fonts.EkMukta_Bold)):setAlignY("center")




	self.m_BtnLeft = GUIButton:new(60, self.m_Height-60, 40, 40, "<", self):setAlternativeColor(tocolor(51,120,37)):setBackgroundColor(Color.White)
	self.m_BtnLeft.m_AnimatedBar:setColor(Color.Black)
	self.m_BtnLeft.onLeftClick = function() self:left() end

	self.m_BtnRight = GUIButton:new(self.m_Width-160, self.m_Height-60, 40, 40, ">", self):setAlternativeColor(tocolor(51,120,37)):setBackgroundColor(Color.White)
	self.m_BtnRight.m_AnimatedBar:setColor(Color.Black)
	self.m_BtnRight.onLeftClick = function() self:right() end


	self.m_Main = mainInstance

	self.m_BtnBack = GUIButton:new(10, 20, 80, 26, "Back", self):setAlternativeColor(tocolor(51,120,37)):setBackgroundColor(Color.White)
	self.m_BtnBack.m_AnimatedBar:setColor(Color.Black)
	self.m_BtnBack.onLeftClick = function() self.m_Main:setVisible(true);GUIForm.destructor(self);delete(self); self.m_Main.m_Info = nil;showCursor(true); end

	self:showPage()
	self.m_BtnLeft:setVisible(false)
	self.m_BtnRight:setVisible(true)

end

function BlackJackHelp:showPage()
	for i = 1, 4 do 
		for k, element in pairs(self.m_Pages[i]) do 
			element:setVisible(false)
		end
	end
	
	if self.m_Pages[self.m_Page] then 
		for k, element in pairs(self.m_Pages[self.m_Page]) do 
			element:setVisible(true)
		end
	else 
		self.m_Page = 1
	end
end

function BlackJackHelp:right() 
	playSound(self:makeSoundPath("card_draw.ogg"))
	self.m_Page = self.m_Page + 1 
	if self.m_Page > 4 then self.m_Page = 4 end
	if self.m_Page == 4 then 
		self.m_BtnRight:setVisible(false)
		self.m_BtnLeft:setVisible(true)
	else 
		self.m_BtnLeft:setVisible(true)
		self.m_BtnRight:setVisible(true)
	end
	self:showPage()
end

function BlackJackHelp:left() 
	playSound(self:makeSoundPath("card_draw.ogg"))
	self.m_Page = self.m_Page - 1
	if self.m_Page < 1 then self.m_Page = 1 end
	if self.m_Page == 1 then 
		self.m_BtnLeft:setVisible(false)
		self.m_BtnRight:setVisible(true)
	else 
		self.m_BtnLeft:setVisible(true)
	end
	self:showPage()
end

function BlackJackHelp:destructor() 

end

function BlackJackHelp:makeCardPath(file) 
	return ("%s%s.png"):format(cardPath, file)
end

function BlackJackHelp:makeSoundPath(file) 
	return ("%s%s"):format(soundPath, file)
end


