-- src/screen.lua
-- Maintains a logical 800x600 canvas that scales to any real window size.
-- All game objects use logical coords. Call Screen:apply() before drawing,
-- Screen:toGame(x,y) to convert mouse/touch input back to logical coords.

local Screen = {}

Screen.W       = 800   -- logical width
Screen.H       = 600   -- logical height
Screen.scale   = 1
Screen.offsetX = 0
Screen.offsetY = 0

function Screen:update()
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    self.scale   = math.min(sw / self.W, sh / self.H)
    self.offsetX = math.floor((sw - self.W * self.scale) / 2)
    self.offsetY = math.floor((sh - self.H * self.scale) / 2)
end

-- Call inside love.draw() before drawing game objects
function Screen:apply()
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale, self.scale)
end

-- Draw letterbox bars so gaps outside the canvas look clean
function Screen:drawBars()
    love.graphics.setColor(0, 0, 0, 1)
    -- Left / right bars
    if self.offsetX > 0 then
        love.graphics.rectangle("fill", 0, 0, self.offsetX, love.graphics.getHeight())
        love.graphics.rectangle("fill",
            self.offsetX + self.W * self.scale, 0,
            self.offsetX + 1, love.graphics.getHeight())
    end
    -- Top / bottom bars
    if self.offsetY > 0 then
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), self.offsetY)
        love.graphics.rectangle("fill",
            0, self.offsetY + self.H * self.scale,
            love.graphics.getWidth(), self.offsetY + 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Convert real window coords (mouse, touch) → logical game coords
function Screen:toGame(x, y)
    return (x - self.offsetX) / self.scale,
           (y - self.offsetY) / self.scale
end

-- Clamp logical coords to canvas bounds
function Screen:clamp(x, y)
    return math.max(0, math.min(self.W, x)),
           math.max(0, math.min(self.H, y))
end

return Screen
