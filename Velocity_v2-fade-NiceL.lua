-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Velocity")
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Show Velocity", "bShowVelocity", true)
Menu.Checkbox("Show Takeoff Velocity", "bShowTakeoffVel", true)
Menu.Checkbox("Show Stamina", "bShowStamina", true)
Menu.Checkbox("Show Takeoff Stamina", "bShowTakeoffStamina", true)
Menu.Checkbox("Show Units", "bShowUnits", true)
Menu.Checkbox("Show Vert", "bShowVert", true)


Menu.SetInt("iShowVelocityOld", 1)
Menu.SetInt("iShowVert", 1)

Menu.Spacing()
Menu.Spacing()
Menu.Text("Stats")
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Show JB Status", "bShowJBStatus", true)
Menu.Checkbox("Show Round Info to Chat", "bShowRoundInfo", true)
Menu.Checkbox("Show LJ Stat to Chat", "bShowLJInfo", true)
Menu.Checkbox("Enable LJ Sounds", "bEnableLJSound", true)

Menu.Spacing()
Menu.Spacing()
Menu.Text("Graph")
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Show Velocity Graph", "bShowVelocityGraph", true)
Menu.Checkbox("Show Stamina Graph", "bShowStaminaGraph", true)
Menu.Checkbox("Show Graph Start Line", "bShowVelocityLine1", true)
Menu.Checkbox("Show Velocity Old on Graph", "bShowVelocityOldOnGraph", true)
Menu.Checkbox("Show Velocity Plus on Graph", "bShowVelocityPlusOnGraph", true)
Menu.Checkbox("Show JB on Graph", "bShowJBOnGraph", true)

Menu.Spacing()
Menu.Spacing()
Menu.Text("Fading")
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Fade Velocity", "bFadeVel", true)
Menu.Checkbox("Fade Stamina", "bFadeStamina", true)
Menu.Checkbox("Fade Graph", "bFadeGraph", true)

Menu.Spacing()
Menu.Spacing()
Menu.Text("Indicator Colors")
Menu.Separator()
Menu.Spacing()
Menu.ColorPicker("Jumpbug Indicator", "cIndJB", 255, 255, 255, 255)
Menu.ColorPicker("Jumpbug Detected", "cIndJBD", 255, 0, 0, 255)

Menu.Spacing()
Menu.Spacing()
Menu.Text("Sizing")
Menu.Separator()
Menu.Spacing()
Menu.SliderInt("Graph Fade", "fGraphFade", 0, 50, 1, 5)
Menu.SliderFloat("Graph Size X", "fGraphSizeX", 1, 1000, "%.0f", 200)
Menu.SliderFloat("Graph Size Y", "fGraphSizeY", 0, 3, "%.2f", 0.5)
Menu.SliderFloat("Pos Y", "fVelPosY", 0, 10, "%.2f", 1.2)


