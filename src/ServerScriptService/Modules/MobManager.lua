local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Data = require(script.Parent.Data)

local Mobs = ReplicatedStorage.Mobs
local MobModels = ReplicatedStorage.MobModels
local MobFolder = Workspace.Mobs

local MobManager = {}
MobManager.__index = MobManager

function MobManager:Spawn(mobInfo)
    local model = MobModels:FindFirstChild("Zombie")

    local clone = model:Clone()
    local humanoid = clone.Humanoid

    humanoid.WalkSpeed = mobInfo.WalkSpeed
    humanoid.MaxHealth = mobInfo.MaxHealth
    humanoid.Health = mobInfo.MaxHealth

    clone.Parent = MobFolder
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "GameAssets"
            part:SetNetworkOwner(nil)
        end
    end

    local mobData = {
        Object = clone;
        MobName = "Zombie";
        MaxHealth = mobInfo.MaxHealth;
        Health = mobInfo.MaxHealth;
    }
    setmetatable(mobData, MobManager)
    table.insert(self.Mobs, mobData)
end

function MobManager.generateDefaultMob(weight)
    local mob = {
        MaxHealth = weight * 2;
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/7)*6);
    }
    return mob
end


function MobManager.generateSpeedMob(weight)
    local mob = {
        MaxHealth = math.ceil(weight * 1.5);
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/3)*8);
    }
    return mob
end

function MobManager.generateTankMob(weight)
    local mob = {
        MaxHealth = math.ceil(weight * 4.5);
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/8)*4);
    }
    return mob
end

function MobManager.generateSpecialMob(weight)
    local mob = {
        MaxHealth = math.ceil(weight * 2.5);
        WalkSpeed = math.floor((math.log(weight, 1.095) + 5)^(1/7)*6);
    }
    return mob
end

local GenerationFunctions = {
    Default = MobManager.generateDefaultMob;
    Speed = MobManager.generateSpeedMob;
    Tank = MobManager.generateTankMob;
    Special = MobManager.generateSpecialMob;
}

function MobManager:startWave()
    self.CurrentWave += 1
    self.Starting = true
    local difficultyWeight = 1.095^self.CurrentWave * 100
    local waveType = math.random(1, 10)
    local mobsDistribution
    local totalMob
    if waveType < 3 then
        totalMob = math.floor(difficultyWeight / math.random(41, 46))
        mobsDistribution = {
            Default = math.ceil(totalMob * 0.2);
            Tank = math.ceil(totalMob * 0.55);
            Speed = math.ceil(totalMob * 0.1);
            Special = math.ceil(totalMob * 0.15);
        }
    elseif waveType < 5 then
        totalMob = math.floor(difficultyWeight / math.random(26, 33))
        mobsDistribution = {
            Default = math.ceil(totalMob * 0.2);
            Tank = math.ceil(totalMob * 0.15);
            Speed = math.ceil(totalMob * 0.5);
            Special = math.ceil(totalMob * 0.15);
        }
    else
        totalMob = math.floor(difficultyWeight / math.random(22, 28))
        mobsDistribution = {
            Default = math.ceil(totalMob * 0.6);
            Tank = math.ceil(totalMob * 0.15);
            Speed = math.ceil(totalMob * 0.1);
            Special = math.ceil(totalMob * 0.15);
        }
    end
    local mobWeight = math.floor(difficultyWeight / 35)
    for mobType, mobAmount in pairs(mobsDistribution) do
        for _ = 1, mobAmount, 1 do
            local mob = GenerationFunctions[mobType](mobWeight)
            table.insert(self.PreSpawn, math.random(1, #self.PreSpawn + 1), mob)
        end
    end
    task.wait(5)
    print("Starting Wave ".. self.CurrentWave)
    self.Starting = false
    coroutine.wrap(
        function()
            for _ = 1, #self.PreSpawn, 1 do
                local mob = self.PreSpawn[1]
                self:Spawn(mob)
                table.remove(self.PreSpawn, 1)
                task.wait(0.25)
            end
        end
    )()
end

function MobManager:TakeDamage(coinManager, mobIndex, damage)
    local mob = self.Mobs[mobIndex]
    local humanoid = mob.Object.Humanoid
    local prevHealth = humanoid.Health
    humanoid:TakeDamage(damage)
    coinManager.Coins += (prevHealth - humanoid.Health)
    if humanoid.Health <= 0 then
        mob.Object:Destroy()
    end
end

function MobManager:startMovement(playerIndex, mobIndex)
    local wayPoints = table.clone(Data[playerIndex].Map.WayPoints)
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
    }
    setmetatable(mobs, MobManager)
    return mobs
end

return MobManager