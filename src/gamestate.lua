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

-- Spawn a single coin using new strategy
function GameState:spawnSingleCoin()
    local x, y
    local validPosition = false
    local attempts = 0
    
    -- 58% chance to cluster near existing coin
    local clusterChance = 0.58
    local shouldCluster = math.random() < clusterChance and #self.coins > 0
    
    -- Try to find a valid position
    while not validPosition and attempts < 100 do
        if shouldCluster then
            -- Spawn near an existing coin
            local existingCoin = self.coins[math.random(#self.coins)]
            local angle = math.random() * 2 * math.pi
            local distance = 40 + math.random(30)  -- 40-70 pixels from existing coin
            x = existingCoin.x + math.cos(angle) * distance
            y = existingCoin.y + math.sin(angle) * distance
        else
            -- Spawn 65px from predicted player position
            local predictedX, predictedY = self:predictPlayerPosition()
            local angle = math.random() * 2 * math.pi
            x = predictedX + math.cos(angle) * 65
            y = predictedY + math.sin(angle) * 65
        end
        
        -- Clamp to screen bounds
        x = math.max(50, math.min(x, love.graphics.getWidth() - 50))
        y = math.max(50, math.min(y, love.graphics.getHeight() - 50))
        
        -- Check distance from both balls
        local distToPlayer = math.sqrt((x - self.playerBall.x)^2 + (y - self.playerBall.y)^2)
        local distToPush = math.sqrt((x - self.pushableBall.x)^2 + (y - self.pushableBall.y)^2)
        
        -- Check distance from existing coins (but allow clustering)
        local tooCloseToCoins = false
        if not shouldCluster then
            for _, coin in ipairs(self.coins) do
                local distToCoin = math.sqrt((x - coin.x)^2 + (y - coin.y)^2)
                if distToCoin < 30 then  -- Minimum distance when not clustering
                    tooCloseToCoins = true
                    break
                end
            end
        end
        
        if distToPlayer > 40 and distToPush > 40 and not tooCloseToCoins then
            validPosition = true
        end
        attempts = attempts + 1
    end
    
    -- Create coin at found position (or fallback if no valid position found)
    if attempts >= 100 then
        -- Fallback: place coin at random position
        x = math.random(50, love.graphics.getWidth() - 50)
        y = math.random(50, love.graphics.getHeight() - 50)
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