-- Init need Files
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\Velocity_v2-NiceL\\")
URLDownloadToFile("https://cdn.discordapp.com/attachments/673132064295485490/678738952412332069/perfect.wav",
    GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\Velocity_v2-NiceL\\perfect.wav")
URLDownloadToFile("https://cdn.discordapp.com/attachments/673132064295485490/678738951535853639/ownage.wav",
    GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\Velocity_v2-NiceL\\ownage.wav")
URLDownloadToFile("https://cdn.discordapp.com/attachments/673132064295485490/678738953070706689/godlike.wav",
    GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\Velocity_v2-NiceL\\godlike.wav")
URLDownloadToFile("https://cdn.discordapp.com/attachments/382580856621105164/678729162097426432/comboking.wav",
    GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\Velocity_v2-NiceL\\comboking.wav")


-- Customize from Menu
local PosY = 0
local SizeY = 0

local TextOffsetY = 0

-- Offsets
local fFlags_Offset = Hack.GetOffset("DT_BasePlayer", "m_fFlags")
local vVelocity_Offset = Hack.GetOffset("DT_BasePlayer", "m_vecVelocity[0]")
local vOrigin_Offset = Hack.GetOffset("DT_BaseEntity", "m_vecOrigin")
local fStamina_Offset = Hack.GetOffset("DT_CSPlayer", "m_flStamina")

-- Flag States
local ON_GROUND = 0

-- For Vec
local function VecLenght(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
end

local function VecLenght2D(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

local function Dist(Vec1, Vec2)
    local vBuf = Vector.new()

    vBuf.x = Vec1.x - Vec2.x
    vBuf.y = Vec1.y - Vec2.y
    vBuf.z = Vec1.z - Vec2.z

    return VecLenght2D(vBuf)
end

local function Clamp(n, min, max)
    if n < min then return min elseif n > max then return max else return n end
end

local function s(c, t, f)
    if c then return t else return f end
end

local MoveType_NOCLIP = 8
local MoveType_LADDER = 9
local function IsCanMovement(MoveType)
    if (MoveType == MoveType_NOCLIP or MoveType == MoveType_LADDER) then
        return false
    end

    return true
end

local fVelocity_old = 0 -- Just Velocity old for all
local vVelocity_old = Vector.new() -- For Check JB

local fStamina_old = 0 -- Just Stamina old for all

-- Info For Round
local Jumps = 0
local Strafes = 0
local JBs = 0

-- Graph
local Mnoj = 5
local VelocityArray = {}
local StaminaArray = {}
local PlusOnGroundVelocityArray = {}
local OnGroundVelocityArray = {}
local IsJBArray = {}
local VelocityrraySize = 150
for i = 1, 9999 do
    VelocityArray[i] = 0
    StaminaArray[i] = 0
    PlusOnGroundVelocityArray[i] = -999
    OnGroundVelocityArray[i] = -999
    IsJBArray[i] = -999
end

-- Ignore some Times
local OnGroundTime = 0
local OnGroundTimeMax = 1250 -- Visual
local NotJumpingTimeMax = 100 -- Rebuild

-- For Velocity Old
local IsOnGroud_old = false
local VelocityOnGround_old = 0
local VelocityOnGround = 0
local StaminaOnGround_old = 0
local StaminaOnGround = 0
-- For JB Status
local IsJBTime = 0
local IsJBTimeMax = 250
-- Units
local LastUnits = 0
local LastVert = 0
local vOriginOnGround = Vector.new()

-- KZ
local KZ_Jumps = 0
local KZ_TimeMax = 25
local KZ_ComboOf245 = 0
--
local KZ_Strafes = 0
local KZ_MaxVelocity = 0
local KZ_PreVelocity = 0

function BuildVelocityInfo(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    if (not IsCanMovement(iMoveType)) then return end

    -- Build Velocity
    if (IsBit(Flags, ON_GROUND)) then
        if (OnGroundTime == 0) then OnGroundTime = GetTickCount() end
    else
        if (OnGroundTime > 0 and GetTickCount() > (OnGroundTime + NotJumpingTimeMax)) then
            VelocityOnGround_old = 0
            VelocityOnGround = 0

            StaminaOnGround_old = 0
            StaminaOnGround = 0

            --LastUnits = 0
            --LastVert = 0
        end
        OnGroundTime = 0
    end

    -- KZ
    if (IsOnGroud_old and not IsBit(Flags, ON_GROUND)) then
        KZ_Jumps = KZ_Jumps + 1
    elseif (vVelocity_old.z < 0 and vVelocity.z > 0) then
        KZ_Jumps = KZ_Jumps + 1
    end
    if (not IsBit(Flags, ON_GROUND)) then
        if (KZ_PreVelocity == 0) then KZ_PreVelocity = fVelocity end
        if (KZ_MaxVelocity < fVelocity) then KZ_MaxVelocity = fVelocity end
        if (KZ_PreZ == 0) then KZ_PreZ = math.abs(vOrigin.z) end
        if (vVelocity.z > 0) then KZ_MaxZ = math.abs(vOrigin.z) end
    end
    if (OnGroundTime > 0 and GetTickCount() > (OnGroundTime + KZ_TimeMax)) then
        if (KZ_Jumps == 1 and LastUnits > 200 and LastUnits < 300 and math.abs(LastVert) <= 1) then
            -- Check Level
            KZ_Level = 0
            if (LastUnits >= 230 and LastUnits < 240) then
                KZ_Level = 1
            elseif (LastUnits >= 240 and LastUnits < 245) then
                KZ_Level = 2
            elseif (LastUnits >= 245 and KZ_ComboOf245 < 2) then
                KZ_Level = 3
            elseif (LastUnits >= 245 and KZ_ComboOf245 >= 2) then
                KZ_Level = 4
            end

            -- LJ Stat to Chat
            if (Menu.GetBool("bShowLJInfo")) then
                local LogoColor = "\x06"

                if (KZ_Level == 1) then
                    LogoColor = "\x0C"
                elseif (KZ_Level == 2) then
                    LogoColor = "\x03"
                elseif (KZ_Level == 3) then
                    LogoColor = "\x10"
                elseif (KZ_Level == 4) then
                    LogoColor = "\x02"
                end

                local Text = "[" .. LogoColor .. "INTERIUM\x01] "
                Text = Text .. "\x08Units: \x06" .. LastUnits
                Text = Text .. "\x01 | \x08Strafes: \x06" .. KZ_Strafes
                Text = Text ..
                    "\x01 | \x08Speed: \x06" ..
                    "\x01( \x06" .. KZ_PreVelocity .. "\x01 / \x06" .. KZ_MaxVelocity .. "\x01 )\x06"
                if (Menu.GetBool("bShowLJInfo")) then IChatElement.ChatPrintf(0, 0, Text) end
            end
        end

        KZ_Jumps = 0

        KZ_Strafes = 0
        KZ_MaxVelocity = 0
        KZ_PreVelocity = 0
    end


    -- Build Velocity
    if (IsOnGroud_old and not IsBit(Flags, ON_GROUND)) then -- Just Jump ?
        VelocityOnGround_old = VelocityOnGround
        VelocityOnGround = fVelocity
        StaminaOnGround = fStamina

        Jumps = Jumps + 1

        if (VelocityOnGround ~= 0) then
            OnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround
        end
        if (VelocityOnGround_old ~= 0 and VelocityOnGround ~= 0) then
            PlusOnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround - VelocityOnGround_old
        end
    else -- JB ?
        if (vVelocity_old.z < 0 and vVelocity.z > 0) then
            IsJBArray[VelocityrraySize * 2] = 1
            IsJBTime = GetTickCount() + IsJBTimeMax
            JBs = JBs + 1

            VelocityOnGround_old = VelocityOnGround
            VelocityOnGround = fVelocity

            StaminaOnGround_old = StaminaOnGround
            StaminaOnGround = fStamina

            if (VelocityOnGround ~= 0) then
                OnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround
            end
            if (VelocityOnGround_old ~= 0 and VelocityOnGround ~= 0) then
                PlusOnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround - VelocityOnGround_old
            end
        end
    end


    -- Save Units with with JB
    if (vVelocity_old.z < 0 and vVelocity.z > 0) then
        LastUnits = math.floor((Dist(vOriginOnGround, vOrigin) + 37 + 0.5) * 100) / 100
        LastVert = math.floor((vOriginOnGround.z - vOrigin.z) * -1 + 3 + 0.5)
        vOriginOnGround = vOrigin
    end
    -- Save Units with Jumps
    if (not IsOnGroud_old and IsBit(Flags, ON_GROUND)) then
        LastUnits = math.floor((Dist(vOriginOnGround, vOrigin) + 37 + 0.5) * 100) / 100
        LastVert = math.floor((vOriginOnGround.z - vOrigin.z) * -1 + 3 + 0.5)
    elseif (IsOnGroud_old and IsBit(Flags, ON_GROUND) or IsOnGroud_old and not IsBit(Flags, ON_GROUND)) then
        vOriginOnGround = vOrigin
    end

    if (LastUnits > 500) then
        LastUnits = 0
        LastVert = 0
    end

    -- Delete OnGround Saves bc u r OnGround so long
    if (IsBit(Flags, ON_GROUND) and GetTickCount() > (OnGroundTime + OnGroundTimeMax)) then
        VelocityOnGround_old = 0
        VelocityOnGround = 0

        StaminaOnGround_old = 0
        StaminaOnGround = 0

        LastUnits = 0
        LastVert = 0
    end
end

function DrawGraph(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    if (not Menu.GetBool("bShowVelocityGraph")) then
        return
    end

    -- Render Graph
    local NoRender = false
    local pointsToFade = (VelocityrraySize * 2) * (Menu.GetInt("fGraphFade") / 100)
    local fadePerPoint = 255 / pointsToFade
    local arrSize = VelocityrraySize * 2
    local polyIdx = 0
    for i = 2, VelocityrraySize * 2 do
        if (VelocityArray[i] ~= -999) then
            local VelNow = VelocityArray[i]
            if (VelNow > 400) then VelNow = 400 end
            if (VelNow < 0) then VelNow = 0 end

            local VelOld = VelocityArray[i - 1]
            if (VelOld > 400) then VelOld = 400 end
            if (VelOld < 0) then VelOld = 0 end

            local isFade = false
            local alpha = 255
            if i <= pointsToFade then
                alpha = math.floor(255 - (fadePerPoint * (pointsToFade - i)))
                isFade = true
            elseif i >= arrSize - pointsToFade then
                alpha = math.floor(255 - (fadePerPoint * (pointsToFade - (arrSize - i))))
                isFade = true
            end

            if isFade then
                Render.Line(Globals.ScreenWidth() / 2 - VelocityrraySize + i, PosY - VelOld * SizeY,
                    Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - VelNow * SizeY,
                    Color.new(255, 255, 255, alpha), 1
                )
            else
                Render.AddPoly(polyIdx, Globals.ScreenWidth() / 2 - VelocityrraySize + i, PosY - VelOld * SizeY)
                Render.AddPoly(polyIdx + 1, Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - VelNow * SizeY)
                polyIdx = polyIdx + 2
            end

            if i + 1 <= pointsToFade or i + 1 >= arrSize - pointsToFade then
                Render.Poly(polyIdx, Color.new(255, 255, 255, alpha), false, 1)
                polyIdx = 0
            end

            -- Render Speed
            if (OnGroundVelocityArray[i] ~= -999 and Menu.GetBool("bShowVelocityOldOnGraph")) then
                local Text = tostring(OnGroundVelocityArray[i])
                if (PlusOnGroundVelocityArray[i] ~= -999 and Menu.GetBool("bShowVelocityPlusOnGraph")) then
                    Text = "(" .. Text .. ")"
                end

                if (VelOld > VelNow) then
                    Render.Text_1(Text, Globals.ScreenWidth() / 2 - VelocityrraySize + i, PosY - VelOld * SizeY - 16, 12
                        , Color.new(200, 200, 200, 255), true, true)
                else
                    Render.Text_1(Text, Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - VelNow * SizeY - 16
                        , 12, Color.new(200, 200, 200, 255), true, true)
                end

                --Render.Text_1(PlusOnGroundVelocityArray[i], Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1 - 1, PosY - OnGroundVelocityArray[i] * SizeY - 43, 12, col3, true, true)
                --Render.Text_1("(" .. OnGroundVelocityArray[i] .. ")", Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - OnGroundVelocityArray[i] * SizeY - 32, 12, Color.new(200, 200, 200, 255), true, true)
            end

            -- Render Speed Plus
            if (PlusOnGroundVelocityArray[i] ~= -999 and Menu.GetBool("bShowVelocityPlusOnGraph")) then

                local Text = tostring(PlusOnGroundVelocityArray[i])
                if (PlusOnGroundVelocityArray[i] >= 0) then
                    Text = "+" .. Text
                end

                local col3 = Color.new()
                if (PlusOnGroundVelocityArray[i] > 0) then
                    col3 = Color.new(100, 225, 25, 255)
                elseif (PlusOnGroundVelocityArray[i] < 0) then
                    col3 = Color.new(225, 50, 50, 255)
                else
                    col3 = Color.new(255, 150, 50, 255)
                end

                if (VelOld > VelNow) then
                    Render.Text_1(Text, Globals.ScreenWidth() / 2 - VelocityrraySize + i - 1, PosY - VelOld * SizeY - 28
                        , 12, col3, true, true)
                else
                    Render.Text_1(Text, Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1 - 1,
                        PosY - VelNow * SizeY - 28, 12, col3, true, true)
                end

                --Render.Text_1(PlusOnGroundVelocityArray[i], Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1 - 1, PosY - OnGroundVelocityArray[i] * SizeY - 43, 12, col3, true, true)
                --Render.Text_1("(" .. OnGroundVelocityArray[i] .. ")", Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - OnGroundVelocityArray[i] * SizeY - 32, 12, Color.new(200, 200, 200, 255), true, true)
            end

            -- Render JB
            if (IsJBArray[i] == 1 and Menu.GetBool("bShowJBOnGraph")) then
                if (VelOld > VelNow) then
                    Render.Text_1("JB", Globals.ScreenWidth() / 2 - VelocityrraySize + i, PosY - VelOld * SizeY - 40, 12
                        , Color.new(25, 100, 255, 255), true, true)
                else
                    Render.Text_1("JB", Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - VelNow * SizeY - 40
                        , 12, Color.new(25, 100, 255, 255), true, true)
                end

                --Render.Text_1(PlusOnGroundVelocityArray[i], Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1 - 1, PosY - OnGroundVelocityArray[i] * SizeY - 43, 12, col3, true, true)
                --Render.Text_1("(" .. OnGroundVelocityArray[i] .. ")", Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - OnGroundVelocityArray[i] * SizeY - 32, 12, Color.new(200, 200, 200, 255), true, true)
            end
        end
    end
end

function DrawStaminaGraph(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    if (not Menu.GetBool("bShowStaminaGraph")) then
        return
    end

    -- Render Graph
    local pointsToFade = (VelocityrraySize * 2) * (Menu.GetInt("fGraphFade") / 100)
    local fadePerPoint = 255 / pointsToFade
    local arrSize = VelocityrraySize * 2
    local polyIdx = 0
    for i = 2, VelocityrraySize * 2 do
        if (StaminaArray[i] ~= -999) then
            local StaminaNow = StaminaArray[i] * 2
            local StaminaOld = StaminaArray[i - 1] * 2

            local isFade = false
            local alpha = 255
            if i <= pointsToFade then
                alpha = math.floor(255 - (fadePerPoint * (pointsToFade - i)))
                isFade = true
            elseif i >= arrSize - pointsToFade then
                alpha = math.floor(255 - (fadePerPoint * (pointsToFade - (arrSize - i))))
                isFade = true
            end

            if isFade then
                Render.Line(Globals.ScreenWidth() / 2 - VelocityrraySize + i, PosY - StaminaOld * SizeY,
                    Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - StaminaNow * SizeY,
                    Color.new(25, 100, 255, alpha), 1
                )
            else
                Render.AddPoly(polyIdx, Globals.ScreenWidth() / 2 - VelocityrraySize + i, PosY - StaminaOld * SizeY)
                Render.AddPoly(polyIdx + 1, Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1,
                    PosY - StaminaNow * SizeY)
                polyIdx = polyIdx + 2
            end

            if i + 1 <= pointsToFade or i + 1 >= arrSize - pointsToFade then
                Render.Poly(polyIdx, Color.new(25, 100, 255, alpha), false, 1)
                polyIdx = 0
            end
        end
    end
end

function DrawVelocity(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    -- Render Velocity or Velocity with Old Velocity [TYPE 1]
    local Text = tostring(fVelocity)
    if (not Menu.GetBool("bShowVelocity")) then
        Text = ""
    end
    --if (Menu.GetInt("iShowVelocityOld") == 1 and VelocityOnGround > 0) then
    --    Text = Text .. " (" .. tostring(VelocityOnGround) .. ")"
    --end

    local alpha = 255
    if Menu.GetBool("bFadeVel") then
        alpha = Clamp(fVelocity / 250, 0, 1) * 255
    end

    -- Build Speed Color
    local col = Color.new()
    if (fVelocity > fVelocity_old) then
        col = Color.new(255, 255, 255, alpha)
    elseif (fVelocity < fVelocity_old) then
        col = Color.new(255, 255, 255, alpha)
    else
        col = Color.new(255, 255, 255, alpha)
    end


    if (Menu.GetInt("iShowVelocityOld") == 1 and VelocityOnGround > 0) then
        -- Build Velocity Color
        local col2 = Color.new()
        if (VelocityOnGround > VelocityOnGround_old) then
            col2 = Color.new(255, 255, 255, alpha)
        elseif (VelocityOnGround < VelocityOnGround_old) then
            col2 = Color.new(255, 255, 255, alpha)
        else
            col2 = Color.new(255, 255, 255, alpha)
        end

        Render.Text_1(Text,
            Globals.ScreenWidth() / 2 -
            s(Menu.GetBool("bShowTakeoffVel"), Render.CalcTextSize_1("(" .. VelocityOnGround .. ")", 24).x, 0) / 2,
            PosY + 10 + TextOffsetY, 24, col, true, true)

        if Menu.GetBool("bShowTakeoffVel") then
            Render.Text_1("(" .. VelocityOnGround .. ")",
                Globals.ScreenWidth() / 2 - Render.CalcTextSize_1("(" .. VelocityOnGround .. ")", 24).x / 2 +
                Render.CalcTextSize_1(Text, 24).x / 2 + 4, PosY + 10 + TextOffsetY, 24, col2, false, true)
        end
    else
        Render.Text_1(Text, Globals.ScreenWidth() / 2, PosY + 10 + TextOffsetY, 24, col, true, true)
    end

    TextOffsetY = TextOffsetY + 22
end

function DrawStamina(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    -- Render Velocity or Velocity with Old Velocity [TYPE 1]
    local Text = tostring(math.floor(fStamina * 10) / 10)
    if (not Menu.GetBool("bShowStamina")) then
        Text = ""
    end
    --if (Menu.GetInt("iShowVelocityOld") == 1 and VelocityOnGround > 0) then
    --    Text = Text .. " (" .. tostring(VelocityOnGround) .. ")"
    --end

    local alpha = 255
    if Menu.GetBool("bFadeStamina") then
        alpha = Clamp(fStamina / 30, 0, 1) * 255
    end

    -- Build Speed Color
    local col = Color.new()
    if (fStamina > fStamina_old) then
        col = Color.new(255, 255, 255, alpha)
    elseif (fStamina < fStamina_old) then
        col = Color.new(255, 255, 255, alpha)
    else
        col = Color.new(255, 255, 255, alpha)
    end


    if (Menu.GetInt("iShowVelocityOld") == 1 and StaminaOnGround > 0) then
        -- Build Velocity Color
        local col2 = Color.new()
        if (StaminaOnGround > StaminaOnGround_old) then
            col2 = Color.new(255, 255, 255, alpha)
        elseif (StaminaOnGround < StaminaOnGround_old) then
            col2 = Color.new(255, 255, 255, alpha)
        else
            col2 = Color.new(255, 255, 255, alpha)
        end

        Render.Text_1(Text,
            Globals.ScreenWidth() / 2 -
            s(Menu.GetBool("bShowTakeoffStamina"),
                Render.CalcTextSize_1("(" .. (math.floor(StaminaOnGround * 10) / 10) .. ")", 24).x, 0) / 2
            ,
            PosY + 10 + TextOffsetY, 24, col, true, true)
        if Menu.GetBool("bShowTakeoffStamina") then
            Render.Text_1("(" .. (math.floor(StaminaOnGround * 10) / 10) .. ")",
                Globals.ScreenWidth() / 2 -
                Render.CalcTextSize_1("(" .. (math.floor(StaminaOnGround * 10) / 10) .. ")", 24).x / 2 +
                Render.CalcTextSize_1(Text, 24).x / 2 + 4, PosY + 10 + TextOffsetY, 24, col2, false, true)
        end
    else
        Render.Text_1(Text, Globals.ScreenWidth() / 2, PosY + 10 + TextOffsetY, 24, col, true, true)
    end

    TextOffsetY = TextOffsetY + 22
end

function DrawOldVelocity(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    if (Menu.GetInt("iShowVelocityOld") ~= 2) then
        return
    end

    -- Build Velocity Color
    local col2 = Color.new()
    if (VelocityOnGround > VelocityOnGround_old) then
        col2 = Color.new(25, 255, 100, 255)
    elseif (VelocityOnGround < VelocityOnGround_old) then
        col2 = Color.new(225, 100, 100, 255)
    else
        col2 = Color.new(255, 200, 100, 255)
    end

    -- Render Old Velocity [TYPE 2]
    if (VelocityOnGround > 0) then

        Render.Text_1("(" .. VelocityOnGround .. ")", Globals.ScreenWidth() / 2, PosY + 10 + TextOffsetY, 24, col2, true
            , true)
        TextOffsetY = TextOffsetY + 22

        --if (VelocityOnGround - VelocityOnGround_old > 0) then
        --    Render.Text_1(" +" .. VelocityOnGround - VelocityOnGround_old .. " ", Globals.ScreenWidth() / 2, PosY + 10 + 25 * 2, 24, Color.new(255, 255, 255, 150), true, true)
        --else
        --    Render.Text_1(" " .. VelocityOnGround - VelocityOnGround_old .. " ", Globals.ScreenWidth() / 2, PosY + 10 + 25 * 2, 24, Color.new(255, 255, 255, 150), true, true)
        --end
    end
end

function DrawUnits(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    -- Units
    if (not Menu.GetBool("bShowUnits") and not Menu.GetInt("iShowVert")) then
        return
    end

    TextOffsetY = TextOffsetY + 8

    local Text = (math.floor(LastUnits * 100) / 100) .. " Units"
    if (Menu.GetInt("iShowVert") == 1 and math.abs(LastVert) > 10) then
        local Plus = ""
        if (LastVert >= 0) then Plus = "+" end

        Text = Text .. " [" .. Plus .. LastVert .. " Vert]"
    end

    if not Menu.GetBool("bShowVert") then Text = (math.floor(LastUnits * 100) / 100) .. " Units" end

    -- Render Units
    if (VelocityOnGround > 0 and LastUnits > 0) then
        -- Dynamic Alpha
        local a = 255
        if (a > 255) then
            a = 255
        end
        if (OnGroundTime > 0 and (OnGroundTime + OnGroundTimeMax - GetTickCount()) <= a) then
            a = (OnGroundTime + OnGroundTimeMax - GetTickCount())
        end
        if (a < 0) then
            a = 0
        end

        if (Menu.GetBool("bShowUnits") and LastUnits > 100) then
            Render.Text_1(Text, Globals.ScreenWidth() / 2, PosY + 10 + TextOffsetY, 24, Color.new(255, 255, 255, a), true
                , true)
            TextOffsetY = TextOffsetY + 22
        end
        if (Menu.GetInt("iShowVert") == 2 and math.abs(LastVert) > 10) then
            local Plus = ""
            if (LastVert >= 0) then Plus = "+" end
            Render.Text_1("" .. Plus .. LastVert .. " Vert", Globals.ScreenWidth() / 2, PosY + 10 + TextOffsetY, 24,
                Color.new(255, 255, 255, a), true, true)
            TextOffsetY = TextOffsetY + 22
        end
    end
end

function DrawIndicator(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    -- JB Status
    if (not Menu.GetBool("bShowJBStatus")) then
        return
    end

    -- Render JB Status
    if GetBool(Vars.misc_jumpbug) and InputSys.IsKeyDown(GetInt(Vars.misc_jumpbug_key)) then
        local clr = Menu.GetColor("cIndJB")
        if (GetTickCount() < IsJBTime) then
            clr = Menu.GetColor("cIndJBD")
        end

        TextOffsetY = TextOffsetY + 22
        Render.Text_1("JB", Globals.ScreenWidth() / 2, PosY + 10 + TextOffsetY, 24, clr
            ,
            true, true)
        TextOffsetY = TextOffsetY + 22
    end
end

-- Ignore some Times
local VelocityTime = 0
local VelocityTimeToUpdate = 64

function PaintTraverse()
    TextOffsetY = 0
    PosY = Globals.ScreenHeight() / Menu.GetFloat("fVelPosY")

    VelocityrraySize = Menu.GetFloat("fGraphSizeX")
    SizeY = Menu.GetFloat("fGraphSizeY")

    if (not Utils.IsLocalAlive()) then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if (not pLocal) then
        return
    end

    local Flags = pLocal:GetPropInt(fFlags_Offset)
    local fVelocity = math.floor(VecLenght2D(pLocal:GetPropVector(vVelocity_Offset)) + 0.5)
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
    local vOrigin = pLocal:GetPropVector(vOrigin_Offset)
    local iMoveType = pLocal:GetMoveType()
    local fStamina = pLocal:GetPropFloat(fStamina_Offset)

    BuildVelocityInfo(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)

    DrawStaminaGraph(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    DrawGraph(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    -- Render Line
    if (Menu.GetBool("bShowVelocityLine1")) then
        Render.RectFilledMultiColor(Globals.ScreenWidth() / 2 - VelocityrraySize, PosY, Globals.ScreenWidth() / 2,
            PosY + 1, Color.new(255, 255, 255, 0), Color.new(255, 255, 255, 255), Color.new(255, 255, 255, 255),
            Color.new(255, 255, 255, 0))
        Render.RectFilledMultiColor(Globals.ScreenWidth() / 2, PosY, Globals.ScreenWidth() / 2 + VelocityrraySize,
            PosY + 1, Color.new(255, 255, 255, 255), Color.new(255, 255, 255, 0), Color.new(255, 255, 255, 0),
            Color.new(255, 255, 255, 255))

        --Render.Line(Globals.ScreenWidth() / 2 - VelocityrraySize, PosY, Globals.ScreenWidth() / 2 + VelocityrraySize, PosY, Color.new(255, 255, 255, 255), 1)
    end

    DrawVelocity(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    DrawStamina(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    DrawOldVelocity(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    DrawUnits(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    DrawIndicator(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)

    -- Save
    if (GetTickCount() - VelocityTime > VelocityTimeToUpdate) then
        fVelocity_old = fVelocity
        fStamina_old = fStamina
        VelocityTime = GetTickCount()
    end

    IsOnGroud_old = IsBit(Flags, ON_GROUND)
    vVelocity_old = vVelocity

end

Hack.RegisterCallback("PaintTraverse", PaintTraverse)

local IsX = 0
local function CreateMove(cmd, p_bSendPacket)
    if (not Menu.GetBool("bShowRoundInfo") and not Menu.GetBool("bShowLJInfo") and not Menu.GetBool("bEnableLJSound")) then return end
    if (not Utils.IsLocalAlive()) then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if (not pLocal) then
        return
    end
    local Flags = pLocal:GetPropInt(fFlags_Offset)
    local fVelocity = math.floor(VecLenght2D(pLocal:GetPropVector(vVelocity_Offset)) + 0.5)
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
    local vOrigin = pLocal:GetPropVector(vOrigin_Offset)
    local iMoveType = pLocal:GetMoveType()
    local fStamina = pLocal:GetPropFloat(fStamina_Offset)


    -- Build New Graph
    for i = 2, VelocityrraySize * 2 do
        VelocityArray[i - 1] = VelocityArray[i]
        StaminaArray[i - 1] = StaminaArray[i]
        PlusOnGroundVelocityArray[i - 1] = PlusOnGroundVelocityArray[i]
        OnGroundVelocityArray[i - 1] = OnGroundVelocityArray[i]
        IsJBArray[i - 1] = IsJBArray[i]
    end
    VelocityArray[VelocityrraySize * 2] = fVelocity
    StaminaArray[VelocityrraySize * 2] = fStamina
    PlusOnGroundVelocityArray[VelocityrraySize * 2] = -999
    OnGroundVelocityArray[VelocityrraySize * 2] = -999
    IsJBArray[VelocityrraySize * 2] = -999


    if (not IsBit(Flags, ON_GROUND)) then
        if (cmd.mousedx > 5 and (IsX == 1 or IsX == 0)) then
            Strafes = Strafes + 1
            KZ_Strafes = KZ_Strafes + 1
            IsX = 2
        elseif (cmd.mousedx < -5 and (IsX == 2 or IsX == 0)) then
            Strafes = Strafes + 1
            KZ_Strafes = KZ_Strafes + 1
            IsX = 1
        end
    end


    if (OnGroundTime > 0 and GetTickCount() > (OnGroundTime + KZ_TimeMax * 2)) then
        KZ_Strafes = 0
        IsX = 0
    end
end

Hack.RegisterCallback("CreateMove", CreateMove)

function FireEventClientSideThink(Event)
    if (not Menu.GetBool("bShowRoundInfo")) then return end
    if (not Utils.IsLocal()) then
        Jumps = 0
        Strafes = 0
        JBs = 0

        return
    end

    if (Menu.GetBool("bShowRoundInfo")) then
        if (Event:GetName() == "player_spawn") then
            if (IEngine.GetPlayerForUserID(Event:GetInt("userid", 0)) == IEngine.GetLocalPlayer()) then
                local Text = "[\x06INTERIUM\x01] "
                Text = Text .. "\x08Jumps: \x06" .. Jumps
                Text = Text .. "\x01 | \x08Strafes: \x06" .. Strafes
                Text = Text .. "\x01 | \x08JBs: \x06" .. JBs

                IChatElement.ChatPrintf(0, 0, Text)

                Jumps = 0
                Strafes = 0
                JBs = 0
            end
        end
    end
end

Hack.RegisterCallback("FireEventClientSideThink", FireEventClientSideThink)
