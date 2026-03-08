local GameState = require("src/gamestate")
local Physics = require("src/physics")
local UI = require("src/ui")
local Audio = require("src/audio")

-- Initialize game
local gameState
local audio

function love.load()
    gameState = GameState:new()
    gameState:init()
    
    -- Initialize audio system
    audio = Audio
    audio:init()
    
    -- Create assets/sounds directory if it doesn't exist
    local info = love.filesystem.getInfo("assets")
    if not info then
        love.filesystem.createDirectory("assets")
    end
    
    local soundsInfo = love.filesystem.getInfo("assets/sounds")
    if not soundsInfo then
        love.filesystem.createDirectory("assets/sounds")
    end
end

function love.update(dt)
    if gameState.state == "playing" then
        -- Update game state (handles coin respawning)
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
        
        -- Update coins with movement behavior
        for i, coin in ipairs(gameState.coins) do
            coin:update(dt, gameState.playerBall, gameState.pushableBall)
        end
        
        -- Handle collision between balls with audio
        Physics.handleCollision(gameState.playerBall, gameState.pushableBall, audio)
        
        -- Check collision between red ball and coins
        for i = #gameState.coins, 1, -1 do
            if Physics.checkCoinCollision(gameState.pushableBall, gameState.coins[i]) then
                -- Use the new collectCoin method with audio
                gameState:collectCoin(i, audio)
            end
        end
    end
end

function love.draw()
    -- Clear screen with light green grass-like background
    love.graphics.setBackgroundColor(0.6, 0.8, 0.4)
    
    if gameState.state == "playing" then
        -- Draw shadows first (behind all objects)
        gameState.playerBall:drawShadow()
        gameState.pushableBall:drawShadow()
        
        for i, coin in ipairs(gameState.coins) do
            coin:drawShadow()
        end
        
        -- Draw balls
        gameState.playerBall:draw()
        gameState.pushableBall:draw()
        
        -- Draw coins
        for i, coin in ipairs(gameState.coins) do
            coin:draw()
        end
        
        -- Draw UI with audio reference
        UI.draw(gameState, audio)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "m" then
        -- Toggle audio mute
        audio:toggle()
    elseif key == "=" or key == "+" then
        -- Increase volume
        local currentVolume = audio.volume
        audio:setVolume(currentVolume + 0.1)
    elseif key == "-" then
        -- Decrease volume
        local currentVolume = audio.volume
        audio:setVolume(currentVolume - 0.1)
    end
end