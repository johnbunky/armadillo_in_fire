local Ball    = require('src.ball')
local Fire    = require('src.fire')
local Stain   = require('src.stain')
local Physics = require('src.physics')
local Audio   = require('src.audio')
local UI      = require('src.ui')
local Menu    = require('src.menu')
local Screen  = require('src.screen')

local gameState    = {}
local audio
local menu
local currentState = "menu"

-- ─────────────────────────────────────────────────────────────────────────────
-- GAME STATE METHODS
-- ─────────────────────────────────────────────────────────────────────────────

function gameState:update(dt)
    self.gameTime = (self.gameTime or 0) + dt

    -- Fire spawn timer
    self.nextFireSpawn = self.nextFireSpawn - dt
    if self.nextFireSpawn <= 0 and #self.fires < self.maxFires then
        self:spawnFire()
        self.nextFireSpawn = self.fireSpawnInterval
    end

    -- Update fires
    for _, fire in ipairs(self.fires) do
        fire:update(dt, self.playerBall)
    end

    -- Update and remove dissolved stains
    for i = #self.stains, 1, -1 do
        if self.stains[i]:update(dt) then
            table.remove(self.stains, i)
        end
    end
end

function gameState:pickStrategy()
    local U = require("utility_weights")
    local f = self.fires[1]
    local state = {
        self_x   = f and f.x or 400,
        self_y   = f and f.y or 300,
        player_x = self.playerBall.x,
        player_y = self.playerBall.y,
        red_x    = self.pushableBall.x,   -- BUG FIX: was self.pushBall
        red_y    = self.pushableBall.y,
        nfd      = f and (1 - f.positionSignal) * 400 or 200,  -- BUG FIX: was nearest_fire_dist
    }
    local action = U.pick(state, U.weights)
    if action == "chase"   then return "chase"
    elseif action == "block"   then return "block"
    elseif action == "cluster" then return "cluster"
    else                             return "wait"  end
end

