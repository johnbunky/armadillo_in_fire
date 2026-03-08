local Physics = require('src.physics')

local GameState = {}

-- Initialize game state
function GameState.init()
    GameState.balls = {}
    GameState.fires = {}
    GameState.player = {
        x = 400,
        y = 300,
        radius = 20,
        vx = 0,
        vy = 0,
        health = 100,
        maxHealth = 100
    }
    GameState.spawnTimer = 0
    GameState.fireSpawnTimer = 0
    GameState.score = 0
end

-- Add a new ball
function GameState.addBall(x, y, vx, vy, radius)
    table.insert(GameState.balls, {
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        radius = radius or 15
    })
end

-- Add a new fire
function GameState.addFire(x, y)
    table.insert(GameState.fires, {
        x = x,
        y = y,
        radius = 25,
        age = 0
    })
end

-- Update game state
function GameState.update(dt)
    -- Update player
    GameState.updatePlayer(dt)
    
    -- Update balls
    GameState.updateBalls(dt)
    
    -- Update fires
    GameState.updateFires(dt)
    
    -- Spawn new balls
    GameState.spawnTimer = GameState.spawnTimer + dt
    if GameState.spawnTimer > 2 then
        GameState.spawnBall()
        GameState.spawnTimer = 0
    end
    
    -- Spawn new fires
    GameState.fireSpawnTimer = GameState.fireSpawnTimer + dt
    if GameState.fireSpawnTimer > 3 then
        GameState.spawnFire()
        GameState.fireSpawnTimer = 0
    end
    
    -- Check collisions
    GameState.checkCollisions()
    GameState.checkPlayerFireDamage()
end

function GameState.checkPlayerFireDamage()
    for _, fire in ipairs(GameState.fires) do
        if Physics.checkFireCollision(GameState.player, fire) then
            GameState.player.health = GameState.player.health - 20
            if GameState.player.health <= 0 then
                GameState.player.health = 0
                -- Game over logic here
            end
        end
    end
end

function GameState.updatePlayer(dt)
    -- Player movement will be handled by input
    -- Apply basic physics
    GameState.player.x = GameState.player.x + GameState.player.vx * dt
    GameState.player.y = GameState.player.y + GameState.player.vy * dt
    
    -- Apply friction
    GameState.player.vx = GameState.player.vx * 0.95
    GameState.player.vy = GameState.player.vy * 0.95
    
    -- Keep player in bounds
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    if GameState.player.x < GameState.player.radius then
        GameState.player.x = GameState.player.radius
    elseif GameState.player.x > screenWidth - GameState.player.radius then
        GameState.player.x = screenWidth - GameState.player.radius
    end
    
    if GameState.player.y < GameState.player.radius then
        GameState.player.y = GameState.player.radius
    elseif GameState.player.y > screenHeight - GameState.player.radius then
        GameState.player.y = screenHeight - GameState.player.radius
    end
end

function GameState.updateBalls(dt)
    for i = #GameState.balls, 1, -1 do
        local ball = GameState.balls[i]
        
        -- Update position
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt
        
        -- Bounce off walls
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        if ball.x < ball.radius or ball.x > screenWidth - ball.radius then
            ball.vx = -ball.vx
            ball.x = math.max(ball.radius, math.min(screenWidth - ball.radius, ball.x))
        end
        
        if ball.y < ball.radius or ball.y > screenHeight - ball.radius then
            ball.vy = -ball.vy
            ball.y = math.max(ball.radius, math.min(screenHeight - ball.radius, ball.y))
        end
    end
end

function GameState.updateFires(dt)
    for i = #GameState.fires, 1, -1 do
        local fire = GameState.fires[i]
        
        fire.age = fire.age + dt
        
        -- Remove old fires
        if fire.age > 10 then
            table.remove(GameState.fires, i)
        end
    end
end

function GameState.spawnBall()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local x = math.random(50, screenWidth - 50)
    local y = math.random(50, screenHeight - 50)
    local vx = math.random(-200, 200)
    local vy = math.random(-200, 200)
    
    GameState.addBall(x, y, vx, vy)
end

function GameState.spawnFire()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local x = math.random(50, screenWidth - 50)
    local y = math.random(50, screenHeight - 50)
    
    GameState.addFire(x, y)
end

function GameState.checkCollisions()
    -- Check ball-ball collisions
    for i = 1, #GameState.balls do
        for j = i + 1, #GameState.balls do
            if Physics.checkCollision(GameState.balls[i], GameState.balls[j]) then
                Physics.resolveCollision(GameState.balls[i], GameState.balls[j])
            end
        end
    end
    
    -- Check player-ball collisions
    for _, ball in ipairs(GameState.balls) do
        if Physics.checkCollision(GameState.player, ball) then
            Physics.resolveCollision(GameState.player, ball)
        end
    end
end

return GameState