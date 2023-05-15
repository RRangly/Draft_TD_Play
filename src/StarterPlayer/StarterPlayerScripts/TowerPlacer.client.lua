local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Towers = ReplicatedStorage.Towers
local TowerModels = ReplicatedStorage.TowerModels
local RemoteEvent = ReplicatedStorage.ServerCommunication
local PlayerGuis = ReplicatedStorage.PlayerGuis
local PlayerGuiAssets = ReplicatedStorage.PlayerGuiAssets
local TowerSelection = ReplicatedStorage.ClientEvents.TowerSelection
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local TowerPlacer = {}

function TowerPlacer.getPosition()
    local mousePosition = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 100)
    return rayResult.Position
end

UserInputService.InputBegan:Connect(function(inputObj)
    if inputObj.KeyCode == Enum.KeyCode.F then
        local mousePosition = TowerPlacer.getPosition()
        local clone = TowerModels:WaitForChild("Minigunner"):Clone()
        clone.Parent = Workspace
        clone:MoveTo(mousePosition)
    end
end)

TowerSelection.Event:Connect(function(cards)
    local clone = PlayerGuis.TowerPlacer:Clone()
    clone.Parent = PlayerGui
    local xInterval = 1 / (#cards + 1)
    for i, tower in pairs(cards) do
        print("Cards", cards)
        print("I", i)
        local frame = PlayerGuiAssets.TowerFrame:Clone()
        frame.Parent = clone.TowersFrame
        frame.Position = UDim2.new(xInterval * i, 0, 0, 0)
        frame.TowerName.Text = tower
    end
end)