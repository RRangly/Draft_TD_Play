local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TowerModels = ReplicatedStorage.TowerModels
local Towers = ReplicatedStorage.Towers
local WorkSpaceTower = Workspace.Towers
local MobManager = require(script.Parent.MobManager)
local TowerManager = {
    Towers = {}
}

local function towerAttack(model, damage, range)
    local mobs = MobManager.Mobs
    local towerPart = model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)
    local closestMob
    local closestDistance = range

    for i, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < closestDistance then
            closestDistance = mobDistance
            closestMob = {mob, i}
        end
    end

    if closestMob then
        print("AttackClosestMob")
        closestMob[1]:TakeDamage(damage, closestMob[2])
    end
end
local function place(towerName, position)
    local tower = require(Towers:FindFirstChild(towerName))
    local clone = TowerModels:FindFirstChild(towerName):Clone()
    clone.Parent = WorkSpaceTower
    clone:MoveTo(Vector3.new(position.X, 5, position.Z))
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CollisionGroup = "GameAssets"
            --part:SetNetworkOwner(nil)
        end
    end
    local attTime = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        attTime += deltaTime
        if attTime >= tower.Stats.AttackSpeed then
            attTime = 0
            towerAttack(clone, tower.Stats.Damage, tower.Stats.AttackRange)
        end
    end)
    table.insert(TowerManager.Towers, {
        Model = clone;
        Name = towerName
    })
end

function TowerManager.place(player, towerName, position)
    place(towerName, position)
end

return TowerManager