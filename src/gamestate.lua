local Ball = require("src/ball")
local Fire = require("src/fire")

local GameState = {}

function GameState:new()
    local gameState = {}
    setmetatable(gameState, {__index = self})
    
    gameState.state = "playing"
    gameState.playerBall = nil
    gameState.pushableBall = nil
    gameState.fires = {}
    gameState.maxFires = 5
    gameState.respawnTimer = 0
    gameState.respawnDelay = 2.0  -- 2 seconds delay before respawning
    
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
    -- Update all fires (for flickering animation)
    for _, fire in ipairs(self.fires) do
        fire:update(dt)
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

-- Spawn fires at random positions
function GameState:spawnFires(count)
    self.fires = {}
    for i = 1, count do
        self:spawnSingleFire()
    end
end

-- Spawn a single fire at a valid position
function GameState:spawnSingleFire()
    local x, y
    local validPosition = false
    local attempts = 0
    
    -- Try to find a valid position that doesn't overlap with balls or other fires
    while not validPosition and attempts < 100 do
        x = math.random(50, love.graphics.getWidth() - 50)
        y = math.random(50, love.graphics.getHeight() - 50)
        
        -- Check distance from both balls
        local distToPlayer = math.sqrt((x - self.playerBall.x)^2 + (y - self.playerBall.y)^2)
        local distToPush = math.sqrt((x - self.pushableBall.x)^2 + (y - self.pushableBall.y)^2)
        
        -- Check distance from existing fires
        local tooCloseToFires = false
        for _, fire in ipairs(self.fires) do
            local distToFire = math.sqrt((x - fire.x)^2 + (y - fire.y)^2)
            if distToFire < 50 then  -- Minimum distance between fires
                tooCloseToFires = true
                break
            end
        end
        
        if distToPlayer > 80 and distToPush > 80 and not tooCloseToFires then
            validPosition = true
        end
        attempts = attempts + 1
    end
    
    -- Create fire at found position (or random if no valid position found after many attempts)
    if attempts >= 100 then
        -- Fallback: place fire at random position if we can't find a good spot
        x = math.random(50, love.graphics.getWidth() - 50)
        y = math.random(50, love.graphics.getHeight() - 50)
    end
    
    table.insert(self.fires, Fire:new(x, y, 12, {1, 0.5, 0}))
end

function GameState:extinguishFire(index, audio)
    -- Play fire extinguish sound effect
    if audio then
        audio:playCoinCollect()  -- TODO: Will be updated to fire extinguish sound
    end
    
    -- Remove the fire and reset respawn timer to start countdown
    table.remove(self.fires, index)
    self.respawnTimer = 0
end

-- Keep old method name for compatibility until main.lua is updated
function GameState:collectCoin(index, audio)
    self:extinguishFire(index, audio)
end

return GameState