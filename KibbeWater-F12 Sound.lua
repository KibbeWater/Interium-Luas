Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable F12 Sound", "cEnableF12", true)
Menu.InputFloat("Sound Durbation (Seconds)", "cF12Time", 0.6)

local oldEnabled = true

local disableTimer = 0
local disableTimerEnabled = false

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

Hack.RegisterCallback("CreateMove", function (cmd, send)
    local loopback = ICvar.FindVar("voice_loopback")
    local inputFile = ICvar.FindVar("voice_inputfromfile")

    if oldEnabled == true and not Menu.GetBool("cEnableF12") then
        loopback:SetInt(0)
        inputFile:SetInt(0)
    end

    if IGlobalVars.realtime > disableTimer and disableTimerEnabled then
        loopback:SetInt(0)
        inputFile:SetInt(0)
        IEngine.ExecuteClientCmd("-voicerecord")
        disableTimerEnabled = false
    end

    oldEnabled = Menu.GetBool("cEnableF12")
end)

Hack.RegisterCallback("FireEventClientSideThink", function (event)
    if not Menu.GetBool("cEnableF12") then return end

    local loopback = ICvar.FindVar("voice_loopback")
    local inputFile = ICvar.FindVar("voice_inputfromfile")

    if event:GetName() == "player_death" then
        local dead = IEntityList.GetPlayer(UIDToPlayer(event:GetInt("userid")))
        local attacker = IEntityList.GetPlayer(UIDToPlayer(event:GetInt("attacker")))

        if UIDToPlayer(event:GetInt("attacker")) == IEngine.GetLocalPlayer() then
            loopback:SetInt(1)
            inputFile:SetInt(1)
            disableTimer = IGlobalVars.realtime + Menu.GetFloat("cF12Time")
            disableTimerEnabled = true
            IEngine.ExecuteClientCmd("+voicerecord")
        end
    end

    
end)