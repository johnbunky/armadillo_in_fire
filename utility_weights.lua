-- Evolved Utility AI weights
-- [1]=chase [2]=avoid_red [3]=block_escape [4]=cluster [5]=wait
local UTILITY_WEIGHTS = { 2.0000, 1.7097, 0.6166, 0.9987, 0.1374 }

local function utility_pick(state, w)
    local s = {
        -- chase: how close am I to player (higher = closer = more useful to chase)
        w[1] * (1 - math.min(1, math.sqrt(
            (state.self_x - state.player_x)^2 +
            (state.self_y - state.player_y)^2) / 400)),

        -- avoid_red: how close am I to the red ball (higher = closer = danger)
        w[2] * (1 - math.min(1, math.sqrt(
            (state.self_x - state.red_x)^2 +
            (state.self_y - state.red_y)^2) / 200)),

        -- block_escape: how close am I to the nearest screen corner the player is fleeing toward
        w[3] * (1 - math.min(1, math.sqrt(
            (state.self_x - (state.player_x < 400 and 0 or 800))^2 +
            (state.self_y - (state.player_y < 300 and 0 or 600))^2) / 300)),

        -- cluster: how close am I to another fire (pack bonus)
        w[4] * (state.nfd and (1 - math.min(1, state.nfd / 150)) or 0),

        -- wait: small constant drive to do nothing
        w[5] * 0.3,
    }

    local best, bestScore = 1, -math.huge
    for i, v in ipairs(s) do
        if v > bestScore then
            best, bestScore = i, v
        end
    end

    return ({ "chase", "avoid", "block", "cluster", "wait" })[best]
end

return { weights = UTILITY_WEIGHTS, pick = utility_pick }
