local GameState = require("src/gamestate")
local Physics = require("src/physics")
local UI = require("src/ui")

-- Initialize game
local gameState

function love.load()
    gameState = GameState:new()
    gameState:init()
end

function love.update(dt)
    if gameState.state == "playing" then
        -- Player ball movement
        local speed = 300
        gameState.playerBall.vx = 0
        gameState.playerBall.vy = 0
        
        if love.keyboard.isDown("left", "a") then
            gameState.playerBall.vx = -speed
        end
        if love.keyboard.isDown("right", "d") then
            gameState.playerBall.vx = speed
        end
        if love.keyboard.isDown("up", "w") then
            gameState.playerBall.vy = -speed
        end
        if love.keyboard.isDown("down", "s") then
            gameState.playerBall.vy = speed
        end
        
        -- Update balls
        gameState.playerBall:update(dt)
        gameState.pushableBall:update(dt)
        
        -- Handle collision between balls
        Physics.handleCollision(gameState.playerBall, gameState.pushableBall)
        
        -- Check collision between red ball and coins
        for i = #gameState.coins, 1, -1 do
            if Physics.checkCoinCollision(gameState.pushableBall, gameState.coins[i]) then
                -- Remove coin when red ball touches it
                table.remove(gameState.coins, i)
            end
        end
    end
end

function love.draw()
    -- Clear screen with dark background
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    if gameState.state == "playing" then
        -- Draw balls
        gameState.playerBall:draw()
        gameState.pushableBall:draw()
        
        -- Draw coins
        for i, coin in ipairs(gameState.coins) do
            coin:draw()
        end
        
        -- Draw UI
        UI.draw(gameState)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end