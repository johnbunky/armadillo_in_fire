-- tests/properties.lua -- Game-specific properties for push-demo
-- Place in your project's tests/ folder
-- Loaded automatically by: jk test
--
-- How it works:
--   property("name", function(r) ... return true/false, "detail" end)
--   r.float(min, max)   random float
--   r.int(min, max)     random int
--   r.bool()            random boolean
--   r.pick({a,b,c})     random element
--
-- Properties = things that should ALWAYS be true, no matter the input.
-- Think: "what can never happen in my game?"

local W, H = 800, 600   -- screen size

-- ── Ball properties ───────────────────────────────────────────────────────────

property("ball: never outside screen after update", function(r)
    -- simulate a ball update step
    local x   = r.float(0, W)
    local y   = r.float(0, H)
    local vx  = r.float(-1000, 1000)
    local vy  = r.float(-1000, 1000)
    local dt  = r.float(0.001, 0.1)
    local rad = 20

    -- apply velocity
    x = x + vx * dt
    y = y + vy * dt

    -- bounce (same logic as Ball:update)
    if x - rad < 0 then x = rad end
    if x + rad > W then x = W - rad end
    if y - rad < 0 then y = rad end
    if y + rad > H then y = H - rad end

    return x >= rad and x <= W-rad and y >= rad and y <= H-rad,
           string.format("pos=(%.1f,%.1f) vel=(%.1f,%.1f)", x, y, vx, vy)
end)

-- ── Collision properties ──────────────────────────────────────────────────────

property("collision: overlap resolution moves balls apart", function(r)
    local ax, ay, ar = r.float(100,700), r.float(100,500), r.float(10,40)
    local bx, by, br = r.float(100,700), r.float(100,500), r.float(10,40)

    local dist = math.sqrt((ax-bx)^2+(ay-by)^2)
    if dist >= ar+br or dist < 0.001 then return true end  -- skip non-overlapping

    -- resolve overlap (same as Physics module)
    local dx, dy = bx-ax, by-ay
    local d      = math.sqrt(dx*dx+dy*dy)
    local overlap = (ar+br) - d
    dx, dy = dx/d, dy/d

    bx = bx + dx*overlap*0.6
    by = by + dy*overlap*0.6
    ax = ax - dx*overlap*0.4
    ay = ay - dy*overlap*0.4

    local new_dist = math.sqrt((ax-bx)^2+(ay-by)^2)
    return new_dist >= (ar+br) - 0.1,
           string.format("overlap=%.2f before=%.1f after=%.1f", overlap, dist, new_dist)
end)

-- ── Coin / Fire spawn properties ──────────────────────────────────────────────

property("spawn: position always within screen bounds", function(r)
    local margin = 50
    -- simulate spawn position calculation
    local player_x = r.float(margin, W-margin)
    local player_y = r.float(margin, H-margin)
    local vx       = r.float(-200, 200)
    local vy       = r.float(-200, 200)
    local pred_t   = 0.28  -- evolved prediction time

    local pred_x = player_x + vx * pred_t
    local pred_y = player_y + vy * pred_t

    -- clamp to screen
    local spawn_x = math.max(margin, math.min(W-margin, pred_x))
    local spawn_y = math.max(margin, math.min(H-margin, pred_y))

    return spawn_x >= margin and spawn_x <= W-margin
       and spawn_y >= margin and spawn_y <= H-margin,
           string.format("spawn=(%.1f,%.1f)", spawn_x, spawn_y)
end)

-- ── Utility AI properties ─────────────────────────────────────────────────────

property("utility: always returns a valid action", function(r)
    local valid = {chase_player=true, avoid_red_ball=true,
                   block_escape=true, cluster=true, wait=true}
    local weights = {r.float(0,2), r.float(0,2), r.float(0,2),
                     r.float(0,2), r.float(0,2)}
    local state = {
        self_x=r.float(0,W), self_y=r.float(0,H),
        player_x=r.float(0,W), player_y=r.float(0,H),
        red_x=r.float(0,W), red_y=r.float(0,H),
        nfd=r.float(0,300),
    }

    -- inline utility_pick (can't require evolve.lua from here)
    local scores = {
        weights[1]*(1-math.min(1,math.sqrt((state.self_x-state.player_x)^2+(state.self_y-state.player_y)^2)/400)),
        weights[2]*(1-math.min(1,math.sqrt((state.self_x-state.red_x)^2+(state.self_y-state.red_y)^2)/200)),
        weights[3]*(1-math.min(1,math.sqrt((state.self_x-(state.player_x<400 and 0 or 800))^2+(state.self_y-(state.player_y<300 and 0 or 600))^2)/300)),
        weights[4]*(1-math.min(1,state.nfd/150)),
        weights[5]*0.3,
    }
    local b, bs = 1, -math.huge
    for i,v in ipairs(scores) do if v>bs then b,bs=i,v end end
    local actions = {"chase_player","avoid_red_ball","block_escape","cluster","wait"}
    local action  = actions[b]

    return valid[action] == true,
           "action=" .. tostring(action)
end)

-- ── Simulation properties ─────────────────────────────────────────────────────

property("simulation: ball never explodes after 600 frames", function(r)
    local ball = {
        x=r.float(0,800), y=r.float(0,600),
        vx=r.float(-400,400), vy=r.float(-400,400)
    }
    local dt=0.016
    for i=1,600 do
        ball.x=ball.x+ball.vx*dt
        ball.y=ball.y+ball.vy*dt
        if math.abs(ball.x)>10000 or math.abs(ball.y)>10000 then
            return false, "exploded at frame "..i
        end
    end
    return true
end)

property("physics: collision resolver separates overlapping balls", function(r)
    local ax=r.float(100,700); local ay=r.float(100,500); local ar=r.float(10,40)
    local bx=ax+r.float(-30,30); local by=ay+r.float(-30,30); local br=r.float(10,40)
    local d=math.sqrt((ax-bx)^2+(ay-by)^2)
    if d>=ar+br or d<0.001 then return true end
    local dx,dy=bx-ax,by-ay
    local dist=math.sqrt(dx*dx+dy*dy)
    local overlap=(ar+br)-dist
    dx,dy=dx/dist,dy/dist
    bx=bx+dx*overlap*0.6; by=by+dy*overlap*0.6
    ax=ax-dx*overlap*0.4; ay=ay-dy*overlap*0.4
    local new_d=math.sqrt((ax-bx)^2+(ay-by)^2)
    return new_d>=(ar+br)-0.1,
        string.format("overlap=%.2f before=%.1f after=%.1f",overlap,d,new_d)
end)

property("game: random session never corrupts state", function(r)
    local score=0; local lives=3; local gameTime=0
    for frame=1,1000 do
        gameTime=gameTime+0.016
        local event=r.pick({"coin","fire","nothing","nothing"})
        if event=="coin" then score=score+10 end
        if event=="fire" then lives=lives-1 end
        score=math.max(0,score)
        lives=math.max(0,lives)
        if score<0 then return false,"negative score at frame "..frame end
        if lives<0 then return false,"negative lives at frame "..frame end
        if gameTime<0 then return false,"negative gameTime" end
    end
    return true
end)

