local Menu = {}
Menu.__index = Menu

function Menu:new()
    local instance = {}
    setmetatable(instance, Menu)
    
    instance.currentMenu = "main"
    instance.selectedOption = 1
    instance.keyDelay = 0
    instance.keyDelayTime = 0.2
    
    -- Menu definitions
    instance.menus = {
        main = {
            title = "BALL FIRE GAME",
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
                {text = "Audio: ON", action = "toggle_audio", dynamic = true},
                {text = "Volume: 100%", action = "volume", dynamic = true},
                {text = "Back", action = "main"}
            }
        },
        help = {
            title = "HOW TO PLAY",
            options = {
                {text = "Back", action = "main"}
            },
            content = {
                "Use WASD or Arrow Keys to move the green ball",
                "Push the red ball into fires to extinguish them",
                "Avoid touching fires - they damage you!",
                "Survive as long as possible",
                "",
                "Controls:",
                "M - Toggle Audio",
                "+/- - Volume Control",
                "ESC - Quit Game"
            }
        },
        pause = {
            title = "PAUSED",
            options = {
                {text = "Resume", action = "resume"},
                {text = "Restart", action = "restart"},
                {text = "Main Menu", action = "main_menu"}
            }
        }
    }
    
    return instance
end

function Menu:update(dt, audio)
    self.keyDelay = math.max(0, self.keyDelay - dt)
    
    -- Update dynamic menu options
    if self.currentMenu == "settings" then
        local menu = self.menus.settings
        if audio then
            menu.options[1].text = "Audio: " .. (audio.enabled and "ON" or "OFF")
            menu.options[2].text = "Volume: " .. math.floor(audio.volume * 100) .. "%"
        end
    end
end

function Menu:draw()
    local menu = self.menus[self.currentMenu]
    if not menu then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(menu.title, 0, screenHeight * 0.2, screenWidth, "center")
    
    -- Draw help content if it exists
    if menu.content then
        local startY = screenHeight * 0.35
        for i, line in ipairs(menu.content) do
            love.graphics.printf(line, 0, startY + (i - 1) * 25, screenWidth, "center")
        end
    end
    
    -- Draw menu options
    local startY = menu.content and screenHeight * 0.75 or screenHeight * 0.45
    for i, option in ipairs(menu.options) do
        local y = startY + (i - 1) * 40
        
        -- Highlight selected option
        if i == self.selectedOption then
            love.graphics.setColor(1, 1, 0, 1)  -- Yellow for selected
            love.graphics.printf("> " .. option.text .. " <", 0, y, screenWidth, "center")
        else
            love.graphics.setColor(1, 1, 1, 1)  -- White for normal
            love.graphics.printf(option.text, 0, y, screenWidth, "center")
        end
    end
    
    -- Draw navigation hint
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Use UP/DOWN to navigate, ENTER to select", 0, screenHeight - 50, screenWidth, "center")
end

function Menu:keypressed(key, audio)
    if self.keyDelay > 0 then return false end
    
    local menu = self.menus[self.currentMenu]
    if not menu then return false end
    
    if key == "up" or key == "w" then
        self.selectedOption = self.selectedOption - 1
        if self.selectedOption < 1 then
            self.selectedOption = #menu.options
        end
        self.keyDelay = self.keyDelayTime
        if audio then audio:playMenuMove() end
        return true
        
    elseif key == "down" or key == "s" then
        self.selectedOption = self.selectedOption + 1
        if self.selectedOption > #menu.options then
            self.selectedOption = 1
        end
        self.keyDelay = self.keyDelayTime
        if audio then audio:playMenuMove() end
        return true
        
    elseif key == "return" or key == "space" then
        local action = menu.options[self.selectedOption].action
        self.keyDelay = self.keyDelayTime
        if audio then audio:playMenuSelect() end
        return self:handleAction(action, audio)
    end
    
    return false
end

function Menu:handleAction(action, audio)
    if action == "start_game" then
        return "start_game"
    elseif action == "settings" then
        self:setMenu("settings")
    elseif action == "help" then
        self:setMenu("help")
    elseif action == "main" then
        self:setMenu("main")
    elseif action == "quit" then
        love.event.quit()
    elseif action == "resume" then
        return "resume"
    elseif action == "restart" then
        return "restart"
    elseif action == "main_menu" then
        return "main_menu"
    elseif action == "toggle_audio" then
        if audio then
            audio:toggle()
        end
    elseif action == "volume" then
        -- Cycle through volume levels
        if audio then
            local volumes = {0.0, 0.25, 0.5, 0.75, 1.0}
            local currentIndex = 1
            for i, vol in ipairs(volumes) do
                if math.abs(audio.volume - vol) < 0.1 then
                    currentIndex = i
                    break
                end
            end
            local nextIndex = (currentIndex % #volumes) + 1
            audio:setVolume(volumes[nextIndex])
        end
    end
    
    return false
end

function Menu:setMenu(menuName)
    if self.menus[menuName] then
        self.currentMenu = menuName
        self.selectedOption = 1
    end
end

function Menu:getCurrentMenu()
    return self.currentMenu
end

return Menu