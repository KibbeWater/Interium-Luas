local Animator = {starttime = 0, durbation=1, FPS=300, reverse=false, data={frames=0,frame=0}}

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

local function clamp(n,min,max)
    if n < min then return min elseif n > max then return max else return n end
end

function Animator:New()
    return Deepcopy(self)
end

function Animator:Start(FPS, durbation)
    self.FPS = FPS
    self.durbation = durbation
    self.starttime = IGlobalVars.realtime
    self.reverse = 0
    self.data.frame = 0
    self.data.frames = FPS * durbation
end

function Animator:Finished()
    return IGlobalVars.realtime - self.starttime >= self.durbation
end

function Animator:Update()
    self.data.frames = self.FPS * self.durbation
    self.data.frame = clamp(math.floor(clamp(IGlobalVars.realtime - self.starttime, 0, self.durbation) * self.FPS), 0, self.data.frames)
    if self.reverse then self.data.frame = self.data.frames - self.data.frame end
end

function Animator:Reverse()
    self.starttime = IGlobalVars.realtime
    self.reverse = not self.reverse
end

function Animator:GetValue(min, max)
    self:Update()
    return (((max-min) / 100)*(100-((100 / self.data.frames) * self.data.frame)))+min
end

local animFade = Animator:New()
animFade:Start(300, 0.4)
local animFade2 = Animator:New()
animFade2:Start(300, 0.4)
local animFade3 = Animator:New()
animFade3:Start(300, 1)

Hack.RegisterCallback("PaintTraverse", function ()
    local opacity = animFade:GetValue(0,255)
    local sizeX = animFade:GetValue(0,200)
    local opacity2 = animFade2:GetValue(0,255)
    local sizeX2 = animFade2:GetValue(0,400)
    local opacity3 = animFade3:GetValue(0,255)
    local sizeX3 = animFade3:GetValue(0,400)

    Render.RectFilled(0, 400, sizeX, 440, Color.new(255,255,255,opacity))
    Render.RectFilled(0, 480, sizeX2, 440, Color.new(255,255,255,opacity2))
    Render.RectFilled(0, 480, sizeX3, 520, Color.new(255,255,255,opacity3))

    if animFade:Finished() and animFade2:Finished() and animFade3:Finished() then
        animFade:Reverse()
        animFade2:Reverse()
        animFade3:Reverse()
    end
end)