-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/DrivingSchoolTheoryGUI.lua
-- *  PURPOSE:     DrivingSchoolTheoryGUI
-- *
-- ****************************************************************************
DrivingSchoolTheoryGUI = inherit(GUIForm)
inherit(Singleton, DrivingSchoolTheoryGUI)

addRemoteEvents{"showDrivingSchoolTest"}

--// CONSTANTS //
local width,height = screenWidth*0.4,screenHeight*0.4
local TEXT_INFO = "Examination procedure:\nWelcome to the theoretical driving test for driving license category B. There will be 10 questions, which must be answered with a maximum error score of 10. The result will be displayed immediately afterwards. press 'n' to drop"
local QUESTIONS =
{
	{"How fast is allowed to drive on EVo-Reallife in Los Santos?", "30 km/h", "50 km/h", "80 km/h", "120 km/h", 3, 3},
	{"When is overtaking on the right allowed?", "On a highway", "Within city limits on a multi-lane road", "Everywhere", "Outside city limits", 3, 2},
	{"In what condition are you allowed to drive?", "Intoxicated", "Sober", "Under the influence of drugs", nil, 3, 2},
	{"What applies at an intersection without signs or traffic lights?", "First come, first served", "Fastest arrival goes first", "Yield to the right", "Honking gives right of way", 5, 3},
	{"Where is parking allowed on EVo-Reallife?", "On the street", "In front of building entrances", "No regulation", "In parking lots", 4, 4},
	{"Which road users must be especially careful of?", "Truck drivers", "Car drivers", "Pedestrians", nil, 5, 3},
	{"What should you consider in poor lighting conditions?", "Eat enough breakfast", "Sufficient lighting on the vehicle", "Play loud music to stay awake", "Drive fast", 3, 2},
	{"How are you NOT allowed to transport people with your vehicle?", "On the roof or hood", "In seats inside the vehicle", nil, nil, 5, 1},
	{"What applies at dangerous intersections?", "Drive through quickly", "Pass through slowly and cautiously", "Constantly honk", "Avoid intersections", 4, 2},
	{"What is prohibited in the Road Traffic Regulations (RTR)?", "Turn right", "Drive leisurely", "Honk", "Burnouts (spinning wheels)", 4, 4},
	{"What do you do in the event of an accident?", "I stop and clarify the facts", "I just keep driving", "I verbally abuse the other party", nil, 4, 1},
	{"What do you do when a patrol car orders you to stop?", "Drive slowly", "Drive faster", "Pull over to the right", "Ignore", 4, 3},
	{"How do you behave during a traffic control?", "Be polite to the officer", "Use vulgar insults", "Use of weapons", "I run away", 4, 1},
	{"What do you do when an officer asks to see your driver's license?", "I refuse", "I show him the driver's license", nil, nil, 4, 2},
}


function DrivingSchoolTheoryGUI:constructor(type, ped)
	GUIForm.constructor(self, screenWidth/2-width/2, screenHeight/2 - height/2, width,height, false, false, ped)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _("Theoretical Examination"), true, true, self)
	self.m_Window:toggleMoving(false)
	self.m_Window:deleteOnClose(true)
	self.m_Text = GUILabel:new( self.m_Width*0.05, self.m_Height*0.2, self.m_Width*0.9,self.m_Height, TEXT_INFO, self):setFont(VRPFont(24))
	self.m_Text:setAlignX( "left" )
	self.m_Text:setAlignY( "top" )
	self.m_StartButton = GUIButton:new( self.m_Width*0.3, self.m_Height*0.7 , self.m_Width*0.4,self.m_Height*0.1, "Start Now", self)
	self.m_StartButton.onLeftClick = function()

		self.m_Text:delete(); self.m_StartButton:delete(); self:nextQuestion();
	end
	self.m_QuestionsDone = {}
	self.m_QuestionCounter = 0
	self.m_ErrPoints = 0

end

function DrivingSchoolTheoryGUI:destructor()
	GUIForm.destructor(self)
	if not self.m_Success then
		triggerServerEvent("drivingSchoolPassTheory",localPlayer, false)
	end
end

