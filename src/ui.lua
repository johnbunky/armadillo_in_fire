local UI = {}

function UI:draw(gameState)
    -- Draw HUD
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.getFont())
    
    -- Draw fire count and health instead of coin count
    local fireCount = gameState.fires and #gameState.fires or 0
    local stainCount = gameState.stains and #gameState.stains or 0
    
    love.graphics.print("Active Fires: " .. fireCount, 10, 10)
    love.graphics.print("Active Stains: " .. stainCount, 10, 30)
    
    -- Draw game state
    love.graphics.print("State: " .. (gameState.state or "unknown"), 10, 50)
end

return UI