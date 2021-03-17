Menu.SliderFloat("Jumptrail Duration", 'snowClarityDuration', 1, 5, 1.0, 1.5)

local Flags_Offset = Hack.GetOffset("DT_BasePlayer", "m_fFlags")
local Velocity_Offset = Hack.GetOffset("DT_BasePlayer", "m_vecVelocity[0]")

local lastDraw = 0
local interval = 0.017

Hack.RegisterCallback("PaintTraverse", function ()
    if lastDraw + interval >= IGlobalVars.realtime then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if not pLocal then return end

    local flags = pLocal:GetPropInt(Flags_Offset)
    if IsBit(flags, 0) or pLocal:GetMoveType() == 8 or pLocal:GetMoveType() == 9 then return end
    
    local viewang = IClientState.viewangles

    local chromaSpeed = 3
    local r = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed) * 127 + 128)
    local g = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 2) * 127 + 128)
    local b = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 4) * 127 + 128)

    local rgba = Color.new(r,g,b,155)
    local rgb = Color.new(r,g,b,255)

    local vel = pLocal:GetPropVector(Velocity_Offset)
    local tickrate = 1
    vel = Vector.new(vel.x/tickrate, vel.y/tickrate, vel.z/tickrate)
    local newAng = QAngle.new()
    Math.VectorAngles(vel, newAng)
    if vel == Vector.new(0,0,0) then newAng = QAngle.new(0, viewang.yaw, 0) else newAng = QAngle.new(0, newAng.yaw, 0) end
    
    IDebugOverlay.AddBoxOverlay2(pLocal:GetAbsOrigin(), Vector.new(-2, -2, -0.5), Vector.new(2, 2, 0.5), newAng, rgba, rgb, Menu.GetFloat("snowClarityDuration"))

    lastDraw = IGlobalVars.realtime
end)

Hack.RegisterCallback("FireEventClientSideThink", function (event)
    if event:GetName() == "round_start" then IDebugOverlay.ClearAllOverlays() end
end)