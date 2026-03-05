function love.load()
    -- Set window title
    love.window.setTitle("Two Balls - Push Game")
    
    -- Set window size
    love.window.setMode(800, 600)
    
    -- Initialize game state
    gameState = "playing"
    
    -- Create Ball class
    Ball = {}
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
        -- Check if this is a red ball
        local isRedBall = (self.color[1] == 1 and self.color[2] == 0 and self.color[3] == 0)
        
        -- Apply friction/damping only to non-red balls
        local friction = 0.95
        if not self.isPlayer and not isRedBall then
            self.vx = self.vx * friction
            self.vy = self.vy * friction
            
            -- Stop very small movements
            if math.abs(self.vx) < 1 then self.vx = 0 end
            if math.abs(self.vy) < 1 then self.vy = 0 end
        end
        
        -- Update position based on velocity
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
        
        -- Handle screen bounds
        if self.x - self.radius < 0 then
            self.x = self.radius
            if isRedBall then
                self.vx = -self.vx * 0.8  -- Reflect and lose 20% speed
            else
                self.vx = 0
            end
        elseif self.x + self.radius > love.graphics.getWidth() then
            self.x = love.graphics.getWidth() - self.radius
            if isRedBall then
                self.vx = -self.vx * 0.8  -- Reflect and lose 20% speed
            else
                self.vx = 0
            end
        end
        
        if self.y - self.radius < 0 then
            self.y = self.radius
            if isRedBall then
                self.vy = -self.vy * 0.8  -- Reflect and lose 20% speed
            else
                self.vy = 0
            end
        elseif self.y + self.radius > love.graphics.getHeight() then
            self.y = love.graphics.getHeight() - self.radius
            if isRedBall then
                self.vy = -self.vy * 0.8  -- Reflect and lose 20% speed
            else
                self.vy = 0
            end
        end
    end
    
    function Ball:draw()
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
end