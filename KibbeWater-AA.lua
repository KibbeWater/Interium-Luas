-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Anti-Aim", "cEnableKAA", true)
Menu.Combo( "AA Type", "cKAAType", { "Rage", "Legit" }, 0)

local switch = false
local nva = QAngle.new(0,0,0)

local lastfmove = 0
local lastsmove = 0
local lastang = QAngle.new(0,0,0)

function AngleDiff(yaw1, yaw2)
    return yaw2 - yaw1
end

Hack.RegisterCallback("PaintTraverse", function ()
    if not Utils.IsInGame() or not Utils.IsLocalAlive() then return end
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if not pLocal then return end

    local pos = pLocal:GetAbsOrigin()

    local aaVA = QAngle.new(0,0,0)
    local va = QAngle.new(0,0,0)

    IEngine.GetViewAngles(va)
    aaVA = nva

    local aaAngVec = Vector.new(0,0,0)
    local vaAngVec = Vector.new(0,0,0)

    Math.AngleVectors(aaVA, aaAngVec)
    Math.AngleVectors(va, vaAngVec)
    
    local aaLine = Vector.new(pos.x + (aaAngVec.x * 50), pos.y + (aaAngVec.y * 50), pos.z)
    local vaLine = Vector.new(pos.x + (vaAngVec.x * 50), pos.y + (vaAngVec.y * 50), pos.z)
    
    local start = Vector.new(0,0,0)
    local aaEnd = Vector.new(0,0,0)
    local vaEnd = Vector.new(0,0,0)
    
    if Math.WorldToScreen(pos, start) then --Line Start
        if Math.WorldToScreen(aaLine, aaEnd) then --AA Line End
            Render.Line(start.x, start.y, aaEnd.x, aaEnd.y, Color.new(255,0,0,255), 1)
        end
        if Math.WorldToScreen(vaLine, vaEnd) then --VA Line End
            Render.Line(start.x, start.y, vaEnd.x, vaEnd.y, Color.new(0,255,0,255), 1)
        end
    end

end)

Hack.RegisterCallback("CreateMove", function (cmd, send)
    if not Menu.GetBool("cEnableKAA") then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if not pLocal then return end

    local originalVA = QAngle.new(0,0,0)
    IEngine.GetViewAngles(originalVA)

    if InputSys.IsKeyDown(1) or InputSys.IsKeyDown(69) then 
        cmd.viewangles = originalVA
        return
    end

    local fmove = cmd.forwardmove
    local smove = cmd.sidemove

    if Menu.GetInt("cKAAType") == 0 then
        local oldVA = cmd.viewangles
        IEngine.GetViewAngles(oldVA)
        local va = oldVA

        if switch then 
            va.yaw = va.yaw - 218
            switch = false
        else
            va.yaw = va.yaw - 10
            switch = true
        end
        
        Math.ClampAngles(va)

        cmd.viewangles = va
        nva = cmd.viewangles
        
    elseif Menu.GetInt("cKAAType") == 1 then
        local maxDesync = pLocal:GetMaxDesyncDelta()
        local AnimState = pLocal:GetPlayerAnimState()
        local feetyaw = AnimState.m_flGoalFeetYaw - AnimState.m_flCurrentFeetYaw
        local va = cmd.viewangles
        

        if send then
            va.yaw = (feetyaw + maxDesync) * cmd.sidemove
        end

        if switch then 
            if cmd.sidemove == 2 or cmd.sidemove == 0 then cmd.sidemove = -2 end
            switch = false
        else
            if cmd.sidemove == -2 or cmd.sidemove == 0 then cmd.sidemove = 2 end
            switch = true
        end
    end

    Utils.CorrectMovement(originalVA, cmd, fmove, smove, false)
end)