-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("--=General Settings=--")
Menu.Checkbox("Enable Graph", "cEnableGraph", true)
Menu.Text("--=Graph Settings=--")
Menu.SliderInt("Data Points", "cGraphPoints", 20, 100, "", 40)
Menu.SliderInt("Speed", "cGraphSpeed", 1, 10, "", 1)
Menu.Checkbox("Enable Baseline", "cGraphBaseline", true)
Menu.SliderInt("Baseline Thickness", "cGraphBaselineThicc", 1, 10, "", 2)
Menu.SliderInt("Graph Line Thickness", "cGraphLinesThicc", 1, 10, "", 2)
Menu.SliderInt("Graph Size X", "cGraphSizeX", 0, Globals.ScreenWidth(), "", 600)
Menu.SliderInt("Graph Size Y", "cGraphSizeY", 0, Globals.ScreenHeight(), "", 100)
Menu.SliderInt("Graph Pos X", "cGraphPosX", 0, Globals.ScreenWidth(), "", (Globals.ScreenWidth() / 2) - 300)
Menu.SliderInt("Graph Pos Y", "cGraphPosY", 0, Globals.ScreenHeight(), "", ((Globals.ScreenHeight()/4)*3.2))
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
local OSpeed = Menu.GetInt("cGraphSpeed")
local OVel = IEntityList.GetPlayer(IEngine.GetLocalPlayer()):GetPropVector(vVelocity_Offset)
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
        local speed = Menu.GetInt("cGraphSpeed")

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
        local amountOfPointsToFade = DatapointsSize / 20
        local pointsFaded = 0
        local fadePerPoint = amountOfPointsToFade / 255
        local fadingEnd = false
        for i = 1, DatapointsSize do
            if i < DatapointsSize then
                local lineX = ((GraphSizeX / #DatapointsY ) * (i - 1)) + GraphPosX
                local lineY = GraphPosY + ((GraphSizeY / 300) * (300 - DatapointsY[i]))
                local lineX2 = ((GraphSizeX / #DatapointsY) * (i + 0)) + GraphPosX
                local lineY2 = GraphPosY + ((GraphSizeY / 300) * (300 - DatapointsY[i + 1]))
                local clr = Menu.GetColor("cGraphColor")
                Render.Line(lineX, lineY, lineX2, lineY2, clr, Menu.GetInt("cGraphLinesThicc"))
                if DatapointsData[i] == 1 then Render.Text_1("JB", lineX - 5, lineY, 30, Color.new(255, 255, 255, 255), false, true) end
                if DatapointsData[i] == 1 and i >= 3 then DatapointsData[i] = 0 end
                if i > DatapointsSize - amountOfPointsToFade then fadingEnd = true end
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

    local speed = Menu.GetInt("cGraphSpeed")
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
            if DatapointsData[i] == 1 then Print("Detected JB at " .. i) end
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
            Print("Inserted JB at " .. #DatapointsData)
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
    Print("Initializing " .. Menu.GetInt("cGraphPoints") .. " Points")
end

function Velocity(vVel)
    return math.abs(vVel.x) + math.abs(vVel.y) + math.abs(vVel.z)
end
