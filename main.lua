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
        -- Apply friction/damping - less aggressive for better responsiveness
        local friction = 0.995
        if not self.isPlayer then
            self.vx = self.vx * friction
            self.vy = self.vy * friction
            
            -- Stop very small movements - lower threshold
            if math.abs(self.vx) < 2 then self.vx = 0 end
            if math.abs(self.vy) < 2 then self.vy = 0 end
        end
        
        -- Update position based on velocity
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
        
        -- Keep ball within screen bounds
        if self.x - self.radius < 0 then
            self.x = self.radius
            if self.vx < 0 then self.vx = 0 end
        elseif self.x + self.radius > love.graphics.getWidth() then
            self.x = love.graphics.getWidth() - self.radius
            if self.vx > 0 then self.vx = 0 end
        end
        
        if self.y - self.radius < 0 then
            self.y = self.radius
            if self.vy < 0 then self.vy = 0 end
        elseif self.y + self.radius > love.graphics.getHeight() then
            self.y = love.graphics.getHeight() - self.radius
            if self.vy > 0 then self.vy = 0 end
        end
    end
    
    function Ball:draw()
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    
    -- Collision detection function
    function checkCollision(ball1, ball2)
        local dx = ball1.x - ball2.x
        local dy = ball1.y - ball2.y
        local distance = math.sqrt(dx * dx + dy * dy)
        return distance < (ball1.radius + ball2.radius)
    end
    
    -- Physics response for ball collisions
    function resolveCollision(ball1, ball2)
        local dx = ball1.x - ball2.x
        local dy = ball1.y - ball2.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Prevent division by zero
        if distance == 0 then
            dx, dy = 1, 0
            distance = 1
        end
        
        -- Normalize collision vector
        local nx = dx / distance
        local ny = dy / distance
        
        -- Separate the balls
        local overlap = (ball1.radius + ball2.radius) - distance
        local separation = overlap / 2
        
        ball1.x = ball1.x + nx * separation
        ball1.y = ball1.y + ny * separation
        ball2.x = ball2.x - nx * separation
        ball2.y = ball2.y - ny * separation
        
        -- Calculate relative velocity
        local dvx = ball1.vx - ball2.vx
        local dvy = ball1.vy - ball2.vy
        
        -- Calculate relative velocity along collision normal
        local speed = dvx * nx + dvy * ny
        
        -- Only resolve if objects are moving towards each other
        if speed < 0 then
            return
        end
        
        -- Increased push force for more responsive interaction
        local pushForce = 800
        
        if ball1.isPlayer then
            -- Player pushing the other ball
            ball2.vx = ball2.vx + nx * pushForce
            ball2.vy = ball2.vy + ny * pushForce
            -- Player gets slight pushback
            ball1.vx = ball1.vx - nx * 50
            ball1.vy = ball1.vy - ny * 50
        elseif ball2.isPlayer then
            -- Player pushing the other ball
            ball1.vx = ball1.vx - nx * pushForce
            ball1.vy = ball1.vy - ny * pushForce
            -- Player gets slight pushback
            ball2.vx = ball2.vx + nx * 50
            ball2.vy = ball2.vy + ny * 50
        end
    end
    
    -- Create player ball (blue)
    playerBall = Ball:new(200, 300, 25, {0.2, 0.6, 1}, true)
    
    -- Create pushable ball (red)
    pushableBall = Ball:new(500, 300, 25, {1, 0.4, 0.4}, false)
end

function love.update(dt)
    if gameState == "playing" then
        -- Player movement - increased speed for better responsiveness
        local speed = 400
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            playerBall.vx = -speed
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            playerBall.vx = speed
        else
            playerBall.vx = 0
        end
        
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            playerBall.vy = -speed
        elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            playerBall.vy = speed
        else
            playerBall.vy = 0
        end
        
        -- Update balls
        playerBall:update(dt)
        pushableBall:update(dt)
        
        -- Check collision and resolve
        if checkCollision(playerBall, pushableBall) then
            resolveCollision(playerBall, pushableBall)
        end
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
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print("Player Ball (Blue): WASD or Arrow Keys to move", 10, 10)
        love.graphics.print("Push the red ball around!", 10, 30)
        love.graphics.print("Press ESC to quit", 10, 50)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end