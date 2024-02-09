--------------------------------
-- KMUI.lua
-- Handles creation of the addon's user interface
-- Challenge Mode API: https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChallengeModeInfoDocumentation.lua
--------------------------------

--------------------------------
-- TODO's
--------------------------------
-- It seems that over time I moved some things (mostly frames) away from the namespace which causes code navigation
-- and debugging inconsistencies. This should be standardized to exclusively use this addon's namespace.
-- (i.e using core.MainInterface:PartyScreen instead of using _G["KeyMaster_Frame_Party"])
-- This, among other benefits, internalizes the references rather than searching the 
-- games unmanaged globals for functions and/or assets.

--------------------------------
-- Namespace
--------------------------------
local _, core = ...
core.MainInterface = {}
core.KeyMaster = {}

local MainInterface = core.MainInterface
--local UIWindow
--local MainPanel, HeaderFrame, ContentFrame
KeyMaster = core.KeyMaster -- todo: KeyMaster is global, not sure it should be and could be open to vulnerabilities.

--------------------------------
-- In-Game fonts:
-- FRIZQT__.ttf (the main UI font)
-- ARIALN.ttf (the normal number font)
-- skurri.ttf (the 'huge' number font)
-- MORPHEUS.ttf (Mail, Quest Log font)
-- RGB 0.0-1.0 color picker: https://rgbcolorpicker.com/0-1
--------------------------------

--------------------------------
-- UI Functions
--------------------------------
function MainInterface:Toggle()
    -- Shows/Hides the main interface - will only create the window once, otherwise it holds the window pointer
    local mainUI = MainPanel or MainInterface.CreateMainPanel()
    mainUI:SetShown(not mainUI:IsShown())
    --mainUI = nil -- possible bug fix from not releaseing variable?
end

-- sort tables by index because LUA doesn't!
-- order is optional
-- todo: this should probalby be moved to a different file
function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- F:\Games\World of Warcraft\_retail_\BlizzardInterfaceCode\Interface\SharedXML\SharedUIPanelTemplates.xml
-- Dynamic Buttons? https://www.wowinterface.com/forums/showthread.php?t=53126

-- Currently Unused
function KeyMaster:Initialize()
end

