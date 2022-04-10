-- Globals
local appdataPath = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ScriptHub\\"
local configsPath = GetAppData() .. "\\INTERIUM\\CSGO\\Cfg\\"
local scriptsPath = GetAppData() .. "\\INTERIUM\\CSGO\\Lua\\"

FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ScriptHub\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ScriptHub\\Configs\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\ScriptHub\\Scripts\\")

URLDownloadToFile("https://old.kibbewater.xyz/interium/scripthub_host.txt", appdataPath .. "host.txt")
if not FileSys.FileIsExist(appdataPath .. "host.txt") then
    Print("[ScriptHub] Critical Error: Could not download host file!")
    return
end
local host = FileSys.GetTextFromFile(appdataPath .. "host.txt")
Print("[ScriptHub] Retrieved host: " .. host)

local serverURL = "http://"..host..":3000"
local pageLimit = 5
local currentPage = 1
local isScripts = true
local sortRelevant = true
local lastMouseDown = false

local lastConfigs = {}
local configCount = 0
local lastScripts = {}
local scriptCount = 0
local lastUpdate = 0
local updateInterval = 300 * 1000 -- 5 minutes

-- Dragging
local dragging = false
local dragOffset = {x = 0, y = 0}

-- Menu
local menuPos = {x = 10, y = 400}
local pickupOffset = {x = 0, y = 0}

-- GUI
local clickables = {}
local canClick = false

-- Internal API
-- Clickables {[name] = {x, y, w, h, callback}}

-- https://stackoverflow.com/questions/24908199/convert-json-string-to-lua-table
local json = {}

local function kind_of(obj)
    if type(obj) ~= 'table' then return type(obj) end
    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then i = i + 1 else return 'table' end
    end
    if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
    local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
    local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
    for i, c in ipairs(in_char) do
        s = s:gsub(c, '\\' .. out_char[i])
    end
    return s
end

local function skip_delim(str, pos, delim, err_if_missing)
    pos = pos + #str:match('^%s*', pos)
    if str:sub(pos, pos) ~= delim then
        if err_if_missing then
            error('Expected ' .. delim .. ' near position ' .. pos)
        end
        return pos, false
    end
    return pos + 1, true
end

local function parse_str_val(str, pos, val)
    val = val or ''
    local early_end_error = 'End of input found while parsing string.'
    if pos > #str then error(early_end_error) end
    local c = str:sub(pos, pos)
    if c == '"'  then return val, pos + 1 end
    if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
    -- We must have a \ character.
    local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
    local nextc = str:sub(pos + 1, pos + 1)
    if not nextc then error(early_end_error) end
    return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

local function parse_num_val(str, pos)
    local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
    local val = tonumber(num_str)
    if not val then error('Error parsing number at position ' .. pos .. '.') end
    return val, pos + #num_str
end

