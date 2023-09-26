local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Data = require(ServerScriptService.Modules.Data)
local MobModels = ReplicatedStorage.MobModels
local GameMechanics = require(ReplicatedStorage.Game.GameMechanics)
local MobFolder = Workspace.Mobs

local MobManager = {}
MobManager.__index = MobManager

function MobManager:Spawn(mobInfo)
    local wayPoints = Data[self.PIndex].MapManager.WayPoints
    local model = MobModels:FindFirstChild(mobInfo.Model)
    local clone = model:Clone()
    local humanoid = clone.Humanoid
    humanoid.WalkSpeed = mobInfo.WalkSpeed
    clone.Parent = MobFolder

    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "Mobs"
            part.CanCollide = true
            part:SetNetworkOwner(nil)
        end
    end

    clone:MoveTo(wayPoints[1])
    local mob = {
        Object = clone;
        MobName = "Zombie";
        WalkSpeed = mobInfo.WalkSpeed;
        MaxHealth = mobInfo.MaxHealth;
        Health = mobInfo.MaxHealth;
        Waypoint = 2;
        Position = wayPoints[1];
        Frozen = false;
        Completed = false;
    }
    local i = 2
    humanoid:MoveTo(wayPoints[i])
    humanoid.MoveToFinished:Connect(function()
        i += 1
        if wayPoints[i] then
            humanoid:MoveTo(wayPoints[i])
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

function MobManager:spawnWave(toSpawn)
    for _ = 1, #toSpawn, 1 do
        local mob = toSpawn[1]
        self:Spawn(mob)
        table.remove(toSpawn, 1)
        task.wait(0.2)
    end
end

function MobManager:takeDamage(mobIndex, damage)
    local coinManager = Data[self.PIndex].CoinManager
    local mob = self.Mobs[mobIndex]
    local prevHealth = mob.Health
    mob.Health -= damage
    if mob.Health < 0 then
        mob.Health = 0
    end
    local damageDealt = prevHealth - mob.Health
    coinManager.Coins += damageDealt
    if mob.Health == 0 then
        table.remove(self.Mobs, mobIndex)
        mob.Object:Destroy()
        return {mobIndex, true, damageDealt}
    end
    return {mobIndex, false, damageDealt}
end

function MobManager:freeze(mobIndex, length)
    local mob = self.Mobs[mobIndex]
    local model = mob.Object
    if not mob.Frozen then
        model.Ice.Transparency = 0.4
        local hum = model.Humanoid
        mob.Frozen = true
        hum.WalkSpeed = 0
        task.wait(length)
        if model:FindFirstChild("Ice") then
            model.Ice.Transparency = 1
        end
        hum.WalkSpeed = mob.WalkSpeed
        mob.Frozen = false
    end
end

function MobManager.new(pIndex)
    local mobs = {
        PIndex = pIndex;
        Mobs = {};
    }
    setmetatable(mobs, MobManager)
    return mobs
end

return MobManager