-- UI Event handler
-- use /eventtrace in game to see events as they happen (warning: it's a LOT!)
local function uiEventHandler(self, event, ...)
    local arg1 = select(1, ...);

     -- GROUP_LEFT, GROUP_JOINED
    -- Do something with event and arg1


    if event == "GROUP_LEFT" or "GROUP_JOINED" then -- this event needs refined. Fires on things of no signifigance to this addon.
        MainInterface:Refresh_PartyFrames()
        MyAddon:Transmit("PARTYCHANGED", "PARTY", nil)

        --print("-- Number of members: ", GetNumGroupMembers())
    end

    --core:Print("UI Event Handler Called.");
    for key, value in pairs(self) do
        --core:Print(tostringall(key), tostringall(value))
    end
    --core:Print("Event:",event)
    --core:Print("Args:", tostringall(...))
 end

 --------------------------------
-- Tab Functions
--------------------------------
local contentTableNames = {}
local function Tab_OnClick(self)
    PanelTemplates_SetTab(self:GetParent(), self:GetID())
	
    if(contentTableNames) then
        for key, value in pairs(contentTableNames) do
            _G[value]:Hide()
        end
    end
	self.content:Show();
    PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
end


local function SetTabs(frame, tabs)
    local tabCount = 0
    for _ in pairs(tabs) do tabCount = tabCount + 1 end
    --print("tabcount: ", tabCount)
    frame.numTabs = tabCount

    local contents = {}
    local frameName = frame:GetName()

    local count = 1
    for key, value in spairs(tabs) do
        local tab = CreateFrame("Button", frameName.."Tab"..count, frame, "TabSystemButtonTemplate") -- TabSystemButtonArtTemplate, MinimalTabTemplate
        tab:SetID(count)
        tab:SetText(tabs[key].name)
        tab:SetScript("OnClick", Tab_OnClick)
        table.insert(contentTableNames, "KeyMaster_"..tabs[key].window)
        tab.content = _G["KeyMaster_"..tabs[key].window]
        tab.content:Hide()
        
        table.insert(contents, tab.content)
        if (count == 1) then
            tab:SetPoint("TOPLEFT", MainPanel, "BOTTOMLEFT", 5, 3)
        else
            
            tab:SetPoint("TOPLEFT", frameName.."Tab"..(count - 1), "TOPRIGHT", 0, 0)
        end
        tab:SetWidth(100)
        count = count + 1
    end

    -- set first active tab
    -- todo: change this so it can be customized?
    Tab_OnClick(_G[frameName.."Tab1"])

    return unpack(contents)
end

--------------------------------
-- Create Header Content
--------------------------------

-- build main page header info of this weeks affixes
local function GetWeekInfo()
    local str = ""
    local i = 0
    local temp_frame, temp_header,temp_headertxt
    weekData = core.PlayerInfo:GetAffixes()
    for i=1, #weekData, i+1 do

        str = weekData[i].name
        temp_frame = CreateFrame("Frame", "KeyMaster_Affix"..tostringall(i), HeaderFrame)
        temp_frame:SetSize(40, 40)
        if (i == 1) then
            temp_frame:SetPoint("TOPLEFT", HeaderFrame, "TOPLEFT", 350, -30)
        else
            local a = i - 1
            temp_frame:SetPoint("TOPLEFT", "KeyMaster_Affix"..tostringall(a), "TOPRIGHT", 14, 0)
        end
        
        temp_frame.texture = temp_frame:CreateTexture()
        temp_frame.texture:SetAllPoints(temp_frame)
        temp_frame.texture:SetTexture(weekData[i].filedataid)
        myText = temp_frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
        Path, _, Flags = myText:GetFont()
        myText:SetFont(Path, 11, Flags)
        myText:SetPoint("CENTER", 0, -30)
        myText:SetTextColor(1,1,1)
        myText:SetText(str)

        -- create a title and set it to the first affix's frame
        if (i == 1) then
            temp_header = CreateFrame("Frame", "KeyMaster_Affix_Header", temp_frame)
            temp_header:SetSize(168, 20)
            temp_header:SetPoint("BOTTOMLEFT", temp_frame, "TOPLEFT", -4, 0)
            temp_headertxt = temp_header:CreateFontString(nil, "OVERLAY", "GameTooltipText")
            temp_headertxt:SetFont(Path, 14, Flags)
            temp_headertxt:SetPoint("LEFT", 0, 0)
            temp_headertxt:SetTextColor(1,1,1)
            temp_headertxt:SetText("This Week\'s Affixes:")
        end

    end
end

-- Create player rating header frame
local function CreateHeaderRating()
    
    HeaderFrame.ratingPanel = CreateFrame("Frame", "KeyMaster_RatingFrame", HeaderFrame)
    HeaderFrame.ratingPanel:SetWidth(300)
    HeaderFrame.ratingPanel:SetHeight(13)
    HeaderFrame.ratingPanel:SetPoint("TOPRIGHT", -2, -30)
    MythicRatingPreText = HeaderFrame.ratingPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = MythicRatingPreText:GetFont()
    MythicRatingPreText:SetFont(Path, 12, Flags)
    MythicRatingPreText:SetPoint("CENTER")
    MythicRatingPreText:SetText("|cff"..core.PlayerInfo:GetMyClassColor()..UnitName("player").."\'s|r Rating:")

    local myCurrentRating = core.PlayerInfo:GetCurrentRating()
    local myRatingColor = C_ChallengeMode.GetDungeonScoreRarityColor(myCurrentRating)

    MythicRatingText = HeaderFrame.ratingPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = MythicRatingText:GetFont()
    MythicRatingText:SetFont(Path, 30, Flags)
    MythicRatingText:SetPoint("CENTER", 0, -22)
    MythicRatingText:SetTextColor(myRatingColor.r, myRatingColor.g, myRatingColor.b)
    MythicRatingText:SetText(myCurrentRating)

    
    --[[ local myRatingColor = C_ChallengeMode.GetDungeonScoreRarityColor(myCurrentRating)
    HeaderFrame.ratingPanel = CreateFrame("Frame", "KeyMaster_RatingFrame", HeaderFrame.ratingPanel)
    HeaderFrame.ratingPanel:SetWidth(300)
    HeaderFrame.ratingPanel:SetHeight(32)
    HeaderFrame.ratingPanel:SetPoint("TOPRIGHT", -2, -50)
    MythicRatingText = HeaderFrame.ratingPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = MythicRatingText:GetFont()
    MythicRatingText:SetFont(Path, 30, Flags)
    MythicRatingText:SetPoint("CENTER")
    MythicRatingText:SetTextColor(myRatingColor.r, myRatingColor.g, myRatingColor.b)
    MythicRatingText:SetText(myCurrentRating) ]]
end

--------------------------------
-- Create Party Tab Frames  
--------------------------------

-- create a parent frame to contain the party member rows
local function Create_GroupFrame()
    local a, window, gfm, frameTitle, txtPlaceHolder, temp_frame
    frameTitle = "Party Information." -- set title

    -- relative parent frame of this frame
    -- todo: the next 2 lines may be reduntant?
    a = PartyScreen 
    window = _G["KeyMaster_Frame_Party"]

    gfm = 10 -- group frame margin

    if window then return window end -- if it already exists, don't make another one

    temp_frame =  CreateFrame("Frame", "KeyMaster_Frame_Party", a)
    temp_frame:SetSize(a:GetWidth()-(gfm*2), 400)
    temp_frame:SetPoint("TOPLEFT", a, "TOPLEFT", gfm, -40)

    txtPlaceHolder = temp_frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 20, Flags)
    txtPlaceHolder:SetPoint("TOPLEFT", 0, 30)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText(frameTitle)

    temp_frame.texture = temp_frame:CreateTexture()
    temp_frame.texture:SetAllPoints(temp_frame)
    temp_frame.texture:SetColorTexture(0.531, 0.531, 0.531, 0.3) -- temporary bg color 

    return temp_frame
