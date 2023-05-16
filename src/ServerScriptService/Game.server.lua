local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local DraftEnd = ServerStorage.ServerEvents.DraftEnd

local Modules = ServerScriptService.Modules
local Draft = require(Modules.Draft)
local MobManager = require(Modules.MobManager)
local MapManager = require(Modules.MapManager)
local TowerManager = require(Modules.TowerManager)

local PlayingPlayers = {}
local Game = {}
local PlayerDatas = {}

function Game.runUpdate(playerIndex, deltaTime)
    local towerManager = PlayerDatas[playerIndex].Towers
    for i, _ in pairs(towerManager.Towers) do
        towerManager:towerUpdate(i, PlayerDatas[playerIndex].Mobs, deltaTime)
    end
end

function Game.start(players)
    for i = 1, 2, 1 do
        PlayerDatas[i] = {}
    end
    Draft.startDraft(players)
    local draft = DraftEnd.Event:Wait(0)
    for i = 1, 2, 1 do
        PlayerDatas[i].Player = players[i]
        PlayerDatas[i].Towers = TowerManager.new(draft[i])
        RemoteEvent:FireClient(players[i], "TowerUpdate", PlayerDatas[i].Towers)
    end
    task.wait(2)
    for i = 1, 2, 1 do
        PlayerDatas[i].Map = MapManager.load("Basic", Vector3.new(0, 0, ((-1) ^ i) * 100))
    end
    task.wait(1)
    for i = 1, 2, 1 do
        PlayerDatas[i].Towers:place("Minigunner", Vector3.new(12.5, 5, 40 + ((-1) ^ i) * 100))
    end
    task.wait(1)
    for i = 1, 2, 1 do
        PlayerDatas[i].Mobs = MobManager.startGame(PlayerDatas[i].Map.WayPoints)
    end
    local updateTime = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        updateTime += deltaTime
        if updateTime >= 0.1 then
            RemoteEvent:FireClient(PlayerDatas[1].Player, "MobUpdate", PlayerDatas[1].Towers.Cards)
            RemoteEvent:FireClient(PlayerDatas[2].Player, "MobUpdate", PlayerDatas[2].Towers.Cards)
        end
    end)
end

function Game.singleTest(player)
    PlayerDatas[1] = {}
    PlayerDatas[1].Player = player
    Draft.singleDraft(player)
    local draft = DraftEnd.Event:Wait()
    PlayerDatas[1].Towers = TowerManager.new(draft)
    RemoteEvent:FireClient(player, "TowerUpdate", PlayerDatas[1].Towers.Cards)
    task.wait(1)
    PlayerDatas[1].Map = MapManager.load("Basic", Vector3.new(0, 0, 100))
    task.wait(1)
    PlayerDatas[1].Towers:place("Minigunner", Vector3.new(12.5, 5, 140))
    task.wait(1)
    PlayerDatas[1].Mobs = MobManager.startGame(PlayerDatas[1].Map)
    PlayerDatas[1].Mobs:startWave()
    local updateTime = 0

    RunService.Heartbeat:Connect(function(deltaTime)
        Game.runUpdate(1, deltaTime)
        updateTime += deltaTime
        if updateTime >= 0.1 then
            RemoteEvent:FireClient(PlayerDatas[1].Player, "MobUpdate", PlayerDatas[1].Mobs)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    repeat
        wait()
    until player:HasAppearanceLoaded()
    Game.singleTest(player)
    --[[
    table.insert(PlayingPlayers, player)
    if #PlayingPlayers >= 2 then
        Game.start({PlayingPlayers[1], PlayingPlayers[2]})
    end
    ]]
end)

Players.PlayerRemoving:Connect(function(player)
    RemoteEvent:FireAllClients("Leave", player)
end)