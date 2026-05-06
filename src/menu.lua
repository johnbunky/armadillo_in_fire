local Menu = {}
Menu.__index = Menu
-- Palette imported from main via global P (set before any draw call)
-- Fallback colours used if P not yet defined

local function isAndroid()
    return love.system and love.system.getOS() == "Android"
end

local function isWeb()
    return love.system and love.system.getOS() == "Web"
end

local function safeQuit()
    if isWeb() then
        -- on web, close the tab or do nothing — no reliable quit
        love.event.quit()
    elseif isAndroid() then
        os.exit(0)
    else
        love.event.quit()
    end
end

function Menu:new()
    local instance = {}
    setmetatable(instance, Menu)

    instance.currentMenu    = "main"
    instance.selectedOption = 1
    instance.keyDelay       = 0
    instance.keyDelayTime   = 0.15
    instance.animationTimer = 0
    instance.fadeAlpha      = 0
    instance._fonts        = {}  -- cached fonts
    instance.inputCooldown = 0   -- blocks tap-through after menu transition

    instance.settings = {
        masterVolume = 0.7,
        musicVolume  = 0.6,
        fullscreen   = false,
    }

    instance.menus = {
        main = {
            title = "ARMADILLO IN FIRE",
            options = {
                { text = "Start Game", action = "start_game" },
                { text = "How to Play", action = "help" },
                { text = "Quit",        action = "quit" },
            }
        },
        help = {
            title = "HOW TO PLAY",
            content = {
                "TAP anywhere to move the armadillo",
                "Push the stone into fires to extinguish them",
                "Don't touch the fires — they damage you!",
                "Fires spread over time. Move fast.",
                "",
            },
            options = {
                { text = "Back", action = "main" }
            }
        },
        pause = {
            title = "PAUSED",
            options = {
                { text = "Resume",    action = "resume" },
                { text = "Main Menu", action = "main" },
                { text = "Quit",      action = "quit" },
            }
        },
        gameover = {
            title = "GAME OVER",
            options = {
                { text = "Try Again", action = "restart" },
                { text = "Main Menu", action = "main" },
                { text = "Quit",      action = "quit" },
            }
        }
    }

    return instance
end

-- ── Helpers ────────────────────────────────────────────────────────────────

-- Returns the Y start and line spacing used by draw() for the current menu.
-- Needed so mousepressed can hit-test without duplicating layout math.
function Menu:_layoutY()
    local _, H = love.graphics.getDimensions()
    local data = self.menus[self.currentMenu]
    if not data then return H / 2, 50 end

    if self.currentMenu == "help" and data.content then
        local bodySize = math.floor(H * 0.032)
        local lineH    = math.floor(bodySize * 1.35)
        local contentH = #data.content * lineH
        local gap      = math.floor(H * 0.04)
        local spacing  = math.floor(H * 0.09)
        local startY   = H * 0.67 + contentH + gap
        -- Keep back button clear of bottom edge (leave 12% margin)
        local maxY     = H * 0.88 - spacing
        startY = math.min(startY, maxY)
        return startY, spacing
    else
        return H * 0.66, math.floor(H * 0.09)
    end
end

-- ── Update ─────────────────────────────────────────────────────────────────

function Menu:_font(size)
    local key = math.floor(size)
    if not self._fonts[key] then
        self._fonts[key] = love.graphics.newFont(key)
    end
    return self._fonts[key]
end

function Menu:update(dt)
    self.animationTimer = self.animationTimer + dt
    if self.keyDelay > 0 then self.keyDelay = self.keyDelay - dt end
    if self.inputCooldown > 0 then self.inputCooldown = self.inputCooldown - dt end
    if self.fadeAlpha < 1 then
        self.fadeAlpha = math.min(1, self.fadeAlpha + dt * 3)
    end
end

-- ── Input ──────────────────────────────────────────────────────────────────

function Menu:keypressed(key)
    if self.keyDelay > 0 then return end
    local data = self.menus[self.currentMenu]
    if not data then return end

    if key == "up" or key == "w" then
        self.selectedOption = self.selectedOption - 1
        if self.selectedOption < 1 then self.selectedOption = #data.options end
        self.keyDelay = self.keyDelayTime

    elseif key == "down" or key == "s" then
        self.selectedOption = self.selectedOption + 1
        if self.selectedOption > #data.options then self.selectedOption = 1 end
        self.keyDelay = self.keyDelayTime

    elseif key == "return" or key == "space" then
        local action = self:selectOption()
        self.keyDelay = self.keyDelayTime
        return action

    elseif key == "escape" then
        if self.inputCooldown > 0 then return end  -- block double-fire after touch
        if self.currentMenu == "main" then
            safeQuit()
        else
            self:setMenu("main")
        end
        self.keyDelay = self.keyDelayTime
    end
end

-- Mouse / touch click — returns action string or nil
function Menu:mousepressed(x, y)
    if self.inputCooldown > 0 then return end
    local data = self.menus[self.currentMenu]
    if not data or not data.options then return end

    local startY, spacing = self:_layoutY()
    local W = love.graphics.getWidth()

    for i, option in ipairs(data.options) do
        local itemY  = startY + (i - 1) * spacing
        local hitH   = spacing            -- full row height as touch target
        local hitX1  = W * 0.1           -- 10%–90% of screen width
        local hitX2  = W * 0.9

        if x >= hitX1 and x <= hitX2
        and y >= itemY - 4 and y <= itemY + hitH then
            self.selectedOption = i
            return self:selectOption()
        end
    end
end

