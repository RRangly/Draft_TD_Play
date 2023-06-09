local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Data = require(script.Parent.Data)

local Mobs = ReplicatedStorage.Mobs
local MobModels = ReplicatedStorage.MobModels
local MobFolder = Workspace.Mobs

local MobManager = {}
MobManager.__index = MobManager

function MobManager:Spawn(mobName)
    local mobInfo = require(Mobs:FindFirstChild(mobName))
    local model = MobModels:FindFirstChild(mobName)

    local clone = model:Clone()
    local humanoid = clone.Humanoid

    humanoid.WalkSpeed = mobInfo.Stats.WalkSpeed
    humanoid.MaxHealth = mobInfo.Stats.MaxHealth
    humanoid.Health = mobInfo.Stats.MaxHealth

    clone.Parent = MobFolder
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "GameAssets"
            part:SetNetworkOwner(nil)
        end
    end

    local mobData = {
        Object = clone;
        MobName = mobName;
        MaxHealth = mobInfo.Stats.MaxHealth;
        Health = mobInfo.Stats.MaxHealth;
    }
    setmetatable(mobData, MobManager)
    table.insert(self.Mobs, mobData)
end

function MobManager:startWave()
    self.CurrentWave += 1
    self.Starting = true
    local difficultyWeight = 1.075^self.CurrentWave * 7
    task.wait(5)
    print("Starting Wave ".. self.CurrentWave)
    for _ = 1, self.CurrentWave * 3, 1 do
        table.insert(self.PreSpawn, "Zombie")
    end
    self.Starting = false
    coroutine.wrap(
        function()
            for _ = 1, #self.PreSpawn, 1 do
                local mobName = self.PreSpawn[1]
                self:Spawn(mobName)
                table.remove(self.PreSpawn, 1)
                task.wait(0.25)
            end
        end
    )()
end

function MobManager:TakeDamage(mobIndex, damage)
    local mob = self.Mobs[mobIndex]
    local humanoid = mob.Object.Humanoid
    humanoid:TakeDamage(damage)
    if humanoid.Health <= 0 then
        mob.Object:Destroy()
    end
end

function MobManager:startMovement(playerIndex, mobIndex)
    local wayPoints = Data[playerIndex].Map.WayPoints
    local mob = self.Mobs[mobIndex]
    local moveConnection
    local humanoid = mob.Object.Humanoid
    local i = 2
    local healthReduction = nil
    table.insert(self.CurrentMoving, humanoid)
    mob.Object:MoveTo(wayPoints[1])
    humanoid:MoveTo(wayPoints[i])
    mob.Waypoint = i
    moveConnection = humanoid.MoveToFinished:Connect(function()
        i += 1
        if wayPoints[i] then
            humanoid:MoveTo(wayPoints[i])
            mob.Waypoint = i
        else
            healthReduction = 1
        end
    end)

    local deathConnection = humanoid.Died:Once(function()
        moveConnection:Disconnect()
        for index, hum in pairs(self.CurrentMoving) do
            if humanoid == hum then
                table.remove(self.CurrentMoving, index)
            end
        end
        healthReduction = 0
    end)
    repeat
        task.wait()
    until healthReduction
    mob.Object:Destroy()
    deathConnection:Disconnect()
    return healthReduction
end

function MobManager.startGame()
    local mobs = {
        CurrentWave = 0;
        Mobs = {};
        PreSpawn = {};
        CurrentMoving = {};
        Starting = true;
        Waypoint = 1;
    }
    setmetatable(mobs, MobManager)
    return mobs
end

return MobManager