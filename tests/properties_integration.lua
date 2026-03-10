-- tests/properties_integration.lua -- Interface contract tests for push-demo
-- Verifies every method that main.lua calls actually exists in each module.
-- No random inputs. No Love2D window. Just load + check.
--
-- Place in: push-demo/tests/properties_integration.lua
-- Run via:  jk test   (auto-loaded alongside properties.lua)
-- Or:       lua C:\path\to\tools\core\properties.lua --fast

-- ── Love2D mock ───────────────────────────────────────────────────────────────
-- Minimal stubs so modules can be required without a running Love2D instance.
-- Only mocks what modules actually call at load/init time.

love = love or {}

love.graphics = love.graphics or {
    getWidth       = function() return 800 end,
    getHeight      = function() return 600 end,
    newImage       = function() return {getWidth=function()return 32 end,
                                        getHeight=function()return 32 end} end,
    newCanvas      = function() return {} end,
    newFont        = function() return {} end,
    newShader      = function() return {} end,
    setColor       = function() end,
    setFont        = function() end,
    rectangle      = function() end,
    circle         = function() end,
    draw           = function() end,
    print          = function() end,
    printf         = function() end,
    push           = function() end,
    pop            = function() end,
    translate      = function() end,
    scale          = function() end,
    rotate         = function() end,
    clear          = function() end,
    present        = function() end,
    setCanvas      = function() end,
    setBlendMode   = function() end,
    setLineWidth   = function() end,
    line           = function() end,
    getFont        = function() return {} end,
}

love.audio = love.audio or {
    newSource      = function() return {
        play       = function() end,
        stop       = function() end,
        pause      = function() end,
        resume     = function() end,
        setLooping = function() end,
        setVolume  = function() end,
        isPlaying  = function() return false end,
        clone      = function(self) return self end,
    } end,
    setVolume      = function() end,
    getVolume      = function() return 1 end,
}

love.keyboard = love.keyboard or {
    isDown         = function() return false end,
}

love.math = love.math or {
    random         = math.random,
    randomseed     = math.randomseed,
    newRandomGenerator = function() return {random=math.random} end,
}

love.timer = love.timer or {
    getTime        = function() return os.clock() end,
    getDelta       = function() return 0.016 end,
}

love.filesystem = love.filesystem or {
    read           = function() return nil end,
    write          = function() return true end,
    getInfo        = function() return nil end,
}

love.window = love.window or {
    setTitle       = function() end,
    getTitle       = function() return "" end,
    setMode        = function() end,
}

love.system = love.system or {
    getOS          = function() return "Windows" end,
    getProcessorCount = function() return 4 end,
}

love.data = love.data or {
    newByteData    = function(s) return {getString=function()return s end} end,
    compress       = function(f,d) return d end,
    decompress     = function(f,d) return d end,
}

-- Some audio modules call love.audio methods at init time
-- Extend the source mock to be more complete
local function make_source()
    local s = {}
    s.play        = function() end
    s.stop        = function() end
    s.pause       = function() end
    s.resume      = function() end
    s.setLooping  = function() end
    s.setVolume   = function() end
    s.setPosition = function() end
    s.setPitch    = function() end
    s.isPlaying   = function() return false end
    s.isStopped   = function() return true end
    s.clone       = function(self) return make_source() end
    s.release     = function() end
    return s
end

love.audio.newSource  = function() return make_source() end
love.audio.play       = function() end
love.audio.stop       = function() end
love.audio.pause      = function() end
love.audio.resume     = function() end
love.audio.setVolume  = function() end
love.audio.getVolume  = function() return 1 end

-- math.random needs a seed
math.randomseed(42)

-- inject mock into _G so require()'d modules can see it
_G.love = love

-- ── safe require ──────────────────────────────────────────────────────────────

local function safe_require(modname)
    -- clear from cache so re-require works cleanly
    package.loaded[modname] = nil
    local ok, mod = pcall(require, modname)
    if not ok then return nil, tostring(mod) end
    return mod, nil
end

local function check_methods(mod, mod_name, methods)
    for _, m in ipairs(methods) do
        if type(mod[m]) ~= "function" then
            return false, mod_name .. "." .. m .. " expected function, got " ..
                          type(mod[m])
        end
    end
    return true
end

-- ── Audio contract ────────────────────────────────────────────────────────────

