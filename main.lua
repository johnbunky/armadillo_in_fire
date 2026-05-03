local Ball    = require('src.ball')
local Fire    = require('src.fire')
local Stain   = require('src.stain')
local Physics = require('src.physics')
local Audio   = require('src.audio')
local UI      = require('src.ui')
local Menu    = require('src.menu')
local Screen  = require('src.screen')


-- ── _evo: mutable adaptive state ──────────────────────────────────────────
-- Defined before C so evolved_params() is always callable.
local _evo = {
    spawnInterval = 3.2,  -- seconds between fires [0.3 – 4.0]
    damagePerTick = 12,   -- hp lost per fire tick  [5 – 25]
    chaseWeight   = 1.0,  -- ai chase aggression    [0.5 – 2.8]
}

local function evolved_params()
    return {
        spawnInterval = _evo.spawnInterval,
        damagePerTick = _evo.damagePerTick,
        aiWeights     = {
            _evo.chaseWeight,
            1.7097, 0.6166, 0.9987, 0.1374,
        },
    }
end

-- ── C: all tunable game constants in one place ─────────────────────────────
-- Evolve functions will read and mutate these at runtime.
local C = {
    player = {
        spawnX                 = 100,
        spawnY                 = 300,
        speed                  = 300,
        radius                 = 25,
        color                  = {0.2, 0.8, 0.2},
        maxHealth              = 100,
        damageInterval         = 0.5,
        fireResistanceDuration = 0.2,
        regenRate              = 0.5,
        regenDelay             = 2.0,
        wallBounceDamp         = 0.5,
    },
    pushball = {
        spawnX         = 400,
        spawnY         = 300,
        radius         = 25,
        color          = {0.8, 0.2, 0.2},
        friction       = 0.98,
        wallBounceDamp = 0.6,
    },
    multikill = {
        window           = 1.5,
        tier2_count      = 2,
        tier2_multiplier = 2.0,
        tier2_duration   = 5.0,
        tier3_count      = 3,
        tier3_multiplier = 4.0,
        tier3_duration   = 8.0,
    },
    fire = {
        radius            = 15,
        color             = {1, 0.3, 0},
        spawnRate         = 40,
        damagePerTick     = 12,    -- set by _evo; adapt() updates live
        firstSpawnDelay   = 5.0,
        baseSpawnInterval = 2.2,   -- set by _evo; adapt() updates live
        maxFires          = 100,
        spawnScaleBase    = 1,
        spawnScaleFactor  = 0.003,
    },
    stain = {
        radiusOffset = 5,
    },
    ai = {
        weights          = {1.4, 1.7097, 0.6166, 0.9987, 0.1374}, -- [1] updated by adapt()
        predictionTime   = 0.28,
        chaseSpawnRadius = 65,
        waitSpawnRadius  = 200,
        clusterSpread    = 80,
        positionRange    = 400,
        redBallRange     = 200,
        blockRange       = 300,
        clusterRange     = 150,
    },
    movement = {
        lerpSnap      = 10,
        arrivalRadius = 8,
    },

    -- Live game stats (mutated during play, read by evolve/UI)
    stats = {
        gameTime          = 0,   -- seconds elapsed this run
        extinguishedTotal = 0,   -- fires put out this run
    },
}


-- ── adapt(): called on death, tunes _evo then syncs back to C ─────────────
--   score = fires/sec  >0.8 player winning  <0.3 overwhelmed  else nudge
local function adapt()
    local t     = math.max(1, C.stats.gameTime)
    local score = C.stats.extinguishedTotal / t

    local factor
    if     score > 0.8 then factor = 1.08   -- ease in more pressure
    elseif score < 0.3 then factor = 0.92   -- ease off
    else                    factor = 1.02   -- always creep slightly harder
    end

    _evo.spawnInterval = math.max(0.3,  math.min(4.0,  _evo.spawnInterval / factor))
    _evo.damagePerTick = math.max(5,    math.min(25,   _evo.damagePerTick  * factor))
    _evo.chaseWeight   = math.max(0.5,  math.min(2.8,  _evo.chaseWeight   * factor))

    C.fire.baseSpawnInterval = _evo.spawnInterval
    C.fire.damagePerTick     = _evo.damagePerTick
    C.ai.weights[1]          = _evo.chaseWeight
end

local gameState    = {}
local audio
local menu
local currentState = "menu"

-- ─────────────────────────────────────────────────────────────────────────────
-- GAME STATE METHODS
-- ─────────────────────────────────────────────────────────────────────────────

