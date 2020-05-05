--=info=--

-- Page 1: Game Stats

-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("--=General Settings=--")
Menu.Checkbox("Enable UI", "cEnable", false)
Menu.Checkbox("Disable Default UI", "cDisableDefault", true)
Menu.Text("UI Type")
Menu.Combo( "", "cMenuType", { "Menu", "Simple" }, 0)
Menu.Spacing()
Menu.Spacing()
Menu.Text("--=Hotkey Settings=--")
Menu.KeyBind("Toggle Menu open State", "kMenuToggle", 72);
Menu.KeyBind("Next Page", "kMenuNext", 39);
Menu.KeyBind("Previous Page", "kMenuPrev", 37);
Menu.Spacing()
Menu.Spacing()
Menu.Text("--=Module Settings=--")
Menu.Checkbox("Enable Edgebug Module", "cEbEnable", false)
Menu.Checkbox("Enable Music Module", "cMusicEnable", false)
Menu.Checkbox("Enable Checkpoint Module", "cCheckpointEnable", false)
Menu.Spacing()
Menu.Spacing()
Menu.Text("--=Opacity Settings=--")
Menu.SliderInt("Text Opacity", "cOpacityText", 0, 255, "", 255)
Menu.SliderInt("Health Opacity", "cOpacityHealth", 0, 255, "", 255)
Menu.SliderInt("Spectator Opacity", "cOpacitySpec", 0, 255, "", 255)
Menu.SliderInt("Checkpoint Opacity", "cOpacityCheckpoint", 0, 255, "", 255)
Menu.SliderInt("Menu Opacity", "cOpacityMenu", 0, 255, "", 175)
Menu.SliderInt("Menu Handle Opacity", "cOpacityMenuHandle", 0, 255, "", 155)
Menu.SliderInt("Simple Opacity", "cOpacitySimple", 0, 255, "", 175)


--Setup Files
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater")

