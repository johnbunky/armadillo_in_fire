local Stain = {}
Stain.__index = Stain

function Stain:new(x, y, radius)
    local stain = {}
    setmetatable(stain, Stain)
    
    stain.x = x or 0
    stain.y = y or 0
    stain.radius = radius or 20
    stain.maxRadius = radius or 20
    stain.alpha = 1.0
    stain.dissolveTime = 0
    stain.maxDissolveTime = 3.0  -- 3 seconds to fully dissolve
    stain.baseColor = {0.3, 0.2, 0.1}  -- Brown stain color
    
    return stain
end

function Stain:update(dt)
    -- Update dissolve animation
    self.dissolveTime = self.dissolveTime + dt
    
    -- Calculate fade progress (0 to 1)
    local fadeProgress = self.dissolveTime / self.maxDissolveTime
    
    if fadeProgress >= 1.0 then
        return true  -- Stain is fully dissolved
    end
    
    -- Update alpha and radius for dissolving effect
    self.alpha = 1.0 - fadeProgress
    self.radius = self.maxRadius * (1.0 - fadeProgress * 0.5)  -- Shrink as it dissolves
    
    return false  -- Stain still visible
end

function Stain:draw()
    if self.alpha <= 0 then return end
    
    -- Calculate ellipse dimensions with 1.5:0.6 ratio (wider than tall)
    local radiusX = self.radius * 1.5
    local radiusY = self.radius * 0.6
    
    -- Draw stain with fading alpha
    love.graphics.setColor(self.baseColor[1], self.baseColor[2], self.baseColor[3], self.alpha)
    love.graphics.ellipse("fill", self.x, self.y, radiusX, radiusY)
    
    -- Draw slightly darker center
    love.graphics.setColor(self.baseColor[1] * 0.7, self.baseColor[2] * 0.7, self.baseColor[3] * 0.7, self.alpha * 0.8)
    love.graphics.ellipse("fill", self.x, self.y, radiusX * 0.6, radiusY * 0.6)
end

return Stain