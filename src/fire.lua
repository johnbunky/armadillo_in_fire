local Fire = {}
Fire.__index = Fire

function Fire:new(x, y, radius, color)
    local fire = {}
    setmetatable(fire, Fire)
    
    fire.x = x or 0
    fire.y = y or 0
    fire.radius = radius or 15
    fire.baseColor = color or {1, 0.3, 0}  -- orange-red by default
    fire.color = {fire.baseColor[1], fire.baseColor[2], fire.baseColor[3]}
    
    -- Fire animation properties
    fire.flickerTime = 0
    fire.flickerSpeed = 8
    fire.flickerIntensity = 0.3
    
    -- Tracking properties
    fire.speed = 300  -- Full speed tracking
    fire.threatRadius = 89
    fire.vx = 0
    fire.vy = 0
    
    -- Shadow properties
    fire.shadowOffset = {x = 2, y = 3}
    fire.shadowColor = {0, 0, 0, 0.4}  -- Darker shadow for fire
    fire.shadowScale = {x = 1.2, y = 0.6}
    
    return fire
end

function Fire:update(dt, playerBall)
    -- Update flicker animation
    self.flickerTime = self.flickerTime + dt * self.flickerSpeed
    
    -- Create flickering effect by modifying color intensity
    local flicker = math.sin(self.flickerTime) * self.flickerIntensity + 0.7
    self.color[1] = math.min(1, self.baseColor[1] * flicker + 0.3)
    self.color[2] = math.min(1, self.baseColor[2] * flicker)
    self.color[3] = self.baseColor[3] * 0.1  -- Keep blue component low
    
    -- Track player if within threat radius
    if playerBall then
        local dx = playerBall.x - self.x
        local dy = playerBall.y - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance <= self.threatRadius and distance > 0 then
            -- Normalize direction and apply full speed
            dx = dx / distance
            dy = dy / distance
            
            self.vx = dx * self.speed
            self.vy = dy * self.speed
        else
            -- Apply friction when not tracking
            self.vx = self.vx * 0.95
            self.vy = self.vy * 0.95
            
            -- Stop very small movements
            if math.abs(self.vx) < 1 then self.vx = 0 end
            if math.abs(self.vy) < 1 then self.vy = 0 end
        end
        
        -- Update position
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
        
        -- Keep fire within screen bounds
        self.x = math.max(self.radius, math.min(love.graphics.getWidth() - self.radius, self.x))
        self.y = math.max(self.radius, math.min(love.graphics.getHeight() - self.radius, self.y))
    end
end

function Fire:drawShadow()
    -- Draw shadow as an ellipse beneath the fire
    love.graphics.setColor(self.shadowColor[1], self.shadowColor[2], self.shadowColor[3], self.shadowColor[4])
    
    local shadowX = self.x + self.shadowOffset.x
    local shadowY = self.y + self.shadowOffset.y
    local shadowRadiusX = self.radius * self.shadowScale.x
    local shadowRadiusY = self.radius * self.shadowScale.y
    
    love.graphics.ellipse("fill", shadowX, shadowY, shadowRadiusX, shadowRadiusY)
end

function Fire:draw()
    -- Draw main fire body
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- Draw inner core (brighter)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.circle("fill", self.x, self.y, self.radius * 0.6)
    
    -- Draw center hot spot
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.circle("fill", self.x, self.y, self.radius * 0.3)
end

return Fire