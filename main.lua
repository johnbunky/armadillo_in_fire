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
        
        -- Check collision between player ball and fires (damage - placeholder for now)
        for i, fire in ipairs(gameState.fires) do
            if Physics.checkCoinCollision(gameState.playerBall, fire) then
                -- TODO: Implement damage system in next task
                -- For now, just continue without action
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
        
        for i, fire in ipairs(gameState.fires) do
            fire:drawShadow()
        end
        
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