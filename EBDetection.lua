-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Debug", "cDebug", false)
Menu.Checkbox("Enable EB Rainbow", "bRainbowGay", false)
Menu.Checkbox("Enable Steelseries Gamesense", "cEnableGSSDK", false)
Menu.Checkbox("Optimize Steelseries Gamesense", "cOptimizeGSSDK", false)
Menu.Text("To change EB Hitsound change file in")
Menu.Text("\\CSGO\\FilesForLUA\\kibbewater\\ebhit.wav")

--Edgebug Sound
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\")

-- Offsets
local fFlags_Offset = Hack.GetOffset("DT_BasePlayer", "m_fFlags")
local vVelocity_Offset = Hack.GetOffset("DT_BasePlayer", "m_vecVelocity[0]")

-- Flag States
local ON_GROUND = 0

--Variables for data tracking
local oldhVel = 0
local oldvVel = 0
local lastedgebug = ""
local edgebugDetectionStage
local ebsucession = 0
local ebsucessionsession = 0
local cooldown = 0
local skipNext = false

--for rainbow pride gay type beat
local opacity = 0
local viewRainbow = 0
local Height = 0
local Type = { 0, 0, 0, 0 }
local R = { 255, 0, 0, 0 }
local G = { 0, 255, 0, 0 }
local B = { 0, 0, 255, 0 }
local iImageAlpha = 0
local minusAlpha = 1
local MaxTicks = 32
local Ticks = 0
local firstRealTime = 0
local tickCount = 0
local first = true
local first2 = false
local validateEB = true

local function VecLenght2D(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

local function Rainbow(Strong,Type, r, g, b)
	local NewStrong = Strong * (120.0 / Utils:GetFps())

	if (Type == 0) then
		if (g < 255) then
			if (g + NewStrong > 255) then
				g = 255
			else
				g = g + NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 1) then
		if (r > 0) then
			if (r - NewStrong < 0) then
				r = 0
			else
				r = r - NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 2) then
		if (b < 255) then
			if (b + NewStrong > 255) then
				b = 255
			else
				b = b + NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 3) then
		if (g > 0) then
			if (g - NewStrong < 0) then
				g = 0
			else
				g = g - NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 4) then
		if (r < 255) then
			if (r + NewStrong > 255) then
				r = 255
			else
				r = r + NewStrong
			end
		else
			Type = Type + 1
		end
	elseif (Type == 5) then
		if (b > 0) then
			if (b - NewStrong < 0) then
				b = 0
			else
				b = b - NewStrong
			end
		else
			Type = 0
		end
	end

	return Strong,Type, r, g, b
end

function PaintTraverse() 
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 

    local fVelocity = math.floor(VecLenght2D(pLocal:GetPropVector(vVelocity_Offset)) + 0.5)
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)

    local Flags = pLocal:GetPropInt(fFlags_Offset)
    
    Menu.SetInt("EBModuleExists", IGlobalVars.curtime + 1)

    if(iImageAlpha > 0) then
        if (Menu.GetBool("bRainbowGay")) then 
            local Strong = 3
            Strong,Type[1], R[1], G[1], B[1] = Rainbow(Strong,Type[1], R[1], G[1], B[1])
            Strong,Type[4], R[4], G[4], B[4] = Rainbow(Strong,Type[4], R[4], G[4], B[4])
                
            Height = Globals.ScreenHeight()
        
            Render.RectFilledMultiColor(
                  0,                                 -- x1
                  0,                                 -- y1
                  Globals.ScreenWidth(),                           -- x2
                  Height,              -- y2
                  Color.new(R[4], G[4], B[4], iImageAlpha),  --  upper left
                  Color.new(R[1], G[1], B[1], iImageAlpha),  --  upper right
                  Color.new(R[1], G[1], B[1], iImageAlpha),  -- bottom right
                  Color.new(R[4], G[4], B[4], iImageAlpha)   -- bottom left
            )
        end
    end

    if(Menu.GetBool("cDebug")) then
        if(IsBit(Flags, ON_GROUND)) then
            Render.Text_1("On Ground", 10, 500, 20, Color.new(255, 255, 255, 255), false, true)
        else
            Render.Text_1("Zuhn Bhop", 10, 500, 20, Color.new(255, 255, 255, 255), false, true)
        end

        local oldx = vVelocity.x
        local oldy = vVelocity.y
        local x = oldx
        local y = oldy

        if(x < 0) then
            x = oldx*-1
        end

        if(y < 0) then
            y = oldy*-1
        end

        local hVel = x + y;
    
        local vVelDebug = math.floor(vVelocity.z)
        Render.Text_1("Vertical Velocity " .. vVelDebug, 10, 520, 20, Color.new(255, 255, 255, 255), false, true)
        Render.Text_1("Horizontal Velocity " .. math.floor(oldhVel), 10, 540, 20, Color.new(255, 255, 255, 255), false, true)
        Render.Text_1("Last Edgebug Info " .. lastedgebug, 10, 560, 20, Color.new(255, 255, 255, 255), false, true)
        Render.Text_1("Edgebug Detection Stage " .. edgebugDetectionStage, 10, 580, 20, Color.new(255, 255, 255, 255), false, true)
        Render.Text_1("Horizontal Velocity: " .. math.floor(oldhVel), 10, 600, 20, Color.new(255, 255, 255, 255), false, true)
        Render.Text_1("Realtime: " .. IGlobalVars.realtime, 10, 620, 20, Color.new(255, 255, 255, 255), false, true)
        Render.Text_1("Valid EB: " .. tostring(validateEB), 10, 640, 20, Color.new(255, 255, 255, 255), false, true)
    end
