function love.load()
    -- Set window title
    love.window.setTitle("Two Balls - Push Game")
    
    -- Set window size
    love.window.setMode(800, 600)
    
    -- Initialize game state
    gameState = "playing"
end

function love.update(dt)
    -- Game update logic will go here
end

function love.draw()
    -- Clear screen with dark background
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    -- Draw game title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Two Balls - Push Game", 10, 10)
    
    -- Draw instructions
    love.graphics.print("Use WASD or Arrow Keys to move", 10, 30)
end

function love.keypressed(key)
    -- Handle one-time key presses
    if key == "escape" then
        love.event.quit()
    end
end