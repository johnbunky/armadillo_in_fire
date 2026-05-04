local Fire = {}
Fire.__index = Fire

-- ── Helpers ────────────────────────────────────────────────────────────────

local function lerp(a, b, t) return a + (b - a) * t end

local function newParticle()
    return { x = 0, y = 0, vx = 0, vy = 0,
             life = 1, maxLife = 1, size = 8 }
end

-- ── Constructor ────────────────────────────────────────────────────────────

function Fire:new(x, y, radius, color)
    local fire = setmetatable({}, Fire)

    fire.x      = x or 0
    fire.y      = y or 0
    fire.radius = radius or 15

    -- Particle pool
    fire.particles    = {}
    fire.spawnAccum   = 0
    fire.spawnRate    = 40

    -- AI signals (read by utility_weights / pickStrategy)
    fire.positionSignal  = 0
    fire.directionSignal = { x = 0, y = 0 }
    fire.timingSignal    = 0

    return fire
end

-- ── Particle spawn ─────────────────────────────────────────────────────────

local function spawnParticle(fire)
    local p      = newParticle()
    local spread = math.random(-18, 18)
    p.x       = fire.x + spread
    p.y       = fire.y
    p.vx      = spread * 0.6 + math.random(-15, 15)
    p.vy      = math.random(-90, -50)
    p.life    = math.random(50, 90) / 100   -- 0.50 – 0.90 s
    p.maxLife = p.life
    p.size    = math.random(6, 16)
    table.insert(fire.particles, p)
end

-- ── Update ─────────────────────────────────────────────────────────────────

function Fire:update(dt, playerBall)
    -- Spawn new particles
    self.spawnAccum = self.spawnAccum + self.spawnRate * dt
    local toSpawn   = math.floor(self.spawnAccum)
    self.spawnAccum = self.spawnAccum - toSpawn
    for _ = 1, toSpawn do spawnParticle(self) end

    -- Update existing particles
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x    = p.x + p.vx * dt
        p.y    = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end

    -- AI signals
    if playerBall then
        self:_detectPosition(playerBall)
        self:_detectDirection(playerBall)
        self:_detectTiming(playerBall)
    end
end

-- ── AI signal helpers ──────────────────────────────────────────────────────

function Fire:_detectPosition(playerBall)
    local dx = playerBall.x - self.x
    local dy = playerBall.y - self.y
    local d  = math.sqrt(dx * dx + dy * dy)
    self.positionSignal = math.max(0, 1 - d / 400)
end

function Fire:_detectDirection(playerBall)
    local dx = playerBall.x - self.x
    local dy = playerBall.y - self.y
    local d  = math.sqrt(dx * dx + dy * dy)
    if d > 0 then
        self.directionSignal.x = dx / d
        self.directionSignal.y = dy / d
    else
        self.directionSignal.x = 0
        self.directionSignal.y = 0
    end
end

function Fire:_detectTiming(playerBall)
    local spd = math.sqrt(playerBall.vx ^ 2 + playerBall.vy ^ 2)
    self.timingSignal = math.min(1, spd / 300)
end

-- ── Draw ───────────────────────────────────────────────────────────────────

function Fire:drawShadow() end   -- fires cast no shadow

function Fire:draw()
    love.graphics.setBlendMode("add")

    for _, p in ipairs(self.particles) do
        local t  = p.life / p.maxLife        -- 1 = fresh, 0 = dead
        -- How high is this particle above the fire base? (0 = base, 1 = ~50px up)
        local rise = math.max(0, math.min(1, (self.y - p.y) / 50))
        local r  = 1
        local g  = lerp(0.1, 0.7, t) * lerp(1, 0.15, rise)  -- redder toward top
        local b  = 0
        local a  = lerp(0,   0.9, t)
        local sz = p.size * t
        if sz > 0.5 then
            love.graphics.setColor(r, g, b, a)
            love.graphics.circle("fill", p.x, p.y, sz)
        end
    end

    -- Base glow: grounds the fire visually at its collision centre
    love.graphics.setColor(1, 0.35, 0, 0.35)
    love.graphics.circle("fill", self.x, self.y, self.radius * 0.9)

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

return Fire
