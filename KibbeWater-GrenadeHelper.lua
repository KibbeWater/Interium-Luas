Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - Grenade Helper")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Checkbox("Draw Line To Angle", "cHelperDrawLineAngle", true)
Menu.SliderInt("Render Distance", "cHelperRenderDistance", 50, 2000, "", 500)
Menu.Spacing()
Menu.Spacing()
Menu.Text("Publishing")
Menu.Separator()
Menu.InputText("Spot Name", "cSpotFName", "Not Named")
Menu.Combo("Throw Type", "cSpotThrowType", {"Throw", "RunThrow", "JumpThrow", "Right Click"}, 0)
Menu.Checkbox("Submit Spot", "cSubmitGrenadeSpot", false)
Menu.Spacing()
Menu.Text("You need to hold a smoke/molotov to submit")
Menu.Text("Abuse of the API will lead to a ban")

local viewAngle = QAngle.new(0, 0, 0)
local displayedID = 0
local map = ""
local loadedMap = ""

--Global Vars
local coords = {}

--For version handling
local ver = "v2.0"
local notifNew = false
local notifData = ""

FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Grenade Helper\\")

--Register Functions
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

function SplitLiteral(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "("..sep..")") do
            table.insert(t, str)
    end
    return t
end

function SendNotif(ID, type, title, msg, clr, r, g, b, expire)
    local clrBool = "false"
    if clr then clrBool = "true" end
    if Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime then
        Menu.SetString("NM_API_Payload", ID .. "*" .. type .. "*" .. title .. "*" .. msg .. "*" .. clrBool .. "*" .. r .. "*" .. g .. "*" .. b .. "*" .. (IGlobalVars.realtime + expire))
        Menu.SetBool("NM_API_Send", true)
    end
end

function Bool2String(boolz)
    if boolz then
        return "true"
    else
        return "false"
    end
end

