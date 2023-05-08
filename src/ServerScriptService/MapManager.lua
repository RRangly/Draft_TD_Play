local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Settings = require(ReplicatedStorage.Game.Settings)
local Maps = ReplicatedStorage.Maps
local MapModels = ReplicatedStorage.MapModels
local ActiveMap = Workspace.Map

local MapManager = {}

function MapManager.load(mapName)
    local mapModule = Maps:FindFirstChild(mapName)
    local mapModel = MapModels:FindFirstChild(mapName)
    if not mapModule or not mapModel then
        print("LoadCancelled", mapModule, mapModel)
        return
    end
    ActiveMap:ClearAllChildren()
    local map = require(mapModule)
    local clone = mapModel:Clone()
    clone.Parent = ActiveMap
    
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "GameMap"
        end
    end

    Settings.CurrentMap = mapName
    for _, player in pairs(Players:GetPlayers()) do
        player.Character:MoveTo(map.PlayerSpawn)
    end
end
return MapManager