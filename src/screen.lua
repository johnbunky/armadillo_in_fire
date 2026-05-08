-- src/screen.lua
local Screen = {}

Screen.W       = 800
Screen.H       = 600
Screen.scale   = 1
Screen.offsetX = 0
Screen.offsetY = 0

local function getOS()
    return love.system and love.system.getOS() or ""
end

function Screen:update()
    local sw, sh
    if getOS() == "Web" then
        local dpi = love.graphics.getDPIScale() or 1
        sw = love.graphics.getWidth()  / dpi
        sh = love.graphics.getHeight() / dpi
    else
        sw = love.graphics.getWidth()
        sh = love.graphics.getHeight()
    end
    self.H       = 600
    self.W       = math.floor(self.H * sw / sh)
    self.scale   = sh / self.H
    self.offsetX = 0
    self.offsetY = 0
end

function Screen:apply()
    local dpi = (getOS() == "Web") and (love.graphics.getDPIScale() or 1) or 1
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale * dpi, self.scale * dpi)
end

function Screen:drawBars() end

function Screen:toGame(x, y)
    -- On web mouse coords are window-relative, not canvas-relative.
    -- Subtract the canvas position within the window.
    local ox, oy = 0, 0
    if love.system and love.system.getOS() == "Web" then
        -- Canvas is centered in window by love.js
        local dpi = love.graphics.getDPIScale() or 1
        local cw  = love.graphics.getWidth()  / dpi   -- canvas CSS width
        local ch  = love.graphics.getHeight() / dpi   -- canvas CSS height
        local ww  = love.window.getDesktopDimensions and select(1, love.window.getDesktopDimensions()) or cw
        -- Use window inner size if available via love
        local sw, sh = love.window.getMode()
        ox = (sw - cw) / 2   -- won't work if getMode returns physical...
        oy = (sh - ch) / 2
    end
    return (x - ox - self.offsetX) / self.scale,
           (y - oy - self.offsetY) / self.scale
end

function Screen:clamp(x, y)
    return math.max(0, math.min(self.W, x)),
           math.max(0, math.min(self.H, y))
end

return Screen
