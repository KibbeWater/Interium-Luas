-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Checkpoint", "cEnableCheckpoint", true)
Menu.Checkbox("Checkpoint Text", "cEnableCheckpointText", true)
Menu.Checkbox("Enable Notifications", "cEnableNotifications", true)
Menu.KeyBind("Set Checkpoint", "cCheckpointSet", 67)
Menu.KeyBind("Goto Checkpoint", "cCheckpointGoto", 220)
Menu.KeyBind("Remove Checkpoint", "cCheckpointRemove", 70)

--Variables
local currentAng = QAngle.new(0, 0, 0)

local checkpointPos = Vector.new(0, 0, 0)
local checkpointAng = Vector.new(0, 0, 0)
local checkpointSet = false

local cancel = true

--Offsets
local vVelocity_Offset = Hack.GetOffset("DT_BasePlayer", "m_vecVelocity[0]")

function SendNotif(ID, type, title, msg, clr, r, g, b, expire)
    local clrBool = "false"
    if clr then clrBool = "true" end
    if Menu.GetInt("NM_API_Enabled") > IGlobalVars.realtime and Menu.GetBool("cEnableNotifications") then
        Menu.SetString("NM_API_Payload", ID .. "*" .. type .. "*" .. title .. "*" .. msg .. "*" .. clrBool .. "*" .. r .. "*" .. g .. "*" .. b .. "*" .. (IGlobalVars.realtime + expire))
        Menu.SetBool("NM_API_Send", true)
    end
end

function PaintTraverse() 
    --Cross Compatibility
    Menu.SetInt("CheckpointModuleExists", IGlobalVars.curtime + 1)
    Menu.SetString("CheckpointModuleData", tostring(checkpointSet) .. " " .. checkpointPos.x .. "," .. checkpointPos.y .. "," .. checkpointPos.z .. " " .. checkpointAng.x .. "," .. checkpointAng.y)

    if(Menu.GetBool("cEnableCheckpoint") and Utils.IsInGame()) then
        --Set Checkpoint
        if(InputSys.IsKeyPress(Menu.GetInt("cCheckpointSet"))) then
            local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
            checkpointPos = pLocal:GetAbsOrigin()
            checkpointAng = Vector.new(currentAng.pitch, currentAng.yaw, 0)
            checkpointSet = true
            SendNotif("SetCheckpoint", 3, "Set Checkpoint", checkpointPos.x .. ", " .. checkpointPos.y .. ", " .. checkpointPos.z, true, 252, 3, 223, 4)
        end

        --Goto Checkpoint
        if(InputSys.IsKeyPress(Menu.GetInt("cCheckpointGoto")) and checkpointSet) then
            IEngine.ExecuteClientCmd("setpos_exact " .. checkpointPos.x .. " " .. checkpointPos.y .. " " .. checkpointPos.z)
            IEngine.ExecuteClientCmd("setang_exact " .. checkpointAng.x .. " " .. checkpointAng.y)
            cancel = true
        end

        --Remove Checkpoint
        if(InputSys.IsKeyPress(Menu.GetInt("cCheckpointRemove"))) then
            if checkpointSet then SendNotif("RMCheckpoint", 3, "Checkpoint", "Removed checkpoint", true, 252, 3, 223, 4) end
            checkpointSet = false
        end
        
        if checkpointSet then
            local pos = checkpointPos
            local textPos = Vector.new(0, 0, 0)

            local BeamInfo = BeamInfo_t.new()
            BeamInfo.m_nType = 0
            BeamInfo.m_pszModelName = "sprites/purplelaser1.vmt"
            BeamInfo.m_nModelIndex = -1
            BeamInfo.m_flHaloScale = 0.0
            BeamInfo.m_flLife = 0.1
            BeamInfo.m_flWidth = 5.0
            BeamInfo.m_flEndWidth = 3.0
            BeamInfo.m_flFadeLength = 0.0
            BeamInfo.m_flAmplitude = 2.0
            BeamInfo.m_flBrightness = 255
            BeamInfo.m_flSpeed = 0
            BeamInfo.m_nStartFrame = 0
            BeamInfo.m_flFrameRate = 0
            BeamInfo.m_flRed = 255
            BeamInfo.m_flGreen = 255
            BeamInfo.m_flBlue = 255
            BeamInfo.m_nSegments = 2
            BeamInfo.m_bRenderable = true
            BeamInfo.m_nFlags = 0
            BeamInfo.m_vecStart = pos
            BeamInfo.m_vecEnd = Vector.new(pos.x, pos.y, pos.z + 1000)

            local Beam = IRenderBeams.CreateBeamPoints(BeamInfo)
            local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
            local textWPos = Vector.new(pos.x, pos.y, pos.z + 70)
            local dist = Math.VectorDistance(pos, pLocal:GetAbsOrigin())

            if(Math.WorldToScreen(textWPos, textPos) and Menu.GetBool("cEnableCheckpointText")) then
                Render.Text_1("Checkpoint\n" .. math.floor(dist) .. " From target", textPos.x + 10, textPos.y, 20, Color.new(200,200,200,255), false, false)
            end
        end
    end
end
Hack.RegisterCallback("PaintTraverse", PaintTraverse)  

function CreateMove(cmd, sendPacket)
    currentAng = cmd.viewangles

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if not pLocal or not Utils.IsLocalAlive() then return end

    local vel = pLocal:GetPropVector(vVelocity_Offset)

    if cancel then
        Utils.CorrectMovement(QAngle.new(0,0,0), cmd, (vel.x * 1.75) * -1, vel.y, false)
        if vel.x < 15 and vel.x > -15 then 
            if vel.y < 15 and vel.y > -15 then 
                cancel = false 
                IEngine.ExecuteClientCmd("setpos_exact " .. checkpointPos.x .. " " .. checkpointPos.y .. " " .. checkpointPos.z)
                IEngine.ExecuteClientCmd("setang_exact " .. checkpointAng.x .. " " .. checkpointAng.y)
            end
        end
    end
end
Hack.RegisterCallback("CreateMove", CreateMove)  
