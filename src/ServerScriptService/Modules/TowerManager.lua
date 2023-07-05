local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ClientLoad = ReplicatedStorage.ClientLoad
local TowerModels = ReplicatedStorage.TowerModels
local Towers = ReplicatedStorage.Towers
local WorkSpaceTower = Workspace.Towers
local Data = require(script.Parent.Data)

local TowerManager = {}
TowerManager.__index = TowerManager

function TowerManager:attackAvailable(towerIndex, mobs)
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local range = towerInfo.Stats[tower.Level].AttackRange
    local towerPart = tower.Model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)

    for _, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        if not mobPart then
            continue
        end
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < range then
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
    local closestDistance = towerInfo.Stats[tower.Level].AttackRange
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
    local range = towerInfo.Stats[tower.Level].AttackRange
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

function TowerManager:findFirstMob(towerIndex, mobs, waypoints)
    local tower = self.Towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local range = towerInfo.Stats[tower.Level].AttackRange
    local towerPart = tower.Model.PrimaryPart
    local towerVector = Vector3.new(towerPart.Position.X, 0, towerPart.Position.Z)

    local FirstMob = nil
    local FirstWaypoint = 0
    local FirstDistance = 0
    for i, mob in pairs(mobs) do
        local mobPart = mob.Object.PrimaryPart
        if not mobPart then continue end
        local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
        local mobDistance = (mobVector - towerVector).Magnitude
        if mobDistance < range then
            if mob.Waypoint >= FirstWaypoint then
                local waypoint = waypoints[mob.Waypoint - 1]
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

function TowerManager:checkPlacementAvailable(chunks, towerName, position)
    local towerInfo = require(Towers:FindFirstChild(towerName))
    local chunkPos = position.Chunk
    local tilePos = position.Tile
    if chunks[chunkPos.X] and chunks[chunkPos.X][chunkPos.Y] then
        local chunk = chunks[chunkPos.X][chunkPos.Y]
        local tiles = chunk.Tiles
        if tiles[tilePos.X] and tiles[tilePos.X][tilePos.Y] then
            local tile = tiles[tilePos.X][tilePos.Y]
            if tile.Type == towerInfo.Placement.Type and not tile.Occupied then
                return tile
            end
        end
    end
    return false
end

function TowerManager:place(playerIndex, towerIndex, position)
    local data = Data[playerIndex]
    local cards = self.Cards
    local chunks = data.MapManager.Chunks
    local chunkPos = position.Chunk
    local tilePos = position.Tile
    local card = cards[towerIndex]
    if not card then
        return
    end
    --local tower = require(Towers:FindFirstChild(cards[towerIndex]))
    local placeTile = TowerManager:checkPlacementAvailable(chunks, card, position)
        if placeTile then
            placeTile.Occupied = true
            local clone = TowerModels:FindFirstChild(card):Clone() 
            clone.Parent = WorkSpaceTower
            for _, part in pairs(clone:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                    part.CanCollide = true
                    part.CanTouch = false
                    part.CanQuery = false
                    part.CollisionGroup = "Towers"
                end
            end
            clone:MoveTo(Vector3.new(chunkPos.X * 50 + tilePos.X * 5, 5, chunkPos.Y * 50 + tilePos.Y * 5))
            table.insert(self.Towers, {
                Name = card;
                Model = clone;
                AttackCD = 0;
                PreAttackCD = 0;
                Level = 1;
                Target = "First";
                Position = position
            })
            table.remove(self.Cards, towerIndex)
            return true
        end
    return false
end

function TowerManager:upgrade(playerIndex, manageType, towerIndex)
    local data = Data[playerIndex]
    local coinManager = data.Coins
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
                tower.Level += 1
                coinManager.Coins -= towerInfo.Stats[tower.Level + 1].Cost
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

function TowerManager.new(cards)
    local towers = {
        Cards = cards;
        Towers = {};
    }
    setmetatable(towers, TowerManager)
    return towers
end

return TowerManager