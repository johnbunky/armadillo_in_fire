local Audio = {}

-- Audio state
Audio.sounds = {}
Audio.enabled = true
Audio.volume = 0.7

-- Initialize audio system and load sounds
function Audio:init()
    -- Create sounds directory path
    local soundsPath = "assets/sounds/"
    
    -- Try to load sound files (will use placeholder if files don't exist)
    self.sounds = {
        ballCollision = self:loadSound(soundsPath .. "bounce.wav", "static"),
        coinCollect = self:loadSound(soundsPath .. "pickup.wav", "static"),
        ballPush = self:loadSound(soundsPath .. "push.wav", "static")
    }
    
    -- Set default volume for all sounds
    for name, sound in pairs(self.sounds) do
        if sound then
            sound:setVolume(self.volume)
        end
    end
end

-- Load a sound file with error handling
function Audio:loadSound(filepath, sourceType)
    local success, sound = pcall(love.audio.newSource, filepath, sourceType or "static")
    if success then
        print("Loaded sound: " .. filepath)
        return sound
    else
        print("Could not load sound: " .. filepath)
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

-- Specific sound effect functions
function Audio:playBallCollision()
    self:playSound("ballCollision")
end

function Audio:playCoinCollect()
    self:playSound("coinCollect")
end

function Audio:playBallPush()
    self:playSound("ballPush")
end

return Audio