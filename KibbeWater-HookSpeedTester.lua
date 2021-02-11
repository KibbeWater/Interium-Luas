local nextPrint = IGlobalVars.curtime + 1

local detections = {}
local detected = {}

for i = 1, 13 do
    detections[i] = 0
    detected[i] = false
end

function Detect(i, hook)
    if nextPrint <= IGlobalVars.curtime and not detected[i] then
        Print(hook .. ": " .. detections[i] .. " Detections per sec")
        nextPrint = IGlobalVars.curtime + 1
        detections[i] = 0
        detected[i] = true
    else
        detections[i] = detections[i] + 1
    end
end

Hack.RegisterCallback("PaintTraverse", function ()
    Detect(1, "PaintTraverse")
end)

Hack.RegisterCallback("CreateMove", function ()
    Detect(2, "CreateMove")
end)

Hack.RegisterCallback("EmitSound", function ()
    Detect(3, "EmitSound")
end)

Hack.RegisterCallback("FrameStageNotify", function ()
    Detect(4, "FrameStageNotify")
end)

Hack.RegisterCallback("FireEventClientSideThink", function ()
    Detect(5, "FireEventClientSideThink")
end)


Hack.RegisterCallback("DrawModelExecute", function ()
    Detect(6, "DrawModelExecute")
end)

Hack.RegisterCallback("FindMDL", function ()
    Detect(7, "FindMDL")
end)


Hack.RegisterCallback("DoPostScreenEffects", function ()
    Detect(8, "DoPostScreenEffects")
end)


Hack.RegisterCallback("OverrideView", function ()
    Detect(9, "OverrideView")
end)


Hack.RegisterCallback("CreateMovePredict", function ()
    Detect(10, "CreateMovePredict")
end)


Hack.RegisterCallback("SendNetMsg", function ()
    Detect(11, "SendNetMsg")
end)


Hack.RegisterCallback("SendDatagram", function ()
    Detect(12, "SendDatagram")
end)


Hack.RegisterCallback("LockCursor", function ()
    Detect(13, "LockCursor")
end)


