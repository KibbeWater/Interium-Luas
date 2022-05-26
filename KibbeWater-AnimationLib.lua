local Animator = { starttime = 0, durbation = 1, FPS = 300, reverse = false, keepBezier = true, p1 = { x = 0.5, y = 0.5 }, p2 = { x = 0.5, y = 0.5 }, data = { frames = 0, frame = 0 } }

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

local function clamp(n, min, max)
    if n < min then return min elseif n > max then return max else return n end
end

local function interpolate(p1, p2, t)
    return { x = p1.x + (p2.x - p1.x) * t, y = p1.y + (p2.y - p1.y) * t }
end

local function ComputeLines(lines, t)
    if #lines > 2 then
        local newLines = {}
        for i = 2, #lines do
            local p1 = lines[i - 1]
            local p2 = lines[i]
            table.insert(newLines, { p1 = interpolate(p1.p1, p1.p2, t), p2 = interpolate(p2.p1, p2.p2, t) })
        end
        return ComputeLines(newLines, t)
    else
        local point1Diff = interpolate(lines[1].p1, lines[1].p2, t)
        local point2Diff = interpolate(lines[2].p1, lines[2].p2, t)
        return interpolate(point1Diff, point2Diff, t)
    end
end

local function BezierCurve(start, endd, p, t)
    local points = { start }
    for i = 1, #p do table.insert(points, p[i]) end
    table.insert(points, endd)

    local lines = {}
    for i = 2, #points do
        local curPoint = points[i]
        local prevPoint = points[i - 1]
        table.insert(lines, { p1 = prevPoint, p2 = curPoint })
    end
    return ComputeLines(lines, t)
end

function Animator:New()
    return Deepcopy(self)
end

function Animator:SetBezier(x, y, x2, y2)
    self.p1 = { x = x, y = y }
    self.p2 = { x = x2, y = y2 }
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

    local t = self.data.frame / self.data.frames
    if self.reverse and self.keepBezier then t = 1 - t end
    local val = 1 - BezierCurve({ x = 0, y = 0 }, { x = 1, y = 1 }, { self.p1, self.p2 }, t).y
    if self.reverse and self.keepBezier then val = 1 - val end

    return (((max - min) / 100) * (100 - val * 100)) + min
end
