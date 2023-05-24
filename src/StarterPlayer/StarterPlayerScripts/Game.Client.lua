local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local Modules = PlayerScripts:WaitForChild("Modules")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local Draft = require(Modules:WaitForChild("Draft"))
local MobHealthDisplay = require(Modules:WaitForChild("MobHealthDisplay"))
local HudManager = require(Modules:WaitForChild("HudManager"))
local TowerFXManager = require(Modules:FindFirstChild("TowerFXManager"))

local Towers = ReplicatedStorage.Towers

local ClientEvents = ReplicatedStorage.ClientEvents
local DraftBegin = ClientEvents.DraftBegin
local CardsUpdate = ClientEvents.CardsUpdate
local TowerUpdate = ClientEvents.TowerUpdate
local GameStarted = ClientEvents.GameStarted
local MobUpdate = ClientEvents.MobUpdate
local BaseHpUpdate = ClientEvents.BaseHpUpdate
local WaveReady = ClientEvents.WaveReady
local WaveStart = ClientEvents.WaveStart
local CoinsUpdate = ClientEvents.CoinUpdate

local Data = {}

TowerUpdate.Event:Connect(function(towers)
    Data.Towers = towers
end)

CardsUpdate.Event:Connect(function(cards)
    Data.Cards = cards
    HudManager.TowerManager.updateCards(cards)
end)

print("DraftBeginReady")
DraftBegin.Event:Connect(function(cards)
    print("BeginDraft")
    Draft.draftBegin(cards)
end)

MobUpdate.Event:Connect(function(mobs)
    Data.Mobs = mobs
    MobHealthDisplay.update(mobs.Mobs)
end)

BaseHpUpdate.Event:Connect(function(base)
    Data.Base = base
    HudManager.BaseManager.updateBaseHp(base)
end)

GameStarted.Event:Once(function(data)
    Data = data
    HudManager.start()
    HudManager.TowerManager.updateCards(data.Towers.Cards)
    HudManager.BaseManager.updateBaseHp(data.Base)
    HudManager.WaveManager.updateWave(data.Mobs.CurrentWave)
    HudManager.CoinManager.updateCoins(data.Coins)
end)

WaveReady.Event:Connect(function(wave)
    HudManager.WaveManager.starting(wave)
end)

WaveStart.Event:Connect(function(wave)
    HudManager.WaveManager.updateWave(wave)
end)

CoinsUpdate.Event:Connect(function(coins)
    HudManager.CoinManager.updateCoins(coins)
end)

UserInputService.InputBegan:Connect(function(inputObj)
    local placing = HudManager.TowerManager.Placing
    if inputObj.KeyCode == Enum.KeyCode.E then
        if placing and Data.Coins then
            HudManager.TowerManager.placeTower(Data.Coins.Coins)
        else
            if Data.Towers then
                HudManager.TowerManager.selectTower(Data.Towers)
            end
        end
    elseif inputObj.KeyCode == Enum.KeyCode.F then
        if placing then
            HudManager.TowerManager.cancelPlacement()
        end
    end
end)

local exTime = 0
local index = 1

RunService.Heartbeat:Connect(function(deltaTime)
    index += 1
    exTime += deltaTime
    if index >= 5 then
        if Data then
            if not Data.Towers or not Data.Mobs then
                return
            end
            local towerManager = Data.Towers
            local mobManager = Data.Mobs
            for _, tower in pairs(towerManager.Towers) do
                TowerFXManager.towerUpdate(tower, mobManager, exTime)
            end
            exTime = 0
            index = 1
        end
    end
    
end)