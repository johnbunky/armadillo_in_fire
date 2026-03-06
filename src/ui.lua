local UI = {}

function UI.draw(gameState)
    -- Draw instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Use WASD or Arrow Keys to move the blue ball", 10, 10)
    love.graphics.print("Push the red ball to collect yellow coins!", 10, 30)
    love.graphics.print("Press ESC to quit", 10, 50)
    love.graphics.print("Coins remaining: " .. #gameState.coins, 10, 70)
end

return UI