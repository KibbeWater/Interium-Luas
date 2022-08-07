Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - Millionware")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Feature Settings")
Menu.Separator()
Menu.Spacing()
Menu.Spacing()
Menu.InputFloat("Killsay sound length", "mwF12Time", 0.6)
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Menu Customization")
Menu.Separator()
Menu.Spacing()
Menu.Spacing()
Menu.KeyBind("Menu key", "mwMenuKey", 45)
Menu.ColorPicker("Accent color", "mwAccentColor", 186,0,179, 255)

-- Animation Settings
local FPS = 60

local animStage = 0
local nextAnim = 0

-- Animation Properties IN
local percentAnimatedIn = 0
local percentNeededIn = 100
local animationTimeIn = 0.3

-- Globals
local downloadQueue = {}
local oldEnable = false
local appData = GetAppData() .. "\\Millionware\\"
local assets = appData .. "Assets\\"
local images = appData .. "Images\\"
local font = appData .. "Font\\"
local configs = appData .. "Configs\\"
local sounds = appData .. "Sounds\\"

-- Types
local settingTypes = {
    ["empty"]=1, 
    ["text"]=2, 
    ["checkbox"]=3, 
    ["sliderInt"]=4, 
    ["inputText"]=5, 
    ["dropdown"]=6
}

local parentTypes = {
    ["category"]=1,
    ["checkbox"]=2,
    ["sliderInt"]=3,
    ["inputText"]=4,
    ["dropdown"]=5,
    ["dropdownChild"]=6,
    ["keybind"]=7
}

-- Clantag
local delay = 750
local a1 = 0
local a2 = 0

-- Killsay
local oldF12 = true
local disableTimer = 0
local disableTimerEnabled = false

-- Pre functions
function Download(downloadURL, downloadPath)
    local downloadObj = {}
    downloadObj["URL"] = downloadURL
    downloadObj["Output"] = downloadPath
    table.insert(downloadQueue, downloadObj)
end

-- Create Folders
FileSys.CreateDirectory(appData)
FileSys.CreateDirectory(assets)
FileSys.CreateDirectory(font)
FileSys.CreateDirectory(images)
--FileSys.CreateDirectory(configs)
FileSys.CreateDirectory(sounds)

-- Download Font
Download("https://kibbewater.xyz/interium/assets/sunflower.ttf", font .. "millionware.ttf")

-- Download Logo
Download("https://kibbewater.xyz/interium/assets/MWLogo.png", images .. "MWLogo.png")
Download("https://kibbewater.xyz/interium/assets/MWDollar.png", images .. "MWDollar.png")
Download("https://kibbewater.xyz/interium/assets/MWArrow.png", images .. "MWArrow.png")

-- Config
local sizeX = 580
local sizeY = 390

local settings = {}
local settingsCount = 5

local switchTime = 0.8
local lastSwitch = 0
local switch = false

-- Auto pistol
local switchPistol = false

-- Team damage list
local iDamage = 0
local iKills = 0

-- Autosave
local autoSaveInterval = 5
local lastAutoSave = IGlobalVars.realtime + autoSaveInterval

-- Data handling for dragging
local Dragging = false
local OldDragging = false
local DraggingOffset = Vector.new(0, 0, 0)

local Invalidated = false
local oldMouse = false
local mouseDown = 0

local clantag = {
    "$ millionware",
    "$ e millionwar",
    "$ re millionwa",
    "$ are millionw",
    "$ ware million",
    "$ nware millio",
    "$ onware milli",
    "$ ionware mill",
    "$ lionware mil",
    "$ llionware mi",
    "$ illionware m",
    "$ millionware"
}
local clantagStatic = "$ millionware"

--Graph stuff
    local VelocityArray = { }
    local StaminaArray = { }
    local PlusOnGroundVelocityArray = { }
    local OnGroundVelocityArray = { }
    local IsJBArray = { }
    local VelocityrraySize = 150
    for i = 1, 9999 do
        VelocityArray[i] = 0
        StaminaArray[i] = 0
        PlusOnGroundVelocityArray[i] = -999
        OnGroundVelocityArray[i] = -999
        IsJBArray[i] = -999
    end

    -- Ignore some Times
    local OnGroundTime = 0
    local OnGroundTimeMax = 1250 -- Visual
    local NotJumpingTimeMax = 100 -- Rebuild

    -- For Velocity Old
    local IsOnGroud_old = false
    local VelocityOnGround_old = 0
    local VelocityOnGround = 0

    -- For JB Status
    local IsJBTime = 0
    local IsJBTimeMax = 250

    -- Units
    local LastUnits = 0
    local LastVert = 0
    local vOriginOnGround = Vector.new()

    -- KZ
    local KZ_Jumps = 0
    local KZ_TimeMax = 25
    local KZ_ComboOf245 = 0

    --
    local KZ_Strafes = 0
    local KZ_MaxVelocity = 0
    local KZ_PreVelocity = 0
    local SizeY = 0

    local fVelocity_old = 0 -- Just Velocity old for all
    local vVelocity_old = Vector.new() -- For Check JB

--Menu Data
local window = {}
local clickRegions = {}
local loadedCategory = {}
local lastInteractedSlider = {}
local activeTextInput = {}
local activeKeybind = ""
local canCapture = false
local roundStart = false
local canCheckboxActive = false
local activeDropdown = ""

-- Offsets
local fFlags_Offset = Hack.GetOffset("DT_BasePlayer", "m_fFlags")
local vVelocity_Offset = Hack.GetOffset("DT_BasePlayer", "m_vecVelocity[0]")
local vOrigin_Offset = Hack.GetOffset("DT_BaseEntity", "m_vecOrigin")
local fStamina_Offset = Hack.GetOffset("DT_CSPlayer", "m_flStamina")
local nextPrimaryAttack_Offset = 12856
local iHealth_Offset = Hack.GetOffset("DT_BasePlayer", "m_iHealth")

-- Flag States
local ON_GROUND = 0

--Variables for data tracking
local oldVertical = 0
local validateEB = true
local cooldown = 0
local pendingEB = false

--ISurface Font
local ISurfaceFont = 0
local FontName = "Tahoma"

local FontInited = false

