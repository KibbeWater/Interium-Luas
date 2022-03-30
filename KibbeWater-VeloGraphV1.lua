-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("--=General Settings=--")
Menu.Checkbox("Enable Graph", "cEnableGraph", true)
Menu.Text("--=Graph Settings=--")
Menu.SliderInt("Fade Percent", "cGraphFade", 0, 50, 1, 5)
Menu.SliderInt("Data Points", "cGraphPoints", 50, 500, 1, 300)
Menu.SliderFloat("Speed", "cGraphSpeed", 0.1, 10, 0.1, 0.5)
Menu.Checkbox("Optimised Rendering", "cGraphOptimised", false)
Menu.Checkbox("Enable Baseline", "cGraphBaseline", true)
Menu.SliderInt("Baseline Thickness", "cGraphBaselineThicc", 1, 10, 1, 2)
Menu.SliderInt("Graph Line Thickness", "cGraphLinesThicc", 1, 10, 1, 1)
Menu.SliderInt("Graph Size X", "cGraphSizeX", 0, Globals.ScreenWidth(), 1, 600)
Menu.SliderInt("Graph Size Y", "cGraphSizeY", 0, Globals.ScreenHeight(), 1, 100)
Menu.SliderInt("Graph Pos X", "cGraphPosX", 0, Globals.ScreenWidth(), 1, (Globals.ScreenWidth() / 2) - 300)
Menu.SliderInt("Graph Pos Y", "cGraphPosY", 0, Globals.ScreenHeight(), 1, ((Globals.ScreenHeight()/4)*3.2))
Menu.Button("Align To Middle", "cGraphAlign")
Menu.Text("--=Graph Colors=--")
Menu.ColorPicker("Baseline Color", "cGraphBaselineColor", 255, 255, 255, 255)
Menu.ColorPicker("Graph Color", "cGraphColor", 0, 0, 0, 255)

local DatapointsY = {}
local DatapointsData = {}
local firstExecution = true

local tick = 0
local lastExecutionTick = 5
local nextExecutionTick = 5

-- Offsets
local fFlags_Offset = Hack.GetOffset("DT_BasePlayer", "m_fFlags")
local vVelocity_Offset = Hack.GetOffset("DT_BasePlayer", "m_vecVelocity[0]")

-- Flag States
local ON_GROUND = 0

local OPoints = Menu.GetInt("cGraphPoints")
local OSpeed = Menu.GetFloat("cGraphSpeed")
local OVel = Vector.new(0, 0, 0)
local OGround = true
local NextJB = false

