Hack.UnloadLua("KibbeWater-RichPresence.lua")
local luadir = GetAppData() .. "\\INTERIUM\\CSGO\\Lua\\"
URLDownloadToFile("https://raw.githubusercontent.com/KibbeWater/Interium-Luas/master/KibbeWater-RichPresence.lua", luadir.."KibbeWater-RichPresence.lua")
Hack.LoadLua("KibbeWater-RichPresence.lua")