function Menu:selectOption()
    local data = self.menus[self.currentMenu]
    if not data then return end
    local option = data.options[self.selectedOption]
    if not option then return end

    local a = option.action
    if     a == "start_game" then return "start_game"
    elseif a == "resume"     then return "resume"
    elseif a == "restart"    then return "restart"
    elseif a == "quit"       then safeQuit()
    elseif a == "help"       then self:setMenu("help")
    elseif a == "main"       then self:setMenu("main")
    end
    return nil
end

function Menu:setMenu(name)
    self.currentMenu    = name
    self.selectedOption = 1
    self.fadeAlpha      = 0
    self.inputCooldown  = 0.25  -- block tap-through for 250ms
end

function Menu:showGameOver() self:setMenu("gameover") end
function Menu:showPause()    self:setMenu("pause") end
function Menu:getSettings()  return self.settings end

-- ── Draw ───────────────────────────────────────────────────────────────────

function Menu:draw(extinguishedTotal, fireCount)
    local W, H   = love.graphics.getDimensions()
    local data   = self.menus[self.currentMenu]
    if not data then return end

    -- Dim background
    -- Semi-transparent so background image shows through on menu/game_over
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, W, H)

    local fa = self.fadeAlpha  -- shorthand

    -- ── Title ──
    -- Title: start at preferred size, shrink until it fits within margins
    local margin    = W * 0.07
    local maxTitleW = W - margin * 2
    local titleSize = math.floor(H * 0.062)
    local titleFont = self:_font(titleSize)
    while titleFont:getWidth(data.title) > maxTitleW and titleSize > 12 do
        titleSize = titleSize - 1
        titleFont = self:_font(titleSize)
    end
    love.graphics.setFont(titleFont)
    love.graphics.setColor(P and P.uiTitle or {1, 0.55, 0.1})
    local tw = titleFont:getWidth(data.title)
    love.graphics.print(data.title, W / 2 - tw / 2, H * 0.55)

    -- ── Help content ──
    if self.currentMenu == "help" and data.content then
        -- Find longest line, shrink font until it fits with margins
        local maxContentW = W - margin * 2
        local bodySize    = math.floor(H * 0.032)
        local bodyFont    = self:_font(bodySize)
        local longest     = ""
        for _, line in ipairs(data.content) do
            if #line > #longest then longest = line end
        end
        while bodyFont:getWidth(longest) > maxContentW and bodySize > 9 do
            bodySize = bodySize - 1
            bodyFont = self:_font(bodySize)
        end
        love.graphics.setFont(bodyFont)
        local lineH = math.floor(bodySize * 1.35)
        local baseY = math.floor(H * 0.63)
        for i, line in ipairs(data.content) do
            love.graphics.setColor(P and P.uiText or {0.9,0.9,0.9})
            local lw = bodyFont:getWidth(line)
            love.graphics.print(line, W / 2 - lw / 2, baseY + (i - 1) * lineH)
        end
    end

    -- ── Game over score ──
    if self.currentMenu == "gameover" then
        local scoreFont = self:_font(math.floor(H * 0.038))
        love.graphics.setFont(scoreFont)
        local margin = W * 0.10
        local scoreY = H * 0.62
        local lineH  = math.floor(H * 0.055)

        local function scoreLine(label, value)
            local full = label .. ": " .. tostring(value)
            local fw   = scoreFont:getWidth(full)
            -- label part
            love.graphics.setColor(P and P.uiDim or {0.7,0.7,0.7})
            local lw = scoreFont:getWidth(label .. ": ")
            love.graphics.print(label .. ": ", W / 2 - fw / 2, scoreY)
            -- value part in gold
            love.graphics.setColor(P and P.uiTitle or {1,0.85,0.2})
            love.graphics.print(tostring(value), W / 2 - fw / 2 + lw, scoreY)
            scoreY = scoreY + lineH
        end

        if extinguishedTotal then
            scoreLine("Fires extinguished", extinguishedTotal)
        end
    end

    -- ── Options ──
    local optFont   = self:_font(math.floor(H * 0.05))
    love.graphics.setFont(optFont)
    local startY, spacing = self:_layoutY()

    for i, option in ipairs(data.options) do
        -- On Android hide Back in help screen — hardware back handles it
        local hide = (isAndroid() and option.action == "main" and self.currentMenu == "help")
                  or (isWeb() and option.action == "quit")
        if not hide then
            local oy       = startY + (i - 1) * spacing
            local selected = (i == self.selectedOption)
            if selected then
                local pulse = 0.55 + 0.45 * math.sin(self.animationTimer * 4)
                love.graphics.setColor(1, 0.7, 0.1, 0.18 * fa)
                love.graphics.rectangle("fill", W * 0.1, oy - 4, W * 0.8, spacing - 4, 6, 6)
                love.graphics.setColor(1, 0.75, 0.1, pulse * fa)
                love.graphics.print(">", W / 2 - optFont:getWidth(option.text) / 2 - 30, oy)
                love.graphics.setColor(P and P.uiTitle or {1, 0.85, 0.2})
            else
                love.graphics.setColor(P and P.uiText or {0.88, 0.88, 0.88})
            end
            local tw2 = optFont:getWidth(option.text)
            love.graphics.print(option.text, W / 2 - tw2 / 2, oy)
        end
    end

    -- ── Hint ──
    -- local hintFont = self:_font(math.floor(H * 0.025))
    -- love.graphics.setFont(hintFont)
    -- love.graphics.setColor(P and P.uiDim or {0.55,0.55,0.55})
    -- local hint = "Tap a menu item  ·  Keyboard: ↑↓ Enter"
    -- love.graphics.print(hint, W / 2 - hintFont:getWidth(hint) / 2, H - math.floor(H * 0.06))
    --
    -- love.graphics.setColor(1, 1, 1, 1)
end

return Menu
