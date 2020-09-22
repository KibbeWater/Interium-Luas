-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.ColorPicker("Text Color", "cBombClrText", 255, 255, 255, 255)
Menu.ColorPicker("Time Color", "cBombClrTime", 0, 255, 0, 255)
Menu.ColorPicker("Background Color", "cBombClrBG", 33, 36, 41, 255)
Menu.ColorPicker("Line Color", "cBombClrLine", 255, 152, 244, 255)

local FPS = 60

local animStage = 0
local nextAnim = 0

local ticking = false
local oldTicking = false
local timeLeft = 0
local site = 0
local defusing = false

--Line Anim
local percentAnimatedLine = 0
local percentNeededLine = 100
local animationTimeLine = 0.3

--Between Anim
local pauseLineBox = 0.2
local pauseLineBoxEnd = 0

--Box Anim
local percentAnimatedBox = 0
local percentNeededBox = 100
local animationTimeBox = 0.5

--Text Anim
local percentAnimatedText = 0
local percentNeededText = 100
local animationTimeText = 0.5

--Defuse Line
local defuseTimeLeft = 0
local defuseTime = 0

--Final Fade Anim
local percentAnimatedFade = 0
local percentNeededFade = 100
local animationTimeFade = 2

--Offsets
local Blow_Offset = Hack.GetOffset("DT_PlantedC4", "m_flC4Blow")
local Site_Offset = Hack.GetOffset("DT_PlantedC4", "m_nBombSite")
local Ticking_Offset = Hack.GetOffset("DT_PlantedC4", "m_bBombTicking")
local DefuseTime_Offset = Hack.GetOffset("DT_PlantedC4", "m_flDefuseLength")
local DefuseCountdown_Offset = Hack.GetOffset("DT_PlantedC4", "m_flDefuseCountDown")
local Defused_Offset = Hack.GetOffset("DT_PlantedC4", "m_bBombDefused")
local Defuser_Offset = Hack.GetOffset("DT_PlantedC4", "m_hBombDefuser")

Hack.RegisterCallback("PaintTraverse", function()
    local sizeXLine = 150 - 10
    sizeXLine = (sizeXLine / percentNeededLine) * percentAnimatedLine
    local sizeXBox = 680 - 550
    sizeXBox = (sizeXLine / percentNeededBox) * percentAnimatedBox
    local textAlpha = 255
    textAlpha = (textAlpha / percentNeededText) * percentAnimatedText
    local allAlpha = 255
    allAlpha = (allAlpha / percentNeededFade) * (100 - percentAnimatedFade)
    local sizeXOutOfNames = 144 - 16
    sizeXOutOfNames = (sizeXOutOfNames / defuseTime) * defuseTimeLeft

    if allAlpha < 0 then allAlpha = 0 end

    if textAlpha > allAlpha then textAlpha = allAlpha end
    local boxFade = 130
    if boxFade > allAlpha then boxFade = allAlpha end

    local bombSite = "A"
    local sites = {"A", "B", "C", "D"}
    local textClr = Menu.GetColor("cBombClrText")
    textClr.a = textAlpha
    local timeClr = Menu.GetColor("cBombClrTime")
    timeClr.a = textAlpha
    local bgClr = Menu.GetColor("cBombClrBG")
    local lineClr = Menu.GetColor("cBombClrLine")
    bgClr.a = boxFade
    lineClr.a = boxFade
    if site ~= 0 then bombSite = sites[site+1] end

    if animStage >= 1 then Render.RectFilled(10, 545, 10 + sizeXLine, 550, lineClr, 1) end
    if animStage >= 3 then Render.RectFilled(10, 550, 150, 550 + sizeXBox, bgClr, 1) end
    if animStage >= 4 then Render.Text_1("BOMBSITE: " .. bombSite, 16, 565, 20, textClr, false, false) end
    if animStage >= 4 then Render.Text_1("TIMER: ", 16, 588, 20, textClr, false, false) end
    local tSize = Render.CalcTextSize_1("TIMER: ", 20)
    if animStage >= 4 then Render.Text_1(timeLeft, tSize.x + 16 + 3, 588, 20, timeClr, false, false) end
    if animStage >= 4 and defusing then Render.Text_1("DEFUSING", ((144 - 6) / 2) + 10, ((550 + 150) - 20) - 35, 20, textClr, true, false) end
    if animStage >= 4 and defusing and sizeXOutOfNames > 0 then Render.RectFilled(16, ((550 + 150) - 20) - 10, sizeXOutOfNames + 16, (550 + 150) - 20, textClr, 1) end

    if animStage == 1 and IGlobalVars.realtime > nextAnim then
        percentAnimatedLine = percentAnimatedLine + 1
        if percentAnimatedLine >= percentNeededLine then 
            animStage = 2 
            pauseLineBoxEnd = IGlobalVars.realtime + pauseLineBox
        end
    elseif animStage == 2 then
        if pauseLineBoxEnd > IGlobalVars.realtime then 
            animStage = 3 
            nextAnim = 0
        end
    elseif animStage == 3 and IGlobalVars.realtime > nextAnim then
        percentAnimatedBox = percentAnimatedBox + 1
        if percentAnimatedBox >= percentNeededBox then 
            animStage = 4
            nextAnim = 0 
        end
    elseif animStage == 4 and IGlobalVars.realtime > nextAnim then
        percentAnimatedText = percentAnimatedText + 1
        if percentAnimatedText >= percentNeededText then 
            animStage = 5
            nextAnim = 0 
        end
    elseif animStage == 5 then
        if not ticking or timeLeft <= animationTimeFade then 
            animStage = 6 
            nextAnim = 0 
        end
    elseif animStage == 6 and IGlobalVars.realtime > nextAnim then
        percentAnimatedFade = percentAnimatedFade + 1
        if percentAnimatedFade >= percentNeededFade then 
            animStage = 0
            nextAnim = 0 
            percentAnimatedLine = 0
            percentAnimatedBox = 0
            percentAnimatedText = 0
            percentAnimatedFade = 0
        end
    end

    for i = 1, IEntityList.GetHighestEntityIndex() do
        local ent = IEntityList.GetEntity(i)
        if not ent or ent:GetClassId() ~= 128 then goto continue end
        local bomb = IEntityList.GetPlantedC4(i)
        if not bomb then goto continue end
        timeLeft = bomb:GetPropFloat(Blow_Offset) - IGlobalVars.curtime
        site = bomb:GetPropInt(Site_Offset)
        ticking = bomb:GetPropBool(Ticking_Offset)
        defuseTime = bomb:GetPropFloat(DefuseTime_Offset)
        defuseTimeLeft = bomb:GetPropFloat(DefuseCountdown_Offset) - IGlobalVars.curtime
        local defused = bomb:GetPropBool(Defused_Offset)
        timeLeft = math.floor(timeLeft * 10) / 10
        if defused then timeLeft = 0 end
        local defuser = bomb:GetPropInt(Defuser_Offset) 
        if defuser ~= -1 then defusing = true else defusing = false end
        ::continue::
    end

    if timeLeft > 0 then
        ticking = true
    else ticking = false end

    if ticking ~= oldTicking and ticking then
        animStage = 1
        percentAnimatedLine = 0
        percentAnimatedBox = 0
        percentAnimatedFade = 0
        percentAnimatedText = 0
    end

    oldTicking = ticking
end)

Hack.RegisterCallback("FireEventClientSideThink", function (event)
	if event:GetName() == "round_start" then
		timeLeft = 0
		ticking = false
	end
end)