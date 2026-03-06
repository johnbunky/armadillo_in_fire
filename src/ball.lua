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
    
    return ball
end

function Ball:update(dt)
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
    
    -- Bounce reduction factor for realistic physics
    local bounceReduction = 0.7
    
    -- Keep ball within screen bounds with reflection
    if self.x - self.radius < 0 then
        self.x = self.radius
        self.vx = -self.vx * bounceReduction
    elseif self.x + self.radius > love.graphics.getWidth() then
        self.x = love.graphics.getWidth() - self.radius
        self.vx = -self.vx * bounceReduction
    end
    
    if self.y - self.radius < 0 then
        self.y = self.radius
        self.vy = -self.vy * bounceReduction
    elseif self.y + self.radius > love.graphics.getHeight() then
        self.y = love.graphics.getHeight() - self.radius
        self.vy = -self.vy * bounceReduction
    end
end

function Ball:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Ball