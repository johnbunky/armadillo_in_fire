local UI = {}

function UI.draw(gameState, audio)
    -- Draw HUD
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.getFont())
    
    -- Draw player health bar
    if gameState.playerBall then
        local healthPercent = gameState.playerBall.health / gameState.playerBall.maxHealth
        local barWidth = 200
        local barHeight = 20
        local barX = 10
        local barY = 10
        
        -- Health bar background
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
        
        -- Health bar fill
        local healthColor = {1 - healthPercent + 0.3, healthPercent, 0.2}  -- Red to green gradient
        love.graphics.setColor(healthColor[1], healthColor[2], healthColor[3], 0.9)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
        
        -- Health bar border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
        
        -- Health text
        love.graphics.print(string.format("Health: %.0f/%.0f", gameState.playerBall.health, gameState.playerBall.maxHealth), barX, barY + 25)
    end
    
    -- Draw fire count and stain count
    local fireCount = gameState.fires and #gameState.fires or 0
    local stainCount = gameState.stains and #gameState.stains or 0
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Active Fires: " .. fireCount, 10, 60)
    love.graphics.print("Extinguished: " .. stainCount, 10, 80)
    
    -- Draw instructions
    love.graphics.print("Push red ball into fires to extinguish them!", 10, 110)
    love.graphics.print("Avoid touching fires - they damage you!", 10, 130)
    
    -- Draw audio status
    if audio then
        local audioStatus = audio:isEnabled() and "ON" or "OFF"
        love.graphics.print("Audio: " .. audioStatus .. " (M to toggle)", love.graphics.getWidth() - 200, 10)
        love.graphics.print("Volume: " .. math.floor(audio.volume * 100) .. "% (+/- to adjust)", love.graphics.getWidth() - 200, 30)
    end
end

return UI