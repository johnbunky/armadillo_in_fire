local GameState = {}
GameState.__index = GameState

function GameState:new()
    local state = {}
    setmetatable(state, GameState)
    
    state.currentState = "playing"
    state.gameOverTime = 0
    state.gameOverDelay = 2.0
    
    return state
end

function GameState:update(dt, player)
    if self.currentState == "playing" then
        if player.health <= 0 then
            self.currentState = "gameOver"
            self.gameOverTime = 0
        end
    elseif self.currentState == "gameOver" then
        self.gameOverTime = self.gameOverTime + dt
        
        if self.gameOverTime >= self.gameOverDelay then
            self:restart()
        end
    end
end

function GameState:restart()
    self.currentState = "playing"
    self.gameOverTime = 0
end

function GameState:isGameOver()
    return self.currentState == "gameOver"
end

function GameState:isPlaying()
    return self.currentState == "playing"
end

return GameState