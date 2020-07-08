Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Checkbox('Enable Notification Manager', 'cEnableNotifManagerLib', true)
Menu.Checkbox('Enable Light Notifications', 'cEnableLightNotifs', false)
Menu.Checkbox('Enable Debug', 'cDebugNotifManagerLib', false)

local API_Send = false
local API_Payload = ""

local payloads = {}

local ver = "1.1"

--Register Functions
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

function String2Bool(string)
    if string == "true" then return true else return false end
end

function Bool2String(bool)
    if bool then return "true" else return "false" end
end

function Setup()
    --Reset needed functions
    Menu.SetBool("NM_API_Send", false)
    Menu.SetString("NM_API_Payload", "")

    URLDownloadToFile("http://kibbewater.ml/ver/notif.txt", GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\notif.txt")
    if FileSys.FileIsExist(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\notif.txt") then
        local data = Split(FileSys.GetTextFromFile(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\notif.txt"), "\n")
        if #data == 2 then
            if ver ~= data[1] then
                table.insert(payloads, "NotifUpdate" .. "*" .. "1" .. "*" .. "Notification Manager Update" .. "*" .. "Please download version " .. data[1] .. " from interium.ooo" .. "*" .. "false" .. "*" .. "0" .. "*" .. "0" .. "*" .. "0" .. "*" .. (IGlobalVars.realtime + 7))
            end
        end
    end
end

function RecievePacket(payload)
    local data = Split(payload, "*")
    if #data ~= 9 then 
        DebugPrint("Recieved invalid Payload: \"" .. payload .. "\"")
    else
        table.insert(payloads, payload)
        DebugPrint("Recieved Payload: \"" .. payload .. "\"")
    end
    Menu.SetString("NM_API_Payload", "")
end

function DebugPrint(text)
    local prefix = "[\x03Debug\x01] \x08"
    if Menu.GetBool("cDebugNotifManagerLib") then IChatElement.ChatPrintf(0, 0, prefix .. text) end
end

Hack.RegisterCallback("PaintTraverse", function ()
    --//
    --UAI (arg 1, user application identification)
    --Type (arg 2, 1=critical(red) 2=warning(yellow) 3=info(blue) 4=noicon(blue))
    --Title (arg 3, SHOULD NEVER HAVE THE CHARACTER '*' IN IT FOR PARSING REASONS)
    --Message (arg 4, SHOULD NEVER HAVE THE CHARACTER '*' IN IT FOR PARSING REASONS)
    --Custom Color (arg 5, true / false to use custom color instead of arg 2 color)
    --Custom R (arg 6, R value in the custom RGB Color)
    --Custom G (arg 7, G value in the custom RGB Color)
    --Custom B (arg 8, B value in the custom RGB Color)
    --Expiration Time (arg 9, second based var)
    --//

    local w = Globals.ScreenWidth()
    local h = Globals.ScreenHeight()

    for i = 1, #payloads do
        local expire = tonumber(Split(payloads[i], "*")[9])
        if expire <= IGlobalVars.realtime then 
            DebugPrint("Removed expired payload: " .. payloads[i])
            table.remove(payloads, i) 
        end
    end

    local displayedItems = 0
    local displayedIDs = {}

    for i = 1, #payloads do
        local data = Split(payloads[i], "*")

        local ID = data[1]
        local Type = tonumber(data[2])

        local Title = data[3]
        local Msg = data[4]

        local useColor = String2Bool(data[5])
        local clr = Color.new(tonumber(data[6]), tonumber(data[7]), tonumber(data[8]), 255)

        local expire = tonumber(tonumber(data[9]))

        local IDUsed = false
        for i = 1, #displayedIDs do
            if displayedIDs[i] == ID then IDUsed = true end
        end

        --Draw notification
        if not IDUsed then
            --Get Color
            local color = Color.new(255,255,255,255)
            local bgColor = Color.new(0,0,0,255)
            local txtClr = Color.new(255,255,255,255)
            if useColor then color = clr else
                if Type == 1 then
                    color = Color.new(255,0,0,255)
                elseif Type == 2 then
                    color = Color.new(255,255,0,255)
                elseif Type == 3 then
                    color = Color.new(0,149,255,255)
                elseif Type == 4 then
                    color = Color.new(0,149,255,255)
                end
            end
            if Menu.GetBool("cEnableLightNotifs") then 
                bgColor = Color.new(255,255,255,255) 
                txtClr = Color.new(0,0,0,255)
            end

            local titleSize = Render.CalcTextSize_1(Title, 20)
            local msgSize = Render.CalcTextSize_1(Msg, 16)

            local addSize = 0
            
            if msgSize.x > 245 then
                addSize = msgSize.x - 238
            end

            Render.AddPoly(0, (w-255) - addSize, 0 + (50*displayedItems))
            Render.AddPoly(1, (w-245) - addSize, 0 + (50*(displayedItems+1)))
            Render.AddPoly(2, w, 0 + (50*(displayedItems+1)))
            Render.AddPoly(3, w, 0 + (50*displayedItems))
            Render.PolyFilled(4, bgColor)
            Render.AddPoly(0, (w-257) - addSize, 0 + (50*displayedItems))
            Render.AddPoly(1, (w-247) - addSize, 0 + (50*(displayedItems+1)))
            Render.AddPoly(2, (w-245) - addSize, 0 + (50*(displayedItems+1)))
            Render.AddPoly(3, (w-255) - addSize, 0 + (50*displayedItems))
            Render.PolyFilled(4, color)

            Render.Text_1(Title, (w-240)-addSize, 5 + (50*displayedItems), 20, txtClr, false, true)
            Render.Text_1(Msg, (w-240)-addSize, (6 + titleSize.y) + (50*displayedItems), 16, txtClr, false, false)

            displayedItems = displayedItems + 1
            table.insert(displayedIDs, ID)
        end
        ::continue::
    end
end)

Hack.RegisterCallback("FrameStageNotify", function (stage)
    if stage == 5 then return end
    
    --Send out enabled status
    Menu.SetInt("NM_API_Enabled", IGlobalVars.realtime+0.5)

    --Check for sent data
    if API_Send ~= Menu.GetBool("NM_API_Send") then
        DebugPrint("Change in API_Send detected, now is " .. Bool2String(Menu.GetBool("NM_API_Send")))
        if Menu.GetString("NM_API_Payload") ~= "" and Menu.GetBool("NM_API_Send") then
            RecievePacket(Menu.GetString("NM_API_Payload"))
        end
        if Menu.GetBool("NM_API_Send") then 
            DebugPrint("Resetting API_Send to FALSE")
            Menu.SetBool("NM_API_Send", false) 
        end
    end

    --Register data
    API_Send = Menu.GetBool("NM_API_Send")
    API_Payload = Menu.GetString("NM_API_Payload")
end)

--One time executions
Setup()