function DrivingSchoolTheoryGUI:submitQuestion( pQuestion )
	self.m_QuestionsDone[pQuestion] = true
	local iAnswer = QUESTIONS[pQuestion][7]
	local iChecked
	for i = 1,4 do
		if self.m_QuestionButtons[i]:isChecked() then
			iChecked = i
			break
		end
	end
	if iAnswer ~= iChecked then
		self.m_ErrPoints = self.m_ErrPoints + QUESTIONS[pQuestion][6]
	end
	if self.m_QuestionCounter < 10 then
		self:nextQuestion()
	else
		self:showResult()
	end
end

function DrivingSchoolTheoryGUI:nextQuestion()
	if not self.m_SubmitButton then
		self.m_SubmitButton = GUIButton:new( self.m_Width*0.3, self.m_Height*0.9 , self.m_Width*0.4,self.m_Height*0.08, "Weiter", self)
	end
	if self.m_QuestionText then
		self.m_QuestionText:delete()
		self.m_QuestionPoints:delete()
		self.m_RBGroup:delete()
	end
	local randomInt = math.random( 1,#QUESTIONS )
	if not self.m_QuestionsDone[randomInt] then
		self.m_QuestionButtons = {	}
		self.m_QuestionCounter = self.m_QuestionCounter + 1
		local question = QUESTIONS[randomInt][1]
		self.m_QuestionPoints = GUILabel:new( self.m_Width*0.025, self.m_Height*0.15, 50, 2, QUESTIONS[randomInt][6].." Points" ,self.m_Window):setFont(VRPFont(22))
		self.m_QuestionPoints:setAlignX( "left" )
		self.m_QuestionPoints:setAlignY( "top" )
		self.m_QuestionText = GUILabel:new( self.m_Width*0.05, self.m_Height*0.2, self.m_Width*0.9, 28, self.m_QuestionCounter..". "..question ,self.m_Window):setFont(VRPFont(28))
		self.m_QuestionText:setAlignX( "center" )
		self.m_QuestionText:setAlignY( "top" )
		self.m_RBGroup = GUIRadioButtonGroup:new(self.m_Width*0.1, self.m_Height*0.4, self.m_Width*0.09, self.m_Height*0.4 ,self)
		for i =1,4 do
			if QUESTIONS[randomInt][1+i] then
				self.m_QuestionButtons[i] = GUIRadioButton:new(0, self.m_Height*0.11*(i-1), self.m_Width*0.9,  self.m_Height*0.1,QUESTIONS[randomInt][1+i]  , self.m_RBGroup)
			end
		end
		self.m_SubmitButton.onLeftClick = function() self:submitQuestion( randomInt ) end
	else return self:nextQuestion()
	end
end

function DrivingSchoolTheoryGUI:showResult()
	if self.m_SubmitButton then
		self.m_SubmitButton:delete()
	end
	if self.m_QuestionText then
		self.m_QuestionText:delete()
		self.m_RBGroup:delete()
	end
	if self.m_ErrPoints <= 10 then
		self.m_ResultText = GUILabel:new( self.m_Width*0.05, self.m_Height*0, self.m_Width*0.9,self.m_Height,"Congratulations, passed! Error points:".." "..self.m_ErrPoints,self):setFont(VRPFont(30))
		self.m_ResultText:setAlignX( "center" )
		self.m_ResultText:setAlignY( "center" )
		self.m_ResultText:setColor(Color.Green)
		triggerServerEvent("drivingSchoolPassTheory",localPlayer, true)
		self.m_Success = true
	else
		self.m_ResultText = GUILabel:new( self.m_Width*0.05, self.m_Height*0, self.m_Width*0.9,self.m_Height,"You have failed! Error points:".." "..self.m_ErrPoints,self ):setFont(VRPFont(30))
		self.m_ResultText:setAlignX( "center" )
		self.m_ResultText:setAlignY( "center" )
		self.m_ResultText:setColor(Color.Red)
		triggerServerEvent("drivingSchoolPassTheory",localPlayer, false)
	end
end


addEventHandler("showDrivingSchoolTest", localPlayer,
	function(type, ped)
		DrivingSchoolTheoryGUI:new(type, ped)
	end
)

addEventHandler("hideDrivingSchoolTheoryGUI", localPlayer,
	function()
		DrivingSchoolTheoryGUI:getSingleton():delete()
	end
)
