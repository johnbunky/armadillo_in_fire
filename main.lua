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
        ball.vx = 0  -- velocity x
        ball.vy = 0  -- velocity y
        
        return ball
    end
    
    function Ball:update(dt)
        -- Update position based on velocity
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
        
        -- Keep ball within screen bounds
        if self.x - self.radius < 0 then
            self.x = self.radius
        elseif self.x + self.radius > love.graphics.getWidth() then
            self.x = love.graphics.getWidth() - self.radius
        end
        
        if self.y - self.radius < 0 then
            self.y = self.radius
        elseif self.y + self.radius > love.graphics.getHeight() then
            self.y = love.graphics.getHeight() - self.radius
        end
    end
    
    function Ball:draw()
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    
    -- Create player ball (blue)
    playerBall = Ball:new(150, 300, 25, {0.3, 0.7, 1})
    
    -- Create pushable ball (red)
    pushableBall = Ball:new(500, 300, 25, {1, 0.3, 0.3})
    
    -- Player movement speed
    playerSpeed = 300
end

function love.update(dt)
    if gameState == "playing" then
        -- Player ball keyboard controls
        playerBall.vx = 0
        playerBall.vy = 0
        
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            playerBall.vx = -playerSpeed
        end
        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            playerBall.vx = playerSpeed
        end
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            playerBall.vy = -playerSpeed
        end
        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            playerBall.vy = playerSpeed
        end
        
        -- Update both balls
        playerBall:update(dt)
        pushableBall:update(dt)
    end
end

function love.draw()
    -- Clear screen with dark background
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    if gameState == "playing" then
        -- Draw both balls
        playerBall:draw()
        pushableBall:draw()
        
        -- Draw instructions
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Use WASD or Arrow Keys to move the blue ball", 10, 10)
        love.graphics.print("Push the red ball around!", 10, 30)
        love.graphics.print("Press ESC to quit", 10, 50)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end