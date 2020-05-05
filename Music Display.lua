-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Music Display", "cEnableMusicDisplay", true)
Menu.Checkbox("Disable Text", "cMusicText", false)
Menu.Checkbox("Enable Chroma", "cMusicChroma", false)
Menu.Text("Music Provier")
Menu.Combo( "", "cMusicProvider", { "Spotify", "Chrome (SOON)" }, 0)
Menu.Spacing()
Menu.SliderInt("X Position", "cMusicXPos", 1, Globals.ScreenWidth(), "", 100)
Menu.SliderInt("Y Position", "cMusicYPos", 1, Globals.ScreenHeight(), "", 100)
Menu.SliderInt("Size", "cMusicTextSize", 1, 50, "", 20)

--Setup Files
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater")

--Setup Fonts
URLDownloadToFile("https://cdn.discordapp.com/attachments/655694082525364254/700274099775078410/Sunflower.ttf", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf")
Render.LoadFont("sunflowerz", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf", 30)

--Settings thats not open so not gay
local filename = "Songify.txt"
local labelX = (Globals.ScreenWidth() / 100) * 7
local labelY = (Globals.ScreenHeight() / 100) * 92
local size = (Globals.ScreenWidth() / 80)

function PaintTraverse() 
    labelX = Menu.GetInt("cMusicXPos")
    labelY = Menu.GetInt("cMusicYPos")
    size = Menu.GetInt("cMusicTextSize")

    Menu.SetInt("MusicModuleExists", IGlobalVars.curtime + 1)
    
    if(Menu.GetBool("cEnableMusicDisplay")) then
        --Draw RGB
        local r = math.floor(math.sin(IGlobalVars.realtime * 3) * 127 + 128)
        local g = math.floor(math.sin(IGlobalVars.realtime * 3 + 2) * 127 + 128)
        local b = math.floor(math.sin(IGlobalVars.realtime * 3 + 4) * 127 + 128)

        local data = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\" .. filename)
        Menu.SetString("cListening", data)

        if(Utils.IsInGame() and not Menu.GetBool("cMusicText")) then
            if (Menu.GetInt("cMusicProvider") == 0) then
                labelX = (Globals.ScreenWidth() / 100) * (6 + (string.len(data) / 10))
                if(Menu.GetBool("cMusicChroma")) then
                    Render.Text(data, Menu.GetInt("cMusicXPos"), Menu.GetInt("cMusicYPos"), size, Color.new(r, g, b, 255), false, true, "sunflowerz")
                else
                    Render.Text(data, Menu.GetInt("cMusicXPos"), Menu.GetInt("cMusicYPos"), size, Color.new(255, 255, 255, 255), false, true, "sunflowerz")
                end
            end
        end
    end
end
Hack.RegisterCallback("PaintTraverse", PaintTraverse)  
