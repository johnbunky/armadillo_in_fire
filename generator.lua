-- generator.lua
-- Run with: love . --generator   (from your game folder)
-- OR rename to main.lua temporarily and run love .
-- Saves all generated sounds to assets/sounds/ as .wav files

local function generateTone(frequency, duration, volume)
    local sampleRate = 44100
    local samples    = math.floor(sampleRate * duration)
    local soundData  = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t    = i / sampleRate
        local wave = math.sin(2 * math.pi * frequency * t) * volume
        wave = wave * math.max(0, 1 - (t / duration) * 2)
        soundData:setSample(i, wave)
    end
    return soundData
end

local function generateFireCrackle()
    local sampleRate = 44100
    local duration   = 0.4
    local samples    = math.floor(sampleRate * duration)
    local soundData  = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t       = i / sampleRate
        local crackle = (math.random() - 0.5) * 0.3
        crackle = crackle + math.sin(2 * math.pi * 80  * t) * 0.2
        crackle = crackle + math.sin(2 * math.pi * 150 * t) * 0.15
        crackle = crackle + math.sin(2 * math.pi * 300 * t) * 0.1
        crackle = crackle * math.exp(-t * 2) * (1 + math.sin(20 * t) * 0.3) * 0.4
        soundData:setSample(i, crackle)
    end
    return soundData
end

local function generateExtinguish()
    local sampleRate = 44100
    local duration   = 0.6
    local samples    = math.floor(sampleRate * duration)
    local soundData  = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t     = i / sampleRate
        local hiss  = (math.random() - 0.5) * 0.8 * (1 - t / duration)
        local sound = (hiss + math.sin(2 * math.pi * 40 * t) * 0.2) * 0.3
        soundData:setSample(i, sound)
    end
    return soundData
end

local function generateDamage()
    local sampleRate = 44100
    local duration   = 0.25
    local samples    = math.floor(sampleRate * duration)
    local soundData  = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t    = i / sampleRate
        local wave = math.sin(2 * math.pi * 220 * t) * 0.6
                   + math.sin(2 * math.pi * 440 * t) * 0.3
        wave = math.max(-0.7, math.min(0.7, wave * 1.5))
        wave = wave * math.max(0, 1 - (t / duration) * 4)
        soundData:setSample(i, wave)
    end
    return soundData
end

local function generateBounce()
    local sampleRate = 44100
    local duration   = 0.1
    local samples    = math.floor(sampleRate * duration)
    local soundData  = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t    = i / sampleRate
        -- Pitch drops quickly like a bounce
        local freq = 200 * math.exp(-t * 8)
        local wave = math.sin(2 * math.pi * freq * t) * 0.5
        wave = wave * math.max(0, 1 - t / duration)
        soundData:setSample(i, wave)
    end
    return soundData
end

local function generatePush()
    local sampleRate = 44100
    local duration   = 0.15
    local samples    = math.floor(sampleRate * duration)
    local soundData  = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t    = i / sampleRate
        local wave = math.sin(2 * math.pi * 150 * t) * 0.4
        local thud = (math.random() - 0.5) * 0.3 * math.exp(-t * 20)
        wave = (wave + thud) * math.max(0, 1 - (t / duration) * 3)
        soundData:setSample(i, wave)
    end
    return soundData
end

-- ── Write wav files ────────────────────────────────────────────────────────

local function save(name, soundData)
    local fileData = soundData:encode("wav")
    local path     = "assets/sounds/" .. name
    local ok, err  = love.filesystem.write(path, fileData)
    if ok then
        print("Saved: " .. path)
    else
        print("ERROR saving " .. path .. ": " .. tostring(err))
    end
end

function love.load()
    math.randomseed(os.time())

    -- Create directory (love.filesystem.createDirectory is safe to call)
    love.filesystem.createDirectory("assets/sounds")

    print("Generating sounds...")

    save("bounce.wav",          generateBounce())
    save("push.wav",            generatePush())
    save("pickup.wav",          generateTone(800, 0.2, 0.3))
    save("fire_crackle.wav",    generateFireCrackle())
    save("fire_extinguish.wav", generateExtinguish())
    save("fire_damage.wav",     generateDamage())

    print("Done! Files saved to: " .. love.filesystem.getSaveDirectory())
    print("Copy assets/sounds/ from the save directory into your project.")
end

function love.draw()
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.printf(
        "Sound generation complete!\n\n" ..
        "Copy assets/sounds/ from:\n" ..
        love.filesystem.getSaveDirectory() ..
        "\n\ninto your project folder,\nthen close this window.",
        40, 80, love.graphics.getWidth() - 80, "left"
    )
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
