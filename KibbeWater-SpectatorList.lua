-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Speclist", "cEnableSpeclistPublic", true)
Menu.Checkbox("Lock Position", "cSpeclistLockPublic", false)
Menu.Checkbox("Enable RGB", "cEnableSpeclistRGBPublic", true)
Menu.ColorPicker("Speclist Color", "cSpeclistColorPublic", 255, 255, 255, 255)
Menu.Combo( "", "cSpecDesignPublic", { "Sown" }, 0)
Menu.SliderInt("Size", "cPosSizePublic", 1, 50, "", 27)

--idk is essential upp here
function Split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

--Setup Fonts
URLDownloadToFile("https://cdn.discordapp.com/attachments/655694082525364254/700274099775078410/Sunflower.ttf", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf")
Render.LoadFont("sunflowerrr", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf", 30)

--Debug
local fakeNames = {} --This is permanent now? ok

--Offsets
local Health_Offset = Hack.GetOffset("DT_BasePlayer", "m_iHealth");
local obsModeOffset = Hack.GetOffset("DT_BasePlayer", "m_iObserverMode")
local obsTargetOffset = Hack.GetOffset("DT_BasePlayer", "m_hObserverTarget")

--Global Vars
local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
local nextAutosave = 0

--Settings
local sizeX = 175
local sizeY = 27

local posX = 0
local posY = 200

local opacity = 255

local secBeforeAutoSave = 15

local Dragging = "f"
local OldDragging = "f"
local DraggingOffset = Vector.new(0, 0, 0)

--Load up save
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater")
local loadData = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\data.s")
local ParsedData = Split(loadData, ",")
posX = tonumber(ParsedData[1])
posY = tonumber(ParsedData[2])

--RGB
local Type = { 0, 0, 0, 0 }
local R = { 255, 0, 0, 0 }
local G = { 0, 255, 0, 0 }
local B = { 0, 0, 255, 0 }

--Draw Spectator List
function Paint()
    if not Utils.IsInGame() or not Menu.GetBool("cEnableSpeclistPublic") then return end
    if Utils.IsLocalAlive() then
        BuildSpecList(IEngine.GetLocalPlayer())
    else
        BuildSpecList(FindTarget())
    end

    --Set Size 
    sizeY = Menu.GetInt("cPosSizePublic")
    sizeX = sizeY * 6.481481481481481

    if Menu.GetInt("cSpecDesignPublic") == 0 then --Sown

        --RGB first cuz fucking priority rendering ZZZ (extra's rainbow gay pride rgb lua (too lazy to do calculations (I HATE DOING RGB)))
        local S = 3

        S,Type[1], R[1], G[1], B[1] = Rainbow(3,Type[1], R[1], G[1], B[1])
        S,Type[4], R[4], G[4], B[4] = Rainbow(3,Type[4], R[4], G[4], B[4])
             
        if Menu.GetBool("cEnableSpeclistRGBPublic") then
            Render.RectFilledMultiColor(
                posX - 2,
                posY - 2,
                (posX + sizeX) + 2,
                (posY + sizeY) + 2,
                Color.new(R[4], G[4], B[4], 255),
                Color.new(R[1], G[1], B[1], 255),
                Color.new(R[1], G[1], B[1], 255),
                Color.new(R[4], G[4], B[4], 255)
            )
        else
            Render.RectFilled(posX - 2, posY - 2, (posX + sizeX) + 2, (posY + sizeY) + 2, Menu.GetColor("cSpeclistColorPublic"))
        end

        --Render Main Box
        Render.RectFilled(posX, posY, posX + sizeX, posY + sizeY, Color.new(0,0,0,255), 0)

        --Render Speclist Text
        local textYSize = Render.CalcTextSize("Spectator List", sizeY * 0.6666666666666667, "sunflowerrr").y / 2
        Render.Text("Spectator List", posX + (sizeX / 2), (posY + (sizeY / 2)) - textYSize, sizeY * 0.6666666666666667, Color.new(255,255,255,255), true, true, "sunflowerrr")

        --Dragging System
        local cursor = InputSys.GetCursorPos()

        --Check if box is able to be dragged
        if cursor.x >= posX and cursor.x <= posX + sizeX then
            if cursor.y >= posY and cursor.y <= posY + sizeY then
                if InputSys.IsKeyDown(1) and not Menu.GetBool("cSpeclistLockPublic") then
                    Dragging = "t" --supposed to be a bool but I was way to fucking lazy to change it from my old string system (I did parsing be fucking proud atleast)
                else
                    Dragging = "f"
                end
            else
                Dragging = "f"
            end
        else
            Dragging = "f"
        end

        --Render name's BG
        local extensionSizeX = sizeX
        local extensionSizeY = 0
        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 2
            extensionSizeY = extensionSizeY + Render.CalcTextSize(fakeNames[i], 15, "sunflowerrr").y
        end
        if #fakeNames ~= 0 then
            extensionSizeY = extensionSizeY + 2
        end
        if Menu.GetBool("cEnableSpeclistRGBPublic") then
            Render.RectFilledMultiColor(
                posX + 1,
                (posY + sizeY),
                (posX + sizeX) - 1,
                ((posY + sizeY) + extensionSizeY) + 4,
                Color.new(R[4], G[4], B[4], 255),
                Color.new(R[1], G[1], B[1], 255),
                Color.new(R[1], G[1], B[1], 255),
                Color.new(R[4], G[4], B[4], 255)
            )
        else
            Render.RectFilled(posX + 1, (posY + sizeY), (posX + sizeX) - 1, ((posY + sizeY) + extensionSizeY) + 4, Menu.GetColor("cSpeclistColorPublic"))
        end
        Render.RectFilledMultiColor(posX + 3, posY + sizeY, (posX + extensionSizeX) - 3, (((posY + sizeY) + 1) + extensionSizeY) + 1, Color.new(5,5,5,255), Color.new(5,5,5,255), Color.new(35,35,35,255), Color.new(35,35,35,255))
        --Render.RectFilled(posX + 3, (posY + sizeY), (posX + extensionSizeX) - 3, (((posY + sizeY) + 1) + extensionSizeY) + 1, Color.new(13,13,13,255), 0)

        --Render Names
        extensionSizeY = 0
        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 2
            Render.Text(fakeNames[i], posX + 6, ((posY + sizeY)) + extensionSizeY, sizeY * 0.6296296296296296, Color.new(255,255,255,255), false, true, "sunflowerrr")
            extensionSizeY = extensionSizeY + Render.CalcTextSize(fakeNames[i], sizeY * 0.6296296296296296, "sunflowerrr").y
        end

        --Coderman optimize b4 release
        if nextAutosave <= IGlobalVars.realtime then
            FileSys.SaveTextToFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\data.s", posX .. "," .. posY)
            nextAutosave = IGlobalVars.realtime + secBeforeAutoSave
        end
    end
end
Hack.RegisterCallback("PaintTraverse", Paint)

function FrameStageNotify(stage)
    if stage ~= 5 then return end

    if Dragging ~= "f" then
        local cursor = InputSys.GetCursorPos()
        if OldDragging == "f" then
            DraggingOffset = Vector.new(posX - cursor.x, posY - cursor.y, 0)
        end
        posX = cursor.x + DraggingOffset.x
        posY = cursor.y + DraggingOffset.y
    else
        DraggingOffset = Vector.new(0, 0, 0)
    end
    OldDragging = Dragging
end
Hack.RegisterCallback("FrameStageNotify", FrameStageNotify)

function Split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

--Pasting section below
function Rainbow(Strong,Type, r, g, b)
	local NewStrong = Strong * (120.0 / Utils:GetFps())

	if (Type == 0) then
		if (g < 255) then
			if (g + NewStrong > 255) then
				g = 255
			else
				g = g + NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 1) then
		if (r > 0) then
			if (r - NewStrong < 0) then
				r = 0
			else
				r = r - NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 2) then
		if (b < 255) then
			if (b + NewStrong > 255) then
				b = 255
			else
				b = b + NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 3) then
		if (g > 0) then
			if (g - NewStrong < 0) then
				g = 0
			else
				g = g - NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 4) then
		if (r < 255) then
			if (r + NewStrong > 255) then
				r = 255
			else
				r = r + NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 5) then
		if (b > 0) then
			if (b - NewStrong < 0) then
				b = 0
			else
				b = b - NewStrong
			end
		else
			Type = 0
		end
	end

	return Strong,Type, r, g, b
