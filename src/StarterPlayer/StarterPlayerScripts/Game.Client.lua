local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local Modules = PlayerScripts.Modules

local Draft = require(Modules:WaitForChild("Draft"))
local TowerManager = require(Modules:WaitForChild("TowerPlacer"))
local ClientEvents = ReplicatedStorage.ClientEvents
local DraftBegin = ClientEvents.DraftBegin
local TowerSelection = ClientEvents.TowerSelection

TowerSelection.Event:Connect(function(cards)
    TowerManager.updateTowers(cards)
end)
DraftBegin.Event:Connect(function(cards)
    Draft.draftBegin(cards)
end)