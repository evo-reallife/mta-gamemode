SpeakBubble3D = inherit(GUIForm3D)
SpeakBubble3D.Map = {}

function SpeakBubble3D:constructor(element, text, description, rotPlus, zOffset)
	addEventHandler("onClientElementDestroy", element, function () delete(self) end, false)


	self.m_Text = text
	self.m_TextWidth = dxGetTextWidth(text, 1)
	self.m_Description = description
	self.m_LongText = self.m_TextWidth > 98

	local pos = element:getPosition()
	if getElementType(element) == "vehicle" then -- calculate it with the bounding box
		local __,__,__,__,__,bbz2 = getElementBoundingBox(element)
		pos = pos + element.matrix.up*(bbz2 + 0.5)
	else
		if self.m_LongText then
			pos.z = pos.z + 1.7
		else
			pos.z = pos.z + (zOffset or 1.5)
		end
	end



	self.m_TextColor = Color.Accent
	self.m_BackgroundColor = Color.Black
	self.m_BorderColor = Color.Accent
	self.m_DescriptionColor = Color.White

	rotPlus = rotPlus or 0
	if self.m_LongText then
		GUIForm3D.constructor(self, pos, element:getRotation()+Vector3(0,0,rotPlus), Vector2(1, 0.50), Vector2(200,93), 30)
	else
		GUIForm3D.constructor(self, pos, element:getRotation()+Vector3(0,0,rotPlus), Vector2(1, 0.34), Vector2(200,70), 30)
	end
	SpeakBubble3D.Map[element] = self
end

function SpeakBubble3D:setTextColor(color)
	self.m_TextColor = color
	if self.m_TextLabel then self.m_TextLabel:setColor(color) end
end

function SpeakBubble3D:setBorderColor(color)
	self.m_BorderColor = color
	if self.m_Border then self.m_Border:setColor(color) end
end

function SpeakBubble3D:setBackgroundColor(color)
	self.m_BackgroundColor = color
	if self.m_BG then self.m_BG:setColor(color) end
end

function SpeakBubble3D:setDescriptionColor(color)
	self.m_DescriptionColor = color
	if self.m_DescriptionLabel then self.m_DescriptionLabel:setColor(color) end
end

function SpeakBubble3D:onStreamIn(surface)
	print(self.m_TextWidth)

	if self.m_LongText then
		self.m_BG = GUIImage:new(0, 0, 200, 95, "files/images/Other/bubble_bg2X.png", surface):setColor(self.m_BackgroundColor)
		self.m_Border = GUIImage:new(0, 0, 200, 95, "files/images/Other/bubble_border2X.png", surface):setColor(self.m_BorderColor)
		-- print("big")
	else
		self.m_BG = GUIImage:new(0, 0, 200, 70, "files/images/Other/bubble_bg.png", surface):setColor(self.m_BackgroundColor)
		self.m_Border = GUIImage:new(0, 0, 200, 70, "files/images/Other/bubble_border.png", surface):setColor(self.m_BorderColor)
		-- print("small")	
	end
	self.m_TextLabel = GUILabel:new(8, 2, 200, 25, self.m_Text, surface):setColor(self.m_TextColor)
	self.m_DescriptionLabel = GUILabel:new(8, 27, 200, 20, self.m_Description, surface):setColor(self.m_DescriptionColor)
end