property("contract: Audio has all required methods", function(r)
    local Audio, err = safe_require("src.audio")
    if not Audio then return false, "require failed: " .. err end
    return check_methods(Audio, "Audio", {
        "init", "playMusic", "stopMusic", "pauseMusic",
        "resumeMusic", "playSound",
    })
end)

-- ── Ball contract ─────────────────────────────────────────────────────────────

property("contract: Ball has all required methods", function(r)
    local Ball, err = safe_require("src.ball")
    if not Ball then return false, "require failed: " .. err end
    -- Ball is a class -- check prototype methods
    if not Ball.new then return false, 'Ball missing :new constructor' end
    local instance = Ball:new(400, 300)
    if not instance then return false, "Ball:new failed" end
    return check_methods(instance, "Ball", {
        "update", "draw", "keypressed", "keyreleased",
    })
end)

-- ── Fire contract ─────────────────────────────────────────────────────────────

property("contract: Fire has all required methods", function(r)
    local Fire, err = safe_require("src.fire")
    if not Fire then return false, "require failed: " .. err end
    if not Fire.new then return false, 'Fire missing :new constructor' end
    local instance = Fire:new(100, 100)
    if not instance then return false, "Fire:new failed" end
    return check_methods(instance, "Fire", {"update", "draw"})
end)

property("contract: Fire.new accepts (x, y) numbers", function(r)
    local Fire, err = safe_require("src.fire")
    if not Fire then return false, "require failed: " .. err end
    local ok, result = pcall(Fire.new, Fire,
        r.float(50,750), r.float(50,550))
    if not ok then return false, "Fire:new(x,y) error: " .. tostring(result) end
    return result ~= nil and result.x ~= nil or result.position ~= nil,
           "Fire instance missing position data"
end)

-- ── UI contract ───────────────────────────────────────────────────────────────

property("contract: UI has all required methods", function(r)
    local UI, err = safe_require("src.ui")
    if not UI then return false, "require failed: " .. err end
    return check_methods(UI, "UI", {
        "drawScore", "drawLives", "drawGameOver",
    })
end)

-- ── Physics contract ──────────────────────────────────────────────────────────

property("contract: Physics has checkCollisions", function(r)
    local Physics, err = safe_require("src.physics")
    if not Physics then return false, "require failed: " .. err end
    return check_methods(Physics, "Physics", {"checkCollisions"})
end)

-- ── Menu contract ─────────────────────────────────────────────────────────────

property("contract: Menu has all required methods", function(r)
    local Menu, err = safe_require("src.menu")
    if not Menu then return false, "require failed: " .. err end
    if not Menu.new then return false, 'Menu missing :new constructor' end
    local instance = Menu:new()
    if not instance then return false, "Menu:new failed" end
    return check_methods(instance, "Menu", {
        "update", "draw", "keypressed",
        "selectOption", "showPause", "showGameOver",
    })
end)

-- ── Cross-module wiring ───────────────────────────────────────────────────────
-- Verify main.lua's assumptions about how modules talk to each other.

property("wiring: Physics.checkCollisions accepts expected args", function(r)
    local Physics, err = safe_require("src.physics")
    if not Physics then return false, "require failed: " .. err end
    local Ball, _ = safe_require("src.ball")
    if not Ball then return true end  -- skip if ball missing

    -- create minimal stubs
    local ball     = {x=400, y=300, vx=0, vy=0, radius=20,
                      velocity={x=0,y=0}, position={x=400,y=300}}
    local fires    = {}
    local stains   = {}
    local audio    = {playSound=function()end}
    local state    = {score=0, lives=3}

    local ok, err2 = pcall(Physics.checkCollisions, Physics,
                           ball, fires, stains, audio, state)
    return ok, "checkCollisions error: " .. tostring(err2)
end)

-- Audio.init is stateful -- run once, cache result
local _audio_init_result = nil
local _audio_init_err    = nil
do
    local Audio = safe_require("src.audio")
    if Audio then
        _audio_init_result, _audio_init_err = pcall(Audio.init, Audio)
    else
        _audio_init_result = false
        _audio_init_err    = "require failed"
    end
end

property("wiring: Audio.init runs without error", function(r)
    return _audio_init_result,
           "Audio:init error: " .. tostring(_audio_init_err)
end)
