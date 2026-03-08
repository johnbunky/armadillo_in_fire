local GameState = {}
GameState.__index = GameState

function GameState:new()
    local state = {}
    setmetatable(state, GameState)
    
    state.currentState = "playing"
    state.gameOverTime = 0
    state.gameOverDelay = 2.0 -- 2 second delay before restart
    
    return state
end

function GameState:update(dt, player)
    if self.currentState == "playing" then
        -- Check game over condition
        if player.health <= 0 then
            self.currentState = "gameOver"
            self.gameOverTime = 0
        end
    elseif self.currentState == "gameOver" then
        self.gameOverTime = self.gameOverTime + dt
        
        -- Auto-restart after delay
        if self.gameOverTime >= self.gameOverDelay then
            self:restart()
        end
    end
end

function GameState:restart()
    self.currentState = "playing"
    self.gameOverTime = 0
    -- Player health will be reset in main.lua
end

function GameState:isGameOver()
    return self.currentState == "gameOver"
end

function GameState:isPlaying()
    return self.currentState == "playing"
end

return GameState