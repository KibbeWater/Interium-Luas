local isDev = Hack.GetUserName() == "KibbeWater" --Doesn't do fking anything but whatever, knock yourself out

Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - Grenade Helper")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Checkbox("Draw Line To Angle", "cHelperDrawLineAngle", true)
Menu.SliderInt("Render Distance", "cHelperRenderDistance", 50, 4000, 1, 1000)
Menu.KeyBind("Auto-Align with closest point", "cHelperAlignKey", 78)
if isDev then Menu.Checkbox("View Submissions (DEV)", "cHelperDevSubmissions", false) end
Menu.Checkbox("Reviewer Mode", "cReviewerMode", false)
Menu.Checkbox("Disable Remote Spots", "cDisableRemote", false)
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

local API_URL = "https://kibbewater.com/interium"
local DATA_PATH = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Grenade Helper\\"
local HTTP_PATH = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\http.txt"

local viewAngle = QAngle.new(0, 0, 0)
local displayedID = 0
local map = ""
local loadedMap = ""

--Global Vars
local coords = {}

--Aligner Vars
local isAligning = false
local isAiming = false
local alignPos = Vector.new(0,0,0)
local alignAng = QAngle.new(0,0,0)

FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Grenade Helper\\")

--Register Functions
local function Split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

local function Clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

local function LineToObject(line)
    local data = Split(line, "*")

    return {data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8]}
end

local function FindClosest(pos, grenadeName)
    local closestCoord = 0
    local closestPos = Vector.new(0,0,0)
    for i = 1, #coords do
        if coords[i][3] == grenadeName then
            local curPos = Vector.new(tonumber(coords[i][4]), tonumber(coords[i][5]), tonumber(coords[i][6]))

            local distToCur = Math.VectorDistance(pos, curPos)
            local distToClosest = Math.VectorDistance(pos, closestPos)

            if distToCur < distToClosest or closestPos == Vector.new(0,0,0) then
                closestCoord = i
                closestPos = curPos
            end
        end
    end

    return closestCoord
end

