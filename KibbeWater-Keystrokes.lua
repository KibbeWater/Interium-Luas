Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - Keystrokes")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Box Settings")
Menu.Separator()
Menu.SliderInt("Box Size", "snowKeystrokesSize", 0, 100, 1, 60)
Menu.SliderInt("Box Offset", "snowKeystrokesOffset", 0, 10, 1, 5)
Menu.Spacing()
Menu.Spacing()
Menu.Text("Colors")
Menu.Separator()
Menu.ColorPicker("Box Color", "snowKeystrokesBoxClr", 0, 0, 0, 100)
Menu.Checkbox("Box RGB", "snowKeystrokesBoxRGB", false)
Menu.Spacing()
Menu.ColorPicker("Box Pressed Color", "snowKeystrokesBoxClrA", 25, 25, 25, 50)
Menu.Checkbox("Box Pressed RGB", "snowKeystrokesBoxARGB", false)
Menu.Spacing()
Menu.Spacing()
Menu.ColorPicker("Key Color", "snowKeystrokesKeyClr", 255, 255, 255, 255)
Menu.Checkbox("Key RGB", "snowKeystrokesKeyRGB", false)
Menu.Spacing()
Menu.ColorPicker("Key Pressed Color", "snowKeystrokesKeyClrA", 255, 255, 255, 255)
Menu.Checkbox("Key Pressed RGB", "snowKeystrokesKeyARGB", false)
Menu.Spacing()
Menu.Spacing()
Menu.Text("Other")
Menu.Separator()
Menu.InputText("Key Modifier", "snowKeystrokesFormat", "1x1")
Menu.Checkbox("Reset keystrokes position", "snowKeystrokesReset", false)

local PosX = 100
local PosY = 400

local KeySize = 70
local KeyOffset = 5
local KeyRounding = 0
local KeyModifiers = "1x1"

local clrBox = Color.new(0,0,0,100)
local clrBoxPressed = Color.new(25,25,25,55)
local clrKey = Color.new(255,255,255,255)
local clrKeyPressed = Color.new(255,255,255,255)

local appData = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLua\\KibbeWater\\"
FileSys.CreateDirectory(appData)
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLua\\")

URLDownloadToFile("https://kibbewater.xyz/interium/assets/mc.ttf", appData .. "mcfont.ttf")
--Render.LoadFont("mcFontSnow", appData .. "mcfont.ttf", 30)

local oldPos = Vector.new(PosX, PosY, 0)
local saveInterval = 10
local lastSave = IGlobalVars.realtime + saveInterval

if FileSys.FileIsExist(appData .. "keystrokes.dat") then
    local data = FileSys.GetTextFromFile(appData .. "keystrokes.dat")
    local split = Split(data, ",")
    if #split < 2 then split = {tostring(PosX), tostring(PosY)} end
    PosX = tonumber(split[1])
    PosY = tonumber(split[2])
end

--e: Empty
--n: New line
--m: M1 + M2
-- : Space
local keys = {
    "e","87","e","n",
    "65","83","68","n",
    "m","n",
    " "
}

local M1Clicks = {}
local M2Clicks = {}

local Dragging = false
local OldDragging = false
local DraggingOffset = Vector.new(0,0,0)

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

function GetHighestSize()
    local splitModifier = Split(KeyModifiers, "x")
    if #splitModifier < 2 then splitModifier = {"1", "1"} end
    local modifier = Vector.new(tonumber(splitModifier[1]), tonumber(splitModifier[2]), 0)

    local KeyPos = Vector.new(PosX, PosY, 0)
    local KeySize = Vector.new(KeySize * modifier.x, KeySize * modifier.y, 0)

    local currentSize = 0
    local highestSize = 0
    local newline = true
    for i = 1, #keys do
        if keys[i] == "n" or keys[i] == " " then goto custom end

        if not newline then
            currentSize = currentSize + KeyOffset + KeySize.x
        else
            currentSize = currentSize + KeySize.x
            newline = false
        end

        goto skip
        ::custom::

        if keys[i] == "n" then
            newline = true
            if currentSize > highestSize then highestSize = currentSize end
            currentSize = 0
        end

        ::skip::
    end

    return highestSize
end

function GetHeight()
    local splitModifier = Split(KeyModifiers, "x")
    if #splitModifier < 2 then splitModifier = {"1", "1"} end
    local modifier = Vector.new(tonumber(splitModifier[1]), tonumber(splitModifier[2]), 0)

    local KeySize = Vector.new(KeySize * modifier.x, KeySize * modifier.y, 0)

    local height = KeySize.y
    for i = 1, #keys do if keys[i] == "n" then height = height + KeySize.y + KeyOffset end end

    return height
end

