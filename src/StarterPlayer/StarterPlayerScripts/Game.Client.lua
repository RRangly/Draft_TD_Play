local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local Modules = PlayerScripts.Modules

local RemoteEvent = ReplicatedStorage.ServerCommunication
local Draft = require(Modules:WaitForChild("Draft"))
local TowerManager = require(Modules:WaitForChild("TowerManager"))


local ClientEvents = ReplicatedStorage.ClientEvents
local DraftBegin = ClientEvents.DraftBegin
local CardsUpdate = ClientEvents.CardsUpdate
local TowerUpdate = ClientEvents.TowerUpdate
local GameStarted = ClientEvents.GameStarted

local Data = {}

TowerUpdate.Event:Connect(function(towers)
    Data.Towers = towers
end)

CardsUpdate.Event:Connect(function(cards)
    Data.Cards = cards
    TowerManager.updateCards(cards)
end)

DraftBegin.Event:Connect(function(cards)
    Draft.draftBegin(cards)
end)

GameStarted.Event:Wait()

UserInputService.InputBegan:Connect(function(inputObj)
    local placing = TowerManager.Placing
    if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
        if placing then
            TowerManager.placeTower()
        else
            TowerManager.selectTower(Data.Towers)
        end
    elseif inputObj.KeyCode == Enum.KeyCode.F then
        if placing then
            placing.Model:Destroy()
            placing.RenderConnection:Disconnect()
        end
    end
end)