local Ball = require('src.ball')
local Fire = require('src.fire')
local Stain = require('src.stain')
local Physics = require('src.physics')
local Audio = require('src.audio')
local UI = require('src.ui')

-- Global game state
local gameState = {}
local audio

function love.load()
    -- Initialize audio system
    audio = Audio
    audio:init()
    
    -- Initialize game state
    gameState.state = "playing"
    gameState.gameOverTime = 0
    gameState.gameOverDelay = 2.0
    gameState.nextFireSpawn = 2.0  -- First fire spawns after 2 seconds
    gameState.fireSpawnInterval = 1.95  -- Base spawn interval
    gameState.maxFires = 5  -- Maximum fires on screen
    
    -- Create balls
    gameState.playerBall = Ball:new(100, 300, 25, {0.2, 0.8, 0.2}, true)  -- Green player ball
    gameState.pushableBall = Ball:new(400, 300, 25, {0.8, 0.2, 0.2}, false)  -- Red pushable ball
    
    -- Initialize arrays
    gameState.fires = {}
    gameState.stains = {}
    
    -- Set window properties
    love.graphics.setBackgroundColor(0.6, 0.8, 0.4)  -- Light green grass-like background
end

function gameState:update(dt)
    -- Update fire spawn timer
    self.nextFireSpawn = self.nextFireSpawn - dt
    
    if self.nextFireSpawn <= 0 and #self.fires < self.maxFires then
        self:spawnFire()
        self.nextFireSpawn = self.fireSpawnInterval
    end
    
    -- Update fires
    for i, fire in ipairs(self.fires) do
        fire:update(dt, self.playerBall)
    end
    
    -- Update and remove dissolved stains
    for i = #self.stains, 1, -1 do
        if self.stains[i]:update(dt) then
            table.remove(self.stains, i)
        end
    end
end

function gameState:spawnFire()
    -- Predict player position
    local predictionTime = 0.28
    local predictedX = self.playerBall.x + self.playerBall.vx * predictionTime
    local predictedY = self.playerBall.y + self.playerBall.vy * predictionTime
    
    -- Keep predicted position within bounds
    predictedX = math.max(50, math.min(love.graphics.getWidth() - 50, predictedX))
    predictedY = math.max(50, math.min(love.graphics.getHeight() - 50, predictedY))
    
    -- Calculate spawn position around predicted location
    local spawnDistance = 65
    local angle = math.random() * 2 * math.pi
    local spawnX = predictedX + math.cos(angle) * spawnDistance
    local spawnY = predictedY + math.sin(angle) * spawnDistance
    
    -- Keep spawn position within screen bounds
    spawnX = math.max(30, math.min(love.graphics.getWidth() - 30, spawnX))
    spawnY = math.max(30, math.min(love.graphics.getHeight() - 30, spawnY))
    
    -- Create new fire
    local newFire = Fire:new(spawnX, spawnY, 15, {1, 0.3, 0})
    table.insert(self.fires, newFire)
end

function gameState:extinguishFire(fireIndex, audio)
    if self.fires[fireIndex] then
        local fire = self.fires[fireIndex]
        
        -- Create stain at fire position
        local stain = Stain:new(fire.x, fire.y, fire.radius + 5)
        table.insert(self.stains, stain)
        
        -- Remove fire
        table.remove(self.fires, fireIndex)
        
        -- Play extinguish sound
        if audio then
            audio:playCoinCollect()  -- Using coin collect sound for extinguish
        end
    end
end

function gameState:restart()
    -- Reset player ball
    self.playerBall.x = 100
    self.playerBall.y = 300
    self.playerBall.vx = 0
    self.playerBall.vy = 0
    self.playerBall.health = self.playerBall.maxHealth
    self.playerBall.damageTimer = 0
    self.playerBall.fireResistanceTime = 0
    self.playerBall.timeSinceLastDamage = 0
    
    -- Reset pushable ball
    self.pushableBall.x = 400
    self.pushableBall.y = 300
    self.pushableBall.vx = 0
    self.pushableBall.vy = 0
    
    -- Clear fires and stains
    self.fires = {}
    self.stains = {}
    
    -- Reset state
    self.state = "playing"
    self.gameOverTime = 0
    self.nextFireSpawn = 2.0
end

function love.update(dt)
    if gameState.state == "playing" then
        -- Check for game over
        if gameState.playerBall:isDead() then
            gameState.state = "game_over"
            return
        end
        
        -- Update game state (handles fire respawning and stain dissolving)
        gameState:update(dt)
        
        -- Player ball movement
        local speed = 300
        gameState.playerBall.vx = 0
        gameState.playerBall.vy = 0
        
        if love.keyboard.isDown("left", "a") then
            gameState.playerBall.vx = -speed
        end
        if love.keyboard.isDown("right", "d") then
            gameState.playerBall.vx = speed
        end
        if love.keyboard.isDown("up", "w") then
            gameState.playerBall.vy = -speed
        end
        if love.keyboard.isDown("down", "s") then
            gameState.playerBall.vy = speed
        end
        
        -- Update balls with audio support
        gameState.playerBall:update(dt, audio)
        gameState.pushableBall:update(dt, audio)
        
        -- Handle collision between balls with audio
        Physics.handleCollision(gameState.playerBall, gameState.pushableBall, audio)
        
        -- Check collision between red ball and fires (extinguishing)
        for i = #gameState.fires, 1, -1 do
            if Physics.checkCoinCollision(gameState.pushableBall, gameState.fires[i]) then
                gameState:extinguishFire(i, audio)
            end
        end
        
        -- Check collision between player ball and fires (damage)
        for i, fire in ipairs(gameState.fires) do
            if Physics.checkCoinCollision(gameState.playerBall, fire) then
                if gameState.playerBall.damageTimer >= gameState.playerBall.damageInterval then
                    gameState.playerBall:takeDamage(20, audio)  -- 20 damage per hit
                    gameState.playerBall.damageTimer = 0
                end
            end
        end
    elseif gameState.state == "game_over" then
        -- Handle restart input
        if love.keyboard.isDown("r", "space", "return") then
            gameState:restart()
        end
    end
end

function love.draw()
    if gameState.state == "playing" then
        -- Draw shadows first (behind all objects) - skip fire shadows
        gameState.playerBall:drawShadow()
        gameState.pushableBall:drawShadow()
        
        -- Draw stains (on ground level)
        for i, stain in ipairs(gameState.stains) do
            stain:draw()
        end
        
        -- Draw balls
        gameState.playerBall:draw()
        gameState.pushableBall:draw()
        
        -- Draw fires
        for i, fire in ipairs(gameState.fires) do
            fire:draw()
        end
        
        -- Draw UI with audio reference
        UI.draw(gameState, audio)
    elseif gameState.state == "game_over" then
        -- Draw game over screen
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R, SPACE, or ENTER to restart", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    end
end

function love.keypressed(key)
    -- Audio controls
    if key == "m" then
        audio:toggle()
    elseif key == "=" or key == "+" then
        audio:setVolume(audio.volume + 0.1)
    elseif key == "-" or key == "_" then
        audio:setVolume(audio.volume - 0.1)
    elseif key == "escape" then
        love.event.quit()
    elseif gameState.state == "game_over" and (key == "r" or key == "space" or key == "return") then
        gameState:restart()
    end
end
