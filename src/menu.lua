local Menu = {}
Menu.__index = Menu

function Menu:new()
    local instance = {}
    setmetatable(instance, Menu)
    
    instance.currentMenu = "main"
    instance.selectedOption = 1
    instance.keyDelay = 0
    instance.keyDelayTime = 0.15
    instance.animationTimer = 0
    instance.fadeAlpha = 0
    
    -- Settings state
    instance.settings = {
        masterVolume = 0.7,

        musicVolume = 0.6,
        difficulty = "Normal",
        fullscreen = false,
        vsync = true
    }
    
    -- Menu definitions
    instance.menus = {
        main = {
            title = "FIRE BALL GAME",
            options = {
                {text = "Start Game", action = "start_game"},
                {text = "Settings", action = "settings"},
                {text = "Help", action = "help"},
                {text = "Quit", action = "quit"}
            }
        },
        settings = {
            title = "SETTINGS",
            options = {
                {text = "Master Volume: ", action = "master_volume", type = "slider"},
                {text = "SFX Volume: ", action = "sfx_volume", type = "slider"},
                {text = "Music Volume: ", action = "music_volume", type = "slider"},
                {text = "Difficulty: ", action = "difficulty", type = "toggle"},
                {text = "Fullscreen: ", action = "fullscreen", type = "toggle"},
                {text = "VSync: ", action = "vsync", type = "toggle"},
                {text = "Back to Main Menu", action = "main"}
            }
        },
        help = {
            title = "HOW TO PLAY",
            content = {
                "CONTROLS:",
                "Arrow Keys - Move the ball",
                "Spacebar - Activate fire",
                "P - Pause game",
                "Escape - Return to menu",
            },
            options = {
                {text = "Back to Main Menu", action = "main"}
            }
        },
        pause = {
            title = "GAME PAUSED",
            options = {
                {text = "Resume", action = "resume"},
                {text = "Settings", action = "settings"},
                {text = "Main Menu", action = "main"},
                {text = "Quit", action = "quit"}
            }
        },
        gameover = {
            title = "GAME OVER",
            options = {
                {text = "Try Again", action = "restart"},
                {text = "Main Menu", action = "main"},
                {text = "Quit", action = "quit"}
            }
        }
    }
    
    return instance
end

function Menu:update(dt)
    self.animationTimer = self.animationTimer + dt
    
    -- Handle key delay
    if self.keyDelay > 0 then
        self.keyDelay = self.keyDelay - dt
    end
    
    -- Fade in effect
    if self.fadeAlpha < 1 then
        self.fadeAlpha = math.min(1, self.fadeAlpha + dt * 2)
    end
end

function Menu:keypressed(key)
    if self.keyDelay > 0 then return end
    
    local currentMenuData = self.menus[self.currentMenu]
    if not currentMenuData then return end
    
    if key == "up" or key == "w" then
        self.selectedOption = self.selectedOption - 1
        if self.selectedOption < 1 then
            self.selectedOption = #currentMenuData.options
        end
        self.keyDelay = self.keyDelayTime
    elseif key == "down" or key == "s" then
        self.selectedOption = self.selectedOption + 1
        if self.selectedOption > #currentMenuData.options then
            self.selectedOption = 1
        end
        self.keyDelay = self.keyDelayTime
    elseif key == "return" or key == "space" then
        local action = self:selectOption()
        self.keyDelay = self.keyDelayTime
        return action
    elseif key == "escape" then
        if self.currentMenu == "main" then
            love.event.quit()
        else
            self:setMenu("main")
        end
        self.keyDelay = self.keyDelayTime
    elseif key == "left" or key == "a" then
        self:adjustSetting(-1)
        self.keyDelay = self.keyDelayTime
    elseif key == "right" or key == "d" then
        self:adjustSetting(1)
        self.keyDelay = self.keyDelayTime
    end
end

function Menu:adjustSetting(direction)
    if self.currentMenu ~= "settings" then return end
    
    local option = self.menus.settings.options[self.selectedOption]
    if not option or not option.type then return end
    
    if option.action == "master_volume" then
        self.settings.masterVolume = math.max(0, math.min(1, self.settings.masterVolume + direction * 0.1))
        love.audio.setVolume(self.settings.masterVolume)
    elseif option.action == "sfx_volume" then

    elseif option.action == "music_volume" then
        self.settings.musicVolume = math.max(0, math.min(1, self.settings.musicVolume + direction * 0.1))
    elseif option.action == "difficulty" then
        local difficulties = {"Easy", "Normal", "Hard"}
        local currentIndex = 1
        for i, diff in ipairs(difficulties) do
            if diff == self.settings.difficulty then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex + direction
        if currentIndex < 1 then currentIndex = #difficulties end
        if currentIndex > #difficulties then currentIndex = 1 end
        self.settings.difficulty = difficulties[currentIndex]
    elseif option.action == "fullscreen" then
        self.settings.fullscreen = not self.settings.fullscreen
        love.window.setFullscreen(self.settings.fullscreen)
    elseif option.action == "vsync" then
        self.settings.vsync = not self.settings.vsync
    end
end