end

-- create a new template frame for each party members if it doesn't exist
local function createPartyMemberFrame(frameName, parentFrame)
    local frameAnchor, frameHeight
    local mtb = 2 -- top and bottom margin of each frame in pixels

    -- DEBUG
    if (not parentFrame) then
        print("Can not find row reference \"Nil\" while trying to make "..frameName.."'s row.")
    end

    --print("Creating "..frameName.." and setting its parent to "..parentFrame:GetName()..".") -- debug

    if (frameName == "KM_PlayerRow1") then partyNumber = 1
    elseif (frameName == "KM_PlayerRow2") then partyNumber = 2
    elseif (frameName == "KM_PlayerRow3") then partyNumber = 3
    elseif (frameName == "KM_PlayerRow4") then partyNumber = 4
    elseif (frameName == "KM_PlayerRow5") then partyNumber = 5
    end


    local temp_RowFrame = CreateFrame("Frame", frameName, parentFrame)
    temp_RowFrame:ClearAllPoints()

    --temp_RowFrame:SetPoint(frameAnchor)
    if (frameName == "KM_PlayerRow1") then 
        --frameAnchor = "TOPLEFT", parentFrame, "TOPLEFT", 0, -20
        temp_RowFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -2)

         -- get the frame's group container and set this row frame height to 1/5th the group container height minus margins
        frameHeight = (parentFrame:GetHeight()/5) - (mtb*2)

    else
        --frameAnchor = "TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -2
        temp_RowFrame:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -4)

        -- get the frame parent and set this row frame height the parent's height
        frameHeight = parentFrame:GetHeight()

    end

    temp_RowFrame:SetSize(parentFrame:GetWidth(), frameHeight)
    temp_RowFrame.texture = temp_RowFrame:CreateTexture()
    temp_RowFrame.texture:SetAllPoints(temp_RowFrame)
    temp_RowFrame.texture:SetColorTexture(0.531, 0.531, 0.531, 0.3) -- todo: temporary bg color 


    local temp_frame = CreateFrame("Frame", "KM_PortraitFrame"..partyNumber, _G["KM_PlayerRow"..partyNumber])
    temp_frame:SetSize(parentFrame:GetWidth()+(temp_RowFrame:GetHeight()/2), temp_RowFrame:GetHeight())
    temp_frame:ClearAllPoints()
    temp_frame:SetPoint("RIGHT", temp_frame:GetParent(), "RIGHT", 0, 0)

    local img1 = temp_frame:CreateTexture("KM_Portrait"..partyNumber, "BACKGROUND")
    img1:SetHeight(temp_RowFrame:GetHeight())
    img1:SetWidth(temp_RowFrame:GetHeight())
    img1:ClearAllPoints()
    img1:SetPoint("LEFT", 0, 0)

    local img2 = temp_frame:CreateTexture("KM_PortraitFrame"..partyNumber, "OVERLAY")
    img2:SetHeight(temp_RowFrame:GetHeight())
    img2:SetWidth(temp_RowFrame:GetHeight())
    img2:SetTexture("Interface\\AddOns\\KeyMaster\\Imgs\\portrait_frame",false)
    img2:ClearAllPoints()
    img2:SetPoint("LEFT", 0, 0)
    

    --[[ local mdl1 = CreateFrame("PlayerModel", "KM_GroupModelFrame"..partyNumber, _G["KM_PortraitFrame"..partyNumber])
    mdl1:SetHeight(temp_RowFrame:GetHeight())
    mdl1:SetWidth(temp_RowFrame:GetHeight())
    mdl1:ClearAllPoints()
    mdl1:SetPoint("LEFT", 0, 0)
    mdl1:SetPortraitZoom(1) ]]
   --[[  mdl1:SetCustomCamera(1) 
    mdl1:SetCameraPosition(2.8, -1, 0.4)
    mdl1:RefreshCamera()
    mdl1:SetCustomCamera(1) -- Yes, it needs to be  here twice ]]

    -- todo: take the line below out of here and put it in the party frame refresh function?
    -- SetPortraitTexture(img1, "player")

    -- Set a default faux portriat image
    --img1:SetTexture("Interface\\AddOns\\KeyMaster\\Imgs\\portrait_default", false)

    --print(frameName.." created.") -- debug

    return temp_RowFrame
