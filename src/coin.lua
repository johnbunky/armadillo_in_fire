local Coin = {}
Coin.__index = Coin

function Coin:new(x, y, radius, color)
    local coin = {}
    setmetatable(coin, Coin)
    
    coin.x = x or 0
    coin.y = y or 0
    coin.radius = radius or 10
    coin.color = color or {1, 1, 0}  -- yellow by default
    
    return coin
end

function Coin:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Coin