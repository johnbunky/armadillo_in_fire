local UI = {}

function UI:draw(gameState)
    -- Draw HUD
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.getFont())
    
    -- Draw fire count and health instead of coin count
    love.graphics.print("Active Fires: " .. #gameState.fires, 10, 10)
    love.graphics.print("Active Stains: " .. #gameState.stains, 10, 30)
    
    -- Draw game state
    love.graphics.print("State: " .. gameState.state, 10, 50)
end

return UI