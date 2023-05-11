local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RemoteEvent = ReplicatedStorage.ServerCommunication

local Settings = require(ReplicatedStorage.Game.Settings)
local Mobs = ReplicatedStorage.Mobs
local MobModels = ReplicatedStorage.MobModels
local Maps = ReplicatedStorage.Maps
local MobFolder = Workspace.Mobs

local MobManager = {
    CurrentWave = 0;
    Mobs = {};
    PreSpawn = {};
}
MobManager.__index = MobManager

function MobManager.Spawn(mobName)
    local mobInfo = require(Mobs:FindFirstChild(mobName))
    local map = require(Maps:FindFirstChild(Settings.CurrentMap))
    local wayPoints = map.WayPoints
    local model = MobModels:FindFirstChild(mobName)
    local clone = model:Clone()
    local humanoid = clone.Humanoid
    humanoid.WalkSpeed = mobInfo.Stats.WalkSpeed
    humanoid.MaxHealth = mobInfo.Stats.MaxHealth
    humanoid.Health = mobInfo.Stats.MaxHealth
    clone.Parent = MobFolder
    clone:MoveTo(wayPoints[1])
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "GameAssets"
            part:SetNetworkOwner(nil)
        end
    end

    coroutine.wrap(function()
        for i = 2, #wayPoints, 1 do
            if not humanoid then
                return
            end
            humanoid:MoveTo(wayPoints[i])
            humanoid.MoveToFinished:Wait()
        end
    end)()
    local mobData = {
        Object = clone;
        MobName = mobName;
        MaxHealth = mobInfo.Stats.MaxHealth;
        Health = mobInfo.Stats.MaxHealth;
    }
    setmetatable(mobData, MobManager)
    table.insert(MobManager.Mobs, mobData)
end

function MobManager.startWave()
    MobManager.CurrentWave += 1
    print("Starting Wave ".. MobManager.CurrentWave)
    for _ = 1, MobManager.CurrentWave * 3, 1 do
        table.insert(MobManager.PreSpawn, "Zombie")
    end
    coroutine.wrap(
        function()
            for i = #MobManager.PreSpawn, 1, -1 do
                local mobName = MobManager.PreSpawn[i]
                MobManager.Spawn(mobName)
                table.remove(MobManager.PreSpawn, i)
                task.wait(0.25)
            end
        end
    )()
end

function MobManager.killHumanoid(mobIndex)
    table.remove(MobManager.Mobs, mobIndex)
    if #MobManager.Mobs < 1 and #MobManager.PreSpawn < 1 then
        MobManager.startWave()
    end
end

function MobManager:TakeDamage(damage, mobIndex)
    local humanoid = self.Object.Humanoid
    humanoid:TakeDamage(damage)
    if humanoid.Health <= 0 then
        self.Object:Destroy()
        table.remove(MobManager.Mobs, mobIndex)
        if #MobManager.Mobs < 1 and #MobManager.PreSpawn < 1 then
            MobManager.startWave()
        end
        --MobManager.killHumanoid(mobIndex)
    end
end

function MobManager.startGame()
    MobManager.CurrentWave = 0
    MobManager.startWave()
end

local updateTime = 0

RunService.Heartbeat:Connect(function(deltaTime)
    updateTime += deltaTime
    if updateTime >= 0.1 then
        RemoteEvent:FireAllClients("MobUpdate",MobManager.Mobs)
    end
end)
return MobManager