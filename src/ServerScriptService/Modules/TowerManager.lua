local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TowerModels = ReplicatedStorage.TowerModels
local Towers = ReplicatedStorage.Towers
local WorkSpaceTower = Workspace.Towers

local TowerManager = {}
TowerManager.__index = TowerManager

function TowerManager:attackAvailable(towerIndex, mobs)
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local towerPart = tower.Model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)

    for _, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < towerInfo.Stats.AttackRange then
            return true
        end
    end

    return false
end

function TowerManager:findClosestMob(towerIndex, mobs)
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local towerPart = tower.Model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)

    local closestMob = nil
    local closestDistance = towerInfo.Stats.AttackRange
    for i, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < closestDistance then
            closestMob = i
            closestDistance = mobDistance
        end
    end

    return closestMob
end

function TowerManager:towerUpdate(towerIndex, mobs, deltaTime)
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    if self:attackAvailable(towerIndex, mobs.Mobs) then
        tower.AttackCD += deltaTime
        if tower.AttackCD >= towerInfo.Stats.AttackSpeed then
            tower.AttackCD = 0
            mobs:TakeDamage(self:findClosestMob(towerIndex, mobs.Mobs), towerInfo.Stats.Damage)
        end
    else
        tower.AttackCD = 0
    end
end

function TowerManager:place(towerName, position)
    local tower = require(Towers:FindFirstChild(towerName))
    local clone = TowerModels:FindFirstChild(towerName):Clone()
    clone.Parent = WorkSpaceTower
    clone:MoveTo(Vector3.new(position.X, 5, position.Z))
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CollisionGroup = "GameAssets"
        end
    end
    table.insert(self.Towers, {
        Name = towerName;
        Model = clone;
        AttackCD = 0;
    })
end

function TowerManager:delete(towerIndex)
    if self.Towers[towerIndex] then
        self.Towers[towerIndex].Model:Destroy()
        table.remove(self.Towers, towerIndex)
    end
end

function TowerManager.new(cards)
    local towers = {
        Cards = cards;
        Towers = {};
    }
    setmetatable(towers, TowerManager)
    return towers
end

return TowerManager