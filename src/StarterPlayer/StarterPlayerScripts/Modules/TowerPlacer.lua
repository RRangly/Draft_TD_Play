local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Towers = ReplicatedStorage.Towers
local TowerModels = ReplicatedStorage.TowerModels
local RemoteEvent = ReplicatedStorage.ServerCommunication
local PlayerGuis = ReplicatedStorage.PlayerGuis
local PlayerGuiAssets = ReplicatedStorage.PlayerGuiAssets

local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local TowerPlacer = {
    CurrentGui = nil
}

function TowerPlacer.getPosition()
    local mousePosition = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 100)
    return rayResult.Position
end

function TowerPlacer.startPlacement(tower)
    local clone = TowerModels:FindFirstChild(tower):Clone()
    local renderConnection = RunService.RenderStepped:Connect(function()
        clone:MoveTo(TowerPlacer.getPosition())
    end)
    local mouseConnection
    mouseConnection = UserInputService.InputBegan:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
            RemoteEvent:FireServer("PlaceTower")
            clone:Destroy()
            renderConnection:Disconnect()
            mouseConnection:Disconnect()
        elseif inputObj.KeyCode == Enum.KeyCode.F then
            clone:Destroy()
            renderConnection:Disconnect()
            mouseConnection:Disconnect()
        end
    end)
end

function TowerPlacer.updateTowers(cards)
    if TowerPlacer.CurrentGui then
        TowerPlacer.CurrentGui:Destroy()
    end
    local clone = PlayerGuis.TowerPlacer:Clone()
    TowerPlacer.CurrentGui = clone
    clone.Parent = PlayerGui
    local xInterval = 1 / (#cards + 1)
    for i, tower in pairs(cards) do
        local frame = PlayerGuiAssets.TowerFrame:Clone()
        frame.Parent = clone.TowersFrame
        frame.Position = UDim2.new(xInterval * i, 0, 0, 0)
        frame.TowerName.Text = tower
        UserInputService.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                TowerPlacer.startPlacement(tower)
            end
        end)
    end
end

return TowerPlacer 