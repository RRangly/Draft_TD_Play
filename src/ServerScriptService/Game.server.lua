local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Towers = ReplicatedStorage.Towers
local ClientLoad = ReplicatedStorage.ClientLoad

local RemoteEvent = ReplicatedStorage.ServerCommunication
local DraftEnd = ServerStorage.ServerEvents.DraftEnd
local PlaceTower = ServerStorage.ServerEvents.PlaceTower

local Modules = ServerScriptService.Modules
local Draft = require(Modules.Draft)
local MobManager = require(Modules.MobManager)
local MapManager = require(Modules.MapManager)
local TowerManager = require(Modules.TowerManager)
local BaseManager = require(Modules.BaseManager)
local CoinManager = require(Modules.CoinManager)

local PlayingPlayers = {}
local Game = {}
local PlayerDatas = {}

function Game.runUpdate(playerIndex, deltaTime)
    local towerManager = PlayerDatas[playerIndex].Towers
    local mobManager = PlayerDatas[playerIndex].Mobs
    local coinManager = PlayerDatas[playerIndex].Coins
    local player = PlayerDatas[playerIndex].Player
    for i, ti in pairs(towerManager.Towers) do
        local tower = require(Towers:FindFirstChild(ti.Name))
        tower.update(player, towerManager, i, mobManager, deltaTime)
        --towerManager:towerUpdate(i, PlayerDatas[playerIndex].Mobs, deltaTime)
    end
    local wayPoints = PlayerDatas[playerIndex].Map.WayPoints
    for i, mob in pairs(mobManager.Mobs) do
        local hum = mob.Object:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            table.remove(mobManager.Mobs, i)
            coinManager.Coins += 10
            RemoteEvent:FireClient(player, "CoinUpdate", PlayerDatas[1].Coins)
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
                    RemoteEvent:FireClient(player, "BaseHpUpdate", PlayerDatas[playerIndex].Base)
                end
            end)
        end
    end
    if #mobManager.Mobs < 1 and #mobManager.PreSpawn < 1 and not mobManager.Starting then
        RemoteEvent:FireClient(player, "WaveReady", PlayerDatas[1].Mobs.CurrentWave + 1)
        mobManager:startWave()
        RemoteEvent:FireClient(player, "WaveStart", PlayerDatas[1].Mobs.CurrentWave)
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
    PlayerDatas[1].Coins = CoinManager.new()
    local fol = Instance.new("Folder", ClientLoad)
    fol.Name = player.UserId
    task.wait(1)
    PlayerDatas[1].Towers:place("Minigunner", Vector3.new(12.5, 5, 140), PlayerDatas[1].Coins)
    RemoteEvent:FireClient(player, "GameStarted", PlayerDatas[1])
    RemoteEvent:FireClient(player, "WaveReady", PlayerDatas[1].Mobs.CurrentWave + 1)
    PlayerDatas[1].Mobs:startWave()
    RemoteEvent:FireClient(player, "WaveStart", PlayerDatas[1].Mobs.CurrentWave)

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
    print("PlayerAdded", player)
    repeat
        wait()
    until player:HasAppearanceLoaded()
    task.wait(3)
    print("GameStarting")
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
            local placed = data.Towers:place(towerName, position, data.Coins)
            if placed then
                RemoteEvent:FireClient(player, "TowerUpdate", PlayerDatas[1].Towers)
                RemoteEvent:FireClient(player, "CoinUpdate", PlayerDatas[1].Coins)
            end
        end
    end
end)