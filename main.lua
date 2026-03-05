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
    
    function Ball:new(x, y, radius, color)
        local ball = {}
        setmetatable(ball, Ball)
        
        ball.x = x or 0
        ball.y = y or 0
        ball.radius = radius or 20
        ball.color = color or {1, 1, 1}  -- white by default
        
        return ball
    end
    
    function Ball:draw()
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.circle("fill", self.x, self.y, self.radius)
        
        -- Draw outline
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", self.x, self.y, self.radius)
    end
    
    -- Test balls for demonstration
    testBall1 = Ball:new(200, 300, 25, {0.8, 0.2, 0.2})  -- red ball
    testBall2 = Ball:new(600, 300, 30, {0.2, 0.8, 0.2})  -- green ball
end

function love.update(dt)
    -- Game update logic will go here
end

function love.draw()
    -- Clear screen with dark background
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    -- Draw test balls
    testBall1:draw()
    testBall2:draw()
    
    -- Draw game title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Two Balls - Push Game", 10, 10)
end