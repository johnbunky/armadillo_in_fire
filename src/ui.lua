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
        love.graphics.print(string.format("Health: %.0f/%.0f", gameState.playerBall.health, gameState.playerBall.maxHealth), barX, barY + 25)
        
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
        
        -- Health regeneration indicator
        if gameState.playerBall.timeSinceLastDamage >= gameState.playerBall.regenDelay and 
           gameState.playerBall.health < gameState.playerBall.maxHealth then
            love.graphics.setColor(0.3, 1, 0.3, 0.8)
            love.graphics.print("REGENERATING", barX, barY - 15)
        end
    end
    
    -- Draw fire count and stain count
    local fireCount = gameState.fires and #gameState.fires or 0
    local stainCount = gameState.stains and #gameState.stains or 0
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Active Fires: " .. fireCount, 10, 60)
    love.graphics.print("Extinguished: " .. stainCount, 10, 80)
    
    -- Draw instructions
    love.graphics.print("Push red ball into fires to extinguish them!", 10, 110)
    love.graphics.print("Avoid touching fires - they damage you!", 10, 130)
    
    -- Draw audio status
    if audio then
        local audioStatus = audio:isEnabled() and "ON" or "OFF"
        love.graphics.print("Audio: " .. audioStatus .. " (M to toggle)", love.graphics.getWidth() - 200, 10)
        love.graphics.print("Volume: " .. math.floor(audio.volume * 100) .. "% (+/- to adjust)", love.graphics.getWidth() - 200, 30)
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
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Handle score being a table or number
    local scoreValue = 0
    if type(score) == "table" then
        scoreValue = score.value or score.current or score[1] or 0
    elseif type(score) == "number" then
        scoreValue = score
    end
    
    love.graphics.print("Score: " .. scoreValue, 10, love.graphics.getHeight() - 40)
end

function UI:drawLives(lives)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Handle lives being a table or number
    local livesValue = 0
    if type(lives) == "table" then
        livesValue = lives.value or lives.current or lives[1] or 0
    elseif type(lives) == "number" then
        livesValue = lives
    end
    
    love.graphics.print("Lives: " .. livesValue, 10, love.graphics.getHeight() - 20)
end

function UI:drawGameOver(score)
    love.graphics.setColor(1, 0.2, 0.2, 0.9)
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Game Over text
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    local gameOverText = "GAME OVER"
    local gameOverWidth = love.graphics.getFont():getWidth(gameOverText)
    love.graphics.print(gameOverText, width/2 - gameOverWidth/2, height/2 - 100)
    
    -- Final score
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    
    -- Handle score being a table or number
    local scoreValue = 0
    if type(score) == "table" then
        scoreValue = score.value or score.current or score[1] or 0
    elseif type(score) == "number" then
        scoreValue = score
    end
    
    local scoreText = "Final Score: " .. scoreValue
    local scoreWidth = love.graphics.getFont():getWidth(scoreText)
    love.graphics.print(scoreText, width/2 - scoreWidth/2, height/2 - 20)
    
    -- Instructions
    love.graphics.setFont(love.graphics.newFont(16))
    local instructionText = "Press any key to continue..."
    local instructionWidth = love.graphics.getFont():getWidth(instructionText)
    love.graphics.print(instructionText, width/2 - instructionWidth/2, height/2 + 50)
end

return UI