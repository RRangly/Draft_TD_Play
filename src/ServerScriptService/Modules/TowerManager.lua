local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Data = require(ServerScriptService.Modules.Data)
local TowerModels = ReplicatedStorage.TowerModels
local Towers = ReplicatedStorage.Towers
local WorkSpaceTower = Workspace.Towers

local TowerManager = {}
TowerManager.__index = TowerManager

function TowerManager:checkPlacementAvailable(towerType, position)
    local start = Vector3.new(position.X, position.Y + 1, position.Z)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local ray = Workspace:Raycast(start, Vector3.new(0, -10, 0), rayCastParam)
    if ray and ray.Instance:GetAttribute("Placement") == towerType then
        return true
    end
    return false
end

function TowerManager:place(towerIndex, position)
    local cards = self.Cards
    local card = cards[towerIndex]
    if not card then
        return
    end

    local towerInfo = require(Towers:FindFirstChild(cards[towerIndex]))
    local placeAble = TowerManager:checkPlacementAvailable(towerInfo.Placement.Type, position)

    if placeAble and #self.Towers < self.TowerLimit then
        local clone = TowerModels:FindFirstChild(card):Clone()
        clone.Parent = WorkSpaceTower
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = true
                part.CanTouch = false
                part.CanQuery = false
                part.CollisionGroup = "Towers"
            end
        end
        local place = Vector3.new(position.X, position.Y + towerInfo.Placement.Height, position.Z)
        clone:PivotTo(CFrame.new(place))
        table.insert(self.Towers, {
            Name = card;
            Model = clone;
            AttackCD = 0;
            PreAttackCD = 0;
            Level = 1;
            Position = clone:GetPivot().Position;
            Target = "First";
        })
        table.remove(self.Cards, towerIndex)
        return true
    end
    return false
end

function TowerManager:manage(manageType, towerIndex)
    local coinManager = Data[self.PIndex].CoinManager
    local tower = self.Towers[towerIndex]

    if tower then
        local towerInfo = require(Towers:FindFirstChild(tower.Name))
        if manageType == "Sell" then
            tower.Model:Destroy()
            coinManager.Coins += towerInfo.Stats[1].Cost
            table.remove(self.Towers, towerIndex)
            return true
        end
        if manageType == "Upgrade" then
            if coinManager.Coins >= towerInfo.Stats[tower.Level + 1].Cost then
                coinManager.Coins -= towerInfo.Stats[tower.Level + 1].Cost
                tower.Level += 1
                return true
            end
        end
        if manageType == "SwitchTarget" then
            if tower.Target == "Closest" then
                tower.Target = "Lowest Health"
            elseif tower.Target == "Lowest Health" then
                tower.Target = "First"
            elseif tower.Target == "First" then
                tower.Target = "Closest"
            end
            return true
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

function TowerManager:attackAvailable(towerIndex)
    local mobs = Data[self.PIndex].MobManager.Mobs
    local tower = self.Towers[towerIndex]

    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local range = towerInfo.Stats[tower.Level].AttackRange
    local towerVector = Vector3.new(tower.Position.X, 0, tower.Position.Z)

    for _, mob in ipairs(mobs) do
        local mobVector = mob.Position
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < range then
            return true
        end
    end

    return false
end

function TowerManager:findClosestMob(towerIndex)
    local mobs = Data[self.PIndex].MobManager.Mobs
    local tower = self.Towers[towerIndex]

    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local towerVector = Vector3.new(tower.Position.X, 0, tower.Position.Z)
    local closestMob = nil
    local closestDistance = towerInfo.Stats[tower.Level].AttackRange

    for i, mob in ipairs(mobs) do
        local mobVector = mob.Position
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < closestDistance then
            closestMob = i
            closestDistance = mobDistance
        end
    end
    return closestMob
end

function TowerManager:findLowestHealth(towerIndex)
    local mobs = Data[self.PIndex].MobManager.Mobs
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local range = towerInfo.Stats[tower.Level].AttackRange
    local towerVector = Vector3.new(tower.Position.X, 0, tower.Position.Z)

    local lowestHealthMob = nil
    local lowestHealth = math.huge
    for i, mob in ipairs(mobs) do
        local mobVector = mob.Position
        local mobHealth = mob.Health
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < range and mobHealth < lowestHealth then
            lowestHealthMob = i
        end
    end
    return lowestHealthMob
end

function TowerManager:findFirstMob(towerIndex)
    local mobs = Data[self.PIndex].MobManager.Mobs
    local wayPoints = Data[self.PIndex].MapManager.WayPoints
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local range = towerInfo.Stats[tower.Level].AttackRange
    local towerVector = Vector3.new(tower.Position.X, 0, tower.Position.Z)

    local FirstMob = nil
    local FirstWaypoint = 0
    local FirstDistance = 0
    for i, mob in ipairs(mobs) do
        local mobVector = mob.Position
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < range then
            if mob.Waypoint >= FirstWaypoint then
                local waypoint = wayPoints[mob.Waypoint - 1]
                local waypointVector = Vector3.new(waypoint.X, 0, waypoint.Z)
                local waypointDistance = (mobVector - waypointVector).Magnitude
                if mob.Waypoint > FirstWaypoint or waypointDistance >= FirstDistance then
                    FirstMob = i
                    FirstDistance = waypointDistance
                    FirstWaypoint = mob.Waypoint
                end
            end
        end
    end
    return FirstMob
end

function TowerManager.new(cards, pIndex)
    local towers = {
        PIndex = pIndex;
        Cards = cards;
        Towers = {};
        TowerLimit = 20;
    }
    setmetatable(towers, TowerManager)
    return towers
end

return TowerManager