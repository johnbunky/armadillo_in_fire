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
    
    return gameState
end

function GameState:init()
    -- Create the two balls
    self.playerBall = Ball:new(200, 300, 25, {0.2, 0.8, 1}, true)  -- Blue player ball
    self.pushableBall = Ball:new(500, 300, 30, {1, 0.3, 0.3}, false)  -- Red pushable ball
    
    -- Initialize coins
    self:spawnCoins(5)
end

-- Spawn coins at random positions
function GameState:spawnCoins(count)
    self.coins = {}
    for i = 1, count do
        local x, y
        local validPosition = false
        local attempts = 0
        
        -- Try to find a valid position that doesn't overlap with balls
        while not validPosition and attempts < 50 do
            x = math.random(50, love.graphics.getWidth() - 50)
            y = math.random(50, love.graphics.getHeight() - 50)
            
            -- Check distance from both balls
            local distToPlayer = math.sqrt((x - self.playerBall.x)^2 + (y - self.playerBall.y)^2)
            local distToPush = math.sqrt((x - self.pushableBall.x)^2 + (y - self.pushableBall.y)^2)
            
            if distToPlayer > 80 and distToPush > 80 then
                validPosition = true
            end
            attempts = attempts + 1
        end
        
        -- Create coin at found position (or random if no valid position found)
        table.insert(self.coins, Coin:new(x, y, 12, {1, 0.8, 0}))
    end
end

return GameState