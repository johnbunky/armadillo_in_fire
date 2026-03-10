-- intent.lua
-- What this project wants to be.
-- Written once, updated when direction changes.
-- jk2 reads this every session.

return {

    -- ── DIRECTION ─────────────────────────────────────────────────────────────
    -- One sentence. What kind of experience is this?
    -- Fill this in yourself -- only you know.
    direction = "Simple game player fight with fire with a ball, the fire´s startedy chanes to keep the player involved",

    -- ── CONTRACTS ─────────────────────────────────────────────────────────────
    -- Things that must always be true.
    -- Technical facts. Auto-verified by tests.
    contracts = {
        "Ball has update, draw, keypressed, keyreleased",
        "Audio has init, playMusic, stopMusic, pauseMusic, resumeMusic, playSound",
        "UI has drawScore, drawLives, drawGameOver",
        "Fire has update, draw",
        "Physics has checkCollisions",
        "Menu has update, draw, keypressed, selectOption, showPause, showGameOver",
    },

    -- ── FEEL ──────────────────────────────────────────────────────────────────
    -- Measurable game feel targets.
    -- These become fitness functions in jk2 balance.
    feel = {
        -- fill in: what should the player feel during a session?
        -- examples (uncomment and adjust):
        survival_variance  = "> 0.3",   -- player shouldn't plateau
        strategy_switches  = "> 2",     -- per session, player changes approach
        red_ball_usage     = "> 0.4",   -- red ball should feel essential
        fire_extinguished  = "> 0.3",   -- fires should be beatable
        -- session_length     = "> 120",   -- seconds, game should hold attention
    },

    -- ── BOUNDARIES ────────────────────────────────────────────────────────────
    -- Things the agent must never touch.
    -- Fill in files or systems that are off-limits.
    boundaries = {
        -- "assets/",          -- never modify art
        -- "src/audio.lua",    -- hand-tuned, don't regenerate
    },

    -- ── OPEN QUESTIONS ────────────────────────────────────────────────────────
    -- Things you haven't decided yet.
    -- jk2 reflect will flag these as unresolved imbalances.
    open = {
        "should fires move or stay static after spawning?",
        "what happens when player reaches score 1000?",
        -- add your own doubts here
    },

    -- ── ENGINE ────────────────────────────────────────────────────────────────
    engine  = "love2d",
    version = "11.x",
    entry   = "main.lua",
}
