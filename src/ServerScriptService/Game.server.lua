local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local DraftEnd = ServerStorage.ServerEvents.DraftEnd
local PlaceTower = ServerStorage.ServerEvents.PlaceTower

local Modules = ServerScriptService.Modules
local Draft = require(Modules.Draft)
local MobManager = require(Modules.MobManager)
local MapManager = require(Modules.MapManager)
local TowerManager = require(Modules.TowerManager)
local BaseManager = require(Modules.BaseManager)

local PlayingPlayers = {}
local Game = {}
local PlayerDatas = {}

function Game.runUpdate(playerIndex, deltaTime)
    local towerManager = PlayerDatas[playerIndex].Towers
    for i, _ in pairs(towerManager.Towers) do
        towerManager:towerUpdate(i, PlayerDatas[playerIndex].Mobs, deltaTime)
    end
    local mobManager = PlayerDatas[playerIndex].Mobs
    local wayPoints = PlayerDatas[playerIndex].Map.WayPoints
    for i, mob in pairs(mobManager.Mobs) do
        local hum = mob.Object:FindFirstChild("Humanoid")
        if not hum then
            table.remove(mobManager.Mobs, i)
            continue
        end
        if hum.Health <= 0 then
            table.remove(mobManager.Mobs, i)
            if #mobManager.Mobs < 1 and #mobManager.PreSpawn < 1 then
                mobManager:startWave()
            end
            continue
        end
        local needAddition = true
        for _, humanoid in pairs(mobManager.CurrentMoving) do
            if hum == humanoid then
                needAddition = false
            end
        end
        if needAddition then
            task.spawn(function()
                local healthReduction = mobManager:startMovement(i, wayPoints)
                if healthReduction > 0 then
                    PlayerDatas[playerIndex].Base.Health -= healthReduction
                    RemoteEvent:FireClient(PlayerDatas[playerIndex].Player, "BaseHpUpdate", PlayerDatas[playerIndex].Base)
                end
            end)
        end
    end
    if #mobManager.Mobs < 1 and #mobManager.PreSpawn < 1 and not mobManager.Starting then
        RemoteEvent:FireClient(PlayerDatas[playerIndex].Player, "WaveReady", PlayerDatas[1].Mobs.CurrentWave + 1)
        mobManager:startWave()
        RemoteEvent:FireClient(PlayerDatas[playerIndex].Player, "WaveStart", PlayerDatas[1].Mobs.CurrentWave)
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
        RemoteEvent:FireClient(players[i], "CardsUpdate", PlayerDatas[i].Towers.Cards)
    end
    task.wait(2)
    for i = 1, 2, 1 do
        PlayerDatas[i].Map = MapManager.load("Basic", Vector3.new(0, 0, ((-1) ^ i) * 100))
    end
    task.wait(1)
    for i = 1, 2, 1 do
        PlayerDatas[i].Base = BaseManager.new()
        PlayerDatas[i].Towers:place("Minigunner", Vector3.new(12.5, 5, 40 + ((-1) ^ i) * 100))
    end
    task.wait(1)
    for i = 1, 2, 1 do
        PlayerDatas[i].Mobs = MobManager.startGame()
        PlayerDatas[i].Mobs:startWave()
    end
    for i = 1, 2, 1 do
        RemoteEvent:FireClient(players[i], "GameStarted", PlayerDatas[1])
    end

    local updateTime = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        Game.runUpdate(1, deltaTime)
        Game.runUpdate(2, deltaTime)
        updateTime += deltaTime
        if updateTime >= 0.1 then
            RemoteEvent:FireClient(PlayerDatas[1].Player, "MobUpdate", PlayerDatas[1].Mobs.Mobs)
            RemoteEvent:FireClient(PlayerDatas[2].Player, "MobUpdate", PlayerDatas[2].Mobs.Mobs)
        end
    end)
end

function Game.singleTest(player)
    PlayerDatas[1] = {}
    PlayerDatas[1].Player = player
    Draft.singleDraft(player)
    local draft = DraftEnd.Event:Wait()
    PlayerDatas[1].Towers = TowerManager.new(draft)
    PlayerDatas[1].Map = MapManager.load("Basic", Vector3.new(0, 0, 100))
    PlayerDatas[1].Base = BaseManager.new()
    PlayerDatas[1].Mobs = MobManager.startGame()
    task.wait(1)
    PlayerDatas[1].Towers:place("Minigunner", Vector3.new(12.5, 5, 140))
    RemoteEvent:FireClient(player, "GameStarted", PlayerDatas[1])
    RemoteEvent:FireClient(player, "WaveReady", PlayerDatas[1].Mobs.CurrentWave + 1)
    PlayerDatas[1].Mobs:startWave()
    RemoteEvent:FireClient(player, "WaveStart", PlayerDatas[1].Mobs.CurrentWave)

    local updateTime = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        Game.runUpdate(1, deltaTime)
        updateTime += deltaTime
        if updateTime >= 0.1 then
            RemoteEvent:FireClient(PlayerDatas[1].Player, "MobUpdate", PlayerDatas[1].Mobs.Mobs)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    print("PlayerAdded", player)
    repeat
        wait()
    until player:HasAppearanceLoaded()
    task.wait(3)
    Game.singleTest(player)
    --[[
    table.insert(PlayingPlayers, player)
    if #PlayingPlayers >= 2 then
        Game.start({PlayingPlayers[1], PlayingPlayers[2]})
    end
    ]]
end)

PlaceTower.Event:Connect(function(player, towerName, position)
    for _, data in pairs(PlayerDatas) do
        if data.Player == player then
            data.Towers:place(towerName, position)
        end
    end
end)