end

-- creates a party member rows lookup table (will create the frames if they don't yet exist)
local function GetPartyMembersFrameStack()
    local p1, p2, p3, p4, p5
    p1 = _G["KM_PlayerRow1"] or createPartyMemberFrame("KM_PlayerRow1", _G["KeyMaster_Frame_Party"])
    p2 = _G["KM_PlayerRow2"] or createPartyMemberFrame("KM_PlayerRow2", p1)
    p3 = _G["KM_PlayerRow3"] or createPartyMemberFrame("KM_PlayerRow3", p2)
    p4 = _G["KM_PlayerRow4"] or createPartyMemberFrame("KM_PlayerRow4", p3)
    p5 = _G["KM_PlayerRow5"] or createPartyMemberFrame("KM_PlayerRow5", p4)

    local frameStack = {
        p1Frame = p1,
        p2Frame = p2,
        p3Frame = p3,
        p4Frame = p4,
        p5Frame = p5
    }

    --[[ p2:SetPoint("TOPLEFT", "KM_PlayerRow1", "BOTTOMLEFT", 0, 0)
    p3:SetPoint("TOPLEFT", "KM_PlayerRow2", "BOTTOMLEFT", 0, 0)
    p4:SetPoint("TOPLEFT", "KM_PlayerRow3", "BOTTOMLEFT", 0, 0)
    p5:SetPoint("TOPLEFT", "KM_PlayerRow4", "BOTTOMLEFT", 0, 0) ]]

return frameStack
end

-- Unused
local function Create_PartyMemberRow(partyNumber, ...)
 --[[local parentFrame, groupSize, frameAnchor, temp_RowFrame, rowParent, rowOwner
    parentFrame = _G[parentFrame]
    groupSize = GetNumGroupMembers()

    -- https://wowwiki-archive.fandom.com/wiki/Events/Party
    -- GetNumPartyMembers() it will return 0, 1, 2, and 3. First event returing zero, 2nd event returning 1, etc etc.
    -- todo: determine if 0 means player 0 - 4 or if 0 means not in group and when in group you get 1 - 5?

    if (groupSize > 5) then print("Group too large - Create_PartyMemberRows") return end -- todo: close (if open) and disable party tab if in raid?
    rowOwner = "party"..partyNumber -- set the owner of the row we are creating/updating

    -- Get any existing party row frame or create a new one
    --p1RowFrame = _G["PlayerRow1"] or createPartyMemberFrame(rowOwner, "PlayerRow"..partyNumber, parentFrame)

    if (GetNumGroupMembers() == 0 ) then -- row owner not in group
        rowOwner = "player"
    else
        rowOwner = "Party1" -- todo: sort out logic? 
    end

    if (not partyNumber and partyNumber < 1 and partyNumber > 5) then
        print("Party number not set 1-5. FIX ME")
        return 
    end
    if (not parentFrame) then
        print("Parent target frame in invalid for Create_PartyMemberRows")
        return 
    end ]]
end 

 -- this needs to be called when the party status/members change
 -- ... passed in for future development
 -- todo: need to check if a party member's model is in memory.. if so, display it, otherwise, show their staic portrait?
 --    this also applies for disconnects!
function MainInterface:Refresh_PartyFrames(...)
    local defPortrait = "Interface\\AddOns\\KeyMaster\\Imgs\\portrait_default"
    local xPortrait = "Interface\\AddOns\\KeyMaster\\Imgs\\portrait_x"
    local fPortrait = "Interface\\AddOns\\KeyMaster\\Imgs\\portrait_frame"
    local numMembers = GetNumGroupMembers()
    local mf1, mf2, mf3, mf4

    -- set the client's portrait
    SetPortraitTexture(_G["KM_Portrait1"], "player")

    -- todo: frame naming here is counter-intuitive. Should update frame names to be easier to associate.
    -- KM_Portrait2 and KM_PlayerRow2 is party1 because there isn't a party0 (the client) or a party5.
    if (numMembers >= 2) then
       -- if ("party1") then
            SetPortraitTexture(_G["KM_Portrait2"], "party1")
       -- else
        _G["KM_PlayerRow2"]:Show()
        -- update data here for party1

       -- _G["KM_Portrait1"]:SetTexture(xPortrait, false)
        --SetPortraitTexture(_G["KM_Portrait1"], nil)
    else
        _G["KM_Portrait2"]:SetTexture(xPortrait, false)
        --_G["KM_PlayerRow2"]:Hide()
    end

    if (numMembers >= 3) then 
       -- mf2 = _G["KM_GroupModelFrame3"]
        --if ("party2") then
            SetPortraitTexture(_G["KM_Portrait3"], "party2")
           -- mf2:SetUnit("party2")
            --mf2:RefreshCamera()
        --else
        --SetPortraitTexture(_G["KM_Portrait3"], "party2")
           -- mf2:SetDisplayInfo(22447)
        --end

        --_G["KM_GroupModelFrame3"]:SetUnit("party2")
        _G["KM_PlayerRow3"]:Show()
        -- update data here for party2

       -- _G["KM_Portrait1"]:SetTexture(xPortrait, false)
        --SetPortraitTexture(_G["KM_Portrait1"], nil)
    else
        _G["KM_Portrait3"]:SetTexture(xPortrait, false)
        --_G["KM_PlayerRow3"]:Hide()
    end

    if (numMembers >= 4) then
       -- mf3 = _G["KM_GroupModelFrame4"]
        --if ("party3") then
            --mf3:SetUnit("party3")
            --mf3:RefreshCamera()
            SetPortraitTexture(_G["KM_Portrait4"], "party3")
        --else
        --SetPortraitTexture(_G["KM_Portrait4"], "party3")
            --mf3:SetDisplayInfo(22447)
       -- end

        --_G["KM_GroupModelFrame4"]:SetUnit("party3")
        _G["KM_PlayerRow4"]:Show()
        -- update data here for party3

       -- _G["KM_Portrait1"]:SetTexture(xPortrait, false)
        --SetPortraitTexture(_G["KM_Portrait1"], nil)
    else
        _G["KM_Portrait4"]:SetTexture(xPortrait, false)
        --_G["KM_PlayerRow4"]:Hide()
    end

    if (numMembers == 5) then 
        --if (UnitIsVisible("party4")) then
            SetPortraitTexture(_G["KM_Portrait5"], "party4")
       -- else
        --SetPortraitTexture(_G["KM_Portrait5"], "party4")
       -- end

        --_G["KM_GroupModelFrame5"]:SetUnit("party4")
        _G["KM_PlayerRow5"]:Show()
        -- update data here for party4

       -- _G["KM_Portrait1"]:SetTexture(xPortrait, false)
        --SetPortraitTexture(_G["KM_Portrait1"], nil)
    else
        _G["KM_Portrait5"]:SetTexture(xPortrait, false)
        --_G["KM_PlayerRow5"]:Hide()
    end


   --[[  SetPortraitTexture(_G["KM_Portrait2"], "party1")
    SetPortraitTexture(_G["KM_Portrait2"], nil)
    SetPortraitTexture(_G["KM_Portrait1"], "party2")
    SetPortraitTexture(_G["KM_Portrait1"], "party3")
    SetPortraitTexture(_G["KM_Portrait1"], "party4") ]]
end

--------------------------------
-- Create Regions
--------------------------------
-- Setup main UI information regions
-- I've seperated this info to build up to a template system
local function GetFrameRegions(myRegion)
    local p, w, h, mh, mw, hh, mtb, mlr
    local r = myRegion
    if (not r) then return end

    mh = MainPanel:GetHeight()
    mw = MainPanel:GetWidth()

    -- desired region heights and margins in pixels.
    -- todo: Needs pulled from saved variables or some other file instead of hard-coded.
    hh = 100 -- header height
    mtb = 4 -- top/bottom margin
    mlr = 4 -- left/right margin

    if (r == "header") then
    -- p = points, w = width, h = height, mtb = margin top and bottom, mlr = margin left and right
        myRegionInfo = {
            w = mw - (mlr*2),
            h = hh
    } 
    elseif (r == "content") then
        myRegionInfo = {
            w = mw - (mlr*2),
            h = mh - hh - (mtb*3)
        }
    else return
    end

    return myRegionInfo, mlr, mtb
end

-- Setup header region
function MainInterface:Headerframe()
    local fr, mlr, mtb = GetFrameRegions("header")
    HeaderFrame = CreateFrame("Frame", "KeyMaster_HeaderRegion", MainPanel);
    HeaderFrame:SetSize(fr.w, fr.h)
    HeaderFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", mlr, -(mtb))
    HeaderFrame.texture = HeaderFrame:CreateTexture()
    HeaderFrame.texture:SetAllPoints(HeaderFrame)
    HeaderFrame.texture:SetColorTexture(0.231, 0.231, 0.231, 1) -- temporary bg color
    return HeaderFrame
end

-- Setup content region
function MainInterface:ContentFrame()
    local fr, mlr, mtb = GetFrameRegions("content")
    ContentFrame = CreateFrame("Frame", "KeyMaster_ContentRegion", MainPanel);
    ContentFrame:SetSize(fr.w, fr.h)
    ContentFrame:SetPoint("TOPLEFT", MainPanel, "TOPLEFT", mtb, -(HeaderFrame:GetHeight() + (mtb*2)))
    ContentFrame.texture = ContentFrame:CreateTexture()
    ContentFrame.texture:SetAllPoints(ContentFrame)
    --ContentFrame.texture:SetTexture("Interface\\AddOns\\KeyMaster\\Imgs\\WHITE8X8")
    ContentFrame.texture:SetColorTexture(0, 0, 0, 1)

    return ContentFrame
end

--------------------------------
-- Create Content Frames
--------------------------------
-- Header content
function MainInterface:HeaderScreen()
    local txtPlaceHolder
    HeaderScreen = CreateFrame("Frame", "KeyMaster_HeaderScreen", HeaderFrame);
    HeaderScreen:SetSize(HeaderFrame:GetWidth(), HeaderFrame:GetHeight())
    HeaderScreen:SetPoint("TOPLEFT", HeaderFrame, "TOPLEFT", 0, 0)
    --[[ HeaderScreen.texture = HeaderScreen:CreateTexture()
    HeaderScreen.texture:SetAllPoints(HeaderScreen)
    HeaderScreen.texture:SetTexture("Interface\\AddOns\\KeyMaster\\Imgs\\WHITE8X8")
    HeaderScreen.texture:SetColorTexture(0.231, 0.231, 0.231, 1) ]]

    txtPlaceHolder = HeaderScreen:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 30, Flags)
    txtPlaceHolder:SetPoint("BOTTOMLEFT", 10, 10)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText("Key Master")

    VersionText = HeaderScreen:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    VersionText:SetPoint("TOPRIGHT", HeaderFrame, "TOPRIGHT", -24, -2)
    VersionText:SetText(KM_VERSION)

    -- Create header content
    CreateHeaderRating()
    GetWeekInfo()

    return HeaderScreen