function gameState:update(dt)
    self.gameTime = (self.gameTime or 0) + dt
    C.stats.gameTime = self.gameTime

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
    local f  = self.fires[1]
    local w  = C.ai.weights
    local px, py = self.playerBall.x, self.playerBall.y
    local rx, ry = self.pushableBall.x, self.pushableBall.y
    local sx = f and f.x or 400
    local sy = f and f.y or 300
    local nfd = f and (1 - f.positionSignal) * 400 or 200

    local function dist(ax, ay, bx, by)
        return math.sqrt((ax-bx)^2 + (ay-by)^2)
    end

    local scores = {
        w[1] * (1 - math.min(1, dist(sx, sy, px, py)  / C.ai.positionRange)),
        w[2] * (1 - math.min(1, dist(sx, sy, rx, ry)  / C.ai.redBallRange)),
        w[3] * (1 - math.min(1, dist(sx, sy,
                    px < Screen.W*0.5 and 0 or Screen.W,
                    py < Screen.H*0.5 and 0 or Screen.H) / C.ai.blockRange)),
        w[4] * (1 - math.min(1, nfd / C.ai.clusterRange)),
        w[5] * 0.3,
    }

    local best, bestScore = 1, -math.huge
    for i, v in ipairs(scores) do
        if v > bestScore then best, bestScore = i, v end
    end

    return ({"chase", "avoid", "block", "cluster", "wait"})[best]
end