function gameState:spawnFire()
    local maxFires = math.floor(1 + math.log(self.gameTime + 1) * 1.8)
    if #self.fires >= maxFires then return end

    local strategy = self:pickStrategy()

    local W, H = Screen.W, Screen.H
    local predictionTime = 0.28
    local predictedX = math.max(50, math.min(W - 50,
        self.playerBall.x + self.playerBall.vx * predictionTime))
    local predictedY = math.max(50, math.min(H - 50,
        self.playerBall.y + self.playerBall.vy * predictionTime))

    local angle  = math.random() * 2 * math.pi
    local spawnX, spawnY

    if strategy == "chase" then
        spawnX = predictedX + math.cos(angle) * 65
        spawnY = predictedY + math.sin(angle) * 65

    elseif strategy == "block" then
        local cx = self.playerBall.x < W * 0.5 and 0 or W
        local cy = self.playerBall.y < H * 0.5 and 0 or H
        spawnX = (predictedX + cx) * 0.5
        spawnY = (predictedY + cy) * 0.5

    elseif strategy == "cluster" then
        if #self.fires > 0 then
            local f = self.fires[math.random(#self.fires)]
            spawnX = f.x + (math.random() - 0.5) * 80
            spawnY = f.y + (math.random() - 0.5) * 80
        else
            spawnX = predictedX + math.cos(angle) * 65
            spawnY = predictedY + math.sin(angle) * 65
        end

    else -- wait
        spawnX = predictedX + math.cos(angle) * 200
        spawnY = predictedY + math.sin(angle) * 200
    end

    spawnX = math.max(30, math.min(W - 30, spawnX))
    spawnY = math.max(30, math.min(H - 30, spawnY))

    local fire = Fire:new(spawnX, spawnY, 15, {1, 0.3, 0})
    fire.stain = Stain:new(spawnX, spawnY, fire.radius + 5)  -- stain lives with fire
    table.insert(self.fires, fire)
end

function gameState:extinguishFire(fireIndex)
    self.extinguishedTotal = self.extinguishedTotal + 1
    if self.fires[fireIndex] then
        local fire = self.fires[fireIndex]
        -- Hand stain off to the dissolving list now that fire is gone
        if fire.stain then
            table.insert(self.stains, fire.stain)
        end
        table.remove(self.fires, fireIndex)
        if audio then audio:playFireExtinguish() end
    end
end

function gameState:restart()
    self.playerBall.x  = 100;  self.playerBall.y  = 300
    self.playerBall.vx = 0;    self.playerBall.vy = 0
    self.playerBall.health           = self.playerBall.maxHealth
    self.playerBall.damageTimer      = 0
    self.playerBall.fireResistanceTime = 0
    self.playerBall.timeSinceLastDamage = 0

    self.pushableBall.x  = 400;  self.pushableBall.y  = 300
    self.pushableBall.vx = 0;    self.pushableBall.vy = 0

    self.fires  = {}
    self.stains = {}
    self.state            = "playing"
    self.gameOverTime     = 0
    self.nextFireSpawn    = 2.0
    self.extinguishedTotal = 0
    self.gameTime         = 0

    -- Clear tap target
    self.touchTarget = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- LOVE CALLBACKS
-- ─────────────────────────────────────────────────────────────────────────────

function love.load()
    menu  = Menu:new()
    audio = Audio
    audio:init()

    gameState.state             = "playing"
    gameState.gameOverTime      = 0
    gameState.gameOverDelay     = 2.0
    gameState.nextFireSpawn     = 2.0
    gameState.fireSpawnInterval = 1.95
    gameState.maxFires          = 100
    gameState.gameTime          = 0
    gameState.extinguishedTotal = 0
    gameState.touchTarget       = nil   -- {x, y} in logical coords

    gameState.playerBall  = Ball:new(100, 300, 25, {0.2, 0.8, 0.2}, true)
    gameState.pushableBall = Ball:new(400, 300, 25, {0.8, 0.2, 0.2}, false)

    gameState.fires  = {}
    gameState.stains = {}

    love.graphics.setBackgroundColor(0, 0, 0)  -- black bars outside canvas

    Screen:update()

    local settings = menu:getSettings()
    love.audio.setVolume(settings.masterVolume)
    if settings.fullscreen then love.window.setFullscreen(true) end
end

function love.resize(w, h)
    Screen:update()
end

function love.update(dt)
    if currentState == "menu" then
        menu:update(dt)

    elseif currentState == "playing" then
        if gameState.playerBall:isDead() then
            currentState = "game_over"
            menu:showGameOver()
            return
        end

        gameState:update(dt)

        -- ── Movement ──────────────────────────────────────────────────
        local speed = 300
        local targetVx, targetVy = 0, 0

        if gameState.touchTarget then
            local dx   = gameState.touchTarget.x - gameState.playerBall.x
            local dy   = gameState.touchTarget.y - gameState.playerBall.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 8 then
                -- Full speed toward target. The exp-lerp below gives smooth
                -- acceleration on start and smooth coast-out after arrival.
                targetVx = (dx / dist) * speed
                targetVy = (dy / dist) * speed
            else
                gameState.touchTarget = nil  -- clear → lerp decays vx/vy to 0
            end
        else
            if love.keyboard.isDown("left",  "a") then targetVx = -speed end
            if love.keyboard.isDown("right", "d") then targetVx =  speed end
            if love.keyboard.isDown("up",    "w") then targetVy = -speed end
            if love.keyboard.isDown("down",  "s") then targetVy =  speed end
        end

        -- Lerp toward target velocity: inertia on both start and stop
        -- Raise 10 for snappier feel, lower for more slide
        local snap = 1 - math.exp(-dt * 10)
        gameState.playerBall.vx = gameState.playerBall.vx + (targetVx - gameState.playerBall.vx) * snap
        gameState.playerBall.vy = gameState.playerBall.vy + (targetVy - gameState.playerBall.vy) * snap

        gameState.playerBall:update(dt, audio)
        gameState.pushableBall:update(dt, audio)

        -- Clamp green ball to logical canvas
        local gp = gameState.playerBall
        local gr = gp.radius
        if gp.x < gr then
            gp.x = gr;  gp.vx = math.abs(gp.vx) * 0.5
        elseif gp.x > Screen.W - gr then
            gp.x = Screen.W - gr;  gp.vx = -math.abs(gp.vx) * 0.5
        end
        if gp.y < gr then
            gp.y = gr;  gp.vy = math.abs(gp.vy) * 0.5
        elseif gp.y > Screen.H - gr then
            gp.y = Screen.H - gr;  gp.vy = -math.abs(gp.vy) * 0.5
        end

        -- Clamp red ball to logical canvas (fullscreen would let it escape otherwise)
        local pb = gameState.pushableBall
        local r  = pb.radius
        if pb.x < r then
            pb.x = r;  pb.vx = math.abs(pb.vx) * 0.6
        elseif pb.x > Screen.W - r then
            pb.x = Screen.W - r;  pb.vx = -math.abs(pb.vx) * 0.6
        end
        if pb.y < r then
            pb.y = r;  pb.vy = math.abs(pb.vy) * 0.6
        elseif pb.y > Screen.H - r then
            pb.y = Screen.H - r;  pb.vy = -math.abs(pb.vy) * 0.6
        end

        Physics.handleCollision(gameState.playerBall, gameState.pushableBall, audio)

        -- Red ball extinguishes fires
        for i = #gameState.fires, 1, -1 do
            if Physics.checkCoinCollision(gameState.pushableBall, gameState.fires[i]) then
                gameState:extinguishFire(i)
            end
        end

        -- Player ball takes damage from fires
        for _, fire in ipairs(gameState.fires) do
            if Physics.checkCoinCollision(gameState.playerBall, fire) then
                if gameState.playerBall.damageTimer >= gameState.playerBall.damageInterval then
                    gameState.playerBall:takeDamage(20, audio)
                    gameState.playerBall.damageTimer = 0
                end
            end
        end

    elseif currentState == "paused" then
        menu:update(dt)
    elseif currentState == "game_over" then
        menu:update(dt)
    end
end

function love.draw()
    if currentState == "playing" or currentState == "paused" then
        love.graphics.push()
        Screen:apply()

        -- Ground
        love.graphics.setColor(0.6, 0.8, 0.4)
        love.graphics.rectangle("fill", 0, 0, Screen.W, Screen.H)

        -- Shadows, stains, balls, fires
        gameState.playerBall:drawShadow()
        gameState.pushableBall:drawShadow()

        -- Dissolving stains (fires already gone)
        for _, stain in ipairs(gameState.stains) do stain:draw() end
        -- Live stains (still burning)
        for _, fire in ipairs(gameState.fires) do
            if fire.stain then fire.stain:draw() end
        end
        gameState.playerBall:draw()
        gameState.pushableBall:draw()
        for _, fire in ipairs(gameState.fires) do fire:draw() end

        -- Touch target indicator (debug / feel)
        if gameState.touchTarget then
            love.graphics.setColor(1, 1, 1, 0.35)
            love.graphics.circle("line", gameState.touchTarget.x, gameState.touchTarget.y, 12)
            love.graphics.setColor(1, 1, 1, 1)
        end

        UI.draw(gameState, audio)

        love.graphics.pop()
        Screen:drawBars()

        if currentState == "paused" then
            menu:draw(gameState.extinguishedTotal, #gameState.fires)
        end

    elseif currentState == "menu" or currentState == "game_over" then
        menu:draw(gameState.extinguishedTotal, #gameState.fires)
    end
end

-- ── Input ──────────────────────────────────────────────────────────────────

-- Mouse click (desktop testing)
local function setTouchTarget(rx, ry)
    local gx, gy = Screen:toGame(rx, ry)
    local dx = gx - gameState.playerBall.x
    local dy = gy - gameState.playerBall.y
    gameState.touchTarget = {
        x        = gx,
        y        = gy,
        initDist = math.sqrt(dx * dx + dy * dy),
    }
end

-- Mouse click (desktop testing)
function love.mousepressed(x, y, button)
    if button == 1 then
        if currentState == "playing" then
            setTouchTarget(x, y)
        elseif currentState == "menu" or currentState == "paused" or currentState == "game_over" then
            local action = menu:mousepressed(x, y)
            if     action == "start_game" then currentState = "playing"; gameState:restart()
            elseif action == "resume"     then currentState = "playing"
            elseif action == "restart"    then currentState = "playing"; gameState:restart()
            end
        end
    end
end

-- Touch (mobile / web)
function love.touchpressed(id, x, y)
    if currentState == "playing" then
        setTouchTarget(x, y)
    elseif currentState == "menu" or currentState == "paused" or currentState == "game_over" then
        local action = menu:mousepressed(x, y)
        if     action == "start_game" then currentState = "playing"; gameState:restart()
        elseif action == "resume"     then currentState = "playing"
        elseif action == "restart"    then currentState = "playing"; gameState:restart()
        end
    end
end

function love.touchmoved(id, x, y)
    if currentState == "playing" then
        local gx, gy = Screen:toGame(x, y)
        gameState.touchTarget = { x = gx, y = gy }
    end
end

function love.keypressed(key)
    if currentState == "menu" or currentState == "paused" or currentState == "game_over" then
        local action = menu:keypressed(key)
        if     action == "start_game" then currentState = "playing"; gameState:restart()
        elseif action == "resume"     then currentState = "playing"
        elseif action == "restart"    then currentState = "playing"; gameState:restart()
        end

    elseif currentState == "playing" then
        if key == "p" or key == "pause" then
            currentState = "paused"
            menu:showPause()
        elseif key == "escape" then
            currentState = "menu"
            menu:setMenu("main")
        elseif key == "m" then
            audio:toggle()
        elseif key == "=" or key == "+" then
            audio:setVolume(audio.volume + 0.1)
        elseif key == "-" or key == "_" then
            audio:setVolume(audio.volume - 0.1)
        end
    end
end
