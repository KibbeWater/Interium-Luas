-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Teamdamage ESP", "cEnableTDamageESP", true)   
Menu.Checkbox("Enemy Only", "cTDamageEnemy", true)  
Menu.Checkbox("Enable Draw Distance", "cEnableTDamageDDistance", true)     
Menu.SliderInt("Draw Distance", "cTDamageDraw", 500, 2000, "", 1250) 
Menu.SliderInt("Position", "cTDamagePos", 0, 100, "", 0)
Menu.Combo( "Alignment", "cTDamageAlign", { "Top Left", "Top Right", "Bottom Left", "Bottom Right"  }, 3)
Menu.ColorPicker("Text Clr", "cTDamageTextClr", 255, 255, 255, 255)
Menu.Separator()

--Global Vars
local nextAutosave = 0
local first = true

--Cool Shit
local kills = {}
local damage = {}

--Setup lua
function Setup()
    Menu.SetBool("cEnableTDamageSizing", false)
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
    --if Menu.GetBool("cDisableTDamageESPCheck") and not Menu.GetBool("&Vars.esp_enabled") then return end

    if first then
        Setup()
        first = false
    end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    

    for i = 1, 64 do
        if IEngine.GetLocalPlayer() == i then goto skip end
        local pCurrent = IEntityList.GetPlayer(i) 
        if (not pCurrent or pCurrent:GetClassId() ~= 40 or pCurrent:IsDormant()) then goto skip end

        local box = pCurrent:GetBox()
        local cPos = pCurrent:GetAbsOrigin()
        local lPos = pCurrent:GetAbsOrigin()
        local dist = Math.VectorDistance(lPos, cPos)
        
        --This string below might be usefull for an alternate rendering when too far away
        --Print((box.bottom - box.top) / 15)
        local dist = Math.VectorDistance(pLocal:GetAbsOrigin(), pCurrent:GetAbsOrigin())
        local sizeZ = 15
        if Menu.GetBool("cEnableTDamageSizing") then sizeZ = dist / 50 end
        if dist < 1500 then sizeZ = 15 end
        Print(sizeZ)

        local textPos = 0
        local onePercent = (box.bottom - box.top) / 100
        if Menu.GetInt("cTDamageAlign") == 0 or Menu.GetInt("cTDamageAlign") == 1 then textPos = (box.top + 20) + (Menu.GetInt("cTDamagePos") * onePercent) else textPos = box.bottom - (Menu.GetInt("cTDamagePos") * onePercent) end

        local clr = Menu.GetColor("cTDamageTextClr")

        if dist <= Menu.GetInt("cTDamageDraw") and Menu.GetBool("cEnableTDamageDDistance") then 
            local kSize = Render.CalcTextSize_1("Kills: " .. kills[i], sizeZ)
            local x = box.right + 5
            if Menu.GetInt("cTDamageAlign") == 0 or Menu.GetInt("cTDamageAlign") == 2 then x = box.left - kSize.x - 5 end
            Render.Text_1("Kills: " .. kills[i], x, textPos - 25, sizeZ, clr, false, false)

            local dSize = Render.CalcTextSize_1("Damage: " .. damage[i], sizeZ)
            if Menu.GetInt("cTDamageAlign") == 0 or Menu.GetInt("cTDamageAlign") == 2 then x = box.left - dSize.x - 5 end
            Render.Text_1("Damage: " .. damage[i], x, textPos - 10, sizeZ, clr, false, false)
        elseif not Menu.GetBool("cEnableTDamageDDistance") then
            local kSize = Render.CalcTextSize_1("Kills: " .. kills[i], sizeZ)
            local x = box.right + 5
            if Menu.GetInt("cTDamageAlign") == 0 or Menu.GetInt("cTDamageAlign") == 2 then x = box.left - kSize.x - 5 end
            Render.Text_1("Kills: " .. kills[i], x, textPos - 25, sizeZ, clr, false, false)

            local dSize = Render.CalcTextSize_1("Damage: " .. damage[i], sizeZ)
            if Menu.GetInt("cTDamageAlign") == 0 or Menu.GetInt("cTDamageAlign") == 2 then x = box.left - dSize.x - 5 end
            Render.Text_1("Damage: " .. damage[i], x, textPos - 10, sizeZ, clr, false, false)
        end

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
