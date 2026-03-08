local Ball = require("src/ball")
local Coin = require("src/coin")

local GameState = {}

function GameState:new()
    local gameState = {}
    setmetatable(gameState, {__index = self})
    
    gameState.state = "playing"
    gameState.playerBall = nil
    gameState.pushableBall = nil
    gameState.coins = {}
    gameState.maxCoins = 5
    gameState.respawnTimer = 0
    gameState.respawnDelay = 1.95  -- 1.95 seconds delay before respawning
    
    return gameState
end

function GameState:init()
    -- Create the two balls
    self.playerBall = Ball:new(200, 300, 25, {0.2, 0.8, 1}, true)  -- Blue player ball
    self.pushableBall = Ball:new(500, 300, 30, {1, 0.3, 0.3}, false)  -- Red pushable ball
    
    -- Initialize coins
    self:spawnCoins(self.maxCoins)
end

function GameState:update(dt)
    -- Update respawn timer
    if #self.coins < self.maxCoins then
        self.respawnTimer = self.respawnTimer + dt
        
        -- Check if it's time to spawn a new coin
        if self.respawnTimer >= self.respawnDelay then
            self:spawnSingleCoin()
            self.respawnTimer = 0
        end
    else
        -- Reset timer when we have max coins
        self.respawnTimer = 0
    end
end

-- Predict player position 0.28 seconds ahead
function GameState:predictPlayerPosition()
    local predictionTime = 0.28
    local predictedX = self.playerBall.x + self.playerBall.vx * predictionTime
    local predictedY = self.playerBall.y + self.playerBall.vy * predictionTime
    
    return predictedX, predictedY
end

-- Spawn coins at random positions
function GameState:spawnCoins(count)
    self.coins = {}
    for i = 1, count do
        self:spawnSingleCoin()
    end
end

-- Spawn a single coin using evolved strategy
function GameState:spawnSingleCoin()
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
        
        -- Check distance from existing coins
        local tooCloseToCoins = false
        for _, coin in ipairs(self.coins) do
            local distToCoin = math.sqrt((x - coin.x)^2 + (y - coin.y)^2)
            if distToCoin < 30 then  -- Minimum distance between coins
                tooCloseToCoins = true
                break
            end
        end
        
        if distToRedBall >= 130 and distToPlayer > 30 and not tooCloseToCoins then
            validPosition = true
        end
        attempts = attempts + 1
    end
    
    -- Create coin at found position (or fallback if no valid position found)
    if attempts >= 100 then
        -- Fallback: place coin at random position avoiding red ball
        local fallbackAttempts = 0
        repeat
            x = math.random(50, love.graphics.getWidth() - 50)
            y = math.random(50, love.graphics.getHeight() - 50)
            local distToRedBall = math.sqrt((x - self.pushableBall.x)^2 + (y - self.pushableBall.y)^2)
            fallbackAttempts = fallbackAttempts + 1
        until distToRedBall >= 130 or fallbackAttempts >= 50
    end
    
    table.insert(self.coins, Coin:new(x, y, 12, {1, 0.8, 0}))
end

function GameState:collectCoin(index, audio)
    -- Play coin collection sound effect
    if audio then
        audio:playCoinCollect()
    end
    
    -- Remove the coin and reset respawn timer to start countdown
    table.remove(self.coins, index)
    self.respawnTimer = 0
end

return GameState