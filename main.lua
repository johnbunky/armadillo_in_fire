local Ball = require('src.ball')
local Fire = require('src.fire')
local Stain = require('src.stain')
local Physics = require('src.physics')
local Audio = require('src.audio')
local UI = require('src.ui')
local Menu = require('src.menu')

-- Global game state
local gameState = {}
local audio
local menu
local currentState = "menu"  -- Can be: "menu", "playing", "paused", "game_over"

function love.load()
    -- Initialize menu system
    menu = Menu:new()
    
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
    
    -- Apply initial settings
    local settings = menu:getSettings()
    love.audio.setVolume(settings.masterVolume)
    if settings.fullscreen then
        love.window.setFullscreen(true)
    end
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
    local strategy = "chase"  -- change to: "block", "cluster", "wait"
    
    local predictionTime = 0.28
    local predictedX = math.max(50, math.min(love.graphics.getWidth()-50,
        self.playerBall.x + self.playerBall.vx * predictionTime))
    local predictedY = math.max(50, math.min(love.graphics.getHeight()-50,
        self.playerBall.y + self.playerBall.vy * predictionTime))

    local spawnX, spawnY
    local angle = math.random() * 2 * math.pi

    if strategy == "chase" then
        -- tight, close to predicted — current behavior
        local d = 65
        spawnX = predictedX + math.cos(angle) * d
        spawnY = predictedY + math.sin(angle) * d

    elseif strategy == "block" then
        -- between player and nearest corner
        local cx = self.playerBall.x < 400 and 0 or 800
        local cy = self.playerBall.y < 300 and 0 or 600
        spawnX = (predictedX + cx) * 0.5
        spawnY = (predictedY + cy) * 0.5

    elseif strategy == "cluster" then
        -- near existing fires if any, else random
        if #self.fires > 0 then
            local f = self.fires[math.random(#self.fires)]
            spawnX = f.x + (math.random()-0.5) * 80
            spawnY = f.y + (math.random()-0.5) * 80
        else
            spawnX = predictedX + math.cos(angle) * 65
            spawnY = predictedY + math.sin(angle) * 65
        end

    elseif strategy == "wait" then
        -- far from player, random side of screen
        local d = 200
        spawnX = predictedX + math.cos(angle) * d
        spawnY = predictedY + math.sin(angle) * d
    end

    spawnX = math.max(30, math.min(love.graphics.getWidth()-30,  spawnX))
    spawnY = math.max(30, math.min(love.graphics.getHeight()-30, spawnY))

    table.insert(self.fires, Fire:new(spawnX, spawnY, 15, {1, 0.3, 0}))
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
            audio:playFireExtinguish()  -- Using fire extinguish sound
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
    if currentState == "menu" then
        menu:update(dt)
    elseif currentState == "playing" then
        -- Check for game over
        if gameState.playerBall:isDead() then
            currentState = "game_over"
            menu:showGameOver()
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
    elseif currentState == "paused" then
        menu:update(dt)
    elseif currentState == "game_over" then
        menu:update(dt)
    end
end

function love.draw()
    if currentState == "playing" or currentState == "paused" then
        -- Draw game world
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
        
        -- Draw menu overlay if paused
        if currentState == "paused" then
            menu:draw()
        end
    elseif currentState == "menu" or currentState == "game_over" then
        -- Draw menu
        menu:draw()
    end
end

function love.keypressed(key)
    if currentState == "menu" or currentState == "paused" or currentState == "game_over" then
        local menuAction = menu:keypressed(key)
        
        if menuAction == "start_game" then
            currentState = "playing"
            gameState:restart()
        elseif menuAction == "resume" then
            currentState = "playing"
        elseif menuAction == "restart" then
            currentState = "playing"
            gameState:restart()
        end
        
    elseif currentState == "playing" then
        -- Game controls
        if key == "p" or key == "pause" then
            currentState = "paused"
            menu:showPause()
        elseif key == "escape" then
            currentState = "menu"
            menu:setMenu("main")
        elseif key == "m" then
            audio:toggle()
        elseif key == "=" or key == "+" then
            audio:setVolume(audio.volume + 0.1)
        elseif key == "-" or key == "_" then
            audio:setVolume(audio.volume - 0.1)
        end
    end
end
