local CoinManager = {}
CoinManager.__index = CoinManager

function CoinManager.new(pIndex)
    local coins = {
        PIndex = pIndex;
        Coins = 1000;
    }
    setmetatable(coins, CoinManager)
    return coins
end

return CoinManager