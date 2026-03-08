local Fire = {}
Fire.__index = Fire

function Fire:new(x, y, radius, color)
    local fire = {}
    setmetatable(fire, Fire)
    
    fire.x = x or 0
    fire.y = y or 0
    fire.radius = radius or 10
    fire.baseColor = color or {1, 0.5, 0}  -- orange by default
    fire.color = {fire.baseColor[1], fire.baseColor[2], fire.baseColor[3]}
    
    -- Flickering animation properties
    fire.flickerTimer = 0
    fire.flickerSpeed = 8  -- How fast the flicker cycles
    fire.flickerIntensity = 0.3  -- How much the color varies
    fire.sizeVariation = 0.2  -- How much the size varies
    fire.currentRadius = fire.radius
    
    -- Shadow properties
    fire.shadowOffset = {x = 2, y = 3}  -- Smaller shadow offset for fires
    fire.shadowColor = {0, 0, 0, 0.25}  -- Semi-transparent black shadow, slightly lighter than balls
    fire.shadowScale = {x = 1.1, y = 0.5}  -- Shadow is wider and flatter than fire
    
    return fire
end

function Fire:update(dt)
    -- Update flicker animation
    self.flickerTimer = self.flickerTimer + dt * self.flickerSpeed
    
    -- Calculate flicker effects using sine waves with different frequencies
    local flicker1 = math.sin(self.flickerTimer) * 0.5 + 0.5
    local flicker2 = math.sin(self.flickerTimer * 1.3) * 0.5 + 0.5
    local flicker3 = math.sin(self.flickerTimer * 0.7) * 0.5 + 0.5
    
    -- Apply flicker to color (make it vary between orange and red)
    local intensity = 1 - (flicker1 * self.flickerIntensity)
    self.color[1] = math.min(1, self.baseColor[1] + flicker2 * 0.2)  -- Red component
    self.color[2] = self.baseColor[2] * intensity  -- Green component (makes it more red when dimmed)
    self.color[3] = self.baseColor[3] * (intensity * 0.5)  -- Blue component (very little blue in fire)
    
    -- Apply size variation
    local sizeFlicker = 1 + (flicker3 * self.sizeVariation - self.sizeVariation * 0.5)
    self.currentRadius = self.radius * sizeFlicker
end

function Fire:drawShadow()
    -- Draw shadow as an ellipse beneath the fire
    love.graphics.setColor(self.shadowColor[1], self.shadowColor[2], self.shadowColor[3], self.shadowColor[4])
    
    local shadowX = self.x + self.shadowOffset.x
    local shadowY = self.y + self.shadowOffset.y
    local shadowRadiusX = self.currentRadius * self.shadowScale.x
    local shadowRadiusY = self.currentRadius * self.shadowScale.y
    
    love.graphics.ellipse("fill", shadowX, shadowY, shadowRadiusX, shadowRadiusY)
end

function Fire:draw()
    -- Draw main fire circle with flickering color and size
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.currentRadius)
    
    -- Draw inner flame core (brighter center)
    local coreIntensity = 0.8 + math.sin(self.flickerTimer * 2) * 0.2
    love.graphics.setColor(1, 0.8 + coreIntensity * 0.2, coreIntensity * 0.3)
    love.graphics.circle("fill", self.x, self.y, self.currentRadius * 0.6)
    
    -- Draw flame tips (small additional circles for flame effect)
    local tipCount = 3
    for i = 1, tipCount do
        local angle = (i / tipCount) * math.pi * 2 + self.flickerTimer
        local tipDistance = self.currentRadius * 0.7
        local tipX = self.x + math.cos(angle) * tipDistance
        local tipY = self.y + math.sin(angle) * tipDistance
        local tipRadius = self.currentRadius * 0.3 * (0.8 + math.sin(self.flickerTimer * 3 + i) * 0.2)
        
        love.graphics.setColor(1, 0.6, 0.1, 0.7)
        love.graphics.circle("fill", tipX, tipY, tipRadius)
    end
end

return Fire