end

-- Setup tab strip frame (Not used)
function MainInterface:TabStrip()
end

function MainInterface:MainScreen()
    local txtPlaceHolder, headerText, Path, Flags
    MainScreen = CreateFrame("Frame", "KeyMaster_MainScreen", ContentFrame)
    MainScreen:SetSize(ContentFrame:GetWidth(), ContentFrame:GetHeight())
    MainScreen:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
    --[[ MainScreen.texture = MainScreen:CreateTexture()
    MainScreen.texture:SetAllPoints(MainScreen)
    MainScreen.texture:SetTexture("Interface\\AddOns\\KeyMaster\\Imgs\\WHITE8X8") 
    MainScreen.texture:SetColorTexture(0.231, 0.231, 0.231, 1) ]]

    --[[ MainScreen.titleFrame = CreateFrame("Frame", "KeyMaster_MS_titelFrame", MainScreen)
    MainScreen.titleFrame:SetSize(MainScreen:GetWidth(), 40)
    MainScreen.titleFrame:SetPoint("TOPLEFT", MainScreen, "TOPLEFT", 12, 20) ]]


    txtPlaceHolder = MainScreen:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 30, Flags)
    txtPlaceHolder:SetPoint("BOTTOMLEFT", 50, 50)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText("Main Screen")
    return MainScreen
