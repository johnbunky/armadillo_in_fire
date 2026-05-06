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
        ball.recoveryBoost     = 1.0
        ball.recoveryBoostTime = 0.0   -- seconds remaining

        ball.damageNumbers = {}
    end

    ball.shadowOffset = { x = 3, y = 5 }
    ball.shadowColor  = { 0, 0, 0, 0.3 }
    ball.shadowScale  = { x = 1.2, y = 0.6 }

    -- Animation state
    ball.rollAngle    = 0   -- current snap angle
    ball.rollAccum    = 0   -- distance accumulator for step-roll
    ball.moveAngle    = 0   -- direction of travel

    -- Stone polygon offsets (only used for pushable ball)
    if not ball.isPlayer then
        math.randomseed(42)  -- fixed seed → same shape every run
        ball.stoneVerts = {}
        local n = 9
        for i = 1, n do
            local a     = (i-1) * (2*math.pi/n)
            local jitter = 0.72 + math.random() * 0.28
            ball.stoneVerts[i] = { math.cos(a)*jitter*1.35, math.sin(a)*jitter*1.35 }
        end
        math.randomseed(os.time())  -- restore random
    end

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

    -- Step-roll: accumulate distance, snap by one plate-width each step.
    -- Like a cube tipping over each edge rather than spinning smoothly.
    local spd = math.sqrt(self.vx^2 + self.vy^2)
    if spd > 5 then
        self.moveAngle = math.atan2(self.vy, self.vx)
        local PLATES   = 5
        local plateArc = (2 * math.pi) / PLATES     -- angle per plate
        local stepDist = self.radius * plateArc      -- px per step
        self.rollAccum = (self.rollAccum or 0) + spd * dt
        local steps    = math.floor(self.rollAccum / stepDist)
        if steps > 0 then
            self.rollAngle = self.rollAngle + steps * plateArc
            self.rollAccum = self.rollAccum - steps * stepDist
        end
    end

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
    local t   = love.timer.getTime()
    local spd = math.sqrt(self.vx^2 + self.vy^2)
    local r   = self.radius

    if self.isPlayer then
        local rolling = spd > 60
        local hp      = self:getHealthPercentage()

        -- colour palette
        local shellDark  = {0.38*hp, 0.22*hp, 0.08*hp}
        local shellMid   = {0.52*hp, 0.32*hp, 0.12*hp}
        local shellLight = {0.68*hp, 0.45*hp, 0.18*hp}
        local belly      = {0.88*hp, 0.72*hp, 0.50*hp}
        local skinTone   = {0.76*hp, 0.58*hp, 0.38*hp}

        love.graphics.push()
        love.graphics.translate(self.x, self.y)

        if rolling then
            -- ── Rolled-up ball ──────────────────────────────────────
            love.graphics.rotate(self.moveAngle or 0)
            love.graphics.rotate(self.rollAngle)

            -- Base shell
            love.graphics.setColor(shellMid)
            love.graphics.circle("fill", 0, 0, r)

            -- Shell plate segments — curved lines rotating with ball
            love.graphics.setColor(shellDark)
            love.graphics.setLineWidth(1.8)

            -- 3 main dividing curves (approximated with arc)
            local segs = {
                {ox= 0,    oy= r*0.5,  rad=r*0.85, a1=-2.4, a2=0.0},
                {ox= r*0.4,oy=-r*0.3,  rad=r*0.9,  a1= 1.8, a2=4.5},
                {ox=-r*0.5,oy=-r*0.2,  rad=r*0.8,  a1=-0.3, a2=2.1},
                {ox= 0,    oy=-r*0.6,  rad=r*0.75, a1= 0.4, a2=3.0},
            }
            for _, s in ipairs(segs) do
                love.graphics.arc("line","open", s.ox, s.oy, s.rad, s.a1, s.a2, 14)
            end

            -- Lighter highlight on one plate
            love.graphics.setColor(shellLight[1], shellLight[2], shellLight[3], 0.55)
            love.graphics.circle("fill", -r*0.28, -r*0.28, r*0.30)

            -- Outer rim
            love.graphics.setColor(shellDark)
            love.graphics.setLineWidth(1.5)
            love.graphics.circle("line", 0, 0, r)
            love.graphics.setLineWidth(1)

            -- Dust particles (simple static dots that fade with speed)
            local dustAlpha = math.min(1, (spd-60)/200)
            love.graphics.setColor(0.85, 0.78, 0.60, dustAlpha * 0.7)
            local dir = math.atan2(self.vy, self.vx) + math.pi
            for i = 1, 4 do
                local da  = dir + (math.random()-0.5)*0.8
                local dd  = r*1.2 + math.random()*r*0.8
                local ds  = 1.5 + math.random()*3
                love.graphics.circle("fill",
                    math.cos(da)*dd, math.sin(da)*dd, ds)
            end

        else
            -- ── Idle: front-facing standing armadillo ───────────────

            -- Tail (behind body, draw first)
            love.graphics.setColor(shellMid)
            love.graphics.setLineWidth(3)
            love.graphics.line(r*0.3, r*0.6,  r*0.7, r*0.85,  r*0.65, r*1.1)
            love.graphics.setLineWidth(1)

            -- Body (main shell oval)
            love.graphics.setColor(shellMid)
            love.graphics.ellipse("fill", 0, r*0.15, r*0.72, r*0.82)

            -- Belly patch (cream front)
            love.graphics.setColor(belly)
            love.graphics.ellipse("fill", 0, r*0.30, r*0.35, r*0.52)

            -- Shell bands (horizontal, 3 rows across body)
            love.graphics.setColor(shellDark)
            love.graphics.setLineWidth(1.5)
            local bandYs = {-r*0.18, r*0.12, r*0.42}
            for _, by in ipairs(bandYs) do
                local hw = math.sqrt(math.max(0, (r*0.72)^2 -
                           ((by - r*0.15)/(r*0.82))^2 * (r*0.72)^2)) * 0.88
                love.graphics.line(-hw, by, hw, by)
            end
            -- Vertical dividers on bands (2 lines)
            for _, bx in ipairs({-r*0.22, r*0.22}) do
                love.graphics.line(bx, -r*0.28, bx, r*0.52)
            end
            love.graphics.setLineWidth(1)

            -- Left arm
            love.graphics.setColor(skinTone)
            love.graphics.ellipse("fill", -r*0.78, r*0.10, r*0.18, r*0.28)
            -- Right arm
            love.graphics.ellipse("fill",  r*0.78, r*0.10, r*0.18, r*0.28)

            -- Legs
            love.graphics.setColor(skinTone)
            love.graphics.ellipse("fill", -r*0.38, r*0.90, r*0.18, r*0.22)
            love.graphics.ellipse("fill",  r*0.38, r*0.90, r*0.18, r*0.22)

            -- Head (large round)
            love.graphics.setColor(shellMid)
            love.graphics.circle("fill", 0, -r*0.72, r*0.48)

            -- Shell cap on top of head
            love.graphics.setColor(shellDark)
            love.graphics.setLineWidth(1.2)
            love.graphics.arc("line","open", 0, -r*0.72, r*0.46, -math.pi+0.3, -0.3, 16)
            love.graphics.line(-r*0.42, -r*0.76, -r*0.12, -r*0.72)
            love.graphics.line( r*0.42, -r*0.76,  r*0.12, -r*0.72)
            love.graphics.setLineWidth(1)

            -- Face area (cream)
            love.graphics.setColor(belly)
            love.graphics.ellipse("fill", 0, -r*0.62, r*0.30, r*0.28)

            -- Eyes fully black
            love.graphics.setColor(0, 0, 0)
            love.graphics.circle("fill", -r*0.18, -r*0.72, r*0.13)
            love.graphics.circle("fill",  r*0.18, -r*0.72, r*0.13)

            -- Nose
            love.graphics.setColor(0.55, 0.32, 0.22)
            love.graphics.ellipse("fill", 0, -r*0.52, r*0.08, r*0.055)

            -- Ears (tall, slightly pink inside)
            love.graphics.setColor(shellDark)
            love.graphics.ellipse("fill", -r*0.32, -r*1.18, r*0.14, r*0.28)
            love.graphics.ellipse("fill",  r*0.32, -r*1.18, r*0.14, r*0.28)
            love.graphics.setColor(0.82, 0.58, 0.52, 0.7)
            love.graphics.ellipse("fill", -r*0.32, -r*1.18, r*0.07, r*0.17)
            love.graphics.ellipse("fill",  r*0.32, -r*1.18, r*0.07, r*0.17)

            -- Idle breathing bob (tiny scale pulse)
            -- (handled by parent push/pop, no extra transform needed)
        end

        love.graphics.pop()

        -- Damage flash
        if self.fireResistanceTime > 0 then
            local intensity = self.fireResistanceTime / self.fireResistanceDuration
            local pulse     = (math.sin(t * 20) + 1) * 0.5
            love.graphics.setColor(1, 0.1, 0.1, 0.22 + pulse * 0.22 * intensity)
            love.graphics.circle("fill", self.x, self.y, r * 1.3)
            love.graphics.setColor(1, 0.3, 0.3, intensity * 0.6)
            love.graphics.setLineWidth(1.5)
            love.graphics.circle("line", self.x, self.y, r + 8)
            love.graphics.setLineWidth(1)
        end

        -- Recovery boost gold ring
        if self.recoveryBoostTime and self.recoveryBoostTime > 0 then
            local pulse = 0.55 + 0.45 * math.sin(t * 7)
            love.graphics.setColor(1, 0.85, 0.1, pulse * 0.9)
            love.graphics.setLineWidth(2.5)
            love.graphics.circle("line", self.x, self.y, r + 13)
            local frac   = math.min(1, self.recoveryBoostTime / 5.0)
            local arcEnd = -math.pi/2 + frac * 2 * math.pi
            love.graphics.setColor(1, 1, 0.3, 0.5)
            love.graphics.arc("line","open", self.x, self.y, r+13, -math.pi/2, arcEnd, 40)
            love.graphics.setLineWidth(1)
        end

        -- Regen glow
        if (not self.recoveryBoostTime or self.recoveryBoostTime <= 0)
        and self.timeSinceLastDamage >= self.regenDelay
        and self.health < self.maxHealth then
            local pulse = (math.sin(t * 6) + 1) * 0.5
            love.graphics.setColor(0.3, 1, 0.3, 0.2 + pulse * 0.3)
            love.graphics.circle("line", self.x, self.y, r + 5)
        end

        -- Floating damage numbers
        if not Ball._dmgFont then Ball._dmgFont = love.graphics.newFont(12) end
        love.graphics.setFont(Ball._dmgFont)
        for _, d in ipairs(self.damageNumbers) do
            love.graphics.setColor(1, 0.3, 0.3, d.alpha)
            love.graphics.print("-"..d.amount, d.x - 10, d.y)
        end

    else
        -- ── Stone ────────────────────────────────────────────────────
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.rollAngle)

        love.graphics.setColor(0.52, 0.42, 0.35)
        local verts = {}
        for _, v in ipairs(self.stoneVerts) do
            verts[#verts+1] = v[1] * r
            verts[#verts+1] = v[2] * r
        end
        love.graphics.polygon("fill", verts)
        love.graphics.setColor(0.32, 0.25, 0.20)
        love.graphics.setLineWidth(1.5)
        love.graphics.polygon("line", verts)
        love.graphics.setColor(0.28, 0.20, 0.15, 0.8)
        love.graphics.setLineWidth(1)
        love.graphics.line(-r*0.1, -r*0.5,  r*0.3,  r*0.2)
        love.graphics.line(-r*0.4,  r*0.1, -r*0.1,  r*0.55)
        love.graphics.setColor(0.72, 0.62, 0.52, 0.5)
        love.graphics.circle("fill", -r*0.25, -r*0.3, r*0.22)
        love.graphics.setLineWidth(1)
        love.graphics.pop()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Ball:keypressed(key)  end
function Ball:keyreleased(key) end

return Ball
