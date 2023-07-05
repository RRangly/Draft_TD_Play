local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Towers = ReplicatedStorage.Towers

local Shop = {}
Shop.__index = Shop

function Shop:reRoll(coinManager)
    local cost = math.floor(1.1 ^ self.ReRoll * 115)
    if coinManager.Coins >= cost then
        coinManager.Coins -= cost
        local towers = Towers:GetChildren()
        for i = 1, 3, 1 do
            self.ShopItems[i] = towers[math.random(1, #towers)].Name
        end
        self.ReRoll += 1
    end
end

function Shop:reRollNoCost()
    local towers = Towers:GetChildren()
    for i = 1, 3, 1 do
        self.ShopItems[i] = towers[math.random(1, #towers)].Name
    end
end

function Shop:pick(data, pickNum)
    local coinManager = data.CoinManager
    local towerManager = data.TowerManager
    local card = self.ShopItems[pickNum]
    if not card then
        return
    end
    local cardInfo = require(Towers:FindFirstChild(card))
    local cost = cardInfo.Stats[1].Cost
    if coinManager.Coins >= cost then
        table.insert(towerManager.Cards, card)
        self.ShopItems[pickNum] = nil
    end
end

function Shop.new()
    local auction = {
        ShopItems = {};
        ReRoll = 0
    }
    setmetatable(auction, Shop)
    return auction
end

return Shop