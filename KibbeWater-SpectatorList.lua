-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Speclist", "cEnableSpeclistPublic", true)
Menu.Checkbox("Lock Position", "cSpeclistLockPublic", false)
Menu.Checkbox("Enable RGB", "cEnableSpeclistRGBPublic", true)
Menu.Checkbox("Enable Notifications", "cSpeclistNotifications", true)
Menu.ColorPicker("Speclist Color", "cSpeclistColorPublic", 255, 255, 255, 255)
Menu.Combo( "Spectator Design", "cSpecDesignPublic", { "Sown", "Aimware", "KibbeWater", "Beta", "Aiyu", "Sown v2", "MillionWare" }, 0)
Menu.SliderInt("Size", "cPosSizePublic", 1, 50, "", 27)
Menu.Separator()
Menu.Text("INCASE SPECTATOR LIST DOESN'T APPEAR")
Menu.Checkbox("Reset Position", "cSpeclistReset", false)

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
local fakeIDs = {}
local loadedUsers = {}

--Offsets
local obsModeOffset = Hack.GetOffset("DT_BasePlayer", "m_iObserverMode")
local obsTargetOffset = Hack.GetOffset("DT_BasePlayer", "m_hObserverTarget")

--Global Vars
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

local letScan = true

--For version handling
local ver = "2.3"
local notifNew = false
local notifData = ""

--Load up save
local basePath = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Spectator List\\"
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Spectator List\\")
local loadData = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Spectator List\\data.s")
local ParsedData = Split(loadData, ",")
posX = tonumber(ParsedData[1])
posY = tonumber(ParsedData[2])

--RGB
local Type = { 0, 0, 0, 0 }
local R = { 255, 0, 0, 0 }
local G = { 0, 255, 0, 0 }
local B = { 0, 0, 255, 0 }

function SendNotif(ID, type, title, msg, clr, r, g, b, expire, update)
    local clrBool = "false"
    if clr then clrBool = "true" end
    if Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime then
        if Menu.GetBool("cSpeclistNotifications") or update then
            Menu.SetString("NM_API_Payload", ID .. "*" .. type .. "*" .. title .. "*" .. msg .. "*" .. clrBool .. "*" .. r .. "*" .. g .. "*" .. b .. "*" .. (IGlobalVars.realtime + expire))
            Menu.SetBool("NM_API_Send", true)
        end
    end
end