function gameState:spawnFire()
    -- Single ceiling: C.fire.maxFires (checked before calling this in update).
    -- Log formula throttles the interval between spawns instead:
    --   interval shrinks from baseSpawnInterval down to a floor of 0.3s over time.
    local logScale = C.fire.spawnScaleBase + math.log(self.gameTime + 1) * C.fire.spawnScaleFactor
    self.fireSpawnInterval = math.max(0.3, C.fire.baseSpawnInterval / logScale)

    local strategy = self:pickStrategy()

    local W, H = Screen.W, Screen.H
    local predictionTime = C.ai.predictionTime
    local predictedX = math.max(50, math.min(W - 50,
        self.playerBall.x + self.playerBall.vx * predictionTime))
    local predictedY = math.max(50, math.min(H - 50,
        self.playerBall.y + self.playerBall.vy * predictionTime))

    local angle  = math.random() * 2 * math.pi
    local spawnX, spawnY

    if strategy == "chase" then
        spawnX = predictedX + math.cos(angle) * C.ai.chaseSpawnRadius
        spawnY = predictedY + math.sin(angle) * C.ai.chaseSpawnRadius

    elseif strategy == "block" then
        local cx = self.playerBall.x < W * 0.5 and 0 or W
        local cy = self.playerBall.y < H * 0.5 and 0 or H
        spawnX = (predictedX + cx) * 0.5
        spawnY = (predictedY + cy) * 0.5

    elseif strategy == "cluster" then
        if #self.fires > 0 then
            local f = self.fires[math.random(#self.fires)]
            spawnX = f.x + (math.random() - 0.5) * C.ai.clusterSpread
            spawnY = f.y + (math.random() - 0.5) * C.ai.clusterSpread
        else
            spawnX = predictedX + math.cos(angle) * 65
            spawnY = predictedY + math.sin(angle) * 65
        end

    else -- wait
        spawnX = predictedX + math.cos(angle) * C.ai.waitSpawnRadius
        spawnY = predictedY + math.sin(angle) * C.ai.waitSpawnRadius
    end

    spawnX = math.max(30, math.min(W - 30, spawnX))
    spawnY = math.max(30, math.min(H - 30, spawnY))

    local fire = Fire:new(spawnX, spawnY, C.fire.radius, C.fire.color)
    fire.stain = Stain:new(spawnX, spawnY, fire.radius + C.stain.radiusOffset)  -- stain lives with fire
    table.insert(self.fires, fire)
end

function gameState:extinguishFire(fireIndex)
    self.extinguishedTotal = self.extinguishedTotal + 1
    C.stats.extinguishedTotal = self.extinguishedTotal
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
    self.playerBall.x  = C.player.spawnX;  self.playerBall.y  = C.player.spawnY
    self.playerBall.vx = 0;    self.playerBall.vy = 0
    self.playerBall.health           = self.playerBall.maxHealth
    self.playerBall.damageTimer      = 0
    self.playerBall.fireResistanceTime = 0
    self.playerBall.timeSinceLastDamage = 0

    self.pushableBall.x  = C.pushball.spawnX;  self.pushableBall.y  = C.pushball.spawnY
    self.pushableBall.vx = 0;    self.pushableBall.vy = 0

    self.fires  = {}
    self.stains = {}
    self.state            = "playing"
    self.gameOverTime     = 0
    self.nextFireSpawn    = C.fire.firstSpawnDelay
    self.extinguishedTotal = 0
    self.gameTime         = 0
    C.stats.gameTime          = 0
    C.stats.extinguishedTotal = 0

    -- Clear tap target
    self.touchTarget       = nil
    self.multiKillTimer    = 0
    self.multiKillCount    = 0
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
    gameState.nextFireSpawn     = C.fire.firstSpawnDelay
    gameState.fireSpawnInterval = C.fire.baseSpawnInterval
    gameState.maxFires          = C.fire.maxFires
    gameState.gameTime          = 0
    gameState.extinguishedTotal = 0
    gameState.touchTarget       = nil   -- {x, y} in logical coords

    gameState.playerBall  = Ball:new(C.player.spawnX, C.player.spawnY, C.player.radius, C.player.color, true)
    gameState.pushableBall = Ball:new(C.pushball.spawnX, C.pushball.spawnY, C.pushball.radius, C.pushball.color, false)

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
            adapt()
            currentState = "game_over"
            menu:showGameOver()
            return
        end

        gameState:update(dt)

        -- ── Movement ──────────────────────────────────────────────────
        local speed = C.player.speed
        local targetVx, targetVy = 0, 0

        if gameState.touchTarget then
            local dx   = gameState.touchTarget.x - gameState.playerBall.x
            local dy   = gameState.touchTarget.y - gameState.playerBall.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > C.movement.arrivalRadius then
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
        local snap = 1 - math.exp(-dt * C.movement.lerpSnap)
        gameState.playerBall.vx = gameState.playerBall.vx + (targetVx - gameState.playerBall.vx) * snap
        gameState.playerBall.vy = gameState.playerBall.vy + (targetVy - gameState.playerBall.vy) * snap

        gameState.playerBall:update(dt, audio)
        gameState.pushableBall:update(dt, audio)

        -- Clamp green ball to logical canvas
        local gp = gameState.playerBall
        local gr = gp.radius
        if gp.x < gr then
            gp.x = gr;  gp.vx = math.abs(gp.vx) * C.player.wallBounceDamp
        elseif gp.x > Screen.W - gr then
            gp.x = Screen.W - gr;  gp.vx = -math.abs(gp.vx) * C.player.wallBounceDamp
        end
        if gp.y < gr then
            gp.y = gr;  gp.vy = math.abs(gp.vy) * C.player.wallBounceDamp
        elseif gp.y > Screen.H - gr then
            gp.y = Screen.H - gr;  gp.vy = -math.abs(gp.vy) * C.player.wallBounceDamp
        end

        -- Clamp red ball to logical canvas (fullscreen would let it escape otherwise)
        local pb = gameState.pushableBall
        local r  = pb.radius
        if pb.x < r then
            pb.x = r;  pb.vx = math.abs(pb.vx) * C.pushball.wallBounceDamp
        elseif pb.x > Screen.W - r then
            pb.x = Screen.W - r;  pb.vx = -math.abs(pb.vx) * C.pushball.wallBounceDamp
        end
        if pb.y < r then
            pb.y = r;  pb.vy = math.abs(pb.vy) * C.pushball.wallBounceDamp
        elseif pb.y > Screen.H - r then
            pb.y = Screen.H - r;  pb.vy = -math.abs(pb.vy) * C.pushball.wallBounceDamp
        end

        Physics.handleCollision(gameState.playerBall, gameState.pushableBall, audio)

        -- Red ball extinguishes fires.
        -- Multi-kill: count extinguishes within a 0.25 s window; if >= 2 → boost.
        local MULTIKILL_WINDOW = C.multikill.window
        gameState.multiKillTimer  = (gameState.multiKillTimer  or 0) - dt
        gameState.multiKillCount  = (gameState.multiKillCount  or 0)
        if gameState.multiKillTimer <= 0 then
            gameState.multiKillCount = 0
        end

        for i = #gameState.fires, 1, -1 do
            if Physics.checkCoinCollision(gameState.pushableBall, gameState.fires[i]) then
                gameState:extinguishFire(i)
                gameState.multiKillCount = gameState.multiKillCount + 1
                gameState.multiKillTimer = MULTIKILL_WINDOW

                if gameState.multiKillCount >= C.multikill.tier3_count then
                    gameState.playerBall:triggerRecoveryBoost(C.multikill.tier3_multiplier, C.multikill.tier3_duration)
                    gameState.multiKillCount = 0
                elseif gameState.multiKillCount == C.multikill.tier2_count then
                    gameState.playerBall:triggerRecoveryBoost(C.multikill.tier2_multiplier, C.multikill.tier2_duration)
                end
            end
        end

        -- Player ball takes damage from fires
        for _, fire in ipairs(gameState.fires) do
            if Physics.checkCoinCollision(gameState.playerBall, fire) then
                if gameState.playerBall.damageTimer >= gameState.playerBall.damageInterval then
                    gameState.playerBall:takeDamage(C.fire.damagePerTick, audio)
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
