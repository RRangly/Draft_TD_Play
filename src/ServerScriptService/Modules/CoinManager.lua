local CoinManager = {}
CoinManager.__index = CoinManager

function CoinManager.new()
    local coins = {
        Coins = 500;
    }
    setmetatable(coins, CoinManager)
    return coins
end

return CoinManager