local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local DraftEnd = ServerStorage.ServerEvents.DraftEnd
local Game = require(script.Parent.Game)
local Draft = require(script.Parent.Draft)
local MobManager = require(script.Parent.MobManager)
local MapManager = require(script.Parent.MapManager)
local TowerManager = require(script.Parent.TowerManager)

local PlayingPlayers = {}

Players.PlayerAdded:Connect(function(player)
    repeat
        wait()
    until player:HasAppearanceLoaded()
    Game.singleTest(player)
    --[[
    table.insert(PlayingPlayers, player)
    if #PlayingPlayers >= 2 then
        Game.start(PlayingPlayers[1], PlayingPlayers[2])
    end
    ]]
end)

Players.PlayerRemoving:Connect(function(player)
    RemoteEvent:FireAllClients("Leave", player)
end)