end

--Srry for pasting but I had to, worked ages to try make this
function BuildSpecList(TargetIndex)
    fakeNames = {}

    if (TargetIndex == -1 or Globals.MenuOpened()) then return end

    for i = 1, 64 do
        if (i == IEngine.GetLocalPlayer()) then goto continue end

 
        -- Player Looking
        local Player = IEntityList.GetPlayer(i) 
        if (not Player or Player:GetClassId() ~= 40 or Player:IsAlive() or Player:IsDormant()) then goto continue end

        local PlayerInfo = CPlayerInfo.new()
        if (not Player:GetPlayerInfo(PlayerInfo)) then goto continue end
    
        local PlayerName = PlayerInfo.szName
        if (PlayerName == "GOTV") then goto continue end
        

        -- Target Playing
        local TargetObserver = Player:GetPropInt(obsTargetOffset) -- int bc need adress
        if (TargetObserver <= 0) then goto continue end

        local TargetHandle = IEntityList.GetClientEntityFromHandleA(TargetObserver) 
        local Target = IEntityList.ToPlayer(TargetHandle)
        if (not Target or Target:GetClassId() ~= 40 or not Target:IsAlive() or Target:IsDormant()) then goto continue end


        -- Build
        if (TargetIndex ~= Target:GetIndex()) then goto continue end
        local PlayerObserverMode = Player:GetPropInt(obsModeOffset)
  
        if (PlayerObserverMode == 4 or PlayerObserverMode == 5) then
            table.insert(fakeNames, PlayerInfo.szName)
        end


        ::continue::
    end
end

function FindTarget()
    -- Local Looking
    local Player = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if (not Player or Player:GetClassId() ~= 40 or Player:IsAlive() or Player:IsDormant()) then return -1 end


    -- Target Playing
    local TargetObserver = Player:GetPropInt(obsTargetOffset) -- int bc need adress
    if (TargetObserver <= 0) then return -1 end

    local TargetHandle = IEntityList.GetClientEntityFromHandleA(TargetObserver) 
    local Target = IEntityList.ToPlayer(TargetHandle) 
    if (not Target or Target:GetClassId() ~= 40 or not Target:IsAlive() or Target:IsDormant()) then return -1 end

    
    return Target:GetIndex()
end
