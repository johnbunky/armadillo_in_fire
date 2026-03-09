local Ball = {}
Ball.__index = Ball

function Ball:new(x, y, radius, color, isPlayer)
    local ball = {}
    setmetatable(ball, Ball)
    
    ball.x = x or 0
    ball.y = y or 0
    ball.radius = radius or 20
    ball.color = color or {1, 1, 1}  -- white by default
    ball.vx = 0  -- velocity x
    ball.vy = 0  -- velocity y
    ball.isPlayer = isPlayer or false
    
    -- Player-specific properties
    if ball.isPlayer then
        ball.maxHealth = 100
        ball.health = ball.maxHealth
        ball.damageTimer = 0
        ball.damageInterval = 0.5  -- Take damage every 0.5 seconds when touching fire
        ball.fireResistanceTime = 0  -- Brief immunity after taking damage
        ball.fireResistanceDuration = 0.2  -- 0.2 seconds of immunity
        ball.regenRate = 10  -- Health regeneration per second when not taking damage
        ball.regenDelay = 2.0  -- Delay before regeneration starts after damage
        ball.timeSinceLastDamage = 0
    end
    
    -- Shadow properties
    ball.shadowOffset = {x = 3, y = 5}  -- Shadow offset from ball position
    ball.shadowColor = {0, 0, 0, 0.3}   -- Semi-transparent black shadow
    ball.shadowScale = {x = 1.2, y = 0.6}  -- Shadow is wider and flatter than ball
    
    return ball
end

function Ball:update(dt, audio)
    -- Apply friction/damping
    local friction = 0.98
    if not self.isPlayer then
        self.vx = self.vx * friction
        self.vy = self.vy * friction
        
        -- Stop very small movements
        if math.abs(self.vx) < 1 then self.vx = 0 end
        if math.abs(self.vy) < 1 then self.vy = 0 end
    end
    
    -- Update position based on velocity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Update player-specific properties
    if self.isPlayer then
        -- Update timers
        self.damageTimer = self.damageTimer + dt
        self.fireResistanceTime = math.max(0, self.fireResistanceTime - dt)
        self.timeSinceLastDamage = self.timeSinceLastDamage + dt
        
        -- Health regeneration
        if self.timeSinceLastDamage >= self.regenDelay and self.health < self.maxHealth then
            self.health = math.min(self.maxHealth, self.health + self.regenRate * dt)
        end
    end
    
    -- Handle boundary collisions with audio
    local Physics = require("src/physics")
    Physics.handleBoundaryCollision(self, audio)
end

function Ball:takeDamage(amount, audio)
    if not self.isPlayer or self.fireResistanceTime > 0 then
        return false  -- Not player or still resistant
    end
    
    self.health = math.max(0, self.health - amount)
    self.fireResistanceTime = self.fireResistanceDuration
    self.timeSinceLastDamage = 0
    
    -- Play fire damage sound
    if audio then
        audio:playFireDamage()  -- Using fire damage sound
    end
    
    return true  -- Damage was applied
end

function Ball:getHealthPercentage()
    if not self.isPlayer then
        return 1
    end
    return self.health / self.maxHealth
end

function Ball:isDead()
    return self.isPlayer and self.health <= 0
end

function Ball:drawShadow()
    -- Draw shadow as an ellipse beneath the ball
    love.graphics.setColor(self.shadowColor[1], self.shadowColor[2], self.shadowColor[3], self.shadowColor[4])
    
    local shadowX = self.x + self.shadowOffset.x
    local shadowY = self.y + self.shadowOffset.y
    local shadowRadiusX = self.radius * self.shadowScale.x
    local shadowRadiusY = self.radius * self.shadowScale.y
    
    love.graphics.ellipse("fill", shadowX, shadowY, shadowRadiusX, shadowRadiusY)
end

function Ball:draw()
    -- For player ball, show health by changing color intensity when damaged
    if self.isPlayer then
        local healthPercent = self:getHealthPercentage()
        local r = self.color[1]
        local g = self.color[2] * healthPercent  -- Reduce green as health decreases
        local b = self.color[3]
        love.graphics.setColor(r, g, b)
    else
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    end
    
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- Draw damage indicator for player (red tint when taking damage)
    if self.isPlayer and self.fireResistanceTime > 0 then
        love.graphics.setColor(1, 0.3, 0.3, 0.5)
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
end

return Ball