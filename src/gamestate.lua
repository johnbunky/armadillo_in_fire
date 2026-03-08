<<<<<<< HEAD
local Physics = require('src.physics')

local GameState = {}

-- Initialize game state
function GameState.init()
    GameState.balls = {}
    GameState.fires = {}
    GameState.player = {
        x = 400,
        y = 300,
        radius = 20,
        vx = 0,
        vy = 0,
        health = 100,
        maxHealth = 100
    }
    GameState.spawnTimer = 0
    GameState.fireSpawnTimer = 0
    GameState.score = 0
end

-- Add a new ball
function GameState.addBall(x, y, vx, vy, radius)
    table.insert(GameState.balls, {
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        radius = radius or 15
    })
end

-- Add a new fire
function GameState.addFire(x, y)
    table.insert(GameState.fires, {
        x = x,
        y = y,
        radius = 25,
        age = 0
    })
end

-- Update game state
function GameState.update(dt)
    -- Update player
    GameState.updatePlayer(dt)
    
    -- Update balls
    GameState.updateBalls(dt)
    
    -- Update fires
    GameState.updateFires(dt)
    
    -- Spawn new balls
    GameState.spawnTimer = GameState.spawnTimer + dt
    if GameState.spawnTimer > 2 then
        GameState.spawnBall()
        GameState.spawnTimer = 0
    end
    
    -- Spawn new fires
    GameState.fireSpawnTimer = GameState.fireSpawnTimer + dt
    if GameState.fireSpawnTimer > 3 then
        GameState.spawnFire()
        GameState.fireSpawnTimer = 0
    end
    
    -- Check collisions
    GameState.checkCollisions()
    GameState.checkPlayerFireDamage()
end

function GameState.checkPlayerFireDamage()
    for _, fire in ipairs(GameState.fires) do
        if Physics.checkFireCollision(GameState.player, fire) then
            GameState.player.health = GameState.player.health - 20
            if GameState.player.health <= 0 then
                GameState.player.health = 0
                -- Game over logic here
            end
        end
    end
end

function GameState.updatePlayer(dt)
    -- Player movement will be handled by input
    -- Apply basic physics
    GameState.player.x = GameState.player.x + GameState.player.vx * dt
    GameState.player.y = GameState.player.y + GameState.player.vy * dt
    
    -- Apply friction
    GameState.player.vx = GameState.player.vx * 0.95
    GameState.player.vy = GameState.player.vy * 0.95
    
    -- Keep player in bounds
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    if GameState.player.x < GameState.player.radius then
        GameState.player.x = GameState.player.radius
    elseif GameState.player.x > screenWidth - GameState.player.radius then
        GameState.player.x = screenWidth - GameState.player.radius
    end
    
    if GameState.player.y < GameState.player.radius then
        GameState.player.y = GameState.player.radius
    elseif GameState.player.y > screenHeight - GameState.player.radius then
        GameState.player.y = screenHeight - GameState.player.radius
    end
end

function GameState.updateBalls(dt)
    for i = #GameState.balls, 1, -1 do
        local ball = GameState.balls[i]
        
        -- Update position
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt
        
        -- Bounce off walls
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        if ball.x < ball.radius or ball.x > screenWidth - ball.radius then
            ball.vx = -ball.vx
            ball.x = math.max(ball.radius, math.min(screenWidth - ball.radius, ball.x))
        end
        
        if ball.y < ball.radius or ball.y > screenHeight - ball.radius then
            ball.vy = -ball.vy
            ball.y = math.max(ball.radius, math.min(screenHeight - ball.radius, ball.y))
        end
    end
end

function GameState.updateFires(dt)
    for i = #GameState.fires, 1, -1 do
        local fire = GameState.fires[i]
        
        fire.age = fire.age + dt
        
        -- Remove old fires
        if fire.age > 10 then
            table.remove(GameState.fires, i)
        end
    end
end

function GameState.spawnBall()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local x = math.random(50, screenWidth - 50)
    local y = math.random(50, screenHeight - 50)
    local vx = math.random(-200, 200)
    local vy = math.random(-200, 200)
    
    GameState.addBall(x, y, vx, vy)
end

function GameState.spawnFire()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local x = math.random(50, screenWidth - 50)
    local y = math.random(50, screenHeight - 50)
    
    GameState.addFire(x, y)
end

function GameState.checkCollisions()
    -- Check ball-ball collisions
    for i = 1, #GameState.balls do
        for j = i + 1, #GameState.balls do
            if Physics.checkCollision(GameState.balls[i], GameState.balls[j]) then
                Physics.resolveCollision(GameState.balls[i], GameState.balls[j])
            end
        end
    end
    
    -- Check player-ball collisions
    for _, ball in ipairs(GameState.balls) do
        if Physics.checkCollision(GameState.player, ball) then
            Physics.resolveCollision(GameState.player, ball)
        end
    end
=======
local Ball = require("src/ball")
local Fire = require("src/fire")
local Stain = require("src/stain")

local GameState = {}

function GameState:new()
    local gameState = {}
    setmetatable(gameState, {__index = self})
    
    gameState.state = "playing"  -- Can be "playing" or "game_over"
    gameState.playerBall = nil
    gameState.pushableBall = nil
    gameState.fires = {}
    gameState.stains = {}
    gameState.maxFires = 3
    gameState.respawnTimer = 0
    gameState.respawnDelay = 1.95  -- 1.95 seconds delay before respawning
    
    return gameState
end

