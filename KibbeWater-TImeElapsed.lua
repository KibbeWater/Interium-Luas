Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox("Enable Time Elapsed", "cEnableElapsed", true)
Menu.ColorPicker("Elapsed Text Color", "cElapsedColor", 255, 255, 255, 255)
Menu.Combo( "", "cElapsedPosition", { "Top Left", "Top Right", "Bottom Left", "Bottom Right" }, 0)
Menu.SliderInt("Size", "cElapsedSize", 1, 50, "", 20)
Menu.SliderInt("Position Offset", "cElapsedOffset", 1, 100, "", 20)
Menu.Checkbox("Elapsed Seconds", "cElapsedSeconds", true)
Menu.Checkbox("Elapsed Minutes", "cElapsedMinutes", true)
Menu.Checkbox("Elapsed Hours", "cElapsedHours", true)
Menu.Checkbox("Elapsed Days", "cElapsedDays", true)

--Setup Fonts
URLDownloadToFile("https://cdn.discordapp.com/attachments/655694082525364254/700274099775078410/Sunflower.ttf", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf")
Render.LoadFont("font", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\Sunflower.ttf", 30)

--Global Vars
local seconds = 0
local minutes = 0
local hours = 0
local days = 0

Hack.RegisterCallback("PaintTraverse", function ()
    --Do Calculations
    seconds = math.floor(IGlobalVars.realtime)
    minutes = math.floor(seconds / 60)
    hours = math.floor(minutes / 60)
    days = math.floor(hours / 24)

    seconds = seconds - (minutes * 60)
    minutes = minutes - (hours * 60)
    hours = hours - (days * 24)

    local displaySec = false
    local displayMin = false
    local displayHours = false
    local displayDays = false

    if seconds > 0 and Menu.GetBool("cElapsedSeconds") then displaySec = true end
    if minutes > 0 and Menu.GetBool("cElapsedMinutes") then displayMin = true end
    if hours > 0 and Menu.GetBool("cElapsedHours") then displayHours = true end
    if days > 0 and Menu.GetBool("cElapsedDays") then displayDays = true end

    local composedString = ""
    if displayDays then composedString = composedString .. days .. " Days " end
    if displayHours then composedString = composedString .. hours .. " Hours " end
    if displayMin then composedString = composedString .. minutes .. " Minutes " end
    if displaySec then composedString = composedString .. seconds .. " Seconds " end

    local textSize = Render.CalcTextSize_1(composedString, Menu.GetInt("cElapsedSize"), "font")
    local offset = Menu.GetInt("cElapsedOffset")

    if Menu.GetInt("cElapsedPosition") == 0 then
        Render.Text(composedString, offset, offset, Menu.GetInt("cElapsedSize"), Menu.GetColor("cElapsedColor"), false, true, "font")
    elseif Menu.GetInt("cElapsedPosition") == 1 then
        Render.Text(composedString, Globals.ScreenWidth() - (textSize.x + offset), offset, Menu.GetInt("cElapsedSize"), Menu.GetColor("cElapsedColor"), false, true, "font")
    elseif Menu.GetInt("cElapsedPosition") == 2 then
        Render.Text(composedString, 20, Globals.ScreenHeight() - (textSize.y + offset), Menu.GetInt("cElapsedSize"), Menu.GetColor("cElapsedColor"), false, true, "font")
    elseif Menu.GetInt("cElapsedPosition") == 3 then
        Render.Text(composedString, Globals.ScreenWidth() - (textSize.x + offset), Globals.ScreenHeight() - (textSize.y + 20), Menu.GetInt("cElapsedSize"), Menu.GetColor("cElapsedColor"), false, true, "font")
    end

end)