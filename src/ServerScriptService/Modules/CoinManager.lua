local CoinManager = {}
CoinManager.__index = CoinManager

function CoinManager:checkCoin()
    local coins = {
        Coins = 500;
    }
    setmetatable(coins, CoinManager)
    return coins
end

function CoinManager.new()
    
end

return CoinManager