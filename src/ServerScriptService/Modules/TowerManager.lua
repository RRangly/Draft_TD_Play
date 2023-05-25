local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ClientLoad = ReplicatedStorage.ClientLoad
local TowerModels = ReplicatedStorage.TowerModels
local Towers = ReplicatedStorage.Towers
local WorkSpaceTower = Workspace.Towers

local TowerManager = {}
TowerManager.__index = TowerManager

function TowerManager:playSound(player, soundName)
    player = Instance.new("Player")
    local folder = ClientLoad:FindFirstChild(player.UserId)
    local instance = Instance.new("StringValue", folder)
    instance.Name = "PlaySound"
    instance.Value = soundName
end

function TowerManager:playAnimation(player, towerIndex)
    local instance = Instance.new("IntValue", ClientLoad)
    instance.Name = "PlayAnim"
    instance.Value = towerIndex
end

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

function TowerManager:checkPlacementAvailable(towerPosition)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local origin = Vector3.new(towerPosition.X, towerPosition.Y + 1, towerPosition.Z)
    local ending = Vector3.new(towerPosition.X, towerPosition.Y - 3000, towerPosition.Z)
    return Workspace:Raycast(origin, ending, rayCastParam)
end

function TowerManager:place(towerName, position, coins)
    local tower = require(Towers:FindFirstChild(towerName))
    local cost = tower.Stats.Cost
    if coins.Coins >= cost then
        local ray = TowerManager:checkPlacementAvailable(position)
        if ray then
            local mapType = ray.Instance:GetAttribute("MapType")
            if mapType == tower.Placement.Type then
                local clone = TowerModels:FindFirstChild(towerName):Clone()
                clone.Parent = WorkSpaceTower
                clone:MoveTo(Vector3.new(position.X, ray.Position.Y, position.Z))
                for _, part in pairs(clone:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = true
                        part.CollisionGroup = "GameAssets"
                    end
                end
                coins.Coins -= cost
                table.insert(self.Towers, {
                    Name = towerName;
                    Model = clone;
                    AttackCD = 0;
                    PreAttackCD = 0;
                })
            return true
            end
        end
    end
    return false
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