Hack.RegisterCallback("PaintTraverse", function ()
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
        URLDownloadToFile(API_URL .. "/submitspot.php?username=" .. Hack.GetUserName() .. "&map=" .. map .. "&location=" .. Menu.GetString("cSpotFName") .. "&throwtype=" .. throwTypes[Menu.GetInt("cSpotThrowType")+1] .. "&grenadetype=" .. wName .. "&x=" .. tostring(pPos.x) .. "&y=" .. tostring(pPos.y) .. "&z=" .. tostring(pPos.z) .. "&pitch=" .. tostring(viewAngle.pitch) .. "&yaw=" .. tostring(viewAngle.yaw), HTTP_PATH)
        local data = FileSys.GetTextFromFile(HTTP_PATH)
        if data ~= "true" then
            --Submission failed
        else
            Menu.SetString("cSpotFName", "")
        end
        Menu.SetBool("cSubmitGrenadeSpot", false)
    end

    if InputSys.IsKeyPress(Menu.GetInt("cHelperAlignKey")) then
        local cP = FindClosest(pLocal:GetAbsOrigin(), wName)

        if cP ~= 0 then
            local closestPos = Vector.new(tonumber(coords[cP][4]), tonumber(coords[cP][5]), tonumber(coords[cP][6]))
            local closestAng = QAngle.new(tonumber(coords[cP][7]), tonumber(coords[cP][8]), 0)

            local closestDist = Math.VectorDistance(localPos, closestPos)
            if closestDist < 100 then
                alignPos = closestPos
                alignAng = closestAng
                if isAiming then
                    isAiming = false
                else isAligning = not isAligning end
            end
        end
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

local lastForcedUpdate = 0
local forceGrenadeUpdate = false
local oldDisableRemote = false
local oldReviewMode = false
Hack.RegisterCallback("CreateMove", function (cmd, send)
    if not Utils.IsInGame() then 
        coords = {}
        displayedID = 0
        loadedMap = ""
        return
    end
    if not Utils.IsLocal() then return end

    map = IEngine.GetLevelNameShort()
    viewAngle = cmd.viewangles

    if (lastForcedUpdate + 0.5 < IGlobalVars.realtime and Menu.GetBool("cReviewerMode")) or (Menu.GetBool("cReviewerMode") ~= oldReviewMode) then 
        forceGrenadeUpdate = true 
    end
    if oldDisableRemote ~= Menu.GetBool("cDisableRemote") then forceGrenadeUpdate = true end

    --Load Coords
    if map ~= loadedMap or forceGrenadeUpdate then 
        local apiEndpoint = "getspots"

        if isDev and Menu.GetBool("cHelperDevSubmissions") then apiEndpoint = "getsubmissions" end

        if map ~= loadedMap and not Menu.GetBool("cDisableRemote") then URLDownloadToFile(API_URL .. "/" .. apiEndpoint .. ".php?map=" .. map, DATA_PATH .. map .. ".txt") end
        
        local data = ""
        if not Menu.GetBool("cDisableRemote") then data = FileSys.GetTextFromFile(DATA_PATH .. map .. ".txt"):gsub("<br>", "\n") end
        
        local custom = ""
        if FileSys.FileIsExist(DATA_PATH .. map .. "_custom.txt") then custom = FileSys.GetTextFromFile(DATA_PATH .. map .. "_custom.txt"):gsub("<br>", "\n") end
        local reviewer = ""
        if FileSys.FileIsExist(DATA_PATH .. map .. "_review.txt") and Menu.GetBool("cReviewerMode") then reviewer = FileSys.GetTextFromFile(DATA_PATH .. map .. "_review.txt"):gsub("<br>", "\n") end
        
        if custom ~= "" then if data ~= "" then data = data .. "\n" .. custom else data = custom end end
        if reviewer ~= "" then if data ~= "" then data = data .. "\n" .. reviewer else data = reviewer end end
        
        local locations = Split(data, "\n")
        coords = {}
        
        for i = 1, #locations do
            if #Split(locations[i], "*") >= 8 then
                table.insert(coords, LineToObject(locations[i]))
            end
        end
        loadedMap = map
        isAligning = false

        
        forceGrenadeUpdate = false
        lastForcedUpdate = IGlobalVars.realtime
    end

    oldDisableRemote = Menu.GetBool("cDisableRemote")
    oldReviewMode = Menu.GetBool("cReviewerMode")

    if not Utils.IsLocalAlive() then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if not pLocal then return end

    local localPos = pLocal:GetAbsOrigin()

    if isAligning then
        local wAng = QAngle.new(0,0,0)
        Math.VectorAngles(Vector.new(alignPos.x - localPos.x, alignPos.y - localPos.y, alignPos.z - localPos.z), wAng)
        
        local dist = Math.VectorDistance(localPos, alignPos)
        
        if dist < 0.08 then
            isAligning = false
            isAiming = true
        end
        
        local clientAng = QAngle.new(0,0,0)
        IEngine.GetViewAngles(clientAng)

        cmd.forwardmove = dist + 10
        Utils.CorrectMovement(wAng, cmd, cmd.forwardmove, 0, false)
    end

    if isAiming then
        --View aligning
        local oldVA = QAngle.new()
        IEngine.GetViewAngles(oldVA)
        
        if alignAng.yaw - oldVA.yaw > 30 or alignAng.yaw - oldVA.yaw < -30 then
            oldVA.yaw = oldVA.yaw + 360
            if alignAng.yaw - oldVA.yaw > 30 or alignAng.yaw - oldVA.yaw < -30 then
                oldVA.yaw = oldVA.yaw - 720
            end
        end
        
        local angDiff = ((alignAng.pitch+180) - (oldVA.pitch+180)) / 10
        local angDiffYaw = 0

        angDiffYaw = ((alignAng.yaw+180) - (oldVA.yaw+180)) / 10
        if ((alignAng.yaw+180) - (oldVA.yaw+180)>(oldVA.yaw+180) + (360 - (alignAng.yaw+180))) then angDiffYaw = (((oldVA.yaw+180) + (360 - (alignAng.yaw+180)))*-1) / 10 end
        
        local clampAmount = 3
        local clampAmountYaw = 2
        
        local angYaw = Clamp(angDiffYaw,clampAmountYaw*-1,clampAmountYaw)
        local angPitch = Clamp(angDiff,clampAmount*-1,clampAmount)
        
        local newViewang = QAngle.new()
        newViewang.roll = 0
        newViewang.yaw = oldVA.yaw + angYaw
        newViewang.pitch = oldVA.pitch + angPitch

        

        local dizt = Math.VectorDistance(localPos, alignPos)
        if (math.abs(angYaw) <= 0.001 and math.abs(angPitch) <= 0.001) or dizt > 1 then isAiming = false end
        
        IEngine.SetViewAngles(newViewang)
    end
end)
