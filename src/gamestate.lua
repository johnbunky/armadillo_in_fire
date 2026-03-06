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
    gameState.respawnDelay = 2.0  -- 2 seconds delay before respawning
    
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

-- Spawn coins at random positions
function GameState:spawnCoins(count)
    self.coins = {}
    for i = 1, count do
        self:spawnSingleCoin()
    end
end

-- Spawn a single coin at a valid position
function GameState:spawnSingleCoin()
    local x, y
    local validPosition = false
    local attempts = 0
    
    -- Try to find a valid position that doesn't overlap with balls or other coins
    while not validPosition and attempts < 100 do
        x = math.random(50, love.graphics.getWidth() - 50)
        y = math.random(50, love.graphics.getHeight() - 50)
        
        -- Check distance from both balls
        local distToPlayer = math.sqrt((x - self.playerBall.x)^2 + (y - self.playerBall.y)^2)
        local distToPush = math.sqrt((x - self.pushableBall.x)^2 + (y - self.pushableBall.y)^2)
        
        -- Check distance from existing coins
        local tooCloseToCoins = false
        for _, coin in ipairs(self.coins) do
            local distToCoin = math.sqrt((x - coin.x)^2 + (y - coin.y)^2)
            if distToCoin < 50 then  -- Minimum distance between coins
                tooCloseToCoins = true
                break
            end
        end
        
        if distToPlayer > 80 and distToPush > 80 and not tooCloseToCoins then
            validPosition = true
        end
        attempts = attempts + 1
    end
    
    -- Create coin at found position (or random if no valid position found after many attempts)
    if attempts >= 100 then
        -- Fallback: place coin at random position if we can't find a good spot
        x = math.random(50, love.graphics.getWidth() - 50)
        y = math.random(50, love.graphics.getHeight() - 50)
    end
    
    table.insert(self.coins, Coin:new(x, y, 12, {1, 0.8, 0}))
end

function GameState:collectCoin(index)
    -- Remove the coin and reset respawn timer to start countdown
    table.remove(self.coins, index)
    self.respawnTimer = 0
end

return GameState