--Setup Fonts
URLDownloadToFile("https://cdn.discordapp.com/attachments/655694082525364254/700274099775078410/Sunflower.ttf", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf")
Render.LoadFont("sunflower", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf", 30)

--Settings thats not open so not gay
local menuToggleCooldown = false
local menuNavigationCooldown = false
local ScreenSplitSize = 10
local screenWSplit = Globals.ScreenWidth() / ScreenSplitSize
local screenHSplit = Globals.ScreenHeight() / ScreenSplitSize 

local interiumUsername = "null"

local menuWidth = 0
local menuHeight = 0

-- Offsets
local fFlags_Offset = Hack.GetOffset("DT_BasePlayer", "m_fFlags")
local vVelocity_Offset = Hack.GetOffset("DT_BasePlayer", "m_vecVelocity[0]")

-- Flag States
local ON_GROUND = 0

--Debug Info
local debugData = ""
local oldDebugData = ""
local moneyFirst = ""

--Chroma Speed
local chromaSpeed = 3

--Module Settings
local EBDetectionMounted = false
local MusicDisplayMounted = false
local CheckpointMounted = false
local LoadedModules = 0

--Menu Box
local pointX1 = 0
local pointY1 = screenHSplit * 4
local pointX2 = screenWSplit * 2
local pointY2 = screenHSplit * 8

--RGB Open Point1
local fancyX1 = screenWSplit * 2
local fancyY1 = screenHSplit * 4

--Point 2
local fancyX2 = (screenWSplit * 2) + 2
local fancyY2 = screenHSplit * 8

--RGB Closes Point1
local fancy2X1 = screenWSplit * 0
local fancy2Y1 = screenHSplit * 4

--Point 2
local fancy2X2 = (screenWSplit * 0) + 2
local fancy2Y2 = screenHSplit * 8

--Handle Closed Point1
local handle2X1 = (screenWSplit * 0) + 2
local handle2Y1 = screenHSplit * 4
--Point2
local handle2X2 = (screenWSplit * 0) + 2
local handle2Y2 = screenHSplit * 8
--Point3
local handle2X3 = screenWSplit * 0.2
local handle2Y3 = screenHSplit * 7.8
--Point4
local handle2X4 = screenWSplit * 0.2
local handle2Y4 = screenHSplit * 4.2

--Handle Opened Point1
local handleX1 = (screenWSplit * 2) + 2
local handleY1 = screenHSplit * 4
--Point2
local handleX2 = (screenWSplit * 2) + 2
local handleY2 = screenHSplit * 8
--Point3
local handleX3 = screenWSplit * 2.2
local handleY3 = screenHSplit * 7.8
--Point4
local handleX4 = screenWSplit * 2.2
local handleY4 = screenHSplit * 4.2

--Health Bars Point1
local mainHealthX1 = screenWSplit * 0.3
local mainHealthY1 = screenHSplit * 8.2

--Point2
local mainHealthX2 = screenWSplit * 2.3
local mainHealthY2 = screenHSplit * 9.7

--Health Fancy Point1
local fancyHealthX1 = screenWSplit * 2.3
local fancyHealthY1 = screenHSplit * 8.2

--Point2
local fancyHealthX2 = screenWSplit * 0.3
local fancyHealthY2 = (screenHSplit * 8.2) - 2

--Spectator Normal Point1
local spectatorX1 = screenWSplit * 4.4
local spectatorY1 = screenHSplit * 2.7

--Point2
local spectatorX2 = screenWSplit * 5.6
local spectatorY2 = screenHSplit * 3.3

--Spectator Fancy Point1
local fancySpectatorX1 = screenWSplit * 4.4
local fancySpectatorY1 = screenHSplit * 2.7

--Point2
local fancySpectatorX2 = screenWSplit * 5.6
local fancySpectatorY2 = (screenHSplit * 2.7) - 2

--Checkpoint Normal Point1
local checkpointX1 = screenWSplit * 0.3
local checkpointY1 = screenHSplit * 2.65

--Point2
local checkpointX2 = screenWSplit * 1.8
local checkpointY2 = screenHSplit * 3.35

--Checkpoint Fancy Point1
local fancyCheckpointX1 = screenWSplit * 0.3
local fancyCheckpointY1 = screenHSplit * 2.65

--Point2
local fancyCheckpointX2 = screenWSplit * 1.8
local fancyCheckpointY2 = (screenHSplit * 2.65) - 2

--Store data for menu
local menuOpen = false
local pages = 3
local page = 1

--Game Statitics
local deaths = 0
local kills = 0
local RNG = 0
local Headshots = 0
local ebsucession = 0
local moneySpent = 0

--Session Statitics
local sdeaths = 0
local skills = 0
local sRNG = 0
local sHeadshots = 0
local sebsucession = 0
local sMoneySpent = 0

--Register Functions
function Paint()
    if(Utils.IsInGame() and Menu.GetBool("cEnable")) then
        --Toggle Default UI if not already
        local cvar = ICvar.FindVar("cl_draw_only_deathnotices")
        if(cvar:GetInt() == 0 and Menu.GetBool("cDisableDefault")) then
            IEngine.ExecuteClientCmd("cl_draw_only_deathnotices 1")
        elseif(cvar:GetInt() == 1 and not Menu.GetBool("cDisableDefault")) then
            IEngine.ExecuteClientCmd("cl_draw_only_deathnotices 0")
        end

        --Toggle UI
        if(InputSys.IsKeyPress(Menu.GetInt("kMenuToggle")) and Menu.GetInt("cMenuType") == 0) then
            if(menuOpen) then
                menuOpen = false
                menuToggleCooldown = true
            else
                menuOpen = true
                menuToggleCooldown = true
            end
        else
            menuToggleCooldown = false
        end

        --Page Navigation
        if(InputSys.IsKeyPress(Menu.GetInt("kMenuNext")) and Menu.GetInt("cMenuType") == 0) then
            if(page < pages) then
                page = page + 1
            else
                page = 1
            end
        end

        if(InputSys.IsKeyPress(Menu.GetInt("kMenuPrev")) and Menu.GetInt("cMenuType") == 0) then
            if(1 < page) then
                page = page - 1
            else
                page = pages
            end
        end

        --Store data for Cross Script availability
        ebsucession = Menu.GetInt("kEbSuccession")
        sebsucession = Menu.GetInt("kEbSuccessionSession")

        --Set Variables
        if(Menu.GetInt("EBModuleExists") > IGlobalVars.curtime) then EBDetectionMounted = true else EBDetectionMounted = false end
        if(Menu.GetInt("MusicModuleExists") > IGlobalVars.curtime) then  MusicDisplayMounted = true else MusicDisplayMounted = false end
        if(Menu.GetInt("CheckpointModuleExists") > IGlobalVars.curtime) then  CheckpointMounted = true else CheckpointMounted = false end
        local currentlyLoaded = 0
        if EBDetectionMounted then currentlyLoaded = currentlyLoaded + 1 end
        if MusicDisplayMounted then currentlyLoaded = currentlyLoaded + 1 end
        if CheckpointMounted then currentlyLoaded = currentlyLoaded + 1 end
        LoadedModules = currentlyLoaded
        interiumUsername = Hack.GetUserName()

        --Menu Variables
        local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
        local TextOpacity = Menu.GetInt("cOpacityText")
        local moneyOffset = Hack.GetOffset("DT_CSPlayer", "m_iAccount")
        local money = pLocal:GetPropInt(moneyOffset)
        local checkpointPreData = 0
        local CheckpointData = 0
        local checkpointSet = 0
        local checkpointPosData = 0
        local checkPointPos = 0
        local checkpointAngData = 0
        local checkPointAng = 0
        local checkpointDist = 0
        if CheckpointMounted and Menu.GetString("CheckpointModuleData") ~= "" then
            checkpointPreData = Menu.GetString("CheckpointModuleData")
            CheckpointData = Split(checkpointPreData, " ")
            if CheckpointData[1] == "true" then checkpointSet = true else checkpointSet = false end
            checkpointPosData = Split(CheckpointData[2], ",")
            checkpointPos = Vector.new(tonumber(checkpointPosData[1]), tonumber(checkpointPosData[2]), tonumber(checkpointPosData[3]))
            checkpointAngData = Split(CheckpointData[3], ",")
            checkpointAng = Vector.new(tonumber(checkpointAngData[1]), tonumber(checkpointAngData[2]), 0)
            checkpointDist = math.floor(Math.VectorDistance(checkpointPos, pLocal:GetAbsOrigin()))
        end
        local song = Split(Menu.GetString("cListening"), "-")
        local songLength = #song
        local songName = ""
        for i=1,songLength do 
            if(i > 1) then
                if(songName == "") then
                    songName = song[i]
                else
                    songName = songName .. "-" .. song[i]
                end
            end
        end

        --Draw RGB
        local r = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed) * 127 + 128)
        local g = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 2) * 127 + 128)
        local b = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 4) * 127 + 128)

        --Draw Simple menu
        if(Menu.GetInt("cMenuType") == 1) then
            local SimpleOpacity = Menu.GetInt("cOpacitySimple")
            Render.RectFilled(-1, -1, Globals.ScreenWidth(), (Globals.ScreenHeight() / 100) * 2.5, Color.new(25,25,25,SimpleOpacity), 2)
            Render.RectFilled(0, (Globals.ScreenHeight() / 100) * 2.5, Globals.ScreenWidth(), ((Globals.ScreenHeight() / 100) * 2.5) + 3, Color.new(r, g, b,SimpleOpacity), 2)

            --Draw out Text
            Render.Text("Kills: " .. kills, 10, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), false, true, "sunflower")
            Render.Text("RNG: " .. RNG, 110, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), false, true, "sunflower")
            Render.Text("Deaths: " .. deaths, 210, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), false, true, "sunflower")
            Render.Text("Money: " .. money, 340, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), false, true, "sunflower")
            if EBDetectionMounted then Render.Text("Edgebugs: " .. ebsucession, 490, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), false, true, "sunflower") end
            if MusicDisplayMounted and songName ~= "" then Render.Text("Listening To: " .. songName, Globals.ScreenWidth() / 2, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), true, true, "sunflower") end
            Render.Text("Modules Loaded: " .. LoadedModules, 1390, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), true, true, "sunflower")
            local nameSize = Render.CalcTextSize(interiumUsername, 20, "sunflower")
            Render.Text(interiumUsername, (Globals.ScreenWidth() - 20) - nameSize.x, (Globals.ScreenHeight() / 100) * 0.5, 20, Color.new(255,255,255,TextOpacity), false, true, "sunflower")
        end

        --Draw Left Menu Open
        if(menuOpen and Menu.GetInt("cMenuType") == 0) then
            --Get Variables
            menuHeight = (pointY2 - pointY1)
            menuWidth = (pointX2 - pointX1)
            local MenuOpacity = Menu.GetInt("cOpacityMenu")

            --Add Polys
            Render.AddPoly(0, handleX1, handleY1)
            Render.AddPoly(1, handleX2, handleY2)
            Render.AddPoly(2, handleX3, handleY3)
            Render.AddPoly(3, handleX4, handleY4)

            --Render Menu
            Render.RectFilled(fancyX1, fancyY1, fancyX2, fancyY2, Color.new(r,g,b,MenuOpacity), 2)
            Render.RectFilled(pointX1, pointY1, pointX2, pointY2, Color.new(25,25,25,MenuOpacity), 2)
            Render.PolyFilled(4, Color.new(20,20,20,Menu.GetInt("cOpacityMenuHandle")))

            --Populate Menus
            if(page == 1) then
                --Calculate Module Placement
                local musicLocation = 9
                
                --Data Calculations
                local song = Split(Menu.GetString("cListening"), "-")

                local loginData = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\login")
                local loginSplit = Split(loginData, "\n")


                --Render Page Header
                Render.Text("Home", (pointX1 + (menuWidth / 2)), (pointY1 + ((menuHeight/10) * 0.5)), (Globals.ScreenWidth() / 70), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")
                Render.Text("(" .. page .. "/" .. pages .. ")", pointX1 + ((menuWidth / 10) * 1), (pointY1 + ((menuHeight/10) * 0.3)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")

                --Populate Menu
                Render.Text("Welcome back " .. interiumUsername, pointX1 + ((menuWidth / 10) * 5), (pointY1 + ((menuHeight/10) * 1.2)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")
                Render.Text("Edgebug Detection: ", pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 2.6)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("Checkpoint: ", pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 3.8)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("Music Display: ", pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 3.2)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                if(EBDetectionMounted) then
                    Render.Text("Enabled", pointX1 + ((menuWidth / 10) * 5.8), (pointY1 + ((menuHeight/10) * 2.6)), (Globals.ScreenWidth() / 80), Color.new(0, 255, 0, TextOpacity), false, true, "sunflower")
                else
                    Render.Text("Disabled", pointX1 + ((menuWidth / 10) * 5.8), (pointY1 + ((menuHeight/10) * 2.6)), (Globals.ScreenWidth() / 80), Color.new(255, 0, 0, TextOpacity), false, true, "sunflower")
                end
                if(MusicDisplayMounted) then
                    Render.Text("Enabled", pointX1 + ((menuWidth / 10) * 4.4), (pointY1 + ((menuHeight/10) * 3.2)), (Globals.ScreenWidth() / 80), Color.new(0, 255, 0, TextOpacity), false, true, "sunflower")
                else
                    Render.Text("Disabled", pointX1 + ((menuWidth / 10) * 4.4), (pointY1 + ((menuHeight/10) * 3.2)), (Globals.ScreenWidth() / 80), Color.new(255, 0, 0, TextOpacity), false, true, "sunflower")
                end
                if(CheckpointMounted) then
                    Render.Text("Enabled", pointX1 + ((menuWidth / 10) * 3.8), (pointY1 + ((menuHeight/10) * 3.8)), (Globals.ScreenWidth() / 80), Color.new(0, 255, 0, TextOpacity), false, true, "sunflower")
                else
                    Render.Text("Disabled", pointX1 + ((menuWidth / 10) * 3.8), (pointY1 + ((menuHeight/10) * 3.8)), (Globals.ScreenWidth() / 80), Color.new(255, 0, 0, TextOpacity), false, true, "sunflower")
                end
                if (Menu.GetBool("cMusicEnable") and MusicDisplayMounted and songName ~= "") then Render.Text("Listening to:" .. songName, pointX1 + ((menuWidth / 10) * 5), (pointY1 + ((menuHeight/10) * musicLocation)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower") end
            elseif(page == 2) then
                --Calculate Module Placement
                local ebLocation = 4.4
                local musicLocation = 9

                --Data Calculations
                local song = Split(Menu.GetString("cListening"), "-")

                --Render Page Header
                Render.Text("Game Statistics", (pointX1 + (menuWidth / 2)), (pointY1 + ((menuHeight/10) * 0.5)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")
                Render.Text("(" .. page .. "/" .. pages .. ")", pointX1 + ((menuWidth / 10) * 1), (pointY1 + ((menuHeight/10) * 0.3)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")

                --Render Statitics
                Render.Text("Kills: " .. kills, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 1.7)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("RNG: " .. RNG, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 2.3)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("Deaths: " .. deaths, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 2.85)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("Money Spent: " .. moneySpent, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 3.38)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")

                if (EBDetectionMounted) then if (Menu.GetBool("cEbEnable")) then Render.Text("Edgebugs Hit: " .. ebsucession, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * ebLocation)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower") end end
                if (Menu.GetBool("cMusicEnable") and MusicDisplayMounted and songName ~= "") then Render.Text("Listening to:" .. songName, pointX1 + ((menuWidth / 10) * 5), (pointY1 + ((menuHeight/10) * musicLocation)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower") end
            elseif(page == 3) then
                --Calculate Module Placement
                local ebLocation = 4.4
                local musicLocation = 9

                --Data Calculations
                local song = Split(Menu.GetString("cListening"), "-")

                --Render Page Header
                Render.Text("Session Statistics", (pointX1 + (menuWidth / 2)), (pointY1 + ((menuHeight/10) * 0.5)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")
                Render.Text("(" .. page .. "/" .. pages .. ")", pointX1 + ((menuWidth / 10) * 1), (pointY1 + ((menuHeight/10) * 0.3)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")

                --Render Session Statitics
                Render.Text("Kills: " .. skills, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 1.7)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("RNG: " .. sRNG, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 2.3)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("Deaths: " .. sdeaths, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 2.85)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
                Render.Text("Money Spent: " .. sMoneySpent, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * 3.38)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")

                if (EBDetectionMounted) then if (Menu.GetBool("cEbEnable")) then Render.Text("Edgebugs Hit: " .. sebsucession, pointX1 + ((menuWidth / 10) * 0.4), (pointY1 + ((menuHeight/10) * ebLocation)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), false, true, "sunflower") end end
                if (Menu.GetBool("cMusicEnable") and MusicDisplayMounted and songName ~= "") then Render.Text("Listening to:" .. songName, pointX1 + ((menuWidth / 10) * 5), (pointY1 + ((menuHeight/10) * musicLocation)), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, TextOpacity), true, true, "sunflower") end
            
            end
        elseif(not menuOpen and Menu.GetInt("cMenuType") == 0) then
            --Add Polys
            Render.AddPoly(0, handle2X1, handle2Y1)
            Render.AddPoly(1, handle2X2, handle2Y2)
            Render.AddPoly(2, handle2X3, handle2Y3)
            Render.AddPoly(3, handle2X4, handle2Y4)

            Render.RectFilled(fancy2X1, fancy2Y1, fancy2X2, fancy2Y2, Color.new(r,g,b,155), 2)
            Render.PolyFilled(4, Color.new(20,20,20,75))
        end

        --Draw Spectator Indicator
        if (not Utils.IsLocalAlive() and Utils.IsInGame()) then
            local SpecOpacity = Menu.GetInt("cOpacitySpec")

            Render.RectFilled(spectatorX1, spectatorY1, spectatorX2, spectatorY2, Color.new(25,25,25,SpecOpacity), 2)
            Render.RectFilled(fancySpectatorX1, fancySpectatorY1, fancySpectatorX2, fancySpectatorY2, Color.new(r, g, b, SpecOpacity), 2)

            Render.Text("*SPECTATING*", screenWSplit * 5, screenHSplit * 2.9, 25, Color.new(255, 255, 255, TextOpacity), true, true, "sunflower")
        end

        --Draw Checkpoint
        if (Utils.IsInGame() and CheckpointMounted and Menu.GetBool("cCheckpointEnable") and checkpointSet) then
            local CheckOpacity = Menu.GetInt("cOpacityCheckpoint")

            Render.RectFilled(checkpointX1, checkpointY1, checkpointX2, checkpointY2, Color.new(25,25,25,CheckOpacity), 2)
            Render.RectFilled(fancyCheckpointX1, fancyCheckpointY1, fancyCheckpointX2, fancyCheckpointY2, Color.new(r, g, b, CheckOpacity), 2)

            Render.Text("Checkpoint:\n" .. checkpointDist .. " units from Checkpoint", screenWSplit * 0.4, screenHSplit * 2.8, 22, Color.new(255, 255, 255, TextOpacity), false, true, "sunflower")
        end

        if(not IChatElement.IsChatOpened() and not IEngine.IsPaused() and Utils.IsLocalAlive()) then
            local HealthOpacity = Menu.GetInt("cOpacityHealth")

            local mainHeight = (mainHealthY2 - mainHealthY1)
            local mainWidth = (mainHealthX2 - mainHealthX1)

            local splitX = mainWidth / 10
            local splitY = mainHeight / 10

            local Armor_Offset = Hack.GetOffset("DT_CSPlayer", "m_ArmorValue");
            local Health_Offset = Hack.GetOffset("DT_BasePlayer", "m_iHealth");
            local Ammo_Offset = Hack.GetOffset("DT_BaseCombatWeapon", "m_iClip1");

            local Player = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
            local activeWeapon = Player:GetActiveWeapon()
            local WeaponInfo = CWeaponInfo.new()
            WeaponInfo = activeWeapon:GetWeaponData()


            local health = Player:GetPropInt(Health_Offset);
            local armor = Player:GetPropInt(Armor_Offset);
            local ammo = activeWeapon:GetPropInt(Ammo_Offset)
            local maxAmmo = WeaponInfo.iMaxClip1

            Render.RectFilled(mainHealthX1, mainHealthY1, mainHealthX2, mainHealthY2, Color.new(25,25,25,HealthOpacity), 2)
            Render.RectFilled(fancyHealthX1, fancyHealthY1, fancyHealthX2, fancyHealthY2, Color.new(r,g,b,HealthOpacity), 2)

            Render.RectFilled(mainHealthX1 + (splitX * 3), mainHealthY1 + (splitY * 1), mainHealthX1 + (splitX * 9), mainHealthY1 + (splitY * 3), Color.new(0,0,0,HealthOpacity), 3)
            Render.RectFilled(mainHealthX1 + (splitX * 3), mainHealthY1 + (splitY * 4), mainHealthX1 + (splitX * 9), mainHealthY1 + (splitY * 6), Color.new(0,0,0,HealthOpacity), 3)
            Render.RectFilled(mainHealthX1 + (splitX * 3), mainHealthY1 + (splitY * 7), mainHealthX1 + (splitX * 9), mainHealthY1 + (splitY * 9), Color.new(0,0,0,HealthOpacity), 3)

            Render.Text("Health:", mainHealthX1 + (splitX * 1.5), mainHealthY1 + (splitY * 1.3), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, HealthOpacity), true, true, "sunflower")
            if(health > 0) then Render.RectFilled(mainHealthX1 + (splitX * 3), mainHealthY1 + (splitY * 1), mainHealthX1 + (splitX * 3) + (((splitX*6) / 100) * health), mainHealthY1 + (splitY * 3),  Color.new(255 - (health * 2.25), health * 2.25, 0, HealthOpacity), 2) end

            Render.Text("Armor:", mainHealthX1 + (splitX * 1.5), mainHealthY1 + (splitY * 4.3), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, HealthOpacity), true, true, "sunflower")
            if(armor > 0) then Render.RectFilled(mainHealthX1 + (splitX * 3), mainHealthY1 + (splitY * 4), mainHealthX1 + (splitX * 3) + (((splitX*6) / 100) * armor), mainHealthY1 + (splitY * 6), Color.new(20,70,255,HealthOpacity), 2) end

            Render.Text("Ammo:", mainHealthX1 + (splitX * 1.5), mainHealthY1 + (splitY * 7.3), (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, HealthOpacity), true, true, "sunflower")
            if(ammo > 0) then Render.RectFilled(mainHealthX1 + (splitX * 3), mainHealthY1 + (splitY * 7), mainHealthX1 + (splitX * 3) + (((splitX*6) / maxAmmo) * ammo), mainHealthY1 + (splitY * 9), Color.new(155,155,155,HealthOpacity), 2) end
        end
    else
        kills = 0
        deaths = 0
        Headshots = 0
        RNG = 0
        ebsucession = 0
        moneySpent = 0
    end
end
Hack.RegisterCallback("PaintTraverse", Paint)

function ClientSideThink(Event)
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 

    local fVelocity = math.floor(VecLenght2D(pLocal:GetPropVector(vVelocity_Offset)) + 0.5)
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
    local moneyOffset = Hack.GetOffset("DT_CSPlayer", "m_iAccount")

    local Flags = pLocal:GetPropInt(fFlags_Offset)

    if(Event:GetName() == "round_end") then
        local winningTeam = Event:GetInt("winner", 0)
        local TeamOffset = Hack.GetOffset("DT_BasePlayer", "m_iTeamNum")
        local Player = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
        local team = Player:GetPropInt(TeamOffset)
    end

    if(Event:GetName() == "round_start")   then
        moneyFirst = pLocal:GetPropInt(moneyOffset)
    end

    if(Event:GetName() == "buytime_ended") then
        local moneyNow = pLocal:GetPropInt(moneyOffset)
        local moneySpentNow = moneyFirst - moneyNow

        moneySpent = moneySpent + moneySpentNow
        sMoneySpent = sMoneySpent + moneySpentNow
    end

    if(Event:GetName() == "player_team") then
        local uid = Event:GetInt("userid")
        local playerLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
        local IsMeLocal = true
    end

    if (Event:GetName() == "player_death") then
        local attacker = Event:GetInt("attacker", 0)
        local AttackerId = IEngine.GetPlayerForUserID(attacker)
        local NoobId = IEngine.GetPlayerForUserID(Event:GetInt("userid", 0))
        if (AttackerId == IEngine.GetLocalPlayer()) then
            if(NoobId == IEngine.GetLocalPlayer()) then
                deaths = deaths + 1
                sdeaths = sdeaths + 1
            else
                if(not IsBit(Flags, ON_GROUND)) then 
                    RNG = RNG + 1 
                    sRNG = sRNG + 1
                end
                if(Event:GetBool("headshot", 0)) then 
                    Headshots = Headshots + 1 
                    sHeadshots = sHeadshots + 1
                end
                kills = kills + 1
                skills = skills + 1
            end
        elseif (NoobId == IEngine.GetLocalPlayer()) then
            deaths = deaths + 1
            sdeaths = sdeaths + 1
        end
    end 

    if Event:GetName() == "player_say" then
        local userid = Event:GetInt("userid")
        local PlayerId = IEngine.GetPlayerForUserID(userid)
        local text = Event:GetString("text")
        Print("oi " .. text)
    end
end
Hack.RegisterCallback("FireEventClientSideThink", ClientSideThink)

function GetLocalName()
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    local PlayerInfo = CPlayerInfo.new()
    pLocal:GetPlayerInfo(PlayerInfo)

    return PlayerInfo.szName
end

function chat(msg)
    
end

function VecLenght2D(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

function Split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
