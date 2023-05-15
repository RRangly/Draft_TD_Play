local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Mobs = ReplicatedStorage.Mobs
local MobModels = ReplicatedStorage.MobModels
local MobFolder = Workspace.Mobs

local MobManager = {}
MobManager.__index = MobManager

function MobManager:Spawn(mobName)
    local mobInfo = require(Mobs:FindFirstChild(mobName))
    local model = MobModels:FindFirstChild(mobName)

    local wayPoints = self.Map.WayPoints
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
    table.insert(self.Mobs, mobData)
end

function MobManager:startWave()
    self.CurrentWave += 1
    print("Starting Wave ".. self.CurrentWave)
    for _ = 1, self.CurrentWave * 3, 1 do
        table.insert(self.PreSpawn, "Zombie")
    end
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
        table.remove(self.Mobs, mobIndex)
        if #self.Mobs < 1 and #self.PreSpawn < 1 then
            self:startWave()
        end
    end
end

function MobManager.startGame(map)
    local mobs = {
        CurrentWave = 0;
        Map = map;
        Mobs = {};
        PreSpawn = {};
    }
    setmetatable(mobs, MobManager)
    return mobs
end

return MobManager