function Setup()
    URLDownloadToFile("http://old.kibbewater.xyz/ver/spec.txt", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\spec.txt")
    if FileSys.FileIsExist(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\spec.txt") then
        local data = Split(FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\spec.txt"), "\n")
        if #data == 2 then
            if ver ~= data[1] and Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and not Menu.GetBool("NM_API_Send") and Menu.GetString("NM_API_Payload") == "" then
                Menu.SetString("NM_API_Payload", "SpecUpdates" .. "*" .. "1" .. "*" .. "Spectator List Update" .. "*" .. "Please download version " .. data[1] .. " from interium.ooo" .. "*" .. "false" .. "*" .. "0" .. "*" .. "0" .. "*" .. "0" .. "*" .. (IGlobalVars.realtime + 7))
                Menu.SetBool("NM_API_Send", true)
            elseif Menu.GetInt("NM_API_Enabled") < IGlobalVars.realtime or not Menu.GetBool("NM_API_Send") or Menu.GetString("NM_API_Payload") == "" then
                notifData = "SpecUpdates" .. "*" .. "1" .. "*" .. "Spectator List Update" .. "*" .. "Please download version " .. data[1] .. " from interium.ooo" .. "*" .. "false" .. "*" .. "0" .. "*" .. "0" .. "*" .. "0" .. "*"
                notifNew = true
                Print("Awaiting, sending")
            end
        end
    end
end

function Exists(table, value) 
    for i = 1, #table do
        if table[i] == value then return true end
    end
    return false
end

function IndexToSteam64(idx) 
    local pEnt = IEntityList.GetPlayer(idx)
    if not pEnt then return end

    local entInfo = CPlayerInfo.new()
    if not pEnt:GetPlayerInfo(entInfo) then return end

    return entInfo.steamID64
end

--Draw Spectator List
function Paint()
    if Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and notifNew and not Menu.GetBool("NM_API_Send") and Menu.GetString("NM_API_Payload") == "" then
        Print(IGlobalVars.realtime .. ": Sending")
        Menu.SetString("NM_API_Payload", notifData .. (IGlobalVars.realtime + 7))
        Menu.SetBool("NM_API_Send", true)
        notifNew = false
    end
    
    if not Utils.IsInGame() then 
        letScan = true
        return
    end

    if not Menu.GetBool("cEnableSpeclistPublic") then return end
    if Utils.IsLocalAlive() then
        BuildSpecList(IEngine.GetLocalPlayer())
    else
        BuildSpecList(FindTarget())
    end

    if letScan and Menu.GetInt("cSpecDesignPublic") == 6 then
        local loaded = false
        for i = 1, 64 do
            if loaded then goto skip end

            local pEnt = IEntityList.GetPlayer(i)
            if not pEnt then goto skip end

            local entInfo = CPlayerInfo.new()
            if not pEnt:GetPlayerInfo(entInfo) then goto skip end

            if Exists(loadedUsers, entInfo.steamID64) then goto skip end

            Print("Loading " .. entInfo.szName .. "'s icon")
            URLDownloadToFile("https://old.kibbewater.xyz/interium/getavatar?steamid=" .. entInfo.steamID64, basePath .. entInfo.steamID64 .. ".jpg")
            Render.LoadImage(entInfo.steamID64, basePath .. entInfo.steamID64 .. ".jpg")
            table.insert(loadedUsers, entInfo.steamID64)
            loaded = true

            ::skip::
        end
        if not loaded then letScan = false end
    elseif not Menu.GetBool("cSpecDesignPublic") then
        letScan = true
    end

    if Menu.GetBool("cSpeclistReset") then
        posX = 100
        posY = 100
        Menu.SetBool("cSpeclistReset", false)
    end

    --Set Size 
    sizeY = Menu.GetInt("cPosSizePublic")
    sizeX = sizeY * 6.481481481481481

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if not pLocal then return end

    local info = CPlayerInfo.new()
    if not pLocal:GetPlayerInfo(info) then return end

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
                if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
            end
        else
            if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
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
    elseif Menu.GetInt("cSpecDesignPublic") == 1 then --Aimware

        --Dragging System
        local cursor = InputSys.GetCursorPos()

        --Check if box is able to be dragged
        if cursor.x >= posX and cursor.x <= posX + 200 then
            if cursor.y >= posY and cursor.y <= posY + 24 then
                if InputSys.IsKeyDown(1) and not Menu.GetBool("cSpeclistLockPublic") then
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

        --Render Header
        Render.RectFilled(posX, posY, posX + 200, posY + 24, Color.new(200,40,40,255), 3)
        Render.RectFilled(posX, posY + 23, posX + 200, posY + 24, Color.new(200,40,40,255), 0)

        --Render Header Text
        local dotTextSize = Render.CalcTextSize_1("Spectators list", 15, "sunflower").y / 2
        Render.Text_1("Spectators list", posX + 8, posY + (12 - dotTextSize), 15, Color.new(255,255,255,255), false, false, "sunflower")

        --Draw Extension
        local extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 8
            local textSizeS = Render.CalcTextSize_1(fakeNames[i], 14, "sunflower")
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 8

        Render.RectFilled(posX, posY + 24, posX + 200, posY + extensionSizeY + 24, Color.new(0,0,0,75), 0)
        Render.RectFilled(posX, posY + extensionSizeY + 24, posX + 200, posY + extensionSizeY + 28, Color.new(200,40,40,255), 0)
       
        --Draw Extension
        local extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 8
            local textSizeS = Render.CalcTextSize(fakeNames[i], 14, "sunflower")
            Render.Text(fakeNames[i], posX + 6, posY + extensionSizeY + 24, 14, Color.new(255,255,255,255), false, false, "sunflower")
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 8
        
        
    elseif Menu.GetInt("cSpecDesignPublic") == 2 then --KibbeWater
        
        --Dragging System
        local cursor = InputSys.GetCursorPos()

        --Draw RGB
        local S = 3

        S,Type[1], R[1], G[1], B[1] = Rainbow(3,Type[1], R[1], G[1], B[1])
        S,Type[4], R[4], G[4], B[4] = Rainbow(3,Type[4], R[4], G[4], B[4])

        --Check if box is able to be dragged
        if cursor.x >= posX and cursor.x <= posX + 200 then
            if cursor.y >= posY and cursor.y <= posY + 22 then
                if InputSys.IsKeyDown(1) and not Menu.GetBool("cSpeclistLockPublic") then
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

        Render.RectFilled(posX, posY, posX + 200, posY + 16, Color.new(25,25,25,255), 0)
        Render.RectFilledMultiColor(
            posX + 5,
            posY + 14,
            (posX + 200) - 5,
            posY + 16,
            Color.new(R[4], G[4], B[4], 255),
            Color.new(R[1], G[1], B[1], 255),
            Color.new(R[1], G[1], B[1], 255),
            Color.new(R[4], G[4], B[4], 255)
        )

        --Draw Extension
        local extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 6
            local textSizeS = Render.CalcTextSize(fakeNames[i], 16, "sunflower")
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 6

        Render.RectFilled(posX, posY + 16, posX + 200, posY + 16 + extensionSizeY, Color.new(25,25,25,255), 0)

        --Draw Extension
        extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 6
            local textSizeS = Render.CalcTextSize(fakeNames[i], 16, "sunflower")
            Render.Text(fakeNames[i], posX + 6, posY + extensionSizeY + 16, 16, Color.new(255,255,255,255), false, false, "sunflower")
            extensionSizeY = extensionSizeY + textSizeS.y
        end
        extensionSizeY = extensionSizeY + 6

    elseif Menu.GetInt("cSpecDesignPublic") == 3 then --Beta Custom
        local textYSize = Render.CalcTextSize("Spectator List", 18, "sunflower").y / 5
        Render.RectFilled(posX, posY, posX + sizeX, posY + sizeY, Color.new(0,0,0,opacity), 4)
        Render.Text_1("Spectator List", posX + sizeX / 2, posY + textYSize, 18, Color.new(255,255,255,opacity), true, true)

        --Dragging System
        local cursor = InputSys.GetCursorPos()

        --Check if box is able to be dragged
        if cursor.x >= posX and cursor.x <= posX + sizeX then
            if cursor.y >= posY and cursor.y <= posY + sizeY then
                if InputSys.IsKeyDown(1) and not Menu.GetBool("cSpeclistLock") then
                    Dragging = "t"
                else
                    Dragging = "f"
                end
            else
                if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
            end
        else
            if InputSys.IsKeyDown(0) or OldDragging == "f" then Dragging = "f" end
        end

        --Draw Extension
        local extensionSizeX = sizeX
        local extensionSizeY = 0
        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 2
            extensionSizeY = extensionSizeY + Render.CalcTextSize(fakeNames[i], 15, "sunflower").y
        end
        if #fakeNames ~= 0 then
            extensionSizeY = extensionSizeY + 2
        end
        Render.RectFilled(posX + 3, (posY + sizeY), (posX + extensionSizeX) - 3, (((posY + sizeY) + 1) + extensionSizeY) + 1, Color.new(10,10,10,opacity), 5)
        Render.RectFilled(posX + 3, (((posY + sizeY) + 1) + extensionSizeY) - 4, (posX + extensionSizeX) - 3, (((posY + sizeY) + 1) + extensionSizeY) + 8, Color.new(10,10,10,opacity), 5)

        --Draw RGB
        local S = 3

        S,Type[1], R[1], G[1], B[1] = Rainbow(3,Type[1], R[1], G[1], B[1])
	    S,Type[4], R[4], G[4], B[4] = Rainbow(3,Type[4], R[4], G[4], B[4])

	    Render.RectFilledMultiColor(
		    posX,                                 -- x1
		    (posY + sizeY) - 2,                                 -- y1
		    posX + sizeX,                           -- x2
		    (posY + sizeY) + 1,              -- y2
		    Color.new(R[4], G[4], B[4], opacity),  --  upper left
		    Color.new(R[1], G[1], B[1], opacity),  --  upper right
		    Color.new(R[1], G[1], B[1], opacity),  -- bottom right
		    Color.new(R[4], G[4], B[4], opacity)   -- bottom left
        )

        extensionSizeY = 0
        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 2
            Render.Text_1(fakeNames[i], posX + sizeX / 2, ((posY + sizeY) + 1) + extensionSizeY, 17, Color.new(255,255,255,opacity), true, true, "sunflowerr")
            extensionSizeY = extensionSizeY + Render.CalcTextSize(fakeNames[i], 15, "sunflowerr").y
        end

        FileSys.SaveTextToFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Spectator List\\data.s", posX .. "," .. posY)
    elseif Menu.GetInt("cSpecDesignPublic") == 4 then --Aiyu
        --Draw Extension
        local extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 2
            local textSizeS = Render.CalcTextSize(fakeNames[i], 17, "sunflower")
            Render.Text(fakeNames[i], Globals.ScreenWidth() - (textSizeS.x + 5), extensionSizeY, 17, Color.new(255,255,255,opacity), false, true, "sunflower")
            extensionSizeY = extensionSizeY + Render.CalcTextSize(fakeNames[i], 17, "sunflower").y
        end
    elseif Menu.GetInt("cSpecDesignPublic") == 5 then --Sown v2
        --Dragging System
        local cursor = InputSys.GetCursorPos()

        if #fakeNames == 0 then
            --Check if box is able to be dragged
            if cursor.x >= posX and cursor.x <= posX + sizeX then
                if cursor.y >= posY and cursor.y <= posY + sizeY then
                    if InputSys.IsKeyDown(1) and not Menu.GetBool("cSpeclistLock") then
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
            --Draw RGB
            local S = 3

            S,Type[1], R[1], G[1], B[1] = Rainbow(3,Type[1], R[1], G[1], B[1])
            S,Type[4], R[4], G[4], B[4] = Rainbow(3,Type[4], R[4], G[4], B[4])
        
            if Menu.GetBool("cSownSpecEnableRGB") then
                Render.RectFilledMultiColor(
                    posX - 2,                                 -- x1
                    posY - 2,                                 -- y1
                    (posX + sizeX) + 2,                           -- x2
                    (posY + sizeY) + 2,              -- y2
                    Color.new(R[4], G[4], B[4], opacity),  --  upper left
                    Color.new(R[1], G[1], B[1], opacity),  --  upper right
                    Color.new(R[1], G[1], B[1], opacity),  -- bottom right
                    Color.new(R[4], G[4], B[4], opacity)   -- bottom left
                )
            else
                Render.RectFilled(posX - 2, posY - 2, (posX + sizeX) + 2, (posY + sizeY) + 2, Color.new(0,0,0,opacity), 0)
            end

            if not Menu.GetBool("cSownSpecLightMode") then Render.RectFilled(posX, posY,sizeX + posX, posY + sizeY, Color.new(0,0,0,opacity), 0) else Render.RectFilled(posX, posY,sizeX + posX, posY + sizeY, Color.new(255,255,255,opacity), 0) end
            local dotTextSize = Render.CalcTextSize(Menu.GetString("cSownSpecEmptyText"), 17, "sunflower").y / 2
            if not Menu.GetBool("cSownSpecLightMode") then Render.Text(Menu.GetString("cSownSpecEmptyText"), posX + (sizeX / 2), posY + ((sizeY / 2) - dotTextSize), 17, Color.new(255,255,255,opacity), true, true, "sunflower") else Render.Text(Menu.GetString("cSownSpecEmptyText"), posX + (sizeX / 2), posY + ((sizeY / 2) - dotTextSize), 17, Color.new(0,0,0,opacity), true, true, "sunflower") end
        end

        --Draw Extension
        local extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 2
            local textSizeS = Render.CalcTextSize(fakeNames[i], 15, "sunflower")
            extensionSizeY = extensionSizeY + Render.CalcTextSize(fakeNames[i], 15, "sunflower").y
        end
        extensionSizeY = extensionSizeY + 4

        if #fakeNames ~= 0 then
            --Check if box is able to be dragged
            if cursor.x >= posX and cursor.x <= posX + sizeX then
                if cursor.y >= posY and cursor.y <= posY + extensionSizeY then
                    if InputSys.IsKeyDown(1) and not Menu.GetBool("cSpeclistLock") then
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
            --Draw RGB
            local S = 3

            S,Type[1], R[1], G[1], B[1] = Rainbow(3,Type[1], R[1], G[1], B[1])
            S,Type[4], R[4], G[4], B[4] = Rainbow(3,Type[4], R[4], G[4], B[4])
        
            if Menu.GetBool("cSownSpecEnableRGB") then
                Render.RectFilledMultiColor(
                    posX - 2,                                 -- x1
                    posY - 2,                                 -- y1
                    (posX + sizeX) + 2,                           -- x2
                    (posY + extensionSizeY) + 2,              -- y2
                    Color.new(R[4], G[4], B[4], 255),  --  upper left
                    Color.new(R[1], G[1], B[1], 255),  --  upper right
                    Color.new(R[1], G[1], B[1], 255),  -- bottom right
                    Color.new(R[4], G[4], B[4], 255)   -- bottom left
                )
            else
                Render.RectFilled(posX - 2, posY - 2, (posX + sizeX) + 2, (posY + extensionSizeY) + 2, Menu.GetColor("cSownSpecColor"), 0)
            end

            if not Menu.GetBool("cSownSpecLightMode") then Render.RectFilled(posX, posY,sizeX + posX, posY + extensionSizeY, Color.new(0,0,0,opacity), 0) else Render.RectFilled(posX, posY,sizeX + posX, posY + extensionSizeY, Color.new(255,255,255,opacity), 0) end
        end

        extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 2
            if not Menu.GetBool("cSownSpecLightMode") then Render.Text(fakeNames[i], posX + 6, posY + extensionSizeY, 17, Color.new(255,255,255,255), false, true, "sunflower") else Render.Text(fakeNames[i], posX + 6, posY + extensionSizeY, 17, Color.new(0,0,0,255), false, true, "sunflower") end
            extensionSizeY = extensionSizeY + Render.CalcTextSize(fakeNames[i], 15, "sunflower").y
        end
    elseif Menu.GetInt("cSpecDesignPublic") == 6 then

        --Dragging System
        local cursor = InputSys.GetCursorPos()

        --Check if box is able to be dragged
        if cursor.x >= posX and cursor.x <= posX + 250 then
            if cursor.y >= posY and cursor.y <= posY + 22 then
                if InputSys.IsKeyDown(1) and not Menu.GetBool("cSpeclistLockPublic") then
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

        --Draw Extension
        local extensionSizeY = 0

        for i = 1, #fakeNames do
            extensionSizeY = extensionSizeY + 6
            local textSizeS = Render.CalcTextSize(fakeNames[i], 11, "sunflower")
            extensionSizeY = extensionSizeY + textSizeS.y + 6
        end
        extensionSizeY = extensionSizeY + 9

        --Main box
        Render.RectFilledMultiColor(posX, posY, posX + 250, posY + 18 + extensionSizeY, Color.new(20,20,20,255), Color.new(20,20,20,255), Color.new(11,11,11,255), Color.new(11,11,11,255))

        --Border
        Render.Rect(posX-1, posY-1, posX + 251, posY + 17 + extensionSizeY, Color.new(0,0,0,255), 0, 1)
        --Render.Rect(posX-2, posY-2, posX + 202, posY + 18 + extensionSizeY, Color.new(0,0,0,255), 0, 1)

        if #fakeNames == 0 then
            Render.RectFilled(posX + 8, posY + 19, (posX + 250) - 8, posY + 21, Color.new(11,11,11,255), 0)
        end
        local specTestS = Render.CalcTextSize_1("Spectators", 11)
        Render.Text_1("Spectators", posX+125, posY+11 - (specTestS.y / 2) - 2, 13, Color.new(255,255,255,255), true, true)
        

        --Draw Extension
        extensionSizeY = 0
        for i = 1, #fakeNames do
            
            extensionSizeY = extensionSizeY + 6
            local textSizeS = Render.CalcTextSize(fakeNames[i], 11, "sunflower")
            Render.RectFilled(posX+8+19, (posY + extensionSizeY + 18 + (textSizeS.y/2))-10, posX + 242, (posY + extensionSizeY + 18 + (textSizeS.y/2))+10, Color.new(18,18,18,255))
            Render.Text(fakeNames[i], posX + 12 + 30, posY + extensionSizeY + 18, 11, Color.new(255,255,255,255), false, false, "sunflower")            

            local col = 11

            --Border
            Render.Rect(posX+8+19, (posY + extensionSizeY + 16 + (textSizeS.y/2))-10, posX + 242, (posY + extensionSizeY + 18 + (textSizeS.y/2))+10, Color.new(col,col,col,255), 0, 1)
            --Render.Rect(posX+8+19, (posY + extensionSizeY + 16 + (textSizeS.y/2))-9, posX + 191, (posY + extensionSizeY + 16 + (textSizeS.y/2))+9, Color.new(col,col,col,255), 0, 1)

            --Render image
            Render.Image(IndexToSteam64(fakeIDs[i]), posX+8, (posY + extensionSizeY + 18 + (textSizeS.y/2))-10, posX+8+20, (posY + extensionSizeY + 18 + (textSizeS.y/2))+10, Color.new(255,255,255,255), 0, 0, 1, 1)
            
            extensionSizeY = extensionSizeY + textSizeS.y + 6
        end
        extensionSizeY = extensionSizeY + 9
    end

    --Coderman optimize b4 release
    if nextAutosave <= IGlobalVars.realtime then
        FileSys.SaveTextToFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Spectator List\\data.s", posX .. "," .. posY)
        nextAutosave = IGlobalVars.realtime + secBeforeAutoSave
    end
end
Hack.RegisterCallback("PaintTraverse", Paint)

function FrameStageNotify(stage)
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
end
Hack.RegisterCallback("FrameStageNotify", FrameStageNotify)

Hack.RegisterCallback("FireEventClientSideThink", function (Event)
    if Event:GetName() == "round_start" then
        letScan =  true
    end
end)

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

function BuildSpecList(TargetIndex)
    fakeNames = {}
    fakeIDs = {}
    
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
            table.insert(fakeIDs, i)
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

Setup()
