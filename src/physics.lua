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

-- Handle collision physics
function Physics.handleCollision(playerBall, pushBall)
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
end

return Physics