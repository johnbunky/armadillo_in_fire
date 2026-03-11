local Physics = {}

-- Collision detection function
function Physics.checkCollision(ball1, ball2)
    local dx = ball1.x - ball2.x
    local dy = ball1.y - ball2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (ball1.radius + ball2.radius)
end

-- Check collision between ball and coin
function Physics.checkCoinCollision(ball, coin)
    local dx = ball.x - coin.x
    local dy = ball.y - coin.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (ball.radius + coin.radius)
end

-- Handle collision physics with audio support
function Physics.handleCollision(playerBall, pushBall, audio)
    if not Physics.checkCollision(playerBall, pushBall) then
        return
    end
    
    -- Calculate collision direction
    local dx = pushBall.x - playerBall.x
    local dy = pushBall.y - playerBall.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Avoid division by zero
    if distance == 0 then
        dx, dy = 1, 0
        distance = 1
    end
    
    -- Normalize direction
    dx = dx / distance
    dy = dy / distance
    
    -- Separate balls to prevent overlap
    local overlap = (playerBall.radius + pushBall.radius) - distance
    pushBall.x = pushBall.x + dx * overlap * 0.6
    pushBall.y = pushBall.y + dy * overlap * 0.4
    playerBall.x = playerBall.x - dx * overlap * 0.4
    playerBall.y = playerBall.y - dy * overlap * 0.4
    
    -- Transfer momentum (player ball pushes the other)
    local pushForce = 200
    pushBall.vx = pushBall.vx + dx * pushForce
    pushBall.vy = pushBall.vy + dy * pushForce
    
    -- Play collision sound effect
    if audio then
        audio:playBallPush()
    end
end

-- Handle ball boundary collision with audio support
function Physics.handleBoundaryCollision(ball, audio)
    local bounced = false
    local bounceReduction = 0.7
    
    -- Check and handle boundary collisions
    if ball.x - ball.radius < 0 then
        ball.x = ball.radius
        ball.vx = -ball.vx * bounceReduction
        bounced = true
    elseif ball.x + ball.radius > love.graphics.getWidth() then
        ball.x = love.graphics.getWidth() - ball.radius
        ball.vx = -ball.vx * bounceReduction
        bounced = true
    end
    
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.vy = -ball.vy * bounceReduction
        bounced = true
    elseif ball.y + ball.radius > love.graphics.getHeight() then
        ball.y = love.graphics.getHeight() - ball.radius
        ball.vy = -ball.vy * bounceReduction
        bounced = true
    end
    
    -- Play bounce sound if ball hit a wall
    if bounced and audio then
        -- Only play bounce sound for fast-moving balls to avoid spam
        local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
        if speed > 50 then
            audio:playBallCollision()
        end
    end
    
    return bounced
end

return Physics