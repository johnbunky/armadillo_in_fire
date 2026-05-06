local Physics = {}
local Screen  = require('src.screen')

-- ── Collision detection ────────────────────────────────────────────────────

function Physics.checkCollision(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx*dx + dy*dy) < (a.radius + b.radius)
end

-- Same shape as checkCollision but named for fire/coin use
function Physics.checkCoinCollision(ball, coin)
    local dx = ball.x - coin.x
    local dy = ball.y - coin.y
    return math.sqrt(dx*dx + dy*dy) < (ball.radius + coin.radius)
end

-- ── Ball ↔ ball collision ──────────────────────────────────────────────────

function Physics.handleCollision(playerBall, pushBall, audio)
    if not Physics.checkCollision(playerBall, pushBall) then return end

    local dx = pushBall.x - playerBall.x
    local dy = pushBall.y - playerBall.y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist == 0 then dx, dy, dist = 1, 0, 1 end

    -- Normalise collision axis
    local nx = dx / dist
    local ny = dy / dist

    -- Separate so they no longer overlap (equal split)
    local overlap = (playerBall.radius + pushBall.radius) - dist
    pushBall.x   = pushBall.x   + nx * overlap * 0.5
    pushBall.y   = pushBall.y   + ny * overlap * 0.5
    playerBall.x = playerBall.x - nx * overlap * 0.5
    playerBall.y = playerBall.y - ny * overlap * 0.5

    -- Transfer momentum: only the component of player velocity
    -- along the collision axis drives the push (no phantom force).
    local playerSpeed = playerBall.vx * nx + playerBall.vy * ny
    if playerSpeed > 0 then
        local transfer = playerSpeed * 1.4
        pushBall.vx = pushBall.vx + nx * transfer
        pushBall.vy = pushBall.vy + ny * transfer
        playerBall.vx = playerBall.vx - nx * transfer * 0.2
        playerBall.vy = playerBall.vy - ny * transfer * 0.2
    end

    -- Corner escape: if stone is pinned near two walls, add a nudge
    -- so it doesn't get completely stuck
    local margin = pushBall.radius * 1.5
    local W, H   = Screen.W, Screen.H
    local nearL  = pushBall.x < margin
    local nearR  = pushBall.x > W - margin
    local nearT  = pushBall.y < margin
    local nearB  = pushBall.y > H - margin
    if (nearL or nearR) and (nearT or nearB) then
        -- Push diagonally away from the corner
        local ex = nearL and 1 or (nearR and -1 or 0)
        local ey = nearT and 1 or (nearB and -1 or 0)
        local escapeForce = math.max(0, playerSpeed) * 0.5 + 80
        pushBall.vx = pushBall.vx + ex * escapeForce
        pushBall.vy = pushBall.vy + ey * escapeForce
    end

    if audio then audio:playBallPush() end
end

-- ── Boundary collision — uses logical canvas size ─────────────────────────

function Physics.handleBoundaryCollision(ball, audio)
    local bounced       = false
    local bounceReduce  = 0.7
    local W, H          = Screen.W, Screen.H   -- logical coords, not screen pixels

    if ball.x - ball.radius < 0 then
        ball.x  = ball.radius
        ball.vx = math.abs(ball.vx) * bounceReduce
        bounced = true
    elseif ball.x + ball.radius > W then
        ball.x  = W - ball.radius
        ball.vx = -math.abs(ball.vx) * bounceReduce
        bounced = true
    end

    if ball.y - ball.radius < 0 then
        ball.y  = ball.radius
        ball.vy = math.abs(ball.vy) * bounceReduce
        bounced = true
    elseif ball.y + ball.radius > H then
        ball.y  = H - ball.radius
        ball.vy = -math.abs(ball.vy) * bounceReduce
        bounced = true
    end

    if bounced and audio then
        local spd = math.sqrt(ball.vx*ball.vx + ball.vy*ball.vy)
        if spd > 50 then audio:playBallCollision() end
    end

    return bounced
end

return Physics
