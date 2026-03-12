local Audio = {}

-- Audio state
Audio.sounds = {}
Audio.enabled = true
Audio.volume = 0.7

-- Generate a simple tone sound programmatically
function Audio:generateTone(frequency, duration, volume)
    local sampleRate = 44100
    local samples = sampleRate * duration
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local wave = math.sin(2 * math.pi * frequency * t) * volume
        -- Add fade out to prevent clicks
        local fadeOut = math.max(0, 1 - (t / duration) * 2)
        wave = wave * fadeOut
        soundData:setSample(i, wave)
    end
    
    return love.audio.newSource(soundData)
end

-- Generate crackling fire sound with noise
function Audio:generateFireCrackle()
    local sampleRate = 44100
    local duration = 0.4
    local samples = sampleRate * duration
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Create crackling effect with multiple frequencies and noise
        local crackle = (math.random() - 0.5) * 0.3  -- Random noise
        crackle = crackle + math.sin(2 * math.pi * 80 * t) * 0.2  -- Low rumble
        crackle = crackle + math.sin(2 * math.pi * 150 * t) * 0.15  -- Mid crackle
        crackle = crackle + math.sin(2 * math.pi * 300 * t) * 0.1   -- High crackle
        
        -- Add envelope for natural sound
        local envelope = math.exp(-t * 2) * (1 + math.sin(20 * t) * 0.3)
        crackle = crackle * envelope * 0.4
        
        soundData:setSample(i, crackle)
    end
    
    return love.audio.newSource(soundData)
end

-- Generate hissing extinguish sound
function Audio:generateExtinguish()
    local sampleRate = 44100
    local duration = 0.6
    local samples = sampleRate * duration
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Create hissing sound with filtered noise
        local hiss = (math.random() - 0.5) * 0.8
        -- Low-pass filter effect
        local filteredHiss = hiss * (1 - t / duration)
        -- Add some steam-like modulation
        local steam = math.sin(2 * math.pi * 40 * t) * 0.2
        local sound = (filteredHiss + steam) * 0.3
        
        soundData:setSample(i, sound)
    end
    
    return love.audio.newSource(soundData)
end

-- Generate damage sound with harsh tone
function Audio:generateDamage()
    local sampleRate = 44100
    local duration = 0.25
    local samples = sampleRate * duration
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Harsh, distorted sound for damage
        local wave = math.sin(2 * math.pi * 220 * t) * 0.6
        wave = wave + math.sin(2 * math.pi * 440 * t) * 0.3
        -- Add distortion
        wave = math.max(-0.7, math.min(0.7, wave * 1.5))
        -- Quick fade out
        local fadeOut = math.max(0, 1 - (t / duration) * 4)
        wave = wave * fadeOut
        soundData:setSample(i, wave)
    end
    
    return love.audio.newSource(soundData)
end

-- Initialize audio system and load sounds
function Audio:init()
    -- Create sounds directory path
    local soundsPath = "assets/sounds/"
    
    -- Try to load sound files, generate fallback sounds if files don't exist
    self.sounds = {
        ballCollision = self:loadSound(soundsPath .. "bounce.wav", "static") or self:generateTone(200, 0.1, 0.5),
        coinCollect = self:loadSound(soundsPath .. "pickup.wav", "static") or self:generateTone(800, 0.2, 0.3),
        ballPush = self:loadSound(soundsPath .. "push.wav", "static") or self:generateTone(150, 0.15, 0.4),
        
        -- Fire-related sounds
        fireCrackle = self:loadSound(soundsPath .. "fire_crackle.wav", "static") or self:generateFireCrackle(),
        fireExtinguish = self:loadSound(soundsPath .. "fire_extinguish.wav", "static") or self:generateExtinguish(),
        fireDamage = self:loadSound(soundsPath .. "fire_damage.wav", "static") or self:generateDamage()
    }
    
    -- Set default volume for all sounds
    for name, sound in pairs(self.sounds) do
        if sound then
            sound:setVolume(self.volume)
        end
    end
    
    print("Audio system initialized with " .. (self.sounds.ballCollision and "loaded" or "generated") .. " sounds")
    print("Fire sound effects: crackle, extinguish, damage")
end

-- Load a sound file with error handling
function Audio:loadSound(filepath, sourceType)
    local success, sound = pcall(love.audio.newSource, filepath, sourceType or "static")
    if success then
        print("Loaded sound: " .. filepath)
        return sound
    else
        print("Could not load sound: " .. filepath .. " (will use generated sound)")
        return nil
    end
end

-- Play a sound effect
function Audio:playSound(soundName)
    if not self.enabled then
        return
    end
    
    local sound = self.sounds[soundName]
    if sound then
        -- Stop the sound if it's already playing to allow overlapping
        sound:stop()
        sound:play()
    end
end

-- Play music (stub implementation)
function Audio:playMusic(musicName)
    -- Stub: Music functionality not implemented yet
    if self.enabled then
        print("Playing music: " .. (musicName or "default"))
    end
end

-- Set master volume for all sounds
function Audio:setVolume(volume)
    self.volume = math.max(0, math.min(1, volume))  -- Clamp between 0 and 1
    
    for name, sound in pairs(self.sounds) do
        if sound then
            sound:setVolume(self.volume)
        end
    end
end

-- Toggle audio on/off
function Audio:toggle()
    self.enabled = not self.enabled
    print("Audio " .. (self.enabled and "enabled" or "disabled"))
end

-- Check if audio is enabled
function Audio:isEnabled()
    return self.enabled
end

-- Existing sound effect functions
function Audio:playBallCollision()
    self:playSound("ballCollision")
end

function Audio:playCoinCollect()
    self:playSound("coinCollect")
end

function Audio:playBallPush()
    self:playSound("ballPush")
end

-- New fire-related sound effect functions
function Audio:playFireCrackle()
    self:playSound("fireCrackle")
end

function Audio:playFireExtinguish()
    self:playSound("fireExtinguish")
end

function Audio:playFireDamage()
    self:playSound("fireDamage")
end

return Audio