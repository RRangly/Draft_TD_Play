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
local ManageTower = ServerStorage.ServerEvents.ManageTower

local Modules = ServerScriptService.Modules
local Data = require(Modules.Data)
local Draft = require(Modules.Draft)
local MobManager = require(Modules.MobManager)
local MapManager = require(Modules.MapManager)
local TowerManager = require(Modules.TowerManager)
local BaseManager = require(Modules.BaseManager)
local CoinManager = require(Modules.CoinManager)
local MapGenerator = require(Modules.MapGenerator)

local PlayingPlayers = {}
local Game = {}

function Game.runUpdate(playerIndex, deltaTime)
    local data = Data[playerIndex]
    local towerManager = data.Towers
    local mobManager = data.Mobs
    local coinManager = data.Coins
    local player = data.Player
    local mapManager = data.Map
    --local wayPoints = data.Map.WayPoints
    for i, ti in pairs(towerManager.Towers) do
        local tower = require(Towers:FindFirstChild(ti.Name))
        tower.update(player, towerManager, i, mobManager, data.Map.WayPoints, deltaTime)
    end
    for i, mob in pairs(mobManager.Mobs) do
        local hum = mob.Object:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            table.remove(mobManager.Mobs, i)
            coinManager.Coins += 10
            RemoteEvent:FireClient(player, "CoinUpdate", Data[1].Coins)
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
                local healthReduction = mobManager:startMovement(playerIndex, i)
                if healthReduction > 0 then
                    data.Base.Health -= healthReduction
                    RemoteEvent:FireClient(player, "BaseHpUpdate", data.Base)
                end
            end)
        end
    end
    if #mobManager.Mobs < 1 and #mobManager.PreSpawn < 1 and not mobManager.Starting then
        RemoteEvent:FireClient(player, "WaveReady", data.Mobs.CurrentWave + 1)
        mapManager:generateChunk()
        RemoteEvent:FireClient(player, "MapUpdate", data.Map)
        mobManager:startWave()
        RemoteEvent:FireClient(player, "WaveStart", data.Mobs.CurrentWave)
    end
end

function Game.start(players)
    for i = 1, 2, 1 do
        Data[i] = {}
    end
    Draft.startDraft(players)
    local draft = DraftEnd.Event:Wait(0)
    for i = 1, 2, 1 do
        Data[i].Player = players[i]
        Data[i].Towers = TowerManager.new(draft[i])
        RemoteEvent:FireClient(players[i], "CardsUpdate", Data[i].Towers.Cards)
    end
    task.wait(2)
    for i = 1, 2, 1 do
        Data[i].Map = MapManager.load("Basic", Vector3.new(0, 0, ((-1) ^ i) * 100))
    end
    task.wait(1)
    for i = 1, 2, 1 do
        Data[i].Base = BaseManager.new()
        Data[i].Towers:place(i, "Minigunner", Vector3.new(12.5, 5, 40 + ((-1) ^ i) * 100))
    end
    task.wait(1)
    for i = 1, 2, 1 do
        Data[i].Mobs = MobManager.startGame()
        Data[i].Mobs:startWave()
    end
    for i = 1, 2, 1 do
        RemoteEvent:FireClient(players[i], "GameStarted", Data[1])
    end

    local updateTime = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        Game.runUpdate(1, deltaTime)
        Game.runUpdate(2, deltaTime)
        updateTime += deltaTime
        if updateTime >= 0.1 then
            RemoteEvent:FireClient(Data[1].Player, "MobUpdate", Data[1].Mobs.Mobs)
            RemoteEvent:FireClient(Data[2].Player, "MobUpdate", Data[2].Mobs.Mobs)
        end
    end)
end

function Game.singleTest(player)
    Data[1] = {}
    Data[1].Player = player
    Draft.singleDraft(player)
    local draft = DraftEnd.Event:Wait()
    Data[1].Towers = TowerManager.new(draft)
    Data[1].Map = MapGenerator.generateMap(player)
    Data[1].Map:generateChunk()
    Data[1].Base = BaseManager.new()
    Data[1].Mobs = MobManager.startGame()
    Data[1].Coins = CoinManager.new()
    local fol = Instance.new("Folder", ClientLoad)
    fol.Name = player.UserId
    task.wait(1)
    Data[1].Towers:place(1, "Minigunner", {Chunk = Vector2.new(0, 0); Tile = Vector2.new(8, 3)})
    RemoteEvent:FireClient(player, "GameStarted", Data[1])
    RemoteEvent:FireClient(player, "WaveReady", Data[1].Mobs.CurrentWave + 1)
    Data[1].Mobs:startWave()
    RemoteEvent:FireClient(player, "WaveStart", Data[1].Mobs.CurrentWave)
    print("DataMap", Data[1].Map)
    local updateTime = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        Game.runUpdate(1, deltaTime)
        updateTime += deltaTime
        if updateTime > 0.1 then
            RemoteEvent:FireClient(Data[1].Player, "MobUpdate", Data[1].Mobs)
            updateTime = 0
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
    for i, data in pairs(Data) do
        if data.Player == player then
            local placed = data.Towers:place(i, towerName, position)
            if placed then
                RemoteEvent:FireClient(player, "TowerUpdate", data.Towers)
                RemoteEvent:FireClient(player, "CoinUpdate", data.Coins)
            end
        end
    end
end)

ManageTower.Event:Connect(function(player, manageType, towerIndex)
    for i, data in pairs(Data) do
        if data.Player == player then
            local applied = data.Towers:upgrade(i, manageType, towerIndex)
            if applied then
                RemoteEvent:FireClient(player, "TowerUpdate", data.Towers)
            end
        end
    end
end)