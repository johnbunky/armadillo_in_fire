local UI = {}

function UI.draw(gameState, audio)
    -- Draw player health bar
    if gameState.playerBall then
        local healthPercent = gameState.playerBall.health / gameState.playerBall.maxHealth
        local barWidth = 200
        local barHeight = 20
        local barX = 10
        local barY = 10
        
        -- Health bar background
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
        
        -- Health bar fill with pulsing effect when low health
        local healthColor = {1 - healthPercent + 0.3, healthPercent, 0.2}  -- Red to green gradient
        
        -- Add pulsing effect when health is low
        if healthPercent < 0.25 then
            local pulse = (math.sin(love.timer.getTime() * 8) + 1) * 0.5  -- 0 to 1 pulse
            local pulseIntensity = 0.3
            healthColor[1] = math.min(1, healthColor[1] + pulse * pulseIntensity)
        end
        
        love.graphics.setColor(healthColor[1], healthColor[2], healthColor[3], 0.9)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
        
        -- Health bar border with warning color when low
        if healthPercent < 0.25 then
            love.graphics.setColor(1, 0.2, 0.2, 1)  -- Red border for low health
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
        
        -- Health text with color coding
        if healthPercent < 0.25 then
            love.graphics.setColor(1, 0.3, 0.3, 1)  -- Red text for critical health
        elseif healthPercent < 0.5 then
            love.graphics.setColor(1, 0.7, 0.3, 1)  -- Orange text for low health
        else
            love.graphics.setColor(1, 1, 1, 1)      -- White text for good health
        end
        
        -- Critical health warning
        if healthPercent < 0.15 then
            local warningAlpha = (math.sin(love.timer.getTime() * 10) + 1) * 0.5
            love.graphics.setColor(1, 0.2, 0.2, warningAlpha)
            love.graphics.printf("CRITICAL HEALTH!", 0, love.graphics.getHeight() * 0.3, love.graphics.getWidth(), "center")
        end
        
        -- Damage resistance indicator
        if gameState.playerBall.fireResistanceTime > 0 then
            love.graphics.setColor(0.8, 0.8, 1, 0.7)
            love.graphics.print("FIRE RESISTANCE", barX + barWidth + 10, barY + 5)
        end
    end
    
    -- Draw screen-edge damage indicators when player is taking damage
    if gameState.playerBall and gameState.playerBall.fireResistanceTime > 0 then
        local damageAlpha = gameState.playerBall.fireResistanceTime / gameState.playerBall.fireResistanceDuration * 0.3
        love.graphics.setColor(1, 0.1, 0.1, damageAlpha)
        
        -- Draw damage overlay around screen edges
        local edgeThickness = 20
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), edgeThickness)  -- Top
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() - edgeThickness, love.graphics.getWidth(), edgeThickness)  -- Bottom
        love.graphics.rectangle("fill", 0, 0, edgeThickness, love.graphics.getHeight())  -- Left
        love.graphics.rectangle("fill", love.graphics.getWidth() - edgeThickness, 0, edgeThickness, love.graphics.getHeight())  -- Right
    end
end

function UI:drawScore(score)
end

function UI:drawLives(lives)
end

function UI:drawGameOver()
end

return UI