--Draw Visuals
Hack.RegisterCallback("PaintTraverse", function ()
    if Menu.GetBool("cEnableGraph") then
        --Execute INIT on first Paint execution
        if firstExecution then 
            init()
            firstExecution = false
        end

        --Get Variables
        local GraphSizeX = Menu.GetInt("cGraphSizeX")
        local GraphSizeY = Menu.GetInt("cGraphSizeY")
        local GraphPosX = Menu.GetInt("cGraphPosX")
        local GraphPosY = Menu.GetInt("cGraphPosY")
        local DatapointsSize = Menu.GetInt("cGraphPoints")
        local speed = Menu.GetFloat("cGraphSpeed")

        --TODO: make it fucking work you lazy ass mother fucking egoed ass coder bitch
        if Menu.GetBool("cGraphAlign") then
            Menu.SetInt("cGraphPosX", (Globals.ScreenWidth() / 2) - (Menu.GetInt("cGraphSizeX") / 2))
            Menu.SetInt("cGraphPoxY", ((Globals.ScreenHeight()/4)*3) - (Menu.GetInt("cGraphSizeY") / 2))
        end

        if OPoints ~= DatapointsSize or OSpeed ~= speed then
            firstExecution = true
            tick = 1
            nextExecutionTick = 1
        end

        --Pasted vars cuz lazy
        local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
        local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
        local Flags = pLocal:GetPropInt(fFlags_Offset)

        --Check JB
        if OGround and not IsBit(Flags, ON_GROUND) then
            tick = tick
        else
            if (OVel.z < 0 and vVelocity.z > 0) then
                NextJB = true
            end
        end

        --Reg old Data
        OPoints = DatapointsSize
        OSpeed = speed
        OVel = vVelocity

        --Only kibbes brain got injured during these calculations
        --Oh yeah start calculating pos for every point in given size
        local amountOfPointsToFade = math.floor(DatapointsSize * (Menu.GetInt("cGraphFade") / 100))
        local fadePerPoint = 255 / amountOfPointsToFade
        local polyIdx = 0
        for i = 1, DatapointsSize do
            if i < DatapointsSize then
                local lineX = ((GraphSizeX / #DatapointsY ) * (i - 1)) + GraphPosX
                local lineY = GraphPosY + ((GraphSizeY / 300) * (300 - DatapointsY[i]))
                local lineX2 = ((GraphSizeX / #DatapointsY) * (i + 0)) + GraphPosX
                local lineY2 = GraphPosY + ((GraphSizeY / 300) * (300 - DatapointsY[i + 1]))
                local clr = Menu.GetColor("cGraphColor")

                -- Check if it's a beginning or a end fade
                local isFade = false
                if i <= amountOfPointsToFade then
                    clr.a = math.floor(255 - (fadePerPoint * (amountOfPointsToFade - i)))
                    isFade = true
                elseif i >= DatapointsSize - amountOfPointsToFade then
                    clr.a = math.floor(255 - (fadePerPoint * (amountOfPointsToFade - (DatapointsSize - i))))
                    isFade = true
                end

                -- Check if next iteration is gonna fade, if it does then Print("Fade")
                
                if isFade or not Menu.GetBool("cGraphOptimised") then Render.Line(lineX, lineY, lineX2, lineY2, clr, Menu.GetInt("cGraphLinesThicc")) end

                if Menu.GetBool("cGraphOptimised") then
                    Render.AddPoly(polyIdx, lineX, lineY)
                    polyIdx = polyIdx + 1
                    if i + 1 <= amountOfPointsToFade or i + 1 >= DatapointsSize - amountOfPointsToFade then
                        Render.AddPoly(polyIdx, lineX2, lineY2)
                        Render.Poly(polyIdx + 1, clr, false, Menu.GetInt("cGraphLinesThicc"))
                        polyIdx = 0
                    end
                end

                if DatapointsData[i] == 1 then Render.Text_1("JB", lineX - 5, lineY, 30, Color.new(255, 255, 255, 255), false, true) end
                if DatapointsData[i] == 1 and i >= 3 then DatapointsData[i] = 0 end
            end
        end

        --Draw Static Lines
        if Menu.GetBool("cGraphBaseline") then Render.Line(GraphPosX, GraphPosY + GraphSizeY, GraphPosX + (GraphSizeX / #DatapointsY) * (#DatapointsY - 1), GraphPosY + GraphSizeY, Menu.GetColor("cGraphBaselineColor"), Menu.GetInt("cGraphBaselineThicc")) end
    end
end)

--Record Data
Hack.RegisterCallback("CreateMove", function ()
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
    local Flags = pLocal:GetPropInt(fFlags_Offset)

    local speed = Menu.GetFloat("cGraphSpeed")
    local DatapointsSize = Menu.GetInt("cGraphPoints")

    if nextExecutionTick <= tick then
        local temp = {}
        local tempData = {}
        local vel = Velocity(vVelocity)
        if vel > 700 then vel = 700 end
        for i = 1, #DatapointsY do
            if i ~= 1 then
                temp[i - 1] = DatapointsY[i]
            end
        end
        for i = 1, #DatapointsData do
            if i ~= 1 then
                tempData[i - 1] = DatapointsData[i]
            end
        end
        tempData[#DatapointsData] = 0
        DatapointsY = temp
        DatapointsData = tempData
        DatapointsY[#DatapointsY+1] = vel
        if NextJB then
            DatapointsData[#DatapointsData] = 1
            NextJB = false
        end
        nextExecutionTick = tick + speed
        --Print(nextExecutionTick .. " " .. tick)
    end
    if IsBit(Flags, ON_GROUND) then OGround = true else OGround = false end
    tick = tick + 1
end)

function init()
    for i = 1, Menu.GetInt("cGraphPoints") do
        DatapointsY[i] = 0
        DatapointsData[i] = 0
    end
end

function Velocity(vVel)
    return math.abs(vVel.x) + math.abs(vVel.y) + math.abs(vVel.z)
end
