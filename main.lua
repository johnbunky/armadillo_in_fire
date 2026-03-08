local GameState = require('src.gamestate')
local Ball = require('src.ball')
local Fire = require('src.fire')
local Stain = require('src.stain')
local Physics = require('src.physics')
local Audio = require('src.audio')
local UI = require('src.ui')

-- Global game state
local gameState
local audio

function love.load()
    -- Initialize audio system
    audio = Audio
    audio:init()
    
    -- Initialize game state
    gameState = GameState:new()
    gameState:init()
    
    -- Set window properties
    love.graphics.setBackgroundColor(0.6, 0.8, 0.4)  -- Light green grass-like background
end

function love.update(dt)
    if gameState.state == "playing" then
        -- Check for game over
        if gameState.playerBall:isDead() then
            gameState.state = "game_over"
            return
        end
        
        -- Update game state (handles fire respawning and stain dissolving)
        gameState:update(dt)
        
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
        
        -- Update balls with audio support
        gameState.playerBall:update(dt, audio)
        gameState.pushableBall:update(dt, audio)
        
        -- Handle collision between balls with audio
        Physics.handleCollision(gameState.playerBall, gameState.pushableBall, audio)
        
        -- Check collision between red ball and fires (extinguishing)
        for i = #gameState.fires, 1, -1 do
            if Physics.checkCoinCollision(gameState.pushableBall, gameState.fires[i]) then
                gameState:extinguishFire(i, audio)
            end
        end
        
        -- Check collision between player ball and fires (damage)
        for i, fire in ipairs(gameState.fires) do
            if Physics.checkCoinCollision(gameState.playerBall, fire) then
                if gameState.playerBall.damageTimer >= gameState.playerBall.damageInterval then
                    gameState.playerBall:takeDamage(20, audio)  -- 20 damage per hit
                    gameState.playerBall.damageTimer = 0
                end
            end
        end
    elseif gameState.state == "game_over" then
        -- Update game state for restart handling
        gameState:update(dt)
    end
end

function love.draw()
    if gameState.state == "playing" then
        -- Draw shadows first (behind all objects) - skip fire shadows
        gameState.playerBall:drawShadow()
        gameState.pushableBall:drawShadow()
        
        -- Draw stains (on ground level)
        for i, stain in ipairs(gameState.stains) do
            stain:draw()
        end
        
        -- Draw balls
        gameState.playerBall:draw()
        gameState.pushableBall:draw()
        
        -- Draw fires
        for i, fire in ipairs(gameState.fires) do
            fire:draw()
        end
        
        -- Draw UI with audio reference
        UI.draw(gameState, audio)
    elseif gameState.state == "game_over" then
        -- Draw game over screen
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R, SPACE, or ENTER to restart", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    end
end

function love.keypressed(key)
    -- Audio controls
    if key == "m" then
        audio:toggle()
    elseif key == "=" or key == "+" then
        audio:setVolume(audio.volume + 0.1)
    elseif key == "-" or key == "_" then
        audio:setVolume(audio.volume - 0.1)
    elseif key == "escape" then
        love.event.quit()
    end
end
