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
    
    -- Handle boundary collisions with audio
    local Physics = require("src/physics")
    Physics.handleBoundaryCollision(self, audio)
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
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Ball