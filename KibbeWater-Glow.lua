Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - Glow")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Options")
Menu.Separator()
Menu.Checkbox("Visible Only", "snowGlowVischeck", false)
Menu.Checkbox("fullBloom", "snowGlowFullbloom", false)
Menu.SliderFloat('Opacity', 'snowGlowAlpha', 0.1, 1, 1.0, 1.0)
Menu.SliderFloat('Bloom', 'snowGlowBloom', 0.1, 1, 1.0, 1.0)
Menu.Combo('Style', 'snowGlowStyle', {"Full", "Inline + Flicker", "Inline Glow", "Flicker"}, 0)
Menu.Combo('Color Style', 'snowGlowClrStyle', {"Rainbow", "Health"}, 0)

local glowObjManager = GetIntA(GetIntA(Hack.PatternScan("client.dll", "0F 11 05 ? ? ? ? 83 C8 01") + 3))

local glowIdxOffset = Hack.GetOffset("DT_CSPlayer", "m_flFlashDuration")+24
local m_iHealth = Hack.GetOffset("DT_BasePlayer", "m_iHealth")

local memoryInfo = {pos=0}

local function ColorToFloat(clr)
    local fl = 0.003921568627451
    return {r=fl*clr.r, g=fl*clr.g, b=fl*clr.b, a=fl*clr.a}
end

function memoryInfo.Pad(x) memoryInfo.pos = memoryInfo.pos + x end

function memoryInfo.WriteFloat(float)
    SetFloatA(memoryInfo.pos, float)
    memoryInfo.Pad(4) --Shift pos by 4 because a float is 4 bytes
end

function memoryInfo.WriteInt(int)
    SetIntA(memoryInfo.pos, int)
    memoryInfo.Pad(4) --Shift pos by 4 because an int is 4 bytes
end

function memoryInfo.WriteBool(bool)
    SetBoolA(memoryInfo.pos, bool)
    memoryInfo.Pad(1) --Shift pos by 1 because a bool is 1 byte
end

function memoryInfo.WriteColor(clr)
    memoryInfo.WriteFloat(clr.r)
    memoryInfo.WriteFloat(clr.g)
    memoryInfo.WriteFloat(clr.b)
end

function WriteGlow(player, clr, style, fullBloom)
    memoryInfo.pos = glowObjManager + ((player:GetPropInt(glowIdxOffset) * 56) + 4)

    local floatClr = ColorToFloat(clr)

    memoryInfo.WriteColor(floatClr)
    memoryInfo.WriteFloat(floatClr.a)
    memoryInfo.Pad(8)
    memoryInfo.WriteFloat(Menu.GetFloat("snowGlowBloom"))
    memoryInfo.Pad(4)
    memoryInfo.WriteBool(true)
    memoryInfo.WriteBool(false)
    memoryInfo.WriteBool(fullBloom)
    memoryInfo.Pad(5)
    memoryInfo.WriteInt(style)
end

Hack.RegisterCallback("DrawModelExecute", function ()
    if not Utils.IsInGame() then return end

    local chromaSpeed = 3
    local r = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed) * 127 + 128)
    local g = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 2) * 127 + 128)
    local b = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 4) * 127 + 128)
    local a = math.floor(math.sin(IGlobalVars.realtime * 5.5 + 6) * 127 + 128)

    local rainbow = Color.new(r,g,b,Menu.GetFloat("snowGlowAlpha")*255)

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if not pLocal then return end

    for i = 1, 64 do
        local pEnt = IEntityList.GetPlayer(i)
        if not pEnt or pEnt:IsTeammate() then goto skip end

        local hit = trace_t.new()
        Utils.TraceLine(pLocal:GetEyePos(), pEnt:GetEyePos(), 24705, pLocal, hit)
        local hitEnt = IEntityList.ToPlayer(hit.hit_entity)
        if not hitEnt then goto skip end
        local canSee = hitEnt:GetAbsOrigin() == pEnt:GetAbsOrigin()

        if not canSee then
            local hit = trace_t.new()
            Utils.TraceLine(hitEnt:GetEyePos(), pEnt:GetEyePos(), 24705, hitEnt, hit)
            local hitEnt = IEntityList.ToPlayer(hit.hit_entity)
            if not hitEnt then goto skipif end
            if hitEnt:GetAbsOrigin() == pEnt:GetAbsOrigin() then canSee = true end
            ::skipif::
        end

        local health = pEnt:GetPropInt(m_iHealth)
        local healthAmnt = 255/100
        local healthGlow = Color.new(255-(2.55*health),healthAmnt*health, 0,Menu.GetFloat("snowGlowAlpha")*255)
        
        local wantedClr = healthGlow
        if Menu.GetInt("snowGlowClrStyle") == 0 then wantedClr = rainbow end

        local controlledStyle = Menu.GetInt("snowGlowStyle")
        if controlledStyle == 3 then 
            controlledStyle = 0
            wantedClr.a = a
        end

        if (not canSee and not Menu.GetBool("snowGlowVischeck")) or canSee then WriteGlow(pEnt, wantedClr, controlledStyle, Menu.GetBool("snowGlowFullbloom")) end

        ::skip::
    end
end)
