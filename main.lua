local Ball = require('src.ball')
local Fire = require('src.fire')
local Stain = require('src.stain')
local Physics = require('src.physics')
local Audio = require('src.audio')
local UI = require('src.ui')
local Menu = require('src.menu')

-- Global game state
local gameState = {}
local audio
local menu
local currentState = "menu"  -- Can be: "menu", "playing", "paused", "game_over"

function love.load()
    -- Initialize menu system
    menu = Menu:new()
    
    -- Initialize audio system
    audio = Audio
    audio:init()
    
    -- Initialize game state
    gameState.state = "playing"
    gameState.gameOverTime = 0
    gameState.gameOverDelay = 2.0
    gameState.nextFireSpawn = 2.0
    gameState.fireSpawnInterval = 3.0
    gameState.minFireSpawnInterval = 0.8
    gameState.fireSpawnReduction = 0.1
    gameState.score = 0
    gameState.lives = 3
    
    -- Initialize game objects
    gameState.ball = Ball:new(400, 550)
    gameState.fires = {}
    gameState.stains = {}
    
    -- Set window title
    love.window.setTitle("Fire Ball Game")
end

function startNewGame()
    currentState = "playing"
    gameState.state = "playing"
    gameState.gameOverTime = 0
    gameState.nextFireSpawn = 2.0
    gameState.fireSpawnInterval = 3.0
    gameState.score = 0
    gameState.lives = 3
    
    -- Reset game objects
    gameState.ball = Ball:new(400, 550)
    gameState.fires = {}
    gameState.stains = {}
    
    audio:playMusic('game')
end

function love.update(dt)
    if currentState == "menu" then
        menu:update(dt)
    elseif currentState == "playing" then
        if gameState.state == "playing" then
            -- Update game objects
            gameState.ball:update(dt)
            
            for i = #gameState.fires, 1, -1 do
                local fire = gameState.fires[i]
                fire:update(dt)
                
                if fire.position.y > love.graphics.getHeight() + 50 then
                    table.remove(gameState.fires, i)
                    gameState.score = gameState.score + 10
                end
            end
            
            for i = #gameState.stains, 1, -1 do
                local stain = gameState.stains[i]
                stain:update(dt)
                
                if stain.alpha <= 0 then
                    table.remove(gameState.stains, i)
                end
            end
            
            -- Check collisions
            Physics:checkCollisions(gameState.ball, gameState.fires, gameState.stains, audio)
            
            -- Spawn fires
            gameState.nextFireSpawn = gameState.nextFireSpawn - dt
            if gameState.nextFireSpawn <= 0 then
                local fire = Fire:new(math.random(50, love.graphics.getWidth() - 50), -30)
                table.insert(gameState.fires, fire)
                gameState.nextFireSpawn = gameState.fireSpawnInterval
                
                if gameState.fireSpawnInterval > gameState.minFireSpawnInterval then
                    gameState.fireSpawnInterval = gameState.fireSpawnInterval - gameState.fireSpawnReduction
                end
            end
            
            -- Check game over
            if gameState.ball.lives <= 0 then
                gameState.state = "game_over"
                gameState.gameOverTime = 0
                audio:stopMusic()
                audio:playSound('game_over')
            end
        elseif gameState.state == "game_over" then
            gameState.gameOverTime = gameState.gameOverTime + dt
            if gameState.gameOverTime >= gameState.gameOverDelay then
                currentState = "menu"
                menu:showGameOver(gameState.score)
            end
        end
    elseif currentState == "paused" then
        menu:update(dt)
    end
end

function love.draw()
    if currentState == "menu" or currentState == "paused" then
        -- Draw game in background if paused
        if currentState == "paused" then
            -- Draw game objects
            gameState.ball:draw()
            
            for _, fire in ipairs(gameState.fires) do
                fire:draw()
            end
            
            for _, stain in ipairs(gameState.stains) do
                stain:draw()
            end
            
            -- Draw UI
            UI:drawScore(gameState.score)
            UI:drawLives(gameState.ball.lives)
        end
        
        -- Draw menu on top
        menu:draw()
    elseif currentState == "playing" then
        -- Draw game objects
        gameState.ball:draw()
        
        for _, fire in ipairs(gameState.fires) do
            fire:draw()
        end
        
        for _, stain in ipairs(gameState.stains) do
            stain:draw()
        end
        
        -- Draw UI
        UI:drawScore(gameState.score)
        UI:drawLives(gameState.ball.lives)
        
        if gameState.state == "game_over" then
            UI:drawGameOver(gameState.score)
        end
    end
end

function love.keypressed(key)
    if currentState == "menu" or currentState == "paused" then
        -- Handle menu input and check for actions
        local action = nil
        
        -- Store the original selectOption function temporarily
        local originalSelectOption = menu.selectOption
        
        -- Override selectOption to capture the return value
        menu.selectOption = function(self)
            return originalSelectOption(self)
        end
        
        -- Process the key press
        if key == "return" or key == "space" then
            action = menu:selectOption()
        else
            menu:keypressed(key)
        end
        
        -- Restore original function
        menu.selectOption = originalSelectOption
        
        -- Handle menu actions
        if action == "start_game" then
            startNewGame()
        elseif action == "resume" then
            if currentState == "paused" then
                currentState = "playing"
                audio:resumeMusic()
            end
        elseif action == "restart" then
            startNewGame()
        end
        
    elseif currentState == "playing" then
        if key == "escape" then
            currentState = "paused"
            menu:showPause()
            audio:pauseMusic()
        elseif key == "p" then
            currentState = "paused"
            menu:showPause()
            audio:pauseMusic()
        else
            -- Handle game input
            gameState.ball:keypressed(key)
        end
    end
end

function love.keyreleased(key)
    if currentState == "playing" then
        gameState.ball:keyreleased(key)
    end
end