-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Teamdamage List", "cEnableTDamageList", true)
Menu.Checkbox("Lock Position", "cTDamageLock", false)
Menu.Spacing()
Menu.Combo( "Colors", "cTDamageColorScheme", { "Default", "Light", "RGB" }, 0)
Menu.Spacing()
Menu.Combo( "Design", "cTDamageDesign", { "Default", "Simple" }, 0)
Menu.Spacing()
Menu.Combo( "Format", "cTDamageFormat", { "{name} K:{kills} D:{deaths}", "{name}: {damage} ({kills})" }, 0)
Menu.Separator()
Menu.Text("INCASE TEAM DAMAGE LIST DOESN'T APPEAR")
Menu.Checkbox("Reset Position", "cTDamageListReset", false)

URLDownloadToFile("https://cdn.discordapp.com/attachments/655694082525364254/700274099775078410/Sunflower.ttf", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf")
Render.LoadFont("TDamageFont", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf", 30)

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

--Data handling for dragging
local Dragging = "f"
local OldDragging = "f"
local DraggingOffset = Vector.new(0, 0, 0)


--Global Vars
local nextAutosave = 0
local first = true

--Settings
local sizeX = 175
local sizeY = 16

local posX = 0
local posY = 200 

local secBeforeAutoSave = 15

--Cool Shit
local kills = {}
local damage = {}

FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater")
local loadData = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\dataTDamage.s")
local ParsedData = Split(loadData, ",")
posX = tonumber(ParsedData[1])
posY = tonumber(ParsedData[2])

--Setup lua
function Setup()
    for i = 1, 64 do
        kills[i] = 0
        damage[i] = 0
    end
end

--RGB
local Type = { 0, 0, 0, 0 }
local R = { 255, 0, 0, 0 }
local G = { 0, 255, 0, 0 }
local B = { 0, 0, 255, 0 }

--well, the name said it
function UIDToPlayer(uid)
    for i = 1, 64 do
        local pCurrent = IEntityList.GetPlayer(i) 
        if (not pCurrent or pCurrent:GetClassId() ~= 40) then goto skip end

        local Info = CPlayerInfo.new()
        if (not pCurrent:GetPlayerInfo(Info)) then goto skip end

        if Info.userId == uid then
            return i
        end

        ::skip::
    end
end

--Get username from ID
function GetUsername(ID)
    local pCurrent = IEntityList.GetPlayer(ID) 
    if (not pCurrent or pCurrent:GetClassId() ~= 40) then return "null" end

    local PlayerInfo = CPlayerInfo.new()
    if (not pCurrent:GetPlayerInfo(PlayerInfo)) then return "null" end

    return PlayerInfo.szName
end

function ShortenString(text, maxLength)
    local returnString = text
    if string.len(text) > maxLength then 
        returnString = string.sub(returnString, 1, maxLength-3)
        returnString = returnString .. "..."
    end
    return returnString
end

Hack.RegisterCallback("PaintTraverse", function ()
    if first then
        Setup()
        first = false
    end
    --Reset pos
    if Menu.GetBool("cTDamageListReset") then
        posX = 100
        posY = 100
        Menu.SetBool("cTDamageListReset", false)
    end

    --Dragging System
    local cursor = InputSys.GetCursorPos()

    local data = {}
    local banned = {}
    
    for i = 1, 64 do
        local currentPlayer = IEntityList.GetPlayer(i) 
        if (not currentPlayer or currentPlayer:GetClassId() ~= 40) then goto skip end
        
        local Info = CPlayerInfo.new()
        if (not currentPlayer:GetPlayerInfo(Info)) then goto skip end
        
        local username = GetUsername(i)
        
        if kills[i] > 0 or damage[i] > 0 then
            if Menu.GetInt("cTDamageFormat") == 0 then
                if kills[i] > 2 or damage[i] > 299 then table.insert(banned, true) else table.insert(banned, false) end
                if kills[i] > 2 or damage[i] > 299 then table.insert(data, ShortenString(username, 18) .. " K:" .. kills[i] .. " D:" .. damage[i] .. " BANNED") else table.insert(data, ShortenString(username, 18) .. " K:" .. kills[i] .. " D:" .. damage[i]) end
            elseif Menu.GetInt("cTDamageFormat") == 1 then
                if kills[i] > 2 or damage[i] > 299 then table.insert(banned, true) else table.insert(banned, false) end
                if kills[i] > 2 or damage[i] > 299 then table.insert(data, ShortenString(username, 18) .. ": " .. kills[i] .. " (" .. damage[i] .. ") BANNED") else table.insert(data, ShortenString(username, 18) .. ": " .. kills[i] .. " (" .. damage[i] .. ")") end
            end
        end

        ::skip::
    end
    
    --RGB Drawing (why does everyone like rbg xP)
    local S = 3
    
    S,Type[1], R[1], G[1], B[1] = Rainbow(3,Type[1], R[1], G[1], B[1])
    S,Type[4], R[4], G[4], B[4] = Rainbow(3,Type[4], R[4], G[4], B[4])
    
    if Menu.GetInt("cTDamageDesign") == 0 then --Default
        sizeY = 16
        
        --Draw Extension
        local extensionSizeY = 0
        local highestX = 0
        
        for i = 1, #data do
            extensionSizeY = extensionSizeY + 6
            local textSizeS = Render.CalcTextSize(data[i], 16, "TDamageFont")
            if highestX < textSizeS.x then highestX = textSizeS.x end
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 6
        
        local xSize = sizeX
        if highestX + 12 > sizeX then xSize = highestX + 12 end
    
        local clr = Color.new(255,255,255,255)
        local clrBG = Color.new(0,0,0,255)
        if Menu.GetInt("cTDamageColorScheme") == 0 then 
            clr = Color.new(255,255,255,255) 
            clrBG = Color.new(0,0,0,255)
        elseif Menu.GetInt("cTDamageColorScheme") == 1 then 
            clr = Color.new(0,0,0,255) 
            clrBG = Color.new(255,255,255,255)
        end

        Render.RectFilled(posX, posY, posX + xSize, posY + sizeY, clrBG, 0)
        if Menu.GetInt("cTDamageColorScheme") == 2 then Render.RectFilledMultiColor(posX + 4, posY + 7, (posX + xSize) - 4, posY + sizeY - 7, Color.new(R[4], G[4], B[4], 255),Color.new(R[1], G[1], B[1], 255),Color.new(R[1], G[1], B[1], 255),Color.new(R[4], G[4], B[4], 255)) else Render.RectFilled(posX + 4, posY + 7, (posX + xSize) - 4, posY + sizeY - 7, clr, 0) end

        Render.RectFilled(posX, posY + sizeY, posX + xSize, posY + sizeY + extensionSizeY, clrBG, 0)

        --Draw Data
        extensionSizeY = 0

        for i = 1, #data do
            extensionSizeY = extensionSizeY + 6
            local textSizeS = Render.CalcTextSize(data[i], 16, "TDamageFont")
            local textClr = clr
        
            if banned[i] then textClr = Color.new(255, 0, 0, 255) end
            Render.Text(data[i], posX + 6, posY + extensionSizeY + sizeY, 16, textClr, false, false, "TDamageFont")
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 6

        --Check if box is able to be dragged
        if cursor.x >= posX and cursor.x <= posX + sizeX then
            if cursor.y >= posY and cursor.y <= posY + sizeY then
                if InputSys.IsKeyDown(1) and not Menu.GetBool("cTDamageLock") then
                    Dragging = "t" --supposed to be a bool but I was way to fucking lazy to change it from my old string system (I did parsing be fucking proud atleast)
                else
                    Dragging = "f"
                end
            else
                if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
            end
        else
            if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
        end
    elseif Menu.GetInt("cTDamageDesign") == 1 then --Simple
        --Draw Extension
        local extensionSizeY = 3 + Render.CalcTextSize("Team Damage List:", 16, "TDamageFont").y
        local highestX = sizeX
        local boxSize = 2.5
        
        for i = 1, #data do
            extensionSizeY = extensionSizeY + 1
            local textSizeS = Render.CalcTextSize(data[i], 16, "TDamageFont")
            if highestX < textSizeS.x then highestX = textSizeS.x end
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 1
        sizeY = extensionSizeY
        
        Render.Text("Team Damage List:", posX, posY, 16, Color.new(255,255,255,255), false, false, "TDamageFont")

        if Globals.MenuOpened() then 
            Render.Rect(posX, posY, posX + highestX, posY + extensionSizeY, Color.new(255,255,255,255), 0, 2)
        
            Render.RectFilled(posX - boxSize, posY - boxSize, posX + boxSize, posY + boxSize, Color.new(255,255,255,255), 0)
            Render.RectFilled(posX - boxSize + highestX, posY - boxSize, posX + boxSize + highestX, posY + boxSize, Color.new(255,255,255,255), 0)

            Render.RectFilled(posX - boxSize, posY - boxSize + extensionSizeY, posX + boxSize, posY + boxSize + extensionSizeY, Color.new(255,255,255,255), 0)
            Render.RectFilled(posX - boxSize + highestX, posY - boxSize + extensionSizeY, posX + boxSize + highestX, posY + boxSize + extensionSizeY, Color.new(255,255,255,255), 0)
        end

        extensionSizeY = 3 + Render.CalcTextSize_1("Team Damage List:", 16).y
        for i = 1, #data do
            extensionSizeY = extensionSizeY + 1
            local textSizeS = Render.CalcTextSize(data[i], 16, "TDamageFont")
            if highestX < textSizeS.x then highestX = textSizeS.x end
            Render.Text(data[i], posX, posY + extensionSizeY, 16, Color.new(255,255,255,255), false, false, "TDamageFont")
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 1

        --Check if box is able to be dragged
        if cursor.x >= posX and cursor.x <= posX + highestX then
            if cursor.y >= posY and cursor.y <= posY + extensionSizeY then
                if InputSys.IsKeyDown(1) and not Menu.GetBool("cTDamageLock") and Globals.MenuOpened() then
                    Dragging = "t" --supposed to be a bool but I was way to fucking lazy to change it from my old string system (I did parsing be fucking proud atleast)
                else
                    Dragging = "f"
                end
            else
                if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
            end
        else
            if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
        end

    end

    --Coderman optimize b4 release
    if nextAutosave <= IGlobalVars.realtime then
        FileSys.SaveTextToFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\dataTDamage.s", posX .. "," .. posY)
        nextAutosave = IGlobalVars.realtime + secBeforeAutoSave
    end
end)

Hack.RegisterCallback("FireEventClientSideThink", function(Event)
    if Event:GetName() == "player_hurt" then
        
        local attackerID = UIDToPlayer(Event:GetInt("attacker"))
        local hurt = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("userid"))) 
        local attacker = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("attacker")))
        local dmg = Event:GetInt("dmg_health")

        if not hurt then return end
        if not attacker then return end

        if hurt ~= attacker then
            if attacker:IsTeammate() or IEngine.GetLocalPlayer() == attackerID then
                if hurt:IsTeammate() or IEngine.GetLocalPlayer() == UIDToPlayer(Event:GetInt("userid")) then
                    damage[attackerID] = damage[attackerID] + dmg
                end
            end
        end
    end
    if Event:GetName() == "player_death" then
        local attackerID = UIDToPlayer(Event:GetInt("attacker"))
        local hurt = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("userid"))) 
        local attacker = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("attacker")))
        
        if not hurt then return end

        if not attacker then return end

        if hurt ~= attacker then
            if attacker:IsTeammate() or IEngine.GetLocalPlayer() == attackerID then
                if hurt:IsTeammate() or IEngine.GetLocalPlayer() == UIDToPlayer(Event:GetInt("userid")) then
                    kills[attackerID] = kills[attackerID] + 1
                end
            end
        end
    end
end)

Hack.RegisterCallback("FrameStageNotify", function (stage)
    if stage == 5 then return end

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
end)

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
