function love.conf(t)
    t.title    = "Armadillo in Fire"
    t.identity = "armadillo_in_fire"   -- save dir name on all platforms

    t.window.width     = 800
    t.window.height    = 600
    t.window.resizable = true
    t.window.minwidth  = 400
    t.window.minheight = 300

    -- Mobile / Android hints
    t.window.fullscreen      = false
    t.window.fullscreentype  = "desktop"
    t.window.highdpi         = true

    -- Turn off unused modules (faster load, smaller APK)
    t.modules.joystick = false
end
