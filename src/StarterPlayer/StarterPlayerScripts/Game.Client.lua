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
local GameFXManager = require(Modules:WaitForChild("GameFXManager"))
local Data = require(Modules:WaitForChild("Data"))

local PlayerGui = Player.PlayerGui

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

TowerUpdate.Event:Connect(function(towers)
    Data.Towers = towers
    HudManager.TowerManager.updateSelection(Data.Coins, towers.Towers, HudManager.TowerManager.Selected.Index)
end)

CardsUpdate.Event:Connect(function(cards)
    Data.Cards = cards
    HudManager.TowerManager.updateCards()
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
    Data.Coins = coins
    HudManager.CoinManager.updateCoins(coins)
end)

UserInputService.InputBegan:Connect(function(inputObj, processed)
    if processed then
        return
    end
    local mouseLocation = UserInputService:GetMouseLocation()
    local frames = PlayerGui:GetGuiObjectsAtPosition(mouseLocation.X, mouseLocation.Y)
    if #frames == 0 then
        local placing = HudManager.TowerManager.Placing
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
            if placing then
                HudManager.TowerManager.placeTower(Data.Coins.Coins)
            elseif Data.Towers then
                HudManager.TowerManager.selectTower(Data.Coins, Data.Towers.Towers)
            end
        elseif inputObj.KeyCode == Enum.KeyCode.F then
            if placing then
                HudManager.TowerManager.cancelPlacement()
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local ClientLoad = ReplicatedStorage.ClientLoad:FindFirstChild(Player.UserId)
    if ClientLoad and Data then
        for _, instance in pairs(ClientLoad:GetChildren()) do
            GameFXManager.executeLoad(Data, instance)
        end
    end
end)