Menu.SetString("snow_nogui", "false")
Menu.SetString("snow_config_autoload", "")
Menu.SetString("snow_config_disable_watermark", "false")
Menu.SetString("snow_nogui_disabler", "0")

local appData = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\KibbeWater\\"

FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(appData)

local function Split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function Setup()
    if FileSys.FileIsExist(appData .. "nogui.ini") then
        local lines = Split(FileSys.GetTextFromFile(appData.."nogui.ini"), "\n")
        for i = 1, #lines do
            if lines[i] == "" then goto cont end
            if lines[i]:sub(1,1) == "-" and lines[i]:sub(2,2) == "-" then goto cont end
            
            local line = Split(lines[i], "=")
            if #line > 1 then
                Menu.SetString(line[1], line[2])
                Print("Setting key: " .. line[1] .. " with value: " .. line[2])
            end

            ::cont::
        end
    else FileSys.SaveTextToFile(appData.."nogui.ini", "snow_nogui=false\nsnow_config_autoload=\nsnow_config_disable_watermark=false\nsnow_nogui_disabler=0") end

    if Menu.GetString("snow_nogui"):lower() == "true" then
        if Menu.GetString("snow_config_autoload") ~= "" then
            Hack.LoadCfg(Menu.GetString("snow_config_autoload"))
        end
        if Menu.GetString("snow_config_disable_watermark"):lower() == "true" then
            SetBool(Vars.visuals_watermark, false)
        end
    end
end

Hack.RegisterCallback("PaintTraverse", function()
    if Menu.GetString("snow_nogui"):lower() == "true" then
        if GetInt(Vars.menu_key) ~= 0 and not Globals.MenuOpened() then
            SetInt(Vars.menu_key, 0)
        end
    end

    if InputSys.IsKeyPress(tonumber(Menu.GetString("snow_nogui_disabler"))) then
        Menu.SetString("snow_nogui", "false")
        SetInt(Vars.menu_key, 45)
    end
end)

Setup()