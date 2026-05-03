local UI = {}
local Screen = require('src.screen')

function UI.draw(gameState, audio)
    local W, H = Screen.W, Screen.H

    -- ── Health strip ───────────────────────────────────────────────────────
    if gameState.playerBall then
        local hp    = gameState.playerBall.health / gameState.playerBall.maxHealth
        local stripW = 200
        local stripH = 4       -- thin
        local x, y  = 10, 10
        local t     = love.timer.getTime()

        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", x, y, stripW, stripH, 2, 2)

        -- Fill: green → orange → red
        local r = math.min(1, 2 * (1 - hp) + 0.1)
        local g = math.min(1, 2 * hp)
        -- Low health pulse
        if hp < 0.25 then
            local pulse = (math.sin(t * 8) + 1) * 0.5
            r = math.min(1, r + pulse * 0.3)
        end
        love.graphics.setColor(r, g, 0.1, 0.95)
        love.graphics.rectangle("fill", x, y, stripW * hp, stripH, 2, 2)

        -- Recovery boost indicator: gold bar underneath
        if gameState.playerBall.recoveryBoostTime and gameState.playerBall.recoveryBoostTime > 0 then
            local frac  = math.min(1, gameState.playerBall.recoveryBoostTime / 5.0)
            local pulse = 0.6 + 0.4 * math.sin(t * 7)
            love.graphics.setColor(1, 0.85, 0.1, pulse)
            love.graphics.rectangle("fill", x, y + stripH + 2, stripW * frac, 2, 1, 1)
        end

        -- Critical warning text
        if hp < 0.15 then
            local alpha = (math.sin(t * 10) + 1) * 0.5
            love.graphics.setColor(1, 0.2, 0.2, alpha)
            love.graphics.printf("CRITICAL", x, y + stripH + 6, stripW, "left")
        end
    end

    -- ── Screen-edge damage flash ────────────────────────────────────────────
    if gameState.playerBall and gameState.playerBall.fireResistanceTime > 0 then
        local alpha = (gameState.playerBall.fireResistanceTime
                      / gameState.playerBall.fireResistanceDuration) * 0.28
        local edge  = 18
        love.graphics.setColor(1, 0.1, 0.1, alpha)
        love.graphics.rectangle("fill", 0,       0,       W,    edge)   -- top
        love.graphics.rectangle("fill", 0,       H-edge,  W,    edge)   -- bottom
        love.graphics.rectangle("fill", 0,       0,       edge, H)      -- left
        love.graphics.rectangle("fill", W-edge,  0,       edge, H)      -- right
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return UI