function json.stringify(obj, as_key)
    local s = {}  -- We'll build the string as an array of strings to be concatenated.
    local kind = kind_of(obj)  -- This is 'array' if it's an array or type(obj) otherwise.
    if kind == 'array' then
        if as_key then error('Can\'t encode array as key.') end
        s[#s + 1] = '['
        for i, val in ipairs(obj) do
            if i > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = json.stringify(val)
        end
        s[#s + 1] = ']'
    elseif kind == 'table' then
        if as_key then error('Can\'t encode table as key.') end
        s[#s + 1] = '{'
        for k, v in pairs(obj) do
            if #s > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = json.stringify(k, true)
            s[#s + 1] = ':'
            s[#s + 1] = json.stringify(v)
        end
        s[#s + 1] = '}'
    elseif kind == 'string' then
        return '"' .. escape_str(obj) .. '"'
    elseif kind == 'number' then
        if as_key then return '"' .. tostring(obj) .. '"' end
        return tostring(obj)
    elseif kind == 'boolean' then
        return tostring(obj)
    elseif kind == 'nil' then
        return 'null'
    else
        error('Unjsonifiable type: ' .. kind .. '.')
    end
    return table.concat(s)
end

json.null = {}  -- This is a one-off table to represent the null value.

function json.parse(str, pos, end_delim)
    pos = pos or 1
    if pos > #str then error('Reached unexpected end of input.') end
    local pos = pos + #str:match('^%s*', pos)  -- Skip whitespace.
    local first = str:sub(pos, pos)
    if first == '{' then  -- Parse an object.
        local obj, key, delim_found = {}, true, true
        pos = pos + 1
        while true do
          key, pos = json.parse(str, pos, '}')
          if key == nil then return obj, pos end
          if not delim_found then error('Comma missing between object items.') end
          pos = skip_delim(str, pos, ':', true)  -- true -> error if missing.
          obj[key], pos = json.parse(str, pos)
          pos, delim_found = skip_delim(str, pos, ',')
        end
    elseif first == '[' then  -- Parse an array.
        local arr, val, delim_found = {}, true, true
        pos = pos + 1
        while true do
          val, pos = json.parse(str, pos, ']')
          if val == nil then return arr, pos end
          if not delim_found then error('Comma missing between array items.') end
          arr[#arr + 1] = val
          pos, delim_found = skip_delim(str, pos, ',')
        end
    elseif first == '"' then  -- Parse a string.
        return parse_str_val(str, pos + 1)
    elseif first == '-' or first:match('%d') then  -- Parse a number.
        return parse_num_val(str, pos)
    elseif first == end_delim then  -- End of an object or array.
        return nil, pos + 1
    else  -- Parse true, false, or null.
        local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
        for lit_str, lit_val in pairs(literals) do
            local lit_end = pos + #lit_str - 1
            if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
        end
        local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
        error('Invalid json syntax starting at ' .. pos_info_str)
    end
end

function s(comparison, isTrue, isFalse) if comparison then return isTrue else return isFalse end end

function randomString(length)
    local str = ""
    for i = 1, length do
        str = str .. string.char(math.random(97, 122))
    end
    return str
end

function print_r(arr, indentLevel)
    local str = ""
    local indentStr = "#"

    if(indentLevel == nil) then
        Print(print_r(arr, 0))
        return
    end

    for i = 0, indentLevel do
        indentStr = indentStr.." "
    end

    for index,value in pairs(arr) do
        if type(value) == "table" then
            str = str..indentStr..index..": \necho "..print_r(value, (indentLevel + 1))
        else 
            str = str..indentStr..index..": "..value.."\necho "
        end
    end
    return str
end

function GetConfigs(page, limit)
    URLDownloadToFile(serverURL .. "/api/v1/configs?page=" .. page .. "&limit=" .. limit .. "&sort=" .. s(sortRelevant, "relevant", "latest") .. "&random=" .. randomString(4), appdataPath .. "configs.json")
    local fileData = FileSys.GetTextFromFile(appdataPath .. "configs.json")
    local jsonOut = json.parse(fileData)
    if jsonOut.status == "success" then
        configCount = jsonOut.count
        return jsonOut.data
    else
        Print("[ScriptHub] Error getting configs: " .. jsonOut.reason)
        return nil
    end
    return jsonOut.data
end

function GetScripts(page, limit)
    URLDownloadToFile(serverURL .. "/api/v1/scripts?page=" .. page .. "&limit=" .. limit .. "&sort=" .. s(sortRelevant, "relevant", "latest") .. "&random=" .. randomString(4), appdataPath .. "scripts.json")
    local fileData = FileSys.GetTextFromFile(appdataPath .. "scripts.json")
    local jsonOut = json.parse(fileData)
    if jsonOut.status == "success" then
        scriptCount = jsonOut.count
        return jsonOut.data
    else
        Print("[ScriptHub] Error getting scripts: " .. jsonOut.reason)
        return nil
    end
    return jsonOut.data
end

function IsInsidePolygon(position, polygon)
    local polygonLength = #polygon
    local j = polygonLength
    local oddNodes = false
    local x = position.x
    local y = position.y
    for i = 1, polygonLength do
        if ((polygon[i].y < y and polygon[j].y >= y) or (polygon[j].y < y and polygon[i].y >= y)) and (polygon[i].x <= x or polygon[j].x <= x) then
            oddNodes = not oddNodes
        end
        j = i
    end
    return oddNodes
end

function RegisterClickable(x, y, w, h, callback)
    local clickable = {
        x = x,
        y = y,
        w = w,
        h = h,
        callback = callback
    }
    table.insert(clickables, clickable)
end

function CreateButton(x, y, w, h, color, rounding, callback)
    local button = {
        x = x,
        y = y,
        w = w,
        h = h,
        callback = callback
    }
    Render.RectFilled(x, y, x + w, y + h, color, rounding)
    table.insert(clickables, button)
end

--Create a paint hook
Hack.RegisterCallback("PaintTraverse", function ()
    if not Globals.MenuOpened() then return end

    if GetTickCount() > lastUpdate + updateInterval then
        lastUpdate = GetTickCount()
        lastConfigs = GetConfigs(currentPage, pageLimit)
        lastScripts = GetScripts(currentPage, pageLimit)
    end

    Render.RectFilled(menuPos.x, menuPos.y, menuPos.x + 400, menuPos.y + 25, Color.new(255, 255, 255, 255), 0)
    local headerScale = Render.CalcTextSize_1(s(isScripts, "Scripts", "Configs"), 15)
    Render.Text_1(s(isScripts, "Scripts", "Configs"), menuPos.x + 200, menuPos.y + ((25/2) - headerScale.y/2), 15, Color.new(15, 15, 15, 255), true, false)
    
    local cfgBtnSize = {x = 70, y = 19}
    CreateButton(menuPos.x + 400 - (cfgBtnSize.x+5), menuPos.y+3, cfgBtnSize.x, cfgBtnSize.y, Color.new(235, 235, 235, 255), 0, function()
        isScripts = not isScripts
        currentPage = 1
        lastUpdate = 0
    end)
    local cfgBtnText = Render.CalcTextSize_1(s(isScripts, "Configs", "Scripts"), 14)
    Render.Text_1(s(isScripts, "Configs", "Scripts"), menuPos.x + 400 - (cfgBtnSize.x+5)/2, (menuPos.y+3) + ((cfgBtnSize.y/2) - cfgBtnText.y/2), 14, Color.new(15, 15, 15, 255), true, false)

    local sortBtnSize = {x = 70, y = 19}
    local sortBtnText = Render.CalcTextSize_1(s(not sortRelevant, "Sort: Latest", "Sort: Relevant"), 14)
    sortBtnText.x = sortBtnText.x + 10
    if sortBtnText.x > sortBtnSize.x then sortBtnSize.x = sortBtnText.x end
    CreateButton(menuPos.x + 5, menuPos.y+3, sortBtnSize.x, sortBtnSize.y, Color.new(235, 235, 235, 255), 0, function()
        sortRelevant = not sortRelevant
        currentPage = 1
        lastUpdate = 0
    end)
    Render.Text_1(s(not sortRelevant, "Sort: Latest", "Sort: Relevant"), menuPos.x + 5 + (sortBtnSize.x/2), (menuPos.y+3) + ((sortBtnSize.y/2) - sortBtnText.y/2), 14, Color.new(15, 15, 15, 255), true, false)

    local iteratingArray = s(isScripts, lastScripts, lastConfigs)
    for i = 1, #iteratingArray do
        Render.RectFilled(menuPos.x, menuPos.y + 25 + ((i-1) * 40), menuPos.x + 400, menuPos.y + 65 + ((i-1) * 40), Color.new(235, 235, 235, 255), 0)
        Render.RectFilled(menuPos.x + 5, menuPos.y + 25 + ((i-1) * 40) + 5, menuPos.x + 400 - 5, menuPos.y + 65 + ((i-1) * 40) - 5, Color.new(250, 250, 250, 255), 0)
        local itemScale = Render.CalcTextSize_1(iteratingArray[i].username .. " - " .. iteratingArray[i][s(isScripts, "scriptName", "configName")], 15)
        Render.Text_1(iteratingArray[i].username .. " - " .. iteratingArray[i][s(isScripts, "scriptName", "configName")], menuPos.x + 10, menuPos.y + 25 + ((i-1) * 40) + (20 - (itemScale.y/2)), 15, Color.new(15, 15, 15, 255), false, false)

        local authorTxtScale = 12
        local authorScale = Render.CalcTextSize_1(iteratingArray[i].version, authorTxtScale)
        Render.Text_1(iteratingArray[i].version, menuPos.x + 10 + itemScale.x + 5, menuPos.y + 25 + ((i-1) * 40) + (20 - (itemScale.y/2)) + (itemScale.y - authorScale.y), authorTxtScale, Color.new(95, 95, 95, 255), false, false)

        local buttonScale = {x = 75, y = 20}
        local padding = 10
        local buttonPos = {x = menuPos.x + 400 - buttonScale.x - padding, y = menuPos.y + 25 + ((i-1) * 40) + (20 - (buttonScale.y/2))}
        CreateButton(buttonPos.x, buttonPos.y, buttonScale.x, buttonScale.y, Color.new(235,235,235,255), 0, function()
            Print("[ScriptHub] Downloading " .. s(isScripts, "script", "config") .. ": " .. iteratingArray[i][s(isScripts, "scriptName", "configName")])
            Utils.ConsolePrint("[ScriptHub] Downloading " .. s(isScripts, "script", "config") .. ": " .. serverURL .. iteratingArray[i].dataPath .. "\n")
            local fileName = iteratingArray[i].dataPath:match("([^/]+)$")
            Utils.ConsolePrint("[ScriptHub] Downloading to " .. s(isScripts, scriptsPath, configsPath) .. fileName .. "\n")
            URLDownloadToFile(serverURL .. iteratingArray[i].dataPath .. "?random=" .. randomString(4), s(isScripts, scriptsPath, configsPath) .. fileName)
            Utils.ConsolePrint("[ScriptHub] Loading " .. s(isScripts, "script", "config") .. ": " .. fileName .. "\n")
            if isScripts then Hack.LoadLua(fileName) end
        end)
        local buttonTxtScale = 15
        local downloadScale = Render.CalcTextSize_1("Download", buttonTxtScale)
        Render.Text_1("Download", buttonPos.x + buttonScale.x/2, (buttonPos.y + buttonScale.y/2) - downloadScale.y / 2, buttonTxtScale, Color.new(15,15,15,255), true, false)
    end

    -- Render footer
    local footerSize = {x = 400, y = 30}
    local footerY = menuPos.y + 65 + ((#iteratingArray-1) * 40)
    Render.RectFilled(menuPos.x, footerY, menuPos.x+footerSize.x, footerY+footerSize.y+5, Color.new(235, 235, 235, 255))
    Render.RectFilled(menuPos.x, footerY+footerSize.y+2, menuPos.x+footerSize.x, footerY+footerSize.y+7, Color.new(255, 255, 255, 255))

    --Pagination controls
    local paginationText = currentPage .. "/" .. math.ceil(s(isScripts, scriptCount, configCount) / pageLimit)
    local paginationScale = Render.CalcTextSize_1(paginationText, 15)
    local paginationPos = {x = menuPos.x + footerSize.x/2 - paginationScale.x/2, y = footerY + footerSize.y/2 - paginationScale.y/2}
    local paginationScaleX = math.max(75, paginationScale.x)

    Render.RectFilled(menuPos.x+(footerSize.x/2)-(paginationScaleX/2), paginationPos.y - 5, menuPos.x+(footerSize.x/2)+(paginationScaleX/2), paginationPos.y + paginationScale.y + 5, Color.new(255, 255, 255, 255))
    Render.Text_1(paginationText, menuPos.x+footerSize.x/2, paginationPos.y, 15, Color.new(15, 15, 15, 255), true, false)

    -- Create a left button 5 px from the left of the footer make it have a padding of px from top and bottom
    local leftButtonSize = {x = 75, y = 20}
    local leftButtonPos = {x = menuPos.x + 5, y = footerY + footerSize.y/2 - leftButtonSize.y/2}
    CreateButton(leftButtonPos.x, paginationPos.y - 5, leftButtonSize.x, paginationScale.y + 10, Color.new(255, 255, 255, 255), 0, function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            lastUpdate = 0
        end
    end)
    local leftButtonTxtScale = 15
    local leftButtonTxtScale = Render.CalcTextSize_1("<<", leftButtonTxtScale)
    Render.Text_1("<<", leftButtonPos.x + leftButtonSize.x/2 - leftButtonTxtScale.x/2, leftButtonPos.y + leftButtonSize.y/2 - leftButtonTxtScale.y/2, leftButtonTxtScale, Color.new(15, 15, 15, 255), true, false)

    -- Create another button 5 px from the right and make it similar to the button above
    local rightButtonSize = {x = 75, y = 20}
    local rightButtonPos = {x = menuPos.x + footerSize.x - rightButtonSize.x - 5, y = footerY + footerSize.y/2 - rightButtonSize.y/2}
    CreateButton(rightButtonPos.x, paginationPos.y - 5, rightButtonSize.x, paginationScale.y + 10, Color.new(255, 255, 255, 255), 0, function()
        if currentPage < math.ceil(s(isScripts, scriptCount, configCount) / pageLimit) then
            currentPage = currentPage + 1
            lastUpdate = 0
        end
    end)
    local rightButtonTxtScale = 15
    local rightButtonTxtScale = Render.CalcTextSize_1(">>", rightButtonTxtScale)
    Render.Text_1(">>", rightButtonPos.x + rightButtonSize.x/2 - rightButtonTxtScale.x/2, rightButtonPos.y + rightButtonSize.y/2 - rightButtonTxtScale.y/2, rightButtonTxtScale, Color.new(15, 15, 15, 255), true, false)

    local hoveringClickable = false
    local mouse = InputSys.GetCursorPos()
    for i = 1, #clickables do
        local clickable = clickables[i]
        if mouse.x > clickable.x and mouse.x < clickable.x + clickable.w and mouse.y > clickable.y and mouse.y < clickable.y + clickable.h then
            local color = Color.new(11, 11, 11, 155)
            if InputSys.IsKeyDown(1) then color = Color.new(25, 25, 25, 255) end
            if InputSys.IsKeyPress(1) then
                clickable.callback()
            end
            hoveringClickable = true
            Render.Rect(clickable.x, clickable.y, clickable.x + clickable.w, clickable.y + clickable.h,color,0,2)
        end
    end
    clickables = {}

    local mouseDown = InputSys.IsKeyDown(1)
    if not lastMouseDown and mouseDown and not hoveringClickable then
        if mouse.x > menuPos.x and mouse.x < menuPos.x + 400 and mouse.y > menuPos.y and mouse.y < menuPos.y + 25 then
            dragging = true
        dragOffset = {x = mouse.x - menuPos.x, y = mouse.y - menuPos.y}
        end
    end
    if dragging and mouseDown then
        menuPos.x = mouse.x - dragOffset.x
        menuPos.y = mouse.y - dragOffset.y
    elseif dragging and not mouseDown then
        dragging = false
    end
    lastMouseDown = mouseDown
end)