function GameState:init()
    -- Create the two balls
    self.playerBall = Ball:new(200, 300, 25, {0.2, 0.8, 1}, true)  -- Blue player ball
    self.pushableBall = Ball:new(500, 300, 30, {1, 0.3, 0.3}, false)  -- Red pushable ball
    
    -- Initialize fires
    self:spawnFires(self.maxFires)
end

function GameState:update(dt)
    if self.state == "playing" then
        self:updatePlaying(dt)
        
        -- Check for game over condition
        if self.playerBall:isDead() then
            self.state = "game_over"
        end
    elseif self.state == "game_over" then
        self:updateGameOver(dt)
    end
end

function GameState:updatePlaying(dt)
    -- Update fires
    for i, fire in ipairs(self.fires) do
        fire:update(dt, self.playerBall)
    end
    
    -- Update stains and remove dissolved ones
    for i = #self.stains, 1, -1 do
        local dissolved = self.stains[i]:update(dt)
        if dissolved then
            table.remove(self.stains, i)
        end
    end
    
    -- Update respawn timer
    if #self.fires < self.maxFires then
        self.respawnTimer = self.respawnTimer + dt
        
        -- Check if it's time to spawn a new fire
        if self.respawnTimer >= self.respawnDelay then
            self:spawnSingleFire()
            self.respawnTimer = 0
        end
    else
        -- Reset timer when we have max fires
        self.respawnTimer = 0
    end
end

function GameState:updateGameOver(dt)
    -- Handle restart input - check for common restart keys
    if love.keyboard.isDown("r") or love.keyboard.isDown("space") or love.keyboard.isDown("return") then
        self:restart()
    end
end

function GameState:restart()
    -- Reset game state
    self.state = "playing"
    
    -- Recreate player ball with full health
    self.playerBall = Ball:new(200, 300, 25, {0.2, 0.8, 1}, true)
    
    -- Reset pushable ball position
    self.pushableBall = Ball:new(500, 300, 30, {1, 0.3, 0.3}, false)
    
    -- Clear and respawn fires
    self.fires = {}
    self.stains = {}
    self:spawnFires(self.maxFires)
    
    -- Reset timers
    self.respawnTimer = 0
end

function GameState:isGameOver()
    return self.state == "game_over"
end

-- Predict player position 0.28 seconds ahead
function GameState:predictPlayerPosition()
    local predictionTime = 0.28
    local predictedX = self.playerBall.x + self.playerBall.vx * predictionTime
    local predictedY = self.playerBall.y + self.playerBall.vy * predictionTime
    
    return predictedX, predictedY
end

-- Spawn fires at random positions
function GameState:spawnFires(count)
    self.fires = {}
    for i = 1, count do
        self:spawnSingleFire()
    end
end

-- Spawn a single fire using evolved strategy
function GameState:spawnSingleFire()
    local x, y
    local validPosition = false
    local attempts = 0
    
    -- Try to find a valid position
    while not validPosition and attempts < 100 do
        -- Predict player position and spawn 65px from it
        local predictedX, predictedY = self:predictPlayerPosition()
        local angle = math.random() * 2 * math.pi
        x = predictedX + math.cos(angle) * 65
        y = predictedY + math.sin(angle) * 65
        
        -- Clamp to screen bounds
        x = math.max(50, math.min(x, love.graphics.getWidth() - 50))
        y = math.max(50, math.min(y, love.graphics.getHeight() - 50))
        
        -- Check minimum distance from red ball (130px)
        local distToRedBall = math.sqrt((x - self.pushableBall.x)^2 + (y - self.pushableBall.y)^2)
        
        -- Check distance from player ball
        local distToPlayer = math.sqrt((x - self.playerBall.x)^2 + (y - self.playerBall.y)^2)
        
        -- Check distance from existing fires
        local tooCloseToFires = false
        for _, fire in ipairs(self.fires) do
            local distToFire = math.sqrt((x - fire.x)^2 + (y - fire.y)^2)
            if distToFire < 40 then  -- Minimum distance between fires
                tooCloseToFires = true
                break
            end
        end
        
        if distToRedBall >= 130 and distToPlayer > 30 and not tooCloseToFires then
            validPosition = true
        end
        attempts = attempts + 1
    end
    
    -- Create fire at found position (or fallback if no valid position found)
    if attempts >= 100 then
        -- Fallback: place fire at random position avoiding red ball
        local fallbackAttempts = 0
        repeat
            x = math.random(50, love.graphics.getWidth() - 50)
            y = math.random(50, love.graphics.getHeight() - 50)
            local distToRedBall = math.sqrt((x - self.pushableBall.x)^2 + (y - self.pushableBall.y)^2)
            fallbackAttempts = fallbackAttempts + 1
        until distToRedBall >= 130 or fallbackAttempts >= 50
    end
    
    table.insert(self.fires, Fire:new(x, y, 15, {1, 0.3, 0}))
end

function GameState:extinguishFire(index, audio)
    local fire = self.fires[index]
    
    -- Create stain where fire was extinguished
    table.insert(self.stains, Stain:new(fire.x, fire.y, fire.radius + 5))
    
    -- Play fire extinguish sound effect (placeholder - will be implemented in audio system)
    if audio then
        audio:playCoinCollect()  -- Temporary: reuse existing sound
    end
    
    -- Remove the fire and reset respawn timer to start countdown
    table.remove(self.fires, index)
    self.respawnTimer = 0
>>>>>>> detached-work
end

return GameState