end
Hack.RegisterCallback("PaintTraverse", PaintTraverse)  

function CreateMove() 
    if first then
        firstRealTime = IGlobalVars.realtime
        first2 = true
        first = false
    end

    if firstRealTime + 1 <= IGlobalVars.realtime then
        first2 = false
        tickrate = tickCount - 4
    end

    if first2 then tickCount = tickCount + 1 end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 

    local fVelocity = math.floor(VecLenght2D(pLocal:GetPropVector(vVelocity_Offset)) + 0.5)
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)

    local Flags = pLocal:GetPropInt(fFlags_Offset)
    edgebugDetectionStage = 0
    
    Menu.SetInt("kEbSuccession", ebsucession)
    Menu.SetInt("kEbSuccessionSession", ebsucessionsession)

    local pX = math.abs(vVelocity.x)
    local pY = math.abs(vVelocity.y)

    local horizontal = pX + pY

    if pLocal:GetMoveType() == 9 then validateEB = false end
    if IsBit(Flags, ON_GROUND) == true then validateEB = true end

    --Detect EB
    if(IsBit(Flags, ON_GROUND) == false and Utils.IsLocalAlive() and pLocal:GetMoveType() ~= 8 and pLocal:GetMoveType() ~= 9 and validateEB) then
        edgebugDetectionStage = 1
        if(vVelocity.z < 1 and oldvVel < vVelocity.z) then
            edgebugDetectionStage = 2
            if(horizontal > 10) then
                edgebugDetectionStage = 3
                if vVelocity.x ~= 0 or vVelocity.y ~= 0 then
                    if IGlobalVars.realtime > cooldown then
                        --Debug Data
                        if Menu.GetBool("cDebug") then Print("Detection S4 (Edgebug)\necho Info: " .. vVelocity.x .. " " .. vVelocity.y .. " " .. vVelocity.z) end
                        edgebugDetectionStage = 4

                        --Set Cooldown
                        cooldown = IGlobalVars.realtime + 0.5

                        --Trigger Optimized request to backend
                        if Menu.GetBool("cEnableGSSDK") and Menu.GetBool("cOptimizeGSSDK") then URLDownloadToFile("http://127.0.0.1:420/Edgebug?game=INTERIUM&event=EDGEBUG&value=40", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\dummy.txt") end
                        
                        --Do Edgebug Stuff
                        PlaySound(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ebhit.wav")

                        --Cross compatibility stat variables
                        ebsucession = ebsucession + 1
                        ebsucessionsession = ebsucessionsession + 1

                        --Rainbow Stuff
                        iImageAlpha = 40
                        Ticks = MaxTicks

                        --Draw Last Edgebug Data
                        if(IsBit(Flags, ON_GROUND)) then
                            lastedgebug = math.floor(vVelocity.x) .. "x " .. math.floor(vVelocity.y) .. "y " .. vVelocity.z .. "z OnGround: true"
                        else
                            lastedgebug = math.floor(vVelocity.x) .. "x " .. math.floor(vVelocity.y) .. "y " .. vVelocity.z .. "z OnGround: false"
                        end
                    end
                end
            end
        end
    end

    if (Ticks == 0 and iImageAlpha > 0) then 
        iImageAlpha = iImageAlpha - minusAlpha 
        if Menu.GetBool("cEnableGSSDK") and not Menu.GetBool("cOptimizeGSSDK") then URLDownloadToFile("http://127.0.0.1:420/Update?game=INTERIUM&event=EDGEBUG&value=" .. iImageAlpha, GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\dummy.txt") end
    end
    if (Ticks > 0) then Ticks = Ticks - 1 end

    if (not Utils.IsInGame()) then
        ebsucession = 0
        cooldown = 0
        viewRainbow = 0
    end

    if iImageAlpha > 0 and not skipNext then 
        
    end
    if skipNext then skipNext = false end

    --Finish and register old Data
    oldhVel = horizontal
    oldvVel = vVelocity.z
    if IsBit(Flags, ON_GROUND) == false then
        oldground = false
        oldgrounddebug = "false"
    else
        oldground = true
        oldgrounddebug = "true"
    end
    x2 = vVelocity.x
    y2 = vVelocity.y
end
Hack.RegisterCallback("CreateMove", CreateMove)  

function Func(Event)
	if (not Utils.IsLocalAlive()) then
		iKillCount = 0
		iImageAlpha = 0
		return
	end
    
    if (Event:GetName() == "round_start") then 
		Ticks = 0
		iImageAlpha = 0
    end
end
Hack.RegisterCallback("FireEventClientSideThink", Func)
