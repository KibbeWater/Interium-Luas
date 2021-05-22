local Buffer = {pos=0,length=0,data={}}

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
    return string.unpack(">d", packedStr)
end

function Buffer:ReadString()
    local outStr = ""

    local finding = true
    while finding do
        local b = self:ReadByte()
        if b ~= 0 then outStr = outStr .. b else finding = false end
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
    local packed = string.pack(">d",n)
    for i = 1, string.len(packed) do
        self:WriteByte(string.byte(packed:sub(i,i)))
    end
end

function Buffer:WriteString(str)
    for i = 1, string.len(str) do
        self:WriteByte(string.byte(str:sub(i,i)))
    end
    self:WriteByte(0)
end