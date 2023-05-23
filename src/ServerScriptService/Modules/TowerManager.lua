local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function TowerManager:findClosestMob(towerIndex, mobs)
    local tower = self.Towers[towerIndex]
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

function TowerManager:findLowestHealth(towerIndex, mobs)
    local tower = self.Towers[towerIndex]
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

function TowerManager:towerUpdate(towerIndex, mobs, deltaTime)
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    if self:attackAvailable(towerIndex, mobs.Mobs) then
        local model = tower.Model
        local mobPart = mobs.Mobs[self:findClosestMob(towerIndex, mobs.Mobs)].Object.PrimaryPart
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(mobPart.Position.X, model:GetPivot().Position.Y, mobPart.Position.Z)))
        tower.AttackCD += deltaTime
        if tower.AttackCD >= towerInfo.Stats.AttackSpeed then
            tower.AttackCD = 0
            mobs:TakeDamage(self:findClosestMob(towerIndex, mobs.Mobs), towerInfo.Stats.Damage)
        end
    else
        tower.AttackCD = 0
    end
end

function TowerManager:checkPlacementAvailable(towerPosition)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local origin = Vector3.new(towerPosition.X, towerPosition.Y + 1, towerPosition.Z)
    local ending = Vector3.new(towerPosition.X, towerPosition.Y - 3000, towerPosition.Z)
    return Workspace:Raycast(origin, ending, rayCastParam)
end

function TowerManager:place(towerName, position)
    local tower = require(Towers:FindFirstChild(towerName))
    local ray = TowerManager:checkPlacementAvailable(position)
    if ray then
        local mapType = ray.Instance:GetAttribute("MapType")
        if mapType ~= tower.Placement.Type then
            return
        end
        local clone = TowerModels:FindFirstChild(towerName):Clone()
        clone.Parent = WorkSpaceTower
        clone:MoveTo(Vector3.new(position.X, ray.Position.Y, position.Z))
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