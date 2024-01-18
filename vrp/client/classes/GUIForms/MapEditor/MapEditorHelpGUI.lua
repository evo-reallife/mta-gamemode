-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/MapEditor/MapEditorHelpGUI.lua
-- *  PURPOSE:     Map Editor Help GUI class
-- *
-- ****************************************************************************

MapEditorHelpGUI = inherit(GUIForm)
inherit(Singleton, MapEditorHelpGUI)

function MapEditorHelpGUI:constructor()
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 20)
	self.m_Height = grid("y", 15)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Instructions for the Map Editor", true, true, self)
	self.m_Scrollable = GUIGridScrollableArea:new(1, 1, 19, 14, 19, 40, true, false, self.m_Window)
    self.m_Scrollable:updateGrid()
	
	GUIGridLabel:new(1, 1, 19, 1, "Introduction", self.m_Scrollable):setHeader()
	GUIGridLabel:new(1, 2, 19, 9, [[The Map Editor is a tool for editing the map in real time. It makes it possible to remove objects from the standard map and add new objects as desired. Objects added by the script (faction bases, minor embellishments etc.) cannot be influenced by the Map Editor.

	The intention behind the programming of the map editor is to enable events such as construction sites, accidents, roadblocks and further extensions of actions etc. on the map in real time and to give the administration team a certain freedom over the structure of the map.
	
	Since changing the map, whether during runtime or not, always has an enormous influence on the gameplay, the map editor should always be used with caution and care. 
	It is better to think twice or talk to other team members before creating something that may cause an unforeseen intervention in the game]]., self.m_Scrollable)
    

    GUIGridLabel:new(1, 12, 19, 1, "Start with the folder", self.m_Scrollable):setHeader()
	GUIGridLabel:new(1, 13, 19, 2, "During the entire time you are mapping, you will find a window with three additional buttons at the bottom of the screen:", self.m_Scrollable)
    
    GUIGridLabel:new(1, 15, 1, 1, FontAwesomeSymbols.Plus, self.m_Scrollable):setFont(FontAwesome(30))
	GUIGridLabel:new(2, 15, 18, 1, "A plus sign to create a new object", self.m_Scrollable):setHeader("sub")
	GUIGridLabel:new(1, 16, 19, 2, [[    A window will now open where you can filter objects by name or category. 
    You can then place the object with your mouse.]], self.m_Scrollable)

    GUIGridLabel:new(1, 18, 1, 1, FontAwesomeSymbols.Erase, self.m_Scrollable):setFont(FontAwesome(30))
	GUIGridLabel:new(2, 18, 18, 1, "An eraser for removing objects from the standard map", self.m_Scrollable):setHeader("sub")
	GUIGridLabel:new(1, 19, 19, 3, [[    Your mouse now shows objects on the standard map that can be removed. With a double 
    left-click on the object, the object is colored red for better recognition and a marker appears on the map.
    appears on the map. Unfortunately, it is not possible to recognize some objects on the script side.
    Unfortunately, these objects cannot be removed using the Map Editor.]], self.m_Scrollable)

    GUIGridLabel:new(1, 22, 1, 1, FontAwesomeSymbols.Edit, self.m_Scrollable):setFont(FontAwesome(30))
	GUIGridLabel:new(2, 22, 18, 1, "An edit icon for selecting the map and creating new maps", self.m_Scrollable):setHeader("sub")
	GUIGridLabel:new(1, 23, 19, 7, [[    The list on the left-hand side shows the created maps and their current status. 
    The list on the right-hand side shows the objects that are assigned to the map. If you are unable to click on an object 
    cannot click on an object due to a missing collision, you can search, select and edit the object here. 
    edit it. The object is also indicated here by a coordinate cross, a bounding box and a marker on the map. 
    marker on the map. Removed standard objects can also be restored here. 
    be restored. Restorable objects are also marked here by coloring and a map marker. 
    map marking.
    It is still possible for higher-ranking team members to deactivate a map and make the associated objects disappear. 
    objects and restore standard objects removed from this map until the map is reactivated. 
    reactivate the map.]], self.m_Scrollable)

	
	GUIGridLabel:new(1, 31, 19, 1, "Further information", self.m_Scrollable):setHeader()
	GUIGridLabel:new(1, 32, 19, 2, [[Double-clicking on a newly placed object opens a window for more detailed editing of the object. A selected object can be deleted with the delete button.
	Right-click on the corresponding object to place it again with the mouse.]], self.m_Scrollable)

	
	GUIGridLabel:new(1, 35, 19, 1, "Call up the Map Editor", self.m_Scrollable):setHeader()
	GUIGridLabel:new(1, 36, 19, 4, [[The Map Editor can only be accessed by administrators or higher-ranking team members. However, they are free to invite other team members to map. This is possible by right-clicking on the "Edit" button in the administration window. An invitation window now opens. 
	With the button "Currently editing players" it is possible for a higher ranking team member to close the map editor of other team members.]], self.m_Scrollable)
end

function MapEditorHelpGUI:destructor()
	GUIForm.destructor(self)
end