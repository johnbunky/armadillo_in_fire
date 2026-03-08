local GameState = require('src.gamestate')
local Renderer = require('src.renderer')
local Input = require('src.input')

function love.load()
    -- Initialize game systems
    GameState.init()
    Renderer.init()
    Input.init()
    
    -- Set window properties
    love.window.setTitle("Ball Physics Game")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
end

function love.update(dt)
    Input.update(dt)
    GameState.update(dt)
end

function love.draw()
    Renderer.draw(GameState)
end

function love.keypressed(key)
    Input.keypressed(key)
end

function love.keyreleased(key)
    Input.keyreleased(key)
end