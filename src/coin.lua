local Coin = {}
Coin.__index = Coin

function Coin:new(x, y, radius, color)
    local coin = {}
    setmetatable(coin, Coin)
    
    coin.x = x or 0
    coin.y = y or 0
    coin.radius = radius or 10
    coin.color = color or {1, 1, 0}  -- yellow by default
    
    -- Shadow properties
    coin.shadowOffset = {x = 2, y = 3}  -- Smaller shadow offset for coins
    coin.shadowColor = {0, 0, 0, 0.25}  -- Semi-transparent black shadow, slightly lighter than balls
    coin.shadowScale = {x = 1.1, y = 0.5}  -- Shadow is wider and flatter than coin
    
    -- Movement behavior properties
    coin.vx = 0
    coin.vy = 0
    coin.speed = 20
    coin.playerDetectionRange = 150
    coin.redBallAvoidanceRange = 130
    coin.repositionTimer = 0
    coin.repositionDelay = math.random(2, 4)  -- Random delay between 2-4 seconds
    
    return coin
end

function Coin:update(dt, playerBall, redBall)
    -- Update reposition timer
    self.repositionTimer = self.repositionTimer + dt
    
    -- Reset velocity
    self.vx = 0
    self.vy = 0
    
    -- Check if player is within detection range
    local distToPlayer = math.sqrt((self.x - playerBall.x)^2 + (self.y - playerBall.y)^2)
    local playerDetected = distToPlayer <= self.playerDetectionRange
    
    -- Check distance to red ball
    local distToRedBall = math.sqrt((self.x - redBall.x)^2 + (self.y - redBall.y)^2)
    local needsToAvoidRedBall = distToRedBall < self.redBallAvoidanceRange
    
    -- Apply movement behaviors
    if playerDetected or needsToAvoidRedBall or self.repositionTimer >= self.repositionDelay then
        -- Avoid red ball (highest priority)
        if needsToAvoidRedBall then
            local dirX = (self.x - redBall.x) / distToRedBall
            local dirY = (self.y - redBall.y) / distToRedBall
            self.vx = self.vx + dirX * self.speed * 1.5  -- Stronger avoidance
            self.vy = self.vy + dirY * self.speed * 1.5
        end
        
        -- React to player when detected
        if playerDetected then
            -- Move away from player
            local dirX = (self.x - playerBall.x) / distToPlayer
            local dirY = (self.y - playerBall.y) / distToPlayer
            self.vx = self.vx + dirX * self.speed * 0.8
            self.vy = self.vy + dirY * self.speed * 0.8
        end
        
        -- Random repositioning every few seconds
        if self.repositionTimer >= self.repositionDelay then
            local randomAngle = math.random() * 2 * math.pi
            local randomStrength = math.random(0.5, 1.0)
            self.vx = self.vx + math.cos(randomAngle) * self.speed * randomStrength
            self.vy = self.vy + math.sin(randomAngle) * self.speed * randomStrength
            
            -- Reset timer with new random delay
            self.repositionTimer = 0
            self.repositionDelay = math.random(2, 4)
        end
        
        -- Apply movement
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
        
        -- Keep coins within screen bounds
        self.x = math.max(self.radius, math.min(self.x, love.graphics.getWidth() - self.radius))
        self.y = math.max(self.radius, math.min(self.y, love.graphics.getHeight() - self.radius))
    end
end

function Coin:drawShadow()
    -- Draw shadow as an ellipse beneath the coin
    love.graphics.setColor(self.shadowColor[1], self.shadowColor[2], self.shadowColor[3], self.shadowColor[4])
    
    local shadowX = self.x + self.shadowOffset.x
    local shadowY = self.y + self.shadowOffset.y
    local shadowRadiusX = self.radius * self.shadowScale.x
    local shadowRadiusY = self.radius * self.shadowScale.y
    
    love.graphics.ellipse("fill", shadowX, shadowY, shadowRadiusX, shadowRadiusY)
end

function Coin:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Coin