-- For Vec
local function VecLenght(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
end

local function VecLenght2D(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

local function Dist(Vec1, Vec2)
    local vBuf = Vector.new()

    vBuf.x = Vec1.x - Vec2.x
    vBuf.y = Vec1.y - Vec2.y
    vBuf.z = Vec1.z - Vec2.z

    return VecLenght2D(vBuf)
end

local MoveType_NOCLIP = 8
local MoveType_LADDER = 9
local function IsCanMovement(MoveType)
    if (MoveType == MoveType_NOCLIP or MoveType == MoveType_LADDER) then
        return false
    end

    return true
end
function Round(x)
    return x + 0.5 - (x + 0.5) % 1
end

function Split (inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
    return t
end

function UIDToPlayer(uid)
    for i = 1, 64 do
        local pCurrent = IEntityList.GetPlayer(i) 
        if (not pCurrent or pCurrent:GetClassId() ~= 40) then goto continue end

        local Info = CPlayerInfo.new()
        if (not pCurrent:GetPlayerInfo(Info)) then goto continue end

        if Info.userId == uid then
            return i
        end

        ::continue::
    end
end

function DownloadQueue()
    for i = 1, #downloadQueue do
        local downloadURL = downloadQueue[i]["URL"]
        local downloadPath = downloadQueue[i]["Output"]
        URLDownloadToFile(downloadURL, downloadPath)
        if FileSys.FileIsExist(downloadPath) then
            table.remove(downloadQueue, i)
            return
        end
    end
end

function CompareReturn(comparer, returnTrue, returnFalse)
    if comparer then return returnTrue else return returnFalse end
end

function GetType(variableName)
    local stringType = Menu.GetString(variableName)
    local intType = Menu.GetInt(variableName)
    local boolType = Menu.GetBool(variableName)

    if stringType ~= "" then
        return "String"
    else
        if intType ~= 0 then
            return "Int"
        else
            if boolType then
                return "Bool"
            else
                return false
            end
        end
    end
end

function CompareReturn(comparer, returnTrue, returnFalse)
    if comparer then return returnTrue else return returnFalse end
end

function GetAllSettings()
    local allSettings = {}
    for i = 1, #window do
        for x = 1, #window[i]["Sections"] do
            for z = 1, #window[i]["Sections"][x]["Settings"] do
                local setting = window[i]["Sections"][x]["Settings"][z]
                if setting["SettingType"] == 1 or setting["SettingType"] == 2 then goto skip end

                local varName = setting["VariableName"]
                local type = GetType(varName)
                if not type then
                    table.insert(allSettings, varName .. "=B=0")
                    goto skip
                    Print("Skip")
                end
                
                local val = 0
                if type == "String" then val = Menu.GetString(varName) elseif type == "Int" then val = Menu.GetInt(varName) elseif type == "Bool" then val = CompareReturn(Menu.GetBool(varName), "1", "0") end

                table.insert(allSettings, varName .. "=" .. type:sub(1, 1) .. "=" .. tostring(val))

                ::skip::
            end
        end
    end

    local output = ""
    for i = 1, #allSettings do
        if output == "" then output = allSettings[i] else output = output .. "," .. allSettings[i] end
    end

    return output
end

function EncryptString(text)
    local encryptedByte = {}
    local bytes = 1
    for i = 1, #text do
        local c = text:sub(i,i)
        local byte = string.byte(c)

        byte = byte + math.floor(bytes / 2)
        if bytes > 200 then bytes = 1 end
        
        bytes = bytes + 1
        table.insert(encryptedByte, byte)
    end
    
    local encryptedString = ""
    for i = 1, #encryptedByte do
        local c = string.char(encryptedByte[i])
        encryptedString = encryptedString .. c
    end

    return encryptedString
end

function DecryptString(text)
    local decryptedByte = {}
    local bytes = 1
    for i = 1, #text do
        local c = text:sub(i,i)
        local byte = string.byte(c)

        byte = byte - math.floor(bytes / 2)
        if bytes > 200 then bytes = 1 end
        
        bytes = bytes + 1
        table.insert(decryptedByte, byte)
    end

    local decryptedString = ""
    for i = 1, #decryptedByte do
        local c = string.char(decryptedByte[i])
        decryptedString = decryptedString .. c
    end

    return decryptedString
end

function SetDefaultSettings()
    settings["position"] = Vector.new(100, 100, 0)
    settings["size"] = Vector.new(580, 390, 0)
    settings["menuKey"] = 45
    settings["accentClr"] = Color.new(186,0,179,255)
end

function AssignMenuVars()
    Menu.SetInt("mwMenuKey", settings["menuKey"])
    Menu.SetColor("mwAccentColor", settings["accentClr"])
end

function AssignSettingsVar()
    settings["menuKey"] = Menu.GetInt("mwMenuKey")
    settings["accentClr"] = Menu.GetColor("mwAccentColor")
end

--Setup Setting creators
function AddEmpty(categorySetting)
    local empty = {}
    empty["SettingType"] = settingTypes.empty
    table.insert(categorySetting, empty)
end

function AddText(categorySetting, Parent, Text)
    local text = {}
    text["SettingType"] = settingTypes.text
    text["SettingParent"] = Parent
    text["Text"] = Text
    table.insert(categorySetting, text)
end

function AddCheckbox(categorySetting, Parent, Text, OutVar, useKeybind, keyVar)
    local keybind = {}
    keybind["VariableName"] = keyVar
    local checkbox = {}
    checkbox["SettingType"] = settingTypes.checkbox
    checkbox["SettingParent"] = Parent
    checkbox["Text"] = Text
    checkbox["VariableName"] = OutVar
    checkbox["useKeybind"] = useKeybind
    checkbox["keybind"] = keybind
    table.insert(categorySetting, checkbox)
end

function AddSliderInt(categorySetting, Parent, Text, Min, Max, OutVar)
    local sliderInt = {}
    sliderInt["SettingType"] = settingTypes.sliderInt
    sliderInt["SettingParent"] = Parent
    sliderInt["Text"] = Text
    sliderInt["Min"] = Min
    sliderInt["Max"] = Max
    sliderInt["VariableName"] = OutVar
    table.insert(categorySetting, sliderInt)
end

function AddTextbox(categorySetting, Parent, Text, OutVar)
    local textbox = {}
    textbox["SettingType"] = settingTypes.inputText
    textbox["SettingParent"] = Parent
    textbox["Text"] = Text
    textbox["VariableName"] = OutVar
    table.insert(categorySetting, textbox)
end

function AddDropdown(categorySetting, Parent, Text, Items, Default, OutVar)
    local Dropdown = {}
    Dropdown["SettingType"] = settingTypes.dropdown
    Dropdown["SettingParent"] = Parent
    Dropdown["Text"] = Text
    Dropdown["Active"] = false
    Dropdown["Items"] = Items
    Dropdown["Current"] = Default
    Dropdown["VariableName"] = OutVar
    table.insert(categorySetting, Dropdown)
end

function VerifyData()
    settings["position"].x = Clamp(settings["position"].x, 0, Globals.ScreenWidth() - sizeX)
    settings["position"].y = Clamp(settings["position"].y, 0, Globals.ScreenHeight() - sizeY)
end

function Setup()
    --Load Config
    local configPath = appData .. "menu.cfg"
    if FileSys.FileIsExist(configPath) then
        local decrypted = DecryptString(FileSys.GetTextFromFile(configPath))
        local data = Split(decrypted, "\n")
        
        if #data >= settingsCount then
            local posSplit = Split(data[1], ",")
            settings["position"] = Vector.new(tonumber(posSplit[1]), tonumber(posSplit[2]), 0)
            local sizeSplit = Split(data[2], ",")
            settings["size"] = Vector.new(tonumber(sizeSplit[1]), tonumber(sizeSplit[2]), 0)
            local accentSplit = Split(data[3], ",")
            settings["accentClr"] = Color.new(tonumber(accentSplit[1]), tonumber(accentSplit[2]), tonumber(accentSplit[3]), 255)
            settings["menuKey"] = tonumber(data[4])
            local vars = Split(data[5], ",")

            for i = 1, #vars do
                local varSplit = Split(vars[i], "=")
                local varName = varSplit[1]
                local varType = varSplit[2]
                local value = varSplit[3]

                if varType == "B" then

                    Menu.SetBool(varName, CompareReturn(value:lower() == "1", true, false))

                elseif varType == "S" then
                    Menu.SetString(varName, value)
                elseif varType == "I" then
                    Menu.SetInt(varName, tonumber(value))
                end
            end

            VerifyData()
        else SetDefaultSettings() end
    else SetDefaultSettings() end
    AssignMenuVars()

    SetupMenu()
end

function SaveConfig()
    --Continue if settings exist
    local configPath = appData .. "menu.cfg"
    local saveString = ""
    local settingszz = GetAllSettings()

    --Add settings
    saveString = saveString .. settings["position"].x .. "," .. settings["position"].y
    saveString = saveString .. "\n" .. settings["size"].x .. "," .. settings["size"].y
    saveString = saveString .. "\n" .. settings["accentClr"].r .. "," .. settings["accentClr"].g .. "," .. settings["accentClr"].b
    saveString = saveString .. "\n" .. Menu.GetInt("mwMenuKey")
    saveString = saveString .. "\n" .. settingszz
    saveString = EncryptString(saveString)

    FileSys.SaveTextToFile(configPath, saveString)

end



function CutTextStart(text, maxLength)
    local returnString = text
    while Render.CalcTextSize_1(returnString, 15).x > maxLength do
        returnString = string.sub(returnString, 2)
    end
    return returnString
end

local function FindCategory(Name)
    for i = 1, #window do
        if window[i]["Name"] == Name then
            return window[i]
        end
    end
end

function Print_r(arr, indentLevel)
    local str = ""
    local indentStr = "#"

    if(indentLevel == nil) then
        Print(Print_r(arr, 0))
        return
    end

    for i = 0, indentLevel do
        indentStr = indentStr.."."
    end

    for index,value in pairs(arr) do
        if type(value) == "table" then
            str = str..indentStr..index..": \necho "..Print_r(value, (indentLevel + 1))
        else 
            str = str..indentStr..index..": "..tostring(value).."\n echo "
        end
    end
    return str
end

function Tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function InitFont()
	if (not FontInited) then
		if (ISurfaceFont == 0) then
			ISurfaceFont = ISurface.CreateFont_()
			ISurface.SetFontGlyphSet(ISurfaceFont, "Tahoma", 13, 500, 0, 0, 0x200 + 0x400, 0, 0)
		end
		
        FontInited = true
	end
end

function Clamp(current, min, max) 
    return math.min(math.max(current, min), max);
end

Hack.RegisterCallback("LockCursor", function (lock)
    if Menu.GetBool("mwMenu") then 
        SetBool(lock, true)
    end
end)

Hack.RegisterCallback("PaintTraverse", function ()
    DownloadQueue()

    --Simple Vars
    local posX = tonumber(settings["position"].x)
    local posY = tonumber(settings["position"].y)

    --Menu Code
    local loaded = false
    if not loaded and not Render.IsFont("mwFont") then
        Render.LoadFont("mwFont", font .. "millionware.ttf", 30)
        loaded = true
    end

    for i = 1, #window do
        if window[i]["useImg"] and not Render.IsImage(window[i]["Name"]) and not loaded then
            Render.LoadImage(window[i]["Name"], window[i]["Image"]["Path"])
            loaded = true
        end
    end

    if not loaded and not Render.IsImage("MWLogo") then 
        Render.LoadImage("MWLogo", images .. "MWLogo.png")
        loaded = true
    end

    if not loaded and not Render.IsImage("MWDollar") then
        Render.LoadImage("MWDollar", images .. "MWDollar.png")
        loaded = true
    end

    if not loaded and not Render.IsImage("MWArrow") then
        Render.LoadImage("MWArrow", images .. "MWArrow.png")
        loaded = true
    end

    --Autosave
    if IGlobalVars.realtime >= lastAutoSave + autoSaveInterval then
        SaveConfig()
        lastAutoSave = IGlobalVars.realtime + autoSaveInterval
    end

    --If not default Color
    if Menu.GetColor("clrMenuMain") ~= Color.new(25,25,25,255) then
        AssignSettingsVar()
    end

    --Handle Toggling
    if InputSys.IsKeyPress(Menu.GetInt("mwMenuKey")) or oldEnable ~= Menu.GetBool("mwMenu") then
        if Menu.GetBool("mwMenu") then 
            animStage = 1
            Menu.SetBool("mwMenu", false)
        else 
            animStage = 2 
            Menu.SetBool("mwMenu", true)
        end
    end

    --Replace Interium
    if Menu.GetBool("mwReplaceInt") then SetInt(Vars.menu_key, 0) else SetInt(Vars.menu_key, 45) end

    --Handle Animations
    if animStage == 1 and IGlobalVars.realtime > nextAnim then
        percentAnimatedIn = percentAnimatedIn + 1
        if percentAnimatedIn >= percentNeededIn then 
            animStage = 0
            nextAnim = 0
        end
    elseif animStage == 2 and IGlobalVars.realtime > nextAnim then
        percentAnimatedIn = percentAnimatedIn - 1
        if percentAnimatedIn <= 0 then 
            animStage = 0
            nextAnim = 0
        end
    end

    --Clear click regions
    clickRegions = {}

    --Render cheat functions before menu to keep menu on first priority
    Draw()

    --Render
    local clr = Menu.GetColor("clrMenuMain")
    local alpha = clr.a
    alpha = (alpha / percentNeededIn) * percentAnimatedIn
    if Menu.GetBool("mwMenu") then alpha = 255 else alpha = 0 end

    local tabClr = Color.new(15,15,15,alpha)
    local tabClrActive = Color.new(23,23,23,alpha)
    local tabClrHover = Color.new(23,23,23,alpha)
    local themeClr = Color.new(settings["accentClr"].r,settings["accentClr"].g,settings["accentClr"].b, alpha)


    local tabColor = tabClr

    --Render main window
    Render.RectFilledMultiColor(posX, posY, posX + sizeX, posY + sizeY-359, 
        Color.new(25,25,25,alpha), 
        Color.new(25,25,25,alpha), 
        Color.new(13,13,13,alpha),
    Color.new(13,13,13,alpha))
    Render.RectFilled(posX, posY + sizeY-359, posX + sizeX, posY + sizeY, Color.new(13,13,13,alpha), 0)

    --Border
    Render.Rect(posX, posY, posX + sizeX, posY + sizeY, Color.new(0,0,0,alpha), 0, 1)

    --Render inner window (Offset 10)
    Render.RectFilled(posX + 10, posY + 30, posX + sizeX - 10, posY + sizeY - 10, Color.new(18,18,18,alpha), 0)
	
    --Render settings border
    Render.Rect(posX + 10 + 123 + 10, posY + 30 + 7, posX + sizeX - 17, posY + sizeY - 17, Color.new(0,0,0,alpha), 0, 0)

    --Inner border
    Render.Rect(posX + 10, posY + 30, posX + sizeX - 10, posY + sizeY - 10, Color.new(0,0,0,alpha), 0, 1)

    --Render Image
    Render.Image("MWLogo", posX + 30, posY + 49, posX + 30 + 90, posY + 49 + 40, Color.new(255,255,255,alpha), 0, 0, 1, 1)
    Render.Image("MWDollar", posX + 30, posY + 49, posX + 30 + 90, posY + 49 + 40, Color.new(themeClr.r,themeClr.g,themeClr.b,alpha), 0, 0, 1, 1)
    Render.RectFilled(posX + 30 + 88, posY + 49 + 30, posX + 30 + 90, posY + 49 + 40, Color.new(18,18,18,alpha), 0)

    --Movement recorder
    for i = 1, #window do
        if window[i]["Name"] == "Movement Recorder" then
            if Menu.GetInt("mwMovementEnable")+1 > IGlobalVars.realtime then
                window[i]["Enabled"] = true
            else window[i]["Enabled"] = false end
        end
    end

    local menuOpen = alpha == 255

    --Render categories
    for i = 1, #window do
        if not window[i]["Enabled"] then goto skipRender end

        local cSizeX = 123
        local cSizeY = 30

        local cPosX = posX + 10 + 5
        local cPosY = posY + 30 + 87 + (cSizeY * (i-1)) + ((i-1)*5)
		
        local cursor = InputSys.GetCursorPos()

        tabColor = tabClr
		
        if cursor.x > cPosX and cursor.x < cPosX + cSizeX and cursor.y > cPosY and cursor.y < cPosY + cSizeY then tabColor = tabClrHover end

        if window[i]["Name"] == loadedCategory["Name"] then 
            tabColor = tabClrActive 
            Render.Rect(cPosX+1, cPosY, cPosX + 3, cPosY + cSizeY, themeClr, 0, 1)
        end

        --Render button
        Render.RectFilled(cPosX, cPosY, cPosX + cSizeX, cPosY + cSizeY, tabColor, 0)

        --Render button border
        Render.Rect(cPosX, cPosY, cPosX + cSizeX, cPosY + cSizeY, Color.new(0,0,0,alpha), 0, 0)

        if window[i]["Name"] == loadedCategory["Name"] then Render.Rect(cPosX+1, cPosY+1, cPosX + 3, cPosY + cSizeY-1, themeClr, 0, 1) end

        if not window[i]["useImg"] then 
            local TSize = Render.CalcTextSize(window[i]["Name"], 13, "mwFont")
            Render.Text(window[i]["Name"], cPosX + 12, cPosY + ((cSizeY/2)-TSize.y/2), 13, Color.new(255,255,255,alpha), false, false, "mwFont")
        else
            local size = window[i]["Image"]["Size"]
            Render.Image(window[i]["Name"], (cPosX + (cSizeX/2)) - size.x/2, (cPosY + (cSizeY/2))-size.y/2, (cPosX + (cSizeX/2)) + size.x/2, (cPosY + (cSizeY/2)) + size.y/2, Color.new(255,255,255,alpha), 0, 0, 1, 1)
        end

        if window[i]["Name"] == loadedCategory["Name"] then --Create Settings
                local nextInline = 0
                local removeInline = 0
				
                for y = 1, #loadedCategory["Sections"] do
                    if nextInline ~= 0 or loadedCategory["Sections"][y]["Inline"] then 
                        if nextInline == 0 then 
                            nextInline = 1 
                            removeInline = removeInline + 1
                        else nextInline = 0 end
                    end
                end

                nextInline = 0
				
                local lastxSize = 0
                local lastxPos = 0

                for y = 1, #loadedCategory["Sections"] do
                    local addAmount = loadedCategory["Sections"][y]["ScrollOffset"]
                    local render = {}

                    local loadedSection = loadedCategory["Sections"][y]
                    local sections = #loadedCategory["Sections"]

                    local sbSizeY = (posY + sizeY - 17 -7) - (posY + 30 + 14)
                    local sbPosY = posY + 30 + 14

                    if nextInline ~= 0 or loadedCategory["Sections"][y]["Inline"] then 
                        sbSizeY = (((posY + sizeY - 17 -7) - (posY + 30 + 14))- (11 * (y-1))) / 2
                        sbPosY = (posY + 30 + 14) + (sbSizeY * (nextInline)) + (11 * (y-1))
                        if nextInline == 0 then nextInline = 1 else nextInline = 0 end
                    end

                    local sbSizeX = (((posX + sizeX - 17) - (posX + 10 + cSizeX + 10)) - (11 * ((sections-removeInline) - (y-2)))) / (sections-removeInline)
                    local sbPosX = (posX + 10 + cSizeX + 17) + (sbSizeX * (y-1)) + (11 * (y-1))

                    if nextInline == 1 then
                        --sbSizeX = lastxSize
                        --sbPosX = lastxPos
                    end
					
                    lastxSize = sbSizeX
                    lastxPos = sbPosX
					
                    local sStart = posY + 30 + 14
                    local sEnd = posY + sizeY - 17 -7

                    --Render sections
                    if loadedCategory["Sections"][y]["useSeperator"] then 
                        Render.Rect(sbPosX, sbPosY, sbPosX + sbSizeX, sbPosY + sbSizeY, Color.new(0,0,0,alpha), 0, 0) 
                        local textSize = Render.CalcTextSize(loadedCategory["Sections"][y]["Name"], 13, "mwFont")
                        Render.RectFilled(sbPosX + 13, posY + 43, sbPosX + 13 + textSize.x + 2, posY + 45, Color.new(18,18,18,alpha))
                        Render.Text(loadedCategory["Sections"][y]["Name"], sbPosX + 15, posY + (48 - textSize.y), 13, Color.new(255,255,255,alpha), false, false, "mwFont")
                    end

                    local loadedCheckboxes = {}
                    for x = 1, #loadedCategory["Sections"][y]["Settings"] do
                        local cSizeY = 123

                        local sSizeX = ((sizeX - 17) - ((y)*11) - 14) / sections

                        local sPosX = (posX + 10 + cSizeX + 20 + 25) + (sbSizeX * (y-1)) + (11 * (y-1))
                        local sPosY = (posY + 37 + 15) + addAmount

                        table.insert(render, addAmount)

                        if loadedSection["Settings"][x]["SettingType"] == settingTypes.empty then --Empty
                            addAmount = addAmount + 20
                        end

                        if loadedSection["Settings"][x]["SettingType"] == settingTypes.text then --Text
                            local parent = loadedSection["Settings"][x]["SettingParent"]
                            local fSetting = false
						
                            if parent ~= "" then for l = 1, #loadedCheckboxes do if loadedCheckboxes[l] == parent then fSetting = true end end else fSetting = true end
                            if not fSetting then goto skipSettings end

                            Render.Text(loadedSection["Settings"][x]["Text"], sPosX, sPosY, 13, Color.new(255,255,255,alpha), false, false, "mwFont")
                            addAmount = addAmount + Render.CalcTextSize_1(loadedSection["Settings"][x]["Text"], 13).y + 6
                        end

                        if loadedSection["Settings"][x]["SettingType"] == settingTypes.checkbox then --Checkbox
                            local parent = loadedSection["Settings"][x]["SettingParent"]
                            local fSetting = false
                            local checkboxTextClr = Color.new(255,255,255,alpha)

                            if parent ~= "" then for l = 1, #loadedCheckboxes do if loadedCheckboxes[l] == parent then fSetting = true end end else fSetting = true end
                            if not fSetting then goto skipSettings end

                            local sizeText = Render.CalcTextSize(loadedSection["Settings"][x]["Text"], 13, "mwFont")

                            if sPosY+1 <= sStart or sPosY + 12 >= sEnd then goto skipSettings end
                            if cursor.x >= sPosX-19 and cursor.x <= sPosX + sizeText.x and cursor.y >= sPosY-1 and cursor.y <= sPosY+10 then Render.RectFilled(sPosX-19, sPosY+1, sPosX-8, sPosY + 12, Color.new(25,25,25,alpha), 0) end

                            if Menu.GetBool(loadedSection["Settings"][x]["VariableName"]) then 
                                Render.RectFilled(sPosX-19, sPosY+1, sPosX-8, sPosY + 12, Color.new(themeClr.r,themeClr.g,themeClr.b,alpha), 0)
                            else
                                checkboxTextClr = Color.new(200,200,200,alpha)
                            end
							
                            Render.Rect(sPosX-19, sPosY+1, sPosX-8, sPosY + 12, Color.new(0,0,0,alpha), 0, 1)
                            Render.Text(loadedSection["Settings"][x]["Text"], sPosX, sPosY, 13, checkboxTextClr, false, false, "mwFont")
                            addAmount = addAmount + 11 + 6

                            if Menu.GetBool(loadedSection["Settings"][x]["VariableName"]) then table.insert(loadedCheckboxes, loadedSection["Settings"][x]["VariableName"]) end

                            --Keybind
                            if loadedSection["Settings"][x]["useKeybind"] then

                                local keybindClr = Color.new(80,80,80,alpha)
                                local varNameKeybind = loadedSection["Settings"][x]["keybind"]["VariableName"]
							
                                Render.Rect(sbPosX + sbSizeX - (12+19), sPosY-1, sbPosX + sbSizeX - 12, sPosY+10, Color.new(0,0,0,alpha), 0, 1)
                                Render.Rect(sbPosX + sbSizeX - (12+18), sPosY, sbPosX + sbSizeX - 13, sPosY+9, Color.new(27,27,27,alpha), 0, 1)
								
                                local text = GetKey(Menu.GetInt(varNameKeybind)+1)
                                if activeKeybind == loadedSection["Settings"][x]["keybind"]["VariableName"] then 
                                    keybindClr = Color.new(255,255,0,alpha)
                                end
                                if text == "Unknown" then text = "..." end
                                local keybindSize = Render.CalcTextSize(text, 11, "mwFont")
                                Render.Text(text, sbPosX + (sbSizeX - (21)), sPosY+((9/2) - (keybindSize.y/2)), 11, keybindClr, true, false, "mwFont")

                                --Create Click Region
                                local region = {}
                                region["Position"] = Vector.new(sbPosX + sbSizeX - (12+19), sPosY-1, 0)
                                region["Size"] = Vector.new(19, 11, 0)
                                region["Parent"] = loadedSection["Settings"][x]["keybind"]["VariableName"]
                                region["ParentType"] = 7
                                table.insert(clickRegions, region)
                            end

                            --Create Click Region
                            local region = {}
                            region["Position"] = Vector.new(sPosX-19, sPosY+1, 0)
                            region["Size"] = Vector.new(19+sizeText.x, 11, 0)
                            region["Parent"] = loadedSection["Settings"][x]["VariableName"]
                            region["ParentType"] = 2
                            table.insert(clickRegions, region)
                        end

                        if loadedSection["Settings"][x]["SettingType"] == settingTypes.sliderInt then --Slider Int
                            local parent = loadedSection["Settings"][x]["SettingParent"]
                            local fSetting = false
                            if parent ~= "" then for l = 1, #loadedCheckboxes do if loadedCheckboxes[l] == parent then fSetting = true end end else fSetting = true end
                            if not fSetting then goto skipSettings end

                            local textSize = Render.CalcTextSize_1(loadedSection["Settings"][x]["Text"], 13)
                            if (sPosY+textSize.y)+12 <= sStart or (sPosY+textSize.y)+4 >= sEnd then goto skipSettings end
                            Render.Text(loadedSection["Settings"][x]["Text"], sPosX, sPosY, 13, Color.new(255,255,255,alpha), false, false, "mwFont")

                            local Max = loadedSection["Settings"][x]["Max"]
                            local sliderSize = (((sbPosX + sbSizeX - 32) - sPosX) / Max) * (Menu.GetInt(loadedSection["Settings"][x]["VariableName"]))

                            Render.RectFilled(sPosX, (sPosY+textSize.y)+4, sbPosX + sliderSize + (32-4), (sPosY+textSize.y)+12, themeClr) --Scroll
                            Render.Rect(sPosX, (sPosY+textSize.y)+4, sbPosX + sbSizeX - 32, (sPosY+textSize.y)+12, Color.new(0,0,0,alpha)) --BG

                            local num = tostring(Menu.GetInt(loadedSection["Settings"][x]["VariableName"]))
                            local numSize = Render.CalcTextSize_1(num, 14)
                            Render.Text(num, sbPosX + sbSizeX - (32+numSize.x), (sPosY+textSize.y) - numSize.y, 14, Color.new(153,153,153,alpha), false, false, "mwFont")

                            addAmount = addAmount + textSize.y + 12 + 6

                            --Create Click Region
                            local region = {}
                            region["Position"] = Vector.new(sPosX, sPosY+textSize.y+4, 0)
                            region["Size"] = Vector.new((sbPosX + sbSizeX - 32) - sPosX, 8, 0)
                            region["Parent"] = loadedSection["Settings"][x]
                            region["ParentType"] = 3
                            table.insert(clickRegions, region)
                        end

                        if loadedSection["Settings"][x]["SettingType"] == settingTypes.inputText then --Text Input
                            local parent = loadedSection["Settings"][x]["SettingParent"]
                            local fSetting = false
                            if parent ~= "" then for l = 1, #loadedCheckboxes do if loadedCheckboxes[l] == parent then fSetting = true end end else fSetting = true end
                            if not fSetting then goto skipSettings end
                            local Text = loadedSection["Settings"][x]["Text"]

                            local textSize = Render.CalcTextSize(Text, 13, "mwFont")

                            if sPosY+textSize.y+21 <= sStart or sPosY+textSize.y+3 >= sEnd then goto skipSettings end

                            --Text
                            Render.Text(Text, sPosX+3, sPosY, 13, Color.new(255,255,255,alpha), false, false, "mwFont")

                            --Textbox
                            Render.RectFilledMultiColor(sPosX+3, sPosY+textSize.y+3, sbPosX+sbSizeX-30, sPosY+textSize.y+21, 
                                Color.new(24,24,24,alpha), 
                                Color.new(24,24,24,alpha), 
                                Color.new(17,17,17,alpha), 
                            Color.new(17,17,17,alpha))
                            Render.Rect(sPosX+3, sPosY+textSize.y+3, sbPosX+sbSizeX-30, sPosY+textSize.y+21, Color.new(0,0,0,alpha), 0, 1)

                            local text = CutTextStart(Menu.GetString(loadedSection["Settings"][x]["VariableName"]), (sbPosX+sbSizeX-30) - (sPosX+3))

                            local varSize = Render.CalcTextSize(text, 13, "mwFont")
                            local textboxClr = Color.new(255,255,255,alpha)
                            if text == "" then 
                                if Tablelength(activeTextInput) == 0 then
                                    text = "..." 
                                    textboxClr = Color.new(80,80,80,alpha) 
                                else
                                    if activeTextInput["Parent"]["Text"] ~= loadedSection["Settings"][x]["Text"] then
                                        text = "..." 
                                        textboxClr = Color.new(80,80,80,alpha) 
                                    end
                                end
                            end
                            Render.Text(text, sPosX+6, (sPosY+textSize.y+21) - varSize.y - 4, 13, textboxClr, false, false, "mwFont")

                            if switch and Tablelength(activeTextInput) ~= 0 then
                                if activeTextInput["Parent"]["Text"] == loadedSection["Settings"][x]["Text"] then Render.Line(sPosX+6+varSize.x+2, (sPosY+textSize.y+21) - varSize.y - 2, sPosX+6+varSize.x+2, (sPosY+textSize.y+21) - 6, Color.new(255,255,255,alpha), 1) end
                            end

                            if IGlobalVars.realtime > lastSwitch + switchTime then
                                if switch then switch = false else switch = true end
                                lastSwitch = IGlobalVars.realtime
                            end


                            addAmount = addAmount + textSize.y + 21 + 6

                            --Create Click Region
                            local region = {}
                            region["Position"] = Vector.new(sPosX+3, sPosY+textSize.y+3, 0)
                            region["Size"] = Vector.new((sbPosX+sbSizeX-30) - (sPosX+3), (sPosY+textSize.y+21) - (sPosY+textSize.y+3), 0)
                            region["Parent"] = loadedSection["Settings"][x]
                            region["ParentType"] = 4
                            table.insert(clickRegions, region)
                        end

                        if loadedSection["Settings"][x]["SettingType"] == settingTypes.dropdown then --Dropdown
                            local parent = loadedSection["Settings"][x]["SettingParent"]
                            local fSetting = false
                            if parent ~= "" then for l = 1, #loadedCheckboxes do if loadedCheckboxes[l] == parent then fSetting = true end end else fSetting = true end
                            if not fSetting then goto skipSettings end
                            local setting = loadedSection["Settings"][x]

                            local textSize = Render.CalcTextSize(setting["Text"], 13, "mwFont")

                            --Text
                            Render.Text(setting["Text"], sPosX, sPosY, 13, Color.new(255,255,255,alpha), false, false, "mwFont")

                            --Dropdown
                            Render.RectFilledMultiColor(sPosX, sPosY+textSize.y+3, sbPosX+sbSizeX-32, sPosY+textSize.y+21, 
                                Color.new(24,24,24,alpha), 
                                Color.new(24,24,24,alpha), 
                                Color.new(17,17,17,alpha), 
                            Color.new(17,17,17,alpha))
                            Render.Rect(sPosX, sPosY+textSize.y+3, sbPosX+sbSizeX-32, sPosY+textSize.y+21, Color.new(0,0,0,alpha))

                            local varSize = Render.CalcTextSize(setting["Items"][setting["Current"]], 13, "mwFont")
                            Render.Text(setting["Items"][setting["Current"]], sPosX + 3, (sPosY+textSize.y+21) - varSize.y-2, 13, Color.new(255,255,255,alpha), false, false, "mwFont")

                            Render.Image("MWArrow", sbPosX+sbSizeX-42, sPosY+textSize.y+3+8, sbPosX+sbSizeX-37, sPosY+textSize.y+3+12, Color.new(255,255,255,alpha), 0, 0, 1, 1)

                            table.insert(loadedCheckboxes, loadedSection["Settings"][x]["VariableName"] .. "[" .. loadedSection["Settings"][x]["Current"] .. "]")

                            addAmount = addAmount + textSize.y + 21 + 6
                        end
                        ::skipSettings::
                    end 

                    Render.RectFilledMultiColor(sbPosX+1, sbPosY + sbSizeY - 11, sbPosX + sbSizeX - 1, sbPosY + sbSizeY - 1,
                        Color.new(17,17,17,0),
                        Color.new(17,17,17,0),
                        Color.new(17,17,17,alpha),
                    Color.new(17,17,17,alpha))

                    --Render inner window (Offset 10)
                    Render.RectFilled(posX + 10 + 123 + 10, (posY + sizeY - 17 - 7), posX + sizeX - 11, posY + sizeY - 11, Color.new(18,18,18,alpha), 0)

                    --Render settings border
                    Render.Rect(posX + 10 + 123 + 10, posY + 30 + 7, posX + sizeX - 17, posY + sizeY - 17, Color.new(0,0,0,alpha), 0, 0)

                    --Render dropdowns with higher priority
                    for x = 1, #loadedCategory["Sections"][y]["Settings"] do
                        local parent = loadedSection["Settings"][x]["SettingParent"]
                        local fSetting = false
						
                        if parent ~= "" then for l = 1, #loadedCheckboxes do if loadedCheckboxes[l] == parent then fSetting = true end end else fSetting = true end

                        if not fSetting then goto skipSettings end
                        local cSizeY = 123

                        local sSizeX = ((sizeX - 17) - ((y)*11) - 14) / sections

                        local sPosX = (posX + 10 + cSizeX + 20 + 25) + (sbSizeX * (y-1)) + (11 * (y-1))
                        local sPosY = (posY + 37 + 15) + render[x]

                        if loadedSection["Settings"][x]["SettingType"] == 6 then --Dropdown
                            local setting = loadedSection["Settings"][x]
                            local textSize = Render.CalcTextSize(setting["Text"], 13, "mwFont")

                            if sPosY+textSize.y+21 <= sStart or sPosY+textSize.y+3 >= sEnd then goto skipSettings end
                            Menu.SetInt(setting["VariableName"], setting["Current"])

                            setting["ID"] = x
                            setting["Section"] = y

                            --Create Click Region
                            local region = {}
                            region["Position"] = Vector.new(sPosX, sPosY+textSize.y+3, 0)
                            region["Size"] = Vector.new((sbPosX+sbSizeX-32) - sPosX, (sPosY+textSize.y+21) - (sPosY+textSize.y+3), 0)
                            region["Parent"] = setting
                            region["ParentType"] = parentTypes.dropdown

                            table.insert(clickRegions, region)

                            if setting["Active"] and activeDropdown == setting["VariableName"] then
                                local extendz = textSize.y+21
                                for zf = 1, #setting["Items"] do
                                    local obj = setting
                                    local extendStart = extendz
                                    extendz = extendz + 4
                                    local tSize = Render.CalcTextSize(setting["Items"][zf], 15, "mwFont")
                                    if zf ~= #setting["Items"] then extendz = extendz + tSize.y + 5 else extendz = extendz + tSize.y-1 end

                                    local regionZ = {}
                                    regionZ["Position"] = Vector.new(sPosX, extendStart + sPosY, 0)
                                    regionZ["Size"] = Vector.new((sbPosX+sbSizeX-32) - sPosX, extendz - extendStart, 0)
                                    regionZ["Parent"] = obj
                                    regionZ["ParentType"] = 6
                                    regionZ["ItemID"] = zf
                                    table.insert(clickRegions, regionZ)
                                end

                                Render.RectFilled(sPosX, sPosY+textSize.y+21, sbPosX+sbSizeX-32, extendz + sPosY, Color.new(17,17,17,alpha))
                                Render.Rect(sPosX, sPosY+textSize.y+21, sbPosX+sbSizeX-32, extendz + sPosY, Color.new(0,0,0,alpha))
                                extendz = textSize.y+21

                                for z = 1, #setting["Items"] do

                                    local extendStart = extendz
                                    extendz = extendz + 4
                                    local extendz2 = extendz
                                    local tSize = Render.CalcTextSize(setting["Items"][z], 13, "mwFont")

                                    if z ~= #setting["Items"] then extendz2 = extendz + tSize.y + 5 else extendz2 = extendz + tSize.y+5 end

                                    if cursor.x > sPosX+1 and cursor.x < sbPosX+sbSizeX-33 and cursor.y > extendStart + sPosY and cursor.y < extendz2 + sPosY then
                                        Render.RectFilled(sPosX+1, extendStart + sPosY, sbPosX+sbSizeX-33, extendz2 + sPosY, Color.new(25,25,25,alpha))
                                    end

                                    if tostring(setting["Current"]) ~= tostring(z) then 
                                        Render.Text(setting["Items"][z], sPosX+10, extendz + sPosY, 13, Color.new(255,255,255,alpha), false, false, "mwFont") else
                                    Render.Text(setting["Items"][z], sPosX+10, extendz + sPosY, 13, themeClr, false, false, "mwFont") end

                                    if z ~= #setting["Items"] then extendz = extendz + tSize.y + 5 else extendz = extendz + tSize.y-1 end
                                end
                            elseif setting["Active"] and not canCheckboxActive then window[i]["Sections"][y]["Settings"][x]["Active"] = false end
                        end
                        ::skipSettings::
                    end
                end
            end

            --Create Click Region
            local region = {}
            region["Position"] = Vector.new(cPosX, cPosY, 0)
            region["Size"] = Vector.new(cSizeX, cSizeY, 0)
            region["Parent"] = window[i]["Name"]
            region["ParentType"] = parentTypes.category

            table.insert(clickRegions, region)
            ::skipRender::
    end

    --Calculate needed frames to finish the animation and set time for when next frame should be rendered
    if IGlobalVars.realtime > nextAnim then
        nextAnim = IGlobalVars.realtime + 1 / FPS
        percentNeededIn = animationTimeIn * FPS
    end

    for i = 1, #clickRegions do
        if menuOpen then
            --Render.Rect(clickRegions[i]["Position"].x, clickRegions[i]["Position"].y, clickRegions[i]["Position"].x + clickRegions[i]["Size"].x, clickRegions[i]["Position"].y + clickRegions[i]["Size"].y, Color.new(255,0,0,255), 0, 1)
        end
    end

    --Handle Click
    if InputSys.IsKeyPress(1) and menuOpen then
        local cursorPos = InputSys.GetCursorPos()
        activeTextInput = {}
        local notCheckboxClicked = true

        for i = 1, #clickRegions do
            if cursorPos.x >= clickRegions[i]["Position"].x and cursorPos.x <= clickRegions[i]["Position"].x + clickRegions[i]["Size"].x then
                if cursorPos.y >= clickRegions[i]["Position"].y and cursorPos.y <= clickRegions[i]["Position"].y + clickRegions[i]["Size"].y then
                    if clickRegions[i]["ParentType"] == parentTypes.category then --Parent is category
                        loadedCategory = FindCategory(clickRegions[i]["Parent"])
                        goto finishedClick
                    end

                    if clickRegions[i]["ParentType"] == parentTypes.checkbox then --Parent is checkbox
                        local varName = clickRegions[i]["Parent"]
                        local data = Menu.GetBool(varName)
                        if data then Menu.SetBool(varName, false) else Menu.SetBool(varName, true) end
                        goto finishedClick
                    end

                    if clickRegions[i]["ParentType"] == parentTypes.sliderInt then --Parent is Slider Int
                        lastInteractedSlider = clickRegions[i]
                        goto finishedClick
                    end

                    if clickRegions[i]["ParentType"] == parentTypes.inputText then --Parent is Textbox
                        activeTextInput = clickRegions[i]
                        goto finishedClick
                    end

                    if clickRegions[i]["ParentType"] == parentTypes.dropdown then --Parent is Dropdown
                        if loadedCategory["Sections"][clickRegions[i]["Parent"]["Section"]]["Settings"][clickRegions[i]["Parent"]["ID"]]["Active"] then 
                            loadedCategory["Sections"][clickRegions[i]["Parent"]["Section"]]["Settings"][clickRegions[i]["Parent"]["ID"]]["Active"] = false
                        else
                            loadedCategory["Sections"][clickRegions[i]["Parent"]["Section"]]["Settings"][clickRegions[i]["Parent"]["ID"]]["Active"] = true 
                        end
                        activeDropdown = clickRegions[i]["Parent"]["VariableName"]
                        goto finishedClick
                    end

                    if clickRegions[i]["ParentType"] == parentTypes.dropdownChild then --Parent is Dropdown Child
                        loadedCategory["Sections"][clickRegions[i]["Parent"]["Section"]]["Settings"][clickRegions[i]["Parent"]["ID"]]["Active"] = false
                        loadedCategory["Sections"][clickRegions[i]["Parent"]["Section"]]["Settings"][clickRegions[i]["Parent"]["ID"]]["Current"] = clickRegions[i]["ItemID"]
                        notCheckboxClicked = false
                        goto finishedClick
                    end

                    if clickRegions[i]["ParentType"] == parentTypes.keybind then --Parent is Keybind
                        activeKeybind = clickRegions[i]["Parent"]
                        canCapture = false
                        goto finishedClick
                    end
                end
            end
        end
        ::finishedClick::
    end

    if activeKeybind ~= "" then
        local keybind = KeyBind()
        if keybind ~= false and keybind["Key"] ~= "" and keybind["Key"] ~= "unknown" and canCapture then
            if keybind["Key"] == "escape" then Menu.SetInt(activeKeybind, 0) else Menu.SetInt(activeKeybind, keybind["ID"]-1) end
            activeKeybind = ""
        end
    end

    --Dragging System
    local cursor = InputSys.GetCursorPos()
    local canDrag = false

    if not InputSys.IsKeyDown(1) then 
        Invalidated = false 
        lastInteractedSlider = {}
        canCapture = true
    else

        if Tablelength(lastInteractedSlider) ~= 0 then
            local pos = lastInteractedSlider["Position"]
            local size = lastInteractedSlider["Size"]

            local min = lastInteractedSlider["Parent"]["Min"]
            local max = lastInteractedSlider["Parent"]["Max"]

            local points = max - min
            local distBetween = size.x / points

            local point = min

            for i = 1, points do
                if cursor.x > pos.x + (distBetween * i) then point = i end
            end

            Menu.SetInt(lastInteractedSlider["Parent"]["VariableName"], min + point)
        end
    end

    if Tablelength(activeTextInput) ~= 0 then
        local pressed = KeyPress()

        if InputSys.IsKeyPress(8) then Menu.SetString(activeTextInput["Parent"]["VariableName"], string.sub(Menu.GetString(activeTextInput["Parent"]["VariableName"]), 1, -2)) end
        if InputSys.IsKeyPress(13) then activeTextInput = {} end
        if InputSys.IsKeyPress(32) then Menu.SetString(activeTextInput["Parent"]["VariableName"], Menu.GetString(activeTextInput["Parent"]["VariableName"]) .. " ") end
        if pressed["Key"] ~= "" then Menu.SetString(activeTextInput["Parent"]["VariableName"], Menu.GetString(activeTextInput["Parent"]["VariableName"]) .. pressed["Key"]) end
    end

    if mouseDown ~= 0 and mouseDown <= IGlobalVars.realtime - 0.1 then canDrag = true end
    if Invalidated then canDrag = false end
    if InputSys.IsKeyDown(1) and not oldMouse then mouseDown = IGlobalVars.realtime end
    if not InputSys.IsKeyDown(1) and oldMouse then mouseDown = 0 end

    for i = 1, #clickRegions do
        if cursor.x >= clickRegions[i]["Position"].x and cursor.x <= clickRegions[i]["Position"].x + clickRegions[i]["Size"].x and menuOpen then
            if cursor.y >= clickRegions[i]["Position"].y and cursor.y <= clickRegions[i]["Position"].y + clickRegions[i]["Size"].y then
                canDrag = false
                Invalidated = true
            end
        end
    end

    --Check if box is able to be dragged
    if cursor.x >= posX and cursor.x <= posX + sizeX and menuOpen then
        if cursor.y >= posY and cursor.y <= posY + sizeY-359 then
            if canDrag then
                Dragging = true
            else
                Dragging = false
            end
        else
            if InputSys.IsKeyDown(0) or not OldDragging then Dragging = false end
        end
    else
        if InputSys.IsKeyDown(0) or not OldDragging then Dragging = false end
    end

    Paint()

    --Register old values for next execution
    oldEnable = Menu.GetBool("mwMenu")
    oldMouse = InputSys.IsKeyDown(1)
end)

Hack.RegisterCallback("FrameStageNotify", function (stage)

    if stage == 5 then 
        PreserveKillfeed(roundStart)
        if roundStart then roundStart = false end
        return 
    end

    if Dragging then
        local cursor = InputSys.GetCursorPos()

        if not OldDragging then
            DraggingOffset = Vector.new(settings["position"].x - cursor.x, settings["position"].y - cursor.y, 0)
        end

        settings["position"].x = Clamp(cursor.x + DraggingOffset.x, 0, Globals.ScreenWidth() - sizeX)
        settings["position"].y = Clamp(cursor.y + DraggingOffset.y, 0, Globals.ScreenHeight() - sizeY)
        settings["position"].x = cursor.x + DraggingOffset.x
        settings["position"].y = cursor.y + DraggingOffset.y
    else
        DraggingOffset = Vector.new(0, 0, 0)
    end

    OldDragging = Dragging
end)



function SetupMenu()
    local aimbotCategory = {}
    local visualsCategory = {}
    local miscCategory = {}
    local skinsCategory = {}
    local settingsCategory = {}
    local movementRecCategory = {}

    --Aimbot
    local aimbotSection = {}
    local aimbotSection2 = {}
    local aimbotSection3 = {}
    local aimOne = {}

    aimbotCategory["Name"] = "Aimbot"
    aimbotCategory["useImg"] = false
    aimbotCategory["Enabled"] = true
	
    AddText(aimOne, "This is text")
    AddCheckbox(aimOne, "", "Checkbox", "cCheckboxTest", false, "")
    AddCheckbox(aimOne, "", "Checkbox 2", "cCheckboxTest2", false, "")
    AddTextbox(aimOne, "", "Textbox", "cTextboxTest")
    AddSliderInt(aimOne, "", "Slider Int", 0, 10, "cSlideIntTest")
    AddDropdown(aimOne, "", "Dropdown", {"Test1", "Test2", "Test3"}, 1, "cDropdownTest")
    AddCheckbox(aimOne, "", "Checkbox 3", "cCheckboxTest3", true, "cKeybindTest")
	
    aimbotSection["Name"] = "Test 1"
    aimbotSection["Settings"] = aimOne
    aimbotSection["useSeperator"] = true
    aimbotSection["ScrollOffset"] = 0
    aimbotSection["Inline"] = false
    aimbotSection2["Name"] = "Test 2"
    aimbotSection2["Settings"] = aimOne
    aimbotSection2["useSeperator"] = true
    aimbotSection2["ScrollOffset"] = 0
    aimbotSection2["Inline"] = true
    aimbotSection3["Name"] = "Test 3"
    aimbotSection3["Settings"] = aimOne
    aimbotSection3["useSeperator"] = true
    aimbotSection3["ScrollOffset"] = 0
    aimbotSection3["Inline"] = true
    aimbotCategory["Sections"] = {aimbotSection, aimbotSection2, aimbotSection3}

    --Visuals
    visualsCategory["Name"] = "Visuals"
    visualsCategory["Sections"] = {}
    visualsCategory["useImg"] = false
    visualsCategory["Enabled"] = true

    --Misc
    local miscSection = {}
    local sectionOneSettings = {}
	
    AddCheckbox(sectionOneSettings, "", "Bunny hop", "mwBHop", false, "")
    --AddCheckbox(sectionOneSettings, "", "Autostrafe", "mwAS", false, "")
    AddCheckbox(sectionOneSettings, "", "Infinite Duck", "mwFastDuck", false, "")
    AddCheckbox(sectionOneSettings, "", "Jump stats", "mwJumpstats", false, "")
    AddCheckbox(sectionOneSettings, "", "Blockbot", "mwBlockbot", true, "mwBlockbotKey")
    AddCheckbox(sectionOneSettings, "", "Fast walk", "mwFastWalk", true, "mwFastWalkKey")
    AddCheckbox(sectionOneSettings, "", "Edge jump", "mwEJ", true, "mwEJKey")
    AddCheckbox(sectionOneSettings, "", "Long jump", "mwLJ", true, "mwLJKey")
    AddCheckbox(sectionOneSettings, "", "LJ on ej", "mwLJEJ", true, "mwLJEJKey")
    AddCheckbox(sectionOneSettings, "", "Jump bug", "mwJB", true, "mwJBKey")
    AddCheckbox(sectionOneSettings, "mwJB", "Jump bug indicator", "mwJBIndicator", false, "")
    AddCheckbox(sectionOneSettings, "", "Edge bug", "mwEB", true, "mwEBKey")
    AddCheckbox(sectionOneSettings, "mwEB", "Edge bug indicator", "mwEBIndicator", false, "")
    AddTextbox(sectionOneSettings, "mwEB", "Edge bug sound", "mwEBSound")
    AddCheckbox(sectionOneSettings, "", "Velocity indicator", "mwVelocityIndicator", false, "")
    AddCheckbox(sectionOneSettings, "mwVelocityIndicator", "Takeoff", "mwVelocityTakeoff", false, "")
    AddCheckbox(sectionOneSettings, "", "Velocity graph", "mwVelocity", false, "")
    AddSliderInt(sectionOneSettings, "mwVelocity", "Graph size", 0, 1000, "mwGraphSize")
    AddSliderInt(sectionOneSettings, "mwVelocity", "Graph scale", 0, 150, "mwGraphScale")

    local miscSection2 = {}
    local sectionTwoSettings = {}
	
    AddCheckbox(sectionTwoSettings, "", "Auto pistol", "mwAutoPistol", false, "")
    AddSliderInt(sectionTwoSettings, "mwAutoPistol", "Auto pistol delay", 0, 1000, "mwAutoPistolDelay")
    AddCheckbox(sectionTwoSettings, "", "Reveal ranks", "mwRevealRanks", false, "")
    AddCheckbox(sectionTwoSettings, "", "Auto accept", "mwAutoAccept", false, "")
    AddCheckbox(sectionTwoSettings, "", "Clantag", "mwClantag", false, "")
    AddDropdown(sectionTwoSettings, "mwClantag", "Options", {"Static", "Normal", "Backwards"}, 1, "mwClantagOptions")
    AddCheckbox(sectionTwoSettings, "", "Watermark", "mwWatermark", false, "")
    AddCheckbox(sectionTwoSettings, "", "Name spam", "mwNameSpam", false, "")
    AddCheckbox(sectionTwoSettings, "", "Team damage log", "mwTeamDamageLog", false, "")
    AddCheckbox(sectionTwoSettings, "", "View vote", "mwViewVote", false, "")
    AddCheckbox(sectionTwoSettings, "", "Preserve Killfeed", "mwPreserveKillfeed", false, "")
    AddCheckbox(sectionTwoSettings, "", "Killsay", "mwKillSay", false, "")
    AddDropdown(sectionTwoSettings, "", "Server selector", {"Don't force", "Probably doesn't", "even work", "because MW", "is shit"}, 1, "mwServerSelector")
    AddDropdown(sectionTwoSettings, "", "Hitsound", {"None", "Cash grab", "Arena switch press", "Custom"}, 1, "mwHitsound")
    AddTextbox(sectionTwoSettings, "mwHitsound[4]", "Custom hitsound", "mwCustomHitSound")

    miscSection["Settings"] = sectionOneSettings
    miscSection["useSeperator"] = true
    miscSection["Name"] = "Movement"
    miscSection["ScrollOffset"] = 0
	
    miscSection2["Settings"] = sectionTwoSettings
    miscSection2["useSeperator"] = true
    miscSection2["Name"] = "Other"
    miscSection2["ScrollOffset"] = 0

    miscCategory["Name"] = "Misc"
    miscCategory["Sections"] = {miscSection, miscSection2}
    miscCategory["useImg"] = false
    miscCategory["Enabled"] = true

    --Skins
    skinsCategory["Name"] = "Skins"
    skinsCategory["Sections"] = {}
    skinsCategory["useImg"] = false
    skinsCategory["Enabled"] = true

    --Settings
    local sSectionOne = {}
    local sSectionOneSettings = {}
    local sSectionTwo = {}
	
    AddCheckbox(sSectionOneSettings, "", "Replace interium", "mwReplaceInt", false, "")
    AddCheckbox(sSectionOneSettings, "", "Menu key", "mwMenu", true, "mwMenuKey")
	
    sSectionOne["Name"] = "Main Settings"
    sSectionOne["Settings"] = sSectionOneSettings
    sSectionOne["useSeperator"] = true
    sSectionOne["ScrollOffset"] = 0
    sSectionOne["Inline"] = false
    sSectionTwo["Settings"] = {}
    sSectionTwo["useSeperator"] = false
    sSectionTwo["ScrollOffset"] = 0
    sSectionTwo["Inline"] = false

    settingsCategory["Name"] = "Settings"
    settingsCategory["Sections"] = {sSectionOne, sSectionTwo}
    settingsCategory["useImg"] = false
    settingsCategory["Enabled"] = true

    --Movement Recorder
    local recS1 = {}
    local recS1S = {}
    local recS2 = {}
    local recS2S = {}
    AddCheckbox(recS1S, "", "Line", "cEnableMRecorderLine", false, "")
    AddCheckbox(recS1S, "", "Rainbow Line", "cRainbowLine", false, "")
    AddCheckbox(recS1S, "", "Short line", "cEnableMRecorderMagicLine", false, "")
    AddCheckbox(recS1S, "", "Progress bar", "cEnableMRecorderTimer", false, "")
    AddCheckbox(recS1S, "", "Aimspot", "cEnableAimspot", false, "")
    AddCheckbox(recS1S, "", "Indicators", "cEnableMRecorderIndicators", false, "")
    AddCheckbox(recS1S, "", "Notifications", "cEnableMRecorderNotifs", false, "")
    AddTextbox(recS1S, "", "File name", "cMRecorderFName")
    AddCheckbox(recS1S, "", "Load file", "cMRecorderLoad", false, "")
    AddCheckbox(recS1S, "", "Save file", "cMRecorderSave", false, "")
    --AddCheckbox(recS1S, "Optimize Line", "", false, "")
    AddCheckbox(recS2S, "", "Record", "", true, "cToggleMRecorder")
    AddCheckbox(recS2S, "", "Playback", "", true, "cMRecorderPlayback")
    AddCheckbox(recS2S, "", "Legit mode", "cEnableLegitAlign", false, "")
    AddCheckbox(recS2S, "", "Multidirectional aligning", "cEnableMDirAlign", false, "")
    AddCheckbox(recS2S, "", "Show all recordings", "cAllRecordings", false, "")
    AddCheckbox(recS2S, "", "Recording override", "cEnableMRecorderOverride", false, "")
    AddCheckbox(recS2S, "", "Disable autocancel", "cACancel", false, "")
    AddCheckbox(recS2S, "", "Freelook", "mwRecFreelook", true, "mwRecFreelookKey")
    AddCheckbox(recS2S, "", "Server freelook", "cEnableMRecorderUnlockGlobal", false, "")
    AddCheckbox(recS2S, "", "Proximity loading", "cEnableProximityLoading", false, "")
    AddSliderInt(recS2S, "", "Radius", 1, 200, "cMRecorderProximity")
    AddCheckbox(recS2S, "", "Replay buffer", "cMRecorderReplayBuffer", false, "")
    AddSliderInt(recS2S, "", "Replay time", 1, 120, "cMRecorderBufferTime")

    recS1["Settings"] = recS1S
    recS1["useSeperator"] = true
    recS1["Name"] = "Visuals"
    recS1["ScrollOffset"] = 0
    recS1["Inline"] = false
	
    recS2["Settings"] = recS2S
    recS2["useSeperator"] = true
    recS2["Name"] = "Features"
    recS2["ScrollOffset"] = 0
    recS2["Inline"] = false
    movementRecCategory["Name"] = "Movment Recorder"
    movementRecCategory["Sections"] = {recS1, recS2}
    movementRecCategory["useImg"] = false
    movementRecCategory["Enabled"] = false
    table.insert(window, aimbotCategory)
    table.insert(window, visualsCategory)
    table.insert(window, miscCategory)
    table.insert(window, skinsCategory)    
    table.insert(window, settingsCategory)
    table.insert(window, movementRecCategory)
end

function GetKey(ID) 
    local keys = {
        "Unknown",
        "M1",
        "M2",
        "CANCEL",
        "M3",
        "M4",
        "M5",
        "Unknown",
        "BACK",
        "TAB",
        "Unknown",
        "Unknown",
        "CLEAR",
        "RETURN",
        "Unknown",
        "Unknown",
        "SHIFT",
        "CTRL",
        "ALT",
        "PAUSE",
        "CAPITAL",
        "KANA",
        "Unknown",
        "JUNJA",
        "FINAL",
        "KANJI",
        "Unknown",
        "ESCAPE",
        "CONVERT",
        "NONCONVERT",
        "ACCEPT",
        "MODECHANGE",
        "SPACE",
        "PG UP",
        "PG DOWN",
        "END",
        "HOME",
        "LEFT",
        "UP",
        "RIGHT",
        "DOWN",
        "SELECT",
        "PRINT",
        "EXECUTE",
        "SNAPSHOT",
        "INSERT",
        "DELETE",
        "HELP",
        "0",
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z",
        "LWIN",
        "RWIN",
        "APPS",
        "Unknown",
        "SLEEP",
        "NUMPAD0",
        "NUMPAD1",
        "NUMPAD2",
        "NUMPAD3",
        "NUMPAD4",
        "NUMPAD5",
        "NUMPAD6",
        "NUMPAD7",
        "NUMPAD8",
        "NUMPAD9",
        "MULTIPLY",
        "ADD",
        "SEPARATOR",
        "SUBTRACT",
        "DECIMAL",
        "DIVIDE",
        "F1",
        "F2",
        "F3",
        "F4",
        "F5",
        "F6",
        "F7",
        "F8",
        "F9",
        "F10",
        "F11",
        "F12",
        "F13",
        "F14",
        "F15",
        "F16",
        "F17",
        "F18",
        "F19",
        "F20",
        "F21",
        "F22",
        "F23",
        "F24",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "NUMLOCK",
        "SCROLL",
        "OEM_NEC_EQUAL",
        "OEM_FJ_MASSHOU",
        "OEM_FJ_TOUROKU",
        "OEM_FJ_LOYA",
        "OEM_FJ_ROYA",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "LSHIFT",
        "RSHIFT",
        "LCONTROL",
        "RCONTROL",
        "LMENU",
        "RMENU",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        ";",
        "=",
        ",",
        "-",
        ".",
        "/",
        "`",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "Unknown",
        "[",
        "\\",
        "]",
        "'"
    }
    return keys[ID]
end

function KeyPress()
    for i = 1, 255 do
        if InputSys.IsKeyPress(i-2) and i >= 65 and i <= 90 then
            local pressedKey = GetKey(i-1)
            local SHIFT = InputSys.IsKeyDown(16)
            if not SHIFT then pressedKey = pressedKey:lower() else pressedKey = pressedKey:upper() end
            if pressedKey ~= "Unknown" and pressedKey ~= "SHIFT" and not pressedKey:match("CONTROL") and not pressedKey:match("ALT") then 
                local obj = {}
                obj["Key"] = pressedKey
                obj["ID"] = i-1
                return obj
            end
        end
    end
    return false
end

function KeyBind()
    for i = 1, 255 do
        if InputSys.IsKeyPress(i-2) then
            local pressedKey = GetKey(i-1)
            local SHIFT = InputSys.IsKeyDown(16)
            if not SHIFT then pressedKey = pressedKey:lower() else pressedKey = pressedKey:upper() end
            if pressedKey ~= "Unknown" and pressedKey ~= "SHIFT" and not pressedKey:match("CONTROL") and not pressedKey:match("ALT") then 
                local obj = {}
                obj["Key"] = pressedKey
                obj["ID"] = i-1
                return obj
            end
        end
    end
    return false
end

Setup()

function Paint()
    local LJonEJEnabled = Menu.GetBool("mwLJEJ") and InputSys.IsKeyDown(Menu.GetInt("mwLJEJKey"))

    --Misc Left Section
    if GetBool(Vars.misc_bhop) ~= Menu.GetBool("mwBHop") then SetBool(Vars.misc_bhop, Menu.GetBool("mwBHop")) end
    if GetBool(Vars.misc_edgejump) ~= Menu.GetBool("mwEJ") and InputSys.IsKeyDown(Menu.GetInt("mwEJKey")) and not LJonEJEnabled then 
        SetBool(Vars.misc_edgejump, Menu.GetBool("mwEJ")) 
        SetInt(Vars.misc_edgejump_enabletype, 0)
    elseif not InputSys.IsKeyDown(Menu.GetInt("mwEJKey")) then
        SetBool(Vars.misc_edgejump, false)
    end
    if GetBool(Vars.misc_longjump) ~= Menu.GetBool("mwLJ") and InputSys.IsKeyDown(Menu.GetInt("mwLJKey")) and not LJonEJEnabled then 
        SetBool(Vars.misc_longjump, Menu.GetBool("mwLJ")) 
        SetBool(Vars.misc_longjump_always, Menu.GetBool("mwLJ"))
        SetBool(Vars.Vars.misc_longjump_ej, false)
    elseif not InputSys.IsKeyDown(Menu.GetInt("mwLJKey")) then
        SetBool(Vars.misc_longjump, false) 
    end
    if GetBool(Vars.misc_jumpbug) ~= Menu.GetBool("mwJB") or GetInt(Vars.misc_jumpbug_key) ~= Menu.GetInt("mwJBKey") then 
        SetBool(Vars.misc_jumpbug, Menu.GetBool("mwJB")) 
        if true then
            SetInt(Vars.misc_jumpbug_type, 0)
            SetInt(Vars.misc_jumpbug_key, Menu.GetInt("mwJBKey"))
        end
    end
    if GetBool(Vars.misc_edgebug) ~= Menu.GetBool("mwEB") or GetInt(Vars.misc_edgebug_key) ~= Menu.GetInt("mwEBKey") then 
        SetBool(Vars.misc_edgebug, Menu.GetBool("mwEB")) 
        SetInt(Vars.misc_edgebug_type, 1)
        SetInt(Vars.misc_edgebug_key, Menu.GetInt("mwEBKey"))
    end
    if Menu.GetBool("mwLJEJ") and InputSys.IsKeyDown(Menu.GetInt("mwLJEJKey")) then
        SetBool(Vars.misc_longjump, true) 
        SetBool(Vars.misc_longjump_always, false)
        SetBool(Vars.misc_longjump_ej, true)
        SetBool(Vars.misc_edgejump, true) 
        SetInt(Vars.misc_edgejump_enabletype, 0)
    end

    SetBool(Vars.misc_BlockBot, Menu.GetBool("mwBlockbot"))
    SetInt(Vars.misc_BlockBotKey, Menu.GetInt("mwBlockbotKey"))

    --Misc Right Section
    if GetBool(Vars.misc_showrank) ~= Menu.GetBool("mwRevealRanks") then SetBool(Vars.misc_showrank, Menu.GetBool("mwRevealRanks")) end
    if GetBool(Vars.misc_autoaccept) ~= Menu.GetBool("mwAutoAccept") then SetBool(Vars.misc_autoaccept, Menu.GetBool("mwAutoAccept")) end
    if GetBool(Vars.misc_NameStealer) ~= Menu.GetBool("mwNameSpam") then SetBool(Vars.misc_NameStealer, Menu.GetBool("mwNameSpam")) end
    --if GetBool(Vars.misc_bhop) ~= Menu.GetBool("mwViewVote") then SetBool(Vars.misc_bhop, Menu.GetBool("mwViewVote")) end
    --if GetBool(Vars.misc_bhop) ~= Menu.GetBool("mwPreserveKillfeed") then SetBool(Vars.misc_bhop, Menu.GetBool("mwPreserveKillfeed")) end
end

Hack.RegisterCallback("CreateMove", function (cmd, send)
    if Menu.GetBool("mwFastDuck") then cmd.buttons = SetBit(cmd.buttons, 22) end
    Autopistol(cmd)
    Fastwalk(cmd)
    DetectEdgebug()
    GraphCMD()

    FixMove(cmd)
end)

Hack.RegisterCallback("FireEventClientSideThink", function (Event)
    Hitsound(Event)
    EventTeamDmg(Event)
    Killsay(Event)

    --Other
    if Event:GetName() == "round_start" then roundStart = true end
end)

function Draw()
    Clantag()
    Watermark()
    Indicators()
    PaintTeamDmg()
    Graph()
end

function Clantag()
    if Utils.IsLocal() and Utils.IsInGame() then
        if a1 < GetTickCount() then     
            a2 = a2 + 1
            if (a2 > #clantag) then
                a2 = 0
            end
            if Menu.GetBool("mwClantag") then 
                if Menu.GetInt("mwClantagOptions") == 1 then
                    Utils.SetClantag(clantagStatic)
                elseif Menu.GetInt("mwClantagOptions") == 2 then
                    Utils.SetClantag(clantag[a2]) 
                elseif Menu.GetInt("mwClantagOptions") == 3 then
                    Utils.SetClantag(clantag[#clantag - a2]) 
                end
            end
            a1 = GetTickCount() + delay
        end  
    end
end


function Watermark()
    --Generate watermark days
    local days = tonumber(Hack.GetSubDays())
    local dateType = ""
    local dLeft = ""

    if days <= 1 then 
        dateType = " day" 
        dLeft = math.floor(days/1) .. dateType
    end    
    if days > 1 then 
        dateType = " days" 
        dLeft = math.floor(days/1) .. dateType
    end
    if days >= 30 then 
        dateType = " month"
        dLeft = math.floor(days/30) .. dateType
    end
    if days >= 60 then 
        dateType = " months" 
        dLeft = math.floor(days/30) .. dateType
    end

    if days >= 365 then 
        dateType = " year" 
        dLeft = math.floor(days/365) .. dateType
    end

    if days >= 728 then 
        dateType = " years"
        dLeft = math.floor(days/365) .. dateType
    end

    --Generate watermark text
    local watermark = "millionware v2 | " .. Hack.GetUserName() .. " | " .. dLeft
    local watermarkSize = Render.CalcTextSize(watermark, 13, "mwFont")

    --Vars
    local clr = Color.new(settings["accentClr"].r,settings["accentClr"].g,settings["accentClr"].b, 255)
    local clrBody = Color.new(0, 0, 0,40.5)
    local offset = 4

    --Debug purposes
    local yOffset = 0

    if Menu.GetBool("mwWatermark") then
        Render.RectFilled(6, 4 + yOffset, (offset*2) + watermarkSize.x + 6, 6 + yOffset, clr) --Head
        Render.RectFilled(6, 6 + yOffset, (offset*2) + watermarkSize.x + 6, 21 + yOffset, clrBody)
        Render.Text(watermark, 10, 6 + yOffset, 13, Color.new(255,255,255,255), false,false,"mwFont")
    end
end

function Indicators()
    if Menu.GetBool("mwEBIndicator") and InputSys.IsKeyDown(Menu.GetInt("mwEBKey")) then
        Render.Text_1("eb", Globals.ScreenWidth() / 2, Globals.ScreenHeight() - 50, 26, Color.new(255,255,255,255), true, true)
    end
    if Menu.GetBool("mwJBIndicator") and InputSys.IsKeyDown(Menu.GetInt("mwJBKey")) then
        Render.Text_1("jb", Globals.ScreenWidth() / 2, Globals.ScreenHeight() - 83, 26, Color.new(255,255,255,255), true, true)
    end
end

function DetectEdgebug()
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if not pLocal or Menu.GetString("mwEBSound") == "" then return end

    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
    
    local Flags = pLocal:GetPropInt(fFlags_Offset)
    
    local pX = math.abs(vVelocity.x)
    local pY = math.abs(vVelocity.y)

    local horizontal = pX + pY


    if pLocal:GetMoveType() == 9 then validateEB = false end
    if IsBit(Flags, ON_GROUND) == true then validateEB = true end

    --EB
    if pendingEB and pLocal:GetMoveType() ~= 8 and pLocal:GetMoveType() ~= 9 then
        PlaySound(sounds .. Menu.GetString("mwEBSound") .. ".wav")
        pendingEB = false
        validateEB = false
        cooldown = IGlobalVars.realtime + 0.3
    elseif pendingEB then pendingEB = false end

    --Detect EB
    if(IsBit(Flags, ON_GROUND) == false and Utils.IsLocalAlive() and 
    pLocal:GetMoveType() ~= 8 and pLocal:GetMoveType() ~= 9 and 
    validateEB and 
    InputSys.IsKeyDown(Menu.GetInt("mwEBKey"))) then
        if(vVelocity.z < 1 and oldVertical < vVelocity.z) then
            if(horizontal > 10) then
                if vVelocity.x ~= 0 or vVelocity.y ~= 0 then
                    if IGlobalVars.realtime > cooldown then
                        pendingEB = true
                    end
                end
            end
        end
    end
    
    oldVertical = vVelocity.z
end


function Hitsound(Event)
    if Menu.GetInt("mwHitsound") == 1 then return end
    if Event:GetName() == "player_hurt" then
        local sound = Menu.GetString("mwCustomHitSound")
        local attacker = IEngine.GetPlayerForUserIDEvent:GetInt("attacker", 0)

        if attacker == IEngine.GetLocalPlayer() then
            Print(Menu.GetInt("mwHitsound"))
            if Menu.GetInt("mwHitsound") == 2 then
                ISurface.PlaySound_("survival\\money_collect_04.wav")
            elseif Menu.GetInt("mwHitsound") == 3 then
                ISurface.PlaySound_("buttons\\arena_switch_press_02.wav")
            elseif Menu.GetInt("mwHitsound") == 4 and Menu.GetString("mwCustomHitSound") ~= "" then
                PlaySound(sounds .. sound .. ".wav")
            end
        end
    end
end

function Autopistol(cmd)
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if not pLocal or not Menu.GetBool("mwAutoPistol") then return end

    local wLocal = pLocal:GetActiveWeapon()
    if not wLocal then return end


    local wepInfo = wLocal:GetWeaponData()
    if not wepInfo then return end

    if not wLocal:IsReloading() then

        local name = wepInfo.consoleName
        if name == "weapon_usp_silencer" or name == "weapon_deagle" or name == "weapon_elite" or name == "weapon_fiveseven" or name == "weapon_glock" or name == "weapon_hkp2000" or name == "weapon_p250" or name == "weapon_tec9" or name == "weapon_cz75a" or name == "weapon_revolver" then
            if IGlobalVars.curtime > wLocal:GetPropFloat(nextPrimaryAttack_Offset) then
                if IsBit(cmd.buttons, 0) == true and switchPistol then switchPistol = false else
                    switchPistol = true
                    cmd.buttons = DelBit(cmd.buttons, 0)
                end
            end
        end
    end
end

function EventTeamDmg(Event)
    if (Event:GetName() == "player_death") then
        local IsLocalShot = IEngine.GetPlayerForUserID(Event:GetInt("attacker", 0)) == IEngine.GetLocalPlayer()
		if IsLocalShot then
		local Player = IEntityList.GetPlayer(IEngine.GetPlayerForUserID(Event:GetInt("userid", 0)))
			if (Player and Player:GetClassId() == 40 and Player:IsTeammate()) then 
			    iKlls = iKills + 1
			end
        end
	end 

	if (Event:GetName() == "player_hurt") then
		local attacker_EntInd = IEngine.GetPlayerForUserID(Event:GetInt("attacker", 0))
		local userid_EntInd = IEngine.GetPlayerForUserID(Event:GetInt("userid", 0))

        local IsLocalShot = attacker_EntInd == IEngine.GetLocalPlayer()
	    local IsLocalIsTarget = userid_EntInd == IEngine.GetLocalPlayer() --or attacker_EntInd == userid_EntInd
		if (IsLocalShot and not IsLocalIsTarget) then
			local Player = IEntityList.GetPlayer(userid_EntInd)
			if (Player and Player:GetClassId() == 40 and Player:IsTeammate()) then 
				local Health = Player:GetPropInt(iHealth_Offset)
				if (Health >= Event:GetInt("dmg_health", 0)) then
					iDamage = iDamage + Event:GetInt("dmg_health", 0)
				else
			        iDamage = iDamage + Health
		        end
			end
        end
	end 
end

function PaintTeamDmg()
    if Menu.GetBool("mwTeamDamageLog") then
        ISurface.DrawText(ISurfaceFont, 25, 55, Color.new(255,255,255,255), 0, tostring(iDamage) .. " / 300")
        ISurface.DrawText(ISurfaceFont, 25, 73, Color.new(255,255,255,255), 0, tostring(iKills) .. " / 3")
    end
end

function Killsay(Event)
    if (Event:GetName() == "player_death" and Menu.GetBool("mwKillSay")) then
		if IEngine.GetPlayerForUserID(Event:GetInt("attacker", 0)) == IEngine.GetLocalPlayer() then
			local Player = IEntityList.GetPlayer(IEngine.GetPlayerForUserID(Event:GetInt("userid", 0)))
		if Player and Player:GetClassId() == 40 then 
				Print("\nsay god i wish i had millionware")
			end
        end
    end 
end

function Fastwalk(cmd)
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if not pLocal then return end

    local vel = pLocal:GetPropVector(vVelocity_Offset)
    local Speed = math.abs(Round(math.sqrt((vel.x * vel.x) + (vel.y * vel.y))))

    local fs = ICvar.FindVar("cl_forwardspeed")
    local ss = ICvar.FindVar("cl_sidespeed")
    local bs = ICvar.FindVar("cl_backspeed")

    local ForwardSpeed = fs:GetInt()
    local BackSpeed = bs:GetInt()
    local SideSpeed = ss:GetInt()

    if InputSys.IsKeyDown(Menu.GetInt("mwFastWalkKey")) and Menu.GetBool("mwFastWalk") then
        if Speed <= 0 then 
            ForwardSpeed = 134
            BackSpeed = 134
            SideSpeed = 134
        end   
        if Speed < 133 then
            ForwardSpeed = ForwardSpeed + 1
            BackSpeed = BackSpeed + 1
            SideSpeed = SideSpeed + 1
        end
        if Speed > 133 and Speed < 134 then
            ForwardSpeed = ForwardSpeed - 1
            BackSpeed = BackSpeed - 1
            SideSpeed = SideSpeed - 1
        end
        if Speed > 134 and Speed < 136 then
            ForwardSpeed = ForwardSpeed - 4
            BackSpeed = BackSpeed - 4
            SideSpeed = SideSpeed - 4
        end
        if Speed > 136 and Speed < 145 then
            ForwardSpeed = ForwardSpeed - 7
            BackSpeed = BackSpeed - 7
            SideSpeed = SideSpeed - 7
        end
        if Speed > 145 and Speed < 170 then
            ForwardSpeed = ForwardSpeed - 6
            BackSpeed = BackSpeed - 6
            SideSpeed = SideSpeed - 6
        end
        if Speed >= 170 then 
            ForwardSpeed = ForwardSpeed - 10
            BackSpeed = BackSpeed - 10
            SideSpeed = SideSpeed - 10
        end
        if InputSys.IsKeyDown(16) then cmd.buttons = DelBit(cmd.buttons, 17) end
    else
        ForwardSpeed = 450
        BackSpeed = 450
        SideSpeed = 450
    end

    fs:SetInt(ForwardSpeed)
    ss:SetInt(SideSpeed)
    bs:SetInt(BackSpeed)
end

function FixMove(cmd)
    if not Menu.GetBool("mwMenu") then 
        local didTap = false
        if not InputSys.IsKeyDown(87) and cmd.forwardmove > 0 then 
            InputSys.SendKey(17) 
            didTap = true
        end --W
        if not InputSys.IsKeyDown(65) and cmd.sidemove < 0 then 
            InputSys.SendKey(30) 
            didTap = true
        end --A
        if not InputSys.IsKeyDown(83) and cmd.forwardmove < 0 then 
            InputSys.SendKey(31) 
            didTap = true
        end --S
        if not InputSys.IsKeyDown(68) and cmd.sidemove > 0 then 
            InputSys.SendKey(32) 
            didTap = true
        end --D
        if didTap then
            cmd.forwardmove = 0
            cmd.sidemove = 0
        end
        return 
    end

    cmd.forwardmove = 0
    cmd.sidemove = 0
end

--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING
--WELCOME TO GRAPH HELL, PLEASE LEAVE BEFORE YOUR EYES WILL HURT OF TOO MUCH WORK AND PASTING

-- Ignore some Times
local VelocityTime = 0
local VelocityTimeToUpdate = 64

function Graph()
    if not Menu.GetBool("mwVelocity") then return end
    TextOffsetY = 0
    PosY = Globals.ScreenHeight() / 1.2

    VelocityrraySize = Menu.GetInt("mwGraphSize")
    SizeY = Menu.GetInt("mwGraphScale") * (3/150)

    if (not Utils.IsLocalAlive()) then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if (not pLocal) then 
        return
    end

    local Flags = pLocal:GetPropInt(fFlags_Offset)
    local fVelocity = math.floor(VecLenght2D(pLocal:GetPropVector(vVelocity_Offset)) + 0.5)
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
    local vOrigin = pLocal:GetPropVector(vOrigin_Offset)
    local iMoveType = pLocal:GetMoveType()
    local fStamina = pLocal:GetPropFloat(fStamina_Offset)

    BuildVelocityInfo(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    DrawGraph(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    DrawVelocity(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)

    -- Save
    if (GetTickCount() - VelocityTime > VelocityTimeToUpdate) then
        fVelocity_old = fVelocity
        VelocityTime = GetTickCount()
    end

    IsOnGroud_old = IsBit(Flags, ON_GROUND)
    vVelocity_old = vVelocity
end

function GraphCMD(cmd)
    if not Menu.GetBool("mwVelocity") then return end
    if (not Utils.IsLocalAlive()) then return end

    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer()) 
    if (not pLocal) then 
        return
    end
    local Flags = pLocal:GetPropInt(fFlags_Offset)
    local fVelocity = math.floor(VecLenght2D(pLocal:GetPropVector(vVelocity_Offset)) + 0.5)
    local vVelocity = pLocal:GetPropVector(vVelocity_Offset)
    local vOrigin = pLocal:GetPropVector(vOrigin_Offset)
    local iMoveType = pLocal:GetMoveType()
    local fStamina = pLocal:GetPropFloat(fStamina_Offset)

    -- Build New Graph
    for i = 2, VelocityrraySize * 2 do
        VelocityArray[i - 1] = VelocityArray[i]
        StaminaArray[i - 1] = StaminaArray[i]
        PlusOnGroundVelocityArray[i - 1] = PlusOnGroundVelocityArray[i]
        OnGroundVelocityArray[i - 1] = OnGroundVelocityArray[i] 
        IsJBArray[i - 1] = IsJBArray[i] 
    end
    VelocityArray[VelocityrraySize * 2] = fVelocity
    StaminaArray[VelocityrraySize * 2] = fStamina
    PlusOnGroundVelocityArray[VelocityrraySize * 2] = -999
    OnGroundVelocityArray[VelocityrraySize * 2] = -999
    IsJBArray[VelocityrraySize * 2] = -999
end

function BuildVelocityInfo(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    if (not IsCanMovement(iMoveType)) then return end

    -- Build Velocity
    if (IsBit(Flags, ON_GROUND)) then
        if (OnGroundTime == 0) then OnGroundTime = GetTickCount() end
    else
        if (OnGroundTime > 0 and GetTickCount() > (OnGroundTime + NotJumpingTimeMax)) then
            VelocityOnGround_old = 0
            VelocityOnGround = 0
    
            --LastUnits = 0
            --LastVert = 0
        end
        OnGroundTime = 0
    end

    -- Build Velocity
    if (IsOnGroud_old and not IsBit(Flags, ON_GROUND)) then -- Just Jump ?
        VelocityOnGround_old = VelocityOnGround
        VelocityOnGround = fVelocity

        if (VelocityOnGround ~= 0) then
            OnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround
        end
        if (VelocityOnGround_old ~= 0 and VelocityOnGround ~= 0) then
            PlusOnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround - VelocityOnGround_old
        end
    else -- JB ?
        if (vVelocity_old.z < 0 and vVelocity.z > 0) then
            IsJBArray[VelocityrraySize * 2] = 1
            IsJBTime = GetTickCount() + IsJBTimeMax

            VelocityOnGround_old = VelocityOnGround
            VelocityOnGround = fVelocity
        
            if (VelocityOnGround ~= 0) then
                OnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround
            end
            if (VelocityOnGround_old ~= 0 and VelocityOnGround ~= 0) then
                PlusOnGroundVelocityArray[VelocityrraySize * 2] = VelocityOnGround - VelocityOnGround_old
            end
        end
    end


    -- Save Units with with JB
    if (vVelocity_old.z < 0 and vVelocity.z > 0) then
        LastUnits = math.floor(Dist(vOriginOnGround, vOrigin) + 37 + 0.5)
        LastVert = math.floor((vOriginOnGround.z - vOrigin.z) * -1 + 3 + 0.5)
        vOriginOnGround = vOrigin
    end
    -- Save Units with Jumps
    if (not IsOnGroud_old and IsBit(Flags, ON_GROUND)) then
        LastUnits = math.floor(Dist(vOriginOnGround, vOrigin) + 37 + 0.5)
        LastVert = math.floor((vOriginOnGround.z - vOrigin.z) * -1 + 3 + 0.5)
    elseif (IsOnGroud_old and IsBit(Flags, ON_GROUND) or IsOnGroud_old and not IsBit(Flags, ON_GROUND)) then
        vOriginOnGround = vOrigin
    end

	if (LastUnits > 500) then
	    LastUnits = 0
        LastVert = 0
	end

    -- Delete OnGround Saves bc u r OnGround so long
    if (IsBit(Flags, ON_GROUND) and GetTickCount() > (OnGroundTime + OnGroundTimeMax)) then
        VelocityOnGround_old = 0
        VelocityOnGround = 0

        LastUnits = 0
        LastVert = 0
    end
end

function DrawVelocity(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    -- Render Velocity or Velocity with Old Velocity [TYPE 1]
    local Text = tostring(fVelocity)
    if (not Menu.GetBool("mwVelocityIndicator")) then 
        Text = ""
    end

    -- Build Speed Color
    local col = Color.new()
    if (fVelocity > fVelocity_old) then
        col = Color.new(25, 255, 100, 255)
    elseif (fVelocity < fVelocity_old) then
        col = Color.new(225, 100, 100, 255)
    else
        col = Color.new(255, 200, 100, 255)
    end 

    if Menu.GetBool("mwVelocityIndicator") and Menu.GetBool("mwVelocityTakeoff") and VelocityOnGround > 0 then 

        -- Build Velocity Color
        local col2 = Color.new()

        if (VelocityOnGround > VelocityOnGround_old) then
            col2 = Color.new(25, 255, 100, 255)
        elseif (VelocityOnGround < VelocityOnGround_old) then
            col2 = Color.new(225, 100, 100, 255)
        else
            col2 = Color.new(255, 200, 100, 255)
        end

        Render.Text_1(Text, Globals.ScreenWidth() / 2 - Render.CalcTextSize_1("(" .. VelocityOnGround .. ")", 24).x / 2, PosY + 10 + TextOffsetY, 24, col, true, true)
        Render.Text_1("(" .. VelocityOnGround .. ")", Globals.ScreenWidth() / 2 - Render.CalcTextSize_1("(" .. VelocityOnGround .. ")", 24).x / 2 + Render.CalcTextSize_1(Text, 24).x / 2 + 4, PosY + 10 + TextOffsetY, 24, col2, false, true)
    elseif Menu.GetBool("mwVelocityIndicator") then
        Render.Text_1(Text, Globals.ScreenWidth() / 2, PosY + 10 + TextOffsetY, 24, col, true, true)
    end
end

function DrawGraph(Flags, fVelocity, vVelocity, vOrigin, iMoveType, fStamina)
    if (not Menu.GetBool("mwVelocity")) then 
        return
    end

    -- Render Graph
    local NoRender = false
    for i = 2, VelocityrraySize * 2 do
        if (VelocityArray[i] ~= -999) then
            local VelNow = VelocityArray[i]
            if (VelNow > 400) then VelNow = 400 end
            if (VelNow < 0) then VelNow = 0 end

            local VelOld = VelocityArray[i - 1]
            if (VelOld > 400) then VelOld = 400 end
            if (VelOld < 0) then VelOld = 0 end

            Render.AddPoly(i - 2, Globals.ScreenWidth() / 2 - VelocityrraySize + i, PosY - VelOld * SizeY)
            Render.AddPoly(i - 1, Globals.ScreenWidth() / 2 - VelocityrraySize + i + 1, PosY - VelNow * SizeY)
        end
    end
    Render.Poly(VelocityrraySize * 2, Color.new(settings["accentClr"].r,settings["accentClr"].g,settings["accentClr"].b, 255), false, 1)
end
