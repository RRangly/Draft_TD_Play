local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Towers = ReplicatedStorage.Towers

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
local WaveManager = require(Modules.WaveManager)
local ClientLoad = require(Modules.ClientLoad)

local PlayingPlayers = {}
local Game = {}

function Game.runUpdate(playerIndex, deltaTime)
    local data = Data[playerIndex]
    local towerManager = data.Towers
    local mobManager = data.Mobs
    local player = data.Player
    for i, ti in pairs(towerManager.Towers) do
        local tower = require(Towers:FindFirstChild(ti.Name))
        --tower.update(player, towerManager, i, mobManager, data.Map.WayPoints, deltaTime)
        tower.update(data, i, deltaTime)
    end
    for i, mob in pairs(mobManager.Mobs) do
        local hum = mob.Object:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            table.remove(mobManager.Mobs, i)
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
    Draft.megadraft({player})
    local draft = DraftEnd.Event:Wait()
    Data[1].Towers = TowerManager.new(draft[1])
    Data[1].Map = MapGenerator.generateMap(player)
    Data[1].Map:generateChunk()
    Data[1].Base = BaseManager.new()
    Data[1].Mobs = MobManager.new()
    Data[1].Coins = CoinManager.new()
    Data[1].WaveManager = WaveManager.startGame()
    Data[1].ClientLoad = ClientLoad.new(player)
    task.wait(5)
    player.Character:MoveTo(Vector3.new(25, 5, 25))
    RemoteEvent:FireClient(player, "GameStarted", Data[1])
    RemoteEvent:FireClient(player, "WaveReady", Data[1].Mobs.CurrentWave + 1)
    RemoteEvent:FireClient(player, "WaveStart", Data[1].Mobs.CurrentWave)
    local updateTime = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        Game.runUpdate(1, deltaTime)
        updateTime += deltaTime
        if updateTime > 0.1 then
            RemoteEvent:FireClient(player, "MobUpdate", Data[1].Mobs)
            RemoteEvent:FireClient(player, "CoinUpdate", Data[1].Coins)
            updateTime = 0
        end
    end)
    while true do
        RemoteEvent:FireClient(player, "WaveReady", Data[1].Mobs.CurrentWave + 1)
        if (Data[1].WaveManager.CurrentWave + 1) % 5 == 0 then
            Data[1].Map:generateChunk()
        end
        task.wait(5)
        RemoteEvent:FireClient(player, "WaveStart", Data[1].WaveManager.CurrentWave)
        Data[1].WaveManager:startWave(Data[1].Mobs)
    end
end

Players.PlayerAdded:Connect(function(player)
    print("PlayerAdded", player)
    repeat
        wait()
    until player:HasAppearanceLoaded()
    task.wait(3)
    print("GameStarting")
    Game.singleTest(player)
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