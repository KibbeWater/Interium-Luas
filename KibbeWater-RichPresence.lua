Menu.Spacing()
Menu.Separator()
Menu.Spacing()
Menu.Text("KibbeWater - Rich Presence")
Menu.Spacing()
Menu.Spacing()
Menu.Spacing()
Menu.Text("Options")
Menu.Separator()
Menu.Checkbox("Hide game status", "snowRPHidden", false)

--Do autoupdating
local currentVer = "1.0"
local appdir = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\RichPresence\\"
local verdir = GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\"
local luadir = GetAppData() .. "\\INTERIUM\\CSGO\\Lua\\"
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\")
FileSys.CreateDirectory(GetAppData() .. "\\INTERIUM\\CSGO\\FilesForLUA\\kibbewater\\RichPresence\\")

URLDownloadToFile("https://kibbewater.xyz/ver/rp.txt", verdir.."rp.txt")

if FileSys.FileIsExist(luadir.."RPUpdater.lua") and false then
    Hack.UnloadLua("RPUpdater.lua")
    FileSys.SaveTextToFile(luadir.."RPUpdater.lua", "Hello, this is an autoupdater for KibbeWater-RichPresence.lua. Feel free to delete me if I'm taking space")
    Print("[RichPresence] Seems like I've been updated... Feel free to remove the RPUpdater.lua file now")
end

local verData = FileSys.GetTextFromFile(verdir.."rp.txt")
if verData == currentVer then
    Print("[RichPresence] You are running the latest version")
else
    Print("[RichPresence] Outdated version, initialising update protocol")
    if not FileSys.FileIsExist(luadir.."KibbeWater-RichPresence.lua") then
        Print("[RichPresence] You have renamed me! Please rename me back to KibbeWater-RichPresence.lua or it might cause major issues!")
        return
    end
    URLDownloadToFile("https://kibbewater.xyz/f/RPUpdater.lua", luadir.."RPUpdater.lua")
    Hack.LoadLua("RPUpdater.lua")
end

local Buffer = {pos=0,length=0,data={}}

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

function Deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Deepcopy(orig_key)] = Deepcopy(orig_value)
        end
        setmetatable(copy, Deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Buffer:New()
    return Deepcopy(self)
end

function Buffer:Update()
    return
end

function Buffer:Flush()
    self.data = {}
    self.length = 0
    self.pos = 0
end

function Buffer:String()
    local strOut = ""
    for i = 1, #self.data do
        strOut = strOut .. self.data[i]
    end
    return strOut
end

function Buffer:LoadData(data)
    for i = 1, string.len(data) do
        table.insert(self.data, string.sub(data,i,i))
    end
    self:Update()
end

function Buffer:LoadFile(filename)
    if not FileSys.FileIsExist(filename) then return end
    local data = FileSys.GetTextFromFile(filename)
    self:LoadData(data)
end

function Buffer:ReadByte()
    self:Update()
    self.pos = self.pos + 1
    return string.byte(self.data[self.pos])
end

function Buffer:ReadInt()
    self:Update()
    local b1 = self:ReadByte()
    local b2 = self:ReadByte()
    local b3 = self:ReadByte()
    local b4 = self:ReadByte()

    if not b4 then return 0 end
    local n = b1*16777216 + b2*65536 + b3*256 + b4
    n = (n > 2147483647) and (n - 4294967296) or n
    return n
end

function Buffer:ReadDouble()
    self:Update()
    local packedStr = ""
    for i = 1, 8 do
        packedStr = packedStr .. string.char(Buffer:ReadByte())
    end
    return string.unpack("<d", packedStr)
end

function Buffer:ReadString(len)
    local outStr = ""

    for i = 1, len do
        outStr = outStr .. string.char(self:ReadByte())
    end

    return outStr
end

function Buffer:WriteByte(n)
    self:Update()
    self.pos = self.pos + 1
    table.insert(self.data, string.char(n))
end

function Buffer:WriteInt(n)
    self:Update()
    if n > 2147483647 then return end
    if n < -2147483648 then return end
    n = (n < 0) and (4294967296 + n) or n

    self:WriteByte(math.modf(n/16777216)%256)
    self:WriteByte(math.modf(n/65536)%256)
    self:WriteByte(math.modf(n/256)%256)
    self:WriteByte(n%256)
end

function Buffer:WriteDouble(n)
    self:Update()
    local packed = string.pack("<d",n)
    for i = 1, string.len(packed) do
        self:WriteByte(string.byte(packed:sub(i,i)))
    end
end

function Buffer:WriteString(str, len)
    for i = 1, len do
        local byte = 0
        if string.len(str) >= i then byte = string.byte(str:sub(i,i)) end
        self:WriteByte(byte)
    end
end

--Start of custom buffer functions
function Buffer:WriteShort(n)
    local packed = string.pack("<h",n)
    for i = 1, string.len(packed) do
        self:WriteByte(string.byte(packed:sub(i,i)))
    end
end

function Buffer:ReadShort()
    local packedStr = ""
    for i = 1, 2 do
        packedStr = packedStr .. string.char(Buffer:ReadByte())
    end
    return string.unpack("<h", packedStr)
end

function Buffer:WriteLong(n)
    local packed = string.pack("<l",n)
    for i = 1, string.len(packed) do
        self:WriteByte(string.byte(packed:sub(i,i)))
    end
end

function Buffer:ReadLong()
    local packedStr = ""
    for i = 1, 4 do
        packedStr = packedStr .. string.char(Buffer:ReadByte())
    end
    return string.unpack("<l", packedStr)
end

function Buffer:WriteFloat(n)
    local packed = string.pack("<f",n)
    for i = 1, string.len(packed) do
        self:WriteByte(string.byte(packed:sub(i,i)))
    end
end

function Buffer:ReadFloat()
    local packedStr = ""
    for i = 1, 4 do
        packedStr = packedStr .. string.char(Buffer:ReadByte())
    end
    return string.unpack("<f", packedStr)
end

--Custom functions
function GetIPType(ip)
    -- must pass in a string value
    if ip == nil or type(ip) ~= "string" then
        return 0
    end

    -- check for format 1.11.111.111 for ipv4
    local chunks = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
    if (#chunks == 4) then
        for _,v in pairs(chunks) do
            if (tonumber(v) < 0 or tonumber(v) > 255) then
                return 0
            end
        end
        return 1
    else
        return 0
    end

    -- check for ipv6 format, should be 8 'chunks' of numbers/letters
    local _, chunks = ip:gsub("[%a%d]+%:?", "")
    if chunks == 8 then
        return 2
    end

    -- if we get here, assume we've been given a random string
    return 3
end

function GetUsername()
    local pLocal = IEntityList.GetPlayer(IEngine.GetLocalPlayer())
    if not pLocal then return "" end

    local playerInfo = CPlayerInfo.new()
    pLocal:GetPlayerInfo(playerInfo)
    if not playerInfo then return "" end

    return playerInfo.szName
end

local lastUpdate = 0
local updateInterval = 0.75

local writeBuffer = Buffer:New()

--Structure
--  struct PresenceData
--  {
--      char state[128];
--      char details[128];
--      char largeText[128];
--      float uptime;
--      short partySize;
--      short partyMax;
--      bool hasParty;
--  };

--StatusIDs:
--0: idle
--1: matchmaking
--2: community server
--3: offline bots
--3: hidden server
Hack.RegisterCallback("PaintTraverse", function ()
    if IGlobalVars.realtime < lastUpdate + updateInterval then return end

    local netChannel = IEngine.GetNetChannelInfo()

    local statusID = 1
    
    if netChannel then 
        local ipType = GetIPType(netChannel:GetAddress()) 
        if ipType ~= 3 and ipType ~= 0 then 
            statusID = 2 
        end
        if netChannel:GetAddress() == "loopback" then statusID = 3 end
    end
    if not Utils.IsInGame() then statusID = 0 end

    if Menu.GetBool("snowRPHidden") and statusID ~= 0 then statusID = 4 end
    
    writeBuffer:Flush()

    if statusID == 0 then
        writeBuffer:WriteString("Waiting in Lobby", 128)
        writeBuffer:WriteString("Idle", 128)
        writeBuffer:WriteString(GetUsername(), 128)
        writeBuffer:WriteFloat(IGlobalVars.realtime)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteByte(0)
    elseif statusID == 1 then
        writeBuffer:WriteString("Playing " .. IEngine.GetLevelNameShort(), 128)
        writeBuffer:WriteString("Official Servers", 128)
        writeBuffer:WriteString(GetUsername(), 128)
        writeBuffer:WriteFloat(IGlobalVars.realtime)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteByte(0)
    elseif statusID == 2 then
        writeBuffer:WriteString("Playing on " .. netChannel:GetAddress(), 128)
        writeBuffer:WriteString("Community Server", 128)
        writeBuffer:WriteString(GetUsername(), 128)
        writeBuffer:WriteFloat(IGlobalVars.realtime)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteByte(0)
    elseif statusID == 3 then
        writeBuffer:WriteString("Playing with bots", 128)
        writeBuffer:WriteString("Offline Match", 128)
        writeBuffer:WriteString(GetUsername(), 128)
        writeBuffer:WriteFloat(IGlobalVars.realtime)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteByte(0)
    elseif statusID == 4 then
        writeBuffer:WriteString("Playing CS:GO", 128)
        writeBuffer:WriteString("In a Match", 128)
        writeBuffer:WriteString("", 128)
        writeBuffer:WriteFloat(IGlobalVars.realtime)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteShort(0)
        writeBuffer:WriteByte(0)
    end
    
    FileSys.SaveTextToFile(appdir.."presence.dat", writeBuffer:String())

    lastUpdate = IGlobalVars.realtime
end)
