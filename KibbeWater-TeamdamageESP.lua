-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Teamdamage ESP", "cEnableTDamageESP", true)       
Menu.Separator()
Menu.Text("INCASE TEAM DAMAGE LIST DOESN'T APPEAR")
Menu.Checkbox("Reset Position", "cTDamageESPReset", false)

--Global Vars
local nextAutosave = 0
local first = true

--Cool Shit
local kills = {}
local damage = {}

--Setup lua
function Setup()
    for i = 1, 64 do
        kills[i] = 0
        damage[i] = 0
    end
end

--well, the name said it
function UIDToPlayer(uid)
    for i = 1, 64 do
        local pCurrent = IEntityList.GetPlayer(i) 
        if (not pCurrent or pCurrent:GetClassId() ~= 40) then goto skip end

        local Info = CPlayerInfo.new()
        if (not pCurrent:GetPlayerInfo(Info)) then goto skip end

        if Info.userId == uid then
            return i
        end

        ::skip::
    end
end

Hack.RegisterCallback("PaintTraverse", function ()
    if not Menu.GetBool("cEnableTDamageESP") then return end

    if first then
        Setup()
        first = false
    end

    --Reset pos
    if Menu.GetBool("cTDamageESPReset") then
        posX = 100
        posY = 100
        Menu.SetBool("cTDamageESPReset", false)
    end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())

    for i = 1, 64 do
        if IEngine.GetLocalPlayer() == i then goto skip end
        local pCurrent = IEntityList.GetPlayer(i) 
        if (not pCurrent or pCurrent:GetClassId() ~= 40 or pCurrent:IsDormant()) then goto skip end

        local box = pCurrent:GetBox()
        Print((box.bottom - box.top) / 14)
        local dist = Math.VectorDistance(pLocal:GetAbsOrigin(), pCurrent:GetAbsOrigin())
        local size = Render.CalcTextSize_1("Kills: " .. kills[i], 15)
        local sizeD = Render.CalcTextSize_1("Damage: " .. damage[i], 15)
        Render.Text_1("Kills: " .. kills[i], box.right + 5, box.bottom - 25, 15, Color.new(255,255,255,255), false, false)
        Render.Text_1("Damage: " .. damage[i], box.right + 5, box.bottom - 10, 15, Color.new(255,255,255,255), false, false)

        ::skip::
    end

end)

Hack.RegisterCallback("FireEventClientSideThink", function(Event)
    if Event:GetName() == "player_hurt" then
        
        local attackerID = UIDToPlayer(Event:GetInt("attacker"))
        local hurt = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("userid"))) 
        local attacker = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("attacker")))
        local dmg = Event:GetInt("dmg_health")

        if not hurt then return end
        if not attacker then return end

        if hurt ~= attacker then
            if attacker:IsTeammate() or IEngine.GetLocalPlayer() == attackerID then
                if hurt:IsTeammate() or IEngine.GetLocalPlayer() == UIDToPlayer(Event:GetInt("userid")) then
                    damage[attackerID] = damage[attackerID] + dmg
                end
            end
        end
    end
    if Event:GetName() == "player_death" then
        local attackerID = UIDToPlayer(Event:GetInt("attacker"))
        local hurt = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("userid"))) 
        local attacker = IEntityList.GetPlayer(UIDToPlayer(Event:GetInt("attacker")))
        
        if not hurt then return end

        if not attacker then return end

        if hurt ~= attacker then
            if attacker:IsTeammate() or IEngine.GetLocalPlayer() == attackerID then
                if hurt:IsTeammate() or IEngine.GetLocalPlayer() == UIDToPlayer(Event:GetInt("userid")) then
                    kills[attackerID] = kills[attackerID] + 1
                end
            end
        end
    end
end)
