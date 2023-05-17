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

local TowerManager = {
    RayCast = {

    }
}

function TowerManager.mouseRayCast()
    local mousePosition = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 100)
    return {rayResult.Instance, rayResult.Position}
end

function TowerManager.startPlacement(tower)
    TowerManager.Placing = {}
    TowerManager.Placing.Tower = tower
    TowerManager.Placing.Model = TowerModels:FindFirstChild(tower):Clone();
    TowerManager.Placing.RenderConnection = RunService.Heartbeat:Connect(function()
        TowerManager.Placing.Model:MoveTo(TowerManager.RayCast.Position)
    end)
end

function TowerManager.placeTower()
    local placing = TowerManager.Placing
    local rayCast = TowerManager.RayCast
    placing.Model:Destroy()
    placing.RenderConnection:Disconnect()
    TowerManager.Placing = nil
    RemoteEvent:FireServer("PlaceTower", placing.Tower, rayCast.Position)
end

function TowerManager.cancelPlacement()
    local placing = TowerManager.Placing
    placing.Model:Destroy()
    placing.RenderConnection:Disconnect()
    TowerManager.Placing = nil
end
function TowerManager.selectTower(towers)
    local rayCast = TowerManager.RayCast
    for i, tower in pairs(towers) do
        local model = rayCast.Part.Parent
        if model == tower.Model then
            TowerManager.Selected = {
                Index = i;
                TowerInfo = tower;
            }
        else
            TowerManager.Selected = nil
        end
    end
end
function TowerManager.updateCard(cards)
    if TowerManager.CurrentGui then
        TowerManager.CurrentGui:Destroy()
    end
    local clone = PlayerGuis.TowerPlacer:Clone()
    TowerManager.CurrentGui = clone
    clone.Parent = PlayerGui
    local xInterval = 1 / (#cards + 1)
    for i, tower in pairs(cards) do
        local towerInfo = require(Towers:FindFirstChild(tower))
        local frame = PlayerGuiAssets.TowerFrame:Clone()
        frame.Parent = clone.TowersFrame
        frame.Position = UDim2.new(xInterval * i, 0, 0, 0)
        frame.TowerName.Text = towerInfo.Name
        UserInputService.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                TowerManager.startPlacement(tower)
            end
        end)
    end
end

RunService.RenderStepped:Connect(function()
    local rayCast = TowerManager.mouseRayCast()
    TowerManager.RayCast.Part = rayCast[1]
    TowerManager.RayCast.Position = rayCast[2]
end)

return TowerManager