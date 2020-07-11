Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Grenade Helper", "cEnableGriefNadeHelper", true)
Menu.Checkbox("Enable Autothrow", "cEnableAutothrow", true)
Menu.Checkbox("Enable Notifications", "cEnableAGNotifs", true)
Menu.Checkbox("Draw Line To Angle (nades)", "cGriefHelperDrawLineAngle", true)
Menu.Checkbox("Draw Line To Kickable Decoys", "cGriefHelperDrawLineKickable", true)
Menu.Checkbox("Draw Line To preffered decoy", "cGriefHelperDrawLinePreffered", true)
Menu.SliderInt("Grenade Helper Render Distance", "cGriefHelperRenderDistance", 50, 2000, "", 1000)
Menu.KeyBind("Auto-Align with closest point", "cGriefAlign", 0)
Menu.KeyBind("Throw 2HP Grenade", "cAGriefNadeThrow", 0)

local displayedID = 0
local map = ""
local loadedMap = ""

--positions
local angEye = QAngle.new(0,0,0)
local posEye = Vector.new(0,0,0)

--Delay
local usingDelay = false
local delayTime = 0

--Timers
local crouchTime = 0
local fireTime = 0

--Global Vars
local coords = {}
local fire = false

--Decoy ESP shit
local entID = {}
local playerID = {}
local startTime = {}
local timeLeft = {}

--Priority shit
local kills = {}
local damage = {}

--Auto-Align
local aligning = false
local closestPos = Vector.new(0,0,0)
local closestDist = 1000000
local foundClosest = false
local startedAlign = -5

--Old Data (for aligning)
local oldDist = 420

--For version handling
local ver = "1.2"
local notifNew = false
local notifData = ""

--New 2HP grenade method
local throwType = 0
local executeTime = 0
local executeStart = 0

local va = QAngle.new(0,0,0)

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

--well, the name said it
function UIDToPlayer(uid)
    for i = 1, 64 do
        local pCurrent = IEntityList.GetPlayer(i) 
        if (not pCurrent or pCurrent:GetClassId() ~= 40) then goto continue end

        local Info = CPlayerInfo.new()
        if (not pCurrent:GetPlayerInfo(Info)) then goto continue end

        if Info.userId == uid then
            return i
        end

        ::continue::
    end
end

function SendNotif(ID, type, title, msg, clr, r, g, b, expire)
    local clrBool = "false"
    if clr then clrBool = "true" end
    if Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and Menu.GetBool("cEnableAGNotifs") then
        Menu.SetString("NM_API_Payload", ID .. "*" .. type .. "*" .. title .. "*" .. msg .. "*" .. clrBool .. "*" .. r .. "*" .. g .. "*" .. b .. "*" .. (IGlobalVars.realtime + expire))
        Menu.SetBool("NM_API_Send", true)
    end
end

