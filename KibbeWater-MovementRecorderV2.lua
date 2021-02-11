----------------------------------/
------DOCUMENTATION
----StatusTypes:
--0: Idle
--1: Aligning
--2: Executing
--3: End Aim
----Tick:
--pos
--ang
--aimDir
--forwardmove
--sidemove
--upmove
--buttons
--mousedx
--mousedy
----------------------------------/

--Download assets and setup new folders
local csgoIcons = GetCSGOPath() .. "\\csgo\\materials\\panorama\\images\\icons\\"
local csgoLayouts = GetCSGOPath() .. "\\csgo\\panorama\\layout\\"
local layoutSettings = csgoLayouts .. "settings\\"
local csgoScripts = GetCSGOPath() .. "\\csgo\\panorama\\scripts\\"

FileSys.CreateDirectory(csgoLayouts)
FileSys.CreateDirectory(layoutSettings)
FileSys.CreateDirectory(csgoScripts)

Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - Movement Recorder v2")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Saving / Loading")
Menu.Separator()
Menu.InputText("Recording Name", "snowMRName", "")
Menu.Checkbox("Save Recording", "snowMRSave", false)
Menu.Checkbox("Load Recording", "snowMRLoad", false)
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Keybinds")
Menu.Separator()
Menu.KeyBind("Record", "snowMRRecord", 78)
Menu.KeyBind("Playback", "snowMRExecute", 86)
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Customization")
Menu.Separator()
Menu.ColorPicker("Line Color", "snowMRLine", 255, 0, 0, 255)
Menu.ColorPicker("Jumpbug Line Color", "snowMRLineJB", 0, 0, 255, 255)
Menu.ColorPicker("Edgebug Line Color", "snowMRLineEB", 0, 255, 0, 255)
Menu.ColorPicker("JB and EB Line Color", "snowMRLineJBEB", 255, 0, 255, 255)

--Inject panorama button code
local codeCompact = [[<RadioButton id="MovementBTN" class="mainmenu-navbar__btn-small" group="NavBar" onactivate="MainMenu.NavigateToTab(\'MOVEMENTREC\', \'mrec\');" onmouseover="UiToolkitAPI.ShowTextTooltip( \'MovementBTN\', \'Movement recorder options and settings\' );" onmouseout="UiToolkitAPI.HideTextTooltip();"> <Image textureheight="32" texturewidth="-1" src="file://{images}/icons/cam.png" /> </RadioButton>]]

IPanorama.RunScript_Menu([[
    var items = $('#MainMenu').FindChildInLayoutFile('JsMainMenuNavBar');
    var children = items.Children();

    var found = false;
    children.forEach(child => {
        if (child.id == "MovementBTN")
            found = true;
    });
    if (!found){
        items.BCreateChildren(']] .. codeCompact .. [[');

        var first = null;
        var second = null;

        items.Children().forEach(child => {
            if (child.id == "MovementBTN")
                first = child;
            if (child.id == "MainMenuNavBarInventory")
                second = child;
        });

        if (first != null && second != null)
            items.MoveChildAfter(first, second);
    }
]])

--Startup
for i=1, 100 do
	Print("")
end
Print("----------------------------------------------------------------")
Print("                 KibbeWater Movement Recorder v2.0              ")
Print("                             Loading...                         ")
Print("----------------------------------------------------------------")
Print("[Movement Recorder] Downloading and mounting assets, please wait...")

--Create some vars
local gifBasePath = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gifs\\"
local fileExtension = ".png"
local loadedImages = {}
local debug = false
local first = true

--Old data
local oldName = ""

--Rendering info
local FPS = 10
local frame = 0
local LRF = 0
local NFR = 0

--Create Folders
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gifs\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gifs\\rickroll\\")

--Create functions
function LoadGIF(name, keyName)
    local gifPath = gifBasePath .. name .. "\\"
    local i = 0
    local sizeGIF = GifSize(name)
    for y = 1, sizeGIF do
        local size = string.len(tostring(i))
        local fileID = tostring(i)
        for x = 1, 5 - size do fileID = "0" .. fileID end
        local fileName = name .. "_" .. fileID .. fileExtension
        Render.LoadImage(keyName .. "_" .. i, gifPath .. fileName)
        i = i + 1
    end
    table.insert(loadedImages, keyName)
end

function GifSize(name)
    local gifPath = gifBasePath .. name .. "\\"
    local loop = true
    local i = 0
    while loop do
        local size = string.len(tostring(i))
        local fileID = tostring(i)
        for x = 1, 5 - size do fileID = "0" .. fileID end
        local fileName = name .. "_" .. fileID .. fileExtension
        if FileSys.FileIsExist(gifPath .. fileName) then i = i + 1 else loop = false end
    end
    return i
end

--Create hooks
local i = 0
local loadingGif = true
local loadName = "rickroll"
local switch = false
Hack.RegisterCallback("PaintTraverse", function ()
    local exist = FileSys.FileIsExist(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gifs\\rickroll\\rickroll_00000.png")

    if not exist and first then
        Render.Text_1("Loading assets, please wait", 20, 0, 50, Color.new(255,255,255,255)) 
        first = false
        return 
    end

    --Download Assets
    if not exist then
        Render.Text_1("Loading assets, please wait", 20, 0, 50, Color.new(255,255,255,255)) 
        for i = 0, 80 do
            local size = string.len(tostring(i))
            local fileID = tostring(i)
            for x = 1, 5 - size do fileID = "0" .. fileID end
            URLDownloadToFile("https://kibbewater.xyz/interium/assets/rickroll/rickroll_"..fileID..".png", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gifs\\rickroll\\rickroll_"..fileID..".png")
        end
    end

    --Load
    if loadingGif then Render.Text_1("Mounting assets...", 20, 0, 50, Color.new(255,255,255,255))  end
    if loadingGif and not switch then
        local gifPath = gifBasePath .. loadName .. "\\"
        local size = string.len(tostring(i))
        local fileID = tostring(i)
        for x = 1, 5 - size do fileID = "0" .. fileID end
        local fileName = loadName .. "_" .. fileID .. fileExtension
        Render.LoadImage(loadName .. "_" .. i, gifPath .. fileName)
        i = i + 1
        if i >= GifSize(loadName) then 
            loadName = ""
            i = 0
            loadingGif = false
        else switch = true end
    elseif switch then switch = false end

    ::execute::
    if Globals.MenuOpened() and not loadingGif then
        Render.Text_1("Waiting for user to close menu...", 20, 0, 50, Color.new(255,255,255,255))
    end
    if GetInt(Vars.menu_key) ~= 0 and not Globals.MenuOpened() then
        SetInt(Vars.menu_key, 0)
    end
    if not Globals.MenuOpened() then --Render
        local gifLength = GifSize("rickroll")
        if NFR <= IGlobalVars.realtime then --Render frame because were allowed to
            if gifLength - 1 >= frame + 1 then frame = frame + 1 else frame = 0 end
        end
        if Render.IsImage("rickroll" .. "_" .. frame) then
            Render.Image("rickroll_" .. frame, 0, 0, Globals.ScreenWidth(), Globals.ScreenWidth(), Color.new(255,255,255,255), 0, 0, 1, 1) 
        else
            frame = 0
        end
    end

    --Calculate rendering for next frame
    if IGlobalVars.realtime > NFR then
        NFR = IGlobalVars.realtime + 1 / FPS
    end

    --Register old data
    oldName = "rickroll"
end)