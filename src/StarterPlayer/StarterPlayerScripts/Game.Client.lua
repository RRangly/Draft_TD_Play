local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local Modules = PlayerScripts:WaitForChild("Modules")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local Draft = require(Modules:WaitForChild("Draft"))
--local TowerManager = require(Modules:WaitForChild("TowerManager"))
local MobHealthDisplay = require(Modules:WaitForChild("MobHealthDisplay"))
--local BaseHp = require(Modules:WaitForChild("BaseHp"))
local HudManager = require(Modules:WaitForChild("HudManager"))

local ClientEvents = ReplicatedStorage.ClientEvents
local DraftBegin = ClientEvents.DraftBegin
local CardsUpdate = ClientEvents.CardsUpdate
local TowerUpdate = ClientEvents.TowerUpdate
local GameStarted = ClientEvents.GameStarted
local MobUpdate = ClientEvents.MobUpdate
local BaseHpUpdate = ClientEvents.BaseHpUpdate
local WaveReady = ClientEvents.WaveReady
local WaveStart = ClientEvents.WaveStart

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
    MobHealthDisplay.update(mobs)
end)

BaseHpUpdate.Event:Connect(function(base)
    Data.Base = base
    HudManager.BaseManager.updateBaseHp(base)
end)

GameStarted.Event:Once(function(data)
    HudManager.start()
    HudManager.TowerManager.updateCards(data.Towers.Cards)
    HudManager.BaseManager.updateBaseHp(data.Base)
    HudManager.WaveManager.updateWave(data.Mobs.CurrentWave)
end)

WaveReady.Event:Connect(function(wave)
    HudManager.WaveManager.starting(wave)
end)

WaveStart.Event:Connect(function(wave)
    HudManager.WaveManager.updateWave(wave)
end)

UserInputService.InputBegan:Connect(function(inputObj)
    local placing = HudManager.TowerManager.Placing
    if inputObj.KeyCode == Enum.KeyCode.E then
        if placing then
            HudManager.TowerManager.placeTower()
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