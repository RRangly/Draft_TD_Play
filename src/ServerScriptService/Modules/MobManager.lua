local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--local Mobs = ReplicatedStorage.Mobs
local MobModels = ReplicatedStorage.MobModels
local GameMechanics = require(ReplicatedStorage.Game.GameMechanics)
local MobFolder = Workspace.Mobs

local MobManager = {}
MobManager.__index = MobManager

function MobManager:Spawn(waypoints, mobInfo)
    local model = MobModels:FindFirstChild(mobInfo.Model)
    local clone = model:Clone()
    local humanoid = clone.Humanoid
    humanoid.WalkSpeed = mobInfo.WalkSpeed
    clone.Parent = MobFolder

    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "Mobs"
            part.CanCollide = true
            part:SetNetworkOwner(nil)
        end
    end

    clone:MoveTo(waypoints[1])
    local mob = {
        Object = clone;
        MobName = "Zombie";
        WalkSpeed = mobInfo.WalkSpeed;
        MaxHealth = mobInfo.MaxHealth;
        Health = mobInfo.MaxHealth;
        Waypoint = 2;
        Position = waypoints[1];
        Completed = false
    }
    local i = 2
    humanoid:MoveTo(waypoints[i])
    humanoid.MoveToFinished:Connect(function()
        i += 1
        if waypoints[i] then
            humanoid:MoveTo(waypoints[i])
            mob.Waypoint = i
        else
            mob.Completed = true
        end
    end)
    setmetatable(mob, MobManager)
    table.insert(self.Mobs, mob)
end

function MobManager.generateDefaultMob(weight)
    local mob = {
        Model = "Zombie";
        MaxHealth = weight * 2;
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/7)*6);
    }
    return mob
end


function MobManager.generateSpeedMob(weight)
    local mob = {
        Model = "Speedy";
        MaxHealth = math.ceil(weight * 1.5);
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/3)*8);
    }
    return mob
end

function MobManager.generateTankMob(weight)
    local mob = {
        Model = "Stone_Zombie";
        MaxHealth = math.ceil(weight * 4.5);
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/8)*4);
    }
    return mob
end

function MobManager.generateSpecialMob(weight)
    local mob = {
        Model = "Zombie";
        MaxHealth = math.ceil(weight * 2.5);
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/7)*6);
    }
    return mob
end

function MobManager:spawnWave(waypoints, toSpawn)
    for _ = 1, #toSpawn, 1 do
        local mob = toSpawn[1]
        self:Spawn(waypoints, mob)
        table.remove(toSpawn, 1)
        task.wait(0.2)
    end
end

function MobManager:TakeDamage(coinManager, mobIndex, damage)
    local mob = self.Mobs[mobIndex]
    local prevHealth = mob.Health
    if prevHealth > damage then
        mob.Health -= damage
    else
        table.remove(self.Mobs, mobIndex)
        mob.Object:Destroy()
    end
    coinManager.Coins += (prevHealth - mob.Health)
end

function MobManager.new()
    local mobs = {
        CurrentWave = 0;
        Mobs = {};
        CurrentMoving = {};
    }
    setmetatable(mobs, MobManager)
    return mobs
end

return MobManager