--Set initial settings
function Setup()
    Print("Downloading version file...")
    URLDownloadToFile("https://kibbewater.xyz/ver/gh.txt", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gh.txt")
    Print("Download finished")
    if FileSys.FileIsExist(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gh.txt") then
        local fileData = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gh.txt")
        local data = Split(fileData, "\n")
        Print("Recieved data: " .. data[1])
        if #data == 2 then
            if ver ~= data[1] and Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and not Menu.GetBool("NM_API_Send") and Menu.GetString("NM_API_Payload") == "" then
                Menu.SetString("NM_API_Payload", "GHUpdates" .. "*" .. "1" .. "*" .. "Grenade Helper Update" .. "*" .. "Please download " .. data[1] .. ", check forums for the latest update" .. "*" .. "false" .. "*" .. "0" .. "*" .. "0" .. "*" .. "0" .. "*" .. (IGlobalVars.realtime + 7))
                Menu.SetBool("NM_API_Send", true)
            elseif Menu.GetInt("NM_API_Enabled") < IGlobalVars.realtime or Menu.GetBool("NM_API_Send") or Menu.GetString("NM_API_Payload") ~= "" then
                notifData = "GHUpdates" .. "*" .. "1" .. "*" .. "Grenade Helper Update" .. "*" .. "Please download " .. data[1] .. ", check forums for the latest update" .. "*" .. "false" .. "*" .. "0" .. "*" .. "0" .. "*" .. "0" .. "*"
                notifNew = true
            end
        end
    else
        Print("File not recieved")
        SendNotif("GHUpdates", 1, "Movement Recorder Update", "Error occured while getting current version", false, 0, 0, 0, IGlobalVars.realtime + 7)
    end
end

Hack.RegisterCallback("PaintTraverse", function ()
    if Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and notifNew and not Menu.GetBool("NM_API_Send") and Menu.GetString("NM_API_Payload") == "" then
        Menu.SetString("NM_API_Payload", notifData .. (IGlobalVars.realtime + 7))
        Menu.SetBool("NM_API_Send", true)
        notifNew = false
    end

    if (not Utils.IsLocalAlive()) then return end

    if not Utils.IsInGame() then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if (not pLocal) then return end

    local weapon = pLocal:GetActiveWeapon()
    if (not weapon) then return end

    local wInfo = weapon:GetWeaponData()
    if (not wInfo) then return end

    local localPos = pLocal:GetAbsOrigin()
    local wName = ""
    if wInfo.consoleName == "weapon_molotov" or wInfo.consoleName == "weapon_incgrenade" then wName = "molotov" elseif wInfo.consoleName == "weapon_smokegrenade" then wName = "smoke" else wName = "" end
    if wName ~= "" and map ~= "" and Menu.GetString("cSpotFName") ~= "" and Menu.GetBool("cSubmitGrenadeSpot") then
        local throwTypes = {"Throw", "RunThrow", "JumpThrow", "Right Click"}
        local pPos = pLocal:GetAbsOrigin()
        --FileSys.SaveTextToFile("https://kibbewater.xyz/interium/submitspot.php?username=" .. Hack.GetUserName() .. "&map=" .. map .. "&location=" .. Menu.GetString("cSpotFName") .. "&throwtype=" .. throwTypes[Menu.GetInt("cSpotThrowType")+1] .. "&grenadetype=" .. wName .. "&x=" .. tostring(pPos.x) .. "&y=" .. tostring(pPos.y) .. "&z=" .. tostring(pPos.z) .. "&pitch=" .. tostring(viewAngle.pitch) .. "&yaw=" .. tostring(viewAngle.yaw))
        URLDownloadToFile("https://kibbewater.xyz/interium/submitspot.php?username=" .. Hack.GetUserName() .. "&map=" .. map .. "&location=" .. Menu.GetString("cSpotFName") .. "&throwtype=" .. throwTypes[Menu.GetInt("cSpotThrowType")+1] .. "&grenadetype=" .. wName .. "&x=" .. tostring(pPos.x) .. "&y=" .. tostring(pPos.y) .. "&z=" .. tostring(pPos.z) .. "&pitch=" .. tostring(viewAngle.pitch) .. "&yaw=" .. tostring(viewAngle.yaw), GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\http.txt")
        local data = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\http.txt")
        if data ~= "true" then
            SendNotif("GHError", 1, "Submission Error", "Submission failed with '" .. data .. "'", false, 0, 0, 0, 7)
        else
            SendNotif("GH", 3, "Submission", "Thank you for your submitting '" .. Menu.GetString("cSpotFName") .. "'", false, 0, 0, 0, 7)
        end
        Menu.SetBool("cSubmitGrenadeSpot", false)
    end

    for i = 1, #coords do
        if #coords[i] == 8 and coords[i][3] == wName then
            if displayedID == 0 or i == displayedID then
                local string = coords[i][1] .. "\n" .. coords[i][2]
                local textPos = Vector.new(tonumber(coords[i][4]), tonumber(coords[i][5]), tonumber(coords[i][6]) + 50)
                local pos = Vector.new(tonumber(coords[i][4]), tonumber(coords[i][5]), tonumber(coords[i][6]))
                local ang = QAngle.new(tonumber(coords[i][7]), tonumber(coords[i][8]), 0)
                local angVec = Vector.new(0,0,0)
                local angVecEye = Vector.new(0,0,0)
                local toScreen = Vector.new(0,0,0)
                local sCircle = Vector.new(0,0,0)
                local dist = Math.VectorDistance(pos, localPos)
                local nadeDist = 300
                local screen = Vector.new(0,0,0)

                Math.AngleVectors(ang, angVec)
                Math.AngleVectors(viewAngle, angVecEye)

                local throwPos = Vector.new(pos.x + (angVec.x * nadeDist), pos.y + (angVec.y * nadeDist), pos.z + (angVec.z * nadeDist) + 64)
                local throwPosText = Vector.new(pos.x + (angVec.x * nadeDist), pos.y + (angVec.y * nadeDist), pos.z + (angVec.z * nadeDist) + 54)
                local screenThrow = Vector.new(0,0,0)
                
                local eyePosition = Vector.new(localPos.x + (angVecEye.x * nadeDist), localPos.y + (angVecEye.y * nadeDist), localPos.z + (angVecEye.z * nadeDist) + 64)
                local aimDist = Math.VectorDistance(eyePosition, throwPos)

                if Math.WorldToScreen(textPos, toScreen) and dist <= Menu.GetInt("cHelperRenderDistance") and dist >= 50 then
                    Render.Text_1(string, toScreen.x, toScreen.y, 15, Color.new(255, 255, 255, 255), false, true)
                end
                if dist <= Menu.GetInt("cHelperRenderDistance") then
                    local radius = 17
                    local color = Color.new(255,0,0,255)
                    if dist >= 17 then radius = 27 else radius = 7 end
                    if dist <= 2 then 
                        displayedID = i
                        color = Color.new(0,255,0,255) 
                    else color = Color.new(255,0,0,255) end
                
                    Render.Circle3D(pos, 100, radius, color)
                    --Render.Circle(sCircle.x, sCircle.y, radius, color, 25, 2)
                end
                if Math.WorldToScreen(throwPos, screenThrow) and dist <= 5 then
                    if Math.WorldToScreen(throwPosText, screen) then Render.Text_1(string, screen.x, screen.y, 15, Color.new(255, 255, 255, 255), false, true) end
                    local color = Color.new(255,0,0,255)
                    if aimDist <= 1.5 then color = Color.new(0,255,0,255) end
                    displayedID = i
                    Render.Circle(screenThrow.x, screenThrow.y, 8, color, 25, 2)
                    if Menu.GetBool("cHelperDrawLineAngle") then Render.Line(Globals.ScreenWidth()/2, Globals.ScreenHeight()/2, screenThrow.x, screenThrow.y, color, 1) end
                end
                if displayedID == i and dist >= 3 then displayedID = 0 end
            end
        end
    end
end)

function LineToObject(line)
    local data = Split(line, "*")

    return {data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8]}
end

Hack.RegisterCallback("CreateMove", function (cmd, send)
    if (not Utils.IsInGame()) then 
        coords = {}
        displayedID = 0
        loadedMap = ""
    end
    if (not Utils.IsLocal()) then return end

    map = IEngine.GetLevelNameShort()
    viewAngle = cmd.viewangles

    --Load Coords
    if map ~= loadedMap then 
        URLDownloadToFile("https://kibbewater.xyz/interium/getspots.php?map=" .. map, GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Grenade Helper\\" .. map .. ".txt")
        local data = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Grenade Helper\\" .. map .. ".txt"):gsub("<br>", "\n")
        local locations = Split(data, "\n")
        coords = {}
        for i = 1, #locations do
            table.insert(coords, LineToObject(locations[i]))
        end
        loadedMap = map
    end
end)

Setup()
