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
    
    -- Collision detection function
    function checkCollision(ball1, ball2)
        local dx = ball2.x - ball1.x
        local dy = ball2.y - ball1.y
        local distance = math.sqrt(dx * dx + dy * dy)
        local minDistance = ball1.radius + ball2.radius
        
        return distance < minDistance, dx, dy, distance, minDistance
    end
    
    -- Physics collision response function
    function resolveCollision(ball1, ball2)
        local colliding, dx, dy, distance, minDistance = checkCollision(ball1, ball2)
        
        if colliding then
            -- Normalize collision vector
            local nx = dx / distance
            local ny = dy / distance
            
            -- Separate balls to prevent overlap
            local overlap = minDistance - distance
            local separationX = nx * overlap * 0.5
            local separationY = ny * overlap * 0.5
            
            ball1.x = ball1.x - separationX
            ball1.y = ball1.y - separationY
            ball2.x = ball2.x + separationX
            ball2.y = ball2.y + separationY
            
            -- Calculate relative velocity
            local relativeVelX = ball1.vx - ball2.vx
            local relativeVelY = ball1.vy - ball2.vy
            
            -- Velocity in collision normal direction
            local velInNormal = relativeVelX * nx + relativeVelY * ny
            
            -- Only resolve if objects are moving towards each other
            if velInNormal > 0 then
                return
            end
            
            -- Collision restitution (bounciness)
            local restitution = 0.8
            
            -- Calculate impulse
            local impulse = -(1 + restitution) * velInNormal / 2
            
            -- Apply impulse to balls
            ball1.vx = ball1.vx + impulse * nx
            ball1.vy = ball1.vy + impulse * ny
            ball2.vx = ball2.vx - impulse * nx
            ball2.vy = ball2.vy - impulse * ny
        end
    end
    
    -- Create player ball (blue)
    playerBall = Ball:new(200, 300, 25, {0.2, 0.6, 1})
    
    -- Create pushable ball (red)
    pushableBall = Ball:new(600, 300, 30, {1, 0.3, 0.3})
    
    -- Player movement speed
    playerSpeed = 300
end

function love.update(dt)
    if gameState == "playing" then
        -- Player ball movement
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            playerBall.vx = -playerSpeed
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            playerBall.vx = playerSpeed
        else
            playerBall.vx = 0
        end
        
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            playerBall.vy = -playerSpeed
        elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            playerBall.vy = playerSpeed
        else
            playerBall.vy = 0
        end
        
        -- Update ball positions
        playerBall:update(dt)
        pushableBall:update(dt)
        
        -- Handle collision between balls
        resolveCollision(playerBall, pushableBall)
    end
end

function love.draw()
    -- Clear screen with dark background
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    if gameState == "playing" then
        -- Draw balls
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