function GetKeyName(keyID)
    local keyz = {
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
    return keyz[keyID]
end

Hack.RegisterCallback("PaintTraverse", function ()
    local chromaSpeed = 3
    local r = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed) * 127 + 128)
    local g = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 2) * 127 + 128)
    local b = math.floor(math.sin(IGlobalVars.realtime * chromaSpeed + 4) * 127 + 128)

    local col = Color.new(r,g,b,255)

    clrBox = Menu.GetColor("snowKeystrokesBoxClr")
    if Menu.GetBool("snowKeystrokesBoxRGB") then clrBox = Color.new(col.r,col.g,col.b,clrBox.a) end
    clrBoxPressed = Menu.GetColor("snowKeystrokesBoxClrA")
    if Menu.GetBool("snowKeystrokesBoxARGB") then clrBoxPressed = Color.new(col.r,col.g,col.b,clrBoxPressed.a) end
    clrKey = Menu.GetColor("snowKeystrokesKeyClr")
    if Menu.GetBool("snowKeystrokesKeyRGB") then clrKey = Color.new(col.r,col.g,col.b,clrKey.a) end
    clrKeyPressed = Menu.GetColor("snowKeystrokesKeyClrA")
    if Menu.GetBool("snowKeystrokesKeyARGB") then clrKeyPressed = Color.new(col.r,col.g,col.b,clrKeyPressed.a) end

    KeySize = Menu.GetInt("snowKeystrokesSize")
    KeyOffset = Menu.GetInt("snowKeystrokesOffset")
    KeyModifiers = Menu.GetString("snowKeystrokesFormat")

    local splitModifier = Split(KeyModifiers, "x")
    if #splitModifier < 2 then splitModifier = {"1", "1"} end
    local modifier = Vector.new(tonumber(splitModifier[1]), tonumber(splitModifier[2]), 0)

    local KeyPos = Vector.new(PosX, PosY, 0)
    local KeySize = Vector.new(KeySize * modifier.x, KeySize * modifier.y, 0)

    for i = 1, #keys do
        if keys[i] == "e" or keys[i] == "n" or keys[i] == " " or keys[i] == "m" then goto otherKey end
        
        do
            local keyClr = clrKey
            local boxClr = clrBox

            if InputSys.IsKeyDown(tonumber(keys[i])) then
                keyClr = clrKeyPressed
                boxClr = clrBoxPressed
            end

            Render.RectFilled2(KeyPos.x, KeyPos.y, KeySize.x, KeySize.y, boxClr, KeyRounding)

            local key = GetKeyName(tonumber(keys[i]) + 1)
            local size = Render.CalcTextSize_1(key, KeySize.y/2)
            
            Render.Text_1(key, KeyPos.x + (KeySize.x/2), KeyPos.y + (KeySize.y/2) - size.y / 2, KeySize.y/2, keyClr, true, false)
        end

        goto skipOtherKey
        ::otherKey::

        if keys[i] == "n" then
            KeyPos = Vector.new(PosX, KeyPos.y + KeySize.y + KeyOffset, 0)
            goto endLoop
        elseif keys[i] == " " then
            local keyClr = clrKey
            local boxClr = clrBox

            if InputSys.IsKeyDown(32) then
                keyClr = clrKeyPressed
                boxClr = clrBoxPressed
            end

            local size = GetHighestSize()

            Render.RectFilled2(KeyPos.x, KeyPos.y, size, KeySize.y, boxClr, KeyRounding)
            Render.RectFilled((KeyPos.x + size/2)-size/3, (KeyPos.y + KeySize.y/2)-KeySize.y/16, (KeyPos.x + size/2)+size/3, (KeyPos.y + KeySize.y/2)+KeySize.y/16, keyClr, KeyRounding)
        elseif keys[i] == "m" then
            
            local keyClr = clrKey
            local boxClr = clrBox
            local keyClr2 = clrKey
            local boxClr2 = clrBox

            if InputSys.IsKeyDown(1) then
                keyClr = clrKeyPressed
                boxClr = clrBoxPressed
            end
            if InputSys.IsKeyDown(2) then
                keyClr2 = clrKeyPressed
                boxClr2 = clrBoxPressed
            end
            
            local size = GetHighestSize() - KeyOffset

            local pos1 = Vector.new(KeyPos.x, KeyPos.y, 0)
            local size1 = Vector.new(size/2, KeySize.y, 0)

            local pos2 = Vector.new((size/2) + KeyOffset + KeyPos.x, KeyPos.y, 0)
            local size2 = Vector.new(size/2, KeySize.y, 0)

            Render.RectFilled2(pos1.x, pos1.y, size1.x, size1.y, boxClr, KeyRounding)
            Render.RectFilled2(pos2.x, pos2.y, size2.x, size2.y, boxClr2, KeyRounding)

            local size11 = Render.CalcTextSize_1("LMB", KeySize.y/2)
            local size12 = Render.CalcTextSize_1(#M1Clicks .. " CPS", KeySize.y/3)
            local size21 = Render.CalcTextSize_1("RMB", KeySize.y/2)
            local size22 = Render.CalcTextSize_1(#M2Clicks .. " CPS", KeySize.y/3)

            local textOffset = -3
            
            local textSize1 = (size1.y - (size11.y + size12.y + textOffset)) / 2
            local textSize2 = (size2.y - (size21.y + size22.y + textOffset)) / 2

            Render.Text_1("LMB", pos1.x + (size1.x/2), pos1.y + textSize1 + (size1.y/2) - size1.y / 2, size1.y/2, keyClr, true, false)
            Render.Text_1(#M1Clicks .. " CPS", pos1.x + (size1.x/2), pos1.y + textSize1 + size11.y + textOffset + (size1.y/2) - size1.y / 2, size1.y/3, keyClr, true, false)

            Render.Text_1("RMB", pos2.x + (size2.x/2), pos2.y + textSize2 + (size2.y/2) - size2.y / 2, size2.y/2, keyClr, true, false)
            Render.Text_1(#M2Clicks .. " CPS", pos2.x + (size2.x/2), pos2.y + textSize2 + size21.y + textOffset + (size2.y/2) - size2.y / 2, size2.y/3, keyClr, true, false)
        end

        ::skipOtherKey::

        KeyPos = Vector.new(KeyPos.x + KeySize.x + KeyOffset, KeyPos.y, 0)

        ::endLoop::
    end

    local newM1Array = {}
    for i = 1, #M1Clicks do
        if M1Clicks[i] + 1 > IGlobalVars.realtime then table.insert(newM1Array, M1Clicks[i]) end
    end
    M1Clicks = newM1Array
    local newM2Array = {}
    for i = 1, #M2Clicks do
        if M2Clicks[i] + 1 > IGlobalVars.realtime then table.insert(newM2Array, M2Clicks[i]) end
    end
    M2Clicks = newM2Array

    if InputSys.IsKeyPress(1) then
       table.insert(M1Clicks, IGlobalVars.realtime) 
    end
    if InputSys.IsKeyPress(2) then
        table.insert(M2Clicks, IGlobalVars.realtime) 
    end

    local boxOffset = 4
    local corners = {PosX - boxOffset, PosY - boxOffset, PosX + GetHighestSize() + boxOffset, PosY + GetHeight() + boxOffset}
    if Globals.MenuOpened() then
        Render.Rect(corners[1], corners[2], corners[3], corners[4], Color.new(255,255,255,255))

        for i = 1, #corners do
            if string.match(tostring(i/2), ".5") then
                for x = 1, #corners do
                    if not string.match(tostring(x/2), ".5") then
                        Render.RectFilled2(corners[i] - boxOffset, corners[x] - boxOffset, boxOffset*2, boxOffset*2, Color.new(255,255,255,255), 0)
                    end
                end
            end
        end
    end

    local cursor = InputSys.GetCursorPos()
    if cursor.x >= corners[1] and cursor.x <= corners[1] + corners[3] then
        if cursor.y >= corners[2] and cursor.y <= corners[2] + corners[4] then
            if InputSys.IsKeyDown(1) and Globals.MenuOpened() then
                Dragging = true
            elseif not Globals.MenuOpened() then
                if not InputSys.IsKeyDown(1) and not Dragging then Dragging = false end
            end
        elseif not Dragging then
            Dragging = false
        end
    elseif not Dragging then
        Dragging = false
    end
    if not InputSys.IsKeyDown(1) and Dragging then Dragging = false end

    if lastSave < IGlobalVars.realtime then
        if oldPos.x ~= PosX or oldPos.x ~= PosX then 
            FileSys.SaveTextToFile(appData .. "keystrokes.dat", PosX .. "," .. PosY)
            oldPos = Vector.new(PosX, PosY, 0)
        end
        lastSave = IGlobalVars.realtime + saveInterval
    end

    if Menu.GetBool("snowKeystrokesReset") then
        PosX = 10
        PosY = 400
        Menu.SetBool("snowKeystrokesReset")
    end
end)

Hack.RegisterCallback("FrameStageNotify", function(stage)
    if stage == 5 then return end

    if Dragging then
        local cursor = InputSys.GetCursorPos()
        if not OldDragging then
            DraggingOffset = Vector.new(PosX - cursor.x, PosY - cursor.y, 0)
        end
        PosX = cursor.x + DraggingOffset.x
        PosY = cursor.y + DraggingOffset.y
    else
        DraggingOffset = Vector.new(0, 0, 0)
    end
    OldDragging = Dragging
end)