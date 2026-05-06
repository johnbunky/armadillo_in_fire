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
    local sw, sh
    local os = love.system and love.system.getOS() or ""
    -- CSS pixel size = physical / DPI; mouse coords are in CSS pixels
    local os  = love.system and love.system.getOS() or ""
    local dpi = (os == "Web") and (love.graphics.getDPIScale() or 1) or 1
    sw = love.graphics.getWidth()  / dpi
    sh = love.graphics.getHeight() / dpi
    self.H       = 600
    self.W       = math.floor(self.H * sw / sh)
    self.scale   = sh / self.H
    self.offsetX = 0
    self.offsetY = 0
end

-- Call inside love.draw() before drawing game objects
function Screen:apply()
    -- Draw scale must use physical pixel ratio
    local os  = love.system and love.system.getOS() or ""
    local dpi = (os == "Web") and (love.graphics.getDPIScale() or 1) or 1
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale * dpi, self.scale * dpi)
end

-- No letterbox bars needed: canvas always fills the full screen
function Screen:drawBars() end

-- Convert real window coords (mouse, touch) → logical game coords
-- scale is computed from CSS pixels, mouse coords are CSS pixels: plain divide
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
