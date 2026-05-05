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
    -- Adapt logical canvas to actual screen aspect ratio (no black bars).
    -- Height stays at 600; width stretches to fill the real aspect ratio.
    self.H    = 600
    self.W    = math.floor(self.H * sw / sh)
    self.scale   = sh / self.H
    self.offsetX = 0
    self.offsetY = 0
end

-- Call inside love.draw() before drawing game objects
function Screen:apply()
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale, self.scale)
end

-- No letterbox bars needed: canvas always fills the full screen
function Screen:drawBars() end

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
