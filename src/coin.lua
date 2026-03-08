local Coin = {}
Coin.__index = Coin

function Coin:new(x, y, radius, color)
    local coin = {}
    setmetatable(coin, Coin)
    
    coin.x = x or 0
    coin.y = y or 0
    coin.radius = radius or 10
    coin.color = color or {1, 1, 0}  -- yellow by default
    
    -- Shadow properties
    coin.shadowOffset = {x = 2, y = 3}  -- Smaller shadow offset for coins
    coin.shadowColor = {0, 0, 0, 0.25}  -- Semi-transparent black shadow, slightly lighter than balls
    coin.shadowScale = {x = 1.1, y = 0.5}  -- Shadow is wider and flatter than coin
    
    return coin
end

function Coin:drawShadow()
    -- Draw shadow as an ellipse beneath the coin
    love.graphics.setColor(self.shadowColor[1], self.shadowColor[2], self.shadowColor[3], self.shadowColor[4])
    
    local shadowX = self.x + self.shadowOffset.x
    local shadowY = self.y + self.shadowOffset.y
    local shadowRadiusX = self.radius * self.shadowScale.x
    local shadowRadiusY = self.radius * self.shadowScale.y
    
    love.graphics.ellipse("fill", shadowX, shadowY, shadowRadiusX, shadowRadiusY)
end

function Coin:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Coin