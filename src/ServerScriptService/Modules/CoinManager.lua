local CoinManager = {}
CoinManager.__index = CoinManager

function CoinManager.new()
    local coins = {
        Coins = 1000;
    }
    setmetatable(coins, CoinManager)
    return coins
end

return CoinManager