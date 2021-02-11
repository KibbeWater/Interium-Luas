Menu.Checkbox("Start GIF", "cGIFStart")
Menu.InputText("GIF Name", "cGIFName", "")
Menu.Checkbox("Load GIF", "cGIFLoad")
Menu.InputInt("Playback FPS", "cGIFFPS", 30)
Menu.Spacing()
Menu.Spacing()
Menu.InputInt("x Size", "cGIFx", 512)
Menu.InputInt("y Size", "cGIFy", 512)

--Startup
Print("----------------------------------------------------------------")
Print("                    KibbeWater GIF Loader v1.0                  ")
Print("                             Loading...                         ")
Print("----------------------------------------------------------------")

--Create some vars
local gifBasePath = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gifs\\"
local fileExtension = ".png"
local loadedImages = {}
local debug = false

--Old data
local oldName = ""

--Rendering info
local FPS = 30
local frame = 0
local LRF = 0
local NFR = 0

--Create Folders
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\gifs\\")

--Create functions
function Log(text)
    Print("[GIF Loader] " .. text)
end

function LoadGIF(name, keyName)
    local gifPath = gifBasePath .. name .. "\\"
    local i = 0
    Log("Starting GIF loading...")
    local sizeGIF = GifSize(name)
    for y = 1, sizeGIF do
        local size = string.len(tostring(i))
        local fileID = tostring(i)
        for x = 1, 5 - size do fileID = "0" .. fileID end
        local fileName = name .. "_" .. fileID .. fileExtension
        if debug then Log("Generated image name and finding \"" .. fileName .. "\"") end
        if debug then Log("Key: " .. keyName .. "_" .. i) end
        ::reload::
        Render.LoadImage(keyName .. "_" .. i, gifPath .. fileName)
        if Render.IsImage(keyName .. "_" .. i) then
            Print("Loaded " .. i .. " correctly")
        end
        if debug then Log("Loaded image") end
        i = i + 1
    end
    Log("Finished loading")
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
local loadingGif = false
local loadName = ""
local switch = false
Hack.RegisterCallback("PaintTraverse", function ()
    --Load
    if loadingGif and not switch then
        local gifPath = gifBasePath .. loadName .. "\\"
        local size = string.len(tostring(i))
        local fileID = tostring(i)
        for x = 1, 5 - size do fileID = "0" .. fileID end
        local fileName = loadName .. "_" .. fileID .. fileExtension
        if debug then Log("Generated image name and finding \"" .. fileName .. "\"") end
        if debug then Log("Key: " .. loadName .. "_" .. i) end
        Render.LoadImage(loadName .. "_" .. i, gifPath .. fileName)
        i = i + 1
        if i >= GifSize(loadName) then 
            loadName = ""
            i = 0
            loadingGif = false
        else switch = true end
    elseif switch then switch = false end

    ::execute::

    --Set variables
    FPS = Menu.GetInt("cGIFFPS")

    if Menu.GetBool("cGIFLoad") then
        if Menu.GetString("cGIFName") ~= "" then 
            loadingGif = true
            loadName = Menu.GetString("cGIFName")
            i = 0
        end
        Menu.SetBool("cGIFLoad", false)
    end

    if oldName ~= Menu.GetString("cGIFName") and Menu.GetBool("cGIFStart") then
        Menu.SetBool("cGIFStart", false)
        if debug then Log("Name missmatch, probably due to new user input. closing") end
    end

    if Menu.GetBool("cGIFStart") then --Render
        local gifLength = GifSize(Menu.GetString("cGIFName"))
        if NFR <= IGlobalVars.realtime then --Render frame because were allowed to
            if gifLength - 1 >= frame + 1 then frame = frame + 1 else frame = 0 end
        end
        if Render.IsImage(Menu.GetString("cGIFName") .. "_" .. frame) then
            Render.Image(Menu.GetString("cGIFName") .. "_" .. frame, 0, 0, Menu.GetInt("cGIFx"), Menu.GetInt("cGIFy"), Color.new(255,255,255,255), 0, 0, 1, 1) 
            if debug then Log("Rendering frame " .. frame) end
        else
            if debug then Log("Image does not exist, not loaded? closing (" .. Menu.GetString("cGIFName") .. "_" .. frame .. ")") end
            frame = 0
            Menu.SetBool("cGIFStart", false)
        end
    end

    --Calculate rendering for next frame
    if IGlobalVars.realtime > NFR then
        NFR = IGlobalVars.realtime + 1 / FPS
    end

    --Register old data
    oldName = Menu.GetString("cGIFName")
end)