end

function MainInterface:ConfigScreen()
    local txtPlaceHolder
    ConfigScreen = CreateFrame("Frame", "KeyMaster_ConfigScreen", ContentFrame);
    ConfigScreen:SetSize(ContentFrame:GetWidth(), ContentFrame:GetHeight())
    ConfigScreen:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
   --[[  ConfigScreen:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
        edgeFile="", 
        tile = false, 
        tileSize = 0, 
        edgeSize = 0, 
        insets = {left = 0, right = 0, top = 0, bottom = 0}})
    ConfigScreen:SetBackdropColor(120,120,120,1); -- color for testing ]]
    txtPlaceHolder = ConfigScreen:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 30, Flags)
    txtPlaceHolder:SetPoint("BOTTOMLEFT", 50, 50)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText("Configuration Screen")
    return ConfigScreen
end

function MainInterface:AboutScreen()
    local txtPlaceHolder
    AboutScreen = CreateFrame("Frame", "KeyMaster_AboutScreen", ContentFrame);
    AboutScreen:SetSize(ContentFrame:GetWidth(), ContentFrame:GetHeight())
    AboutScreen:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
    --[[ AboutScreen:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
        edgeFile="", 
        tile = false, 
        tileSize = 0, 
        edgeSize = 0, 
        insets = {left = 0, right = 0, top = 0, bottom = 0}})
    AboutScreen:SetBackdropColor(160,160,160,1); -- color for testing ]]
    txtPlaceHolder = AboutScreen:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 30, Flags)
    txtPlaceHolder:SetPoint("BOTTOMLEFT", 50, 50)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText("About Screen")
    return AboutScreen
