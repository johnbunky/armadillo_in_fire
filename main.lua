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
        -- Apply friction/damping
        local friction = 0.95
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
        
        -- Keep ball within screen bounds
        if self.x - self.radius < 0 then
            self.x = self.radius
            self.vx = 0
        elseif self.x + self.radius > love.graphics.getWidth() then
            self.x = love.graphics.getWidth() - self.radius
            self.vx = 0
        end
        
        if self.y - self.radius < 0 then
            self.y = self.radius
            self.vy = 0
        elseif self.y + self.radius > love.graphics.getHeight() then
            self.y = love.graphics.getHeight() - self.radius
            self.vy = 0
        end
    end
    
    function Ball:draw()
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    
    -- Collision detection between two balls
    function checkCollision(ball1, ball2)
        local dx = ball1.x - ball2.x
        local dy = ball1.y - ball2.y
        local distance = math.sqrt(dx * dx + dy * dy)
        return distance < (ball1.radius + ball2.radius)
    end
    
    -- Handle collision and pushing physics
    function handleCollision(ball1, ball2)
        if not checkCollision(ball1, ball2) then return end
        
        local dx = ball1.x - ball2.x
        local dy = ball1.y - ball2.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Prevent division by zero
        if distance == 0 then return end
        
        -- Normalize collision vector
        local nx = dx / distance
        local ny = dy / distance
        
        -- Separate balls to prevent overlap
        local overlap = (ball1.radius + ball2.radius) - distance
        local separation = overlap / 2
        
        ball1.x = ball1.x + nx * separation
        ball1.y = ball1.y + ny * separation
        ball2.x = ball2.x - nx * separation
        ball2.y = ball2.y - ny * separation
        
        -- Calculate relative velocity
        local rvx = ball1.vx - ball2.vx
        local rvy = ball1.vy - ball2.vy
        
        -- Calculate relative velocity in collision normal direction
        local speed = rvx * nx + rvy * ny
        
        -- Do not resolve if velocities are separating
        if speed > 0 then return end
        
        -- Calculate restitution (bounciness)
        local restitution = 0.8
        
        -- Calculate impulse scalar
        local impulse = -(1 + restitution) * speed
        local mass1 = ball1.radius * ball1.radius -- mass proportional to area
        local mass2 = ball2.radius * ball2.radius
        impulse = impulse / (1/mass1 + 1/mass2)
        
        -- Apply impulse
        local impulsex = impulse * nx
        local impulsey = impulse * ny
        
        ball1.vx = ball1.vx + impulsex / mass1
        ball1.vy = ball1.vy + impulsey / mass1
        ball2.vx = ball2.vx - impulsex / mass2
        ball2.vy = ball2.vy - impulsey / mass2
    end
    
    -- Create player ball (blue)
    playerBall = Ball:new(200, 300, 25, {0.3, 0.6, 1}, true)
    
    -- Create pushable ball (red)
    pushableBall = Ball:new(600, 300, 30, {1, 0.4, 0.4}, false)
    
    -- Player movement speed
    playerSpeed = 200
end

function love.update(dt)
    if gameState == "playing" then
        -- Player controls with smooth movement and friction
        local moving = false
        
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            playerBall.vx = -playerSpeed
            moving = true
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            playerBall.vx = playerSpeed
            moving = true
        else
            playerBall.vx = playerBall.vx * 0.9  -- Apply friction when not moving
        end
        
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            playerBall.vy = -playerSpeed
            moving = true
        elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            playerBall.vy = playerSpeed
            moving = true
        else
            playerBall.vy = playerBall.vy * 0.9  -- Apply friction when not moving
        end
        
        -- Stop very small movements for player
        if not moving then
            if math.abs(playerBall.vx) < 5 then playerBall.vx = 0 end
            if math.abs(playerBall.vy) < 5 then playerBall.vy = 0 end
        end
        
        -- Update balls
        playerBall:update(dt)
        pushableBall:update(dt)
        
        -- Handle collision between player and pushable ball
        handleCollision(playerBall, pushableBall)
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