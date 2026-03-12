local Fire = {}
Fire.__index = Fire

function Fire:new(x, y, radius, color, strategy)
    local fire = {}
    setmetatable(fire, Fire)
    
    fire.x = x or 0
    fire.y = y or 0
    fire.radius = radius or 15
    fire.baseColor = color or {1, 0.3, 0}  -- orange-red by default
    fire.color = {fire.baseColor[1], fire.baseColor[2], fire.baseColor[3]}
    
    -- Fire animation properties
    fire.flickerTime = 0
    fire.flickerSpeed = 8
    fire.flickerIntensity = 0.3
    
    -- Shadow properties - fires don't need shadows based on user feedback
    fire.shadowOffset = {x = 2, y = 3}
    fire.shadowColor = {0, 0, 0, 0.4}  -- Darker shadow for fire
    fire.shadowScale = {x = 1.2, y = 0.6}
    
    -- Strategy properties
    fire.strategy = strategy or "chase"  -- hardcoded to chase for now
    fire.speed = 50  -- base movement speed
    fire.vx = 0
    fire.vy = 0
    fire.targetX = x
    fire.targetY = y
    fire.strategyTimer = 0
    
    return fire
end

function Fire:update(dt, playerBall)
    -- Update flicker animation only
    self.flickerTime = self.flickerTime + dt * self.flickerSpeed
    
    -- Create flickering effect by modifying color intensity
    local flicker = math.sin(self.flickerTime) * self.flickerIntensity + 0.7
    self.color[1] = math.min(1, self.baseColor[1] * flicker + 0.3)
    self.color[2] = math.min(1, self.baseColor[2] * flicker)
    self.color[3] = self.baseColor[3] * 0.1  -- Keep blue component low
    
    -- Update strategy timer
    self.strategyTimer = self.strategyTimer + dt
    
    -- Execute strategy-based movement
    self:executeStrategy(dt, playerBall)
    
    -- Apply velocity to position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Keep fire within screen bounds
    local margin = self.radius
    self.x = math.max(margin, math.min(love.graphics.getWidth() - margin, self.x))
    self.y = math.max(margin, math.min(love.graphics.getHeight() - margin, self.y))
end

function Fire:executeStrategy(dt, playerBall)
    if self.strategy == "chase" then
        self:executeChase(dt, playerBall)
    elseif self.strategy == "block" then
        self:executeBlock(dt, playerBall)
    elseif self.strategy == "cluster" then
        self:executeCluster(dt, playerBall)
    elseif self.strategy == "wait" then
        self:executeWait(dt, playerBall)
    end
end

function Fire:executeChase(dt, playerBall)
    -- Move directly toward player
    local dx = playerBall.x - self.x
    local dy = playerBall.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance > 0 then
        local dirX = dx / distance
        local dirY = dy / distance
        self.vx = dirX * self.speed
        self.vy = dirY * self.speed
    else
        self.vx = 0
        self.vy = 0
    end
end

function Fire:executeBlock(dt, playerBall)
    -- Position to block player's escape route to nearest edge
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Find nearest screen edge to player
    local distToLeft = playerBall.x
    local distToRight = screenW - playerBall.x
    local distToTop = playerBall.y
    local distToBottom = screenH - playerBall.y
    
    local minDist = math.min(distToLeft, distToRight, distToTop, distToBottom)
    
    -- Set target position to block escape
    if minDist == distToLeft then
        self.targetX = playerBall.x * 0.5
        self.targetY = playerBall.y
    elseif minDist == distToRight then
        self.targetX = playerBall.x + (screenW - playerBall.x) * 0.5
        self.targetY = playerBall.y
    elseif minDist == distToTop then
        self.targetX = playerBall.x
        self.targetY = playerBall.y * 0.5
    else -- distToBottom
        self.targetX = playerBall.x
        self.targetY = playerBall.y + (screenH - playerBall.y) * 0.5
    end
    
    -- Move toward blocking position
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance > 5 then
        local dirX = dx / distance
        local dirY = dy / distance
        self.vx = dirX * self.speed
        self.vy = dirY * self.speed
    else
        self.vx = 0
        self.vy = 0
    end
end

function Fire:executeCluster(dt, playerBall)
    -- Move to a position near the player but maintain some distance from other fires
    -- For now, just orbit around the player at medium distance
    local orbitRadius = 100
    local orbitSpeed = 1.5
    
    -- Calculate orbit position
    local angle = self.strategyTimer * orbitSpeed
    self.targetX = playerBall.x + math.cos(angle) * orbitRadius
    self.targetY = playerBall.y + math.sin(angle) * orbitRadius
    
    -- Move toward orbit position
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance > 5 then
        local dirX = dx / distance
        local dirY = dy / distance
        self.vx = dirX * self.speed * 0.7  -- Slower movement for clustering
        self.vy = dirY * self.speed * 0.7
    else
        self.vx = 0
        self.vy = 0
    end
end

function Fire:executeWait(dt, playerBall)
    -- Stay mostly still, with occasional small movements
    if self.strategyTimer > 2.0 then
        -- Reset timer and set small random movement
        self.strategyTimer = 0
        local angle = math.random() * math.pi * 2
        self.vx = math.cos(angle) * self.speed * 0.2
        self.vy = math.sin(angle) * self.speed * 0.2
    else
        -- Gradually slow down
        self.vx = self.vx * 0.95
        self.vy = self.vy * 0.95
    end
end

function Fire:drawShadow()
    -- Skip drawing shadow for fires per user feedback
    return
end

function Fire:draw()
    -- Draw as triangle shape per user feedback
    local height = self.radius * 1.5
    local baseWidth = self.radius * 1.2
    
    -- Main fire triangle
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    local vertices = {
        self.x, self.y - height,  -- top point
        self.x - baseWidth/2, self.y + height/2,  -- bottom left
        self.x + baseWidth/2, self.y + height/2   -- bottom right
    }
    love.graphics.polygon("fill", vertices)
    
    -- Inner core triangle (brighter)
    love.graphics.setColor(1, 0.8, 0.2)
    local coreVertices = {
        self.x, self.y - height * 0.6,
        self.x - baseWidth/3, self.y + height/3,
        self.x + baseWidth/3, self.y + height/3
    }
    love.graphics.polygon("fill", coreVertices)
    
    -- Center hot spot
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.circle("fill", self.x, self.y, self.radius * 0.2)
end

return Fire