end

function MainInterface:PartyScreen()
    local txtPlaceHolder
    PartyScreen = CreateFrame("Frame", "KeyMaster_PartyScreen", ContentFrame);
    PartyScreen:SetSize(ContentFrame:GetWidth(), ContentFrame:GetHeight())
    PartyScreen:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
    --[[ PartyScreen:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
        edgeFile="", 
        tile = false, 
        tileSize = 0, 
        edgeSize = 0, 
        insets = {left = 0, right = 0, top = 0, bottom = 0}})
    PartyScreen:SetBackdropColor(160,160,160,1); -- color for testing ]]
    --[[ txtPlaceHolder = PartyScreen:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 30, Flags)
    txtPlaceHolder:SetPoint("BOTTOMLEFT", 50, 50)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText("Party Screen") ]]

    --[[ PartyScreen.texture = PartyScreen:CreateTexture()
    PartyScreen.texture:SetAllPoints(PartyScreen)
    PartyScreen.texture:SetColorTexture(0.531, 0.531, 0.531, 1) -- temporary bg color ]]

    txtPlaceHolder = PartyScreen:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 30, Flags)
    txtPlaceHolder:SetPoint("BOTTOMLEFT", 50, 50)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText("Group Screen")

    PartyScreen:RegisterEvent("GROUP_ROSTER_UPDATE")
    PartyScreen:SetScript("OnEvent", uiEventHandler)

    return PartyScreen
end

function MainInterface:JournalScreen()
    local txtPlaceHolder
    JournalScreen = CreateFrame("Frame", "KeyMaster_JournalScreen", ContentFrame);
    JournalScreen:SetSize(ContentFrame:GetWidth(), ContentFrame:GetHeight())
    JournalScreen:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
    txtPlaceHolder = JournalScreen:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local Path, _, Flags = txtPlaceHolder:GetFont()
    txtPlaceHolder:SetFont(Path, 30, Flags)
    txtPlaceHolder:SetPoint("BOTTOMLEFT", 50, 50)
    txtPlaceHolder:SetTextColor(1, 1, 1)
    txtPlaceHolder:SetText("Journal Screen")

    return JournalScreen
end

