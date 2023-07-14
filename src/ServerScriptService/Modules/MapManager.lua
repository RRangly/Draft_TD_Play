local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Settings = require(ReplicatedStorage.Game.Settings)
local Maps = ReplicatedStorage.Maps
local MapModels = ReplicatedStorage.MapModels
local ActiveMap = Workspace.Map

local MapManager = {}

function MapManager.load(mapName, origin)
    ActiveMap:ClearAllChildren()
    local mapInfo = require(Maps:FindFirstChild(mapName))
    local mapModel = MapModels:FindFirstChild(mapName)

    local map = {
        WayPoints = {};
    }
    local ps = mapInfo.PlayerSpawn
    map.PlayerSpawn = Vector3.new(ps.X + origin.X, ps.Y + origin.Y, ps.Z + origin.Z)
    for i, waypoint in pairs(mapInfo.WayPoints) do
        map.WayPoints[i] = Vector3.new(waypoint.X + origin.X, waypoint.Y + origin.Y, waypoint.Z + origin.Z)
    end
    local clone = mapModel:Clone()
    clone.Parent = ActiveMap

    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            --part.CollisionGroup = "GameMap"
            local pos = part.Position
            part.Position = Vector3.new(pos.X + origin.X, pos.Y + origin.Y, pos.Z + origin.Z)
        end
    end

    Settings.CurrentMap = mapName
    return map
end

return MapManager