local UI = {}

function UI.draw(gameState, audio)
    -- Draw instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Use WASD or Arrow Keys to move the blue ball", 10, 10)
    love.graphics.print("Push the red ball to extinguish fires!", 10, 30)
    love.graphics.print("Press ESC to quit", 10, 50)
    love.graphics.print("Press M to toggle audio", 10, 70)
    love.graphics.print("Fires remaining: " .. #gameState.fires, 10, 90)
    
    -- Show audio status
    local audioStatus = audio and audio:isEnabled() and "ON" or "OFF"
    love.graphics.print("Audio: " .. audioStatus, 10, 110)
end

return UI