--------------------------------
-- Create Main UI Frame and shared assets
--------------------------------
function MainInterface:CreateMainPanel()
    MainPanel = CreateFrame("Frame", "KeyMaster_MainPanel", UIParent, "KeyMasterFrame");
    MainPanel:ClearAllPoints(); -- Fixes SetPoint bug thus far.
    MainPanel:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
    MainPanel:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = false, 
        tileSize = 0, 
        edgeSize = 16, 
        insets = {left = 4, right = 4, top = 4, bottom = 4}})

    MainPanel:SetBackdropColor(0,0,0,1);
    

    --[[ -- Was playing with in-game models. Maybe later, this doesn't work how I want
    MainPanel.model = CreateFrame("PlayerModel", "myModelFrame", "KeyMaster_MainPanel")
    MainPanel.model:SetSize(600, 800)
    MainPanel.model:SetPoint("CENTER", "KeyMaster_MainPanel", "CENTER")
    MainPanel.model:SetUnit("player")
    MainPanel.model:SetPosition(0, 0, -0.75)
    MainPanel.model:SetCustomCamera(1) -- Yes, it needs to be  here twice
    MainPanel.model:SetCameraPosition(2.8, -1, 0.4)
    MainPanel.model:RefreshCamera()
    MainPanel.model:SetCustomCamera(1) -- Yes, it needs to be  here twice ]]

    MainPanel.closeBtn = CreateFrame("Button", "CloseButton", MainPanel, "UIPanelCloseButton")
    MainPanel.closeBtn:SetPoint("TOPRIGHT")
    MainPanel.closeBtn:SetSize(20, 20)
    MainPanel.closeBtn:SetNormalFontObject("GameFontNormalLarge")
    MainPanel.closeBtn:SetHighlightFontObject("GameFontHighlightLarge")
    MainPanel.closeBtn:SetScript("OnClick", core.MainInterface.Toggle)

   --MainPanel:SetScript("OnEvent", uiEventHandler);
   --MainPanel:SetScript("OnDragStart", function(self) self:StartMoving() end);
   --MainPanel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end);

   -- Create main content regions and show them
    HeaderFrame = MainInterface.Headerframe()
    HeaderFrame:Show()
    ContentFrame = MainInterface.ContentFrame()
    ContentFrame:Show()

    -- Create content screens and show/hide them
    -- the way this works probaly needs changed so any tab could be the first tab displayed
    headerFrameContent = MainInterface:HeaderScreen()
    headerFrameContent:Show();
    mainFrameContent = MainInterface:MainScreen()
    mainFrameContent:Hide()
    journalFrameContent = MainInterface:JournalScreen()
    journalFrameContent:Hide()
    partyFrameContent = MainInterface:PartyScreen()
    partyFrameContent:Hide()
    configFrameContent = MainInterface:ConfigScreen()
    configFrameContent:Hide()
    aboutFrameContent = MainInterface:AboutScreen()
    aboutFrameContent:Hide()

    -- Party tab content
    Create_GroupFrame()
    tblPartyRows = GetPartyMembersFrameStack()
    MainInterface:Refresh_PartyFrames()
 
    -- Create tabs
    -- name = tab text, window = the frame's name suffix (i.e. KeyMaster_BigScreen  would be "BigScreen")
    local myTabs = {
        [0] = {
            ["name"] = "Main",
            ["window"] = "MainScreen"
        },
        [1] = {
            ["name"] = "Party",
            ["window"] = "PartyScreen"
        },
        [2] = {
            ["name"] = "Journal",
            ["window"] = "JournalScreen"
        },
        [3] = {
            ["name"] = "Config",
            ["window"] = "ConfigScreen"
        },
        [4] = {
            ["name"] = "About",
            ["window"] = "AboutScreen"
        }
    }

    -- Create the tabs (content region, Tab table)
    SetTabs(ContentFrame, myTabs)

   --[[ mainFrameContent = MainInterface:MainScreen()
    mainFrameContent:Show()
    confgFrameContent.content = MainInterface:ConfigScreen()
    confgFrameContent.content:Hide()
    aboutFrameContent.content = MainInterface:AboutScreen()
    aboutFrameContent.content:Hide()

    -- load child windows
    --HeaderFrame = MainInterface:Headerframe()
    --HeaderFrame:Show()
    --ContentFrame = MainInterface.ContentFrame()
    --ContentFrame:Show()
   
    --[ MainScreen = MainInterface.MainScreen()
    --MainScreen:Show()
    
    --ConfigScreen = MainInterface.ConfigScreen()
    --ConfigScreen:Hide()
    
    --AboutScreen = MainInterface.AboutScreen()
    --AboutScreen:Hide()]]

    MainPanel:Hide()
    return MainPanel
end


--------------------------------
-- Buttton_OnClick actions (template)
--------------------------------
--[[ function KeyMaster:Button_OnClick(button)
    local operation = button:GetName():match("KeyMasterButton_(.+)")
	if operation == "New" then
		KeyMaster:Button_New(button)
	elseif operation == "Open" then
		KeyMaster:Button_Open(button)
	elseif operation == "Save" then
		KeyMaster:Button_Save(button)
	elseif operation == "Undo" then
		KeyMaster:Button_Undo(button)
	elseif operation == "Redo" then
		KeyMaster:Button_Redo(button)
	elseif operation == "Delete" then
		KeyMaster:Button_Delete(button)
	elseif operation == "Lock" then
		KeyMaster:Button_Lock(button)
	elseif operation == "Unlock" then
		KeyMaster:Button_Unlock(button)
	elseif operation == "Previous" then
		KeyMaster:Button_Previous(button)
	elseif operation == "Next" then
		KeyMaster:Button_Next(button)
	elseif operation == "Run" then
		KeyMaster:Button_Run(button)
    elseif operation == "Config" then
        KeyMaster:Button_Config(button)
	elseif operation == "Close" then
		KeyMaster:Button_Close(button)
	end
end ]]

-- Frame asset event handlers


function KeyMaster:Button_OnEnter(frame)
end
function KeyMaster:Button_OnLeave(frame)
end
function KeyMaster:Button_Close(frame)
    core.MainInterface.Toggle()
end