local GameState = {}
GameState.__index = GameState

function GameState:new()
    local instance = {}
    setmetatable(instance, GameState)
    return instance
end

function GameState:init()
    -- Initialize game state
    self.currentState = "menu"
    self.player = nil
    self.enemies = {}
    self.bullets = {}
    self.score = 0
    self.level = 1
    self.gameOver = false
    self.paused = false
end

function GameState:update(dt)
    if self.paused or self.gameOver then
        return
    end
    
    -- Update game logic here
    if self.player then
        self.player:update(dt)
    end
    
    for i, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
    
    for i, bullet in ipairs(self.bullets) do
        bullet:update(dt)
    end
end

function GameState:draw()
    -- Draw game objects here
    if self.player then
        self.player:draw()
    end
    
    for i, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    
    for i, bullet in ipairs(self.bullets) do
        bullet:draw()
    end
    
    -- Draw UI
    love.graphics.print("Score: " .. self.score, 10, 10)
    love.graphics.print("Level: " .. self.level, 10, 30)
end

function GameState:setState(newState)
    self.currentState = newState
end

function GameState:getState()
    return self.currentState
end

function GameState:pause()
    self.paused = true
end

function GameState:resume()
    self.paused = false
end

function GameState:reset()
    self:init()
end

return GameState