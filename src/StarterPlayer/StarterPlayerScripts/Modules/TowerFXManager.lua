local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Towers = ReplicatedStorage.Towers
local SoundFX = ReplicatedStorage.SoundFX

local TowerFXManager = {}

function TowerFXManager.attackAvailable(tower, mobs)
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local towerPart = tower.Model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)

    for _, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        if not mobPart then
            continue
        end
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < towerInfo.Stats.AttackRange then
            return true
        end
    end

    return false
end

function TowerFXManager.findClosestMob(tower, mobs)
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local towerPart = tower.Model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)

    local closestMob = nil
    local closestDistance = towerInfo.Stats.AttackRange
    for i, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        if not mobPart then continue end
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < closestDistance then
            closestMob = i
            closestDistance = mobDistance
        end
    end

    return closestMob
end

function TowerFXManager.findLowestHealth(tower, mobs)
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local range = towerInfo.Stats.AttackRange
    local towerPart = tower.Model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)

    local lowestHealthMob = nil
    local lowestHealth = math.huge
    for i, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        if not mobPart then continue end
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local humanoid = mob.Object.Humanoid

        local mobHealth = humanoid.Health
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < range and mobHealth < lowestHealth then
            lowestHealthMob = i
        end
    end

    return lowestHealthMob
end

function TowerFXManager.towerUpdate(tower, mobs, deltaTime)
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local attack = TowerFXManager.attackAvailable(tower, mobs.Mobs)
    if attack then
        tower.AttackCD += deltaTime
        if tower.AttackCD >= towerInfo.Stats.AttackSpeed then
            print("Shoot")
            local sound = SoundFX.MinigunShot
            sound:Play()
            tower.AttackCD = 0
        end
    else
        tower.AttackCD = 0
    end
end

return TowerFXManager