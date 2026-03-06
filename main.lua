function love.conf(t)
    t.title = "Two Balls - Push Game"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
end

function love.load()
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
    
    -- Create Coin class
    Coin = {}
    Coin.__index = Coin
    
    function Coin:new(x, y, radius, color)
        local coin = {}
        setmetatable(coin, Coin)
        
        coin.x = x or 0
        coin.y = y or 0
        coin.radius = radius or 10
        coin.color = color or {1, 1, 0}  -- yellow by default
        
        return coin
    end
    
    function Coin:draw()
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
    
    -- Check collision between ball and coin
    function checkCoinCollision(ball, coin)
        local dx = ball.x - coin.x
        local dy = ball.y - coin.y
        local distance = math.sqrt(dx * dx + dy * dy)
        return distance < (ball.radius + coin.radius)
    end
    
    -- Handle collision physics
    function handleCollision(playerBall, pushBall)
        if not checkCollision(playerBall, pushBall) then
            return
        end
        
        -- Calculate collision direction
        local dx = pushBall.x - playerBall.x
        local dy = pushBall.y - playerBall.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Avoid division by zero
        if distance == 0 then
            dx, dy = 1, 0
            distance = 1
        end
        
        -- Normalize direction
        dx = dx / distance
        dy = dy / distance
        
        -- Separate balls to prevent overlap
        local overlap = (playerBall.radius + pushBall.radius) - distance
        pushBall.x = pushBall.x + dx * overlap * 0.6
        pushBall.y = pushBall.y + dy * overlap * 0.4
        playerBall.x = playerBall.x - dx * overlap * 0.4
        playerBall.y = playerBall.y - dy * overlap * 0.4
        
        -- Transfer momentum (player ball pushes the other)
        local pushForce = 200
        pushBall.vx = pushBall.vx + dx * pushForce
        pushBall.vy = pushBall.vy + dy * pushForce
    end
    
    -- Spawn coins at random positions
    function spawnCoins(count)
        coins = {}
        for i = 1, count do
            local x, y
            local validPosition = false
            local attempts = 0
            
            -- Try to find a valid position that doesn't overlap with balls
            while not validPosition and attempts < 50 do
                x = math.random(50, love.graphics.getWidth() - 50)
                y = math.random(50, love.graphics.getHeight() - 50)
                
                -- Check distance from both balls
                local distToPlayer = math.sqrt((x - playerBall.x)^2 + (y - playerBall.y)^2)
                local distToPush = math.sqrt((x - pushableBall.x)^2 + (y - pushableBall.y)^2)
                
                if distToPlayer > 80 and distToPush > 80 then
                    validPosition = true
                end
                attempts = attempts + 1
            end
            
            -- Create coin at found position (or random if no valid position found)
            table.insert(coins, Coin:new(x, y, 12, {1, 0.8, 0}))
        end
    end
    
    -- Create the two balls
    playerBall = Ball:new(200, 300, 25, {0.2, 0.8, 1}, true)  -- Blue player ball
    pushableBall = Ball:new(500, 300, 30, {1, 0.3, 0.3}, false)  -- Red pushable ball
    
    -- Initialize coins
    spawnCoins(5)
end

function love.update(dt)
    if gameState == "playing" then
        -- Player ball movement
        local speed = 300
        playerBall.vx = 0
        playerBall.vy = 0
        
        if love.keyboard.isDown("left", "a") then
            playerBall.vx = -speed
        end
        if love.keyboard.isDown("right", "d") then
            playerBall.vx = speed
        end
        if love.keyboard.isDown("up", "w") then
            playerBall.vy = -speed
        end
        if love.keyboard.isDown("down", "s") then
            playerBall.vy = speed
        end
        
        -- Update balls
        playerBall:update(dt)
        pushableBall:update(dt)
        
        -- Handle collision between balls
        handleCollision(playerBall, pushableBall)
        
        -- Check collision between red ball and coins
        for i = #coins, 1, -1 do
            if checkCoinCollision(pushableBall, coins[i]) then
                -- Remove coin when red ball touches it
                table.remove(coins, i)
            end
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
        
        -- Draw coins
        for i, coin in ipairs(coins) do
            coin:draw()
        end
        
        -- Draw instructions
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Use WASD or Arrow Keys to move the blue ball", 10, 10)
        love.graphics.print("Push the red ball to collect yellow coins!", 10, 30)
        love.graphics.print("Press ESC to quit", 10, 50)
        love.graphics.print("Coins remaining: " .. #coins, 10, 70)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end