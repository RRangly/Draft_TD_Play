local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Towers = ReplicatedStorage.Towers

local Data = require(ServerScriptService.Modules.Data)

local Shop = {}
Shop.__index = Shop

function Shop:reRoll()
    local coinManager = Data[self.PIndex].CoinManager
    local cost = math.floor(1.1 ^ self.ReRoll * 115)
    if coinManager.Coins >= cost then
        print("Coins", coinManager.Coins, cost)
        coinManager.Coins -= cost
        print("CoinLeft", coinManager.Coins)
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

function Shop:purchaseChunk()
    local coinManager = Data[self.PIndex].CoinManager
    local mapManager = Data[self.PIndex].MapManager
    local cost = math.floor(1.1 ^ self.Chunks * 825)
    if coinManager.Coins >= cost then
        coinManager.Coins -= cost
        mapManager:generateChunk()
        self.Chunks += 1
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
        coinManager.Coins -= cost
        table.insert(towerManager.Cards, card)
        self.ShopItems[pickNum] = nil
    end
end

function Shop.new(pIndex)
    local auction = {
        PIndex = pIndex;
        ShopItems = {};
        ReRoll = 0;
    }
    setmetatable(auction, Shop)
    return auction
end

return Shop