-- Init Menu
Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Music Display", "cEnableDisplay", true)
Menu.Checkbox("Disable Text", "cText", false)
Menu.Checkbox("Enable Chroma", "cChroma", false)
Menu.Text("Music Provier")
Menu.Combo( "", "cProvider", { "Spotify", "Chrome (SOON)" }, 0)

--Setup Files
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater")

--Setup Fonts
URLDownloadToFile("https://cdn.discordapp.com/attachments/655694082525364254/700274099775078410/Sunflower.ttf", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf")
Render.LoadFont("sunflower", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf", 30)

--Settings thats not open so not gay
local filename = "Songify.txt"
local labelX = (Globals.ScreenWidth() / 100) * 7
local labelY = (Globals.ScreenHeight() / 100) * 92

function PaintTraverse() 
    Menu.SetInt("MusicModuleExists", IGlobalVars.curtime + 1)

    if(Menu.GetBool("cEnableDisplay")) then
        --Draw RGB
        local r = math.floor(math.sin(IGlobalVars.realtime * 3) * 127 + 128)
        local g = math.floor(math.sin(IGlobalVars.realtime * 3 + 2) * 127 + 128)
        local b = math.floor(math.sin(IGlobalVars.realtime * 3 + 4) * 127 + 128)

        local data = FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\" .. filename)
        Menu.SetString("cListening", data)

        if(Utils.IsInGame() and not Menu.GetBool("cText")) then
            if (Menu.GetInt("cProvider") == 0) then
                labelX = (Globals.ScreenWidth() / 100) * (6 + (string.len(data) / 10))
                if(Menu.GetBool("cChroma")) then
                    Render.Text(data, labelX, labelY, (Globals.ScreenWidth() / 80), Color.new(r, g, b, 255), true, true, "sunflower")
                else
                    Render.Text(data, labelX, labelY, (Globals.ScreenWidth() / 80), Color.new(255, 255, 255, 255), true, true, "sunflower")
                end
            end
        end
    end
end
Hack.RegisterCallback("PaintTraverse", PaintTraverse)  
