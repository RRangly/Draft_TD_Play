local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local Draft = require(script.Parent.Draft)
local MobManager = require(script.Parent.MobManager)
local MapManager = require(script.Parent.MapManager)
local TowerManager = require(script.Parent.TowerManager)

local PlayingPlayers = {}
local GameStarted = false
local GameEnded = false

Players.PlayerAdded:Connect(function(player)
    repeat
        wait()
    until player:HasAppearanceLoaded()
    MapManager.load("Basic")
    wait(1)
    TowerManager.place(player, "Minigunner", Vector3.new(12.5, 5, 40))
    wait(2)
    MobManager.Spawn("Zombie")
    table.insert(PlayingPlayers, player)
    if #PlayingPlayers == 2 then
        GameStarted = true
        RemoteEvent:FireAllClients("GameStart")
        Draft.startDraft(PlayingPlayers[1], PlayingPlayers[2])
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoteEvent:FireAllClients("Leave", player)
end)