function Menu:selectOption()
    local currentMenuData = self.menus[self.currentMenu]
    if not currentMenuData then return end
    
    local option = currentMenuData.options[self.selectedOption]
    if not option then return end
    
    if option.action == "start_game" then
        return "start_game"
    elseif option.action == "settings" then
        self:setMenu("settings")
    elseif option.action == "help" then
        self:setMenu("help")
    elseif option.action == "main" then
        self:setMenu("main")
    elseif option.action == "pause" then
        self:setMenu("pause")
    elseif option.action == "gameover" then
        self:setMenu("gameover")
    elseif option.action == "resume" then
        return "resume"
    elseif option.action == "restart" then
        return "restart"
    elseif option.action == "quit" then
        love.event.quit()
    elseif option.type == "slider" or option.type == "toggle" then
        self:adjustSetting(1)
    end
    
    return nil
end

function Menu:setMenu(menuName)
    self.currentMenu = menuName
    self.selectedOption = 1
    self.fadeAlpha = 0
end

function Menu:draw(gameState)
    local width, height = love.graphics.getDimensions()
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Apply fade alpha
    love.graphics.setColor(1, 1, 1, self.fadeAlpha)
    
    local currentMenuData = self.menus[self.currentMenu]
    if not currentMenuData then return end
    
    -- Title
    love.graphics.setFont(love.graphics.newFont(32))
    local titleWidth = love.graphics.getFont():getWidth(currentMenuData.title)
    love.graphics.print(currentMenuData.title, width/2 - titleWidth/2, height/4)
    
    -- Help content (special case)
    if self.currentMenu == "help" and currentMenuData.content then
        love.graphics.setFont(love.graphics.newFont(16))
        local startY = height/3
        for i, line in ipairs(currentMenuData.content) do
            local lineWidth = love.graphics.getFont():getWidth(line)
            love.graphics.print(line, width/2 - lineWidth/2, startY + (i-1) * 25)
        end
        startY = startY + #currentMenuData.content * 25 + 50
        
        -- Help menu options
        love.graphics.setFont(love.graphics.newFont(20))
        for i, option in ipairs(currentMenuData.options) do
            local color = {1, 1, 1, self.fadeAlpha}
            if i == self.selectedOption then
                color = {1, 0.8, 0, self.fadeAlpha}
                -- Selection indicator
                local pulse = 0.5 + 0.5 * math.sin(self.animationTimer * 4)
                love.graphics.setColor(1, 0.8, 0, pulse * self.fadeAlpha)
                love.graphics.print("> ", width/2 - 120, startY + (i-1) * 40)
            end
            
            love.graphics.setColor(color)
            local optionWidth = love.graphics.getFont():getWidth(option.text)
            love.graphics.print(option.text, width/2 - optionWidth/2, startY + (i-1) * 40)
        end
    else
        -- Game over score display (if in game over menu)
        if self.currentMenu == "gameover" and gameState and gameState.extinguishedTotal then
            love.graphics.setColor(0.8, 0.8, 1, self.fadeAlpha)            
            love.graphics.setFont(love.graphics.newFont(18))            
            local scoreText = "Fires Extinguished: " .. gameState.extinguishedTotal            
            local scoreWidth = love.graphics.getFont():getWidth(scoreText)            
            love.graphics.print(scoreText, width/2 - scoreWidth/2, startY - 60)       
        end               
        -- Regular menu options
        love.graphics.setFont(love.graphics.newFont(20))
        local startY = height/2
        
        for i, option in ipairs(currentMenuData.options) do
            local displayText = option.text
            
            -- Add setting values for settings menu
            if self.currentMenu == "settings" and option.type then
                if option.action == "master_volume" then
                    displayText = displayText .. math.floor(self.settings.masterVolume * 100) .. "%"
                elseif option.action == "sfx_volume" then

                elseif option.action == "music_volume" then
                    displayText = displayText .. math.floor(self.settings.musicVolume * 100) .. "%"
                elseif option.action == "difficulty" then
                    displayText = displayText .. self.settings.difficulty
                elseif option.action == "fullscreen" then
                    displayText = displayText .. (self.settings.fullscreen and "On" or "Off")
                elseif option.action == "vsync" then
                    displayText = displayText .. (self.settings.vsync and "On" or "Off")
                end
            end
            
            local color = {1, 1, 1, self.fadeAlpha}
            if i == self.selectedOption then
                color = {1, 0.8, 0, self.fadeAlpha}
                -- Selection indicator with pulse animation
                local pulse = 0.5 + 0.5 * math.sin(self.animationTimer * 4)
                love.graphics.setColor(1, 0.8, 0, pulse * self.fadeAlpha)
                love.graphics.print("> ", width/2 - 150, startY + (i-1) * 50)
            end
            
            love.graphics.setColor(color)
            local textWidth = love.graphics.getFont():getWidth(displayText)
            love.graphics.print(displayText, width/2 - textWidth/2, startY + (i-1) * 50)
        end
    end
    
    -- Instructions
    if self.currentMenu == "settings" then
        love.graphics.setColor(0.7, 0.7, 0.7, self.fadeAlpha)
        love.graphics.setFont(love.graphics.newFont(14))
        local instructions = "Use Left/Right arrows to adjust settings"
        local instWidth = love.graphics.getFont():getWidth(instructions)
        love.graphics.print(instructions, width/2 - instWidth/2, height - 50)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu:getSettings()
    return self.settings
end

function Menu:showGameOver(score)
    self:setMenu("gameover")
    -- Could add score display here if needed
end

function Menu:showPause()
    self:setMenu("pause")
end

return Menu
