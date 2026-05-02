local Ball = {}
Ball.__index = Ball

function Ball:new(x, y, radius, color, isPlayer)
    local ball = setmetatable({}, Ball)

    ball.x      = x or 0
    ball.y      = y or 0
    ball.radius = radius or 20
    ball.color  = color or {1, 1, 1}
    ball.vx     = 0
    ball.vy     = 0
    ball.isPlayer = isPlayer or false

    if ball.isPlayer then
        ball.maxHealth    = 100
        ball.health       = ball.maxHealth
        ball.damageTimer  = 0
        ball.damageInterval       = 0.5
        ball.fireResistanceTime   = 0
        ball.fireResistanceDuration = 0.2
        ball.timeSinceLastDamage  = 0

        -- Regen: base rate reduced 3× from original 10 hp/s → ~3.33 hp/s
        ball.regenRate  = 0.5
        ball.regenDelay = 2.0

        -- Recovery boost (triggered by multi-extinguish)
        ball.recoveryBoost     = 1.0   -- active multiplier
        ball.recoveryBoostTime = 0.0   -- seconds remaining

        ball.damageNumbers = {}
    end

    ball.shadowOffset = { x = 3, y = 5 }
    ball.shadowColor  = { 0, 0, 0, 0.3 }
    ball.shadowScale  = { x = 1.2, y = 0.6 }

    return ball
end

-- ── Update ─────────────────────────────────────────────────────────────────

function Ball:update(dt, audio)
    -- Friction for pushable ball
    if not self.isPlayer then
        local friction = 0.98
        self.vx = self.vx * friction
        self.vy = self.vy * friction
        if math.abs(self.vx) < 1 then self.vx = 0 end
        if math.abs(self.vy) < 1 then self.vy = 0 end
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    if self.isPlayer then
        self.damageTimer          = self.damageTimer + dt
        self.fireResistanceTime   = math.max(0, self.fireResistanceTime - dt)
        self.timeSinceLastDamage  = self.timeSinceLastDamage + dt

        -- Tick down recovery boost
        if self.recoveryBoostTime > 0 then
            self.recoveryBoostTime = self.recoveryBoostTime - dt
            if self.recoveryBoostTime <= 0 then
                self.recoveryBoostTime = 0
                self.recoveryBoost     = 1.0
            end
        end

        -- Health regeneration (base rate × boost multiplier)
        if self.timeSinceLastDamage >= self.regenDelay
        and self.health < self.maxHealth then
            self.health = math.min(self.maxHealth,
                self.health + self.regenRate * self.recoveryBoost * dt)
        end

        -- Floating damage numbers
        for i = #self.damageNumbers, 1, -1 do
            local d  = self.damageNumbers[i]
            d.y      = d.y - 50 * dt
            d.life   = d.life - dt
            d.alpha  = math.max(0, d.life / d.maxLife)
            if d.life <= 0 then table.remove(self.damageNumbers, i) end
        end
    end

    local Physics = require("src/physics")
    Physics.handleBoundaryCollision(self, audio)
end

-- ── Recovery boost ─────────────────────────────────────────────────────────

-- Called from main.lua when >= 2 fires are extinguished in one frame.
-- Stacks duration if already active; multiplier takes the higher value.
function Ball:triggerRecoveryBoost(multiplier, duration)
    self.recoveryBoost     = math.max(self.recoveryBoost, multiplier)
    self.recoveryBoostTime = math.max(self.recoveryBoostTime, duration)
end

-- ── Damage ─────────────────────────────────────────────────────────────────

function Ball:takeDamage(amount, audio)
    if not self.isPlayer or self.fireResistanceTime > 0 then return false end

    self.health = math.max(0, self.health - amount)
    self.fireResistanceTime  = self.fireResistanceDuration
    self.timeSinceLastDamage = 0

    table.insert(self.damageNumbers, {
        x       = self.x + (math.random() - 0.5) * 20,
        y       = self.y - 20,
        amount  = amount,
        life    = 1.5,
        maxLife = 1.5,
        alpha   = 1,
    })

    if audio then audio:playFireDamage() end
    return true
end

function Ball:getHealthPercentage()
    if not self.isPlayer then return 1 end
    return self.health / self.maxHealth
end

function Ball:isDead()
    return self.isPlayer and self.health <= 0
end

-- ── Draw ───────────────────────────────────────────────────────────────────

function Ball:drawShadow()
    love.graphics.setColor(
        self.shadowColor[1], self.shadowColor[2],
        self.shadowColor[3], self.shadowColor[4])
    love.graphics.ellipse("fill",
        self.x + self.shadowOffset.x,
        self.y + self.shadowOffset.y,
        self.radius * self.shadowScale.x,
        self.radius * self.shadowScale.y)
end

function Ball:draw()
    -- Base colour (health-tinted for player)
    if self.isPlayer then
        local hp = self:getHealthPercentage()
        love.graphics.setColor(self.color[1], self.color[2] * hp, self.color[3])
    else
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    end
    love.graphics.circle("fill", self.x, self.y, self.radius)

    if self.isPlayer then
        local t = love.timer.getTime()

        -- Damage flash
        if self.fireResistanceTime > 0 then
            local intensity = self.fireResistanceTime / self.fireResistanceDuration
            local pulse     = (math.sin(t * 20) + 1) * 0.5
            love.graphics.setColor(1, 0.1, 0.1, 0.3 + pulse * 0.3 * intensity)
            love.graphics.circle("fill", self.x, self.y, self.radius * 1.2)
            love.graphics.setColor(1, 0.3, 0.3, intensity * 0.8)
            love.graphics.circle("line", self.x, self.y, self.radius + 8)
        end

        -- Recovery boost indicator: gold pulsing ring
        if self.recoveryBoostTime > 0 then
            local pulse = 0.55 + 0.45 * math.sin(t * 7)
            love.graphics.setColor(1, 0.85, 0.1, pulse * 0.9)
            love.graphics.setLineWidth(2.5)
            love.graphics.circle("line", self.x, self.y, self.radius + 13)
            love.graphics.setLineWidth(1)
            -- Small countdown arc (full circle = 5 s, shrinks to 0)
            -- drawn as a slightly thicker overlay so the player sees time left
            local frac    = math.min(1, self.recoveryBoostTime / 5.0)
            local arcEnd  = -math.pi / 2 + frac * 2 * math.pi
            love.graphics.setColor(1, 1, 0.3, 0.5)
            love.graphics.arc("line", "open",
                self.x, self.y, self.radius + 13,
                -math.pi / 2, arcEnd, 40)
        end

        -- Normal regen glow
        if self.recoveryBoostTime <= 0
        and self.timeSinceLastDamage >= self.regenDelay
        and self.health < self.maxHealth then
            local pulse = (math.sin(t * 6) + 1) * 0.5
            love.graphics.setColor(0.3, 1, 0.3, 0.2 + pulse * 0.3)
            love.graphics.circle("line", self.x, self.y, self.radius + 5)
        end

        -- Floating damage numbers
        for _, d in ipairs(self.damageNumbers) do
            love.graphics.setColor(1, 0.3, 0.3, d.alpha)
            love.graphics.print("-" .. d.amount, d.x - 10, d.y)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Ball:keypressed(key)  end
function Ball:keyreleased(key) end

return Ball