--Set initial settings
function Setup()
    for i = 1, 64 do
        local pCurrent = IEntityList.GetPlayer(i) 
        if (not pCurrent or pCurrent:GetClassId() ~= 40) then goto continue end

        kills[i] = 0
        damage[i] = 0

        ::continue::
    end
    URLDownloadToFile("http://kibbewater.ml/ver/ag.txt", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ag.txt")
    if FileSys.FileIsExist(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ag.txt") then
        local data = Split(FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ag.txt"), "\n")
        if #data == 2 then
            if ver ~= data[1] and Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and not Menu.GetBool("NM_API_Send") and Menu.GetString("NM_API_Payload") == "" then
                Menu.SetString("NM_API_Payload", "AGUpdates" .. "*" .. "1" .. "*" .. "Advanced Griefing Update" .. "*" .. "Please download version " .. data[1] .. " from interium.ooo" .. "*" .. "false" .. "*" .. "0" .. "*" .. "0" .. "*" .. "0" .. "*" .. (IGlobalVars.realtime + 7))
                Menu.SetBool("NM_API_Send", true)
            elseif Menu.GetInt("NM_API_Enabled") < IGlobalVars.realtime or Menu.GetBool("NM_API_Send") or Menu.GetString("NM_API_Payload") ~= "" then
                notifData = "AGUpdates" .. "*" .. "1" .. "*" .. "Advanced Griefing Update" .. "*" .. "Please download version " .. data[1] .. " from interium.ooo" .. "*" .. "false" .. "*" .. "0" .. "*" .. "0" .. "*" .. "0" .. "*"
                notifNew = true
            end
        end
    end
end

--Get username form ID
function GetUsername(ID)
    local pCurrent = IEntityList.GetPlayer(ID) 
    if (not pCurrent or pCurrent:GetClassId() ~= 40) then return "" end

    local PlayerInfo = CPlayerInfo.new()
    if (not pCurrent:GetPlayerInfo(PlayerInfo)) then return "" end

    return PlayerInfo.szName
end

--Find best decoy to sit on
function FindPriority(activeDecoys)
    local highestKills = -1
    local userid = -1
    local result = {}

    for i = 1, #activeDecoys do
        local ID = UIDToPlayer(activeDecoys[i])
        local teamkills = kills[ID]
        local teamdamage = kills[ID]

        if teamkills > highestKills then 
            highestKills = teamkills 
            userid = i
        end
    end

    result[1] = userid
    result[2] = highestKills

    return result
end

--Calculate the color depending on how many seconds are remaining
function TimeToColor(timeLasts, index)
    local timeElapsed = IGlobalVars.realtime - startTime[index]
    local amountToAdd = 255 / timeLasts
    if timeElapsed > timeLasts or timeElapsed < -1 then timeElapsed = timeLasts end
    local clr = Color.new(timeElapsed * amountToAdd,255 - (timeElapsed * amountToAdd),0,255)
    timeLeft[index] = timeLasts - math.floor(timeElapsed)
    return clr
end

--Get time before something goes off
function GetTimeRemaining(timeLasts, index)
    local timeElapsed = IGlobalVars.realtime - startTime[index]
    if timeElapsed > timeLasts or timeElapsed < -1 then timeElapsed = timeLasts end
    return (timeLasts - (math.floor(timeElapsed * 10) / 10))
end

Hack.RegisterCallback("PaintTraverse", function ()
    if (not Menu.GetBool("cEnableGriefNadeHelper") or not Utils.IsLocalAlive()) then return end

    LoadMap()

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if (not pLocal) then return end

    local weapon = pLocal:GetActiveWeapon()
    if (not weapon) then return end

    local wInfo = weapon:GetWeaponData()
    if (not wInfo) then return end

    local localPos = pLocal:GetAbsOrigin()
    local grenade = false
    if wInfo.consoleName == "weapon_hegrenade" then grenade = true end

    if Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and notifNew and not Menu.GetBool("NM_API_Send") and Menu.GetString("NM_API_Payload") == "" then
        Menu.SetString("NM_API_Payload", notifData .. (IGlobalVars.realtime + 7))
        Menu.SetBool("NM_API_Send", true)
        notifNew = false
        Print(IGlobalVars.realtime .. ": Sent " .. notifData .. (IGlobalVars.realtime + 7))
    end

    if InputSys.IsKeyPress(Menu.GetInt("cGriefAlign")) and grenade then 
        startedAlign = IGlobalVars.realtime
        aligning = true 
        Print("Aligning")
    end
    foundClosest = false
    closestDist = 100000
    for i = 1, #coords do
        if #coords[i] == 8 and grenade then
            if displayedID == 0 or i == displayedID then
                local string = coords[i][1] .. "\n" .. coords[i][2] .. " + " .. coords[i][3]
                local textPos = Vector.new(coords[i][4], coords[i][5], coords[i][6] + 50)
                local pos = Vector.new(coords[i][4], coords[i][5], coords[i][6])

                local nadePos = Vector.new(pos.x, pos.y, pos.z)
                local screenPos = Vector.new(0,0,0)

                local ang = QAngle.new(coords[i][7], coords[i][8], 0)
                local angVec = Vector.new(0,0,0)
                local angVecEye = Vector.new(0,0,0)
                local toScreen = Vector.new(0,0,0)
                
                local dist = Math.VectorDistance(pos, localPos)
                local nadeDist = 300
                local screen = Vector.new(0,0,0)

                Math.AngleVectors(ang, angVec)
                Math.AngleVectors(angEye, angVecEye)

                local throwPos = Vector.new(pos.x + (angVec.x * nadeDist), pos.y + (angVec.y * nadeDist), pos.z + (angVec.z * nadeDist) + 64)
                local throwPosText = Vector.new(pos.x + (angVec.x * nadeDist), pos.y + (angVec.y * nadeDist), pos.z + (angVec.z * nadeDist) + 54)
                local screenThrow = Vector.new(0,0,0)
                
                local eyePosition = Vector.new(posEye.x + (angVecEye.x * nadeDist), posEye.y + (angVecEye.y * nadeDist), posEye.z + (angVecEye.z * nadeDist) + 64)
                local aimDist = Math.VectorDistance(eyePosition, throwPos)

                if dist < closestDist then
                    foundClosest = true
                    closestPos = pos
                    closestDist = dist
                end

                if Math.WorldToScreen(textPos, toScreen) and dist <= Menu.GetInt("cGriefHelperRenderDistance") and dist >= 50 then
                    Render.Text_1(string, toScreen.x, toScreen.y, 15, Color.new(255, 255, 255, 255), false, true)
                end
                if Math.WorldToScreen(nadePos, screenPos) and dist <= Menu.GetInt("cGriefHelperRenderDistance") then
                    local color = Color.new(255,0,0,255)
                    local radius = 10
                    if dist <= 0.6 then 
                        displayedID = i
                        color = Color.new(0,255,0,255) 
                    else color = Color.new(255,0,0,255) end
                    if dist <= 3 then 
                        radius = 4
                    end
                    Render.Circle(screenPos.x, screenPos.y, radius, color, 12, 2)
                end
                if Math.WorldToScreen(throwPos, screenThrow) and dist <= 0.6 then
                    if Math.WorldToScreen(throwPosText, screen) then Render.Text_1(string, screen.x, screen.y, 15, Color.new(255, 255, 255, 255), false, true) end
                    local color = Color.new(255,0,0,255)
                    if aimDist <= 0.5 then color = Color.new(0,255,0,255) end
                    displayedID = i
                    Render.Circle(screenThrow.x, screenThrow.y, 4, color, 25, 2)
                    if Menu.GetBool("cGriefHelperDrawLineAngle") and aimDist >= 10 then Render.Line(Globals.ScreenWidth() / 2, Globals.ScreenHeight() / 2,screenThrow.x, screenThrow.y, color, 1) end
                    if aimDist <= 0.5 and Menu.GetBool("cEnableAutothrow") and fireTime <= IGlobalVars.realtime then 
                        if delayTime < IGlobalVars.realtime then
                            if usingDelay then
                                if coords[i][3] == "crouch" then
                                    Throw(true)
                                else
                                    Throw(false)
                                end
                            else
                                delayTime = IGlobalVars.realtime + 0.5
                                usingDelay = true
                            end
                        end
                    else
                        usingDelay = false
                    end
                end
                if displayedID == i and dist >= 3 then displayedID = 0 end
            end
        end
    end

    for i = 1, 64 do
        local Player = IEntityList.GetPlayer(i) 
        if (not Player or Player:GetClassId() ~= 40) then goto new end

        for x = 1, #playerID do
            local PlayerInfo = CPlayerInfo.new()
            if (not Player:GetPlayerInfo(PlayerInfo)) then goto skip end
        
            local eDecoy = IEntityList.GetEntity(entID[x]) 
            if (not eDecoy) then return end
    
            local PlayerName = PlayerInfo.szName
            local ID = PlayerInfo.userId
            if (playerID[x] == ID) then 
                local pos = eDecoy:GetAbsOrigin()
                local screen = Vector.new(0,0,0)

                local textPos = Vector.new(pos.x, pos.y, pos.z + 27)
                local screenText = Vector.new(0,0,0)

                local textPos2 = Vector.new(pos.x, pos.y, pos.z + 5)
                local screenText2 = Vector.new(0,0,0)
                
                local box = eDecoy:GetBox()
                local dist = Math.VectorDistance(pos, pLocal:GetAbsOrigin())
                local rangeForEsp = 150

                local lineStart = Vector.new(pos.x, pos.y, pos.z + 5)
                local lineEnd = Vector.new(pos.x, pos.y, pos.z + 25)

                local prio = FindPriority(playerID)
                local pUser = prio[1]
                local pKills = prio[2]
                
                if dist < rangeForEsp then 
                    Render.Rect(box.left, box.top, box.right, box.bottom, TimeToColor(15, x), 0, 2) 
                end
                if Math.WorldToScreen(pos, screen) then
                    if dist > rangeForEsp then Render.Circle(screen.x, screen.y, 10, TimeToColor(15, x), 25, 2) end
                    if pKills > 1 and Menu.GetBool("cGriefHelperDrawLineKickable") then
                        Render.Text_1("Kickable decoy found from \"" .. GetUsername(UIDToPlayer(playerID[pUser])) .. "\"", Globals.ScreenWidth() / 2, (Globals.ScreenHeight() / 5) * 0.3, 25, Color.new(255, 255, 255, 255), true, true)
                        Render.Text_1(GetTimeRemaining(15, x) .. "s", Globals.ScreenWidth() / 2, (Globals.ScreenHeight() / 5) * 0.4, 20, Color.new(255, 255, 255, 255), true, true)

                        Render.Line(Globals.ScreenWidth() / 2, Globals.ScreenHeight() / 2, screen.x, screen.y, TimeToColor(15, x), 2)
                    elseif Menu.GetBool("cGriefHelperDrawLinePreffered") then
                        Render.Text_1("Preffered nade from \"" .. GetUsername(UIDToPlayer(playerID[pUser])) .. "\"", Globals.ScreenWidth() / 2, (Globals.ScreenHeight() / 5) * 0.3, 17, Color.new(255, 255, 255, 255), true, true)
                        Render.Text_1(GetTimeRemaining(15, x) .. "s", Globals.ScreenWidth() / 2, (Globals.ScreenHeight() / 5) * 0.38, 12, Color.new(255, 255, 255, 255), true, true)

                        Render.Line(Globals.ScreenWidth() / 2, Globals.ScreenHeight() / 2, screen.x, screen.y, Color.new(255, 255, 255, 255), 1)
                    end
                end
                if Math.WorldToScreen(textPos, screenText) then
                    if dist > rangeForEsp then 
                        local sScreen = Vector.new(0,0,0)
                        local eScreen = Vector.new(0,0,0)
                        if Math.WorldToScreen(lineEnd, eScreen) then 
                            if Math.WorldToScreen(lineStart, sScreen) then 
                                Render.Line(sScreen.x, sScreen.y, eScreen.x, eScreen.y, TimeToColor(15, x), 1)
                                Render.Text_1(PlayerName, screenText.x, screenText.y - Render.CalcTextSize_1(PlayerName, 15).y, 15, TimeToColor(15, x), true, true) 
                            end 
                        end
                    else 
                        if Math.WorldToScreen(textPos2, screenText2) then Render.Text_1(GetTimeRemaining(15, x), screenText2.x, screenText2.y, 20, TimeToColor(15, x), true, true) end
                    end
                end
            end
            ::skip:: 
        end
        ::new::
    end
end)

function Throw(crouch)
    usingDelay = false
    if crouch then
        fire = true
        crouchTime = IGlobalVars.realtime + 2
    else
        fire = true
    end
end

function LoadMap()
    if (not Utils.IsInGame()) then 
        coords = {}
        displayedID = 0
        loadedMap = ""
    end
    
    if (loadedMap ~= "") then return end

    map = IEngine.GetLevelNameShort()
    
    --Load Coords
    if map == "de_nuke" and loadedMap ~= "de_nuke" then 
        coords = {{"CT Spawn","Throw","crouch",3304.9758300781,-1086.96875,-303.96875, -89.0,-90.99015045166},{"T Spawn","Throw","crouch",-2894.4489746094,-1256.9884033203,-408.47064208984, -85.708793640137,-90.246948242188}}
        loadedMap = "de_nuke"
    end
    if map == "de_mirage" and loadedMap ~= "de_mirage" then 
        coords = {{"T Spawn","Throw","crouch",1414.7142333984,27.624822616577,-167.968, -89.0, -1.3922407627106},{"CT Spawn","Throw","stand",-1516.3454589844,-1335.8951416016,-259.96875, -89.0, 0.01853758841753}} 
        loadedMap = "de_mirage"
    end
    if map == "de_dust2" and loadedMap ~= "de_dust2" then 
        coords = {{"T Spawn","Throw","stand",-786.35052490234,-1051.96875,128.29962158203, -89.0,-86.203414916992},{"CT Spawn","Throw","crouch",-57.96875,2010.03125,-121.51098632813, -89.0,179.06463623047}}
        loadedMap = "de_dust2"
    end
    if map == "de_inferno" and loadedMap ~= "de_inferno" then 
        coords = {{"CT Spawn","Throw","stand",1646.3775634766,1900.9371337891,160.03125, -89.0, -7.1046228408813},{"T Spawn","Throw","crouch",-1186.03125,585.96875,-55.96875, -89.0, 27.183813095093}}
        loadedMap = "de_inferno"
    end
    if map == "de_overpass" and loadedMap ~= "de_overpass" then 
        coords = {{"CT Spawn","Throw","crouch",-2322.8095703125,1267.4503173828,480.03125, -89.0,6.9663600921631},{"T Spawn","Throw","stand",-1058.9029541016,-3138.8576660156,272.03125, -89.0,-52.240837097168}}
        loadedMap = "de_overpass"
    end
    if map == "de_train" and loadedMap ~= "de_train" then 
        coords = {{"T Spawn","Throw","crouch",-1588.0235595703,1174.9838867188,-191.96875, -89.0,-0.029468365013599},{"CT Spawn","Throw","crouch",1651.6903076172,-844.18420410156,-319.96875, -89.0,1.3822977542877}}
        loadedMap = "de_train"
    end
    if map == "de_cache" and loadedMap ~= "de_cache" then 
        coords = {{"T Spawn","Throw","stand",1255.03125,172.47453308105,1613.03125, -89.0,-176.53729248047}, {"CT Spawn","Throw","stand",-1098.4376220703,121.03125,1614.1027832031, -89.0,-94.934463500977}}
        loadedMap = "de_cache"
    end
    if map == "cs_agency" and loadedMap ~= "cs_agency" then 
        coords = {{"CT Spawn","Throw","stand",-403.96875,-837.20361328125,321.03125, -89.0,-179.18190002441},{"CT Spawn","Throw","crouch",-651.84075927734,879.96875,512.03125, -89.0,123.8231048584}}
        loadedMap = "cs_agency"
    end
    if map == "cs_office" and loadedMap ~= "cs_office" then 
        coords = {{"CT Spawn","Throw","crouch",-991.96875,-1576.03125,-327.96875, -89.0,130.61959838867}}
        loadedMap = "cs_office"
    end
    if map == "de_vertigo" and loadedMap ~= "de_vertigo" then
        coords = {{"CT Spawn","Throw","crouch",-813.19244384766,967.98895263672,11818.03125, -89.0,89.763343811035},{"T Spawn","Throw","stand",-1223.1530761719,-1399.0194091797,11493.03125, -89.0,3.1573293209076}}
        loadedMap = "de_vertigo"
    end
    if map == "de_anubis" and loadedMap ~= "de_anubis" then
        coords = {{"CT Spawn","Throw","stand",-140.03125,2363.828125,52.03125, -89.0,0.39708650112152},{"T Spawn","Throw","stand",-509.96875,-283.28573608398,0.03125, -89.0,-152.59544372559}}
        loadedMap = "de_anubis"
    end
    if map == "de_chlorine" and loadedMap ~= "de_chlorine" then
        coords = {{"CT Spawn","Throw","crouch",4488.3012695313,-3631.5285644531,9.03125, -89.0,73.192726135254},{"T Spawn","Throw","crouch",4764.166015625,578.27105712891,-98.293960571289, -87.110221862793,-46.279232025146}}
        loadedMap = "de_chlorine"
    end
    
end

Hack.RegisterCallback("CreateMove", function (cmd, send)
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if (not pLocal) then return end

    posEye = pLocal:GetAbsOrigin()
    angEye = cmd.viewangles

    if aligning and foundClosest then

        --Define relavant vars
        local localPos = pLocal:GetAbsOrigin()
        local dist = Math.VectorDistance(localPos, closestPos)                     

        --Define and set Wanted Angle (this took so much time idk why)
        local wAng = QAngle.new(0,0,0)
        Math.VectorAngles(Vector.new(closestPos.x - localPos.x, closestPos.y - localPos.y, closestPos.z - localPos.z), wAng)

        --Debug
        Print("Dist from goal: " .. dist)

        --Incase it's above 700 units then make it 450 because if it's like above 1000 it wont move ingame, so sets it to normal moving speed (450)
        if dist > 700 then dist = 450 end

        --Set your forward speet to distance so it will move you towards the position
        cmd.viewangles = wAng
        cmd.forwardmove = dist + 1
        
        --if it's further than 0.007 units away from the point it wants to be at then just continue aligning
        if dist < 0.08 then
            aligning = false
        end

        if oldDist ~= 420 and (oldDist - dist) == 0 and (IGlobalVars.realtime - startedAlign) > 0.2 and startedAlign ~= -5 then 
            aligning = false
            oldDist = 420
        end

        oldDist = dist
    else
        aligning = false
    end

    if IGlobalVars.realtime < crouchTime then 
        cmd.buttons = SetBit(cmd.buttons, 2)
    end

    if fire then 
        cmd.buttons = SetBit(cmd.buttons, 0)
        fire = false
        fireTime = IGlobalVars.realtime + 1
    end

    if (not Utils.IsInGame()) then 
        coords = {}
        displayedID = 0
        loadedMap = {}
    end
    if (not Menu.GetBool("cEnableGriefNadeHelper")) then return end

    local weapon = pLocal:GetActiveWeapon()
    if (not weapon) then return end

    local wInfo = weapon:GetWeaponData()
    if (not wInfo) then return end

    local grenade = false
    if wInfo.consoleName == "weapon_hegrenade" then grenade = true end
    if InputSys.IsKeyPress(Menu.GetInt("cAGriefNadeThrow")) and throwType == 0 and grenade then
        executeStart = IGlobalVars.realtime
        executeTime = 0.5
        throwType = 1
    end
    if throwType == 1 then
        if executeStart <= IGlobalVars.realtime then
            if executeStart + executeTime >= IGlobalVars.realtime then
                cmd.buttons = SetBit(cmd.buttons, 0)
            else
                executeStart = IGlobalVars.realtime
                executeTime = 0.7
                throwType = 2
            end
        end
    end
    if throwType == 2 then
        if executeStart <= IGlobalVars.realtime then
            if executeStart + executeTime >= IGlobalVars.realtime then
                cmd.buttons = SetBit(cmd.buttons, 11)
            else
                executeStart = IGlobalVars.realtime + 0.7
                executeTime = 2
                throwType = 3
            end
        end
    end
    if throwType == 3 then
        if executeStart <= IGlobalVars.realtime then
            if executeStart + executeTime >= IGlobalVars.realtime then
                cmd.buttons = SetBit(cmd.buttons, 2)
            else
                executeStart = 0
                executeTime = 0
                throwType = 0
            end
        end
    end
    if throwType ~= 0 then
        cmd.viewangles = QAngle.new(-89.0, cmd.viewangles.yaw, 0)
        cmd.forwardmove = 0
        cmd.sidemove = 0
    end
    va = cmd.viewangles

    map = IEngine.GetLevelNameShort()

    --Load Coords
    if map == "de_nuke" and loadedMap ~= "de_nuke" then 
        coords = {{"CT Spawn","Throw","crouch",3304.9758300781,-1086.96875,-303.96875, -89.0,-90.99015045166},{"T Spawn","Throw","crouch",-2894.4489746094,-1256.9884033203,-408.47064208984, -85.708793640137,-90.246948242188}}
        loadedMap = "de_nuke"
    end
    if map == "de_mirage" and loadedMap ~= "de_mirage" then 
        coords = {{"T Spawn","Throw","crouch",1414.7142333984,27.624822616577,-167.968, -89.0, -1.3922407627106},{"CT Spawn","Throw","stand",-1516.3454589844,-1335.8951416016,-259.96875, -89.0, 0.01853758841753}} 
        loadedMap = "de_mirage"
    end
    if map == "de_dust2" and loadedMap ~= "de_dust2" then 
        coords = {{"T Spawn","Throw","stand",-786.35052490234,-1051.96875,128.29962158203, -89.0,-86.203414916992},{"CT Spawn","Throw","crouch",-57.96875,2010.03125,-121.51098632813, -89.0,179.06463623047}}
        loadedMap = "de_dust2"
    end
    if map == "de_inferno" and loadedMap ~= "de_inferno" then 
        coords = {{"CT Spawn","Throw","stand",1646.3775634766,1900.9371337891,160.03125, -89.0, -7.1046228408813},{"T Spawn","Throw","crouch",-1186.03125,585.96875,-55.96875, -89.0, 27.183813095093}}
        loadedMap = "de_inferno"
    end
    if map == "de_overpass" and loadedMap ~= "de_overpass" then 
        coords = {{"CT Spawn","Throw","crouch",-2322.8095703125,1267.4503173828,480.03125, -89.0,6.9663600921631},{"T Spawn","Throw","stand",-1058.9029541016,-3138.8576660156,272.03125, -89.0,-52.240837097168}}
        loadedMap = "de_overpass"
    end
    if map == "de_train" and loadedMap ~= "de_train" then 
        coords = {{"T Spawn","Throw","crouch",-1588.0235595703,1174.9838867188,-191.96875, -89.0,-0.029468365013599},{"CT Spawn","Throw","crouch",1651.6903076172,-844.18420410156,-319.96875, -89.0,1.3822977542877}}
        loadedMap = "de_train"
    end
    if map == "de_cache" and loadedMap ~= "de_cache" then 
        coords = {{"T Spawn","Throw","stand",1255.03125,172.47453308105,1613.03125, -89.0,-176.53729248047}, {"CT Spawn","Throw","stand",-1098.4376220703,121.03125,1614.1027832031, -89.0,-94.934463500977}}
        loadedMap = "de_cache"
    end
    if map == "cs_agency" and loadedMap ~= "cs_agency" then 
        coords = {{"CT Spawn","Throw","stand",-403.96875,-837.20361328125,321.03125, -89.0,-179.18190002441},{"CT Spawn","Throw","crouch",-651.84075927734,879.96875,512.03125, -89.0,123.8231048584}}
        loadedMap = "cs_agency"
    end
    if map == "cs_office" and loadedMap ~= "cs_office" then 
        coords = {{"CT Spawn","Throw","crouch",-991.96875,-1576.03125,-327.96875, -89.0,130.61959838867}}
        loadedMap = "cs_office"
    end
    if map == "de_vertigo" and loadedMap ~= "de_vertigo" then
        coords = {{"CT Spawn","Throw","crouch",-802.08764648438,703.08837890625,11776.03125, -0.51800179481506,89.412673950195},{"T Spawn","Throw","stand",-1223.1530761719,-1399.0194091797,11493.03125, -89.0,3.1573293209076}}
        loadedMap = "de_vertigo"
    end
    if map == "de_anubis" and loadedMap ~= "de_anubis" then
        coords = {{"CT Spawn","Throw","stand",-140.03125,2363.828125,52.03125, -89.0,0.39708650112152},{"T Spawn","Throw","stand",-509.96875,-283.28573608398,0.03125, -89.0,-152.59544372559}}
        loadedMap = "de_anubis"
    end
    if map == "de_chlorine" and loadedMap ~= "de_chlorine" then
        coords = {{"CT Spawn","Throw","crouch",4488.3012695313,-3631.5285644531,9.03125, -89.0,73.192726135254},{"T Spawn","Throw","crouch",4764.166015625,578.27105712891,-98.293960571289, -87.110221862793,-46.279232025146}}
        loadedMap = "de_chlorine"
    end
end)

Hack.RegisterCallback("FireEventClientSideThink", function(Event)
    if Event:GetName() == "decoy_started" then
        local Index = UIDToPlayer(Event:GetInt("userid"))
        local owner = IEntityList.GetPlayer(Index)
        if owner:IsTeammate() then
            local i = #playerID+1
            entID[i] = Event:GetInt("entityid")
            startTime[i] = IGlobalVars.realtime
            playerID[i] = Event:GetInt("userid")
            SendNotif("Decoy Started", 1, "Advanced Griefing", "Decoy thrown by \"" .. GetUsername(Index) .. "\"", false, 252, 3, 223, 4)
        end
    end
    if Event:GetName() == "decoy_detonate" then
        for i = 1, #playerID do
            if Event:GetInt("entityid") == entID[i] then
                table.remove(playerID, i)
                table.remove(entID, i)
                table.remove(startTime, i)
            end
        end
    end
    if Event:GetName() == "player_hurt" then
        local attackerID = UIDToPlayer(Event:GetInt("attacker"))
        local hurt = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("userid"))) 
        local attacker = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("attacker")))
        local dmg = Event:GetInt("dmg_health")

        if hurt ~= attacker then
            if hurt:IsTeammate() and attacker:IsTeammate() then
                damage[attackerID] = damage[attackerID] + dmg
            end
        end
    end
    if Event:GetName() == "player_death" then
        local attackerID = UIDToPlayer(Event:GetInt("attacker"))
        local hurt = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("userid"))) 
        local attacker = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("attacker")))
        
        if hurt ~= attacker then
            if hurt:IsTeammate() and attacker:IsTeammate() then
                kills[attackerID] = kills[attackerID] + 1
            end
        end
    end
end)

Setup()
